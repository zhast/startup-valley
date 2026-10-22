import type { DatabaseSync } from "node:sqlite";

import { JourneyStore } from "./journey.js";

/**
 * Authoritative offline tycoon rules. Gameplay never calls a model provider,
 * the network, or a credential. Reviews and sales are pure functions of the
 * saved seed, the product, and the points earned on office days.
 */

export const DEFAULT_TYCOON_SEED = 26021;
export const SALES_WINDOW_DAYS = 4;
export const EXTRA_POLISH_DAYS = 2;
export const TRAIN_COST_PER_LEVEL_CENTS = 15000;
export const STAT_CAP = 10;
export const STATS = ["design", "tech", "hype"] as const;
const IDEAL_POINTS_PER_DAY = 4;

export const TOPICS = [
  { id: "fitness", name: "Fitness" },
  { id: "trading", name: "Trading" },
  { id: "sneakers", name: "Sneakers" },
  { id: "reselling", name: "Reselling" },
  { id: "sports_betting", name: "Sports Betting Picks" },
  { id: "cooking", name: "Cooking" },
  { id: "gaming", name: "Gaming" },
  { id: "dating", name: "Dating Advice" },
  { id: "study_notes", name: "Study Notes" },
  { id: "crypto", name: "Crypto Alpha" },
] as const;

export const PRODUCT_TYPES = [
  { id: "course", name: "Course", devDays: 3, design: 3, tech: 1, hype: 2, priceCents: 4900 },
  { id: "community", name: "Community", devDays: 3, design: 2, tech: 1, hype: 3, priceCents: 2900 },
  { id: "template_pack", name: "Template Pack", devDays: 2, design: 2, tech: 3, hype: 1, priceCents: 1900 },
  { id: "coaching", name: "Coaching", devDays: 3, design: 2, tech: 1, hype: 2, priceCents: 7900 },
  { id: "software", name: "Software Tool", devDays: 4, design: 1, tech: 3, hype: 1, priceCents: 3900 },
  { id: "newsletter", name: "Newsletter", devDays: 2, design: 1, tech: 1, hype: 3, priceCents: 900 },
] as const;

export const STAFF = [
  { id: "founder", name: "Founder", design: 2, tech: 2, hype: 2 },
  { id: "mira", name: "Mina", design: 3, tech: 2, hype: 1 },
  { id: "theo", name: "Theo", design: 1, tech: 2, hype: 3 },
  { id: "creative", name: "Creative", design: 4, tech: 1, hype: 2 },
] as const;

export type TopicId = (typeof TOPICS)[number]["id"];
export type ProductTypeId = (typeof PRODUCT_TYPES)[number]["id"];
export type StaffId = (typeof STAFF)[number]["id"];
export type StatId = (typeof STATS)[number];
export type Fit = "great" | "good" | "okay" | "bad";

const FIT_NUMERATOR: Record<Fit, number> = { great: 112, good: 100, okay: 84, bad: 64 };
const FIT_UNITS: Record<Fit, number> = { great: 12, good: 9, okay: 6, bad: 3 };
const SALES_CURVE = [100, 70, 45, 25] as const;

/** Topic × type fit. Rows are topics, columns follow PRODUCT_TYPES order. */
const FIT_ROWS: Record<TopicId, readonly Fit[]> = {
  fitness: ["great", "good", "okay", "great", "bad", "okay"],
  trading: ["good", "okay", "great", "good", "good", "great"],
  sneakers: ["okay", "great", "good", "okay", "bad", "okay"],
  reselling: ["good", "okay", "great", "okay", "okay", "good"],
  sports_betting: ["okay", "great", "bad", "good", "okay", "great"],
  cooking: ["great", "good", "okay", "great", "bad", "good"],
  gaming: ["okay", "great", "good", "okay", "great", "okay"],
  dating: ["good", "great", "bad", "great", "okay", "good"],
  study_notes: ["great", "okay", "great", "good", "okay", "good"],
  crypto: ["okay", "good", "okay", "good", "great", "great"],
};

