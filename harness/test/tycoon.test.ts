import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, mkdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import test from "node:test";
import { Ajv2020 } from "ajv/dist/2020.js";
import { readFileSync } from "node:fs";

import { GameDatabase } from "../src/database.js";
import { parseRequest } from "../src/validation.js";
import { DatabaseSync } from "node:sqlite";

import {
  CONTRACTS,
  EVENT_BONUS_FANS,
  LAUNCH_PRICES,
  MARKETING,
  AWARD_COST_CENTS,
  AWARD_NOMINEE_FANS,
  AWARD_NOMINEE_SCORE,
  AWARD_SHOW,
  AWARD_WIN_FANS,
  AWARD_WIN_SCORE,
  PATCH_COST_CENTS,
  ENGINE_COST_CENTS,
  ENGINE_ID,
  ENGINE_NAME,
  ENGINE_SCORE_BONUS,
  FOCUS_BONUS,
  FOCUSES,
  applyFocusPoints,
  AUDIENCE_FANS,
  AUDIENCE_NEWCOMER_UNIT_PERCENT,
  AUDIENCES,
  applyAudienceUnits,
  audienceFansForSale,
  SIZE_LONG_UNIT_PERCENT,
  SIZE_SHORT_UNIT_PERCENT,
  SIZES,
  applySizeUnits,
  sizedDevDays,
  PORT_COST_CENTS,
  PORT_SHELF,
  SALES_WINDOW_DAYS,
  PATCH_SCORE_BONUS,
  PRODUCT_TYPES,
  SEQUEL_DAYS_SAVED,
  SEQUEL_SCORE_BONUS,
  SEQUEL_SCORE_MARK,
  SEASON_UNIT_BOOST_PERCENT,
  STAT_CAP,
  TOPICS,
  UPGRADES,
  allFits,
  applyLaunchPriceUnits,
  applyMarketingUnits,
  baseScore,
  boostedPriceCents,
  calendarForDay,
  catalogCheckCents,
  catalogPaydayDay,
  CATALOG_CENTS_PER_SCORE,
  contractBySlot,
  fitFor,
  launchPriceCents,
  awardForScore,
  patchedScore,
  pacedCraft,
  payrollCents,
  lowestCraftStat,
  raisedDayCraft,
  LOAN_AMOUNT_CENTS,
  LOAN_FEE_CENTS,
  LOAN_LENDER,
  LOAN_REPAY_CENTS,
  loanDueDay,
  paydayLabel,
  PUBLISHER_ADVANCE_CENTS,
  PUBLISHER_CUT_PERCENT,
  PUBLISHER_NAME,
  EXPO_COST_CENTS,
  EXPO_DAY_OF_SEASON,
  EXPO_FANS,
  EXPO_NAME,
  TOWN_DAY_COST_CENTS,
  TOWN_DAY_FANS,
  TOWN_DAY_NAME,
  townDaySeason,
  PRESS_DEMO_COST_CENTS,
  PRESS_DEMO_FANS,
  PRESS_DEMO_NAME,
  TRAILER_COST_CENTS,
  TRAILER_FANS,
  TRAILER_NAME,
  DIARY_COST_CENTS,
  DIARY_FANS,
  DIARY_NAME,
  RIVAL_UNIT_PERCENT,
  RIVALS,
  FEATURE_DAY_DELTA,
  FEATURE_NAME,
  FEATURE_UNIT_PERCENT,
  DAY_PLANS,
  personalForDayPlan,
  bugCount,
  bugsClearedGain,
  liveBugs,
  EARLY_ACCESS_PENALTY_CAP,
  earlyAccessPenalty,
  openingDemand,
  rivalForDay,
  seasonIndexForDay,
  LOCALIZE_COST_CENTS,
  LOCALIZE_EDITION,
  LOCALIZE_UNIT_PERCENT,
  nextExpoFair,
  publisherCutCents,
  publisherNetCents,
  requiredDevDays,
  reviewProduct,
  reviewBand,
  SALARY_CENTS,
  salesForDay,
  sequelDevDays,
  sequelScoreCarry,
  staffPoints,
  trainCostCents,
} from "../src/tycoon.js";

async function setup() {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-tycoon-"));
  const project = join(root, "company-project");
  await mkdir(project);
  const db = new GameDatabase(join(root, "game.sqlite"), project);
  return { root, db };
}

test("topic x type fit covers every pairing once", () => {
  const fits = allFits();
  assert.equal(fits.length, TOPICS.length * PRODUCT_TYPES.length);
  const seen = new Set(fits.map((item) => `${item.topicId}:${item.typeId}`));
  assert.equal(seen.size, fits.length);
  for (const fit of fits) assert.ok(["great", "good", "okay", "bad"].includes(fit.fit));
  assert.equal(fitFor("crypto", "newsletter"), "great");
  assert.equal(fitFor("fitness", "software"), "bad");
  assert.equal(fitFor("gaming", "software"), "great");
  assert.equal(fitFor("sneakers", "community"), "great");
  assert.equal(fitFor("dating", "template_pack"), "bad");
});

test("review scores and sales are deterministic and fit changes the take", () => {
  const points = { design: 4, tech: 4, hype: 4 };
  const great = reviewProduct({ seed: 26021, productId: "p1", topicId: "crypto", typeId: "newsletter", ...points });
  const again = reviewProduct({ seed: 26021, productId: "p1", topicId: "crypto", typeId: "newsletter", ...points });
  assert.deepEqual(great, again);
  assert.equal(great.reviewers.length, 4);
  assert.deepEqual(great.reviewers.map((reviewer) => reviewer.name), [
    "TownSquare Weekly",
    "Discord Dave",
    "Margin Call Molly",
    "Cohort Casey",
  ]);
  assert.equal(great.score, Math.round(great.reviewers.reduce((sum, reviewer) => sum + reviewer.score, 0) / 4));
  assert.ok(great.reviewers.every((reviewer) => reviewer.score >= 1 && reviewer.score <= 10 && reviewer.blurb.length > 0));
  const bad = reviewProduct({ seed: 26021, productId: "p1", topicId: "fitness", typeId: "software", design: 8, tech: 8, hype: 8 });
  assert.ok(baseScore(points, "crypto", "newsletter") > baseScore(points, "fitness", "newsletter"));
  assert.ok(great.score >= 5);
  assert.ok(bad.score <= great.score);

  const launch = { seed: 26021, productId: "p1", typeId: "newsletter" as const, score: 6, dayIndex: 0, reputation: 0 };
  const greatSales = salesForDay({ ...launch, fit: "great" });
  const badSales = salesForDay({ ...launch, fit: "bad" });
  assert.deepEqual(greatSales, salesForDay({ ...launch, fit: "great" }));
  assert.ok(greatSales.cents > badSales.cents);
  assert.ok(greatSales.fans >= 1 && badSales.fans >= 1);
  assert.ok(greatSales.units >= 1);
  const later = salesForDay({ ...launch, fit: "great", dayIndex: 3, reputation: 20 });
  assert.ok(later.cents > 0);
  assert.notDeepEqual(later, greatSales);
});

test("assigned staff add design, tech, and hype", () => {
  const founder = staffPoints(["founder"]);
  const withCreative = staffPoints(["founder", "creative"]);
  assert.deepEqual(founder, { design: 2, tech: 2, hype: 2 });
  assert.ok(withCreative.design > founder.design);
  assert.deepEqual(staffPoints(["founder", "founder"]), founder);
});

test("shipping a product pays cash and fans, then keeps selling on later days", async () => {
  const { db } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.equal(validate(db.bootstrap().journey), true, JSON.stringify(validate.errors));
  assert.equal(db.journey.state().company.cashCents, 0);
  assert.throws(() => db.tycoon.start("crypto", "newsletter", ["mira"]), /not on the team/u);
  db.tycoon.start("crypto", "newsletter", ["founder"]);
  assert.throws(() => db.tycoon.start("fitness", "course", []), /already on the bench/u);
  const started = db.tycoon.view().developing;
  assert.ok(started);
  assert.equal(started.name, "Crypto Alpha Newsletter");
  assert.equal(started.fit, "great");
  assert.equal(started.devDays, 0);
  assert.equal(started.ready, false);
  assert.throws(() => db.tycoon.release("p1"), /more office day/u);

  db.endDay(1);
  assert.equal(db.tycoon.view().developing?.devDays, 1);
  assert.equal(db.tycoon.view().developing?.design, 2);
  db.endDay(1);
  assert.equal(db.tycoon.view().developing?.devDays, 1, "ending the same day does not build twice");
  assert.equal(db.clockState().day, 2);

  db.endDay(2);
  const ready = db.tycoon.view().developing;
  assert.equal(ready?.devDays, 2);
  assert.equal(ready?.design, 4);
  assert.equal(ready?.tech, 4);
  assert.equal(ready?.hype, 4);
  assert.equal(ready?.ready, true);

  db.tycoon.release("p1");
  const shipped = db.tycoon.view().history[0];
  assert.equal(db.tycoon.view().developing, null);
  assert.equal(shipped?.status, "released");
  assert.equal(shipped?.salesDays, 1);
  assert.ok(shipped && shipped.salesCents > 0 && shipped.fans > 0);
  assert.equal(shipped.review?.reviewers.length, 4);
  const company = db.journey.state().company;
  assert.equal(company.cashCents, shipped.salesCents);
  assert.equal(company.reputation, shipped.fans);
  assert.ok(company.earnedCents === shipped.salesCents);
  const launchCash = company.cashCents;

  db.endDay(3);
  assert.equal(db.tycoon.view().history[0]?.salesCents, launchCash, "release day does not sell twice");
  db.endDay(4);
  const second = db.tycoon.view().history[0];
  assert.ok(second && second.salesCents > launchCash);
  assert.ok(db.journey.state().company.reputation > company.reputation);
  assert.equal(second.salesDays, 2);
  db.close();
});

test("a restarted company keeps the shipped product and the same payout", async () => {
  const first = await setup();
  first.db.tycoon.start("crypto", "newsletter", []);
  first.db.endDay(1);
  first.db.endDay(2);
  first.db.tycoon.release("p1");
  const original = first.db.tycoon.view().history[0];
  const cash = first.db.journey.state().company.cashCents;
  const file = join(first.root, "game.sqlite");
  const project = join(first.root, "company-project");
  first.db.close();

  const second = await setup();
  second.db.tycoon.start("crypto", "newsletter", []);
  second.db.endDay(1);
  second.db.endDay(2);
  second.db.tycoon.release("p1");
  assert.deepEqual(second.db.tycoon.view().history[0], original);
  assert.equal(second.db.journey.state().company.cashCents, cash);
  second.db.close();

  const restored = new GameDatabase(file, project);
  assert.deepEqual(restored.tycoon.view().history[0], original);
  assert.equal(restored.journey.state().company.cashCents, cash);
  assert.equal(restored.journey.state().company.reputation, original?.fans);
  restored.close();
});

test("stdio tycoon start, days, and release need no credential", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-tycoon-stdio-"));
  const child = spawn(process.execPath, ["dist/main.js", "--data-dir", root], {
    cwd: new URL("..", import.meta.url),
    stdio: ["pipe", "pipe", "pipe"],
    env: { ...process.env, STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS: "1" },
  });
  t.after(() => { child.kill("SIGTERM"); });
  let stderr = "";
  child.stderr.on("data", (chunk: Buffer) => { stderr += chunk.toString("utf8"); });
  const responses = new Map<string, (value: { ok: boolean; result?: any; error?: string }) => void>();
  const lines = createInterface({ input: child.stdout });
  lines.on("line", (line) => {
    const value = JSON.parse(line) as { id?: string };
    if (value.id) responses.get(value.id)?.(value as { ok: boolean; result?: any; error?: string });
  });
  const request = (id: string, method: string, params: object = {}) => new Promise<{ ok: boolean; result?: any; error?: string }>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out: ${method}`)), 8000);
    responses.set(id, (value) => { clearTimeout(timer); responses.delete(id); resolve(value); });
    child.stdin.write(`${JSON.stringify({ kind: "request", id, method, params })}\n`);
  });
  const locked = await request("locked", "tycoon.start", { topicId: "sneakers", typeId: "newsletter", staffIds: ["founder"] });
  assert.equal(locked.ok, false);
  assert.match(locked.error ?? "", /locked/u);
  const started = await request("start", "tycoon.start", { topicId: "crypto", typeId: "newsletter", staffIds: ["founder"] });
  assert.equal(started.ok, true, started.error);
  assert.equal(started.result.journey.tycoon.developing.name, "Crypto Alpha Newsletter");
  assert.equal(started.result.journey.company.cashCents, 0);
  assert.equal((await request("day1", "day.end", { day: 1 })).result.clock.day, 2);
  assert.equal((await request("day2", "day.end", { day: 2 })).result.journey.tycoon.developing.ready, true);
  const released = await request("release", "tycoon.release", { productId: "p1" });
  assert.equal(released.ok, true, released.error);
  assert.ok(released.result.journey.company.cashCents > 0);
  assert.ok(released.result.journey.company.reputation > 0);
  assert.equal(released.result.journey.tycoon.history[0].review.reviewers.length, 4);
  assert.equal(released.result.journey.tycoon.researchPoints, 5);
  assert.equal(released.result.journey.tycoon.history[0].researchPoints, 3);
  const researched = await request("research", "tycoon.research", { kind: "topic", id: "sneakers" });
  assert.equal(researched.ok, true, researched.error);
  assert.equal(researched.result.journey.tycoon.researchPoints, 1);
  assert.equal(researched.result.journey.tycoon.researchNotice, "Unlocked Sneakers. −4 RP");
  assert.equal(researched.result.journey.tycoon.topics.find((topic: { id: string }) => topic.id === "sneakers").unlocked, true);
  const short = await request("short", "tycoon.research", { kind: "type", id: "coaching" });
  assert.equal(short.ok, false);
  assert.match(short.error ?? "", /Not enough research points/u);
  const earlyOffice = await request("office-early", "tycoon.expandOffice", {});
  assert.equal(earlyOffice.ok, false);
  assert.match(earlyOffice.error ?? "", /Hire 2 people before the Open Floor/u);
  const unknownUpgrade = await request("unknown-upgrade", "tycoon.buyUpgrade", { id: "lava_lamp" });
  assert.equal(unknownUpgrade.ok, false);
  assert.match(unknownUpgrade.error ?? "", /Unknown upgrade/u);
  assert.equal((await request("day3", "day.end", { day: 3 })).result.clock.day, 4);
  const funded = await request("day4", "day.end", { day: 4 });
  assert.equal(funded.result.journey.company.cashCents, 33300);
  const bought = await request("buy", "tycoon.buyUpgrade", { id: "standing_desk" });
  assert.equal(bought.ok, true, bought.error);
  assert.equal(bought.result.journey.company.cashCents, 8300);
  assert.equal(bought.result.journey.tycoon.upgradeNotice, "Bought Oak Standing Desk. −$250");
  assert.equal(bought.result.journey.tycoon.upgrades.find((item: { id: string }) => item.id === "standing_desk").owned, true);
  const ownedAgain = await request("owned", "tycoon.buyUpgrade", { id: "standing_desk" });
  assert.equal(ownedAgain.ok, false);
  assert.match(ownedAgain.error ?? "", /already in the office/u);
  assert.equal((await request("day5", "day.end", { day: 5 })).result.journey.tycoon.upgradeNotice, "");
  assert.equal(stderr.includes("sk-"), false);
  child.stdin.end();
  await once(child, "exit");
  lines.close();
});

test("training costs cash, caps, and rejects unhired or a second lesson the same day", async () => {
  const { db } = await setup();
  const founder = db.tycoon.view().staff.find((person) => person.id === "founder");
  assert.equal(founder?.design, 2);
  assert.equal(founder?.training.tech.costCents, trainCostCents(2));
  assert.equal(founder?.training.tech.enabled, false);
  assert.throws(() => db.tycoon.train("founder", "tech"), /Not enough game cash/u);
  assert.throws(() => db.tycoon.train("mira", "tech"), /not on the team/u);

  db.journey.recordCompanyChange("test-cash", 1, 1_000_000, 0, 0, "Test cash");
  const afterGift = db.tycoon.view().staff.find((person) => person.id === "founder");
  assert.equal(afterGift?.training.tech.enabled, true);
  db.tycoon.train("founder", "tech");
  const trained = db.tycoon.view();
  const founderNow = trained.staff.find((person) => person.id === "founder");
  assert.equal(founderNow?.tech, 3);
  assert.equal(founderNow?.trainedToday, true);
  assert.equal(founderNow?.training.tech.enabled, false);
  assert.equal(trained.trainingNotice, "Founder trained Tech to 3. −$300");
  assert.equal(db.journey.state().company.cashCents, 1_000_000 - trainCostCents(2));
  assert.throws(() => db.tycoon.train("founder", "design"), /already in training today/u);
  assert.throws(() => db.tycoon.train("founder", "tech"), /already in training today/u);

  db.endDay(1);
  assert.equal(db.tycoon.view().trainingNotice, "");
  for (let level = 3; level < STAT_CAP; level += 1) {
    db.tycoon.train("founder", "tech");
    db.endDay(db.clockState().day);
  }
  const capped = db.tycoon.view().staff.find((person) => person.id === "founder");
  assert.equal(capped?.tech, STAT_CAP);
  assert.equal(capped?.training.tech.enabled, false);
  assert.equal(capped?.training.tech.costCents, 0);
  assert.throws(() => db.tycoon.train("founder", "tech"), /already at 10/u);
  db.close();
});

test("a product keeps the staff snapshot from the day it started", async () => {
  const { db } = await setup();
  db.journey.recordCompanyChange("test-cash", 1, 1_000_000, 0, 0, "Test cash");
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  assert.equal(db.tycoon.view().developing?.design, 2);
  assert.equal(db.tycoon.view().developing?.tech, 2);
  db.tycoon.train("founder", "tech");
  assert.equal(db.tycoon.view().staff.find((person) => person.id === "founder")?.tech, 3);
  db.endDay(2);
  const mid = db.tycoon.view().developing;
  assert.equal(mid?.devDays, 2);
  assert.equal(mid?.design, 2, "a person in training adds no points that office day");
  assert.equal(mid?.tech, 2, "training mid-build does not raise the current product");
  db.endDay(3);
  const polished = db.tycoon.view().developing;
  assert.equal(polished?.design, 4);
  assert.equal(polished?.tech, 4, "later days still use the start-day snapshot");
  db.tycoon.release("p1");

  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(4);
  const next = db.tycoon.view().developing;
  assert.equal(next?.design, 2);
  assert.equal(next?.tech, 3, "the next product uses the trained stats");
  db.close();
});

test("older saves without staff stats load starting values", async () => {
  const first = await setup();
  const file = join(first.root, "game.sqlite");
  const project = join(first.root, "company-project");
  first.db.close();
  const raw = new DatabaseSync(file);
  raw.exec("UPDATE tycoon_meta SET staff_json = ''");
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 0, 0, 0, 0, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(JSON.stringify(["founder"]));
  raw.close();

  const restored = new GameDatabase(file, project);
  const founder = restored.tycoon.view().staff.find((person) => person.id === "founder");
  assert.equal(founder?.design, 2);
  assert.equal(founder?.tech, 2);
  assert.equal(founder?.hype, 2);
  assert.equal(founder?.trainedToday, false);
  restored.endDay(1);
  const developing = restored.tycoon.view().developing;
  assert.equal(developing?.design, 2);
  assert.equal(developing?.tech, 2);
  assert.equal(developing?.hype, 2);
  restored.close();
});

test("a new company starts with the starter research catalog", async () => {
  const { db } = await setup();
  const view = db.tycoon.view();
  assert.equal(view.researchPoints, 0);
  assert.equal(view.researchNotice, "");
  assert.deepEqual(view.topics.filter((topic) => topic.unlocked).map((topic) => topic.id), [
    "fitness", "trading", "cooking", "gaming", "study_notes", "crypto",
  ]);
  assert.deepEqual(view.topics.filter((topic) => !topic.unlocked).map((topic) => topic.id), [
    "sneakers", "reselling", "sports_betting", "dating",
  ]);
  assert.deepEqual(view.types.filter((type) => type.unlocked).map((type) => type.id), [
    "course", "community", "template_pack", "newsletter",
  ]);
  assert.deepEqual(view.types.filter((type) => !type.unlocked).map((type) => type.id), [
    "coaching", "software",
  ]);
  assert.ok(view.topics.every((topic) => topic.researchCost === 4));
  assert.ok(view.types.every((type) => type.researchCost === 6));
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.tycoon.start("crypto", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.name, "Crypto Alpha Newsletter");
  assert.throws(() => db.tycoon.start("sneakers", "course", []), /already on the bench/u);
  db.close();
});

test("older saves that predate research load with everything unlocked", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-tycoon-preresearch-"));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  await mkdir(project);
  const old = new DatabaseSync(file);
  for (const name of [
    "001_initial.sql", "002_product_layer.sql", "003_persistent_studio.sql", "004_work_order_handoff.sql",
    "005_employee_chat.sql", "006_company_journey.sql", "007_furnishing.sql", "008_company_journey_opening.sql",
    "009_tycoon_products.sql", "010_tycoon_staff.sql",
  ]) old.exec(readFileSync(new URL(`../migrations/${name}`, import.meta.url), "utf8"));
  old.exec("CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)");
  for (const version of [2, 3, 4, 5, 6, 7, 8, 9, 10]) old.prepare("INSERT INTO schema_migrations VALUES (?, 'old')").run(version);
  old.close();

  const restored = new GameDatabase(file, project);
  const view = restored.tycoon.view();
  assert.equal(view.researchPoints, 0);
  assert.ok(view.topics.every((topic) => topic.unlocked));
  assert.ok(view.types.every((type) => type.unlocked));
  assert.ok(view.upgrades.every((item) => item.owned === false));
  restored.tycoon.start("sneakers", "software", []);
  assert.equal(restored.tycoon.view().developing?.name, "Sneakers Software Tool");
  assert.equal(restored.tycoon.view().developing?.researchBonus, 0);
  assert.ok(restored.tycoon.view().fits.every((fit) => fit.researchBonus === 0));
  restored.close();
});

test("development days and release award research points, and a training day does not", async () => {
  const { db } = await setup();
  assert.equal(db.tycoon.view().researchPoints, 0);
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  assert.equal(db.tycoon.view().researchPoints, 1);
  db.journey.hire("mira", 2);
  db.endDay(2);
  assert.equal(db.tycoon.view().researchPoints, 2, "Mina was not on this build");
  db.tycoon.release("p1");
  const shipped = db.tycoon.view().history[0];
  assert.equal(shipped?.review?.score, 6);
  assert.equal(shipped?.researchPoints, 3);
  assert.equal(db.tycoon.view().researchPoints, 5);

  db.journey.recordCompanyChange("test-cash", 3, 1_000_000, 0, 0, "Test cash");
  db.tycoon.start("crypto", "newsletter", ["mira"]);
  db.tycoon.train("founder", "tech");
  db.endDay(3);
  const mid = db.tycoon.view().developing;
  assert.equal(mid?.devDays, 1);
  assert.equal(db.tycoon.view().researchPoints, 6, "only Mina earns a point while the founder is in training");
  db.endDay(4);
  assert.equal(db.tycoon.view().researchPoints, 8, "the next office day both people earn a point");
  db.close();
});

test("research spends points and start rejects a locked topic or type", async () => {
  const { db, root } = await setup();
  assert.throws(() => db.tycoon.research("topic", "nope"), /Unknown topic/u);
  assert.throws(() => db.tycoon.research("type", "nope"), /Unknown product type/u);
  assert.throws(() => db.tycoon.research("fit", "sneakers"), /topic or a product type/u);
  assert.throws(() => db.tycoon.research("topic", "fitness"), /already unlocked/u);
  assert.throws(() => db.tycoon.research("type", "newsletter"), /already unlocked/u);
  assert.throws(() => db.tycoon.research("topic", "sneakers"), /Not enough research points/u);
  assert.throws(() => db.tycoon.start("sneakers", "newsletter", []), /Sneakers is locked/u);
  assert.throws(() => db.tycoon.start("crypto", "software", []), /Software Tool is locked/u);
  assert.throws(() => db.tycoon.start("dating", "coaching", []), /Dating Advice is locked/u);

  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  assert.equal(db.tycoon.view().researchPoints, 5);
  db.tycoon.research("topic", "sneakers");
  const unlocked = db.tycoon.view();
  assert.equal(unlocked.researchPoints, 1);
  assert.equal(unlocked.researchNotice, "Unlocked Sneakers. −4 RP");
  assert.equal(unlocked.topics.find((topic) => topic.id === "sneakers")?.unlocked, true);
  assert.throws(() => db.tycoon.research("topic", "sneakers"), /already unlocked/u);
  assert.throws(() => db.tycoon.research("type", "coaching"), /Not enough research points/u);
  db.tycoon.start("sneakers", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.name, "Sneakers Newsletter");
  db.endDay(3);
  assert.equal(db.tycoon.view().researchNotice, "");
  assert.equal(db.tycoon.view().researchPoints, 2);
  db.close();

  const restored = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  assert.equal(restored.tycoon.view().researchPoints, 2);
  assert.equal(restored.tycoon.view().topics.find((topic) => topic.id === "sneakers")?.unlocked, true);
  assert.equal(restored.tycoon.view().types.find((type) => type.id === "software")?.unlocked, false);
  assert.equal(restored.tycoon.view().developing?.name, "Sneakers Newsletter");
  restored.close();
});

test("a new company lists the upgrade catalog and nothing is owned yet", async () => {
  const { db } = await setup();
  const view = db.tycoon.view();
  assert.equal(view.upgradeNotice, "");
  assert.deepEqual(view.upgrades.map((item) => item.id), UPGRADES.map((item) => item.id));
  assert.deepEqual(view.upgrades.map((item) => item.priceCents), [25000, 36000, 40000, 56000]);
  assert.ok(view.upgrades.every((item) => item.owned === false && item.affordable === false && item.effect.length > 0 && item.blurb.length > 0));
  assert.equal(view.upgrades.find((item) => item.id === "standing_desk")?.kind, "design");
  assert.equal(view.upgrades.find((item) => item.id === "checkout_page")?.kind, "price");
  assert.equal(boostedPriceCents(900, 10), 990);
  assert.equal(boostedPriceCents(5, 10), 6);
  assert.equal(boostedPriceCents(900, 0), 900);
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.close();
});

test("older saves that predate the upgrades column load with none", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-tycoon-preupgrade-"));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  await mkdir(project);
  const old = new DatabaseSync(file);
  for (const name of [
    "001_initial.sql", "002_product_layer.sql", "003_persistent_studio.sql", "004_work_order_handoff.sql",
    "005_employee_chat.sql", "006_company_journey.sql", "007_furnishing.sql", "008_company_journey_opening.sql",
    "009_tycoon_products.sql", "010_tycoon_staff.sql", "011_tycoon_research.sql",
  ]) old.exec(readFileSync(new URL(`../migrations/${name}`, import.meta.url), "utf8"));
  old.exec("CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)");
  for (const version of [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) old.prepare("INSERT INTO schema_migrations VALUES (?, 'old')").run(version);
  old.close();

  const restored = new GameDatabase(file, project);
  const view = restored.tycoon.view();
  assert.equal(view.upgrades.length, 4);
  assert.ok(view.upgrades.every((item) => item.owned === false));
  assert.equal(view.upgradeNotice, "");
  const row = (restored as unknown as { journey: { db: DatabaseSync } }).journey.db
    .prepare("SELECT upgrades_json FROM tycoon_meta WHERE id = 1").get() as { upgrades_json: string };
  assert.equal(row.upgrades_json, "");
  restored.close();
});

test("buying an upgrade spends cash once and rejects unknown, owned, or broke", async () => {
  const { db, root } = await setup();
  assert.throws(() => db.tycoon.buyUpgrade("lava_lamp"), /Unknown upgrade/u);
  assert.throws(() => db.tycoon.buyUpgrade("standing_desk"), /Not enough game cash\. Oak Standing Desk costs \$250/u);
  assert.equal(db.journey.state().company.cashCents, 0);
  db.journey.recordCompanyChange("short", 1, 24_999, 0, 0, "Short cash");
  assert.throws(() => db.tycoon.buyUpgrade("standing_desk"), /Not enough game cash/u);
  assert.equal(db.journey.state().company.cashCents, 24_999);
  assert.ok(db.tycoon.view().upgrades.every((item) => item.owned === false));

  db.journey.recordCompanyChange("enough", 1, 1, 0, 0, "One more cent");
  const desk = db.tycoon.view().upgrades.find((item) => item.id === "standing_desk");
  assert.equal(desk?.affordable, true);
  db.tycoon.buyUpgrade("standing_desk");
  const bought = db.tycoon.view();
  assert.equal(db.journey.state().company.cashCents, 0);
  assert.equal(bought.upgradeNotice, "Bought Oak Standing Desk. −$250");
  assert.equal(bought.upgrades.find((item) => item.id === "standing_desk")?.owned, true);
  assert.equal(bought.upgrades.find((item) => item.id === "standing_desk")?.affordable, false);
  assert.equal(bought.upgrades.find((item) => item.id === "ring_light")?.affordable, false);
  assert.throws(() => db.tycoon.buyUpgrade("standing_desk"), /already in the office/u);
  assert.equal(db.journey.state().company.cashCents, 0);
  db.endDay(1);
  assert.equal(db.tycoon.view().upgradeNotice, "");
  assert.equal(db.tycoon.view().upgrades.find((item) => item.id === "standing_desk")?.owned, true);
  db.close();

  const restored = new GameDatabase(join(root, "game.sqlite"), join(root, "company-project"));
  assert.equal(restored.tycoon.view().upgradeNotice, "");
  assert.equal(restored.tycoon.view().upgrades.find((item) => item.id === "standing_desk")?.owned, true);
  assert.equal(restored.tycoon.view().upgrades.find((item) => item.id === "second_monitor")?.owned, false);
  restored.close();
});

test("point boosts apply on dev days after the purchase and leave the staff snapshot alone", async () => {
  const { db } = await setup();
  db.journey.recordCompanyChange("test-cash", 1, 1_000_000, 0, 0, "Test cash");
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  assert.equal(db.tycoon.view().developing?.design, 2);
  db.tycoon.buyUpgrade("standing_desk");
  assert.equal(db.tycoon.view().developing?.design, 2, "buying does not rewrite points already stored");
  assert.equal(db.tycoon.view().staff.find((person) => person.id === "founder")?.design, 2);
  db.endDay(2);
  const boosted = db.tycoon.view().developing;
  assert.equal(boosted?.devDays, 2);
  assert.equal(boosted?.design, 5, "the day that ends after the purchase adds founder 2 plus the desk");
  assert.equal(boosted?.tech, 4);
  assert.equal(boosted?.hype, 4);
  db.tycoon.train("founder", "tech");
  db.endDay(3);
  const trained = db.tycoon.view().developing;
  assert.equal(trained?.devDays, 3);
  assert.equal(trained?.design, 5, "a person in training adds no office bonus that day");
  assert.equal(trained?.tech, 4);
  db.tycoon.release("p1");

  db.journey.hire("mira", 4);
  db.tycoon.start("crypto", "newsletter", ["mira"]);
  db.endDay(4);
  const pair = db.tycoon.view().developing;
  assert.equal(pair?.design, 7, "founder 2 + Mina 3 + one desk point each");
  assert.equal(pair?.tech, 5, "the next product snapshots trained Tech 3 plus Mina's Tech 2");
  assert.equal(pair?.hype, 3);
  assert.equal(db.tycoon.view().staff.find((person) => person.id === "founder")?.design, 2);
  assert.equal(db.tycoon.view().staff.find((person) => person.id === "mira")?.design, 3);
  db.endDay(5);
  assert.equal(db.tycoon.view().developing?.design, 14, "the next day adds the same bonus and does not bake it into the snapshot");
  db.close();
});

test("the checkout upgrade raises later sales and does not rewrite a stored review", async () => {
  const { db } = await setup();
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const shipped = db.tycoon.view().history[0];
  assert.ok(shipped);
  const launch = shipped.salesCents;
  const review = structuredClone(shipped.review);
  assert.equal(launch, 20700);
  db.journey.recordCompanyChange("test-cash", 3, 1_000_000, 0, 0, "Test cash");
  db.tycoon.buyUpgrade("checkout_page");
  assert.deepEqual(db.tycoon.view().history[0]?.review, review);
  assert.equal(db.tycoon.view().history[0]?.salesCents, launch);
  db.endDay(3);
  assert.equal(db.tycoon.view().history[0]?.salesCents, launch, "the release day does not sell again");
  db.endDay(4);
  const second = db.tycoon.view().history[0];
  assert.equal(second?.salesCents, launch + 14 * 990);
  assert.deepEqual(second?.review, review);

  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(5);
  db.endDay(6);
  const before = db.journey.state().company.reputation;
  db.tycoon.release("p2");
  const next = db.tycoon.view().history.find((item) => item.id === "p2");
  assert.ok(next?.review);
  const expected = salesForDay({
    seed: 26021,
    productId: "p2",
    typeId: "newsletter",
    fit: "great",
    score: next.review.score,
    dayIndex: 0,
    reputation: before,
    priceBoostPercent: 10,
  });
  const plain = salesForDay({
    seed: 26021,
    productId: "p2",
    typeId: "newsletter",
    fit: "great",
    score: next.review.score,
    dayIndex: 0,
    reputation: before,
  });
  assert.equal(next.salesCents, expected.cents);
  assert.equal(next.salesCents, expected.units * 990);
  assert.ok(next.salesCents > plain.cents);
  assert.equal(next.fans, plain.fans);
  db.close();
});

test("the same upgrades and the same days pay the same cash", async () => {
  async function play() {
    const ctx = await setup();
    ctx.db.journey.recordCompanyChange("cash", 1, 500_000, 0, 0, "Cash");
    ctx.db.tycoon.buyUpgrade("ring_light");
    ctx.db.tycoon.buyUpgrade("checkout_page");
    ctx.db.tycoon.start("crypto", "newsletter", []);
    ctx.db.endDay(1);
    ctx.db.endDay(2);
    ctx.db.tycoon.release("p1");
    ctx.db.endDay(3);
    ctx.db.endDay(4);
    const view = ctx.db.tycoon.view();
    const company = ctx.db.journey.state().company;
    ctx.db.close();
    return {
      history: view.history,
      cash: company.cashCents,
      reputation: company.reputation,
      owned: view.upgrades.filter((item) => item.owned).map((item) => item.id),
    };
  }
  assert.deepEqual(await play(), await play());
});

test("the office calendar maps day boundaries and repeats every 112 days", () => {
  const spring = calendarForDay(1);
  assert.deepEqual(spring, calendarForDay(1));
  assert.equal(spring.season, "spring");
  assert.equal(spring.seasonName, "Spring");
  assert.equal(spring.dayOfSeason, 1);
  assert.equal(spring.year, 1);
  assert.equal(spring.label, "Spring 1 · Year 1");
  assert.deepEqual(spring.favoredTopics.map((topic) => topic.id), ["fitness", "dating"]);
  assert.deepEqual(spring.favoredTopics.map((topic) => topic.name), ["Fitness", "Dating Advice"]);
  assert.equal(spring.event, null);
  assert.equal(spring.nextEvent.name, "Creator Fair");
  assert.equal(spring.nextEvent.daysUntil, 12);

  const springThird = calendarForDay(3);
  assert.equal(springThird.label, "Spring 3 · Year 1");
  assert.equal(springThird.event, null);
  assert.equal(springThird.nextEvent.name, "Creator Fair");
  assert.equal(springThird.nextEvent.daysUntil, 10);

  const fair = calendarForDay(13);
  assert.equal(fair.dayOfSeason, 13);
  assert.equal(fair.event?.id, "creator_fair");
  assert.equal(fair.event?.name, "Creator Fair");
  assert.equal(fair.event?.effect, "+2 fans on sales today");
  assert.equal(fair.nextEvent.name, "Drop Day");
  assert.equal(fair.nextEvent.daysUntil, 26);

  const springEnd = calendarForDay(28);
  assert.equal(springEnd.season, "spring");
  assert.equal(springEnd.dayOfSeason, 28);
  assert.equal(springEnd.year, 1);
  assert.equal(springEnd.event, null);
  assert.deepEqual(springEnd.favoredTopics.map((topic) => topic.id), ["fitness", "dating"]);
  assert.equal(springEnd.nextEvent.name, "Drop Day");
  assert.equal(springEnd.nextEvent.daysUntil, 11);

  const summer = calendarForDay(29);
  assert.equal(summer.season, "summer");
  assert.equal(summer.dayOfSeason, 1);
  assert.equal(summer.year, 1);
  assert.equal(summer.label, "Summer 1 · Year 1");
  assert.deepEqual(summer.favoredTopics.map((topic) => topic.name), ["Sneakers", "Sports Betting Picks"]);
  assert.equal(summer.event, null);
  assert.equal(summer.nextEvent.name, "Drop Day");
  assert.equal(summer.nextEvent.daysUntil, 10);

  assert.equal(calendarForDay(39).event?.name, "Drop Day");
  assert.equal(calendarForDay(57).season, "fall");
  assert.equal(calendarForDay(57).dayOfSeason, 1);
  assert.deepEqual(calendarForDay(57).favoredTopics.map((topic) => topic.name), ["Study Notes", "Trading"]);
  assert.equal(calendarForDay(72).event?.name, "Cohort Kickoff");
  assert.equal(calendarForDay(85).season, "winter");
  assert.equal(calendarForDay(85).dayOfSeason, 1);
  assert.deepEqual(calendarForDay(85).favoredTopics.map((topic) => topic.name), ["Cooking", "Gaming"]);
  assert.equal(calendarForDay(109).event?.name, "Cozy Gift Guide");

  const yearEnd = calendarForDay(112);
  assert.equal(yearEnd.season, "winter");
  assert.equal(yearEnd.dayOfSeason, 28);
  assert.equal(yearEnd.year, 1);
  assert.equal(yearEnd.label, "Winter 28 · Year 1");
  assert.equal(yearEnd.event, null);
  assert.equal(yearEnd.nextEvent.name, "Creator Fair");
  assert.equal(yearEnd.nextEvent.daysUntil, 13);

  const nextYear = calendarForDay(113);
  assert.equal(nextYear.season, "spring");
  assert.equal(nextYear.dayOfSeason, 1);
  assert.equal(nextYear.year, 2);
  assert.equal(nextYear.label, "Spring 1 · Year 2");
  assert.deepEqual(nextYear.favoredTopics.map((topic) => topic.id), ["fitness", "dating"]);
  assert.equal(nextYear.event, null);
  assert.equal(nextYear.nextEvent.daysUntil, 12);
  assert.deepEqual(calendarForDay(113), calendarForDay(113));

  const eventDays = new Set([13, 39, 72, 109]);
  for (let day = 1; day <= 113; day += 1) {
    const dayOfYear = ((day - 1) % 112) + 1;
    const calendar = calendarForDay(day);
    assert.equal(calendar.event === null, !eventDays.has(dayOfYear), `day ${day}`);
    assert.ok(calendar.nextEvent.daysUntil >= 1);
    assert.equal(calendar.dayOfSeason >= 1 && calendar.dayOfSeason <= 28, true);
  }
});

test("a favored topic gains 20 percent units, rounded, and an event adds fans only on its day", async () => {
  const input = {
    seed: 26021,
    productId: "p9",
    typeId: "newsletter" as const,
    fit: "great" as const,
    score: 8,
    dayIndex: 0,
    reputation: 0,
  };
  const plain = salesForDay(input);
  const boosted = salesForDay({ ...input, unitBoostPercent: SEASON_UNIT_BOOST_PERCENT });
  assert.equal(boosted.units, Math.max(1, Math.round((plain.units * 120) / 100)));
  assert.ok(boosted.units > plain.units);
  assert.equal(boosted.cents, boosted.units * 900);
  assert.equal(boosted.fans, Math.max(1, Math.round((boosted.units * 400) / 1000)));
  const withEvent = salesForDay({ ...input, bonusFans: EVENT_BONUS_FANS });
  assert.equal(withEvent.units, plain.units);
  assert.equal(withEvent.cents, plain.cents);
  assert.equal(withEvent.fans, plain.fans + EVENT_BONUS_FANS);
  const both = salesForDay({ ...input, unitBoostPercent: SEASON_UNIT_BOOST_PERCENT, bonusFans: EVENT_BONUS_FANS });
  assert.equal(both.units, boosted.units);
  assert.equal(both.cents, boosted.cents);
  assert.equal(both.fans, boosted.fans + EVENT_BONUS_FANS);
  assert.deepEqual(salesForDay({ ...input, unitBoostPercent: 0, bonusFans: 0 }), plain);
  assert.deepEqual(salesForDay(input), plain);

  const { db } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.equal(db.tycoon.view().calendar.label, "Spring 1 · Year 1");
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));

  db.tycoon.start("fitness", "newsletter", []);
  db.endDay(1);
  db.endDay(2);
  const before = db.journey.state().company.reputation;
  db.tycoon.release("p1");
  const launched = db.tycoon.view().history[0];
  assert.ok(launched?.review);
  const review = structuredClone(launched.review);
  const favored = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: launched.fit,
    score: launched.review.score,
    dayIndex: 0,
    reputation: before,
    unitBoostPercent: SEASON_UNIT_BOOST_PERCENT,
  });
  const unfavored = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: launched.fit,
    score: launched.review.score,
    dayIndex: 0,
    reputation: before,
  });
  assert.equal(launched.salesCents, favored.cents);
  assert.equal(launched.fans, favored.fans);
  assert.ok(favored.units > unfavored.units);
  assert.equal(launched.salesCents, favored.units * 900);
  db.endDay(3);
  assert.equal(db.tycoon.view().history[0]?.salesCents, launched.salesCents, "the release day does not sell twice");
  assert.deepEqual(db.tycoon.view().history[0]?.review, review);
  db.endDay(4);
  const second = db.tycoon.view().history[0];
  assert.ok(second?.review);
  const nextPayout = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: second.fit,
    score: second.review.score,
    dayIndex: 1,
    reputation: launched.fans,
    unitBoostPercent: SEASON_UNIT_BOOST_PERCENT,
  });
  assert.equal(second.salesCents - launched.salesCents, nextPayout.cents);
  assert.equal(second.fans - launched.fans, nextPayout.fans);
  assert.deepEqual(second.review, review, "a later season boost does not rewrite the stored review");
  db.close();

  const summer = await setup();
  summer.db.setClock(29, 480, 0);
  assert.equal(summer.db.tycoon.view().calendar.season, "summer");
  summer.db.tycoon.start("fitness", "newsletter", []);
  summer.db.endDay(29);
  summer.db.endDay(30);
  const summerBefore = summer.db.journey.state().company.reputation;
  summer.db.tycoon.release("p1");
  const summerLaunch = summer.db.tycoon.view().history[0];
  assert.ok(summerLaunch?.review);
  const summerPlain = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: summerLaunch.fit,
    score: summerLaunch.review.score,
    dayIndex: 0,
    reputation: summerBefore,
  });
  assert.equal(summerLaunch.salesCents, summerPlain.cents, "Fitness is not favored in Summer");
  assert.equal(summerLaunch.fans, summerPlain.fans);
  summer.db.close();

  const fair = await setup();
  fair.db.setClock(11, 480, 0);
  fair.db.tycoon.start("crypto", "newsletter", []);
  fair.db.endDay(11);
  fair.db.endDay(12);
  assert.equal(fair.db.tycoon.view().calendar.event?.name, "Creator Fair");
  const fairBefore = fair.db.journey.state().company.reputation;
  fair.db.tycoon.release("p1");
  const fairLaunch = fair.db.tycoon.view().history[0];
  assert.ok(fairLaunch?.review);
  const fairSale = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: fairLaunch.fit,
    score: fairLaunch.review.score,
    dayIndex: 0,
    reputation: fairBefore,
    bonusFans: EVENT_BONUS_FANS,
  });
  const fairPlain = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: fairLaunch.fit,
    score: fairLaunch.review.score,
    dayIndex: 0,
    reputation: fairBefore,
  });
  assert.equal(fairLaunch.salesCents, fairSale.cents);
  assert.equal(fairLaunch.salesCents, fairPlain.cents, "Creator Fair does not change units for Crypto Alpha");
  assert.equal(fairLaunch.fans, fairPlain.fans + EVENT_BONUS_FANS);
  const launchFans = fairLaunch.fans;
  const launchCents = fairLaunch.salesCents;
  fair.db.endDay(13);
  assert.equal(fair.db.tycoon.view().history[0]?.fans, launchFans, "ending the event day does not sell twice");
  fair.db.endDay(14);
  const after = fair.db.tycoon.view().history[0];
  assert.ok(after?.review);
  const dayAfter = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: after.fit,
    score: after.review.score,
    dayIndex: 1,
    reputation: launchFans,
  });
  assert.equal(after.salesCents - launchCents, dayAfter.cents);
  assert.equal(after.fans - launchFans, dayAfter.fans, "the next office day does not keep the event fans");
  assert.deepEqual(after.review, fairLaunch.review);
  assert.equal(validate(fair.db.journey.state()), true, JSON.stringify(validate.errors));
  fair.db.close();
});

test("an older save loads and the calendar follows the clock day", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-tycoon-preseason-"));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  await mkdir(project);
  const old = new DatabaseSync(file);
  for (const name of [
    "001_initial.sql", "002_product_layer.sql", "003_persistent_studio.sql", "004_work_order_handoff.sql",
    "005_employee_chat.sql", "006_company_journey.sql", "007_furnishing.sql", "008_company_journey_opening.sql",
    "009_tycoon_products.sql", "010_tycoon_staff.sql", "011_tycoon_research.sql",
  ]) old.exec(readFileSync(new URL(`../migrations/${name}`, import.meta.url), "utf8"));
  old.exec("CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)");
  for (const version of [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) old.prepare("INSERT INTO schema_migrations VALUES (?, 'old')").run(version);
  const storedReview = JSON.stringify({
    score: 6,
    reviewers: [
      { name: "TownSquare Weekly", score: 6, blurb: "Fine." },
      { name: "Discord Dave", score: 6, blurb: "Fine." },
      { name: "Margin Call Molly", score: 6, blurb: "Fine." },
      { name: "Cohort Casey", score: 6, blurb: "Fine." },
    ],
  });
  old.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans, release_research
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'complete', 1, 2, 4, 4, 6, '[]', 2, 3, ?, 4, 6, 12345, 7, 3)
  `).run(storedReview);
  old.close();

  const restored = new GameDatabase(file, project);
  const loaded = restored.tycoon.view();
  assert.equal(loaded.calendar.season, "spring");
  assert.equal(loaded.calendar.dayOfSeason, 1);
  assert.equal(loaded.calendar.year, 1);
  assert.equal(loaded.calendar.label, "Spring 1 · Year 1");
  assert.equal(loaded.history[0]?.salesCents, 12345);
  assert.equal(loaded.history[0]?.fans, 7);
  assert.equal(loaded.history[0]?.review?.score, 6);
  restored.endDay(1);
  const afterDay = restored.tycoon.view().history[0];
  assert.equal(afterDay?.salesCents, 12345, "ending a day does not rewrite a finished product's sales");
  assert.equal(afterDay?.fans, 7);
  assert.deepEqual(afterDay?.review, JSON.parse(storedReview));
  assert.equal(restored.tycoon.view().calendar.label, "Spring 2 · Year 1");
  restored.setClock(28, 480, 0);
  assert.equal(restored.tycoon.view().calendar.label, "Spring 28 · Year 1");
  restored.setClock(29, 480, 0);
  assert.equal(restored.tycoon.view().calendar.label, "Summer 1 · Year 1");
  restored.setClock(112, 480, 0);
  assert.equal(restored.tycoon.view().calendar.label, "Winter 28 · Year 1");
  restored.setClock(113, 480, 0);
  assert.equal(restored.tycoon.view().calendar.label, "Spring 1 · Year 2");
  assert.equal(restored.tycoon.view().history[0]?.salesCents, 12345);
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.equal(validate(restored.journey.state()), true, JSON.stringify(validate.errors));
  restored.close();

  const again = new GameDatabase(file, project);
  assert.equal(again.tycoon.view().calendar.label, "Spring 1 · Year 2");
  assert.equal(again.tycoon.view().history[0]?.salesCents, 12345);
  assert.equal(again.tycoon.view().history[0]?.fans, 7);
  again.close();
});

async function teamOfThree(root: string, db: GameDatabase, cashCents: number): Promise<GameDatabase> {
  db.journey.hire("mira", 1);
  db.close();
  const file = join(root, "game.sqlite");
  const sql = new DatabaseSync(file);
  sql.prepare("UPDATE milestone_progress SET completed = 1 WHERE id = 'website'").run();
  sql.close();
  const next = new GameDatabase(file, join(root, "company-project"));
  next.journey.recordCompanyChange("office-team-cash", 1, cashCents, 0, 0, "Office team cash");
  next.journey.hire("theo", 1);
  return next;
}

test("a new company starts in the Garage Loft and an older save stays at level 1", async () => {
  const { db } = await setup();
  const office = db.tycoon.view().office;
  assert.equal(office.level, 1);
  assert.equal(office.name, "Garage Loft");
  assert.equal(office.blurb, "A checkout link and one desk by the garage door.");
  assert.deepEqual(office.desks, { used: 1, total: 4 });
  assert.equal(office.next?.name, "Open Floor");
  assert.equal(office.next?.costCents, 60_000);
  assert.equal(office.next?.requiredHires, 2);
  assert.equal(office.next?.enabled, false);
  assert.equal(office.next?.reason, "Hire 2 people first.");
  const before = db.furnishing.state();
  assert.equal(before.inventory.some((item) => item.id.startsWith("spare-")), false);
  assert.equal(before.placements["spare-compact-a"], undefined);
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.close();

  const root = await mkdtemp(join(tmpdir(), "startup-valley-tycoon-preoffice-"));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  await mkdir(project);
  const old = new DatabaseSync(file);
  for (const name of [
    "001_initial.sql", "002_product_layer.sql", "003_persistent_studio.sql", "004_work_order_handoff.sql",
    "005_employee_chat.sql", "006_company_journey.sql", "007_furnishing.sql", "008_company_journey_opening.sql",
    "009_tycoon_products.sql", "010_tycoon_staff.sql", "011_tycoon_research.sql", "012_tycoon_upgrades.sql",
  ]) old.exec(readFileSync(new URL(`../migrations/${name}`, import.meta.url), "utf8"));
  old.exec("CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)");
  for (const version of [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) old.prepare("INSERT INTO schema_migrations VALUES (?, 'old')").run(version);
  old.close();
  const restored = new GameDatabase(file, project);
  const loaded = restored.tycoon.view().office;
  assert.equal(loaded.level, 1);
  assert.equal(loaded.name, "Garage Loft");
  assert.deepEqual(loaded.desks, { used: 1, total: 4 });
  assert.equal(loaded.next?.enabled, false);
  const row = (restored as unknown as { journey: { db: DatabaseSync } }).journey.db
    .prepare("SELECT office_level FROM tycoon_meta WHERE id = 1").get() as { office_level: number };
  assert.equal(row.office_level, 1);
  assert.equal(validate(restored.journey.state()), true, JSON.stringify(validate.errors));
  restored.close();
});

test("expanding the office rejects a short team, short cash, and a second buy", async () => {
  const fresh = await setup();
  assert.throws(() => fresh.db.tycoon.expandOffice(), /Hire 2 people before the Open Floor/u);
  assert.equal(fresh.db.journey.state().company.cashCents, 0);
  assert.equal(fresh.db.tycoon.view().office.level, 1);
  fresh.db.journey.recordCompanyChange("mira-cash", 1, 60_000, 0, 0, "Mina cash");
  fresh.db.journey.hire("mira", 1);
  assert.equal(fresh.db.tycoon.view().office.desks.used, 2);
  assert.equal(fresh.db.tycoon.view().office.next?.reason, "Hire 2 people first.");
  assert.throws(() => fresh.db.tycoon.expandOffice(), /Hire 2 people before the Open Floor/u);
  assert.equal(fresh.db.journey.state().company.cashCents, 60_000);
  fresh.db.close();

  const broke = await setup();
  const short = await teamOfThree(broke.root, broke.db, 89_999);
  assert.equal(short.journey.state().company.cashCents, 59_999);
  assert.deepEqual(short.tycoon.view().office.desks, { used: 3, total: 4 });
  assert.equal(short.tycoon.view().office.next?.enabled, false);
  assert.equal(short.tycoon.view().office.next?.reason, "Need $600 game cash.");
  assert.throws(() => short.tycoon.expandOffice(), /Not enough game cash\. Open Floor costs \$600/u);
  assert.equal(short.journey.state().company.cashCents, 59_999);
  assert.equal(short.tycoon.view().office.level, 1);
  short.close();

  const ready = await setup();
  const db = await teamOfThree(ready.root, ready.db, 90_000);
  assert.equal(db.journey.state().company.cashCents, 60_000);
  assert.equal(db.tycoon.view().office.next?.enabled, true);
  assert.equal(db.tycoon.view().office.next?.reason, "");
  db.tycoon.expandOffice();
  const expanded = db.tycoon.view().office;
  assert.equal(db.journey.state().company.cashCents, 0);
  assert.equal(expanded.level, 2);
  assert.equal(expanded.name, "Open Floor");
  assert.equal(expanded.blurb, "Spare desks for the next drop.");
  assert.deepEqual(expanded.desks, { used: 3, total: 7 });
  assert.equal(expanded.next, null);
  const room = db.furnishing.state();
  for (const [id, grid] of [
    ["spare-compact-a", [20, 17]],
    ["spare-compact-b", [25, 17]],
    ["spare-workbench", [23, 14]],
  ] as const) {
    const item = room.inventory.find((entry) => entry.id === id);
    assert.equal(item?.essential, true);
    assert.equal(item?.grant, "office-level:2");
    assert.deepEqual(room.placements[id], { grid: [...grid], facing: "south" });
  }
  assert.equal(room.inventory.find((entry) => entry.id === "spare-workbench")?.kind, "shared_workbench");
  assert.throws(() => db.tycoon.expandOffice(), /already as large as it gets/u);
  assert.equal(db.journey.state().company.cashCents, 0);
  assert.equal(db.tycoon.view().office.level, 2);
  db.close();

  const reopened = new GameDatabase(join(ready.root, "game.sqlite"), join(ready.root, "company-project"));
  assert.equal(reopened.tycoon.view().office.level, 2);
  assert.equal(reopened.tycoon.view().office.desks.total, 7);
  assert.equal(reopened.furnishing.state().placements["spare-compact-a"]?.grid[0], 20);
  reopened.close();
});

test("the Open Floor dev bonus is flat, stacks with upgrades, and skips training and polish days", async () => {
  const play = async (expand: boolean) => {
    const opened = await setup();
    const db = await teamOfThree(opened.root, opened.db, 200_000);
    if (expand) db.tycoon.expandOffice();
    db.tycoon.start("crypto", "newsletter", ["founder"]);
    db.endDay(1);
    return db;
  };
  const loft = await play(false);
  const floor = await play(true);
  assert.equal(loft.tycoon.view().developing?.design, 2);
  assert.equal(loft.tycoon.view().developing?.tech, 2);
  assert.equal(loft.tycoon.view().developing?.hype, 2);
  assert.equal(floor.tycoon.view().developing?.design, 3);
  assert.equal(floor.tycoon.view().developing?.tech, 3);
  assert.equal(floor.tycoon.view().developing?.hype, 2);
  floor.tycoon.buyUpgrade("standing_desk");
  assert.equal(floor.tycoon.view().developing?.design, 3, "buying a tool does not rewrite stored points");
  floor.endDay(2);
  assert.equal(floor.tycoon.view().developing?.design, 7, "founder 2, plus the desk, plus the flat office bonus");
  assert.equal(floor.tycoon.view().developing?.tech, 6);
  assert.equal(floor.tycoon.view().developing?.hype, 4);
  loft.close();
  floor.close();

  const training = await setup();
  const trained = await teamOfThree(training.root, training.db, 200_000);
  trained.tycoon.expandOffice();
  trained.tycoon.start("crypto", "newsletter", ["founder"]);
  trained.endDay(1);
  trained.tycoon.train("founder", "tech");
  trained.endDay(2);
  const paused = trained.tycoon.view().developing;
  assert.equal(paused?.design, 3, "a training day adds no office bonus");
  assert.equal(paused?.tech, 3);
  assert.equal(paused?.hype, 2);
  trained.close();

  const run = async () => {
    const opened = await setup();
    const db = await teamOfThree(opened.root, opened.db, 90_000);
    db.tycoon.expandOffice();
    db.tycoon.start("crypto", "newsletter", ["founder"]);
    for (let day = 1; day <= 5; day += 1) db.endDay(day);
    const developing = db.tycoon.view().developing;
    db.close();
    return developing;
  };
  const first = await run();
  const second = await run();
  assert.deepEqual(
    { design: first?.design, tech: first?.tech, hype: first?.hype, devDays: first?.devDays },
    { design: second?.design, tech: second?.tech, hype: second?.hype, devDays: second?.devDays },
  );
  assert.equal(first?.devDays, 5);
  assert.equal(first?.design, 12, "four accruing days add +1, and the polish day after that adds none");
  assert.equal(first?.tech, 12);
  assert.equal(first?.hype, 8);
});

test("research fit bonus counts only parts bought with research points", async () => {
  const starter = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.ok(starter.db.tycoon.view().fits.every((fit) => fit.researchBonus === 0));
  starter.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(starter.db.tycoon.view().developing?.researchBonus, 0);
  starter.db.endDay(1);
  starter.db.endDay(2);
  starter.db.tycoon.release("p1");
  const launch = starter.db.tycoon.view().history[0];
  assert.equal(launch?.researchBonus, 0);
  assert.equal(launch?.salesCents, 20700);
  assert.equal(launch?.fans, 5);

  starter.db.journey.db.prepare("UPDATE tycoon_meta SET research_points = research_points + 20 WHERE id = 1").run();
  starter.db.tycoon.research("topic", "sneakers");
  const view = starter.db.tycoon.view();
  assert.equal(view.fits.find((fit) => fit.topicId === "sneakers" && fit.typeId === "newsletter")?.researchBonus, 6);
  assert.equal(view.fits.find((fit) => fit.topicId === "crypto" && fit.typeId === "newsletter")?.researchBonus, 0);
  starter.db.tycoon.start("sneakers", "newsletter", []);
  starter.db.endDay(3);
  starter.db.endDay(4);
  const built = starter.db.tycoon.view().developing;
  assert.ok(built);
  assert.equal(built.researchBonus, 6);
  const earned = { design: built.design, tech: built.tech, hype: built.hype };
  assert.ok(baseScore(earned, "sneakers", "newsletter", 6) >= baseScore(earned, "sneakers", "newsletter", 0));
  const picked = { design: 5, tech: 5, hype: 6 };
  assert.ok(baseScore(picked, "sneakers", "newsletter", 6) > baseScore(picked, "sneakers", "newsletter", 0));
  const snapshot = () => JSON.parse(String((starter.db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p2'").get() as { staff_json: string }).staff_json)) as { researchBonus?: number };
  assert.equal(snapshot().researchBonus, 6);

  starter.db.tycoon.research("type", "coaching");
  assert.equal(starter.db.tycoon.view().developing?.researchBonus, 6);
  assert.equal(starter.db.tycoon.view().fits.find((fit) => fit.topicId === "sneakers" && fit.typeId === "coaching")?.researchBonus, 12);
  assert.equal(snapshot().researchBonus, 6);

  starter.db.tycoon.release("p2");
  starter.db.tycoon.research("topic", "dating");
  starter.db.tycoon.start("dating", "coaching", []);
  assert.equal(starter.db.tycoon.view().developing?.researchBonus, 12);
  starter.db.endDay(5);
  starter.db.endDay(6);
  starter.db.endDay(7);
  const pair = starter.db.tycoon.view().developing;
  assert.ok(pair);
  assert.equal(pair.researchBonus, 12);
  const pairPoints = { design: pair.design, tech: pair.tech, hype: pair.hype };
  assert.ok(baseScore(pairPoints, "dating", "coaching", 12) > baseScore(pairPoints, "dating", "coaching", 0));
  starter.db.tycoon.release("p3");
  const shipped = starter.db.tycoon.view().history[0];
  const reviewInput = {
    seed: starter.db.tycoon.view().seed,
    productId: "p3",
    topicId: "dating" as const,
    typeId: "coaching" as const,
    ...pairPoints,
  };
  assert.deepEqual(shipped?.review, reviewProduct({ ...reviewInput, researchBonus: 12 }));
  assert.notDeepEqual(shipped?.review, reviewProduct({ ...reviewInput, researchBonus: 0 }));
  assert.equal(validate(starter.db.journey.state()), true, JSON.stringify(validate.errors));
  starter.db.close();

  const legacy = await setup();
  legacy.db.journey.db.prepare("UPDATE tycoon_meta SET research_json = ? WHERE id = 1").run(JSON.stringify({
    topics: ["fitness", "trading", "cooking", "gaming", "study_notes", "crypto", "sneakers"],
    types: ["course", "community", "template_pack", "newsletter", "coaching"],
  }));
  assert.ok(legacy.db.tycoon.view().fits.every((fit) => fit.researchBonus === 0));
  legacy.db.tycoon.start("sneakers", "coaching", []);
  assert.equal(legacy.db.tycoon.view().developing?.researchBonus, 0);
  assert.equal(baseScore({ design: 6, tech: 6, hype: 6 }, "sneakers", "coaching", 0), baseScore({ design: 6, tech: 6, hype: 6 }, "sneakers", "coaching"));
  legacy.db.close();
  const reopened = new GameDatabase(join(legacy.root, "game.sqlite"), join(legacy.root, "company-project"));
  assert.equal(reopened.tycoon.view().developing?.researchBonus, 0);
  assert.ok(reopened.tycoon.view().fits.every((fit) => fit.researchBonus === 0));
  reopened.close();
});

test("launch price nudges units the other way and snapshots the choice", async () => {
  const catalog = { seed: 26021, productId: "p1", typeId: "newsletter" as const, fit: "great" as const, score: 6, dayIndex: 0, reputation: 0 };
  const plain = salesForDay(catalog);
  assert.equal(plain.units, 23);
  assert.equal(plain.cents, 20700);
  assert.equal(plain.fans, 5);
  assert.deepEqual(salesForDay({ ...catalog, pricePercent: 100 }), plain);
  assert.deepEqual(salesForDay(catalog), plain);

  const cheap = salesForDay({ ...catalog, pricePercent: 80 });
  assert.equal(cheap.units, applyLaunchPriceUnits(plain.units, 80));
  assert.equal(cheap.units, Math.max(1, Math.round((plain.units * 120) / 100)));
  assert.ok(cheap.units > plain.units);
  assert.equal(cheap.cents, cheap.units * launchPriceCents(900, 80));
  assert.equal(cheap.cents, cheap.units * 720);
  assert.equal(cheap.fans, Math.max(1, Math.round((cheap.units * 200) / 1000)));

  const premium = salesForDay({ ...catalog, pricePercent: 120 });
  assert.equal(premium.units, applyLaunchPriceUnits(plain.units, 120));
  assert.equal(premium.units, Math.max(1, Math.round((plain.units * 80) / 100)));
  assert.ok(premium.units < plain.units);
  assert.equal(premium.cents, premium.units * 1080);
  assert.equal(applyLaunchPriceUnits(1, 120), 1);

  const composed = salesForDay({ ...catalog, pricePercent: 80, unitBoostPercent: SEASON_UNIT_BOOST_PERCENT, priceBoostPercent: 10 });
  let units = applyLaunchPriceUnits(plain.units, 80);
  units = Math.max(1, Math.round((units * 120) / 100));
  const price = boostedPriceCents(launchPriceCents(900, 80), 10);
  assert.equal(composed.units, units);
  assert.equal(composed.cents, units * price);
  assert.equal(composed.fans, Math.max(1, Math.round((units * 200) / 1000)));
  const seasonThenCheckout = salesForDay({ ...catalog, unitBoostPercent: SEASON_UNIT_BOOST_PERCENT, priceBoostPercent: 10 });
  assert.equal(seasonThenCheckout.cents, Math.max(1, Math.round((plain.units * 120) / 100)) * 990);

  const { db } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  assert.deepEqual(db.tycoon.view().priceSteps, [...LAUNCH_PRICES]);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.tycoon.start("crypto", "newsletter", []);
  const starter = db.tycoon.view().developing;
  assert.equal(starter?.pricePercent, 100);
  assert.equal(starter?.priceCents, 900);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const catalogLaunch = db.tycoon.view().history[0];
  assert.equal(catalogLaunch?.pricePercent, 100);
  assert.equal(catalogLaunch?.priceCents, 900);
  assert.equal(catalogLaunch?.salesCents, 20700);
  assert.equal(catalogLaunch?.fans, 5);
  const catalogSnapshot = JSON.parse(String((db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json)) as { pricePercent?: number };
  assert.equal(catalogSnapshot.pricePercent, 100);

  assert.throws(() => db.tycoon.start("crypto", "newsletter", [], 90), /Pick −20%, catalog, or \+20%/u);
  db.tycoon.start("crypto", "newsletter", [], 80);
  const cheapRow = db.tycoon.view().developing;
  assert.equal(cheapRow?.pricePercent, 80);
  assert.equal(cheapRow?.priceCents, 720);
  const stored = JSON.parse(String((db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p2'").get() as { staff_json: string }).staff_json)) as { pricePercent?: number; researchBonus?: number };
  assert.equal(stored.pricePercent, 80);
  db.endDay(3);
  db.endDay(4);
  const before = db.journey.state().company.reputation;
  db.tycoon.release("p2");
  const cheapLaunch = db.tycoon.view().history.find((item) => item.id === "p2");
  assert.ok(cheapLaunch?.review);
  const expectedCheap = salesForDay({
    seed: 26021,
    productId: "p2",
    typeId: "newsletter",
    fit: "great",
    score: cheapLaunch.review.score,
    dayIndex: 0,
    reputation: before,
    pricePercent: 80,
  });
  assert.equal(cheapLaunch.salesCents, expectedCheap.cents);
  assert.equal(cheapLaunch.fans, expectedCheap.fans);
  assert.ok(cheapLaunch.salesCents !== 20700);
  assert.equal(stored.pricePercent, 80);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.close();

  const legacy = await setup();
  const file = join(legacy.root, "game.sqlite");
  const project = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(file);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(JSON.stringify(["founder"]));
  raw.close();
  const restored = new GameDatabase(file, project);
  assert.equal(restored.tycoon.view().developing?.pricePercent, 100);
  assert.equal(restored.tycoon.view().developing?.priceCents, 900);
  restored.tycoon.release("p1");
  const oldLaunch = restored.tycoon.view().history[0];
  assert.equal(oldLaunch?.pricePercent, 100);
  assert.equal(oldLaunch?.salesCents, 20700);
  assert.equal(oldLaunch?.fans, 5);
  const oldJson = String((restored.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json);
  assert.equal(oldJson, JSON.stringify(["founder"]));
  restored.close();
});

test("marketing buys extra units, charges at the start, and leaves old rows alone", async () => {
  const catalog = { seed: 26021, productId: "p1", typeId: "newsletter" as const, fit: "great" as const, score: 6, dayIndex: 0, reputation: 0 };
  const plain = salesForDay(catalog);
  assert.equal(plain.units, 23);
  assert.equal(plain.cents, 20700);
  assert.equal(plain.fans, 5);
  assert.deepEqual(salesForDay({ ...catalog, marketing: "none" }), plain);
  assert.deepEqual(salesForDay(catalog), plain);

  const small = salesForDay({ ...catalog, marketing: "small" });
  assert.equal(small.units, applyMarketingUnits(plain.units, "small"));
  assert.equal(small.units, Math.max(1, Math.round((plain.units * 120) / 100)));
  assert.equal(small.cents, small.units * 900);
  assert.equal(small.fans, Math.max(1, Math.round((small.units * 200) / 1000)));
  assert.ok(small.units > plain.units);

  const big = salesForDay({ ...catalog, marketing: "big" });
  assert.equal(big.units, Math.max(1, Math.round((plain.units * 150) / 100)));
  assert.equal(big.cents, big.units * 900);
  assert.equal(applyMarketingUnits(1, "none"), 1);
  assert.equal(applyMarketingUnits(0, "big"), 1);

  const composed = salesForDay({
    ...catalog,
    pricePercent: 80,
    unitBoostPercent: SEASON_UNIT_BOOST_PERCENT,
    marketing: "small",
    priceBoostPercent: 10,
    bonusFans: 2,
  });
  let units = applyLaunchPriceUnits(plain.units, 80);
  units = Math.max(1, Math.round((units * (100 + SEASON_UNIT_BOOST_PERCENT)) / 100));
  units = applyMarketingUnits(units, "small");
  const price = boostedPriceCents(launchPriceCents(900, 80), 10);
  assert.equal(composed.units, units);
  assert.equal(composed.cents, units * price);
  assert.equal(composed.fans, Math.max(1, Math.round((units * 200) / 1000)) + 2);

  const broke = await setup();
  const products = () => Number((broke.db.journey.db.prepare("SELECT COUNT(*) AS n FROM tycoon_products").get() as { n: number }).n);
  const transactions = () => Number((broke.db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions").get() as { n: number }).n);
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  const offers = broke.db.tycoon.view().marketingOptions;
  assert.deepEqual(offers.map((item) => ({ id: item.id, label: item.label, costCents: item.costCents, unitPercent: item.unitPercent })), MARKETING.map((item) => ({ ...item })));
  assert.equal(offers.find((item) => item.id === "none")?.enabled, true);
  assert.equal(offers.find((item) => item.id === "small")?.enabled, false);
  assert.equal(offers.find((item) => item.id === "small")?.reason, "Need $50");
  assert.equal(offers.find((item) => item.id === "big")?.reason, "Need $150");
  assert.throws(() => broke.db.tycoon.start("crypto", "newsletter", [], 100, "small"), /Need \$50/u);
  assert.throws(() => broke.db.tycoon.start("crypto", "newsletter", [], 100, "poster"), /Pick None, Small ad, or Big ad/u);
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(broke.db.tycoon.view().developing, null);
  assert.equal(products(), 0);
  assert.equal(transactions(), 0);
  broke.db.journey.recordCompanyChange("gift-cash", 1, 5000, 0, 0, "Gift");
  assert.equal(broke.db.tycoon.view().marketingOptions.find((item) => item.id === "small")?.enabled, true);
  assert.equal(broke.db.tycoon.view().marketingOptions.find((item) => item.id === "big")?.reason, "Need $150");
  assert.throws(() => broke.db.tycoon.start("crypto", "newsletter", [], 100, "big"), /Need \$150/u);
  assert.equal(broke.db.journey.state().company.cashCents, 5000);
  assert.equal(products(), 0);
  broke.db.tycoon.start("crypto", "newsletter", [], 100, "small");
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(broke.db.tycoon.view().developing?.marketing, "small");
  const charged = JSON.parse(String((broke.db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json)) as { marketing?: string; pricePercent?: number };
  assert.equal(charged.marketing, "small");
  assert.equal(charged.pricePercent, 100);
  assert.equal(transactions(), 2);
  broke.db.close();

  const { db } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  db.tycoon.start("crypto", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.marketing, "none");
  assert.equal(db.journey.state().company.cashCents, 0);
  const noneSnap = JSON.parse(String((db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json)) as { marketing?: string };
  assert.equal(noneSnap.marketing, "none");
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const catalogLaunch = db.tycoon.view().history[0];
  assert.equal(catalogLaunch?.marketing, "none");
  assert.equal(catalogLaunch?.salesCents, 20700);
  assert.equal(catalogLaunch?.fans, 5);
  assert.equal(db.journey.state().company.cashCents, 20700);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.close();

  const ad = await setup();
  ad.db.journey.recordCompanyChange("gift-ad", 1, 5000, 0, 0, "Gift");
  ad.db.tycoon.start("crypto", "newsletter", [], 100, "small");
  assert.equal(ad.db.journey.state().company.cashCents, 0);
  ad.db.endDay(1);
  ad.db.endDay(2);
  const before = ad.db.journey.state().company.reputation;
  ad.db.tycoon.release("p1");
  const adLaunch = ad.db.tycoon.view().history[0];
  assert.ok(adLaunch?.review);
  const expected = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: adLaunch.review.score,
    dayIndex: 0,
    reputation: before,
    marketing: "small",
  });
  assert.equal(adLaunch.marketing, "small");
  assert.equal(adLaunch.salesCents, expected.cents);
  assert.equal(adLaunch.fans, expected.fans);
  assert.ok(adLaunch.salesCents > 20700);
  ad.db.endDay(3);
  ad.db.endDay(4);
  const later = ad.db.tycoon.view().history[0];
  const dayTwo = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: adLaunch.review.score,
    dayIndex: 1,
    reputation: before + expected.fans,
    marketing: "small",
  });
  assert.equal((later?.salesCents ?? 0) - adLaunch.salesCents, dayTwo.cents);
  assert.equal(validate(ad.db.journey.state()), true, JSON.stringify(validate.errors));
  ad.db.close();

  const legacy = await setup();
  const file = join(legacy.root, "game.sqlite");
  const project = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(file);
  const staffOnly = JSON.stringify(["founder"]);
  const pricedOnly = JSON.stringify({ staff: [{ id: "founder", design: 2, tech: 2, hype: 2 }], researchBonus: 0, pricePercent: 100 });
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p2', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 0, 0, 0, 0, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(pricedOnly);
  raw.close();
  const restored = new GameDatabase(file, project);
  assert.equal(restored.tycoon.view().developing?.marketing, "none");
  restored.tycoon.release("p1");
  const oldLaunch = restored.tycoon.view().history.find((item) => item.id === "p1");
  assert.equal(oldLaunch?.marketing, "none");
  assert.equal(oldLaunch?.salesCents, 20700);
  assert.equal(oldLaunch?.fans, 5);
  const untouched = String((restored.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json);
  const pricedJson = String((restored.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p2'").get() as { staff_json: string }).staff_json);
  assert.equal(untouched, staffOnly);
  assert.equal(pricedJson, pricedOnly);
  assert.equal(restored.tycoon.view().developing?.marketing, "none");
  restored.close();
});

test("contracts lock one offer and pay the bonus once", async () => {
  const first = contractBySlot(26021, 0);
  assert.deepEqual(contractBySlot(26021, 0), first);
  assert.notEqual(contractBySlot(26021, 1).id, first.id);
  assert.equal(CONTRACTS.length, 6);
  assert.ok(CONTRACTS.every((item) => item.bonusCents > 0 && item.client.includes("TownSquare")));

  const left = await setup();
  const right = await setup();
  assert.deepEqual(left.db.tycoon.view().contract, right.db.tycoon.view().contract);
  assert.equal(left.db.tycoon.view().contract.id, first.id);
  assert.equal(left.db.tycoon.view().contract.status, "offered");
  assert.equal(left.db.tycoon.view().contract.enabled, true);
  assert.equal(left.db.tycoon.view().contract.reason, "");
  left.db.endDay(1);
  assert.equal(left.db.tycoon.view().contract.id, first.id);
  assert.equal(String((left.db.journey.db.prepare("SELECT contract_json FROM tycoon_meta WHERE id = 1").get() as { contract_json: string }).contract_json), "");
  right.db.close();

  left.db.tycoon.start("crypto", "newsletter", []);
  assert.throws(() => left.db.tycoon.acceptContract(), /Ship the product on the bench first/u);
  assert.equal(left.db.tycoon.view().contract.status, "offered");
  assert.equal(left.db.tycoon.view().contract.enabled, false);
  assert.equal(left.db.tycoon.view().contract.reason, "Ship the product on the bench first.");
  assert.equal(left.db.tycoon.view().developing?.contract, null);
  const ignored = JSON.parse(String((left.db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json)) as { contract?: unknown };
  assert.equal(ignored.contract, undefined);
  left.db.endDay(2);
  left.db.endDay(3);
  left.db.tycoon.release("p1");
  const plain = left.db.tycoon.view().history[0];
  assert.equal(plain?.contract, null);
  assert.equal(plain?.salesCents, 20700);
  assert.equal(plain?.fans, 5);
  assert.equal(left.db.journey.state().company.cashCents, 20700);
  assert.equal(left.db.journey.state().company.reputation, 5);
  const plainLabels = left.db.journey.db.prepare("SELECT label FROM company_transactions").all() as Array<{ label: string }>;
  assert.equal(plainLabels.some((row) => row.label.startsWith("Contract:")), false);
  assert.equal(left.db.tycoon.view().contract.id, first.id);
  assert.equal(left.db.tycoon.view().contract.status, "offered");
  left.db.close();

  const { db, root } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = db.tycoon.view().contract;
  assert.equal(offer.id, first.id);
  const other = offer.topicId === "crypto" ? ["fitness", "course"] as const : ["crypto", "newsletter"] as const;
  db.tycoon.acceptContract();
  assert.equal(db.tycoon.view().contract.status, "accepted");
  assert.equal(db.tycoon.view().contract.enabled, false);
  assert.equal(db.tycoon.view().contract.reason, "Accepted. The next product uses this pair.");
  assert.throws(() => db.tycoon.acceptContract(), /already accepted/u);
  assert.throws(() => db.tycoon.start(other[0], other[1], []), new RegExp(`This contract is ${offer.topicName} × ${offer.typeName}\\.`));
  assert.equal(db.tycoon.view().developing, null);
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().contract.status, "accepted");
  assert.equal(reopened.tycoon.view().contract.id, offer.id);
  reopened.tycoon.start(offer.topicId, offer.typeId, []);
  const built = reopened.tycoon.view().developing;
  assert.equal(built?.topicId, offer.topicId);
  assert.equal(built?.typeId, offer.typeId);
  assert.equal(built?.contract?.client, offer.client);
  assert.equal(built?.contract?.bonusCents, offer.bonusCents);
  assert.equal(reopened.tycoon.view().contract.status, "building");
  assert.equal(String((reopened.journey.db.prepare("SELECT contract_json FROM tycoon_meta WHERE id = 1").get() as { contract_json: string }).contract_json), "");
  const required = PRODUCT_TYPES.find((item) => item.id === offer.typeId)?.devDays ?? 2;
  let day = 1;
  for (let index = 0; index < required; index += 1) {
    reopened.endDay(day);
    day += 1;
  }
  assert.equal(reopened.tycoon.view().developing?.ready, true);
  const before = reopened.journey.state().company;
  const favored = (officeDay: number) => calendarForDay(officeDay).favoredTopics.some((topic) => topic.id === offer.topicId);
  reopened.tycoon.release("p1");
  const launch = reopened.tycoon.view().history[0];
  assert.ok(launch?.review);
  const expected = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: offer.typeId,
    fit: launch.fit,
    score: launch.review.score,
    dayIndex: 0,
    reputation: before.reputation,
    unitBoostPercent: favored(day) ? SEASON_UNIT_BOOST_PERCENT : 0,
  });
  assert.equal(launch.salesCents, expected.cents);
  assert.equal(launch.fans, expected.fans);
  assert.equal(launch.contract?.client, offer.client);
  assert.equal(launch.contract?.bonusCents, offer.bonusCents);
  assert.equal(reopened.journey.state().company.cashCents, before.cashCents + expected.cents + offer.bonusCents);
  assert.equal(reopened.journey.state().company.earnedCents, before.earnedCents + expected.cents + offer.bonusCents);
  assert.equal(reopened.journey.state().company.reputation, before.reputation + expected.fans);
  const paid = reopened.journey.db.prepare("SELECT label, cash_delta FROM company_transactions WHERE id = 'tycoon:contract:p1'").get() as { label: string; cash_delta: number };
  assert.equal(paid.label, `Contract: ${offer.client}`);
  assert.equal(paid.cash_delta, offer.bonusCents);
  assert.throws(() => reopened.tycoon.release("p1"), /already shipped/u);
  reopened.endDay(day);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, launch.salesCents);
  reopened.endDay(day + 1);
  const later = reopened.tycoon.view().history[0];
  const dayTwo = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: offer.typeId,
    fit: launch.fit,
    score: launch.review.score,
    dayIndex: 1,
    reputation: before.reputation + expected.fans,
    unitBoostPercent: favored(day + 1) ? SEASON_UNIT_BOOST_PERCENT : 0,
  });
  assert.equal((later?.salesCents ?? 0) - launch.salesCents, dayTwo.cents);
  const bonusCount = Number((reopened.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE label LIKE 'Contract:%'").get() as { n: number }).n);
  assert.equal(bonusCount, 1);
  const next = reopened.tycoon.view().contract;
  assert.equal(next.status, "offered");
  assert.equal(next.enabled, true);
  assert.equal(next.id, contractBySlot(26021, 1).id);
  assert.notEqual(next.id, offer.id);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  assert.equal(restored.tycoon.view().developing?.contract, null);
  restored.tycoon.release("p1");
  const oldLaunch = restored.tycoon.view().history[0];
  assert.equal(oldLaunch?.contract, null);
  assert.equal(oldLaunch?.salesCents, 20700);
  assert.equal(oldLaunch?.fans, 5);
  assert.equal(restored.journey.state().company.cashCents, 20700);
  const oldJson = String((restored.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json);
  assert.equal(oldJson, staffOnly);
  const oldLabels = restored.journey.db.prepare("SELECT label FROM company_transactions").all() as Array<{ label: string }>;
  assert.equal(oldLabels.some((row) => row.label.startsWith("Contract:")), false);
  restored.close();
});

test("a patch charges once and raises later sales only", async () => {
  assert.equal(PATCH_COST_CENTS, 10_000);
  assert.equal(PATCH_SCORE_BONUS, 1);
  assert.equal(patchedScore(7, false), 7);
  assert.equal(patchedScore(7, true), 8);
  assert.equal(patchedScore(10, true), 10);

  const left = await setup();
  left.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(left.db.tycoon.view().developing?.patch, null);
  assert.throws(() => left.db.tycoon.patch("p1"), /Ship this product first/u);
  assert.throws(() => left.db.tycoon.patch("p9"), /No product with that id/u);
  left.db.endDay(1);
  left.db.endDay(2);
  left.db.tycoon.release("p1");
  const plain = left.db.tycoon.view().history[0];
  assert.equal(plain?.salesCents, 20700);
  assert.equal(plain?.fans, 5);
  assert.equal(plain?.patch?.applied, false);
  assert.equal(plain?.patch?.enabled, true);
  assert.equal(plain?.patch?.reason, "");
  assert.equal(plain?.patch?.costCents, PATCH_COST_CENTS);
  assert.equal(left.db.journey.state().company.cashCents, 20700);
  const ignored = JSON.parse(String((left.db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json)) as { patched?: unknown };
  assert.equal(ignored.patched, undefined);
  left.db.close();

  const { db, root } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const launch = db.tycoon.view().history[0];
  assert.ok(launch?.review);
  const launchScore = launch.review.score;
  assert.equal(launch.salesCents, 20700);
  assert.equal(db.journey.state().company.cashCents, 20700);
  db.tycoon.patch("p1");
  const patched = db.tycoon.view().history[0];
  assert.equal(patched?.patch?.applied, true);
  assert.equal(patched?.patch?.enabled, false);
  assert.equal(patched?.patch?.reason, "Already patched.");
  assert.equal(patched?.salesCents, 20700);
  assert.equal(patched?.fans, 5);
  assert.equal(db.journey.state().company.cashCents, 10700);
  assert.equal(db.tycoon.view().patchNotice, "Patched Crypto Alpha Newsletter. −$100");
  const paid = db.journey.db.prepare("SELECT label, cash_delta FROM company_transactions WHERE id = 'tycoon:patch:p1'").get() as { label: string; cash_delta: number };
  assert.equal(paid.label, "Patch: Crypto Alpha Newsletter");
  assert.equal(paid.cash_delta, -PATCH_COST_CENTS);
  const stored = JSON.parse(String((db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json)) as { patched?: boolean };
  assert.equal(stored.patched, true);
  assert.throws(() => db.tycoon.patch("p1"), /Already patched/u);
  const patchCount = Number((db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id LIKE 'tycoon:patch:%'").get() as { n: number }).n);
  assert.equal(patchCount, 1);
  assert.equal(db.journey.state().company.cashCents, 10700);
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().history[0]?.patch?.applied, true);
  assert.equal(reopened.tycoon.view().patchNotice, "");
  reopened.endDay(3);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, 20700, "release day does not sell twice");
  const beforeDayTwo = reopened.journey.state().company.reputation;
  reopened.endDay(4);
  const later = reopened.tycoon.view().history[0];
  const dayTwo = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: patchedScore(launchScore, true),
    dayIndex: 1,
    reputation: beforeDayTwo,
  });
  const unpatchedDayTwo = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: launchScore,
    dayIndex: 1,
    reputation: beforeDayTwo,
  });
  assert.equal((later?.salesCents ?? 0) - 20700, dayTwo.cents);
  assert.equal(later?.salesCents, 20700 + dayTwo.cents);
  assert.ok(dayTwo.cents >= unpatchedDayTwo.cents);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const broke = await setup();
  broke.db.tycoon.start("crypto", "newsletter", []);
  broke.db.endDay(1);
  broke.db.endDay(2);
  broke.db.tycoon.release("p1");
  broke.db.journey.recordCompanyChange("drain", 3, -20700, 0, 0, "Drain");
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(broke.db.tycoon.view().history[0]?.patch?.enabled, false);
  assert.equal(broke.db.tycoon.view().history[0]?.patch?.reason, "Need $100");
  const brokeJson = String((broke.db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json);
  assert.throws(() => broke.db.tycoon.patch("p1"), /Need \$100/u);
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(String((broke.db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json), brokeJson);
  const brokeLabels = broke.db.journey.db.prepare("SELECT label FROM company_transactions").all() as Array<{ label: string }>;
  assert.equal(brokeLabels.some((row) => row.label.startsWith("Patch:")), false);
  broke.db.close();

  const ended = await setup();
  ended.db.tycoon.start("crypto", "newsletter", []);
  ended.db.endDay(1);
  ended.db.endDay(2);
  ended.db.tycoon.release("p1");
  ended.db.endDay(3);
  ended.db.endDay(4);
  ended.db.endDay(5);
  ended.db.endDay(6);
  assert.equal(ended.db.tycoon.view().history[0]?.status, "complete");
  assert.equal(ended.db.tycoon.view().history[0]?.salesDays, 4);
  assert.equal(ended.db.tycoon.view().history[0]?.patch?.enabled, false);
  assert.equal(ended.db.tycoon.view().history[0]?.patch?.reason, "Sales have ended.");
  const endedCash = ended.db.journey.state().company.cashCents;
  assert.throws(() => ended.db.tycoon.patch("p1"), /Sales have ended/u);
  assert.equal(ended.db.journey.state().company.cashCents, endedCash);
  ended.db.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  assert.equal(restored.tycoon.view().developing?.patch, null);
  restored.tycoon.release("p1");
  const oldLaunch = restored.tycoon.view().history[0];
  assert.equal(oldLaunch?.patch?.applied, false);
  assert.equal(oldLaunch?.salesCents, 20700);
  assert.equal(oldLaunch?.fans, 5);
  const oldJson = String((restored.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = 'p1'").get() as { staff_json: string }).staff_json);
  assert.equal(oldJson, staffOnly);
  restored.close();
});

function staffJson(db: GameDatabase, productId: string): string {
  return String((db.journey.db.prepare("SELECT staff_json FROM tycoon_products WHERE id = ?").get(productId) as { staff_json: string }).staff_json);
}

function productCount(db: GameDatabase): number {
  return Number((db.journey.db.prepare("SELECT COUNT(*) AS n FROM tycoon_products").get() as { n: number }).n);
}

function setReviewScore(db: GameDatabase, productId: string, score: number): void {
  const row = db.journey.db.prepare("SELECT review_json FROM tycoon_products WHERE id = ?").get(productId) as { review_json: string };
  const review = JSON.parse(row.review_json) as { score: number };
  review.score = score;
  db.journey.db.prepare("UPDATE tycoon_products SET review_json = ? WHERE id = ?").run(JSON.stringify(review), productId);
}

function finishNewsletter(db: GameDatabase): void {
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  db.endDay(3);
  db.endDay(4);
  db.endDay(5);
  db.endDay(6);
}

test("a sequel builds faster and carries a score", async () => {
  assert.equal(SEQUEL_DAYS_SAVED, 1);
  assert.equal(SEQUEL_SCORE_MARK, 6);
  assert.equal(SEQUEL_SCORE_BONUS, 1);
  assert.equal(sequelDevDays(2), 1);
  assert.equal(sequelDevDays(1), 1);
  assert.equal(sequelDevDays(4), 3);
  assert.equal(requiredDevDays(2, false), 2);
  assert.equal(requiredDevDays(2, true), 1);
  assert.equal(sequelScoreCarry(5), 0);
  assert.equal(sequelScoreCarry(6), 1);
  assert.equal(sequelScoreCarry(10), 1);

  const { db, root } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  db.tycoon.start("crypto", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.sequel, null);
  assert.equal(db.tycoon.view().developing?.devDaysRequired, 2);
  assert.throws(() => db.tycoon.sequel("p1"), /Ship this product first/u);
  assert.throws(() => db.tycoon.sequel("p9"), /No product with that id/u);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const plain = db.tycoon.view().history[0];
  assert.equal(plain?.salesCents, 20700);
  assert.equal(plain?.fans, 5);
  assert.equal(plain?.sequel?.isSequel, false);
  assert.equal(plain?.sequel?.started, false);
  assert.equal(plain?.sequel?.enabled, false);
  assert.equal(plain?.sequel?.reason, "Still selling.");
  assert.equal(plain?.sequel?.scoreBonus, 0);
  const ignored = JSON.parse(staffJson(db, "p1")) as { sequelOf?: unknown; sequelId?: unknown; scoreBonus?: unknown };
  assert.equal(ignored.sequelOf, undefined);
  assert.equal(ignored.sequelId, undefined);
  assert.equal(ignored.scoreBonus, undefined);
  const sellingCash = db.journey.state().company.cashCents;
  assert.throws(() => db.tycoon.sequel("p1"), /Still selling/u);
  assert.equal(productCount(db), 1);
  assert.equal(db.journey.state().company.cashCents, sellingCash);
  db.endDay(3);
  db.endDay(4);
  db.endDay(5);
  db.endDay(6);
  const finished = db.tycoon.view().history[0];
  assert.equal(finished?.status, "complete");
  assert.equal(finished?.salesDays, 4);
  assert.equal(finished?.sequel?.enabled, true);
  assert.equal(finished?.sequel?.reason, "");
  const before = db.journey.state().company.cashCents;
  db.tycoon.sequel("p1");
  const started = db.tycoon.view().developing;
  assert.equal(started?.name, "Crypto Alpha Newsletter 2");
  assert.equal(started?.topicId, "crypto");
  assert.equal(started?.typeId, "newsletter");
  assert.equal(started?.devDays, 0);
  assert.equal(started?.devDaysRequired, 1);
  assert.equal(started?.ready, false);
  assert.equal(started?.pricePercent, 100);
  assert.equal(started?.marketing, "none");
  assert.equal(started?.sequel?.isSequel, true);
  assert.equal(started?.sequel?.scoreBonus, 1);
  assert.equal(started?.sequel?.savedDays, 1);
  assert.equal(started?.sequel?.reason, "This is a sequel.");
  assert.equal(started?.sequel?.enabled, false);
  const original = db.tycoon.view().history.find((item) => item.id === "p1");
  assert.equal(original?.sequel?.started, true);
  assert.equal(original?.sequel?.reason, "Already has a sequel.");
  assert.equal(original?.salesCents, finished?.salesCents);
  assert.equal(db.journey.state().company.cashCents, before);
  const sequelStored = JSON.parse(staffJson(db, "p2")) as { sequelOf?: string; scoreBonus?: number; marketing?: string; pricePercent?: number };
  assert.equal(sequelStored.sequelOf, "p1");
  assert.equal(sequelStored.scoreBonus, 1);
  assert.equal(sequelStored.marketing, "none");
  assert.equal(sequelStored.pricePercent, 100);
  const originalStored = JSON.parse(staffJson(db, "p1")) as { sequelId?: string; sequelOf?: string };
  assert.equal(originalStored.sequelId, "p2");
  assert.equal(originalStored.sequelOf, undefined);
  assert.throws(() => db.tycoon.sequel("p1"), /Already has a sequel/u);
  assert.throws(() => db.tycoon.sequel("p2"), /This is a sequel/u);
  assert.equal(productCount(db), 2);
  assert.equal(db.journey.state().company.cashCents, before);
  assert.throws(() => db.tycoon.release("p2"), /1 more office day/u);
  db.endDay(7);
  const built = db.tycoon.view().developing;
  assert.equal(built?.devDays, 1);
  assert.equal(built?.ready, true);
  assert.equal(built?.devDaysRequired, 1);
  const carriedReview = reviewProduct({
    seed: 26021,
    productId: "p2",
    topicId: "crypto",
    typeId: "newsletter",
    design: built?.design ?? 0,
    tech: built?.tech ?? 0,
    hype: built?.hype ?? 0,
    sequelBonus: 1,
    devDays: 1,
  });
  const plainReview = reviewProduct({
    seed: 26021,
    productId: "p2",
    topicId: "crypto",
    typeId: "newsletter",
    design: built?.design ?? 0,
    tech: built?.tech ?? 0,
    hype: built?.hype ?? 0,
    devDays: 1,
  });
  db.tycoon.release("p2");
  const shipped = db.tycoon.view().history.find((item) => item.id === "p2");
  assert.equal(shipped?.review?.score, carriedReview.score);
  assert.equal(shipped?.review?.score, Math.min(10, plainReview.score + 1));
  assert.ok((shipped?.review?.score ?? 0) > plainReview.score);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().history.find((item) => item.id === "p1")?.sequel?.started, true);
  assert.equal(reopened.tycoon.view().history.find((item) => item.id === "p2")?.sequel?.isSequel, true);
  assert.equal(reopened.tycoon.view().history.find((item) => item.id === "p2")?.sequel?.scoreBonus, 1);
  reopened.close();

  const low = await setup();
  finishNewsletter(low.db);
  setReviewScore(low.db, "p1", 5);
  low.db.tycoon.sequel("p1");
  const lowSequel = JSON.parse(staffJson(low.db, "p2")) as { scoreBonus?: number };
  assert.equal(lowSequel.scoreBonus, undefined);
  assert.equal(low.db.tycoon.view().developing?.sequel?.scoreBonus, 0);
  low.db.close();

  const patched = await setup();
  patched.db.tycoon.start("crypto", "newsletter", []);
  patched.db.endDay(1);
  patched.db.endDay(2);
  patched.db.tycoon.release("p1");
  setReviewScore(patched.db, "p1", 5);
  patched.db.tycoon.patch("p1");
  patched.db.endDay(3);
  patched.db.endDay(4);
  patched.db.endDay(5);
  patched.db.endDay(6);
  patched.db.tycoon.sequel("p1");
  const patchedSequel = JSON.parse(staffJson(patched.db, "p2")) as { scoreBonus?: number };
  assert.equal(patchedSequel.scoreBonus, 1);
  assert.equal(patched.db.tycoon.view().developing?.sequel?.scoreBonus, 1);
  patched.db.close();

  const locked = await setup();
  finishNewsletter(locked.db);
  locked.db.journey.db.prepare("UPDATE tycoon_meta SET contract_json = ? WHERE id = 1").run(JSON.stringify({ id: "remy" }));
  const lockedCash = locked.db.journey.state().company.cashCents;
  assert.throws(() => locked.db.tycoon.sequel("p1"), /This contract is Fitness × Course\./u);
  assert.equal(locked.db.tycoon.view().developing, null);
  assert.equal(productCount(locked.db), 1);
  assert.equal(locked.db.journey.state().company.cashCents, lockedCash);
  assert.equal(staffJson(locked.db, "p1").includes("sequelId"), false);
  locked.db.close();

  const matched = await setup();
  finishNewsletter(matched.db);
  matched.db.journey.db.prepare("UPDATE tycoon_meta SET contract_json = ? WHERE id = 1").run(JSON.stringify({ id: "nova" }));
  const matchedCash = matched.db.journey.state().company.cashCents;
  matched.db.tycoon.sequel("p1");
  assert.equal(matched.db.tycoon.view().developing?.contract?.client, "Nova on TownSquare");
  assert.equal(matched.db.tycoon.view().contract.status, "building");
  assert.equal(String((matched.db.journey.db.prepare("SELECT contract_json FROM tycoon_meta WHERE id = 1").get() as { contract_json: string }).contract_json), "");
  assert.equal(matched.db.journey.state().company.cashCents, matchedCash);
  matched.db.close();

  const crowded = await setup();
  finishNewsletter(crowded.db);
  crowded.db.tycoon.start("fitness", "newsletter", []);
  const crowdedCash = crowded.db.journey.state().company.cashCents;
  assert.throws(() => crowded.db.tycoon.sequel("p1"), /Ship the product on the bench first/u);
  assert.equal(crowded.db.tycoon.view().developing?.name, "Fitness Newsletter");
  assert.equal(productCount(crowded.db), 2);
  assert.equal(crowded.db.journey.state().company.cashCents, crowdedCash);
  crowded.db.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  const legacySchema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validateLegacy = new Ajv2020({ strict: true, allErrors: true }).compile(legacySchema);
  assert.equal(restored.tycoon.view().developing?.sequel, null);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  const oldReview = JSON.stringify({
    score: 6,
    reviewers: ["TownSquare Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
  });
  restored.journey.db.prepare(`
    UPDATE tycoon_products
    SET status = 'complete', released_day = 3, review_json = ?, sales_applied = 4, last_sales_day = 5, sales_cents = 20700, fans = 5
    WHERE id = 'p1'
  `).run(oldReview);
  const oldRow = restored.tycoon.view().history[0];
  assert.equal(oldRow?.sequel?.isSequel, false);
  assert.equal(oldRow?.sequel?.started, false);
  assert.equal(oldRow?.sequel?.scoreBonus, 0);
  assert.equal(oldRow?.sequel?.savedDays, 1);
  assert.equal(oldRow?.sequel?.enabled, true);
  assert.equal(oldRow?.sequel?.reason, "");
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(validateLegacy(restored.journey.state()), true, JSON.stringify(validateLegacy.errors));
  restored.close();
});

test("an award charges once and adds fans from the stored review score", async () => {
  assert.equal(AWARD_SHOW, "TownSquare Creator Awards");
  assert.equal(AWARD_COST_CENTS, 4_000);
  assert.equal(AWARD_WIN_SCORE, 8);
  assert.equal(AWARD_NOMINEE_SCORE, 5);
  assert.equal(AWARD_WIN_FANS, 12);
  assert.equal(AWARD_NOMINEE_FANS, 4);
  assert.deepEqual(awardForScore(10), { outcome: "won", fans: 12 });
  assert.deepEqual(awardForScore(8), { outcome: "won", fans: 12 });
  assert.deepEqual(awardForScore(7), { outcome: "nominated", fans: 4 });
  assert.deepEqual(awardForScore(5), { outcome: "nominated", fans: 4 });
  assert.deepEqual(awardForScore(4), { outcome: "entered", fans: 0 });
  assert.deepEqual(awardForScore(1), { outcome: "entered", fans: 0 });

  const { db, root } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  db.tycoon.start("crypto", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.award, null);
  assert.throws(() => db.tycoon.award("p1"), /Ship this product first/u);
  assert.throws(() => db.tycoon.award("p9"), /No product with that id/u);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const plain = db.tycoon.view().history[0];
  assert.equal(plain?.salesCents, 20700);
  assert.equal(plain?.fans, 5);
  assert.equal(plain?.review?.score, 6);
  assert.equal(plain?.award?.entered, false);
  assert.equal(plain?.award?.enabled, false);
  assert.equal(plain?.award?.reason, "Still selling.");
  assert.equal(plain?.award?.outcome, "");
  assert.equal(plain?.award?.fans, 0);
  assert.equal(plain?.award?.show, AWARD_SHOW);
  assert.equal(plain?.award?.costCents, AWARD_COST_CENTS);
  const ignored = JSON.parse(staffJson(db, "p1")) as { award?: unknown };
  assert.equal(ignored.award, undefined);
  const sellingCash = db.journey.state().company.cashCents;
  const sellingFans = db.journey.state().company.reputation;
  assert.throws(() => db.tycoon.award("p1"), /Still selling/u);
  assert.equal(db.journey.state().company.cashCents, sellingCash);
  assert.equal(db.journey.state().company.reputation, sellingFans);
  assert.equal(staffJson(db, "p1").includes("award"), false);
  db.endDay(3);
  db.endDay(4);
  db.endDay(5);
  db.endDay(6);
  const finished = db.tycoon.view().history[0];
  assert.equal(finished?.status, "complete");
  assert.equal(finished?.award?.enabled, true);
  assert.equal(finished?.award?.reason, "");
  const beforeCash = db.journey.state().company.cashCents;
  const beforeFans = db.journey.state().company.reputation;
  const beforeSales = finished?.salesCents;
  const beforeProductFans = finished?.fans;
  db.tycoon.award("p1");
  const entered = db.tycoon.view().history[0];
  assert.equal(entered?.award?.entered, true);
  assert.equal(entered?.award?.enabled, false);
  assert.equal(entered?.award?.reason, "Already entered.");
  assert.equal(entered?.award?.outcome, "nominated");
  assert.equal(entered?.award?.fans, 4);
  assert.equal(entered?.salesCents, beforeSales);
  assert.equal(entered?.fans, beforeProductFans);
  assert.equal(db.journey.state().company.cashCents, beforeCash - AWARD_COST_CENTS);
  assert.equal(db.journey.state().company.reputation, beforeFans + 4);
  const paid = db.journey.db.prepare("SELECT label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:award:p1'").get() as {
    label: string;
    cash_delta: number;
    earned_delta: number;
    reputation_delta: number;
  };
  assert.equal(paid.label, "Award: TownSquare Creator Awards");
  assert.equal(paid.cash_delta, -AWARD_COST_CENTS);
  assert.equal(paid.earned_delta, 0);
  assert.equal(paid.reputation_delta, 4);
  const stored = JSON.parse(staffJson(db, "p1")) as { award?: { outcome: string; fans: number } };
  assert.deepEqual(stored.award, { outcome: "nominated", fans: 4 });
  assert.throws(() => db.tycoon.award("p1"), /Already entered/u);
  const awardCount = Number((db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id LIKE 'tycoon:award:%'").get() as { n: number }).n);
  assert.equal(awardCount, 1);
  assert.equal(db.journey.state().company.cashCents, beforeCash - AWARD_COST_CENTS);
  assert.equal(db.journey.state().company.reputation, beforeFans + 4);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().history[0]?.award?.outcome, "nominated");
  assert.equal(reopened.tycoon.view().history[0]?.award?.fans, 4);
  assert.equal(reopened.journey.state().company.reputation, beforeFans + 4);
  reopened.close();

  const won = await setup();
  finishNewsletter(won.db);
  setReviewScore(won.db, "p1", 8);
  const wonCash = won.db.journey.state().company.cashCents;
  const wonFans = won.db.journey.state().company.reputation;
  const wonSales = won.db.tycoon.view().history[0]?.salesCents;
  won.db.tycoon.award("p1");
  assert.equal(won.db.tycoon.view().history[0]?.award?.outcome, "won");
  assert.equal(won.db.tycoon.view().history[0]?.award?.fans, 12);
  assert.equal(won.db.journey.state().company.cashCents, wonCash - AWARD_COST_CENTS);
  assert.equal(won.db.journey.state().company.reputation, wonFans + 12);
  assert.equal(won.db.tycoon.view().history[0]?.salesCents, wonSales);
  const wonRow = won.db.journey.db.prepare("SELECT reputation_delta FROM company_transactions WHERE id = 'tycoon:award:p1'").get() as { reputation_delta: number };
  assert.equal(wonRow.reputation_delta, 12);
  won.db.close();

  const low = await setup();
  finishNewsletter(low.db);
  setReviewScore(low.db, "p1", 4);
  const lowCash = low.db.journey.state().company.cashCents;
  const lowFans = low.db.journey.state().company.reputation;
  low.db.tycoon.award("p1");
  assert.equal(low.db.tycoon.view().history[0]?.award?.outcome, "entered");
  assert.equal(low.db.tycoon.view().history[0]?.award?.fans, 0);
  assert.equal(low.db.journey.state().company.cashCents, lowCash - AWARD_COST_CENTS);
  assert.equal(low.db.journey.state().company.reputation, lowFans);
  const lowRow = low.db.journey.db.prepare("SELECT reputation_delta, label FROM company_transactions WHERE id = 'tycoon:award:p1'").get() as { reputation_delta: number; label: string };
  assert.equal(lowRow.reputation_delta, 0);
  assert.equal(lowRow.label, "Award: TownSquare Creator Awards");
  low.db.close();

  const patched = await setup();
  patched.db.tycoon.start("crypto", "newsletter", []);
  patched.db.endDay(1);
  patched.db.endDay(2);
  patched.db.tycoon.release("p1");
  setReviewScore(patched.db, "p1", 7);
  patched.db.tycoon.patch("p1");
  patched.db.endDay(3);
  patched.db.endDay(4);
  patched.db.endDay(5);
  patched.db.endDay(6);
  patched.db.tycoon.award("p1");
  assert.equal(patched.db.tycoon.view().history[0]?.award?.outcome, "nominated");
  assert.equal(patched.db.tycoon.view().history[0]?.award?.fans, 4);
  patched.db.close();

  const broke = await setup();
  finishNewsletter(broke.db);
  const brokeHave = broke.db.journey.state().company.cashCents;
  broke.db.journey.recordCompanyChange("drain-award", 7, -brokeHave, 0, 0, "Drain");
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(broke.db.tycoon.view().history[0]?.award?.enabled, false);
  assert.equal(broke.db.tycoon.view().history[0]?.award?.reason, "Need $40");
  const brokeJson = staffJson(broke.db, "p1");
  const brokeFans = broke.db.journey.state().company.reputation;
  assert.throws(() => broke.db.tycoon.award("p1"), /Need \$40/u);
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(broke.db.journey.state().company.reputation, brokeFans);
  assert.equal(staffJson(broke.db, "p1"), brokeJson);
  const brokeLabels = broke.db.journey.db.prepare("SELECT label FROM company_transactions").all() as Array<{ label: string }>;
  assert.equal(brokeLabels.some((row) => row.label.startsWith("Award:")), false);
  broke.db.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  const legacySchema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validateLegacy = new Ajv2020({ strict: true, allErrors: true }).compile(legacySchema);
  assert.equal(restored.tycoon.view().developing?.award, null);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  const oldReview = JSON.stringify({
    score: 6,
    reviewers: ["TownSquare Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
  });
  restored.journey.db.prepare(`
    UPDATE tycoon_products
    SET status = 'complete', released_day = 3, review_json = ?, sales_applied = 4, last_sales_day = 5, sales_cents = 20700, fans = 5
    WHERE id = 'p1'
  `).run(oldReview);
  const oldRow = restored.tycoon.view().history[0];
  assert.equal(oldRow?.award?.entered, false);
  assert.equal(oldRow?.award?.outcome, "");
  assert.equal(oldRow?.award?.fans, 0);
  assert.equal(oldRow?.award?.enabled, false);
  assert.equal(oldRow?.award?.reason, "Need $40");
  assert.equal(staffJson(restored, "p1"), staffOnly);
  restored.journey.recordCompanyChange("award-test-cash", 6, AWARD_COST_CENTS, 0, 0, "Award test cash");
  assert.equal(restored.tycoon.view().history[0]?.award?.enabled, true);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(validateLegacy(restored.journey.state()), true, JSON.stringify(validateLegacy.errors));
  restored.close();
});

function productById(db: GameDatabase, productId: string) {
  const view = db.tycoon.view();
  return [view.developing, ...view.history].find((item) => item?.id === productId);
}

function expectedPortSale(db: GameDatabase, productId: string, day: number, score: number) {
  const product = productById(db, productId);
  if (!product) throw new Error(`missing ${productId}`);
  const calendar = calendarForDay(day);
  return salesForDay({
    seed: 26021,
    productId,
    typeId: product.typeId,
    fit: product.fit,
    score,
    dayIndex: SALES_WINDOW_DAYS,
    reputation: db.journey.state().company.reputation,
    pricePercent: product.pricePercent,
    marketing: product.marketing,
    unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === product.topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
  });
}

test("a port charges once and pays one extra sales day from the stored score", async () => {
  assert.equal(PORT_SHELF, "TownSquare Mobile");
  assert.equal(PORT_COST_CENTS, 8_000);
  assert.equal(SALES_WINDOW_DAYS, 4);
  const curve = { seed: 26021, productId: "p1", typeId: "newsletter" as const, fit: "great" as const, score: 6, reputation: 0 };
  const opening = salesForDay({ ...curve, dayIndex: 0 });
  const lastStep = salesForDay({ ...curve, dayIndex: 3 });
  const extraStep = salesForDay({ ...curve, dayIndex: SALES_WINDOW_DAYS });
  assert.notDeepEqual(extraStep, lastStep);
  assert.notDeepEqual(extraStep, opening);
  assert.ok(extraStep.cents > 0 && extraStep.fans >= 1);
  assert.throws(() => salesForDay({ ...curve, dayIndex: SALES_WINDOW_DAYS + 1 }), /Sales day is outside the window/u);

  const { db, root } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  db.tycoon.start("crypto", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.port, null);
  assert.throws(() => db.tycoon.port("p1"), /Ship this product first/u);
  assert.throws(() => db.tycoon.port("p9"), /No product with that id/u);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const plain = db.tycoon.view().history[0];
  assert.equal(plain?.salesCents, 20700);
  assert.equal(plain?.fans, 5);
  assert.equal(plain?.review?.score, 6);
  assert.equal(plain?.port?.phase, "");
  assert.equal(plain?.port?.enabled, false);
  assert.equal(plain?.port?.reason, "Still selling.");
  assert.equal(plain?.port?.shelf, PORT_SHELF);
  assert.equal(plain?.port?.costCents, PORT_COST_CENTS);
  assert.equal(plain?.port?.cents, 0);
  assert.equal(plain?.port?.fans, 0);
  const ignored = JSON.parse(staffJson(db, "p1")) as { port?: unknown };
  assert.equal(ignored.port, undefined);
  const sellingCash = db.journey.state().company.cashCents;
  const sellingFans = db.journey.state().company.reputation;
  assert.throws(() => db.tycoon.port("p1"), /Still selling/u);
  assert.equal(db.journey.state().company.cashCents, sellingCash);
  assert.equal(db.journey.state().company.reputation, sellingFans);
  assert.equal(staffJson(db, "p1").includes("port"), false);
  db.endDay(3);
  db.endDay(4);
  db.endDay(5);
  db.endDay(6);
  const finished = productById(db, "p1");
  assert.equal(finished?.status, "complete");
  assert.equal(finished?.salesDays, 4);
  assert.equal(finished?.port?.enabled, true);
  assert.equal(finished?.port?.reason, "");
  assert.equal(finished?.port?.phase, "");
  const finishedSales = finished?.salesCents;
  const finishedProductFans = finished?.fans;
  const beforeCash = db.journey.state().company.cashCents;
  const beforeFans = db.journey.state().company.reputation;
  db.tycoon.port("p1");
  const started = productById(db, "p1");
  assert.equal(started?.port?.phase, "selling");
  assert.equal(started?.port?.enabled, false);
  assert.equal(started?.port?.reason, "Already ported.");
  assert.equal(started?.port?.cents, 0);
  assert.equal(started?.port?.fans, 0);
  assert.equal(started?.salesCents, finishedSales);
  assert.equal(started?.fans, finishedProductFans);
  assert.equal(started?.salesDays, 4);
  assert.equal(started?.status, "complete");
  assert.equal(db.journey.state().company.cashCents, beforeCash - PORT_COST_CENTS);
  assert.equal(db.journey.state().company.reputation, beforeFans);
  const fee = db.journey.db.prepare("SELECT label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:port:p1'").get() as {
    label: string;
    cash_delta: number;
    earned_delta: number;
    reputation_delta: number;
  };
  assert.equal(fee.label, "Port: TownSquare Mobile");
  assert.equal(fee.cash_delta, -PORT_COST_CENTS);
  assert.equal(fee.earned_delta, 0);
  assert.equal(fee.reputation_delta, 0);
  const stored = JSON.parse(staffJson(db, "p1")) as { port?: { shelf: string; startedDay: number; cents?: number; fans?: number } };
  assert.deepEqual(stored.port, { shelf: PORT_SHELF, startedDay: 7 });
  assert.throws(() => db.tycoon.port("p1"), /Already ported/u);
  assert.equal(Number((db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:port:p1'").get() as { n: number }).n), 1);
  assert.equal(db.journey.state().company.cashCents, beforeCash - PORT_COST_CENTS);
  const payout = expectedPortSale(db, "p1", 7, patchedScore(started?.review?.score ?? 0, started?.patch?.applied ?? false));
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.endDay(7);
  const sold = productById(db, "p1");
  assert.equal(sold?.status, "complete");
  assert.equal(sold?.salesDays, 4);
  assert.equal(sold?.port?.phase, "sold");
  assert.equal(sold?.port?.enabled, false);
  assert.equal(sold?.port?.reason, "Already ported.");
  assert.equal(sold?.port?.cents, payout.cents);
  assert.equal(sold?.port?.fans, payout.fans);
  assert.equal(sold?.salesCents, (finishedSales ?? 0) + payout.cents);
  assert.equal(sold?.fans, (finishedProductFans ?? 0) + payout.fans);
  assert.equal(db.journey.state().company.cashCents, beforeCash - PORT_COST_CENTS + payout.cents);
  assert.equal(db.journey.state().company.reputation, beforeFans + payout.fans);
  const sale = db.journey.db.prepare("SELECT label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:p1:4'").get() as {
    label: string;
    cash_delta: number;
    earned_delta: number;
    reputation_delta: number;
  };
  assert.equal(sale.label, "Sales · Crypto Alpha Newsletter");
  assert.equal(sale.cash_delta, payout.cents);
  assert.equal(sale.earned_delta, payout.cents);
  assert.equal(sale.reputation_delta, payout.fans);
  const applied = db.journey.db.prepare("SELECT status, sales_applied FROM tycoon_products WHERE id = 'p1'").get() as { status: string; sales_applied: number };
  assert.equal(applied.status, "complete");
  assert.equal(applied.sales_applied, 4);
  const paidPort = JSON.parse(staffJson(db, "p1")) as { port?: { shelf: string; startedDay: number; cents: number; fans: number } };
  assert.deepEqual(paidPort.port, { shelf: PORT_SHELF, startedDay: 7, cents: payout.cents, fans: payout.fans });
  db.endDay(8);
  assert.equal(productById(db, "p1")?.port?.cents, payout.cents);
  assert.equal(productById(db, "p1")?.salesCents, (finishedSales ?? 0) + payout.cents);
  assert.equal(productById(db, "p1")?.fans, (finishedProductFans ?? 0) + payout.fans);
  assert.equal(db.journey.state().company.cashCents, beforeCash - PORT_COST_CENTS + payout.cents);
  assert.equal(db.journey.state().company.reputation, beforeFans + payout.fans);
  assert.equal(Number((db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:p1:4'").get() as { n: number }).n), 1);
  assert.throws(() => db.tycoon.port("p1"), /Already ported/u);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().history.find((item) => item.id === "p1")?.port?.phase, "sold");
  assert.equal(reopened.tycoon.view().history.find((item) => item.id === "p1")?.port?.cents, payout.cents);
  assert.equal(reopened.journey.state().company.reputation, beforeFans + payout.fans);
  reopened.close();

  const patched = await setup();
  patched.db.tycoon.start("crypto", "newsletter", []);
  patched.db.endDay(1);
  patched.db.endDay(2);
  patched.db.tycoon.release("p1");
  setReviewScore(patched.db, "p1", 5);
  patched.db.tycoon.patch("p1");
  patched.db.endDay(3);
  patched.db.endDay(4);
  patched.db.endDay(5);
  patched.db.endDay(6);
  const patchedSales = productById(patched.db, "p1")?.salesCents;
  const patchedFans = productById(patched.db, "p1")?.fans;
  patched.db.tycoon.port("p1");
  const lifted = expectedPortSale(patched.db, "p1", 7, patchedScore(5, true));
  const unlifted = expectedPortSale(patched.db, "p1", 7, 5);
  assert.equal(patchedScore(5, true), 6);
  assert.notEqual(lifted.cents, unlifted.cents);
  patched.db.endDay(7);
  const patchedSold = productById(patched.db, "p1");
  assert.equal(patchedSold?.port?.cents, lifted.cents);
  assert.equal(patchedSold?.port?.fans, lifted.fans);
  assert.equal(patchedSold?.salesCents, (patchedSales ?? 0) + lifted.cents);
  assert.equal(patchedSold?.fans, (patchedFans ?? 0) + lifted.fans);
  assert.equal(patchedSold?.salesDays, 4);
  patched.db.close();

  const broke = await setup();
  finishNewsletter(broke.db);
  const brokeHave = broke.db.journey.state().company.cashCents;
  broke.db.journey.recordCompanyChange("drain-port", 7, -brokeHave, 0, 0, "Drain");
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(productById(broke.db, "p1")?.port?.enabled, false);
  assert.equal(productById(broke.db, "p1")?.port?.reason, "Need $80");
  const brokeJson = staffJson(broke.db, "p1");
  const brokeFans = broke.db.journey.state().company.reputation;
  const brokeSales = productById(broke.db, "p1")?.salesCents;
  assert.throws(() => broke.db.tycoon.port("p1"), /Need \$80/u);
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(broke.db.journey.state().company.reputation, brokeFans);
  assert.equal(productById(broke.db, "p1")?.salesCents, brokeSales);
  assert.equal(staffJson(broke.db, "p1"), brokeJson);
  const brokeLabels = broke.db.journey.db.prepare("SELECT label FROM company_transactions").all() as Array<{ label: string }>;
  assert.equal(brokeLabels.some((row) => row.label.startsWith("Port:")), false);
  broke.db.close();

  const pair = await setup();
  finishNewsletter(pair.db);
  pair.db.tycoon.start("crypto", "newsletter", []);
  pair.db.endDay(7);
  pair.db.endDay(8);
  pair.db.tycoon.release("p2");
  pair.db.endDay(9);
  pair.db.endDay(10);
  pair.db.endDay(11);
  pair.db.endDay(12);
  assert.equal(productById(pair.db, "p1")?.status, "complete");
  assert.equal(productById(pair.db, "p2")?.status, "complete");
  assert.equal(productById(pair.db, "p2")?.salesDays, 4);
  pair.db.tycoon.port("p1");
  assert.equal(productById(pair.db, "p1")?.port?.phase, "selling");
  assert.equal(productById(pair.db, "p2")?.port?.enabled, false);
  assert.equal(productById(pair.db, "p2")?.port?.reason, "Another port is still selling.");
  const pairJson = staffJson(pair.db, "p2");
  const pairCash = pair.db.journey.state().company.cashCents;
  assert.throws(() => pair.db.tycoon.port("p2"), /Another port is still selling/u);
  assert.equal(pair.db.journey.state().company.cashCents, pairCash);
  assert.equal(staffJson(pair.db, "p2"), pairJson);
  pair.db.endDay(13);
  assert.equal(productById(pair.db, "p1")?.port?.phase, "sold");
  assert.equal(productById(pair.db, "p2")?.port?.enabled, true);
  assert.equal(productById(pair.db, "p2")?.port?.reason, "");
  pair.db.tycoon.port("p2");
  assert.equal(productById(pair.db, "p2")?.port?.phase, "selling");
  assert.equal(productById(pair.db, "p1")?.port?.phase, "sold");
  pair.db.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  const legacySchema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validateLegacy = new Ajv2020({ strict: true, allErrors: true }).compile(legacySchema);
  assert.equal(restored.tycoon.view().developing?.port, null);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  const oldReview = JSON.stringify({
    score: 6,
    reviewers: ["TownSquare Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
  });
  restored.journey.db.prepare(`
    UPDATE tycoon_products
    SET status = 'complete', released_day = 3, review_json = ?, sales_applied = 4, last_sales_day = 5, sales_cents = 20700, fans = 5
    WHERE id = 'p1'
  `).run(oldReview);
  const oldRow = restored.tycoon.view().history[0];
  assert.equal(oldRow?.port?.phase, "");
  assert.equal(oldRow?.port?.cents, 0);
  assert.equal(oldRow?.port?.fans, 0);
  assert.equal(oldRow?.port?.enabled, false);
  assert.equal(oldRow?.port?.reason, "Need $80");
  assert.equal(oldRow?.salesCents, 20700);
  assert.equal(oldRow?.fans, 5);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  restored.journey.recordCompanyChange("port-test-cash", 6, PORT_COST_CENTS, 0, 0, "Port test cash");
  assert.equal(restored.tycoon.view().history[0]?.port?.enabled, true);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(validateLegacy(restored.journey.state()), true, JSON.stringify(validateLegacy.errors));
  restored.close();
});

test("an engine is bought once and a product started on it stores a score bump", async () => {
  assert.equal(ENGINE_ID, "whop_kit");
  assert.equal(ENGINE_NAME, "TownSquare Kit Engine");
  assert.equal(ENGINE_COST_CENTS, 12_000);
  assert.equal(ENGINE_SCORE_BONUS, 1);
  const points = { design: 4, tech: 4, hype: 4 };
  const firstPlain = reviewProduct({ seed: 26021, productId: "p1", topicId: "crypto", typeId: "newsletter", ...points });
  const firstLifted = reviewProduct({ seed: 26021, productId: "p1", topicId: "crypto", typeId: "newsletter", ...points, engineBonus: ENGINE_SCORE_BONUS });
  assert.equal(firstPlain.score, 6);
  assert.equal(firstLifted.score, 7);
  const capped = reviewProduct({
    seed: 26021, productId: "p1", topicId: "crypto", typeId: "newsletter",
    design: 80, tech: 80, hype: 80, sequelBonus: SEQUEL_SCORE_BONUS, engineBonus: ENGINE_SCORE_BONUS,
  });
  assert.equal(capped.score, 10);
  const secondPlain = reviewProduct({ seed: 26021, productId: "p2", topicId: "crypto", typeId: "newsletter", ...points });
  const secondLifted = reviewProduct({ seed: 26021, productId: "p2", topicId: "crypto", typeId: "newsletter", ...points, engineBonus: ENGINE_SCORE_BONUS });
  assert.ok(secondLifted.score <= 10);
  assert.equal(secondLifted.score, Math.min(10, secondPlain.score + 1));

  const broke = await setup();
  const brokeView = broke.db.tycoon.view();
  assert.equal(brokeView.engine.owned, false);
  assert.equal(brokeView.engine.enabled, false);
  assert.equal(brokeView.engine.reason, "Need $120");
  assert.equal(brokeView.engine.priceCents, ENGINE_COST_CENTS);
  assert.equal(brokeView.engineOptions.length, 2);
  assert.equal(brokeView.engineOptions[0]?.id, "none");
  assert.equal(brokeView.engineOptions[0]?.enabled, true);
  assert.equal(brokeView.engineOptions[1]?.id, ENGINE_ID);
  assert.equal(brokeView.engineOptions[1]?.enabled, false);
  assert.equal(brokeView.engineOptions[1]?.reason, "Buy it first.");
  assert.throws(() => broke.db.tycoon.buyEngine("lava_lamp"), /Unknown engine\./u);
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.throws(() => broke.db.tycoon.buyEngine(ENGINE_ID), /Need \$120/u);
  assert.throws(() => broke.db.tycoon.start("crypto", "newsletter", [], 100, "none", ENGINE_ID), /Buy the engine first\./u);
  assert.equal(broke.db.tycoon.view().developing, null);
  assert.throws(() => broke.db.tycoon.start("crypto", "newsletter", [], 100, "none", "rocket"), /Pick None or TownSquare Kit Engine\./u);
  broke.db.journey.recordCompanyChange("engine-short", 1, 11_900, 0, 0, "Engine short cash");
  assert.equal(broke.db.tycoon.view().engine.reason, "Need $120");
  assert.equal(broke.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:engine'").get(), undefined);
  const shortCash = broke.db.journey.state().company.cashCents;
  assert.throws(() => broke.db.tycoon.start("crypto", "newsletter", [], 100, "small", ENGINE_ID), /Buy the engine first\./u);
  assert.equal(broke.db.journey.state().company.cashCents, shortCash);
  assert.equal(broke.db.tycoon.view().developing, null);
  const adRows = broke.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:marketing:%'").all();
  assert.equal(adRows.length, 0);
  broke.db.close();

  const { db, root } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  db.tycoon.start("crypto", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.engine, null);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const first = productById(db, "p1");
  assert.equal(first?.salesCents, 20700);
  assert.equal(first?.fans, 5);
  assert.equal(first?.review?.score, 6);
  assert.equal(first?.engine, null);
  const firstJson = staffJson(db, "p1");
  const firstBody = JSON.parse(firstJson) as Record<string, unknown>;
  assert.equal("engine" in firstBody, false);
  assert.equal("engineBonus" in firstBody, false);
  const cashBefore = db.journey.state().company.cashCents;
  db.tycoon.buyEngine(ENGINE_ID);
  const fee = db.journey.db.prepare("SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:engine'").get() as {
    id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number;
  };
  assert.equal(fee.id, "tycoon:engine");
  assert.equal(fee.label, "Engine: TownSquare Kit Engine");
  assert.equal(fee.cash_delta, -ENGINE_COST_CENTS);
  assert.equal(fee.earned_delta, 0);
  assert.equal(fee.reputation_delta, 0);
  assert.equal(db.journey.state().company.cashCents, cashBefore - ENGINE_COST_CENTS);
  const owned = db.tycoon.view();
  assert.equal(owned.engine.owned, true);
  assert.equal(owned.engine.enabled, false);
  assert.equal(owned.engine.reason, "Already owned.");
  assert.equal(owned.engineNotice, "Bought TownSquare Kit Engine. −$120");
  assert.equal(owned.engineOptions[1]?.enabled, true);
  assert.equal(owned.engineOptions[1]?.reason, "");
  const cashOwned = db.journey.state().company.cashCents;
  assert.throws(() => db.tycoon.buyEngine(ENGINE_ID), /Already owned\./u);
  assert.equal(Number((db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:engine'").get() as { n: number }).n), 1);
  assert.equal(db.journey.state().company.cashCents, cashOwned);
  assert.equal(staffJson(db, "p1"), firstJson);

  db.tycoon.start("crypto", "newsletter", [], 100, "none", ENGINE_ID);
  const building = productById(db, "p2");
  assert.deepEqual(building?.engine, { id: ENGINE_ID, name: ENGINE_NAME, scoreBonus: ENGINE_SCORE_BONUS });
  const secondBody = JSON.parse(staffJson(db, "p2")) as { engine: string; engineBonus: number; marketing: string; pricePercent: number };
  assert.equal(secondBody.engine, ENGINE_ID);
  assert.equal(secondBody.engineBonus, ENGINE_SCORE_BONUS);
  assert.equal(secondBody.marketing, "none");
  assert.equal(secondBody.pricePercent, 100);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.endDay(db.clockState().day);
  assert.equal(db.tycoon.view().engineNotice, "");
  assert.equal(db.tycoon.view().engine.owned, true);
  db.endDay(db.clockState().day);
  const releaseDay = db.clockState().day;
  const reputation = db.journey.state().company.reputation;
  const calendar = calendarForDay(releaseDay);
  const favored = calendar.favoredTopics.some((topic) => topic.id === "crypto");
  const saleInput = {
    seed: 26021,
    productId: "p2" as const,
    typeId: "newsletter" as const,
    fit: "great" as const,
    dayIndex: 0,
    reputation,
    pricePercent: 100,
    marketing: "none",
    unitBoostPercent: favored ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
  };
  const liftedSale = salesForDay({ ...saleInput, score: secondLifted.score });
  const plainSale = salesForDay({ ...saleInput, score: secondPlain.score });
  db.tycoon.release("p2");
  const second = productById(db, "p2");
  assert.deepEqual(second?.review, secondLifted);
  assert.equal(second?.salesCents, liftedSale.cents);
  assert.equal(second?.fans, liftedSale.fans);
  assert.ok(liftedSale.cents > plainSale.cents);
  assert.equal(productById(db, "p1")?.engine, null);
  assert.equal(staffJson(db, "p1"), firstJson);

  db.tycoon.start("fitness", "course", []);
  assert.equal(productById(db, "p3")?.engine, null);
  const thirdBody = JSON.parse(staffJson(db, "p3")) as Record<string, unknown>;
  assert.equal("engine" in thirdBody, false);
  assert.equal("engineBonus" in thirdBody, false);
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().engine.owned, true);
  assert.equal(productById(reopened, "p3")?.engine, null);
  assert.equal(productById(reopened, "p2")?.engine?.scoreBonus, ENGINE_SCORE_BONUS);
  assert.equal(staffJson(reopened, "p1"), firstJson);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  assert.equal(restored.tycoon.view().developing?.engine, null);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  const oldReview = JSON.stringify({
    score: 6,
    reviewers: ["TownSquare Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
  });
  restored.journey.db.prepare(`
    UPDATE tycoon_products
    SET status = 'complete', released_day = 3, review_json = ?, sales_applied = 4, last_sales_day = 5, sales_cents = 20700, fans = 5
    WHERE id = 'p1'
  `).run(oldReview);
  assert.equal(restored.tycoon.view().history[0]?.engine, null);
  assert.equal(restored.tycoon.view().history[0]?.salesCents, 20700);
  assert.equal(restored.tycoon.view().history[0]?.fans, 5);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  restored.journey.recordCompanyChange("engine-test-cash", 6, ENGINE_COST_CENTS, 0, 0, "Engine test cash");
  restored.tycoon.buyEngine(ENGINE_ID);
  assert.equal(restored.tycoon.view().engine.owned, true);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(validate(restored.journey.state()), true, JSON.stringify(validate.errors));
  restored.close();
});

test("a focus stores a point bump and Balanced leaves the first newsletter alone", async () => {
  assert.equal(FOCUS_BONUS, 1);
  assert.deepEqual(FOCUSES.map((item) => item.id), ["balanced", "design", "tech", "hype"]);
  const plainPoints = { design: 4, tech: 4, hype: 4 };
  assert.deepEqual(applyFocusPoints(plainPoints, "balanced"), plainPoints);
  assert.deepEqual(applyFocusPoints(plainPoints, undefined), plainPoints);
  assert.deepEqual(applyFocusPoints(plainPoints, "design"), { design: 5, tech: 4, hype: 4 });
  assert.deepEqual(applyFocusPoints(plainPoints, "tech"), { design: 4, tech: 5, hype: 4 });
  assert.deepEqual(applyFocusPoints(plainPoints, "hype"), { design: 4, tech: 4, hype: 5 });
  assert.deepEqual(applyFocusPoints({ design: 10, tech: 3, hype: 12 }, "design"), { design: 10, tech: 3, hype: 12 });
  assert.deepEqual(applyFocusPoints({ design: 9, tech: 0, hype: 0 }, "design"), { design: 10, tech: 0, hype: 0 });
  assert.deepEqual(applyFocusPoints({ design: 11, tech: 0, hype: 0 }, "design"), { design: 11, tech: 0, hype: 0 });
  const plainReview = reviewProduct({ seed: 26021, productId: "p1", topicId: "crypto", typeId: "newsletter", ...plainPoints });
  const hypeReview = reviewProduct({ seed: 26021, productId: "p1", topicId: "crypto", typeId: "newsletter", ...applyFocusPoints(plainPoints, "hype") });
  assert.equal(plainReview.score, 6);
  assert.ok(hypeReview.score <= 10);
  assert.notEqual(hypeReview.score, plainReview.score);

  const balanced = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const options = balanced.db.tycoon.view().focusOptions;
  assert.equal(options.length, 4);
  assert.equal(options[0]?.id, "balanced");
  assert.equal(options[0]?.bonus, 0);
  assert.equal(options[1]?.stat, "design");
  assert.equal(options[1]?.bonus, 1);
  assert.throws(() => balanced.db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "poster"), /Pick Balanced, Design, Tech, or Hype\./u);
  assert.equal(balanced.db.tycoon.view().developing, null);
  balanced.db.journey.recordCompanyChange("focus-ad-cash", 1, 20_000, 0, 0, "Focus ad cash");
  const cashBeforeBad = balanced.db.journey.state().company.cashCents;
  assert.throws(() => balanced.db.tycoon.start("crypto", "newsletter", [], 100, "small", "none", "poster"), /Pick Balanced, Design, Tech, or Hype\./u);
  assert.equal(balanced.db.journey.state().company.cashCents, cashBeforeBad);
  assert.equal(balanced.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:marketing:%'").all().length, 0);
  assert.equal(balanced.db.tycoon.view().developing, null);
  balanced.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(balanced.db.tycoon.view().developing?.focus, null);
  assert.equal(balanced.db.tycoon.view().developing?.design, 0);
  assert.equal(validate(balanced.db.journey.state()), true, JSON.stringify(validate.errors));
  balanced.db.endDay(1);
  balanced.db.endDay(2);
  const ready = balanced.db.tycoon.view().developing;
  assert.equal(ready?.design, 4);
  assert.equal(ready?.tech, 4);
  assert.equal(ready?.hype, 4);
  balanced.db.tycoon.release("p1");
  const shipped = productById(balanced.db, "p1");
  assert.equal(shipped?.salesCents, 20700);
  assert.equal(shipped?.fans, 5);
  assert.equal(shipped?.review?.score, 6);
  assert.equal(shipped?.focus, null);
  const balancedBody = JSON.parse(staffJson(balanced.db, "p1")) as Record<string, unknown>;
  assert.equal("focus" in balancedBody, false);
  assert.equal("focusBonus" in balancedBody, false);
  assert.equal(balanced.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:focus:%'").all().length, 0);
  balanced.db.close();

  const { db, root } = await setup();
  db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "hype");
  const started = db.tycoon.view().developing;
  assert.deepEqual(started?.focus, { id: "hype", label: "Hype", stat: "hype", bonus: 1 });
  assert.equal(started?.hype, 1);
  assert.equal(started?.design, 0);
  assert.equal(db.journey.state().company.cashCents, 0);
  const stored = JSON.parse(staffJson(db, "p1")) as { focus?: string; focusBonus?: number; marketing?: string; pricePercent?: number };
  assert.equal(stored.focus, "hype");
  assert.equal(stored.focusBonus, 1);
  assert.equal(stored.marketing, "none");
  assert.equal(stored.pricePercent, 100);
  db.endDay(1);
  db.endDay(2);
  const built = db.tycoon.view().developing;
  assert.equal(built?.design, 4);
  assert.equal(built?.tech, 4);
  assert.equal(built?.hype, 5);
  const releaseDay = db.clockState().day;
  db.tycoon.release("p1");
  const hypeProduct = productById(db, "p1");
  assert.deepEqual(hypeProduct?.review, hypeReview);
  assert.equal(hypeProduct?.focus?.bonus, 1);
  const calendar = calendarForDay(releaseDay);
  const sale = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: hypeReview.score,
    dayIndex: 0,
    reputation: 0,
    pricePercent: 100,
    marketing: "none",
    unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === "crypto") ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
  });
  assert.equal(hypeProduct?.salesCents, sale.cents);
  assert.equal(hypeProduct?.fans, sale.fans);
  assert.notEqual(sale.cents, 20700);
  db.tycoon.patch("p1");
  assert.equal(JSON.parse(staffJson(db, "p1")).focus, "hype");
  assert.equal(JSON.parse(staffJson(db, "p1")).focusBonus, 1);
  db.endDay(db.clockState().day);
  db.endDay(db.clockState().day);
  db.endDay(db.clockState().day);
  db.endDay(db.clockState().day);
  assert.equal(productById(db, "p1")?.status, "complete");
  db.tycoon.sequel("p1");
  const sequelBody = JSON.parse(staffJson(db, "p2")) as Record<string, unknown>;
  assert.equal("focus" in sequelBody, false);
  assert.equal("focusBonus" in sequelBody, false);
  assert.equal(productById(db, "p2")?.focus, null);
  assert.equal(JSON.parse(staffJson(db, "p1")).focus, "hype");
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(productById(reopened, "p1")?.focus?.id, "hype");
  assert.equal(productById(reopened, "p2")?.focus, null);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  const cappedJson = JSON.stringify({ staff: [{ id: "founder", design: 2, tech: 2, hype: 2 }], researchBonus: 0, pricePercent: 100, marketing: "none", focus: "design", focusBonus: 1 });
  const oddJson = JSON.stringify({ staff: [{ id: "founder", design: 2, tech: 2, hype: 2 }], researchBonus: 0, pricePercent: 100, marketing: "none", focus: "design", focusBonus: 9 });
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES
      ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0),
      ('p2', 'crypto', 'newsletter', 'Capped', 'great', 'complete', 1, 2, 10, 4, 4, ?, 2, 3, NULL, 4, 6, 0, 0),
      ('p3', 'crypto', 'newsletter', 'Odd bonus', 'great', 'complete', 1, 2, 4, 4, 4, ?, 2, 3, NULL, 4, 6, 0, 0)
  `).run(staffOnly, cappedJson, oddJson);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  const legacyView = restored.tycoon.view();
  const legacyRows = [legacyView.developing, ...legacyView.history];
  const legacyById = (id: string) => legacyRows.find((item) => item?.id === id);
  assert.equal(legacyById("p1")?.focus, null);
  assert.equal(legacyById("p1")?.design, 4);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(legacyById("p2")?.design, 10);
  assert.equal(legacyById("p2")?.focus?.id, "design");
  assert.equal(legacyById("p3")?.design, 5);
  assert.equal(JSON.parse(staffJson(restored, "p3")).focusBonus, 9);
  assert.equal(staffJson(restored, "p2"), cappedJson);
  assert.equal(validate(restored.journey.state()), true, JSON.stringify(validate.errors));
  restored.close();
});

test("an audience stores a fan rule and Everyone leaves the first newsletter alone", async () => {
  assert.equal(AUDIENCE_FANS, 2);
  assert.equal(AUDIENCE_NEWCOMER_UNIT_PERCENT, 90);
  assert.deepEqual(AUDIENCES.map((item) => item.id), ["everyone", "regulars", "newcomers"]);
  assert.equal(applyAudienceUnits(23, "everyone"), 23);
  assert.equal(applyAudienceUnits(23, "regulars"), 23);
  assert.equal(applyAudienceUnits(23, undefined), 23);
  assert.equal(applyAudienceUnits(23, "newcomers"), 21);
  assert.equal(audienceFansForSale("everyone", true), 0);
  assert.equal(audienceFansForSale("regulars", false), 0);
  assert.equal(audienceFansForSale("regulars", true), 2);
  assert.equal(audienceFansForSale("newcomers", false), 2);

  const everyone = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const options = everyone.db.tycoon.view().audienceOptions;
  assert.equal(options.length, 3);
  assert.equal(options[0]?.id, "everyone");
  assert.equal(options[0]?.fans, 0);
  assert.equal(options[1]?.id, "regulars");
  assert.equal(options[1]?.fans, 2);
  assert.equal(options[2]?.id, "newcomers");
  assert.equal(options[2]?.unitPercent, 90);
  assert.throws(() => everyone.db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "balanced", "crowd"), /Pick Everyone, Regulars, or Newcomers\./u);
  assert.equal(everyone.db.tycoon.view().developing, null);
  everyone.db.journey.recordCompanyChange("audience-ad-cash", 1, 20_000, 0, 0, "Audience ad cash");
  const cashBeforeBad = everyone.db.journey.state().company.cashCents;
  assert.throws(() => everyone.db.tycoon.start("crypto", "newsletter", [], 100, "small", "none", "balanced", "crowd"), /Pick Everyone, Regulars, or Newcomers\./u);
  assert.equal(everyone.db.journey.state().company.cashCents, cashBeforeBad);
  assert.equal(everyone.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:marketing:%'").all().length, 0);
  assert.equal(everyone.db.tycoon.view().developing, null);
  everyone.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(everyone.db.tycoon.view().developing?.audience, null);
  assert.equal(validate(everyone.db.journey.state()), true, JSON.stringify(validate.errors));
  everyone.db.endDay(1);
  everyone.db.endDay(2);
  everyone.db.tycoon.release("p1");
  const shipped = productById(everyone.db, "p1");
  assert.equal(shipped?.salesCents, 20700);
  assert.equal(shipped?.fans, 5);
  assert.equal(shipped?.audience, null);
  const everyoneBody = JSON.parse(staffJson(everyone.db, "p1")) as Record<string, unknown>;
  assert.equal("audience" in everyoneBody, false);
  assert.equal(everyone.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:audience:%'").all().length, 0);
  everyone.db.close();

  const firstRegulars = await setup();
  firstRegulars.db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "balanced", "regulars");
  const firstStarted = firstRegulars.db.tycoon.view().developing;
  assert.deepEqual(firstStarted?.audience, { id: "regulars", label: "Regulars", fans: 2, unitPercent: 100 });
  assert.equal(JSON.parse(staffJson(firstRegulars.db, "p1")).audience, "regulars");
  firstRegulars.db.endDay(1);
  firstRegulars.db.endDay(2);
  firstRegulars.db.tycoon.release("p1");
  const firstRegularsShip = productById(firstRegulars.db, "p1");
  assert.equal(firstRegularsShip?.salesCents, 20700);
  assert.equal(firstRegularsShip?.fans, 5);
  assert.equal(firstRegularsShip?.audience?.id, "regulars");
  firstRegulars.db.close();

  const newcomers = await setup();
  newcomers.db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "balanced", "newcomers");
  const newStarted = newcomers.db.tycoon.view().developing;
  assert.deepEqual(newStarted?.audience, { id: "newcomers", label: "Newcomers", fans: 2, unitPercent: 90 });
  assert.equal(newcomers.db.journey.state().company.cashCents, 0);
  newcomers.db.endDay(1);
  newcomers.db.endDay(2);
  const newReleaseDay = newcomers.db.clockState().day;
  newcomers.db.tycoon.release("p1");
  const newProduct = productById(newcomers.db, "p1");
  const newCalendar = calendarForDay(newReleaseDay);
  const newSale = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: newProduct?.review?.score ?? 0,
    dayIndex: 0,
    reputation: 0,
    pricePercent: 100,
    marketing: "none",
    audience: "newcomers",
    unitBoostPercent: newCalendar.favoredTopics.some((topic) => topic.id === "crypto") ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: newCalendar.event ? EVENT_BONUS_FANS : 0,
  });
  const plainSale = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: newProduct?.review?.score ?? 0,
    dayIndex: 0,
    reputation: 0,
    pricePercent: 100,
    marketing: "none",
    unitBoostPercent: newCalendar.favoredTopics.some((topic) => topic.id === "crypto") ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: newCalendar.event ? EVENT_BONUS_FANS : 0,
  });
  assert.equal(newProduct?.salesCents, newSale.cents);
  assert.equal(newProduct?.fans, newSale.fans);
  assert.ok(newSale.cents < plainSale.cents);
  assert.equal(newSale.units, applyAudienceUnits(plainSale.units, "newcomers"));
  assert.equal(newSale.fans, Math.max(1, Math.round((newSale.units * 200) / 1000)) + (newCalendar.event ? EVENT_BONUS_FANS : 0) + AUDIENCE_FANS);
  assert.notEqual(newSale.cents, 20700);
  newcomers.db.close();

  const { db, root } = await setup();
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "balanced", "regulars");
  db.endDay(db.clockState().day);
  db.endDay(db.clockState().day);
  const matchReleaseDay = db.clockState().day;
  const matchReputation = db.journey.state().company.reputation;
  db.tycoon.release("p2");
  const matched = productById(db, "p2");
  const matchCalendar = calendarForDay(matchReleaseDay);
  const matchSale = salesForDay({
    seed: 26021,
    productId: "p2",
    typeId: "newsletter",
    fit: "great",
    score: matched?.review?.score ?? 0,
    dayIndex: 0,
    reputation: matchReputation,
    pricePercent: 100,
    marketing: "none",
    audience: "regulars",
    topicMatch: true,
    unitBoostPercent: matchCalendar.favoredTopics.some((topic) => topic.id === "crypto") ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: matchCalendar.event ? EVENT_BONUS_FANS : 0,
  });
  const unmatchedSale = salesForDay({
    seed: 26021,
    productId: "p2",
    typeId: "newsletter",
    fit: "great",
    score: matched?.review?.score ?? 0,
    dayIndex: 0,
    reputation: matchReputation,
    pricePercent: 100,
    marketing: "none",
    audience: "regulars",
    topicMatch: false,
    unitBoostPercent: matchCalendar.favoredTopics.some((topic) => topic.id === "crypto") ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: matchCalendar.event ? EVENT_BONUS_FANS : 0,
  });
  assert.equal(matched?.salesCents, matchSale.cents);
  assert.equal(matched?.fans, matchSale.fans);
  assert.equal(matchSale.cents, unmatchedSale.cents);
  assert.equal(matchSale.fans, unmatchedSale.fans + 2);
  db.tycoon.patch("p2");
  assert.equal(JSON.parse(staffJson(db, "p2")).audience, "regulars");
  db.endDay(db.clockState().day);
  db.endDay(db.clockState().day);
  db.endDay(db.clockState().day);
  db.endDay(db.clockState().day);
  assert.equal(productById(db, "p2")?.status, "complete");
  db.tycoon.sequel("p2");
  const sequelBody = JSON.parse(staffJson(db, "p3")) as Record<string, unknown>;
  assert.equal("audience" in sequelBody, false);
  assert.equal(productById(db, "p3")?.audience, null);
  assert.equal(JSON.parse(staffJson(db, "p2")).audience, "regulars");
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(productById(reopened, "p2")?.audience?.id, "regulars");
  assert.equal(productById(reopened, "p3")?.audience, null);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const otherTopic = await setup();
  otherTopic.db.tycoon.start("crypto", "newsletter", []);
  otherTopic.db.endDay(1);
  otherTopic.db.endDay(2);
  otherTopic.db.tycoon.release("p1");
  otherTopic.db.tycoon.start("trading", "newsletter", [], 100, "none", "none", "balanced", "regulars");
  otherTopic.db.endDay(otherTopic.db.clockState().day);
  otherTopic.db.endDay(otherTopic.db.clockState().day);
  const otherDay = otherTopic.db.clockState().day;
  const otherRep = otherTopic.db.journey.state().company.reputation;
  otherTopic.db.tycoon.release("p2");
  const other = productById(otherTopic.db, "p2");
  const otherCalendar = calendarForDay(otherDay);
  const otherSale = salesForDay({
    seed: 26021,
    productId: "p2",
    typeId: "newsletter",
    fit: "great",
    score: other?.review?.score ?? 0,
    dayIndex: 0,
    reputation: otherRep,
    pricePercent: 100,
    marketing: "none",
    audience: "regulars",
    topicMatch: false,
    unitBoostPercent: otherCalendar.favoredTopics.some((topic) => topic.id === "trading") ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: otherCalendar.event ? EVENT_BONUS_FANS : 0,
  });
  assert.equal(other?.salesCents, otherSale.cents);
  assert.equal(other?.fans, otherSale.fans);
  otherTopic.db.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 2, 4, 4, 4, ?, NULL, NULL, NULL, 0, NULL, 0, 0)
  `).run(staffOnly);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  assert.equal(restored.tycoon.view().developing?.audience, null);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  const oldReview = JSON.stringify({
    score: 6,
    reviewers: ["TownSquare Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
  });
  restored.journey.db.prepare(`
    UPDATE tycoon_products
    SET status = 'complete', released_day = 3, review_json = ?, sales_applied = 4, last_sales_day = 5, sales_cents = 20700, fans = 5
    WHERE id = 'p1'
  `).run(oldReview);
  assert.equal(restored.tycoon.view().history[0]?.audience, null);
  assert.equal(restored.tycoon.view().history[0]?.salesCents, 20700);
  assert.equal(restored.tycoon.view().history[0]?.fans, 5);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(validate(restored.journey.state()), true, JSON.stringify(validate.errors));
  restored.close();
});

test("a size stores a length and Catalog leaves the first newsletter alone", async () => {
  assert.equal(SIZE_SHORT_UNIT_PERCENT, 90);
  assert.equal(SIZE_LONG_UNIT_PERCENT, 110);
  assert.deepEqual(SIZES.map((item) => item.id), ["catalog", "short", "long"]);
  assert.equal(sizedDevDays(2, "catalog"), 2);
  assert.equal(sizedDevDays(2, undefined), 2);
  assert.equal(sizedDevDays(2, "short"), 1);
  assert.equal(sizedDevDays(1, "short"), 1);
  assert.equal(sizedDevDays(4, "short"), 3);
  assert.equal(sizedDevDays(2, "long"), 3);
  assert.equal(sizedDevDays(4, "long"), 5);
  assert.equal(requiredDevDays(2, false), 2);
  assert.equal(requiredDevDays(2, false, "long"), 3);
  assert.equal(requiredDevDays(2, true, "long"), 1);
  assert.equal(requiredDevDays(2, true, "short"), 1);
  assert.equal(applySizeUnits(23, "catalog"), 23);
  assert.equal(applySizeUnits(23, undefined), 23);
  assert.equal(applySizeUnits(23, "short"), 21);
  assert.equal(applySizeUnits(23, "long"), 25);
  const plainPort = salesForDay({
    seed: 26021, productId: "p1", typeId: "newsletter", fit: "great", score: 6, dayIndex: SALES_WINDOW_DAYS, reputation: 0,
  });
  const shortPort = salesForDay({
    seed: 26021, productId: "p1", typeId: "newsletter", fit: "great", score: 6, dayIndex: SALES_WINDOW_DAYS, reputation: 0, size: "short",
  });
  assert.equal(shortPort.units, applySizeUnits(plainPort.units, "short"));
  assert.ok(shortPort.cents < plainPort.cents);

  const catalog = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const options = catalog.db.tycoon.view().sizeOptions;
  assert.equal(options.length, 3);
  assert.equal(options[0]?.id, "catalog");
  assert.equal(options[0]?.dayDelta, 0);
  assert.equal(options[0]?.unitPercent, 100);
  assert.equal(options[1]?.id, "short");
  assert.equal(options[1]?.unitPercent, 90);
  assert.equal(options[2]?.id, "long");
  assert.equal(options[2]?.dayDelta, 1);
  assert.equal(options[2]?.unitPercent, 110);
  assert.throws(() => catalog.db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "balanced", "everyone", "huge"), /Pick Catalog, Short, or Long\./u);
  assert.equal(catalog.db.tycoon.view().developing, null);
  catalog.db.journey.recordCompanyChange("size-ad-cash", 1, 20_000, 0, 0, "Size ad cash");
  const cashBeforeBad = catalog.db.journey.state().company.cashCents;
  assert.throws(() => catalog.db.tycoon.start("crypto", "newsletter", [], 100, "small", "none", "balanced", "everyone", "huge"), /Pick Catalog, Short, or Long\./u);
  assert.equal(catalog.db.journey.state().company.cashCents, cashBeforeBad);
  assert.equal(catalog.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:marketing:%'").all().length, 0);
  assert.equal(catalog.db.tycoon.view().developing, null);
  catalog.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(catalog.db.tycoon.view().developing?.size, null);
  assert.equal(catalog.db.tycoon.view().developing?.devDaysRequired, 2);
  assert.equal(validate(catalog.db.journey.state()), true, JSON.stringify(validate.errors));
  catalog.db.endDay(1);
  catalog.db.endDay(2);
  catalog.db.tycoon.release("p1");
  const shipped = productById(catalog.db, "p1");
  assert.equal(shipped?.salesCents, 20700);
  assert.equal(shipped?.fans, 5);
  assert.equal(shipped?.review?.score, 6);
  assert.equal(shipped?.size, null);
  const catalogBody = JSON.parse(staffJson(catalog.db, "p1")) as Record<string, unknown>;
  assert.equal("size" in catalogBody, false);
  assert.equal(catalog.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:size:%'").all().length, 0);
  catalog.db.close();

  const short = await setup();
  short.db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "balanced", "everyone", "short");
  const shortStarted = short.db.tycoon.view().developing;
  assert.deepEqual(shortStarted?.size, { id: "short", label: "Short", dayDelta: -1, unitPercent: 90 });
  assert.equal(shortStarted?.devDaysRequired, 1);
  assert.equal(JSON.parse(staffJson(short.db, "p1")).size, "short");
  assert.equal(short.db.journey.state().company.cashCents, 0);
  assert.throws(() => short.db.tycoon.release("p1"), /1 more office day/u);
  short.db.endDay(1);
  assert.equal(short.db.tycoon.view().developing?.devDays, 1);
  assert.equal(short.db.tycoon.view().developing?.design, 2);
  assert.equal(short.db.tycoon.view().developing?.ready, true);
  short.db.tycoon.release("p1");
  const shortShip = productById(short.db, "p1");
  assert.equal(shortShip?.review?.score, 6);
  assert.equal(shortShip?.salesCents, 18900);
  assert.equal(shortShip?.fans, 4);
  assert.equal(shortShip?.size?.id, "short");
  short.db.close();

  const long = await setup();
  long.db.tycoon.start("crypto", "newsletter", [], 100, "none", "none", "balanced", "everyone", "long");
  assert.deepEqual(long.db.tycoon.view().developing?.size, { id: "long", label: "Long", dayDelta: 1, unitPercent: 110 });
  assert.equal(long.db.tycoon.view().developing?.devDaysRequired, 3);
  assert.equal(validate(long.db.journey.state()), true, JSON.stringify(validate.errors));
  assert.throws(() => long.db.tycoon.release("p1"), /3 more office days/u);
  long.db.endDay(1);
  long.db.endDay(2);
  assert.equal(long.db.tycoon.view().developing?.devDays, 2);
  assert.equal(long.db.tycoon.view().developing?.ready, false);
  assert.throws(() => long.db.tycoon.release("p1"), /1 more office day/u);
  long.db.endDay(3);
  assert.equal(long.db.tycoon.view().developing?.design, 6);
  assert.equal(long.db.tycoon.view().developing?.ready, true);
  long.db.tycoon.release("p1");
  const longShip = productById(long.db, "p1");
  assert.equal(longShip?.review?.score, 6);
  assert.equal(longShip?.salesCents, 22500);
  assert.equal(longShip?.fans, 5);
  long.db.endDay(4);
  long.db.endDay(5);
  long.db.endDay(6);
  long.db.endDay(7);
  assert.equal(productById(long.db, "p1")?.status, "complete");
  long.db.tycoon.sequel("p1");
  const sequelBody = JSON.parse(staffJson(long.db, "p2")) as Record<string, unknown>;
  assert.equal("size" in sequelBody, false);
  assert.equal(productById(long.db, "p2")?.size, null);
  assert.equal(productById(long.db, "p2")?.devDaysRequired, 1);
  assert.equal(JSON.parse(staffJson(long.db, "p1")).size, "long");
  const file = join(long.root, "game.sqlite");
  const project = join(long.root, "company-project");
  long.db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(productById(reopened, "p1")?.size?.id, "long");
  assert.equal(productById(reopened, "p2")?.size, null);
  assert.equal(productById(reopened, "p2")?.devDaysRequired, 1);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  const objectWithoutSize = JSON.stringify({ staff: [{ id: "founder", design: 2, tech: 2, hype: 2 }], researchBonus: 0, pricePercent: 100, marketing: "none" });
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES
      ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'developing', 1, 0, 0, 0, 0, ?, NULL, NULL, NULL, 0, NULL, 0, 0),
      ('p2', 'crypto', 'newsletter', 'Older object', 'great', 'released', 1, 2, 4, 4, 4, ?, 2, 3, NULL, 0, NULL, 20700, 5)
  `).run(staffOnly, objectWithoutSize);
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  assert.equal(restored.tycoon.view().developing?.size, null);
  assert.equal(restored.tycoon.view().developing?.devDaysRequired, 2);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(restored.tycoon.view().history[0]?.size, null);
  assert.equal(restored.tycoon.view().history[0]?.devDaysRequired, 2);
  assert.equal(restored.tycoon.view().history[0]?.salesCents, 20700);
  assert.equal(staffJson(restored, "p2"), objectWithoutSize);
  const oldReview = JSON.stringify({
    score: 6,
    reviewers: ["TownSquare Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
  });
  restored.journey.db.prepare("DELETE FROM tycoon_products WHERE id = 'p2'").run();
  restored.journey.db.prepare(`
    UPDATE tycoon_products
    SET status = 'complete', released_day = 3, review_json = ?, sales_applied = 4, last_sales_day = 5, sales_cents = 20700, fans = 5
    WHERE id = 'p1'
  `).run(oldReview);
  assert.equal(restored.tycoon.view().history[0]?.size, null);
  assert.equal(restored.tycoon.view().history[0]?.salesCents, 20700);
  assert.equal(restored.tycoon.view().history[0]?.fans, 5);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(validate(restored.journey.state()), true, JSON.stringify(validate.errors));
  restored.close();
});

test("payroll pays hired staff once per season and can go negative", async () => {
  assert.equal(payrollCents([]), 0);
  assert.equal(payrollCents(["founder"]), 0);
  assert.equal(payrollCents(["nope"]), 0);
  assert.equal(payrollCents(["mira", "mira", "founder"]), SALARY_CENTS.mira);
  assert.equal(SALARY_CENTS.mira, 8_000);
  assert.equal(payrollCents(["theo"]), 10_000);
  assert.equal(payrollCents(["creative"]), 12_000);
  assert.equal(payrollCents(["creative", "mira", "theo", "founder"]), 30_000);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const empty = await setup();
  empty.db.setClock(28, 480, 0);
  assert.equal(empty.db.tycoon.view().payroll.cents, 0);
  assert.equal(empty.db.tycoon.view().payroll.payday, "Spring 28");
  assert.equal(empty.db.tycoon.view().payroll.notice, "");
  empty.db.endDay(28);
  assert.equal(empty.db.journey.state().company.cashCents, 0);
  assert.equal(empty.db.clockState().day, 29);
  assert.equal(empty.db.tycoon.view().payroll.payday, "Summer 28");
  assert.equal(empty.db.tycoon.view().payroll.cents, 0);
  assert.equal(empty.db.tycoon.view().payroll.notice, "");
  assert.equal(empty.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:payroll:%'").all().length, 0);
  assert.equal(validate(empty.db.journey.state()), true, JSON.stringify(validate.errors));
  empty.db.close();

  const mina = await setup();
  mina.db.journey.hire("mira", 1);
  mina.db.setClock(27, 480, 0);
  mina.db.endDay(27);
  assert.equal(mina.db.clockState().day, 28);
  assert.equal(mina.db.journey.state().company.cashCents, 0);
  assert.equal(mina.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:payroll:%'").all().length, 0);
  mina.db.tycoon.tickDay(28);
  mina.db.tycoon.tickDay(28);
  assert.equal(mina.db.clockState().day, 28);
  assert.equal(mina.db.journey.state().company.cashCents, -8_000);
  assert.equal(mina.db.tycoon.view().payroll.notice, "");
  const spring = mina.db.journey.db.prepare(
    "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:payroll:%'",
  ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
  assert.equal(spring.length, 1);
  assert.equal(spring[0]?.id, "tycoon:payroll:1-spring");
  assert.equal(spring[0]?.label, "Payroll: Spring");
  assert.equal(spring[0]?.cash_delta, -8_000);
  assert.equal(spring[0]?.earned_delta, 0);
  assert.equal(spring[0]?.reputation_delta, 0);
  mina.db.endDay(28);
  mina.db.endDay(28);
  assert.equal(mina.db.clockState().day, 29);
  assert.equal(mina.db.journey.state().company.cashCents, -8_000);
  assert.equal(mina.db.tycoon.view().payroll.notice, "Paid payroll · −$80");
  assert.equal(mina.db.tycoon.view().payroll.payday, "Summer 28");
  assert.equal(mina.db.tycoon.view().payroll.cents, 8_000);
  assert.equal(validate(mina.db.journey.state()), true, JSON.stringify(validate.errors));
  assert.throws(() => mina.db.tycoon.buyUpgrade("standing_desk"), /Not enough game cash/u);
  assert.throws(() => mina.db.tycoon.train("founder", "tech"), /Not enough game cash/u);
  assert.throws(() => mina.db.tycoon.buyEngine("whop_kit"), /Need \$120/u);
  const small = mina.db.tycoon.view().marketingOptions.find((item) => item.id === "small");
  assert.equal(small?.enabled, false);
  assert.equal(small?.reason, "Need $50");
  assert.throws(() => mina.db.journey.recordCompanyChange("payroll-overdraft", 29, -1, 0, 0, "Too much"), /Not enough company cash/u);
  assert.equal(mina.db.journey.state().company.cashCents, -8_000);
  mina.db.journey.recordCompanyChange("payroll-test-sale", 29, 1_000, 1_000, 0, "A small sale");
  assert.equal(mina.db.journey.state().company.cashCents, -7_000);
  mina.db.tycoon.start("crypto", "newsletter", []);
  mina.db.endDay(29);
  assert.equal(mina.db.tycoon.view().developing?.devDays, 1);
  assert.equal(mina.db.tycoon.view().payroll.notice, "");
  assert.equal(mina.db.journey.state().company.cashCents, -7_000);
  assert.notEqual(mina.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:build:p1:29'").get(), undefined);
  const minaFile = join(mina.root, "game.sqlite");
  const minaProject = join(mina.root, "company-project");
  mina.db.close();
  const reopened = new GameDatabase(minaFile, minaProject);
  assert.equal(reopened.journey.state().company.cashCents, -7_000);
  assert.equal(reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:payroll:%'").all().length, 1);
  assert.equal(reopened.tycoon.view().payroll.notice, "");
  reopened.tycoon.tickDay(30);
  assert.equal(reopened.journey.state().company.cashCents, -7_000);
  reopened.setClock(56, 480, 0);
  reopened.endDay(56);
  reopened.endDay(56);
  assert.equal(reopened.journey.state().company.cashCents, -15_000);
  const summer = reopened.journey.db.prepare("SELECT label FROM company_transactions WHERE id = 'tycoon:payroll:1-summer'").get() as { label: string } | undefined;
  assert.equal(summer?.label, "Payroll: Summer");
  assert.equal(reopened.tycoon.view().payroll.notice, "Paid payroll · −$80");
  reopened.setClock(140, 480, 0);
  reopened.endDay(140);
  assert.equal(reopened.journey.state().company.cashCents, -23_000);
  const yearTwo = reopened.journey.db.prepare("SELECT label FROM company_transactions WHERE id = 'tycoon:payroll:2-spring'").get() as { label: string } | undefined;
  assert.equal(yearTwo?.label, "Payroll: Spring");
  assert.equal(reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:payroll:%'").all().length, 3);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const team = await setup();
  team.db.journey.hire("mira", 1);
  team.db.journey.db.prepare("UPDATE employees SET employment_status = 'hired' WHERE id IN ('theo', 'creative')").run();
  team.db.setClock(28, 480, 0);
  assert.equal(team.db.tycoon.view().payroll.cents, 30_000);
  assert.equal(team.db.tycoon.view().payroll.payday, "Spring 28");
  team.db.endDay(28);
  assert.equal(team.db.journey.state().company.cashCents, -30_000);
  assert.equal(team.db.tycoon.view().payroll.notice, "Paid payroll · −$300");
  const teamRow = team.db.journey.db.prepare("SELECT label, cash_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'").get() as { label: string; cash_delta: number };
  assert.equal(teamRow.label, "Payroll: Spring");
  assert.equal(teamRow.cash_delta, -30_000);
  assert.equal(validate(team.db.journey.state()), true, JSON.stringify(validate.errors));
  team.db.close();
});

test("one optional loan pays once, repays once on payday, and skipping it changes nothing", async () => {
  assert.equal(LOAN_LENDER, "TownSquare Treasury");
  assert.equal(LOAN_AMOUNT_CENTS, 50_000);
  assert.equal(LOAN_FEE_CENTS, 5_000);
  assert.equal(LOAN_REPAY_CENTS, 55_000);
  assert.equal(loanDueDay(1), 28);
  assert.equal(loanDueDay(27), 28);
  assert.equal(loanDueDay(28), 56);
  assert.equal(loanDueDay(29), 56);
  assert.equal(loanDueDay(56), 84);
  assert.equal(paydayLabel(28), "Spring 28");
  assert.equal(paydayLabel(56), "Summer 28");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const skip = await setup();
  assert.equal(skip.db.tycoon.view().loan.outstanding, false);
  assert.equal(skip.db.tycoon.view().loan.amountCents, 50_000);
  assert.equal(skip.db.tycoon.view().loan.repayCents, 55_000);
  assert.equal(skip.db.tycoon.view().loan.due, "Spring 28");
  assert.equal(skip.db.tycoon.view().loan.lender, "TownSquare Treasury");
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  skip.db.endDay(3);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700, "release day does not sell twice");
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(skip.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:loan:%'").all().length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const taken = await setup();
  taken.db.tycoon.takeLoan();
  assert.equal(taken.db.journey.state().company.cashCents, 50_000);
  assert.equal(taken.db.tycoon.view().loan.outstanding, true);
  assert.equal(taken.db.tycoon.view().loan.due, "Spring 28");
  const takeRow = taken.db.journey.db.prepare(
    "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:loan:%'",
  ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
  assert.equal(takeRow.length, 1);
  assert.equal(takeRow[0]?.id, "tycoon:loan:1:taken");
  assert.equal(takeRow[0]?.label, "Loan: TownSquare Treasury");
  assert.equal(takeRow[0]?.cash_delta, 50_000);
  assert.equal(takeRow[0]?.earned_delta, 0);
  assert.equal(takeRow[0]?.reputation_delta, 0);
  assert.throws(() => taken.db.tycoon.takeLoan(), /A loan is already out\./u);
  assert.equal(taken.db.journey.state().company.cashCents, 50_000);
  taken.db.tycoon.tickDay(1);
  taken.db.tycoon.tickDay(1);
  assert.equal(taken.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:loan:%'").all().length, 1);
  taken.db.setClock(27, 480, 0);
  taken.db.endDay(27);
  assert.equal(taken.db.journey.state().company.cashCents, 50_000);
  assert.equal(taken.db.tycoon.view().loan.outstanding, true);
  taken.db.tycoon.tickDay(28);
  taken.db.tycoon.tickDay(28);
  assert.equal(taken.db.journey.state().company.cashCents, -5_000);
  const repaid = taken.db.journey.db.prepare(
    "SELECT id, label, cash_delta FROM company_transactions WHERE id LIKE 'tycoon:loan:%:repaid'",
  ).all() as Array<{ id: string; label: string; cash_delta: number }>;
  assert.equal(repaid.length, 1);
  assert.equal(repaid[0]?.id, "tycoon:loan:1:repaid");
  assert.equal(repaid[0]?.label, "Loan repaid");
  assert.equal(repaid[0]?.cash_delta, -55_000);
  taken.db.endDay(28);
  taken.db.endDay(28);
  assert.equal(taken.db.clockState().day, 29);
  assert.equal(taken.db.journey.state().company.cashCents, -5_000);
  assert.equal(taken.db.tycoon.view().loan.outstanding, false);
  assert.equal(taken.db.tycoon.view().loan.due, "Summer 28");
  assert.equal(validate(taken.db.journey.state()), true, JSON.stringify(validate.errors));
  const takenFile = join(taken.root, "game.sqlite");
  const takenProject = join(taken.root, "company-project");
  taken.db.close();
  const reopened = new GameDatabase(takenFile, takenProject);
  assert.equal(reopened.journey.state().company.cashCents, -5_000);
  assert.equal(reopened.tycoon.view().loan.outstanding, false);
  reopened.tycoon.tickDay(29);
  assert.equal(reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:loan:%'").all().length, 2);
  reopened.tycoon.takeLoan();
  assert.equal(reopened.journey.state().company.cashCents, 45_000);
  const second = reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:loan:2:taken'").get() as { id: string } | undefined;
  assert.equal(second?.id, "tycoon:loan:2:taken");
  assert.equal(reopened.tycoon.view().loan.outstanding, true);
  assert.equal(reopened.tycoon.view().loan.due, "Summer 28");
  assert.throws(() => reopened.tycoon.takeLoan(), /A loan is already out\./u);
  reopened.setClock(56, 480, 0);
  reopened.endDay(56);
  reopened.endDay(56);
  assert.equal(reopened.journey.state().company.cashCents, -10_000);
  assert.equal(reopened.tycoon.view().loan.outstanding, false);
  const secondRepaid = reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:loan:2:repaid'").get() as { id: string } | undefined;
  assert.equal(secondRepaid?.id, "tycoon:loan:2:repaid");
  assert.equal(reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:loan:%'").all().length, 4);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const paydayTake = await setup();
  paydayTake.db.setClock(28, 480, 0);
  paydayTake.db.tycoon.takeLoan();
  assert.equal(paydayTake.db.tycoon.view().loan.due, "Summer 28");
  paydayTake.db.endDay(28);
  assert.equal(paydayTake.db.journey.state().company.cashCents, 50_000);
  assert.equal(paydayTake.db.tycoon.view().loan.outstanding, true);
  assert.equal(paydayTake.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:loan:%:repaid'").all().length, 0);
  paydayTake.db.close();

  const withMina = await setup();
  withMina.db.journey.hire("mira", 1);
  withMina.db.tycoon.takeLoan();
  withMina.db.setClock(28, 480, 0);
  withMina.db.endDay(28);
  assert.equal(withMina.db.journey.state().company.cashCents, -13_000);
  assert.equal(withMina.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'").get() !== undefined, true);
  assert.equal(withMina.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:loan:1:repaid'").get() !== undefined, true);
  assert.equal(withMina.db.tycoon.view().loan.outstanding, false);
  assert.equal(validate(withMina.db.journey.state()), true, JSON.stringify(validate.errors));
  withMina.db.close();
});

test("one optional publisher pays an advance once and cuts only that product", async () => {
  assert.equal(PUBLISHER_NAME, "Creator Collective");
  assert.equal(PUBLISHER_ADVANCE_CENTS, 15_000);
  assert.equal(PUBLISHER_CUT_PERCENT, 30);
  assert.equal(publisherCutCents(20_700), 6_210);
  assert.equal(publisherNetCents(20_700), 14_490);
  assert.equal(publisherCutCents(1), 0);
  assert.equal(publisherCutCents(2), 1);
  assert.equal(publisherCutCents(5), 2);
  assert.equal(publisherCutCents(0), 0);
  assert.equal(publisherCutCents(-4), 0);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = {
    name: "Creator Collective",
    advanceCents: 15_000,
    cutPercent: 30,
    signed: false,
  };
  const signedOffer = { ...offer, signed: true };

  function publisherRows(db: GameDatabase) {
    return db.journey.db.prepare(
      "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:publisher:%' ORDER BY id",
    ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
  }

  function saleRow(db: GameDatabase, id: string) {
    return db.journey.db.prepare(
      "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id = ?",
    ).get(id) as { id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number } | undefined;
  }

  function saleOnDay(productId: string, day: number, dayIndex: number, score: number, reputation: number, topicMatch: boolean) {
    const calendar = calendarForDay(day);
    return salesForDay({
      seed: 26021,
      productId,
      typeId: "newsletter",
      fit: "great",
      score,
      dayIndex,
      reputation,
      pricePercent: 100,
      marketing: "none",
      audience: "everyone",
      topicMatch,
      size: "catalog",
      unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === "crypto") ? SEASON_UNIT_BOOST_PERCENT : 0,
      bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
    });
  }

  const skip = await setup();
  assert.equal(skip.db.tycoon.view().developing, null);
  assert.throws(() => skip.db.tycoon.signPublisher(), /No product is on the bench\./u);
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.publisher, offer);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).publisher, undefined);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  const unsignedLaunch = saleOnDay("p1", 3, 0, 6, 0, false);
  assert.equal(unsignedLaunch.cents, 20_700);
  assert.equal(unsignedLaunch.fans, 5);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.publisher, null);
  const unsignedSale = saleRow(skip.db, "tycoon:p1:0");
  assert.equal(unsignedSale?.cash_delta, 20_700);
  assert.equal(unsignedSale?.earned_delta, 20_700);
  assert.equal(unsignedSale?.reputation_delta, 5);
  skip.db.endDay(3);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700, "release day does not sell twice");
  const secondReputation = skip.db.journey.state().company.reputation;
  skip.db.endDay(4);
  const unsignedSecond = saleOnDay("p1", 4, 1, 6, secondReputation, false);
  assert.equal(unsignedSecond.cents, 33_300 - 20_700);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 33_300);
  assert.equal(saleRow(skip.db, "tycoon:p1:1")?.cash_delta, unsignedSecond.cents);
  assert.equal(saleRow(skip.db, "tycoon:p1:1")?.reputation_delta, unsignedSecond.fans);
  assert.equal(publisherRows(skip.db).length, 0);
  assert.throws(() => skip.db.tycoon.signPublisher(), /No product is on the bench\./u);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const signed = await setup();
  signed.db.tycoon.start("crypto", "newsletter", []);
  signed.db.tycoon.signPublisher();
  assert.equal(signed.db.journey.state().company.cashCents, 15_000);
  assert.deepEqual(signed.db.tycoon.view().developing?.publisher, signedOffer);
  assert.equal(JSON.parse(staffJson(signed.db, "p1")).publisher, true);
  const advance = publisherRows(signed.db);
  assert.equal(advance.length, 1);
  assert.equal(advance[0]?.id, "tycoon:publisher:p1:advance");
  assert.equal(advance[0]?.label, "Publisher: Creator Collective");
  assert.equal(advance[0]?.cash_delta, 15_000);
  assert.equal(advance[0]?.earned_delta, 0);
  assert.equal(advance[0]?.reputation_delta, 0);
  assert.throws(() => signed.db.tycoon.signPublisher(), /Already signed\./u);
  assert.equal(signed.db.journey.state().company.cashCents, 15_000);
  signed.db.tycoon.tickDay(1);
  signed.db.tycoon.tickDay(1);
  assert.equal(publisherRows(signed.db).length, 1);
  assert.equal(signed.db.tycoon.view().developing?.devDays, 1);
  signed.db.endDay(1);
  signed.db.endDay(2);
  const releaseDay = signed.db.clockState().day;
  signed.db.tycoon.release("p1");
  const grossLaunch = saleOnDay("p1", releaseDay, 0, 6, 0, false);
  assert.equal(grossLaunch.cents, 20_700);
  assert.equal(grossLaunch.fans, 5);
  const netLaunch = publisherNetCents(grossLaunch.cents);
  assert.equal(signed.db.tycoon.view().history[0]?.salesCents, netLaunch);
  assert.equal(signed.db.tycoon.view().history[0]?.fans, 5);
  assert.deepEqual(signed.db.tycoon.view().history[0]?.publisher, signedOffer);
  assert.equal(signed.db.journey.state().company.cashCents, 15_000 + netLaunch);
  assert.equal(signed.db.journey.state().company.reputation, 5);
  const cutSale = saleRow(signed.db, "tycoon:p1:0");
  assert.equal(cutSale?.label, "Sales · Crypto Alpha Newsletter");
  assert.equal(cutSale?.cash_delta, netLaunch);
  assert.equal(cutSale?.earned_delta, netLaunch);
  assert.equal(cutSale?.reputation_delta, 5);
  const launchCash = signed.db.journey.state().company.cashCents;
  signed.db.tycoon.tickDay(releaseDay);
  signed.db.tycoon.tickDay(releaseDay);
  assert.equal(signed.db.journey.state().company.cashCents, launchCash);
  assert.equal(publisherRows(signed.db).length, 1);
  assert.equal(saleRow(signed.db, "tycoon:p1:0")?.cash_delta, netLaunch);
  signed.db.endDay(releaseDay);
  signed.db.endDay(releaseDay);
  assert.equal(signed.db.clockState().day, releaseDay + 1);
  assert.equal(signed.db.journey.state().company.cashCents, launchCash);
  assert.equal(validate(signed.db.journey.state()), true, JSON.stringify(validate.errors));
  const signedFile = join(signed.root, "game.sqlite");
  const signedProject = join(signed.root, "company-project");
  signed.db.close();
  const reopened = new GameDatabase(signedFile, signedProject);
  reopened.tycoon.tickDay(releaseDay);
  assert.equal(reopened.journey.state().company.cashCents, launchCash);
  assert.equal(publisherRows(reopened).length, 1);
  assert.equal(saleRow(reopened, "tycoon:p1:0")?.cash_delta, netLaunch);
  const secondDay = reopened.clockState().day;
  const fansBeforeSecond = reopened.journey.state().company.reputation;
  reopened.endDay(secondDay);
  reopened.endDay(secondDay);
  const grossSecond = saleOnDay("p1", secondDay, 1, 6, fansBeforeSecond, false);
  const netSecond = publisherNetCents(grossSecond.cents);
  assert.equal(grossSecond.cents, unsignedSecond.cents);
  assert.equal(saleRow(reopened, "tycoon:p1:1")?.cash_delta, netSecond);
  assert.equal(saleRow(reopened, "tycoon:p1:1")?.earned_delta, netSecond);
  assert.equal(saleRow(reopened, "tycoon:p1:1")?.reputation_delta, grossSecond.fans);
  assert.equal(productById(reopened, "p1")?.salesCents, netLaunch + netSecond);
  assert.equal(reopened.journey.state().company.cashCents, launchCash + netSecond);
  reopened.tycoon.tickDay(secondDay);
  assert.equal(reopened.journey.state().company.cashCents, launchCash + netSecond);
  assert.equal(publisherRows(reopened).length, 1);
  reopened.endDay(secondDay + 1);
  reopened.endDay(secondDay + 2);
  assert.equal(productById(reopened, "p1")?.status, "complete");
  assert.throws(() => reopened.tycoon.signPublisher(), /No product is on the bench\./u);
  const portDay = reopened.clockState().day;
  const portScore = productById(reopened, "p1")?.review?.score ?? 0;
  const portGross = expectedPortSale(reopened, "p1", portDay, portScore);
  assert.ok(publisherCutCents(portGross.cents) > 0);
  const portNet = publisherNetCents(portGross.cents);
  const salesBeforePort = productById(reopened, "p1")?.salesCents ?? 0;
  const fansBeforePort = productById(reopened, "p1")?.fans ?? 0;
  const cashBeforePort = reopened.journey.state().company.cashCents;
  reopened.tycoon.port("p1");
  reopened.endDay(portDay);
  assert.equal(saleRow(reopened, "tycoon:p1:4")?.cash_delta, portNet);
  assert.equal(saleRow(reopened, "tycoon:p1:4")?.reputation_delta, portGross.fans);
  assert.equal(productById(reopened, "p1")?.port?.cents, portNet);
  assert.equal(productById(reopened, "p1")?.port?.fans, portGross.fans);
  assert.equal(productById(reopened, "p1")?.salesCents, salesBeforePort + portNet);
  assert.equal(productById(reopened, "p1")?.fans, fansBeforePort + portGross.fans);
  assert.equal(reopened.journey.state().company.cashCents, cashBeforePort - PORT_COST_CENTS + portNet);
  reopened.endDay(portDay + 1);
  assert.equal(productById(reopened, "p1")?.salesCents, salesBeforePort + portNet);
  assert.equal(publisherRows(reopened).length, 1);
  const keptLaunch = saleRow(reopened, "tycoon:p1:0")?.cash_delta;
  reopened.tycoon.sequel("p1");
  const sequel = reopened.tycoon.view().developing;
  assert.equal(sequel?.id, "p2");
  assert.equal(sequel?.devDaysRequired, 1);
  assert.deepEqual(sequel?.publisher, offer);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).publisher, undefined);
  assert.equal(productById(reopened, "p1")?.publisher?.signed, true);
  const sequelStart = reopened.clockState().day;
  reopened.endDay(sequelStart);
  assert.equal(reopened.tycoon.view().developing?.ready, true);
  const fansBeforeSequel = reopened.journey.state().company.reputation;
  const sequelDay = reopened.clockState().day;
  reopened.tycoon.release("p2");
  const sequelProduct = productById(reopened, "p2");
  const sequelGross = saleOnDay("p2", sequelDay, 0, sequelProduct?.review?.score ?? 0, fansBeforeSequel, true);
  assert.ok(publisherCutCents(sequelGross.cents) > 0);
  assert.equal(sequelProduct?.publisher, null);
  assert.equal(sequelProduct?.salesCents, sequelGross.cents);
  assert.equal(sequelProduct?.fans, sequelGross.fans);
  assert.equal(saleRow(reopened, "tycoon:p2:0")?.cash_delta, sequelGross.cents);
  assert.equal(saleRow(reopened, "tycoon:p2:0")?.reputation_delta, sequelGross.fans);
  assert.equal(publisherRows(reopened).some((row) => row.id === "tycoon:publisher:p2:advance"), false);
  assert.equal(saleRow(reopened, "tycoon:p1:0")?.cash_delta, keptLaunch);
  assert.equal(productById(reopened, "p1")?.publisher?.signed, true);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();
});

test("one optional expo booth charges once and pays fans once on the fair day", async () => {
  assert.equal(EXPO_NAME, "TownSquare Creator Fair");
  assert.equal(EXPO_COST_CENTS, 6_000);
  assert.equal(EXPO_FANS, 3);
  assert.equal(EXPO_DAY_OF_SEASON, 14);
  assert.equal(nextExpoFair(1).when, "Spring 14");
  assert.equal(nextExpoFair(1).key, "1-spring");
  assert.equal(nextExpoFair(1).day, 14);
  assert.equal(nextExpoFair(14).when, "Spring 14");
  assert.equal(nextExpoFair(15).when, "Summer 14");
  assert.equal(nextExpoFair(15).day, 42);
  assert.equal(nextExpoFair(42).key, "1-summer");
  assert.equal(nextExpoFair(43).when, "Fall 14");
  assert.equal(nextExpoFair(70).when, "Fall 14");
  assert.equal(nextExpoFair(71).when, "Winter 14");
  assert.equal(nextExpoFair(98).key, "1-winter");
  assert.equal(nextExpoFair(99).when, "Spring 14");
  assert.equal(nextExpoFair(99).year, 2);
  assert.equal(nextExpoFair(126).key, "2-spring");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  function expoRows(db: GameDatabase) {
    return db.journey.db.prepare(
      "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:expo:%' ORDER BY id",
    ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
  }

  const skip = await setup();
  assert.equal(skip.db.tycoon.view().expo.booked, false);
  assert.equal(skip.db.tycoon.view().expo.name, EXPO_NAME);
  assert.equal(skip.db.tycoon.view().expo.costCents, 6_000);
  assert.equal(skip.db.tycoon.view().expo.fans, 3);
  assert.equal(skip.db.tycoon.view().expo.when, "Spring 14");
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  skip.db.endDay(3);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(expoRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const missed = await setup();
  missed.db.setClock(14, 480, 0);
  missed.db.endDay(14);
  missed.db.endDay(14);
  assert.equal(missed.db.journey.state().company.cashCents, 0);
  assert.equal(missed.db.journey.state().company.reputation, 0);
  assert.equal(expoRows(missed.db).length, 0);
  assert.equal(missed.db.tycoon.view().expo.when, "Summer 14");
  assert.equal(missed.db.tycoon.view().expo.booked, false);
  missed.db.close();

  const short = await setup();
  short.db.journey.recordCompanyChange("expo-short", 1, 5_999, 0, 0, "Short cash");
  assert.throws(() => short.db.tycoon.bookBooth(), /Need \$60/u);
  assert.equal(short.db.journey.state().company.cashCents, 5_999);
  assert.equal(expoRows(short.db).length, 0);
  assert.equal(short.db.tycoon.view().expo.booked, false);
  short.db.close();

  const booked = await setup();
  booked.db.journey.recordCompanyChange("expo-cash", 1, 6_000, 0, 0, "Booth cash");
  booked.db.tycoon.bookBooth();
  assert.equal(booked.db.journey.state().company.cashCents, 0);
  assert.equal(booked.db.journey.state().company.reputation, 0);
  assert.equal(booked.db.tycoon.view().expo.booked, true);
  assert.equal(booked.db.tycoon.view().expo.when, "Spring 14");
  const fee = expoRows(booked.db);
  assert.equal(fee.length, 1);
  assert.equal(fee[0]?.id, "tycoon:expo:1-spring:booth");
  assert.equal(fee[0]?.label, "Booth: TownSquare Creator Fair");
  assert.equal(fee[0]?.cash_delta, -6_000);
  assert.equal(fee[0]?.earned_delta, 0);
  assert.equal(fee[0]?.reputation_delta, 0);
  assert.throws(() => booked.db.tycoon.bookBooth(), /Already booked\./u);
  assert.equal(booked.db.journey.state().company.cashCents, 0);
  assert.equal(expoRows(booked.db).length, 1);
  booked.db.setClock(13, 480, 0);
  booked.db.tycoon.tickDay(13);
  assert.equal(expoRows(booked.db).length, 1);
  assert.equal(booked.db.journey.state().company.reputation, 0);
  booked.db.setClock(14, 480, 0);
  booked.db.tycoon.tickDay(14);
  booked.db.tycoon.tickDay(14);
  assert.equal(booked.db.journey.state().company.cashCents, 0);
  assert.equal(booked.db.journey.state().company.reputation, 3);
  const paid = expoRows(booked.db);
  assert.equal(paid.length, 2);
  const fans = paid.find((row) => row.id === "tycoon:expo:1-spring:fans");
  assert.equal(fans?.label, "Expo: TownSquare Creator Fair");
  assert.equal(fans?.cash_delta, 0);
  assert.equal(fans?.earned_delta, 0);
  assert.equal(fans?.reputation_delta, 3);
  booked.db.endDay(14);
  booked.db.endDay(14);
  assert.equal(booked.db.clockState().day, 15);
  assert.equal(booked.db.journey.state().company.reputation, 3);
  assert.equal(booked.db.journey.state().company.cashCents, 0);
  assert.equal(booked.db.tycoon.view().expo.booked, false);
  assert.equal(booked.db.tycoon.view().expo.when, "Summer 14");
  assert.equal(validate(booked.db.journey.state()), true, JSON.stringify(validate.errors));
  const bookedFile = join(booked.root, "game.sqlite");
  const bookedProject = join(booked.root, "company-project");
  booked.db.close();
  const reopened = new GameDatabase(bookedFile, bookedProject);
  assert.equal(reopened.journey.state().company.reputation, 3);
  assert.equal(reopened.journey.state().company.cashCents, 0);
  assert.equal(expoRows(reopened).length, 2);
  reopened.tycoon.tickDay(15);
  assert.equal(reopened.journey.state().company.reputation, 3);
  reopened.journey.recordCompanyChange("expo-summer-cash", 15, 6_000, 0, 0, "Summer booth cash");
  reopened.tycoon.bookBooth();
  assert.equal(reopened.tycoon.view().expo.booked, true);
  assert.equal(reopened.tycoon.view().expo.when, "Summer 14");
  assert.equal(expoRows(reopened).some((row) => row.id === "tycoon:expo:1-summer:booth"), true);
  assert.throws(() => reopened.tycoon.bookBooth(), /Already booked\./u);
  reopened.setClock(42, 480, 0);
  reopened.endDay(42);
  reopened.endDay(42);
  assert.equal(reopened.journey.state().company.reputation, 6);
  assert.equal(reopened.journey.state().company.cashCents, 0);
  assert.equal(expoRows(reopened).filter((row) => row.id.endsWith(":fans")).length, 2);
  assert.equal(reopened.tycoon.view().expo.when, "Fall 14");
  assert.equal(reopened.tycoon.view().expo.booked, false);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const sameDay = await setup();
  sameDay.db.journey.recordCompanyChange("expo-same-day", 1, 6_000, 0, 0, "Fair day cash");
  sameDay.db.setClock(14, 480, 0);
  sameDay.db.tycoon.bookBooth();
  assert.equal(sameDay.db.tycoon.view().expo.booked, true);
  sameDay.db.endDay(14);
  assert.equal(sameDay.db.journey.state().company.reputation, 3);
  assert.equal(sameDay.db.journey.state().company.cashCents, 0);
  assert.equal(sameDay.db.tycoon.view().expo.when, "Summer 14");
  sameDay.db.close();

  const yearTwo = await setup();
  yearTwo.db.journey.recordCompanyChange("expo-year-two", 1, 6_000, 0, 0, "Year two cash");
  yearTwo.db.setClock(113, 480, 0);
  assert.equal(yearTwo.db.tycoon.view().expo.when, "Spring 14");
  assert.equal(yearTwo.db.tycoon.view().expo.booked, false);
  yearTwo.db.tycoon.bookBooth();
  const yearRow = expoRows(yearTwo.db).find((row) => row.id === "tycoon:expo:2-spring:booth");
  assert.equal(yearRow?.cash_delta, -6_000);
  yearTwo.db.setClock(126, 480, 0);
  yearTwo.db.endDay(126);
  assert.equal(yearTwo.db.journey.state().company.reputation, 3);
  assert.equal(expoRows(yearTwo.db).some((row) => row.id === "tycoon:expo:2-spring:fans"), true);
  assert.equal(validate(yearTwo.db.journey.state()), true, JSON.stringify(validate.errors));
  yearTwo.db.close();
});

function localizeRows(db: GameDatabase) {
  return db.journey.db.prepare(
    "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:localize:%' ORDER BY id",
  ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
}

function expectedLocalizeSale(db: GameDatabase, productId: string, day: number, score: number, reputation = db.journey.state().company.reputation) {
  const product = productById(db, productId);
  if (!product) throw new Error(`missing ${productId}`);
  const calendar = calendarForDay(day);
  return salesForDay({
    seed: 26021,
    productId,
    typeId: product.typeId,
    fit: product.fit,
    score,
    dayIndex: SALES_WINDOW_DAYS,
    reputation,
    pricePercent: product.pricePercent,
    marketing: product.marketing,
    quietPercent: LOCALIZE_UNIT_PERCENT,
    unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === product.topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
  });
}

test("a translation charges once and pays one quieter extra sales day", async () => {
  assert.equal(LOCALIZE_EDITION, "Spanish edition");
  assert.equal(LOCALIZE_COST_CENTS, 5_000);
  assert.equal(LOCALIZE_UNIT_PERCENT, 50);
  const curve = { seed: 26021, productId: "p1", typeId: "newsletter" as const, fit: "great" as const, score: 6, reputation: 0, dayIndex: SALES_WINDOW_DAYS };
  const portDay = salesForDay(curve);
  const quietDay = salesForDay({ ...curve, quietPercent: LOCALIZE_UNIT_PERCENT });
  const unchanged = salesForDay({ ...curve, quietPercent: 100 });
  assert.deepEqual(unchanged, portDay);
  assert.ok(quietDay.cents > 0 && quietDay.cents < portDay.cents);
  assert.ok(quietDay.fans >= 1 && quietDay.fans <= portDay.fans);
  assert.throws(() => salesForDay({ ...curve, dayIndex: SALES_WINDOW_DAYS + 1 }), /Sales day is outside the window/u);

  const { db, root } = await setup();
  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  db.tycoon.start("crypto", "newsletter", []);
  assert.equal(db.tycoon.view().developing?.localization, null);
  assert.throws(() => db.tycoon.localize("p1"), /Ship this product first/u);
  assert.throws(() => db.tycoon.localize("p9"), /No product with that id/u);
  assert.equal(localizeRows(db).length, 0);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  const plain = productById(db, "p1");
  assert.equal(plain?.salesCents, 20700);
  assert.equal(plain?.fans, 5);
  assert.equal(plain?.localization?.phase, "");
  assert.equal(plain?.localization?.enabled, false);
  assert.equal(plain?.localization?.reason, "Still selling.");
  assert.equal(plain?.localization?.edition, LOCALIZE_EDITION);
  assert.equal(plain?.localization?.costCents, LOCALIZE_COST_CENTS);
  assert.equal(staffJson(db, "p1").includes("localization"), false);
  assert.throws(() => db.tycoon.localize("p1"), /Still selling/u);
  assert.equal(localizeRows(db).length, 0);
  assert.equal(db.journey.state().company.cashCents, 20700);
  assert.equal(db.journey.state().company.reputation, 5);
  db.endDay(3);
  assert.equal(productById(db, "p1")?.salesCents, 20700);
  db.endDay(4);
  assert.equal(productById(db, "p1")?.salesCents, 33300);
  assert.equal(localizeRows(db).length, 0);
  db.endDay(5);
  db.endDay(6);
  const finished = productById(db, "p1");
  assert.equal(finished?.status, "complete");
  assert.equal(finished?.salesDays, 4);
  assert.equal(finished?.localization?.enabled, true);
  assert.equal(finished?.localization?.reason, "");
  assert.equal(finished?.localization?.phase, "");
  const finishedSales = finished?.salesCents ?? 0;
  const finishedFans = finished?.fans ?? 0;
  const beforeCash = db.journey.state().company.cashCents;
  const beforeRep = db.journey.state().company.reputation;
  db.tycoon.localize("p1");
  const started = productById(db, "p1");
  assert.equal(started?.localization?.phase, "selling");
  assert.equal(started?.localization?.enabled, false);
  assert.equal(started?.localization?.reason, "Already translated.");
  assert.equal(started?.salesCents, finishedSales);
  assert.equal(started?.fans, finishedFans);
  assert.equal(started?.salesDays, 4);
  assert.equal(db.journey.state().company.cashCents, beforeCash - LOCALIZE_COST_CENTS);
  assert.equal(db.journey.state().company.reputation, beforeRep);
  const fee = localizeRows(db);
  assert.equal(fee.length, 1);
  assert.equal(fee[0]?.id, "tycoon:localize:p1:fee");
  assert.equal(fee[0]?.label, "Translate: Spanish edition");
  assert.equal(fee[0]?.cash_delta, -LOCALIZE_COST_CENTS);
  assert.equal(fee[0]?.earned_delta, 0);
  assert.equal(fee[0]?.reputation_delta, 0);
  const stored = JSON.parse(staffJson(db, "p1")) as { localization?: { edition: string; startedDay: number; cents?: number } };
  assert.deepEqual(stored.localization, { edition: LOCALIZE_EDITION, startedDay: 7 });
  assert.throws(() => db.tycoon.localize("p1"), /Already translated/u);
  assert.equal(localizeRows(db).length, 1);
  const payout = expectedLocalizeSale(db, "p1", 7, patchedScore(started?.review?.score ?? 0, started?.patch?.applied ?? false));
  const fullExtra = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: started?.review?.score ?? 0,
    dayIndex: SALES_WINDOW_DAYS,
    reputation: beforeRep,
    pricePercent: 100,
    marketing: "none",
  });
  assert.ok(payout.cents < fullExtra.cents);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  db.endDay(7);
  const sold = productById(db, "p1");
  assert.equal(sold?.localization?.phase, "sold");
  assert.equal(sold?.localization?.cents, payout.cents);
  assert.equal(sold?.localization?.fans, payout.fans);
  assert.equal(sold?.salesCents, finishedSales + payout.cents);
  assert.equal(sold?.fans, finishedFans + payout.fans);
  assert.equal(sold?.salesDays, 4);
  assert.equal(db.journey.state().company.cashCents, beforeCash - LOCALIZE_COST_CENTS + payout.cents);
  assert.equal(db.journey.state().company.reputation, beforeRep + payout.fans);
  const sale = localizeRows(db).find((row) => row.id === "tycoon:localize:p1:sales");
  assert.equal(sale?.label, "Sales · Spanish edition");
  assert.equal(sale?.cash_delta, payout.cents);
  assert.equal(sale?.earned_delta, payout.cents);
  assert.equal(sale?.reputation_delta, payout.fans);
  assert.equal(localizeRows(db).length, 2);
  db.endDay(7);
  db.endDay(8);
  assert.equal(productById(db, "p1")?.localization?.cents, payout.cents);
  assert.equal(productById(db, "p1")?.salesCents, finishedSales + payout.cents);
  assert.equal(db.journey.state().company.cashCents, beforeCash - LOCALIZE_COST_CENTS + payout.cents);
  assert.equal(db.journey.state().company.reputation, beforeRep + payout.fans);
  assert.equal(localizeRows(db).filter((row) => row.id === "tycoon:localize:p1:sales").length, 1);
  assert.equal(validate(db.journey.state()), true, JSON.stringify(validate.errors));
  const file = join(root, "game.sqlite");
  const project = join(root, "company-project");
  db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().history.find((item) => item.id === "p1")?.localization?.phase, "sold");
  assert.equal(reopened.tycoon.view().history.find((item) => item.id === "p1")?.localization?.cents, payout.cents);
  reopened.endDay(8);
  assert.equal(reopened.journey.state().company.cashCents, beforeCash - LOCALIZE_COST_CENTS + payout.cents);
  assert.equal(localizeRows(reopened).length, 2);
  reopened.close();

  const broke = await setup();
  finishNewsletter(broke.db);
  const brokeHave = broke.db.journey.state().company.cashCents;
  broke.db.journey.recordCompanyChange("drain-localize", 7, -brokeHave, 0, 0, "Drain");
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(productById(broke.db, "p1")?.localization?.enabled, false);
  assert.equal(productById(broke.db, "p1")?.localization?.reason, "Need $50");
  const brokeJson = staffJson(broke.db, "p1");
  assert.throws(() => broke.db.tycoon.localize("p1"), /Need \$50/u);
  assert.equal(broke.db.journey.state().company.cashCents, 0);
  assert.equal(staffJson(broke.db, "p1"), brokeJson);
  assert.equal(localizeRows(broke.db).length, 0);
  broke.db.close();

  const published = await setup();
  published.db.tycoon.start("crypto", "newsletter", []);
  published.db.tycoon.signPublisher();
  published.db.endDay(1);
  published.db.endDay(2);
  published.db.tycoon.release("p1");
  published.db.endDay(3);
  published.db.endDay(4);
  published.db.endDay(5);
  published.db.endDay(6);
  const gross = expectedLocalizeSale(published.db, "p1", 7, productById(published.db, "p1")?.review?.score ?? 0);
  assert.ok(publisherCutCents(gross.cents) > 0);
  published.db.tycoon.localize("p1");
  published.db.endDay(7);
  const net = publisherNetCents(gross.cents);
  const publishedSale = localizeRows(published.db).find((row) => row.id === "tycoon:localize:p1:sales");
  assert.equal(publishedSale?.cash_delta, net);
  assert.equal(publishedSale?.reputation_delta, gross.fans);
  assert.equal(productById(published.db, "p1")?.localization?.cents, net);
  assert.equal(productById(published.db, "p1")?.localization?.fans, gross.fans);
  published.db.close();

  const both = await setup();
  finishNewsletter(both.db);
  const bothRep = both.db.journey.state().company.reputation;
  const bothScore = productById(both.db, "p1")?.review?.score ?? 0;
  const portPayout = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: bothScore,
    dayIndex: SALES_WINDOW_DAYS,
    reputation: bothRep,
  });
  both.db.tycoon.port("p1");
  both.db.tycoon.localize("p1");
  const quiet = expectedLocalizeSale(both.db, "p1", 7, bothScore, bothRep + portPayout.fans);
  assert.ok(quiet.cents < portPayout.cents);
  both.db.endDay(7);
  assert.equal(productById(both.db, "p1")?.port?.cents, portPayout.cents);
  assert.equal(productById(both.db, "p1")?.localization?.cents, quiet.cents);
  assert.equal(productById(both.db, "p1")?.port?.phase, "sold");
  assert.equal(productById(both.db, "p1")?.localization?.phase, "sold");
  const portRow = both.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:p1:4'").get();
  assert.ok(portRow);
  assert.equal(localizeRows(both.db).filter((row) => row.id.endsWith(":sales")).length, 1);
  both.db.close();

  const legacy = await setup();
  const legacyFile = join(legacy.root, "game.sqlite");
  const legacyProject = join(legacy.root, "company-project");
  legacy.db.close();
  const raw = new DatabaseSync(legacyFile);
  const staffOnly = JSON.stringify(["founder"]);
  raw.prepare(`
    INSERT INTO tycoon_products (
      id, topic_id, type_id, name, fit, status, started_day, dev_days,
      design_points, tech_points, hype_points, staff_json, last_dev_day,
      released_day, review_json, sales_applied, last_sales_day, sales_cents, fans
    ) VALUES ('p1', 'crypto', 'newsletter', 'Crypto Alpha Newsletter', 'great', 'complete', 1, 2, 4, 4, 4, ?, NULL, 3, ?, 4, 6, 20700, 5)
  `).run(staffOnly, JSON.stringify({
    score: 6,
    reviewers: ["TownSquare Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
  }));
  raw.close();
  const restored = new GameDatabase(legacyFile, legacyProject);
  assert.equal(restored.tycoon.view().history[0]?.localization?.phase, "");
  assert.equal(restored.tycoon.view().history[0]?.localization?.reason, "Need $50");
  assert.equal(staffJson(restored, "p1"), staffOnly);
  restored.journey.recordCompanyChange("localize-test-cash", 7, LOCALIZE_COST_CENTS, 0, 0, "Translate test cash");
  assert.equal(restored.tycoon.view().history[0]?.localization?.enabled, true);
  assert.equal(staffJson(restored, "p1"), staffOnly);
  assert.equal(validate(restored.journey.state()), true, JSON.stringify(validate.errors));
  restored.close();
});

function townRows(db: GameDatabase) {
  return db.journey.db.prepare(
    "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:townday:%' ORDER BY id",
  ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
}

test("one optional town afternoon charges once and grants fans once", async () => {
  assert.equal(TOWN_DAY_NAME, "TownSquare Block Picnic");
  assert.equal(TOWN_DAY_COST_CENTS, 2_000);
  assert.equal(TOWN_DAY_FANS, 2);
  assert.equal(townDaySeason(1).key, "1-spring");
  assert.equal(townDaySeason(1).seasonName, "Spring");
  assert.equal(townDaySeason(28).key, "1-spring");
  assert.equal(townDaySeason(29).key, "1-summer");
  assert.equal(townDaySeason(29).seasonName, "Summer");
  assert.equal(townDaySeason(56).key, "1-summer");
  assert.equal(townDaySeason(57).key, "1-fall");
  assert.equal(townDaySeason(112).key, "1-winter");
  assert.equal(townDaySeason(113).key, "2-spring");
  assert.equal(townDaySeason(113).year, 2);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const skip = await setup();
  assert.equal(skip.db.tycoon.view().townDay.taken, false);
  assert.equal(skip.db.tycoon.view().townDay.name, TOWN_DAY_NAME);
  assert.equal(skip.db.tycoon.view().townDay.costCents, 2_000);
  assert.equal(skip.db.tycoon.view().townDay.fans, 2);
  assert.equal(skip.db.tycoon.view().townDay.season, "Spring");
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  skip.db.endDay(3);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(townRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const short = await setup();
  short.db.journey.recordCompanyChange("town-short", 1, 1_999, 0, 0, "Short cash");
  assert.throws(() => short.db.tycoon.takeTownDay(), /Need \$20/u);
  assert.equal(short.db.journey.state().company.cashCents, 1_999);
  assert.equal(short.db.journey.state().company.reputation, 0);
  assert.equal(townRows(short.db).length, 0);
  assert.equal(short.db.tycoon.view().townDay.taken, false);
  short.db.close();

  const taken = await setup();
  taken.db.journey.recordCompanyChange("town-cash", 1, 2_000, 0, 0, "Picnic cash");
  taken.db.tycoon.start("crypto", "newsletter", []);
  const devDays = taken.db.tycoon.view().developing?.devDays;
  taken.db.tycoon.takeTownDay();
  assert.equal(taken.db.clockState().day, 1);
  assert.equal(taken.db.tycoon.view().developing?.devDays, devDays);
  assert.equal(taken.db.journey.state().company.cashCents, 0);
  assert.equal(taken.db.journey.state().company.reputation, 2);
  assert.equal(taken.db.tycoon.view().townDay.taken, true);
  assert.equal(taken.db.tycoon.view().townDay.season, "Spring");
  const fee = townRows(taken.db);
  assert.equal(fee.length, 1);
  assert.equal(fee[0]?.id, "tycoon:townday:1-spring:fee");
  assert.equal(fee[0]?.label, "Town day: TownSquare Block Picnic");
  assert.equal(fee[0]?.cash_delta, -2_000);
  assert.equal(fee[0]?.earned_delta, 0);
  assert.equal(fee[0]?.reputation_delta, 2);
  assert.throws(() => taken.db.tycoon.takeTownDay(), /Already took the afternoon\./u);
  assert.equal(taken.db.journey.state().company.cashCents, 0);
  assert.equal(taken.db.journey.state().company.reputation, 2);
  assert.equal(townRows(taken.db).length, 1);
  taken.db.tycoon.tickDay(1);
  taken.db.tycoon.tickDay(1);
  assert.equal(townRows(taken.db).length, 1);
  assert.equal(taken.db.journey.state().company.reputation, 2);
  const ended = taken.db.endDay(1);
  const again = taken.db.endDay(1);
  assert.equal(ended.summary.reputation, 2);
  assert.equal(again.summary.reputation, 2);
  assert.equal(taken.db.clockState().day, 2);
  assert.equal(taken.db.journey.state().company.cashCents, 0);
  assert.equal(taken.db.journey.state().company.reputation, 2);
  assert.equal(townRows(taken.db).length, 1);
  assert.equal(taken.db.tycoon.view().townDay.taken, true);
  assert.equal(validate(taken.db.journey.state()), true, JSON.stringify(validate.errors));
  const takenFile = join(taken.root, "game.sqlite");
  const takenProject = join(taken.root, "company-project");
  taken.db.close();
  const reopened = new GameDatabase(takenFile, takenProject);
  assert.equal(reopened.journey.state().company.cashCents, 0);
  assert.equal(reopened.journey.state().company.reputation, 2);
  assert.equal(townRows(reopened).length, 1);
  assert.equal(reopened.tycoon.view().townDay.taken, true);
  reopened.tycoon.tickDay(2);
  assert.equal(reopened.journey.state().company.reputation, 2);
  assert.throws(() => reopened.tycoon.takeTownDay(), /Already took the afternoon\./u);
  reopened.setClock(29, 480, 0);
  assert.equal(reopened.tycoon.view().townDay.taken, false);
  assert.equal(reopened.tycoon.view().townDay.season, "Summer");
  reopened.journey.recordCompanyChange("town-summer-cash", 29, 2_000, 0, 0, "Summer picnic cash");
  reopened.tycoon.takeTownDay();
  assert.equal(reopened.tycoon.view().townDay.taken, true);
  assert.equal(reopened.journey.state().company.cashCents, 0);
  assert.equal(reopened.journey.state().company.reputation, 4);
  assert.equal(townRows(reopened).some((row) => row.id === "tycoon:townday:1-summer:fee"), true);
  assert.throws(() => reopened.tycoon.takeTownDay(), /Already took the afternoon\./u);
  reopened.endDay(29);
  reopened.endDay(29);
  assert.equal(reopened.journey.state().company.reputation, 4);
  assert.equal(reopened.journey.state().company.cashCents, 0);
  assert.equal(townRows(reopened).length, 2);
  assert.equal(reopened.tycoon.view().townDay.season, "Summer");
  assert.equal(reopened.tycoon.view().townDay.taken, true);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const beforeSale = await setup();
  beforeSale.db.journey.recordCompanyChange("town-before-sale", 1, 20_000, 0, 0, "Cash");
  beforeSale.db.tycoon.takeTownDay();
  assert.equal(beforeSale.db.journey.state().company.reputation, 2);
  beforeSale.db.tycoon.start("crypto", "newsletter", []);
  beforeSale.db.endDay(1);
  beforeSale.db.endDay(2);
  beforeSale.db.tycoon.release("p1");
  assert.equal(beforeSale.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(beforeSale.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(beforeSale.db.journey.state().company.reputation, 7);
  assert.equal(beforeSale.db.journey.state().company.cashCents, 38_700);
  assert.equal(townRows(beforeSale.db).length, 1);
  beforeSale.db.close();

  const yearTwo = await setup();
  yearTwo.db.journey.recordCompanyChange("town-year-two", 1, 2_000, 0, 0, "Year two cash");
  yearTwo.db.setClock(113, 480, 0);
  assert.equal(yearTwo.db.tycoon.view().townDay.season, "Spring");
  assert.equal(yearTwo.db.tycoon.view().townDay.taken, false);
  yearTwo.db.tycoon.takeTownDay();
  const yearRow = townRows(yearTwo.db).find((row) => row.id === "tycoon:townday:2-spring:fee");
  assert.equal(yearRow?.cash_delta, -2_000);
  assert.equal(yearRow?.reputation_delta, 2);
  yearTwo.db.endDay(113);
  yearTwo.db.endDay(113);
  assert.equal(yearTwo.db.journey.state().company.reputation, 2);
  assert.equal(townRows(yearTwo.db).length, 1);
  assert.equal(validate(yearTwo.db.journey.state()), true, JSON.stringify(validate.errors));
  yearTwo.db.close();
});

function pressDemoRows(db: GameDatabase) {
  return db.journey.db.prepare(
    "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:pressdemo:%' ORDER BY id",
  ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
}

test("one optional press demo charges once and grants fans once", async () => {
  assert.equal(PRESS_DEMO_NAME, "TownSquare Weekly Preview");
  assert.equal(PRESS_DEMO_COST_CENTS, 3_000);
  assert.equal(PRESS_DEMO_FANS, 4);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = {
    name: "TownSquare Weekly Preview",
    costCents: 3_000,
    fans: 4,
    shown: false,
  };
  const shownOffer = { ...offer, shown: true };

  const skip = await setup();
  assert.equal(skip.db.tycoon.view().developing, null);
  assert.throws(() => skip.db.tycoon.showPressDemo(), /No product is on the bench\./u);
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.pressDemo, offer);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).pressDemo, undefined);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.pressDemo, null);
  skip.db.endDay(3);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(pressDemoRows(skip.db).length, 0);
  assert.throws(() => skip.db.tycoon.showPressDemo(), /No product is on the bench\./u);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const short = await setup();
  short.db.tycoon.start("crypto", "newsletter", []);
  short.db.journey.recordCompanyChange("press-short", 1, 2_999, 0, 0, "Short cash");
  assert.throws(() => short.db.tycoon.showPressDemo(), /Need \$30/u);
  assert.equal(short.db.journey.state().company.cashCents, 2_999);
  assert.equal(short.db.journey.state().company.reputation, 0);
  assert.equal(pressDemoRows(short.db).length, 0);
  assert.deepEqual(short.db.tycoon.view().developing?.pressDemo, offer);
  assert.equal(JSON.parse(staffJson(short.db, "p1")).pressDemo, undefined);
  short.db.close();

  const shown = await setup();
  shown.db.journey.recordCompanyChange("press-cash", 1, 3_000, 0, 0, "Preview cash");
  shown.db.tycoon.start("crypto", "newsletter", []);
  const devDays = shown.db.tycoon.view().developing?.devDays;
  shown.db.tycoon.showPressDemo();
  assert.equal(shown.db.clockState().day, 1);
  assert.equal(shown.db.tycoon.view().developing?.devDays, devDays);
  assert.equal(shown.db.journey.state().company.cashCents, 0);
  assert.equal(shown.db.journey.state().company.reputation, 4);
  assert.deepEqual(shown.db.tycoon.view().developing?.pressDemo, shownOffer);
  assert.equal(JSON.parse(staffJson(shown.db, "p1")).pressDemo, true);
  const fee = pressDemoRows(shown.db);
  assert.equal(fee.length, 1);
  assert.equal(fee[0]?.id, "tycoon:pressdemo:p1:fee");
  assert.equal(fee[0]?.label, "Press demo: TownSquare Weekly Preview");
  assert.equal(fee[0]?.cash_delta, -3_000);
  assert.equal(fee[0]?.earned_delta, 0);
  assert.equal(fee[0]?.reputation_delta, 4);
  assert.throws(() => shown.db.tycoon.showPressDemo(), /Already shown\./u);
  assert.equal(shown.db.journey.state().company.cashCents, 0);
  assert.equal(shown.db.journey.state().company.reputation, 4);
  assert.equal(pressDemoRows(shown.db).length, 1);
  shown.db.tycoon.tickDay(1);
  shown.db.tycoon.tickDay(1);
  assert.equal(pressDemoRows(shown.db).length, 1);
  assert.equal(shown.db.journey.state().company.reputation, 4);
  const ended = shown.db.endDay(1);
  const again = shown.db.endDay(1);
  assert.equal(ended.summary.reputation, 4);
  assert.equal(again.summary.reputation, 4);
  assert.equal(shown.db.clockState().day, 2);
  assert.equal(shown.db.journey.state().company.cashCents, 0);
  assert.equal(shown.db.journey.state().company.reputation, 4);
  assert.equal(pressDemoRows(shown.db).length, 1);
  assert.deepEqual(shown.db.tycoon.view().developing?.pressDemo, shownOffer);
  assert.equal(validate(shown.db.journey.state()), true, JSON.stringify(validate.errors));
  const shownFile = join(shown.root, "game.sqlite");
  const shownProject = join(shown.root, "company-project");
  shown.db.close();
  const reopened = new GameDatabase(shownFile, shownProject);
  assert.equal(reopened.journey.state().company.cashCents, 0);
  assert.equal(reopened.journey.state().company.reputation, 4);
  assert.equal(pressDemoRows(reopened).length, 1);
  assert.deepEqual(reopened.tycoon.view().developing?.pressDemo, shownOffer);
  reopened.tycoon.tickDay(2);
  assert.equal(reopened.journey.state().company.reputation, 4);
  assert.throws(() => reopened.tycoon.showPressDemo(), /Already shown\./u);
  reopened.endDay(2);
  assert.equal(reopened.tycoon.view().developing?.ready, true);
  reopened.tycoon.release("p1");
  assert.equal(reopened.tycoon.view().history[0]?.fans, 5);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, 20_700);
  assert.deepEqual(reopened.tycoon.view().history[0]?.pressDemo, shownOffer);
  assert.equal(reopened.journey.state().company.reputation, 9);
  assert.equal(reopened.journey.state().company.cashCents, 20_700);
  assert.throws(() => reopened.tycoon.showPressDemo(), /No product is on the bench\./u);
  reopened.tycoon.start("fitness", "newsletter", []);
  assert.deepEqual(reopened.tycoon.view().developing?.pressDemo, offer);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).pressDemo, undefined);
  reopened.journey.recordCompanyChange("press-p2-cash", reopened.clockState().day, 3_000, 0, 0, "Second preview cash");
  reopened.tycoon.showPressDemo();
  assert.deepEqual(reopened.tycoon.view().developing?.pressDemo, shownOffer);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).pressDemo, true);
  assert.equal(pressDemoRows(reopened).some((row) => row.id === "tycoon:pressdemo:p2:fee"), true);
  assert.equal(pressDemoRows(reopened).length, 2);
  assert.equal(reopened.journey.state().company.reputation, 13);
  assert.throws(() => reopened.tycoon.showPressDemo(), /Already shown\./u);
  assert.deepEqual(productById(reopened, "p1")?.pressDemo, shownOffer);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const beforeSale = await setup();
  beforeSale.db.journey.recordCompanyChange("press-before-sale", 1, 3_000, 0, 0, "Cash");
  beforeSale.db.tycoon.start("crypto", "newsletter", []);
  beforeSale.db.tycoon.showPressDemo();
  assert.equal(beforeSale.db.journey.state().company.reputation, 4);
  beforeSale.db.endDay(1);
  beforeSale.db.endDay(2);
  beforeSale.db.tycoon.release("p1");
  assert.equal(beforeSale.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(beforeSale.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(beforeSale.db.journey.state().company.reputation, 9);
  assert.equal(beforeSale.db.journey.state().company.cashCents, 20_700);
  assert.equal(pressDemoRows(beforeSale.db).length, 1);
  beforeSale.db.close();

  const sequel = await setup();
  sequel.db.tycoon.start("crypto", "newsletter", []);
  sequel.db.endDay(1);
  sequel.db.endDay(2);
  sequel.db.tycoon.release("p1");
  sequel.db.endDay(3);
  sequel.db.endDay(4);
  sequel.db.endDay(5);
  sequel.db.endDay(6);
  sequel.db.tycoon.sequel("p1");
  assert.deepEqual(sequel.db.tycoon.view().developing?.pressDemo, offer);
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).pressDemo, undefined);
  assert.equal(productById(sequel.db, "p1")?.pressDemo, null);
  sequel.db.close();
});

function trailerRows(db: GameDatabase) {
  return db.journey.db.prepare(
    "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:trailer:%' ORDER BY id",
  ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
}

test("one optional launch trailer charges once and grants fans once", async () => {
  assert.equal(TRAILER_NAME, "TownSquare Creator Cut");
  assert.equal(TRAILER_COST_CENTS, 2_500);
  assert.equal(TRAILER_FANS, 6);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = {
    name: "TownSquare Creator Cut",
    costCents: 2_500,
    fans: 6,
    made: false,
  };
  const madeOffer = { ...offer, made: true };

  const skip = await setup();
  assert.throws(() => skip.db.tycoon.makeTrailer("p1"), /No product with that id\./u);
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(skip.db.tycoon.view().developing?.trailer, null);
  assert.throws(() => skip.db.tycoon.makeTrailer("p1"), /No product is selling\./u);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).trailer, undefined);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.deepEqual(skip.db.tycoon.view().history[0]?.trailer, offer);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.endDay(3);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(trailerRows(skip.db).length, 0);
  assert.deepEqual(skip.db.tycoon.view().history[0]?.trailer, offer);
  skip.db.endDay(5);
  skip.db.endDay(6);
  assert.equal(skip.db.tycoon.view().history[0]?.status, "complete");
  assert.equal(skip.db.tycoon.view().history[0]?.trailer, null);
  assert.throws(() => skip.db.tycoon.makeTrailer("p1"), /No product is selling\./u);
  assert.equal(trailerRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const short = await setup();
  short.db.tycoon.start("crypto", "newsletter", []);
  short.db.endDay(1);
  short.db.endDay(2);
  short.db.tycoon.release("p1");
  short.db.journey.recordCompanyChange("trailer-short", short.db.clockState().day, 2_499 - 20_700, 0, 0, "Short cash");
  assert.equal(short.db.journey.state().company.cashCents, 2_499);
  assert.throws(() => short.db.tycoon.makeTrailer("p1"), /Need \$25/u);
  assert.equal(short.db.journey.state().company.cashCents, 2_499);
  assert.equal(short.db.journey.state().company.reputation, 5);
  assert.equal(trailerRows(short.db).length, 0);
  assert.deepEqual(short.db.tycoon.view().history[0]?.trailer, offer);
  assert.equal(JSON.parse(staffJson(short.db, "p1")).trailer, undefined);
  assert.equal(short.db.tycoon.view().history[0]?.salesCents, 20_700);
  short.db.close();

  const made = await setup();
  made.db.tycoon.start("crypto", "newsletter", []);
  made.db.endDay(1);
  made.db.endDay(2);
  made.db.tycoon.release("p1");
  const day = made.db.clockState().day;
  const devDays = made.db.tycoon.view().history[0]?.devDays;
  made.db.tycoon.makeTrailer("p1");
  assert.equal(made.db.clockState().day, day);
  assert.equal(made.db.tycoon.view().history[0]?.devDays, devDays);
  assert.equal(made.db.journey.state().company.cashCents, 18_200);
  assert.equal(made.db.journey.state().company.reputation, 11);
  assert.equal(made.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(made.db.tycoon.view().history[0]?.fans, 5);
  assert.deepEqual(made.db.tycoon.view().history[0]?.trailer, madeOffer);
  assert.equal(JSON.parse(staffJson(made.db, "p1")).trailer, true);
  const fee = trailerRows(made.db);
  assert.equal(fee.length, 1);
  assert.equal(fee[0]?.id, "tycoon:trailer:p1:fee");
  assert.equal(fee[0]?.label, "Trailer: TownSquare Creator Cut");
  assert.equal(fee[0]?.cash_delta, -2_500);
  assert.equal(fee[0]?.earned_delta, 0);
  assert.equal(fee[0]?.reputation_delta, 6);
  assert.throws(() => made.db.tycoon.makeTrailer("p1"), /Already made\./u);
  assert.equal(made.db.journey.state().company.cashCents, 18_200);
  assert.equal(made.db.journey.state().company.reputation, 11);
  assert.equal(trailerRows(made.db).length, 1);
  made.db.tycoon.tickDay(day);
  made.db.tycoon.tickDay(day);
  assert.equal(trailerRows(made.db).length, 1);
  assert.equal(made.db.journey.state().company.reputation, 11);
  const ended = made.db.endDay(day);
  const again = made.db.endDay(day);
  assert.equal(ended.summary.reputation, 11);
  assert.equal(again.summary.reputation, 11);
  assert.equal(made.db.clockState().day, day + 1);
  assert.equal(made.db.journey.state().company.cashCents, 18_200);
  assert.equal(made.db.journey.state().company.reputation, 11);
  assert.equal(trailerRows(made.db).length, 1);
  assert.deepEqual(made.db.tycoon.view().history[0]?.trailer, madeOffer);
  assert.equal(validate(made.db.journey.state()), true, JSON.stringify(validate.errors));
  const madeFile = join(made.root, "game.sqlite");
  const madeProject = join(made.root, "company-project");
  made.db.close();
  const reopened = new GameDatabase(madeFile, madeProject);
  assert.equal(reopened.journey.state().company.cashCents, 18_200);
  assert.equal(reopened.journey.state().company.reputation, 11);
  assert.equal(trailerRows(reopened).length, 1);
  assert.deepEqual(reopened.tycoon.view().history[0]?.trailer, madeOffer);
  assert.throws(() => reopened.tycoon.makeTrailer("p1"), /Already made\./u);
  reopened.tycoon.start("fitness", "newsletter", []);
  assert.equal(reopened.tycoon.view().developing?.trailer, null);
  reopened.endDay(day + 1);
  reopened.endDay(day + 2);
  assert.equal(reopened.tycoon.view().developing?.ready, true);
  reopened.tycoon.release("p2");
  assert.deepEqual(reopened.tycoon.view().developing, null);
  assert.deepEqual(productById(reopened, "p2")?.trailer, offer);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).trailer, undefined);
  assert.deepEqual(productById(reopened, "p1")?.trailer, madeOffer);
  reopened.tycoon.makeTrailer("p2");
  assert.deepEqual(productById(reopened, "p2")?.trailer, madeOffer);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).trailer, true);
  assert.equal(trailerRows(reopened).some((row) => row.id === "tycoon:trailer:p2:fee"), true);
  assert.equal(trailerRows(reopened).length, 2);
  assert.throws(() => reopened.tycoon.makeTrailer("p2"), /Already made\./u);
  assert.throws(() => reopened.tycoon.makeTrailer("p1"), /Already made\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const sequel = await setup();
  sequel.db.tycoon.start("crypto", "newsletter", []);
  sequel.db.endDay(1);
  sequel.db.endDay(2);
  sequel.db.tycoon.release("p1");
  sequel.db.endDay(3);
  sequel.db.endDay(4);
  sequel.db.endDay(5);
  sequel.db.endDay(6);
  sequel.db.tycoon.sequel("p1");
  assert.equal(sequel.db.tycoon.view().developing?.trailer, null);
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).trailer, undefined);
  assert.equal(productById(sequel.db, "p1")?.trailer, null);
  sequel.db.close();
});

function diaryRows(db: GameDatabase) {
  return db.journey.db.prepare(
    "SELECT id, label, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:diary:%' ORDER BY id",
  ).all() as Array<{ id: string; label: string; cash_delta: number; earned_delta: number; reputation_delta: number }>;
}

function finishFirstNewsletter(db: GameDatabase) {
  db.tycoon.start("crypto", "newsletter", []);
  db.endDay(1);
  db.endDay(2);
  db.tycoon.release("p1");
  db.endDay(3);
  db.endDay(4);
  db.endDay(5);
  db.endDay(6);
}

test("one optional dev diary charges once and grants fans once", async () => {
  assert.equal(DIARY_NAME, "TownSquare Post-Mortem");
  assert.equal(DIARY_COST_CENTS, 1_500);
  assert.equal(DIARY_FANS, 1);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = {
    name: "TownSquare Post-Mortem",
    costCents: 1_500,
    fans: 1,
    written: false,
  };
  const writtenOffer = { ...offer, written: true };

  const skip = await setup();
  assert.throws(() => skip.db.tycoon.writeDiary("p1"), /No product with that id\./u);
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(skip.db.tycoon.view().developing?.diary, null);
  assert.throws(() => skip.db.tycoon.writeDiary("p1"), /Ship this product first\./u);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).diary, undefined);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.diary, null);
  assert.throws(() => skip.db.tycoon.writeDiary("p1"), /Still selling\./u);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.endDay(3);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(diaryRows(skip.db).length, 0);
  skip.db.endDay(5);
  skip.db.endDay(6);
  assert.equal(skip.db.tycoon.view().history[0]?.status, "complete");
  assert.deepEqual(skip.db.tycoon.view().history[0]?.diary, offer);
  assert.equal(diaryRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const short = await setup();
  finishFirstNewsletter(short.db);
  const finishedCash = short.db.journey.state().company.cashCents;
  const finishedFans = short.db.journey.state().company.reputation;
  short.db.journey.recordCompanyChange("diary-short", short.db.clockState().day, 1_499 - finishedCash, 0, 0, "Short cash");
  assert.equal(short.db.journey.state().company.cashCents, 1_499);
  assert.throws(() => short.db.tycoon.writeDiary("p1"), /Need \$15/u);
  assert.equal(short.db.journey.state().company.cashCents, 1_499);
  assert.equal(short.db.journey.state().company.reputation, finishedFans);
  assert.equal(diaryRows(short.db).length, 0);
  assert.deepEqual(short.db.tycoon.view().history[0]?.diary, offer);
  assert.equal(JSON.parse(staffJson(short.db, "p1")).diary, undefined);
  assert.equal(short.db.tycoon.view().history[0]?.status, "complete");
  short.db.close();

  const written = await setup();
  finishFirstNewsletter(written.db);
  const day = written.db.clockState().day;
  const cashBefore = written.db.journey.state().company.cashCents;
  const fansBefore = written.db.journey.state().company.reputation;
  const salesCents = written.db.tycoon.view().history[0]?.salesCents;
  const productFans = written.db.tycoon.view().history[0]?.fans;
  const devDays = written.db.tycoon.view().history[0]?.devDays;
  written.db.tycoon.writeDiary("p1");
  assert.equal(written.db.clockState().day, day);
  assert.equal(written.db.tycoon.view().history[0]?.devDays, devDays);
  assert.equal(written.db.journey.state().company.cashCents, cashBefore - 1_500);
  assert.equal(written.db.journey.state().company.reputation, fansBefore + 1);
  assert.equal(written.db.tycoon.view().history[0]?.salesCents, salesCents);
  assert.equal(written.db.tycoon.view().history[0]?.fans, productFans);
  assert.deepEqual(written.db.tycoon.view().history[0]?.diary, writtenOffer);
  assert.equal(JSON.parse(staffJson(written.db, "p1")).diary, true);
  const fee = diaryRows(written.db);
  assert.equal(fee.length, 1);
  assert.equal(fee[0]?.id, "tycoon:diary:p1:fee");
  assert.equal(fee[0]?.label, "Diary: TownSquare Post-Mortem");
  assert.equal(fee[0]?.cash_delta, -1_500);
  assert.equal(fee[0]?.earned_delta, 0);
  assert.equal(fee[0]?.reputation_delta, 1);
  assert.throws(() => written.db.tycoon.writeDiary("p1"), /Already written\./u);
  assert.equal(written.db.journey.state().company.cashCents, cashBefore - 1_500);
  assert.equal(written.db.journey.state().company.reputation, fansBefore + 1);
  assert.equal(diaryRows(written.db).length, 1);
  written.db.tycoon.tickDay(day);
  written.db.tycoon.tickDay(day);
  assert.equal(diaryRows(written.db).length, 1);
  assert.equal(written.db.journey.state().company.reputation, fansBefore + 1);
  const ended = written.db.endDay(day);
  const again = written.db.endDay(day);
  assert.equal(ended.summary.reputation, 1);
  assert.equal(again.summary.reputation, 1);
  assert.equal(written.db.clockState().day, day + 1);
  assert.equal(written.db.journey.state().company.cashCents, cashBefore - 1_500);
  assert.equal(written.db.journey.state().company.reputation, fansBefore + 1);
  assert.equal(diaryRows(written.db).length, 1);
  assert.deepEqual(written.db.tycoon.view().history[0]?.diary, writtenOffer);
  assert.equal(validate(written.db.journey.state()), true, JSON.stringify(validate.errors));
  const writtenFile = join(written.root, "game.sqlite");
  const writtenProject = join(written.root, "company-project");
  written.db.close();
  const reopened = new GameDatabase(writtenFile, writtenProject);
  assert.equal(reopened.journey.state().company.cashCents, cashBefore - 1_500);
  assert.equal(reopened.journey.state().company.reputation, fansBefore + 1);
  assert.equal(diaryRows(reopened).length, 1);
  assert.deepEqual(reopened.tycoon.view().history[0]?.diary, writtenOffer);
  assert.throws(() => reopened.tycoon.writeDiary("p1"), /Already written\./u);
  reopened.tycoon.start("fitness", "newsletter", []);
  assert.equal(reopened.tycoon.view().developing?.diary, null);
  assert.throws(() => reopened.tycoon.writeDiary("p2"), /Ship this product first\./u);
  const nextStart = reopened.clockState().day;
  reopened.endDay(nextStart);
  reopened.endDay(nextStart + 1);
  assert.equal(reopened.tycoon.view().developing?.ready, true);
  reopened.tycoon.release("p2");
  assert.equal(productById(reopened, "p2")?.diary, null);
  assert.throws(() => reopened.tycoon.writeDiary("p2"), /Still selling\./u);
  const afterRelease = reopened.clockState().day;
  reopened.endDay(afterRelease);
  reopened.endDay(afterRelease + 1);
  reopened.endDay(afterRelease + 2);
  reopened.endDay(afterRelease + 3);
  assert.equal(productById(reopened, "p2")?.status, "complete");
  assert.deepEqual(productById(reopened, "p2")?.diary, offer);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).diary, undefined);
  assert.deepEqual(productById(reopened, "p1")?.diary, writtenOffer);
  const nextCash = reopened.journey.state().company.cashCents;
  const nextFans = reopened.journey.state().company.reputation;
  reopened.tycoon.writeDiary("p2");
  assert.deepEqual(productById(reopened, "p2")?.diary, writtenOffer);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).diary, true);
  assert.equal(reopened.journey.state().company.cashCents, nextCash - 1_500);
  assert.equal(reopened.journey.state().company.reputation, nextFans + 1);
  assert.equal(diaryRows(reopened).some((row) => row.id === "tycoon:diary:p2:fee"), true);
  assert.equal(diaryRows(reopened).length, 2);
  assert.throws(() => reopened.tycoon.writeDiary("p2"), /Already written\./u);
  assert.throws(() => reopened.tycoon.writeDiary("p1"), /Already written\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const sequel = await setup();
  finishFirstNewsletter(sequel.db);
  sequel.db.tycoon.sequel("p1");
  assert.equal(sequel.db.tycoon.view().developing?.diary, null);
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).diary, undefined);
  assert.deepEqual(productById(sequel.db, "p1")?.diary, offer);
  sequel.db.close();
});

test("a seasonal rival cuts opening demand only for a matching release", async () => {
  assert.equal(RIVAL_UNIT_PERCENT, 90);
  assert.equal(RIVALS.length, 4);
  assert.equal(seasonIndexForDay(1), 0);
  assert.equal(seasonIndexForDay(28), 0);
  assert.equal(seasonIndexForDay(29), 1);
  assert.equal(seasonIndexForDay(57), 2);
  assert.equal(seasonIndexForDay(85), 3);
  assert.equal(seasonIndexForDay(113), 4);
  const spring = { shop: "Pip's Pop-up", topicId: "cooking", topicName: "Cooking", unitPercent: 90 };
  const summer = { shop: "Harbor Goods", topicId: "trading", topicName: "Trading", unitPercent: 90 };
  const fall = { shop: "Lumen Kiosk", topicId: "gaming", topicName: "Gaming", unitPercent: 90 };
  const winter = { shop: "Sable Shelf", topicId: "study_notes", topicName: "Study Notes", unitPercent: 90 };
  assert.deepEqual(rivalForDay(1), spring);
  assert.deepEqual(rivalForDay(28), spring);
  assert.deepEqual(rivalForDay(113), spring);
  assert.deepEqual(rivalForDay(29), summer);
  assert.deepEqual(rivalForDay(57), fall);
  assert.deepEqual(rivalForDay(85), winter);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const fresh = await setup();
  assert.deepEqual(fresh.db.tycoon.view().rival, spring);
  assert.equal(validate(fresh.db.journey.state()), true, JSON.stringify(validate.errors));
  fresh.db.tycoon.start("crypto", "newsletter", []);
  fresh.db.endDay(1);
  fresh.db.endDay(2);
  fresh.db.tycoon.release("p1");
  assert.equal(fresh.db.journey.state().company.cashCents, 20_700);
  assert.equal(fresh.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(JSON.parse(staffJson(fresh.db, "p1")).rivalCut, undefined);
  fresh.db.endDay(3);
  fresh.db.endDay(4);
  assert.equal(fresh.db.journey.state().company.cashCents, 33_300);
  assert.equal(JSON.parse(staffJson(fresh.db, "p1")).rivalCut, undefined);
  fresh.db.close();

  const hit = await setup();
  hit.db.setClock(25, 480, 0);
  assert.deepEqual(hit.db.tycoon.view().rival, spring);
  hit.db.tycoon.start("cooking", "newsletter", []);
  hit.db.endDay(25);
  hit.db.endDay(26);
  hit.db.tycoon.release("p1");
  const opened = hit.db.tycoon.view().history[0];
  assert.ok(opened?.review);
  const seed = hit.db.tycoon.view().seed;
  const plain = salesForDay({
    seed,
    productId: "p1",
    typeId: "newsletter",
    fit: opened.fit,
    score: opened.review.score,
    dayIndex: 0,
    reputation: 0,
  });
  const cut = salesForDay({
    seed,
    productId: "p1",
    typeId: "newsletter",
    fit: opened.fit,
    score: opened.review.score,
    dayIndex: 0,
    reputation: 0,
    rivalCut: true,
  });
  const base = openingDemand(opened.fit, opened.review.score, 0, false);
  assert.equal(openingDemand(opened.fit, opened.review.score, 0, true), Math.max(1, Math.round((base * 90) / 100)));
  assert.ok(cut.cents < plain.cents);
  assert.equal(opened.salesCents, cut.cents);
  assert.equal(opened.fans, cut.fans);
  assert.equal(hit.db.journey.state().company.cashCents, cut.cents);
  assert.equal(JSON.parse(staffJson(hit.db, "p1")).rivalCut, true);
  const rivalRows = hit.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:rival%'").all();
  assert.equal(rivalRows.length, 0);
  const releaseDay = hit.db.clockState().day;
  const releaseCents = hit.db.journey.state().company.cashCents;
  const releaseFans = hit.db.journey.state().company.reputation;
  hit.db.endDay(releaseDay);
  hit.db.endDay(releaseDay);
  assert.equal(hit.db.clockState().day, releaseDay + 1);
  assert.equal(hit.db.journey.state().company.cashCents, releaseCents);
  assert.equal(hit.db.tycoon.view().history[0]?.salesCents, releaseCents);
  assert.equal(hit.db.journey.state().company.reputation, releaseFans);

  const dayOne = salesForDay({
    seed,
    productId: "p1",
    typeId: "newsletter",
    fit: opened.fit,
    score: opened.review.score,
    dayIndex: 1,
    reputation: releaseFans,
    rivalCut: true,
  });
  hit.db.endDay(28);
  assert.equal(hit.db.tycoon.view().history[0]?.salesCents, releaseCents + dayOne.cents);
  assert.equal(hit.db.journey.state().company.reputation, releaseFans + dayOne.fans);
  const fansAfterDayOne = releaseFans + dayOne.fans;
  const summerDay = salesForDay({
    seed,
    productId: "p1",
    typeId: "newsletter",
    fit: opened.fit,
    score: opened.review.score,
    dayIndex: 2,
    reputation: fansAfterDayOne,
    rivalCut: true,
  });
  const summerPlain = salesForDay({
    seed,
    productId: "p1",
    typeId: "newsletter",
    fit: opened.fit,
    score: opened.review.score,
    dayIndex: 2,
    reputation: fansAfterDayOne,
  });
  hit.db.endDay(29);
  assert.ok(summerDay.cents < summerPlain.cents);
  assert.equal(hit.db.tycoon.view().history[0]?.salesCents, releaseCents + dayOne.cents + summerDay.cents);
  assert.equal(JSON.parse(staffJson(hit.db, "p1")).rivalCut, true);
  assert.deepEqual(hit.db.tycoon.view().rival, summer);
  const savedCents = hit.db.journey.state().company.cashCents;
  const savedSales = hit.db.tycoon.view().history[0]?.salesCents;
  const hitFile = join(hit.root, "game.sqlite");
  const hitProject = join(hit.root, "company-project");
  hit.db.close();
  const reopened = new GameDatabase(hitFile, hitProject);
  assert.equal(reopened.journey.state().company.cashCents, savedCents);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, savedSales);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).rivalCut, true);
  reopened.endDay(29);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, savedSales);
  assert.equal(reopened.journey.state().company.cashCents, savedCents);
  reopened.close();

  const other = await setup();
  other.db.setClock(29, 480, 0);
  assert.deepEqual(other.db.tycoon.view().rival, summer);
  other.db.tycoon.start("cooking", "newsletter", []);
  other.db.endDay(29);
  other.db.endDay(30);
  other.db.tycoon.release("p1");
  const quiet = other.db.tycoon.view().history[0];
  assert.ok(quiet?.review);
  const untouched = salesForDay({
    seed: other.db.tycoon.view().seed,
    productId: "p1",
    typeId: "newsletter",
    fit: quiet.fit,
    score: quiet.review.score,
    dayIndex: 0,
    reputation: 0,
  });
  assert.equal(quiet.salesCents, untouched.cents);
  assert.equal(quiet.fans, untouched.fans);
  assert.equal(JSON.parse(staffJson(other.db, "p1")).rivalCut, undefined);
  assert.equal(validate(other.db.journey.state()), true, JSON.stringify(validate.errors));
  other.db.close();
});

test("one optional feature adds one office day and bumps opening demand once", async () => {
  assert.equal(FEATURE_NAME, "TownSquare Bonus Drop");
  assert.equal(FEATURE_DAY_DELTA, 1);
  assert.equal(FEATURE_UNIT_PERCENT, 110);
  assert.equal(requiredDevDays(2, false), 2);
  assert.equal(requiredDevDays(2, false, null, false), 2);
  assert.equal(requiredDevDays(2, false, null, true), 3);
  assert.equal(requiredDevDays(2, false, "long", true), 4);
  assert.equal(requiredDevDays(2, true, null, true), 2);
  assert.equal(requiredDevDays(2, true, "long", false), 1);
  const demandBase = openingDemand("great", 6, 0);
  const featuredDemand = Math.max(1, Math.round((demandBase * FEATURE_UNIT_PERCENT) / 100));
  assert.equal(openingDemand("great", 6, 0, false, true), featuredDemand);
  assert.equal(
    openingDemand("great", 6, 0, true, true),
    Math.max(1, Math.round((featuredDemand * RIVAL_UNIT_PERCENT) / 100)),
  );
  assert.equal(parseRequest({ kind: "request", id: "feature", method: "tycoon.addFeature", params: {} }).method, "tycoon.addFeature");
  assert.throws(() => parseRequest({ kind: "request", id: "feature", method: "tycoon.addFeature", params: { extra: true } }), /Invalid protocol request/u);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = { name: FEATURE_NAME, dayDelta: FEATURE_DAY_DELTA, unitPercent: FEATURE_UNIT_PERCENT, added: false };
  const added = { ...offer, added: true };

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.addFeature(), /No product is on the bench\./u);
  assert.equal(bare.db.tycoon.view().developing, null);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.feature, offer);
  assert.equal(skip.db.tycoon.view().developing?.devDaysRequired, 2);
  assert.equal(skip.db.tycoon.view().developing?.size, null);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).feature, undefined);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).featureDemand, undefined);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.feature, null);
  assert.equal(skip.db.tycoon.view().history[0]?.size, null);
  const plainScore = skip.db.tycoon.view().history[0]?.review?.score;
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).featureDemand, undefined);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.throws(() => skip.db.tycoon.addFeature(), /No product is on the bench\./u);
  assert.equal(featureRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const { db, root } = await setup();
  db.tycoon.start("crypto", "newsletter", []);
  const cashBefore = db.journey.state().company.cashCents;
  const fansBefore = db.journey.state().company.reputation;
  db.tycoon.addFeature();
  const building = db.tycoon.view().developing;
  assert.equal(db.clockState().day, 1);
  assert.equal(db.journey.state().company.cashCents, cashBefore);
  assert.equal(db.journey.state().company.reputation, fansBefore);
  assert.equal(building?.devDays, 0);
  assert.equal(building?.devDaysRequired, 3);
  assert.equal(building?.progress, 0);
  assert.equal(building?.ready, false);
  assert.equal(building?.size, null);
  assert.deepEqual(building?.feature, added);
  assert.equal(JSON.parse(staffJson(db, "p1")).feature, true);
  assert.equal(JSON.parse(staffJson(db, "p1")).featureDemand, undefined);
  assert.equal(JSON.parse(staffJson(db, "p1")).size, undefined);
  assert.equal(featureRows(db).length, 0);
  assert.throws(() => db.tycoon.addFeature(), /Already added\./u);
  assert.equal(db.tycoon.view().developing?.devDaysRequired, 3);
  assert.equal(db.journey.state().company.cashCents, cashBefore);
  const developingFile = join(root, "game.sqlite");
  const developingProject = join(root, "company-project");
  db.close();
  const stillBuilding = new GameDatabase(developingFile, developingProject);
  assert.equal(stillBuilding.tycoon.view().developing?.devDaysRequired, 3);
  assert.deepEqual(stillBuilding.tycoon.view().developing?.feature, added);
  assert.equal(JSON.parse(staffJson(stillBuilding, "p1")).featureDemand, undefined);
  assert.throws(() => stillBuilding.tycoon.addFeature(), /Already added\./u);
  assert.equal(stillBuilding.tycoon.view().developing?.devDays, 0);
  stillBuilding.endDay(1);
  stillBuilding.endDay(1);
  assert.equal(stillBuilding.clockState().day, 2);
  assert.equal(stillBuilding.tycoon.view().developing?.devDays, 1);
  assert.equal(stillBuilding.tycoon.view().developing?.ready, false);
  stillBuilding.endDay(2);
  assert.equal(stillBuilding.tycoon.view().developing?.devDays, 2);
  assert.equal(stillBuilding.tycoon.view().developing?.ready, false);
  assert.throws(() => stillBuilding.tycoon.release("p1"), /needs 1 more office day/u);
  assert.equal(stillBuilding.tycoon.view().developing?.devDays, 2);
  stillBuilding.endDay(3);
  assert.equal(stillBuilding.tycoon.view().developing?.devDays, 3);
  assert.equal(stillBuilding.tycoon.view().developing?.devDaysRequired, 3);
  assert.equal(stillBuilding.tycoon.view().developing?.ready, true);
  assert.equal(stillBuilding.clockState().day, 4);
  stillBuilding.tycoon.release("p1");
  const opened = stillBuilding.tycoon.view().history[0];
  assert.ok(opened?.review);
  assert.equal(opened.review.score, plainScore);
  assert.equal(opened.size, null);
  assert.deepEqual(opened.feature, added);
  assert.equal(JSON.parse(staffJson(stillBuilding, "p1")).feature, true);
  assert.equal(JSON.parse(staffJson(stillBuilding, "p1")).featureDemand, true);
  const releaseDay = stillBuilding.clockState().day;
  const bumped = featureSale(stillBuilding, "p1", 0, 0, releaseDay);
  const plain = featureSale(stillBuilding, "p1", 0, 0, releaseDay, { featureDemand: false });
  const openedBase = openingDemand(opened.fit, opened.review.score, 0, false, false);
  assert.equal(openingDemand(opened.fit, opened.review.score, 0, false, true), Math.max(1, Math.round((openedBase * FEATURE_UNIT_PERCENT) / 100)));
  assert.ok(bumped.cents > plain.cents);
  assert.equal(opened.salesCents, bumped.cents);
  assert.equal(opened.fans, bumped.fans);
  assert.equal(stillBuilding.journey.state().company.cashCents, bumped.cents);
  assert.equal(stillBuilding.journey.state().company.reputation, bumped.fans);
  assert.equal(featureRows(stillBuilding).length, 0);
  const releaseCents = stillBuilding.journey.state().company.cashCents;
  const releaseFans = stillBuilding.journey.state().company.reputation;
  stillBuilding.tycoon.tickDay(releaseDay);
  stillBuilding.tycoon.tickDay(releaseDay);
  stillBuilding.endDay(releaseDay);
  stillBuilding.endDay(releaseDay);
  assert.equal(stillBuilding.clockState().day, releaseDay + 1);
  assert.equal(stillBuilding.journey.state().company.cashCents, releaseCents);
  assert.equal(stillBuilding.tycoon.view().history[0]?.salesCents, releaseCents);
  assert.equal(stillBuilding.journey.state().company.reputation, releaseFans);
  assert.equal(JSON.parse(staffJson(stillBuilding, "p1")).featureDemand, true);

  const dayOne = featureSale(stillBuilding, "p1", 1, releaseFans, releaseDay + 1);
  stillBuilding.endDay(releaseDay + 1);
  assert.equal(stillBuilding.tycoon.view().history[0]?.salesCents, releaseCents + dayOne.cents);
  assert.equal(stillBuilding.journey.state().company.reputation, releaseFans + dayOne.fans);
  const fansAfterDayOne = releaseFans + dayOne.fans;
  const dayTwo = featureSale(stillBuilding, "p1", 2, fansAfterDayOne, releaseDay + 2);
  stillBuilding.endDay(releaseDay + 2);
  const fansAfterDayTwo = fansAfterDayOne + dayTwo.fans;
  const dayThree = featureSale(stillBuilding, "p1", 3, fansAfterDayTwo, releaseDay + 3);
  stillBuilding.endDay(releaseDay + 3);
  const windowCents = releaseCents + dayOne.cents + dayTwo.cents + dayThree.cents;
  const windowFans = fansAfterDayTwo + dayThree.fans;
  assert.equal(stillBuilding.tycoon.view().history[0]?.status, "complete");
  assert.equal(stillBuilding.tycoon.view().history[0]?.salesDays, 4);
  assert.equal(stillBuilding.tycoon.view().history[0]?.salesCents, windowCents);
  assert.equal(stillBuilding.journey.state().company.reputation, windowFans);
  assert.equal(stillBuilding.clockState().day, releaseDay + 4);

  const beforePort = stillBuilding.journey.state().company.cashCents;
  const portDay = stillBuilding.clockState().day;
  stillBuilding.tycoon.port("p1");
  assert.equal(stillBuilding.journey.state().company.cashCents, beforePort - PORT_COST_CENTS);
  assert.equal(stillBuilding.journey.state().company.reputation, windowFans);
  const portSale = featureSale(stillBuilding, "p1", SALES_WINDOW_DAYS, windowFans, portDay);
  stillBuilding.endDay(portDay);
  stillBuilding.endDay(portDay);
  const shipped = productById(stillBuilding, "p1");
  assert.equal(shipped?.port?.cents, portSale.cents);
  assert.equal(shipped?.port?.fans, portSale.fans);
  assert.equal(shipped?.salesCents, windowCents + portSale.cents);
  assert.equal(stillBuilding.journey.state().company.cashCents, beforePort - PORT_COST_CENTS + portSale.cents);
  assert.equal(stillBuilding.journey.state().company.reputation, windowFans + portSale.fans);
  assert.equal(stillBuilding.clockState().day, portDay + 1);

  const afterPortCash = stillBuilding.journey.state().company.cashCents;
  const afterPortFans = stillBuilding.journey.state().company.reputation;
  const localizeDay = stillBuilding.clockState().day;
  stillBuilding.tycoon.localize("p1");
  assert.equal(stillBuilding.journey.state().company.cashCents, afterPortCash - LOCALIZE_COST_CENTS);
  assert.equal(stillBuilding.journey.state().company.reputation, afterPortFans);
  const localized = featureSale(stillBuilding, "p1", SALES_WINDOW_DAYS, afterPortFans, localizeDay, { quietPercent: LOCALIZE_UNIT_PERCENT });
  stillBuilding.endDay(localizeDay);
  stillBuilding.endDay(localizeDay);
  const translated = productById(stillBuilding, "p1");
  assert.equal(translated?.localization?.cents, localized.cents);
  assert.equal(translated?.localization?.fans, localized.fans);
  assert.equal(translated?.salesCents, windowCents + portSale.cents + localized.cents);
  assert.equal(stillBuilding.journey.state().company.cashCents, afterPortCash - LOCALIZE_COST_CENTS + localized.cents);
  assert.equal(JSON.parse(staffJson(stillBuilding, "p1")).featureDemand, true);
  assert.deepEqual(translated?.feature, added);
  const savedCents = stillBuilding.journey.state().company.cashCents;
  const savedSales = translated?.salesCents;
  const savedFile = join(root, "game.sqlite");
  const savedProject = join(root, "company-project");
  stillBuilding.close();
  const reopened = new GameDatabase(savedFile, savedProject);
  assert.equal(reopened.journey.state().company.cashCents, savedCents);
  assert.equal(productById(reopened, "p1")?.salesCents, savedSales);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).featureDemand, true);
  assert.deepEqual(productById(reopened, "p1")?.feature, added);
  reopened.endDay(localizeDay);
  assert.equal(reopened.journey.state().company.cashCents, savedCents);
  assert.equal(productById(reopened, "p1")?.salesCents, savedSales);
  assert.throws(() => reopened.tycoon.addFeature(), /No product is on the bench\./u);
  reopened.tycoon.start("fitness", "newsletter", []);
  assert.deepEqual(reopened.tycoon.view().developing?.feature, offer);
  assert.equal(reopened.tycoon.view().developing?.devDaysRequired, 2);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).feature, undefined);
  reopened.tycoon.addFeature();
  assert.equal(reopened.tycoon.view().developing?.devDaysRequired, 3);
  assert.deepEqual(reopened.tycoon.view().developing?.feature, added);
  assert.deepEqual(productById(reopened, "p1")?.feature, added);
  assert.equal(productById(reopened, "p1")?.salesCents, savedSales);
  assert.throws(() => reopened.tycoon.addFeature(), /Already added\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const sequel = await setup();
  sequel.db.tycoon.start("crypto", "newsletter", []);
  sequel.db.tycoon.addFeature();
  sequel.db.endDay(1);
  sequel.db.endDay(2);
  sequel.db.endDay(3);
  sequel.db.tycoon.release("p1");
  const sequelReleaseDay = sequel.db.clockState().day;
  sequel.db.endDay(sequelReleaseDay);
  sequel.db.endDay(sequelReleaseDay + 1);
  sequel.db.endDay(sequelReleaseDay + 2);
  sequel.db.endDay(sequelReleaseDay + 3);
  assert.equal(sequel.db.tycoon.view().history[0]?.status, "complete");
  sequel.db.tycoon.sequel("p1");
  const follow = sequel.db.tycoon.view().developing;
  assert.equal(follow?.name, "Crypto Alpha Newsletter 2");
  assert.equal(follow?.devDaysRequired, 1);
  assert.deepEqual(follow?.feature, offer);
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).feature, undefined);
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).featureDemand, undefined);
  assert.deepEqual(productById(sequel.db, "p1")?.feature, added);
  assert.equal(JSON.parse(staffJson(sequel.db, "p1")).featureDemand, true);
  sequel.db.tycoon.addFeature();
  assert.equal(sequel.db.tycoon.view().developing?.devDaysRequired, 2);
  assert.deepEqual(sequel.db.tycoon.view().developing?.feature, added);
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).feature, true);
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).featureDemand, undefined);
  assert.throws(() => sequel.db.tycoon.addFeature(), /Already added\./u);
  assert.equal(sequel.db.tycoon.view().developing?.devDays, 0);
  sequel.db.close();

  const late = await setup();
  late.db.tycoon.start("crypto", "newsletter", []);
  late.db.endDay(1);
  late.db.endDay(2);
  assert.equal(late.db.tycoon.view().developing?.ready, true);
  assert.equal(late.db.tycoon.view().developing?.devDays, 2);
  const lateCash = late.db.journey.state().company.cashCents;
  late.db.tycoon.addFeature();
  assert.equal(late.db.clockState().day, 3);
  assert.equal(late.db.journey.state().company.cashCents, lateCash);
  assert.equal(late.db.tycoon.view().developing?.devDays, 2);
  assert.equal(late.db.tycoon.view().developing?.devDaysRequired, 3);
  assert.equal(late.db.tycoon.view().developing?.ready, false);
  assert.throws(() => late.db.tycoon.release("p1"), /needs 1 more office day/u);
  assert.equal(late.db.tycoon.view().developing?.devDays, 2);
  late.db.close();
});

test("a day plan folds personal craft and leaves the even newsletter alone", async () => {
  assert.deepEqual(DAY_PLANS.map((item) => item.id), ["even", "design", "tech", "hype"]);
  assert.deepEqual(personalForDayPlan({ design: 2, tech: 2, hype: 2 }, null), { design: 2, tech: 2, hype: 2 });
  assert.deepEqual(personalForDayPlan({ design: 2, tech: 2, hype: 2 }, "design"), { design: 6, tech: 0, hype: 0 });
  assert.deepEqual(personalForDayPlan({ design: 3, tech: 2, hype: 1 }, "tech"), { design: 0, tech: 6, hype: 0 });
  assert.deepEqual(personalForDayPlan({ design: 5, tech: 4, hype: 3 }, "hype"), { design: 0, tech: 0, hype: 12 });
  assert.equal(parseRequest({ kind: "request", id: "day-plan", method: "tycoon.setDayPlan", params: { stat: "design" } }).method, "tycoon.setDayPlan");
  assert.throws(() => parseRequest({ kind: "request", id: "day-plan", method: "tycoon.setDayPlan", params: {} }), /Invalid protocol request/u);
  assert.throws(() => parseRequest({ kind: "request", id: "day-plan", method: "tycoon.setDayPlan", params: { stat: "balanced" } }), /Invalid protocol request/u);
  assert.throws(() => parseRequest({ kind: "request", id: "day-plan", method: "tycoon.setDayPlan", params: { stat: "design", extra: true } }), /Invalid protocol request/u);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const designPlan = { id: "design", label: "Design", stat: "design" };
  const techPlan = { id: "tech", label: "Tech", stat: "tech" };
  const hypePlan = { id: "hype", label: "Hype", stat: "hype" };

  const bare = await setup();
  assert.deepEqual(bare.db.tycoon.view().dayPlanOptions, [...DAY_PLANS]);
  assert.throws(() => bare.db.tycoon.setDayPlan("design"), /No product is on the bench\./u);
  assert.throws(() => bare.db.tycoon.setDayPlan("balanced"), /Pick Even, Design, Tech, or Hype\./u);
  assert.equal(bare.db.tycoon.view().developing, null);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  const fresh = staffJson(skip.db, "p1");
  assert.equal(skip.db.tycoon.view().developing?.dayPlan, null);
  assert.equal(JSON.parse(fresh).dayPlan, undefined);
  assert.equal(staffJson(skip.db, "p1"), fresh);
  skip.db.tycoon.setDayPlan("even");
  assert.equal(staffJson(skip.db, "p1"), fresh);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.dayPlan, null);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).dayPlan, undefined);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.throws(() => skip.db.tycoon.setDayPlan("hype"), /No product is on the bench\./u);
  assert.equal(dayPlanRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const fold = await setup();
  fold.db.tycoon.start("crypto", "newsletter", []);
  const beforeSet = staffJson(fold.db, "p1");
  assert.throws(() => fold.db.tycoon.setDayPlan("nope"), /Pick Even, Design, Tech, or Hype\./u);
  assert.equal(staffJson(fold.db, "p1"), beforeSet);
  const cash = fold.db.journey.state().company.cashCents;
  const tx = txCount(fold.db);
  fold.db.tycoon.setDayPlan("design");
  assert.equal(fold.db.clockState().day, 1);
  assert.equal(fold.db.journey.state().company.cashCents, cash);
  assert.equal(txCount(fold.db), tx);
  assert.equal(dayPlanRows(fold.db).length, 0);
  assert.deepEqual(fold.db.tycoon.view().developing?.dayPlan, designPlan);
  assert.equal(JSON.parse(staffJson(fold.db, "p1")).dayPlan, "design");
  const stored = staffJson(fold.db, "p1");
  fold.db.tycoon.setDayPlan("design");
  assert.equal(staffJson(fold.db, "p1"), stored);
  fold.db.tycoon.view();
  assert.equal(staffJson(fold.db, "p1"), stored);
  fold.db.endDay(1);
  assert.equal(fold.db.tycoon.view().developing?.design, 6);
  assert.equal(fold.db.tycoon.view().developing?.tech, 0);
  assert.equal(fold.db.tycoon.view().developing?.hype, 0);
  fold.db.tycoon.setDayPlan("tech");
  assert.deepEqual(fold.db.tycoon.view().developing?.dayPlan, techPlan);
  fold.db.endDay(2);
  assert.equal(fold.db.tycoon.view().developing?.design, 6);
  assert.equal(fold.db.tycoon.view().developing?.tech, 6);
  assert.equal(fold.db.tycoon.view().developing?.hype, 0);
  fold.db.tycoon.setDayPlan("hype");
  assert.deepEqual(fold.db.tycoon.view().developing?.dayPlan, hypePlan);
  fold.db.endDay(3);
  assert.equal(fold.db.tycoon.view().developing?.design, 6);
  assert.equal(fold.db.tycoon.view().developing?.tech, 6);
  assert.equal(fold.db.tycoon.view().developing?.hype, 6);
  fold.db.tycoon.setDayPlan("even");
  assert.equal(fold.db.tycoon.view().developing?.dayPlan, null);
  assert.equal(JSON.parse(staffJson(fold.db, "p1")).dayPlan, undefined);
  fold.db.endDay(4);
  assert.equal(fold.db.tycoon.view().developing?.design, 8);
  assert.equal(fold.db.tycoon.view().developing?.tech, 8);
  assert.equal(fold.db.tycoon.view().developing?.hype, 8);
  assert.equal(validate(fold.db.journey.state()), true, JSON.stringify(validate.errors));
  fold.db.close();

  const opened = await setup();
  const tools = await teamOfThree(opened.root, opened.db, 250_000);
  tools.tycoon.expandOffice();
  tools.tycoon.buyUpgrade("standing_desk");
  tools.tycoon.buyUpgrade("second_monitor");
  tools.tycoon.buyUpgrade("ring_light");
  tools.tycoon.start("crypto", "newsletter", ["founder"]);
  tools.tycoon.setDayPlan("design");
  tools.endDay(1);
  assert.equal(tools.tycoon.view().developing?.design, 8, "personal 6 plus the desk and the office");
  assert.equal(tools.tycoon.view().developing?.tech, 2, "the monitor and the office stay on tech");
  assert.equal(tools.tycoon.view().developing?.hype, 1, "the ring light stays on hype");
  tools.tycoon.setDayPlan("tech");
  tools.endDay(2);
  assert.equal(tools.tycoon.view().developing?.design, 8 + 2);
  assert.equal(tools.tycoon.view().developing?.tech, 2 + 8);
  assert.equal(tools.tycoon.view().developing?.hype, 1 + 1);
  tools.tycoon.setDayPlan("hype");
  tools.endDay(3);
  assert.equal(tools.tycoon.view().developing?.design, 12);
  assert.equal(tools.tycoon.view().developing?.tech, 12);
  assert.equal(tools.tycoon.view().developing?.hype, 9);
  tools.close();

  const plainOffice = await setup();
  const plain = await teamOfThree(plainOffice.root, plainOffice.db, 250_000);
  plain.tycoon.expandOffice();
  plain.tycoon.buyUpgrade("standing_desk");
  plain.tycoon.buyUpgrade("second_monitor");
  plain.tycoon.buyUpgrade("ring_light");
  plain.tycoon.start("crypto", "newsletter", ["founder"]);
  plain.endDay(1);
  assert.equal(plain.tycoon.view().developing?.design, 4);
  assert.equal(plain.tycoon.view().developing?.tech, 4);
  assert.equal(plain.tycoon.view().developing?.hype, 3);
  assert.equal(JSON.parse(staffJson(plain, "p1")).dayPlan, undefined);
  plain.close();

  const trained = await setup();
  trained.db.journey.recordCompanyChange("dayplan-train-cash", 1, 40_000, 0, 0, "Day plan train cash");
  trained.db.journey.hire("mira", 1);
  trained.db.tycoon.start("crypto", "newsletter", ["mira"]);
  trained.db.tycoon.setDayPlan("design");
  trained.db.tycoon.train("founder", "tech");
  trained.db.endDay(1);
  assert.equal(trained.db.tycoon.view().developing?.design, 6, "Mina's 3/2/1 lands on design; the founder is in training");
  assert.equal(trained.db.tycoon.view().developing?.tech, 0);
  assert.equal(trained.db.tycoon.view().developing?.hype, 0);
  trained.db.endDay(2);
  assert.equal(trained.db.tycoon.view().developing?.design, 18);
  trained.db.close();

  const polish = await setup();
  polish.db.tycoon.start("crypto", "newsletter", []);
  for (let day = 1; day <= 4; day += 1) polish.db.endDay(day);
  assert.equal(polish.db.tycoon.view().developing?.design, 8);
  polish.db.tycoon.setDayPlan("design");
  polish.db.endDay(5);
  assert.equal(polish.db.tycoon.view().developing?.devDays, 5);
  assert.equal(polish.db.tycoon.view().developing?.design, 8);
  assert.equal(polish.db.tycoon.view().developing?.tech, 8);
  assert.equal(polish.db.tycoon.view().developing?.hype, 8);
  polish.db.close();

  const emphasized = await setup();
  emphasized.db.tycoon.start("crypto", "newsletter", []);
  emphasized.db.tycoon.setDayPlan("hype");
  for (let day = 1; day <= 5; day += 1) emphasized.db.endDay(day);
  assert.equal(emphasized.db.tycoon.view().developing?.design, 0);
  assert.equal(emphasized.db.tycoon.view().developing?.tech, 0);
  assert.equal(emphasized.db.tycoon.view().developing?.hype, 24);
  assert.equal(emphasized.db.tycoon.view().developing?.devDays, 5);
  emphasized.db.close();

  const kept = await setup();
  kept.db.tycoon.start("crypto", "newsletter", []);
  kept.db.tycoon.setDayPlan("tech");
  const keptFile = join(kept.root, "game.sqlite");
  const keptProject = join(kept.root, "company-project");
  const keptJson = staffJson(kept.db, "p1");
  kept.db.close();
  const reopened = new GameDatabase(keptFile, keptProject);
  assert.equal(staffJson(reopened, "p1"), keptJson);
  assert.deepEqual(reopened.tycoon.view().developing?.dayPlan, techPlan);
  reopened.tycoon.setDayPlan("tech");
  assert.equal(staffJson(reopened, "p1"), keptJson);
  reopened.endDay(1);
  assert.equal(reopened.tycoon.view().developing?.design, 0);
  assert.equal(reopened.tycoon.view().developing?.tech, 6);
  assert.equal(reopened.tycoon.view().developing?.hype, 0);
  assert.throws(() => reopened.tycoon.release("p1"), /needs 1 more office day/u);
  reopened.endDay(2);
  reopened.tycoon.release("p1");
  assert.equal(reopened.tycoon.view().history[0]?.dayPlan, null);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).dayPlan, "tech");
  finishSales(reopened);
  reopened.tycoon.sequel("p1");
  assert.equal(reopened.tycoon.view().developing?.dayPlan, null);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).dayPlan, undefined);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).dayPlan, "tech");
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();
});

test("bugs track imbalance, lower the release, and clear with tomorrow's craft", async () => {
  assert.equal(bugCount({ design: 4, tech: 4, hype: 4 }), 0);
  assert.equal(bugCount({ design: 12, tech: 0, hype: 0 }), 3);
  assert.equal(bugCount({ design: 6, tech: 0, hype: 0 }), 1);
  assert.equal(bugCount({ design: 20, tech: 0, hype: 0 }), 5);
  assert.equal(bugsClearedGain(0), 0);
  assert.equal(bugsClearedGain(2), 1);
  assert.equal(bugsClearedGain(6), 1);
  assert.equal(bugsClearedGain(8), 2);
  assert.equal(parseRequest({ kind: "request", id: "bugs", method: "tycoon.fixBugs", params: {} }).method, "tycoon.fixBugs");
  assert.throws(() => parseRequest({ kind: "request", id: "bugs", method: "tycoon.fixBugs", params: { extra: true } }), /Invalid protocol request/u);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.fixBugs(), /No product is on the bench\./u);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.bugs, { count: 0, cleared: 0, fixing: false });
  assert.throws(() => skip.db.tycoon.fixBugs(), /No bugs to fix\./u);
  const fresh = staffJson(skip.db, "p1");
  assert.equal(JSON.parse(fresh).bugs, undefined);
  assert.equal(JSON.parse(fresh).bugsCleared, undefined);
  assert.equal(JSON.parse(fresh).fixBugs, undefined);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.bugs, null);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).bugs, undefined);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.throws(() => skip.db.tycoon.fixBugs(), /No product is on the bench\./u);
  assert.equal(bugRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const even = await setup();
  even.db.tycoon.start("crypto", "newsletter", []);
  even.db.endDay(1);
  even.db.endDay(2);
  even.db.tycoon.release("p1");
  const evenCash = even.db.journey.state().company.cashCents;
  const evenScore = even.db.tycoon.view().history[0]?.review?.score ?? 0;
  even.db.close();

  const lop = await setup();
  lop.db.tycoon.start("crypto", "newsletter", []);
  lop.db.tycoon.setDayPlan("design");
  lop.db.endDay(1);
  assert.deepEqual(lop.db.tycoon.view().developing?.bugs, { count: 1, cleared: 0, fixing: false });
  assert.equal(lop.db.tycoon.view().developing?.design, 6);
  assert.equal(lop.db.tycoon.view().developing?.tech, 0);
  assert.equal(lop.db.tycoon.view().developing?.hype, 0);
  lop.db.endDay(2);
  assert.deepEqual(lop.db.tycoon.view().developing?.bugs, { count: 3, cleared: 0, fixing: false });
  assert.equal(lop.db.tycoon.view().developing?.design, 12);
  const cashBefore = lop.db.journey.state().company.cashCents;
  const tx = txCount(lop.db);
  lop.db.tycoon.fixBugs();
  assert.equal(lop.db.clockState().day, 3);
  assert.equal(lop.db.journey.state().company.cashCents, cashBefore);
  assert.equal(txCount(lop.db), tx);
  assert.equal(bugRows(lop.db).length, 0);
  assert.deepEqual(lop.db.tycoon.view().developing?.bugs, { count: 3, cleared: 0, fixing: true });
  assert.equal(JSON.parse(staffJson(lop.db, "p1")).fixBugs, true);
  const armed = staffJson(lop.db, "p1");
  lop.db.tycoon.fixBugs();
  assert.equal(staffJson(lop.db, "p1"), armed);
  lop.db.tycoon.view();
  assert.equal(staffJson(lop.db, "p1"), armed);
  // Day plan stays set but the fix day ignores it for personal craft.
  lop.db.endDay(3);
  assert.equal(lop.db.tycoon.view().developing?.design, 12, "fix day adds no personal craft");
  assert.equal(lop.db.tycoon.view().developing?.tech, 0);
  assert.equal(lop.db.tycoon.view().developing?.hype, 0);
  assert.equal(lop.db.tycoon.view().developing?.devDays, 3);
  assert.deepEqual(lop.db.tycoon.view().developing?.bugs, { count: 2, cleared: 1, fixing: false });
  assert.equal(JSON.parse(staffJson(lop.db, "p1")).bugsCleared, 1);
  assert.equal(JSON.parse(staffJson(lop.db, "p1")).fixBugs, undefined);
  lop.db.tycoon.release("p1");
  assert.equal(JSON.parse(staffJson(lop.db, "p1")).bugs, 2);
  assert.equal(lop.db.tycoon.view().history[0]?.bugs, 2);
  assert.ok((lop.db.tycoon.view().history[0]?.review?.score ?? 0) < evenScore, "bugs lower the release score");
  assert.ok(lop.db.journey.state().company.cashCents < evenCash, "bugs lower opening cash");
  assert.equal(validate(lop.db.journey.state()), true, JSON.stringify(validate.errors));
  lop.db.close();

  const tools = await setup();
  const toolsDb = await teamOfThree(tools.root, tools.db, 250_000);
  toolsDb.tycoon.expandOffice();
  toolsDb.tycoon.buyUpgrade("standing_desk");
  toolsDb.tycoon.buyUpgrade("second_monitor");
  toolsDb.tycoon.buyUpgrade("ring_light");
  toolsDb.tycoon.start("crypto", "newsletter", ["founder"]);
  toolsDb.tycoon.setDayPlan("design");
  toolsDb.endDay(1);
  assert.equal(toolsDb.tycoon.view().developing?.design, 8);
  assert.equal(toolsDb.tycoon.view().developing?.tech, 2);
  assert.equal(toolsDb.tycoon.view().developing?.hype, 1);
  assert.deepEqual(toolsDb.tycoon.view().developing?.bugs, { count: 1, cleared: 0, fixing: false });
  toolsDb.tycoon.fixBugs();
  toolsDb.endDay(2);
  // Personal 6 clears 1; tools/office still land 2/2/1 on their own stats.
  assert.equal(toolsDb.tycoon.view().developing?.design, 8 + 2);
  assert.equal(toolsDb.tycoon.view().developing?.tech, 2 + 2);
  assert.equal(toolsDb.tycoon.view().developing?.hype, 1 + 1);
  // Points are now 10/4/2 → bugCount 2, minus 1 cleared → 1 left.
  assert.deepEqual(toolsDb.tycoon.view().developing?.bugs, { count: 1, cleared: 1, fixing: false });
  toolsDb.close();

  const polish = await setup();
  polish.db.tycoon.start("crypto", "newsletter", []);
  polish.db.tycoon.setDayPlan("design");
  for (let day = 1; day <= 4; day += 1) polish.db.endDay(day);
  assert.equal(polish.db.tycoon.view().developing?.design, 24);
  assert.deepEqual(polish.db.tycoon.view().developing?.bugs, { count: 5, cleared: 0, fixing: false });
  polish.db.tycoon.fixBugs();
  polish.db.endDay(5);
  assert.equal(polish.db.tycoon.view().developing?.devDays, 5);
  assert.equal(polish.db.tycoon.view().developing?.design, 24, "polish window clears nothing");
  assert.deepEqual(polish.db.tycoon.view().developing?.bugs, { count: 5, cleared: 0, fixing: false });
  assert.equal(JSON.parse(staffJson(polish.db, "p1")).fixBugs, undefined);
  polish.db.close();

  const priority = await setup();
  priority.db.tycoon.start("crypto", "newsletter", []);
  priority.db.tycoon.setDayPlan("design");
  priority.db.endDay(1);
  priority.db.tycoon.fixBugs();
  // Setting day plan again does not clear the armed fix.
  priority.db.tycoon.setDayPlan("hype");
  priority.db.endDay(2);
  assert.equal(priority.db.tycoon.view().developing?.design, 6);
  assert.equal(priority.db.tycoon.view().developing?.tech, 0);
  assert.equal(priority.db.tycoon.view().developing?.hype, 0);
  assert.deepEqual(priority.db.tycoon.view().developing?.bugs, { count: 0, cleared: 1, fixing: false });
  priority.db.close();

  const kept = await setup();
  kept.db.tycoon.start("crypto", "newsletter", []);
  kept.db.tycoon.setDayPlan("design");
  kept.db.endDay(1);
  kept.db.endDay(2);
  kept.db.tycoon.fixBugs();
  kept.db.endDay(3);
  assert.equal(JSON.parse(staffJson(kept.db, "p1")).bugsCleared, 1);
  const keptFile = join(kept.root, "game.sqlite");
  const keptProject = join(kept.root, "company-project");
  const keptJson = staffJson(kept.db, "p1");
  kept.db.close();
  const reopened = new GameDatabase(keptFile, keptProject);
  assert.equal(staffJson(reopened, "p1"), keptJson);
  assert.deepEqual(reopened.tycoon.view().developing?.bugs, { count: 2, cleared: 1, fixing: false });
  reopened.tycoon.release("p1");
  assert.equal(JSON.parse(staffJson(reopened, "p1")).bugs, 2);
  assert.equal(reopened.tycoon.view().history[0]?.bugs, 2);
  finishSales(reopened);
  reopened.tycoon.sequel("p1");
  assert.deepEqual(reopened.tycoon.view().developing?.bugs, { count: 0, cleared: 0, fixing: false });
  assert.equal(JSON.parse(staffJson(reopened, "p2")).bugs, undefined);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).bugsCleared, undefined);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).fixBugs, undefined);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).bugs, 2);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).bugsCleared, 1);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();
});

test("crunch doubles the next personal craft, then rests and adds a bug", async () => {
  assert.equal(liveBugs({ design: 4, tech: 4, hype: 4 }, 0, 0), 0);
  assert.equal(liveBugs({ design: 4, tech: 4, hype: 4 }, 1, 0), 1);
  assert.equal(liveBugs({ design: 12, tech: 0, hype: 0 }, 1, 3), 1);
  assert.equal(liveBugs({ design: 20, tech: 0, hype: 0 }, 3, 0), 5);
  assert.equal(parseRequest({ kind: "request", id: "crunch", method: "tycoon.crunch", params: {} }).method, "tycoon.crunch");
  assert.throws(() => parseRequest({ kind: "request", id: "crunch", method: "tycoon.crunch", params: { extra: true } }), /Invalid protocol request/u);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.crunch(), /No product is on the bench\./u);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.crunch, { state: "idle" });
  const fresh = staffJson(skip.db, "p1");
  assert.equal(JSON.parse(fresh).crunch, undefined);
  assert.equal(JSON.parse(fresh).crunchBugs, undefined);
  skip.db.tycoon.view();
  assert.equal(staffJson(skip.db, "p1"), fresh);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.crunch, null);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).crunch, undefined);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).crunchBugs, undefined);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.throws(() => skip.db.tycoon.crunch(), /No product is on the bench\./u);
  assert.equal(crunchRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const even = await setup();
  even.db.tycoon.start("crypto", "newsletter", []);
  even.db.endDay(1);
  even.db.endDay(2);
  even.db.tycoon.release("p1");
  const evenCash = even.db.journey.state().company.cashCents;
  const evenScore = even.db.tycoon.view().history[0]?.review?.score ?? 0;
  even.db.close();

  const early = await setup();
  early.db.tycoon.start("crypto", "newsletter", []);
  const earlyCash = early.db.journey.state().company.cashCents;
  const earlyTx = txCount(early.db);
  early.db.tycoon.crunch();
  assert.equal(early.db.clockState().day, 1);
  assert.equal(early.db.journey.state().company.cashCents, earlyCash);
  assert.equal(txCount(early.db), earlyTx);
  assert.equal(crunchRows(early.db).length, 0);
  assert.deepEqual(early.db.tycoon.view().developing?.crunch, { state: "armed" });
  assert.equal(JSON.parse(staffJson(early.db, "p1")).crunch, "armed");
  const armed = staffJson(early.db, "p1");
  early.db.tycoon.crunch();
  early.db.tycoon.view();
  assert.equal(staffJson(early.db, "p1"), armed);
  early.db.endDay(1);
  assert.equal(early.db.tycoon.view().developing?.design, 4);
  assert.equal(early.db.tycoon.view().developing?.tech, 4);
  assert.equal(early.db.tycoon.view().developing?.hype, 4);
  assert.equal(early.db.tycoon.view().developing?.devDays, 1);
  assert.equal(early.db.tycoon.view().researchPoints, 1);
  assert.deepEqual(early.db.tycoon.view().developing?.crunch, { state: "resting" });
  assert.equal(JSON.parse(staffJson(early.db, "p1")).crunchBugs, 1);
  assert.deepEqual(early.db.tycoon.view().developing?.bugs, { count: 1, cleared: 0, fixing: false });
  const resting = staffJson(early.db, "p1");
  assert.throws(() => early.db.tycoon.crunch(), /The team is still tired\./u);
  assert.equal(staffJson(early.db, "p1"), resting);
  early.db.tycoon.fixBugs();
  early.db.endDay(2);
  // Rest zeroes personal before the fix, so the armed fix clears nothing.
  assert.equal(early.db.tycoon.view().developing?.design, 4);
  assert.equal(early.db.tycoon.view().developing?.tech, 4);
  assert.equal(early.db.tycoon.view().developing?.hype, 4);
  assert.equal(early.db.tycoon.view().developing?.devDays, 2);
  assert.equal(early.db.tycoon.view().researchPoints, 2);
  assert.deepEqual(early.db.tycoon.view().developing?.crunch, { state: "idle" });
  assert.equal(JSON.parse(staffJson(early.db, "p1")).crunch, undefined);
  assert.equal(JSON.parse(staffJson(early.db, "p1")).crunchBugs, 1);
  assert.equal(JSON.parse(staffJson(early.db, "p1")).fixBugs, undefined);
  assert.equal(JSON.parse(staffJson(early.db, "p1")).bugsCleared, undefined);
  assert.deepEqual(early.db.tycoon.view().developing?.bugs, { count: 1, cleared: 0, fixing: false });
  early.db.tycoon.release("p1");
  assert.equal(JSON.parse(staffJson(early.db, "p1")).bugs, 1);
  assert.equal(early.db.tycoon.view().history[0]?.bugs, 1);
  assert.ok((early.db.tycoon.view().history[0]?.review?.score ?? 0) < evenScore, "crunch bugs lower the release score");
  assert.ok(early.db.journey.state().company.cashCents < evenCash, "crunch bugs lower opening cash");
  assert.equal(validate(early.db.journey.state()), true, JSON.stringify(validate.errors));
  early.db.close();

  const tools = await setup();
  const toolsDb = await teamOfThree(tools.root, tools.db, 250_000);
  toolsDb.tycoon.expandOffice();
  toolsDb.tycoon.buyUpgrade("standing_desk");
  toolsDb.tycoon.buyUpgrade("second_monitor");
  toolsDb.tycoon.buyUpgrade("ring_light");
  toolsDb.tycoon.start("crypto", "newsletter", ["founder"]);
  toolsDb.tycoon.setDayPlan("design");
  toolsDb.tycoon.crunch();
  toolsDb.endDay(1);
  // Personal 6 doubled onto design is 12. Tools stay 1/1/1 and the Open Floor stays 1/1/0.
  assert.equal(toolsDb.tycoon.view().developing?.design, 14);
  assert.equal(toolsDb.tycoon.view().developing?.tech, 2);
  assert.equal(toolsDb.tycoon.view().developing?.hype, 1);
  assert.equal(toolsDb.tycoon.view().researchPoints, 1);
  assert.deepEqual(toolsDb.tycoon.view().developing?.crunch, { state: "resting" });
  toolsDb.endDay(2);
  assert.equal(toolsDb.tycoon.view().developing?.design, 16);
  assert.equal(toolsDb.tycoon.view().developing?.tech, 4);
  assert.equal(toolsDb.tycoon.view().developing?.hype, 2);
  assert.equal(toolsDb.tycoon.view().developing?.devDays, 2);
  assert.equal(toolsDb.tycoon.view().researchPoints, 2);
  assert.deepEqual(toolsDb.tycoon.view().developing?.crunch, { state: "idle" });
  assert.equal(JSON.parse(staffJson(toolsDb, "p1")).crunch, undefined);
  assert.equal(JSON.parse(staffJson(toolsDb, "p1")).crunchBugs, 1);
  toolsDb.close();

  const polish = await setup();
  polish.db.tycoon.start("crypto", "newsletter", []);
  for (let day = 1; day <= 4; day += 1) polish.db.endDay(day);
  assert.equal(polish.db.tycoon.view().developing?.design, 8);
  assert.equal(polish.db.tycoon.view().developing?.devDays, 4);
  assert.deepEqual(polish.db.tycoon.view().developing?.bugs, { count: 0, cleared: 0, fixing: false });
  polish.db.tycoon.crunch();
  polish.db.endDay(5);
  assert.equal(polish.db.tycoon.view().developing?.design, 8, "a polish-window crunch adds no craft");
  assert.equal(polish.db.tycoon.view().developing?.tech, 8);
  assert.equal(polish.db.tycoon.view().developing?.hype, 8);
  assert.equal(polish.db.tycoon.view().developing?.devDays, 5);
  assert.equal(polish.db.tycoon.view().researchPoints, 5);
  assert.deepEqual(polish.db.tycoon.view().developing?.crunch, { state: "resting" });
  assert.equal(JSON.parse(staffJson(polish.db, "p1")).crunchBugs, 1);
  assert.deepEqual(polish.db.tycoon.view().developing?.bugs, { count: 1, cleared: 0, fixing: false });
  polish.db.close();

  const both = await setup();
  both.db.tycoon.start("crypto", "newsletter", []);
  both.db.tycoon.setDayPlan("design");
  both.db.endDay(1);
  assert.deepEqual(both.db.tycoon.view().developing?.bugs, { count: 1, cleared: 0, fixing: false });
  both.db.tycoon.crunch();
  both.db.tycoon.fixBugs();
  both.db.endDay(2);
  assert.equal(both.db.tycoon.view().developing?.design, 6, "fix day adds no personal craft");
  assert.equal(both.db.tycoon.view().developing?.tech, 0);
  assert.equal(both.db.tycoon.view().developing?.hype, 0);
  assert.equal(JSON.parse(staffJson(both.db, "p1")).bugsCleared, 3, "the clear uses the doubled total");
  assert.equal(JSON.parse(staffJson(both.db, "p1")).crunch, "resting");
  assert.equal(JSON.parse(staffJson(both.db, "p1")).crunchBugs, 1);
  assert.equal(JSON.parse(staffJson(both.db, "p1")).fixBugs, undefined);
  assert.deepEqual(both.db.tycoon.view().developing?.bugs, { count: 0, cleared: 3, fixing: false });
  assert.deepEqual(both.db.tycoon.view().developing?.crunch, { state: "resting" });
  both.db.close();

  const kept = await setup();
  kept.db.tycoon.start("crypto", "newsletter", []);
  kept.db.tycoon.crunch();
  const keptFile = join(kept.root, "game.sqlite");
  const keptProject = join(kept.root, "company-project");
  const keptJson = staffJson(kept.db, "p1");
  kept.db.close();
  const reopened = new GameDatabase(keptFile, keptProject);
  assert.equal(staffJson(reopened, "p1"), keptJson);
  assert.deepEqual(reopened.tycoon.view().developing?.crunch, { state: "armed" });
  reopened.tycoon.view();
  assert.equal(staffJson(reopened, "p1"), keptJson);
  reopened.endDay(1);
  assert.deepEqual(reopened.tycoon.view().developing?.crunch, { state: "resting" });
  assert.equal(JSON.parse(staffJson(reopened, "p1")).crunchBugs, 1);
  const restedJson = staffJson(reopened, "p1");
  reopened.close();
  const again = new GameDatabase(keptFile, keptProject);
  assert.equal(staffJson(again, "p1"), restedJson);
  assert.deepEqual(again.tycoon.view().developing?.crunch, { state: "resting" });
  again.endDay(2);
  again.tycoon.release("p1");
  finishSales(again);
  again.tycoon.sequel("p1");
  assert.deepEqual(again.tycoon.view().developing?.crunch, { state: "idle" });
  assert.equal(JSON.parse(staffJson(again, "p2")).crunch, undefined);
  assert.equal(JSON.parse(staffJson(again, "p2")).crunchBugs, undefined);
  assert.equal(JSON.parse(staffJson(again, "p1")).crunchBugs, 1);
  assert.equal(JSON.parse(staffJson(again, "p1")).crunch, undefined);
  assert.equal(validate(again.journey.state()), true, JSON.stringify(validate.errors));
  again.close();
});

test("early access ships a short build, stores a capped score penalty, and starts sales", async () => {
  assert.equal(EARLY_ACCESS_PENALTY_CAP, 3);
  assert.equal(earlyAccessPenalty(0), 0);
  assert.equal(earlyAccessPenalty(1), 1);
  assert.equal(earlyAccessPenalty(3), 3);
  assert.equal(earlyAccessPenalty(4), 3);
  assert.equal(earlyAccessPenalty(9), 3);
  const rich = { seed: 26021, productId: "p1", topicId: "crypto" as const, typeId: "newsletter" as const, design: 40, tech: 40, hype: 40, devDays: 2 };
  const plainRich = reviewProduct(rich);
  const cutRich = reviewProduct({ ...rich, earlyPenalty: 4 });
  assert.equal(cutRich.score, plainRich.score - 3, "four missing days cap at −3");
  assert.ok(cutRich.reviewers.every((reviewer) => reviewer.score >= 1 && reviewer.score <= 10));
  const floored = reviewProduct({ ...rich, design: 0, tech: 0, hype: 0, earlyPenalty: 3 });
  const flooredPlain = reviewProduct({ ...rich, design: 0, tech: 0, hype: 0 });
  assert.ok(floored.score >= 1 && floored.score <= flooredPlain.score);
  assert.ok(floored.reviewers.every((reviewer) => reviewer.score >= 1));
  assert.equal(parseRequest({ kind: "request", id: "early", method: "tycoon.earlyAccess", params: {} }).method, "tycoon.earlyAccess");
  assert.throws(() => parseRequest({ kind: "request", id: "early", method: "tycoon.earlyAccess", params: { extra: true } }), /Invalid protocol request/u);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.earlyAccess(), /No product is on the bench\./u);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.earlyAccess, {
    enabled: false, reason: "Work one office day first.", daysLeft: 2, penalty: 0,
  });
  const fresh = staffJson(skip.db, "p1");
  assert.equal(JSON.parse(fresh).earlyAccess, undefined);
  assert.equal(JSON.parse(fresh).earlyDays, undefined);
  skip.db.tycoon.view();
  assert.equal(staffJson(skip.db, "p1"), fresh);
  const freshTx = txCount(skip.db);
  assert.throws(() => skip.db.tycoon.earlyAccess(), /Work one office day first\./u);
  assert.equal(staffJson(skip.db, "p1"), fresh);
  assert.equal(txCount(skip.db), freshTx);
  assert.equal(skip.db.clockState().day, 1);
  skip.db.endDay(1);
  skip.db.endDay(2);
  assert.deepEqual(skip.db.tycoon.view().developing?.earlyAccess, {
    enabled: false, reason: "Required days are done. Use Release.", daysLeft: 0, penalty: 0,
  });
  const readyJson = staffJson(skip.db, "p1");
  assert.throws(() => skip.db.tycoon.earlyAccess(), /Required days are done\. Use Release\./u);
  assert.equal(staffJson(skip.db, "p1"), readyJson);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.earlyAccess, null);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).earlyAccess, undefined);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).earlyDays, undefined);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.throws(() => skip.db.tycoon.earlyAccess(), /No product is on the bench\./u);
  assert.equal(earlyRows(skip.db).length, 0);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const ship = await setup();
  ship.db.tycoon.start("crypto", "newsletter", []);
  ship.db.endDay(1);
  assert.equal(ship.db.tycoon.view().developing?.devDays, 1);
  assert.deepEqual(ship.db.tycoon.view().developing?.earlyAccess, {
    enabled: true, reason: "", daysLeft: 1, penalty: 1,
  });
  const beforeJson = staffJson(ship.db, "p1");
  ship.db.tycoon.view();
  assert.equal(staffJson(ship.db, "p1"), beforeJson);
  const day = ship.db.clockState().day;
  const tx = txCount(ship.db);
  ship.db.tycoon.earlyAccess();
  assert.equal(ship.db.clockState().day, day);
  assert.equal(ship.db.tycoon.view().developing, null);
  const shipped = ship.db.tycoon.view().history[0];
  assert.equal(shipped?.status, "released");
  assert.equal(shipped?.releasedDay, day);
  assert.equal(shipped?.salesDays, 1);
  assert.equal(JSON.parse(staffJson(ship.db, "p1")).earlyAccess, true);
  assert.equal(JSON.parse(staffJson(ship.db, "p1")).earlyDays, 1);
  assert.deepEqual(shipped?.earlyAccess, { enabled: false, reason: "", daysLeft: 0, penalty: 1 });
  const expected = reviewProduct({
    seed: ship.db.tycoon.view().seed,
    productId: "p1",
    topicId: "crypto",
    typeId: "newsletter",
    design: 2,
    tech: 2,
    hype: 2,
    devDays: 2,
    earlyPenalty: 1,
  });
  const uncut = reviewProduct({
    seed: ship.db.tycoon.view().seed,
    productId: "p1",
    topicId: "crypto",
    typeId: "newsletter",
    design: 2,
    tech: 2,
    hype: 2,
    devDays: 2,
  });
  assert.deepEqual(shipped?.review, expected);
  assert.equal(expected.score, uncut.score - 1);
  assert.ok(expected.score >= 1);
  const sale = salesForDay({
    seed: ship.db.tycoon.view().seed,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score: expected.score,
    dayIndex: 0,
    reputation: 0,
  });
  assert.equal(shipped?.salesCents, sale.cents);
  assert.equal(shipped?.fans, sale.fans);
  assert.equal(ship.db.journey.state().company.cashCents, sale.cents);
  assert.equal(ship.db.journey.state().company.reputation, sale.fans);
  assert.ok(sale.cents < 20_700);
  assert.equal(earlyRows(ship.db).length, 0);
  assert.equal(txCount(ship.db) > tx, true);
  const launchCash = ship.db.journey.state().company.cashCents;
  const stored = staffJson(ship.db, "p1");
  ship.db.tycoon.view();
  assert.equal(staffJson(ship.db, "p1"), stored);
  assert.throws(() => ship.db.tycoon.earlyAccess(), /No product is on the bench\./u);
  assert.equal(ship.db.tycoon.view().history[0]?.salesCents, launchCash);
  ship.db.endDay(day);
  assert.equal(ship.db.tycoon.view().history[0]?.salesCents, launchCash, "the release day does not sell twice");
  assert.equal(ship.db.tycoon.view().history[0]?.salesDays, 1);
  ship.db.endDay(day + 1);
  assert.equal(ship.db.tycoon.view().history[0]?.salesDays, 2);
  assert.ok((ship.db.tycoon.view().history[0]?.salesCents ?? 0) > launchCash);
  assert.equal(JSON.parse(staffJson(ship.db, "p1")).earlyDays, 1);
  assert.equal(validate(ship.db.journey.state()), true, JSON.stringify(validate.errors));
  ship.db.close();

  const deal = await setup();
  const offer = deal.db.tycoon.view().contract;
  deal.db.tycoon.acceptContract();
  deal.db.tycoon.start(offer.topicId, offer.typeId, []);
  deal.db.endDay(1);
  const dealDay = deal.db.clockState().day;
  deal.db.tycoon.earlyAccess();
  const launch = deal.db.tycoon.view().history[0];
  assert.equal(launch?.contract?.bonusCents, offer.bonusCents);
  assert.equal(deal.db.journey.state().company.cashCents, (launch?.salesCents ?? 0) + offer.bonusCents);
  assert.equal(deal.db.journey.state().company.earnedCents, (launch?.salesCents ?? 0) + offer.bonusCents);
  assert.equal(deal.db.journey.state().company.reputation, launch?.fans);
  const paid = deal.db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:contract:p1'").get() as { n: number };
  assert.equal(Number(paid.n), 1);
  assert.throws(() => deal.db.tycoon.earlyAccess(), /No product is on the bench\./u);
  deal.db.endDay(dealDay);
  deal.db.endDay(dealDay + 1);
  const paidAgain = deal.db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:contract:p1'").get() as { n: number };
  assert.equal(Number(paidAgain.n), 1);
  assert.equal(earlyRows(deal.db).length, 0);
  deal.db.close();

  const cap = await setup();
  cap.db.tycoon.start("fitness", "course", [], 100, "none", "none", "balanced", "everyone", "long");
  cap.db.tycoon.addFeature();
  assert.equal(cap.db.tycoon.view().developing?.devDaysRequired, 5);
  cap.db.endDay(1);
  assert.deepEqual(cap.db.tycoon.view().developing?.earlyAccess, {
    enabled: true, reason: "", daysLeft: 4, penalty: 3,
  });
  cap.db.tycoon.earlyAccess();
  const capped = JSON.parse(staffJson(cap.db, "p1")) as { earlyAccess?: boolean; earlyDays?: number; featureDemand?: boolean; feature?: boolean };
  assert.equal(capped.earlyAccess, true);
  assert.equal(capped.earlyDays, 4);
  assert.equal(capped.feature, true);
  assert.equal(capped.featureDemand, true);
  assert.equal(cap.db.tycoon.view().history[0]?.earlyAccess?.penalty, 3);
  const capReview = cap.db.tycoon.view().history[0]?.review;
  assert.ok(capReview && capReview.score >= 1);
  assert.ok(capReview.reviewers.every((reviewer) => reviewer.score >= 1));
  assert.deepEqual(capReview, reviewProduct({
    seed: cap.db.tycoon.view().seed,
    productId: "p1",
    topicId: "fitness",
    typeId: "course",
    design: 2,
    tech: 2,
    hype: 2,
    devDays: 5,
    earlyPenalty: 4,
  }));
  cap.db.close();

  const lop = await setup();
  lop.db.tycoon.start("crypto", "newsletter", []);
  lop.db.tycoon.setDayPlan("design");
  lop.db.endDay(1);
  lop.db.tycoon.earlyAccess();
  assert.equal(JSON.parse(staffJson(lop.db, "p1")).bugs, 1);
  assert.equal(lop.db.tycoon.view().history[0]?.bugs, 1);
  assert.deepEqual(lop.db.tycoon.view().history[0]?.review, reviewProduct({
    seed: lop.db.tycoon.view().seed,
    productId: "p1",
    topicId: "crypto",
    typeId: "newsletter",
    design: 6,
    tech: 0,
    hype: 0,
    devDays: 2,
    bugs: 1,
    earlyPenalty: 1,
  }));
  lop.db.close();

  const kept = await setup();
  kept.db.tycoon.start("crypto", "newsletter", []);
  kept.db.endDay(1);
  kept.db.tycoon.earlyAccess();
  const keptFile = join(kept.root, "game.sqlite");
  const keptProject = join(kept.root, "company-project");
  const keptJson = staffJson(kept.db, "p1");
  const keptSales = kept.db.tycoon.view().history[0]?.salesCents;
  const keptBlock = kept.db.tycoon.view().history[0]?.earlyAccess;
  kept.db.tycoon.view();
  assert.equal(staffJson(kept.db, "p1"), keptJson);
  kept.db.close();
  const reopened = new GameDatabase(keptFile, keptProject);
  assert.equal(staffJson(reopened, "p1"), keptJson);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, keptSales);
  assert.deepEqual(reopened.tycoon.view().history[0]?.earlyAccess, keptBlock);
  reopened.tycoon.view();
  assert.equal(staffJson(reopened, "p1"), keptJson);
  finishSales(reopened);
  reopened.tycoon.sequel("p1");
  assert.equal(JSON.parse(staffJson(reopened, "p2")).earlyAccess, undefined);
  assert.equal(JSON.parse(staffJson(reopened, "p2")).earlyDays, undefined);
  assert.deepEqual(reopened.tycoon.view().developing?.earlyAccess, {
    enabled: false, reason: "Work one office day first.", daysLeft: 1, penalty: 0,
  });
  assert.equal(JSON.parse(staffJson(reopened, "p1")).earlyAccess, true);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).earlyDays, 1);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();
});

test("cancel build drops the bench product without a review, a sale, or a history row", async () => {
  assert.equal(parseRequest({ kind: "request", id: "cancel", method: "tycoon.cancelBuild", params: {} }).method, "tycoon.cancelBuild");
  assert.throws(() => parseRequest({ kind: "request", id: "cancel", method: "tycoon.cancelBuild", params: { extra: true } }), /Invalid protocol request/u);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("cancelBuild():");
  const body = source.slice(bodyStart, source.indexOf("crunch():", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.cancelBuild(), /No product is on the bench\./u);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.cancel, { enabled: true, reason: "" });
  const fresh = staffJson(skip.db, "p1");
  skip.db.tycoon.view();
  assert.equal(staffJson(skip.db, "p1"), fresh);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.cancel, null);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(cancelRows(skip.db).length, 0);
  assert.throws(() => skip.db.tycoon.cancelBuild(), /No product is on the bench\./u);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const drop = await setup();
  drop.db.tycoon.start("crypto", "newsletter", []);
  drop.db.endDay(1);
  assert.equal(drop.db.tycoon.view().developing?.devDays, 1);
  assert.equal(drop.db.tycoon.view().developing?.design, 2);
  const points = drop.db.tycoon.view().researchPoints;
  const founder = drop.db.tycoon.view().staff.find((person) => person.id === "founder");
  const cash = drop.db.journey.state().company.cashCents;
  const fans = drop.db.journey.state().company.reputation;
  const day = drop.db.clockState().day;
  const before = txIds(drop.db);
  assert.equal(validate(drop.db.journey.state()), true, JSON.stringify(validate.errors));
  drop.db.tycoon.cancelBuild();
  assert.equal(drop.db.clockState().day, day);
  assert.equal(drop.db.tycoon.view().developing, null);
  assert.equal(drop.db.tycoon.view().history.length, 0);
  assert.equal(productCount(drop.db), 0);
  assert.equal(drop.db.journey.db.prepare("SELECT id FROM tycoon_products WHERE id = 'p1'").get(), undefined);
  assert.deepEqual(txIds(drop.db), before);
  assert.equal(cancelRows(drop.db).length, 0);
  assert.equal(drop.db.tycoon.view().researchPoints, points);
  assert.equal(drop.db.tycoon.view().staff.find((person) => person.id === "founder")?.design, founder?.design);
  assert.equal(drop.db.journey.state().company.cashCents, cash);
  assert.equal(drop.db.journey.state().company.reputation, fans);
  assert.throws(() => drop.db.tycoon.cancelBuild(), /No product is on the bench\./u);
  assert.throws(() => drop.db.tycoon.release("p1"), /No product is on the bench\./u);
  assert.throws(() => drop.db.tycoon.award("p1"), /No product with that id\./u);
  assert.throws(() => drop.db.tycoon.sequel("p1"), /No product with that id\./u);
  assert.throws(() => drop.db.tycoon.port("p1"), /No product with that id\./u);
  assert.throws(() => drop.db.tycoon.patch("p1"), /No product with that id\./u);
  drop.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(drop.db.tycoon.view().developing?.id, "p2");
  assert.equal(drop.db.tycoon.view().developing?.devDays, 0);
  assert.equal(drop.db.tycoon.view().developing?.design, 0);
  assert.deepEqual(drop.db.tycoon.view().developing?.cancel, { enabled: true, reason: "" });
  assert.equal(drop.db.tycoon.view().researchPoints, points);
  assert.equal(validate(drop.db.journey.state()), true, JSON.stringify(validate.errors));
  drop.db.close();

  const again = await setup();
  again.db.tycoon.start("crypto", "newsletter", []);
  again.db.tycoon.cancelBuild();
  again.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(again.db.tycoon.view().developing?.id, "p1");
  assert.equal(again.db.tycoon.view().developing?.devDays, 0);
  again.db.close();

  const kept = await setup();
  kept.db.tycoon.start("crypto", "newsletter", []);
  kept.db.endDay(1);
  const keptPoints = kept.db.tycoon.view().researchPoints;
  const keptCash = kept.db.journey.state().company.cashCents;
  const keptFans = kept.db.journey.state().company.reputation;
  const keptDay = kept.db.clockState().day;
  kept.db.tycoon.cancelBuild();
  const keptFile = join(kept.root, "game.sqlite");
  const keptProject = join(kept.root, "company-project");
  kept.db.close();
  const reopened = new GameDatabase(keptFile, keptProject);
  assert.equal(reopened.tycoon.view().developing, null);
  assert.equal(reopened.tycoon.view().history.length, 0);
  assert.equal(productCount(reopened), 0);
  assert.equal(reopened.tycoon.view().researchPoints, keptPoints);
  assert.equal(reopened.journey.state().company.cashCents, keptCash);
  assert.equal(reopened.journey.state().company.reputation, keptFans);
  assert.equal(reopened.clockState().day, keptDay);
  reopened.tycoon.view();
  assert.equal(productCount(reopened), 0);
  reopened.tycoon.start("fitness", "newsletter", []);
  assert.equal(reopened.tycoon.view().developing?.id, "p2");
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const deal = await setup();
  const offer = deal.db.tycoon.view().contract;
  deal.db.tycoon.acceptContract();
  deal.db.tycoon.start(offer.topicId, offer.typeId, []);
  assert.equal(deal.db.tycoon.view().contract.status, "building");
  assert.equal(deal.db.tycoon.view().developing?.contract?.bonusCents, offer.bonusCents);
  const dealCash = deal.db.journey.state().company.cashCents;
  const dealFans = deal.db.journey.state().company.reputation;
  const dealTx = txIds(deal.db);
  deal.db.tycoon.cancelBuild();
  assert.equal(deal.db.tycoon.view().developing, null);
  assert.equal(deal.db.tycoon.view().history.length, 0);
  assert.equal(deal.db.journey.state().company.cashCents, dealCash);
  assert.equal(deal.db.journey.state().company.reputation, dealFans);
  assert.deepEqual(txIds(deal.db), dealTx);
  const returned = deal.db.tycoon.view().contract;
  assert.equal(returned.status, "offered");
  assert.equal(returned.id, offer.id);
  assert.equal(returned.enabled, true);
  assert.equal(Number((deal.db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id LIKE 'tycoon:contract:%'").get() as { n: number }).n), 0);
  deal.db.tycoon.acceptContract();
  deal.db.tycoon.start(returned.topicId, returned.typeId, []);
  assert.equal(deal.db.tycoon.view().developing?.contract?.bonusCents, offer.bonusCents);
  assert.equal(deal.db.tycoon.view().contract.status, "building");
  deal.db.close();

  const published = await setup();
  published.db.tycoon.start("crypto", "newsletter", []);
  published.db.tycoon.signPublisher();
  published.db.tycoon.showPressDemo();
  assert.equal(published.db.journey.state().company.cashCents, 12_000);
  assert.equal(published.db.journey.state().company.reputation, 4);
  const publishedTx = txIds(published.db);
  published.db.tycoon.cancelBuild();
  assert.equal(published.db.tycoon.view().developing, null);
  assert.equal(published.db.tycoon.view().history.length, 0);
  assert.equal(published.db.journey.state().company.cashCents, 12_000);
  assert.equal(published.db.journey.state().company.reputation, 4);
  assert.deepEqual(txIds(published.db), publishedTx);
  assert.equal(Number((published.db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:publisher:p1:advance'").get() as { n: number }).n), 1);
  assert.equal(Number((published.db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions WHERE id = 'tycoon:pressdemo:p1:fee'").get() as { n: number }).n), 1);
  published.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(published.db.tycoon.view().developing?.id, "p2");
  assert.equal(published.db.tycoon.view().developing?.publisher?.signed, false);
  assert.equal(published.db.tycoon.view().developing?.pressDemo?.shown, false);
  published.db.close();

  const shipped = await setup();
  shipped.db.tycoon.start("crypto", "newsletter", []);
  shipped.db.endDay(1);
  shipped.db.endDay(2);
  shipped.db.tycoon.release("p1");
  const history = JSON.stringify(shipped.db.tycoon.view().history[0]);
  const shippedCash = shipped.db.journey.state().company.cashCents;
  const shippedFans = shipped.db.journey.state().company.reputation;
  shipped.db.tycoon.start("fitness", "newsletter", []);
  assert.equal(shipped.db.tycoon.view().developing?.id, "p2");
  shipped.db.tycoon.cancelBuild();
  assert.equal(JSON.stringify(shipped.db.tycoon.view().history[0]), history);
  assert.equal(shipped.db.tycoon.view().history.length, 1);
  assert.equal(shipped.db.tycoon.view().history[0]?.id, "p1");
  assert.equal(shipped.db.journey.state().company.cashCents, shippedCash);
  assert.equal(shipped.db.journey.state().company.reputation, shippedFans);
  assert.equal(shipped.db.tycoon.view().developing, null);
  assert.throws(() => shipped.db.tycoon.award("p2"), /No product with that id\./u);
  assert.throws(() => shipped.db.tycoon.sequel("p2"), /No product with that id\./u);
  assert.throws(() => shipped.db.tycoon.port("p2"), /No product with that id\./u);
  assert.throws(() => shipped.db.tycoon.localize("p2"), /No product with that id\./u);
  assert.throws(() => shipped.db.tycoon.patch("p2"), /No product with that id\./u);
  assert.throws(() => shipped.db.tycoon.makeTrailer("p2"), /No product with that id\./u);
  assert.throws(() => shipped.db.tycoon.writeDiary("p2"), /No product with that id\./u);
  assert.throws(() => shipped.db.tycoon.release("p2"), /No product is on the bench\./u);
  shipped.db.close();

  const sequel = await setup();
  finishNewsletter(sequel.db);
  sequel.db.tycoon.sequel("p1");
  assert.equal(sequel.db.tycoon.view().developing?.id, "p2");
  assert.equal(JSON.parse(staffJson(sequel.db, "p1")).sequelId, "p2");
  sequel.db.tycoon.cancelBuild();
  assert.equal(JSON.parse(staffJson(sequel.db, "p1")).sequelId, undefined);
  assert.equal(sequel.db.tycoon.view().developing, null);
  assert.equal(sequel.db.tycoon.view().history[0]?.id, "p1");
  sequel.db.tycoon.sequel("p1");
  assert.equal(sequel.db.tycoon.view().developing?.id, "p2");
  assert.equal(JSON.parse(staffJson(sequel.db, "p1")).sequelId, "p2");
  assert.equal(validate(sequel.db.journey.state()), true, JSON.stringify(validate.errors));
  sequel.db.close();
});

test("slip a day holds the bench product for one office day", async () => {
  assert.equal(parseRequest({ kind: "request", id: "slip", method: "tycoon.slipDay", params: {} }).method, "tycoon.slipDay");
  assert.throws(() => parseRequest({ kind: "request", id: "slip", method: "tycoon.slipDay", params: { extra: true } }), /Invalid protocol request/u);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("slipDay():");
  const body = source.slice(bodyStart, source.indexOf("addFeature():", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("slipDay"), "slip a day lives in the harness");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const idle = { enabled: true, pending: false, reason: "" };
  const pending = { enabled: false, pending: true, reason: "" };

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.slipDay(), /No product is on the bench\./u);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.slip, idle);
  const fresh = staffJson(skip.db, "p1");
  skip.db.tycoon.view();
  assert.equal(staffJson(skip.db, "p1"), fresh);
  assert.equal(JSON.parse(fresh).slip, undefined);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.slip, null);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(slipRows(skip.db).length, 0);
  assert.throws(() => skip.db.tycoon.slipDay(), /No product is on the bench\./u);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const hold = await setup();
  hold.db.tycoon.start("crypto", "newsletter", []);
  const before = txIds(hold.db);
  const cash = hold.db.journey.state().company.cashCents;
  const fans = hold.db.journey.state().company.reputation;
  const day = hold.db.clockState().day;
  hold.db.tycoon.slipDay();
  hold.db.tycoon.slipDay();
  assert.equal(hold.db.clockState().day, day);
  assert.equal(hold.db.journey.state().company.cashCents, cash);
  assert.equal(hold.db.journey.state().company.reputation, fans);
  assert.deepEqual(txIds(hold.db), before);
  assert.equal(slipRows(hold.db).length, 0);
  assert.equal(JSON.parse(staffJson(hold.db, "p1")).slip, true);
  assert.deepEqual(hold.db.tycoon.view().developing?.slip, pending);
  const heldJson = staffJson(hold.db, "p1");
  hold.db.tycoon.view();
  assert.equal(staffJson(hold.db, "p1"), heldJson);
  const heldFile = join(hold.root, "game.sqlite");
  const heldProject = join(hold.root, "company-project");
  hold.db.close();
  const reopened = new GameDatabase(heldFile, heldProject);
  assert.deepEqual(reopened.tycoon.view().developing?.slip, pending);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).slip, true);
  assert.equal(reopened.tycoon.view().developing?.devDays, 0);
  reopened.tycoon.view();
  assert.equal(staffJson(reopened, "p1"), heldJson);
  reopened.tycoon.tickDay(1);
  reopened.tycoon.tickDay(1);
  assert.equal(reopened.tycoon.view().developing?.devDays, 0);
  assert.equal(reopened.tycoon.view().developing?.design, 0);
  assert.equal(reopened.tycoon.view().developing?.tech, 0);
  assert.equal(reopened.tycoon.view().developing?.hype, 0);
  assert.equal(reopened.tycoon.view().researchPoints, 0);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).slip, undefined);
  assert.deepEqual(reopened.tycoon.view().developing?.slip, idle);
  const devRow = reopened.journey.db.prepare("SELECT dev_days, design_points, tech_points, hype_points, last_dev_day FROM tycoon_products WHERE id = 'p1'").get() as {
    dev_days: number; design_points: number; tech_points: number; hype_points: number; last_dev_day: number;
  };
  assert.equal(devRow.dev_days, 0);
  assert.equal(devRow.design_points, 0);
  assert.equal(devRow.tech_points, 0);
  assert.equal(devRow.hype_points, 0);
  assert.equal(devRow.last_dev_day, 1);
  assert.equal(reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:build:p1:1'").get(), undefined);
  reopened.endDay(1);
  assert.equal(reopened.clockState().day, 2);
  assert.equal(reopened.tycoon.view().calendar.label, "Spring 2 · Year 1");
  assert.equal(reopened.tycoon.view().developing?.devDays, 0);
  assert.equal(reopened.tycoon.view().developing?.design, 0);
  reopened.endDay(2);
  assert.equal(reopened.tycoon.view().developing?.devDays, 1);
  assert.equal(reopened.tycoon.view().developing?.design, 2);
  assert.equal(reopened.tycoon.view().developing?.tech, 2);
  assert.equal(reopened.tycoon.view().developing?.hype, 2);
  assert.equal(reopened.tycoon.view().researchPoints, 1);
  assert.notEqual(reopened.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:build:p1:2'").get(), undefined);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const again = await setup();
  again.db.tycoon.start("crypto", "newsletter", []);
  again.db.tycoon.slipDay();
  again.db.endDay(1);
  assert.equal(again.db.tycoon.view().developing?.devDays, 0);
  again.db.tycoon.slipDay();
  again.db.endDay(2);
  assert.equal(again.db.clockState().day, 3);
  assert.equal(again.db.tycoon.view().calendar.label, "Spring 3 · Year 1");
  assert.equal(again.db.tycoon.view().developing?.devDays, 0);
  assert.equal(again.db.tycoon.view().developing?.design, 0);
  assert.deepEqual(again.db.tycoon.view().developing?.slip, idle);
  again.db.endDay(3);
  assert.equal(again.db.tycoon.view().developing?.devDays, 1);
  again.db.close();

  const plan = await setup();
  plan.db.tycoon.start("crypto", "newsletter", []);
  plan.db.tycoon.setDayPlan("design");
  plan.db.tycoon.crunch();
  plan.db.tycoon.slipDay();
  plan.db.endDay(1);
  assert.equal(plan.db.tycoon.view().developing?.devDays, 0);
  assert.equal(plan.db.tycoon.view().developing?.design, 0);
  assert.deepEqual(plan.db.tycoon.view().developing?.dayPlan, { id: "design", label: "Design", stat: "design" });
  assert.deepEqual(plan.db.tycoon.view().developing?.crunch, { state: "armed" });
  assert.deepEqual(plan.db.tycoon.view().developing?.bugs, { count: 0, cleared: 0, fixing: false });
  plan.db.endDay(2);
  assert.equal(plan.db.tycoon.view().developing?.devDays, 1);
  assert.equal(plan.db.tycoon.view().developing?.design, 12);
  assert.equal(plan.db.tycoon.view().developing?.tech, 0);
  assert.equal(plan.db.tycoon.view().developing?.hype, 0);
  assert.deepEqual(plan.db.tycoon.view().developing?.crunch, { state: "resting" });
  assert.deepEqual(plan.db.tycoon.view().developing?.bugs, { count: 4, cleared: 0, fixing: false });
  plan.db.close();

  const fixing = await setup();
  fixing.db.tycoon.start("crypto", "newsletter", []);
  fixing.db.tycoon.setDayPlan("design");
  fixing.db.endDay(1);
  assert.equal(fixing.db.tycoon.view().developing?.design, 6);
  fixing.db.tycoon.fixBugs();
  fixing.db.tycoon.crunch();
  fixing.db.tycoon.slipDay();
  fixing.db.endDay(2);
  assert.equal(fixing.db.tycoon.view().developing?.devDays, 1);
  assert.equal(fixing.db.tycoon.view().developing?.design, 6);
  assert.deepEqual(fixing.db.tycoon.view().developing?.bugs, { count: 1, cleared: 0, fixing: true });
  assert.deepEqual(fixing.db.tycoon.view().developing?.crunch, { state: "armed" });
  fixing.db.endDay(3);
  assert.equal(fixing.db.tycoon.view().developing?.devDays, 2);
  assert.equal(fixing.db.tycoon.view().developing?.design, 6);
  assert.deepEqual(fixing.db.tycoon.view().developing?.bugs, { count: 0, cleared: 3, fixing: false });
  assert.deepEqual(fixing.db.tycoon.view().developing?.crunch, { state: "resting" });
  fixing.db.close();

  const lesson = await setup();
  lesson.db.journey.recordCompanyChange("slip-train-gift", 1, 30_000, 0, 0, "Gift");
  lesson.db.tycoon.start("crypto", "newsletter", []);
  lesson.db.tycoon.slipDay();
  lesson.db.tycoon.train("founder", "design");
  assert.equal(lesson.db.journey.state().company.cashCents, 0);
  assert.equal(lesson.db.tycoon.view().staff.find((person) => person.id === "founder")?.design, 3);
  lesson.db.endDay(1);
  assert.equal(lesson.db.tycoon.view().developing?.devDays, 0);
  assert.equal(lesson.db.tycoon.view().developing?.design, 0);
  assert.equal(lesson.db.tycoon.view().researchPoints, 0);
  lesson.db.endDay(2);
  assert.equal(lesson.db.tycoon.view().developing?.design, 2);
  assert.equal(lesson.db.tycoon.view().developing?.tech, 2);
  assert.equal(lesson.db.tycoon.view().developing?.hype, 2);
  assert.equal(JSON.parse(staffJson(lesson.db, "p1")).staff[0].design, 2);
  assert.equal(lesson.db.tycoon.view().staff.find((person) => person.id === "founder")?.design, 3);
  lesson.db.tycoon.cancelBuild();
  lesson.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(JSON.parse(staffJson(lesson.db, "p2")).staff[0].design, 3);
  lesson.db.close();

  const pay = await setup();
  pay.db.journey.hire("mira", 1);
  pay.db.tycoon.start("crypto", "newsletter", []);
  pay.db.tycoon.slipDay();
  pay.db.setClock(28, 480, 0);
  const payBefore = txIds(pay.db);
  pay.db.endDay(28);
  assert.equal(pay.db.clockState().day, 29);
  assert.equal(pay.db.tycoon.view().calendar.label, "Summer 1 · Year 1");
  assert.equal(pay.db.journey.state().company.cashCents, -8_000);
  assert.equal(pay.db.tycoon.view().developing?.devDays, 0);
  assert.equal(pay.db.tycoon.view().developing?.design, 0);
  assert.equal(pay.db.tycoon.view().developing?.tech, 0);
  assert.equal(pay.db.tycoon.view().developing?.hype, 0);
  assert.deepEqual(pay.db.tycoon.view().developing?.slip, idle);
  assert.equal(pay.db.tycoon.view().payroll.notice, "Paid payroll · −$80");
  const payroll = pay.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'").get() as { cash_delta: number };
  assert.equal(payroll.cash_delta, -8_000);
  assert.equal(pay.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:build:p1:28'").get(), undefined);
  assert.equal(slipRows(pay.db).length, 0);
  assert.deepEqual(txIds(pay.db).filter((id) => !payBefore.includes(id)), ["tycoon:payroll:1-spring"]);
  assert.equal(validate(pay.db.journey.state()), true, JSON.stringify(validate.errors));
  pay.db.close();

  const selling = await setup();
  selling.db.tycoon.start("crypto", "newsletter", []);
  selling.db.endDay(1);
  selling.db.endDay(2);
  selling.db.tycoon.release("p1");
  assert.equal(selling.db.journey.state().company.cashCents, 20_700);
  selling.db.tycoon.start("fitness", "newsletter", []);
  selling.db.tycoon.slipDay();
  selling.db.endDay(3);
  assert.equal(selling.db.journey.state().company.cashCents, 20_700);
  assert.equal(selling.db.tycoon.view().developing?.devDays, 0);
  selling.db.tycoon.slipDay();
  selling.db.endDay(4);
  assert.equal(selling.db.journey.state().company.cashCents, 33_300);
  assert.equal(selling.db.tycoon.view().developing?.id, "p2");
  assert.equal(selling.db.tycoon.view().developing?.devDays, 0);
  assert.equal(selling.db.tycoon.view().developing?.design, 0);
  assert.equal(selling.db.tycoon.view().history[0]?.salesCents, 33_300);
  assert.equal(selling.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:build:p2:4'").get(), undefined);
  selling.db.close();

  const sequel = await setup();
  finishNewsletter(sequel.db);
  sequel.db.tycoon.sequel("p1");
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).slip, undefined);
  assert.deepEqual(sequel.db.tycoon.view().developing?.slip, idle);
  assert.equal(validate(sequel.db.journey.state()), true, JSON.stringify(validate.errors));
  sequel.db.close();
});

test("pivot changes the bench product topic or type once", async () => {
  assert.equal(parseRequest({ kind: "request", id: "pivot", method: "tycoon.pivot", params: { topicId: "fitness", typeId: "course" } }).method, "tycoon.pivot");
  assert.throws(() => parseRequest({ kind: "request", id: "pivot", method: "tycoon.pivot", params: {} }), /Invalid protocol request/u);
  assert.throws(() => parseRequest({ kind: "request", id: "pivot", method: "tycoon.pivot", params: { topicId: "fitness", typeId: "course", extra: true } }), /Invalid protocol request/u);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("pivot(topicValue");
  const body = source.slice(bodyStart, source.indexOf("addFeature():", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("pivot"), "pivot lives in the harness");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const idle = { enabled: true, used: false, reason: "" };
  const used = { enabled: false, used: true, reason: "" };

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.pivot("fitness", "course"), /No product is on the bench\./u);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  const skipPivot = skip.db.tycoon.view().developing?.pivot;
  assert.deepEqual({ enabled: skipPivot?.enabled, used: skipPivot?.used, reason: skipPivot?.reason }, idle);
  assert.equal(skipPivot?.options.topics.find((topic) => topic.id === "crypto")?.unlocked, true);
  assert.equal(skipPivot?.options.topics.find((topic) => topic.id === "sneakers")?.unlocked, false);
  assert.equal(skipPivot?.options.types.find((type) => type.id === "newsletter")?.unlocked, true);
  assert.equal(skipPivot?.options.types.find((type) => type.id === "software")?.unlocked, false);
  const fresh = staffJson(skip.db, "p1");
  skip.db.tycoon.view();
  assert.equal(staffJson(skip.db, "p1"), fresh);
  assert.equal(JSON.parse(fresh).pivoted, undefined);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.pivot, null);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(pivotRows(skip.db).length, 0);
  assert.throws(() => skip.db.tycoon.pivot("fitness", "course"), /No product is on the bench\./u);
  assert.equal(validate(skip.db.journey.state()), true, JSON.stringify(validate.errors));
  skip.db.close();

  const same = await setup();
  same.db.tycoon.start("crypto", "newsletter", []);
  assert.throws(() => same.db.tycoon.pivot("crypto", "newsletter"), /Pick a new topic or type\./u);
  same.db.close();

  const locked = await setup();
  locked.db.tycoon.start("crypto", "newsletter", []);
  assert.throws(() => locked.db.tycoon.pivot("sneakers", "newsletter"), /Sneakers is locked\. Research it first\./u);
  assert.throws(() => locked.db.tycoon.pivot("crypto", "software"), /Software Tool is locked\. Research it first\./u);
  locked.db.close();

  const change = await setup();
  change.db.tycoon.start("crypto", "newsletter", []);
  change.db.endDay(1);
  const before = txIds(change.db);
  const cash = change.db.journey.state().company.cashCents;
  const fans = change.db.journey.state().company.reputation;
  const day = change.db.clockState().day;
  const days = change.db.tycoon.view().developing?.devDays;
  const design = change.db.tycoon.view().developing?.design;
  const tech = change.db.tycoon.view().developing?.tech;
  const hype = change.db.tycoon.view().developing?.hype;
  change.db.tycoon.pivot("fitness", "course");
  assert.equal(change.db.clockState().day, day);
  assert.equal(change.db.journey.state().company.cashCents, cash);
  assert.equal(change.db.journey.state().company.reputation, fans);
  assert.deepEqual(txIds(change.db), before);
  assert.equal(pivotRows(change.db).length, 0);
  const moved = change.db.tycoon.view().developing;
  assert.equal(moved?.name, "Fitness Course");
  assert.equal(moved?.topicId, "fitness");
  assert.equal(moved?.typeId, "course");
  assert.equal(moved?.topicName, "Fitness");
  assert.equal(moved?.typeName, "Course");
  assert.equal(moved?.fit, "great");
  assert.equal(moved?.devDays, days);
  assert.equal(moved?.design, design);
  assert.equal(moved?.tech, tech);
  assert.equal(moved?.hype, hype);
  assert.equal(moved?.devDaysRequired, 3);
  assert.equal(moved?.ready, false);
  assert.equal(moved?.priceCents, 4_900);
  assert.equal(moved?.researchBonus, 0);
  assert.deepEqual({ enabled: moved?.pivot?.enabled, used: moved?.pivot?.used, reason: moved?.pivot?.reason }, used);
  assert.equal(JSON.parse(staffJson(change.db, "p1")).pivoted, true);
  const pivotedJson = staffJson(change.db, "p1");
  change.db.tycoon.view();
  assert.equal(staffJson(change.db, "p1"), pivotedJson);
  assert.throws(() => change.db.tycoon.pivot("cooking", "newsletter"), /Already pivoted\./u);
  assert.equal(validate(change.db.journey.state()), true, JSON.stringify(validate.errors));
  const changeFile = join(change.root, "game.sqlite");
  const changeProject = join(change.root, "company-project");
  change.db.close();
  const reopened = new GameDatabase(changeFile, changeProject);
  const kept = reopened.tycoon.view().developing;
  assert.equal(kept?.name, "Fitness Course");
  assert.equal(kept?.topicId, "fitness");
  assert.equal(kept?.typeId, "course");
  assert.equal(kept?.fit, "great");
  assert.equal(kept?.devDays, 1);
  assert.equal(kept?.design, 2);
  assert.equal(JSON.parse(staffJson(reopened, "p1")).pivoted, true);
  assert.deepEqual({ enabled: kept?.pivot?.enabled, used: kept?.pivot?.used, reason: kept?.pivot?.reason }, used);
  reopened.tycoon.view();
  assert.equal(staffJson(reopened, "p1"), pivotedJson);
  assert.throws(() => reopened.tycoon.pivot("gaming", "community"), /Already pivoted\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const review = await setup();
  review.db.tycoon.start("crypto", "newsletter", []);
  review.db.endDay(1);
  review.db.endDay(2);
  assert.equal(review.db.tycoon.view().developing?.ready, true);
  review.db.tycoon.pivot("fitness", "newsletter");
  const pivotedReady = review.db.tycoon.view().developing;
  assert.equal(pivotedReady?.name, "Fitness Newsletter");
  assert.equal(pivotedReady?.fit, "okay");
  assert.equal(pivotedReady?.devDays, 2);
  assert.equal(pivotedReady?.design, 4);
  assert.equal(pivotedReady?.tech, 4);
  assert.equal(pivotedReady?.hype, 4);
  assert.equal(pivotedReady?.ready, true);
  review.db.tycoon.release("p1");
  const shipped = review.db.tycoon.view().history[0];
  assert.equal(shipped?.name, "Fitness Newsletter");
  assert.equal(shipped?.fit, "okay");
  assert.equal(shipped?.pivot, null);
  assert.notEqual(shipped?.salesCents, 20_700);
  assert.ok((shipped?.salesCents ?? 0) < 20_700);
  assert.equal(review.db.journey.state().company.cashCents, shipped?.salesCents);
  assert.equal(pivotRows(review.db).length, 0);
  assert.equal(validate(review.db.journey.state()), true, JSON.stringify(validate.errors));
  review.db.close();

  const deal = await setup();
  const offer = deal.db.tycoon.view().contract;
  deal.db.tycoon.acceptContract();
  deal.db.tycoon.start(offer.topicId, offer.typeId, []);
  const blocked = deal.db.tycoon.view().developing?.pivot;
  const contractReason = `This contract is ${offer.topicName} × ${offer.typeName}.`;
  assert.equal(blocked?.enabled, false);
  assert.equal(blocked?.used, false);
  assert.equal(blocked?.reason, contractReason);
  const otherTopic = offer.topicId === "fitness" ? "crypto" : "fitness";
  const otherType = offer.typeId === "course" ? "newsletter" : "course";
  assert.throws(() => deal.db.tycoon.pivot(otherTopic, otherType), new RegExp(`This contract is ${offer.topicName} × ${offer.typeName}\\.`));
  assert.equal(deal.db.tycoon.view().developing?.topicId, offer.topicId);
  assert.equal(deal.db.tycoon.view().developing?.typeId, offer.typeId);
  assert.equal(JSON.parse(staffJson(deal.db, "p1")).pivoted, undefined);
  assert.equal(validate(deal.db.journey.state()), true, JSON.stringify(validate.errors));
  deal.db.close();

  const bonus = await setup();
  bonus.db.tycoon.start("crypto", "newsletter", []);
  bonus.db.journey.db.prepare("UPDATE tycoon_meta SET research_points = research_points + 20 WHERE id = 1").run();
  bonus.db.tycoon.research("topic", "sneakers");
  bonus.db.tycoon.pivot("sneakers", "newsletter");
  assert.equal(bonus.db.tycoon.view().developing?.name, "Sneakers Newsletter");
  assert.equal(bonus.db.tycoon.view().developing?.researchBonus, 6);
  assert.equal(JSON.parse(staffJson(bonus.db, "p1")).researchBonus, 6);
  bonus.db.close();

  const sequel = await setup();
  finishNewsletter(sequel.db);
  sequel.db.tycoon.sequel("p1");
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).pivoted, undefined);
  const sequelPivot = sequel.db.tycoon.view().developing?.pivot;
  assert.deepEqual({ enabled: sequelPivot?.enabled, used: sequelPivot?.used, reason: sequelPivot?.reason }, idle);
  sequel.db.tycoon.pivot("fitness", "course");
  assert.equal(sequel.db.tycoon.view().developing?.name, "Fitness Course 2");
  assert.equal(JSON.parse(staffJson(sequel.db, "p2")).pivoted, true);
  assert.equal(validate(sequel.db.journey.state()), true, JSON.stringify(validate.errors));
  sequel.db.close();
});

test("playtest reports the current review band and changes nothing", async () => {
  assert.equal(parseRequest({ kind: "request", id: "playtest", method: "tycoon.playtest", params: {} }).method, "tycoon.playtest");
  assert.throws(() => parseRequest({ kind: "request", id: "playtest", method: "tycoon.playtest", params: { extra: true } }), /Invalid protocol request/u);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("playtest():");
  const body = source.slice(bodyStart, source.indexOf("pivot(topicValue", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("Work one office day first."), "playtest lives in the harness");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const waiting = { enabled: false, band: null, reason: "Work one office day first." };

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.playtest(), /No product is on the bench\./u);
  bare.db.close();

  async function shipNewsletter(look: boolean) {
    const run = await setup();
    const db = run.db;
    db.tycoon.start("crypto", "newsletter", []);
    if (look) assert.throws(() => db.tycoon.playtest(), /Work one office day first\./u);
    db.endDay(1);
    if (look) db.tycoon.playtest();
    db.endDay(2);
    const before = {
      staff: staffJson(db, "p1"),
      txs: txIds(db),
      day: db.clockState().day,
      cash: db.journey.state().company.cashCents,
      fans: db.journey.state().company.reputation,
      devDays: db.tycoon.view().developing?.devDays,
      design: db.tycoon.view().developing?.design,
      tech: db.tycoon.view().developing?.tech,
      hype: db.tycoon.view().developing?.hype,
      seed: Number((db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
    };
    const band = db.tycoon.view().developing?.playtest?.band ?? null;
    if (look) {
      db.tycoon.playtest();
      db.tycoon.playtest();
      assert.equal(staffJson(db, "p1"), before.staff);
      assert.deepEqual(txIds(db), before.txs);
      assert.equal(db.clockState().day, before.day);
      assert.equal(db.journey.state().company.cashCents, before.cash);
      assert.equal(db.journey.state().company.reputation, before.fans);
      assert.equal(db.tycoon.view().developing?.devDays, before.devDays);
      assert.equal(db.tycoon.view().developing?.design, before.design);
      assert.equal(db.tycoon.view().developing?.tech, before.tech);
      assert.equal(db.tycoon.view().developing?.hype, before.hype);
      assert.equal(Number((db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), before.seed);
      assert.equal(playtestRows(db).length, 0);
    }
    db.tycoon.release("p1");
    const launched = db.tycoon.view().history[0];
    db.endDay(3);
    db.endDay(4);
    const result = {
      band,
      review: launched?.review ?? null,
      launchCents: launched?.salesCents,
      launchFans: launched?.fans,
      cash: db.journey.state().company.cashCents,
      txs: txIds(db),
      seed: before.seed,
    };
    db.close();
    return result;
  }

  const skipped = await shipNewsletter(false);
  const looked = await shipNewsletter(true);
  assert.equal(skipped.band, "mid");
  assert.equal(looked.band, "mid");
  assert.equal(reviewBand(skipped.review?.score ?? 0), "mid");
  assert.equal(reviewBand(looked.review?.score ?? 0), "mid");
  assert.deepEqual(looked.review, skipped.review);
  assert.equal(skipped.launchCents, 20_700);
  assert.equal(skipped.launchFans, 5);
  assert.equal(skipped.cash, 33_300);
  assert.equal(looked.launchCents, 20_700);
  assert.equal(looked.launchFans, 5);
  assert.equal(looked.cash, 33_300);
  assert.deepEqual(looked.txs, skipped.txs);
  assert.equal(looked.seed, skipped.seed);

  const low = await setup();
  low.db.tycoon.start("crypto", "newsletter", []);
  low.db.tycoon.setDayPlan("design");
  low.db.endDay(1);
  low.db.endDay(2);
  assert.equal(low.db.tycoon.view().developing?.playtest?.band, "low");
  const lowStaff = staffJson(low.db, "p1");
  const lowTx = txIds(low.db);
  low.db.tycoon.playtest();
  assert.equal(staffJson(low.db, "p1"), lowStaff);
  assert.deepEqual(txIds(low.db), lowTx);
  low.db.tycoon.release("p1");
  assert.equal(reviewBand(low.db.tycoon.view().history[0]?.review?.score ?? 0), "low");
  assert.equal(low.db.tycoon.view().history[0]?.playtest, null);
  assert.equal(playtestRows(low.db).length, 0);
  assert.equal(validate(low.db.journey.state()), true, JSON.stringify(validate.errors));
  low.db.close();

  const high = await setup();
  high.db.tycoon.start("crypto", "newsletter", []);
  high.db.endDay(1);
  high.db.endDay(2);
  high.db.endDay(3);
  high.db.endDay(4);
  assert.equal(high.db.tycoon.view().developing?.playtest?.enabled, true);
  assert.equal(high.db.tycoon.view().developing?.playtest?.band, "high");
  assert.equal(high.db.tycoon.view().developing?.playtest?.reason, "");
  high.db.tycoon.playtest();
  high.db.tycoon.release("p1");
  assert.equal(reviewBand(high.db.tycoon.view().history[0]?.review?.score ?? 0), "high");
  assert.equal(high.db.tycoon.view().history[0]?.playtest, null);
  assert.equal(playtestRows(high.db).length, 0);
  high.db.close();

  const pivot = await setup();
  pivot.db.tycoon.start("crypto", "newsletter", []);
  pivot.db.endDay(1);
  pivot.db.endDay(2);
  assert.equal(pivot.db.tycoon.view().developing?.playtest?.band, "mid");
  const pivotPoints = {
    design: pivot.db.tycoon.view().developing?.design,
    tech: pivot.db.tycoon.view().developing?.tech,
    hype: pivot.db.tycoon.view().developing?.hype,
    devDays: pivot.db.tycoon.view().developing?.devDays,
  };
  pivot.db.tycoon.pivot("fitness", "course");
  const pivoted = pivot.db.tycoon.view().developing;
  assert.equal(pivoted?.playtest?.band, "low");
  assert.equal(pivoted?.design, pivotPoints.design);
  assert.equal(pivoted?.tech, pivotPoints.tech);
  assert.equal(pivoted?.hype, pivotPoints.hype);
  assert.equal(pivoted?.devDays, pivotPoints.devDays);
  pivot.db.tycoon.playtest();
  assert.equal(pivot.db.tycoon.view().developing?.playtest?.band, "low");
  assert.equal(playtestRows(pivot.db).length, 0);
  pivot.db.close();

  const crunch = await setup();
  crunch.db.tycoon.start("crypto", "newsletter", []);
  crunch.db.endDay(1);
  assert.deepEqual(crunch.db.tycoon.view().developing?.playtest, { enabled: true, band: "low", reason: "" });
  crunch.db.tycoon.crunch();
  assert.equal(crunch.db.tycoon.view().developing?.playtest?.band, "low");
  crunch.db.endDay(2);
  assert.equal(crunch.db.tycoon.view().developing?.playtest?.band, "high");
  crunch.db.tycoon.playtest();
  assert.equal(crunch.db.tycoon.view().developing?.playtest?.band, "high");
  assert.equal(playtestRows(crunch.db).length, 0);
  crunch.db.close();

  const fresh = await setup();
  fresh.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(fresh.db.tycoon.view().developing?.playtest, waiting);
  const freshStaff = staffJson(fresh.db, "p1");
  fresh.db.tycoon.view();
  assert.equal(staffJson(fresh.db, "p1"), freshStaff);
  assert.equal(JSON.parse(freshStaff).playtest, undefined);
  assert.throws(() => fresh.db.tycoon.playtest(), /Work one office day first\./u);
  assert.equal(staffJson(fresh.db, "p1"), freshStaff);
  fresh.db.endDay(1);
  fresh.db.endDay(2);
  const block = fresh.db.tycoon.view().developing?.playtest;
  const savedStaff = staffJson(fresh.db, "p1");
  fresh.db.tycoon.playtest();
  assert.deepEqual(fresh.db.tycoon.view().developing?.playtest, block);
  assert.equal(staffJson(fresh.db, "p1"), savedStaff);
  assert.equal(validate(fresh.db.journey.state()), true, JSON.stringify(validate.errors));
  const freshFile = join(fresh.root, "game.sqlite");
  const freshProject = join(fresh.root, "company-project");
  fresh.db.close();
  const reopened = new GameDatabase(freshFile, freshProject);
  assert.deepEqual(reopened.tycoon.view().developing?.playtest, block);
  assert.equal(staffJson(reopened, "p1"), savedStaff);
  reopened.tycoon.playtest();
  assert.deepEqual(reopened.tycoon.view().developing?.playtest, block);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.tycoon.release("p1");
  assert.equal(reopened.tycoon.view().history[0]?.playtest, null);
  assert.throws(() => reopened.tycoon.playtest(), /No product is on the bench\./u);
  reopened.close();

  const dropped = await setup();
  dropped.db.tycoon.start("crypto", "newsletter", []);
  dropped.db.tycoon.cancelBuild();
  assert.throws(() => dropped.db.tycoon.playtest(), /No product is on the bench\./u);
  dropped.db.close();
});

test("assignTeam changes who crafts later days and keeps earned points", async () => {
  assert.equal(parseRequest({ kind: "request", id: "team", method: "tycoon.assignTeam", params: { staffIds: ["founder"] } }).method, "tycoon.assignTeam");
  assert.throws(() => parseRequest({ kind: "request", id: "team", method: "tycoon.assignTeam", params: {} }), /Invalid protocol request/u);
  assert.throws(() => parseRequest({ kind: "request", id: "team", method: "tycoon.assignTeam", params: { staffIds: ["founder"], extra: true } }), /Invalid protocol request/u);
  assert.throws(() => parseRequest({ kind: "request", id: "team", method: "tycoon.assignTeam", params: { staffIds: ["nope"] } }), /Invalid protocol request/u);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("assignTeam(requestedStaff");
  const body = source.slice(bodyStart, source.indexOf("addFeature():", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("No product is on the bench."), "assignTeam lives in the harness");
  assert.ok(source.includes("Pick at least one teammate."), "empty team fails clearly");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const founderOnly = {
    enabled: true,
    members: [{ id: "founder", name: "Founder", onTeam: true }],
    reason: "",
  };

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.assignTeam(["founder"]), /No product is on the bench\./u);
  bare.db.close();

  const empty = await setup();
  empty.db.tycoon.start("crypto", "newsletter", []);
  assert.throws(() => empty.db.tycoon.assignTeam([]), /Pick at least one teammate\./u);
  assert.deepEqual(empty.db.tycoon.view().developing?.staffIds, ["founder"]);
  empty.db.close();

  const unknown = await setup();
  unknown.db.tycoon.start("crypto", "newsletter", []);
  assert.throws(() => unknown.db.tycoon.assignTeam(["nope"]), /Unknown teammate/u);
  unknown.db.close();

  const unhired = await setup();
  unhired.db.tycoon.start("crypto", "newsletter", []);
  assert.throws(() => unhired.db.tycoon.assignTeam(["mira"]), /not on the team/u);
  unhired.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.team, founderOnly);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.team, null);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.throws(() => skip.db.tycoon.assignTeam(["founder"]), /No product is on the bench\./u);
  skip.db.close();

  const kept = await setup();
  kept.db.tycoon.start("crypto", "newsletter", []);
  kept.db.endDay(1);
  assert.equal(kept.db.tycoon.view().developing?.design, 2);
  assert.equal(kept.db.tycoon.view().developing?.tech, 2);
  assert.equal(kept.db.tycoon.view().developing?.hype, 2);
  const before = {
    staff: staffJson(kept.db, "p1"),
    txs: txIds(kept.db),
    day: kept.db.clockState().day,
    cash: kept.db.journey.state().company.cashCents,
    fans: kept.db.journey.state().company.reputation,
    seed: Number((kept.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  };
  kept.db.tycoon.assignTeam(["founder"]);
  kept.db.tycoon.assignTeam(["founder"]);
  assert.equal(staffJson(kept.db, "p1"), before.staff);
  assert.deepEqual(txIds(kept.db), before.txs);
  assert.equal(kept.db.clockState().day, before.day);
  assert.equal(kept.db.journey.state().company.cashCents, before.cash);
  assert.equal(kept.db.journey.state().company.reputation, before.fans);
  assert.equal(kept.db.tycoon.view().developing?.design, 2);
  assert.equal(kept.db.tycoon.view().developing?.devDays, 1);
  assert.equal(Number((kept.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), before.seed);
  assert.equal(teamRows(kept.db).length, 0);
  kept.db.journey.hire("mira", 1);
  kept.db.tycoon.assignTeam(["founder", "mira"]);
  kept.db.tycoon.assignTeam(["mira", "founder"]);
  assert.deepEqual(kept.db.tycoon.view().developing?.staffIds, ["founder", "mira"]);
  assert.equal(kept.db.tycoon.view().developing?.design, 2);
  assert.equal(kept.db.tycoon.view().developing?.devDays, 1);
  assert.equal(kept.db.clockState().day, before.day);
  assert.equal(kept.db.journey.state().company.cashCents, before.cash);
  assert.deepEqual(txIds(kept.db).filter((id) => id.startsWith("tycoon:")), before.txs.filter((id) => id.startsWith("tycoon:")));
  assert.equal(teamRows(kept.db).length, 0);
  kept.db.endDay(2);
  assert.equal(kept.db.tycoon.view().developing?.devDays, 2);
  assert.equal(kept.db.tycoon.view().developing?.design, 7);
  assert.equal(kept.db.tycoon.view().developing?.tech, 6);
  assert.equal(kept.db.tycoon.view().developing?.hype, 5);
  const withMina = kept.db.tycoon.view().developing?.team;
  assert.equal(withMina?.enabled, true);
  assert.equal(withMina?.reason, "");
  assert.deepEqual(withMina?.members, [
    { id: "founder", name: "Founder", onTeam: true },
    { id: "mira", name: "Mina", onTeam: true },
  ]);
  assert.equal(validate(kept.db.journey.state()), true, JSON.stringify(validate.errors));
  kept.db.close();

  const hired = await setup();
  hired.db.tycoon.start("crypto", "newsletter", []);
  hired.db.endDay(1);
  hired.db.journey.hire("mira", 1);
  assert.deepEqual(hired.db.tycoon.view().developing?.team?.members, [
    { id: "founder", name: "Founder", onTeam: true },
    { id: "mira", name: "Mina", onTeam: false },
  ]);
  hired.db.tycoon.assignTeam(["mira"]);
  assert.deepEqual(hired.db.tycoon.view().developing?.staffIds, ["mira"]);
  assert.equal(hired.db.tycoon.view().developing?.design, 2);
  hired.db.endDay(2);
  assert.equal(hired.db.tycoon.view().developing?.design, 5);
  assert.equal(hired.db.tycoon.view().developing?.tech, 4);
  assert.equal(hired.db.tycoon.view().developing?.hype, 3);
  hired.db.close();

  const trained = await setup();
  trained.db.journey.hire("mira", 1);
  trained.db.journey.recordCompanyChange("train-cash", 1, 45_000, 0, 0, "Train cash");
  trained.db.tycoon.start("crypto", "newsletter", ["mira"]);
  const startedStaff = JSON.parse(staffJson(trained.db, "p1")) as { staff: Array<{ id: string; design: number }> };
  assert.equal(startedStaff.staff.find((person) => person.id === "mira")?.design, 3);
  trained.db.tycoon.train("mira", "design");
  trained.db.tycoon.assignTeam(["founder", "mira"]);
  trained.db.endDay(1);
  assert.equal(trained.db.tycoon.view().developing?.design, 2, "training still zeroes Mina that day");
  assert.equal(JSON.parse(staffJson(trained.db, "p1")).staff.find((person: { id: string }) => person.id === "mira").design, 3);
  trained.db.endDay(2);
  assert.equal(trained.db.tycoon.view().developing?.design, 7, "the stored snapshot still crafts, not the lesson");
  trained.db.close();

  const fresh = await setup();
  fresh.db.tycoon.start("crypto", "newsletter", []);
  const freshStaff = staffJson(fresh.db, "p1");
  fresh.db.tycoon.view();
  assert.equal(staffJson(fresh.db, "p1"), freshStaff);
  assert.equal(JSON.parse(freshStaff).team, undefined);
  assert.deepEqual(fresh.db.tycoon.view().developing?.team, founderOnly);
  const freshFile = join(fresh.root, "game.sqlite");
  const freshProject = join(fresh.root, "company-project");
  fresh.db.close();
  const reopened = new GameDatabase(freshFile, freshProject);
  assert.deepEqual(reopened.tycoon.view().developing?.team, founderOnly);
  assert.equal(staffJson(reopened, "p1"), freshStaff);
  reopened.journey.hire("mira", 1);
  reopened.tycoon.assignTeam(["founder", "mira"]);
  const assigned = reopened.tycoon.view().developing?.team;
  const assignedStaff = staffJson(reopened, "p1");
  assert.deepEqual(assigned?.members.map((person) => person.id), ["founder", "mira"]);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();
  const again = new GameDatabase(freshFile, freshProject);
  assert.deepEqual(again.tycoon.view().developing?.team, assigned);
  assert.equal(staffJson(again, "p1"), assignedStaff);
  again.endDay(1);
  again.endDay(2);
  again.tycoon.release("p1");
  assert.equal(again.tycoon.view().history[0]?.team, null);
  assert.throws(() => again.tycoon.assignTeam(["founder"]), /No product is on the bench\./u);
  again.close();

  const dropped = await setup();
  dropped.db.tycoon.start("crypto", "newsletter", []);
  dropped.db.tycoon.cancelBuild();
  assert.throws(() => dropped.db.tycoon.assignTeam(["founder"]), /No product is on the bench\./u);
  dropped.db.close();
});

test("researchSpike converts one day's personal craft and keeps earned points", async () => {
  assert.equal(parseRequest({ kind: "request", id: "spike", method: "tycoon.researchSpike", params: {} }).method, "tycoon.researchSpike");
  assert.throws(() => parseRequest({ kind: "request", id: "spike", method: "tycoon.researchSpike", params: { extra: true } }), /Invalid protocol request/u);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("researchSpike():");
  const body = source.slice(bodyStart, source.indexOf("addFeature():", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("No product is on the bench."), "researchSpike lives in the harness");
  assert.ok(body.includes("A research spike is already set."), "a pending spike fails clearly");
  assert.ok(body.includes("This build already used its research spike."), "a used spike fails clearly");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const idle = { enabled: true, pending: false, used: false, reason: "", points: 0 };

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.researchSpike(), /No product is on the bench\./u);
  bare.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(skip.db.tycoon.view().developing?.researchSpike, idle);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.researchSpike, null);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.throws(() => skip.db.tycoon.researchSpike(), /No product is on the bench\./u);
  skip.db.close();

  const kept = await setup();
  kept.db.tycoon.start("crypto", "newsletter", []);
  kept.db.endDay(1);
  assert.equal(kept.db.tycoon.view().developing?.design, 2);
  assert.equal(kept.db.tycoon.view().developing?.tech, 2);
  assert.equal(kept.db.tycoon.view().developing?.hype, 2);
  assert.equal(kept.db.tycoon.view().researchPoints, 1);
  const before = {
    staff: staffJson(kept.db, "p1"),
    txs: txIds(kept.db),
    day: kept.db.clockState().day,
    cash: kept.db.journey.state().company.cashCents,
    fans: kept.db.journey.state().company.reputation,
    seed: Number((kept.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  };
  kept.db.tycoon.researchSpike();
  assert.throws(() => kept.db.tycoon.researchSpike(), /already set/u);
  assert.equal(kept.db.tycoon.view().developing?.design, 2);
  assert.equal(kept.db.tycoon.view().developing?.tech, 2);
  assert.equal(kept.db.tycoon.view().developing?.hype, 2);
  assert.equal(kept.db.tycoon.view().developing?.devDays, 1);
  assert.equal(kept.db.tycoon.view().researchPoints, 1);
  assert.equal(kept.db.clockState().day, before.day);
  assert.equal(kept.db.journey.state().company.cashCents, before.cash);
  assert.equal(kept.db.journey.state().company.reputation, before.fans);
  assert.equal(Number((kept.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), before.seed);
  assert.deepEqual(txIds(kept.db), before.txs);
  assert.equal(spikeRows(kept.db).length, 0);
  assert.equal(JSON.parse(staffJson(kept.db, "p1")).researchSpike, "pending");
  assert.deepEqual(kept.db.tycoon.view().developing?.researchSpike, {
    enabled: false, pending: true, used: false, reason: "", points: 0,
  });
  kept.db.endDay(2);
  assert.equal(kept.db.tycoon.view().developing?.devDays, 2);
  assert.equal(kept.db.tycoon.view().developing?.design, 2);
  assert.equal(kept.db.tycoon.view().developing?.tech, 2);
  assert.equal(kept.db.tycoon.view().developing?.hype, 2);
  assert.equal(kept.db.tycoon.view().researchPoints, 8);
  assert.deepEqual(kept.db.tycoon.view().developing?.researchSpike, {
    enabled: false, pending: false, used: true, reason: "", points: 6,
  });
  assert.throws(() => kept.db.tycoon.researchSpike(), /already used/u);
  assert.equal(kept.db.tycoon.view().developing?.design, 2);
  kept.db.endDay(3);
  assert.equal(kept.db.tycoon.view().developing?.devDays, 3);
  assert.equal(kept.db.tycoon.view().developing?.design, 4);
  assert.equal(kept.db.tycoon.view().developing?.tech, 4);
  assert.equal(kept.db.tycoon.view().developing?.hype, 4);
  assert.equal(kept.db.tycoon.view().researchPoints, 9);
  assert.equal(validate(kept.db.journey.state()), true, JSON.stringify(validate.errors));
  kept.db.close();

  const fresh = await setup();
  fresh.db.tycoon.start("crypto", "newsletter", []);
  fresh.db.tycoon.researchSpike();
  fresh.db.endDay(1);
  assert.equal(fresh.db.tycoon.view().developing?.devDays, 1);
  assert.equal(fresh.db.tycoon.view().developing?.design, 0);
  assert.equal(fresh.db.tycoon.view().developing?.tech, 0);
  assert.equal(fresh.db.tycoon.view().developing?.hype, 0);
  assert.equal(fresh.db.tycoon.view().researchPoints, 7);
  assert.equal(fresh.db.tycoon.view().developing?.researchSpike?.points, 6);
  fresh.db.endDay(2);
  assert.equal(fresh.db.tycoon.view().developing?.design, 2);
  assert.equal(fresh.db.tycoon.view().developing?.tech, 2);
  assert.equal(fresh.db.tycoon.view().developing?.hype, 2);
  assert.equal(fresh.db.tycoon.view().researchPoints, 8);
  fresh.db.close();

  const pair = await setup();
  pair.db.journey.hire("mira", 1);
  pair.db.tycoon.start("crypto", "newsletter", ["mira"]);
  pair.db.tycoon.researchSpike();
  pair.db.endDay(1);
  assert.equal(pair.db.tycoon.view().developing?.design, 0);
  assert.equal(pair.db.tycoon.view().developing?.tech, 0);
  assert.equal(pair.db.tycoon.view().developing?.hype, 0);
  assert.equal(pair.db.tycoon.view().researchPoints, 14);
  assert.equal(pair.db.tycoon.view().developing?.researchSpike?.points, 12);
  pair.db.endDay(2);
  assert.equal(pair.db.tycoon.view().developing?.design, 5);
  assert.equal(pair.db.tycoon.view().developing?.tech, 4);
  assert.equal(pair.db.tycoon.view().developing?.hype, 3);
  assert.equal(pair.db.tycoon.view().researchPoints, 16);
  pair.db.close();

  const tool = await setup();
  tool.db.journey.recordCompanyChange("tool-cash", 1, 25_000, 0, 0, "Tool cash");
  tool.db.tycoon.buyUpgrade("standing_desk");
  tool.db.tycoon.start("crypto", "newsletter", []);
  tool.db.tycoon.researchSpike();
  tool.db.endDay(1);
  assert.equal(tool.db.tycoon.view().developing?.design, 1);
  assert.equal(tool.db.tycoon.view().developing?.tech, 0);
  assert.equal(tool.db.tycoon.view().developing?.hype, 0);
  assert.equal(tool.db.tycoon.view().researchPoints, 7);
  assert.equal(tool.db.tycoon.view().developing?.researchSpike?.points, 6);
  tool.db.close();

  const held = await setup();
  held.db.tycoon.start("crypto", "newsletter", []);
  held.db.tycoon.slipDay();
  held.db.tycoon.researchSpike();
  held.db.endDay(1);
  assert.equal(held.db.tycoon.view().developing?.devDays, 0);
  assert.equal(held.db.tycoon.view().researchPoints, 0);
  assert.equal(held.db.tycoon.view().developing?.researchSpike?.pending, true);
  held.db.endDay(2);
  assert.equal(held.db.tycoon.view().developing?.devDays, 1);
  assert.equal(held.db.tycoon.view().developing?.design, 0);
  assert.equal(held.db.tycoon.view().researchPoints, 7);
  assert.equal(held.db.tycoon.view().developing?.researchSpike?.used, true);
  held.db.close();

  const lesson = await setup();
  lesson.db.journey.recordCompanyChange("train-cash", 1, 30_000, 0, 0, "Train cash");
  lesson.db.tycoon.start("crypto", "newsletter", []);
  lesson.db.tycoon.train("founder", "design");
  lesson.db.tycoon.researchSpike();
  lesson.db.endDay(1);
  assert.equal(lesson.db.tycoon.view().developing?.devDays, 1);
  assert.equal(lesson.db.tycoon.view().developing?.design, 0);
  assert.equal(lesson.db.tycoon.view().researchPoints, 0);
  assert.equal(lesson.db.tycoon.view().developing?.researchSpike?.used, true);
  assert.equal(lesson.db.tycoon.view().developing?.researchSpike?.points, 0);
  lesson.db.close();

  const reopen = await setup();
  reopen.db.tycoon.start("crypto", "newsletter", []);
  const untouched = staffJson(reopen.db, "p1");
  reopen.db.tycoon.view();
  assert.equal(staffJson(reopen.db, "p1"), untouched);
  assert.equal(JSON.parse(untouched).researchSpike, undefined);
  reopen.db.tycoon.researchSpike();
  const pending = reopen.db.tycoon.view().developing?.researchSpike;
  const pendingStaff = staffJson(reopen.db, "p1");
  const file = join(reopen.root, "game.sqlite");
  const project = join(reopen.root, "company-project");
  reopen.db.close();
  const reopened = new GameDatabase(file, project);
  assert.deepEqual(reopened.tycoon.view().developing?.researchSpike, pending);
  assert.equal(staffJson(reopened, "p1"), pendingStaff);
  reopened.endDay(1);
  const used = reopened.tycoon.view().developing?.researchSpike;
  assert.equal(used?.used, true);
  assert.equal(used?.points, 6);
  assert.equal(reopened.tycoon.view().researchPoints, 7);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  const usedStaff = staffJson(reopened, "p1");
  reopened.close();
  const again = new GameDatabase(file, project);
  assert.deepEqual(again.tycoon.view().developing?.researchSpike, used);
  assert.equal(staffJson(again, "p1"), usedStaff);
  assert.throws(() => again.tycoon.researchSpike(), /already used/u);
  again.tycoon.cancelBuild();
  again.tycoon.start("crypto", "newsletter", []);
  assert.deepEqual(again.tycoon.view().developing?.researchSpike, idle);
  again.tycoon.researchSpike();
  assert.equal(again.tycoon.view().developing?.researchSpike?.pending, true);
  again.close();

  const dropped = await setup();
  dropped.db.tycoon.start("crypto", "newsletter", []);
  dropped.db.tycoon.cancelBuild();
  assert.throws(() => dropped.db.tycoon.researchSpike(), /No product is on the bench\./u);
  dropped.db.close();
});

test("salePrice changes the percent for the days still ahead", async () => {
  assert.equal(
    parseRequest({ kind: "request", id: "sale", method: "tycoon.salePrice", params: { productId: "p1", pricePercent: 80 } }).method,
    "tycoon.salePrice",
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "sale", method: "tycoon.salePrice", params: { productId: "p1", pricePercent: 90 } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "sale", method: "tycoon.salePrice", params: { productId: "p1" } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "sale", method: "tycoon.salePrice", params: { productId: "p1", pricePercent: 80, extra: true } }),
    /Invalid protocol request/u,
  );
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("salePrice(productId: string");
  const body = source.slice(bodyStart, source.indexOf("makeTrailer(productId: string", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("No product is selling."), "salePrice lives in the harness");
  assert.ok(body.includes("A sale price was already set."), "a repeat fails clearly");
  assert.ok(body.includes("Price is unchanged."), "the same percent fails clearly");
  const ports = source.slice(source.indexOf("private payPorts"), source.indexOf("private payLocalizations"));
  const translations = source.slice(source.indexOf("private payLocalizations"), source.indexOf("private assignedStaff"));
  assert.equal(ports.includes("salePricePercent"), false);
  assert.equal(translations.includes("salePricePercent"), false);
  assert.ok(source.slice(source.indexOf("private applySale"), source.indexOf("private payPorts")).includes("stored.salePricePercent ?? stored.pricePercent"));

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = {
    enabled: true,
    used: false,
    currentPercent: 100,
    options: [...LAUNCH_PRICES],
    reason: "",
  };

  const bare = await setup();
  assert.throws(() => bare.db.tycoon.salePrice("p1", 80), /No product with that id\./u);
  bare.db.close();

  const bench = await setup();
  bench.db.tycoon.start("crypto", "newsletter", []);
  assert.equal(bench.db.tycoon.view().developing?.salePrice, null);
  assert.throws(() => bench.db.tycoon.salePrice("p1", 80), /No product is selling\./u);
  bench.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.deepEqual(skip.db.tycoon.view().history[0]?.salePrice, offer);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).salePricePercent, undefined);
  assert.throws(() => skip.db.tycoon.salePrice("p1", 100), /Price is unchanged\./u);
  assert.throws(() => skip.db.tycoon.salePrice("p1", 90), /Pick −20%, catalog, or \+20%\./u);
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(JSON.parse(staffJson(skip.db, "p1")).salePricePercent, undefined);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 33_300);
  skip.db.close();

  const sold = await setup();
  sold.db.tycoon.start("crypto", "newsletter", []);
  sold.db.endDay(1);
  sold.db.endDay(2);
  sold.db.tycoon.release("p1");
  const score = sold.db.tycoon.view().history[0]?.review?.score ?? 0;
  assert.equal(score, 6);
  const before = {
    txs: txIds(sold.db),
    day: sold.db.clockState().day,
    cash: sold.db.journey.state().company.cashCents,
    fans: sold.db.journey.state().company.reputation,
    sales: sold.db.tycoon.view().history[0]?.salesCents,
    seed: Number((sold.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  };
  assert.equal(before.seed, 26021);
  assert.equal(before.cash, 20_700);
  assert.equal(before.fans, 5);
  sold.db.tycoon.salePrice("p1", 80);
  assert.throws(() => sold.db.tycoon.salePrice("p1", 120), /A sale price was already set\./u);
  assert.throws(() => sold.db.tycoon.salePrice("p1", 80), /A sale price was already set\./u);
  assert.throws(() => sold.db.tycoon.salePrice("p1", 90), /A sale price was already set\./u);
  const changed = sold.db.tycoon.view().history[0];
  assert.equal(changed?.pricePercent, 100);
  assert.equal(changed?.priceCents, 900);
  assert.equal(changed?.salesCents, 20_700);
  assert.equal(changed?.fans, 5);
  assert.deepEqual(changed?.salePrice, {
    enabled: false,
    used: true,
    currentPercent: 80,
    options: [...LAUNCH_PRICES],
    reason: "A sale price was already set.",
  });
  assert.equal(sold.db.clockState().day, before.day);
  assert.equal(sold.db.journey.state().company.cashCents, before.cash);
  assert.equal(sold.db.journey.state().company.reputation, before.fans);
  assert.equal(Number((sold.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), before.seed);
  assert.deepEqual(txIds(sold.db), before.txs);
  assert.equal(salePriceRows(sold.db).length, 0);
  assert.equal(JSON.parse(staffJson(sold.db, "p1")).salePricePercent, 80);
  const posted = sold.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:p1:0'").get() as { cash_delta: number };
  assert.equal(posted.cash_delta, 20_700);
  assert.equal(validate(sold.db.journey.state()), true, JSON.stringify(validate.errors));
  sold.db.endDay(3);
  assert.equal(sold.db.tycoon.view().history[0]?.salesCents, 20_700, "the day already sold stays at the launch percent");
  const catalogDay = salesForDay({
    seed: 26021, productId: "p1", typeId: "newsletter", fit: "great", score, dayIndex: 1, reputation: before.fans, pricePercent: 100,
  });
  const pricedDay = salesForDay({
    seed: 26021, productId: "p1", typeId: "newsletter", fit: "great", score, dayIndex: 1, reputation: before.fans, pricePercent: 80,
  });
  assert.notEqual(pricedDay.cents, catalogDay.cents);
  sold.db.endDay(4);
  const later = sold.db.tycoon.view().history[0];
  assert.equal((later?.salesCents ?? 0) - 20_700, pricedDay.cents);
  assert.equal((later?.fans ?? 0) - 5, pricedDay.fans);
  const next = sold.db.journey.db.prepare("SELECT cash_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:p1:1'").get() as { cash_delta: number; reputation_delta: number };
  assert.equal(next.cash_delta, pricedDay.cents);
  assert.equal(next.reputation_delta, pricedDay.fans);
  assert.equal((sold.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:p1:0'").get() as { cash_delta: number }).cash_delta, 20_700);
  let reputation = before.fans + pricedDay.fans;
  let salesCents = 20_700 + pricedDay.cents;
  for (const dayIndex of [2, 3]) {
    const day = salesForDay({
      seed: 26021, productId: "p1", typeId: "newsletter", fit: "great", score, dayIndex, reputation, pricePercent: 80,
    });
    sold.db.endDay(sold.db.clockState().day);
    salesCents += day.cents;
    reputation += day.fans;
  }
  assert.equal(sold.db.tycoon.view().history[0]?.status, "complete");
  assert.equal(sold.db.tycoon.view().history[0]?.salesCents, salesCents);
  assert.equal(sold.db.tycoon.view().history[0]?.fans, reputation);
  assert.equal(sold.db.tycoon.view().history[0]?.salePrice, null);
  assert.equal(JSON.parse(staffJson(sold.db, "p1")).salePricePercent, 80);
  assert.throws(() => sold.db.tycoon.salePrice("p1", 120), /No product is selling\./u);
  const finishedSales = sold.db.tycoon.view().history[0]?.salesCents ?? 0;
  sold.db.tycoon.port("p1");
  const atLaunch = expectedPortSale(sold.db, "p1", sold.db.clockState().day, score);
  const atSale = salesForDay({
    seed: 26021,
    productId: "p1",
    typeId: "newsletter",
    fit: "great",
    score,
    dayIndex: SALES_WINDOW_DAYS,
    reputation: sold.db.journey.state().company.reputation,
    pricePercent: 80,
  });
  assert.notEqual(atLaunch.cents, atSale.cents);
  sold.db.endDay(sold.db.clockState().day);
  assert.equal(productById(sold.db, "p1")?.port?.cents, atLaunch.cents);
  assert.equal(productById(sold.db, "p1")?.salesCents, finishedSales + atLaunch.cents);
  assert.equal((sold.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:p1:0'").get() as { cash_delta: number }).cash_delta, 20_700);
  sold.db.close();

  const cheap = await setup();
  cheap.db.tycoon.start("crypto", "newsletter", [], 80);
  cheap.db.endDay(1);
  cheap.db.endDay(2);
  cheap.db.tycoon.release("p1");
  const cheapSales = cheap.db.tycoon.view().history[0]?.salesCents;
  assert.throws(() => cheap.db.tycoon.salePrice("p1", 80), /Price is unchanged\./u);
  cheap.db.tycoon.salePrice("p1", 100);
  assert.equal(cheap.db.tycoon.view().history[0]?.pricePercent, 80);
  assert.equal(cheap.db.tycoon.view().history[0]?.salePrice?.currentPercent, 100);
  assert.equal(cheap.db.tycoon.view().history[0]?.salesCents, cheapSales);
  assert.equal(JSON.parse(staffJson(cheap.db, "p1")).pricePercent, 80);
  assert.equal(JSON.parse(staffJson(cheap.db, "p1")).salePricePercent, 100);
  cheap.db.close();

  const reopen = await setup();
  reopen.db.tycoon.start("crypto", "newsletter", []);
  reopen.db.endDay(1);
  reopen.db.endDay(2);
  reopen.db.tycoon.release("p1");
  const untouched = staffJson(reopen.db, "p1");
  reopen.db.tycoon.view();
  assert.equal(staffJson(reopen.db, "p1"), untouched);
  assert.equal(JSON.parse(untouched).salePricePercent, undefined);
  reopen.db.tycoon.salePrice("p1", 80);
  const pending = reopen.db.tycoon.view().history[0]?.salePrice;
  const pendingStaff = staffJson(reopen.db, "p1");
  const file = join(reopen.root, "game.sqlite");
  const project = join(reopen.root, "company-project");
  reopen.db.close();
  const reopened = new GameDatabase(file, project);
  assert.deepEqual(reopened.tycoon.view().history[0]?.salePrice, pending);
  assert.equal(staffJson(reopened, "p1"), pendingStaff);
  assert.equal(reopened.journey.state().company.cashCents, 20_700);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, 20_700);
  assert.throws(() => reopened.tycoon.salePrice("p1", 120), /A sale price was already set\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.endDay(3);
  reopened.endDay(4);
  const resumed = salesForDay({
    seed: 26021, productId: "p1", typeId: "newsletter", fit: "great", score: 6, dayIndex: 1, reputation: 5, pricePercent: 80,
  });
  assert.equal((reopened.tycoon.view().history[0]?.salesCents ?? 0) - 20_700, resumed.cents);
  reopened.close();

  const legacy = await setup();
  legacy.db.tycoon.start("crypto", "newsletter", []);
  legacy.db.endDay(1);
  legacy.db.endDay(2);
  legacy.db.tycoon.release("p1");
  legacy.db.journey.db.prepare("UPDATE tycoon_products SET staff_json = ? WHERE id = 'p1'").run(JSON.stringify(["founder"]));
  assert.deepEqual(legacy.db.tycoon.view().history[0]?.salePrice, offer);
  assert.equal(staffJson(legacy.db, "p1"), JSON.stringify(["founder"]));
  legacy.db.close();
});

test("letGo dismisses a hired teammate and leaves earned days in place", async () => {
  assert.equal(
    parseRequest({ kind: "request", id: "letgo", method: "tycoon.letGo", params: { staffId: "mira" } }).method,
    "tycoon.letGo",
  );
  assert.equal(
    parseRequest({ kind: "request", id: "letgo", method: "tycoon.letGo", params: { staffId: "founder" } }).method,
    "tycoon.letGo",
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "letgo", method: "tycoon.letGo", params: { staffId: "nope" } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "letgo", method: "tycoon.letGo", params: {} }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "letgo", method: "tycoon.letGo", params: { staffId: "mira", extra: true } }),
    /Invalid protocol request/u,
  );
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("letGo(staffId: string");
  const body = source.slice(bodyStart, source.indexOf("researchSpike()", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("The founder stays."), "letGo lives in the harness");
  assert.ok(body.includes("already left."), "a repeat fails clearly");
  assert.ok(body.includes("is not on the team yet."), "an unhired teammate fails clearly");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);

  const fresh = await setup();
  const freshStaff = fresh.db.tycoon.view().staff;
  assert.deepEqual(freshStaff.find((person) => person.id === "founder")?.letGo, { enabled: false, reason: "The founder stays." });
  assert.deepEqual(freshStaff.find((person) => person.id === "mira")?.letGo, { enabled: false, reason: "Mina is not on the team yet." });
  assert.equal(fresh.db.tycoon.view().letGoNotice, "");
  assert.throws(() => fresh.db.tycoon.letGo("founder"), /The founder stays\./u);
  assert.throws(() => fresh.db.tycoon.letGo("nope"), /Unknown teammate/u);
  assert.throws(() => fresh.db.tycoon.letGo("mira"), /Mina is not on the team yet\./u);
  assert.throws(() => fresh.db.tycoon.letGo("theo"), /Theo is not on the team yet\./u);
  assert.equal(fresh.db.tycoon.view().payroll.cents, 0);
  assert.equal(validate(fresh.db.journey.state()), true, JSON.stringify(validate.errors));
  fresh.db.close();

  const bench = await setup();
  bench.db.journey.hire("mira", 1);
  bench.db.tycoon.start("crypto", "newsletter", ["mira"]);
  bench.db.endDay(1);
  const worked = bench.db.tycoon.view().developing;
  assert.deepEqual(worked?.staffIds, ["founder", "mira"]);
  assert.equal(worked?.devDays, 1);
  assert.equal(worked?.design, 5);
  assert.equal(worked?.tech, 4);
  assert.equal(worked?.hype, 3);
  assert.equal(bench.db.tycoon.view().payroll.cents, 8_000);
  assert.equal(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.letGo.enabled, true);
  const before = {
    txs: txIds(bench.db),
    day: bench.db.clockState().day,
    cash: bench.db.journey.state().company.cashCents,
    fans: bench.db.journey.state().company.reputation,
    points: pointsOf(bench.db, "p1"),
    seed: Number((bench.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  };
  assert.equal(before.seed, 26021);
  const untouched = staffJson(bench.db, "p1");
  bench.db.tycoon.view();
  assert.equal(staffJson(bench.db, "p1"), untouched);
  bench.db.tycoon.letGo("mira");
  assert.throws(() => bench.db.tycoon.letGo("mira"), /Mina already left\./u);
  const dropped = bench.db.tycoon.view().developing;
  assert.deepEqual(dropped?.staffIds, ["founder"]);
  assert.equal(dropped?.devDays, 1);
  assert.equal(dropped?.design, 5);
  assert.equal(dropped?.tech, 4);
  assert.equal(dropped?.hype, 3);
  assert.deepEqual(pointsOf(bench.db, "p1"), before.points);
  assert.deepEqual(JSON.parse(staffJson(bench.db, "p1")).staff.map((person: { id: string }) => person.id), ["founder"]);
  assert.equal(bench.db.clockState().day, before.day);
  assert.equal(bench.db.journey.state().company.cashCents, before.cash);
  assert.equal(bench.db.journey.state().company.reputation, before.fans);
  assert.equal(Number((bench.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), before.seed);
  assert.deepEqual(txIds(bench.db), before.txs);
  assert.equal(bench.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:letgo%' OR id LIKE 'tycoon:letGo%'").all().length, 0);
  assert.equal(bench.db.tycoon.view().payroll.cents, 0);
  assert.equal(bench.db.tycoon.view().letGoNotice, "Mina left the company.");
  assert.deepEqual(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.letGo, { enabled: false, reason: "Mina already left." });
  assert.equal(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.hired, false);
  assert.equal(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.design, 3);
  assert.equal(bench.db.bootstrap().employees.some((person) => person.id === "mira"), false);
  assert.equal(validate(bench.db.journey.state()), true, JSON.stringify(validate.errors));
  const kept = staffJson(bench.db, "p1");
  bench.db.tycoon.view();
  assert.equal(staffJson(bench.db, "p1"), kept);
  bench.db.endDay(bench.db.clockState().day);
  const later = bench.db.tycoon.view().developing;
  assert.equal(later?.devDays, 2);
  assert.equal(later?.design, 7);
  assert.equal(later?.tech, 6);
  assert.equal(later?.hype, 5);
  assert.deepEqual(later?.staffIds, ["founder"]);
  const file = join(bench.root, "game.sqlite");
  const project = join(bench.root, "company-project");
  bench.db.close();
  const reopened = new GameDatabase(file, project);
  assert.equal(reopened.tycoon.view().letGoNotice, "Mina left the company.");
  assert.deepEqual(reopened.tycoon.view().developing?.staffIds, ["founder"]);
  assert.equal(reopened.tycoon.view().developing?.design, 7);
  assert.equal(reopened.tycoon.view().payroll.cents, 0);
  assert.equal(reopened.bootstrap().employees.some((person) => person.id === "mira"), false);
  assert.throws(() => reopened.tycoon.letGo("mira"), /Mina already left\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.journey.hire("mira", reopened.clockState().day);
  assert.equal(reopened.tycoon.view().payroll.cents, 8_000);
  assert.equal(reopened.tycoon.view().letGoNotice, "");
  assert.equal(reopened.tycoon.view().staff.find((person) => person.id === "mira")?.letGo.enabled, true);
  assert.equal(reopened.tycoon.view().staff.find((person) => person.id === "mira")?.design, 3);
  assert.equal(reopened.bootstrap().employees.some((person) => person.id === "mira"), true);
  reopened.tycoon.letGo("mira");
  assert.throws(() => reopened.tycoon.letGo("mira"), /Mina already left\./u);
  assert.equal(reopened.tycoon.view().payroll.cents, 0);
  reopened.close();

  const sitting = await setup();
  sitting.db.journey.hire("mira", 1);
  sitting.db.tycoon.start("crypto", "newsletter", []);
  const founderOnly = staffJson(sitting.db, "p1");
  sitting.db.tycoon.letGo("mira");
  assert.equal(staffJson(sitting.db, "p1"), founderOnly);
  sitting.db.close();

  const alone = await setup();
  alone.db.journey.hire("mira", 1);
  alone.db.tycoon.start("crypto", "newsletter", ["mira"]);
  alone.db.tycoon.assignTeam(["mira"]);
  alone.db.endDay(1);
  assert.deepEqual(alone.db.tycoon.view().developing?.staffIds, ["mira"]);
  assert.equal(alone.db.tycoon.view().developing?.design, 3);
  assert.equal(alone.db.tycoon.view().developing?.tech, 2);
  assert.equal(alone.db.tycoon.view().developing?.hype, 1);
  alone.db.tycoon.letGo("mira");
  assert.deepEqual(alone.db.tycoon.view().developing?.staffIds, []);
  assert.equal(alone.db.tycoon.view().developing?.design, 3);
  alone.db.endDay(alone.db.clockState().day);
  assert.equal(alone.db.tycoon.view().developing?.devDays, 2);
  assert.equal(alone.db.tycoon.view().developing?.design, 3);
  assert.equal(alone.db.tycoon.view().developing?.tech, 2);
  assert.equal(alone.db.tycoon.view().developing?.hype, 1);
  alone.db.close();

  const payday = await setup();
  payday.db.journey.hire("mira", 1);
  payday.db.setClock(27, 480, 0);
  payday.db.endDay(27);
  assert.equal(payday.db.clockState().day, 28);
  payday.db.tycoon.letGo("mira");
  payday.db.tycoon.tickDay(28);
  assert.equal(payday.db.journey.state().company.cashCents, 0);
  assert.equal(payday.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:payroll:%'").all().length, 0);
  assert.equal(payday.db.tycoon.view().payroll.cents, 0);
  payday.db.close();

  const trained = await setup();
  trained.db.journey.recordCompanyChange("letgo-train-cash", 1, 50_000, 0, 0, "Train cash");
  trained.db.journey.hire("mira", 1);
  trained.db.tycoon.train("mira", "design");
  trained.db.tycoon.letGo("mira");
  assert.equal(trained.db.tycoon.view().staff.find((person) => person.id === "mira")?.design, 4);
  assert.equal(trained.db.tycoon.view().staff.find((person) => person.id === "mira")?.hired, false);
  trained.db.journey.hire("mira", 1);
  assert.equal(trained.db.tycoon.view().staff.find((person) => person.id === "mira")?.design, 4);
  assert.equal(trained.db.tycoon.view().staff.find((person) => person.id === "mira")?.hired, true);
  trained.db.close();

  const gated = await setup();
  gated.db.journey.db.prepare("UPDATE employees SET employment_status = 'hired', hired_day = 1 WHERE id = 'theo'").run();
  assert.equal(gated.db.tycoon.view().payroll.cents, 10_000);
  gated.db.tycoon.letGo("theo");
  assert.throws(() => gated.db.journey.hire("theo", 1), /Candidate is not available yet/u);
  assert.equal(gated.db.tycoon.view().letGoNotice, "Theo left the company.");
  gated.db.journey.db.prepare("UPDATE employees SET employment_status = 'hired', hired_day = 1 WHERE id = 'mira'").run();
  gated.db.tycoon.letGo("mira");
  assert.equal(gated.db.tycoon.view().letGoNotice, "Mina left the company. Theo left the company.");
  gated.db.close();

  const shipped = await setup();
  const stayed = await setup();
  for (const ctx of [shipped, stayed]) {
    ctx.db.journey.hire("mira", 1);
    ctx.db.tycoon.start("crypto", "newsletter", ["mira"]);
    ctx.db.endDay(1);
    ctx.db.endDay(2);
    ctx.db.tycoon.release("p1");
  }
  const postedSales = shipped.db.tycoon.view().history[0]?.salesCents;
  const postedFans = shipped.db.tycoon.view().history[0]?.fans;
  const postedStaff = staffJson(shipped.db, "p1");
  assert.equal(postedSales, stayed.db.tycoon.view().history[0]?.salesCents);
  assert.ok(JSON.parse(postedStaff).staff.some((person: { id: string }) => person.id === "mira"));
  shipped.db.tycoon.letGo("mira");
  assert.equal(staffJson(shipped.db, "p1"), postedStaff);
  assert.equal(shipped.db.tycoon.view().history[0]?.salesCents, postedSales);
  assert.equal(shipped.db.tycoon.view().history[0]?.fans, postedFans);
  shipped.db.endDay(3);
  stayed.db.endDay(3);
  shipped.db.endDay(4);
  stayed.db.endDay(4);
  assert.equal(shipped.db.tycoon.view().history[0]?.salesCents, stayed.db.tycoon.view().history[0]?.salesCents);
  assert.equal(shipped.db.tycoon.view().history[0]?.fans, stayed.db.tycoon.view().history[0]?.fans);
  assert.equal(shipped.db.journey.state().company.cashCents, stayed.db.journey.state().company.cashCents);
  assert.equal(staffJson(shipped.db, "p1"), postedStaff);
  shipped.db.close();
  stayed.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 33_300);
  assert.equal(skip.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:letgo%' OR id LIKE 'tycoon:letGo%'").all().length, 0);
  skip.db.close();
});

test("setPace halves later craft and salary and leaves posted days alone", async () => {
  assert.equal(
    parseRequest({ kind: "request", id: "pace", method: "tycoon.setPace", params: { staffId: "mira", pace: "part" } }).method,
    "tycoon.setPace",
  );
  assert.equal(
    parseRequest({ kind: "request", id: "pace", method: "tycoon.setPace", params: { staffId: "founder", pace: "full" } }).method,
    "tycoon.setPace",
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "pace", method: "tycoon.setPace", params: { staffId: "nope", pace: "part" } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "pace", method: "tycoon.setPace", params: { staffId: "mira", pace: "half" } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "pace", method: "tycoon.setPace", params: { staffId: "mira" } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "pace", method: "tycoon.setPace", params: { staffId: "mira", pace: "part", extra: true } }),
    /Invalid protocol request/u,
  );
  assert.deepEqual(pacedCraft({ design: 3, tech: 2, hype: 1 }, "part"), { design: 1, tech: 1, hype: 0 });
  assert.deepEqual(pacedCraft({ design: 3, tech: 2, hype: 1 }, "full"), { design: 3, tech: 2, hype: 1 });
  assert.equal(payrollCents(["mira"], { mira: "part" }), 4_000);
  assert.equal(payrollCents(["theo"], { theo: "part" }), 5_000);
  assert.equal(payrollCents(["creative"], { creative: "part" }), 6_000);
  assert.equal(payrollCents(["mira", "theo"], { mira: "part" }), 14_000);
  assert.equal(payrollCents(["mira"]), 8_000);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("setPace(staffId: string");
  const body = source.slice(bodyStart, source.indexOf("letGo(staffId: string", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("The founder stays full time."), "setPace lives in the harness");
  assert.ok(body.includes("Pick full time or part-time."), "a bad pace fails clearly");
  assert.ok(body.includes("already part-time."), "a no-op fails clearly");
  assert.ok(body.includes("already full time."), "a full-time no-op fails clearly");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const full = { value: "full", enabled: true, reason: "" };
  const part = { value: "part", enabled: true, reason: "" };

  const fresh = await setup();
  const freshStaff = fresh.db.tycoon.view().staff;
  assert.deepEqual(freshStaff.find((person) => person.id === "founder")?.pace, { value: "full", enabled: false, reason: "The founder stays full time." });
  assert.deepEqual(freshStaff.find((person) => person.id === "mira")?.pace, { value: "full", enabled: false, reason: "Mina is not on the team yet." });
  assert.throws(() => fresh.db.tycoon.setPace("founder", "part"), /The founder stays full time\./u);
  assert.throws(() => fresh.db.tycoon.setPace("founder", "full"), /The founder stays full time\./u);
  assert.throws(() => fresh.db.tycoon.setPace("founder", "sideways"), /Pick full time or part-time\./u);
  assert.throws(() => fresh.db.tycoon.setPace("nope", "part"), /Unknown teammate/u);
  assert.throws(() => fresh.db.tycoon.setPace("nope", "sideways"), /Unknown teammate/u);
  assert.throws(() => fresh.db.tycoon.setPace("mira", "part"), /Mina is not on the team yet\./u);
  assert.throws(() => fresh.db.tycoon.setPace("mira", "full"), /Mina is not on the team yet\./u);
  assert.throws(() => fresh.db.tycoon.setPace("theo", "part"), /Theo is not on the team yet\./u);
  assert.throws(() => fresh.db.tycoon.setPace("mira", "half"), /Pick full time or part-time\./u);
  assert.equal(fresh.db.tycoon.view().payroll.cents, 0);
  assert.equal(validate(fresh.db.journey.state()), true, JSON.stringify(validate.errors));
  fresh.db.close();

  const bench = await setup();
  bench.db.journey.hire("mira", 1);
  bench.db.tycoon.start("crypto", "newsletter", ["mira"]);
  bench.db.endDay(1);
  const worked = bench.db.tycoon.view().developing;
  assert.equal(worked?.devDays, 1);
  assert.equal(worked?.design, 5);
  assert.equal(worked?.tech, 4);
  assert.equal(worked?.hype, 3);
  assert.equal(bench.db.tycoon.view().researchPoints, 2);
  assert.deepEqual(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.pace, full);
  assert.equal(bench.db.tycoon.view().payroll.cents, 8_000);
  assert.throws(() => bench.db.tycoon.setPace("mira", "full"), /Mina is already full time\./u);
  const before = {
    txs: txIds(bench.db),
    day: bench.db.clockState().day,
    cash: bench.db.journey.state().company.cashCents,
    fans: bench.db.journey.state().company.reputation,
    points: pointsOf(bench.db, "p1"),
    seed: Number((bench.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  };
  assert.equal(before.seed, 26021);
  const untouched = staffJson(bench.db, "p1");
  bench.db.tycoon.setPace("mira", "part");
  assert.throws(() => bench.db.tycoon.setPace("mira", "part"), /Mina is already part-time\./u);
  assert.deepEqual(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.pace, part);
  assert.equal(bench.db.tycoon.view().payroll.cents, 4_000);
  assert.deepEqual(pointsOf(bench.db, "p1"), before.points);
  assert.equal(bench.db.tycoon.view().developing?.design, 5);
  assert.equal(bench.db.tycoon.view().developing?.tech, 4);
  assert.equal(bench.db.tycoon.view().developing?.hype, 3);
  assert.equal(staffJson(bench.db, "p1"), untouched);
  assert.equal(bench.db.clockState().day, before.day);
  assert.equal(bench.db.journey.state().company.cashCents, before.cash);
  assert.equal(bench.db.journey.state().company.reputation, before.fans);
  assert.equal(Number((bench.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), before.seed);
  assert.deepEqual(txIds(bench.db), before.txs);
  assert.equal(bench.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:pace%' OR id LIKE 'tycoon:setPace%' OR id LIKE 'tycoon:setpace%'").all().length, 0);
  const meta = JSON.parse(String((bench.db.journey.db.prepare("SELECT staff_json FROM tycoon_meta WHERE id = 1").get() as { staff_json: string }).staff_json)) as { mira: { pace?: string }; founder: { pace?: string } };
  assert.equal(meta.mira.pace, "part");
  assert.equal(meta.founder.pace, undefined);
  bench.db.tycoon.view();
  assert.equal(staffJson(bench.db, "p1"), untouched);
  bench.db.endDay(bench.db.clockState().day);
  const halved = bench.db.tycoon.view().developing;
  assert.equal(halved?.devDays, 2);
  assert.equal(halved?.design, 8);
  assert.equal(halved?.tech, 7);
  assert.equal(halved?.hype, 5);
  assert.equal(bench.db.tycoon.view().researchPoints, 4);
  bench.db.tycoon.setPace("mira", "full");
  assert.throws(() => bench.db.tycoon.setPace("mira", "full"), /Mina is already full time\./u);
  assert.equal(bench.db.tycoon.view().developing?.design, 8);
  assert.equal(bench.db.tycoon.view().payroll.cents, 8_000);
  assert.deepEqual(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.pace, full);
  const restoredMeta = JSON.parse(String((bench.db.journey.db.prepare("SELECT staff_json FROM tycoon_meta WHERE id = 1").get() as { staff_json: string }).staff_json)) as { mira: { pace?: string } };
  assert.equal(restoredMeta.mira.pace, undefined);
  bench.db.endDay(bench.db.clockState().day);
  const restored = bench.db.tycoon.view().developing;
  assert.equal(restored?.devDays, 3);
  assert.equal(restored?.design, 13);
  assert.equal(restored?.tech, 11);
  assert.equal(restored?.hype, 8);
  assert.equal(validate(bench.db.journey.state()), true, JSON.stringify(validate.errors));
  bench.db.close();

  const reopen = await setup();
  reopen.db.journey.hire("mira", 1);
  reopen.db.tycoon.setPace("mira", "part");
  const pending = reopen.db.tycoon.view().staff.find((person) => person.id === "mira")?.pace;
  assert.deepEqual(pending, part);
  assert.equal(reopen.db.tycoon.view().payroll.cents, 4_000);
  const file = join(reopen.root, "game.sqlite");
  const project = join(reopen.root, "company-project");
  reopen.db.close();
  const reopened = new GameDatabase(file, project);
  assert.deepEqual(reopened.tycoon.view().staff.find((person) => person.id === "mira")?.pace, pending);
  assert.equal(reopened.tycoon.view().payroll.cents, 4_000);
  assert.throws(() => reopened.tycoon.setPace("mira", "part"), /Mina is already part-time\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.tycoon.letGo("mira");
  assert.throws(() => reopened.tycoon.setPace("mira", "part"), /Mina already left\./u);
  assert.deepEqual(reopened.tycoon.view().staff.find((person) => person.id === "mira")?.pace, { value: "full", enabled: false, reason: "Mina already left." });
  reopened.journey.hire("mira", reopened.clockState().day);
  assert.deepEqual(reopened.tycoon.view().staff.find((person) => person.id === "mira")?.pace, full);
  assert.equal(reopened.tycoon.view().payroll.cents, 8_000);
  assert.throws(() => reopened.tycoon.setPace("mira", "full"), /Mina is already full time\./u);
  reopened.tycoon.setPace("mira", "part");
  assert.deepEqual(reopened.tycoon.view().staff.find((person) => person.id === "mira")?.pace, part);
  reopened.close();

  const payday = await setup();
  payday.db.journey.hire("mira", 1);
  payday.db.tycoon.setPace("mira", "part");
  payday.db.setClock(27, 480, 0);
  payday.db.endDay(27);
  assert.equal(payday.db.journey.state().company.cashCents, 0);
  payday.db.tycoon.tickDay(28);
  assert.equal(payday.db.journey.state().company.cashCents, -4_000);
  assert.equal((payday.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'").get() as { cash_delta: number }).cash_delta, -4_000);
  payday.db.tycoon.tickDay(28);
  assert.equal(payday.db.journey.state().company.cashCents, -4_000);
  payday.db.close();

  const shipped = await setup();
  const stayed = await setup();
  for (const ctx of [shipped, stayed]) {
    ctx.db.journey.hire("mira", 1);
    ctx.db.tycoon.start("crypto", "newsletter", ["mira"]);
    ctx.db.endDay(1);
    ctx.db.endDay(2);
    ctx.db.tycoon.release("p1");
  }
  const postedSales = shipped.db.tycoon.view().history[0]?.salesCents;
  const postedFans = shipped.db.tycoon.view().history[0]?.fans;
  const postedStaff = staffJson(shipped.db, "p1");
  shipped.db.tycoon.setPace("mira", "part");
  assert.equal(shipped.db.tycoon.view().history[0]?.salesCents, postedSales);
  assert.equal(shipped.db.tycoon.view().history[0]?.fans, postedFans);
  assert.equal(staffJson(shipped.db, "p1"), postedStaff);
  shipped.db.endDay(3);
  stayed.db.endDay(3);
  assert.equal(shipped.db.tycoon.view().history[0]?.salesCents, stayed.db.tycoon.view().history[0]?.salesCents);
  assert.equal(shipped.db.tycoon.view().history[0]?.fans, stayed.db.tycoon.view().history[0]?.fans);
  shipped.db.close();
  stayed.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 33_300);
  assert.equal(skip.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:pace%' OR id LIKE 'tycoon:setPace%' OR id LIKE 'tycoon:setpace%'").all().length, 0);
  skip.db.close();
});

test("listCatalog pays score * 200 on later paydays and leaves posted sales alone", async () => {
  assert.equal(CATALOG_CENTS_PER_SCORE, 200);
  assert.equal(catalogCheckCents(6), 1_200);
  assert.equal(catalogCheckCents(0), 0);
  assert.equal(catalogPaydayDay(3, null), 28);
  assert.equal(catalogPaydayDay(3, 3), 28);
  assert.equal(catalogPaydayDay(28, 3), 28);
  assert.equal(catalogPaydayDay(28, null), 56);
  assert.equal(catalogPaydayDay(28, 28), 56);
  assert.equal(catalogPaydayDay(30, 3), 56);
  assert.equal(
    parseRequest({ kind: "request", id: "catalog", method: "tycoon.listCatalog", params: { productId: "p1" } }).method,
    "tycoon.listCatalog",
  );
  assert.equal(
    parseRequest({ kind: "request", id: "catalog", method: "tycoon.delistCatalog", params: {} }).method,
    "tycoon.delistCatalog",
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "catalog", method: "tycoon.listCatalog", params: {} }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "catalog", method: "tycoon.listCatalog", params: { productId: "nope" } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "catalog", method: "tycoon.listCatalog", params: { productId: "p1", extra: true } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "catalog", method: "tycoon.delistCatalog", params: { productId: "p1" } }),
    /Invalid protocol request/u,
  );
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("listCatalog(productId: string");
  const body = source.slice(bodyStart, source.indexOf("letGo(staffId: string", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("This product is not finished."), "an unfinished product fails clearly");
  assert.ok(body.includes("Already listed."), "listing twice fails clearly");
  assert.ok(body.includes("A product is already listed."), "a second product does not swap");
  assert.ok(body.includes("Nothing is listed."), "delist with an empty slot fails clearly");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const emptyList = { productId: null, enabled: false, reason: "Ship a product first." };
  const emptyDelist = { enabled: false, reason: "Nothing is listed." };

  const fresh = await setup();
  assert.deepEqual(fresh.db.tycoon.view().catalog, {
    productId: null,
    name: "",
    score: 0,
    checkCents: 0,
    payday: "Spring 28",
    list: emptyList,
    delist: emptyDelist,
  });
  assert.throws(() => fresh.db.tycoon.listCatalog("p1"), /No product with that id\./u);
  assert.throws(() => fresh.db.tycoon.listCatalog("p99"), /No product with that id\./u);
  assert.throws(() => fresh.db.tycoon.delistCatalog(), /Nothing is listed\./u);
  fresh.db.tycoon.start("crypto", "newsletter", []);
  assert.throws(() => fresh.db.tycoon.listCatalog("p1"), /This product is not finished\./u);
  assert.equal(fresh.db.tycoon.view().catalog.list.enabled, false);
  fresh.db.tycoon.cancelBuild();
  assert.throws(() => fresh.db.tycoon.listCatalog("p1"), /No product with that id\./u);
  assert.equal(validate(fresh.db.journey.state()), true, JSON.stringify(validate.errors));
  const older = structuredClone(fresh.db.journey.state()) as { tycoon: { catalog?: unknown } };
  delete older.tycoon.catalog;
  assert.equal(validate(older), true, JSON.stringify(validate.errors));
  fresh.db.close();

  const listed = await setup();
  const plain = await setup();
  for (const ctx of [listed, plain]) {
    ctx.db.tycoon.start("crypto", "newsletter", []);
    ctx.db.endDay(1);
    ctx.db.endDay(2);
    ctx.db.tycoon.release("p1");
  }
  assert.equal(listed.db.journey.state().company.cashCents, 20_700);
  assert.equal(listed.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(listed.db.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(listed.db.tycoon.view().history[0]?.review?.score, 6);
  const beforeList = {
    txs: txIds(listed.db),
    day: listed.db.clockState().day,
    cash: listed.db.journey.state().company.cashCents,
    fans: listed.db.journey.state().company.reputation,
    sales: listed.db.tycoon.view().history[0]?.salesCents,
    productFans: listed.db.tycoon.view().history[0]?.fans,
    seed: Number((listed.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  };
  assert.equal(beforeList.seed, 26021);
  const offer = listed.db.tycoon.view().catalog;
  assert.equal(offer.productId, null);
  assert.equal(offer.name, "Crypto Alpha Newsletter");
  assert.equal(offer.score, 6);
  assert.equal(offer.checkCents, 1_200);
  assert.equal(offer.payday, "Spring 28");
  assert.deepEqual(offer.list, { productId: "p1", enabled: true, reason: "" });
  assert.deepEqual(offer.delist, { enabled: false, reason: "Nothing is listed." });
  listed.db.tycoon.listCatalog("p1");
  assert.throws(() => listed.db.tycoon.listCatalog("p1"), /Already listed\./u);
  const after = listed.db.tycoon.view().catalog;
  assert.equal(after.productId, "p1");
  assert.equal(after.checkCents, 1_200);
  assert.equal(after.payday, "Spring 28");
  assert.deepEqual(after.list, { productId: "p1", enabled: false, reason: "Already listed." });
  assert.deepEqual(after.delist, { enabled: true, reason: "" });
  assert.equal(listed.db.clockState().day, beforeList.day);
  assert.equal(listed.db.journey.state().company.cashCents, beforeList.cash);
  assert.equal(listed.db.journey.state().company.reputation, beforeList.fans);
  assert.equal(listed.db.tycoon.view().history[0]?.salesCents, beforeList.sales);
  assert.equal(listed.db.tycoon.view().history[0]?.fans, beforeList.productFans);
  assert.deepEqual(txIds(listed.db), beforeList.txs);
  assert.equal(Number((listed.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), beforeList.seed);
  const stored = JSON.parse(staffJson(listed.db, "p1")) as { catalogDay?: number };
  assert.equal(stored.catalogDay, beforeList.day);
  const untouched = staffJson(listed.db, "p1");
  listed.db.tycoon.view();
  assert.equal(staffJson(listed.db, "p1"), untouched);
  listed.db.endDay(3);
  plain.db.endDay(3);
  listed.db.endDay(4);
  plain.db.endDay(4);
  assert.equal(listed.db.journey.state().company.cashCents, 33_300);
  assert.equal(plain.db.journey.state().company.cashCents, 33_300);
  assert.equal(listed.db.tycoon.view().history[0]?.salesCents, plain.db.tycoon.view().history[0]?.salesCents);
  assert.equal(listed.db.tycoon.view().history[0]?.fans, plain.db.tycoon.view().history[0]?.fans);
  assert.equal(listed.db.journey.state().company.reputation, plain.db.journey.state().company.reputation);
  assert.equal(listed.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:catalog%'").all().length, 0);
  listed.db.setClock(28, 480, 0);
  plain.db.setClock(28, 480, 0);
  listed.db.tycoon.tickDay(28);
  plain.db.tycoon.tickDay(28);
  const check = listed.db.journey.db.prepare(
    "SELECT cash_delta, earned_delta, reputation_delta, label FROM company_transactions WHERE id = 'tycoon:catalog:1-spring'",
  ).get() as { cash_delta: number; earned_delta: number; reputation_delta: number; label: string };
  assert.equal(check.cash_delta, 1_200);
  assert.equal(check.earned_delta, 0);
  assert.equal(check.reputation_delta, 0);
  assert.equal(check.label, "Catalog: Crypto Alpha Newsletter");
  assert.equal(listed.db.journey.state().company.cashCents, plain.db.journey.state().company.cashCents + 1_200);
  assert.equal(listed.db.journey.state().company.reputation, plain.db.journey.state().company.reputation);
  assert.equal(listed.db.tycoon.view().history[0]?.salesCents, plain.db.tycoon.view().history[0]?.salesCents);
  assert.equal(listed.db.tycoon.view().history[0]?.fans, plain.db.tycoon.view().history[0]?.fans);
  const saleRows = (db: GameDatabase) => db.journey.db.prepare(
    "SELECT id, cash_delta, earned_delta, reputation_delta FROM company_transactions WHERE id LIKE 'tycoon:p1:%' ORDER BY id",
  ).all();
  assert.deepEqual(saleRows(listed.db), saleRows(plain.db));
  listed.db.tycoon.tickDay(28);
  assert.equal(listed.db.journey.state().company.cashCents, plain.db.journey.state().company.cashCents + 1_200);
  assert.equal(validate(listed.db.journey.state()), true, JSON.stringify(validate.errors));
  listed.db.tycoon.delistCatalog();
  assert.throws(() => listed.db.tycoon.delistCatalog(), /Nothing is listed\./u);
  assert.equal(listed.db.tycoon.view().catalog.productId, null);
  assert.equal(JSON.parse(staffJson(listed.db, "p1")).catalogDay, undefined);
  listed.db.tycoon.tickDay(56);
  plain.db.tycoon.tickDay(56);
  assert.equal(listed.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id = 'tycoon:catalog:1-summer'").get(), undefined);
  assert.equal(listed.db.journey.state().company.cashCents, plain.db.journey.state().company.cashCents + 1_200);
  assert.equal(listed.db.tycoon.view().history[0]?.salesCents, plain.db.tycoon.view().history[0]?.salesCents);
  assert.equal(listed.db.journey.state().company.reputation, plain.db.journey.state().company.reputation);
  listed.db.close();
  plain.db.close();

  const patched = await setup();
  const patchedTwin = await setup();
  for (const ctx of [patched, patchedTwin]) {
    ctx.db.tycoon.start("crypto", "newsletter", []);
    ctx.db.endDay(1);
    ctx.db.endDay(2);
    ctx.db.tycoon.release("p1");
    ctx.db.tycoon.patch("p1");
  }
  const postedSales = patched.db.tycoon.view().history[0]?.salesCents;
  patched.db.tycoon.listCatalog("p1");
  assert.equal(patched.db.tycoon.view().catalog.score, 6);
  assert.equal(patched.db.tycoon.view().catalog.checkCents, 1_200);
  assert.equal(patched.db.tycoon.view().history[0]?.salesCents, postedSales);
  patched.db.tycoon.tickDay(28);
  patchedTwin.db.tycoon.tickDay(28);
  assert.equal((patched.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:catalog:1-spring'").get() as { cash_delta: number }).cash_delta, 1_200);
  assert.equal(patched.db.tycoon.view().history[0]?.salesCents, patchedTwin.db.tycoon.view().history[0]?.salesCents);
  assert.equal(patched.db.journey.state().company.cashCents, patchedTwin.db.journey.state().company.cashCents + 1_200);
  patched.db.close();
  patchedTwin.db.close();

  const second = await setup();
  second.db.tycoon.start("crypto", "newsletter", []);
  second.db.endDay(1);
  second.db.endDay(2);
  second.db.tycoon.release("p1");
  second.db.tycoon.start("fitness", "newsletter", []);
  second.db.endDay(3);
  second.db.endDay(4);
  second.db.tycoon.release("p2");
  assert.equal(second.db.tycoon.view().catalog.list.productId, "p2");
  second.db.tycoon.listCatalog("p1");
  assert.throws(() => second.db.tycoon.listCatalog("p2"), /A product is already listed\./u);
  assert.equal(second.db.tycoon.view().catalog.productId, "p1");
  const firstReview = second.db.tycoon.view().history.find((item) => item.id === "p1")?.review?.score;
  const secondReview = second.db.tycoon.view().history.find((item) => item.id === "p2")?.review?.score;
  const twin = await setup();
  twin.db.tycoon.start("crypto", "newsletter", []);
  twin.db.endDay(1);
  twin.db.endDay(2);
  twin.db.tycoon.release("p1");
  twin.db.tycoon.start("fitness", "newsletter", []);
  twin.db.endDay(3);
  twin.db.endDay(4);
  twin.db.tycoon.release("p2");
  assert.equal(firstReview, twin.db.tycoon.view().history.find((item) => item.id === "p1")?.review?.score);
  assert.equal(secondReview, twin.db.tycoon.view().history.find((item) => item.id === "p2")?.review?.score);
  assert.equal(second.db.tycoon.view().history.find((item) => item.id === "p1")?.salesCents, twin.db.tycoon.view().history.find((item) => item.id === "p1")?.salesCents);
  second.db.close();
  twin.db.close();

  const draw = await setup();
  const drawTwin = await setup();
  for (const ctx of [draw, drawTwin]) {
    ctx.db.tycoon.start("crypto", "newsletter", []);
    ctx.db.endDay(1);
    ctx.db.endDay(2);
    ctx.db.tycoon.release("p1");
  }
  draw.db.tycoon.listCatalog("p1");
  for (const ctx of [draw, drawTwin]) {
    ctx.db.tycoon.start("fitness", "newsletter", []);
    ctx.db.endDay(3);
    ctx.db.endDay(4);
    ctx.db.tycoon.release("p2");
  }
  assert.equal(draw.db.tycoon.view().history.find((item) => item.id === "p2")?.review?.score, drawTwin.db.tycoon.view().history.find((item) => item.id === "p2")?.review?.score);
  assert.equal(draw.db.tycoon.view().history.find((item) => item.id === "p1")?.salesCents, drawTwin.db.tycoon.view().history.find((item) => item.id === "p1")?.salesCents);
  assert.equal(
    Number((draw.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
    Number((drawTwin.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  );
  draw.db.close();
  drawTwin.db.close();

  const sameDay = await setup();
  sameDay.db.tycoon.start("crypto", "newsletter", []);
  sameDay.db.endDay(1);
  sameDay.db.endDay(2);
  sameDay.db.tycoon.release("p1");
  sameDay.db.setClock(28, 480, 0);
  sameDay.db.tycoon.listCatalog("p1");
  assert.equal(sameDay.db.tycoon.view().catalog.payday, "Summer 28");
  const cashOnPayday = sameDay.db.journey.state().company.cashCents;
  sameDay.db.tycoon.tickDay(28);
  assert.equal(sameDay.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:catalog%'").all().length, 0);
  assert.equal(sameDay.db.journey.state().company.cashCents, cashOnPayday + ((sameDay.db.journey.db.prepare("SELECT COALESCE(SUM(cash_delta), 0) AS cents FROM company_transactions WHERE id LIKE 'tycoon:p1:%' AND day = 28").get() as { cents: number }).cents));
  sameDay.db.tycoon.tickDay(56);
  const summer = sameDay.db.journey.db.prepare(
    "SELECT cash_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:catalog:1-summer'",
  ).get() as { cash_delta: number; reputation_delta: number };
  assert.equal(summer.cash_delta, 1_200);
  assert.equal(summer.reputation_delta, 0);
  sameDay.db.close();

  const reopen = await setup();
  reopen.db.tycoon.start("crypto", "newsletter", []);
  reopen.db.endDay(1);
  reopen.db.endDay(2);
  reopen.db.tycoon.release("p1");
  reopen.db.tycoon.listCatalog("p1");
  const pending = reopen.db.tycoon.view().catalog;
  assert.equal(pending.productId, "p1");
  assert.equal(pending.checkCents, 1_200);
  const file = join(reopen.root, "game.sqlite");
  const project = join(reopen.root, "company-project");
  reopen.db.close();
  const reopened = new GameDatabase(file, project);
  assert.deepEqual(reopened.tycoon.view().catalog, pending);
  assert.equal(reopened.journey.state().company.cashCents, 20_700);
  assert.equal(reopened.journey.state().company.reputation, 5);
  assert.equal(reopened.tycoon.view().history[0]?.salesCents, 20_700);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 33_300);
  assert.equal(skip.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:catalog%'").all().length, 0);
  skip.db.close();
});

test("giveRaise lifts the next payday and the lowest stored stat", async () => {
  assert.equal(
    parseRequest({ kind: "request", id: "raise", method: "tycoon.giveRaise", params: { staffId: "mira" } }).method,
    "tycoon.giveRaise",
  );
  assert.equal(
    parseRequest({ kind: "request", id: "raise", method: "tycoon.giveRaise", params: { staffId: "founder" } }).method,
    "tycoon.giveRaise",
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "raise", method: "tycoon.giveRaise", params: { staffId: "nope" } }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "raise", method: "tycoon.giveRaise", params: {} }),
    /Invalid protocol request/u,
  );
  assert.throws(
    () => parseRequest({ kind: "request", id: "raise", method: "tycoon.giveRaise", params: { staffId: "mira", extra: true } }),
    /Invalid protocol request/u,
  );
  assert.equal(lowestCraftStat({ design: 3, tech: 2, hype: 1 }), "hype");
  assert.equal(lowestCraftStat({ design: 1, tech: 2, hype: 3 }), "design");
  assert.equal(lowestCraftStat({ design: 4, tech: 1, hype: 2 }), "tech");
  assert.equal(lowestCraftStat({ design: 2, tech: 2, hype: 2 }), "design");
  assert.equal(lowestCraftStat({ design: 3, tech: 1, hype: 1 }), "tech");
  assert.equal(lowestCraftStat({ design: 1, tech: 2, hype: 1 }), "design");
  assert.equal(lowestCraftStat({ design: 2, tech: 1, hype: 1 }), "tech");
  assert.deepEqual(raisedDayCraft({ design: 3, tech: 2, hype: 1 }, "full", true), { design: 3, tech: 2, hype: 2 });
  assert.deepEqual(raisedDayCraft({ design: 3, tech: 2, hype: 1 }, "part", true), { design: 1, tech: 1, hype: 1 });
  assert.deepEqual(raisedDayCraft({ design: 3, tech: 2, hype: 1 }, "part", false), { design: 1, tech: 1, hype: 0 });
  assert.deepEqual(raisedDayCraft({ design: 3, tech: 2, hype: 2 }, "full", true), { design: 3, tech: 3, hype: 2 });
  assert.deepEqual(raisedDayCraft({ design: 3, tech: 3, hype: 3 }, "full", true), { design: 4, tech: 3, hype: 3 });
  assert.equal(payrollCents(["mira"], {}, { mira: true }), 12_000);
  assert.equal(payrollCents(["mira"], { mira: "part" }, { mira: true }), 6_000);
  assert.equal(payrollCents(["theo"], {}, { theo: true }), 15_000);
  assert.equal(payrollCents(["theo"], { theo: "part" }, { theo: true }), 7_500);
  assert.equal(payrollCents(["creative"], {}, { creative: true }), 18_000);
  assert.equal(payrollCents(["creative"], { creative: "part" }, { creative: true }), 9_000);
  assert.equal(payrollCents(["mira", "theo"], {}, { mira: true }), 22_000);
  assert.equal(payrollCents(["mira", "mira"], {}, { mira: true }), 12_000);
  assert.equal(payrollCents(["founder"], {}, { founder: true }), 0);
  assert.equal(payrollCents(["mira"]), 8_000);
  const source = readFileSync(new URL("../src/tycoon.ts", import.meta.url), "utf8");
  const bodyStart = source.indexOf("giveRaise(staffId: string");
  const body = source.slice(bodyStart, source.indexOf("letGo(staffId: string", bodyStart));
  assert.equal(/fetch|https?:|Connect|credential|openrouter/iu.test(body), false);
  assert.ok(body.includes("The founder cannot take a raise."), "giveRaise lives in the harness");
  assert.ok(body.includes("already has a raise."), "a second raise fails clearly");
  assert.ok(body.includes("is not on the team yet."), "an unhired teammate fails clearly");

  const schema = JSON.parse(readFileSync(new URL("../../contracts/journey.schema.json", import.meta.url), "utf8"));
  const validate = new Ajv2020({ strict: true, allErrors: true }).compile(schema);
  const offer = { raised: false, salaryCents: 12_000, stat: "hype", enabled: true, reason: "" };
  const given = { raised: true, salaryCents: 12_000, stat: "hype", enabled: false, reason: "Mina already has a raise." };

  const fresh = await setup();
  const freshStaff = fresh.db.tycoon.view().staff;
  assert.deepEqual(freshStaff.find((person) => person.id === "founder")?.raise, {
    raised: false, salaryCents: 0, stat: "design", enabled: false, reason: "The founder cannot take a raise.",
  });
  assert.deepEqual(freshStaff.find((person) => person.id === "mira")?.raise, {
    raised: false, salaryCents: 12_000, stat: "hype", enabled: false, reason: "Mina is not on the team yet.",
  });
  assert.throws(() => fresh.db.tycoon.giveRaise("founder"), /The founder cannot take a raise\./u);
  assert.throws(() => fresh.db.tycoon.giveRaise("nope"), /Unknown teammate/u);
  assert.throws(() => fresh.db.tycoon.giveRaise("mira"), /Mina is not on the team yet\./u);
  assert.throws(() => fresh.db.tycoon.giveRaise("theo"), /Theo is not on the team yet\./u);
  assert.equal(fresh.db.tycoon.view().payroll.cents, 0);
  assert.equal(validate(fresh.db.journey.state()), true, JSON.stringify(validate.errors));
  fresh.db.close();

  const bench = await setup();
  bench.db.journey.hire("mira", 1);
  bench.db.tycoon.start("crypto", "newsletter", ["mira"]);
  bench.db.endDay(1);
  const worked = bench.db.tycoon.view().developing;
  assert.equal(worked?.devDays, 1);
  assert.equal(worked?.design, 5);
  assert.equal(worked?.tech, 4);
  assert.equal(worked?.hype, 3);
  assert.equal(bench.db.tycoon.view().researchPoints, 2);
  assert.equal(bench.db.tycoon.view().payroll.cents, 8_000);
  assert.deepEqual(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise, offer);
  const before = {
    txs: txIds(bench.db),
    day: bench.db.clockState().day,
    cash: bench.db.journey.state().company.cashCents,
    fans: bench.db.journey.state().company.reputation,
    points: pointsOf(bench.db, "p1"),
    seed: Number((bench.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed),
  };
  assert.equal(before.seed, 26021);
  const untouched = staffJson(bench.db, "p1");
  bench.db.tycoon.giveRaise("mira");
  assert.throws(() => bench.db.tycoon.giveRaise("mira"), /Mina already has a raise\./u);
  assert.deepEqual(bench.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise, given);
  assert.equal(bench.db.tycoon.view().payroll.cents, 12_000);
  assert.deepEqual(pointsOf(bench.db, "p1"), before.points);
  assert.equal(bench.db.tycoon.view().developing?.design, 5);
  assert.equal(bench.db.tycoon.view().developing?.tech, 4);
  assert.equal(bench.db.tycoon.view().developing?.hype, 3);
  assert.equal(staffJson(bench.db, "p1"), untouched);
  assert.equal(bench.db.clockState().day, before.day);
  assert.equal(bench.db.journey.state().company.cashCents, before.cash);
  assert.equal(bench.db.journey.state().company.reputation, before.fans);
  assert.equal(Number((bench.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), before.seed);
  assert.deepEqual(txIds(bench.db), before.txs);
  assert.equal(bench.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:raise%' OR id LIKE 'tycoon:giveRaise%' OR id LIKE 'tycoon:giveraise%'").all().length, 0);
  const meta = JSON.parse(String((bench.db.journey.db.prepare("SELECT staff_json FROM tycoon_meta WHERE id = 1").get() as { staff_json: string }).staff_json)) as { mira: { raised?: boolean }; founder: { raised?: boolean } };
  assert.equal(meta.mira.raised, true);
  assert.equal(meta.founder.raised, undefined);
  bench.db.endDay(bench.db.clockState().day);
  const bumped = bench.db.tycoon.view().developing;
  assert.equal(bumped?.devDays, 2);
  assert.equal(bumped?.design, 10);
  assert.equal(bumped?.tech, 8);
  assert.equal(bumped?.hype, 7);
  assert.equal(bench.db.tycoon.view().researchPoints, 4);
  assert.equal(validate(bench.db.journey.state()), true, JSON.stringify(validate.errors));
  bench.db.close();

  const halved = await setup();
  halved.db.journey.hire("mira", 1);
  halved.db.tycoon.start("crypto", "newsletter", ["mira"]);
  halved.db.endDay(1);
  halved.db.tycoon.setPace("mira", "part");
  halved.db.tycoon.giveRaise("mira");
  assert.equal(halved.db.tycoon.view().payroll.cents, 6_000);
  assert.deepEqual(halved.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise, {
    raised: true, salaryCents: 6_000, stat: "hype", enabled: false, reason: "Mina already has a raise.",
  });
  halved.db.tycoon.setPace("mira", "full");
  assert.equal(halved.db.tycoon.view().payroll.cents, 12_000);
  assert.equal(halved.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.raised, true);
  halved.db.tycoon.setPace("mira", "part");
  halved.db.endDay(halved.db.clockState().day);
  const mixed = halved.db.tycoon.view().developing;
  assert.equal(mixed?.design, 8);
  assert.equal(mixed?.tech, 7);
  assert.equal(mixed?.hype, 6);
  assert.equal(halved.db.tycoon.view().researchPoints, 4);
  halved.db.close();

  const aside = await setup();
  aside.db.journey.hire("mira", 1);
  aside.db.tycoon.start("crypto", "newsletter", []);
  aside.db.endDay(1);
  assert.equal(aside.db.tycoon.view().developing?.design, 2);
  assert.equal(aside.db.tycoon.view().developing?.tech, 2);
  assert.equal(aside.db.tycoon.view().developing?.hype, 2);
  aside.db.tycoon.giveRaise("mira");
  assert.equal(aside.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.stat, "hype");
  assert.equal(aside.db.tycoon.view().payroll.cents, 12_000);
  aside.db.endDay(aside.db.clockState().day);
  assert.equal(aside.db.tycoon.view().developing?.design, 4);
  assert.equal(aside.db.tycoon.view().developing?.tech, 4);
  assert.equal(aside.db.tycoon.view().developing?.hype, 4);
  aside.db.close();

  const tied = await setup();
  tied.db.journey.hire("mira", 1);
  tied.db.journey.recordCompanyChange("gift-train", 1, trainCostCents(1), 0, 0, "Gift");
  tied.db.tycoon.train("mira", "hype");
  tied.db.endDay(1);
  tied.db.tycoon.start("crypto", "newsletter", ["mira"]);
  tied.db.endDay(tied.db.clockState().day);
  assert.equal(tied.db.tycoon.view().developing?.design, 5);
  assert.equal(tied.db.tycoon.view().developing?.tech, 4);
  assert.equal(tied.db.tycoon.view().developing?.hype, 4);
  assert.equal(tied.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.stat, "tech");
  tied.db.tycoon.giveRaise("mira");
  tied.db.endDay(tied.db.clockState().day);
  assert.equal(tied.db.tycoon.view().developing?.design, 10);
  assert.equal(tied.db.tycoon.view().developing?.tech, 9);
  assert.equal(tied.db.tycoon.view().developing?.hype, 8);
  tied.db.close();

  const three = await setup();
  three.db.journey.hire("mira", 1);
  three.db.journey.recordCompanyChange("gift-train", 1, trainCostCents(1) + trainCostCents(2) + trainCostCents(2), 0, 0, "Gift");
  three.db.tycoon.train("mira", "hype");
  three.db.endDay(1);
  three.db.tycoon.train("mira", "hype");
  three.db.endDay(2);
  three.db.tycoon.train("mira", "tech");
  three.db.endDay(3);
  three.db.tycoon.start("crypto", "newsletter", ["mira"]);
  three.db.endDay(three.db.clockState().day);
  assert.equal(three.db.tycoon.view().developing?.design, 5);
  assert.equal(three.db.tycoon.view().developing?.tech, 5);
  assert.equal(three.db.tycoon.view().developing?.hype, 5);
  assert.equal(three.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.stat, "design");
  three.db.tycoon.giveRaise("mira");
  three.db.endDay(three.db.clockState().day);
  assert.equal(three.db.tycoon.view().developing?.design, 11);
  assert.equal(three.db.tycoon.view().developing?.tech, 10);
  assert.equal(three.db.tycoon.view().developing?.hype, 10);
  three.db.close();

  const laterTrain = await setup();
  laterTrain.db.journey.hire("mira", 1);
  laterTrain.db.tycoon.start("crypto", "newsletter", ["mira"]);
  laterTrain.db.endDay(1);
  laterTrain.db.journey.recordCompanyChange("gift-train", laterTrain.db.clockState().day, trainCostCents(1), 0, 0, "Gift");
  laterTrain.db.tycoon.train("mira", "hype");
  assert.equal(laterTrain.db.tycoon.view().staff.find((person) => person.id === "mira")?.hype, 2);
  assert.equal(laterTrain.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.stat, "hype");
  laterTrain.db.tycoon.giveRaise("mira");
  assert.equal(laterTrain.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.stat, "hype");
  laterTrain.db.close();

  const theo = await setup();
  theo.db.close();
  const theoFile = join(theo.root, "game.sqlite");
  const theoSql = new DatabaseSync(theoFile);
  theoSql.prepare("UPDATE milestone_progress SET completed = 1 WHERE id = 'website'").run();
  theoSql.close();
  const theoDb = new GameDatabase(theoFile, join(theo.root, "company-project"));
  theoDb.journey.recordCompanyChange("gift-theo", 1, 30_000, 0, 0, "Gift");
  theoDb.journey.hire("theo", 1);
  assert.equal(theoDb.journey.state().company.cashCents, 0);
  theoDb.tycoon.start("crypto", "newsletter", ["theo"]);
  theoDb.endDay(1);
  assert.equal(theoDb.tycoon.view().developing?.design, 3);
  assert.equal(theoDb.tycoon.view().developing?.tech, 4);
  assert.equal(theoDb.tycoon.view().developing?.hype, 5);
  assert.equal(theoDb.tycoon.view().staff.find((person) => person.id === "theo")?.raise.stat, "design");
  theoDb.tycoon.giveRaise("theo");
  assert.equal(theoDb.tycoon.view().payroll.cents, 15_000);
  theoDb.endDay(theoDb.clockState().day);
  assert.equal(theoDb.tycoon.view().developing?.design, 7);
  assert.equal(theoDb.tycoon.view().developing?.tech, 8);
  assert.equal(theoDb.tycoon.view().developing?.hype, 10);
  theoDb.close();

  const payday = await setup();
  payday.db.journey.hire("mira", 1);
  payday.db.tycoon.giveRaise("mira");
  payday.db.setClock(27, 480, 0);
  payday.db.endDay(27);
  assert.equal(payday.db.journey.state().company.cashCents, 0);
  assert.equal(payday.db.journey.state().company.reputation, 0);
  payday.db.tycoon.tickDay(28);
  assert.equal(payday.db.journey.state().company.cashCents, -12_000);
  const spring = payday.db.journey.db.prepare("SELECT cash_delta, reputation_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'").get() as { cash_delta: number; reputation_delta: number };
  assert.equal(spring.cash_delta, -12_000);
  assert.equal(spring.reputation_delta, 0);
  payday.db.tycoon.tickDay(28);
  assert.equal(payday.db.journey.state().company.cashCents, -12_000);
  payday.db.close();

  const afterPay = await setup();
  afterPay.db.journey.hire("mira", 1);
  afterPay.db.setClock(27, 480, 0);
  afterPay.db.endDay(27);
  afterPay.db.tycoon.tickDay(28);
  assert.equal(afterPay.db.journey.state().company.cashCents, -8_000);
  afterPay.db.tycoon.giveRaise("mira");
  afterPay.db.tycoon.tickDay(28);
  assert.equal(afterPay.db.journey.state().company.cashCents, -8_000);
  assert.equal((afterPay.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'").get() as { cash_delta: number }).cash_delta, -8_000);
  afterPay.db.tycoon.tickDay(56);
  assert.equal((afterPay.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-summer'").get() as { cash_delta: number }).cash_delta, -12_000);
  assert.equal((afterPay.db.journey.db.prepare("SELECT cash_delta FROM company_transactions WHERE id = 'tycoon:payroll:1-spring'").get() as { cash_delta: number }).cash_delta, -8_000);
  assert.equal(afterPay.db.journey.state().company.cashCents, -20_000);
  assert.equal(afterPay.db.journey.state().company.reputation, 0);
  afterPay.db.close();

  const partPay = await setup();
  partPay.db.journey.hire("mira", 1);
  partPay.db.tycoon.setPace("mira", "part");
  partPay.db.tycoon.giveRaise("mira");
  partPay.db.setClock(27, 480, 0);
  partPay.db.endDay(27);
  partPay.db.tycoon.tickDay(28);
  assert.equal(partPay.db.journey.state().company.cashCents, -6_000);
  assert.equal(partPay.db.journey.state().company.reputation, 0);
  partPay.db.close();

  const cleared = await setup();
  cleared.db.journey.hire("mira", 1);
  cleared.db.tycoon.setPace("mira", "part");
  cleared.db.tycoon.giveRaise("mira");
  cleared.db.tycoon.letGo("mira");
  assert.throws(() => cleared.db.tycoon.giveRaise("mira"), /Mina already left\./u);
  const clearedMeta = JSON.parse(String((cleared.db.journey.db.prepare("SELECT staff_json FROM tycoon_meta WHERE id = 1").get() as { staff_json: string }).staff_json)) as { mira: { raised?: boolean; pace?: string } };
  assert.equal(clearedMeta.mira.raised, undefined);
  assert.equal(clearedMeta.mira.pace, undefined);
  assert.equal(cleared.db.tycoon.view().payroll.cents, 0);
  cleared.db.journey.hire("mira", cleared.db.clockState().day);
  assert.equal(cleared.db.tycoon.view().payroll.cents, 8_000);
  assert.equal(cleared.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.raised, false);
  assert.equal(cleared.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise.enabled, true);
  cleared.db.tycoon.giveRaise("mira");
  assert.equal(cleared.db.tycoon.view().payroll.cents, 12_000);
  cleared.db.close();

  const reopen = await setup();
  reopen.db.journey.hire("mira", 1);
  reopen.db.tycoon.giveRaise("mira");
  const pending = reopen.db.tycoon.view().staff.find((person) => person.id === "mira")?.raise;
  assert.deepEqual(pending, given);
  assert.equal(reopen.db.tycoon.view().payroll.cents, 12_000);
  const file = join(reopen.root, "game.sqlite");
  const project = join(reopen.root, "company-project");
  reopen.db.close();
  const reopened = new GameDatabase(file, project);
  assert.deepEqual(reopened.tycoon.view().staff.find((person) => person.id === "mira")?.raise, pending);
  assert.equal(reopened.tycoon.view().payroll.cents, 12_000);
  assert.throws(() => reopened.tycoon.giveRaise("mira"), /Mina already has a raise\./u);
  assert.equal(validate(reopened.journey.state()), true, JSON.stringify(validate.errors));
  reopened.close();

  const shipped = await setup();
  const stayed = await setup();
  for (const ctx of [shipped, stayed]) {
    ctx.db.journey.hire("mira", 1);
    ctx.db.tycoon.start("crypto", "newsletter", ["mira"]);
    ctx.db.endDay(1);
    ctx.db.endDay(2);
    ctx.db.tycoon.release("p1");
  }
  const postedSales = shipped.db.tycoon.view().history[0]?.salesCents;
  const postedFans = shipped.db.tycoon.view().history[0]?.fans;
  const postedStaff = staffJson(shipped.db, "p1");
  const postedSeed = Number((shipped.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed);
  shipped.db.tycoon.giveRaise("mira");
  assert.equal(shipped.db.tycoon.view().history[0]?.salesCents, postedSales);
  assert.equal(shipped.db.tycoon.view().history[0]?.fans, postedFans);
  assert.equal(staffJson(shipped.db, "p1"), postedStaff);
  shipped.db.endDay(3);
  stayed.db.endDay(3);
  assert.equal(shipped.db.tycoon.view().history[0]?.salesCents, stayed.db.tycoon.view().history[0]?.salesCents);
  assert.equal(shipped.db.tycoon.view().history[0]?.fans, stayed.db.tycoon.view().history[0]?.fans);
  assert.equal(Number((shipped.db.journey.db.prepare("SELECT seed FROM tycoon_meta WHERE id = 1").get() as { seed: number }).seed), postedSeed);
  shipped.db.close();
  stayed.db.close();

  const skip = await setup();
  skip.db.tycoon.start("crypto", "newsletter", []);
  skip.db.endDay(1);
  skip.db.endDay(2);
  skip.db.tycoon.release("p1");
  assert.equal(skip.db.journey.state().company.cashCents, 20_700);
  assert.equal(skip.db.tycoon.view().history[0]?.fans, 5);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 20_700);
  skip.db.endDay(3);
  skip.db.endDay(4);
  assert.equal(skip.db.journey.state().company.cashCents, 33_300);
  assert.equal(skip.db.tycoon.view().history[0]?.salesCents, 33_300);
  assert.equal(skip.db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:raise%' OR id LIKE 'tycoon:giveRaise%' OR id LIKE 'tycoon:giveraise%'").all().length, 0);
  skip.db.close();
});

function pointsOf(db: GameDatabase, productId: string): { dev_days: number; design_points: number; tech_points: number; hype_points: number; sales_cents: number; fans: number } {
  return db.journey.db.prepare(
    "SELECT dev_days, design_points, tech_points, hype_points, sales_cents, fans FROM tycoon_products WHERE id = ?",
  ).get(productId) as { dev_days: number; design_points: number; tech_points: number; hype_points: number; sales_cents: number; fans: number };
}

function txIds(db: GameDatabase): string[] {
  return (db.journey.db.prepare("SELECT id FROM company_transactions ORDER BY id").all() as Array<{ id: string }>).map((row) => row.id);
}

function cancelRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:cancel%'").all();
}

function txCount(db: GameDatabase): number {
  return Number((db.journey.db.prepare("SELECT COUNT(*) AS n FROM company_transactions").get() as { n: number }).n);
}

function dayPlanRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:dayplan%'").all();
}

function bugRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:bugs%' OR id LIKE 'tycoon:fixBugs%'").all();
}

function crunchRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:crunch%'").all();
}

function earlyRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:early%'").all();
}

function slipRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:slip%'").all();
}

function pivotRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:pivot%'").all();
}

function playtestRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:playtest%'").all();
}

function teamRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:assign%' OR id LIKE 'tycoon:team%'").all();
}

function spikeRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:spike%' OR id LIKE 'tycoon:researchSpike%'").all();
}

function salePriceRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:saleprice%' OR id LIKE 'tycoon:salePrice%'").all();
}

function finishSales(db: GameDatabase): void {
  for (let guard = 0; guard < 8; guard += 1) {
    if (db.tycoon.view().history[0]?.status === "complete") return;
    db.endDay(db.clockState().day);
  }
  throw new Error("sales did not finish");
}

function featureRows(db: GameDatabase) {
  return db.journey.db.prepare("SELECT id FROM company_transactions WHERE id LIKE 'tycoon:feature%'").all();
}

function featureSale(
  db: GameDatabase,
  productId: string,
  dayIndex: number,
  reputation: number,
  day: number,
  extra: { featureDemand?: boolean; quietPercent?: number } = {},
) {
  const product = productById(db, productId);
  if (!product?.review) throw new Error(`missing ${productId}`);
  const calendar = calendarForDay(day);
  return salesForDay({
    seed: db.tycoon.view().seed,
    productId,
    typeId: product.typeId,
    fit: product.fit,
    score: product.review.score,
    dayIndex,
    reputation,
    unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === product.topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
    featureDemand: extra.featureDemand ?? true,
    ...(extra.quietPercent === undefined ? {} : { quietPercent: extra.quietPercent }),
  });
}
