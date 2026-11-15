import sqlite3InitModule from "@sqlite.org/sqlite-wasm";
import { sha256 } from "@noble/hashes/sha2.js";
import { bytesToHex } from "@noble/hashes/utils.js";
import { createBrowserRuntime } from "../../harness/src/browser-runtime";
import { geometryData, migrations, schemas } from "./resources";
import { openDatabase, resetDatabase, type Pool, type WasmDatabase } from "./sqlite-adapter";
import { MAX_REQUEST_BYTES, type FromWorker, type ToWorker } from "./messages";

const scope = self as unknown as DedicatedWorkerGlobalScope;
const send = (message: FromWorker): void => scope.postMessage(message);
let runtime: ReturnType<typeof createBrowserRuntime> | null = null;
let pool: Pool | null = null;
let connection: WasmDatabase | null = null;
let releaseLock: (() => void) | null = null;
let lockLifetime: Promise<void> | null = null;
let queue: Promise<void> = Promise.resolve();
let started = false;

async function ownSave(): Promise<void> {
  if (!scope.isSecureContext || !navigator.storage?.getDirectory) {
    throw new Error("Persistent game saves require HTTPS (or localhost) and a browser with Origin Private File System support.");
  }
  if (!navigator.locks) throw new Error("This browser cannot safely lock the game save. Use a browser with Web Locks support.");
  let acquired!: () => void;
  let rejected!: (error: Error) => void;
  const ready = new Promise<void>((resolve, reject) => { acquired = resolve; rejected = reject; });
  const lifetime = navigator.locks.request("startup-valley-save-owner", { mode: "exclusive", ifAvailable: true }, async (lock) => {
    if (!lock) { rejected(new Error("This company is already open in another tab. Close that tab, then retry.")); return; }
    await new Promise<void>((resolve) => { releaseLock = resolve; acquired(); });
  }).then(() => {});
  lockLifetime = lifetime;
  lifetime.catch((cause) => rejected(cause instanceof Error ? cause : new Error(String(cause))));
  await ready;
}

async function start(): Promise<void> {
  if (started) throw new Error("The game worker has already started.");
  started = true;
  await ownSave();
  let sqlite: Awaited<ReturnType<typeof sqlite3InitModule>>;
  try { sqlite = await sqlite3InitModule(); }
  catch (cause) {
    console.error("SQLite runtime initialization failed", cause);
    throw new Error("The game simulation files could not be loaded. Check your connection, then reload. If this continues, try an updated browser.");
  }
  pool = await sqlite.installOpfsSAHPoolVfs({
    name: "startup-valley-opfs",
    directory: ".startup-valley",
    initialCapacity: 12,
    clearOnInit: false,
    // Without this 3.54+ option, failed initialization may clear pool storage.
    preserveOnInitFailure: true,
  });
  await pool.reserveMinimumCapacity(12);
  connection = await openDatabase(pool);
  runtime = createBrowserRuntime({
    database: connection, migrations, geometryData, schemas,
    hash: (value) => bytesToHex(sha256(new TextEncoder().encode(value))),
    resetDatabase: (current, initialize) => resetDatabase(pool!, current as WasmDatabase, initialize),
  });
  const mode = connection.prepare("PRAGMA journal_mode").get();
  if (!mode || Object.values(mode)[0] !== "wal") throw new Error("The persistent save could not enable its transaction journal.");
  send({ type: "ready", storage: "opfs-sahpool" });
}

async function stop(): Promise<void> {
  try {
    if (runtime) await runtime.close();
    else connection?.close();
  } finally {
    runtime = null;
    connection = null;
    // Pausing releases handles but preserves every database in the pool.
    await pool?.pauseVfs();
    releaseLock?.();
    releaseLock = null;
    await lockLifetime;
    send({ type: "stopped" });
    scope.close();
  }
}

scope.onmessage = ({ data }: MessageEvent<ToWorker>) => {
  queue = queue.then(async () => {
    switch (data.type) {
      case "start": await start(); break;
      case "request": {
        if (!runtime) throw new Error("The persistent game save has not opened.");
        if (typeof data.json !== "string" || new TextEncoder().encode(data.json).length > MAX_REQUEST_BYTES) throw new Error("Game request exceeds the 1 MiB limit.");
        send({ type: "message", json: JSON.stringify(await runtime.handleRequest(data.json)) });
        break;
      }
      case "stop": await stop(); break;
    }
  }).catch((cause) => {
    send({ type: "error", message: cause instanceof Error ? cause.message : String(cause) });
    // The page terminates this worker after receiving the fatal error, releasing
    // every handle. Never create a replacement or memory-only save on failure.
  });
};
