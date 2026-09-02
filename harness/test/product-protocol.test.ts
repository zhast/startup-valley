import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdir, mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";

import { GameDatabase } from "../src/database.js";

test("game protocol promotes approved artifacts, reads the studio, and writes memories", async () => {
  const dataRoot = await mkdtemp(join(tmpdir(), "startup-valley-product-protocol-"));
  const projectRoot = join(dataRoot, "company-project");
  const jobRoot = join(projectRoot, "jobs", "completed-note");
  await mkdir(jobRoot, { recursive: true });
  await writeFile(join(jobRoot, "note.md"), "# Note\n\nKeyboard focus stays visible.\n", "utf8");

  const database = new GameDatabase(join(dataRoot, "startup-valley.sqlite"), projectRoot);
  database.createWorkOrder({
    jobId: "completed-note",
    employeeId: "mira",
    projectId: "company",
    title: "Keyboard note",
    assignment: "Write note.md",
    acceptanceCriteria: ["note.md exists"],
    tokenBudget: 4000,
  });
  database.createArtifact("completed-note", {
    artifactId: "note-artifact",
    jobId: "completed-note",
    name: "note.md",
    relativePath: "note.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  database.completeWorkOrder("completed-note", "Documented visible keyboard focus.");
  database.close();

  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", dataRoot], {
    cwd: new URL("..", import.meta.url),
    stdio: ["pipe", "pipe", "pipe"],
  });
  const lines = createInterface({ input: child.stdout });
  const responses = new Map<string, (value: Record<string, unknown>) => void>();
  lines.on("line", (line) => {
    const message = JSON.parse(line) as { id?: string } & Record<string, unknown>;
    if (message.id) responses.get(message.id)?.(message);
  });
  const request = async (id: string, method: string, params: Record<string, unknown>): Promise<Record<string, unknown>> => {
    const response = new Promise<Record<string, unknown>>((resolve) => responses.set(id, resolve));
    child.stdin.write(`${JSON.stringify({ kind: "request", id, method, params })}\n`);
    return response;
  };

  const bootstrap = await request("bootstrap", "bootstrap", {});
  assert.equal(bootstrap.ok, true);
  assert.equal(
    ((bootstrap.result as { pendingPromotions: Array<{ jobId: string }> }).pendingPromotions[0]?.jobId),
    "completed-note",
  );
  const opened = await request("read", "artifact.read", { jobId: "completed-note", relativePath: "note.md" });
  assert.equal(opened.ok, true);
  assert.match((opened.result as { content: string }).content, /focus stays visible/u);
  const promoted = await request("promote", "job.promote", { jobId: "completed-note", approved: true });
  assert.equal(promoted.ok, true);
  const promotionResult = promoted.result as {
    studioFiles: Array<{ relativePath: string }>;
    pendingPromotions: unknown[];
  };
  assert.equal(promotionResult.studioFiles[0]?.relativePath, "note.md");
  assert.deepEqual(promotionResult.pendingPromotions, []);
  const studioOpened = await request("studio-read", "studio.read", { relativePath: "note.md" });
  assert.equal(studioOpened.ok, true);
  assert.match((studioOpened.result as { content: string }).content, /focus stays visible/u);
  const remembered = await request("remember", "job.remember", { jobId: "completed-note" });
  assert.equal(remembered.ok, true);
  assert.equal((remembered.result as unknown[]).length, 3);

  child.stdin.end();
  await new Promise<void>((resolve, reject) => {
    child.once("exit", (code) => (code === 0 ? resolve() : reject(new Error(`worker exited ${code}`))));
  });

  const verified = new GameDatabase(join(dataRoot, "startup-valley.sqlite"), projectRoot);
  assert.equal(verified.employeeMemories("mira").filter((memory) => memory.workOrderId === "completed-note").length, 3);
  assert.equal(verified.studioFiles()[0]?.relativePath, "note.md");
  verified.close();
});