const REVIEWERS = [
  {
    name: "Whop Weekly",
    blurbs: {
      high: "I would pay before the free trial ended.",
      mid: "Fine if you already trust the creator.",
      low: "This is a vibe and a checkout link.",
    },
  },
  {
    name: "Discord Dave",
    blurbs: {
      high: "Pinned it. The server already bought in.",
      mid: "People will lurk. A few will pay.",
      low: "Even the lurkers left to touch grass.",
    },
  },
  {
    name: "Margin Call Molly",
    blurbs: {
      high: "The margin is rude, in a good way.",
      mid: "It covers costs if nobody refunds out of spite.",
      low: "I would not put my own money in.",
    },
  },
  {
    name: "Cohort Casey",
    blurbs: {
      high: "Completion rate like a cozy streak.",
      mid: "Some lessons land. The rest is nice fonts.",
      low: "I dropped out in the welcome module.",
    },
  },
] as const;

export interface CraftPoints {
  design: number;
  tech: number;
  hype: number;
}

export interface TrainOffer {
  costCents: number;
  enabled: boolean;
}

export interface TycoonStaffView {
  id: StaffId;
  name: string;
  design: number;
  tech: number;
  hype: number;
  hired: boolean;
  trainedToday: boolean;
  training: { design: TrainOffer; tech: TrainOffer; hype: TrainOffer };
}

interface StaffState extends CraftPoints {
  trainedDay: number | null;
}

interface StaffSnapshot extends CraftPoints {
  id: StaffId;
}

export interface TycoonReview {
  score: number;
  reviewers: Array<{ name: string; score: number; blurb: string }>;
}

export interface TycoonSales {
  units: number;
  cents: number;
  fans: number;
}

export interface TycoonProductView {
  id: string;
  name: string;
  topicId: TopicId;
  typeId: ProductTypeId;
  topicName: string;
  typeName: string;
  fit: Fit;
  status: "developing" | "released" | "complete";
  startedDay: number;
  devDays: number;
  devDaysRequired: number;
  design: number;
  tech: number;
  hype: number;
  progress: number;
  ready: boolean;
  staffIds: StaffId[];
  releasedDay: number | null;
  review: TycoonReview | null;
  salesDays: number;
  salesDaysTotal: number;
  salesCents: number;
  fans: number;
}

export interface TycoonSnapshot {
  seed: number;
  salesWindowDays: number;
  topics: Array<{ id: TopicId; name: string }>;
  types: Array<{ id: ProductTypeId; name: string; devDays: number; priceCents: number; design: number; tech: number; hype: number }>;
  fits: Array<{ topicId: TopicId; typeId: ProductTypeId; fit: Fit }>;
  staff: TycoonStaffView[];
  trainingNotice: string;
  developing: TycoonProductView | null;
  history: TycoonProductView[];
}

interface ProductRow {
  id: string;
  topic_id: string;
  type_id: string;
  name: string;
  fit: string;
  status: string;
  started_day: number;
  dev_days: number;
  design_points: number;
  tech_points: number;
  hype_points: number;
  staff_json: string;
  last_dev_day: number | null;
  released_day: number | null;
  review_json: string | null;
  sales_applied: number;
  last_sales_day: number | null;
  sales_cents: number;
  fans: number;
}

export function mixSeed(seed: number, ...parts: Array<string | number>): number {
  let hash = (seed >>> 0) || 1;
  const text = parts.map((part) => String(part)).join("\u001f");
  for (let index = 0; index < text.length; index += 1) {
    hash = Math.imul(hash ^ text.charCodeAt(index), 16777619) >>> 0;
  }
  return hash >>> 0;
}

export function topicById(id: string): (typeof TOPICS)[number] | undefined {
  return TOPICS.find((topic) => topic.id === id);
}

export function typeById(id: string): (typeof PRODUCT_TYPES)[number] | undefined {
  return PRODUCT_TYPES.find((type) => type.id === id);
}

export function fitFor(topicId: TopicId, typeId: ProductTypeId): Fit {
  const row = FIT_ROWS[topicId];
  const column = PRODUCT_TYPES.findIndex((type) => type.id === typeId);
  const fit = row[column];
  if (fit === undefined) throw new Error("Unknown topic and product pairing");
  return fit;
}

