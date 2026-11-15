// Map admission complements the asset gate; it does not assess artistic quality.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ROOT, localFile, sha256, styleReference, validateStyleProfile } from './lib/art-reference.mjs';

const DIRECTORY = 'dev/map-catalogue';
const CHECKS = ['universe', 'camera_scale', 'composition', 'depth', 'navigation', 'spawn_return', 'interaction_readability'];
const json = (root, name) => JSON.parse(fs.readFileSync(localFile(root, name), 'utf8'));
const text = (root, name) => fs.readFileSync(localFile(root, name), 'utf8');
const key = point => point.join(',');
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function requireThat(condition, message) { if (!condition) throw new Error(message); }
function cell(value) { return Array.isArray(value) && value.length === 2 && value.every(Number.isInteger); }
function resource(name) { requireThat(name.startsWith('res://') && !name.includes('..'), `Invalid resource: ${name}`); return `game/${name.slice(6)}`; }
function records(root, directory) {
  return fs.readdirSync(path.join(root, directory)).filter(name => name.endsWith('.json')).sort().map(name => json(root, `${directory}/${name}`));
}

// Explicit adapters read actual runtime geometry. A new representation needs an
// adapter and tests, rather than an unverified duplicate map in its manifest.
export function mapGeometry(root, manifest) {
  if (manifest.adapter === 'office_json') {
    const value = json(root, manifest.source);
    requireThat(value.id === manifest.id, 'Layout id differs from manifest');
    const doors = value.doors ?? [];
    return { width: value.width, height: value.height, tile: value.tile_size,
      floor: value.floor_rects, walls: value.wall_rects ?? [], doors: doors.map(d => [...d.grid, d.width ?? 1, d.depth ?? 1]),
      spawn: value.player_spawn, exits: doors.filter(d => d.entrance).map(d => d.grid),
      targets: [], props: value.props.map(p => ({ kind: p.kind, facing: p.facing, cell: p.grid })) };
  }
  requireThat(manifest.adapter === 'courtyard_gd', `Unsupported map adapter: ${manifest.adapter}`);
  const source = text(root, manifest.source);
  const configure = source.match(/navigation\.configure\((\{[^\n]+\}), Vector2.ZERO\)/);
  requireThat(configure, 'Courtyard must expose literal navigation configuration');
  const nav = JSON.parse(configure[1]);
  const vector = name => {
    const match = source.match(new RegExp(`const ${name} := Vector2\\(([^)]+)\\)`));
    requireThat(match, `Missing courtyard ${name}`);
    const value = match[1].split(',').map(Number);
    requireThat(cell(value), `Invalid courtyard ${name}`);
    return value.map(n => Math.floor(n / nav.tile_size));
  };
  const props = [...source.matchAll(/_add_decoration\(catalogue, "([^"]+)", Vector2\(([^)]+)\)\)/g)].map(match => ({
    kind: match[1], facing: 'south', cell: match[2].split(',').map(n => Math.floor(Number(n) / nav.tile_size))
  }));
  requireThat(props.length > 0, 'Courtyard decoration adapter found no registered props');
  requireThat(source.includes('catalogue.resolve_profile(kind, "south")'), 'Courtyard prop facing adapter drift');
  return { width: nav.width, height: nav.height, tile: nav.tile_size, floor: nav.walkable_rects, walls: nav.wall_rects ?? [],
    spawn: vector('SPAWN'), exits: [vector('SPAWN')], targets: [vector('THEO_APPROACH')], props };
}

