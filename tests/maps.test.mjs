import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { spawnSync } from 'node:child_process';
import { ROOT, sha256 } from '../scripts/validate-assets.mjs';
import { inspectMap, reviewCandidate, validateMaps } from '../scripts/validate-maps.mjs';

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'startup-valley-maps-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const write = (name, value) => { fs.mkdirSync(path.dirname(path.join(root, name)), { recursive: true }); fs.writeFileSync(path.join(root, name), typeof value === 'object' && !Buffer.isBuffer(value) ? JSON.stringify(value) : value); };
  const profile = JSON.parse(fs.readFileSync(path.join(ROOT, 'dev/art-catalogue/style-profile.json')));
  for (const name of ['dev/art-catalogue/style-profile.json', 'dev/map-catalogue/world-profile.json', ...profile.references.map(r => r.path), profile.board.path, profile.prompt_template.path]) write(name, fs.readFileSync(path.join(ROOT, name)));
  write('game/world/fixture.gd', 'navigation.configure({})');
  const layout = { id: 'fixture-map', tile_size: 32, width: 8, height: 8, floor_rects: [[0, 0, 8, 8]], player_spawn: [1, 1], doors: [{ grid: [0, 1], entrance: true }], props: [{ kind: 'chair', facing: 'south', grid: [3, 3] }] };
  write('game/data/fixture.json', layout);
  const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/1ioAAAAASUVORK5CYII=', 'base64');
  write('game/assets/runtime/chair.png', png);
  write('game/data/furniture_catalog.json', { furniture: { chair: { facings: ['south'], facing_profiles: { south: { status: 'runtime_ready', occupied: [[0, 0]], art: 'res://assets/runtime/chair.png' } } } } });
  write('game/data/furnishing_catalog.json', { furniture: {} });
  const manifest = { schema_version: 1, id: layout.id, adapter: 'office_json', source: 'game/data/fixture.json', world_profile: 'startup-valley-world-v1', camera_profile: 'office-square-grid-v1', runtime_scale: 1, sampling: 'nearest', modules: ['game/world/fixture.gd'] };
  const baseline = { status: 'pre_framework_snapshot_not_visual_approval', maps: { [manifest.id]: inspectMap(root, manifest).signature } };
  const options = { root, manifests: [manifest], baseline, reviews: [] };
  return { root, write, layout, manifest, options, png };
}

function approve(f) {
  const review = reviewCandidate(f.root, f.manifest);
  Object.assign(review, { status: 'approved', reviewer: 'Synthetic validation fixture only', reviewed_at: '2026-11-15T00:00:00Z' });
  f.write('evidence/frame.png', f.png); f.write('evidence/report.json', { checks: 3, failures: [] });
  review.evidence = [['frame.png', 'godot_frame'], ['report.json', 'godot_test_report']].map(([name, kind]) => ({ path: `evidence/${name}`, sha256: sha256(fs.readFileSync(path.join(f.root, 'evidence', name))), kind, capture_method: 'godot_engine', note: 'Synthetic fixture tests validation structure; not a real visual approval.' }));
  for (const check of Object.values(review.checks)) Object.assign(check, { result: 'passed', note: 'Synthetic fixture only.' });
  f.options.reviews = [review];
  return review;
}

test('existing map snapshot is explicitly not a visual approval', t => {
  const f = fixture(t), result = validateMaps(f.options);
  assert.equal(result.ok, true); assert.equal(result.maps[0].status, 'legacy_snapshot');
  assert.match(result.warnings[0], /NOT a current visual approval/);
});

test('new and changed maps require current review, candidate output never approves', t => {
  const f = fixture(t);
  f.options.baseline.maps = {};
  f.options.reviews = [reviewCandidate(f.root, f.manifest)];
  assert.match(validateMaps(f.options).errors.join('\n'), /new\/changed map needs/);
  assert.equal(validateMaps({ ...f.options, allowUnreviewed: true }).ok, true);
  approve(f); assert.equal(validateMaps(f.options).ok, true);
  f.layout.player_spawn = [2, 1]; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /Map review is stale/);
});

test('unregistered map data and custom renderers fail closed', t => {
  const f = fixture(t);
  f.write('game/data/forgotten.json', f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /Unregistered map layout/);
  fs.unlinkSync(path.join(f.root, 'game/data/forgotten.json'));
  f.write('game/world/forgotten.gd', 'navigation.configure({})');
  assert.match(validateMaps(f.options).errors.join('\n'), /Unregistered map renderer/);
});

