import assert from "node:assert/strict";
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { mkdir, mkdtemp, unlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";

import type { CredentialStore } from "../src/credential-store.js";
import { GameDatabase } from "../src/database.js";
import { PiWorkerAdapter } from "../src/pi-worker-adapter.js";

const stages = ["think", "read", "write", "approval", "complete", "promote"] as const;

class StaticCredentialStore implements CredentialStore {
  constructor(readonly key: string | undefined) {}
  async hasOpenRouterKey(): Promise<boolean> { return this.key !== undefined; }
  async getOpenRouterKey(): Promise<string | undefined> { return this.key; }
  async setOpenRouterKey(_key: string): Promise<void> {}
}

function jobSpec(jobId: string) {
  return {
    jobId,
    employeeId: "mira",
    projectId: "company",
    title: "Lifecycle work",
    assignment: "Write note.md",
    acceptanceCriteria: ["note.md exists"],
    tokenBudget: 4000,
  };
}

async function waitForLine(child: ChildProcessWithoutNullStreams): Promise<string> {
  const lines = createInterface({ input: child.stdout });
  return new Promise<string>((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error("Timed out waiting for lifecycle fixture")), 5000);
    lines.once("line", (line) => {
      clearTimeout(timeout);
      lines.close();
      resolve(line);
    });
    child.once("error", reject);
  });
}

async function waitForExit(child: ChildProcessWithoutNullStreams): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error("Killed worker did not exit")), 5000);
    child.once("exit", () => {
      clearTimeout(timeout);
      resolve();
    });
  });
}

for (const stage of stages) {
  test(`SIGKILL during ${stage} leaves durable recoverable state and no worker process`, async () => {
    const dataRoot = await mkdtemp(join(tmpdir(), `startup-valley-kill-${stage}-`));
    const child = spawn(process.execPath, ["test/fixtures/lifecycle-worker.mjs", dataRoot, stage], {
      cwd: new URL("..", import.meta.url),
      stdio: ["pipe", "pipe", "pipe"],
    });
    const stderr: Buffer[] = [];
    child.stderr.on("data", (chunk: Buffer) => stderr.push(chunk));
    const ready = JSON.parse(await waitForLine(child)) as { jobId: string; stage: string };
    assert.equal(ready.stage, stage);
    assert.equal(child.kill("SIGKILL"), true);
    await waitForExit(child);
    assert.throws(() => process.kill(child.pid as number, 0), /ESRCH/u, Buffer.concat(stderr).toString("utf8"));

    const projectRoot = join(dataRoot, "company-project");
    const database = new GameDatabase(join(dataRoot, "game.sqlite"), projectRoot);
    const stored = database.workOrder(ready.jobId);
    assert.equal(database.employee("mira")?.assignment, undefined, "employee must not remain busy after recovery");
    if (stage === "think" || stage === "read" || stage === "write") {
      assert.equal(stored?.status, "failed");
    } else if (stage === "approval") {
      assert.equal(stored?.status, "blocked");
    } else {
      assert.equal(stored?.status, "completed");
      assert.equal(database.pendingPromotions()[0]?.jobId, ready.jobId);
    }

    if (stage === "promote") {
      const adapter = new PiWorkerAdapter(database, new StaticCredentialStore(undefined), dataRoot);
      const result = await adapter.promoteArtifacts(ready.jobId, true);
      assert.equal(result.pendingPromotions.length, 0);
      assert.equal((await adapter.readStudioFile("deliverable.md")).content, "# Deliverable\n\nLifecycle-safe content.\n");
    }
    database.close();
  });
}

test("missing OpenRouter key blocks work and releases the employee", async () => {
  const dataRoot = await mkdtemp(join(tmpdir(), "startup-valley-missing-key-"));
  const database = new GameDatabase(join(dataRoot, "game.sqlite"), join(dataRoot, "company-project"));
  const adapter = new PiWorkerAdapter(database, new StaticCredentialStore(undefined), dataRoot);
  await adapter.startJob(jobSpec("missing-key"));
  const events = [];
  for await (const event of adapter.events("missing-key")) events.push(event);
  assert.deepEqual(events.map((event) => event.type), ["job.started", "job.blocked"]);
  assert.equal(database.workOrder("missing-key")?.status, "blocked");
  assert.equal(database.employee("mira")?.assignment, undefined);
  database.close();
});