function floorCells(geometry) {
  requireThat(geometry.tile === 32, 'Maps must use the canonical 32px grid');
  requireThat([geometry.width, geometry.height].every(n => Number.isInteger(n) && n > 0 && n <= 256), 'Invalid map dimensions');
  const floor = new Set();
  // Match OfficeLayout.configure: door cells reopen authored wall cutouts.
  for (const [rects, enabled] of [[geometry.floor, true], [geometry.walls, false], [geometry.doors ?? [], true]]) {
    requireThat(Array.isArray(rects), 'Missing map rectangles');
    for (const rect of rects) {
      requireThat(Array.isArray(rect) && rect.length === 4 && rect.every(Number.isInteger) && rect[0] >= 0 && rect[1] >= 0 && rect[2] > 0 && rect[3] > 0 && rect[0] + rect[2] <= geometry.width && rect[1] + rect[3] <= geometry.height, 'Invalid map rectangle');
      for (let y = rect[1]; y < rect[1] + rect[3]; y++) for (let x = rect[0]; x < rect[0] + rect[2]; x++) {
        if (enabled) floor.add(key([x, y])); else floor.delete(key([x, y]));
      }
    }
  }
  requireThat(floor.size > 0, 'Map has no floor');
  return floor;
}

export function inspectMap(root, manifest) {
  requireThat(manifest.schema_version === 1 && /^[a-z0-9][a-z0-9-]+$/.test(manifest.id), 'Invalid map identity/version');
  requireThat(manifest.world_profile === 'startup-valley-world-v1', 'Map must use the shared world profile');
  requireThat(manifest.camera_profile === 'office-square-grid-v1' && manifest.runtime_scale === 1 && manifest.sampling === 'nearest', 'Map camera/scale/sampling differs from shared assets');
  requireThat(Array.isArray(manifest.modules) && manifest.modules.length > 0, 'Map needs its rendering modules');
  const geometry = mapGeometry(root, manifest), floor = floorCells(geometry), occupied = new Set();
  const bindings = new Map();
  const bind = name => { const bytes = fs.readFileSync(localFile(root, name)); bindings.set(name, sha256(bytes)); };
  const bindData = (name, value) => {
    bindings.set(name, sha256(JSON.stringify(value)));
    for (const match of JSON.stringify(value).matchAll(/"(res:\/\/[^"\n]+\.png)"/g)) bind(resource(match[1]));
  };
  bind(`${DIRECTORY}/world-profile.json`);
  for (const name of [manifest.source, ...manifest.modules, ...(manifest.art ?? [])]) {
    bind(name);
    if (!name.endsWith('.gd')) continue;
    for (const match of text(root, name).matchAll(/"(res:\/\/[^"\n]+\.png)"/g)) bind(resource(match[1]));
  }
  // Hash only used catalog families, not unrelated furnishings or UI scripts.
  const catalogs = ['game/data/furniture_catalog.json', 'game/data/furnishing_catalog.json'].map(name => ({ name, value: json(root, name) }));
  for (const prop of geometry.props) {
    requireThat(cell(prop.cell), `Invalid ${prop.kind} placement`);
    const catalog = catalogs.find(c => c.value.furniture?.[prop.kind]);
    requireThat(catalog, `Unregistered prop: ${prop.kind}`);
    const family = catalog.value.furniture[prop.kind];
    requireThat(family.facings?.includes(prop.facing), `Unsupported facing: ${prop.kind}/${prop.facing}`);
    const profile = family.facing_profiles?.[prop.facing];
    if (profile) requireThat(profile.status === 'runtime_ready', `Unapproved prop profile: ${prop.kind}/${prop.facing}`);
    const resolved = { ...family, ...profile };
    bindData(`${catalog.name}#/furniture/${prop.kind}`, family);
    for (const offset of resolved.occupied ?? []) {
      requireThat(cell(offset), `Invalid ${prop.kind} footprint`);
      const point = key([prop.cell[0] + offset[0], prop.cell[1] + offset[1]]);
      requireThat(floor.has(point), `${prop.kind} footprint leaves floor`);
      requireThat(!occupied.has(point), `${prop.kind} footprint overlaps another prop`);
      occupied.add(point);
    }
  }
  if (manifest.adapter === 'office_json') {
    // Owned starter decor and employee kits are assembled at runtime, not
    // listed as static room.props. Bind the real source entries, not a second
    // independently authored placement map. Live arrangement validation stays
    // in FurnishingStore/OfficeLayout and their existing tests.
    const library = catalogs[1];
    for (const name of ['starter_decor', 'employee_role_kits', 'employee_decor_kits', 'role_kits', 'decor_kits']) {
      if (library.value[name]) bindData(`${library.name}#/${name}`, library.value[name]);
    }
    for (const item of library.value.starter_decor ?? []) {
      const catalog = catalogs.find(c => c.value.furniture?.[item.kind]);
      requireThat(catalog, `Unregistered starter decor: ${item.kind}`);
      bindData(`${catalog.name}#/furniture/${item.kind}`, catalog.value.furniture[item.kind]);
    }
  }
  requireThat(cell(geometry.spawn) && floor.has(key(geometry.spawn)) && !occupied.has(key(geometry.spawn)), 'Spawn is blocked or outside floor');
  requireThat(geometry.exits.length > 0, 'Map needs a safe exit/return');
  const reached = new Set(), queue = [geometry.spawn];
  for (let i = 0; i < queue.length; i++) {
    const point = queue[i], id = key(point);
    if (reached.has(id) || !floor.has(id) || occupied.has(id)) continue;
    reached.add(id);
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) queue.push([point[0] + dx, point[1] + dy]);
  }
  for (const target of [...geometry.exits, ...geometry.targets]) requireThat(cell(target) && reached.has(key(target)), 'Exit or story interaction is unreachable from spawn');
  const files = [...bindings].sort(([a], [b]) => a.localeCompare(b)).map(([path, sha256]) => ({ path, sha256 }));
  const signature = sha256(JSON.stringify({ manifest, style: styleReference(root), files }));
  return { signature, bindings: files, geometry };
}

