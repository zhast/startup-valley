import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { GameDatabase } from "../src/database.js";

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
  const memories = database.writebackMemories("mina-note");
  assert.deepEqual(memories.map((memory) => memory.kind).sort(), ["artifacts", "assignment", "outcome"]);
  assert.equal(database.writebackMemories("mina-note").length, 3, "writeback is idempotent");

  const handoff = database.teammateHandoffs("theo")[0];
  assert.equal(handoff?.employeeName, "Mina");
  assert.equal(handoff?.artifactPaths[0], "jobs/mina-note/design-note.md");
  assert.match(handoff?.summary ?? "", /focus order/u);
  assert.equal(JSON.stringify(handoff).includes("transcript"), false);
  database.close();
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