test('unknown props, unsupported facings and escaping resources are rejected', t => {
  const f = fixture(t);
  f.layout.props[0].kind = 'unregistered'; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /Unregistered prop/);
  f.layout.props[0] = { kind: 'chair', facing: 'east', grid: [3, 3] }; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /Unsupported facing/);
  f.layout.props[0].facing = 'south'; f.write(f.manifest.source, f.layout);
  f.manifest.art = ['../outside.png'];
  assert.equal(validateMaps(f.options).ok, false);
});

test('blocked spawn, overlapping props and unreachable exit fail even in preview', t => {
  const f = fixture(t); f.options.allowUnreviewed = true;
  f.layout.player_spawn = [3, 3]; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /Spawn is blocked/);
  f.layout.player_spawn = [1, 1]; f.layout.props.push({ ...f.layout.props[0] }); f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /overlaps another prop/);
  f.layout.props.pop(); f.layout.wall_rects = [[1, 0, 1, 8]]; f.layout.player_spawn = [2, 1]; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /unreachable/);
});

test('door cutouts reopen walls in the same order as OfficeLayout', t => {
  const f = fixture(t);
  f.layout.floor_rects = [[1, 0, 7, 8]];
  f.layout.wall_rects = [[0, 0, 1, 8]];
  f.write(f.manifest.source, f.layout);
  assert.equal(validateMaps({ ...f.options, allowUnreviewed: true }).ok, true);
});

test('art changes and changed evidence invalidate review', t => {
  const f = fixture(t); approve(f);
  f.write('game/assets/runtime/chair.png', Buffer.concat([f.png, Buffer.from('change')]));
  assert.match(validateMaps(f.options).errors.join('\n'), /Map review is stale/);
  f.write('game/assets/runtime/chair.png', f.png); f.write('evidence/report.json', '{}');
  assert.match(validateMaps(f.options).errors.join('\n'), /Stale map evidence/);
});

test('map approval needs actual-engine evidence and every visual assessment', t => {
  const f = fixture(t), review = approve(f);
  review.evidence[0].capture_method = 'mockup';
  assert.match(validateMaps(f.options).errors.join('\n'), /actual Godot capture/);
  review.evidence[0].capture_method = 'godot_engine'; review.checks.composition.result = 'pending';
  assert.match(validateMaps(f.options).errors.join('\n'), /composition assessment/);
});

test('in-app Godot frames can pair with headless routes but require their build identity', t => {
  const f = fixture(t), review = approve(f);
  review.evidence[0].capture_method = 'in_app_browser_godot';
  review.evidence[1].capture_method = 'godot_headless';
  assert.match(validateMaps(f.options).errors.join('\n'), /captured build identifier/);
  review.evidence[0].build_id = 'b5d7da90f647ea26';
  assert.equal(validateMaps(f.options).ok, true);
  // A headless route report never substitutes for a rendered game frame.
  review.evidence[0].capture_method = 'godot_headless';
  assert.match(validateMaps(f.options).errors.join('\n'), /actual Godot capture/);
  review.evidence[0].capture_method = 'in_app_browser_godot';
  // CUA can return JPEG. Signature-only bytes here test admission, not imaging.
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
  f.write('evidence/frame.jpg', jpeg);
  Object.assign(review.evidence[0], { path: 'evidence/frame.jpg', sha256: sha256(jpeg) });
  assert.equal(validateMaps(f.options).ok, true);
  review.evidence[0].capture_method = 'godot_engine';
  assert.match(validateMaps(f.options).errors.join('\n'), /in-app browser JPEG/);
});

test('courtyard JSON is tied to its real renderer, spawn and interaction approach', t => {
  const f = fixture(t);
  f.manifest.adapter = 'courtyard_json';
  f.manifest.modules = ['game/world/fixture.gd', 'game/world/courtyard.gd'];
  f.layout.walkable_rects = f.layout.floor_rects;
  f.layout.story_approach = [4, 4];
  f.write(f.manifest.source, f.layout);
  const source = 'const LAYOUT_PATH := "res://data/fixture.json"\nconst SPAWN := Vector2(48, 48)\nconst THEO_APPROACH := Vector2(144, 144)\ncatalogue.resolve_profile(kind, "south")\n';
  f.write('game/world/courtyard.gd', source);
  assert.equal(validateMaps({ ...f.options, allowUnreviewed: true }).ok, true);
  f.write('game/world/courtyard.gd', source.replace('144, 144', '176, 144'));
  assert.match(validateMaps({ ...f.options, allowUnreviewed: true }).errors.join('\n'), /THEO_APPROACH differs/);
  f.write('game/world/courtyard.gd', source.replace('fixture.json', 'another.json'));
  assert.match(validateMaps({ ...f.options, allowUnreviewed: true }).errors.join('\n'), /load its registered source/);
  f.write('game/world/courtyard.gd', source);
  f.layout.props[0].facing = 'north'; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps({ ...f.options, allowUnreviewed: true }).errors.join('\n'), /south-facing renderer/);
});