export function allFits(): TycoonSnapshot["fits"] {
  return TOPICS.flatMap((topic) => PRODUCT_TYPES.map((type) => ({
    topicId: topic.id,
    typeId: type.id,
    fit: fitFor(topic.id, type.id),
  })));
}

export function productTitle(topicId: TopicId, typeId: ProductTypeId): string {
  const topic = topicById(topicId);
  const type = typeById(typeId);
  if (!topic || !type) throw new Error("Unknown topic or product type");
  return `${topic.name} ${type.name}`;
}

export function trainCostCents(level: number): number {
  return TRAIN_COST_PER_LEVEL_CENTS * Math.max(1, level);
}

export function statLabel(stat: StatId): string {
  if (stat === "design") return "Design";
  if (stat === "tech") return "Tech";
  return "Hype";
}

export function staffPoints(staffIds: readonly string[], stats?: Readonly<Record<string, CraftPoints>>): CraftPoints {
  const totals: CraftPoints = { design: 0, tech: 0, hype: 0 };
  const seen = new Set<string>();
  for (const id of staffIds) {
    if (seen.has(id)) continue;
    seen.add(id);
    const person = stats?.[id] ?? STAFF.find((member) => member.id === id);
    if (!person) continue;
    totals.design += person.design;
    totals.tech += person.tech;
    totals.hype += person.hype;
  }
  return totals;
}

export function snapshotPoints(members: readonly CraftPoints[]): CraftPoints {
  const totals: CraftPoints = { design: 0, tech: 0, hype: 0 };
  for (const person of members) {
    totals.design += person.design;
    totals.tech += person.tech;
    totals.hype += person.hype;
  }
  return totals;
}

function asStat(value: string): StatId {
  if (value === "design" || value === "tech" || value === "hype") return value;
  throw new Error("Train Design, Tech, or Hype.");
}

function clampStat(value: unknown, fallback: number): number {
  const amount = Number(value);
  if (!Number.isInteger(amount)) return fallback;
  return Math.max(0, Math.min(STAT_CAP, amount));
}

function parseStaffSnapshot(raw: string): StaffSnapshot[] {
  let parsed: unknown;
  try { parsed = JSON.parse(raw); } catch { return []; }
  if (!Array.isArray(parsed)) return [];
  const result: StaffSnapshot[] = [];
  const seen = new Set<string>();
  for (const item of parsed) {
    if (typeof item === "string") {
      const person = STAFF.find((member) => member.id === item);
      if (!person || seen.has(person.id)) continue;
      seen.add(person.id);
      result.push({ id: person.id, design: person.design, tech: person.tech, hype: person.hype });
      continue;
    }
    if (!item || typeof item !== "object" || !("id" in item)) continue;
    const id = String((item as { id: unknown }).id);
    const person = STAFF.find((member) => member.id === id);
    if (!person || seen.has(person.id)) continue;
    seen.add(person.id);
    const row = item as { design?: unknown; tech?: unknown; hype?: unknown };
    result.push({
      id: person.id,
      design: clampStat(row.design, person.design),
      tech: clampStat(row.tech, person.tech),
      hype: clampStat(row.hype, person.hype),
    });
  }
  return result;
}

/** 0..1000. Matching the ideal is full credit. A little extra holds. A lot extra dulls the work. */
export function statRatioMilli(points: number, ideal: number): number {
  if (ideal <= 0) return 0;
  const raw = Math.floor((points * 1000) / ideal);
  if (raw <= 1000) return raw;
  if (raw <= 1500) return 1000;
  const penalty = Math.floor(((raw - 1500) * 15) / 100);
  return Math.max(700, 1000 - penalty);
}

export function qualityMilli(points: CraftPoints, typeId: ProductTypeId): number {
  const type = typeById(typeId);
  if (!type) throw new Error("Unknown product type");
  const ideal = type.devDays * IDEAL_POINTS_PER_DAY;
  const weighted = statRatioMilli(points.design, ideal) * type.design
    + statRatioMilli(points.tech, ideal) * type.tech
    + statRatioMilli(points.hype, ideal) * type.hype;
  return Math.floor(weighted / (type.design + type.tech + type.hype));
}

