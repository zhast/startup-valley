import { mkdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";

import { KeychainCredentialStore } from "./credential-store.js";
import { GameDatabase } from "./database.js";
import { PiWorkerAdapter } from "./pi-worker-adapter.js";
import type { WorkerEvent } from "./types.js";

const EXPECTED_NOTE = "Welcome to Startup Valley Studio. We build an office town where AI employees deliver real artifacts.";

function argument(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const dataRoot = resolve(argument("--data-dir") ?? join(process.cwd(), ".startup-valley-live"));
const projectRoot = join(dataRoot, "company-project");
const jobId = `live_${Date.now()}`;
await mkdir(projectRoot, { recursive: true });
const database = new GameDatabase(join(dataRoot, "startup-valley.sqlite"), projectRoot);
const credentials = new KeychainCredentialStore();
const adapter = new PiWorkerAdapter(database, credentials, dataRoot);

try {
  assert(await credentials.hasOpenRouterKey(), "No Startup Valley OpenRouter credential is stored in the OS keychain. Save it from the game first.");
  await adapter.startJob({
    jobId,
    employeeId: "mira",
    projectId: "company",
    title: "Live OpenRouter hello note",
    assignment: `Use write_file to create hello.md containing exactly these two sentences and no other text:\n\n${EXPECTED_NOTE}`,
    acceptanceCriteria: [
      "hello.md exists in the job workspace",
      "The file contains exactly the supplied two-sentence studio note",
    ],
    tokenBudget: 4_000,
  });

  const events: WorkerEvent[] = [];
  for await (const event of adapter.events(jobId)) {
    events.push(event);
    if (event.type === "usage.updated") {
      console.log(`${event.type} input=${event.inputTokens} output=${event.outputTokens} cost=${event.cost?.toFixed(6) ?? "unavailable"}`);
    } else {
      console.log(event.type);
    }
  }

  const eventTypes = events.map((event) => event.type);
  const indexOf = (type: WorkerEvent["type"]): number => eventTypes.indexOf(type);
  assert(indexOf("job.started") === 0, "Expected job.started as the first event");
  assert(indexOf("tool.started") > indexOf("job.started"), "Expected a tool.started event");
  assert(indexOf("tool.completed") > indexOf("tool.started"), "Expected a tool.completed event after tool.started");
  assert(indexOf("artifact.created") > indexOf("tool.started"), "Expected artifact.created after tool work began");
  assert(indexOf("usage.updated") > indexOf("tool.started"), "Expected usage.updated after tool work began");
  assert(indexOf("job.completed") > indexOf("usage.updated"), "Expected job.completed after usage.updated");
  assert(!events.some((event) => event.type === "job.failed" || event.type === "job.blocked"), "The live job failed or was blocked");

  const usageEvents = events.filter((event): event is Extract<WorkerEvent, { type: "usage.updated" }> => event.type === "usage.updated");
  const usage = usageEvents.at(-1);
  assert(usage && usage.inputTokens > 0 && usage.outputTokens > 0, "Expected nonzero input and output token usage");
  assert(usage.cost !== undefined && Number.isFinite(usage.cost), "Expected an estimated cost in the usage event");

  const artifactPath = join(projectRoot, "jobs", jobId, "hello.md");
  const content = (await readFile(artifactPath, "utf8")).trim();
  assert(content === EXPECTED_NOTE, "hello.md did not contain the exact two-sentence studio note");
  assert((await adapter.artifacts(jobId)).some((artifact) => artifact.relativePath === "hello.md"), "hello.md was not registered as an artifact");

  console.log(`PASS artifact=${artifactPath}`);
  console.log(`PASS estimated_cost=${usage.cost.toFixed(6)}`);
} finally {
  database.close();
}
