import { copyFile, mkdir, readFile, stat } from "node:fs/promises";
import { dirname, join } from "node:path";

import type { Credential, CredentialInfo, CredentialStore as PiCredentialStore } from "@earendil-works/pi-ai";
import type { Model } from "@earendil-works/pi-ai/compat";
import {
  createAgentSession,
  DefaultResourceLoader,
  ModelRuntime,
  SessionManager,
  SettingsManager,
  type AgentSession,
  type AgentSessionEvent,
} from "@earendil-works/pi-coding-agent";

import { ApprovalBroker } from "./approval-broker.js";
import type { CredentialStore } from "./credential-store.js";
import type { GameDatabase } from "./database.js";
import { EventStream } from "./event-stream.js";
import { JobPathGuard } from "./path-guard.js";
import { createJobTools } from "./tools.js";
import type { ApprovalDecision, Artifact, ArtifactContent, JobSpec, WorkerAdapter, WorkerEvent } from "./types.js";

const DEFAULT_MODEL_ID = "~openai/gpt-mini-latest";

class EmptyPiCredentialStore implements PiCredentialStore {
  async read(_providerId: string): Promise<Credential | undefined> {
    return undefined;
  }

  async list(): Promise<readonly CredentialInfo[]> {
    return [];
  }

  async modify(
    _providerId: string,
    callback: (current: Credential | undefined) => Promise<Credential | undefined>,
  ): Promise<Credential | undefined> {
    return callback(undefined);
  }

  async delete(_providerId: string): Promise<void> {}
}

function toolLabel(name: string): string {
  return name
    .split("_")
    .map((word) => `${word.slice(0, 1).toLocaleUpperCase()}${word.slice(1)}`)
    .join(" ");
}

function bounded(value: string, limit: number): string {
  return value.length <= limit ? value : `${value.slice(0, limit - 1)}…`;
}

export class PiWorkerAdapter implements WorkerAdapter {
  readonly #database: GameDatabase;
  readonly #credentials: CredentialStore;
  readonly #jobsRoot: string;
  readonly #runtimeRoot: string;
  readonly #streams = new Map<string, EventStream<WorkerEvent>>();
  readonly #sessions = new Map<string, AgentSession>();
  readonly #approvals = new ApprovalBroker();
  readonly #cancelledJobs = new Set<string>();
  #activeJobId: string | undefined;

  constructor(database: GameDatabase, credentials: CredentialStore, dataRoot: string) {
    this.#database = database;
    this.#credentials = credentials;
    this.#jobsRoot = join(dataRoot, "company-project", "jobs");
    this.#runtimeRoot = join(dataRoot, "runtime");
  }