function clampScore(score: number): number {
  return Math.max(1, Math.min(10, score));
}

export function baseScore(points: CraftPoints, topicId: TopicId, typeId: ProductTypeId): number {
  const fitted = Math.floor((qualityMilli(points, typeId) * FIT_NUMERATOR[fitFor(topicId, typeId)]) / 100);
  const used = Math.min(1000, fitted);
  return clampScore(Math.round((used * 9) / 1000 + 1));
}

function blurbBand(score: number): "high" | "mid" | "low" {
  if (score >= 8) return "high";
  if (score >= 5) return "mid";
  return "low";
}

export function reviewProduct(input: {
  seed: number;
  productId: string;
  topicId: TopicId;
  typeId: ProductTypeId;
  design: number;
  tech: number;
  hype: number;
}): TycoonReview {
  const base = baseScore(
    { design: input.design, tech: input.tech, hype: input.hype },
    input.topicId,
    input.typeId,
  );
  const reviewers = REVIEWERS.map((reviewer, index) => {
    const jitter = (mixSeed(input.seed, input.productId, "review", index) % 3) - 1;
    const score = clampScore(base + jitter);
    return { name: reviewer.name, score, blurb: reviewer.blurbs[blurbBand(score)] };
  });
  const score = clampScore(Math.round(reviewers.reduce((sum, reviewer) => sum + reviewer.score, 0) / reviewers.length));
  return { score, reviewers };
}

export function salesForDay(input: {
  seed: number;
  productId: string;
  typeId: ProductTypeId;
  fit: Fit;
  score: number;
  dayIndex: number;
  reputation: number;
}): TycoonSales {
  const curve = SALES_CURVE[input.dayIndex];
  const type = typeById(input.typeId);
  if (curve === undefined || !type) throw new Error("Sales day is outside the window");
  const swing = (mixSeed(input.seed, input.productId, "sales", input.dayIndex) % 21) - 10;
  const baseUnits = FIT_UNITS[input.fit] + Math.floor((input.score * 3) / 2) + Math.floor(input.reputation / 10);
  const units = Math.max(1, Math.round((baseUnits * curve * (100 + swing)) / 10000));
  const fanPermille = input.score >= 8 ? 400 : input.score >= 5 ? 200 : 100;
  const fans = Math.max(1, Math.round((units * fanPermille) / 1000));
  return { units, cents: units * type.priceCents, fans };
}

export function pointsStillAccrue(devDaysAlready: number, required: number): boolean {
  return devDaysAlready < required + EXTRA_POLISH_DAYS;
}

function asTopic(id: string): TopicId {
  if (!topicById(id)) throw new Error("Unknown topic");
  return id as TopicId;
}

function asType(id: string): ProductTypeId {
  if (!typeById(id)) throw new Error("Unknown product type");
  return id as ProductTypeId;
}

function asFit(value: string): Fit {
  if (value !== "great" && value !== "good" && value !== "okay" && value !== "bad") throw new Error("Stored fit is invalid");
  return value;
}

export class TycoonStore {
  private trainingNotice = "";

  constructor(private readonly db: DatabaseSync, private readonly journey: JourneyStore) {}

  view(): TycoonSnapshot {
    const hired = this.hiredIds();
    const developing = this.developingRow();
    const history = (this.db.prepare(`
      SELECT * FROM tycoon_products WHERE status != 'developing'
      ORDER BY released_day DESC, id DESC LIMIT 48
    `).all() as unknown as ProductRow[]).map((row) => this.toView(row));
    const stats = this.loadStaffState();
    const day = this.day();
    const cash = this.cashCents();
    return {
      seed: this.seed(),
      salesWindowDays: SALES_WINDOW_DAYS,
      topics: TOPICS.map((topic) => ({ id: topic.id, name: topic.name })),
      types: PRODUCT_TYPES.map((type) => ({
        id: type.id, name: type.name, devDays: type.devDays, priceCents: type.priceCents,
        design: type.design, tech: type.tech, hype: type.hype,
      })),
      fits: allFits(),
      staff: STAFF.map((person) => {
        const current = stats[person.id];
        const isHired = person.id === "founder" || hired.has(person.id);
        const trainedToday = current.trainedDay === day;
        return {
          id: person.id,
          name: person.name,
          design: current.design,
          tech: current.tech,
          hype: current.hype,
          hired: isHired,
          trainedToday,
          training: {
            design: this.trainOffer(current.design, isHired, trainedToday, cash),
            tech: this.trainOffer(current.tech, isHired, trainedToday, cash),
            hype: this.trainOffer(current.hype, isHired, trainedToday, cash),
          },
        };
      }),
      trainingNotice: this.trainingNotice,
      developing: developing ? this.toView(developing) : null,
      history,
    };
  }

