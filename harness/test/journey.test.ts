import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, mkdir, writeFile, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { createInterface } from "node:readline";
import test from "node:test";
import { Ajv2020 } from "ajv/dist/2020.js";
import { GameDatabase } from "../src/database.js";
import { milestone, parseEvaluation } from "../src/journey.js";
import { PiWorkerAdapter } from "../src/pi-worker-adapter.js";
import type { JobSpec } from "../src/types.js";

const credentials = { async hasOpenRouterKey() { return false; }, async getOpenRouterKey() { return undefined; }, async setOpenRouterKey() {} };
const review = (id: string, score = 3) => JSON.stringify({ criteria: milestone(id).criteria.map((name) => ({ name, score, evidence: "Specific artifact evidence." })), summary: "Useful deliverable.", revisionBrief: "Clarify the offer and complete all required files." });
async function setup(filename = "game.sqlite") {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-journey-"));
  const project = join(root, "company-project");
  await mkdir(project);
  const db = new GameDatabase(join(root, filename), project);
  return { root, project, db };
}
async function deliver(db: GameDatabase, root: string, id: string, jobId = id, revisionOfJobId?: string) {
  const def = milestone(id);
  const spec: JobSpec = { jobId, employeeId: def.employeeId, projectId: "company", title: def.title, assignment: def.assignment, acceptanceCriteria: def.criteria, tokenBudget: 12000, milestoneId: id, ...(revisionOfJobId ? { revisionOfJobId } : {}) };
  db.journey.validateAssignment(spec);
  db.createWorkOrder(spec);
  for (const [index, relativePath] of def.files.entries()) {
    const path = join(root, "company-project", "jobs", jobId, relativePath);
    await mkdir(join(path, ".."), { recursive: true });
    await writeFile(path, "A real deterministic local deliverable.");
    db.createArtifact(jobId, { artifactId: `${jobId}-${index}`, jobId, name: relativePath, relativePath, mediaType: "text/plain", createdAt: new Date().toISOString() });
  }
  db.completeWorkOrder(jobId, "Ready for review.");
  return spec;
}

test("new company is founder-only; hiring is gated and idempotent", async () => {
  const { db } = await setup();
  const schema = JSON.parse(await readFile(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true }).compile(schema);
  assert.equal(validate(db.bootstrap().journey), true, JSON.stringify(validate.errors));
  assert.deepEqual(db.bootstrap().employees, []);
  assert.throws(() => db.journey.hire("theo", 1), /not available/u);
  db.journey.hire("mira", 1); db.journey.hire("mira", 1);
  assert.deepEqual(db.bootstrap().employees.map((e) => e.id), ["mira"]);
  assert.equal(db.journey.db.prepare("SELECT COUNT(*) n FROM company_transactions").get()!.n, 1);
  db.close();
});

test("queued work crosses days; active work blocks End Day and crash recovery releases approvals", async () => {
  const { db, root, project } = await setup();
  db.journey.hire("mira", 1);
  db.createWorkOrder({ jobId: "overnight", employeeId: "mira", projectId: "company", title: "Queued note", assignment: "Write a note", acceptanceCriteria: ["note"], tokenBudget: 4000 }, "queued");
  db.setClock(1, 1050, 1);
  assert.equal(db.endDay(1).clock.day, 2);
  assert.equal(db.workOrder("overnight")?.status, "queued");
  db.setWorkOrderStatus("overnight", "running");
  db.createApproval("overnight", "pending", "Review a choice");
  assert.throws(() => db.endDay(2), /Finish or cancel/u);
  db.close();
  const recovered = new GameDatabase(join(root, "game.sqlite"), project);
  assert.equal(recovered.workOrder("overnight")?.status, "failed");
  assert.equal(recovered.journey.db.prepare("SELECT status FROM approvals WHERE id='pending'").get()!.status, "denied");
  assert.equal(recovered.endDay(2).clock.day, 3);
  recovered.close();
});

test("shutdown waits for bounded chat cleanup before the database can close", async () => {
  const { db, root } = await setup();
  db.journey.hire("mira", 1);
  let release!: (value: string | undefined) => void;
  const delayed = { ...credentials, getOpenRouterKey: () => new Promise<string | undefined>((resolve) => { release = resolve; }) };
  const adapter = new PiWorkerAdapter(db, delayed, root);
  const chat = adapter.sendChat("mira", "An internal test");
  const stopped = adapter.shutdown();
  release(undefined);
  await assert.rejects(chat, /shutting down/u);
  await stopped;
  assert.equal(adapter.isBusy(), false);
  db.close();
});

