import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import type { DatabaseSync } from "node:sqlite";
import { fileURLToPath } from "node:url";
import { parseFurnishingState } from "./validation.js";

export type Cell = [number, number];
export type Facing = "north" | "east" | "south" | "west";
export interface FurniturePlacement { grid: Cell; facing: Facing }
export type FurniturePlacements = Record<string, FurniturePlacement>;
export interface FurnitureItem {
  id: string; kind: string; ownerId: string; essential: boolean; grant: string; roleKit: string;
}
export interface FurnishingState {
  version: 1; revision: number; inventory: FurnitureItem[]; placements: FurniturePlacements; recovery: string;
}
export interface FurnitureActor {
  id: string; grid: Cell;
  /** Exact world pixels, not rounded cell centres. Optional for older clients. */
  position?: [number, number];
}
export interface FurnishingUpdate {
  operationId: string; expectedRevision: number; placements: FurniturePlacements;
  actorCells?: FurnitureActor[];
}
interface Prop { id: string; kind: string; grid: Cell; facing: Facing; required_hires: number; owner_id?: string; required_office_level?: number }
type Rect = [number, number, number, number];
interface Room {
  tile_size: number; width: number; height: number;
  floor_rects: Rect[]; wall_rects: Rect[]; circulation_rects: Rect[];
  doors: Array<{ grid: Cell; width: number; depth: number; entrance?: boolean }>;
  player_spawn: Cell; employees: Array<{ id: string; spawn: Cell }>; props: Prop[];
}
interface Profile {
  status?: string; profile_kind?: string; occupied: Cell[]; clearance: Cell[];
  anchor_offset: Cell; visual_bounds: Rect; interaction?: Cell; work_cell?: Cell;
  approach_visual_bounds?: Rect; collaboration_slots?: Array<{ cell: Cell; visual_bounds: Rect }>;
  standing_viewpoints?: Array<{ cell: Cell; visual_bounds: Rect }>;
  facing_profiles?: Partial<Record<Facing, Partial<Profile>>>;
}
interface Resolved {
  id: string; occupied: Cell[]; clearance: Cell[]; targets: Cell[]; bounds: Rect; headroom: Rect[];
}
interface RoleKit { host_kind: string; owner_id: string; facing_profiles: Record<Facing, { visual_bounds: Rect }> }
interface DecorKit { host_kind: string; owner_id: string; facing_profiles: Record<Facing, { visual_bounds: Rect }> }
const FACINGS = ["north", "east", "south", "west"];
const key = (cell: Cell): string => `${cell[0]},${cell[1]}`;
const plus = (left: Cell, right: Cell): Cell => [left[0] + right[0], left[1] + right[1]];
const cell = (value: unknown): value is Cell => Array.isArray(value) && value.length === 2 && value.every(Number.isSafeInteger);
function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value && typeof value === "object") return `{${Object.entries(value).sort(([a], [b]) => a.localeCompare(b)).map(([k, v]) => `${JSON.stringify(k)}:${canonical(v)}`).join(",")}}`;
  return JSON.stringify(value);
}
function addRectangle(set: Set<string>, rect: Rect, enabled = true): void {
  for (let y = rect[1]; y < rect[1] + rect[3]; y++) for (let x = rect[0]; x < rect[0] + rect[2]; x++) {
    if (enabled) set.add(key([x, y])); else set.delete(key([x, y]));
  }
}

/** The worker validates the same authored JSON geometry as Godot. No client may
 * grant itself an item, supply a footprint, or persist an unreviewed direction. */
export class FurnishingGeometry {
  readonly room: Room;
  readonly catalog: Record<string, Profile>;
  readonly starterDecor: Array<{ id: string; kind: string }>;
  readonly employeeRoleKits: Record<string, string>;
  readonly roleKits: Record<string, RoleKit>;
  readonly employeeDecorKits: Record<string, string>;
  readonly decorKits: Record<string, DecorKit>;
  readonly floor = new Set<string>();
  readonly circulation = new Set<string>();
  readonly entrances = new Set<string>();