test("bad JSONL returns a bounded error and the daemon still handles health", async () => {
  const dataRoot = await mkdtemp(join(tmpdir(), "startup-valley-bad-jsonl-"));
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", dataRoot], {
    cwd: new URL("..", import.meta.url),
    stdio: ["pipe", "pipe", "pipe"],
  });
  const lines = createInterface({ input: child.stdout });
  const received: Array<Record<string, unknown>> = [];
  const complete = Promise.withResolvers<void>();
  lines.on("line", (line) => {
    received.push(JSON.parse(line) as Record<string, unknown>);
    if (received.length === 2) complete.resolve();
  });
  child.stdin.write("{definitely-not-json}\n");
  child.stdin.write(`${JSON.stringify({ kind: "request", id: "health-after-bad-json", method: "health", params: {} })}\n`);
  await Promise.race([
    complete.promise,
    new Promise<never>((_, reject) => setTimeout(() => reject(new Error("Timed out waiting for protocol responses")), 5000)),
  ]);
  const invalid = received.find((message) => message.id === "invalid");
  const health = received.find((message) => message.id === "health-after-bad-json");
  assert.equal(invalid?.ok, false);
  assert.match(String(invalid?.error), /JSON|position|property/iu);
  assert.equal(health?.ok, true);
  child.stdin.end();
  await waitForExit(child);
  assert.throws(() => process.kill(child.pid as number, 0), /ESRCH/u);
});

test("a queued attachment that vanishes fails before model startup and releases the employee", async () => {
  const dataRoot = await mkdtemp(join(tmpdir(), "startup-valley-vanished-attachment-"));
  const projectRoot = join(dataRoot, "company-project");
  const studioRoot = join(projectRoot, "studio");
  await mkdir(studioRoot, { recursive: true });
  const attachmentPath = join(studioRoot, "brief.md");
  await writeFile(attachmentPath, "# Brief\n\nDurable reference.\n", "utf8");
  const database = new GameDatabase(join(dataRoot, "game.sqlite"), projectRoot);
  database.createWorkOrder({ ...jobSpec("source"), title: "Source brief" });
  database.createArtifact("source", {
    artifactId: "source-artifact",
    jobId: "source",
    name: "brief.md",
    relativePath: "brief.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  database.completeWorkOrder("source", "Created the source brief.");
  database.upsertStudioFile({
    name: "brief.md",
    relativePath: "brief.md",
    mediaType: "text/markdown",
    sourceJobId: "source",
    sourceArtifactId: "source-artifact",
    promotedAt: new Date().toISOString(),
  });
  database.decidePromotion("source", true);
  database.setClock(1, 18 * 60, 1);
  const adapter = new PiWorkerAdapter(database, new StaticCredentialStore("fake-key-never-used"), dataRoot);
  await adapter.submitJob({ ...jobSpec("vanished"), attachedStudioPath: "brief.md" });
  const iterator = adapter.events("vanished")[Symbol.asyncIterator]();
  assert.equal((await iterator.next()).value?.type, "job.queued");
  await unlink(attachmentPath);
  database.setClock(2, 8 * 60, 1);
  assert.equal(await adapter.startNextQueuedJob(), "vanished");
  assert.equal((await iterator.next()).value?.type, "job.started");
  const failed = (await iterator.next()).value;
  assert.equal(failed?.type, "job.failed");
  if (failed?.type === "job.failed") assert.match(failed.error, /studio file is not readable|path does not exist|ENOENT/iu);
  assert.equal((await iterator.next()).done, true);
  assert.equal(database.workOrder("vanished")?.status, "failed");
  assert.equal(database.employee("mira")?.assignment, undefined);
  database.close();
});

test("double-click assignment accepts exactly one queued work order", async () => {
  const dataRoot = await mkdtemp(join(tmpdir(), "startup-valley-double-click-"));
  const database = new GameDatabase(join(dataRoot, "game.sqlite"), join(dataRoot, "company-project"));
  database.setClock(1, 18 * 60, 1);
  const adapter = new PiWorkerAdapter(database, new StaticCredentialStore(undefined), dataRoot);
  const results = await Promise.allSettled([
    adapter.submitJob(jobSpec("double-click-a")),
    adapter.submitJob(jobSpec("double-click-b")),
  ]);
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  assert.equal(results.filter((result) => result.status === "rejected").length, 1);
  assert.equal(database.recentWorkOrders().filter((order) => order.status === "queued").length, 1);
  assert.notEqual(database.employee("mira")?.assignment, undefined);
  database.close();
});