export function reviewCandidate(root, manifest) {
  const inspected = inspectMap(root, manifest);
  return { schema_version: 1, map_id: manifest.id, status: 'candidate', signature: inspected.signature,
    reviewer: '', reviewed_at: '', style_profile: styleReference(root, 'retrospective_review'),
    bindings: inspected.bindings, evidence: [],
    checks: Object.fromEntries(CHECKS.map(name => [name, { result: 'pending', note: '' }])) };
}

function validateReview(root, review, inspected) {
  requireThat(review.schema_version === 1 && review.status === 'approved', 'Map review is not approved');
  requireThat(typeof review.reviewer === 'string' && review.reviewer.trim() && !Number.isNaN(Date.parse(review.reviewed_at)), 'Map review needs reviewer/date');
  requireThat(review.signature === inspected.signature && equal(review.bindings, inspected.bindings), 'Map review is stale: composition, geometry, art or profile changed');
  requireThat(equal(review.style_profile, styleReference(root, 'retrospective_review')), 'Map review style references are stale');
  for (const name of CHECKS) requireThat(review.checks?.[name]?.result === 'passed' && review.checks[name].note?.trim(), `Map review needs an explicit ${name} assessment`);
  requireThat(Array.isArray(review.evidence) && review.evidence.some(item => item.kind === 'godot_frame') && review.evidence.some(item => item.kind === 'godot_test_report'), 'Map review needs actual-engine frame and test report');
  for (const evidence of review.evidence) {
    requireThat(evidence.capture_method === 'godot_engine' && evidence.note?.trim(), 'Map evidence must name actual Godot capture and coverage');
    const bytes = fs.readFileSync(localFile(root, evidence.path));
    requireThat(sha256(bytes) === evidence.sha256, `Stale map evidence: ${evidence.path}`);
    if (evidence.kind === 'godot_frame') requireThat(bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])), 'Godot frame must be a PNG');
  }
}

