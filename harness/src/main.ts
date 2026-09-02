import { mkdir } from "node:fs/promises";
import { join, resolve } from "node:path";
import { createInterface } from "node:readline";

import { KeychainCredentialStore } from "./credential-store.js";
import { GameDatabase } from "./database.js";
import { PiWorkerAdapter } from "./pi-worker-adapter.js";
import type { ApprovalDecision, ProtocolEvent, ProtocolRequest, ProtocolResponse } from "./types.js";
import { parseJobSpec, parseRequest } from "./validation.js";

const MAX_LINE_LENGTH = 1_000_000;

function argument(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

function stringParameter(request: ProtocolRequest, name: string, maxLength = 4000): string {
  const value = request.params[name];
  if (typeof value !== "string" || value.length === 0 || value.length > maxLength) throw new Error(`Parameter ${name} must be a non-empty string`);
  return value;
}

function numberParameter(request: ProtocolRequest, name: string): number {
  const value = request.params[name];
  if (typeof value !== "number" || !Number.isFinite(value)) throw new Error(`Parameter ${name} must be a finite number`);
  return value;
}

function write(message: ProtocolResponse | ProtocolEvent): void {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function success(id: string, result: unknown): void {
  write({ kind: "response", id, ok: true, result });
}

function failure(id: string, error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  write({ kind: "response", id, ok: false, error: message.slice(0, 4000) });
}

const dataRoot = resolve(argument("--data-dir") ?? join(process.cwd(), ".startup-valley-data"));
const projectRoot = join(dataRoot, "company-project");
await mkdir(projectRoot, { recursive: true });
const database = new GameDatabase(join(dataRoot, "startup-valley.sqlite"), projectRoot);
const credentials = new KeychainCredentialStore();
const adapter = new PiWorkerAdapter(database, credentials, dataRoot);
let shuttingDown = false;
const pumpingJobs = new Set<string>();

async function pumpEvents(jobId: string): Promise<void> {
  try {
    for await (const event of adapter.events(jobId)) write({ kind: "event", jobId, event });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    process.stderr.write(`Event stream failed for ${jobId}: ${message.slice(0, 1000)}\n`);
  } finally {
    pumpingJobs.delete(jobId);
  }
}

function ensureEventPump(jobId: string): void {
  if (pumpingJobs.has(jobId)) return;
  pumpingJobs.add(jobId);
  void pumpEvents(jobId);
}

async function dispatch(request: ProtocolRequest): Promise<unknown> {
  switch (request.method) {
    case "health":
      return { status: "ok", protocolVersion: 1, workerVersion: "0.0.1", provider: "openrouter", maxConcurrentJobs: 1 };
    case "bootstrap":
      return database.bootstrap();
    case "credential.status":
      return { configured: await credentials.hasOpenRouterKey() };
    case "credential.set":
      await credentials.setOpenRouterKey(stringParameter(request, "key", 512));
      return { configured: true };
    case "job.start": {
      const spec = parseJobSpec(request.params.spec);
      const result = await adapter.submitJob(spec);
      ensureEventPump(spec.jobId);
      return { jobId: spec.jobId, accepted: true, queued: result.queued };
    }
    case "job.resume": {
      const jobId = stringParameter(request, "jobId", 64);
      await adapter.resumeJob(jobId);
      ensureEventPump(jobId);
      return { jobId, accepted: true };
    }
    case "job.steer":
      await adapter.steer(stringParameter(request, "jobId", 64), stringParameter(request, "message", 2000));
      return { accepted: true };
    case "job.approve": {
      const jobId = stringParameter(request, "jobId", 64);
      const approvalId = stringParameter(request, "approvalId", 100);
      const approved = request.params.approved;
      if (typeof approved !== "boolean") throw new Error("Parameter approved must be a boolean");
      const reasonValue = request.params.reason;
      if (reasonValue !== undefined && typeof reasonValue !== "string") throw new Error("Parameter reason must be a string");
      const base: ApprovalDecision = { approvalId, approved };
      const decision = typeof reasonValue === "string" ? { ...base, reason: reasonValue.slice(0, 1000) } : base;
      await adapter.approve(jobId, decision);
      return { accepted: true };
    }
    case "job.cancel": {
      const jobId = stringParameter(request, "jobId", 64);
      await adapter.cancel(jobId);
      ensureEventPump(jobId);
      return { accepted: true };
    }
    case "job.artifacts":
      return adapter.artifacts(stringParameter(request, "jobId", 64));
    case "job.remember":
      return database.writebackMemories(stringParameter(request, "jobId", 64));
    case "job.promote": {
      const approved = request.params.approved;
      if (typeof approved !== "boolean") throw new Error("Parameter approved must be a boolean");
      return adapter.promoteArtifacts(stringParameter(request, "jobId", 64), approved);
    }
    case "artifact.read":
      return adapter.readArtifact(
        stringParameter(request, "jobId", 64),
        stringParameter(request, "relativePath", 1024),
      );
    case "studio.files":
      return adapter.studioFiles();
    case "studio.read":
      return adapter.readStudioFile(stringParameter(request, "relativePath", 1024));
    case "clock.set": {
      const clock = database.setClock(
        numberParameter(request, "day"),
        numberParameter(request, "minuteOfDay"),
        numberParameter(request, "speed"),
      );
      const startedJobId = await adapter.startNextQueuedJob();
      if (startedJobId) ensureEventPump(startedJobId);
      return { clock, startedJobId };
    }
  }
}

const lines = createInterface({ input: process.stdin, crlfDelay: Infinity, terminal: false });
lines.on("line", (line) => {
  void (async () => {
    let id = "invalid";
    try {
      if (line.length > MAX_LINE_LENGTH) throw new Error("Protocol line is too large");
      const raw = JSON.parse(line) as unknown;
      if (typeof raw === "object" && raw !== null && typeof (raw as { id?: unknown }).id === "string") id = (raw as { id: string }).id;
      const request = parseRequest(raw);
      const result = await dispatch(request);
      success(request.id, result);
    } catch (error) {
      failure(id, error);
    }
  })();
});

async function shutdown(): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;
  lines.close();
  try {
    await adapter.shutdown();
  } finally {
    database.close();
  }
}

process.once("SIGINT", () => { void shutdown().finally(() => process.exit(0)); });
process.once("SIGTERM", () => { void shutdown().finally(() => process.exit(0)); });
process.stdin.once("end", () => { void shutdown(); });
