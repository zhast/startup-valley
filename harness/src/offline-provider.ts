import { join } from "node:path";
import { randomUUID } from "node:crypto";

import { ApprovalBroker } from "./approval-broker.js";
import type { GameDatabase } from "./database.js";
import type { EvaluationInput } from "./evaluation-evidence.js";
import { milestone, type MilestoneDefinition } from "./journey.js";
import { prepareRevisionFiles } from "./milestone-adapter.js";
import { createJobTools } from "./tools.js";
import type { Artifact, JobSpec, WorkerEvent } from "./types.js";

export const FAKE_PROVIDER_ENV = "STARTUP_VALLEY_FAKE_PROVIDER";

export function offlineProviderEnabled(env: NodeJS.ProcessEnv | Record<string, string | undefined> = process.env): boolean {
  return env[FAKE_PROVIDER_ENV] === "1";
}

export function offlineEvaluationText(definition: MilestoneDefinition): string {
  return JSON.stringify({
    criteria: definition.criteria.map((name) => ({
      name,
      score: 3,
      evidence: `Offline deliverable covers ${name.toLowerCase()} with concrete local artifact evidence.`,
    })),
    summary: `Offline review: ${definition.title} is ready as an internal prototype/plan.`,
    revisionBrief: "",
  });
}

export function offlineEvaluationRunner(definition: MilestoneDefinition, _artifacts: readonly string[], _input: EvaluationInput) {
  return Promise.resolve({
    text: offlineEvaluationText(definition),
    inputTokens: 120,
    outputTokens: 80,
    cost: 0,
  });
}

export function offlineDeliverables(spec: JobSpec): Array<{ path: string; content: string }> {
  if (spec.milestoneId) return Object.entries(OFFLINE_MILESTONE_FILES[spec.milestoneId] ?? {}).map(([path, content]) => ({ path, content }));
  return [{
    path: "deliverable.md",
    content: `# ${spec.title}\n\nOffline test provider wrote this bounded local note. It is not a live service, filing, or paid model result.\n`,
  }];
}

export async function runOfflineJob(
  spec: JobSpec,
  options: {
    database: GameDatabase;
    jobsRoot: string;
    studioRoot: string;
    emit: (event: WorkerEvent) => void;
    finished: () => boolean;
  },
): Promise<void> {
  const jobRoot = join(options.jobsRoot, spec.jobId);
  if (spec.revisionOfJobId && spec.milestoneId) {
    await prepareRevisionFiles(
      join(options.jobsRoot, spec.revisionOfJobId),
      jobRoot,
      options.database.artifacts(spec.revisionOfJobId),
      milestone(spec.milestoneId).files,
      (original) => {
        const artifact: Artifact = { ...original, jobId: spec.jobId, artifactId: randomUUID(), createdAt: new Date().toISOString() };
        options.database.createArtifact(spec.jobId, artifact);
        options.emit({ type: "artifact.created", artifactId: artifact.artifactId, name: artifact.name });
      },
    );
  }
  if (options.finished()) return;
  options.emit({ type: "agent.thinking", summary: "Planning the offline deliverable." });
  const tools = await createJobTools({
    jobId: spec.jobId,
    jobRoot,
    studioRoot: options.studioRoot,
    approvalBroker: new ApprovalBroker(),
    onArtifact: (artifact) => {
      options.database.createArtifact(spec.jobId, artifact);
      options.emit({ type: "artifact.created", artifactId: artifact.artifactId, name: artifact.name });
    },
    onApproval: () => {},
  });
  const writeFile = tools.find((tool) => tool.name === "write_file");
  if (!writeFile) throw new Error("Offline provider could not load write_file");
  for (const file of offlineDeliverables(spec)) {
    if (options.finished()) return;
    options.emit({ type: "tool.started", tool: "write_file", label: "Write file" });
    await writeFile.execute("offline", { path: file.path, content: file.content }, undefined, undefined, {} as never);
    options.emit({ type: "tool.completed", tool: "write_file", ok: true });
  }
  if (options.finished()) return;
  if (options.database.artifacts(spec.jobId).length === 0) {
    throw new Error("The offline provider finished without creating a deliverable artifact");
  }
  options.database.recordUsage(spec.jobId, 0, 0, 0);
  options.emit({ type: "usage.updated", inputTokens: 0, outputTokens: 0, cost: 0 });
  const summary = spec.milestoneId
    ? `Offline ${milestone(spec.milestoneId).title} files are ready for review.`
    : "Offline work order completed.";
  options.database.completeWorkOrder(spec.jobId, summary);
  options.emit({ type: "job.completed", summary });
}

