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
/** Research point prices. A topic is the cheaper unlock. A type costs more. */
export const RESEARCH_COST = { topic: 4, type: 6 } as const;
/** Added to the fit numerator for each part the player bought with research points. */
export const RESEARCH_FIT_BONUS = 6;
/** Percent added to the type price by the checkout upgrade. Half rounds away from zero. */
export const PRICE_BOOST_PERCENT = 10;
/** Catalog is 100. A nudge moves price and units the opposite way by 20. */
export const LAUNCH_PRICES = [
  { percent: 80, unitPercent: 120, label: "−20%" },
  { percent: 100, unitPercent: 100, label: "Catalog" },
  { percent: 120, unitPercent: 80, label: "+20%" },
] as const;
/** None is free and leaves units alone. A paid ad is cash at the start, then extra units all window. */
export const MARKETING = [
  { id: "none", label: "None", costCents: 0, unitPercent: 100 },
  { id: "small", label: "Small ad", costCents: 5_000, unitPercent: 120 },
  { id: "big", label: "Big ad", costCents: 15_000, unitPercent: 150 },
] as const;
/**
 * One client at a time. Every pair is in the starter catalog.
 * The bonus is cash on release. It does not change units, price, or fans.
 */
export const CONTRACTS = [
  { id: "nova", client: "Nova on Whop", topicId: "crypto", typeId: "newsletter", bonusCents: 8_000 },
  { id: "remy", client: "Remy on Whop", topicId: "fitness", typeId: "course", bonusCents: 12_000 },
  { id: "juniper", client: "Juniper on Whop", topicId: "cooking", typeId: "newsletter", bonusCents: 7_000 },
  { id: "pax", client: "Pax on Whop", topicId: "gaming", typeId: "community", bonusCents: 10_000 },
  { id: "kit", client: "Kit on Whop", topicId: "study_notes", typeId: "template_pack", bonusCents: 6_000 },
  { id: "lane", client: "Lane on Whop", topicId: "trading", typeId: "newsletter", bonusCents: 9_000 },
] as const;
/** One optional patch per shipped product. Cash now, +1 score on remaining sales days. */
export const PATCH_COST_CENTS = 10_000;
export const PATCH_SCORE_BONUS = 1;
/** One optional sequel. One fewer build day, and +1 base score when the original finished at 6 or more. */
export const SEQUEL_DAYS_SAVED = 1;
export const SEQUEL_SCORE_MARK = 6;
export const SEQUEL_SCORE_BONUS = 1;
/** One optional show after sales finish. The fee is cash. Fans come from the stored review score, once. */
export const AWARD_SHOW = "Whop Creator Awards";
export const AWARD_COST_CENTS = 4_000;
export const AWARD_WIN_SCORE = 8;
export const AWARD_NOMINEE_SCORE = 5;
export const AWARD_WIN_FANS = 12;
export const AWARD_NOMINEE_FANS = 4;
/** One optional port. One extra sales day on a second shelf, after a small fee. */
export const PORT_SHELF = "Whop Mobile";
export const PORT_COST_CENTS = 8_000;
/** Stardew-shaped office calendar. Derived from the saved day. It does not replace the clock. */
export const SEASON_LENGTH_DAYS = 28;
export const YEAR_LENGTH_DAYS = 112;
/** Percent added to that day's units when the season favors the product topic. */
export const SEASON_UNIT_BOOST_PERCENT = 20;
/** Extra fans on any product that sells on an event day. */
export const EVENT_BONUS_FANS = 2;
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

/** Office tools. Each row is bought once and has one effect. */
export const UPGRADES = [
  { id: "standing_desk", name: "Oak Standing Desk", blurb: "Sketches land cleaner when you stand.", priceCents: 25_000, kind: "design", effect: "+1 design per person per dev day" },
  { id: "second_monitor", name: "Second Monitor", blurb: "The build on one screen, the notes on the other.", priceCents: 36_000, kind: "tech", effect: "+1 tech per person per dev day" },
  { id: "ring_light", name: "Ring Light", blurb: "Launch clips look like a real shop.", priceCents: 40_000, kind: "hype", effect: "+1 hype per person per dev day" },
  { id: "checkout_page", name: "Nicer Checkout Page", blurb: "The buy button finally looks finished.", priceCents: 56_000, kind: "price", effect: "+10% price on later sales" },
] as const;

/** Founder plus the three story hires. Desk capacity is informational and does not block a hire. */
export const STORY_DESK_COUNT = 4;
/** One expansion inside the current room. Tuned just above Nicer Checkout Page. */
export const OFFICE_EXPANSION_COST_CENTS = 60_000;
/** Hires besides the founder. Mina alone is not enough. */
export const OFFICE_EXPANSION_HIRES = 2;
/**
 * Level 1 is the room the company already has. Level 2 adds two compact desks
 * and one shared workbench, plus a flat team bonus on accruing dev days.
 */
export const OFFICE_LEVELS = [
  { level: 1, name: "Garage Loft", blurb: "A checkout link and one desk by the garage door.", spareDesks: 0, design: 0, tech: 0 },
  { level: 2, name: "Open Floor", blurb: "Spare desks for the next drop.", spareDesks: 3, design: 1, tech: 1 },
] as const;

export type TopicId = (typeof TOPICS)[number]["id"];
export type ProductTypeId = (typeof PRODUCT_TYPES)[number]["id"];
export type StaffId = (typeof STAFF)[number]["id"];
export type StatId = (typeof STATS)[number];
export type ResearchKind = keyof typeof RESEARCH_COST;
export type UpgradeId = (typeof UPGRADES)[number]["id"];
export type UpgradeKind = (typeof UPGRADES)[number]["kind"];
export type Fit = "great" | "good" | "okay" | "bad";
export type SeasonId = "spring" | "summer" | "fall" | "winter";
export type LaunchPricePercent = (typeof LAUNCH_PRICES)[number]["percent"];
export type LaunchPriceStep = (typeof LAUNCH_PRICES)[number];
export type MarketingId = (typeof MARKETING)[number]["id"];
export type MarketingOption = (typeof MARKETING)[number];
export type ContractId = (typeof CONTRACTS)[number]["id"];

/** New companies. Crypto Alpha × Newsletter stays in this set. */
const STARTER_TOPIC_IDS: readonly TopicId[] = ["fitness", "trading", "cooking", "gaming", "study_notes", "crypto"];
const STARTER_TYPE_IDS: readonly ProductTypeId[] = ["course", "community", "template_pack", "newsletter"];

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

export const SEASONS = [
  { id: "spring", name: "Spring" },
  { id: "summer", name: "Summer" },
  { id: "fall", name: "Fall" },
  { id: "winter", name: "Winter" },
] as const;

/** Two topics sell a little better for the whole season. Ids match TOPICS. */
export const SEASON_FAVORED_TOPICS: Record<SeasonId, readonly TopicId[]> = {
  spring: ["fitness", "dating"],
  summer: ["sneakers", "sports_betting"],
  fall: ["study_notes", "trading"],
  winter: ["cooking", "gaming"],
};

/** One cozy event per season, on a fixed day of that season. The effect lasts that day only. */
export const SEASON_EVENTS = [
  { id: "creator_fair", season: "spring", dayOfSeason: 13, name: "Creator Fair", blurb: "The floor is full of shops and first buyers." },
  { id: "drop_day", season: "summer", dayOfSeason: 11, name: "Drop Day", blurb: "Everyone refreshes the page at the same minute." },
  { id: "cohort_kickoff", season: "fall", dayOfSeason: 16, name: "Cohort Kickoff", blurb: "A new class shows up with notebooks open." },
  { id: "cozy_gift_guide", season: "winter", dayOfSeason: 25, name: "Cozy Gift Guide", blurb: "Whop Weekly lists the warm shops." },
] as const;

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
  researchPoints: number;
  /** Fit numerator bonus snapshotted when development started. 0, 6, or 12. */
  researchBonus: number;
  /** Launch price as a percent of the catalog. Omitted rows read as 100. */
  pricePercent: LaunchPricePercent;
  /** Chosen unit price in cents, before the checkout boost. */
  priceCents: number;
  /** Ad bought at the start. Omitted rows read as none. */
  marketing: MarketingId;
  /** Client bonus snapshotted at the start. Omitted rows are no contract. */
  contract: { client: string; bonusCents: number } | null;
  /** Null while the product is on the bench. Omitted rows read as unpatched. */
  patch: TycoonPatchView | null;
  /** Null on the bench unless this product is itself a sequel. Omitted rows are not sequels. */
  sequel: TycoonSequelView | null;
  /** Null while the product is on the bench. Omitted rows have not entered. */
  award: TycoonAwardView | null;
  /** Null while the product is on the bench. Omitted rows have not been ported. */
  port: TycoonPortView | null;
}

