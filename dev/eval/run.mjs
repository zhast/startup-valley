import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import { mkdir, mkdtemp, readFile, readdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { DatabaseSync } from "node:sqlite";

import { ApprovalBroker } from "../../harness/dist/approval-broker.js";
import { GameDatabase } from "../../harness/dist/database.js";
import { PiWorkerAdapter } from "../../harness/dist/pi-worker-adapter.js";
import { createJobTools } from "../../harness/dist/tools.js";

const evalRoot = dirname(fileURLToPath(import.meta.url));
const fixturesRoot = join(evalRoot, "fixtures");

class EmptyCredentialStore {
  async hasOpenRouterKey() { return false; }
  async getOpenRouterKey() { return undefined; }
  async setOpenRouterKey() {}
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function spec(jobId, attachedStudioPath) {
  return {
    jobId,
    employeeId: "mira",
    projectId: "company",
    title: `Offline evaluation: ${jobId}`,
    assignment: "Produce the fixture deliverable.",
    acceptanceCriteria: ["Objective checker passes"],
    tokenBudget: 4000,
    ...(attachedStudioPath ? { attachedStudioPath } : {}),
  };
}

async function listTree(root) {
  if (!existsSync(root)) return [];
  const files = [];
  const queue = [root];
  while (queue.length > 0) {
    const directory = queue.shift();
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      const path = join(directory, entry.name);
      if (entry.isDirectory()) queue.push(path);
      if (entry.isFile()) {
        const content = await readFile(path);
        files.push({
          path: relative(root, path).replaceAll("\\", "/"),
          sha256: createHash("sha256").update(content).digest("hex"),
        });
      }
    }
  }
  return files.sort((left, right) => left.path.localeCompare(right.path));
}

async function studioSnapshot(database, studioRoot) {
  return JSON.stringify({ tree: await listTree(studioRoot), records: database.studioFiles() });
}

async function seedStudio(database, projectRoot) {
  const studioRoot = join(projectRoot, "studio");
  await mkdir(studioRoot, { recursive: true });
  await writeFile(join(studioRoot, "baseline.md"), "# Baseline\n\nKnown durable baseline.\n", "utf8");
  database.createWorkOrder({ ...spec("seed-studio"), title: "Seed durable baseline" });
  database.createArtifact("seed-studio", {
    artifactId: "seed-artifact",
    jobId: "seed-studio",
    name: "baseline.md",
    relativePath: "baseline.md",
    mediaType: "text/markdown",
    createdAt: new Date(0).toISOString(),
  });
  database.completeWorkOrder("seed-studio", "Seeded the offline evaluation baseline.");
  database.upsertStudioFile({
    name: "baseline.md",
    relativePath: "baseline.md",
    mediaType: "text/markdown",
    sourceJobId: "seed-studio",
    sourceArtifactId: "seed-artifact",
    promotedAt: new Date(0).toISOString(),
  });
  database.decidePromotion("seed-studio", true);
  return studioRoot;
}

async function prepareJobFiles(jobRoot, files = {}) {
  for (const [path, content] of Object.entries(files)) {
    const target = join(jobRoot, path);
    await mkdir(dirname(target), { recursive: true });
    await writeFile(target, content, "utf8");
  }
}

function workerEventExists(databasePath, jobId, type) {
  const raw = new DatabaseSync(databasePath, { readOnly: true });
  try {
    return raw.prepare("SELECT 1 AS found FROM worker_events WHERE work_order_id = ? AND type = ? LIMIT 1").get(jobId, type) !== undefined;
  } finally {
    raw.close();
  }
}

async function runAction(fixture, context) {
  const { action } = fixture;
  if (action.type === "tool") {
    context.database.createWorkOrder(spec(context.jobId));
    const tools = await createJobTools({
      jobId: context.jobId,
      jobRoot: context.jobRoot,
      studioRoot: context.studioRoot,
      approvalBroker: new ApprovalBroker(),
      onArtifact: (artifact) => context.database.createArtifact(context.jobId, artifact),
      onApproval: () => {},
    });
    const tool = tools.find((candidate) => candidate.name === action.tool);
    assert(tool, `Tool ${action.tool} was not exposed`);
    try {
      context.output = await tool.execute("eval-call", action.arguments, undefined, undefined, {});
    } catch (error) {
      context.error = error instanceof Error ? error.message : String(error);
      if (!action.expectError) throw error;
    }
    if (action.expectError) assert(context.error, `Expected ${action.tool} to reject`);
    return;
  }
  if (action.type === "compose_attached_context") {
    const attached = await context.adapter.readStudioFile(action.path);
    context.output = context.adapter.systemPromptFor(spec(context.jobId, action.path), attached.content);
    return;
  }
  if (action.type === "submit_off_hours") {
    context.database.setClock(1, action.minuteOfDay, 1);
    context.output = await context.adapter.submitJob(spec(context.jobId));
    return;
  }
  if (action.type === "missing_attachment") {
    context.database.setClock(1, 18 * 60, 1);
    try {
      await context.adapter.submitJob(spec(context.jobId, action.path));
    } catch (error) {
      context.error = error instanceof Error ? error.message : String(error);
    }
    assert(context.error, "Expected missing attachment submission to reject");
    return;
  }
  if (action.type === "approve_promotion") {
    context.database.createWorkOrder(spec(context.jobId));
    context.database.createArtifact(context.jobId, {
      artifactId: `${context.jobId}-artifact`,
      jobId: context.jobId,
      name: action.path,
      relativePath: action.path,
      mediaType: "text/markdown",
      createdAt: new Date().toISOString(),
    });
    context.database.completeWorkOrder(context.jobId, "Completed the approved promotion fixture.");
    context.output = await context.adapter.promoteArtifacts(context.jobId, true);
    return;
  }
  throw new Error(`Unsupported action type: ${action.type}`);
}

async function runCheck(check, context) {
  switch (check.type) {
    case "job_file_equals":
      assert(await readFile(join(context.jobRoot, check.path), "utf8") === check.value, `${check.path} content did not match`);
      return;
    case "artifact_registered":
      assert(context.database.artifacts(context.jobId).some((artifact) => artifact.relativePath === check.path), `${check.path} was not registered`);
      return;
    case "output_contains":
      assert(JSON.stringify(context.output).includes(check.value), `Output did not contain ${check.value}`);
      return;
    case "work_order_status":
      assert(context.database.workOrder(context.jobId)?.status === check.value, `Work order was not ${check.value}`);
      return;
    case "worker_event_present":
      assert(workerEventExists(context.databasePath, context.jobId, check.value), `Expected ${check.value} event`);
      return;
    case "worker_event_absent":
      assert(!workerEventExists(context.databasePath, context.jobId, check.value), `Unexpected ${check.value} event`);
      return;
    case "error_matches":
      assert(context.error?.toLocaleLowerCase().includes(check.value.toLocaleLowerCase()), `Error did not match ${check.value}: ${context.error ?? "none"}`);
      return;
    case "work_order_absent":
      assert(context.database.workOrder(context.jobId) === undefined, "Rejected work order was stored");
      return;
    case "outside_file_absent":
      assert(!existsSync(join(dirname(context.jobRoot), check.path)), `${check.path} escaped job scratch`);
      return;
    case "studio_path_absent":
      assert(!existsSync(join(context.studioRoot, check.path)), `${check.path} appeared in studio without approval`);
      return;
    case "promotion_cleared":
      assert(!context.database.pendingPromotions().some((candidate) => candidate.jobId === context.jobId), "Promotion remained pending");
      return;
    case "studio_file_equals":
      assert(await readFile(join(context.studioRoot, check.path), "utf8") === check.value, `${check.path} was not promoted exactly`);
      return;
    case "studio_provenance": {
      const file = context.database.studioFile(check.path);
      assert(file?.sourceJobId === context.jobId, `${check.path} lacks work-order provenance`);
      assert(file?.sourceArtifactId === `${context.jobId}-artifact`, `${check.path} lacks artifact provenance`);
      return;
    }
    default:
      throw new Error(`Unsupported check type: ${check.type}`);
  }
}

async function runFixture(fixture) {
  const dataRoot = await mkdtemp(join(tmpdir(), `startup-valley-eval-${fixture.id}-`));
  const projectRoot = join(dataRoot, "company-project");
  const databasePath = join(dataRoot, "game.sqlite");
  const database = new GameDatabase(databasePath, projectRoot);
  database.journey.db.prepare("UPDATE employees SET employment_status='hired'").run();
  try {
    const studioRoot = await seedStudio(database, projectRoot);
    const jobId = `eval-${fixture.id}`;
    const jobRoot = join(projectRoot, "jobs", jobId);
    await mkdir(jobRoot, { recursive: true });
    await prepareJobFiles(jobRoot, fixture.setup?.jobFiles);
    const context = {
      adapter: new PiWorkerAdapter(database, new EmptyCredentialStore(), dataRoot),
      database,
      databasePath,
      dataRoot,
      jobId,
      jobRoot,
      output: undefined,
      error: undefined,
      studioRoot,
    };
    const before = await studioSnapshot(database, studioRoot);
    await runAction(fixture, context);
    for (const check of fixture.checks) await runCheck(check, context);
    const after = await studioSnapshot(database, studioRoot);
    if (fixture.studioMutationApproved) {
      assert(after !== before, "Approved promotion did not change the studio");
    } else {
      assert(after === before, "Studio changed without explicit promotion approval");
    }
    return fixture.checks.length + 1;
  } finally {
    database.close();
  }
}

const fixtureFiles = (await readdir(fixturesRoot)).filter((name) => name.endsWith(".json")).sort();
const results = [];
for (const name of fixtureFiles) {
  const fixture = JSON.parse(await readFile(join(fixturesRoot, name), "utf8"));
  try {
    const checks = await runFixture(fixture);
    results.push({ id: fixture.id, objective: fixture.objective, passed: true, checks });
    process.stdout.write(`PASS ${fixture.id} (${checks} checks)\n`);
  } catch (error) {
    const message = error instanceof Error ? error.stack ?? error.message : String(error);
    results.push({ id: fixture.id, objective: fixture.objective, passed: false, error: message });
    process.stdout.write(`FAIL ${fixture.id}: ${message}\n`);
  }
}

const passed = results.filter((result) => result.passed).length;
process.stdout.write(`RESULT ${passed}/${results.length} fixtures passed\n`);
if (passed !== results.length || results.length !== 8) process.exitCode = 1;