const OFFLINE_MILESTONE_FILES: Record<string, Record<string, string>> = {
  website: {
    "site/index.html": `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DeskBloom — local prototype</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <header>
    <p class="eyebrow">Internal prototype</p>
    <h1>DeskBloom keeps a small office honest</h1>
    <p>A calm local workspace for founders who want real files, not a live product yet.</p>
    <nav>
      <a href="#offer">Offer</a>
      <a href="#benefits">Benefits</a>
      <a href="#prototype">How this prototype works</a>
    </nav>
    <a class="cta" href="#prototype">See how this prototype works</a>
  </header>
  <main>
    <section id="offer">
      <h2>Clear offer</h2>
      <p>DeskBloom is a local company office for reviewing teammate work. This page is the first public-facing draft.</p>
    </section>
    <section id="benefits">
      <h2>Benefits</h2>
      <ul>
        <li>A named offer and audience in one place</li>
        <li>Local navigation between sections</li>
        <li>An honest next step that does not collect data</li>
      </ul>
    </section>
    <section id="prototype">
      <h2>This is a prototype</h2>
      <p>Signup is not yet open. This page does not collect data, send email, or connect to a backend. It is an internal company prototype for review only. Assumptions: company name DeskBloom, audience is a first-time founder, and no live billing exists.</p>
    </section>
  </main>
</body>
</html>
`,
    "site/styles.css": `:root { color-scheme: light; font-family: Georgia, serif; }
body { margin: 0 auto; max-width: 40rem; padding: 1.5rem; line-height: 1.5; }
nav { display: flex; gap: 1rem; flex-wrap: wrap; }
.cta { display: inline-block; margin-top: 1rem; padding: 0.6rem 1rem; background: #354b98; color: #fff; text-decoration: none; }
@media (max-width: 640px) { body { padding: 1rem; } h1 { font-size: 1.6rem; } }
`,
  },
  ads: {
    "ads/campaign-plan.md": `# Advertising experiment plan

This is a plan, not a launched campaign. No real spend, impressions, or results are claimed.

## Audience
First-time founders who already hired one teammate and need a public prototype page.

## Offer
Invite them to review the DeskBloom prototype website. Real signup tracking must be connected before launch.

## Channel
One initial channel: a founder newsletter placement.

## Budget split
Proposed $200 total over 14 days: $140 creative test, $60 reserve. This is a proposed split only.

## Test design
Two creative variants with a controlled comparison: same audience, channel, and budget; only headline changes.

## Measurement
Events: page view of the prototype explanation, and CTA click. Numeric success: 8% CTA click-through or 40 explanation views in 14 days.

## Stop rule
Stop if $200 is spent or 14 days elapse, whichever comes first. Do not continue without connected signup tracking.
`,
    "ads/creative.md": `# Creative variants

These are draft messages for the planned experiment. They have not run.

## Variant A
Headline: Review the DeskBloom prototype before signup exists.
Body: A local office that produces real files. CTA: Read the prototype explanation.

## Variant B
Headline: See the first DeskBloom page without joining a waitlist.
Body: Honest prototype, no form, no collected emails. CTA: Read the prototype explanation.

Controlled comparison: keep audience, channel, budget, and landing section identical; change only the headline.
`,
  },
  incorporate: {
    "company/incorporation-readiness.md": `# Incorporation readiness questions

Planning exercise only. No legal filing, payment, or incorporation has occurred. This is not legal advice.

## Open questions
- Jurisdiction: which state or country should be considered first, and why?
- Ownership: how should founder and later teammate equity be discussed with counsel?
- Entity: LLC, corporation, or another form — what tradeoffs apply here?
- Tax: which registrations and elections need a professional answer?
- Advice: which licensed attorney and accountant should review this before any filing?

Assumptions and limitations: DeskBloom is a game company with fictional cash. No real registered agent, EIN, or bank account exists.
`,
    "company/incorporation-checklist.md": `# Incorporation checklist

Planning checklist only. None of these steps have been completed. This is not a filing-ready legal document.

1. Confirm jurisdiction with licensed counsel.
2. Decide entity type after professional advice.
3. List ownership questions; do not invent cap-table answers.
4. Identify tax registrations that require an accountant.
5. Do not file, pay, or sign formation documents from this game.

Limitations: this checklist cannot incorporate a business and must not be treated as legal advice.
`,
  },
};
