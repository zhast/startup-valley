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
