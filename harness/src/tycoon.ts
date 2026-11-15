import type { SqlDatabase } from "./sql-database.js";

import { JourneyStore } from "./journey.js";
import { fictionalWorld } from "./fictional-world.js";

/**
 * Authoritative offline tycoon rules. Gameplay never calls a model provider,
 * the network, or a credential. Reviews and sales are pure functions of the
 * saved seed, the product, and the points earned on office days.
 */

export const DEFAULT_TYCOON_SEED = 26021;
export const SALES_WINDOW_DAYS = 4;
export const EXTRA_POLISH_DAYS = 2;
/** Score points subtracted per missing office day when a product ships early. */
export const EARLY_ACCESS_PENALTY_CAP = 3;
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
  { id: "nova", client: "Nova on TownSquare", topicId: "crypto", typeId: "newsletter", bonusCents: 8_000 },
  { id: "remy", client: "Remy on TownSquare", topicId: "fitness", typeId: "course", bonusCents: 12_000 },
  { id: "juniper", client: "Juniper on TownSquare", topicId: "cooking", typeId: "newsletter", bonusCents: 7_000 },
  { id: "pax", client: "Pax on TownSquare", topicId: "gaming", typeId: "community", bonusCents: 10_000 },
  { id: "kit", client: "Kit on TownSquare", topicId: "study_notes", typeId: "template_pack", bonusCents: 6_000 },
  { id: "lane", client: "Lane on TownSquare", topicId: "trading", typeId: "newsletter", bonusCents: 9_000 },
] as const;
/** One optional patch per shipped product. Cash now, +1 score on remaining sales days. */
export const PATCH_COST_CENTS = 10_000;
export const PATCH_SCORE_BONUS = 1;
/** One optional sequel. One fewer build day, and +1 base score when the original finished at 6 or more. */
export const SEQUEL_DAYS_SAVED = 1;
export const SEQUEL_SCORE_MARK = 6;
export const SEQUEL_SCORE_BONUS = 1;
/** One optional show after sales finish. The fee is cash. Fans come from the stored review score, once. */
export const AWARD_SHOW = "TownSquare Creator Awards";
export const AWARD_COST_CENTS = 4_000;
export const AWARD_WIN_SCORE = 8;
export const AWARD_NOMINEE_SCORE = 5;
export const AWARD_WIN_FANS = 12;
export const AWARD_NOMINEE_FANS = 4;
/** One optional port. One extra sales day on a second shelf, after a small fee. */
export const PORT_SHELF = "TownSquare Mobile";
export const PORT_COST_CENTS = 8_000;
/**
 * One optional translation of a finished product, on its existing shelf.
 * Copy only, so the fee is under the $80 port and over the $40 award.
 * $50 is also under the $60 expo booth and Mina's $80 season salary.
 * The extra day keeps half the units of the port's extra-day formula.
 */
export const LOCALIZE_EDITION = "Spanish edition";
export const LOCALIZE_COST_CENTS = 5_000;
export const LOCALIZE_UNIT_PERCENT = 50;
/** One optional in-house engine. Bought once. A product started on it stores +1 score, capped at 10. */
export const ENGINE_ID = "whop_kit";
export const ENGINE_NAME = "TownSquare Kit Engine";
export const ENGINE_BLURB = "One kit, used on the builds you choose.";
export const ENGINE_COST_CENTS = 12_000;
export const ENGINE_SCORE_BONUS = 1;
/**
 * One optional focus when a product starts. Balanced adds nothing.
 * Design, Tech, or Hype stores +1 on that stat. The add stops at STAT_CAP.
 */
export const FOCUS_BONUS = 1;
export const FOCUSES = [
  { id: "balanced", label: "Balanced", stat: "", bonus: 0 },
  { id: "design", label: "Design", stat: "design", bonus: 1 },
  { id: "tech", label: "Tech", stat: "tech", bonus: 1 },
  { id: "hype", label: "Hype", stat: "hype", bonus: 1 },
] as const;
/**
 * One optional audience when a product starts. Everyone adds nothing.
 * Regulars adds +2 fans on a sale when a past release used the same topic.
 * Newcomers adds +2 fans and sells at 90% units.
 */
export const AUDIENCE_FANS = 2;
export const AUDIENCE_NEWCOMER_UNIT_PERCENT = 90;
export const AUDIENCES = [
  { id: "everyone", label: "Everyone", fans: 0, unitPercent: 100 },
  { id: "regulars", label: "Regulars", fans: 2, unitPercent: 100 },
  { id: "newcomers", label: "Newcomers", fans: 2, unitPercent: 90 },
] as const;
/**
 * One optional length when a product starts. Catalog adds nothing.
 * Short takes one fewer build day, never below one, and sells at 90% units.
 * Long adds one build day and sells at 110% units.
 */
export const SIZE_SHORT_UNIT_PERCENT = 90;
export const SIZE_LONG_UNIT_PERCENT = 110;
export const SIZES = [
  { id: "catalog", label: "Catalog", dayDelta: 0, unitPercent: 100 },
  { id: "short", label: "Short", dayDelta: -1, unitPercent: SIZE_SHORT_UNIT_PERCENT },
  { id: "long", label: "Long", dayDelta: 1, unitPercent: SIZE_LONG_UNIT_PERCENT },
] as const;
/**
 * One optional back-catalog listing. While a shipped product is listed, each
 * later payday pays $2 per stored review score. A patch does not change it.
 * Listing on payday itself waits until the next season.
 */
export const CATALOG_CENTS_PER_SCORE = 200;
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

/**
 * Season salary in cents. The founder is omitted and is never paid.
 * Mina is under one newsletter. Theo matches a patch. Creative matches the engine.
 */
export const SALARY_CENTS = {
  mira: 8_000,
  theo: 10_000,
  creative: 12_000,
} as const;

/**
 * One optional loan from TownSquare Treasury. $500 now, $550 back on a later payday.
 * $500 covers a full-team payday ($300) plus a patch ($100). It stays under the
 * $600 office expansion. The $50 fee is under Mina's $80 season salary.
 */
export const LOAN_LENDER = "TownSquare Treasury";
export const LOAN_AMOUNT_CENTS = 50_000;
export const LOAN_FEE_CENTS = 5_000;
export const LOAN_REPAY_CENTS = LOAN_AMOUNT_CENTS + LOAN_FEE_CENTS;

/**
 * One optional publisher for the product on the bench. Copy only.
 * $150 matches the big ad: under the $207 first newsletter, over Mina's $80,
 * and well under the $500 loan and the $600 office. 30% of that newsletter's
 * four-day window is about the same $150, so the advance is cash during the
 * build. A larger product gives up more than it got.
 */
export const PUBLISHER_NAME = "Creator Collective";
export const PUBLISHER_ADVANCE_CENTS = 15_000;
export const PUBLISHER_CUT_PERCENT = 30;

/**
 * One optional booth at the TownSquare Creator Fair. Copy only.
 * $60 is over the $40 award fee and under Mina's $80 season salary, so a
 * company that just shipped the $207 newsletter can book and still keep cash.
 * The fair pays exactly 3 fans, under that newsletter's 5. Day 14 is the
 * middle of the season: not payday, and not an existing event day.
 */
export const EXPO_NAME = "TownSquare Creator Fair";
export const EXPO_COST_CENTS = 6_000;
export const EXPO_FANS = 3;
export const EXPO_DAY_OF_SEASON = 14;

/**
 * One optional afternoon off in town. Copy only. Not a booth and not a sale.
 * $20 is under the $40 award fee, the $50 translation, and the $60 expo booth.
 * A company that just shipped the $207 newsletter can go and still keep $187.
 * The picnic pays exactly 2 fans, under the expo's 3 and that newsletter's 5.
 */
export const TOWN_DAY_NAME = "TownSquare Block Picnic";
export const TOWN_DAY_COST_CENTS = 2_000;
export const TOWN_DAY_FANS = 2;

/**
 * One optional press look at the product on the bench. Copy only.
 * $30 is unused: over the $20 town afternoon, under the $40 award fee,
 * the $50 translation, the $60 expo booth, and Mina's $80 season salary.
 * A company that just shipped the $207 newsletter can preview and still
 * keep $177. The preview pays exactly 4 fans, over the picnic's 2 and
 * the expo's 3, under that newsletter's 5. +4 from 0 does not change
 * Math.floor(reputation / 10).
 */
export const PRESS_DEMO_NAME = "TownSquare Weekly Preview";
export const PRESS_DEMO_COST_CENTS = 3_000;
export const PRESS_DEMO_FANS = 4;

/**
 * One optional creator-cut trailer for a product that is selling. Copy only.
 * Not a press look and not a sales day. $25 is unused: over the $20 town
 * afternoon, under the $30 press preview, the $40 award fee, the $50
 * translation, the $60 expo booth, and Mina's $80 season salary. A company
 * that just shipped the $207 newsletter can cut it and still keep $182.
 * The cut pays exactly 6 fans, over that newsletter's 5, on the same company
 * fan total. It does not spend an office day.
 */
export const TRAILER_NAME = "TownSquare Creator Cut";
export const TRAILER_COST_CENTS = 2_500;
export const TRAILER_FANS = 6;

/**
 * One optional creator post-mortem after sales finish. Copy only, a writeup
 * on the TownSquare blog. Not a sales day, not a press look, and not a trailer.
 * $15 is unused: under the $20 town afternoon, the $25 trailer, the $30
 * press preview, the $40 award fee, the $50 translation, the $60 expo booth,
 * and Mina's $80 season salary. A company that just shipped the $207
 * newsletter can write it and still keep $192. The writeup pays exactly 1
 * fan, under the picnic's 2 and the trailer's 6, on the same company fan
 * total. It does not spend an office day.
 */
export const DIARY_NAME = "TownSquare Post-Mortem";
export const DIARY_COST_CENTS = 1_500;
export const DIARY_FANS = 1;

/**
 * One rival creator shop per season. The same shop returns each year.
 * Shipping that topic in that season cuts opening demand to 90.
 * 90 is the same small cut Newcomers and Short use, applied once to
 * opening demand so every sales day of that release is a little quieter.
 * Ten points sits inside the ±10 swing and under the season's +20,
 * so waiting for a favored season still pays. Skipping the topic
 * leaves the sale unchanged. Spring is Cooking so the shipped
 * Crypto Alpha, Fitness, Trading, and Gaming paths stay exact.
 */
export const RIVAL_UNIT_PERCENT = 90;
export const RIVALS = [
  { shop: "Pip's Pop-up", topicId: "cooking" },
  { shop: "Harbor Goods", topicId: "trading" },
  { shop: "Lumen Kiosk", topicId: "gaming" },
  { shop: "Sable Shelf", topicId: "study_notes" },
] as const;

/**
 * One optional feature on the product on the bench. Copy only.
 * TownSquare Bonus Drop is an add-on the studio ships with that product.
 * There is no fee and no ledger row. The cost is one extra office day.
 * Opening demand becomes 110 before the curve. 110 is the same 10
 * points as Long's unit bump and the rival's cut. Long applies 110
 * after the curve. The rival applies 90 before the curve. The feature
 * uses that earlier step, in the other direction, so every sales day
 * of the release moves a little. Ten points sits inside the ±10 swing
 * and under the season's +20. The ideal grows with the extra day, so
 * working that day keeps the catalog score. The sales change is the bump.
 */
export const FEATURE_NAME = "TownSquare Bonus Drop";
export const FEATURE_DAY_DELTA = 1;
export const FEATURE_UNIT_PERCENT = 110;
/**
 * One optional emphasis for the office day on the bench. Even is the default
 * and keeps each stat's personal craft. Design, Tech, or Hype folds that
 * day's personal craft into one stat. Tool and office bonuses stay put.
 * There is no fee and no ledger row.
 */
export const DAY_PLANS = [
  { id: "even", label: "Even", stat: "even" },
  { id: "design", label: "Design", stat: "design" },
  { id: "tech", label: "Tech", stat: "tech" },
  { id: "hype", label: "Hype", stat: "hype" },
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
/** Full time is the default. Part-time is the only other pace. */
export type StaffPace = "full" | "part";
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
export type EngineId = typeof ENGINE_ID;
export type FocusId = (typeof FOCUSES)[number]["id"];
export type FocusStat = Exclude<(typeof FOCUSES)[number]["stat"], "">;
export type DayPlanId = (typeof DAY_PLANS)[number]["id"];
export type AudienceId = (typeof AUDIENCES)[number]["id"];
export type AudienceLean = Exclude<AudienceId, "everyone">;
export type AudienceOption = (typeof AUDIENCES)[number];
export type SizeId = (typeof SIZES)[number]["id"];
export type SizeLean = Exclude<SizeId, "catalog">;
export type SizeOption = (typeof SIZES)[number];

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
  { id: "cozy_gift_guide", season: "winter", dayOfSeason: 25, name: "Cozy Gift Guide", blurb: "TownSquare Weekly lists the warm shops." },
] as const;

