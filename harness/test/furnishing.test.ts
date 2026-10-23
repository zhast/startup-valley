import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { readFileSync } from "node:fs";
import { mkdir, mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { GameDatabase } from "../src/database.js";
import type { Facing, FurniturePlacements, FurnishingState } from "../src/furnishing.js";
import { parseFurnishingState, parseRequest } from "../src/validation.js";

const furnishingCatalog = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "..", "..", "game", "data", "furnishing_catalog.json"), "utf8")) as {
  starter_decor: Array<{ id: string; kind: string }>;
  furniture: Record<string, { facings?: Facing[] }>;
};
const starterCount = furnishingCatalog.starter_decor.length;
const founderInventory = 1 + starterCount;
const hiredTwoInventory = 8 + starterCount;

async function setup() {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-furnishing-"));
  const project = join(root, "company-project"); await mkdir(project);
  const path = join(root, "startup-valley.sqlite");
  return { root, project, path, db: new GameDatabase(path, project) };
}
// Open Floor desks reserve the old east-center pocket. [24,8] still clears story
// props, aisles, and those desks for every starter facing except the three below.
const decorCell = (kind: string, facing: Facing): [number, number] => {
  if (kind === "shared_workbench" && (facing === "east" || facing === "west")) return [24, 6];
  if (kind === "lounge_sofa" && facing === "south") return [4, 8];
  return [24, 8];
};
const plant = (state: FurnishingState, facing: Facing = "south"): FurniturePlacements => ({
  ...state.placements, "decor-broadleaf_planter": { grid: decorCell("broadleaf_planter", facing), facing },
});
const apply = (db: GameDatabase, operationId: string, placements: FurniturePlacements) => db.furnishing.update({ operationId, expectedRevision: db.furnishing.state().revision, placements });

async function versionSixCompany(desks: Array<[string, string, number, number]> = [["mira", "Mina", 8, 5], ["theo", "Theo", 8, 5]]) {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-furnishing-migration-")); const path = join(root, "game.sqlite");
  const old = new DatabaseSync(path);
  for (const name of ["001_initial.sql", "002_product_layer.sql", "003_persistent_studio.sql", "004_work_order_handoff.sql", "005_employee_chat.sql", "006_company_journey.sql"]) old.exec(await readFile(new URL(`../migrations/${name}`, import.meta.url), "utf8"));
  old.exec("CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY,applied_at TEXT NOT NULL)");
  for (const version of [2, 3, 4, 5, 6]) old.prepare("INSERT INTO schema_migrations VALUES (?,'old')").run(version);
  for (const [id, name, x, y] of desks) old.prepare("INSERT INTO employees VALUES (?, ?,?,?,'{}','{}',80,NULL,'before','before','hired',1)").run(id, name, x, y);
  old.exec("UPDATE company_state SET cash_cents=12500,earned_cents=90000,reputation=13,player_json='{\"x\":550,\"y\":550}'");
  old.close();
  return { root, path, project: join(root, "company-project") };
}

test("furnishing schema rejects forged inventory, decimal cells, duplicate actors and malformed updates", async () => {
  const { db } = await setup(); const state = db.bootstrap().furnishing;
  assert.deepEqual(parseFurnishingState(state), state);
  const valid = { kind: "request", id: "one", method: "furnishing.update", params: { operationId: "one", expectedRevision: 0, placements: state.placements } };
  assert.equal(parseRequest(valid).method, "furnishing.update");
  for (const params of [
    { ...valid.params, inventory: [] }, { ...valid.params, expectedRevision: -1 },
    { ...valid.params, operationId: "../bad" },
    { ...valid.params, placements: { "founder-workstation": { grid: [8.5, 17], facing: "south" } } },
    { ...valid.params, placements: { "founder-workstation": { grid: [8, 17], facing: "south", kind: "free-desks" } } },
    { ...valid.params, actorCells: [{ id: "lawyer", grid: [22, 16] }] },
  ]) assert.throws(() => parseRequest({ ...valid, params }), /Invalid protocol/u);
  assert.throws(() => db.furnishing.update({ ...valid.params, actorCells: [{ id: "founder", grid: [17, 19] }, { id: "founder", grid: [17, 18] }] }), /Invalid live actor/u);
  assert.throws(() => apply(db, "forged", { ...state.placements, "unowned-desk": { grid: [22, 16], facing: "south" } }), /not owned/u);
  assert.deepEqual(db.bootstrap().furnishing, state);
  db.close();
});

