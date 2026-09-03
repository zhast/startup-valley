import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";

import { LegacyDatabase as GameDatabase } from "./legacy-database.js";

test("SQLite is authoritative for employees, work orders, events, and artifacts", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-db-"));
  const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  assert.deepEqual(database.bootstrap().employees.map((employee) => employee.id), ["mira", "theo"]);
  database.createWorkOrder({
    jobId: "job-1",
    employeeId: "mira",
    projectId: "company",
    title: "Write a note",
    assignment: "Write a note",
    acceptanceCriteria: ["note.md exists"],
    tokenBudget: 4000,
  });
  database.recordEvent("job-1", { type: "job.started" });
  database.recordUsage("job-1", 100, 50, 0.001);
  database.createArtifact("job-1", {
    artifactId: "artifact-1",
    jobId: "job-1",
    name: "note.md",
    relativePath: "note.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  assert.equal(database.workOrder("job-1")?.status, "running");
  assert.equal(database.artifacts("job-1")[0]?.name, "note.md");
  database.completeWorkOrder("job-1", "Mina delivered a short note.");
  assert.equal(database.employee("mira")?.assignment, undefined);
  database.close();
});

test("employee chat persists in order and contributes to daily spend", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-chat-"));
  const path = join(root, "game.sqlite");
  const projectRoot = join(root, "company-project");
  const first = new GameDatabase(path, projectRoot);
  first.createChatMessage("mira", "player", "What should we build first?");
  first.createChatMessage("mira", "employee", "Start with a small onboarding experiment.", {
    inputTokens: 120,
    outputTokens: 24,
    cost: 0.0025,
  });
  assert.deepEqual(first.chatMessages("mira").map((message) => message.sender), ["player", "employee"]);
  assert.equal(first.dailySpend(), 0.0025);
  first.close();

  const reopened = new GameDatabase(path, projectRoot);
  assert.match(reopened.chatMessages("mira")[1]?.content ?? "", /onboarding experiment/u);
  assert.deepEqual(reopened.chatMessages("theo"), []);
  reopened.close();
});

test("completed work orders write structured memories and teammate handoffs without transcripts", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-memory-"));
  const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  database.createWorkOrder({
    jobId: "mina-note",
    employeeId: "mira",
    projectId: "company",
    title: "Inventory keyboard navigation design note",
    assignment: "Write design-note.md",
    acceptanceCriteria: ["design-note.md exists"],
    tokenBudget: 4000,
  });
  database.createArtifact("mina-note", {
    artifactId: "artifact-note",
    jobId: "mina-note",
    name: "design-note.md",
    relativePath: "design-note.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  database.completeWorkOrder("mina-note", "Outlined focus order, arrow navigation, and escape behavior.");
  database.upsertStudioFile({
    name: "design-note.md",
    relativePath: "design-note.md",
    mediaType: "text/markdown",
    sourceJobId: "mina-note",
    sourceArtifactId: "artifact-note",
    promotedAt: new Date().toISOString(),
  });
  const memories = database.writebackMemories("mina-note");
  assert.deepEqual(memories.map((memory) => memory.kind).sort(), ["artifacts", "assignment", "outcome"]);
  assert.equal(database.writebackMemories("mina-note").length, 3, "writeback is idempotent");

  const handoff = database.teammateHandoffs("theo")[0];
  assert.equal(handoff?.employeeName, "Mina");
  assert.equal(handoff?.artifactPaths[0], "studio/design-note.md");
  assert.match(handoff?.summary ?? "", /focus order/u);
  assert.equal(JSON.stringify(handoff).includes("transcript"), false);
  database.close();
});

test("clock, queued work, studio listing, and recent status survive reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-persistence-"));
  const path = join(root, "game.sqlite");
  const projectRoot = join(root, "company-project");
  const first = new GameDatabase(path, projectRoot);
  first.setClock(3, 18 * 60, 4);
  first.createWorkOrder({
    jobId: "queued-night",
    employeeId: "theo",
    projectId: "company",
    title: "Morning review",
    assignment: "Review the studio note",
    acceptanceCriteria: ["review.md exists"],
    tokenBudget: 4000,
  }, "queued");
  first.close();

  const raw = new DatabaseSync(path);
  raw.prepare("UPDATE employees SET schedule_json = ? WHERE id = 'mira'").run(JSON.stringify({ weekday: "07:30-16:00" }));
  raw.close();

  const reopened = new GameDatabase(path, projectRoot);
  assert.deepEqual(reopened.clockState(), { day: 3, minuteOfDay: 18 * 60, speed: 4, phase: "off" });
  assert.equal(reopened.nextQueuedWorkOrder()?.jobId, "queued-night");
  assert.equal(reopened.bootstrap().recentJobs[0]?.status, "queued");
  assert.deepEqual(reopened.employee("mira")?.schedule, { weekday: "07:30-16:00" });
  reopened.close();
});