export interface TycoonUpgradeView {
  id: UpgradeId;
  name: string;
  blurb: string;
  priceCents: number;
  kind: UpgradeKind;
  effect: string;
  owned: boolean;
  affordable: boolean;
}

export interface TycoonEventView {
  id: (typeof SEASON_EVENTS)[number]["id"];
  name: string;
  blurb: string;
  effect: string;
}

export interface TycoonCalendar {
  season: SeasonId;
  seasonName: string;
  dayOfSeason: number;
  year: number;
  /** Player-facing date, for example "Spring 3 · Year 1". */
  label: string;
  favoredTopics: Array<{ id: TopicId; name: string }>;
  /** The event on this office day, or null. */
  event: TycoonEventView | null;
  nextEvent: TycoonEventView & { season: SeasonId; dayOfSeason: number; daysUntil: number };
}

export interface TycoonOfficeDesks {
  used: number;
  total: number;
}

export interface TycoonOfficeNext {
  name: string;
  costCents: number;
  requiredHires: number;
  enabled: boolean;
  reason: string;
}

export interface TycoonOffice {
  level: number;
  name: string;
  blurb: string;
  desks: TycoonOfficeDesks;
  next: TycoonOfficeNext | null;
}

export interface TycoonContractView {
  id: ContractId;
  client: string;
  topicId: TopicId;
  typeId: ProductTypeId;
  topicName: string;
  typeName: string;
  bonusCents: number;
  /** offered = free to ignore. accepted = locked, no product yet. building = on the bench. */
  status: "offered" | "accepted" | "building";
  enabled: boolean;
  reason: string;
}

export interface TycoonPatchView {
  costCents: number;
  scoreBonus: number;
  applied: boolean;
  enabled: boolean;
  reason: string;
}

export interface TycoonSequelView {
  /** 0, or 1 when this product carried a point from its original. */
  scoreBonus: number;
  /** Office days a sequel skips. The build uses catalog days minus this, at least 1. */
  savedDays: number;
  isSequel: boolean;
  started: boolean;
  enabled: boolean;
  reason: string;
}

export type AwardOutcome = "won" | "nominated" | "entered";

export interface TycoonAwardView {
  show: string;
  costCents: number;
  /** Empty until the product enters. */
  outcome: AwardOutcome | "";
  fans: number;
  entered: boolean;
  enabled: boolean;
  reason: string;
}

export interface TycoonPortView {
  shelf: string;
  costCents: number;
  /** Empty until the port starts. Selling until the extra day pays, then sold. */
  phase: "" | "selling" | "sold";
  cents: number;
  fans: number;
  enabled: boolean;
  reason: string;
}

