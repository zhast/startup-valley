import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { GameDatabase } from "../src/database.js";

async function company() {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-offline-growth-"));
  const path = join(root, "game.sqlite");
  return { root, path, db: new GameDatabase(path, root) };
}

function release(db: GameDatabase): string {
  const started = db.tycoon.start("fitness", "course", ["founder", "mira"]);
  const id = started.tycoon!.developing!.id;
  for (let n = 0; n < 3; n++) db.endDay(db.clockState().day);
  db.tycoon.release(id);
  return id;
}

test("ordinary offline releases unlock every teammate and the larger office without legacy work orders", async () => {
  const { db, path, root } = await company();
  assert.equal(db.journey.state().candidates.find((person) => person.id === "theo")!.available, false);
  db.journey.hire("mira", 1);
  release(db);
  assert.equal(db.journey.state().candidates.find((person) => person.id === "theo")!.available, true);
  assert.equal(db.journey.state().candidates.find((person) => person.id === "creative")!.available, false);
  db.journey.hire("theo", db.clockState().day);
  assert.equal(db.furnishing.state().layoutId, "startup-office");
  db.tycoon.expandOffice();
  assert.equal(db.tycoon.view().office.level, 2);
  release(db);
  assert.equal(db.journey.state().candidates.find((person) => person.id === "creative")!.available, false);
  release(db);
  assert.equal(db.journey.state().candidates.find((person) => person.id === "creative")!.available, true);
  db.journey.hire("creative", db.clockState().day);
  assert.equal(db.bootstrap().employees.length, 3);
  assert.ok(db.journey.state().milestones.every((step) => step.state !== "completed"));
  assert.equal(db.recentWorkOrders().length, 0);
  assert.equal(db.dailySpend(), 0);
  const state = db.bootstrap();
  db.close();
  const reopened = new GameDatabase(path, root);
  assert.deepEqual(reopened.bootstrap().journey, state.journey);
  assert.deepEqual(reopened.bootstrap().furnishing, state.furnishing);
  reopened.close();
});

test("existing optional chapter milestones still unlock their teammates without fabricating releases", async () => {
  const { db } = await company();
  db.journey.db.exec("UPDATE milestone_progress SET completed=1 WHERE id IN ('website','incorporate'); UPDATE company_state SET opened_chapter=2 WHERE id=1");
  assert.equal(db.journey.releasedProducts(), 0);
  assert.equal(db.journey.state().candidates.find((person) => person.id === "theo")!.available, true);
  assert.equal(db.journey.state().candidates.find((person) => person.id === "creative")!.available, true);
  db.close();
});
