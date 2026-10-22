import { mkdir, mkdtemp, rename } from "node:fs/promises";
import { join, resolve } from "node:path";
import { createInterface } from "node:readline";

import { credentialStoreFromEnvironment } from "./credential-store.js";
import { GameDatabase } from "./database.js";
import type { FurnishingUpdate } from "./furnishing.js";
import { offlineProviderEnabled } from "./offline-provider.js";
import { PiWorkerAdapter } from "./pi-worker-adapter.js";
import type { ApprovalDecision, ProtocolEvent, ProtocolRequest, ProtocolResponse } from "./types.js";
import { parseJobSpec, parseRequest } from "./validation.js";

function withOfflineCredentialStatus<T extends { configured: boolean }>(status: T): T & { offline?: boolean } {
  if (!offlineProviderEnabled()) return status;
  return { ...status, configured: true, offline: true };
}

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

function staffParameter(request: ProtocolRequest): string[] {
  const value = request.params.staffIds;
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) throw new Error("Parameter staffIds must be an array of strings");
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
let database = new GameDatabase(join(dataRoot, "startup-valley.sqlite"), projectRoot);
const credentials = credentialStoreFromEnvironment();
let adapter = new PiWorkerAdapter(database, credentials, dataRoot);
let resetting = false;
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
  if (resetting) throw new Error("New company is being prepared");
  switch (request.method) {
    case "furnishing.update":
      return database.furnishing.update(request.params as unknown as FurnishingUpdate);
    case "hiring.complete":
      database.journey.hire(stringParameter(request, "employeeId", 64), database.clockState().day);
      return database.bootstrap();
    case "milestone.evaluate":
      return adapter.evaluateMilestone(stringParameter(request, "jobId", 64));
    case "milestone.complete":
    case "milestone.override":
      return { journey: database.journey.complete(stringParameter(request, "jobId", 64), request.method === "milestone.override", database.clockState().day), dailySpend: database.dailySpend() };
    case "chapter.continue":
      return { journey: database.journey.continueChapter(), dailySpend: database.dailySpend() };
    case "game.save":
      database.journey.savePlayer(request.params);
      return { saved: true };
    case "day.end": {
      if (adapter.isBusy()) throw new Error("Wait for active AI work to finish before ending the day");
      const result = database.endDay(numberParameter(request, "day"));
      const startedJobId = await adapter.startNextQueuedJob();
      if (startedJobId) ensureEventPump(startedJobId);
      return { ...result, journey: database.journey.state(), dailySpend: database.dailySpend() };
    }
    case "tycoon.start":
      return {
        journey: database.tycoon.start(
          stringParameter(request, "topicId", 64),
          stringParameter(request, "typeId", 64),
          staffParameter(request),
        ),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.release":
      return { journey: database.tycoon.release(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.train":
      return {
        journey: database.tycoon.train(stringParameter(request, "staffId", 32), stringParameter(request, "stat", 16)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.research":
      return {
        journey: database.tycoon.research(stringParameter(request, "kind", 16), stringParameter(request, "id", 64)),
        dailySpend: database.dailySpend(),
      };
    case "game.new": {
      if (request.params.confirmed !== true) throw new Error("Confirm New Company first");
      if (adapter.isBusy() || database.hasOpenWorkOrder()) throw new Error("Finish or cancel open work before starting a new company");
      resetting = true;
      const dbPath = join(dataRoot, "startup-valley.sqlite");
      await mkdir(join(dataRoot, "backups"), { recursive: true }).catch((error: unknown) => { resetting = false; throw error; });
      const safeBackup = await mkdtemp(join(dataRoot, "backups", new Date().toISOString().replace(/[:.]/gu, "-") + "-")).catch((error: unknown) => { resetting = false; throw error; });
      const stagedPath = join(safeBackup, "prepared.sqlite");
      let movedDb = false, movedProject = false, installedDb = false, installedProject = false, closed = false;
      let replacement: GameDatabase | undefined;
      try {
        // Validate and checkpoint the new database before touching the old company.
        const prepared = new GameDatabase(stagedPath, projectRoot);
        prepared.close();
        await mkdir(join(safeBackup, "prepared-project"));
        database.close(); closed = true;
        await rename(dbPath, join(safeBackup, "startup-valley.sqlite")); movedDb = true;
        await rename(projectRoot, join(safeBackup, "company-project")); movedProject = true;
        await rename(stagedPath, dbPath); installedDb = true;
        await rename(join(safeBackup, "prepared-project"), projectRoot); installedProject = true;
        replacement = new GameDatabase(dbPath, projectRoot);
        database = replacement;
        adapter = new PiWorkerAdapter(database, credentials, dataRoot);
        return { ...database.bootstrap(), backupPath: safeBackup };
      } catch (error) {
        replacement?.close();
        // Keep even the failed replacement recoverable; never overwrite the backup.
        if (installedProject) await rename(projectRoot, join(safeBackup, "failed-new-project"));
        if (installedDb) await rename(dbPath, join(safeBackup, "failed-new.sqlite"));
        if (movedProject) await rename(join(safeBackup, "company-project"), projectRoot);
        if (movedDb) await rename(join(safeBackup, "startup-valley.sqlite"), dbPath);
        if (closed) {
          database = new GameDatabase(dbPath, projectRoot);
          adapter = new PiWorkerAdapter(database, credentials, dataRoot);
        }
        throw error;
      } finally { resetting = false; }
    }
    case "health":
      return { status: "ok", protocolVersion: 1, workerVersion: "0.0.1", provider: await credentials.peekProvider(), maxConcurrentJobs: 1, offline: offlineProviderEnabled() || undefined };
    case "bootstrap":
      return database.bootstrap();
    case "credential.status":
      return withOfflineCredentialStatus(await credentials.status());
    case "credential.set":
      await credentials.setOpenRouterKey(stringParameter(request, "key", 512));
      return withOfflineCredentialStatus(await credentials.status());
    case "credential.grok.login.start":
      return credentials.startGrokLogin();
    case "credential.grok.login.poll":
      return credentials.pollGrokLogin();
    case "credential.grok.login.cancel":
      await credentials.cancelGrokLogin();
      return withOfflineCredentialStatus(await credentials.status());
    case "credential.grok.logout":
      await credentials.logoutGrok();
      return withOfflineCredentialStatus(await credentials.status());
    case "credential.grok.use_local":
      await credentials.useLocalGrok();
      return withOfflineCredentialStatus(await credentials.status());
    case "chat.history":
      return adapter.chatHistory(stringParameter(request, "employeeId", 64));
    case "chat.send":
      return adapter.sendChat(
        stringParameter(request, "employeeId", 64),
        stringParameter(request, "message", 2000),
      );
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
// Protocol retries share the same in-flight operation and response. Domain writes
// also have durable unique keys, so replay after a process restart stays safe.
const requests = new Map<string, { fingerprint: string; result: Promise<unknown> }>();
lines.on("line", (line) => {
  void (async () => {
    let id = "invalid";
    try {
      if (line.length > MAX_LINE_LENGTH) throw new Error("Protocol line is too large");
      const raw = JSON.parse(line) as unknown;
      if (typeof raw === "object" && raw !== null && typeof (raw as { id?: unknown }).id === "string") id = (raw as { id: string }).id;
      const request = parseRequest(raw);
      const fingerprint = JSON.stringify([request.method, request.params]);
      let entry = requests.get(request.id);
      if (entry && entry.fingerprint !== fingerprint) throw new Error("Request id was already used for a different action");
      if (!entry) {
        entry = { fingerprint, result: dispatch(request) };
        requests.set(request.id, entry);
        if (requests.size > 512) requests.delete(requests.keys().next().value!);
      }
      const result = await entry.result;
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
