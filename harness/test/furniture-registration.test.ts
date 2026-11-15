import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test, { type TestContext } from "node:test";
import { GameDatabase } from "../src/database.js";
import { FurnishingGeometry, type FurnishingState, type FurnishingUpdate } from "../src/furnishing-core.js";
import { readGeometryData } from "../src/furnishing.js";

async function legacyRoom(t: TestContext, besideBooth = false) {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-prop-registration-"));
  const path = join(root, "game.sqlite");
  const opened: GameDatabase[] = [];
  const open = () => { const db = new GameDatabase(path, root); opened.push(db); return db; };
  t.after(async () => { for (const db of opened) { try { db.close(); } catch { /* already closed */ } } await rm(root, { force: true, recursive: true }); });
  const db = open();
  // Explicit old-owner state: the full library and full office existed before
  // registration revision1. This is not a new-company gameplay shortcut.
  for (const item of db.furnishing.geometry.starterDecor) db.journey.db.prepare("INSERT OR IGNORE INTO furnishing_inventory VALUES (?,?, '',0,'starter-decor-v1','')").run(item.id, item.kind);
  db.journey.db.exec("UPDATE office_layout_state SET layout_id='startup-office'; DELETE FROM furnishing_state");
  const initial = db.furnishing.state();
  const operation: FurnishingUpdate = { operationId: "old-owned-layout", expectedRevision: initial.revision, placements: { ...initial.placements, "decor-broadleaf_planter": { grid: [24, 8], facing: "south" } } };
  db.furnishing.update(operation);
  if (besideBooth) db.journey.db.prepare("UPDATE company_state SET player_json=? WHERE id=1").run(JSON.stringify({ x: 80, y: 592, movementSeen: true }));
  const before = db.bootstrap();
  const data = readGeometryData();
  const oldProfiles = JSON.parse(readFileSync(new URL("../../game/assets/source/furniture-scale-v1/prior-profiles.json", import.meta.url), "utf8"));
  Object.assign((data.furnishingCatalog as { furniture: Record<string, unknown> }).furniture, oldProfiles);
  new FurnishingGeometry(data).validate(before.furnishing.placements, before.furnishing.inventory, [{ id: "founder", grid: besideBooth ? [2, 18] : [17, 19] }]);
  db.close();
  const raw = new DatabaseSync(path);
  raw.exec("DROP TABLE furnishing_geometry_state; DELETE FROM schema_migrations WHERE version=19");
  raw.close();
  return { path, open, before, operation };
}

test("registration migration preserves every valid old anchor, owned item and unrelated company state", async (t) => {
  const { open, before } = await legacyRoom(t);
  const db = open(); const after = db.bootstrap();
  assert.deepEqual(after.furnishing.inventory, before.furnishing.inventory);
  assert.deepEqual(after.furnishing.placements, before.furnishing.placements);
  assert.equal(after.furnishing.revision, before.furnishing.revision + 1);
  assert.deepEqual(after.journey, before.journey);
  assert.equal(db.journey.db.prepare("SELECT revision FROM furnishing_geometry_state").get()!.revision, 1);
  db.close();
  assert.deepEqual(open().bootstrap(), after);
});

test("an old founder beside the one-cell booth stores only that corrected item, preserving receipts and IDs", async (t) => {
  const { open, before, operation } = await legacyRoom(t, true);
  const db = open(); const after = db.bootstrap();
  const expected = { ...before.furnishing.placements }; delete expected["decor-phone_booth"];
  assert.deepEqual(after.furnishing.placements, expected);
  assert.deepEqual(after.furnishing.inventory, before.furnishing.inventory);
  assert.match(after.furnishing.recovery, /Safely stored.*Phone booth/u);
  assert.deepEqual(after.journey.player, before.journey.player);
  assert.equal(after.furnishing.revision, before.furnishing.revision + 1);
  assert.throws(() => db.furnishing.update({ ...operation, operationId: "stale-after-resize", expectedRevision: before.furnishing.revision }), /room changed/u);
  assert.deepEqual(db.furnishing.update(operation), { furnishing: after.furnishing, replayed: true });
  db.close();
  assert.deepEqual(open().furnishing.state(), after.furnishing);
});

test("interrupted registration migration rolls back placement and version together before a safe retry", async (t) => {
  const { path, open, before } = await legacyRoom(t, true);
  const raw = new DatabaseSync(path);
  // Emulate interruption after layout write, before committing its version.
  raw.exec(readFileSync(new URL("../migrations/019_furniture_registration.sql", import.meta.url), "utf8"));
  raw.exec("INSERT INTO schema_migrations VALUES (19,'interrupted-fixture'); CREATE TRIGGER stop_registration BEFORE UPDATE ON furnishing_geometry_state BEGIN SELECT RAISE(ABORT,'registration interrupted'); END");
  assert.throws(open, /registration interrupted/u);
  assert.equal(raw.prepare("SELECT revision FROM furnishing_geometry_state").get()!.revision, 0);
  const stored = raw.prepare("SELECT placements_json, revision FROM furnishing_state").get()!;
  assert.equal(stored.revision, before.furnishing.revision);
  assert.deepEqual(JSON.parse(String(stored.placements_json)), before.furnishing.placements);
  raw.exec("DROP TRIGGER stop_registration"); raw.close();
  const after: FurnishingState = open().furnishing.state();
  assert.equal(after.revision, before.furnishing.revision + 1);
  assert.equal(after.placements["decor-phone_booth"], undefined);
});

test("an old last-valid snapshot is selectively migrated when the current layout is corrupt", async (t) => {
  const { path, open, before } = await legacyRoom(t, true);
  const raw = new DatabaseSync(path);
  raw.exec("UPDATE furnishing_state SET placements_json='{}'"); raw.close();
  const after = open().furnishing.state();
  const expected = { ...before.furnishing.placements }; delete expected["decor-phone_booth"];
  assert.deepEqual(after.placements, expected);
  assert.deepEqual(after.inventory, before.furnishing.inventory);
  assert.match(after.recovery, /last valid.*Safely stored/u);
});
