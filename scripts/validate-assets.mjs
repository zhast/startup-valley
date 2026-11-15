// Current-runtime gate; historical art catalogue remains the source library.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { ROOT, sha256, localFile, styleReference, validateStyleProfile } from './lib/art-reference.mjs';
export { ROOT, sha256, STYLE_PATH, localFile, styleReference, validateStyleProfile } from './lib/art-reference.mjs';
import { parsePngHeader, nativePngFacts } from '../dev/tools/validate_art_catalogue.mjs';
import { SCALE_CONTRACT, validateFurnitureScale } from './validate-furniture-scale.mjs';

const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const HASH = /^[a-f0-9]{64}$/;
const CHECKS = ['style', 'camera', 'scale', 'anchor', 'layering', 'animation', 'placement', 'readability'];
const ORIGINS = ['openai_imagegen', 'code_native', 'manual', 'licensed', 'legacy_unknown'];
const json = file => JSON.parse(fs.readFileSync(file, 'utf8'));

export function runtimePngs(root) {
  const directory = path.join(root, 'game/assets/runtime');
  return fs.readdirSync(directory, { recursive: true }).filter(name => name.endsWith('.png'))
    .map(name => `game/assets/runtime/${name.replaceAll(path.sep, '/')}`).sort();
}

// Produces an unsigned candidate only. It never changes the baseline or approves art.
export function reviewCandidate(root, files) {
  return {
    schema_version: 1, id: 'replace-with-asset-revision', status: 'candidate',
    reviewer: '', reviewed_at: '', camera_profile: 'office-square-grid-v1',
    style_profile: styleReference(root),
    provenance: { kind: 'legacy_unknown', note: 'Replace with the actual source history; do not infer generation from appearance.', sources: [], prompt: null, generation_id: null, transform: '' },
    artifacts: files.map(name => ({ path: name, sha256: sha256(fs.readFileSync(localFile(root, name))) })),
    bindings: [], evidence: [],
    checks: Object.fromEntries(CHECKS.map(name => [name, { result: 'pending', note: '' }]))
  };
}

export function validateReview(review, root) {
  const errors = [];
  const check = (ok, message) => { if (!ok) errors.push(message); };
  check(review?.schema_version === 1, 'review schema_version must be 1');
  check(typeof review?.id === 'string' && /^[a-z0-9][a-z0-9-]+$/.test(review.id), 'review needs a stable id');
  check(review?.status === 'approved', 'review is not approved');
  check(typeof review?.reviewer === 'string' && review.reviewer.trim().length > 0, 'reviewer is required');
  check(typeof review?.reviewed_at === 'string' && !Number.isNaN(Date.parse(review.reviewed_at)), 'review date is required');
  check(review?.camera_profile === 'office-square-grid-v1', 'camera profile must be office-square-grid-v1');
  try {
    const expected = styleReference(root);
    const style = review?.style_profile;
    check(style?.id === expected.id && style?.path === expected.path && style?.sha256 === expected.sha256, 'style profile missing or does not match the canonical profile hash');
    check(['generation_reference', 'retrospective_review'].includes(style?.application), 'record whether style references were supplied at generation or assessed retrospectively');
    check(same(style?.reference_board, expected.reference_board), 'style reference board hash mismatch');
    check(same(style?.references, expected.references), 'style reference image hashes missing or mismatched');
    errors.push(...validateStyleProfile(root).errors);
  } catch (error) { errors.push(`style profile: ${error.message}`); }
  const origin = review?.provenance ?? {};
  check(ORIGINS.includes(origin.kind), 'declare the actual origin');
  check(typeof origin.note === 'string' && origin.note.trim().length > 0, 'provenance note is required');
  check(typeof origin.transform === 'string' && origin.transform.trim().length > 0, 'record the source-to-runtime transformation');
  check(Array.isArray(origin.sources) && (origin.kind === 'legacy_unknown' || origin.sources.length > 0), 'known origin needs retained source hashes');
  if (origin.kind === 'openai_imagegen') {
    check(origin.prompt && HASH.test(origin.prompt.sha256 ?? ''), 'ImageGen origin needs a retained prompt hash');
    check(typeof origin.generation_id === 'string' && origin.generation_id.trim().length > 0, 'ImageGen origin needs the actual generation/output identifier');
    if (review?.style_profile?.application === 'generation_reference' && origin.prompt?.path) {
      try { check(fs.readFileSync(localFile(root, origin.prompt.path), 'utf8').includes(review.style_profile.id), 'generation prompt must name the supplied canonical style profile'); }
      catch (error) { errors.push(error.message); }
    }
  }
  if (origin.kind === 'legacy_unknown') check(origin.generation_id == null, 'unknown legacy origin cannot claim a generation id');
  check(Array.isArray(review?.artifacts) && review.artifacts.length > 0, 'review needs runtime artifacts');
  check(Array.isArray(review?.bindings) && review.bindings.length > 0, 'review needs the relevant placement/animation binding hashes');
  check(Array.isArray(review?.evidence) && review.evidence.some(item => item.kind === 'in_game') && review.evidence.some(item => item.kind === 'test_report'), 'review needs in-game evidence and a test report');
  for (const name of CHECKS) {
    const item = review?.checks?.[name];
    check(item && ['passed', 'not_applicable'].includes(item.result) && typeof item.note === 'string' && item.note.trim().length > 0, `${name} needs an explicit reviewed result and note`);
  }
  const records = [...(review?.artifacts ?? []), ...(review?.bindings ?? []), ...(review?.evidence ?? []), ...(origin.sources ?? []), ...(origin.prompt ? [origin.prompt] : [])];
  for (const record of records) {
    try {
      check(HASH.test(record.sha256 ?? ''), `invalid hash for ${record.path}`);
      check(sha256(fs.readFileSync(localFile(root, record.path))) === record.sha256, `stale or missing review evidence: ${record.path}`);
    } catch (error) { errors.push(error.message); }
  }
  for (const artifact of review?.artifacts ?? []) check(artifact.path?.startsWith('game/assets/runtime/') && artifact.path.endsWith('.png'), 'review artifacts must be runtime PNGs');
  return { ok: errors.length === 0, errors };
}