test("starter inventory, four-facing placement, move, store and Undo survive restart without duplicate grants", async () => {
  const { db, path, project } = await setup();
  const initial = db.bootstrap().furnishing;
  assert.equal(initial.inventory.length, founderInventory); assert.equal(initial.revision, 0);
  assert.equal(initial.inventory.filter((item) => !item.essential).length, starterCount);
  assert.equal(initial.inventory.find((item) => item.id === "founder-workstation")?.roleKit, "founder_strategy_kit");
  assert.equal(db.furnishing.geometry.employeeDecorKits.founder, "desk_lamp_kit");
  assert.equal(db.furnishing.geometry.decorKits.desk_lamp_kit?.host_kind, "desk");
  assert.equal(db.furnishing.geometry.decorKits.desk_lamp_kit?.owner_id, "founder");
  assert.deepEqual(Object.keys(initial.placements), ["founder-workstation", "decor-phone_booth"]);
  assert.deepEqual(initial.placements["decor-phone_booth"], { grid: [3, 18], facing: "south" });
  assert.notDeepEqual(initial.placements["decor-phone_booth"]?.grid, [24, 8]);
  for (const item of initial.inventory.filter((entry) => !entry.essential)) {
    const facings = furnishingCatalog.furniture[item.kind]?.facings ?? ["south"];
    for (const facing of facings) {
      const grid = decorCell(item.kind, facing);
      const placed = apply(db, `${item.kind}-${facing}`, { ...initial.placements, [item.id]: { grid, facing } }).furnishing;
      assert.deepEqual(placed.placements[item.id], { grid, facing });
    }
  }
  const beforeMove = apply(db, "plant-final", plant(initial)).furnishing;
  const moved = apply(db, "plant-move", { ...beforeMove.placements, "decor-broadleaf_planter": { grid: [7, 14], facing: "south" } }).furnishing;
  assert.equal(moved.revision, beforeMove.revision + 1);
  const stored = apply(db, "store", initial.placements).furnishing;
  assert.equal(stored.placements["decor-broadleaf_planter"], undefined);
  const restored = apply(db, "undo-store", moved.placements).furnishing;
  db.close();
  const reopened = new GameDatabase(path, project);
  assert.deepEqual(reopened.bootstrap().furnishing, restored);
  for (let n = 0; n < 5; n++) assert.deepEqual(reopened.bootstrap().furnishing, restored);
  reopened.close();
});

test("transactional receipts survive retry/restart and stale requests never overwrite newer edits", async () => {
  const { db, path, project } = await setup(); const initial = db.bootstrap().furnishing;
  const request = { operationId: "exact-layout", expectedRevision: initial.revision, placements: plant(initial) };
  const first = db.furnishing.update(request);
  assert.equal(first.replayed, false);
  assert.equal(db.furnishing.update(request).replayed, true);
  assert.throws(() => db.furnishing.update({ ...request, placements: plant(initial, "west") }), /already used/u);
  assert.throws(() => db.furnishing.update({ ...request, operationId: "stale" }), /room changed/u);
  const latest = apply(db, "newer-edit", plant(first.furnishing, "east")).furnishing;
  db.close(); const reopened = new GameDatabase(path, project);
  assert.deepEqual(reopened.furnishing.update(request), { furnishing: latest, replayed: true }, "old receipt must not regress the projection");
  assert.equal(reopened.journey.db.prepare("SELECT COUNT(*) n FROM furnishing_operations").get()!.n, 2);
  reopened.close();
});