export function validateMaps({ root = ROOT, allowUnreviewed = false, manifests, reviews, baseline } = {}) {
  const errors = [], warnings = [], maps = [];
  try {
    errors.push(...validateStyleProfile(root).errors);
    const profile = json(root, `${DIRECTORY}/world-profile.json`);
    requireThat(profile.id === 'startup-valley-world-v1' && profile.style_profile === 'startup-valley-cozy-pixel-v1', 'Invalid shared world/style profile');
    requireThat(profile.camera_profile === 'office-square-grid-v1' && profile.rules?.grid_px === 32 && profile.rules?.runtime_scale === 1 && profile.rules?.sampling === 'nearest' && profile.rules?.lighting === 'upper-left', 'World geometry or lighting differs from canonical style');
    manifests ??= records(root, `${DIRECTORY}/maps`);
    reviews ??= records(root, `${DIRECTORY}/reviews`);
    baseline ??= json(root, `${DIRECTORY}/baseline.json`);
    requireThat(baseline.status === 'pre_framework_snapshot_not_visual_approval', 'Baseline must not claim visual approval');
    const registered = new Set(manifests.map(m => m.source)), ids = new Set();
    const runtimeScripts = fs.readdirSync(path.join(root, 'game'), { recursive: true }).filter(n => n.endsWith('.gd') && !n.startsWith('tests/') && !n.startsWith('tools/')).map(n => text(root, `game/${n}`)).join('\n');
    for (const name of fs.readdirSync(path.join(root, 'game/data')).filter(n => n.endsWith('.json'))) {
      const source = `game/data/${name}`, value = json(root, source);
      if (value.tile_size && (value.floor_rects || value.walkable_rects)) {
        const retired = baseline.retired?.[source];
        if (retired) {
          requireThat(retired.reason?.trim() && sha256(fs.readFileSync(localFile(root, source))) === retired.sha256, `Retired map changed: ${source}`);
          requireThat(!runtimeScripts.includes(`res://${source.slice(5)}`), `Retired map referenced by runtime: ${source}`);
        } else requireThat(registered.has(source), `Unregistered map layout: ${source}`);
      }
    }
    const modules = new Set(manifests.flatMap(m => [m.source, ...m.modules]));
    for (const name of fs.readdirSync(path.join(root, 'game/world')).filter(n => n.endsWith('.gd'))) {
      const source = `game/world/${name}`;
      if (/navigation\.configure\(/.test(text(root, source))) requireThat(modules.has(source), `Unregistered map renderer: ${source}`);
    }
    for (const manifest of manifests) {
      try {
        requireThat(!ids.has(manifest.id), `Duplicate map id: ${manifest.id}`); ids.add(manifest.id);
        const inspected = inspectMap(root, manifest);
        const current = reviews.filter(review => review.map_id === manifest.id && review.status === 'approved');
        requireThat(current.length <= 1, 'Multiple active map approvals');
        let status;
        if (current.length) { validateReview(root, current[0], inspected); status = 'reviewed'; }
        else if (baseline.maps?.[manifest.id] === inspected.signature) {
          status = 'legacy_snapshot'; warnings.push(`${manifest.id}: unchanged pre-framework map; NOT a current visual approval`);
        } else {
          const message = `${manifest.id}: new/changed map needs current actual-engine visual review`;
          if (!allowUnreviewed) throw new Error(message);
          warnings.push(message); status = 'candidate_preview';
        }
        maps.push({ id: manifest.id, status, signature: inspected.signature });
      } catch (error) { errors.push(`${manifest.id}: ${error.message}`); }
    }
    for (const review of reviews) requireThat(ids.has(review.map_id), `Review refers to unregistered map: ${review.map_id}`);
  } catch (error) { errors.push(error.message); }
  return { ok: errors.length === 0, mode: allowUnreviewed ? 'candidate_preview' : 'release', maps, warnings, errors };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    if (args[0] === '--candidate' && args.length === 2) {
      const manifest = records(ROOT, `${DIRECTORY}/maps`).find(item => item.id === args[1]);
      requireThat(manifest, 'Unknown map id');
      console.log(JSON.stringify(reviewCandidate(ROOT, manifest), null, 2));
    } else {
      requireThat(args.length === 0 || equal(args, ['--preview']), 'Usage: validate-maps.mjs [--preview | --candidate map-id]');
      const report = validateMaps({ allowUnreviewed: args.includes('--preview') });
      console.log(JSON.stringify(report, null, 2));
      if (!report.ok) process.exitCode = 1;
    }
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
