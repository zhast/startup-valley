import type { FromWorker, ToWorker } from "./messages";
import { MAX_REQUEST_BYTES } from "./messages";

type Listener = (json: string) => void;
type State = "idle" | "starting" | "ready" | "stopping" | "failed";
type Envelope = { id?: string; method?: string; kind?: string; [key: string]: unknown };

export interface StartupValleyWorkerBridge {
  start(): Promise<void>;
  request(json: string): void;
  onMessage(callback: Listener): () => void;
  offMessage(callback: Listener): void;
  onError(callback: Listener): () => void;
  offError(callback: Listener): void;
  stop(): Promise<void>;
  diagnostics(): { state: State; error: string | null; storage: string | null; pendingRequests: { id: string; method: string }[]; lastResponses: Record<string, Envelope> };
}

declare global { interface Window { StartupValleyWorker: StartupValleyWorkerBridge } }

// This is an IIFE loaded with a normal script tag. Capture its own URL now so
// Godot exports hosted under any path find the sibling worker and WASM assets.
const scriptUrl = (document.currentScript as HTMLScriptElement | null)?.src;
if (!scriptUrl) throw new Error("Startup Valley bridge must be loaded with a script tag.");
const workerUrl = new URL("worker.js", scriptUrl);
const messageListeners = new Set<Listener>();
const errorListeners = new Set<Listener>();
const pending = new Map<string, string>();
const lastResponses: Record<string, Envelope> = Object.create(null);
let state: State = "idle";
let error: string | null = null;
let storage: string | null = null;
let worker: Worker | null = null;
let startPromise: Promise<void> | null = null;
let startResolve: (() => void) | null = null;
let startReject: ((reason: Error) => void) | null = null;
let startTimer: ReturnType<typeof setTimeout> | null = null;
let stopPromise: Promise<void> | null = null;
let stopResolve: (() => void) | null = null;
let stopTimer: ReturnType<typeof setTimeout> | null = null;

function emit(listeners: Set<Listener>, value: string): void {
  for (const listener of [...listeners]) {
    try { listener(value); } catch (cause) { console.error("Startup Valley listener failed", cause); }
  }
}

function clearStartTimer(): void { if (startTimer !== null) clearTimeout(startTimer); startTimer = null; }

function fail(message: string): void {
  clearStartTimer();
  state = "failed";
  error = message;
  worker?.terminate();
  worker = null;
  startReject?.(new Error(message));
  startResolve = startReject = null;
  startPromise = null;
  pending.clear();
  emit(errorListeners, message);
  finishStop();
}

function finishStop(): void {
  if (stopTimer !== null) clearTimeout(stopTimer);
  stopTimer = null;
  worker?.terminate();
  worker = null;
  pending.clear();
  if (state !== "failed") state = "idle";
  stopResolve?.();
  stopResolve = null;
  stopPromise = null;
  startPromise = null;
}

function receive({ data }: MessageEvent<FromWorker>): void {
  switch (data.type) {
    case "ready":
      if (state === "stopping") break;
      clearStartTimer();
      state = "ready";
      storage = data.storage;
      startResolve?.();
      startResolve = startReject = null;
      break;
    case "message": {
      const response = JSON.parse(data.json) as Envelope;
      if (response.kind === "response" && typeof response.id === "string") {
        const method = pending.get(response.id);
        if (method) lastResponses[method] = response;
        pending.delete(response.id);
      }
      emit(messageListeners, data.json);
      break;
    }
    case "error": fail(data.message); break;
    case "stopped": finishStop(); break;
  }
}

const bridge: StartupValleyWorkerBridge = {
  start() {
    if (state === "ready") return Promise.resolve();
    if (state === "stopping") return Promise.reject(new Error("The save is still closing. Please retry shortly."));
    if (startPromise) return startPromise;
    state = "starting";
    error = null;
    storage = null;
    startPromise = new Promise<void>((resolve, reject) => { startResolve = resolve; startReject = reject; });
    const result = startPromise;
    try {
      worker = new Worker(workerUrl, { type: "module", name: "startup-valley-simulation" });
      worker.onmessage = receive;
      worker.onerror = (event) => { event.preventDefault(); fail(`The game worker stopped: ${event.message || "could not load runtime"}`); };
      worker.onmessageerror = () => fail("The game worker sent an unreadable message. Your committed save remains on this device.");
      startTimer = setTimeout(() => fail("The game save did not open within 45 seconds. Close other game tabs and retry."), 45_000);
      worker.postMessage({ type: "start" } satisfies ToWorker);
    } catch (cause) { fail(cause instanceof Error ? cause.message : String(cause)); }
    return result;
  },
  request(json) {
    if (state !== "ready" || !worker) throw new Error(error ?? "The game save is not ready.");
    if (typeof json !== "string" || new TextEncoder().encode(json).length > MAX_REQUEST_BYTES) throw new Error("Game request exceeds the 1 MiB limit.");
    try {
      const envelope = JSON.parse(json) as Envelope;
      if (envelope && typeof envelope.id === "string" && typeof envelope.method === "string") pending.set(envelope.id, envelope.method);
    } catch { /* Shared worker validation returns the protocol error. */ }
    worker.postMessage({ type: "request", json } satisfies ToWorker);
  },
  onMessage(callback) { messageListeners.add(callback); return () => messageListeners.delete(callback); },
  offMessage(callback) { messageListeners.delete(callback); },
  onError(callback) { errorListeners.add(callback); return () => errorListeners.delete(callback); },
  offError(callback) { errorListeners.delete(callback); },
  stop() {
    if (!worker) return Promise.resolve();
    if (stopPromise) return stopPromise;
    clearStartTimer();
    startReject?.(new Error("Game startup was cancelled."));
    startResolve = startReject = null;
    state = "stopping";
    stopPromise = new Promise<void>((resolve) => { stopResolve = resolve; });
    const result = stopPromise;
    stopTimer = setTimeout(() => fail("The worker could not finish closing. The last committed save will reopen next time."), 5_000);
    worker.postMessage({ type: "stop" } satisfies ToWorker);
    return result;
  },
  diagnostics() {
    return structuredClone({ state, error, storage, pendingRequests: [...pending].map(([id, method]) => ({ id, method })), lastResponses });
  },
};

window.StartupValleyWorker = Object.freeze(bridge);
window.addEventListener("pagehide", () => { void bridge.stop(); });
// A restored Godot instance retains its old callbacks and connection state.
// Reload both halves together after BFCache rather than leave stale UI alive.
window.addEventListener("pageshow", (event) => { if (event.persisted) window.location.reload(); });