test("placement validation protects walls, art bounds, service clearance, future hires and live actors", async () => {
  const { db } = await setup(); const initial = db.bootstrap().furnishing;
  for (const grid of [[0, 4], [17, 10], [10, 8], [29, 18], [2, 3], [8, 16]]) {
    assert.throws(() => apply(db, `invalid-${grid.join("-")}`, { ...initial.placements, "decor-broadleaf_planter": { grid: grid as [number, number], facing: "south" } }));
  }
  assert.throws(() => apply(db, "remove-essential", {}), /required station/u);
  assert.throws(() => db.furnishing.update({ operationId: "hit-founder", expectedRevision: 0, placements: plant(initial), actorCells: [{ id: "founder", grid: [24, 8] }] }), /blocks or traps/u);
  assert.throws(() => db.furnishing.update({ operationId: "occupied-seat", expectedRevision: 0, placements: { "founder-workstation": { grid: [8, 17], facing: "north" } }, actorCells: [{ id: "founder", grid: [8, 16] }] }), /wait for the actor/u);
  assert.equal(db.furnishing.update({ operationId: "future-empty-floor", expectedRevision: 0, placements: initial.placements, actorCells: [{ id: "founder", grid: [10, 8] }] }).furnishing.revision, 1, "unbuilt future station is not invisible live collision");
  // A supplied live founder supersedes a stale autosave location.
  db.journey.savePlayer({ x: 22 * 32 + 16, y: 16 * 32 + 16 });
  const accepted = db.furnishing.update({ operationId: "live-founder", expectedRevision: 1, placements: plant(initial), actorCells: [{ id: "founder", grid: [17, 19] }] });
  assert.equal(accepted.furnishing.revision, 2);
  db.close();
});

test("write failure rolls back layout and receipt, and hiring failure rolls back employee/charge/grant together", async () => {
  const { db } = await setup(); const initial = db.bootstrap().furnishing;
  db.journey.db.exec("CREATE TEMP TRIGGER fail_receipt BEFORE INSERT ON furnishing_operations BEGIN SELECT RAISE(ABORT,'Simulated full disk'); END");
  assert.throws(() => apply(db, "failed-write", plant(initial)), /full disk/u);
  assert.deepEqual(db.furnishing.state(), initial);
  assert.equal(db.journey.db.prepare("SELECT COUNT(*) n FROM furnishing_operations").get()!.n, 0);
  db.journey.db.exec("DROP TRIGGER fail_receipt");
  assert.equal(apply(db, "failed-write", plant(initial)).furnishing.revision, 1);
  db.journey.db.exec("CREATE TEMP TRIGGER fail_hire_grant BEFORE INSERT ON furnishing_inventory WHEN NEW.id='mira-workstation' BEGIN SELECT RAISE(ABORT,'Grant write failed'); END");
  assert.throws(() => db.journey.hire("mira", 1), /Grant write failed/u);
  assert.equal(db.journey.hired("mira"), false);
  assert.equal(db.journey.db.prepare("SELECT COUNT(*) n FROM company_transactions WHERE id='hire:mira'").get()!.n, 0);
  assert.equal(db.furnishing.state().inventory.some((item) => item.id === "mira-workstation"), false);
  db.journey.db.exec("DROP TRIGGER fail_hire_grant");
  db.journey.hire("mira", 1); db.journey.hire("mira", 1);
  assert.equal(db.furnishing.state().inventory.filter((item) => item.roleKit === "mina_discovery_kit").length, 1);
  db.close();
});