test("full three-day journey awards money once, charges hiring/filing, and survives restart", async () => {
  const { db, root, project } = await setup("startup-valley.sqlite");
  const initialRoom = db.bootstrap().furnishing;
  db.furnishing.update({ operationId: "journey-plant", expectedRevision: initialRoom.revision, placements: {
    ...initialRoom.placements, "decor-broadleaf_planter": { grid: [22, 16], facing: "west" },
  } });
  let calls = 0;
  const adapter = new PiWorkerAdapter(db, credentials, root, async (def) => { calls++; return { text: review(def.id), inputTokens: 600, outputTokens: 300, cost: 0.002 }; });
  db.journey.hire("mira", 1);
  await deliver(db, root, "website");
  await Promise.all([adapter.evaluateMilestone("website"), assert.rejects(adapter.evaluateMilestone("website"), /Finish active/u)]);
  await adapter.evaluateMilestone("website");
  assert.equal(calls, 1);
  db.journey.complete("website", false, 1); db.journey.complete("website", false, 1);
  db.journey.hire("theo", 1); db.journey.hire("theo", 1);
  const hiredRoom = db.bootstrap().furnishing;
  assert.deepEqual(hiredRoom.placements["decor-broadleaf_planter"], { grid: [22, 16], facing: "west" });
  assert.deepEqual(hiredRoom.inventory.filter((item) => item.roleKit).map((item) => item.roleKit).sort(), ["mina_discovery_kit", "theo_campaign_kit"]);
  assert.equal(db.journey.state().company.cashCents, 30000);
  db.endDay(1); assert.equal(db.endDay(1).clock.day, 2);
  await deliver(db, root, "ads"); await adapter.evaluateMilestone("ads"); db.journey.complete("ads", false, 2);
  db.endDay(2);
  await deliver(db, root, "incorporate"); await adapter.evaluateMilestone("incorporate"); db.journey.complete("incorporate", false, 3);
  db.journey.savePlayer({ x: 420, y: 550, movementSeen: true, effectsVolume: 0.2, ambienceVolume: 0 });
  assert.deepEqual(db.journey.state().company, { cashCents: 100000, earnedCents: 180000, reputation: 45, chapter: 2 });
  assert.equal(db.dailySpend(), 0.002);
  assert.equal(db.endDay(1).summary.aiSpend, 0.002);
  assert.equal(db.endDay(2).summary.aiSpend, 0.002);
  db.close();
  const restored = new GameDatabase(join(root, "startup-valley.sqlite"), project);
  assert.equal(restored.journey.state().company.chapter, 2);
  assert.equal(restored.journey.state().player.x, 420);
  assert.equal(restored.clockState().day, 3);
  assert.deepEqual(restored.bootstrap().furnishing, hiredRoom, "full chapter and restart preserve the player room and grants");
  restored.journey.complete("incorporate", false, 3);
  assert.equal(restored.journey.state().company.cashCents, 100000);
  restored.close();
  // The chapter uses deterministic local deliverables and injected evaluation,
  // not a paid provider replay. Now load that exact database through production
  // stdio, replay completion/day messages, and restart the actual worker again.
  for (let pass = 0; pass < 2; pass++) {
    const child = spawn(process.execPath, ["dist/main.js", "--data-dir", root], { cwd: new URL("..", import.meta.url), stdio: ["pipe", "pipe", "pipe"] });
    const lines = createInterface({ input: child.stdout });
    const pending = new Map<string, (value: any) => void>();
    let stderr = ""; child.stderr.on("data", (value) => { stderr += String(value); });
    lines.on("line", (line) => { const value = JSON.parse(line); pending.get(value.id)?.(value); });
    const request = (id: string, method: string, params = {}) => new Promise<any>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error(`Chapter protocol ${method}: ${stderr}`)), 5000);
      pending.set(id, (value) => { clearTimeout(timer); pending.delete(id); resolve(value); });
      child.stdin.write(JSON.stringify({ kind: "request", id, method, params }) + "\n");
    });
    try {
      const bootstrap = await request("boot", "bootstrap"); assert.equal(bootstrap.ok, true);
      assert.deepEqual(bootstrap.result.furnishing, hiredRoom);
      assert.equal(bootstrap.result.clock.day, pass === 0 ? 3 : 4);
      assert.equal(bootstrap.result.journey.company.chapter, 2);
      assert.ok(bootstrap.result.journey.milestones.every((item: any) => item.state === "completed"));
      const repeated = await request("complete-again", "milestone.complete", { jobId: "incorporate" });
      assert.equal(repeated.ok, true); assert.equal(repeated.result.journey.company.cashCents, 100000);
      assert.equal((await request("end-three", "day.end", { day: 3 })).result.clock.day, 4);
      assert.equal((await request("repeat-end-three", "day.end", { day: 3 })).result.clock.day, 4);
      assert.deepEqual((await request("after-duplicates", "bootstrap")).result.furnishing, hiredRoom);
    } finally {
      const stopped = once(child, "exit"); child.stdin.end(); await stopped; lines.close();
    }
  }
});

