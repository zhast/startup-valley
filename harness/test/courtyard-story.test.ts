import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test, { type TestContext } from "node:test";
import { GameDatabase, readMigrations } from "../src/database.js";
import { createBrowserRuntime } from "../src/browser-runtime.js";
import { furnishingHash, readGeometryData } from "../src/furnishing.js";
import { dispatchOffline } from "../src/offline-dispatch.js";
import { parseRequest, parseStoryState, readContractSchemas } from "../src/validation.js";
import type { ProtocolMethod } from "../src/types.js";

async function fixture(t: TestContext) {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-courtyard-"));
  const path = join(root, "game.sqlite");
  const connections: GameDatabase[] = [];
  const open = () => { const db = new GameDatabase(path, root); connections.push(db); return db; };
  t.after(async () => {
    for (const db of connections) try { db.close(); } catch { /* explicit restart already closed it */ }
    await rm(root, { recursive: true, force: true });
  });
  return { db: open(), open };
}

async function request(db: GameDatabase, method: ProtocolMethod, params: Record<string, unknown> = {}) {
  return await dispatchOffline(parseRequest({ kind: "request", id: `${method}-fixture`, method, params }), db) as any;
}
async function firstRelease(db: GameDatabase): Promise<void> {
  await request(db, "hiring.complete", { employeeId: "mira" });
  const started = await request(db, "tycoon.start", { topicId: "fitness", typeId: "course", staffIds: ["founder", "mira"] });
  for (let day = 0; day < 3; day++) await request(db, "day.end", { day: db.clockState().day });
  await request(db, "tycoon.release", { productId: started.journey.tycoon.developing.id });
}
const travel = (db: GameDatabase, destination: "office" | "courtyard", operationId: string) => request(db, "story.travel", { destination, operationId, expectedRevision: db.story.view().revision });
const accept = (db: GameDatabase, operationId: string) => request(db, "story.acceptOpportunity", { operationId, expectedRevision: db.story.view().revision });

test("production offline journey visits Theo, preserves exact positions, and completes the real next project", async (t) => {
  const fixtureValue = await fixture(t);
  let db = fixtureValue.db;
  assert.equal(db.story.view().opportunity.status, "locked");
  await assert.rejects(travel(db, "courtyard", "too-early"), /first project/u);
  await firstRelease(db);
  const officePosition = { x: 496.25, y: 601.5, movementSeen: true, effectsVolume: 0.3, ambienceVolume: 0.1, architectureTheme: "cafe", location: "office", storyRevision: 0 };
  await request(db, "game.save", officePosition);
  const playerBefore = db.journey.state().player;
  const entered = await travel(db, "courtyard", "first-visit");
  assert.equal(entered.journey.story.location, "courtyard");
  assert.deepEqual(parseStoryState(entered.journey.story), entered.journey.story);
  assert.deepEqual([entered.journey.player.x, entered.journey.player.y], [496, 560]);
  await request(db, "game.save", { ...officePosition, x: 624.25, y: 416.5, location: "courtyard", storyRevision: 1 });
  const outsideBefore = db.bootstrap();
  db.close(); db = fixtureValue.open();
  assert.deepEqual(db.bootstrap().journey, outsideBefore.journey);
  const companyBefore = db.journey.state().company;
  const researchBefore = db.tycoon.view().researchPoints;
  const accepted = await accept(db, "market-brief");
  assert.equal(accepted.journey.story.opportunity.status, "accepted");
  assert.equal(accepted.journey.story.metTheo, true);
  assert.ok(accepted.journey.tycoon.topics.find((topic: any) => topic.id === "reselling").unlocked);
  assert.equal(db.tycoon.view().researchPoints, researchBefore);
  assert.deepEqual(db.journey.state().company, companyBefore, "a conversation must not invent cash or reputation");
  const replay = await request(db, "story.acceptOpportunity", { operationId: "market-brief", expectedRevision: 1 });
  assert.equal(replay.replayed, true);
  assert.equal(replay.journey.story.revision, 2);
  const returned = await travel(db, "office", "return-home");
  assert.deepEqual(returned.journey.player, playerBefore);
  const oldVisit = await request(db, "story.travel", { destination: "courtyard", operationId: "first-visit", expectedRevision: 0 });
  assert.equal(oldVisit.replayed, true);
  assert.equal(oldVisit.journey.story.location, "office", "old durable receipt must not teleport the player back");
  assert.deepEqual(oldVisit.journey.player, playerBefore);
  const next = await request(db, "tycoon.start", { topicId: "reselling", typeId: "template_pack", staffIds: ["founder", "mira"] });
  const productId = next.journey.tycoon.developing.id;
  assert.equal(next.journey.story.opportunity.productId, productId);
  assert.equal(next.journey.story.opportunity.status, "developing");
  for (let day = 0; day < 2; day++) await request(db, "day.end", { day: db.clockState().day });
  const released = await request(db, "tycoon.release", { productId });
  assert.equal(released.journey.story.opportunity.status, "completed");
  const done = db.bootstrap();
  await assert.rejects(request(db, "tycoon.release", { productId }), /already shipped/u);
  assert.deepEqual(db.journey.state().company, done.journey.company);
  db.close(); db = fixtureValue.open();
  assert.deepEqual(db.bootstrap().journey, done.journey);
  assert.equal(db.dailySpend(), 0);
  assert.deepEqual(db.recentWorkOrders(), []);
});