test("furnishing and exact founder position commit or roll back together over a stale autosave location", async () => {
  const { db, path, project } = await setup(); const initial = db.bootstrap().furnishing;
  db.journey.savePlayer({ x: 720, y: 528, movementSeen: true, effectsVolume: 0.27, ambienceVolume: 0.19, attentionEmployeeId: "mira" });
  const beforePlayer = db.journey.state().player;
  const position: [number, number] = [565.125, 619.875];
  const params = { operationId: "atomic-position", expectedRevision: initial.revision, placements: plant(initial),
    actorCells: [{ id: "founder", grid: [17, 19] as [number, number], position }] };
  assert.equal(parseRequest({ kind: "request", id: "atomic", method: "furnishing.update", params }).method, "furnishing.update");
  for (const bad of [[NaN, 619], [565, Infinity], [720, 528], [-1, 619]] as [number, number][]) {
    assert.throws(() => db.furnishing.update({ ...params, actorCells: [{ id: "founder", grid: [17, 19], position: bad }] }), /position must be finite/u);
  }
  db.journey.db.exec("CREATE TEMP TRIGGER fail_position_receipt BEFORE INSERT ON furnishing_operations BEGIN SELECT RAISE(ABORT,'Simulated lost write'); END");
  assert.throws(() => db.furnishing.update(params), /Simulated lost write/u);
  assert.deepEqual(db.furnishing.state(), initial);
  assert.deepEqual(db.journey.state().player, beforePlayer, "failed furnishing transaction must not move the saved founder");
  db.journey.db.exec("DROP TRIGGER fail_position_receipt");
  const result = db.furnishing.update(params);
  const expectedPlayer = { ...beforePlayer, x: position[0], y: position[1] };
  assert.deepEqual(db.journey.state().player, expectedPlayer);
  db.close();
  const reopened = new GameDatabase(path, project);
  assert.deepEqual(reopened.bootstrap().furnishing, result.furnishing);
  assert.deepEqual(reopened.bootstrap().journey.player, expectedPlayer, "fractional position survives restart exactly, without losing unrelated player fields");
  reopened.journey.savePlayer({ ...expectedPlayer, x: 560.5, y: 650.5 });
  const laterPlayer = reopened.journey.state().player;
  assert.equal(reopened.furnishing.update(params).replayed, true);
  assert.deepEqual(reopened.journey.state().player, laterPlayer, "replayed receipt must not move founder back to an older position");
  reopened.close();
});

test("corrupt/incompatible layouts recover the last valid room or safely store decor without losing ownership", async () => {
  const { db, path, project } = await setup();
  const latest = apply(db, "latest", plant(db.bootstrap().furnishing)).furnishing;
  db.journey.db.prepare("UPDATE furnishing_state SET placements_json=?").run("{corrupt"); db.close();
  let recovered = new GameDatabase(path, project);
  assert.deepEqual(recovered.furnishing.state().placements, latest.placements);
  assert.match(recovered.furnishing.state().recovery, /last valid/u);
  assert.equal(recovered.furnishing.state().revision, latest.revision + 1);
  const stable = recovered.furnishing.state();
  assert.deepEqual(recovered.furnishing.state(), stable, "recovery is durable, not repeated every bootstrap");
  recovered.journey.db.exec("UPDATE furnishing_state SET version=999"); recovered.close();
  recovered = new GameDatabase(path, project);
  assert.deepEqual(recovered.furnishing.state().placements, latest.placements);
  recovered.journey.db.exec("UPDATE furnishing_state SET placements_json='[]',last_valid_json='invalid'"); recovered.close();
  recovered = new GameDatabase(path, project);
  assert.deepEqual(Object.keys(recovered.furnishing.state().placements), ["founder-workstation"]);
  assert.equal(recovered.furnishing.state().inventory.length, founderInventory);
  assert.match(recovered.furnishing.state().recovery, /decorations are in storage/u);
  const clean = apply(recovered, "ack-recovery", recovered.furnishing.state().placements).furnishing;
  assert.equal(clean.recovery, ""); recovered.close();
});

test("version-six migration preserves existing company and grants the two role kits once", async () => {
  const { path, project } = await versionSixCompany();
  const migrated = new GameDatabase(path, project);
  const state = migrated.bootstrap();
  assert.equal(state.employees.length, 2); assert.equal(state.journey.company.cashCents, 12500);
  assert.equal(state.journey.company.earnedCents, 90000); assert.equal(state.journey.company.reputation, 13);
  assert.equal(state.journey.player.x, 550); assert.equal(state.furnishing.inventory.length, hiredTwoInventory);
  assert.deepEqual(state.furnishing.placements["mira-workstation"]?.grid, [8, 5], "compatible legacy desk coordinates are preserved");
  assert.deepEqual(state.furnishing.placements["theo-workstation"]?.grid, [20, 8], "colliding legacy station alone falls back to safe default");
  assert.match(state.furnishing.recovery, /previous workstation locations/u);
  assert.equal(state.employees.find((employee) => employee.id === "mira")?.deskX, 8);
  assert.equal(state.employees.find((employee) => employee.id === "theo")?.deskX, 20);
  assert.deepEqual(state.furnishing.inventory.filter((item) => item.roleKit).map((item) => item.roleKit).sort(), ["founder_strategy_kit", "mina_discovery_kit", "theo_campaign_kit"]);
  assert.deepEqual(migrated.bootstrap().furnishing, state.furnishing);
  migrated.close();
});

