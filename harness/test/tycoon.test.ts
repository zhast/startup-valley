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
  contractBySlot,
  fitFor,
  launchPriceCents,
  awardForScore,
  patchedScore,
  requiredDevDays,
  reviewProduct,
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
    "Whop Weekly",
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
      { name: "Whop Weekly", score: 6, blurb: "Fine." },
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
  assert.ok(CONTRACTS.every((item) => item.bonusCents > 0 && item.client.includes("Whop")));

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
  assert.equal(matched.db.tycoon.view().developing?.contract?.client, "Nova on Whop");
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
    reviewers: ["Whop Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
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
  assert.equal(AWARD_SHOW, "Whop Creator Awards");
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
  assert.equal(paid.label, "Award: Whop Creator Awards");
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
  assert.equal(lowRow.label, "Award: Whop Creator Awards");
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
    reviewers: ["Whop Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
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
  assert.equal(PORT_SHELF, "Whop Mobile");
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
  assert.equal(fee.label, "Port: Whop Mobile");
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
    reviewers: ["Whop Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
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
  assert.equal(ENGINE_NAME, "Whop Kit Engine");
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
  assert.throws(() => broke.db.tycoon.start("crypto", "newsletter", [], 100, "none", "rocket"), /Pick None or Whop Kit Engine\./u);
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
  assert.equal(fee.label, "Engine: Whop Kit Engine");
  assert.equal(fee.cash_delta, -ENGINE_COST_CENTS);
  assert.equal(fee.earned_delta, 0);
  assert.equal(fee.reputation_delta, 0);
  assert.equal(db.journey.state().company.cashCents, cashBefore - ENGINE_COST_CENTS);
  const owned = db.tycoon.view();
  assert.equal(owned.engine.owned, true);
  assert.equal(owned.engine.enabled, false);
  assert.equal(owned.engine.reason, "Already owned.");
  assert.equal(owned.engineNotice, "Bought Whop Kit Engine. −$120");
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
    reviewers: ["Whop Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
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
    reviewers: ["Whop Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
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
    reviewers: ["Whop Weekly", "Discord Dave", "Margin Call Molly", "Cohort Casey"].map((name) => ({ name, score: 6, blurb: "Solid." })),
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
