import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { GameDatabase } from "../src/database.js";
import { milestone, parseEvaluation } from "../src/journey.js";
import { prepareEvaluationInput } from "../src/evaluation-evidence.js";
import { prepareRevisionFiles } from "../src/milestone-adapter.js";
import { ApprovalBroker } from "../src/approval-broker.js";
import { createJobTools } from "../src/tools.js";
import { PiWorkerAdapter } from "../src/pi-worker-adapter.js";

const job = { jobId: "website", milestoneId: "website", employeeId: "mira", projectId: "company", title: "Build a website", assignment: "Create site/index.html and site/styles.css", acceptanceCriteria: ["Complete files"], tokenBudget: 12000 };
async function setup() {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-playtest-regression-"));
  const project = join(root, "company-project");
  const db = new GameDatabase(join(root, "game.sqlite"), project);
  db.journey.hire("mira", 1);
  db.createWorkOrder(job);
  return { root, project, db };
}

test("approval tool retains pending SQLite decision, live assignment and End Day exclusion", async () => {
  const { root, project, db } = await setup();
  const broker = new ApprovalBroker();
  let approvalId = "";
  const tools = await createJobTools({ jobId: job.jobId, jobRoot: join(project, "jobs", job.jobId), studioRoot: join(project, "studio"), approvalBroker: broker, onArtifact: () => {}, onApproval: (id, action) => { approvalId = id; db.createApproval(job.jobId, id, action); } });
  const request = tools.find((tool) => tool.name === "request_player_approval")!;
  const waiting = request.execute("test", { action: "Write welcome memo" }, undefined, undefined, {} as never);
  await new Promise((resolve) => setImmediate(resolve));
  assert.ok(approvalId);
  assert.equal(db.workOrder(job.jobId)?.status, "running");
  assert.equal(db.journey.db.prepare("SELECT finished_at FROM work_orders WHERE id=?").get(job.jobId)!.finished_at, null);
  assert.ok(db.employee("mira")!.assignment);
  assert.equal(db.journey.db.prepare("SELECT status FROM approvals WHERE id=?").get(approvalId)!.status, "pending");
  const room = db.bootstrap().furnishing;
  const approvalRoom = db.furnishing.update({ operationId: "approval-room", expectedRevision: room.revision, placements: {
    ...room.placements, "decor-rolling_storage_pedestal": { grid: [24, 8], facing: "east" },
  }, actorCells: [{ id: "founder", grid: [17, 19] }, { id: "mira", grid: [10, 7] }] }).furnishing;
  assert.equal(db.journey.db.prepare("SELECT status FROM approvals WHERE id=?").get(approvalId)!.status, "pending", "furnishing cannot dismiss approval or finish real work");
  assert.throws(() => db.endDay(1), /Finish or cancel/u);
  broker.decide(job.jobId, { approvalId, approved: true });
  db.decideApproval(approvalId, true);
  await waiting;
  db.decideApproval(approvalId, false); // a repeated stale decision cannot rewrite history
  assert.equal(db.journey.db.prepare("SELECT status FROM approvals WHERE id=?").get(approvalId)!.status, "approved");
  assert.deepEqual(db.bootstrap().furnishing, approvalRoom);
  db.close();
  const recovered = new GameDatabase(join(root, "game.sqlite"), project);
  assert.equal(recovered.workOrder(job.jobId)?.status, "failed");
  assert.deepEqual(recovered.bootstrap().furnishing, approvalRoom);
  recovered.close();
});

