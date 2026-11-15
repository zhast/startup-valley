import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { GameDatabase, readMigrations } from "../src/database.js";
import { parseRequest } from "../src/validation.js";

async function setup(legacy = false) {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-compact-"));
  const path = join(root, "game.sqlite");
  if (legacy) {
    const old = new DatabaseSync(path);
    old.exec("CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY,applied_at TEXT NOT NULL)");
    for (const [name, sql] of Object.entries(readMigrations()).sort().filter(([name]) => Number(name.slice(0, 3)) < 17)) {
      old.exec(sql);
      if (!name.startsWith("001")) old.prepare("INSERT INTO schema_migrations VALUES (?,'before-cottage')").run(Number(name.slice(0, 3)));
    }
    old.close();
  }
  return { root, path, db: new GameDatabase(path, root) };
}

function unlockTheo(db: GameDatabase): void {
  db.journey.db.exec("UPDATE milestone_progress SET completed=1 WHERE id='website'; UPDATE company_state SET cash_cents=100000 WHERE id=1");
}

test("new company and first hire use the compact room, with durable décor and safe entrance", async () => {
  const { db, path, root } = await setup();
  const first = db.furnishing.state();
  assert.equal(first.layoutId, "starter-cottage-v1");
  assert.equal(db.furnishing.geometry.floor.size, 288);
  assert.deepEqual(db.journey.state().player, { x: 496, y: 624 });
  assert.deepEqual(first.placements["founder-workstation"]?.grid, [11, 11]);
  for (const id of ["decor-cafe_table", "decor-cafe_chair", "decor-broadleaf_planter"]) assert.ok(first.placements[id]);
  assert.throws(() => parseRequest({ kind: "request", id: "forged", method: "furnishing.update", params: { operationId: "forged", expectedRevision: 0, layoutId: "startup-office", placements: first.placements } }), /Invalid protocol/u);
  db.journey.hire("mira", 1);
  const hired = db.furnishing.state();
  assert.equal(hired.layoutId, "starter-cottage-v1");
  assert.deepEqual(hired.placements["mira-workstation"]?.grid, [20, 11]);
  assert.equal(hired.inventory.filter((item) => item.essential).length, 5);
  db.furnishing.geometry.validate(hired.placements, hired.inventory);
  db.close();
  const reopened = new GameDatabase(path, root);
  assert.deepEqual(reopened.furnishing.state(), hired);
  reopened.close();
});

test("pre-cottage saves retain the large room, exact furniture, player position and company progress", async () => {
  const { db, path, root } = await setup(true);
  assert.equal(db.furnishing.state().layoutId, "startup-office");
  assert.equal(db.furnishing.geometry.floor.size, 614);
  const before = db.furnishing.state();
  const custom = { ...before.placements, "decor-broadleaf_planter": { grid: [24, 8] as [number, number], facing: "south" as const } };
  db.furnishing.update({ operationId: "old-decoration", expectedRevision: before.revision, placements: custom });
  db.journey.savePlayer({ x: 550.25, y: 590.5, movementSeen: true });
  const saved = db.bootstrap();
  db.journey.db.exec("DROP TABLE office_layout_state; DELETE FROM schema_migrations WHERE version=17");
  db.close();
  const migrated = new GameDatabase(path, root);
  assert.deepEqual(migrated.furnishing.state(), saved.furnishing);
  assert.deepEqual(migrated.journey.state().player, saved.journey.player);
  assert.deepEqual(migrated.journey.state().company, saved.journey.company);
  migrated.close();
});

test("hiring the third studio member moves to the large room exactly once and preserves owned items", async () => {
  const { db, path, root } = await setup();
  db.journey.hire("mira", 1);
  unlockTheo(db);
  const initial = db.furnishing.state();
  const edit = { operationId: "before-move", expectedRevision: initial.revision, placements: initial.placements };
  const before = db.furnishing.update(edit).furnishing;
  db.journey.hire("theo", 2);
  const moved = db.furnishing.state();
  assert.equal(moved.layoutId, "startup-office");
  assert.equal(moved.revision, before.revision + 1);
  assert.deepEqual(moved.placements["mira-workstation"]?.grid, [10, 8]);
  assert.deepEqual(moved.placements["theo-workstation"]?.grid, [20, 8]);
  assert.deepEqual(db.journey.state().player, { x: 560, y: 624 });
  for (const item of before.inventory) assert.ok(moved.inventory.some((current) => current.id === item.id));
  db.furnishing.geometry.validate(moved.placements, moved.inventory);
  assert.match(moved.recovery, /larger studio/u);
  assert.throws(() => db.furnishing.update({ operationId: "stale-cottage-edit", expectedRevision: before.revision, placements: before.placements }), /room changed/u);
  assert.deepEqual(db.furnishing.update(edit), { furnishing: moved, replayed: true }, "an old receipt returns the latest room rather than a stale cottage");
  db.close();
  const reopened = new GameDatabase(path, root);
  assert.deepEqual(reopened.furnishing.state(), moved);
  reopened.journey.db.exec("UPDATE employees SET employment_status='candidate' WHERE id='theo'");
  assert.equal(reopened.furnishing.state().layoutId, "startup-office", "losing staff must never shrink an established room");
  reopened.close();
});

test("layout, hiring charge, staff, grants and player movement roll back together on a failed move", async () => {
  const { db } = await setup();
  db.journey.hire("mira", 1);
  unlockTheo(db);
  const before = db.bootstrap();
  db.journey.db.exec("CREATE TRIGGER fail_move BEFORE UPDATE ON office_layout_state BEGIN SELECT RAISE(ABORT,'Move write failed'); END");
  assert.throws(() => db.journey.hire("theo", 2), /Move write failed/u);
  assert.deepEqual(db.furnishing.state(), before.furnishing);
  assert.deepEqual(db.bootstrap().journey, before.journey);
  assert.deepEqual(db.bootstrap().employees, before.employees);
  db.journey.db.exec("DROP TRIGGER fail_move");
  db.journey.hire("theo", 2);
  assert.equal(db.furnishing.state().layoutId, "startup-office");
  db.close();
});

test("office expansion grants all large-room stations atomically even with only the founder", async () => {
  const { db } = await setup();
  db.journey.db.exec("UPDATE tycoon_meta SET office_level=2 WHERE id=1");
  const state = db.furnishing.state();
  assert.equal(state.layoutId, "startup-office");
  for (const id of ["spare-compact-a", "spare-compact-b", "spare-workbench"]) assert.ok(state.placements[id]);
  db.furnishing.geometry.validate(state.placements, state.inventory);
  db.close();
});