  constructor() {
    const data = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "game", "data");
    this.room = JSON.parse(readFileSync(join(data, "office_layout.json"), "utf8")) as Room;
    this.catalog = (JSON.parse(readFileSync(join(data, "furniture_catalog.json"), "utf8")) as { furniture: Record<string, Profile> }).furniture;
    const additions = JSON.parse(readFileSync(join(data, "furnishing_catalog.json"), "utf8")) as { furniture: Record<string, Profile>; starter_decor: Array<{ id: string; kind: string }>; employee_role_kits: Record<string, string>; role_kits: Record<string, RoleKit>; employee_decor_kits?: Record<string, string>; decor_kits?: Record<string, DecorKit> };
    Object.assign(this.catalog, additions.furniture);
    this.starterDecor = additions.starter_decor;
    this.employeeRoleKits = additions.employee_role_kits;
    this.roleKits = additions.role_kits;
    this.employeeDecorKits = additions.employee_decor_kits ?? {};
    this.decorKits = additions.decor_kits ?? {};
    for (const rect of this.room.floor_rects) addRectangle(this.floor, rect);
    for (const rect of this.room.wall_rects) addRectangle(this.floor, rect, false);
    for (const rect of this.room.circulation_rects) addRectangle(this.circulation, rect);
    for (const door of this.room.doors) {
      const rect: Rect = [...door.grid, door.width, door.depth];
      addRectangle(this.floor, rect);
      if (door.entrance) addRectangle(this.entrances, rect);
    }
    if (this.room.tile_size !== 32 || !this.floor.size || !this.entrances.size) throw new Error("Invalid authored furnishing room");
  }

  #boundsAt(bounds: Rect, anchor: Cell): Rect { return [anchor[0] + bounds[0], anchor[1] + bounds[1], bounds[2], bounds[3]]; }
  #world(grid: Cell): Cell { return [grid[0] * 32 + 16, grid[1] * 32 + 16]; }
  #unionBounds(left: Rect, right: Rect): Rect {
    const x = Math.min(left[0], right[0]);
    const y = Math.min(left[1], right[1]);
    return [x, y, Math.max(left[0] + left[2], right[0] + right[2]) - x, Math.max(left[1] + left[3], right[1] + right[3]) - y];
  }
  #resolve(id: string, kind: string, placement: FurniturePlacement, roleKit = "", ownerId = ""): Resolved {
    const base = this.catalog[kind];
    const direction = base?.facing_profiles?.[placement.facing];
    if (!base || !direction || direction.status !== "runtime_ready") throw new Error(`${id}: facing has no approved runtime profile`);
    const profile = { ...base, ...direction } as Profile;
    const origin = placement.grid;
    const offset = (value: Cell): Cell => plus(origin, value);
    let nativeBounds = profile.visual_bounds;
    if (roleKit) {
      const kit = this.roleKits[roleKit];
      const kitBounds = kit?.facing_profiles?.[placement.facing]?.visual_bounds;
      if (!kit || kit.host_kind !== kind || !kitBounds) throw new Error(`${id}: incompatible workstation role kit`);
      nativeBounds = this.#unionBounds(nativeBounds, kitBounds);
    }
    // Catalog decor kits share the host footprint. Union ink with the role kit; add no cells.
    const decorId = this.employeeDecorKits[ownerId] ?? "";
    if (decorId) {
      const decor = this.decorKits[decorId];
      const decorBounds = decor?.facing_profiles?.[placement.facing]?.visual_bounds;
      if (!decor || decor.host_kind !== kind || decor.owner_id !== ownerId || !decorBounds) throw new Error(`${id}: incompatible workstation decor kit`);
      nativeBounds = this.#unionBounds(nativeBounds, decorBounds);
    }
    const bounds = this.#boundsAt(nativeBounds, plus(this.#world(origin), profile.anchor_offset));
    const targets: Cell[] = [];
    const headroom: Rect[] = [];
    if (profile.profile_kind !== "decorative") {
      if (!profile.interaction) throw new Error(`${id}: missing interaction point`);
      targets.push(offset(profile.interaction), offset(profile.work_cell ?? profile.interaction));
      if (profile.profile_kind === "service" && profile.approach_visual_bounds) headroom.push(this.#boundsAt(profile.approach_visual_bounds, this.#world(offset(profile.interaction))));
    }
    for (const slot of profile.collaboration_slots ?? []) {
      targets.push(offset(slot.cell));
      headroom.push(this.#boundsAt(slot.visual_bounds, this.#world(offset(slot.cell))));
    }
    for (const point of profile.standing_viewpoints ?? []) headroom.push(this.#boundsAt(point.visual_bounds, this.#world(offset(point.cell))));
    return { id, occupied: profile.occupied.map(offset), clearance: profile.clearance.map(offset), targets, bounds, headroom };
  }
  #rectOnFloor(bounds: Rect): boolean {
    if (!bounds.every(Number.isFinite) || bounds[2] <= 0 || bounds[3] <= 0) return false;
    for (let y = Math.floor(bounds[1] / 32); y <= Math.floor((bounds[1] + bounds[3] - 0.001) / 32); y++) {
      for (let x = Math.floor(bounds[0] / 32); x <= Math.floor((bounds[0] + bounds[2] - 0.001) / 32); x++) if (!this.floor.has(key([x, y]))) return false;
    }
    return true;
  }

  validate(placements: FurniturePlacements, inventory: FurnitureItem[], actors: FurnitureActor[] = [], current: FurniturePlacements = placements): void {
    if (!placements || typeof placements !== "object" || Array.isArray(placements) || Object.keys(placements).length > 32) throw new Error("Invalid furnishing placement map");
    const items = new Map(inventory.map((item) => [item.id, item]));
    for (const item of inventory) if (item.essential && !Object.hasOwn(placements, item.id)) throw new Error(`${item.id}: required station cannot be stored`);
    const resolved: Resolved[] = [];
    for (const [id, placement] of Object.entries(placements)) {
      const item = items.get(id);
      if (!item) throw new Error(`Furniture is not owned: ${id}`);
      if (!placement || Object.keys(placement).some((field) => !["grid", "facing"].includes(field)) || !cell(placement.grid) || !FACINGS.includes(placement.facing)) throw new Error(`${id}: invalid integer grid or facing`);
      resolved.push(this.#resolve(id, item.kind, placement, item.roleKit, item.ownerId));
    }
    // Reserve every future station in its authored position. This is the same
    // all-stage gate used by the game, so a later hire never evicts player decor.
    for (const prop of this.room.props) if (!items.has(prop.id)) resolved.push(this.#resolve(prop.id, prop.kind, prop, this.employeeRoleKits[prop.owner_id ?? ""] ?? "", prop.owner_id ?? ""));
    const occupied = new Map<string, string>();
    for (const item of resolved) {
      for (const grid of item.occupied) {
        const k = key(grid);
        if (!this.floor.has(k)) throw new Error(`${item.id}: footprint intersects a wall`);
        if (this.entrances.has(k) || this.circulation.has(k)) throw new Error(`${item.id}: blocks a reserved aisle or entrance`);
        if (occupied.has(k)) throw new Error(`${item.id}: overlaps ${occupied.get(k)}`);
        occupied.set(k, item.id);
      }
      if (!this.#rectOnFloor(item.bounds)) throw new Error(`${item.id}: artwork extends into a wall; move it inward`);
      if (item.headroom.some((bounds) => !this.#rectOnFloor(bounds))) throw new Error(`${item.id}: actor headroom overlaps architecture`);
    }
    for (const item of resolved) {
      for (const grid of [...item.clearance, ...item.targets]) if (!this.floor.has(key(grid)) || occupied.has(key(grid))) throw new Error(`${item.id}: chair, viewing, or service clearance is blocked`);
      for (const other of resolved) {
        if (item.id >= other.id) continue;
        const [x, y, w, h] = item.bounds; const [ox, oy, ow, oh] = other.bounds;
        if (x < ox + ow && x + w > ox && y < oy + oh && y + h > oy) throw new Error(`${item.id}: furniture artwork overlaps ${other.id}`);
      }
    }
    const flood = (blocked: Set<string>): Set<string> => {
      const reached = new Set<string>();
      const queue = [...this.entrances].filter((k) => !blocked.has(k));
      for (let index = 0; index < queue.length; index++) {
        const k = queue[index]!;
        if (reached.has(k)) continue;
        reached.add(k);
        const [x, y] = k.split(",").map(Number) as Cell;
        for (const next of [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]] as Cell[]) {
          const nk = key(next);
          if (this.floor.has(nk) && !blocked.has(nk) && !reached.has(nk)) queue.push(nk);
        }
      }
      return reached;
    };
    const reached = flood(new Set(occupied.keys()));
    for (const item of resolved) if (item.targets.some((target) => !reached.has(key(target)))) throw new Error(`${item.id}: cannot reach the work or interaction point`);
    for (const k of this.floor) if (!occupied.has(k) && !reached.has(k)) throw new Error("Furniture disconnects part of the room");
    // Future stations reserve furnishing space, not invisible live collision.
    // A founder standing in tomorrow's empty workstation must still be able to
    // decorate elsewhere today. Test actors against the actual stage only.
    const liveReached = actors.length ? flood(new Set(resolved.filter((item) => items.has(item.id)).flatMap((item) => item.occupied.map(key)))) : reached;
    const actorIds = new Set<string>();
    for (const actor of actors) {
      if (!actor || !["founder", "mira", "theo", "creative"].includes(actor.id) || actorIds.has(actor.id) || !cell(actor.grid) || !this.floor.has(key(actor.grid))) throw new Error("Invalid live actor cells");
      if (actor.position !== undefined && (!Array.isArray(actor.position) || actor.position.length !== 2 || !actor.position.every(Number.isFinite) || actor.position[0] < 0 || actor.position[0] > 1280 || actor.position[1] < 0 || actor.position[1] > 720 || Math.floor(actor.position[0] / 32) !== actor.grid[0] || Math.floor(actor.position[1] / 32) !== actor.grid[1])) throw new Error("Actor position must be finite world pixels matching its declared cell");
      actorIds.add(actor.id);
      if (!liveReached.has(key(actor.grid))) throw new Error(`${actor.id}: placement blocks or traps an actor`);
      // A seated employee's cell may stay clear while its chair moves away.
      // Do not move any changed station out from under an actor in its old
      // footprint/clearance. Godot also checks its sub-cell collision circle.
      for (const item of inventory) {
        const previous = current[item.id];
        if (!previous || canonical(previous) === canonical(placements[item.id])) continue;
        const old = this.#resolve(item.id, item.kind, previous, item.roleKit, item.ownerId);
        if ([...old.occupied, ...old.clearance].some((grid) => key(grid) === key(actor.grid))) throw new Error(`${item.id}: wait for the actor to leave before moving this furniture`);
      }
    }
  }
}

/** Atomic authoritative furnishing state. Grant IDs are inventory primary keys;
 * layout snapshots and operation receipts commit together in the same database. */
export class FurnishingStore {
  readonly geometry = new FurnishingGeometry();
  constructor(readonly db: DatabaseSync) { this.transaction(() => this.sync()); }
  private transaction<T>(action: () => T): T {
    this.db.exec("BEGIN IMMEDIATE");
    try { const result = action(); this.db.exec("COMMIT"); return result; }
    catch (error) { this.db.exec("ROLLBACK"); throw error; }
  }
  private inventory(): FurnitureItem[] {
    return this.db.prepare("SELECT * FROM furnishing_inventory ORDER BY id").all().map((row) => ({
      id: String(row.id), kind: String(row.kind), ownerId: String(row.owner_id), essential: Boolean(row.essential), grant: String(row.grant_id), roleKit: String(row.role_kit),
    }));
  }
  private defaults(inventory: FurnitureItem[]): FurniturePlacements {
    const owned = new Set(inventory.map((item) => item.id));
    return Object.fromEntries(this.geometry.room.props.filter((prop) => owned.has(prop.id)).map((prop) => [prop.id, { grid: prop.grid, facing: prop.facing }]));
  }
  /** First-run lounge only. Recovery still stores décor; never occupies the [24,8] decor pocket. */
  private starterLounge(inventory: FurnitureItem[], base: FurniturePlacements): FurniturePlacements {
    const owned = new Set(inventory.map((item) => item.id));
    if (!owned.has("decor-phone_booth") || Object.hasOwn(base, "decor-phone_booth")) return base;
    const candidate: FurniturePlacements = { ...base, "decor-phone_booth": { grid: [3, 18], facing: "south" } };
    try {
      this.geometry.validate(candidate, inventory);
      return candidate;
    } catch {
      return base;
    }
  }
  private officeLevel(): number {
    try {
      const row = this.db.prepare("SELECT office_level FROM tycoon_meta WHERE id = 1").get() as { office_level?: number } | undefined;
      const level = Number(row?.office_level ?? 1);
      return Number.isInteger(level) && level > 0 ? level : 1;
    } catch {
      return 1;
    }
  }
  private syncEmployeeDesks(placements: FurniturePlacements, inventory: FurnitureItem[]): void {
    const save = this.db.prepare("UPDATE employees SET desk_x=?,desk_y=? WHERE id=?");
    for (const item of inventory) {
      const placed = placements[item.id];
      if (placed && item.ownerId && item.ownerId !== "founder") save.run(...placed.grid, item.ownerId);
    }
  }
  /** Caller may use this inside the hiring transaction. */
  sync(): void {
    const hired = this.db.prepare("SELECT id FROM employees WHERE employment_status='hired'").all().map((row) => String(row.id));
    const officeLevel = this.officeLevel();
    const insert = this.db.prepare("INSERT OR IGNORE INTO furnishing_inventory(id,kind,owner_id,essential,grant_id,role_kit) VALUES (?,?,?,?,?,?)");
    let grants = 0;
    const addedStations: FurniturePlacements = {};
    for (const prop of this.geometry.room.props) {
      const neededLevel = prop.required_office_level ?? 1;
      if (neededLevel > officeLevel) continue;
      if (prop.required_hires > hired.length || (prop.owner_id && prop.owner_id !== "founder" && !hired.includes(prop.owner_id))) continue;
      const owner = prop.owner_id ?? "";
      const grant = neededLevel > 1 ? `office-level:${neededLevel}` : owner !== "" && owner !== "founder" ? `hire:${owner}` : `office-stage:${prop.required_hires}`;
      const added = Number(insert.run(prop.id, prop.kind, owner, 1, grant, this.geometry.employeeRoleKits[owner] ?? "").changes);
      grants += added;
      if (added) addedStations[prop.id] = { grid: prop.grid, facing: prop.facing };
    }
    for (const { id, kind } of this.geometry.starterDecor) grants += Number(insert.run(id, kind, "", 0, "starter-decor-v1", "").changes);
    const founderKit = this.geometry.employeeRoleKits["founder"] ?? "";
    if (founderKit) {
      grants += Number(this.db.prepare("UPDATE furnishing_inventory SET role_kit=? WHERE id='founder-workstation' AND role_kit=''").run(founderKit).changes);
    }
    const inventory = this.inventory();
    const row = this.db.prepare("SELECT * FROM furnishing_state WHERE id=1").get();
    if (!row) {
      let placements = this.starterLounge(inventory, this.defaults(inventory));
      let recovery = "";
      // Pre-furnishing companies can carry authored/custom workstation cells in
      // employee rows. Preserve every compatible location rather than silently
      // flattening an old room to today's defaults. New hires use reserved cells.
      const legacyStations: FurniturePlacements = {};
      for (const employee of this.db.prepare("SELECT id,desk_x,desk_y FROM employees WHERE employment_status='hired' ORDER BY id").all()) {
        const id = `${String(employee.id)}-workstation`;
        const old = placements[id];
        if (!old) continue;
        legacyStations[id] = { grid: [Number(employee.desk_x), Number(employee.desk_y)], facing: old.facing };
      }
      const legacyBatch = { ...placements, ...legacyStations };
      try {
        // Validate the actual old room as one layout first. A legal desk swap
        // must not collide with the other employee's temporary default desk.
        this.geometry.validate(legacyBatch, inventory);
        placements = legacyBatch;
      } catch {
        for (const [id, legacy] of Object.entries(legacyStations)) {
          const candidate = { ...placements, [id]: legacy };
          try { this.geometry.validate(candidate, inventory); placements = candidate; }
          catch { recovery = "Some previous workstation locations no longer fit the approved room. Those stations use safe default locations; your company progress is unchanged."; }
        }
      }
      this.geometry.validate(placements, inventory);
      this.db.prepare("INSERT INTO furnishing_state VALUES (1,1,0,?,?,?)").run(JSON.stringify(placements), JSON.stringify({ version: 1, placements }), recovery);
      this.syncEmployeeDesks(placements, inventory);
      return;
    }
    let placements: FurniturePlacements;
    let recovery = String(row.recovery);
    let recovered = false;
    try {
      if (row.version !== 1) throw new Error("Unsupported layout version");
      placements = JSON.parse(String(row.placements_json)) as FurniturePlacements;
      if (!placements || typeof placements !== "object" || Array.isArray(placements)) throw new Error("Invalid layout map");
      // Newly granted stations are inserted only into their reserved cells.
      placements = { ...addedStations, ...placements };
      this.geometry.validate(placements, inventory);
    } catch {
      recovered = true;
      try {
        const saved = JSON.parse(String(row.last_valid_json)) as { version: number; placements: FurniturePlacements };
        if (saved.version !== 1 || !saved.placements || typeof saved.placements !== "object" || Array.isArray(saved.placements)) throw new Error("Unsupported snapshot version");
        placements = { ...addedStations, ...saved.placements };
        this.geometry.validate(placements, inventory);
        recovery = "The saved room was invalid. Your last valid furniture layout has been restored.";
      } catch {
        placements = this.defaults(inventory);
        this.geometry.validate(placements, inventory);
        recovery = "The saved room could not be restored. Required stations are safely reset; your decorations are in storage.";
      }
    }
    if (grants || recovered) {
      this.db.prepare("UPDATE furnishing_state SET version=1,revision=revision+1,placements_json=?,last_valid_json=?,recovery=? WHERE id=1").run(JSON.stringify(placements), JSON.stringify({ version: 1, placements }), recovery);
      this.syncEmployeeDesks(placements, inventory);
    }
  }
  private read(): FurnishingState {
    const row = this.db.prepare("SELECT * FROM furnishing_state WHERE id=1").get()!;
    return parseFurnishingState({ version: 1, revision: Number(row.revision), inventory: this.inventory(), placements: JSON.parse(String(row.placements_json)) as FurniturePlacements, recovery: String(row.recovery) });
  }
  state(): FurnishingState { return this.transaction(() => { this.sync(); return this.read(); }); }
  update(value: FurnishingUpdate): { furnishing: FurnishingState; replayed: boolean } {
    return this.transaction(() => {
      if (!value || typeof value.operationId !== "string" || !/^[A-Za-z0-9_-]{1,100}$/u.test(value.operationId) || !Number.isSafeInteger(value.expectedRevision) || value.expectedRevision < 0) throw new Error("Invalid furnishing operation or revision");
      const fingerprint = createHash("sha256").update(canonical(value)).digest("hex");
      const prior = this.db.prepare("SELECT * FROM furnishing_operations WHERE operation_id=?").get(value.operationId);
      if (prior) {
        if (prior.fingerprint !== fingerprint) throw new Error("Furnishing operation id was already used for a different layout");
        this.sync();
        // Return the latest authoritative projection, not an old receipt that
        // would roll the visible room back after newer successful edits.
        return { furnishing: this.read(), replayed: true };
      }
      this.sync();
      const before = this.read();
      if (value.expectedRevision !== before.revision) throw new Error("The room changed. Refresh the saved layout before trying again.");
      const player = JSON.parse(String(this.db.prepare("SELECT player_json FROM company_state WHERE id=1").get()!.player_json)) as Record<string, unknown>;
      const actors = value.actorCells ? [...value.actorCells] : [];
      if (!actors.some((actor) => actor.id === "founder")) {
        const grid: Cell = typeof player.x === "number" && typeof player.y === "number" ? [Math.floor(player.x / 32), Math.floor(player.y / 32)] : this.geometry.room.player_spawn;
        actors.push({ id: "founder", grid });
      }
      this.geometry.validate(value.placements, before.inventory, actors, before.placements);
      this.db.prepare("UPDATE furnishing_state SET revision=revision+1,placements_json=?,last_valid_json=?,recovery='' WHERE id=1").run(JSON.stringify(value.placements), JSON.stringify({ version: 1, placements: value.placements }));
      this.syncEmployeeDesks(value.placements, before.inventory);
      const founder = actors.find((actor) => actor.id === "founder");
      if (founder?.position) {
        // A new prop can occupy the previous autosave location. Save the frozen
        // live founder position in this very transaction so a crash cannot put
        // them inside it. Keep onboarding/settings/attention fields untouched.
        this.db.prepare("UPDATE company_state SET player_json=? WHERE id=1").run(JSON.stringify({ ...player, x: founder.position[0], y: founder.position[1] }));
      }
      const furnishing = this.read();
      this.db.prepare("INSERT INTO furnishing_operations VALUES (?,?,?)").run(value.operationId, fingerprint, JSON.stringify(furnishing));
      return { furnishing, replayed: false };
    });
  }
}
