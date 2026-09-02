import { mkdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";

import { KeychainCredentialStore } from "./credential-store.js";
import { GameDatabase } from "./database.js";
import { auditLiveEvents } from "./live-event-audit.js";
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

  const usage = auditLiveEvents(events);

  const artifactPath = join(projectRoot, "jobs", jobId, "hello.md");
  const content = (await readFile(artifactPath, "utf8")).trim();
  assert(content === EXPECTED_NOTE, "hello.md did not contain the exact two-sentence studio note");
  assert((await adapter.artifacts(jobId)).some((artifact) => artifact.relativePath === "hello.md"), "hello.md was not registered as an artifact");

  console.log(`PASS artifact=${artifactPath}`);
  console.log(`PASS estimated_cost=${usage.cost?.toFixed(6)}`);
} finally {
  database.close();
}
