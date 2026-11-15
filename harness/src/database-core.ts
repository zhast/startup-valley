import { normalizeClock, phaseForMinute } from "./day-clock.js";
import { JourneyStore } from "./journey.js";
import { StoryStore } from "./story.js";
import { FurnishingGeometry, FurnishingStore, type GeometryData, type FurnishingState } from "./furnishing-core.js";
import type { SqlDatabase } from "./sql-database.js";
import { legacyResearchJson, starterResearchJson, TycoonStore } from "./tycoon.js";
import type {
  Artifact,
  BootstrapState,
  ChatMessage,
  ClockState,
  Employee,
  EmployeeMemory,
  JobSpec,
  PromotionCandidate,
  StudioFile,
  TeammateHandoff,
  WorkOrderSummary,
  WorkerEvent,
} from "./types.js";

interface EmployeeRow {
  id: string;
  name: string;
  desk_x: number;
  desk_y: number;
  schedule_json: string;
  relationships_json: string;
  morale: number;
  assignment: string | null;
}

interface ArtifactRow {
  id: string;
  work_order_id: string;
  name: string;
  relative_path: string;
  media_type: string;
  created_at: string;
}

interface WorkOrderRow {
  id: string;
  employee_id: string;
  project_id: string;
  title: string;
  assignment: string;
  acceptance_criteria_json: string;
  token_budget: number;
  input_tokens: number;
  output_tokens: number;
  cost: number | null;
  status: string;
  summary: string | null;
  created_at: string;
  finished_at: string | null;
  attached_studio_path: string | null;
  promotion_status: "none" | "pending" | "approved" | "discarded";
  milestone_id: string | null;
  revision_of_job_id: string | null;
}

interface MemoryRow {
  kind: "assignment" | "artifacts" | "outcome";
  fact: string;
  work_order_id: string;
  payload_json: string;
  created_at: string;
}

interface StudioFileRow {
  relative_path: string;
  name: string;
  media_type: string;
  source_work_order_id: string;
  source_artifact_id: string;
  promoted_at: string;
}

interface ChatMessageRow {
  id: string;
  employee_id: string;
  sender: "player" | "employee";
  content: string;
  input_tokens: number;
  output_tokens: number;
  cost: number | null;
  created_at: string;
}

const DEFAULT_PROJECT_ID = "company";
const DEFAULT_TOKEN_BUDGET = 12_000;
const DAILY_SPEND_WARNING = 5;

function now(): string {
  return new Date().toISOString();
}

function parseObject<T>(value: string): T {
  return JSON.parse(value) as T;
}

export interface DatabaseResources {
  migrations: Record<string, string>;
  geometryData: GeometryData;
  parseFurnishingState: (value: unknown) => FurnishingState;
  hash: (value: string) => string;
}

export class GameDatabase {
  readonly journey: JourneyStore;
  readonly furnishing: FurnishingStore;
  readonly tycoon: TycoonStore;
  readonly story: StoryStore;
  readonly #database: SqlDatabase;
  readonly #projectRoot: string;

