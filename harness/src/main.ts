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

async function pumpEvents(jobId: string): Promise<void> {
  try {
    for await (const event of adapter.events(jobId)) write({ kind: "event", jobId, event });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    process.stderr.write(`Event stream failed for ${jobId}: ${message.slice(0, 1000)}\n`);
  }
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
      await adapter.startJob(spec);
      void pumpEvents(spec.jobId);
      return { jobId: spec.jobId, accepted: true };
    }
    case "job.resume": {
      const jobId = stringParameter(request, "jobId", 64);
      await adapter.resumeJob(jobId);
      void pumpEvents(jobId);
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
    case "job.cancel":
      await adapter.cancel(stringParameter(request, "jobId", 64));
      return { accepted: true };
    case "job.artifacts":
      return adapter.artifacts(stringParameter(request, "jobId", 64));
    case "job.remember":
      return database.writebackMemories(stringParameter(request, "jobId", 64));
    case "artifact.read":
      return adapter.readArtifact(
        stringParameter(request, "jobId", 64),
        stringParameter(request, "relativePath", 1024),
      );
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

function shutdown(): void {
	if (shuttingDown) return;
	shuttingDown = true;
  lines.close();
  database.close();
}

process.once("SIGINT", shutdown);
process.once("SIGTERM", shutdown);
process.stdin.once("end", shutdown);