  start(topicValue: string, typeValue: string, requestedStaff: readonly string[]): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      if (this.developingRow()) throw new Error("A product is already on the bench. Ship it or keep building.");
      const topicId = asTopic(topicValue);
      const typeId = asType(typeValue);
      const staffIds = this.assignedStaff(requestedStaff);
      const stats = this.loadStaffState();
      const snapshot = staffIds.map((id) => ({
        id, design: stats[id].design, tech: stats[id].tech, hype: stats[id].hype,
      }));
      const count = Number((this.db.prepare("SELECT COUNT(*) AS n FROM tycoon_products").get() as { n: number }).n);
      const id = `p${count + 1}`;
      this.db.prepare(`
        INSERT INTO tycoon_products (
          id, topic_id, type_id, name, fit, status, started_day, dev_days,
          design_points, tech_points, hype_points, staff_json, last_dev_day,
          released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
        ) VALUES (?, ?, ?, ?, ?, 'developing', ?, 0, 0, 0, 0, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
      `).run(id, topicId, typeId, productTitle(topicId, typeId), fitFor(topicId, typeId), this.day(), JSON.stringify(snapshot));
      return this.journey.state();
    });
  }

  train(staffValue: string, statValue: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const person = STAFF.find((member) => member.id === staffValue);
      if (!person) throw new Error("Unknown teammate");
      if (person.id !== "founder" && !this.hiredIds().has(person.id)) {
        throw new Error(`${person.name} is not on the team yet.`);
      }
      const stat = asStat(statValue);
      const state = this.loadStaffState();
      const current = state[person.id][stat];
      if (current >= STAT_CAP) throw new Error(`${person.name}'s ${statLabel(stat)} is already at ${STAT_CAP}.`);
      const day = this.day();
      if (state[person.id].trainedDay === day) throw new Error(`${person.name} is already in training today.`);
      const cost = trainCostCents(current);
      const cash = this.cashCents();
      if (cash < cost) {
        throw new Error(`Not enough game cash. Training ${statLabel(stat)} costs $${Math.floor(cost / 100)}.`);
      }
      this.journey.recordCompanyChange(
        `tycoon:train:${person.id}:${stat}:${day}`,
        day,
        -cost,
        0,
        0,
        `Training · ${person.name} ${statLabel(stat)}`,
      );
      state[person.id][stat] = current + 1;
      state[person.id].trainedDay = day;
      this.saveStaffState(state);
      this.trainingNotice = `${person.name} trained ${statLabel(stat)} to ${current + 1}. −$${Math.floor(cost / 100)}`;
      return this.journey.state();
    });
  }

  release(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product is on the bench.");
      if (row.status !== "developing") throw new Error("This product already shipped.");
      const type = typeById(row.type_id);
      if (!type) throw new Error("Unknown product type");
      const remaining = type.devDays - Number(row.dev_days);
      if (remaining > 0) {
        throw new Error(remaining === 1
          ? "Keep building. This product needs 1 more office day."
          : `Keep building. This product needs ${remaining} more office days.`);
      }
      const topicId = asTopic(row.topic_id);
      const typeId = type.id;
      const review = reviewProduct({
        seed: this.seed(),
        productId: row.id,
        topicId,
        typeId,
        design: Number(row.design_points),
        tech: Number(row.tech_points),
        hype: Number(row.hype_points),
      });
      const day = this.day();
      this.db.prepare("UPDATE tycoon_products SET status = 'released', released_day = ?, review_json = ? WHERE id = ?")
        .run(day, JSON.stringify(review), row.id);
      this.applySale(this.row(row.id)!, day);
      return this.journey.state();
    });
  }

  /** One office day of craft or of sales. Caller holds the company transaction. */
  tickDay(day: number): void {
    const rows = this.db.prepare(`
      SELECT * FROM tycoon_products WHERE status IN ('developing', 'released') ORDER BY id
    `).all() as unknown as ProductRow[];
    for (const row of rows) {
      if (row.status === "developing") this.tickDevelopment(row, day);
      else this.applySale(row, day);
    }
  }

  private tickDevelopment(row: ProductRow, day: number): void {
    if (row.last_dev_day !== null && Number(row.last_dev_day) === day) return;
    const type = typeById(row.type_id);
    if (!type) throw new Error("Unknown product type");
    const snapshot = parseStaffSnapshot(row.staff_json);
    const trainedToday = this.trainedIdsOn(day);
    const working = snapshot.filter((person) => !trainedToday.has(person.id));
    const gain = pointsStillAccrue(Number(row.dev_days), type.devDays)
      ? snapshotPoints(working)
      : { design: 0, tech: 0, hype: 0 };
    const devDays = Number(row.dev_days) + 1;
    this.db.prepare(`
      UPDATE tycoon_products
      SET dev_days = ?, design_points = ?, tech_points = ?, hype_points = ?, last_dev_day = ?
      WHERE id = ?
    `).run(
      devDays,
      Number(row.design_points) + gain.design,
      Number(row.tech_points) + gain.tech,
      Number(row.hype_points) + gain.hype,
      day,
      row.id,
    );
    this.journey.recordCompanyChange(`tycoon:build:${row.id}:${day}`, day, 0, 0, 0, `Building ${row.name}`);
  }

  private applySale(row: ProductRow, day: number): void {
    if (row.status !== "released") return;
    const applied = Number(row.sales_applied);
    if (applied >= SALES_WINDOW_DAYS) return;
    if (row.last_sales_day !== null && Number(row.last_sales_day) === day) return;
    const review = JSON.parse(String(row.review_json)) as TycoonReview;
    const reputation = Number((this.db.prepare("SELECT reputation FROM company_state WHERE id = 1").get() as { reputation: number }).reputation);
    const payout = salesForDay({
      seed: this.seed(),
      productId: row.id,
      typeId: asType(row.type_id),
      fit: asFit(row.fit),
      score: review.score,
      dayIndex: applied,
      reputation,
    });
    this.journey.recordCompanyChange(`tycoon:${row.id}:${applied}`, day, payout.cents, payout.cents, payout.fans, `Sales · ${row.name}`);
    const salesDays = applied + 1;
    this.db.prepare(`
      UPDATE tycoon_products
      SET status = ?, sales_applied = ?, last_sales_day = ?, sales_cents = ?, fans = ?
      WHERE id = ?
    `).run(
      salesDays >= SALES_WINDOW_DAYS ? "complete" : "released",
      salesDays,
      day,
      Number(row.sales_cents) + payout.cents,
      Number(row.fans) + payout.fans,
      row.id,
    );
  }

  private assignedStaff(requested: readonly string[]): StaffId[] {
    const hired = this.hiredIds();
    const ids: StaffId[] = ["founder"];
    for (const id of requested) {
      if (id === "founder") continue;
      const person = STAFF.find((member) => member.id === id);
      if (!person) throw new Error("Unknown teammate");
      if (!hired.has(person.id)) throw new Error(`${person.name} is not on the team yet.`);
      if (!ids.includes(person.id)) ids.push(person.id);
    }
    return ids;
  }

  private hiredIds(): Set<string> {
    const rows = this.db.prepare("SELECT id FROM employees WHERE employment_status = 'hired'").all() as unknown as Array<{ id: string }>;
    return new Set(rows.map((row) => row.id));
  }

  private cashCents(): number {
    const row = this.db.prepare("SELECT cash_cents FROM company_state WHERE id = 1").get() as { cash_cents: number } | undefined;
    return Number(row?.cash_cents ?? 0);
  }

  private trainOffer(level: number, hired: boolean, trainedToday: boolean, cash: number): TrainOffer {
    if (level >= STAT_CAP) return { costCents: 0, enabled: false };
    const costCents = trainCostCents(level);
    return { costCents, enabled: hired && !trainedToday && cash >= costCents };
  }

  private trainedIdsOn(day: number): Set<string> {
    const stats = this.loadStaffState();
    return new Set(STAFF.filter((person) => stats[person.id].trainedDay === day).map((person) => person.id));
  }

  private loadStaffState(): Record<StaffId, StaffState> {
    const defaults = Object.fromEntries(STAFF.map((person) => [person.id, {
      design: person.design, tech: person.tech, hype: person.hype, trainedDay: null as number | null,
    }])) as Record<StaffId, StaffState>;
    const row = this.db.prepare("SELECT staff_json FROM tycoon_meta WHERE id = 1").get() as { staff_json?: string } | undefined;
    const raw = row?.staff_json?.trim();
    if (!raw) return defaults;
    let parsed: unknown;
    try { parsed = JSON.parse(raw); } catch { return defaults; }
    if (!parsed || typeof parsed !== "object") return defaults;
    const stored = parsed as Record<string, { design?: unknown; tech?: unknown; hype?: unknown; trainedDay?: unknown }>;
    for (const person of STAFF) {
      const item = stored[person.id];
      if (!item || typeof item !== "object") continue;
      const trainedDay = Number(item.trainedDay);
      defaults[person.id] = {
        design: clampStat(item.design, person.design),
        tech: clampStat(item.tech, person.tech),
        hype: clampStat(item.hype, person.hype),
        trainedDay: Number.isInteger(trainedDay) && trainedDay > 0 ? trainedDay : null,
      };
    }
    return defaults;
  }

  private saveStaffState(state: Record<StaffId, StaffState>): void {
    this.db.prepare("UPDATE tycoon_meta SET staff_json = ? WHERE id = 1").run(JSON.stringify(state));
  }

  private seed(): number {
    const row = this.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number } | undefined;
    if (!row) throw new Error("Tycoon seed is missing");
    return Number(row.seed);
  }

  private day(): number {
    const row = this.db.prepare("SELECT value_json FROM game_state WHERE key = 'clock'").get() as { value_json: string } | undefined;
    if (!row) return 1;
    const parsed = JSON.parse(row.value_json) as { day?: number };
    return Number(parsed.day ?? 1);
  }

  private developingRow(): ProductRow | undefined {
    return this.db.prepare("SELECT * FROM tycoon_products WHERE status = 'developing' LIMIT 1").get() as ProductRow | undefined;
  }

  private row(id: string): ProductRow | undefined {
    return this.db.prepare("SELECT * FROM tycoon_products WHERE id = ?").get(id) as ProductRow | undefined;
  }

  private toView(row: ProductRow): TycoonProductView {
    const topicId = asTopic(row.topic_id);
    const typeId = asType(row.type_id);
    const type = typeById(typeId)!;
    const topic = topicById(topicId)!;
    const devDays = Number(row.dev_days);
    const progress = Math.min(100, Math.round((devDays * 100) / type.devDays));
    const staffIds = parseStaffSnapshot(row.staff_json).map((person) => person.id);
    return {
      id: row.id,
      name: row.name,
      topicId,
      typeId,
      topicName: topic.name,
      typeName: type.name,
      fit: asFit(row.fit),
      status: row.status as TycoonProductView["status"],
      startedDay: Number(row.started_day),
      devDays,
      devDaysRequired: type.devDays,
      design: Number(row.design_points),
      tech: Number(row.tech_points),
      hype: Number(row.hype_points),
      progress,
      ready: row.status === "developing" && devDays >= type.devDays,
      staffIds,
      releasedDay: row.released_day === null ? null : Number(row.released_day),
      review: row.review_json ? JSON.parse(row.review_json) as TycoonReview : null,
      salesDays: Number(row.sales_applied),
      salesDaysTotal: SALES_WINDOW_DAYS,
      salesCents: Number(row.sales_cents),
      fans: Number(row.fans),
    };
  }
}