test("opening a database recovers running work orders as failed", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-recovery-"));
  const path = join(root, "game.sqlite");
  const projectRoot = join(root, "company-project");
  const first = new GameDatabase(path, projectRoot);
  first.createWorkOrder({
    jobId: "interrupted",
    employeeId: "mira",
    projectId: "company",
    title: "Interrupted job",
    assignment: "Wait forever",
    acceptanceCriteria: ["Never reached"],
    tokenBudget: 4000,
  });
  first.close();

  const reopened = new GameDatabase(path, projectRoot);
  assert.equal(reopened.workOrder("interrupted")?.status, "failed");
  assert.equal(reopened.employee("mira")?.assignment, undefined);
  reopened.close();
});

test("completed unpromoted artifacts survive reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-promotion-resume-"));
  const path = join(root, "game.sqlite");
  const projectRoot = join(root, "company-project");
  const first = new GameDatabase(path, projectRoot);
  first.createWorkOrder({
    jobId: "pending-note",
    employeeId: "mira",
    projectId: "company",
    title: "Pending design note",
    assignment: "Write pending-note.md",
    acceptanceCriteria: ["pending-note.md exists"],
    tokenBudget: 4000,
  });
  first.createArtifact("pending-note", {
    artifactId: "pending-artifact",
    jobId: "pending-note",
    name: "pending-note.md",
    relativePath: "pending-note.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  first.completeWorkOrder("pending-note", "Finished and awaiting the player.");
  assert.equal(first.pendingPromotions()[0]?.jobId, "pending-note");
  first.close();

  const reopened = new GameDatabase(path, projectRoot);
  assert.equal(reopened.bootstrap().pendingPromotions[0]?.artifacts[0]?.relativePath, "pending-note.md");
  reopened.close();
});

test("discard clears a pending promotion across reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-promotion-discard-"));
  const path = join(root, "game.sqlite");
  const projectRoot = join(root, "company-project");
  const first = new GameDatabase(path, projectRoot);
  first.createWorkOrder({
    jobId: "discarded-note",
    employeeId: "mira",
    projectId: "company",
    title: "Discarded design note",
    assignment: "Write discarded-note.md",
    acceptanceCriteria: ["discarded-note.md exists"],
    tokenBudget: 4000,
  });
  first.createArtifact("discarded-note", {
    artifactId: "discarded-artifact",
    jobId: "discarded-note",
    name: "discarded-note.md",
    relativePath: "discarded-note.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  first.completeWorkOrder("discarded-note", "Finished and awaiting the player.");
  first.decidePromotion("discarded-note", false);
  assert.deepEqual(first.pendingPromotions(), []);
  first.close();

  const afterDiscard = new GameDatabase(path, projectRoot);
  assert.deepEqual(afterDiscard.bootstrap().pendingPromotions, []);
  afterDiscard.close();
});

test("freeform work-order instructions and attached studio path persist in SQLite", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-freeform-persistence-"));
  const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  database.createWorkOrder({
    jobId: "freeform-brief",
    employeeId: "theo",
    projectId: "company",
    title: "Critique the onboarding plan",
    assignment: "Read the attached plan and write an actionable critique into onboarding-review.md.",
    acceptanceCriteria: ["Create at least one artifact that fulfills the instruction"],
    tokenBudget: 6000,
    attachedStudioPath: "plans/onboarding.md",
  }, "queued");
  const restored = database.workOrder("freeform-brief");
  assert.equal(restored?.title, "Critique the onboarding plan");
  assert.equal(restored?.assignment, "Read the attached plan and write an actionable critique into onboarding-review.md.");
  assert.equal(restored?.attachedStudioPath, "plans/onboarding.md");
  database.close();
});
