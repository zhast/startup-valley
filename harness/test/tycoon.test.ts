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
import {
  PRODUCT_TYPES,
  TOPICS,
  allFits,
  baseScore,
  fitFor,
  reviewProduct,
  salesForDay,
  staffPoints,
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
  assert.equal(stderr.includes("sk-"), false);
  child.stdin.end();
  await once(child, "exit");
  lines.close();
});