test("stale commands, delayed room saves, forged travel and exterior renovation fail without mutation", async (t) => {
  const { db, open } = await fixture(t);
  await firstRelease(db);
  const second = open();
  await travel(db, "courtyard", "go");
  const before = db.bootstrap();
  await assert.rejects(request(second, "story.travel", { operationId: "stale-return", expectedRevision: 0, destination: "office" }), /story changed/u);
  await assert.rejects(request(db, "game.save", { x: 496, y: 624, location: "office", storyRevision: 0 }), /location changed/u);
  await assert.rejects(request(db, "game.save", { x: 624, y: 400, location: "courtyard" }), /missing story revision/u);
  await assert.rejects(request(db, "game.save", { x: 10, y: 10, location: "courtyard", storyRevision: 1 }), /courtyard position/u);
  await assert.rejects(request(db, "story.acceptOpportunity", { operationId: "stale-meeting", expectedRevision: 0 }), /story changed/u);
  await assert.rejects(request(db, "story.travel", { operationId: "go", expectedRevision: 0, destination: "office" }), /already used for a different action/u);
  await assert.rejects(request(db, "story.acceptOpportunity", { operationId: "go", expectedRevision: 0 }), /already used for a different action/u);
  await assert.rejects(request(db, "story.travel", { operationId: "forged", expectedRevision: 1, destination: "secret-office" }), /Invalid protocol/u);
  await assert.rejects(request(db, "story.acceptOpportunity", { operationId: "../bad", expectedRevision: 1, cash: 100000 }), /Invalid protocol/u);
  await assert.rejects(request(db, "furnishing.update", { operationId: "outside-decor", expectedRevision: before.furnishing.revision, placements: before.furnishing.placements }), /Return to the studio/u);
  assert.deepEqual(db.bootstrap().journey, before.journey);
  assert.deepEqual(db.furnishing.state(), before.furnishing);
});

test("travel and topic grants roll back atomically and the same failed operation can be retried", async (t) => {
  const { db } = await fixture(t);
  await firstRelease(db);
  const before = db.bootstrap();
  db.journey.db.exec("CREATE TRIGGER fail_story BEFORE UPDATE ON story_state BEGIN SELECT RAISE(ABORT,'Story write failed'); END");
  await assert.rejects(travel(db, "courtyard", "retry-travel"), /Story write failed/u);
  assert.deepEqual(db.bootstrap().journey, before.journey);
  assert.equal(db.journey.db.prepare("SELECT COUNT(*) n FROM story_operations").get()!.n, 0);
  db.journey.db.exec("DROP TRIGGER fail_story");
  await travel(db, "courtyard", "retry-travel");
  const beforeMeeting = db.bootstrap();
  db.journey.db.exec("CREATE TRIGGER fail_story BEFORE UPDATE ON story_state BEGIN SELECT RAISE(ABORT,'Story write failed'); END");
  await assert.rejects(accept(db, "retry-meeting"), /Story write failed/u);
  assert.deepEqual(db.bootstrap().journey, beforeMeeting.journey);
  db.journey.db.exec("DROP TRIGGER fail_story");
  await accept(db, "retry-meeting");
  assert.equal(db.story.view().opportunity.status, "accepted");
});

