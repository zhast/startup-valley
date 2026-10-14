import { mkdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

import { credentialStoreFromEnvironment } from "./credential-store.js";
import { GameDatabase } from "./database.js";
import { redactSecret } from "./grok-auth.js";
import { milestone, type EvaluationResult } from "./journey.js";
import { offlineProviderEnabled } from "./offline-provider.js";
import { PiWorkerAdapter } from "./pi-worker-adapter.js";
import type { JobSpec, WorkerEvent } from "./types.js";

const TOKEN_BUDGET: Record<string, number> = {
  website: 10_000,
  ads: 8_000,
  incorporate: 8_000,
};
const JOB_TIMEOUT_MS = 180_000;
const EVAL_TIMEOUT_MS = 120_000;
const BRIEFS: Record<string, string> = {
  website: [
    "Write only site/index.html and site/styles.css. Keep each file under 50 lines. Call write_file once per path, then stop.",
    "Do not call web_search, web_fetch, or request_player_approval.",
    "Assume the company is Northwind Studio, a planning workspace for first-time founders, and label that as an assumption.",
    "Include a specific h1 offer, three concrete benefits, and nav links to #offer, #benefits, and #prototype.",
    "The only primary call to action must be a link whose visible text is \"See how the prototype works\" and whose href is \"#prototype\".",
    "Section id=\"prototype\" must say this is a prototype, signup is not yet open, and no data is collected.",
    "Do not add a form, email address, script, or the words Sign up.",
    "styles.css must style the page and include one @media rule.",
  ].join(" "),
  ads: [
    "Write only ads/campaign-plan.md and ads/creative.md. Keep each file under 45 lines. Call write_file once per path, then stop.",
    "Do not call web_search, web_fetch, or request_player_approval.",
    "In campaign-plan.md use these headings: Audience, Offer, Channel, Budget split, Duration, Variants, Events, Thresholds, Stop rule, Limits.",
    "Audience: first-time founders in the United States, ages 28-40, building their first software product and not yet incorporated. Say why one Meta ads campaign reaches them.",
    "Offer: Northwind Studio, a planning workspace. Repeat that visitors can view the prototype and that signup is not open.",
    "Budget: 500 dollars over 14 days, split 50/50. Variants share the audience and offer. The only difference is the headline. Name both headlines.",
    "Events: prototype_section_view now, and planned_signup only after tracking is connected. Threshold: at least 40 prototype_section_view events at or below 2.50 dollars each.",
    "Stop at 500 dollars or 14 days, whichever comes first. State that no money has been spent and no impressions or results exist.",
    "creative.md must repeat both headlines, the shared body, and the single variable that changes.",
  ].join(" "),
  incorporate: [
    "Write only company/incorporation-readiness.md and company/incorporation-checklist.md. Keep each file under 45 lines. Call write_file once per path, then stop.",
    "Do not call web_search, web_fetch, or request_player_approval.",
    "In readiness.md, one unanswered question each for jurisdiction, ownership, entity type, tax, and which lawyer to ask. Do not answer them.",
    "In checklist.md, ordered unchecked items for choosing a lawyer, confirming founders, comparing entity types, and pausing before any filing or payment.",
    "Both files must say no filing, payment, or incorporation has occurred and that this is not legal advice or a filing-ready document.",
  ].join(" "),
};

function briefFor(id: string): string {
  return BRIEFS[id] ?? "Keep each required file concise, under 50 lines. Use write_file once per required path, then stop.";
}

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function argument(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

const dataRoot = resolve(argument("--data-dir") ?? join(tmpdir(), `startup-valley-live-chapter-${process.pid}`));
const projectRoot = join(dataRoot, "company-project");
let secret = "";

try {
  assert(process.env.STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS !== "1", "Host credential isolation is set, so OpenRouter cannot be used");
  assert(!offlineProviderEnabled(), "The offline provider is set. This run must call OpenRouter");
  await mkdir(projectRoot, { recursive: true });
  const database = new GameDatabase(join(dataRoot, "startup-valley.sqlite"), projectRoot);
  const credentials = credentialStoreFromEnvironment();
  const adapter = new PiWorkerAdapter(database, credentials, dataRoot);
  try {
    const status = await credentials.status({ refresh: false });
    const credential = await credentials.resolveModelCredential();
    secret = credential?.apiKey ?? "";
    assert(status.configured && status.provider === "openrouter" && status.openRouterSource === "environment", "OPENROUTER_API_KEY did not resolve to the OpenRouter provider");
    assert(credential?.provider === "openrouter", "Resolved provider was not OpenRouter");
    assert(credential.modelId.includes("/") && credential.modelId.length <= 80, "OpenRouter model id is not usable");
    console.log(`MODEL ${credential.modelId}`);
    console.log("PROVIDER openrouter");

    database.journey.hire("mira", 1);
    await playMilestone(adapter, database, "website", 1);
    database.journey.hire("theo", database.clockState().day);
    database.endDay(1);
    await playMilestone(adapter, database, "ads", 2);
    database.endDay(2);
    await playMilestone(adapter, database, "incorporate", 3);

    const company = database.journey.state().company;
    assert(company.chapter === 2, `Chapter did not advance (chapter=${company.chapter})`);
    const usage = usageTotals(database);
    assert(usage.inputTokens > 0 && usage.outputTokens > 0, "OpenRouter usage tokens were zero");
    assert(usage.cost > 0, "OpenRouter usage cost was zero");
    console.log(`INPUT_TOKENS ${usage.inputTokens}`);
    console.log(`OUTPUT_TOKENS ${usage.outputTokens}`);
    console.log(`TOTAL_TOKENS ${usage.inputTokens + usage.outputTokens}`);
    console.log(`COST ${usage.cost.toFixed(6)}`);
    console.log("CHAPTER 2");
    console.log("LIVE_RESULT PASS");
  } finally {
    await adapter.shutdown().catch(() => undefined);
    database.close();
  }
} catch (error) {
  const message = redactSecret(error instanceof Error ? error.message : String(error), secret);
  console.error(`LIVE_RESULT FAIL ${message}`);
  process.exitCode = 1;
}

async function playMilestone(adapter: PiWorkerAdapter, database: GameDatabase, id: string, day: number): Promise<void> {
  const definition = milestone(id);
  assert(database.clockState().day === day, `${id} expected day ${day}`);
  let jobId = await runMilestoneJob(adapter, database, id, definition.employeeId, definition.assignment);
  await adapter.promoteArtifacts(jobId, true);
  let verdict = await evaluate(adapter, database, id, jobId);
  if (verdict.verdict === "revise") {
    const revisionId = await runMilestoneJob(
      adapter,
      database,
      id,
      definition.employeeId,
      `${definition.assignment}\n\nRevise the files so every rubric item is specific and usable. Keep the original constraints. Do not add a form, email, live signup, external launch, legal filing, or claimed results.\nReview notes:\n${verdict.revisionBrief}\n${briefFor(id)}`,
      jobId,
    );
    await adapter.promoteArtifacts(revisionId, true);
    jobId = revisionId;
    verdict = await evaluate(adapter, database, id, jobId);
  }
  assert(verdict.verdict === "ready", `${id} review was ${verdict.verdict}: ${verdict.summary}`);
  database.journey.complete(jobId, false, day);
  const studio = new Set((await adapter.studioFiles()).map((file) => file.relativePath));
  for (const path of definition.files) assert(studio.has(path), `Studio is missing ${path}`);
  console.log(`MILESTONE ${id} PASS`);
}

async function runMilestoneJob(
  adapter: PiWorkerAdapter,
  database: GameDatabase,
  id: string,
  employeeId: string,
  assignment: string,
  revisionOfJobId?: string,
): Promise<string> {
  const definition = milestone(id);
  const jobId = `${id}-${Date.now()}`;
  const spec: JobSpec = {
    jobId,
    employeeId,
    projectId: "company",
    title: definition.title,
    assignment: `${assignment}\n\n${briefFor(id)}`,
    acceptanceCriteria: definition.criteria,
    tokenBudget: TOKEN_BUDGET[id] ?? 8_000,
    milestoneId: id,
    ...(revisionOfJobId ? { revisionOfJobId } : {}),
  };
  await adapter.startJob(spec);
  const events = await collectEvents(adapter, spec.jobId);
  const outcome = events.at(-1);
  assert(outcome?.type === "job.completed", `${id} ended as ${outcome?.type ?? "no event"}`);
  const artifacts = new Set((await adapter.artifacts(jobId)).map((artifact) => artifact.relativePath));
  for (const path of definition.files) assert(artifacts.has(path), `${id} did not write ${path}`);
  assert(database.workOrder(jobId)?.status === "completed", `${id} was not stored as completed`);
  return jobId;
}

async function collectEvents(adapter: PiWorkerAdapter, jobId: string): Promise<WorkerEvent[]> {
  const events: WorkerEvent[] = [];
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<never>((_resolve, reject) => {
    timer = setTimeout(() => reject(new Error(`${jobId} timed out`)), JOB_TIMEOUT_MS);
  });
  const stream = (async () => {
    for await (const event of adapter.events(jobId)) {
      events.push(event);
      if (event.type === "usage.updated") {
        console.log(`usage job=${jobId} input=${event.inputTokens} output=${event.outputTokens} cost=${event.cost?.toFixed(6) ?? "unavailable"}`);
      } else if (event.type === "job.failed") {
        console.log(`job.failed ${redactSecret(event.error, secret)}`);
      } else if (event.type === "job.blocked") {
        console.log(`job.blocked ${redactSecret(event.reason, secret)}`);
      } else if (event.type === "approval.required") {
        console.log("approval.required");
        await adapter.approve(jobId, { approvalId: event.approvalId, approved: true, reason: "Live chapter accepts this local file step" });
      } else if (event.type !== "agent.thinking") {
        console.log(event.type);
      }
    }
  })();
  try {
    await Promise.race([stream, timeout]);
  } catch (error) {
    await adapter.cancel(jobId).catch(() => undefined);
    throw error;
  } finally {
    if (timer) clearTimeout(timer);
  }
  return events;
}

async function evaluate(adapter: PiWorkerAdapter, database: GameDatabase, id: string, jobId: string): Promise<EvaluationResult> {
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<never>((_resolve, reject) => {
    timer = setTimeout(() => reject(new Error(`${id} evaluation timed out`)), EVAL_TIMEOUT_MS);
  });
  try {
    await Promise.race([adapter.evaluateMilestone(jobId), timeout]);
  } finally {
    if (timer) clearTimeout(timer);
  }
  const result = database.journey.evaluationFor(jobId);
  assert(result, `${id} evaluation did not finish`);
  console.log(`EVAL ${id} verdict=${result.verdict} score=${result.score.toFixed(2)}`);
  return result;
}

function usageTotals(database: GameDatabase): { inputTokens: number; outputTokens: number; cost: number } {
  const row = database.journey.db.prepare(`
    SELECT
      COALESCE((SELECT SUM(input_tokens) FROM work_orders), 0) +
      COALESCE((SELECT SUM(input_tokens) FROM evaluation_usage), 0) AS input_tokens,
      COALESCE((SELECT SUM(output_tokens) FROM work_orders), 0) +
      COALESCE((SELECT SUM(output_tokens) FROM evaluation_usage), 0) AS output_tokens,
      COALESCE((SELECT SUM(cost) FROM work_orders), 0) +
      COALESCE((SELECT SUM(cost) FROM evaluation_usage), 0) AS cost
  `).get() as { input_tokens: number; output_tokens: number; cost: number };
  return {
    inputTokens: Number(row.input_tokens),
    outputTokens: Number(row.output_tokens),
    cost: Number(row.cost),
  };
}
