import type { JourneyStore } from "./journey.js";

export interface JobSpec {
  jobId: string;
  employeeId: string;
  projectId: string;
  title: string;
  assignment: string;
  acceptanceCriteria: string[];
  tokenBudget: number;
  attachedStudioPath?: string;
  milestoneId?: string;
  revisionOfJobId?: string;
}

export interface ApprovalDecision {
  approvalId: string;
  approved: boolean;
  reason?: string;
}

export type WorkerEvent =
  | { type: "job.queued"; reason: string }
  | { type: "job.started" }
  | { type: "agent.thinking"; summary?: string }
  | { type: "tool.started"; tool: string; label: string }
  | { type: "tool.completed"; tool: string; ok: boolean }
  | { type: "approval.required"; approvalId: string; action: string }
  | { type: "artifact.created"; artifactId: string; name: string }
  | { type: "usage.updated"; inputTokens: number; outputTokens: number; cost?: number }
  | { type: "job.blocked"; reason: string }
  | { type: "job.completed"; summary: string }
  | { type: "job.failed"; error: string };

export interface Artifact {
  artifactId: string;
  jobId: string;
  name: string;
  relativePath: string;
  mediaType: string;
  createdAt: string;
}

export interface ArtifactContent {
  jobId: string;
  name: string;
  relativePath: string;
  mediaType: string;
  content: string;
}

export interface EmployeeMemory {
  kind: "assignment" | "artifacts" | "outcome";
  fact: string;
  workOrderId: string;
  payload: Record<string, unknown>;
  createdAt: string;
}

export interface ChatMessage {
  messageId: string;
  employeeId: string;
  sender: "player" | "employee";
  content: string;
  createdAt: string;
  inputTokens: number;
  outputTokens: number;
  cost?: number;
}

export interface ChatReply {
  message: ChatMessage;
  dailySpend: number;
}

export interface TeammateHandoff {
  jobId: string;
  employeeName: string;
  title: string;
  summary: string;
  artifactPaths: string[];
}

export type SchedulePhase = "work" | "lunch" | "off";

export interface ClockState {
  day: number;
  minuteOfDay: number;
  speed: number;
  phase: SchedulePhase;
}

export interface StudioFile {
  name: string;
  relativePath: string;
  mediaType: string;
  sourceJobId: string;
  sourceArtifactId: string;
  promotedAt: string;
}

export interface StudioFileContent extends StudioFile {
  content: string;
}

export interface WorkOrderSummary {
  jobId: string;
  employeeId: string;
  title: string;
  status: string;
  summary?: string;
  createdAt: string;
  finishedAt?: string;
  inputTokens?: number;
  outputTokens?: number;
  cost?: number;
}

export interface PromotionCandidate {
  jobId: string;
  employeeId: string;
  employeeName: string;
  title: string;
  artifacts: Artifact[];
  finishedAt?: string;
}

export interface PromotionResult {
  studioFiles: StudioFile[];
  pendingPromotions: PromotionCandidate[];
}

export interface Employee {
  id: string;
  name: string;
  deskX: number;
  deskY: number;
  schedule: Record<string, string>;
  relationships: Record<string, number>;
  morale: number;
  assignment?: string;
}

export interface WorkerAdapter {
  startJob(spec: JobSpec): Promise<void>;
  resumeJob(jobId: string): Promise<void>;
  steer(jobId: string, message: string): Promise<void>;
  approve(jobId: string, decision: ApprovalDecision): Promise<void>;
  cancel(jobId: string): Promise<void>;
  events(jobId: string): AsyncIterable<WorkerEvent>;
  artifacts(jobId: string): Promise<Artifact[]>;
  readArtifact(jobId: string, relativePath: string): Promise<ArtifactContent>;
  promoteArtifacts(jobId: string, approved: boolean): Promise<PromotionResult>;
  studioFiles(): Promise<StudioFile[]>;
  readStudioFile(relativePath: string): Promise<StudioFileContent>;
  chatHistory(employeeId: string): Promise<ChatMessage[]>;
  sendChat(employeeId: string, message: string): Promise<ChatReply>;
}

export type ProtocolMethod =
  | "health"
  | "bootstrap"
  | "furnishing.update"
  | "story.travel" | "story.acceptOpportunity"
  | "credential.status"
  | "credential.set"
  | "credential.grok.login.start"
  | "credential.grok.login.poll"
  | "credential.grok.login.cancel"
  | "credential.grok.logout"
  | "credential.grok.use_local"
  | "chat.history"
  | "chat.send"
  | "job.start"
  | "job.resume"
  | "job.steer"
  | "job.approve"
  | "job.cancel"
  | "job.artifacts"
  | "job.remember"
  | "job.promote"
  | "artifact.read"
  | "studio.files"
  | "studio.read"
  | "clock.set"
  | "hiring.complete" | "milestone.evaluate" | "milestone.complete" | "milestone.override"
  | "chapter.continue"
  | "day.end" | "game.save" | "game.new"
  | "tycoon.start" | "tycoon.release" | "tycoon.train" | "tycoon.research" | "tycoon.buyUpgrade" | "tycoon.expandOffice" | "tycoon.acceptContract" | "tycoon.patch" | "tycoon.sequel" | "tycoon.award" | "tycoon.port" | "tycoon.localize" | "tycoon.buyEngine" | "tycoon.takeLoan" | "tycoon.signPublisher" | "tycoon.bookBooth" | "tycoon.takeTownDay" | "tycoon.showPressDemo" | "tycoon.makeTrailer" | "tycoon.writeDiary" | "tycoon.addFeature" | "tycoon.setDayPlan" | "tycoon.fixBugs" | "tycoon.crunch" | "tycoon.earlyAccess" | "tycoon.cancelBuild" | "tycoon.slipDay" | "tycoon.pivot" | "tycoon.playtest" | "tycoon.assignTeam" | "tycoon.researchSpike" | "tycoon.salePrice" | "tycoon.letGo" | "tycoon.setPace" | "tycoon.listCatalog" | "tycoon.delistCatalog" | "tycoon.giveRaise" | "tycoon.offerProfitShare";

export interface ProtocolRequest {
  kind: "request";
  id: string;
  method: ProtocolMethod;
  params: Record<string, unknown>;
}

export interface ProtocolResponse {
  kind: "response";
  id: string;
  ok: boolean;
  result?: unknown;
  error?: string;
}

export interface ProtocolEvent {
  kind: "event";
  jobId: string;
  event: WorkerEvent;
}

export interface BootstrapState {
  furnishing: import("./furnishing-core.js").FurnishingState;
  journey: ReturnType<JourneyStore["state"]> & { daySummary?: ReturnType<JourneyStore["daySummary"]> };
  employees: Employee[];
  project: { id: string; name: string; rootPath: string };
  defaultTokenBudget: number;
  dailySpend: number;
  dailySpendWarning: number;
  clock: ClockState;
  studioFiles: StudioFile[];
  pendingPromotions: PromotionCandidate[];
  recentJobs: WorkOrderSummary[];
  memories: Record<string, EmployeeMemory[]>;
}