export function validateAssets({ root = ROOT, baseline, reviews, contracts, allowUnreviewed = false } = {}) {
  baseline ??= json(path.join(root, 'dev/art-catalogue/runtime-baseline.json'));
  contracts ??= json(path.join(root, 'dev/art-catalogue/runtime-contracts.json'));
  if (!reviews) {
    const directory = path.join(root, 'dev/art-catalogue/runtime-reviews');
    reviews = fs.existsSync(directory) ? fs.readdirSync(directory).filter(name => name.endsWith('.json')).map(name => json(path.join(directory, name))) : [];
  }
  const errors = [], warnings = [], approved = new Map(), hashes = new Map();
  errors.push(...validateStyleProfile(root).errors);
  const verify = (ok, message) => { if (!ok) errors.push(message); };
  verify(baseline.schema_version === 1 && baseline.status === 'legacy_snapshot_not_visual_approval', 'baseline must explicitly remain an unreviewed legacy snapshot');
  verify(contracts.schema_version === 1, 'runtime contracts schema_version must be 1');
  if (contracts.scale_calibration !== undefined) {
    verify(contracts.scale_calibration === SCALE_CONTRACT, 'scale calibration must use the shared furniture contract');
    errors.push(...validateFurnitureScale({ root }).errors.map(error => `Furniture scale: ${error}`));
  }
  verify(contracts.camera_profile?.id === 'office-square-grid-v1' && same(contracts.camera_profile.tile_px, [32, 32]), 'runtime camera profile must retain the 32×32 square grid');
  for (const review of reviews) {
    const result = validateReview(review, root);
    if (result.ok) for (const artifact of review.artifacts) approved.set(`${artifact.path}:${artifact.sha256}`, review.id);
    else if (review.status === 'approved') (allowUnreviewed ? warnings : errors).push(...result.errors.map(error => `${review.id}: ${error}`));
    else warnings.push(`${review.id}: ${review.status}; does not authorize changed runtime art`);
  }
  const files = runtimePngs(root);
  for (const name of files) {
    try {
      const bytes = fs.readFileSync(localFile(root, name)), hash = sha256(bytes);
      hashes.set(name, hash);
      const [width, height] = parsePngHeader(bytes);
      verify(width > 0 && height > 0, `${name}: empty PNG`);
      const isLegacy = baseline.files?.[name] === hash;
      if (!isLegacy && !approved.has(`${name}:${hash}`)) (allowUnreviewed ? warnings : errors).push(`${name}: new or changed art needs a current approved review manifest`);
      if (bytes[24] === 8 && [2, 6].includes(bytes[25]) && bytes[28] === 0) {
        const facts = nativePngFacts(bytes);
        if (name.startsWith('game/assets/runtime/characters/')) {
          verify(width % 48 === 0 && height % 80 === 0, `${name}: character sheet must preserve 48×80 cells`);
          verify(facts.partial_alpha_pixels === 0, `${name}: character sheet needs binary alpha`);
        }
      } else verify(isLegacy, `${name}: new art must use decodable non-interlaced 8-bit RGB/RGBA PNGs`);
      const importer = fs.readFileSync(localFile(root, `${name}.import`), 'utf8');
      verify(/^compress\/mode=0$/m.test(importer) && /^mipmaps\/generate=false$/m.test(importer) && /^process\/size_limit=0$/m.test(importer), `${name}: preserve lossless import, no mipmaps, no size limit`);
    } catch (error) { errors.push(`${name}: ${error.message}`); }
  }
  for (const name of Object.keys(baseline.files ?? {})) verify(hashes.has(name), `${name}: baseline file removed; review and remove its stale registry entry explicitly`);
  for (const contract of contracts.families ?? []) {
    try {
      const catalog = json(localFile(root, contract.catalog));
      const family = catalog.furniture?.[contract.id] ?? catalog[contract.id] ?? catalog.catalog?.[contract.id];
      verify(!!family, `${contract.id}: runtime family missing`);
      if (!family) continue;
      const manifest = json(localFile(root, contract.manifest));
      for (const source of contract.provenance?.sources ?? []) verify(sha256(fs.readFileSync(localFile(root, source.path))) === source.sha256, `${contract.id}: source recipe changed: ${source.path}`);
      verify(same(manifest.canvas, contract.canvas) && same(manifest.pivot, contract.pivot) && manifest.native_scale === 1, `${contract.id}: canvas/pivot/native scale drift`);
      verify(manifest.revision === contract.revision, `${contract.id}: asset revision drift`);
      verify(family.interaction_enabled === contract.interaction_enabled, `${contract.id}: interaction capability drift`);
      verify(same(family.facings, Object.keys(contract.profiles)), `${contract.id}: missing or extra facing`);
      for (const [side, expected] of Object.entries(contract.profiles)) {
        const profile = family.facing_profiles?.[side];
        verify(!!profile, `${contract.id}/${side}: profile missing`);
        if (!profile) continue;
        for (const field of ['occupied', 'clearance', 'interaction', 'visual_bounds', 'hit_bounds', 'service_side', 'approach_gaze']) verify(same(profile[field], expected[field]), `${contract.id}/${side}: ${field} drift`);
        verify(same(profile.render_layers.map(item => item.name), expected.layers), `${contract.id}/${side}: missing/reordered semantic layers`);
        verify(same(profile.render_layers.map(item => item.art), expected.art), `${contract.id}/${side}: wrong-facing layer binding`);
        verify(same(profile.render_layers.map(item => item.z_offset), expected.z_offsets), `${contract.id}/${side}: layer depth drift`);
        for (const layer of profile.render_layers) {
          const name = `game/${layer.art.replace(/^res:\/\//, '')}`;
          const bytes = fs.readFileSync(localFile(root, name));
          verify(same(parsePngHeader(bytes), contract.canvas), `${name}: layer canvas drift`);
          verify(same(layer.region, [0, 0, ...contract.canvas]) && same(layer.offset, [contract.canvas[0] / 2 - contract.pivot[0], contract.canvas[1] / 2 - contract.pivot[1]]), `${name}: atlas or anchor offset drift`);
          verify(!['rotation', 'scale', 'flip_h', 'flip_v'].some(key => key in layer), `${name}: do not rotate, scale, or mirror registered art`);
          const facts = nativePngFacts(bytes);
          verify(facts.partial_alpha_pixels === 0, `${name}: solid layer has partial alpha`);
          verify(same(facts.opaque_bounds_px, layer.content_bounds), `${name}: content bounds do not match pixels`);
          verify(manifest.files[path.basename(name)] === sha256(bytes), `${name}: runtime manifest hash drift`);
        }
      }
      const expectedFiles = Object.values(contract.profiles).reduce((count, profile) => count + profile.layers.length + 1, 0);
      verify(Object.keys(manifest.files ?? {}).length === expectedFiles, `${contract.id}: incomplete layer/whole manifest`);
      for (const [name, hash] of Object.entries(manifest.files ?? {})) verify(sha256(fs.readFileSync(localFile(root, path.posix.join(path.posix.dirname(contract.manifest), name)))) === hash, `${contract.id}: stale manifest file ${name}`);
      if (contract.visual_status !== 'approved') warnings.push(`${contract.id}: ${contract.visual_status} — ${contract.visual_note}`);
    } catch (error) { errors.push(`${contract.id}: ${error.message}`); }
  }
  for (const contract of contracts.seating ?? []) {
    try {
      const family = json(localFile(root, contract.catalog)).furniture?.[contract.id];
      verify(!!family, `${contract.id}: seating family missing`);
      if (!family) continue;
      for (const [side, expected] of Object.entries(contract.profiles)) {
        const profile = family.facing_profiles?.[side];
        verify(!!profile, `${contract.id}/${side}: seating profile missing`);
        if (!profile) continue;
        for (const [field, value] of Object.entries(expected)) verify(same(profile[field], value), `${contract.id}/${side}: seating ${field} drift`);
        const names = profile.render_layers.map(layer => layer.name);
        verify(names.includes('DeskRear') && names.includes('DeskFront') && names.some(name => name.startsWith('Chair')), `${contract.id}/${side}: desk and chair must remain separate layers`);
      }
    } catch (error) { errors.push(`${contract.id}: ${error.message}`); }
  }
  return { ok: errors.length === 0, mode: allowUnreviewed ? 'candidate_preview' : 'release', runtimePngs: files.length, reviewedArtifacts: approved.size, legacySnapshotIsNotVisualApproval: true, errors, warnings };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    if (args[0] === '--candidate') {
      if (args.length < 2) throw new Error('Usage: node scripts/validate-assets.mjs --candidate game/assets/runtime/path.png ... > candidate.json');
      console.log(JSON.stringify(reviewCandidate(ROOT, args.slice(1)), null, 2));
    } else {
      if (args.some(arg => arg !== '--godot')) throw new Error('Supported options: --candidate paths... | --godot');
      const result = validateAssets();
      // Keep the reusable image validator independent for asset-only fixtures;
      // the normal CLI admits the complete visual world before export/testing.
      const maps = (await import('./validate-maps.mjs')).validateMaps();
      result.mapReview = maps.maps;
      result.errors.push(...maps.errors.map(error => `Map gate: ${error}`));
      result.warnings.push(...maps.warnings);
      result.ok = result.ok && maps.ok;
      console.log(JSON.stringify(result, null, 2));
      if (!result.ok) process.exitCode = 1;
      else if (args.includes('--godot')) {
        const contracts = json(path.join(ROOT, 'dev/art-catalogue/runtime-contracts.json'));
        const logs = path.join(ROOT, '.build/asset-checks');
        fs.mkdirSync(logs, { recursive: true });
        for (const test of contracts.godot_tests) {
          const run = spawnSync(process.env.GODOT_BIN || 'godot', ['--headless', '--log-file', path.join(logs, path.basename(test, '.gd') + '.log'), '--path', 'game', '--script', test], { cwd: ROOT, stdio: 'inherit', timeout: 120_000, env: { ...process.env, STARTUP_VALLEY_NO_WORKER: '1', STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS: '1' } });
          if (run.error || run.status !== 0) throw new Error(`Asset placement test failed: ${test}: ${run.error?.message ?? run.status}`);
        }
      }
    }
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
