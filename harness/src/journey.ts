import type { DatabaseSync } from "node:sqlite";
import type { JobSpec } from "./types.js";

export interface MilestoneDefinition {
  id: string; title: string; employeeId: string; prerequisite?: string;
  files: string[]; criteria: string[]; assignment: string;
  rewardCents: number; feeCents: number; reputation: number;
  availableFromDay: number;
}
export interface EvaluationResult {
  verdict: "ready" | "revise";
  score: number;
  criteria: Array<{ name: string; score: number; evidence: string }>;
  summary: string; revisionBrief: string;
}
export const MILESTONES: readonly MilestoneDefinition[] = [
  { id: "website", title: "Build a website", employeeId: "mira", files: ["site/index.html", "site/styles.css"],
    criteria: ["Clear offer", "Coherent page structure", "Usable calls to action", "Completeness"],
    assignment: "Build an original, complete static landing page for the founder's company. Create site/index.html and site/styles.css with responsive styling, a clear offer, benefits, and usable local navigation. Keep the two files concise. The primary CTA must link to an on-page section that clearly explains this is a prototype and signup is not yet open. Do not include a fake form, placeholder email address, dead link, or promise of collecting data. No external scripts, deployment, invented customers, or testimonials. Label assumptions if company details are missing.",
    rewardCents: 60000, feeCents: 0, reputation: 10, availableFromDay: 1 },
  { id: "ads", title: "Run ads", employeeId: "theo", prerequisite: "website", files: ["ads/campaign-plan.md", "ads/creative.md"],
    criteria: ["Audience clarity", "Offer-message fit", "Test design", "Measurement plan", "Completeness"],
    assignment: "Prepare an artifact-first advertising experiment for the company's website. Create concise ads/campaign-plan.md and ads/creative.md. Include audience, offer, one initial channel, proposed budget split, test duration, two creative variants with a controlled comparison, event definitions, numeric success thresholds and a spend/time stop rule. Make clear that real signup tracking must be connected before launch. This is a plan, NOT a launched campaign. Do not claim real spend, impressions, or results.",
    rewardCents: 120000, feeCents: 0, reputation: 15, availableFromDay: 2 },
  { id: "incorporate", title: "Incorporate", employeeId: "mira", prerequisite: "ads", files: ["company/incorporation-readiness.md", "company/incorporation-checklist.md"],
    criteria: ["Readiness questions", "Clear checklist", "Assumptions and limitations", "Completeness"],
    assignment: "Create company/incorporation-readiness.md and company/incorporation-checklist.md as a planning exercise only. Identify jurisdiction, ownership, entity, tax, and professional-advice questions without inventing answers. Clearly say no legal filing, payment, or incorporation has occurred. This is not legal advice or a filing-ready legal document.",
    rewardCents: 0, feeCents: 50000, reputation: 20, availableFromDay: 3 },
];

export function milestone(id: string): MilestoneDefinition {
  const result = MILESTONES.find((item) => item.id === id);
  if (!result) throw new Error("Unknown company milestone");
  return result;
}

