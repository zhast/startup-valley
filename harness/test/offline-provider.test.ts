import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";

import { GameDatabase } from "../src/database.js";
import { FAKE_PROVIDER_ENV, offlineProviderEnabled } from "../src/offline-provider.js";
import { PiWorkerAdapter } from "../src/pi-worker-adapter.js";
import type { JobSpec } from "../src/types.js";

const emptyCredentials = {
  async hasOpenRouterKey() { return false; },
  async getOpenRouterKey() { return undefined; },
  async setOpenRouterKey() {},
};

function adapter(database: GameDatabase, root: string) {
  return new PiWorkerAdapter(database, emptyCredentials, root, undefined, true);
}

function milestoneSpec(id: string, jobId = id): JobSpec {
  const titles: Record<string, { employeeId: string; title: string; assignment: string }> = {
    website: { employeeId: "mira", title: "Build a website", assignment: "Create site/index.html and site/styles.css" },
    ads: { employeeId: "theo", title: "Run ads", assignment: "Create ads/campaign-plan.md and ads/creative.md" },
    incorporate: { employeeId: "mira", title: "Incorporate", assignment: "Create company incorporation planning files" },
  };
  const item = titles[id]!;
  return {
    jobId,
    employeeId: item.employeeId,
    projectId: "company",
    title: item.title,
    assignment: item.assignment,
    acceptanceCriteria: ["Complete files"],
    tokenBudget: 12000,
    milestoneId: id,
  };
}

async function drain(adapter: PiWorkerAdapter, jobId: string) {
  const events = [];
  for await (const event of adapter.events(jobId)) events.push(event);
  return events;
}

test("offline provider flag is env-gated and off by default", () => {
  assert.equal(offlineProviderEnabled({}), false);
  assert.equal(offlineProviderEnabled({ [FAKE_PROVIDER_ENV]: "1" }), true);
});

test("offline fake provider completes website work, evaluation, and Theo unlock without credentials", async () => {
    const root = await mkdtemp(join(tmpdir(), "startup-valley-offline-website-"));
    const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
    database.journey.hire("mira", 1);
    const worker = adapter(database, root);
    await worker.startJob(milestoneSpec("website"));
    const events = await drain(worker, "website");
    assert.equal(events[0]?.type, "job.started");
    assert.ok(events.some((event) => event.type === "artifact.created"));
    assert.equal(events.at(-1)?.type, "job.completed");
    assert.equal(database.workOrder("website")?.status, "completed");
    const html = await worker.readArtifact("website", "site/index.html");
    assert.match(html.content, /prototype/iu);
    assert.match(html.content, /#prototype/u);
    await worker.evaluateMilestone("website");
    assert.equal(database.journey.evaluationFor("website")?.verdict, "ready");
    database.journey.complete("website", false, 1);
    const theo = database.journey.state().candidates.find((candidate) => candidate.id === "theo");
    assert.equal(theo?.available, true);
    assert.equal(database.employee("mira")?.assignment, undefined);
    database.close();
});

test("offline fake provider walks the three-day chapter without a paid model", async () => {
    const root = await mkdtemp(join(tmpdir(), "startup-valley-offline-chapter-"));
    const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
    const worker = adapter(database, root);
    database.journey.hire("mira", 1);
    await worker.startJob(milestoneSpec("website"));
    await drain(worker, "website");
    await worker.evaluateMilestone("website");
    database.journey.complete("website", false, 1);
    database.journey.hire("theo", 1);
    database.endDay(1);
    await worker.startJob(milestoneSpec("ads"));
    await drain(worker, "ads");
    await worker.evaluateMilestone("ads");
    database.journey.complete("ads", false, 2);
    database.endDay(2);
    await worker.startJob(milestoneSpec("incorporate"));
    await drain(worker, "incorporate");
    await worker.evaluateMilestone("incorporate");
    database.journey.complete("incorporate", false, 3);
    assert.deepEqual(database.journey.state().company, { cashCents: 100000, earnedCents: 180000, reputation: 45, chapter: 2 });
    assert.ok(database.journey.state().milestones.every((item) => item.state === "completed"));
    const checklist = await readFile(join(root, "company-project", "jobs", "incorporate", "company", "incorporation-checklist.md"), "utf8");
    assert.match(checklist, /must not be treated as legal advice/iu);
    database.close();
});

test("stdio credential.status reports the offline provider as configured", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-offline-stdio-"));
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", root], {
    cwd: new URL("..", import.meta.url),
    stdio: ["pipe", "pipe", "pipe"],
    env: { ...process.env, [FAKE_PROVIDER_ENV]: "1", STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS: "1" },
  });
  const lines = createInterface({ input: child.stdout });
  const pending = new Map<string, (value: { ok: boolean; result?: Record<string, unknown> }) => void>();
  lines.on("line", (line) => {
    const value = JSON.parse(line) as { id?: string; ok: boolean; result?: Record<string, unknown> };
    if (value.id) pending.get(value.id)?.(value);
  });
  const request = (id: string, method: string, params: object = {}) => new Promise<{ ok: boolean; result?: Record<string, unknown> }>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out: ${method}`)), 5000);
    pending.set(id, (value) => { clearTimeout(timer); pending.delete(id); resolve(value); });
    child.stdin.write(JSON.stringify({ kind: "request", id, method, params }) + "\n");
  });
  try {
    const health = await request("health", "health");
    assert.equal(health.ok, true);
    assert.equal(health.result?.offline, true);
    const status = await request("creds", "credential.status");
    assert.equal(status.ok, true);
    assert.equal(status.result?.configured, true);
    assert.equal(status.result?.offline, true);
  } finally {
    child.stdin.end();
    await once(child, "exit");
    lines.close();
  }
});
