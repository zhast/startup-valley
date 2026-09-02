import { join } from "node:path";

import { GameDatabase } from "../../dist/database.js";
import { PiWorkerAdapter } from "../../dist/pi-worker-adapter.js";

const dataRoot = process.argv[2];
if (!dataRoot) throw new Error("Expected a data root argument");

const waitingKey = new Promise(() => {});
const credentials = {
  async hasOpenRouterKey() { return false; },
  async getOpenRouterKey() { return waitingKey; },
  async setOpenRouterKey() {},
};
const database = new GameDatabase(join(dataRoot, "game.sqlite"), join(dataRoot, "company-project"));
const adapter = new PiWorkerAdapter(database, credentials, dataRoot);

await adapter.startJob({
  jobId: "fake-inflight",
  employeeId: "mira",
  projectId: "company",
  title: "Fake in-flight work",
  assignment: "Wait for the shutdown test",
  acceptanceCriteria: ["shutdown is graceful"],
  tokenBudget: 4000,
});

process.stdout.write("READY\n");
process.stdin.resume();
process.stdin.once("end", () => {
  void adapter.shutdown().then(() => database.close());
});