/** Evaluation is advisory evidence, never trusted instructions or proof of an external action. */
export function parseEvaluation(text: string, definition: MilestoneDefinition): EvaluationResult {
  const clean = text.trim().replace(/^```(?:json)?\s*/u, "").replace(/\s*```$/u, "");
  const value = JSON.parse(clean) as Record<string, unknown>;
  if (value.insufficientEvidence === true) throw new Error(`Review could not see enough evidence; no quality verdict or rewrite is required. ${String(value.summary ?? "Retry review with concise complete artifacts.").slice(0, 700)}`);
  if (!Array.isArray(value.criteria) || value.criteria.length !== definition.criteria.length) throw new Error("Evaluator returned an incomplete rubric");
  const rawCriteria = value.criteria as unknown[];
  const criteria = definition.criteria.map((name, index) => {
    const item = rawCriteria[index] as Record<string, unknown>;
    if (!item || item.name !== name || !Number.isInteger(item.score) || Number(item.score) < 0 || Number(item.score) > 3 || typeof item.evidence !== "string" || !item.evidence.trim()) throw new Error("Evaluator returned an invalid criterion");
    return { name, score: Number(item.score), evidence: item.evidence.slice(0, 700) };
  });
  if (typeof value.summary !== "string" || typeof value.revisionBrief !== "string") throw new Error("Evaluator omitted its feedback");
  const score = criteria.reduce((sum, item) => sum + item.score, 0) / criteria.length;
  return { criteria, score, verdict: score >= 2.5 && criteria.every((item) => item.score >= 2) ? "ready" : "revise", summary: value.summary.slice(0, 1200), revisionBrief: value.revisionBrief.slice(0, 1800) };
}