  async startJob(spec: JobSpec): Promise<void> {
    if (this.#activeJobId) throw new Error(`Job ${this.#activeJobId} is already running; v0 permits one concurrent job`);
    if (!this.#database.employee(spec.employeeId)) throw new Error("Employee does not exist");
    this.#database.createWorkOrder(spec);
    const stream = new EventStream<WorkerEvent>();
    this.#streams.set(spec.jobId, stream);
    this.#activeJobId = spec.jobId;
    this.#emit(spec.jobId, { type: "job.started" });
    void this.#runJob(spec);
  }

  async resumeJob(jobId: string): Promise<void> {
    if (this.#activeJobId) throw new Error(`Job ${this.#activeJobId} is already running; v0 permits one concurrent job`);
    const stored = this.#database.workOrder(jobId);
    if (!stored) throw new Error("Work order does not exist");
    const stream = new EventStream<WorkerEvent>();
    this.#streams.set(jobId, stream);
    this.#activeJobId = jobId;
    this.#database.setWorkOrderStatus(jobId, "running");
    this.#emit(jobId, { type: "job.started" });
    void this.#runJob(stored);
  }

  async steer(jobId: string, message: string): Promise<void> {
    const session = this.#sessions.get(jobId);
    if (!session) throw new Error("Job does not have a live Pi session");
    await session.steer(bounded(message.trim(), 2000));
  }

  async approve(jobId: string, decision: ApprovalDecision): Promise<void> {
    this.#approvals.decide(jobId, decision);
    this.#database.decideApproval(decision.approvalId, decision.approved, decision.reason);
    this.#database.setWorkOrderStatus(jobId, "running");
  }

  async cancel(jobId: string): Promise<void> {
    const session = this.#sessions.get(jobId);
    if (this.#activeJobId !== jobId) throw new Error("Job is not active");
    this.#cancelledJobs.add(jobId);
    this.#approvals.cancelJob(jobId);
    this.#database.setWorkOrderStatus(jobId, "cancelled");
    this.#emit(jobId, { type: "job.failed", error: "Cancelled by player" });
    if (session) await session.abort();
  }

  events(jobId: string): AsyncIterable<WorkerEvent> {
    const stream = this.#streams.get(jobId);
    if (!stream) throw new Error("Job event stream does not exist");
    return stream;
  }

  async artifacts(jobId: string): Promise<Artifact[]> {
    return this.#database.artifacts(jobId);
  }

  async readArtifact(jobId: string, relativePath: string): Promise<ArtifactContent> {
    const artifact = this.#database.artifacts(jobId).find((candidate) => candidate.relativePath === relativePath);
    if (!artifact) throw new Error("Artifact does not exist");
    if (!artifact.mediaType.startsWith("text/") && artifact.mediaType !== "application/json") {
      throw new Error("The in-game viewer only opens text artifacts");
    }
    const guard = new JobPathGuard(join(this.#jobsRoot, jobId));
    await guard.initialize();
    const target = await guard.resolve(relativePath);
    const metadata = await stat(target);
    if (!metadata.isFile() || metadata.size > 200_000) throw new Error("Artifact is not a readable text file");
    return { ...artifact, content: await readFile(target, "utf8") };
  }

  #emit(jobId: string, event: WorkerEvent): void {
    this.#database.recordEvent(jobId, event);
    this.#streams.get(jobId)?.push(event);
  }

  #finish(jobId: string): void {
    this.#sessions.delete(jobId);
    this.#cancelledJobs.delete(jobId);
    this.#streams.get(jobId)?.close();
    if (this.#activeJobId === jobId) this.#activeJobId = undefined;
  }

  systemPromptFor(spec: JobSpec): string {
    const employee = this.#database.employee(spec.employeeId);
    if (!employee) throw new Error("Employee was removed before the job started");
    const criteria = spec.acceptanceCriteria.map((criterion, index) => `${index + 1}. ${bounded(criterion, 500)}`).join("\n");
    const memories = this.#database.employeeMemories(spec.employeeId, 9);
    const handoffs = this.#database.teammateHandoffs(spec.employeeId, 4);
    const memoryContext = memories.length > 0
      ? memories.map((memory) => `- [${memory.kind}] ${bounded(memory.fact, 700)}`).join("\n")
      : "- No persistent memories yet.";
    const handoffContext = handoffs.length > 0
      ? handoffs.map((handoff) => {
          const paths = handoff.artifactPaths.length > 0
            ? handoff.artifactPaths.map((path) => `${path} (readable copy: handoffs/${handoff.jobId}/${path.split(`/`).slice(2).join(`/`)})`).join(", ")
            : "none";
          return `- ${handoff.employeeName}: ${bounded(handoff.title, 200)}\n  Summary: ${bounded(handoff.summary, 500)}\n  Artifacts: ${paths}`;
        }).join("\n")
      : "- No teammate deliveries yet.";
    return `You are ${employee.name}, an AI employee in Startup Valley Studio. Morale: ${employee.morale}/100.

You are completing one bounded work order. Use only the supplied tools. You have no shell, package installer, browser automation, hidden credentials, or access outside this job workspace. Never claim that a file exists unless a tool successfully created or read it. Prefer the smallest complete deliverable.

Work order title:
${bounded(spec.title, 200)}

Assignment:
${bounded(spec.assignment, 4000)}

Acceptance criteria:
${criteria}

Persistent memories for this employee (structured game records, not a transcript):
${memoryContext}

Recent teammate deliveries from SQLite (not a shared transcript):
${handoffContext}

When the requested work is complete, give a concise delivery summary. The game records files written by tools as artifacts.`;
  }

  async #stageHandoffs(spec: JobSpec, jobRoot: string): Promise<void> {
    const destinationGuard = new JobPathGuard(jobRoot);
    await destinationGuard.initialize();
    for (const handoff of this.#database.teammateHandoffs(spec.employeeId, 4)) {
      const sourceGuard = new JobPathGuard(join(this.#jobsRoot, handoff.jobId));
      try {
        await sourceGuard.initialize();
      } catch {
        continue;
      }
      for (const artifact of this.#database.artifacts(handoff.jobId)) {
        try {
          const source = await sourceGuard.resolve(artifact.relativePath);
          const destination = await destinationGuard.resolve(`handoffs/${handoff.jobId}/${artifact.relativePath}`, true);
          await mkdir(dirname(destination), { recursive: true });
          await copyFile(source, destination);
        } catch {
          // A missing historical artifact should not prevent a new bounded work order.
        }
      }
    }
  }

  async #runJob(spec: JobSpec): Promise<void> {
    let session: AgentSession | undefined;
    let unsubscribe: (() => void) | undefined;
    let exceededBudget = false;
    try {
      const apiKey = await this.#credentials.getOpenRouterKey();
      if (this.#cancelledJobs.has(spec.jobId)) return;
      if (!apiKey) {
        this.#database.setWorkOrderStatus(spec.jobId, "blocked");
        this.#emit(spec.jobId, { type: "job.blocked", reason: "Add an OpenRouter key before assigning work" });
        return;
      }

      const jobRoot = join(this.#jobsRoot, spec.jobId);
      const agentDirectory = join(this.#runtimeRoot, "pi");
      await Promise.all([mkdir(jobRoot, { recursive: true }), mkdir(agentDirectory, { recursive: true })]);
      await this.#stageHandoffs(spec, jobRoot);

      const modelRuntime = await ModelRuntime.create({
        credentials: new EmptyPiCredentialStore(),
        modelsPath: null,
        refreshOnCreate: false,
      });
      await modelRuntime.setRuntimeApiKey("openrouter", apiKey);
      const model = modelRuntime.getModel("openrouter", DEFAULT_MODEL_ID);
      if (!model) throw new Error(`Pi does not provide the configured OpenRouter model: ${DEFAULT_MODEL_ID}`);
      const cappedModel: Model<any> = { ...model, maxTokens: Math.min(model.maxTokens, spec.tokenBudget) };

      const tools = await createJobTools({
        jobId: spec.jobId,
        jobRoot,
        approvalBroker: this.#approvals,
        onArtifact: (artifact) => {
          this.#database.createArtifact(spec.jobId, artifact);
          this.#emit(spec.jobId, { type: "artifact.created", artifactId: artifact.artifactId, name: artifact.name });
        },
        onApproval: (approvalId, action) => {
          this.#database.createApproval(spec.jobId, approvalId, action);
          this.#database.setWorkOrderStatus(spec.jobId, "blocked");
          this.#emit(spec.jobId, { type: "approval.required", approvalId, action });
        },
      });

      const settingsManager = SettingsManager.inMemory();
      const resourceLoader = new DefaultResourceLoader({
        cwd: jobRoot,
        agentDir: agentDirectory,
        settingsManager,
        noExtensions: true,
        noSkills: true,
        noPromptTemplates: true,
        noThemes: true,
        noContextFiles: true,
        systemPrompt: this.systemPromptFor(spec),
      });
      await resourceLoader.reload();
      const created = await createAgentSession({
        cwd: jobRoot,
        agentDir: agentDirectory,
        model: cappedModel,
        modelRuntime,
        thinkingLevel: "low",
        noTools: "all",
        tools: tools.map((tool) => tool.name),
        customTools: tools,
        resourceLoader,
        settingsManager,
        sessionManager: SessionManager.inMemory(jobRoot),
      });
      session = created.session;
      this.#sessions.set(spec.jobId, session);
      unsubscribe = session.subscribe((event) => {
        exceededBudget = this.#handlePiEvent(spec, session as AgentSession, event) || exceededBudget;
      });

      await session.prompt(spec.assignment);
      if (this.#cancelledJobs.has(spec.jobId)) return;
      if (exceededBudget) {
        this.#database.setWorkOrderStatus(spec.jobId, "blocked");
        this.#emit(spec.jobId, { type: "job.blocked", reason: `Token budget of ${spec.tokenBudget} was reached` });
        return;
      }
      const lastMessage = session.state.messages.at(-1);
      if (lastMessage?.role === "assistant" && lastMessage.stopReason === "error") {
        throw new Error(lastMessage.errorMessage ?? "OpenRouter request failed");
      }
      if (this.#database.artifacts(spec.jobId).length === 0) {
        throw new Error("The agent finished without creating a deliverable artifact");
      }
      const summary = bounded(session.getLastAssistantText() ?? "Work order completed.", 4000);
      this.#database.completeWorkOrder(spec.jobId, summary);
      this.#emit(spec.jobId, { type: "job.completed", summary });
    } catch (error) {
      if (this.#cancelledJobs.has(spec.jobId)) return;
      const message = bounded(error instanceof Error ? error.message : String(error), 4000);
      this.#database.setWorkOrderStatus(spec.jobId, "failed");
      this.#emit(spec.jobId, { type: "job.failed", error: message });
    } finally {
      unsubscribe?.();
      session?.dispose();
      this.#finish(spec.jobId);
    }
  }

  #handlePiEvent(spec: JobSpec, session: AgentSession, event: AgentSessionEvent): boolean {
    switch (event.type) {
      case "agent_start":
        this.#emit(spec.jobId, { type: "agent.thinking", summary: "Planning the work order." });
        break;
      case "tool_execution_start":
        this.#emit(spec.jobId, { type: "tool.started", tool: event.toolName, label: toolLabel(event.toolName) });
        break;
      case "tool_execution_end":
        this.#emit(spec.jobId, { type: "tool.completed", tool: event.toolName, ok: !event.isError });
        break;
      case "message_end": {
        const stats = session.getSessionStats();
        const usage: WorkerEvent = {
          type: "usage.updated",
          inputTokens: stats.tokens.input,
          outputTokens: stats.tokens.output,
          cost: Math.max(0, stats.cost),
        };
        this.#database.recordUsage(spec.jobId, usage.inputTokens, usage.outputTokens, usage.cost);
        this.#emit(spec.jobId, usage);
        if (stats.tokens.input + stats.tokens.output >= spec.tokenBudget) {
          void session.abort();
          return true;
        }
        break;
      }
      default:
        break;
    }
    return false;
  }
}
