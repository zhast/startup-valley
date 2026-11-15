import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { ROOT, localFile, sha256, reviewCandidate, validateAssets, validateReview } from '../scripts/validate-assets.mjs';

const art = 'game/assets/runtime/office/fixture.png';
const oldBytes = fs.readFileSync(path.join(ROOT, 'game/assets/runtime/office/coffee-station-v1/south-espresso.png'));
const newBytes = fs.readFileSync(path.join(ROOT, 'game/assets/runtime/office/coffee-station-v1/south-grinder.png'));
const importer = 'compress/mode=0\nmipmaps/generate=false\nprocess/size_limit=0\n';

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'startup-valley-art-gate-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const write = (name, bytes) => { fs.mkdirSync(path.dirname(path.join(root, name)), { recursive: true }); fs.writeFileSync(path.join(root, name), bytes); };
  const style = JSON.parse(fs.readFileSync(path.join(ROOT, 'dev/art-catalogue/style-profile.json')));
  write('dev/art-catalogue/style-profile.json', fs.readFileSync(path.join(ROOT, 'dev/art-catalogue/style-profile.json')));
  for (const reference of [...style.references, style.board, style.prompt_template]) write(reference.path, fs.readFileSync(path.join(ROOT, reference.path)));
  write(art, oldBytes); write(`${art}.import`, importer);
  const baseline = { schema_version: 1, status: 'legacy_snapshot_not_visual_approval', files: { [art]: sha256(oldBytes) } };
  const options = { root, baseline, contracts: { schema_version: 1, camera_profile: { id: 'office-square-grid-v1', tile_px: [32, 32] }, families: [] }, reviews: [] };
  return { root, write, options };
}

function accepted(f) {
  f.write(art, newBytes);
  f.write('source.png', newBytes);
  f.write('binding.json', '{"anchor":[96,192]}');
  f.write('in-game.png', oldBytes);
  f.write('test-result.json', '{"failures":[]}');
  const record = name => ({ path: name, sha256: sha256(fs.readFileSync(path.join(f.root, name))) });
  const review = reviewCandidate(f.root, [art]);
  Object.assign(review, { id: 'fixture-v2', status: 'approved', reviewer: 'Fixture reviewer', reviewed_at: '2026-11-15T00:00:00Z' });
  review.style_profile.application = 'retrospective_review';
  review.provenance = { kind: 'code_native', note: 'Test-only source fixture, not a production approval.', sources: [record('source.png')], transform: 'Copied without scale or rotation.' };
  review.bindings = [record('binding.json')];
  review.evidence = [{ ...record('in-game.png'), kind: 'in_game' }, { ...record('test-result.json'), kind: 'test_report' }];
  for (const item of Object.values(review.checks)) Object.assign(item, { result: 'passed', note: 'Synthetic test of review validation only.' });
  return review;
}

test('unchanged legacy inventory passes without claiming visual approval', t => {
  const f = fixture(t), result = validateAssets(f.options);
  assert.equal(result.ok, true);
  assert.equal(result.legacySnapshotIsNotVisualApproval, true);
  assert.equal(result.reviewedArtifacts, 0);
});

test('a declared scale contract cannot be missing or redirected', t => {
  const f = fixture(t);
  f.options.contracts.scale_calibration = 'dev/art-catalogue/furniture-scale-contracts.json';
  const missing = validateAssets(f.options);
  assert.equal(missing.ok, false);
  assert.match(missing.errors.join('\n'), /Furniture scale:/);
  f.options.contracts.scale_calibration = 'unreviewed-scale.json';
  assert.match(validateAssets(f.options).errors.join('\n'), /shared furniture contract/);
  delete f.options.contracts.scale_calibration;
  f.write('game/assets/runtime/office/cozy-furniture-v1/cafe-chair-south.png', oldBytes);
  f.write('game/assets/runtime/office/cozy-furniture-v1/cafe-chair-south.png.import', importer);
  assert.match(validateAssets(f.options).errors.join('\n'), /shared furniture contract/,
    'Removing metadata cannot disable scale validation when the runtime family is present');
});

test('changed and unregistered PNGs are blocked even when they decode', t => {
  const f = fixture(t);
  f.write(art, newBytes);
  assert.match(validateAssets(f.options).errors.join('\n'), /changed art needs/);
  f.write('game/assets/runtime/office/new.png', newBytes);
  f.write('game/assets/runtime/office/new.png.import', importer);
  assert.match(validateAssets(f.options).errors.join('\n'), /new.png: new or changed/);
});

test('lossy imports and deleted inventory cannot silently pass', t => {
  const f = fixture(t);
  f.write(`${art}.import`, importer.replace('mode=0', 'mode=2'));
  assert.match(validateAssets(f.options).errors.join('\n'), /lossless import/);
  fs.unlinkSync(path.join(f.root, art));
  assert.match(validateAssets(f.options).errors.join('\n'), /baseline file removed/);
});

test('candidate generation records bytes but does not authorize them', t => {
  const f = fixture(t); f.write(art, newBytes);
  const candidate = reviewCandidate(f.root, [art]);
  assert.equal(candidate.status, 'candidate');
  f.options.reviews = [candidate];
  assert.equal(validateAssets(f.options).ok, false);
});

test('candidate preview permits pending review but retains mechanical checks', t => {
  const f = fixture(t); f.write(art, newBytes);
  f.options.allowUnreviewed = true;
  const result = validateAssets(f.options);
  assert.equal(result.ok, true);
  assert.equal(result.mode, 'candidate_preview');
  assert.match(result.warnings.join('\n'), /new or changed art/);
  f.write(`${art}.import`, importer.replace('generate=false', 'generate=true'));
  assert.equal(validateAssets(f.options).ok, false);
});

