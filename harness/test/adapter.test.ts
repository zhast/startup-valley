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
  await assert.rejects(adapter.startJob(spec("second")), /one concurrent job/u);
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
  const theoContext = adapter.systemPromptFor({ ...spec("theo-review"), employeeId: "theo", title: "Review Mina's note" });
  assert.match(theoContext, /Mina: Inventory keyboard navigation/u);
  assert.match(theoContext, /jobs\/mina-note\/design-note\.md/u);
  assert.match(theoContext, /Specified tab order/u);
  assert.doesNotMatch(theoContext, /shared transcript content/u);

  const noteDirectory = join(root, "company-project", "jobs", "mina-note");
  await mkdir(noteDirectory, { recursive: true });
  await writeFile(join(noteDirectory, "design-note.md"), "# Keyboard navigation\n\nUse visible focus.", "utf8");
  const opened = await adapter.readArtifact("mina-note", "design-note.md");
  assert.match(opened.content, /visible focus/u);
  database.close();
});
