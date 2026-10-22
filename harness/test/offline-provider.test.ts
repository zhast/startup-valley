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
    brand: { employeeId: "creative", title: "Design the brand", assignment: "Create brand/identity.md and brand/palette.md" },
    apply: { employeeId: "creative", title: "Apply the brand", assignment: "Create brand/homepage.md and brand/application.md" },
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
    const milestoneStates = Object.fromEntries(database.journey.state().milestones.map((item) => [item.id, item.state]));
    assert.equal(milestoneStates.website, "completed");
    assert.equal(milestoneStates.ads, "completed");
    assert.equal(milestoneStates.incorporate, "completed");
    assert.equal(milestoneStates.brand, "locked");
    assert.equal(database.journey.state().candidates.find((candidate) => candidate.id === "creative")?.available, false);
    assert.equal(database.journey.continueChapter().candidates.find((candidate) => candidate.id === "creative")?.available, true);
    database.journey.hire("creative", 3);
    assert.equal(database.journey.state().milestones.find((item) => item.id === "brand")?.state, "available");
    assert.equal(database.journey.state().company.cashCents, 100000);
    await worker.startJob(milestoneSpec("brand"));
    await drain(worker, "brand");
    const identity = await readFile(join(root, "company-project", "jobs", "brand", "brand", "identity.md"), "utf8");
    assert.match(identity, /DeskBloom/u);
    const palette = await readFile(join(root, "company-project", "jobs", "brand", "brand", "palette.md"), "utf8");
    assert.match(palette, /#F6F1E7/u);
    const checklist = await readFile(join(root, "company-project", "jobs", "incorporate", "company", "incorporation-checklist.md"), "utf8");
    assert.match(checklist, /must not be treated as legal advice/iu);
    await worker.evaluateMilestone("brand");
    assert.equal(database.journey.evaluationFor("brand")?.verdict, "ready");
    database.journey.complete("brand", false, 3);
    assert.equal(database.journey.state().milestones.find((item) => item.id === "brand")?.state, "completed");
    assert.equal(database.journey.state().milestones.find((item) => item.id === "apply")?.state, "locked");
    assert.deepEqual(database.journey.state().company, { cashCents: 180000, earnedCents: 260000, reputation: 57, chapter: 3 });
    // A save that finished the brand before Chapter 3 still opens on Begin Chapter 3.
    database.journey.db.prepare("UPDATE company_state SET chapter = 2, opened_chapter = 2 WHERE id = 1").run();
    const resumed = database.journey.continueChapter();
    assert.equal(resumed.company.chapter, 3);
    assert.equal(resumed.company.cashCents, 180000);
    assert.equal(resumed.milestones.find((item) => item.id === "apply")?.state, "available");
    await worker.startJob(milestoneSpec("apply"));
    await drain(worker, "apply");
    const homepage = await readFile(join(root, "company-project", "jobs", "apply", "brand", "homepage.md"), "utf8");
    assert.match(homepage, /DeskBloom/u);
    const application = await readFile(join(root, "company-project", "jobs", "apply", "brand", "application.md"), "utf8");
    assert.match(application, /#F6F1E7/u);
    assert.match(application, /not a launched redesign/iu);
    await worker.evaluateMilestone("apply");
    assert.equal(database.journey.evaluationFor("apply")?.verdict, "ready");
    database.journey.complete("apply", false, 3);
    assert.equal(database.journey.state().milestones.find((item) => item.id === "apply")?.state, "completed");
    assert.deepEqual(database.journey.state().company, { cashCents: 220000, earnedCents: 300000, reputation: 65, chapter: 3 });
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