export class JourneyStore {
  constructor(readonly db: DatabaseSync) {
    for (const item of MILESTONES) db.prepare("INSERT OR IGNORE INTO milestone_progress(id) VALUES (?)").run(item.id);
    db.prepare("UPDATE milestone_evaluations SET status = 'failed', error = 'Evaluation interrupted. Retry when ready.' WHERE status = 'evaluating'").run();
  }
  transaction<T>(action: () => T): T {
    this.db.exec("BEGIN IMMEDIATE");
    try { const result = action(); this.db.exec("COMMIT"); return result; }
    catch (error) { this.db.exec("ROLLBACK"); throw error; }
  }
  hired(id: string): boolean {
    return Boolean(this.db.prepare("SELECT id FROM employees WHERE id = ? AND employment_status = 'hired'").get(id));
  }
  completed(id: string): boolean {
    return Boolean(this.db.prepare("SELECT id FROM milestone_progress WHERE id = ? AND completed = 1").get(id));
  }
  state() {
    const company = this.db.prepare("SELECT * FROM company_state WHERE id = 1").get()!;
    const milestones = MILESTONES.map((definition) => {
      const progress = this.db.prepare("SELECT * FROM milestone_progress WHERE id = ?").get(definition.id)!;
      const jobId = String(progress.job_id ?? "");
      const job = jobId ? this.db.prepare("SELECT status FROM work_orders WHERE id = ?").get(jobId) : undefined;
      const evaluation = jobId ? this.db.prepare("SELECT * FROM milestone_evaluations WHERE job_id = ?").get(jobId) : undefined;
      const available = this.day() >= definition.availableFromDay && this.hired(definition.employeeId) && (!definition.prerequisite || this.completed(definition.prerequisite));
      const state = progress.completed ? "completed" : !available ? "locked" : evaluation?.status === "evaluating" ? "evaluating" : evaluation?.status === "done" && JSON.parse(String(evaluation.result_json)).verdict === "revise" ? "revision_required" : job && ["running", "queued", "completed"].includes(String(job.status)) ? "active" : "available";
      return { ...definition, state, jobId, jobStatus: job?.status ?? "", overridden: Boolean(progress.overridden), evaluation: evaluation?.result_json ? JSON.parse(String(evaluation.result_json)) as EvaluationResult : null, evaluationError: evaluation?.error ?? "" };
    });
    return {
      company: { cashCents: Number(company.cash_cents), earnedCents: Number(company.earned_cents), reputation: Number(company.reputation), chapter: Number(company.chapter) },
      player: JSON.parse(String(company.player_json)) as Record<string, unknown>, milestones,
      candidates: [
        { id: "mira", name: "Mina", costCents: 0, available: !this.hired("mira"), hired: this.hired("mira"), role: "Product + research" },
        { id: "theo", name: "Theo", costCents: 30000, available: !this.hired("theo") && this.completed("website"), hired: this.hired("theo"), role: "Growth + operations" },
      ],
    };
  }
  hire(id: string, day: number) {
    return this.transaction(() => {
      if (this.hired(id)) return this.state();
      const candidate = this.state().candidates.find((item) => item.id === id);
      if (!candidate?.available) throw new Error("Candidate is not available yet");
      this.charge(`hire:${id}`, day, -candidate.costCents, 0, 0, `Hired ${candidate.name}`);
      this.db.prepare("UPDATE employees SET employment_status = 'hired', hired_day = ? WHERE id = ?").run(day, id);
      return this.state();
    });
  }
  validateAssignment(spec: JobSpec): void {
    if (!this.hired(spec.employeeId)) throw new Error("Hire this employee before assigning work");
    if (!spec.milestoneId) { if (spec.revisionOfJobId) throw new Error("A revision must belong to a milestone"); return; }
    const definition = milestone(spec.milestoneId);
    if (this.day() < definition.availableFromDay || definition.employeeId !== spec.employeeId || this.completed(definition.id) || (definition.prerequisite && !this.completed(definition.prerequisite))) throw new Error("Milestone is locked or already complete");
    const progress = this.db.prepare("SELECT job_id FROM milestone_progress WHERE id = ?").get(definition.id)!;
    if (progress.job_id) {
      const old = this.db.prepare("SELECT status FROM work_orders WHERE id = ?").get(String(progress.job_id));
      if (old?.status === "completed") {
        const evaluation = this.db.prepare("SELECT result_json FROM milestone_evaluations WHERE job_id = ? AND status = 'done'").get(String(progress.job_id));
        if (!evaluation || JSON.parse(String(evaluation.result_json)).verdict !== "revise" || spec.revisionOfJobId !== progress.job_id) throw new Error("Evaluate the current result before starting a revision");
      }
    }
    if (spec.revisionOfJobId) {
      const source = this.db.prepare("SELECT milestone_id, status FROM work_orders WHERE id = ?").get(spec.revisionOfJobId);
      if (source?.milestone_id !== spec.milestoneId || !["completed", "blocked", "failed", "cancelled"].includes(String(source.status)) || progress.job_id !== spec.revisionOfJobId) throw new Error("Invalid milestone revision source");
    }
  }
  attachJob(spec: JobSpec): void {
    if (spec.milestoneId) this.db.prepare("UPDATE milestone_progress SET job_id = ? WHERE id = ? AND completed = 0").run(spec.jobId, spec.milestoneId);
  }
  private day(): number {
    const row = this.db.prepare("SELECT value_json FROM game_state WHERE key='clock'").get();
    return row ? Number(JSON.parse(String(row.value_json)).day ?? 1) : 1;
  }
  evaluationFor(jobId: string): EvaluationResult | undefined {
    const row = this.db.prepare("SELECT result_json FROM milestone_evaluations WHERE job_id = ? AND status = 'done'").get(jobId);
    return row ? JSON.parse(String(row.result_json)) as EvaluationResult : undefined;
  }
  beginEvaluation(jobId: string): MilestoneDefinition {
    const job = this.db.prepare("SELECT milestone_id, status FROM work_orders WHERE id = ?").get(jobId);
    if (!job || job.status !== "completed" || !job.milestone_id) throw new Error("Complete a milestone work order before evaluation");
    const progress = this.db.prepare("SELECT job_id, completed FROM milestone_progress WHERE id = ?").get(String(job.milestone_id))!;
    if (progress.job_id !== jobId || progress.completed) throw new Error("This is not the current milestone result");
    this.db.prepare("INSERT INTO milestone_evaluations(job_id,status) VALUES (?,'evaluating') ON CONFLICT(job_id) DO UPDATE SET status='evaluating', error=NULL").run(jobId);
    return milestone(String(job.milestone_id));
  }
  finishEvaluation(jobId: string, result: EvaluationResult): void {
    this.db.prepare("UPDATE milestone_evaluations SET status='done',result_json=?,error=NULL WHERE job_id=?").run(JSON.stringify(result), jobId);
  }
  failEvaluation(jobId: string, error: string): void {
    this.db.prepare("UPDATE milestone_evaluations SET status='failed',error=? WHERE job_id=?").run(error.slice(0, 1000), jobId);
  }
  complete(jobId: string, override: boolean, day: number) {
    return this.transaction(() => {
      const job = this.db.prepare("SELECT milestone_id FROM work_orders WHERE id=?").get(jobId);
      if (!job?.milestone_id) throw new Error("Unknown milestone result");
      const definition = milestone(String(job.milestone_id));
      const progress = this.db.prepare("SELECT * FROM milestone_progress WHERE id=?").get(definition.id)!;
      if (progress.completed) return this.state();
      if (progress.job_id !== jobId) throw new Error("Only the current result can complete a milestone");
      const evaluation = this.evaluationFor(jobId);
      if (!evaluation || (!override && evaluation.verdict !== "ready") || (override && evaluation.verdict !== "revise")) throw new Error("Evaluate this result before completing it");
      const reward = override ? Math.floor(definition.rewardCents / 2) : definition.rewardCents;
      this.charge(`milestone:${definition.id}`, day, reward - definition.feeCents, reward, override ? 0 : definition.reputation, definition.title);
      this.db.prepare("UPDATE milestone_progress SET completed=1,overridden=?,completed_day=? WHERE id=?").run(override ? 1 : 0, day, definition.id);
      if (definition.id === "incorporate") this.db.prepare("UPDATE company_state SET chapter=2 WHERE id=1").run();
      return this.state();
    });
  }
  private charge(id: string, day: number, cash: number, earned: number, reputation: number, label: string): void {
    if (this.db.prepare("SELECT id FROM company_transactions WHERE id=?").get(id)) return;
    if (this.state().company.cashCents + cash < 0) throw new Error("Not enough company cash");
    this.db.prepare("INSERT INTO company_transactions VALUES (?,?,?,?,?,?)").run(id, day, cash, earned, reputation, label);
    this.db.prepare("UPDATE company_state SET cash_cents=cash_cents+?,earned_cents=earned_cents+?,reputation=reputation+? WHERE id=1").run(cash, earned, reputation);
  }
  savePlayer(value: Record<string, unknown>): void {
    const x = Number(value.x), y = Number(value.y);
    if (!Number.isFinite(x) || !Number.isFinite(y) || x < 0 || x > 1280 || y < 0 || y > 720) throw new Error("Invalid saved player position");
    const unit = (key: string, fallback: number) => typeof value[key] === "number" ? Math.max(0, Math.min(1, Number(value[key]))) : fallback;
    this.db.prepare("UPDATE company_state SET player_json=? WHERE id=1").run(JSON.stringify({ x, y, movementSeen: value.movementSeen === true, effectsVolume: unit("effectsVolume", 0.5), ambienceVolume: unit("ambienceVolume", 0.2), attentionEmployeeId: ["mira", "theo"].includes(String(value.attentionEmployeeId)) ? value.attentionEmployeeId : "" }));
  }
  daySummary(day: number, spend: number) {
    const rows = this.db.prepare("SELECT label,cash_delta,earned_delta,reputation_delta FROM company_transactions WHERE day=?").all(day);
    const completedWork = this.db.prepare("SELECT title, revision_of_job_id FROM work_orders WHERE game_day=? AND status='completed'").all(day).map((row) => String(row.title) + (row.revision_of_job_id ? " (revision)" : ""));
    return { day, entries: rows, completedWork, earnedCents: rows.reduce((n, row) => n + Number(row.earned_delta), 0), reputation: rows.reduce((n, row) => n + Number(row.reputation_delta), 0), aiSpend: spend, nextMilestone: this.state().milestones.find((item) => item.state !== "completed")?.title ?? "Your next chapter" };
  }
}
