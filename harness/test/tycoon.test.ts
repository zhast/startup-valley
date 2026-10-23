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
  EVENT_BONUS_FANS,
  PRODUCT_TYPES,
  SEASON_UNIT_BOOST_PERCENT,
  STAT_CAP,
  TOPICS,
  UPGRADES,
  allFits,
  baseScore,
  boostedPriceCents,
  calendarForDay,
  fitFor,
  reviewProduct,
  salesForDay,
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