test("version-six migration preserves a valid employee desk swap as one joint layout", async () => {
  const { path, project } = await versionSixCompany([["mira", "Mina", 20, 8], ["theo", "Theo", 10, 8]]);
  const migrated = new GameDatabase(path, project);
  const state = migrated.bootstrap();
  assert.deepEqual(state.furnishing.placements["mira-workstation"], { grid: [20, 8], facing: "south" });
  assert.deepEqual(state.furnishing.placements["theo-workstation"], { grid: [10, 8], facing: "south" });
  assert.equal(state.furnishing.recovery, "", "a valid old batch must not produce a fallback notice");
  assert.equal(state.employees.find((employee) => employee.id === "mira")?.deskX, 20);
  assert.equal(state.employees.find((employee) => employee.id === "theo")?.deskX, 10);
  assert.deepEqual(state.journey.company, { cashCents: 12500, earnedCents: 90000, reputation: 13, chapter: 1 });
  assert.deepEqual(state.journey.player, { x: 550, y: 550 });
  migrated.close();
  const reopened = new GameDatabase(path, project);
  assert.deepEqual(reopened.bootstrap().furnishing, state.furnishing);
  assert.deepEqual(reopened.bootstrap().journey.company, state.journey.company);
  reopened.close();
});

test("process death inside the real mutation rolls back both layout and receipt before restart", async (t) => {
  const { db, root, path, project } = await setup(); const before = db.bootstrap().furnishing;
  db.journey.savePlayer({ x: 720, y: 528, movementSeen: true, effectsVolume: 0.3, ambienceVolume: 0.4 });
  const beforePlayer = db.journey.state().player; db.close();
  const child = spawn(process.execPath, ["test/fixtures/furnishing-interrupted.mjs", root], { cwd: new URL("..", import.meta.url), stdio: ["pipe", "pipe", "pipe"] });
  t.after(() => { if (child.exitCode === null) child.kill("SIGKILL"); });
  let stderr = ""; child.stderr.on("data", (data) => { stderr += String(data); });
  await new Promise<void>((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`Crash probe did not reach transaction: ${stderr}`)), 5000);
    child.stdout.on("data", (data) => { if (String(data).includes("FURNISHING_UNCOMMITTED")) { clearTimeout(timeout); resolve(); } });
    child.once("exit", () => { clearTimeout(timeout); reject(new Error(`Crash probe exited early: ${stderr}`)); });
  });
  const exited = once(child, "exit"); child.kill("SIGKILL"); await exited;
  const reopened = new GameDatabase(path, project);
  assert.deepEqual(reopened.bootstrap().furnishing, before);
  assert.deepEqual(reopened.bootstrap().journey.player, beforePlayer, "SIGKILL inside the transaction also rolls back the exact founder position");
  assert.equal(reopened.journey.db.prepare("SELECT COUNT(*) n FROM furnishing_operations").get()!.n, 0);
  reopened.journey.db.exec("DROP TRIGGER furnishing_crash_probe");
  assert.equal(reopened.furnishing.update({ operationId: "interrupted-layout", expectedRevision: before.revision, placements: plant(before, "east"), actorCells: [{ id: "founder", grid: [17, 19], position: [569.25, 629.75] }] }).furnishing.revision, 1);
  assert.deepEqual(reopened.journey.state().player, { ...beforePlayer, x: 569.25, y: 629.75 });
  reopened.close();
});