export interface TycoonSnapshot {
  seed: number;
  salesWindowDays: number;
  topics: Array<{ id: TopicId; name: string; unlocked: boolean; researchCost: number }>;
  types: Array<{ id: ProductTypeId; name: string; devDays: number; priceCents: number; design: number; tech: number; hype: number; unlocked: boolean; researchCost: number }>;
  fits: Array<{ topicId: TopicId; typeId: ProductTypeId; fit: Fit; researchBonus: number }>;
  staff: TycoonStaffView[];
  trainingNotice: string;
  researchPoints: number;
  researchNotice: string;
  upgradeNotice: string;
  upgrades: TycoonUpgradeView[];
  calendar: TycoonCalendar;
  office: TycoonOffice;
  priceSteps: LaunchPriceStep[];
  marketingOptions: Array<MarketingOption & { enabled: boolean; reason: string }>;
  contract: TycoonContractView;
  patchNotice: string;
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
  release_research: number | null;
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

/** 6 per researched part on the pairing, so 0, 6, or 12. Starters are not researched. */
export function researchFitBonus(topicResearched: boolean, typeResearched: boolean): number {
  return (topicResearched ? RESEARCH_FIT_BONUS : 0) + (typeResearched ? RESEARCH_FIT_BONUS : 0);
}

export function allFits(
  researchedTopics?: ReadonlySet<TopicId>,
  researchedTypes?: ReadonlySet<ProductTypeId>,
): TycoonSnapshot["fits"] {
  const topics = researchedTopics ?? new Set<TopicId>();
  const types = researchedTypes ?? new Set<ProductTypeId>();
  return TOPICS.flatMap((topic) => PRODUCT_TYPES.map((type) => ({
    topicId: topic.id,
    typeId: type.id,
    fit: fitFor(topic.id, type.id),
    researchBonus: researchFitBonus(topics.has(topic.id), types.has(type.id)),
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

export function upgradeById(id: string): (typeof UPGRADES)[number] | undefined {
  return UPGRADES.find((item) => item.id === id);
}

/** Whole dollars for player-facing cash lines. Catalog prices are multiples of $1. */
export function wholeDollars(cents: number): string {
  return `$${Math.floor(cents / 100)}`;
}

/** Unit price after a percent boost. Half rounds away from zero via Math.round. */
export function boostedPriceCents(priceCents: number, boostPercent: number): number {
  if (!Number.isInteger(boostPercent) || boostPercent <= 0) return priceCents;
  return Math.round((priceCents * (100 + boostPercent)) / 100);
}

export function isLaunchPricePercent(value: number): value is LaunchPricePercent {
  return LAUNCH_PRICES.some((step) => step.percent === value);
}

/** Unknown or omitted values are catalog. */
export function normalizeLaunchPricePercent(value: unknown): LaunchPricePercent {
  const amount = Number(value);
  return isLaunchPricePercent(amount) ? amount : 100;
}

export function launchUnitPercent(pricePercent: number): number {
  const percent = normalizeLaunchPricePercent(pricePercent);
  const step = LAUNCH_PRICES.find((item) => item.percent === percent);
  return step?.unitPercent ?? 100;
}

/** Catalog times the launch percent. Catalog (100) returns the catalog cents unchanged. */
export function launchPriceCents(catalogCents: number, pricePercent: number): number {
  const percent = normalizeLaunchPricePercent(pricePercent);
  if (percent === 100) return catalogCents;
  return Math.round((catalogCents * percent) / 100);
}

/** Units move the opposite way from the price. Catalog leaves units unchanged. Always at least 1. */
export function applyLaunchPriceUnits(units: number, pricePercent: number): number {
  const unitPercent = launchUnitPercent(pricePercent);
  if (unitPercent === 100) return Math.max(1, units);
  return Math.max(1, Math.round((units * unitPercent) / 100));
}

function asLaunchPrice(value: number): LaunchPricePercent {
  if (isLaunchPricePercent(value)) return value;
  throw new Error("Pick −20%, catalog, or +20%.");
}

export function marketingById(id: string): MarketingOption | undefined {
  return MARKETING.find((item) => item.id === id);
}

/** Unknown or omitted values are no ad. */
export function normalizeMarketing(value: unknown): MarketingId {
  return typeof value === "string" && marketingById(value) ? value as MarketingId : "none";
}

export function marketingUnitPercent(id: unknown): number {
  return marketingById(normalizeMarketing(id))?.unitPercent ?? 100;
}

export function contractById(id: string): (typeof CONTRACTS)[number] | undefined {
  return CONTRACTS.find((item) => item.id === id);
}

/** Stable offer for this company. The day does not move it. Completing one advances the slot. */
export function contractBySlot(seed: number, completed: number): (typeof CONTRACTS)[number] {
  const start = mixSeed(seed, "contract") % CONTRACTS.length;
  const index = (start + Math.max(0, completed)) % CONTRACTS.length;
  return CONTRACTS[index] ?? CONTRACTS[0];
}

interface ProductContract {
  id: ContractId;
  client: string;
  bonusCents: number;
}

/** A missing or unknown contract pays nothing. A stored bonus stays put. */
function parseContract(value: unknown): ProductContract | null {
  if (!value || typeof value !== "object") return null;
  const body = value as { id?: unknown; client?: unknown; bonusCents?: unknown };
  if (typeof body.id !== "string") return null;
  const known = contractById(body.id);
  if (!known) return null;
  const bonus = Number(body.bonusCents);
  const bonusCents = Number.isInteger(bonus) && bonus > 0 ? bonus : known.bonusCents;
  const client = typeof body.client === "string" && body.client.trim() ? body.client : known.client;
  return { id: known.id, client, bonusCents };
}

function contractView(
  id: ContractId,
  client: string,
  topicId: TopicId,
  typeId: ProductTypeId,
  bonusCents: number,
  status: TycoonContractView["status"],
  enabled: boolean,
  reason: string,
): TycoonContractView {
  const topic = topicById(topicId);
  const type = typeById(typeId);
  if (!topic || !type) throw new Error("Unknown topic or product type");
  return {
    id,
    client,
    topicId,
    typeId,
    topicName: topic.name,
    typeName: type.name,
    bonusCents,
    status,
    enabled,
    reason,
  };
}

/** Extra units for the whole sales window. None leaves units unchanged. Always at least 1. */
export function applyMarketingUnits(units: number, id: unknown): number {
  const percent = marketingUnitPercent(id);
  if (percent === 100) return Math.max(1, units);
  return Math.max(1, Math.round((units * percent) / 100));
}

function asMarketing(value: string): MarketingId {
  const option = marketingById(value);
  if (!option) throw new Error("Pick None, Small ad, or Big ad.");
  return option.id;
}

function marketingOffer(cash: number): TycoonSnapshot["marketingOptions"] {
  return MARKETING.map((item) => {
    const short = item.costCents > 0 && cash < item.costCents;
    return { ...item, enabled: !short, reason: short ? `Need ${wholeDollars(item.costCents)}` : "" };
  });
}

export function releaseResearchPoints(score: number): number {
  return Math.floor(Math.max(0, score) / 2);
}

export function starterResearchJson(): string {
  return JSON.stringify({ topics: STARTER_TOPIC_IDS, types: STARTER_TYPE_IDS });
}

export function legacyResearchJson(): string {
  return JSON.stringify({
    topics: TOPICS.map((topic) => topic.id),
    types: PRODUCT_TYPES.map((type) => type.id),
  });
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

function asResearchKind(value: string): ResearchKind {
  if (value === "topic" || value === "type") return value;
  throw new Error("Research a topic or a product type.");
}

function clampStat(value: unknown, fallback: number): number {
  const amount = Number(value);
  if (!Number.isInteger(amount)) return fallback;
  return Math.max(0, Math.min(STAT_CAP, amount));
}

function parseStaffList(parsed: unknown): StaffSnapshot[] {
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

interface ProductSnapshot {
  staff: StaffSnapshot[];
  researchBonus: number;
  pricePercent: LaunchPricePercent;
  marketing: MarketingId;
  contract: ProductContract | null;
  patched: boolean;
  /** Product id this one continues. Null means it is not a sequel. */
  sequelOf: string | null;
  /** Product id of the one sequel started from this row. Null means none. */
  sequelId: string | null;
  /** 1 when the original's final score was 6 or more. Otherwise 0. */
  scoreBonus: number;
  /** Null until the product enters one show. */
  award: ProductAward | null;
  /** Null until the product is ported to the second shelf. */
  port: ProductPort | null;
}

interface ProductPort {
  shelf: string;
  startedDay: number;
  /** Null while the extra sales day has not paid. */
  cents: number | null;
  fans: number | null;
}

interface ProductAward {
  outcome: AwardOutcome;
  fans: number;
}

function emptyProductSnapshot(staff: StaffSnapshot[] = []): ProductSnapshot {
  return {
    staff,
    researchBonus: 0,
    pricePercent: 100,
    marketing: "none",
    contract: null,
    patched: false,
    sequelOf: null,
    sequelId: null,
    scoreBonus: 0,
    award: null,
    port: null,
  };
}

function parseProductId(value: unknown): string | null {
  return typeof value === "string" && /^p[1-9][0-9]*$/u.test(value) ? value : null;
}

/** Older rows are a staff array and count as catalog price, no bonus, no ad, no contract, unpatched, no sequel, no award, and no port. */
function parseProductSnapshot(raw: string): ProductSnapshot {
  const empty = emptyProductSnapshot();
  let parsed: unknown;
  try { parsed = JSON.parse(raw); } catch { return empty; }
  if (Array.isArray(parsed)) return emptyProductSnapshot(parseStaffList(parsed));
  if (!parsed || typeof parsed !== "object" || !("staff" in parsed)) return empty;
  const body = parsed as {
    staff?: unknown;
    researchBonus?: unknown;
    pricePercent?: unknown;
    marketing?: unknown;
    contract?: unknown;
    patched?: unknown;
    sequelOf?: unknown;
    sequelId?: unknown;
    scoreBonus?: unknown;
    award?: unknown;
    port?: unknown;
  };
  return {
    staff: parseStaffList(body.staff),
    researchBonus: normalizeResearchBonus(Number(body.researchBonus)),
    pricePercent: normalizeLaunchPricePercent(body.pricePercent),
    marketing: normalizeMarketing(body.marketing),
    contract: parseContract(body.contract),
    patched: body.patched === true,
    sequelOf: parseProductId(body.sequelOf),
    sequelId: parseProductId(body.sequelId),
    scoreBonus: body.scoreBonus === SEQUEL_SCORE_BONUS ? SEQUEL_SCORE_BONUS : 0,
    award: parseAward(body.award),
    port: parsePort(body.port),
  };
}

function awardFans(outcome: AwardOutcome): number {
  if (outcome === "won") return AWARD_WIN_FANS;
  if (outcome === "nominated") return AWARD_NOMINEE_FANS;
  return 0;
}

function parsePort(value: unknown): ProductPort | null {
  if (!value || typeof value !== "object") return null;
  const body = value as { shelf?: unknown; startedDay?: unknown; cents?: unknown; fans?: unknown };
  if (body.shelf !== PORT_SHELF) return null;
  const startedDay = Number(body.startedDay);
  if (!Number.isInteger(startedDay) || startedDay < 1) return null;
  if (body.cents === undefined && body.fans === undefined) return { shelf: PORT_SHELF, startedDay, cents: null, fans: null };
  const cents = Number(body.cents);
  const fans = Number(body.fans);
  if (!Number.isInteger(cents) || cents < 0 || !Number.isInteger(fans) || fans < 0) return null;
  return { shelf: PORT_SHELF, startedDay, cents, fans };
}

function parseAward(value: unknown): ProductAward | null {
  if (!value || typeof value !== "object") return null;
  const outcome = (value as { outcome?: unknown }).outcome;
  if (outcome !== "won" && outcome !== "nominated" && outcome !== "entered") return null;
  const fans = Number((value as { fans?: unknown }).fans);
  if (fans !== awardFans(outcome)) return null;
  return { outcome, fans };
}

/** 8+ wins. 5–7 is a nominee. Below that the product only entered. The stored review score, not a patch. */
export function awardForScore(score: number): { outcome: AwardOutcome; fans: number } {
  if (score >= AWARD_WIN_SCORE) return { outcome: "won", fans: AWARD_WIN_FANS };
  if (score >= AWARD_NOMINEE_SCORE) return { outcome: "nominated", fans: AWARD_NOMINEE_FANS };
  return { outcome: "entered", fans: 0 };
}

function serializeProductSnapshot(stored: ProductSnapshot): string {
  const body: Record<string, unknown> = {
    staff: stored.staff,
    researchBonus: stored.researchBonus,
    pricePercent: stored.pricePercent,
    marketing: stored.marketing,
  };
  if (stored.contract) body.contract = stored.contract;
  if (stored.patched) body.patched = true;
  if (stored.sequelOf) body.sequelOf = stored.sequelOf;
  if (stored.sequelId) body.sequelId = stored.sequelId;
  if (stored.scoreBonus === SEQUEL_SCORE_BONUS) body.scoreBonus = SEQUEL_SCORE_BONUS;
  if (stored.award) body.award = { outcome: stored.award.outcome, fans: stored.award.fans };
  if (stored.port) {
    body.port = stored.port.cents === null
      ? { shelf: stored.port.shelf, startedDay: stored.port.startedDay }
      : { shelf: stored.port.shelf, startedDay: stored.port.startedDay, cents: stored.port.cents, fans: stored.port.fans };
  }
  return JSON.stringify(body);
}

/** A sequel skips one office day and never drops below one. */
export function sequelDevDays(catalogDays: number): number {
  return Math.max(1, catalogDays - SEQUEL_DAYS_SAVED);
}

/** Catalog length, or the shorter sequel length when this product continues another. */
export function requiredDevDays(catalogDays: number, isSequel: boolean): number {
  return isSequel ? sequelDevDays(catalogDays) : catalogDays;
}

/** +1 when the original's final score is 6 or more. Otherwise none. */
export function sequelScoreCarry(finalScore: number): number {
  return finalScore >= SEQUEL_SCORE_MARK ? SEQUEL_SCORE_BONUS : 0;
}

/** A patch adds 1, then the score stays on 1–10. Unpatched leaves the stored review score. */
export function patchedScore(score: number, patched: boolean): number {
  return clampScore(score + (patched ? PATCH_SCORE_BONUS : 0));
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

export function qualityMilli(points: CraftPoints, typeId: ProductTypeId, devDays = 0): number {
  const type = typeById(typeId);
  if (!type) throw new Error("Unknown product type");
  const days = devDays > 0 ? devDays : type.devDays;
  const ideal = days * IDEAL_POINTS_PER_DAY;
  const weighted = statRatioMilli(points.design, ideal) * type.design
    + statRatioMilli(points.tech, ideal) * type.tech
    + statRatioMilli(points.hype, ideal) * type.hype;
  return Math.floor(weighted / (type.design + type.tech + type.hype));
}

function clampScore(score: number): number {
  return Math.max(1, Math.min(10, score));
}

function normalizeResearchBonus(value: number): number {
  if (value === RESEARCH_FIT_BONUS || value === RESEARCH_FIT_BONUS * 2) return value;
  return 0;
}

export function baseScore(points: CraftPoints, topicId: TopicId, typeId: ProductTypeId, researchBonus = 0, devDays = 0): number {
  const numerator = FIT_NUMERATOR[fitFor(topicId, typeId)] + normalizeResearchBonus(researchBonus);
  const fitted = Math.floor((qualityMilli(points, typeId, devDays) * numerator) / 100);
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
  /** Bonus stored on the product. Omitted scores as 0. */
  researchBonus?: number;
  /** Carried score stored on a sequel. Omitted is 0. Added before reviewers move the base. */
  sequelBonus?: number;
  /** Days required for the ideal. Omitted uses the catalog length. */
  devDays?: number;
}): TycoonReview {
  const carried = input.sequelBonus === SEQUEL_SCORE_BONUS ? SEQUEL_SCORE_BONUS : 0;
  const base = clampScore(baseScore(
    { design: input.design, tech: input.tech, hype: input.hype },
    input.topicId,
    input.typeId,
    input.researchBonus ?? 0,
    input.devDays ?? 0,
  ) + carried);
  const reviewers = REVIEWERS.map((reviewer, index) => {
    const jitter = (mixSeed(input.seed, input.productId, "review", index) % 3) - 1;
    const score = clampScore(base + jitter);
    return { name: reviewer.name, score, blurb: reviewer.blurbs[blurbBand(score)] };
  });
  const score = clampScore(Math.round(reviewers.reduce((sum, reviewer) => sum + reviewer.score, 0) / reviewers.length));
  return { score, reviewers };
}

/** Indexes 0–3 are the four sales days. The port's extra day stays on the last step. */
function curvePercent(dayIndex: number): number | undefined {
  if (dayIndex === SALES_WINDOW_DAYS) return SALES_CURVE[SALES_CURVE.length - 1];
  return SALES_CURVE[dayIndex];
}

export function salesForDay(input: {
  seed: number;
  productId: string;
  typeId: ProductTypeId;
  fit: Fit;
  score: number;
  dayIndex: number;
  reputation: number;
  priceBoostPercent?: number;
  /** Extra percent of units when the season favors this topic. Omitted leaves the base formula. */
  unitBoostPercent?: number;
  /** Extra fans from the event on this office day. Omitted leaves the base formula. */
  bonusFans?: number;
  /** Launch price as a percent of the catalog. Omitted is catalog (100). */
  pricePercent?: number;
  /** Ad id stored on the product. Omitted is no ad. */
  marketing?: string;
}): TycoonSales {
  const curve = curvePercent(input.dayIndex);
  const type = typeById(input.typeId);
  if (curve === undefined || !type) throw new Error("Sales day is outside the window");
  const swing = (mixSeed(input.seed, input.productId, "sales", input.dayIndex) % 21) - 10;
  const baseUnits = FIT_UNITS[input.fit] + Math.floor((input.score * 3) / 2) + Math.floor(input.reputation / 10);
  // Units: base, launch price, season, marketing. Fans follow those units.
  // Price: launch price, then checkout. Cash is units times that price.
  let units = Math.max(1, Math.round((baseUnits * curve * (100 + swing)) / 10000));
  const pricePercent = normalizeLaunchPricePercent(input.pricePercent);
  units = applyLaunchPriceUnits(units, pricePercent);
  const unitBoost = input.unitBoostPercent ?? 0;
  if (Number.isInteger(unitBoost) && unitBoost > 0) {
    units = Math.max(1, Math.round((units * (100 + unitBoost)) / 100));
  }
  units = applyMarketingUnits(units, input.marketing);
  const fanPermille = input.score >= 8 ? 400 : input.score >= 5 ? 200 : 100;
  const bonusFans = Number.isInteger(input.bonusFans) && (input.bonusFans ?? 0) > 0 ? (input.bonusFans as number) : 0;
  const fans = Math.max(1, Math.round((units * fanPermille) / 1000)) + bonusFans;
  const chosen = launchPriceCents(type.priceCents, pricePercent);
  const price = boostedPriceCents(chosen, input.priceBoostPercent ?? 0);
  return { units, cents: units * price, fans };
}

/** Player-facing line for the event fan bonus. */
export function eventEffectLabel(): string {
  return `+${EVENT_BONUS_FANS} fans on sales today`;
}

function eventDayOfYear(season: SeasonId, dayOfSeason: number): number {
  const index = SEASONS.findIndex((item) => item.id === season);
  return index * SEASON_LENGTH_DAYS + dayOfSeason;
}

function eventView(event: (typeof SEASON_EVENTS)[number]): TycoonEventView {
  return { id: event.id, name: event.name, blurb: event.blurb, effect: eventEffectLabel() };
}

/** Day 1 is Spring 1, Year 1. Day 29 is Summer 1. Day 113 is Spring 1, Year 2. */
export function calendarForDay(day: number): TycoonCalendar {
  const safe = Math.max(1, Math.trunc(Number.isFinite(day) ? day : 1));
  const index = safe - 1;
  const year = Math.floor(index / YEAR_LENGTH_DAYS) + 1;
  const dayOfYear = index % YEAR_LENGTH_DAYS;
  const season = SEASONS[Math.floor(dayOfYear / SEASON_LENGTH_DAYS)] ?? SEASONS[0];
  const dayOfSeason = (dayOfYear % SEASON_LENGTH_DAYS) + 1;
  const favoredTopics = SEASON_FAVORED_TOPICS[season.id].flatMap((id) => {
    const topic = topicById(id);
    return topic ? [{ id: topic.id, name: topic.name }] : [];
  });
  const today = SEASON_EVENTS.find((item) => item.season === season.id && item.dayOfSeason === dayOfSeason) ?? null;
  const dayOfYearNumber = dayOfYear + 1;
  const eventDays = SEASON_EVENTS.map((item) => eventDayOfYear(item.season, item.dayOfSeason));
  let nextSlot = eventDays.findIndex((value) => value > dayOfYearNumber);
  let daysUntil: number;
  if (nextSlot < 0) {
    nextSlot = 0;
    daysUntil = YEAR_LENGTH_DAYS - dayOfYearNumber + (eventDays[0] ?? 1);
  } else {
    daysUntil = (eventDays[nextSlot] ?? dayOfYearNumber) - dayOfYearNumber;
  }
  const next = SEASON_EVENTS[nextSlot] ?? SEASON_EVENTS[0];
  return {
    season: season.id,
    seasonName: season.name,
    dayOfSeason,
    year,
    label: `${season.name} ${dayOfSeason} · Year ${year}`,
    favoredTopics,
    event: today ? eventView(today) : null,
    nextEvent: { ...eventView(next), season: next.season, dayOfSeason: next.dayOfSeason, daysUntil },
  };
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

interface ResearchState {
  points: number;
  topics: Set<TopicId>;
  types: Set<ProductTypeId>;
  researchedTopics: Set<TopicId>;
  researchedTypes: Set<ProductTypeId>;
}

interface OwnedUpgrade {
  id: UpgradeId;
  day: number;
}

function isPointKind(kind: UpgradeKind): kind is StatId {
  return kind === "design" || kind === "tech" || kind === "hype";
}

export class TycoonStore {
  private trainingNotice = "";
  private trainingNoticeDay = 0;
  private researchNotice = "";
  private researchNoticeDay = 0;
  private upgradeNotice = "";
  private upgradeNoticeDay = 0;
  private patchNotice = "";
  private patchNoticeDay = 0;

  constructor(
    private readonly db: DatabaseSync,
    private readonly journey: JourneyStore,
    private readonly onOfficeChanged: () => void = () => {},
  ) {}

  view(): TycoonSnapshot {
    const hired = this.hiredIds();
    const developing = this.developingRow();
    const history = (this.db.prepare(`
      SELECT * FROM tycoon_products WHERE status != 'developing'
      ORDER BY released_day DESC, id DESC LIMIT 48
    `).all() as unknown as ProductRow[]).map((row) => this.toView(row));
    const stats = this.loadStaffState();
    const research = this.loadResearch();
    const owned = this.loadUpgrades();
    const ownedIds = new Set(owned.map((entry) => entry.id));
    const day = this.day();
    const cash = this.cashCents();
    return {
      seed: this.seed(),
      salesWindowDays: SALES_WINDOW_DAYS,
      topics: TOPICS.map((topic) => ({
        id: topic.id,
        name: topic.name,
        unlocked: research.topics.has(topic.id),
        researchCost: RESEARCH_COST.topic,
      })),
      types: PRODUCT_TYPES.map((type) => ({
        id: type.id, name: type.name, devDays: type.devDays, priceCents: type.priceCents,
        design: type.design, tech: type.tech, hype: type.hype,
        unlocked: research.types.has(type.id),
        researchCost: RESEARCH_COST.type,
      })),
      fits: allFits(research.researchedTopics, research.researchedTypes),
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
      trainingNotice: this.trainingNoticeDay === day ? this.trainingNotice : "",
      researchPoints: research.points,
      researchNotice: this.researchNoticeDay === day ? this.researchNotice : "",
      upgradeNotice: this.upgradeNoticeDay === day ? this.upgradeNotice : "",
      upgrades: UPGRADES.map((item) => {
        const isOwned = ownedIds.has(item.id);
        return {
          id: item.id,
          name: item.name,
          blurb: item.blurb,
          priceCents: item.priceCents,
          kind: item.kind,
          effect: item.effect,
          owned: isOwned,
          affordable: !isOwned && cash >= item.priceCents,
        };
      }),
      calendar: calendarForDay(day),
      office: this.officeView(this.officeLevel(), hired.size, cash),
      priceSteps: [...LAUNCH_PRICES],
      marketingOptions: marketingOffer(cash),
      contract: this.contractOffer(developing),
      patchNotice: this.patchNoticeDay === day ? this.patchNotice : "",
      developing: developing ? this.toView(developing) : null,
      history,
    };
  }

  start(topicValue: string, typeValue: string, requestedStaff: readonly string[], pricePercentValue?: number, marketingValue?: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      if (this.developingRow()) throw new Error("A product is already on the bench. Ship it or keep building.");
      const topicId = asTopic(topicValue);
      const typeId = asType(typeValue);
      const research = this.loadResearch();
      const topic = topicById(topicId);
      const type = typeById(typeId);
      if (!topic || !research.topics.has(topicId)) throw new Error(`${topic?.name ?? "That topic"} is locked. Research it first.`);
      if (!type || !research.types.has(typeId)) throw new Error(`${type?.name ?? "That product type"} is locked. Research it first.`);
      const pricePercent = pricePercentValue === undefined ? 100 : asLaunchPrice(pricePercentValue);
      const marketing = marketingValue === undefined ? "none" : asMarketing(marketingValue);
      const pending = this.loadPendingContract();
      if (pending && (pending.topicId !== topicId || pending.typeId !== typeId)) {
        const topicName = topicById(pending.topicId)?.name ?? pending.topicId;
        const typeName = typeById(pending.typeId)?.name ?? pending.typeId;
        throw new Error(`This contract is ${topicName} × ${typeName}.`);
      }
      const staffIds = this.assignedStaff(requestedStaff);
      const option = marketingById(marketing);
      if (!option) throw new Error("Pick None, Small ad, or Big ad.");
      if (option.costCents > 0 && this.cashCents() < option.costCents) throw new Error(`Need ${wholeDollars(option.costCents)}`);
      const stats = this.loadStaffState();
      const researchBonus = researchFitBonus(research.researchedTopics.has(topicId), research.researchedTypes.has(typeId));
      const count = Number((this.db.prepare("SELECT COUNT(*) AS n FROM tycoon_products").get() as { n: number }).n);
      const id = `p${count + 1}`;
      if (option.costCents > 0) {
        this.journey.recordCompanyChange(`tycoon:marketing:${id}`, this.day(), -option.costCents, 0, 0, option.label);
      }
      const snapshot: {
        staff: StaffSnapshot[];
        researchBonus: number;
        pricePercent: LaunchPricePercent;
        marketing: MarketingId;
        contract?: ProductContract;
      } = {
        staff: staffIds.map((memberId) => ({
          id: memberId, design: stats[memberId].design, tech: stats[memberId].tech, hype: stats[memberId].hype,
        })),
        researchBonus,
        pricePercent,
        marketing,
      };
      if (pending) {
        snapshot.contract = { id: pending.id, client: pending.client, bonusCents: pending.bonusCents };
        this.savePendingContract(null);
      }
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
      this.trainingNoticeDay = day;
      return this.journey.state();
    });
  }

  research(kindValue: string, idValue: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const kind = asResearchKind(kindValue);
      const catalog = this.loadResearch();
      if (kind === "topic") {
        const topic = topicById(idValue);
        if (!topic) throw new Error("Unknown topic");
        if (catalog.topics.has(topic.id)) throw new Error(`${topic.name} is already unlocked.`);
        this.spendResearch(catalog, kind, topic.id, topic.name);
      } else {
        const type = typeById(idValue);
        if (!type) throw new Error("Unknown product type");
        if (catalog.types.has(type.id)) throw new Error(`${type.name} is already unlocked.`);
        this.spendResearch(catalog, kind, type.id, type.name);
      }
      return this.journey.state();
    });
  }

  buyUpgrade(idValue: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const upgrade = upgradeById(idValue);
      if (!upgrade) throw new Error("Unknown upgrade.");
      const owned = this.loadUpgrades();
      if (owned.some((entry) => entry.id === upgrade.id)) {
        throw new Error(`${upgrade.name} is already in the office.`);
      }
      if (this.cashCents() < upgrade.priceCents) {
        throw new Error(`Not enough game cash. ${upgrade.name} costs ${wholeDollars(upgrade.priceCents)}.`);
      }
      const day = this.day();
      this.journey.recordCompanyChange(
        `tycoon:upgrade:${upgrade.id}`,
        day,
        -upgrade.priceCents,
        0,
        0,
        `Upgrade · ${upgrade.name}`,
      );
      owned.push({ id: upgrade.id, day });
      this.saveUpgrades(owned);
      this.upgradeNotice = `Bought ${upgrade.name}. −${wholeDollars(upgrade.priceCents)}`;
      this.upgradeNoticeDay = day;
      return this.journey.state();
    });
  }

  expandOffice(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const current = this.officeLevel();
      const next = OFFICE_LEVELS.find((level) => level.level === current + 1);
      if (!next) throw new Error("The office is already as large as it gets.");
      const hires = this.hiredIds().size;
      if (hires < OFFICE_EXPANSION_HIRES) {
        throw new Error(`Hire ${OFFICE_EXPANSION_HIRES} people before the ${next.name}.`);
      }
      if (this.cashCents() < OFFICE_EXPANSION_COST_CENTS) {
        throw new Error(`Not enough game cash. ${next.name} costs ${wholeDollars(OFFICE_EXPANSION_COST_CENTS)}.`);
      }
      const day = this.day();
      this.journey.recordCompanyChange(
        `tycoon:office:${next.level}`,
        day,
        -OFFICE_EXPANSION_COST_CENTS,
        0,
        0,
        `Office · ${next.name}`,
      );
      this.db.prepare("UPDATE tycoon_meta SET office_level = ? WHERE id = 1").run(next.level);
      this.onOfficeChanged();
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
      const stored = parseProductSnapshot(row.staff_json);
      const required = requiredDevDays(type.devDays, stored.sequelOf !== null);
      const remaining = required - Number(row.dev_days);
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
        researchBonus: stored.researchBonus,
        sequelBonus: stored.scoreBonus,
        devDays: required,
      });
      const day = this.day();
      const bonus = releaseResearchPoints(review.score);
      this.db.prepare("UPDATE tycoon_products SET status = 'released', released_day = ?, review_json = ?, release_research = ? WHERE id = ?")
        .run(day, JSON.stringify(review), bonus, row.id);
      this.addResearchPoints(bonus);
      this.applySale(this.row(row.id)!, day);
      if (stored.contract) {
        this.journey.recordCompanyChange(
          `tycoon:contract:${row.id}`,
          day,
          stored.contract.bonusCents,
          stored.contract.bonusCents,
          0,
          `Contract: ${stored.contract.client}`,
        );
      }
      return this.journey.state();
    });
  }

  acceptContract(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      if (this.developingRow()) throw new Error("Ship the product on the bench first.");
      if (this.loadPendingContract()) throw new Error("A contract is already accepted.");
      const offer = contractBySlot(this.seed(), this.completedContractCount());
      this.savePendingContract(offer.id);
      return this.journey.state();
    });
  }

  sequel(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      const stored = parseProductSnapshot(row.staff_json);
      const reason = this.sequelBlockReason(row, stored);
      if (reason) throw new Error(reason);
      const topicId = asTopic(row.topic_id);
      const typeId = asType(row.type_id);
      const research = this.loadResearch();
      const topic = topicById(topicId);
      const type = typeById(typeId);
      if (!topic || !research.topics.has(topicId)) throw new Error(`${topic?.name ?? "That topic"} is locked. Research it first.`);
      if (!type || !research.types.has(typeId)) throw new Error(`${type?.name ?? "That product type"} is locked. Research it first.`);
      const pending = this.loadPendingContract();
      const hired = this.hiredIds();
      const staffIds = this.assignedStaff(stored.staff.map((person) => person.id).filter((id) => id !== "founder" && hired.has(id)));
      const stats = this.loadStaffState();
      const researchBonus = researchFitBonus(research.researchedTopics.has(topicId), research.researchedTypes.has(typeId));
      const count = Number((this.db.prepare("SELECT COUNT(*) AS n FROM tycoon_products").get() as { n: number }).n);
      const id = `p${count + 1}`;
      const carry = sequelScoreCarry(patchedScore(this.storedReviewScore(row), stored.patched));
      const snapshot: ProductSnapshot = {
        staff: staffIds.map((memberId) => ({
          id: memberId, design: stats[memberId].design, tech: stats[memberId].tech, hype: stats[memberId].hype,
        })),
        researchBonus,
        pricePercent: 100,
        marketing: "none",
        contract: pending ? { id: pending.id, client: pending.client, bonusCents: pending.bonusCents } : null,
        patched: false,
        sequelOf: row.id,
        sequelId: null,
        scoreBonus: carry,
        award: null,
        port: null,
      };
      if (pending) this.savePendingContract(null);
      this.db.prepare(`
        INSERT INTO tycoon_products (
          id, topic_id, type_id, name, fit, status, started_day, dev_days,
          design_points, tech_points, hype_points, staff_json, last_dev_day,
          released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
        ) VALUES (?, ?, ?, ?, ?, 'developing', ?, 0, 0, 0, 0, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
      `).run(id, topicId, typeId, `${row.name} 2`, fitFor(topicId, typeId), this.day(), serializeProductSnapshot(snapshot));
      stored.sequelId = id;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  award(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      if (row.status === "developing") throw new Error("Ship this product first.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.award) throw new Error("Already entered.");
      if (row.status !== "complete") throw new Error("Still selling.");
      if (this.cashCents() < AWARD_COST_CENTS) throw new Error(`Need ${wholeDollars(AWARD_COST_CENTS)}`);
      const result = awardForScore(this.storedReviewScore(row));
      this.journey.recordCompanyChange(
        `tycoon:award:${row.id}`,
        this.day(),
        -AWARD_COST_CENTS,
        0,
        result.fans,
        `Award: ${AWARD_SHOW}`,
      );
      stored.award = result;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  port(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      const stored = parseProductSnapshot(row.staff_json);
      const reason = this.portBlockReason(row, stored);
      if (reason) throw new Error(reason);
      const day = this.day();
      this.journey.recordCompanyChange(
        `tycoon:port:${row.id}`,
        day,
        -PORT_COST_CENTS,
        0,
        0,
        `Port: ${PORT_SHELF}`,
      );
      stored.port = { shelf: PORT_SHELF, startedDay: day, cents: null, fans: null };
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  patch(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      if (row.status === "developing") throw new Error("Ship this product first.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.patched) throw new Error("Already patched.");
      if (row.status !== "released" || Number(row.sales_applied) >= SALES_WINDOW_DAYS) {
        throw new Error("Sales have ended.");
      }
      if (this.cashCents() < PATCH_COST_CENTS) throw new Error(`Need ${wholeDollars(PATCH_COST_CENTS)}`);
      const day = this.day();
      this.journey.recordCompanyChange(
        `tycoon:patch:${row.id}`,
        day,
        -PATCH_COST_CENTS,
        0,
        0,
        `Patch: ${row.name}`,
      );
      stored.patched = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      this.patchNotice = `Patched ${row.name}. −${wholeDollars(PATCH_COST_CENTS)}`;
      this.patchNoticeDay = day;
      return this.journey.state();
    });
  }

  /** One office day of craft or of sales. Caller holds the company transaction. */
  tickDay(day: number): void {
    this.expireNotices(day);
    const rows = this.db.prepare(`
      SELECT * FROM tycoon_products WHERE status IN ('developing', 'released') ORDER BY id
    `).all() as unknown as ProductRow[];
    for (const row of rows) {
      if (row.status === "developing") this.tickDevelopment(row, day);
      else this.applySale(row, day);
    }
    this.payPorts(day);
  }

  private tickDevelopment(row: ProductRow, day: number): void {
    if (row.last_dev_day !== null && Number(row.last_dev_day) === day) return;
    const type = typeById(row.type_id);
    if (!type) throw new Error("Unknown product type");
    const snapshot = parseProductSnapshot(row.staff_json);
    const trainedToday = this.trainedIdsOn(day);
    const working = snapshot.staff.filter((person) => !trainedToday.has(person.id));
    const accrue = pointsStillAccrue(Number(row.dev_days), requiredDevDays(type.devDays, snapshot.sequelOf !== null));
    const personal = accrue ? snapshotPoints(working) : { design: 0, tech: 0, hype: 0 };
    const bonus = accrue ? this.pointBonus() : { design: 0, tech: 0, hype: 0 };
    const people = accrue ? working.length : 0;
    const office = accrue && people > 0 ? this.officeBonus() : { design: 0, tech: 0, hype: 0 };
    const gain = {
      design: personal.design + bonus.design * people + office.design,
      tech: personal.tech + bonus.tech * people + office.tech,
      hype: personal.hype + bonus.hype * people + office.hype,
    };
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
    this.addResearchPoints(working.length);
    this.journey.recordCompanyChange(`tycoon:build:${row.id}:${day}`, day, 0, 0, 0, `Building ${row.name}`);
  }

  private applySale(row: ProductRow, day: number): void {
    if (row.status !== "released") return;
    const applied = Number(row.sales_applied);
    if (applied >= SALES_WINDOW_DAYS) return;
    if (row.last_sales_day !== null && Number(row.last_sales_day) === day) return;
    const review = JSON.parse(String(row.review_json)) as TycoonReview;
    const reputation = Number((this.db.prepare("SELECT reputation FROM company_state WHERE id = 1").get() as { reputation: number }).reputation);
    const calendar = calendarForDay(day);
    const topicId = asTopic(row.topic_id);
    const stored = parseProductSnapshot(row.staff_json);
    const payout = salesForDay({
      seed: this.seed(),
      productId: row.id,
      typeId: asType(row.type_id),
      fit: asFit(row.fit),
      score: patchedScore(review.score, stored.patched),
      dayIndex: applied,
      reputation,
      pricePercent: stored.pricePercent,
      marketing: stored.marketing,
      priceBoostPercent: this.priceBoostPercent(),
      unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
      bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
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

  /** One extra sales day for a port that is still selling. The fee was already charged. */
  private payPorts(day: number): void {
    const rows = this.db.prepare("SELECT * FROM tycoon_products WHERE status = 'complete' ORDER BY id").all() as unknown as ProductRow[];
    for (const row of rows) {
      const stored = parseProductSnapshot(row.staff_json);
      if (!stored.port || stored.port.cents !== null || stored.port.startedDay > day) continue;
      const review = JSON.parse(String(row.review_json)) as TycoonReview;
      const reputation = Number((this.db.prepare("SELECT reputation FROM company_state WHERE id = 1").get() as { reputation: number }).reputation);
      const calendar = calendarForDay(day);
      const topicId = asTopic(row.topic_id);
      const payout = salesForDay({
        seed: this.seed(),
        productId: row.id,
        typeId: asType(row.type_id),
        fit: asFit(row.fit),
        score: patchedScore(review.score, stored.patched),
        dayIndex: SALES_WINDOW_DAYS,
        reputation,
        pricePercent: stored.pricePercent,
        marketing: stored.marketing,
        priceBoostPercent: this.priceBoostPercent(),
        unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
        bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
      });
      this.journey.recordCompanyChange(`tycoon:${row.id}:${SALES_WINDOW_DAYS}`, day, payout.cents, payout.cents, payout.fans, `Sales · ${row.name}`);
      stored.port = { ...stored.port, cents: payout.cents, fans: payout.fans };
      this.db.prepare("UPDATE tycoon_products SET staff_json = ?, sales_cents = ?, fans = ? WHERE id = ?").run(
        serializeProductSnapshot(stored),
        Number(row.sales_cents) + payout.cents,
        Number(row.fans) + payout.fans,
        row.id,
      );
    }
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

  private spendResearch(catalog: ResearchState, kind: ResearchKind, id: TopicId | ProductTypeId, name: string): void {
    const cost = RESEARCH_COST[kind];
    if (catalog.points < cost) throw new Error(`Not enough research points. ${name} costs ${cost} RP.`);
    catalog.points -= cost;
    if (kind === "topic") {
      catalog.topics.add(id as TopicId);
      catalog.researchedTopics.add(id as TopicId);
    } else {
      catalog.types.add(id as ProductTypeId);
      catalog.researchedTypes.add(id as ProductTypeId);
    }
    this.saveResearch(catalog);
    this.researchNotice = `Unlocked ${name}. −${cost} RP`;
    this.researchNoticeDay = this.day();
  }

  private expireNotices(endedDay: number): void {
    if (this.trainingNoticeDay !== 0 && this.trainingNoticeDay <= endedDay) {
      this.trainingNotice = "";
      this.trainingNoticeDay = 0;
    }
    if (this.researchNoticeDay !== 0 && this.researchNoticeDay <= endedDay) {
      this.researchNotice = "";
      this.researchNoticeDay = 0;
    }
    if (this.upgradeNoticeDay !== 0 && this.upgradeNoticeDay <= endedDay) {
      this.upgradeNotice = "";
      this.upgradeNoticeDay = 0;
    }
    if (this.patchNoticeDay !== 0 && this.patchNoticeDay <= endedDay) {
      this.patchNotice = "";
      this.patchNoticeDay = 0;
    }
  }

  private officeView(level: number, hires: number, cash: number): TycoonOffice {
    const current = OFFICE_LEVELS.find((entry) => entry.level === level) ?? OFFICE_LEVELS[0];
    const next = OFFICE_LEVELS.find((entry) => entry.level === current.level + 1);
    const shortHires = hires < OFFICE_EXPANSION_HIRES;
    const shortCash = cash < OFFICE_EXPANSION_COST_CENTS;
    return {
      level: current.level,
      name: current.name,
      blurb: current.blurb,
      desks: { used: 1 + hires, total: STORY_DESK_COUNT + current.spareDesks },
      next: next ? {
        name: next.name,
        costCents: OFFICE_EXPANSION_COST_CENTS,
        requiredHires: OFFICE_EXPANSION_HIRES,
        enabled: !shortHires && !shortCash,
        reason: shortHires
          ? `Hire ${OFFICE_EXPANSION_HIRES} people first.`
          : shortCash
            ? `Need ${wholeDollars(OFFICE_EXPANSION_COST_CENTS)} game cash.`
            : "",
      } : null,
    };
  }

  /** Flat team bonus. Level 1 is zero. It is not multiplied by headcount. */
  private officeBonus(): CraftPoints {
    const level = OFFICE_LEVELS.find((entry) => entry.level === this.officeLevel()) ?? OFFICE_LEVELS[0];
    return { design: level.design, tech: level.tech, hype: 0 };
  }

  private officeLevel(): number {
    const row = this.db.prepare("SELECT office_level FROM tycoon_meta WHERE id = 1").get() as { office_level?: number } | undefined;
    const level = Number(row?.office_level ?? 1);
    return OFFICE_LEVELS.some((entry) => entry.level === level) ? level : 1;
  }

  private pointBonus(): CraftPoints {
    const bonus: CraftPoints = { design: 0, tech: 0, hype: 0 };
    for (const entry of this.loadUpgrades()) {
      const upgrade = upgradeById(entry.id);
      if (!upgrade || !isPointKind(upgrade.kind)) continue;
      bonus[upgrade.kind] += 1;
    }
    return bonus;
  }

  private priceBoostPercent(): number {
    return this.loadUpgrades().some((entry) => upgradeById(entry.id)?.kind === "price") ? PRICE_BOOST_PERCENT : 0;
  }

  private loadUpgrades(): OwnedUpgrade[] {
    const row = this.db.prepare("SELECT upgrades_json FROM tycoon_meta WHERE id = 1").get() as { upgrades_json?: string } | undefined;
    const raw = row?.upgrades_json?.trim() ?? "";
    if (!raw) return [];
    let parsed: unknown;
    try { parsed = JSON.parse(raw); } catch { return []; }
    if (!Array.isArray(parsed)) return [];
    const owned: OwnedUpgrade[] = [];
    const seen = new Set<string>();
    for (const item of parsed) {
      if (!item || typeof item !== "object" || !("id" in item)) continue;
      const id = String((item as { id: unknown }).id);
      const upgrade = upgradeById(id);
      if (!upgrade || seen.has(upgrade.id)) continue;
      seen.add(upgrade.id);
      const day = Number((item as { day?: unknown }).day);
      owned.push({ id: upgrade.id, day: Number.isInteger(day) && day > 0 ? day : 1 });
    }
    return owned;
  }

  private saveUpgrades(owned: readonly OwnedUpgrade[]): void {
    const ordered = UPGRADES.flatMap((item) => {
      const entry = owned.find((candidate) => candidate.id === item.id);
      return entry ? [entry] : [];
    });
    this.db.prepare("UPDATE tycoon_meta SET upgrades_json = ? WHERE id = 1").run(JSON.stringify(ordered));
  }

  private addResearchPoints(amount: number): void {
    if (amount <= 0) return;
    const catalog = this.loadResearch();
    catalog.points += amount;
    this.saveResearch(catalog);
  }

  private emptyResearched(): Pick<ResearchState, "researchedTopics" | "researchedTypes"> {
    return { researchedTopics: new Set(), researchedTypes: new Set() };
  }

  /** Missing `researched` means nothing was bought. Starters and legacy unlocks stay at 0. */
  private parseResearched(stored: { researched?: unknown }): Pick<ResearchState, "researchedTopics" | "researchedTypes"> {
    const researched = this.emptyResearched();
    const field = stored.researched;
    if (!field || typeof field !== "object") return researched;
    const body = field as { topics?: unknown; types?: unknown };
    if (Array.isArray(body.topics)) {
      for (const id of body.topics) {
        if (typeof id === "string" && topicById(id)) researched.researchedTopics.add(id as TopicId);
      }
    }
    if (Array.isArray(body.types)) {
      for (const id of body.types) {
        if (typeof id === "string" && typeById(id)) researched.researchedTypes.add(id as ProductTypeId);
      }
    }
    return researched;
  }

  private loadResearch(): ResearchState {
    const everyone: ResearchState = {
      points: 0,
      topics: new Set(TOPICS.map((topic) => topic.id)),
      types: new Set(PRODUCT_TYPES.map((type) => type.id)),
      ...this.emptyResearched(),
    };
    const row = this.db.prepare("SELECT research_points, research_json FROM tycoon_meta WHERE id = 1").get() as { research_points?: number; research_json?: string } | undefined;
    const points = Number(row?.research_points ?? 0);
    everyone.points = Number.isInteger(points) && points > 0 ? points : 0;
    const raw = row?.research_json?.trim() ?? "";
    if (!raw) return everyone;
    let parsed: unknown;
    try { parsed = JSON.parse(raw); } catch { return everyone; }
    if (!parsed || typeof parsed !== "object") return everyone;
    const stored = parsed as { topics?: unknown; types?: unknown; researched?: unknown };
    if (!Array.isArray(stored.topics) || !Array.isArray(stored.types)) return everyone;
    const topics = new Set<TopicId>();
    const types = new Set<ProductTypeId>();
    for (const id of stored.topics) {
      if (typeof id === "string" && topicById(id)) topics.add(id as TopicId);
    }
    for (const id of stored.types) {
      if (typeof id === "string" && typeById(id)) types.add(id as ProductTypeId);
    }
    return { points: everyone.points, topics, types, ...this.parseResearched(stored) };
  }

  private saveResearch(state: ResearchState): void {
    this.db.prepare("UPDATE tycoon_meta SET research_points = ?, research_json = ? WHERE id = 1").run(state.points, JSON.stringify({
      topics: TOPICS.map((topic) => topic.id).filter((id) => state.topics.has(id)),
      types: PRODUCT_TYPES.map((type) => type.id).filter((id) => state.types.has(id)),
      researched: {
        topics: TOPICS.map((topic) => topic.id).filter((id) => state.researchedTopics.has(id)),
        types: PRODUCT_TYPES.map((type) => type.id).filter((id) => state.researchedTypes.has(id)),
      },
    }));
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

  private contractOffer(developing: ProductRow | undefined): TycoonContractView {
    const onBench = developing !== undefined;
    if (developing) {
      const stored = parseProductSnapshot(developing.staff_json).contract;
      if (stored) {
        return contractView(stored.id, stored.client, asTopic(developing.topic_id), asType(developing.type_id), stored.bonusCents, "building", false, "On the bench.");
      }
    }
    const pending = this.loadPendingContract();
    if (pending) {
      return contractView(
        pending.id,
        pending.client,
        pending.topicId,
        pending.typeId,
        pending.bonusCents,
        "accepted",
        false,
        onBench ? "Ship the product on the bench first." : "Accepted. The next product uses this pair.",
      );
    }
    const offer = contractBySlot(this.seed(), this.completedContractCount());
    return contractView(
      offer.id,
      offer.client,
      offer.topicId,
      offer.typeId,
      offer.bonusCents,
      "offered",
      !onBench,
      onBench ? "Ship the product on the bench first." : "",
    );
  }

  private completedContractCount(): number {
    const rows = this.db.prepare("SELECT status, staff_json FROM tycoon_products").all() as Array<{ status: string; staff_json: string }>;
    let count = 0;
    for (const row of rows) {
      if (row.status === "developing") continue;
      if (parseProductSnapshot(row.staff_json).contract) count += 1;
    }
    return count;
  }

  private loadPendingContract(): (typeof CONTRACTS)[number] | null {
    const row = this.db.prepare("SELECT contract_json FROM tycoon_meta WHERE id = 1").get() as { contract_json?: string } | undefined;
    const raw = row?.contract_json?.trim() ?? "";
    if (!raw) return null;
    let parsed: unknown;
    try { parsed = JSON.parse(raw); } catch { return null; }
    if (!parsed || typeof parsed !== "object" || !("id" in parsed)) return null;
    const known = contractById(String((parsed as { id: unknown }).id));
    return known ?? null;
  }

  private savePendingContract(id: ContractId | null): void {
    this.db.prepare("UPDATE tycoon_meta SET contract_json = ? WHERE id = 1").run(id ? JSON.stringify({ id }) : "");
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
    const snapshot = parseProductSnapshot(row.staff_json);
    const required = requiredDevDays(type.devDays, snapshot.sequelOf !== null);
    const progress = Math.min(100, Math.round((devDays * 100) / required));
    const staffIds = snapshot.staff.map((person) => person.id);
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
      devDaysRequired: required,
      design: Number(row.design_points),
      tech: Number(row.tech_points),
      hype: Number(row.hype_points),
      progress,
      ready: row.status === "developing" && devDays >= required,
      staffIds,
      releasedDay: row.released_day === null ? null : Number(row.released_day),
      review: row.review_json ? JSON.parse(row.review_json) as TycoonReview : null,
      salesDays: Number(row.sales_applied),
      salesDaysTotal: SALES_WINDOW_DAYS,
      salesCents: Number(row.sales_cents),
      fans: Number(row.fans),
      researchPoints: this.productResearchPoints(row),
      researchBonus: snapshot.researchBonus,
      pricePercent: snapshot.pricePercent,
      priceCents: launchPriceCents(type.priceCents, snapshot.pricePercent),
      marketing: snapshot.marketing,
      contract: snapshot.contract ? { client: snapshot.contract.client, bonusCents: snapshot.contract.bonusCents } : null,
      patch: this.patchOffer(row, snapshot),
      sequel: this.sequelOffer(row, snapshot),
      award: this.awardOffer(row, snapshot),
      port: this.portOffer(row, snapshot),
    };
  }

  /** Empty when the product can be ported. The same strings are the button reasons. */
  private portBlockReason(row: ProductRow, snapshot: ProductSnapshot): string {
    if (snapshot.port) return "Already ported.";
    if (row.status === "developing") return "Ship this product first.";
    if (row.status !== "complete") return "Still selling.";
    if (this.portPendingId()) return "Another port is still selling.";
    if (this.cashCents() < PORT_COST_CENTS) return `Need ${wholeDollars(PORT_COST_CENTS)}`;
    return "";
  }

  private portPendingId(): string | null {
    const rows = this.db.prepare("SELECT id, staff_json FROM tycoon_products").all() as Array<{ id: string; staff_json: string }>;
    for (const row of rows) {
      const port = parseProductSnapshot(row.staff_json).port;
      if (port && port.cents === null) return row.id;
    }
    return null;
  }

  private portOffer(row: ProductRow, snapshot: ProductSnapshot): TycoonPortView | null {
    if (row.status === "developing") return null;
    const port = snapshot.port;
    const reason = this.portBlockReason(row, snapshot);
    return {
      shelf: PORT_SHELF,
      costCents: PORT_COST_CENTS,
      phase: !port ? "" : port.cents === null ? "selling" : "sold",
      cents: port?.cents ?? 0,
      fans: port?.fans ?? 0,
      enabled: reason === "",
      reason,
    };
  }

  /** Empty when the product can enter. The same strings are the button reasons. */
  private awardOffer(row: ProductRow, snapshot: ProductSnapshot): TycoonAwardView | null {
    if (row.status === "developing") return null;
    const entered = snapshot.award;
    let enabled = false;
    let reason = "";
    if (entered) reason = "Already entered.";
    else if (row.status !== "complete") reason = "Still selling.";
    else if (this.cashCents() < AWARD_COST_CENTS) reason = `Need ${wholeDollars(AWARD_COST_CENTS)}`;
    else enabled = true;
    return {
      show: AWARD_SHOW,
      costCents: AWARD_COST_CENTS,
      outcome: entered?.outcome ?? "",
      fans: entered?.fans ?? 0,
      entered: entered !== null,
      enabled,
      reason,
    };
  }

  /** Empty when a sequel can start. The same strings are the button reasons. */
  private sequelBlockReason(row: ProductRow, snapshot: ProductSnapshot): string {
    if (snapshot.sequelOf) return "This is a sequel.";
    if (snapshot.sequelId) return "Already has a sequel.";
    if (row.status === "developing") return "Ship this product first.";
    if (row.status !== "complete") return "Still selling.";
    if (this.developingRow()) return "Ship the product on the bench first.";
    const pending = this.loadPendingContract();
    if (pending && (pending.topicId !== row.topic_id || pending.typeId !== row.type_id)) {
      const topicName = topicById(pending.topicId)?.name ?? pending.topicId;
      const typeName = typeById(pending.typeId)?.name ?? pending.typeId;
      return `This contract is ${topicName} × ${typeName}.`;
    }
    return "";
  }

  private storedReviewScore(row: ProductRow): number {
    if (!row.review_json) return 0;
    try {
      const review = JSON.parse(String(row.review_json)) as TycoonReview;
      const score = Number(review?.score);
      return Number.isInteger(score) ? score : 0;
    } catch {
      return 0;
    }
  }

  private sequelOffer(row: ProductRow, snapshot: ProductSnapshot): TycoonSequelView | null {
    if (row.status === "developing" && !snapshot.sequelOf) return null;
    const reason = this.sequelBlockReason(row, snapshot);
    return {
      scoreBonus: snapshot.scoreBonus,
      savedDays: SEQUEL_DAYS_SAVED,
      isSequel: snapshot.sequelOf !== null,
      started: snapshot.sequelId !== null,
      enabled: reason === "",
      reason,
    };
  }

  private patchOffer(row: ProductRow, snapshot: ProductSnapshot): TycoonPatchView | null {
    if (row.status === "developing") return null;
    const applied = snapshot.patched;
    const selling = row.status === "released" && Number(row.sales_applied) < SALES_WINDOW_DAYS;
    let enabled = false;
    let reason = "";
    if (applied) reason = "Already patched.";
    else if (!selling) reason = "Sales have ended.";
    else if (this.cashCents() < PATCH_COST_CENTS) reason = `Need ${wholeDollars(PATCH_COST_CENTS)}`;
    else enabled = true;
    return {
      costCents: PATCH_COST_CENTS,
      scoreBonus: PATCH_SCORE_BONUS,
      applied,
      enabled,
      reason,
    };
  }

  private productResearchPoints(row: ProductRow): number {
    if (row.release_research !== null && row.release_research !== undefined) return Math.max(0, Number(row.release_research));
    if (!row.review_json) return 0;
    try {
      const review = JSON.parse(row.review_json) as TycoonReview;
      return releaseResearchPoints(review.score);
    } catch {
      return 0;
    }
  }
}