test('complete current evidence can authorize changed art', t => {
  const f = fixture(t), review = accepted(f);
  f.options.reviews = [review];
  assert.deepEqual(validateReview(review, f.root), { ok: true, errors: [] });
  assert.equal(validateAssets(f.options).ok, true);
});

test('placement changes and stale screenshots invalidate an approved review', t => {
  const f = fixture(t), review = accepted(f);
  f.options.reviews = [review];
  f.write('binding.json', '{"anchor":[0,0]}');
  f.write('in-game.png', newBytes);
  const errors = validateAssets(f.options).errors.join('\n');
  assert.match(errors, /stale or missing review evidence: binding.json/);
  assert.match(errors, /stale or missing review evidence: in-game.png/);
});

test('ImageGen claims need retained prompts and an actual output id', t => {
  const f = fixture(t), review = accepted(f);
  review.provenance.kind = 'openai_imagegen';
  const errors = validateReview(review, f.root).errors.join('\n');
  assert.match(errors, /prompt hash/); assert.match(errors, /generation\/output identifier/);
});

test('wrong camera, pending animation and empty notes cannot be approved', t => {
  const f = fixture(t), review = accepted(f);
  review.camera_profile = 'isometric';
  review.checks.animation.result = 'pending';
  review.checks.placement.note = '';
  const errors = validateReview(review, f.root).errors.join('\n');
  assert.match(errors, /camera profile/); assert.match(errors, /animation/); assert.match(errors, /placement/);
});

test('evidence cannot escape the repo through a path or symlink', t => {
  const f = fixture(t);
  assert.throws(() => localFile(f.root, '../outside.png'));
  fs.symlinkSync(path.join(ROOT, 'package.json'), path.join(f.root, 'external'));
  assert.throws(() => localFile(f.root, 'external'), /Not a regular repository file/);
});

test('coffee pilot rejects anchor and missing-facing drift', () => {
  const contracts = JSON.parse(fs.readFileSync(path.join(ROOT, 'dev/art-catalogue/runtime-contracts.json')));
  contracts.families[0].pivot = [0, 0];
  delete contracts.families[0].profiles.west;
  const errors = validateAssets({ contracts, reviews: [] }).errors.join('\n');
  assert.match(errors, /canvas\/pivot\/native scale drift/);
  assert.match(errors, /missing or extra facing/);
  assert.match(errors, /atlas or anchor offset drift/);
});

test('coffee pilot rejects layer-order and footprint drift', () => {
  const contracts = JSON.parse(fs.readFileSync(path.join(ROOT, 'dev/art-catalogue/runtime-contracts.json')));
  contracts.families[0].profiles.south.layers.reverse();
  contracts.families[0].profiles.south.occupied = [[0, 0]];
  const errors = validateAssets({ contracts, reviews: [] }).errors.join('\n');
  assert.match(errors, /reordered semantic layers/);
  assert.match(errors, /occupied drift/);
});

test('seating contract rejects chair/desk merging and seat-anchor drift', () => {
  const contracts = JSON.parse(fs.readFileSync(path.join(ROOT, 'dev/art-catalogue/runtime-contracts.json')));
  contracts.seating[0].profiles.south.seat_anchor = [0, 0];
  contracts.seating[0].profiles.south.render_layers = contracts.seating[0].profiles.south.render_layers.filter(layer => !layer.name.startsWith('Chair'));
  const errors = validateAssets({ contracts, reviews: [] }).errors.join('\n');
  assert.match(errors, /seating seat_anchor drift/);
  assert.match(errors, /seating render_layers drift/);
});

test('an otherwise approved asset cannot omit or change its style profile', t => {
  const f = fixture(t), review = accepted(f);
  const style = review.style_profile;
  delete review.style_profile;
  assert.match(validateReview(review, f.root).errors.join('\n'), /style profile missing/);
  review.style_profile = { ...style, id: 'unrelated-isometric-style' };
  assert.match(validateReview(review, f.root).errors.join('\n'), /style profile missing/);
  review.style_profile = { ...style, sha256: '0'.repeat(64) };
  assert.match(validateReview(review, f.root).errors.join('\n'), /canonical profile hash/);
});

test('style reference drift and unrecorded reference use block approval', t => {
  const f = fixture(t), review = accepted(f);
  review.style_profile.references[0].sha256 = '0'.repeat(64);
  assert.match(validateReview(review, f.root).errors.join('\n'), /image hashes/);
  const fresh = accepted(f);
  fresh.style_profile.application = 'not_recorded';
  assert.match(validateReview(fresh, f.root).errors.join('\n'), /record whether style/);
  f.write(fresh.style_profile.reference_board.path, newBytes);
  assert.match(validateReview(fresh, f.root).errors.join('\n'), /canonical style reference hash mismatch/);
});

test('a claimed generation reference must appear in the retained prompt', t => {
  const f = fixture(t), review = accepted(f);
  review.provenance.kind = 'openai_imagegen';
  review.provenance.generation_id = 'test-output-id';
  review.style_profile.application = 'generation_reference';
  f.write('prompt.md', 'An unrelated style request');
  review.provenance.prompt = { path: 'prompt.md', sha256: sha256(fs.readFileSync(path.join(f.root, 'prompt.md'))) };
  assert.match(validateReview(review, f.root).errors.join('\n'), /generation prompt must name/);
});