const REVIEWERS = [
  {
    name: "TownSquare Weekly",
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

export interface LetGoOffer {
  enabled: boolean;
  reason: string;
}

export interface PaceOffer {
  value: StaffPace;
  enabled: boolean;
  reason: string;
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
  letGo: LetGoOffer;
  pace: PaceOffer;
}

interface StaffState extends CraftPoints {
  trainedDay: number | null;
  pace: StaffPace;
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
  /** Null while the product is on the bench. Omitted rows have not been translated. */
  localization: TycoonLocalizationView | null;
  /** Null when the product started with no engine. Omitted rows are no engine. */
  engine: TycoonProductEngine | null;
  /** Null when the product started Balanced. Omitted rows are Balanced. */
  focus: TycoonProductFocus | null;
  /** Null when the product started Everyone. Omitted rows are Everyone. */
  audience: TycoonProductAudience | null;
  /** Null when the product started at Catalog length. Omitted rows are Catalog. */
  size: TycoonProductSize | null;
  /** Null unless the product is in development or already signed. */
  publisher: TycoonProductPublisher | null;
  /** Null unless the product is in development or already shown. */
  pressDemo: TycoonProductPressDemo | null;
  /** Null unless the product is selling or the trailer was already made. */
  trailer: TycoonProductTrailer | null;
  /** Null unless sales have finished or the diary was already written. */
  diary: TycoonProductDiary | null;
  /** Null unless the product is in development or the feature was added. */
  feature: TycoonProductFeature | null;
  /** Null while the day is Even, and after the product leaves development. */
  dayPlan: TycoonDayPlan | null;
  /**
   * While developing, the live remaining count, bugs already cleared, and whether the next office day fixes.
   * After release, the stored count, or null when that count was 0.
   */
  bugs: TycoonBugs | number | null;
  /** While developing, idle, armed, or resting. Null after the product leaves the bench. */
  crunch: TycoonCrunch | null;
  /**
   * While developing, whether early access can ship and what it costs.
   * After release, the stored penalty when this product shipped early, otherwise null.
   */
  earlyAccess: TycoonEarlyAccess | null;
  /** While developing, the drop is available. Null once the product has shipped. */
  cancel: TycoonCancel | null;
  /** While developing, whether the next office day is held. Null once the product has shipped. */
  slip: TycoonSlip | null;
  /** While developing, whether the one pivot is still available. Null once the product has shipped. */
  pivot: TycoonPivot | null;
  /**
   * While developing, the likely review band from the current points, fit, and type weights.
   * Null once the product has shipped. The band is not stored.
   */
  playtest: TycoonPlaytest | null;
  /**
   * While developing, who is on the build and who can join.
   * Null once the product has shipped. A payload without it draws no control.
   */
  team: TycoonTeam | null;
  /**
   * While developing, whether the one research spike is free, pending, or used.
   * Null once the product has shipped. A payload without it draws no control.
   */
  researchSpike: TycoonResearchSpike | null;
  /**
   * While the product is selling, the one optional price change for the days still ahead.
   * Null on the bench and after the window. A payload without it draws no control.
   */
  salePrice: TycoonSalePrice | null;
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

export interface TycoonLocalizationView {
  edition: string;
  costCents: number;
  /** Empty until the translation starts. Selling until the extra day pays, then sold. */
  phase: "" | "selling" | "sold";
  cents: number;
  fans: number;
  enabled: boolean;
  reason: string;
}

export interface TycoonEngineView {
  id: EngineId;
  name: string;
  blurb: string;
  priceCents: number;
  scoreBonus: number;
  owned: boolean;
  enabled: boolean;
  reason: string;
}

export interface TycoonEngineOption {
  id: "none" | EngineId;
  label: string;
  scoreBonus: number;
  enabled: boolean;
  reason: string;
}

export interface TycoonProductEngine {
  id: EngineId;
  name: string;
  scoreBonus: number;
}

export interface TycoonProductFocus {
  id: FocusStat;
  label: string;
  stat: FocusStat;
  bonus: number;
}

export interface TycoonProductAudience {
  id: AudienceLean;
  label: string;
  fans: number;
  unitPercent: number;
}

export interface TycoonProductSize {
  id: SizeLean;
  label: string;
  dayDelta: number;
  unitPercent: number;
}

export interface TycoonPayroll {
  /** Next payday total. 0 when nobody besides the founder is hired. */
  cents: number;
  /** Current season's payday, for example "Spring 28". */
  payday: string;
  /** "Paid payroll · −$80" on the morning after payday. Empty otherwise. */
  notice: string;
}

/** One back-catalog slot. `productId` is null until a product is listed. */
export interface TycoonCatalog {
  productId: string | null;
  name: string;
  score: number;
  checkCents: number;
  /** Next payday that would pay this listing, for example "Spring 28". */
  payday: string;
  list: { productId: string | null; enabled: boolean; reason: string };
  delist: { enabled: boolean; reason: string };
}

export interface TycoonLoan {
  lender: string;
  amountCents: number;
  repayCents: number;
  /** Payday the outstanding loan is due, or the payday a new loan would use. */
  due: string;
  outstanding: boolean;
}

export interface TycoonExpo {
  name: string;
  costCents: number;
  fans: number;
  /** Next fair that has not reached day end, for example "Spring 14". */
  when: string;
  booked: boolean;
}

export interface TycoonTownDay {
  name: string;
  costCents: number;
  fans: number;
  /** Current season name, for example "Spring". */
  season: string;
  taken: boolean;
}

/** The rival shop pushing one topic this season. */
export interface TycoonRival {
  shop: string;
  topicId: TopicId;
  topicName: string;
  /** Opening demand percent. 90 means a matching release is a little quieter. */
  unitPercent: number;
}

export interface ExpoFair {
  year: number;
  season: SeasonId;
  seasonName: string;
  when: string;
  /** Office day the fair pays, at day end. */
  day: number;
  /** Ledger key, for example "1-spring". */
  key: string;
}

export interface TycoonProductPublisher {
  name: string;
  advanceCents: number;
  cutPercent: number;
  signed: boolean;
}

export interface TycoonProductPressDemo {
  name: string;
  costCents: number;
  fans: number;
  shown: boolean;
}

export interface TycoonProductTrailer {
  name: string;
  costCents: number;
  fans: number;
  made: boolean;
}

export interface TycoonProductDiary {
  name: string;
  costCents: number;
  fans: number;
  written: boolean;
}

export interface TycoonProductFeature {
  name: string;
  dayDelta: number;
  unitPercent: number;
  added: boolean;
}

/** The emphasis on the bench. Even is null on the product and a row in the options. */
export interface TycoonDayPlan {
  id: StatId;
  label: string;
  stat: StatId;
}

/** Live bugs on the product still on the bench. `count` is what is left. */
export interface TycoonBugs {
  count: number;
  cleared: number;
  fixing: boolean;
}

/** Crunch on the product still on the bench. Idle omits the stored flag. */
export interface TycoonCrunch {
  state: "idle" | "armed" | "resting";
}

/** Early access on the bench, or the stored penalty after an early ship. */
export interface TycoonEarlyAccess {
  enabled: boolean;
  reason: string;
  daysLeft: number;
  /** Score points this ship subtracts. Capped. 0 when the button cannot ship. */
  penalty: number;
}

/** Drop the product still on the bench. A shipped product stores null. */
export interface TycoonCancel {
  enabled: boolean;
  reason: string;
}

/** Hold the next office day. Pending means that day will not craft. A shipped product stores null. */
export interface TycoonSlip {
  enabled: boolean;
  pending: boolean;
  reason: string;
}

/** Change the topic or type of the product still on the bench. A shipped product stores null. */
export interface TycoonPivot {
  enabled: boolean;
  used: boolean;
  reason: string;
  options: {
    topics: Array<{ id: TopicId; name: string; unlocked: boolean }>;
    types: Array<{ id: ProductTypeId; name: string; unlocked: boolean }>;
  };
}

/**
 * Likely review band of the product still on the bench.
 * Computed on read. Null before the first office day, and null once the product ships.
 */
export interface TycoonPlaytest {
  enabled: boolean;
  band: "low" | "mid" | "high" | null;
  reason: string;
}

/** Who is on the product still on the bench. A shipped product stores null. */
export interface TycoonTeam {
  enabled: boolean;
  members: Array<{ id: StaffId; name: string; onTeam: boolean }>;
  reason: string;
}

/**
 * One research spike on the product still on the bench.
 * `points` is the personal craft converted on the spike day. 0 until that day lands.
 */
export interface TycoonResearchSpike {
  enabled: boolean;
  pending: boolean;
  used: boolean;
  reason: string;
  points: number;
}

/**
 * One price change while the product is selling.
 * `currentPercent` is what the days still ahead use. `options` are the launch-price rows.
 */
export interface TycoonSalePrice {
  enabled: boolean;
  used: boolean;
  currentPercent: LaunchPricePercent;
  options: LaunchPriceStep[];
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
  letGoNotice: string;
  researchPoints: number;
  researchNotice: string;
  upgradeNotice: string;
  upgrades: TycoonUpgradeView[];
  calendar: TycoonCalendar;
  payroll: TycoonPayroll;
  catalog: TycoonCatalog;
  loan: TycoonLoan;
  expo: TycoonExpo;
  townDay: TycoonTownDay;
  rival: TycoonRival;
  office: TycoonOffice;
  priceSteps: LaunchPriceStep[];
  marketingOptions: Array<MarketingOption & { enabled: boolean; reason: string }>;
  engineNotice: string;
  engine: TycoonEngineView;
  engineOptions: TycoonEngineOption[];
  focusOptions: Array<(typeof FOCUSES)[number]>;
  audienceOptions: Array<(typeof AUDIENCES)[number]>;
  sizeOptions: Array<(typeof SIZES)[number]>;
  dayPlanOptions: Array<(typeof DAY_PLANS)[number]>;
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

/** Payday check for a stored review score. 0 when the score is not a positive integer. */
export function catalogCheckCents(score: number): number {
  if (!Number.isInteger(score) || score <= 0) return 0;
  return score * CATALOG_CENTS_PER_SCORE;
}

/**
 * First season-end day that pays a listing.
 * A null listed day previews a listing made today, so payday itself waits a season.
 * A listing from an earlier day still pays when today is that payday.
 */
export function catalogPaydayDay(today: number, listedDay: number | null): number {
  const threshold = listedDay === null ? today : listedDay;
  let end = SEASON_LENGTH_DAYS;
  while (end <= threshold) end += SEASON_LENGTH_DAYS;
  while (end < today) end += SEASON_LENGTH_DAYS;
  return end;
}

/**
 * Season salary for these hired ids. The founder and unknown ids add nothing.
 * Duplicates count once. A part-time id pays half, rounded down. Omitted pace is full time.
 */
export function payrollCents(staffIds: readonly string[], pace: Readonly<Record<string, string | undefined>> = {}): number {
  const seen = new Set<string>();
  let total = 0;
  for (const id of staffIds) {
    if (seen.has(id)) continue;
    seen.add(id);
    const cents = SALARY_CENTS[id as keyof typeof SALARY_CENTS];
    if (typeof cents !== "number") continue;
    total += pace[id] === "part" ? Math.floor(cents / 2) : cents;
  }
  return total;
}

/**
 * Payday a loan taken on this office day is due. This season's last day, or the
 * next season when the take itself falls on payday, so the same evening does
 * not take the $550 back.
 */
export function loanDueDay(fromDay: number): number {
  const safe = Math.max(1, Math.trunc(Number.isFinite(fromDay) ? fromDay : 1));
  const thisPayday = (Math.floor((safe - 1) / SEASON_LENGTH_DAYS) + 1) * SEASON_LENGTH_DAYS;
  return safe < thisPayday ? thisPayday : thisPayday + SEASON_LENGTH_DAYS;
}

/**
 * The fair that still pays if today ends on it. Day 14 of this season, or of
 * the next season once day 14 has passed. Booking on the fair day still catches
 * that evening.
 */
export function nextExpoFair(fromDay: number): ExpoFair {
  const safe = Math.max(1, Math.trunc(Number.isFinite(fromDay) ? fromDay : 1));
  const calendar = calendarForDay(safe);
  let seasonIndex = SEASONS.findIndex((item) => item.id === calendar.season);
  let year = calendar.year;
  if (calendar.dayOfSeason > EXPO_DAY_OF_SEASON) {
    seasonIndex += 1;
    if (seasonIndex >= SEASONS.length) {
      seasonIndex = 0;
      year += 1;
    }
  }
  const season = SEASONS[seasonIndex] ?? SEASONS[0];
  return {
    year,
    season: season.id,
    seasonName: season.name,
    when: `${season.name} ${EXPO_DAY_OF_SEASON}`,
    day: (year - 1) * YEAR_LENGTH_DAYS + seasonIndex * SEASON_LENGTH_DAYS + EXPO_DAY_OF_SEASON,
    key: `${year}-${season.id}`,
  };
}

/**
 * Publisher share of one sales row. `Math.round((cents * 30) / 100)`, the same
 * half-up rounding as the unit percents. The company keeps the rest. A 1-cent
 * sale rounds the 0.3 cent share to 0. A 2-cent sale rounds 0.6 to 1.
 */
export function publisherCutCents(cents: number): number {
  if (!Number.isInteger(cents) || cents <= 0) return 0;
  return Math.round((cents * PUBLISHER_CUT_PERCENT) / 100);
}

/** Sales cents posted for a signed product. Fans stay on the gross sale. */
export function publisherNetCents(cents: number): number {
  return Math.max(0, cents - publisherCutCents(cents));
}

/** Player-facing payday, for example "Spring 28". */
export function paydayLabel(day: number): string {
  return `${calendarForDay(day).seasonName} ${SEASON_LENGTH_DAYS}`;
}

/** This season's town-day ledger key, for example "1-spring". */
export function townDaySeason(fromDay: number): { year: number; season: SeasonId; seasonName: string; key: string } {
  const calendar = calendarForDay(fromDay);
  return {
    year: calendar.year,
    season: calendar.season,
    seasonName: calendar.seasonName,
    key: `${calendar.year}-${calendar.season}`,
  };
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

function asEngine(value: string): "none" | EngineId {
  if (value === "none" || value === ENGINE_ID) return value;
  throw new Error("Pick None or TownSquare Kit Engine.");
}

function engineOffer(owned: boolean, cash: number): TycoonEngineView {
  let reason = "";
  if (owned) reason = "Already owned.";
  else if (cash < ENGINE_COST_CENTS) reason = `Need ${wholeDollars(ENGINE_COST_CENTS)}`;
  return {
    id: ENGINE_ID,
    name: ENGINE_NAME,
    blurb: ENGINE_BLURB,
    priceCents: ENGINE_COST_CENTS,
    scoreBonus: ENGINE_SCORE_BONUS,
    owned,
    enabled: reason === "",
    reason,
  };
}

function engineChoices(owned: boolean): TycoonEngineOption[] {
  return [
    { id: "none", label: "None", scoreBonus: 0, enabled: true, reason: "" },
    {
      id: ENGINE_ID,
      label: ENGINE_NAME,
      scoreBonus: ENGINE_SCORE_BONUS,
      enabled: owned,
      reason: owned ? "" : "Buy it first.",
    },
  ];
}

export function focusById(id: string): (typeof FOCUSES)[number] | undefined {
  return FOCUSES.find((item) => item.id === id);
}

/** Unknown or omitted values are Balanced. */
export function normalizeFocus(value: unknown): FocusId {
  return typeof value === "string" && focusById(value) ? value as FocusId : "balanced";
}

function asFocus(value: string): FocusId {
  const option = focusById(value);
  if (!option) throw new Error("Pick Balanced, Design, Tech, or Hype.");
  return option.id;
}

/** +1 on the chosen stat. Balanced adds nothing. A stat already at the training cap stays there. */
export function applyFocusPoints(points: CraftPoints, focus: unknown): CraftPoints {
  const id = normalizeFocus(focus);
  if (id === "balanced") return points;
  const current = points[id];
  if (current >= STAT_CAP) return points;
  return { ...points, [id]: Math.min(STAT_CAP, current + FOCUS_BONUS) };
}

function focusView(stat: FocusStat | null): TycoonProductFocus | null {
  if (!stat) return null;
  return { id: stat, label: statLabel(stat), stat, bonus: FOCUS_BONUS };
}

export function audienceById(id: string): AudienceOption | undefined {
  return AUDIENCES.find((item) => item.id === id);
}

/** Unknown or omitted values are Everyone. */
export function normalizeAudience(value: unknown): AudienceId {
  return typeof value === "string" && audienceById(value) ? value as AudienceId : "everyone";
}

function asAudience(value: string): AudienceId {
  const option = audienceById(value);
  if (!option) throw new Error("Pick Everyone, Regulars, or Newcomers.");
  return option.id;
}

function parseAudience(value: unknown): AudienceLean | null {
  if (value === "regulars" || value === "newcomers") return value;
  return null;
}

function audienceView(id: AudienceLean | null): TycoonProductAudience | null {
  if (!id) return null;
  const option = audienceById(id);
  if (!option || option.id === "everyone") return null;
  return { id, label: option.label, fans: option.fans, unitPercent: option.unitPercent };
}

/** Newcomers sell at 90% units. Everyone and Regulars leave units unchanged. Always at least 1. */
export function applyAudienceUnits(units: number, id: unknown): number {
  const option = audienceById(normalizeAudience(id));
  const percent = option?.unitPercent ?? 100;
  if (percent === 100) return Math.max(1, units);
  return Math.max(1, Math.round((units * percent) / 100));
}

/**
 * Extra fans for one sale. Regulars only pay when a past release used the same topic.
 * Newcomers always add the stored bump. Everyone adds nothing.
 */
export function audienceFansForSale(id: unknown, topicMatch: boolean): number {
  const option = audienceById(normalizeAudience(id));
  if (!option || option.fans <= 0) return 0;
  if (option.id === "regulars" && !topicMatch) return 0;
  return option.fans;
}

export function sizeById(id: string): SizeOption | undefined {
  return SIZES.find((item) => item.id === id);
}

/** Unknown or omitted values are Catalog. */
export function normalizeSize(value: unknown): SizeId {
  return typeof value === "string" && sizeById(value) ? value as SizeId : "catalog";
}

function asSize(value: string): SizeId {
  const option = sizeById(value);
  if (!option) throw new Error("Pick Catalog, Short, or Long.");
  return option.id;
}

function parseSize(value: unknown): SizeLean | null {
  if (value === "short" || value === "long") return value;
  return null;
}

function sizeView(id: SizeLean | null): TycoonProductSize | null {
  if (!id) return null;
  const option = sizeById(id);
  if (!option || option.id === "catalog") return null;
  return { id, label: option.label, dayDelta: option.dayDelta, unitPercent: option.unitPercent };
}

/** Short sells at 90% units. Long sells at 110%. Catalog leaves units unchanged. Always at least 1. */
export function applySizeUnits(units: number, id: unknown): number {
  const option = sizeById(normalizeSize(id));
  const percent = option?.unitPercent ?? 100;
  if (percent === 100) return Math.max(1, units);
  return Math.max(1, Math.round((units * percent) / 100));
}

/** Short skips one office day and never drops below one. Long adds one. Catalog keeps the catalog length. */
export function sizedDevDays(catalogDays: number, size: unknown): number {
  const id = normalizeSize(size);
  if (id === "short") return Math.max(1, catalogDays - 1);
  if (id === "long") return catalogDays + 1;
  return catalogDays;
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

/** Part-time keeps half of each stat, rounded down. Full time returns the same points. */
export function pacedCraft(points: CraftPoints, pace: StaffPace): CraftPoints {
  if (pace !== "part") return points;
  return {
    design: Math.floor(points.design / 2),
    tech: Math.floor(points.tech / 2),
    hype: Math.floor(points.hype / 2),
  };
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

function sameStaffIds(left: readonly string[], right: readonly string[]): boolean {
  if (left.length !== right.length) return false;
  const wanted = new Set(right);
  return left.every((id) => wanted.has(id));
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
  /** Null until the product has a translated edition. */
  localization: ProductLocalization | null;
  /** Null when development started with no engine. */
  engine: EngineId | null;
  /** Null when development started Balanced. */
  focus: FocusStat | null;
  /** Null when development started Everyone. */
  audience: AudienceLean | null;
  /** Null when development started at Catalog length. */
  size: SizeLean | null;
  /** True after this product signs the one publisher deal. */
  publisher: boolean;
  /** True after this product shows the one press demo. */
  pressDemo: boolean;
  /** True after this product cuts the one launch trailer. */
  trailer: boolean;
  /** True after this product writes the one dev diary. */
  diary: boolean;
  /** True when this release shipped into the season rival's topic. */
  rivalCut: boolean;
  /** True after this product adds the one feature. */
  feature: boolean;
  /** True once release stores the opening-demand bump. Later sales reuse it. */
  featureDemand: boolean;
  /** Null spends the day on the even split. Design, tech, or hype folds personal craft. */
  dayPlan: StatId | null;
  /** Bugs stored at release. 0 omits the key. Later sales do not recompute this. */
  bugs: number;
  /** Bugs already cleared during development. 0 omits the key. */
  bugsCleared: number;
  /** True when the next office day spends personal craft on clearing bugs. */
  fixBugs: boolean;
  /** Armed doubles the next personal craft. Resting zeroes the day after. Null is idle. */
  crunch: "armed" | "resting" | null;
  /** Bugs added by armed crunch days. 0 omits the key. */
  crunchBugs: number;
  /** True when this product shipped before its required days. */
  earlyAccess: boolean;
  /** Missing office days at that early ship. 0 omits the key. The score penalty caps this. */
  earlyDays: number;
  /** True when the next office day holds this product. The calendar still moves. */
  slip: boolean;
  /** True after this product has used its one pivot. */
  pivoted: boolean;
  /** Pending converts the next office day's personal craft. Used means this build already spiked. */
  researchSpike: "pending" | "used" | null;
  /** Personal craft converted on the spike day. 0 omits the key. */
  researchSpikePoints: number;
  /** Null until the one sale-price change. Remaining sales days use this percent. */
  salePricePercent: LaunchPricePercent | null;
  /** Office day this shipped product was listed. Null means it is not in the back catalog. */
  catalogDay: number | null;
}

interface ProductPort {
  shelf: string;
  startedDay: number;
  /** Null while the extra sales day has not paid. */
  cents: number | null;
  fans: number | null;
}

interface ProductLocalization {
  edition: string;
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
    localization: null,
    engine: null,
    focus: null,
    audience: null,
    size: null,
    publisher: false,
    pressDemo: false,
    trailer: false,
    diary: false,
    rivalCut: false,
    feature: false,
    featureDemand: false,
    dayPlan: null,
    bugs: 0,
    bugsCleared: 0,
    fixBugs: false,
    crunch: null,
    crunchBugs: 0,
    earlyAccess: false,
    earlyDays: 0,
    slip: false,
    pivoted: false,
    researchSpike: null,
    researchSpikePoints: 0,
    salePricePercent: null,
    catalogDay: null,
  };
}

function parseProductId(value: unknown): string | null {
  return typeof value === "string" && /^p[1-9][0-9]*$/u.test(value) ? value : null;
}

/** Older rows are a staff array and count as catalog price, no bonus, no ad, no contract, unpatched, no sequel, no award, no port, no translation, no engine, Balanced, Everyone, Catalog length, no publisher, no press demo, no trailer, no diary, no rival cut, no feature, an even day plan, no stored bugs, not fixing, not crunching, 0 crunch bugs, not an early ship, not holding the next day, not pivoted, not on a research spike, no sale price, and no catalog listing. */
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
    localization?: unknown;
    engine?: unknown;
    focus?: unknown;
    audience?: unknown;
    size?: unknown;
    publisher?: unknown;
    pressDemo?: unknown;
    trailer?: unknown;
    diary?: unknown;
    rivalCut?: unknown;
    feature?: unknown;
    featureDemand?: unknown;
    dayPlan?: unknown;
    bugs?: unknown;
    bugsCleared?: unknown;
    fixBugs?: unknown;
    crunch?: unknown;
    crunchBugs?: unknown;
    earlyAccess?: unknown;
    earlyDays?: unknown;
    slip?: unknown;
    pivoted?: unknown;
    researchSpike?: unknown;
    researchSpikePoints?: unknown;
    salePricePercent?: unknown;
    catalogDay?: unknown;
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
    localization: parseLocalization(body.localization),
    engine: body.engine === ENGINE_ID ? ENGINE_ID : null,
    focus: parseFocus(body.focus),
    audience: parseAudience(body.audience),
    size: parseSize(body.size),
    publisher: body.publisher === true,
    pressDemo: body.pressDemo === true,
    trailer: body.trailer === true,
    diary: body.diary === true,
    rivalCut: body.rivalCut === true,
    feature: body.feature === true,
    featureDemand: body.featureDemand === true,
    dayPlan: parseDayPlan(body.dayPlan),
    bugs: parseStoredBugs(body.bugs),
    bugsCleared: parseBugsCleared(body.bugsCleared),
    fixBugs: body.fixBugs === true,
    crunch: parseCrunch(body.crunch),
    crunchBugs: parseCrunchBugs(body.crunchBugs),
    earlyAccess: body.earlyAccess === true,
    earlyDays: parseEarlyDays(body.earlyDays),
    slip: body.slip === true,
    pivoted: body.pivoted === true,
    researchSpike: parseResearchSpike(body.researchSpike),
    researchSpikePoints: parseResearchSpikePoints(body.researchSpikePoints),
    salePricePercent: parseSalePricePercent(body.salePricePercent),
    catalogDay: parseCatalogDay(body.catalogDay),
  };
}

function parseCatalogDay(value: unknown): number | null {
  const day = Number(value);
  if (!Number.isInteger(day) || day < 1) return null;
  return day;
}

function parseSalePricePercent(value: unknown): LaunchPricePercent | null {
  const amount = Number(value);
  return isLaunchPricePercent(amount) ? amount : null;
}

function parseResearchSpike(value: unknown): "pending" | "used" | null {
  if (value === "pending" || value === "used") return value;
  return null;
}

function parseResearchSpikePoints(value: unknown): number {
  const points = Number(value);
  if (!Number.isInteger(points) || points <= 0) return 0;
  return points;
}

function parseStoredBugs(value: unknown): number {
  const count = Number(value);
  if (!Number.isInteger(count) || count <= 0) return 0;
  return Math.min(5, count);
}

function parseBugsCleared(value: unknown): number {
  const cleared = Number(value);
  if (!Number.isInteger(cleared) || cleared <= 0) return 0;
  return cleared;
}

function parseCrunch(value: unknown): "armed" | "resting" | null {
  if (value === "armed" || value === "resting") return value;
  return null;
}

function parseCrunchBugs(value: unknown): number {
  const count = Number(value);
  if (!Number.isInteger(count) || count <= 0) return 0;
  return count;
}

function parseEarlyDays(value: unknown): number {
  const days = Number(value);
  if (!Number.isInteger(days) || days <= 0) return 0;
  return days;
}

/** One point per missing office day, and no more than the cap. Zero when the count is not a positive integer. */
export function earlyAccessPenalty(missingDays: number): number {
  const missing = Number(missingDays);
  if (!Number.isInteger(missing) || missing <= 0) return 0;
  return Math.min(EARLY_ACCESS_PENALTY_CAP, missing);
}

function parseDayPlan(value: unknown): StatId | null {
  if (value === "design" || value === "tech" || value === "hype") return value;
  return null;
}

function asDayPlan(value: string): DayPlanId {
  if (value === "even" || value === "design" || value === "tech" || value === "hype") return value;
  throw new Error("Pick Even, Design, Tech, or Hype.");
}

/** Even keeps the split. An emphasis moves the whole personal total onto one stat. */
export function personalForDayPlan(personal: CraftPoints, plan: StatId | null): CraftPoints {
  if (!plan) return personal;
  const total = personal.design + personal.tech + personal.hype;
  return {
    design: plan === "design" ? total : 0,
    tech: plan === "tech" ? total : 0,
    hype: plan === "hype" ? total : 0,
  };
}

/** Spread between the highest and lowest craft stat, one bug per four points, capped at 5. */
export function bugCount(points: CraftPoints): number {
  const high = Math.max(points.design, points.tech, points.hype);
  const low = Math.min(points.design, points.tech, points.hype);
  return Math.min(5, Math.floor((high - low) / 4));
}

/** Spread bugs plus crunch bugs, minus clears. Never below 0 or above 5. */
export function liveBugs(points: CraftPoints, crunchBugs: number, bugsCleared: number): number {
  return Math.min(5, Math.max(0, bugCount(points) + crunchBugs - bugsCleared));
}

/** Bugs one fix day clears from personal craft. Nothing clears when that craft is 0. */
export function bugsClearedGain(personalTotal: number): number {
  if (!Number.isInteger(personalTotal) || personalTotal <= 0) return 0;
  return Math.max(1, Math.floor(personalTotal / 4));
}

function parseFocus(value: unknown): FocusStat | null {
  if (value === "design" || value === "tech" || value === "hype") return value;
  return null;
}

function awardFans(outcome: AwardOutcome): number {
  if (outcome === "won") return AWARD_WIN_FANS;
  if (outcome === "nominated") return AWARD_NOMINEE_FANS;
  return 0;
}

function parsePort(value: unknown): ProductPort | null {
  if (!value || typeof value !== "object") return null;
  const body = value as { shelf?: unknown; startedDay?: unknown; cents?: unknown; fans?: unknown };
  if (fictionalWorld(body.shelf) !== PORT_SHELF) return null;
  const startedDay = Number(body.startedDay);
  if (!Number.isInteger(startedDay) || startedDay < 1) return null;
  if (body.cents === undefined && body.fans === undefined) return { shelf: PORT_SHELF, startedDay, cents: null, fans: null };
  const cents = Number(body.cents);
  const fans = Number(body.fans);
  if (!Number.isInteger(cents) || cents < 0 || !Number.isInteger(fans) || fans < 0) return null;
  return { shelf: PORT_SHELF, startedDay, cents, fans };
}

function parseLocalization(value: unknown): ProductLocalization | null {
  if (!value || typeof value !== "object") return null;
  const body = value as { edition?: unknown; startedDay?: unknown; cents?: unknown; fans?: unknown };
  if (body.edition !== LOCALIZE_EDITION) return null;
  const startedDay = Number(body.startedDay);
  if (!Number.isInteger(startedDay) || startedDay < 1) return null;
  if (body.cents === undefined && body.fans === undefined) return { edition: LOCALIZE_EDITION, startedDay, cents: null, fans: null };
  const cents = Number(body.cents);
  const fans = Number(body.fans);
  if (!Number.isInteger(cents) || cents < 0 || !Number.isInteger(fans) || fans < 0) return null;
  return { edition: LOCALIZE_EDITION, startedDay, cents, fans };
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
  if (stored.localization) {
    body.localization = stored.localization.cents === null
      ? { edition: stored.localization.edition, startedDay: stored.localization.startedDay }
      : { edition: stored.localization.edition, startedDay: stored.localization.startedDay, cents: stored.localization.cents, fans: stored.localization.fans };
  }
  if (stored.engine === ENGINE_ID) {
    body.engine = ENGINE_ID;
    body.engineBonus = ENGINE_SCORE_BONUS;
  }
  if (stored.focus) {
    body.focus = stored.focus;
    body.focusBonus = FOCUS_BONUS;
  }
  if (stored.audience) body.audience = stored.audience;
  if (stored.size) body.size = stored.size;
  if (stored.publisher) body.publisher = true;
  if (stored.pressDemo) body.pressDemo = true;
  if (stored.trailer) body.trailer = true;
  if (stored.diary) body.diary = true;
  if (stored.rivalCut) body.rivalCut = true;
  if (stored.feature) body.feature = true;
  if (stored.featureDemand) body.featureDemand = true;
  if (stored.dayPlan) body.dayPlan = stored.dayPlan;
  if (stored.bugs > 0) body.bugs = stored.bugs;
  if (stored.bugsCleared > 0) body.bugsCleared = stored.bugsCleared;
  if (stored.fixBugs) body.fixBugs = true;
  if (stored.crunch) body.crunch = stored.crunch;
  if (stored.crunchBugs > 0) body.crunchBugs = stored.crunchBugs;
  if (stored.earlyAccess) {
    body.earlyAccess = true;
    if (stored.earlyDays > 0) body.earlyDays = stored.earlyDays;
  }
  if (stored.slip) body.slip = true;
  if (stored.pivoted) body.pivoted = true;
  if (stored.researchSpike) body.researchSpike = stored.researchSpike;
  if (stored.researchSpikePoints > 0) body.researchSpikePoints = stored.researchSpikePoints;
  if (stored.salePricePercent !== null) body.salePricePercent = stored.salePricePercent;
  if (stored.catalogDay !== null) body.catalogDay = stored.catalogDay;
  return JSON.stringify(body);
}

/** A sequel skips one office day and never drops below one. */
export function sequelDevDays(catalogDays: number): number {
  return Math.max(1, catalogDays - SEQUEL_DAYS_SAVED);
}

/** Catalog length, the sized length, or the shorter sequel length, plus one when a feature was added. A sequel ignores size. */
export function requiredDevDays(catalogDays: number, isSequel: boolean, size: unknown = null, feature = false): number {
  const base = isSequel ? sequelDevDays(catalogDays) : sizedDevDays(catalogDays, size);
  return feature ? base + FEATURE_DAY_DELTA : base;
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

/** Same cuts the review blurbs use. 8 or more is high. 5 to 7 is mid. Below that is low. */
export function reviewBand(score: number): "high" | "mid" | "low" {
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
  /** Engine bump stored on the product. Omitted is 0. Added with the sequel bonus, then clamped to 1–10. */
  engineBonus?: number;
  /** Days required for the ideal. Omitted uses the catalog length. */
  devDays?: number;
  /** Stored bug count. Omitted or 0 leaves the base alone. 1–5 subtracts before the clamp. */
  bugs?: number;
  /** Missing office days on an early ship. Omitted is 0. Capped, then subtracted with bugs. */
  earlyPenalty?: number;
}): TycoonReview {
  const carried = input.sequelBonus === SEQUEL_SCORE_BONUS ? SEQUEL_SCORE_BONUS : 0;
  const engineBonus = input.engineBonus === ENGINE_SCORE_BONUS ? ENGINE_SCORE_BONUS : 0;
  const bugs = Number.isInteger(input.bugs) && (input.bugs ?? 0) >= 1 && (input.bugs ?? 0) <= 5 ? input.bugs ?? 0 : 0;
  const early = earlyAccessPenalty(input.earlyPenalty ?? 0);
  const base = clampScore(baseScore(
    { design: input.design, tech: input.tech, hype: input.hype },
    input.topicId,
    input.typeId,
    input.researchBonus ?? 0,
    input.devDays ?? 0,
  ) + carried + engineBonus - bugs - early);
  const reviewers = REVIEWERS.map((reviewer, index) => {
    const jitter = (mixSeed(input.seed, input.productId, "review", index) % 3) - 1;
    const score = clampScore(base + jitter);
    return { name: reviewer.name, score, blurb: reviewer.blurbs[reviewBand(score)] };
  });
  const score = clampScore(Math.round(reviewers.reduce((sum, reviewer) => sum + reviewer.score, 0) / reviewers.length));
  return { score, reviewers };
}

/** Opening demand before the curve and the swing. A stored feature bump uses 110, then a stored rival cut uses 90. Each rounds once. */
export function openingDemand(fit: Fit, score: number, reputation: number, rivalCut = false, featureDemand = false): number {
  let base = FIT_UNITS[fit] + Math.floor((score * 3) / 2) + Math.floor(reputation / 10);
  if (featureDemand) base = Math.max(1, Math.round((base * FEATURE_UNIT_PERCENT) / 100));
  if (rivalCut) base = Math.max(1, Math.round((base * RIVAL_UNIT_PERCENT) / 100));
  return base;
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
  /**
   * Unit percent after size. Omitted is 100 and leaves the sale unchanged.
   * A translation passes 50. A normal day and a port do not.
   */
  quietPercent?: number;
  /** Launch price as a percent of the catalog. Omitted is catalog (100). */
  pricePercent?: number;
  /** Ad id stored on the product. Omitted is no ad. */
  marketing?: string;
  /** Audience id stored on the product. Omitted is Everyone. */
  audience?: string;
  /** True when a past release used this product's topic. Regulars needs this. */
  topicMatch?: boolean;
  /** Size id stored on the product. Omitted is Catalog. */
  size?: string;
  /** True when this release shipped into the season rival's topic. Omitted leaves opening demand alone. */
  rivalCut?: boolean;
  /** True when release stored the feature's opening-demand bump. Omitted leaves that step alone. */
  featureDemand?: boolean;
}): TycoonSales {
  const curve = curvePercent(input.dayIndex);
  const type = typeById(input.typeId);
  if (curve === undefined || !type) throw new Error("Sales day is outside the window");
  const swing = (mixSeed(input.seed, input.productId, "sales", input.dayIndex) % 21) - 10;
  const baseUnits = openingDemand(input.fit, input.score, input.reputation, input.rivalCut === true, input.featureDemand === true);
  // Units: opening demand, launch price, season, marketing, audience, size. Fans follow those units.
  // Price: launch price, then checkout. Cash is units times that price.
  let units = Math.max(1, Math.round((baseUnits * curve * (100 + swing)) / 10000));
  const pricePercent = normalizeLaunchPricePercent(input.pricePercent);
  units = applyLaunchPriceUnits(units, pricePercent);
  const unitBoost = input.unitBoostPercent ?? 0;
  if (Number.isInteger(unitBoost) && unitBoost > 0) {
    units = Math.max(1, Math.round((units * (100 + unitBoost)) / 100));
  }
  units = applyMarketingUnits(units, input.marketing);
  units = applyAudienceUnits(units, input.audience);
  units = applySizeUnits(units, input.size);
  const quietPercent = input.quietPercent ?? 100;
  if (quietPercent !== 100) {
    units = Math.max(1, Math.round((units * quietPercent) / 100));
  }
  const fanPermille = input.score >= 8 ? 400 : input.score >= 5 ? 200 : 100;
  const bonusFans = Number.isInteger(input.bonusFans) && (input.bonusFans ?? 0) > 0 ? (input.bonusFans as number) : 0;
  const fans = Math.max(1, Math.round((units * fanPermille) / 1000)) + bonusFans + audienceFansForSale(input.audience, input.topicMatch === true);
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

/** 0 is the first spring. The rival list repeats every four seasons. */
export function seasonIndexForDay(day: number): number {
  const safe = Math.max(1, Math.trunc(Number.isFinite(day) ? day : 1));
  return Math.floor((safe - 1) / SEASON_LENGTH_DAYS);
}

/** The shop and topic for this office day. Day 1 and day 113 are the same shop. */
export function rivalForDay(day: number): TycoonRival {
  const rival = RIVALS[seasonIndexForDay(day) % RIVALS.length] ?? RIVALS[0];
  const topic = topicById(rival.topicId);
  return {
    shop: rival.shop,
    topicId: rival.topicId,
    topicName: topic?.name ?? rival.topicId,
    unitPercent: RIVAL_UNIT_PERCENT,
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
  private engineNotice = "";
  private engineNoticeDay = 0;
  private payrollNotice = "";
  private payrollNoticeDay = 0;

  constructor(
    private readonly db: SqlDatabase,
    private readonly journey: JourneyStore,
    private readonly onOfficeChanged: () => void = () => {},
  ) {}

  view(): TycoonSnapshot {
    const hired = this.hiredIds();
    const dismissed = this.dismissedIds();
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
    const engineOwned = this.loadEngineOwned();
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
          letGo: this.letGoOffer(person.id, person.name, isHired, dismissed.has(person.id)),
          pace: this.paceOffer(person.id, person.name, isHired, dismissed.has(person.id), current.pace),
        };
      }),
      trainingNotice: this.trainingNoticeDay === day ? this.trainingNotice : "",
      letGoNotice: this.letGoNotice(dismissed),
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
      payroll: this.payrollView(day, hired),
      catalog: this.catalogView(day),
      loan: this.loanView(day),
      expo: this.expoView(day),
      townDay: this.townDayView(day),
      rival: rivalForDay(day),
      office: this.officeView(this.officeLevel(), hired.size, cash),
      priceSteps: [...LAUNCH_PRICES],
      marketingOptions: marketingOffer(cash),
      engineNotice: this.engineNoticeDay === day ? this.engineNotice : "",
      engine: engineOffer(engineOwned, cash),
      engineOptions: engineChoices(engineOwned),
      focusOptions: [...FOCUSES],
      audienceOptions: [...AUDIENCES],
      sizeOptions: [...SIZES],
      dayPlanOptions: [...DAY_PLANS],
      contract: this.contractOffer(developing),
      patchNotice: this.patchNoticeDay === day ? this.patchNotice : "",
      developing: developing ? this.toView(developing) : null,
      history,
    };
  }

  start(topicValue: string, typeValue: string, requestedStaff: readonly string[], pricePercentValue?: number, marketingValue?: string, engineValue?: string, focusValue?: string, audienceValue?: string, sizeValue?: string): ReturnType<JourneyStore["state"]> {
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
      const engine = engineValue === undefined ? "none" : asEngine(engineValue);
      const focus = focusValue === undefined ? "balanced" : asFocus(focusValue);
      const audience = audienceValue === undefined ? "everyone" : asAudience(audienceValue);
      const size = sizeValue === undefined ? "catalog" : asSize(sizeValue);
      if (engine === ENGINE_ID && !this.loadEngineOwned()) throw new Error("Buy the engine first.");
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
      const id = this.nextProductId();
      if (option.costCents > 0) {
        this.journey.recordCompanyChange(`tycoon:marketing:${id}`, this.day(), -option.costCents, 0, 0, option.label);
      }
      const snapshot: {
        staff: StaffSnapshot[];
        researchBonus: number;
        pricePercent: LaunchPricePercent;
        marketing: MarketingId;
        contract?: ProductContract;
        engine?: EngineId;
        engineBonus?: number;
        focus?: FocusStat;
        focusBonus?: number;
        audience?: AudienceLean;
        size?: SizeLean;
      } = {
        staff: staffIds.map((memberId) => ({
          id: memberId, design: stats[memberId].design, tech: stats[memberId].tech, hype: stats[memberId].hype,
        })),
        researchBonus,
        pricePercent,
        marketing,
      };
      if (engine === ENGINE_ID) {
        snapshot.engine = ENGINE_ID;
        snapshot.engineBonus = ENGINE_SCORE_BONUS;
      }
      if (focus !== "balanced") {
        snapshot.focus = focus;
        snapshot.focusBonus = FOCUS_BONUS;
      }
      if (audience !== "everyone") snapshot.audience = audience;
      if (size !== "catalog") snapshot.size = size;
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

  buyEngine(idValue: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      if (idValue !== ENGINE_ID) throw new Error("Unknown engine.");
      if (this.loadEngineOwned()) throw new Error("Already owned.");
      if (this.cashCents() < ENGINE_COST_CENTS) throw new Error(`Need ${wholeDollars(ENGINE_COST_CENTS)}`);
      const day = this.day();
      this.journey.recordCompanyChange(
        "tycoon:engine",
        day,
        -ENGINE_COST_CENTS,
        0,
        0,
        `Engine: ${ENGINE_NAME}`,
      );
      this.saveEngineOwned();
      this.engineNotice = `Bought ${ENGINE_NAME}. −${wholeDollars(ENGINE_COST_CENTS)}`;
      this.engineNoticeDay = day;
      return this.journey.state();
    });
  }

  takeLoan(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      if (this.outstandingLoan()) throw new Error("A loan is already out.");
      const n = this.nextLoanNumber();
      const day = this.day();
      this.journey.recordCompanyChange(
        `tycoon:loan:${n}:taken`,
        day,
        LOAN_AMOUNT_CENTS,
        0,
        0,
        `Loan: ${LOAN_LENDER}`,
      );
      return this.journey.state();
    });
  }

  /** One booth at the next fair. The fee is one ledger row. Fans wait for that day end. */
  bookBooth(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const fair = nextExpoFair(this.day());
      const id = `tycoon:expo:${fair.key}:booth`;
      if (this.transactionExists(id)) throw new Error("Already booked.");
      if (this.cashCents() < EXPO_COST_CENTS) throw new Error(`Need ${wholeDollars(EXPO_COST_CENTS)}`);
      this.journey.recordCompanyChange(id, this.day(), -EXPO_COST_CENTS, 0, 0, `Booth: ${EXPO_NAME}`);
      return this.journey.state();
    });
  }

  /** One afternoon off this season. The fee row also grants the fans. No office day is spent. */
  takeTownDay(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const season = townDaySeason(this.day());
      const id = `tycoon:townday:${season.key}:fee`;
      if (this.transactionExists(id)) throw new Error("Already took the afternoon.");
      if (this.cashCents() < TOWN_DAY_COST_CENTS) throw new Error(`Need ${wholeDollars(TOWN_DAY_COST_CENTS)}`);
      this.journey.recordCompanyChange(id, this.day(), -TOWN_DAY_COST_CENTS, 0, TOWN_DAY_FANS, `Town day: ${TOWN_DAY_NAME}`);
      return this.journey.state();
    });
  }

  /** One deal for the product on the bench. The advance is one ledger row. */
  signPublisher(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.publisher) throw new Error("Already signed.");
      this.journey.recordCompanyChange(
        `tycoon:publisher:${row.id}:advance`,
        this.day(),
        PUBLISHER_ADVANCE_CENTS,
        0,
        0,
        `Publisher: ${PUBLISHER_NAME}`,
      );
      stored.publisher = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /** The office-day emphasis on the bench. Even clears it. No cash row and no clock move. */
  setDayPlan(statValue: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const stat = asDayPlan(statValue);
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      const next = stat === "even" ? null : stat;
      if (stored.dayPlan === next) return this.journey.state();
      stored.dayPlan = next;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /** Arm the next office day to spend personal craft on bugs. No cash row and no clock move. */
  fixBugs(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.fixBugs) return this.journey.state();
      const points = applyFocusPoints({
        design: Number(row.design_points),
        tech: Number(row.tech_points),
        hype: Number(row.hype_points),
      }, stored.focus);
      if (liveBugs(points, stored.crunchBugs, stored.bugsCleared) <= 0) throw new Error("No bugs to fix.");
      stored.fixBugs = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /**
   * Ship the bench product before its required days, after at least one office day.
   * Same release path as Release. Skipped days add no craft. The stored penalty is extra.
   * No cash row and no clock move.
   */
  earlyAccess(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const type = typeById(row.type_id);
      if (!type) throw new Error("Unknown product type");
      const stored = parseProductSnapshot(row.staff_json);
      const required = requiredDevDays(type.devDays, stored.sequelOf !== null, stored.size, stored.feature);
      const worked = Number(row.dev_days);
      if (worked < 1) throw new Error("Work one office day first.");
      const missing = required - worked;
      if (missing <= 0) throw new Error("Required days are done. Use Release.");
      stored.earlyAccess = true;
      stored.earlyDays = missing;
      return this.finishRelease(row, stored, required);
    });
  }

  /**
   * Drop the product on the bench. The row is deleted, so there is no review and no sale.
   * A contract on it fails. A publisher deal on it is void. Fees already paid stay paid.
   * No cash row and no clock move.
   */
  cancelBuild(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.sequelOf) {
        const parent = this.row(stored.sequelOf);
        if (parent) {
          const parentStored = parseProductSnapshot(parent.staff_json);
          if (parentStored.sequelId === row.id) {
            parentStored.sequelId = null;
            this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(parentStored), parent.id);
          }
        }
      }
      this.db.prepare("DELETE FROM tycoon_products WHERE id = ?").run(row.id);
      return this.journey.state();
    });
  }

  /** Arm the next office day to double personal craft. The day after rests. No cash row and no clock move. */
  crunch(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.crunch === "resting") throw new Error("The team is still tired.");
      if (stored.crunch === "armed") return this.journey.state();
      stored.crunch = "armed";
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /**
   * Hold the bench product for the next office day. The calendar, payroll, and other
   * day-end effects still run. That day adds no dev day and no craft. One-shot.
   * No cash row and no clock move.
   */
  slipDay(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.slip) return this.journey.state();
      stored.slip = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /**
   * Look at the likely review band of the product on the bench.
   * The band is computed on read from the current points, fit, and type weights.
   * Free to look again. Nothing is stored. No cash row and no clock move.
   */
  playtest(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      if (Number(row.dev_days) < 1) throw new Error("Work one office day first.");
      return this.journey.state();
    });
  }

  /**
   * Change the topic and/or type of the product on the bench. Dev days and craft
   * points stay. The name, the fit, and the research bonus follow the new pair.
   * At most one pivot. No cash row and no clock move.
   */
  pivot(topicValue: string, typeValue: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const topicId = asTopic(topicValue);
      const typeId = asType(typeValue);
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.pivoted) throw new Error("Already pivoted.");
      if (row.topic_id === topicId && row.type_id === typeId) throw new Error("Pick a new topic or type.");
      if (stored.contract) {
        const topicName = topicById(asTopic(row.topic_id))?.name ?? row.topic_id;
        const typeName = typeById(asType(row.type_id))?.name ?? row.type_id;
        throw new Error(`This contract is ${topicName} × ${typeName}.`);
      }
      const research = this.loadResearch();
      const topic = topicById(topicId);
      const type = typeById(typeId);
      if (!topic || !research.topics.has(topicId)) throw new Error(`${topic?.name ?? "That topic"} is locked. Research it first.`);
      if (!type || !research.types.has(typeId)) throw new Error(`${type?.name ?? "That product type"} is locked. Research it first.`);
      stored.pivoted = true;
      stored.researchBonus = researchFitBonus(research.researchedTopics.has(topicId), research.researchedTypes.has(typeId));
      const title = productTitle(topicId, typeId);
      const name = stored.sequelOf ? `${title} 2` : title;
      this.db.prepare("UPDATE tycoon_products SET topic_id = ?, type_id = ?, name = ?, fit = ?, staff_json = ? WHERE id = ?")
        .run(topicId, typeId, name, fitFor(topicId, typeId), serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /**
   * Change who works on the product on the bench. Days and points stay.
   * Later office days use the new people. Same set is a no-op.
   * No cash row and no clock move.
   */
  assignTeam(requestedStaff: readonly string[]): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const ids = this.assignedTeam(requestedStaff);
      const stored = parseProductSnapshot(row.staff_json);
      const current = stored.staff.map((person) => person.id);
      if (sameStaffIds(current, ids)) return this.journey.state();
      const existing = new Map(stored.staff.map((person) => [person.id, person]));
      const stats = this.loadStaffState();
      stored.staff = ids.map((id) => existing.get(id) ?? {
        id, design: stats[id].design, tech: stats[id].tech, hype: stats[id].hype,
      });
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /**
   * Set one hired teammate's pace. Full time is the default. Part-time pays
   * half their season salary and adds half their design, tech, and hype on
   * later office days, rounded down. The founder stays full time.
   * The same pace fails. No fee, no ledger row, no clock move.
   * Let go clears the pace, so a later hire starts full time.
   */
  setPace(staffId: string, paceValue: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const person = STAFF.find((member) => member.id === staffId);
      if (!person) throw new Error("Unknown teammate");
      if (paceValue !== "full" && paceValue !== "part") throw new Error("Pick full time or part-time.");
      if (person.id === "founder") throw new Error("The founder stays full time.");
      const status = this.employmentStatus(person.id);
      if (status === "dismissed") throw new Error(`${person.name} already left.`);
      if (status !== "hired") throw new Error(`${person.name} is not on the team yet.`);
      const state = this.loadStaffState();
      const next: StaffPace = paceValue;
      if (state[person.id].pace === next) {
        throw new Error(next === "part" ? `${person.name} is already part-time.` : `${person.name} is already full time.`);
      }
      state[person.id].pace = next;
      this.saveStaffState(state);
      return this.journey.state();
    });
  }

  /**
   * List one shipped product in the back catalog. One listing at a time.
   * A second product fails and does not swap. No fee, no fans, no clock move.
   * Posted sales stay. The check waits for a later payday.
   */
  listCatalog(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      if (!this.catalogReady(row)) throw new Error("This product is not finished.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.catalogDay !== null) throw new Error("Already listed.");
      if (this.listedEntry()) throw new Error("A product is already listed.");
      stored.catalogDay = this.day();
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /** Take the listed product off the back catalog. No fee, no fans, no clock move. */
  delistCatalog(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const listed = this.listedEntry();
      if (!listed) throw new Error("Nothing is listed.");
      listed.stored.catalogDay = null;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(listed.stored), listed.row.id);
      return this.journey.state();
    });
  }

  /**
   * Dismiss one hired teammate. The founder stays. They leave the company.
   * A build in development that listed them drops them. Days, points, and
   * sales already earned stay. Later days use whoever remains. Payroll no
   * longer includes them. Part-time clears, so a later hire starts full time.
   * No fee, no ledger row, no clock move. Hiring them again is the usual hire.
   */
  letGo(staffId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const person = STAFF.find((member) => member.id === staffId);
      if (!person) throw new Error("Unknown teammate");
      if (person.id === "founder") throw new Error("The founder stays.");
      const status = this.employmentStatus(person.id);
      if (status === "dismissed") throw new Error(`${person.name} already left.`);
      if (status !== "hired") throw new Error(`${person.name} is not on the team yet.`);
      this.db.prepare("UPDATE employees SET employment_status = 'dismissed' WHERE id = ?").run(person.id);
      const stats = this.loadStaffState();
      if (stats[person.id].pace === "part") {
        stats[person.id].pace = "full";
        this.saveStaffState(stats);
      }
      const row = this.developingRow();
      if (row) {
        const stored = parseProductSnapshot(row.staff_json);
        if (stored.staff.some((member) => member.id === person.id)) {
          stored.staff = stored.staff.filter((member) => member.id !== person.id);
          this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
        }
      }
      return this.journey.state();
    });
  }

  /**
   * Mark the next office day on the bench product as a research spike.
   * That day converts personal craft into research points. One spike per build.
   * Calling it again while pending, or after it was used, fails.
   * No cash row and no clock move.
   */
  researchSpike(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.researchSpike === "pending") throw new Error("A research spike is already set.");
      if (stored.researchSpike === "used") throw new Error("This build already used its research spike.");
      stored.researchSpike = "pending";
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /** One feature on the product on the bench. One extra office day. No cash row. */
  addFeature(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.feature) throw new Error("Already added.");
      stored.feature = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /** One press look at the product on the bench. The fee row also grants the fans. No office day is spent. */
  showPressDemo(): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.developingRow();
      if (!row) throw new Error("No product is on the bench.");
      const stored = parseProductSnapshot(row.staff_json);
      const id = `tycoon:pressdemo:${row.id}:fee`;
      if (stored.pressDemo || this.transactionExists(id)) throw new Error("Already shown.");
      if (this.cashCents() < PRESS_DEMO_COST_CENTS) throw new Error(`Need ${wholeDollars(PRESS_DEMO_COST_CENTS)}`);
      this.journey.recordCompanyChange(id, this.day(), -PRESS_DEMO_COST_CENTS, 0, PRESS_DEMO_FANS, `Press demo: ${PRESS_DEMO_NAME}`);
      stored.pressDemo = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /**
   * One price change on a product that is still selling.
   * The days still ahead use the new percent. Posted days stay.
   * Calling it again fails. No cash row and no clock move.
   */
  salePrice(productId: string, pricePercentValue: number): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      if (row.status !== "released" || Number(row.sales_applied) >= SALES_WINDOW_DAYS) {
        throw new Error("No product is selling.");
      }
      const stored = parseProductSnapshot(row.staff_json);
      if (stored.salePricePercent !== null) throw new Error("A sale price was already set.");
      if (!isLaunchPricePercent(pricePercentValue)) throw new Error("Pick −20%, catalog, or +20%.");
      if (pricePercentValue === stored.pricePercent) throw new Error("Price is unchanged.");
      stored.salePricePercent = pricePercentValue;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /** One trailer for a product that is selling. The fee row also grants the fans. No office day is spent. */
  makeTrailer(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      if (row.status !== "released" || Number(row.sales_applied) >= SALES_WINDOW_DAYS) {
        throw new Error("No product is selling.");
      }
      const stored = parseProductSnapshot(row.staff_json);
      const id = `tycoon:trailer:${row.id}:fee`;
      if (stored.trailer || this.transactionExists(id)) throw new Error("Already made.");
      if (this.cashCents() < TRAILER_COST_CENTS) throw new Error(`Need ${wholeDollars(TRAILER_COST_CENTS)}`);
      this.journey.recordCompanyChange(id, this.day(), -TRAILER_COST_CENTS, 0, TRAILER_FANS, `Trailer: ${TRAILER_NAME}`);
      stored.trailer = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
      return this.journey.state();
    });
  }

  /** One diary for a product whose sales have finished. The fee row also grants the fans. No office day is spent. */
  writeDiary(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      if (row.status === "developing") throw new Error("Ship this product first.");
      const stored = parseProductSnapshot(row.staff_json);
      const id = `tycoon:diary:${row.id}:fee`;
      if (stored.diary || this.transactionExists(id)) throw new Error("Already written.");
      if (row.status !== "complete") throw new Error("Still selling.");
      if (this.cashCents() < DIARY_COST_CENTS) throw new Error(`Need ${wholeDollars(DIARY_COST_CENTS)}`);
      this.journey.recordCompanyChange(id, this.day(), -DIARY_COST_CENTS, 0, DIARY_FANS, `Diary: ${DIARY_NAME}`);
      stored.diary = true;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
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
      const required = requiredDevDays(type.devDays, stored.sequelOf !== null, stored.size, stored.feature);
      const remaining = required - Number(row.dev_days);
      if (remaining > 0) {
        throw new Error(remaining === 1
          ? "Keep building. This product needs 1 more office day."
          : `Keep building. This product needs ${remaining} more office days.`);
      }
      return this.finishRelease(row, stored, required);
    });
  }

  /** Reviews, launch-day sales, the contract bonus, and the stored release flags. Caller is already in a transaction. */
  private finishRelease(row: ProductRow, stored: ProductSnapshot, required: number): ReturnType<JourneyStore["state"]> {
    const type = typeById(row.type_id);
    if (!type) throw new Error("Unknown product type");
    const topicId = asTopic(row.topic_id);
    const typeId = type.id;
    const points = applyFocusPoints({
      design: Number(row.design_points),
      tech: Number(row.tech_points),
      hype: Number(row.hype_points),
    }, stored.focus);
    const bugRemaining = liveBugs(points, stored.crunchBugs, stored.bugsCleared);
    const review = reviewProduct({
      seed: this.seed(),
      productId: row.id,
      topicId,
      typeId,
      design: points.design,
      tech: points.tech,
      hype: points.hype,
      researchBonus: stored.researchBonus,
      sequelBonus: stored.scoreBonus,
      engineBonus: stored.engine === ENGINE_ID ? ENGINE_SCORE_BONUS : 0,
      devDays: required,
      bugs: bugRemaining,
      earlyPenalty: stored.earlyAccess ? stored.earlyDays : 0,
    });
    const day = this.day();
    const bonus = releaseResearchPoints(review.score);
    this.db.prepare("UPDATE tycoon_products SET status = 'released', released_day = ?, review_json = ?, release_research = ? WHERE id = ?")
      .run(day, JSON.stringify(review), bonus, row.id);
    let storeSnapshot = stored.earlyAccess;
    if (rivalForDay(day).topicId === topicId && !stored.rivalCut) {
      stored.rivalCut = true;
      storeSnapshot = true;
    }
    if (stored.feature && !stored.featureDemand) {
      stored.featureDemand = true;
      storeSnapshot = true;
    }
    if (bugRemaining > 0) {
      stored.bugs = bugRemaining;
      storeSnapshot = true;
    }
    if (storeSnapshot) {
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(stored), row.id);
    }
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
      const id = this.nextProductId();
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
        localization: null,
        engine: null,
        focus: null,
        audience: null,
        size: null,
        publisher: false,
        pressDemo: false,
        trailer: false,
        diary: false,
        rivalCut: false,
        feature: false,
        featureDemand: false,
        dayPlan: null,
        bugs: 0,
        bugsCleared: 0,
        fixBugs: false,
        crunch: null,
        crunchBugs: 0,
        earlyAccess: false,
        earlyDays: 0,
        slip: false,
        pivoted: false,
        researchSpike: null,
        researchSpikePoints: 0,
        salePricePercent: null,
        catalogDay: null,
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

  /** One translated edition. The fee is one ledger row. The quieter day waits for day end. */
  localize(productId: string): ReturnType<JourneyStore["state"]> {
    return this.journey.transaction(() => {
      const row = this.row(productId);
      if (!row) throw new Error("No product with that id.");
      const stored = parseProductSnapshot(row.staff_json);
      const reason = this.localizeBlockReason(row, stored);
      if (reason) throw new Error(reason);
      const day = this.day();
      this.journey.recordCompanyChange(
        `tycoon:localize:${row.id}:fee`,
        day,
        -LOCALIZE_COST_CENTS,
        0,
        0,
        `Translate: ${LOCALIZE_EDITION}`,
      );
      stored.localization = { edition: LOCALIZE_EDITION, startedDay: day, cents: null, fans: null };
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
    this.payLocalizations(day);
    this.payPayroll(day);
    this.payCatalog(day);
    this.repayLoan(day);
    this.payExpo(day);
  }

  /** One catalog check, after payroll, on a payday after the listing day. Replaying that payday does not pay again. */
  private payCatalog(day: number): void {
    const calendar = calendarForDay(day);
    if (calendar.dayOfSeason !== SEASON_LENGTH_DAYS) return;
    const listed = this.listedEntry();
    if (!listed || listed.stored.catalogDay === null || listed.stored.catalogDay >= day) return;
    const cents = catalogCheckCents(this.storedReviewScore(listed.row));
    if (cents <= 0) return;
    this.journey.recordCompanyChange(
      `tycoon:catalog:${calendar.year}-${calendar.season}`,
      day,
      cents,
      0,
      0,
      `Catalog: ${listed.row.name}`,
    );
  }

  private catalogView(day: number): TycoonCatalog {
    const listed = this.listedEntry();
    const offer = listed ? null : this.catalogOfferEntry();
    const subject = listed ?? offer;
    const score = subject ? this.storedReviewScore(subject.row) : 0;
    const listedDay = listed?.stored.catalogDay ?? null;
    return {
      productId: listed ? listed.row.id : null,
      name: subject ? subject.row.name : "",
      score,
      checkCents: catalogCheckCents(score),
      payday: paydayLabel(catalogPaydayDay(day, listedDay)),
      list: listed
        ? { productId: listed.row.id, enabled: false, reason: "Already listed." }
        : offer
          ? { productId: offer.row.id, enabled: true, reason: "" }
          : { productId: null, enabled: false, reason: "Ship a product first." },
      delist: listed
        ? { enabled: true, reason: "" }
        : { enabled: false, reason: "Nothing is listed." },
    };
  }

  /** Shipped, with a stored review score. A bench product and a cancelled id are not. */
  private catalogReady(row: ProductRow): boolean {
    return row.status !== "developing" && this.storedReviewScore(row) >= 1;
  }

  private allEntries(): Array<{ row: ProductRow; stored: ProductSnapshot }> {
    const rows = this.db.prepare("SELECT * FROM tycoon_products ORDER BY id").all() as unknown as ProductRow[];
    return rows.map((row) => ({ row, stored: parseProductSnapshot(row.staff_json) }));
  }

  /** The one listed product. The earliest listing wins if a save somehow has two. */
  private listedEntry(): { row: ProductRow; stored: ProductSnapshot } | null {
    const listed = this.allEntries().filter((entry) => entry.stored.catalogDay !== null && this.catalogReady(entry.row));
    listed.sort((a, b) => {
      const day = (a.stored.catalogDay ?? 0) - (b.stored.catalogDay ?? 0);
      if (day !== 0) return day;
      return this.productNumber(a.row.id) - this.productNumber(b.row.id);
    });
    return listed[0] ?? null;
  }

  /** Newest shipped product. The List button offers this one when the slot is empty. */
  private catalogOfferEntry(): { row: ProductRow; stored: ProductSnapshot } | null {
    const ready = this.allEntries().filter((entry) => this.catalogReady(entry.row));
    ready.sort((a, b) => {
      const day = Number(b.row.released_day ?? 0) - Number(a.row.released_day ?? 0);
      if (day !== 0) return day;
      return this.productNumber(b.row.id) - this.productNumber(a.row.id);
    });
    return ready[0] ?? null;
  }

  private productNumber(id: string): number {
    const match = /^p([1-9][0-9]*)$/u.exec(id);
    return match ? Number(match[1]) : 0;
  }

  /** One season salary, after that day's sales. Replaying the same payday does not pay again. */
  private payPayroll(day: number): void {
    const calendar = calendarForDay(day);
    if (calendar.dayOfSeason !== SEASON_LENGTH_DAYS) return;
    const cents = this.payrollDue(this.hiredIds());
    if (cents <= 0) return;
    const id = `tycoon:payroll:${calendar.year}-${calendar.season}`;
    const already = this.db.prepare("SELECT id FROM company_transactions WHERE id = ?").get(id);
    this.journey.recordCompanyChange(id, day, -cents, 0, 0, `Payroll: ${calendar.seasonName}`, true);
    if (already) return;
    this.payrollNotice = `Paid payroll · −${wholeDollars(cents)}`;
    this.payrollNoticeDay = day + 1;
  }

  private payrollView(day: number, hired: ReadonlySet<string>): TycoonPayroll {
    const calendar = calendarForDay(day);
    return {
      cents: this.payrollDue(hired),
      payday: `${calendar.seasonName} ${SEASON_LENGTH_DAYS}`,
      notice: this.payrollNoticeDay === day ? this.payrollNotice : "",
    };
  }

  /** Amount plus fee, on the due payday. Replaying that payday does not repay again. */
  private repayLoan(day: number): void {
    const loan = this.outstandingLoan();
    if (!loan) return;
    if (day < loanDueDay(loan.takenDay)) return;
    if (calendarForDay(day).dayOfSeason !== SEASON_LENGTH_DAYS) return;
    this.journey.recordCompanyChange(
      `tycoon:loan:${loan.n}:repaid`,
      day,
      -LOAN_REPAY_CENTS,
      0,
      0,
      "Loan repaid",
      true,
    );
  }

  private loanView(day: number): TycoonLoan {
    const outstanding = this.outstandingLoan();
    const dueDay = outstanding ? loanDueDay(outstanding.takenDay) : loanDueDay(day);
    return {
      lender: LOAN_LENDER,
      amountCents: LOAN_AMOUNT_CENTS,
      repayCents: LOAN_REPAY_CENTS,
      due: paydayLabel(dueDay),
      outstanding: outstanding !== null,
    };
  }

  /** Fans for a booked booth, after that day's sales. Replaying the fair does not pay again. */
  private payExpo(day: number): void {
    const calendar = calendarForDay(day);
    if (calendar.dayOfSeason !== EXPO_DAY_OF_SEASON) return;
    const key = `${calendar.year}-${calendar.season}`;
    if (!this.transactionExists(`tycoon:expo:${key}:booth`)) return;
    this.journey.recordCompanyChange(
      `tycoon:expo:${key}:fans`,
      day,
      0,
      0,
      EXPO_FANS,
      `Expo: ${EXPO_NAME}`,
    );
  }

  private expoView(day: number): TycoonExpo {
    const fair = nextExpoFair(day);
    return {
      name: EXPO_NAME,
      costCents: EXPO_COST_CENTS,
      fans: EXPO_FANS,
      when: fair.when,
      booked: this.transactionExists(`tycoon:expo:${fair.key}:booth`),
    };
  }

  private townDayView(day: number): TycoonTownDay {
    const season = townDaySeason(day);
    return {
      name: TOWN_DAY_NAME,
      costCents: TOWN_DAY_COST_CENTS,
      fans: TOWN_DAY_FANS,
      season: season.seasonName,
      taken: this.transactionExists(`tycoon:townday:${season.key}:fee`),
    };
  }

  private transactionExists(id: string): boolean {
    return this.db.prepare("SELECT id FROM company_transactions WHERE id = ?").get(id) !== undefined;
  }

  private outstandingLoan(): { n: number; takenDay: number } | null {
    const repaid = new Set(this.loanEntries("repaid").map((entry) => entry.n));
    for (const entry of this.loanEntries("taken")) {
      if (!repaid.has(entry.n)) return entry;
    }
    return null;
  }

  private nextLoanNumber(): number {
    const taken = this.loanEntries("taken");
    return taken.length === 0 ? 1 : taken[taken.length - 1]!.n + 1;
  }

  private loanEntries(kind: "taken" | "repaid"): Array<{ n: number; takenDay: number }> {
    const rows = this.db.prepare(
      "SELECT id, day FROM company_transactions WHERE id LIKE ?",
    ).all(`tycoon:loan:%:${kind}`) as Array<{ id: string; day: number }>;
    const prefix = "tycoon:loan:";
    const suffix = `:${kind}`;
    const entries: Array<{ n: number; takenDay: number }> = [];
    for (const row of rows) {
      if (!row.id.startsWith(prefix) || !row.id.endsWith(suffix)) continue;
      const n = Number(row.id.slice(prefix.length, row.id.length - suffix.length));
      if (!Number.isInteger(n) || n < 1) continue;
      entries.push({ n, takenDay: Number(row.day) });
    }
    entries.sort((a, b) => a.n - b.n);
    return entries;
  }

  private tickDevelopment(row: ProductRow, day: number): void {
    if (row.last_dev_day !== null && Number(row.last_dev_day) === day) return;
    const type = typeById(row.type_id);
    if (!type) throw new Error("Unknown product type");
    const snapshot = parseProductSnapshot(row.staff_json);
    // A held day moves the calendar only. Craft, bugs, crunch, research, and a pending spike wait.
    if (snapshot.slip) {
      snapshot.slip = false;
      this.db.prepare("UPDATE tycoon_products SET staff_json = ?, last_dev_day = ? WHERE id = ?").run(
        serializeProductSnapshot(snapshot),
        day,
        row.id,
      );
      return;
    }
    const trainedToday = this.trainedIdsOn(day);
    const working = snapshot.staff.filter((person) => !trainedToday.has(person.id));
    const accrue = pointsStillAccrue(Number(row.dev_days), requiredDevDays(type.devDays, snapshot.sequelOf !== null, snapshot.size, snapshot.feature));
    // Part-time halves that person's stored craft before the day plan, crunch, a spike, or fix bugs.
    const pace = this.loadStaffState();
    const paced = working.map((person) => pacedCraft(person, pace[person.id]?.pace ?? "full"));
    const rawPersonal = accrue ? snapshotPoints(paced) : { design: 0, tech: 0, hype: 0 };
    // Day plan folds personal first. An armed crunch doubles that fold. A rest day zeroes it.
    // Tools and the office stay on their own stats either way.
    let personal = personalForDayPlan(rawPersonal, snapshot.dayPlan);
    let crunchChanged = false;
    if (snapshot.crunch === "armed") {
      personal = { design: personal.design * 2, tech: personal.tech * 2, hype: personal.hype * 2 };
      snapshot.crunch = "resting";
      snapshot.crunchBugs += 1;
      crunchChanged = true;
    } else if (snapshot.crunch === "resting") {
      personal = { design: 0, tech: 0, hype: 0 };
      snapshot.crunch = null;
      crunchChanged = true;
    }
    // A research spike takes this day's personal craft, after day plan and crunch.
    // An armed fix stays armed and does not clear on the spike day.
    const spiking = snapshot.researchSpike === "pending";
    let spikePoints = 0;
    if (spiking) {
      spikePoints = personal.design + personal.tech + personal.hype;
      personal = { design: 0, tech: 0, hype: 0 };
      snapshot.researchSpike = "used";
      snapshot.researchSpikePoints = spikePoints;
    }
    // Fixing spends this day's personal craft on bugs, including a doubled crunch total.
    const fixing = snapshot.fixBugs && !spiking;
    if (fixing) {
      const personalTotal = personal.design + personal.tech + personal.hype;
      personal = { design: 0, tech: 0, hype: 0 };
      if (personalTotal > 0) snapshot.bugsCleared += bugsClearedGain(personalTotal);
      snapshot.fixBugs = false;
    }
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
    if (fixing || crunchChanged || spiking) {
      this.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = ?").run(serializeProductSnapshot(snapshot), row.id);
    }
    this.addResearchPoints(working.length + spikePoints);
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
      pricePercent: stored.salePricePercent ?? stored.pricePercent,
      marketing: stored.marketing,
      audience: stored.audience ?? "everyone",
      topicMatch: this.topicHasPastRelease(topicId, row.id),
      size: stored.size ?? "catalog",
      priceBoostPercent: this.priceBoostPercent(),
      unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
      bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
      rivalCut: stored.rivalCut,
      featureDemand: stored.featureDemand,
    });
    const posted = stored.publisher ? publisherNetCents(payout.cents) : payout.cents;
    this.journey.recordCompanyChange(`tycoon:${row.id}:${applied}`, day, posted, posted, payout.fans, `Sales · ${row.name}`);
    const salesDays = applied + 1;
    this.db.prepare(`
      UPDATE tycoon_products
      SET status = ?, sales_applied = ?, last_sales_day = ?, sales_cents = ?, fans = ?
      WHERE id = ?
    `).run(
      salesDays >= SALES_WINDOW_DAYS ? "complete" : "released",
      salesDays,
      day,
      Number(row.sales_cents) + posted,
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
        audience: stored.audience ?? "everyone",
        topicMatch: this.topicHasPastRelease(topicId, row.id),
        size: stored.size ?? "catalog",
        priceBoostPercent: this.priceBoostPercent(),
        unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
        bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
        rivalCut: stored.rivalCut,
        featureDemand: stored.featureDemand,
      });
      const posted = stored.publisher ? publisherNetCents(payout.cents) : payout.cents;
      this.journey.recordCompanyChange(`tycoon:${row.id}:${SALES_WINDOW_DAYS}`, day, posted, posted, payout.fans, `Sales · ${row.name}`);
      stored.port = { ...stored.port, cents: posted, fans: payout.fans };
      this.db.prepare("UPDATE tycoon_products SET staff_json = ?, sales_cents = ?, fans = ? WHERE id = ?").run(
        serializeProductSnapshot(stored),
        Number(row.sales_cents) + posted,
        Number(row.fans) + payout.fans,
        row.id,
      );
    }
  }

  /** One quieter extra sales day for a translation that is still waiting. The fee was already charged. */
  private payLocalizations(day: number): void {
    const rows = this.db.prepare("SELECT * FROM tycoon_products WHERE status = 'complete' ORDER BY id").all() as unknown as ProductRow[];
    for (const row of rows) {
      const stored = parseProductSnapshot(row.staff_json);
      if (!stored.localization || stored.localization.cents !== null || stored.localization.startedDay > day) continue;
      const salesId = `tycoon:localize:${row.id}:sales`;
      if (this.transactionExists(salesId)) continue;
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
        audience: stored.audience ?? "everyone",
        topicMatch: this.topicHasPastRelease(topicId, row.id),
        size: stored.size ?? "catalog",
        priceBoostPercent: this.priceBoostPercent(),
        unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
        bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
        quietPercent: LOCALIZE_UNIT_PERCENT,
        rivalCut: stored.rivalCut,
        featureDemand: stored.featureDemand,
      });
      const posted = stored.publisher ? publisherNetCents(payout.cents) : payout.cents;
      this.journey.recordCompanyChange(salesId, day, posted, posted, payout.fans, `Sales · ${LOCALIZE_EDITION}`);
      stored.localization = { ...stored.localization, cents: posted, fans: payout.fans };
      this.db.prepare("UPDATE tycoon_products SET staff_json = ?, sales_cents = ?, fans = ? WHERE id = ?").run(
        serializeProductSnapshot(stored),
        Number(row.sales_cents) + posted,
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

  /** Start always includes the founder. Assign the team does not. Empty fails. */
  private assignedTeam(requested: readonly string[]): StaffId[] {
    const hired = this.hiredIds();
    const ids: StaffId[] = [];
    for (const id of requested) {
      const person = STAFF.find((member) => member.id === id);
      if (!person) throw new Error("Unknown teammate");
      if (person.id !== "founder" && !hired.has(person.id)) throw new Error(`${person.name} is not on the team yet.`);
      if (!ids.includes(person.id)) ids.push(person.id);
    }
    if (ids.length === 0) throw new Error("Pick at least one teammate.");
    return ids;
  }

  private hiredIds(): Set<string> {
    const rows = this.db.prepare("SELECT id FROM employees WHERE employment_status = 'hired'").all() as unknown as Array<{ id: string }>;
    return new Set(rows.map((row) => row.id));
  }

  private dismissedIds(): Set<string> {
    const rows = this.db.prepare("SELECT id FROM employees WHERE employment_status = 'dismissed'").all() as unknown as Array<{ id: string }>;
    return new Set(rows.map((row) => row.id));
  }

  private employmentStatus(id: string): string | null {
    const row = this.db.prepare("SELECT employment_status FROM employees WHERE id = ?").get(id) as { employment_status: string } | undefined;
    return row?.employment_status ?? null;
  }

  private letGoOffer(id: StaffId, name: string, hired: boolean, dismissed: boolean): LetGoOffer {
    if (id === "founder") return { enabled: false, reason: "The founder stays." };
    if (dismissed) return { enabled: false, reason: `${name} already left.` };
    if (!hired) return { enabled: false, reason: `${name} is not on the team yet.` };
    return { enabled: true, reason: "" };
  }

  private paceOffer(id: StaffId, name: string, hired: boolean, dismissed: boolean, pace: StaffPace): PaceOffer {
    if (id === "founder") return { value: "full", enabled: false, reason: "The founder stays full time." };
    if (dismissed) return { value: "full", enabled: false, reason: `${name} already left.` };
    if (!hired) return { value: "full", enabled: false, reason: `${name} is not on the team yet.` };
    return { value: pace === "part" ? "part" : "full", enabled: true, reason: "" };
  }

  private payrollDue(hired: ReadonlySet<string>): number {
    const state = this.loadStaffState();
    const pace: Record<string, StaffPace> = {};
    for (const person of STAFF) pace[person.id] = state[person.id].pace;
    return payrollCents([...hired], pace);
  }

  private letGoNotice(dismissed: ReadonlySet<string>): string {
    return STAFF.filter((person) => dismissed.has(person.id)).map((person) => `${person.name} left the company.`).join(" ");
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
    if (this.engineNoticeDay !== 0 && this.engineNoticeDay <= endedDay) {
      this.engineNotice = "";
      this.engineNoticeDay = 0;
    }
    if (this.payrollNoticeDay !== 0 && this.payrollNoticeDay <= endedDay) {
      this.payrollNotice = "";
      this.payrollNoticeDay = 0;
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

  private loadEngineOwned(): boolean {
    const row = this.db.prepare("SELECT engine_id FROM tycoon_meta WHERE id = 1").get() as { engine_id?: string } | undefined;
    return row?.engine_id === ENGINE_ID;
  }

  private saveEngineOwned(): void {
    this.db.prepare("UPDATE tycoon_meta SET engine_id = ? WHERE id = 1").run(ENGINE_ID);
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
      design: person.design, tech: person.tech, hype: person.hype, trainedDay: null as number | null, pace: "full" as StaffPace,
    }])) as Record<StaffId, StaffState>;
    const row = this.db.prepare("SELECT staff_json FROM tycoon_meta WHERE id = 1").get() as { staff_json?: string } | undefined;
    const raw = row?.staff_json?.trim();
    if (!raw) return defaults;
    let parsed: unknown;
    try { parsed = JSON.parse(raw); } catch { return defaults; }
    if (!parsed || typeof parsed !== "object") return defaults;
    const stored = parsed as Record<string, { design?: unknown; tech?: unknown; hype?: unknown; trainedDay?: unknown; pace?: unknown }>;
    for (const person of STAFF) {
      const item = stored[person.id];
      if (!item || typeof item !== "object") continue;
      const trainedDay = Number(item.trainedDay);
      defaults[person.id] = {
        design: clampStat(item.design, person.design),
        tech: clampStat(item.tech, person.tech),
        hype: clampStat(item.hype, person.hype),
        trainedDay: Number.isInteger(trainedDay) && trainedDay > 0 ? trainedDay : null,
        pace: person.id !== "founder" && item.pace === "part" ? "part" : "full",
      };
    }
    return defaults;
  }

  private saveStaffState(state: Record<StaffId, StaffState>): void {
    const stored: Record<string, { design: number; tech: number; hype: number; trainedDay: number | null; pace?: "part" }> = {};
    for (const person of STAFF) {
      const item = state[person.id];
      const body: { design: number; tech: number; hype: number; trainedDay: number | null; pace?: "part" } = {
        design: item.design,
        tech: item.tech,
        hype: item.hype,
        trainedDay: item.trainedDay,
      };
      if (person.id !== "founder" && item.pace === "part") body.pace = "part";
      stored[person.id] = body;
    }
    this.db.prepare("UPDATE tycoon_meta SET staff_json = ? WHERE id = 1").run(JSON.stringify(stored));
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

  /** One past any product id still stored, or already used on a tycoon ledger row. */
  private nextProductId(): string {
    let max = 0;
    const bump = (id: string): void => {
      const match = /^p([1-9][0-9]*)$/u.exec(id);
      if (!match) return;
      const n = Number(match[1]);
      if (n > max) max = n;
    };
    const products = this.db.prepare("SELECT id FROM tycoon_products").all() as Array<{ id: string }>;
    for (const product of products) bump(String(product.id));
    const txs = this.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:%'").all() as Array<{ id: string }>;
    for (const tx of txs) {
      for (const part of String(tx.id).split(":")) bump(part);
    }
    return `p${max + 1}`;
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
    const required = requiredDevDays(type.devDays, snapshot.sequelOf !== null, snapshot.size, snapshot.feature);
    const progress = Math.min(100, Math.round((devDays * 100) / required));
    const staffIds = snapshot.staff.map((person) => person.id);
    const points = applyFocusPoints({
      design: Number(row.design_points),
      tech: Number(row.tech_points),
      hype: Number(row.hype_points),
    }, snapshot.focus);
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
      design: points.design,
      tech: points.tech,
      hype: points.hype,
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
      localization: this.localizeOffer(row, snapshot),
      engine: snapshot.engine === ENGINE_ID
        ? { id: ENGINE_ID, name: ENGINE_NAME, scoreBonus: ENGINE_SCORE_BONUS }
        : null,
      focus: focusView(snapshot.focus),
      audience: audienceView(snapshot.audience),
      size: sizeView(snapshot.size),
      publisher: this.publisherView(row.status, snapshot.publisher),
      pressDemo: this.pressDemoView(row.status, snapshot.pressDemo),
      trailer: this.trailerView(row.status, Number(row.sales_applied), snapshot.trailer),
      diary: this.diaryView(row.status, snapshot.diary),
      feature: this.featureView(row.status, snapshot.feature),
      dayPlan: this.dayPlanView(row.status, snapshot.dayPlan),
      bugs: row.status === "developing"
        ? {
          count: liveBugs(points, snapshot.crunchBugs, snapshot.bugsCleared),
          cleared: snapshot.bugsCleared,
          fixing: snapshot.fixBugs,
        }
        : (snapshot.bugs > 0 ? snapshot.bugs : null),
      crunch: this.crunchView(row.status, snapshot.crunch),
      earlyAccess: row.status === "developing"
        ? this.earlyAccessOffer(devDays, required)
        : this.earlyAccessShipped(snapshot),
      cancel: row.status === "developing" ? { enabled: true, reason: "" } : null,
      slip: this.slipView(row.status, snapshot.slip),
      pivot: this.pivotView(row, snapshot),
      playtest: this.playtestView(row, snapshot),
      team: this.teamView(row, snapshot),
      researchSpike: this.researchSpikeView(row.status, snapshot),
      salePrice: this.salePriceView(row, snapshot),
    };
  }

  /** One price change while the product is still selling. Hidden on the bench and after the window. */
  private salePriceView(row: ProductRow, snapshot: ProductSnapshot): TycoonSalePrice | null {
    const selling = row.status === "released" && Number(row.sales_applied) < SALES_WINDOW_DAYS;
    if (!selling) return null;
    const used = snapshot.salePricePercent !== null;
    return {
      enabled: !used,
      used,
      currentPercent: snapshot.salePricePercent ?? snapshot.pricePercent,
      options: [...LAUNCH_PRICES],
      reason: used ? "A sale price was already set." : "",
    };
  }

  /** One spike per build. Hidden once the product ships. */
  private researchSpikeView(status: string, snapshot: ProductSnapshot): TycoonResearchSpike | null {
    if (status !== "developing") return null;
    const pending = snapshot.researchSpike === "pending";
    const used = snapshot.researchSpike === "used";
    return {
      enabled: !pending && !used,
      pending,
      used,
      reason: "",
      points: snapshot.researchSpikePoints,
    };
  }

  /**
   * The band a release would write today. Hidden once the product ships.
   * Nothing is stored. Day 0 has no band yet.
   */
  private playtestView(row: ProductRow, snapshot: ProductSnapshot): TycoonPlaytest | null {
    if (row.status !== "developing") return null;
    if (Number(row.dev_days) < 1) {
      return { enabled: false, band: null, reason: "Work one office day first." };
    }
    const type = typeById(asType(row.type_id));
    if (!type) return { enabled: false, band: null, reason: "Work one office day first." };
    const required = requiredDevDays(type.devDays, snapshot.sequelOf !== null, snapshot.size, snapshot.feature);
    const points = applyFocusPoints({
      design: Number(row.design_points),
      tech: Number(row.tech_points),
      hype: Number(row.hype_points),
    }, snapshot.focus);
    const review = reviewProduct({
      seed: this.seed(),
      productId: row.id,
      topicId: asTopic(row.topic_id),
      typeId: type.id,
      design: points.design,
      tech: points.tech,
      hype: points.hype,
      researchBonus: snapshot.researchBonus,
      sequelBonus: snapshot.scoreBonus,
      engineBonus: snapshot.engine === ENGINE_ID ? ENGINE_SCORE_BONUS : 0,
      devDays: required,
      bugs: liveBugs(points, snapshot.crunchBugs, snapshot.bugsCleared),
      earlyPenalty: snapshot.earlyAccess ? snapshot.earlyDays : 0,
    });
    return { enabled: true, band: reviewBand(review.score), reason: "" };
  }

  /** The next office day is free, or one hold is already pending. Hidden once the product ships. */
  private slipView(status: string, pending: boolean): TycoonSlip | null {
    if (status !== "developing") return null;
    return pending
      ? { enabled: false, pending: true, reason: "" }
      : { enabled: true, pending: false, reason: "" };
  }

  /** Founder plus hired people, with who is on this build. Hidden once it ships. */
  private teamView(row: ProductRow, snapshot: ProductSnapshot): TycoonTeam | null {
    if (row.status !== "developing") return null;
    const hired = this.hiredIds();
    const onTeam = new Set(snapshot.staff.map((person) => person.id));
    const members = STAFF
      .filter((person) => person.id === "founder" || hired.has(person.id))
      .map((person) => ({ id: person.id, name: person.name, onTeam: onTeam.has(person.id) }));
    return { enabled: true, members, reason: "" };
  }

  /** One change of topic or type while the product is on the bench. Hidden once it ships. */
  private pivotView(row: ProductRow, snapshot: ProductSnapshot): TycoonPivot | null {
    if (row.status !== "developing") return null;
    const research = this.loadResearch();
    const options = {
      topics: TOPICS.map((topic) => ({ id: topic.id, name: topic.name, unlocked: research.topics.has(topic.id) })),
      types: PRODUCT_TYPES.map((type) => ({ id: type.id, name: type.name, unlocked: research.types.has(type.id) })),
    };
    if (snapshot.pivoted) return { enabled: false, used: true, reason: "", options };
    if (snapshot.contract) {
      const topicName = topicById(asTopic(row.topic_id))?.name ?? row.topic_id;
      const typeName = typeById(asType(row.type_id))?.name ?? row.type_id;
      return { enabled: false, used: false, reason: `This contract is ${topicName} × ${typeName}.`, options };
    }
    return { enabled: true, used: false, reason: "", options };
  }

  /** The offer while the product is on the bench. Day 0 and a finished build cannot ship early. */
  private earlyAccessOffer(devDays: number, required: number): TycoonEarlyAccess {
    const daysLeft = Math.max(0, required - devDays);
    if (devDays < 1) {
      return { enabled: false, reason: "Work one office day first.", daysLeft, penalty: 0 };
    }
    if (daysLeft <= 0) {
      return { enabled: false, reason: "Required days are done. Use Release.", daysLeft: 0, penalty: 0 };
    }
    return { enabled: true, reason: "", daysLeft, penalty: earlyAccessPenalty(daysLeft) };
  }

  /** Null when this product did not ship early. The penalty is the capped score cost. */
  private earlyAccessShipped(snapshot: ProductSnapshot): TycoonEarlyAccess | null {
    if (!snapshot.earlyAccess) return null;
    return { enabled: false, reason: "", daysLeft: 0, penalty: earlyAccessPenalty(snapshot.earlyDays) };
  }

  /** Idle while the product is on the bench. Hidden once it ships. */
  private crunchView(status: string, crunch: "armed" | "resting" | null): TycoonCrunch | null {
    if (status !== "developing") return null;
    return { state: crunch ?? "idle" };
  }

  /** Even is null. The control is only for the product still on the bench. */
  private dayPlanView(status: string, plan: StatId | null): TycoonDayPlan | null {
    if (status !== "developing" || !plan) return null;
    return { id: plan, label: statLabel(plan), stat: plan };
  }

  /** Offer while the product is in development. After that, only an added feature stays. */
  private featureView(status: string, added: boolean): TycoonProductFeature | null {
    if (!added && status !== "developing") return null;
    return {
      name: FEATURE_NAME,
      dayDelta: FEATURE_DAY_DELTA,
      unitPercent: FEATURE_UNIT_PERCENT,
      added,
    };
  }

  /** Offer while the product is in development. After that, only a signed deal stays. */
  private publisherView(status: string, signed: boolean): TycoonProductPublisher | null {
    if (!signed && status !== "developing") return null;
    return {
      name: PUBLISHER_NAME,
      advanceCents: PUBLISHER_ADVANCE_CENTS,
      cutPercent: PUBLISHER_CUT_PERCENT,
      signed,
    };
  }

  /** Offer while the product is selling. After that, only a made trailer stays. */
  private trailerView(status: string, salesApplied: number, made: boolean): TycoonProductTrailer | null {
    const selling = status === "released" && salesApplied < SALES_WINDOW_DAYS;
    if (!made && !selling) return null;
    return {
      name: TRAILER_NAME,
      costCents: TRAILER_COST_CENTS,
      fans: TRAILER_FANS,
      made,
    };
  }

  /** Offer after sales finish. Before that, only a written diary stays. */
  private diaryView(status: string, written: boolean): TycoonProductDiary | null {
    if (!written && status !== "complete") return null;
    return {
      name: DIARY_NAME,
      costCents: DIARY_COST_CENTS,
      fans: DIARY_FANS,
      written,
    };
  }

  /** Offer while the product is in development. After that, only a shown preview stays. */
  private pressDemoView(status: string, shown: boolean): TycoonProductPressDemo | null {
    if (!shown && status !== "developing") return null;
    return {
      name: PRESS_DEMO_NAME,
      costCents: PRESS_DEMO_COST_CENTS,
      fans: PRESS_DEMO_FANS,
      shown,
    };
  }

  /** Another shipped product already used this topic. Regulars reads this on each sale. */
  private topicHasPastRelease(topicId: TopicId, exceptId: string): boolean {
    const row = this.db.prepare(
      "SELECT id FROM tycoon_products WHERE topic_id = ? AND id != ? AND status != 'developing' LIMIT 1",
    ).get(topicId, exceptId) as { id?: string } | undefined;
    return Boolean(row?.id);
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

  /** Empty when the product can be translated. The same strings are the button reasons. */
  private localizeBlockReason(row: ProductRow, snapshot: ProductSnapshot): string {
    if (snapshot.localization) return "Already translated.";
    if (row.status === "developing") return "Ship this product first.";
    if (row.status !== "complete") return "Still selling.";
    if (this.cashCents() < LOCALIZE_COST_CENTS) return `Need ${wholeDollars(LOCALIZE_COST_CENTS)}`;
    return "";
  }

  private localizeOffer(row: ProductRow, snapshot: ProductSnapshot): TycoonLocalizationView | null {
    if (row.status === "developing") return null;
    const localization = snapshot.localization;
    const reason = this.localizeBlockReason(row, snapshot);
    return {
      edition: LOCALIZE_EDITION,
      costCents: LOCALIZE_COST_CENTS,
      phase: !localization ? "" : localization.cents === null ? "selling" : "sold",
      cents: localization?.cents ?? 0,
      fans: localization?.fans ?? 0,
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