test("evaluation failure is retryable; revisions and reduced-reward override cannot deadlock", async () => {
  const { db, root } = await setup(); db.journey.hire("mira", 1);
  const initialRoom = db.bootstrap().furnishing;
  const revisionRoom = db.furnishing.update({ operationId: "revision-room", expectedRevision: initialRoom.revision, placements: {
    ...initialRoom.placements, "decor-broadleaf_planter": { grid: [22, 16], facing: "north" },
  } }).furnishing;
  await deliver(db, root, "website", "first");
  let output = "invalid JSON";
  const adapter = new PiWorkerAdapter(db, credentials, root, async () => ({ text: output, inputTokens: 100, outputTokens: 80, cost: 0.001 }));
  await assert.rejects(adapter.evaluateMilestone("first"));
  assert.equal(db.journey.state().company.cashCents, 0);
  assert.equal(db.workOrder("first")?.status, "completed");
  assert.deepEqual(db.bootstrap().furnishing, revisionRoom);
  output = review("website", 1); await adapter.evaluateMilestone("first");
  assert.throws(() => db.journey.complete("first", false, 1), /Evaluate/u);
  const revision = await deliver(db, root, "website", "revision", "first");
  assert.equal(db.workOrder("revision")?.revisionOfJobId, "first");
  assert.throws(() => db.journey.complete("first", true, 1), /current result/u);
  await adapter.evaluateMilestone(revision.jobId);
  db.journey.complete("revision", true, 1);
  assert.equal(db.journey.state().company.cashCents, 30000);
  assert.equal(db.journey.state().company.reputation, 0);
  assert.deepEqual(db.bootstrap().furnishing, revisionRoom, "revision and reduced reward do not rewrite the player room");
  db.journey.hire("theo", 1);
  assert.equal(db.journey.state().company.cashCents, 0);
  assert.deepEqual(db.bootstrap().furnishing.placements["decor-broadleaf_planter"], revisionRoom.placements["decor-broadleaf_planter"]);
  db.close();
});

test("rubric validation and missing required files fail closed without rewards", async () => {
  assert.throws(() => parseEvaluation('{"criteria":[]}', milestone("website")), /incomplete/u);
  assert.throws(() => parseEvaluation(review("website", 5), milestone("website")), /invalid/u);
  const { db, root } = await setup(); db.journey.hire("mira", 1);
  const spec = { jobId: "empty", employeeId: "mira", projectId: "company", title: "Website", assignment: "Create files", acceptanceCriteria: ["files"], tokenBudget: 4000, milestoneId: "website" };
  db.createWorkOrder(spec); db.completeWorkOrder("empty", "No files");
  const adapter = new PiWorkerAdapter(db, credentials, root, async () => { throw new Error("Must not evaluate missing files"); });
  await assert.rejects(adapter.evaluateMilestone("empty"), /Artifact does not exist/u);
  assert.equal(db.journey.state().company.earnedCents, 0); db.close();
});

test("migration preserves pre-journey employees as hired", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-legacy-"));
  const path = join(root, "game.sqlite");
  const old = new DatabaseSync(path);
  for (const name of ["001_initial.sql", "002_product_layer.sql", "003_persistent_studio.sql", "004_work_order_handoff.sql", "005_employee_chat.sql"]) old.exec(await readFile(new URL(`../migrations/${name}`, import.meta.url), "utf8"));
  old.exec("CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)");
  for (const version of [2,3,4,5]) old.prepare("INSERT INTO schema_migrations VALUES (?, 'before')").run(version);
  old.prepare("INSERT INTO employees VALUES ('mira','Mina',8,5,'{}','{}',80,NULL,'before','before')").run();
  old.close();
  const db = new GameDatabase(path, join(root, "company-project"));
  assert.equal(db.bootstrap().employees[0]?.id, "mira");
  assert.equal(db.journey.hired("theo"), false);
  db.close();
});