test("pre-story save migration preserves the company and unlocks the visit from existing releases", async (t) => {
  const fixtureValue = await fixture(t);
  const { db } = fixtureValue;
  await firstRelease(db);
  await request(db, "hiring.complete", { employeeId: "theo" });
  await request(db, "game.save", { x: 550.25, y: 590.5, movementSeen: true });
  const before = db.bootstrap();
  assert.equal(before.furnishing.layoutId, "startup-office");
  db.journey.db.exec("DROP TABLE story_operations; DROP TABLE story_state; DELETE FROM schema_migrations WHERE version=18");
  db.close();
  const migrated = fixtureValue.open();
  assert.deepEqual(migrated.journey.state().company, before.journey.company);
  assert.deepEqual(migrated.journey.state().player, before.journey.player);
  assert.deepEqual(migrated.furnishing.state(), before.furnishing);
  assert.equal(migrated.story.view().location, "office");
  assert.equal(migrated.story.view().courtyardUnlocked, true);
  assert.equal(migrated.story.view().visited, false);
  await travel(migrated, "courtyard", "old-office-visit");
  await request(migrated, "tycoon.expandOffice");
  await travel(migrated, "office", "old-office-return");
  assert.deepEqual(migrated.journey.state().player, before.journey.player);
});

test("hiring and office expansion outside preserve the courtyard position and choose a safe return", async (t) => {
  const { db } = await fixture(t);
  await firstRelease(db);
  await travel(db, "courtyard", "outside");
  const outside = db.journey.state().player;
  await request(db, "hiring.complete", { employeeId: "theo" });
  assert.equal(db.furnishing.state().layoutId, "startup-office");
  assert.equal(db.story.view().location, "courtyard");
  assert.deepEqual(db.journey.state().player, outside);
  await request(db, "tycoon.expandOffice");
  assert.deepEqual(db.journey.state().player, outside);
  await travel(db, "office", "large-office-return");
  assert.deepEqual([db.journey.state().player.x, db.journey.state().player.y], [560, 624]);
});

test("canceling the offered project keeps its brief available for a real replacement", async (t) => {
  const { db } = await fixture(t);
  await firstRelease(db);
  await travel(db, "courtyard", "visit");
  await accept(db, "brief");
  await travel(db, "office", "return");
  await request(db, "tycoon.start", { topicId: "reselling", typeId: "template_pack", staffIds: ["founder", "mira"] });
  await request(db, "tycoon.cancelBuild");
  assert.equal(db.story.view().opportunity.status, "accepted");
  const again = await request(db, "tycoon.start", { topicId: "reselling", typeId: "template_pack", staffIds: ["founder", "mira"] });
  assert.equal(db.story.view().opportunity.productId, again.journey.tycoon.developing.id);
});

test("New Company clears durable story and operation receipts in the shared offline runtime", async (t) => {
  // This exercises the production portable worker with native SQLite; no browser
  // or computer-use surface is involved or claimed as test coverage.
  let connection = new DatabaseSync(":memory:");
  const runtime = createBrowserRuntime({
    database: connection, migrations: readMigrations(), geometryData: readGeometryData(), schemas: readContractSchemas(), hash: furnishingHash,
    resetDatabase: async (current, initialize) => {
      const candidate = new DatabaseSync(":memory:");
      try { initialize(candidate); } catch (error) { candidate.close(); throw error; }
      current.close();
      connection = candidate;
      return candidate;
    },
  });
  t.after(() => runtime.close());
  let sequence = 0;
  const send = async (method: ProtocolMethod, params: Record<string, unknown> = {}) => {
    const result = await runtime.handleRequest({ kind: "request", id: `story-reset-${sequence++}`, method, params });
    assert.equal(result.ok, true, result.error);
    return result.result as any;
  };
  const original = await send("bootstrap");
  await send("hiring.complete", { employeeId: "mira" });
  const started = await send("tycoon.start", { topicId: "fitness", typeId: "course", staffIds: ["founder", "mira"] });
  for (let day = 1; day <= 3; day++) await send("day.end", { day });
  await send("tycoon.release", { productId: started.journey.tycoon.developing.id });
  await send("story.travel", { operationId: "reset-visit", expectedRevision: 0, destination: "courtyard" });
  await send("story.acceptOpportunity", { operationId: "reset-brief", expectedRevision: 1 });
  assert.equal(connection.prepare("SELECT COUNT(*) n FROM story_operations").get()!.n, 2);
  const fresh = await send("game.new", { confirmed: true });
  assert.deepEqual(fresh.journey.story, original.journey.story);
  assert.equal(connection.prepare("SELECT COUNT(*) n FROM story_operations").get()!.n, 0);
  const rejected = await runtime.handleRequest({ kind: "request", id: "old-receipt-after-reset", method: "story.travel", params: { operationId: "reset-visit", expectedRevision: 0, destination: "courtyard" } });
  assert.equal(rejected.ok, false, "a previous company's receipt cannot unlock a new company's courtyard");
});
