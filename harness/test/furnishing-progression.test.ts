import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test, { type TestContext } from "node:test";
import { GameDatabase } from "../src/database.js";
import type { FurnishingState } from "../src/furnishing-core.js";
import { dispatchOffline } from "../src/offline-dispatch.js";
import type { ProtocolRequest } from "../src/types.js";

async function company(t: TestContext) {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-furniture-progression-"));
  const path = join(root, "game.sqlite");
  const opened: GameDatabase[] = [];
  const open = () => { const db = new GameDatabase(path, root); opened.push(db); return db; };
  t.after(async () => { for (const db of opened) { try { db.close(); } catch { /* closed before restart */ } } await rm(root, { recursive: true, force: true }); });
  return { db: open(), open };
}
async function request(db: GameDatabase, method: ProtocolRequest["method"], params = {}) {
  return await dispatchOffline({ kind: "request", id: "progression", method, params }, db) as { furnishing: FurnishingState; furnishingRewards: string[] };
}
function readyProduct(db: GameDatabase): string {
  const id = db.tycoon.start("fitness", "course", ["founder", "mira"]).tycoon!.developing!.id;
  for (let day = 0; day < 3; day++) db.endDay(db.clockState().day);
  return id;
}
async function release(db: GameDatabase) { return request(db, "tycoon.release", { productId: readyProduct(db) }); }
const decor = (state: FurnishingState) => state.inventory.filter((item) => !item.essential);

test("a new studio owns three modest decorations, with no free premium library", async (t) => {
  const { db } = await company(t);
  const state = db.bootstrap().furnishing;
  assert.deepEqual(decor(state).map((item) => item.kind).sort(), ["broadleaf_planter", "cafe_chair", "cafe_table"]);
  assert.ok(!state.inventory.some((item) => /booth|server|sofa/u.test(item.kind)));
  assert.deepEqual(db.bootstrap().furnishing, state);
  const hired = await request(db, "hiring.complete", { employeeId: "mira" });
  assert.deepEqual(hired.furnishingRewards, []);
  assert.equal(decor(hired.furnishing).length, 3);
});

test("a real first release immediately grants stored improvements exactly once and survives restart", async (t) => {
  const { db, open } = await company(t);
  db.journey.hire("mira", 1);
  const id = readyProduct(db);
  const before = db.furnishing.state();
  const result = await request(db, "tycoon.release", { productId: id });
  assert.equal(result.furnishingRewards.length, 3);
  assert.ok(result.furnishingRewards.every((name) => typeof name === "string" && name.length <= 80));
  assert.deepEqual(decor(result.furnishing).filter((item) => item.grant === "decor:first_release:v1").map((item) => item.kind).sort(), ["coat_bag_stand", "low_bookshelf", "visitor_chair"]);
  assert.deepEqual(result.furnishing.placements, before.placements, "rewards do not rearrange or crowd the room");
  assert.equal(result.furnishing.revision, before.revision + 1);
  await assert.rejects(request(db, "tycoon.release", { productId: id }), /already shipped/u);
  assert.equal(db.dailySpend(), 0);
  const saved = db.bootstrap(); db.close();
  const reopened = open();
  assert.deepEqual(reopened.bootstrap(), saved);
  assert.deepEqual((await release(reopened)).furnishingRewards, [], "second release does not repeat the first reward");
});

test("a growing team receives its furniture immediately on hire, with stale layouts rejected", async (t) => {
  const { db } = await company(t);
  db.journey.hire("mira", 1); await release(db);
  const before = db.furnishing.state();
  const result = await request(db, "hiring.complete", { employeeId: "theo" });
  assert.equal(result.furnishingRewards.length, 6);
  assert.equal(decor(result.furnishing).length, 12);
  assert.equal(result.furnishing.layoutId, "startup-office");
  assert.deepEqual((await request(db, "hiring.complete", { employeeId: "theo" })).furnishingRewards, []);
  assert.throws(() => db.furnishing.update({ operationId: "before-reward", expectedRevision: before.revision, placements: before.placements }), /room changed/u);
});

test("release and office milestones progressively unlock the remaining library without an API", async (t) => {
  const { db } = await company(t);
  db.journey.hire("mira", 1);
  await release(db); await release(db);
  assert.equal((await release(db)).furnishingRewards.length, 6, "three releases work without hiring Theo");
  await release(db); await release(db); await release(db);
  assert.equal(decor(db.furnishing.state()).length, 12, "six releases alone do not grant the later studio library");
  db.journey.hire("theo", db.clockState().day);
  db.tycoon.expandOffice();
  assert.equal(decor(db.furnishing.state()).length, 27);
  assert.ok(db.furnishing.state().inventory.some((item) => item.kind === "phone_booth" && item.grant === "decor:established_studio:v1"));
  assert.equal(db.dailySpend(), 0);
});

test("pre-existing premium inventory and item IDs are never revoked or granted twice", async (t) => {
  const { db, open } = await company(t);
  const insert = db.journey.db.prepare("INSERT OR IGNORE INTO furnishing_inventory VALUES (?,?, '',0,'starter-decor-v1','')");
  for (const item of db.furnishing.geometry.starterDecor) insert.run(item.id, item.kind);
  const before = db.furnishing.state(); db.close();
  const reopened = open();
  assert.deepEqual(reopened.furnishing.state(), before);
  reopened.journey.hire("mira", 1);
  assert.deepEqual((await release(reopened)).furnishingRewards, []);
  for (const item of before.inventory) assert.ok(reopened.furnishing.state().inventory.some((current) => current.id === item.id && current.grant === item.grant));
});

test("a failed reward insert rolls back the entire release and can retry without duplicate rewards", async (t) => {
  const { db } = await company(t);
  db.journey.hire("mira", 1); const id = readyProduct(db);
  const before = db.bootstrap();
  db.journey.db.exec("CREATE TRIGGER reject_reward BEFORE INSERT ON furnishing_inventory WHEN NEW.grant_id='decor:first_release:v1' BEGIN SELECT RAISE(ABORT,'Reward write interrupted'); END");
  await assert.rejects(request(db, "tycoon.release", { productId: id }), /Reward write interrupted/u);
  assert.deepEqual(db.bootstrap(), before);
  db.journey.db.exec("DROP TRIGGER reject_reward");
  assert.equal((await request(db, "tycoon.release", { productId: id })).furnishingRewards.length, 3);
  assert.equal(decor(db.furnishing.state()).length, 6);
});
