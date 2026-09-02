import { randomUUID } from "node:crypto";

import type { ApprovalDecision } from "./types.js";

interface PendingApproval {
  jobId: string;
  resolve: (decision: ApprovalDecision) => void;
  reject: (error: Error) => void;
}

export class ApprovalBroker {
  readonly #pending = new Map<string, PendingApproval>();

  request(jobId: string, action: string, announce: (approvalId: string, action: string) => void): Promise<ApprovalDecision> {
    const approvalId = randomUUID();
    return new Promise<ApprovalDecision>((resolve, reject) => {
      this.#pending.set(approvalId, { jobId, resolve, reject });
      announce(approvalId, action);
    });
  }

  decide(jobId: string, decision: ApprovalDecision): void {
    const pending = this.#pending.get(decision.approvalId);
    if (!pending || pending.jobId !== jobId) throw new Error("Approval is not pending for this job");
    this.#pending.delete(decision.approvalId);
    pending.resolve(decision);
  }

  cancelJob(jobId: string): void {
    for (const [approvalId, pending] of this.#pending) {
      if (pending.jobId !== jobId) continue;
      this.#pending.delete(approvalId);
      pending.reject(new Error("Job was cancelled"));
    }
  }
}