test('terrain recipes bind native grid modules and reject invalid crops even in preview', t => {
  const f = fixture(t);
  f.manifest.terrain = 'game/data/terrain.json';
  // Header metadata is sufficient for this parser fixture; no render uses it.
  const atlas = Buffer.from(f.png); atlas.writeUInt32BE(192, 16); atlas.writeUInt32BE(192, 20);
  f.write('game/assets/runtime/terrain.png', atlas);
  const recipe = { tile_size: 32, runtime_scale: 1, sampling: 'nearest', source: 'res://assets/runtime/terrain.png', grass_patch_columns: 1, grass_patch_rows: 1,
    materials: { grass: { region_size: [32, 32], texture_origin: [0, 0], samples: [[0, 0, 32, 32]] },
      paving: { region_size: [32, 32], texture_origin: [0, 0], samples: [[32, 0, 32, 32]] },
      hedge: { region_size: [64, 64], texture_origin: [0, -16], samples: [[0, 128, 64, 64]] } } };
  f.write(f.manifest.terrain, recipe);
  const options = { ...f.options, allowUnreviewed: true };
  assert.equal(validateMaps(options).ok, true);
  const before = inspectMap(f.root, f.manifest).signature;
  f.layout.terrain_plantings = [[0, 0, 1]]; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(options).errors.join('\n'), /planting overlaps legal walkable floor/);
  f.layout.terrain_plantings = [[0, 0, 0]]; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(options).errors.join('\n'), /Invalid terrain planting row/);
  delete f.layout.terrain_plantings; f.write(f.manifest.source, f.layout);
  recipe.materials.hedge.texture_origin = [0, -15]; f.write(f.manifest.terrain, recipe);
  assert.notEqual(inspectMap(f.root, f.manifest).signature, before);
  recipe.materials.hedge.samples[0][0] = 160; f.write(f.manifest.terrain, recipe);
  assert.match(validateMaps(options).errors.join('\n'), /in-bounds native grid module/);
  recipe.materials.hedge.samples[0][0] = 0; recipe.grass_patch_columns = 2; f.write(f.manifest.terrain, recipe);
  assert.match(validateMaps(options).errors.join('\n'), /sample count/);
  recipe.grass_patch_columns = 1; recipe.runtime_scale = 2; f.write(f.manifest.terrain, recipe);
  assert.match(validateMaps(options).errors.join('\n'), /grid\/native scale/);
});

test('world profile, scale and grid stay aligned with canonical assets', t => {
  const f = fixture(t); f.manifest.runtime_scale = 2;
  assert.match(validateMaps(f.options).errors.join('\n'), /camera\/scale\/sampling/);
  f.manifest.runtime_scale = 1; f.layout.tile_size = 16; f.write(f.manifest.source, f.layout);
  assert.match(validateMaps(f.options).errors.join('\n'), /canonical 32px grid/);
});

test('retired reference cannot silently return to runtime', t => {
  const f = fixture(t); f.write('game/data/retired.json', f.layout);
  f.options.baseline.retired = { 'game/data/retired.json': { sha256: sha256(fs.readFileSync(path.join(f.root, 'game/data/retired.json'))), reason: 'Fixture retired reference.' } };
  assert.equal(validateMaps(f.options).ok, true);
  f.write('game/world/fixture.gd', 'load("res://data/retired.json")');
  assert.match(validateMaps(f.options).errors.join('\n'), /Retired map referenced by runtime/);
});

test('production map adapters inspect actual authored geometry', () => {
  for (const name of fs.readdirSync(path.join(ROOT, 'dev/map-catalogue/maps'))) {
    const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'dev/map-catalogue/maps', name)));
    const inspected = inspectMap(ROOT, manifest);
    assert.equal(inspected.signature.length, 64);
    assert.ok(inspected.bindings.length > 10);
  }
});

test('normal asset CLI completes module initialization and includes the map gate', () => {
  const result = spawnSync(process.execPath, ['scripts/validate-assets.mjs'], { cwd: ROOT, encoding: 'utf8', timeout: 30_000 });
  assert.ifError(result.error);
  // Validation may legitimately report pending art during development; exit13
  // or empty output would reveal the former circular top-level import hang.
  assert.ok([0, 1].includes(result.status), result.stderr);
  assert.ok(Array.isArray(JSON.parse(result.stdout).mapReview));
});