  constructor(database: SqlDatabase, projectRoot: string, resources: DatabaseResources) {
    this.#database = database;
    this.#projectRoot = projectRoot;
    const migration = (name: string): string => {
      const sql = resources.migrations[name];
      if (!sql) throw new Error(`Missing database migration: ${name}`);
      return sql;
    };
    this.#database.exec(migration("001_initial.sql"));
    this.#database.exec("CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)");
    const existingCompany = this.#database.prepare("SELECT version FROM schema_migrations LIMIT 1").get() !== undefined
      || this.#database.prepare("SELECT id FROM projects LIMIT 1").get() !== undefined;
    // A save that already recorded a schema version predates research and keeps the full catalog.
    const researchPredates = this.#database.prepare("SELECT version FROM schema_migrations WHERE version < 11 LIMIT 1").get() !== undefined;
    for (const [version, name] of [
      [2, "002_product_layer.sql"],
      [3, "003_persistent_studio.sql"],
      [4, "004_work_order_handoff.sql"],
      [5, "005_employee_chat.sql"],
      [6, "006_company_journey.sql"],
      [7, "007_furnishing.sql"],
      [8, "008_company_journey_opening.sql"],
      [9, "009_tycoon_products.sql"],
      [10, "010_tycoon_staff.sql"],
      [11, "011_tycoon_research.sql"],
      [12, "012_tycoon_upgrades.sql"],
      [13, "013_tycoon_office.sql"],
      [14, "014_tycoon_contracts.sql"],
      [15, "015_tycoon_engines.sql"],
      [16, "016_payroll_debt.sql"],
      [17, "017_office_layout.sql"],
      [18, "018_courtyard_story.sql"],
      [19, "019_furniture_registration.sql"],
    ] as const) {
      const applied = this.#database.prepare("SELECT version FROM schema_migrations WHERE version = ?").get(version);
      if (applied) continue;
      this.#database.exec("BEGIN IMMEDIATE");
      try {
        this.#database.exec(migration(name));
        if (version === 17 && !existingCompany) {
          this.#database.prepare("UPDATE office_layout_state SET layout_id='starter-cottage-v1' WHERE id=1").run();
        }
        if (version === 11) {
          this.#database.prepare("UPDATE tycoon_meta SET research_points = 0, research_json = ? WHERE id = 1").run(
            researchPredates ? legacyResearchJson() : starterResearchJson(),
          );
        }
        this.#database.prepare("INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)").run(version, now());
        this.#database.exec("COMMIT");
      } catch (error) {
        this.#database.exec("ROLLBACK");
        throw error;
      }
    }
    this.#seed();
    this.furnishing = new FurnishingStore(this.#database, new FurnishingGeometry(resources.geometryData), resources.parseFurnishingState, resources.hash);
    this.journey = new JourneyStore(this.#database, () => this.furnishing.sync());
    this.tycoon = new TycoonStore(this.#database, this.journey, () => this.furnishing.sync(), (id, topic, type) => this.story.productStarted(id, topic, type));
    this.story = new StoryStore(this.#database, this.journey, this.furnishing, () => this.tycoon.unlockStoryResearch("reselling", "template_pack"));
    this.journey.bindStory(() => this.story.view());
    this.journey.bindTycoon(() => this.tycoon.view());
    this.recoverInterruptedJobs();
  }

  close(): void {
    this.#database.exec("PRAGMA wal_checkpoint(TRUNCATE)");
    this.#database.close();
  }

  #seed(): void {
    const timestamp = now();
    this.#database
      .prepare("INSERT OR IGNORE INTO projects (id, name, root_path, created_at) VALUES (?, ?, ?, ?)")
      .run(DEFAULT_PROJECT_ID, "Startup Valley Studio", this.#projectRoot, timestamp);

    const insertEmployee = this.#database.prepare(`
      INSERT OR IGNORE INTO employees
        (id, name, desk_x, desk_y, schedule_json, relationships_json, morale, assignment, created_at, updated_at, employment_status)
      VALUES (?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, 'candidate')
    `);
    insertEmployee.run(
      "mira",
      "Mina",
      8,
      5,
      JSON.stringify({ weekday: "08:00-17:30", lunch: "12:30-13:30" }),
      JSON.stringify({ theo: 12 }),
      82,
      timestamp,
      timestamp,
    );
    this.#database.prepare("UPDATE employees SET name = 'Mina', updated_at = ? WHERE id = 'mira' AND name <> 'Mina'").run(timestamp);
    insertEmployee.run(
      "theo",
      "Theo",
      14,
      8,
      JSON.stringify({ weekday: "08:00-17:30", lunch: "12:30-13:30" }),
      JSON.stringify({ mira: 12 }),
      76,
      timestamp,
      timestamp,
    );
    insertEmployee.run(
      "creative",
      "Creative",
      14,
      8,
      JSON.stringify({ weekday: "08:00-17:30", lunch: "12:30-13:30" }),
      JSON.stringify({ mira: 8, theo: 8 }),
      80,
      timestamp,
      timestamp,
    );
    this.#database.prepare(`
      UPDATE employees
      SET schedule_json = ?, updated_at = ?
      WHERE schedule_json IN (?, ?)
    `).run(
      JSON.stringify({ weekday: "08:00-17:30", lunch: "12:30-13:30" }),
      timestamp,
      JSON.stringify({ weekday: "09:00-17:00" }),
      JSON.stringify({ weekday: "10:00-18:00" }),
    );
  }

  bootstrap(): BootstrapState {
    const furnishing = this.furnishing.state();
    const rows = this.#database.prepare("SELECT * FROM employees WHERE employment_status='hired' ORDER BY name").all() as unknown as EmployeeRow[];
    const memories: Record<string, EmployeeMemory[]> = {};
    for (const row of rows) memories[row.id] = this.employeeMemories(row.id);
    return {
      employees: rows.map((row) => this.#employeeFromRow(row)),
      project: { id: DEFAULT_PROJECT_ID, name: "Startup Valley Studio", rootPath: this.#projectRoot },
      defaultTokenBudget: DEFAULT_TOKEN_BUDGET,
      dailySpend: this.dailySpend(),
      dailySpendWarning: DAILY_SPEND_WARNING,
      clock: this.clockState(),
      studioFiles: this.studioFiles(),
      pendingPromotions: this.pendingPromotions(),
      recentJobs: this.recentWorkOrders(),
      memories,
      furnishing,
      journey: { ...this.journey.state(), daySummary: this.journey.daySummary(this.clockState().day, this.dailySpend()) },
    };
  }

  #employeeFromRow(row: EmployeeRow): Employee {
    const base: Employee = {
      id: row.id,
      name: row.name,
      deskX: row.desk_x,
      deskY: row.desk_y,
      schedule: parseObject<Record<string, string>>(row.schedule_json),
      relationships: parseObject<Record<string, number>>(row.relationships_json),
      morale: row.morale,
    };
    return row.assignment === null ? base : { ...base, assignment: row.assignment };
  }

  employee(employeeId: string): Employee | undefined {
    const row = this.#database.prepare("SELECT * FROM employees WHERE id = ?").get(employeeId) as
      | (EmployeeRow & Record<string, unknown>)
      | undefined;
    return row ? this.#employeeFromRow(row) : undefined;
  }

  chatMessages(employeeId: string, limit = 24): ChatMessage[] {
    const rows = this.#database.prepare(`
      SELECT * FROM (
        SELECT *, rowid AS insertion_order FROM employee_chat_messages
        WHERE employee_id = ?
        ORDER BY created_at DESC, rowid DESC
        LIMIT ?
      ) ORDER BY created_at, insertion_order
    `).all(employeeId, limit) as unknown as ChatMessageRow[];
    return rows.map((row) => ({
      messageId: row.id,
      employeeId: row.employee_id,
      sender: row.sender,
      content: row.content,
      createdAt: row.created_at,
      inputTokens: row.input_tokens,
      outputTokens: row.output_tokens,
      ...(row.cost === null ? {} : { cost: row.cost }),
    }));
  }

  createChatMessage(
    employeeId: string,
    sender: ChatMessage["sender"],
    content: string,
    usage: { inputTokens?: number; outputTokens?: number; cost?: number } = {},
  ): ChatMessage {
    if (!this.employee(employeeId)) throw new Error("Employee does not exist");
    const message: ChatMessage = {
      messageId: globalThis.crypto.randomUUID(),
      employeeId,
      sender,
      content: content.trim().slice(0, 4000),
      createdAt: now(),
      inputTokens: usage.inputTokens ?? 0,
      outputTokens: usage.outputTokens ?? 0,
      ...(usage.cost === undefined ? {} : { cost: Math.max(0, usage.cost) }),
    };
    this.#database.prepare(`
      INSERT INTO employee_chat_messages
        (id, employee_id, sender, content, input_tokens, output_tokens, cost, created_at, game_day)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      message.messageId,
      message.employeeId,
      message.sender,
      message.content,
      message.inputTokens,
      message.outputTokens,
      message.cost ?? null,
      message.createdAt,
      this.clockState().day,
    );
    return message;
  }

  createWorkOrder(spec: JobSpec, status: "queued" | "running" = "running"): void {
    const timestamp = now();
    this.journey.transaction(() => {
    this.#database
      .prepare(`
        INSERT INTO work_orders
          (id, employee_id, project_id, title, assignment, acceptance_criteria_json, status, token_budget, created_at, started_at, attached_studio_path, milestone_id, revision_of_job_id, game_day)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `)
      .run(
        spec.jobId,
        spec.employeeId,
        spec.projectId,
        spec.title,
        spec.assignment,
        JSON.stringify(spec.acceptanceCriteria),
        status,
        spec.tokenBudget,
        timestamp,
        status === "running" ? timestamp : null,
        spec.attachedStudioPath ?? null,
        spec.milestoneId ?? null,
        spec.revisionOfJobId ?? null,
        this.clockState().day,
      );
    this.#database
      .prepare("UPDATE employees SET assignment = ?, updated_at = ? WHERE id = ?")
      .run(spec.assignment, timestamp, spec.employeeId);
    this.journey.attachJob(spec);
    });
  }

  endDay(expectedDay: number) {
    return this.journey.transaction(() => {
      const current = this.clockState();
      const previous = this.#database.prepare("SELECT summary_json FROM day_summaries WHERE day=?").get(expectedDay);
      if (previous) return { clock: current, summary: JSON.parse(String(previous.summary_json)) };
      if (current.day !== expectedDay) throw new Error("Day changed; refresh before ending it");
      const active = this.#database.prepare("SELECT id FROM work_orders WHERE status='running' OR id IN (SELECT work_order_id FROM approvals WHERE status='pending')").get();
      if (active) throw new Error("Finish or cancel active work and approvals before ending the day");
      this.tycoon.tickDay(current.day);
      const summary = this.journey.daySummary(current.day, this.dailySpend());
      this.#database.prepare("INSERT INTO day_summaries VALUES (?,?)").run(current.day, JSON.stringify(summary));
      return { summary, clock: this.setClock(current.day + 1, 480, 1) };
    });
  }

  hasOpenWorkOrder(): boolean {
    const row = this.#database.prepare(`
      SELECT 1 AS found FROM work_orders
      WHERE status IN ('queued', 'running')
      LIMIT 1
    `).get() as { found: number } | undefined;
    return row !== undefined;
  }

  nextQueuedWorkOrder(): (JobSpec & { status: string }) | undefined {
    const row = this.#database.prepare(`
      SELECT id FROM work_orders WHERE status = 'queued'
      ORDER BY created_at, id LIMIT 1
    `).get() as { id: string } | undefined;
    return row ? this.workOrder(row.id) : undefined;
  }

  recentWorkOrders(limit = 8): WorkOrderSummary[] {
    const rows = this.#database.prepare(`
      SELECT * FROM work_orders ORDER BY created_at DESC, id DESC LIMIT ?
    `).all(limit) as unknown as WorkOrderRow[];
    return rows.map((row) => ({
      jobId: row.id,
      employeeId: row.employee_id,
      title: row.title,
      status: row.status,
      ...(row.summary ? { summary: row.summary } : {}),
      createdAt: row.created_at,
      ...(row.finished_at ? { finishedAt: row.finished_at } : {}),
      inputTokens: row.input_tokens,
      outputTokens: row.output_tokens,
      ...(row.cost === null ? {} : { cost: row.cost }),
    }));
  }

  workOrder(jobId: string): (JobSpec & { status: string }) | undefined {
    const row = this.#database.prepare("SELECT * FROM work_orders WHERE id = ?").get(jobId) as
      | (WorkOrderRow & Record<string, unknown>)
      | undefined;
    if (!row) return undefined;
    return {
      jobId: row.id,
      employeeId: row.employee_id,
      projectId: row.project_id,
      title: row.title,
      assignment: row.assignment,
      acceptanceCriteria: parseObject<string[]>(row.acceptance_criteria_json),
      tokenBudget: row.token_budget,
      ...(row.attached_studio_path ? { attachedStudioPath: row.attached_studio_path } : {}),
      ...(row.milestone_id ? { milestoneId: row.milestone_id } : {}),
      ...(row.revision_of_job_id ? { revisionOfJobId: row.revision_of_job_id } : {}),
      status: row.status,
    };
  }

  setWorkOrderStatus(jobId: string, status: "running" | "blocked" | "completed" | "failed" | "cancelled"): void {
    const terminal = status === "blocked" || status === "completed" || status === "failed" || status === "cancelled";
    this.#database
      .prepare(`
        UPDATE work_orders
        SET status = ?,
            started_at = CASE WHEN ? = 'running' THEN COALESCE(started_at, ?) ELSE started_at END,
            finished_at = ?
        WHERE id = ?
      `)
      .run(status, status, now(), terminal ? now() : null, jobId);
    if (status === "running") {
      this.#database.prepare(`
        UPDATE employees
        SET assignment = (SELECT assignment FROM work_orders WHERE id = ?), updated_at = ?
        WHERE id = (SELECT employee_id FROM work_orders WHERE id = ?)
      `).run(jobId, now(), jobId);
    }
    if (terminal) {
      this.#database.prepare("UPDATE approvals SET status='denied',reason='Work order ended before a decision',decided_at=? WHERE work_order_id=? AND status='pending'").run(now(), jobId);
      this.#database.prepare(`
        UPDATE employees SET assignment = NULL, updated_at = ?
        WHERE id = (SELECT employee_id FROM work_orders WHERE id = ?)
      `).run(now(), jobId);
    }
  }

  clockState(): ClockState {
    const row = this.#database.prepare("SELECT value_json FROM game_state WHERE key = 'clock'").get() as
      | { value_json: string }
      | undefined;
    if (!row) return normalizeClock({});
    try {
      return normalizeClock(parseObject<Partial<ClockState>>(row.value_json));
    } catch {
      return normalizeClock({});
    }
  }

  setClock(day: number, minuteOfDay: number, speed: number): ClockState {
    const clock = normalizeClock({ day, minuteOfDay, speed });
    this.#database.prepare(`
      INSERT INTO game_state (key, value_json, updated_at)
      VALUES ('clock', ?, ?)
      ON CONFLICT(key) DO UPDATE SET value_json = excluded.value_json, updated_at = excluded.updated_at
    `).run(JSON.stringify(clock), now());
    return clock;
  }

  isWorkWindow(): boolean {
    return phaseForMinute(this.clockState().minuteOfDay) === "work";
  }

  completeWorkOrder(jobId: string, summary: string): void {
    this.#database.prepare("UPDATE work_orders SET summary = ? WHERE id = ?").run(summary.replace(/\s+/gu, " ").trim().slice(0, 1000), jobId);
    this.setWorkOrderStatus(jobId, "completed");
    this.#database.prepare(`
      UPDATE work_orders
      SET promotion_status = CASE
        WHEN EXISTS (SELECT 1 FROM artifacts WHERE artifacts.work_order_id = work_orders.id) THEN 'pending'
        ELSE 'none'
      END
      WHERE id = ?
    `).run(jobId);
  }

  recoverInterruptedJobs(): string[] {
    const rows = this.#database.prepare("SELECT id FROM work_orders WHERE status = 'running'").all() as unknown as { id: string }[];
    for (const row of rows) {
      this.setWorkOrderStatus(row.id, "failed");
      this.recordEvent(row.id, { type: "job.failed", error: "Worker exited before the work order completed" });
    }
    this.#database.prepare("UPDATE approvals SET status='denied',reason='Recovered ended work order',decided_at=? WHERE status='pending' AND work_order_id IN (SELECT id FROM work_orders WHERE status NOT IN ('running','queued'))").run(now());
    return rows.map((row) => row.id);
  }

  recordEvent(jobId: string, event: WorkerEvent): void {
    const sequenceRow = this.#database
      .prepare("SELECT COALESCE(MAX(sequence), 0) + 1 AS next_sequence FROM worker_events WHERE work_order_id = ?")
      .get(jobId) as { next_sequence: number };
    this.#database
      .prepare(`
        INSERT INTO worker_events (work_order_id, sequence, type, payload_json, created_at)
        VALUES (?, ?, ?, ?, ?)
      `)
      .run(jobId, sequenceRow.next_sequence, event.type, JSON.stringify(event), now());
  }

  recordUsage(jobId: string, inputTokens: number, outputTokens: number, cost?: number): void {
    this.#database
      .prepare("UPDATE work_orders SET input_tokens = ?, output_tokens = ?, cost = ?, game_day = ? WHERE id = ?")
      .run(inputTokens, outputTokens, cost ?? null, this.clockState().day, jobId);
  }

  createArtifact(jobId: string, artifact: Artifact): void {
    this.#database
      .prepare(`
        INSERT INTO artifacts (id, work_order_id, name, relative_path, media_type, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(work_order_id, relative_path) DO UPDATE SET
          id = excluded.id,
          name = excluded.name,
          media_type = excluded.media_type,
          created_at = excluded.created_at
      `)
      .run(
        artifact.artifactId,
        jobId,
        artifact.name,
        artifact.relativePath,
        artifact.mediaType,
        artifact.createdAt,
      );
  }

  artifacts(jobId: string): Artifact[] {
    const rows = this.#database
      .prepare("SELECT * FROM artifacts WHERE work_order_id = ? ORDER BY created_at, name")
      .all(jobId) as unknown as ArtifactRow[];
    return rows.map((row) => ({
      artifactId: row.id,
      jobId: row.work_order_id,
      name: row.name,
      relativePath: row.relative_path,
      mediaType: row.media_type,
      createdAt: row.created_at,
    }));
  }

  upsertStudioFile(file: StudioFile): void {
    this.#database.prepare(`
      INSERT INTO studio_files
        (relative_path, name, media_type, source_work_order_id, source_artifact_id, promoted_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(relative_path) DO UPDATE SET
        name = excluded.name,
        media_type = excluded.media_type,
        source_work_order_id = excluded.source_work_order_id,
        source_artifact_id = excluded.source_artifact_id,
        promoted_at = excluded.promoted_at
    `).run(
      file.relativePath,
      file.name,
      file.mediaType,
      file.sourceJobId,
      file.sourceArtifactId,
      file.promotedAt,
    );
  }

  studioFiles(): StudioFile[] {
    const rows = this.#database.prepare(`
      SELECT * FROM studio_files ORDER BY promoted_at DESC, relative_path
    `).all() as unknown as StudioFileRow[];
    return rows.map((row) => ({
      name: row.name,
      relativePath: row.relative_path,
      mediaType: row.media_type,
      sourceJobId: row.source_work_order_id,
      sourceArtifactId: row.source_artifact_id,
      promotedAt: row.promoted_at,
    }));
  }

  studioFilesForJob(jobId: string): StudioFile[] {
    return this.studioFiles().filter((file) => file.sourceJobId === jobId);
  }

  studioFile(relativePath: string): StudioFile | undefined {
    return this.studioFiles().find((file) => file.relativePath === relativePath);
  }

  pendingPromotions(limit = 8): PromotionCandidate[] {
    const rows = this.#database.prepare(`
      SELECT w.*, e.name AS employee_name
      FROM work_orders w
      JOIN employees e ON e.id = w.employee_id
      WHERE w.status = 'completed' AND w.promotion_status = 'pending'
      ORDER BY w.finished_at DESC, w.created_at DESC
      LIMIT ?
    `).all(limit) as unknown as Array<WorkOrderRow & { employee_name: string }>;
    return rows.map((row) => ({
      jobId: row.id,
      employeeId: row.employee_id,
      employeeName: row.employee_name,
      title: row.title,
      artifacts: this.artifacts(row.id),
      ...(row.finished_at ? { finishedAt: row.finished_at } : {}),
    }));
  }

  decidePromotion(jobId: string, approved: boolean): void {
    const row = this.#database.prepare(`
      SELECT status, promotion_status FROM work_orders WHERE id = ?
    `).get(jobId) as { status: string; promotion_status: string } | undefined;
    if (!row || row.status !== "completed") throw new Error("Only completed work can be promoted or discarded");
    if (row.promotion_status !== "pending") throw new Error("This work order does not have a pending promotion decision");
    this.#database.prepare("UPDATE work_orders SET promotion_status = ? WHERE id = ?")
      .run(approved ? "approved" : "discarded", jobId);
  }

  writebackMemories(jobId: string): EmployeeMemory[] {
    const row = this.#database.prepare("SELECT * FROM work_orders WHERE id = ?").get(jobId) as
      | (WorkOrderRow & Record<string, unknown>)
      | undefined;
    if (!row) throw new Error("Work order does not exist");
    if (row.status !== "completed") throw new Error("Only completed work orders can be remembered");

    const timestamp = now();
    const entries: Array<{ kind: EmployeeMemory["kind"]; fact: string; payload: Record<string, unknown> }> = [
      { kind: "assignment", fact: `Completed assignment: ${row.title}`, payload: { title: row.title } },
    ];
    const artifacts = this.artifacts(jobId);
    const promoted = this.studioFilesForJob(jobId);
    if (artifacts.length > 0) {
      const paths = promoted.length > 0
        ? promoted.slice(0, 20).map((file) => `studio/${file.relativePath}`)
        : artifacts.slice(0, 20).map((artifact) => `jobs/${jobId}/${artifact.relativePath}`);
      entries.push({
        kind: "artifacts",
        fact: `${promoted.length > 0 ? "Delivered studio artifacts" : "Delivered scratch artifacts"}: ${paths.join(", ")}`.slice(0, 1000),
        payload: { names: artifacts.map((artifact) => artifact.name), paths },
      });
    }
    const outcome = (row.summary ?? `Completed ${row.title}.`).replace(/\s+/gu, " ").trim().slice(0, 500);
    entries.push({ kind: "outcome", fact: `Outcome: ${outcome}`, payload: { summary: outcome } });

    const insert = this.#database.prepare(`
      INSERT INTO employee_memories
        (id, employee_id, fact, salience, created_at, kind, work_order_id, payload_json)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(employee_id, work_order_id, kind) DO UPDATE SET
        fact = excluded.fact,
        payload_json = excluded.payload_json,
        created_at = excluded.created_at
    `);
    for (const entry of entries.slice(0, 3)) {
      insert.run(globalThis.crypto.randomUUID(), row.employee_id, entry.fact, 70, timestamp, entry.kind, jobId, JSON.stringify(entry.payload));
    }
    return this.employeeMemories(row.employee_id).filter((memory) => memory.workOrderId === jobId);
  }

  employeeMemories(employeeId: string, limit = 9): EmployeeMemory[] {
    const rows = this.#database.prepare(`
      SELECT kind, fact, work_order_id, payload_json, created_at
      FROM employee_memories
      WHERE employee_id = ? AND work_order_id IS NOT NULL
      ORDER BY created_at DESC, rowid DESC
      LIMIT ?
    `).all(employeeId, limit) as unknown as MemoryRow[];
    return rows.map((row) => ({
      kind: row.kind,
      fact: row.fact,
      workOrderId: row.work_order_id,
      payload: parseObject<Record<string, unknown>>(row.payload_json),
      createdAt: row.created_at,
    }));
  }

  teammateHandoffs(employeeId: string, limit = 4): TeammateHandoff[] {
    const rows = this.#database.prepare(`
      SELECT w.id, w.title, w.summary, e.name AS employee_name
      FROM work_orders w
      JOIN employees e ON e.id = w.employee_id
      WHERE w.status = 'completed' AND w.employee_id <> ?
      ORDER BY w.finished_at DESC, w.created_at DESC
      LIMIT ?
    `).all(employeeId, limit) as unknown as Array<{
      id: string;
      title: string;
      summary: string | null;
      employee_name: string;
    }>;
    return rows.map((row) => ({
      jobId: row.id,
      employeeName: row.employee_name,
      title: row.title,
      summary: (row.summary ?? "Completed without a summary.").replace(/\s+/gu, " ").trim().slice(0, 500),
      artifactPaths: this.studioFilesForJob(row.id).map((file) => `studio/${file.relativePath}`),
    }));
  }

  createApproval(jobId: string, approvalId: string, action: string): void {
    if (this.workOrder(jobId)?.status !== "running") throw new Error("Approval requires a running work order");
    this.#database
      .prepare("INSERT INTO approvals (id, work_order_id, action, status, created_at) VALUES (?, ?, ?, 'pending', ?)")
      .run(approvalId, jobId, action, now());
  }

  decideApproval(approvalId: string, approved: boolean, reason?: string): void {
    this.#database
      .prepare("UPDATE approvals SET status = ?, reason = ?, decided_at = ? WHERE id = ? AND status = 'pending'")
      .run(approved ? "approved" : "denied", reason ?? null, now(), approvalId);
  }

  dailySpend(): number {
    const row = this.#database
      .prepare(`
        SELECT
          COALESCE((SELECT SUM(cost) FROM work_orders WHERE game_day = ?), 0) +
          COALESCE((SELECT SUM(cost) FROM employee_chat_messages WHERE game_day = ?), 0) +
          COALESCE((SELECT SUM(cost) FROM evaluation_usage WHERE game_day = ?), 0)
          AS total
      `)
      .get(this.clockState().day, this.clockState().day, this.clockState().day) as { total: number };
    return row.total;
  }
}
