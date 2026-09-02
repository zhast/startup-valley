import assert from "node:assert/strict";
import { mkdir, mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import type { CredentialStore } from "../src/credential-store.js";
import { GameDatabase } from "../src/database.js";
import { PiWorkerAdapter } from "../src/pi-worker-adapter.js";

class DeferredCredentialStore implements CredentialStore {
  readonly key = Promise.withResolvers<string | undefined>();
  async hasOpenRouterKey(): Promise<boolean> { return false; }
  async getOpenRouterKey(): Promise<string | undefined> { return this.key.promise; }
  async setOpenRouterKey(_key: string): Promise<void> {}
}

function spec(jobId: string) {
  return {
    jobId,
    employeeId: "mira",
    projectId: "company",
    title: "Bounded note",
    assignment: "Write note.md",
    acceptanceCriteria: ["note.md exists"],
    tokenBudget: 4000,
  };
}

test("adapter refuses a second concurrent work order", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-concurrency-"));
  const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  const credentials = new DeferredCredentialStore();
  const adapter = new PiWorkerAdapter(database, credentials, root);
  await adapter.startJob(spec("first"));
  await assert.rejects(adapter.startJob(spec("second")), /one work order/iu);
  await adapter.cancel("first");
  credentials.key.resolve(undefined);
  for await (const _event of adapter.events("first")) {}
  assert.equal(database.workOrder("second"), undefined);
  database.close();
});

test("next employee prompts contain structured memory and SQLite teammate handoff context", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-context-"));
  const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  database.createWorkOrder({ ...spec("mina-note"), title: "Inventory keyboard navigation", assignment: "Write design-note.md" });
  database.createArtifact("mina-note", {
    artifactId: "a1",
    jobId: "mina-note",
    name: "design-note.md",
    relativePath: "design-note.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  database.completeWorkOrder("mina-note", "Specified tab order and arrow-key behavior.");
  database.writebackMemories("mina-note");
  const adapter = new PiWorkerAdapter(database, new DeferredCredentialStore(), root);

  const minaContext = adapter.systemPromptFor({ ...spec("mina-next"), title: "Follow-up" });
  assert.match(minaContext, /Persistent memories[\s\S]*Inventory keyboard navigation/u);
  const noteDirectory = join(root, "company-project", "jobs", "mina-note");
  await mkdir(noteDirectory, { recursive: true });
  await writeFile(join(noteDirectory, "design-note.md"), "# Keyboard navigation\n\nUse visible focus.", "utf8");
  await adapter.promoteArtifacts("mina-note", true);
  const theoContext = adapter.systemPromptFor({ ...spec("theo-review"), employeeId: "theo", title: "Review Mina's note" });
  assert.match(theoContext, /Mina: Inventory keyboard navigation/u);
  assert.match(theoContext, /studio\/design-note\.md/u);
  assert.match(theoContext, /Specified tab order/u);
  assert.doesNotMatch(theoContext, /shared transcript content/u);

  const opened = await adapter.readArtifact("mina-note", "design-note.md");
  assert.match(opened.content, /visible focus/u);
  const studioOpened = await adapter.readStudioFile("design-note.md");
  assert.match(studioOpened.content, /visible focus/u);
  database.close();
  const reopened = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  const restored = new PiWorkerAdapter(reopened, new DeferredCredentialStore(), root);
  assert.equal((await restored.studioFiles())[0]?.relativePath, "design-note.md");
  assert.match((await restored.readStudioFile("design-note.md")).content, /visible focus/u);
  const restoredTheoContext = restored.systemPromptFor({
    ...spec("theo-after-restart"),
    employeeId: "theo",
    title: "Review Mina's restored note",
  });
  assert.match(restoredTheoContext, /studio\/design-note\.md/u);
  assert.match(restoredTheoContext, /Mina: Inventory keyboard navigation/u);
  reopened.close();
});

test("off-hours freeform work queues with its bounded attached studio context", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-freeform-queue-"));
  const projectRoot = join(root, "company-project");
  const studioRoot = join(projectRoot, "studio");
  await mkdir(studioRoot, { recursive: true });
  await writeFile(join(studioRoot, "brief.md"), "# Product brief\n\nKeep setup under five minutes.", "utf8");
  const database = new GameDatabase(join(root, "game.sqlite"), projectRoot);
  database.createWorkOrder({ ...spec("source-job"), title: "Product brief", assignment: "Write brief.md" });
  database.createArtifact("source-job", {
    artifactId: "source-artifact",
    jobId: "source-job",
    name: "brief.md",
    relativePath: "brief.md",
    mediaType: "text/markdown",
    createdAt: new Date().toISOString(),
  });
  database.completeWorkOrder("source-job", "Created the product brief.");
  database.upsertStudioFile({
    name: "brief.md",
    relativePath: "brief.md",
    mediaType: "text/markdown",
    sourceJobId: "source-job",
    sourceArtifactId: "source-artifact",
    promotedAt: new Date().toISOString(),
  });
  database.decidePromotion("source-job", true);
  database.setClock(1, 18 * 60, 1);
  const adapter = new PiWorkerAdapter(database, new DeferredCredentialStore(), root);
  const freeform = {
    ...spec("freeform-night"),
    employeeId: "theo",
    title: "Review the product brief",
    assignment: "Use the attached brief and write recommendations.md.",
    attachedStudioPath: "brief.md",
  };
  assert.deepEqual(await adapter.submitJob(freeform), { queued: true });
  assert.equal(database.workOrder("freeform-night")?.assignment, freeform.assignment);
  assert.equal(database.workOrder("freeform-night")?.attachedStudioPath, "brief.md");
  const prompt = adapter.systemPromptFor(freeform, "# Product brief\n\nKeep setup under five minutes.");
  assert.match(prompt, /Path: studio\/brief\.md/u);
  assert.match(prompt, /Keep setup under five minutes/u);
  database.close();
});

test("an attached missing studio path fails closed before a work order is stored", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-missing-attachment-"));
  const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  database.setClock(1, 18 * 60, 1);
  const adapter = new PiWorkerAdapter(database, new DeferredCredentialStore(), root);
  await assert.rejects(
    adapter.submitJob({ ...spec("missing-attachment"), attachedStudioPath: "missing.md" }),
    /Attached studio file is unavailable/u,
  );
  assert.equal(database.workOrder("missing-attachment"), undefined);
  database.close();
});

test("off-hours work queues, starts at the work window, and shutdown blocks fake in-flight work", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-schedule-"));
  const database = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  database.setClock(1, 18 * 60, 1);
  const credentials = new DeferredCredentialStore();
  const adapter = new PiWorkerAdapter(database, credentials, root);
  assert.deepEqual(await adapter.submitJob(spec("morning-job")), { queued: true });
  const iterator = adapter.events("morning-job")[Symbol.asyncIterator]();
  assert.equal((await iterator.next()).value?.type, "job.queued");
  assert.equal(database.workOrder("morning-job")?.status, "queued");

  database.setClock(2, 8 * 60, 1);
  assert.equal(await adapter.startNextQueuedJob(), "morning-job");
  assert.equal((await iterator.next()).value?.type, "job.started");
  assert.equal(database.workOrder("morning-job")?.status, "running");
  await adapter.shutdown();
  assert.equal(database.workOrder("morning-job")?.status, "blocked");
  credentials.key.resolve(undefined);
  while (!(await iterator.next()).done) {}
  database.close();
});