test("complete later sections reach the production evaluator input; omitted evidence is not a failed rubric", () => {
  const content = `# Audience\n${"Remote workers need affordable plants. ".repeat(25)}\n# Test design\nCompare two variants for 7 days at $10/day each.\n# Measurement plan\nTrack qualified signup rate >= 5%, cost <= $20.\n# Stop rule\nStop at $140 or seven days; do not launch until signup is connected.`;
  const input = prepareEvaluationInput(milestone("ads"), { kind: "local-artifacts", externalActionPerformed: false, documents: [{ path: "ads/campaign-plan.md", content }, { path: "ads/creative.md", content: "# Variant A\nA greener desk.\n# Variant B\nEasy-care plants for remote workers. $19/month. Prototype only." }] });
  assert.equal(input.sampled, false);
  assert.match(input.prompt, /Measurement plan[\s\S]*Stop at \$140/u);
  assert.match(input.prompt, /Variant B/u);
  assert.ok(Buffer.byteLength(input.systemPrompt + input.prompt) <= 7600);
  const long = prepareEvaluationInput(milestone("ads"), { kind: "local-artifacts", externalActionPerformed: false, documents: [{ path: "ads/campaign-plan.md", content: content.repeat(12) }, { path: "ads/creative.md", content: "# Creative\nTwo variations." }] });
  assert.equal(long.sampled, true);
  assert.match(long.prompt, /\[omitted\]/u);
  assert.match(long.prompt, /# Stop rule/u);
  assert.ok(Buffer.byteLength(long.systemPrompt + long.prompt) <= 7600);
  assert.throws(() => parseEvaluation('{"insufficientEvidence":true,"summary":"CSS omitted"}', milestone("website")), /no quality verdict or rewrite/u);
});

test("HTML evidence retains real CTA semantics, target ids, page footer and responsive CSS", () => {
  const input = prepareEvaluationInput(milestone("website"), { kind: "local-artifacts", externalActionPerformed: false, documents: [{ path: "site/index.html", content: '<!-- decoration --><main class="huge decorative classes"><h1>DeskBloom $19/month</h1><a href="#signup">Join</a><section id="signup"><form action="#" method="post"><input type="email"><button>Get updates</button></form></section><footer>Sample company</footer></main>' }, { path: "site/styles.css", content: "/* design */ @media(max-width:600px) { main { display: block; } }" }] });
  assert.match(input.prompt, /form action="#" method="post"/u);
  assert.match(input.prompt, /id="signup"/u);
  assert.match(input.prompt, /Sample company/u);
  assert.match(input.prompt, /@media\(max-width:600px\)/u);
  assert.match(input.prompt, /class="huge decorative classes"/u);
  assert.doesNotMatch(input.prompt, /<!-- decoration -->/u);
  assert.match(input.systemPrompt, /fake signup form/u);
});

test("blocked milestone resumes retained files in isolated editable scratch, with immutable originals", async () => {
  const { project, db } = await setup();
  const source = join(project, "jobs", "website");
  await mkdir(join(source, "site"), { recursive: true });
  await writeFile(join(source, "site/index.html"), "<h1>Keep my offer</h1>");
  const original = { artifactId: "old-html", jobId: "website", name: "index.html", relativePath: "site/index.html", mediaType: "text/html", createdAt: new Date().toISOString() };
  db.createArtifact("website", original);
  db.setWorkOrderStatus("website", "blocked");
  assert.equal(db.journey.state().milestones[0]!.state, "available");
  const revision = { ...job, jobId: "revision", revisionOfJobId: "website", tokenBudget: 24000 };
  db.journey.validateAssignment(revision);
  db.createWorkOrder(revision);
  const target = join(project, "jobs", "revision");
  const copied: string[] = [];
  await prepareRevisionFiles(source, target, [original], milestone("website").files, (artifact) => copied.push(artifact.relativePath));
  assert.deepEqual(copied, ["site/index.html"]);
  await writeFile(join(target, "site/index.html"), "<h1>Revised offer</h1>");
  assert.equal(await readFile(join(source, "site/index.html"), "utf8"), "<h1>Keep my offer</h1>");
  assert.equal(await readFile(join(target, "handoffs/site/index.html"), "utf8"), "<h1>Keep my offer</h1>");
  assert.equal(db.journey.state().milestones[0]!.jobId, "revision");
  assert.equal(db.journey.state().milestones[0]!.evaluation, null);
  assert.throws(() => db.journey.validateAssignment({ ...revision, revisionOfJobId: "not-this-job" }), /Invalid/u);
  db.close();
});

test("Activity usage survives bootstrap and restart instead of asking to select an already selected job", async () => {
  const { root, project, db } = await setup();
  db.recordUsage(job.jobId, 144, 72, 0.0123);
  db.completeWorkOrder(job.jobId, "Delivered a brief");
  assert.equal(db.recentWorkOrders()[0]!.inputTokens, 144);
  db.close();
  const reopened = new GameDatabase(join(root, "game.sqlite"), project);
  const recent = reopened.recentWorkOrders()[0]!;
  assert.equal(recent.outputTokens, 72);
  assert.equal(recent.cost, 0.0123);
  reopened.close();
});

test("injected evaluator exercises the same prepared evidence as the live session", async () => {
  const { root, project, db } = await setup();
  for (const [index, path] of milestone("website").files.entries()) {
    await mkdir(join(project, "jobs", job.jobId, "site"), { recursive: true });
    await writeFile(join(project, "jobs", job.jobId, path), path.endsWith(".html") ? '<h1>DeskBloom</h1><a href="#prototype">See prototype</a><section id="prototype">Signup is not open.</section>' : "body{color:#151515;background:#f1f1f1}");
    db.createArtifact(job.jobId, { artifactId: String(index), jobId: job.jobId, name: path, relativePath: path, mediaType: "text/plain", createdAt: new Date().toISOString() });
  }
  db.completeWorkOrder(job.jobId, "Prototype ready");
  const credentials = { async hasOpenRouterKey() { return false; }, async getOpenRouterKey() { return undefined; }, async setOpenRouterKey() {} };
  const adapter = new PiWorkerAdapter(db, credentials, root, async (definition, _artifacts, input) => {
    assert.match(input.prompt, /Signup is not open/u);
    assert.equal(input.sampled, false);
    return { text: JSON.stringify({ criteria: definition.criteria.map((name) => ({ name, score: 3, evidence: "Specific complete fixture evidence" })), summary: "Ready", revisionBrief: "" }), inputTokens: 700, outputTokens: 250, cost: 0.001 };
  });
  await adapter.evaluateMilestone(job.jobId);
  assert.equal(db.journey.evaluationFor(job.jobId)!.verdict, "ready");
  db.close();
});
