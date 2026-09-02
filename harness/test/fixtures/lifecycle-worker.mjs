import { copyFile, mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";

import { GameDatabase } from "../../dist/database.js";

const dataRoot = process.argv[2];
const stage = process.argv[3];
if (!dataRoot || !stage) throw new Error("Expected data root and lifecycle stage arguments");

const supportedStages = new Set(["think", "read", "write", "approval", "complete", "promote"]);
if (!supportedStages.has(stage)) throw new Error(`Unsupported lifecycle stage: ${stage}`);

const projectRoot = join(dataRoot, "company-project");
const jobId = `kill-${stage}`;
const jobRoot = join(projectRoot, "jobs", jobId);
const database = new GameDatabase(join(dataRoot, "game.sqlite"), projectRoot);

database.createWorkOrder({
  jobId,
  employeeId: "mira",
  projectId: "company",
  title: `Lifecycle ${stage}`,
  assignment: `Remain recoverable if killed during ${stage}`,
  acceptanceCriteria: ["employee is not stuck busy"],
  tokenBudget: 4000,
});
database.recordEvent(jobId, { type: "job.started" });

if (stage === "think") {
  database.recordEvent(jobId, { type: "agent.thinking", summary: "Planning the work order." });
}

if (stage === "read") {
  database.recordEvent(jobId, { type: "tool.started", tool: "read_file", label: "Read File" });
}

if (stage === "write") {
  await mkdir(jobRoot, { recursive: true });
  database.recordEvent(jobId, { type: "tool.started", tool: "write_file", label: "Write File" });
  await writeFile(join(jobRoot, "partial.md"), "# Partial\n\nThe worker stopped during this write-stage fixture.\n", "utf8");
}

if (stage === "approval") {
  database.createApproval(jobId, "approval-under-test", "Publish the draft");
  database.setWorkOrderStatus(jobId, "blocked");
  database.recordEvent(jobId, {
    type: "approval.required",
    approvalId: "approval-under-test",
    action: "Publish the draft",
  });
}

if (stage === "complete" || stage === "promote") {
  await mkdir(jobRoot, { recursive: true });
  await writeFile(join(jobRoot, "deliverable.md"), "# Deliverable\n\nLifecycle-safe content.\n", "utf8");
  database.createArtifact(jobId, {
    artifactId: `artifact-${stage}`,
    jobId,
    name: "deliverable.md",
    relativePath: "deliverable.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  database.completeWorkOrder(jobId, "Completed before the worker stopped.");
  database.recordEvent(jobId, { type: "job.completed", summary: "Completed before the worker stopped." });
}

if (stage === "promote") {
  const studioRoot = join(projectRoot, "studio");
  await mkdir(studioRoot, { recursive: true });
  await copyFile(join(jobRoot, "deliverable.md"), join(studioRoot, "deliverable.md"));
  database.upsertStudioFile({
    name: "deliverable.md",
    relativePath: "deliverable.md",
    mediaType: "text/markdown",
    sourceJobId: jobId,
    sourceArtifactId: "artifact-promote",
    promotedAt: new Date().toISOString(),
  });
  // Deliberately leave promotion_status pending, as if the process stopped
  // between durable copy/upsert and the final approval-state transition.
}

process.stdout.write(`${JSON.stringify({ ready: true, jobId, stage })}\n`);
process.stdin.resume();

