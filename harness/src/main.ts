import { mkdir, mkdtemp, rename } from "node:fs/promises";
import { join, resolve } from "node:path";
import { createInterface } from "node:readline";

import { credentialStoreFromEnvironment } from "./credential-store.js";
import { GameDatabase } from "./database.js";
import { dispatchOffline, UNHANDLED } from "./offline-dispatch.js";
import { stringParameter } from "./request-parameters.js";
import { createRequestHandler } from "./request-handler.js";
import { offlineProviderEnabled } from "./offline-provider.js";
import { PiWorkerAdapter } from "./pi-worker-adapter.js";
import type { ApprovalDecision, ProtocolEvent, ProtocolRequest, ProtocolResponse } from "./types.js";
import { parseJobSpec, parseRequest } from "./validation.js";

function withOfflineCredentialStatus<T extends { configured: boolean }>(status: T): T & { offline?: boolean } {
  if (!offlineProviderEnabled()) return status;
  return { ...status, configured: true, offline: true };
}

function argument(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

function write(message: ProtocolResponse | ProtocolEvent): void {
  process.stdout.write(`${JSON.stringify(message)}\n`);
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
  const offline = await dispatchOffline(request, database, {
    isBusy: () => adapter.isBusy(),
    startNextQueuedJob: async () => {
      const jobId = await adapter.startNextQueuedJob();
      if (jobId) ensureEventPump(jobId);
      return jobId;
    },
  });
  if (offline !== UNHANDLED) return offline;
  switch (request.method) {
    case "milestone.evaluate":
      return adapter.evaluateMilestone(stringParameter(request, "jobId", 64));
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

  }
}

const lines = createInterface({ input: process.stdin, crlfDelay: Infinity, terminal: false });
const handleRequest = createRequestHandler(parseRequest, dispatch);
lines.on("line", (line) => { void handleRequest(line).then(write); });

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
