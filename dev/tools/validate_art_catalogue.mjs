#!/usr/bin/env node
// Dev-only catalogue validation. No Godot, network, providers or runtime writes.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const DEFAULT_CATALOGUE = path.join(ROOT, 'dev/art-catalogue/furniture.json');
const GALLERY = path.join(ROOT, 'dev/art-catalogue/GALLERY.md');
const DIRECTIONS = ['north', 'east', 'south', 'west'];
const VECTORS = [[0, -1], [1, 0], [0, 1], [-1, 0]];
const DIRECTION_SEMANTICS = new Set(['workstation_gaze', 'seated_occupant_gaze',
  'multi_seat_reference_gaze', 'service_side', 'visual_orientation', 'host_gaze']);
const RUBRIC = ['pixel_coherence', 'perspective', 'silhouette_readability',
  'layering_anchors', 'direction_consistency', 'placement'];
const STATUSES = new Set(['planned', 'generated_unreviewed', 'cleanup_required',
  'native_review_required', 'approved', 'runtime_integrated', 'concept_only', 'rejected', 'blocked']);
const APPROVED = new Set(['approved', 'runtime_integrated']);
const AVAILABLE = new Set(['missing', 'source_only', 'generated', 'native_export', 'available',
  'approved', 'runtime_integrated']);
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const pair = (a, positive = false) => Array.isArray(a) && a.length === 2
  && a.every(n => Number.isSafeInteger(n) && (!positive || n > 0));
const rotate = ([x, y]) => [-y || 0, x || 0];
const maskKey = mask => mask.map(p => p.join(',')).sort().join(';');
const md = value => String(value).replaceAll('|', '\\|').replaceAll('\n', ' ');
const code = value => String.fromCharCode(96) + String(value) + String.fromCharCode(96);
const linkPath = target => path.relative(path.dirname(GALLERY), target).split(path.sep)
  .map(part => encodeURIComponent(part)).join('/');

export function parsePngHeader(bytes) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (bytes.length < 33 || !bytes.subarray(0, 8).equals(signature)
      || bytes.readUInt32BE(8) !== 13 || bytes.toString('ascii', 12, 16) !== 'IHDR') {
    throw new Error('Not a PNG with a complete IHDR header');
  }
  const size = [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
  if (!pair(size, true) || size.some(n => n > 100000)) throw new Error('Invalid PNG dimensions');
  return size;
}

function localPath(value, root = ROOT) {
  if (typeof value !== 'string' || !value.trim() || value.includes('\0')) {
    throw new Error('Expected a nonempty local file path, or null for missing art');
  }
  const normalized = value.startsWith('res://') ? `game/${value.slice(6)}` : value;
  if (/^[a-z][a-z0-9+.-]*:/i.test(normalized)) throw new Error('Only local catalogue files are supported');
  const resolved = path.resolve(root, normalized);
  const relative = path.relative(root, resolved);
  if (relative.startsWith(`..${path.sep}`) || relative === '..' || path.isAbsolute(relative)) {
    throw new Error('Catalogue evidence must be inside the repository for a portable handoff');
  }
  return resolved;
}

// Native export proof only: eight-bit, non-interlaced RGB/RGBA. Masters with
// other encodings retain header/hash validation rather than a guessed decode.
export function nativePngFacts(bytes) {
  const [width, height] = parsePngHeader(bytes);
  const channels = bytes[25] === 6 ? 4 : bytes[25] === 2 ? 3 : 0;
  if (bytes[24] !== 8 || !channels || bytes[28] !== 0) throw new Error('Unsupported native PNG encoding');
  const chunks = [];
  for (let offset = 8; offset + 12 <= bytes.length;) {
    const length = bytes.readUInt32BE(offset);
    if (offset + length + 12 > bytes.length) throw new Error('Truncated PNG chunk');
    if (bytes.toString('ascii', offset + 4, offset + 8) === 'IDAT') chunks.push(bytes.subarray(offset + 8, offset + 8 + length));
    offset += length + 12;
  }
  const stride = width * channels, raw = zlib.inflateSync(Buffer.concat(chunks));
  if (raw.length !== (stride + 1) * height) throw new Error('Unexpected PNG scanline length');
  const decoded = Buffer.alloc(stride * height), rgba = Buffer.alloc(width * height * 4);
  const paeth = (a, b, c) => { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); return pa <= pb && pa <= pc ? a : pb <= pc ? b : c; };
  let opaque = 0, partial = 0, hidden = 0, minX = width, minY = height, maxX = -1, maxY = -1;
  const colors = new Set();
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    if (filter > 4) throw new Error('Invalid PNG filter');
    for (let x = 0; x < stride; x++) {
      const i = y * stride + x, left = x >= channels ? decoded[i - channels] : 0;
      const up = y > 0 ? decoded[i - stride] : 0, corner = y > 0 && x >= channels ? decoded[i - stride - channels] : 0;
      decoded[i] = (raw[y * (stride + 1) + 1 + x] + [0, left, up, Math.floor((left + up) / 2), paeth(left, up, corner)][filter]) & 255;
    }
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * channels, o = (y * width + x) * 4;
      rgba[o] = decoded[i]; rgba[o + 1] = decoded[i + 1]; rgba[o + 2] = decoded[i + 2]; rgba[o + 3] = channels === 4 ? decoded[i + 3] : 255;
      const a = rgba[o + 3];
      if (a === 255) opaque++;
      else if (a > 0) partial++;
      else if (rgba[o] || rgba[o + 1] || rgba[o + 2]) hidden++;
      if (a > 0) { minX = Math.min(minX, x); minY = Math.min(minY, y); maxX = Math.max(maxX, x); maxY = Math.max(maxY, y); colors.add(rgba.readUInt32BE(o)); }
    }
  }
  return {opaque_bounds_px: maxX < 0 ? [0, 0, 0, 0] : [minX, minY, maxX - minX + 1, maxY - minY + 1], opaque_pixels: opaque,
    partial_alpha_pixels: partial, hidden_rgb_pixels: hidden, used_colors: colors.size,
    decoded_rgba_sha256: crypto.createHash('sha256').update(rgba).digest('hex')};
}
const nativeFactsCache = new Map();

function realFiles(root = ROOT) {
  const checked = new Map();
  return {
    file(value) {
      const resolved = localPath(value, root);
      if (!fs.statSync(resolved).isFile()) throw new Error('Path is not a regular file');
      const real = fs.realpathSync(resolved);
      const rel = path.relative(root, real);
      if (rel.startsWith(`..${path.sep}`) || rel === '..' || path.isAbsolute(rel)) {
        throw new Error('Symlink points outside the repository');
      }
      checked.set(resolved, real);
      return resolved;
    },
    png(value) {
      const resolved = this.file(value);
      const descriptor = fs.openSync(resolved, 'r');
      try {
        const header = Buffer.alloc(33);
        const length = fs.readSync(descriptor, header, 0, header.length, 0);
        return parsePngHeader(header.subarray(0, length));
      } finally { fs.closeSync(descriptor); }
    },
    count: () => checked.size,
  };
}

export function validateCatalogue(catalogue, files = realFiles()) {
  const errors = [];
  let checks = 0;
  const verify = (ok, message) => { checks += 1; if (!ok) errors.push(message); return !!ok; };
  const file = (value, label, required = false) => {
    if (value === null || value === undefined) { if (required) verify(false, `${label}: required file is missing`); return null; }
    try { const resolved = files.file(value); verify(true, label); return resolved; }
    catch (error) { verify(false, `${label}: ${error.message}`); return null; }
  };
  const png = (value, expected, label) => {
    if (!file(value, label, true)) return;
    try {
      const actual = files.png(value);
      verify(same(actual, expected), `${label}: PNG is ${actual.join('x')}, expected ${expected.join('x')}`);
    } catch (error) { verify(false, `${label}: ${error.message}`); }
  };
  // Future source/output/prompt/evidence fields must not quietly point at imaginary files.
  function checkPathFields(node, label = 'catalogue') {
    if (!node || typeof node !== 'object') return;
    const budget = node.generation_budget ?? node.source_batch;
    if (budget) {
      const retries = budget.targeted_retries_included ?? budget.targeted_retries;
      const limit = budget.max_targeted_retries ?? budget.retry_limit;
      verify(budget.initial_calls === 1 && limit === 3 && Number.isSafeInteger(retries)
        && retries >= 0 && retries <= limit, `${label}: initial plus three targeted retry limit`);
      verify(budget.exhausted === (retries === limit), `${label}: false retry exhaustion`);
      verify(node.source_attempts?.length === 1 + retries, `${label}: request count/source history mismatch`);
    }
    const masterSize = node.source_size_px ?? node.size_px;
    if (node.source_path?.endsWith('.png') && masterSize) {
      if (verify(pair(masterSize, true), `${label}: invalid source PNG dimensions`)) {
        png(node.source_path, masterSize, `${label}: measured source PNG dimensions`);
      }
    }
    if (node.path?.endsWith('.png') && node.canvas_size_px) {
      const grid = node.atlas_grid ?? [1, 1];
      if (verify(pair(node.canvas_size_px, true) && pair(grid, true), `${label}: invalid declared PNG canvas/grid`)) {
        png(node.path, [node.canvas_size_px[0] * grid[0], node.canvas_size_px[1] * grid[1]], `${label}: measured PNG dimensions`);
      }
    }
    if (node.sha256 !== undefined) {
      const target = node.path ?? node.source_path;
      if (verify(typeof node.sha256 === 'string' && /^[a-f0-9]{64}$/.test(node.sha256)
          && typeof target === 'string', `${label}: SHA-256 requires a local path and64 lowercase hex digits`)) {
        const resolved = file(target, `${label}: hashed file`, true);
        if (resolved) verify(crypto.createHash('sha256').update(fs.readFileSync(resolved)).digest('hex') === node.sha256,
          `${label}: recorded file SHA-256 is stale`);
      }
    }
    if (node.verify_decoded_facts === true) {
      const resolved = file(node.path, `${label}: native pixel proof`, true);
      if (resolved) {
        try {
          const bytes = fs.readFileSync(resolved), hash = crypto.createHash('sha256').update(bytes).digest('hex');
          if (!nativeFactsCache.has(hash)) nativeFactsCache.set(hash, nativePngFacts(bytes));
          for (const [key, actual] of Object.entries(nativeFactsCache.get(hash))) {
            verify(same(node[key], actual), `${label}: measured ${key} is stale`);
          }
        } catch (error) { verify(false, `${label}: ${error.message}`); }
      }
    }
    for (const [key, value] of Object.entries(node)) {
      if (value === null || value === undefined) continue;
      if (key === 'path' || key.endsWith('_path')) file(value, `${label}.${key}`);
      else if (key.endsWith('_paths') || key === 'source_files') {
        if (verify(Array.isArray(value), `${label}.${key}: expected a path list`)) {
          value.forEach((item, i) => file(item, `${label}.${key}[${i}]`, true));
        }
      } else if (typeof value === 'object') checkPathFields(value, `${label}.${key}`);
    }
  }
  checkPathFields(catalogue);
  for (const item of catalogue.supporting_assets ?? []) {
    if (item.kind === 'flat_front_measured_fit_not_successful_requested_aspect') {
      const source = item.source_size_px ?? item.size_px;
      verify(item.strict_target_rejected === true && same(item.requested_native_size_px, [88, 24])
        && same(item.strict_uniform_result_px, [88, Math.round(source[1] * 88 / source[0])])
        && !same(item.strict_uniform_result_px, item.requested_native_size_px),
        `${item.id}: failed requested aspect must remain explicit`);
      verify(same(item.measured_native_size_px, [Math.round(source[0] * 24 / source[1]), 24])
        && same(item.exports?.[0]?.canvas_size_px, item.measured_native_size_px)
        && same(item.unchanged_bay_size_px, [88, 24]) && same(item.geometry_inset_px, [9, 0]),
        `${item.id}: measured fit must preserve uniform source normalization and original bay`);
      verify(item.source_crop_applied === false && item.nonuniform_scale_applied === false
        && item.runtime_approved === false && !APPROVED.has(item.status),
        `${item.id}: mechanical fit is not a cropped, stretched or production-approved source`);
    }
    if (item.native_export_absent === true) {
      verify((item.exports ?? []).length === 0 && !APPROVED.has(item.status),
        `${item.id}: source-only rejection cannot claim native exports or approval`);
    }
    if (item.native_review_pending_at_cutoff === true || item.visual_review_passed === false) {
      verify(item.runtime_approved === false && !APPROVED.has(item.status),
        `${item.id}: mechanical checks do not approve pending or failed native review`);
    }
    if (item.kind !== 'passive_storage_front_variant_not_new_furniture_family_or_service') continue;
    verify(same(item.source_drawing_facings, ['south']), `${item.id}: only South is a new role drawing`);
    verify(item.runtime_approved === false && item.role_service_enabled === false
      && !APPROVED.has(item.status), `${item.id}: staged role decor is not a runtime service or approval`);
    const reuses = item.reused_common_facings ?? [];
    verify(same(reuses.map(view => view.service_side), ['north', 'east', 'west']),
      `${item.id}: common N/E/W reuse must be explicit and unique`);
    for (const view of reuses) {
      const index = DIRECTIONS.indexOf(view.service_side);
      const prefix = `game/assets/runtime/office/archive-v1/${view.service_side}-`;
      verify(view.is_new_drawing === false && view.approach_gaze === DIRECTIONS[(index + 2) % 4],
        `${item.id}/${view.service_side}: reuse is not a new drawing or workstation gaze`);
      verify(view.path === `${prefix}whole.png` && same(view.render_layer_paths,
        ['carcass', 'top', 'front', 'plinth', 'insert'].map(layer => `${prefix}${layer}.png`)),
      `${item.id}/${view.service_side}: reuse must retain the actual common archive layers`);
    }
  }
  const originals = catalogue.source_inventory?.items ?? [];
  if (catalogue.source_inventory) {
    verify(catalogue.source_inventory.original_png_count === originals.length, 'Source inventory count is stale');
    verify(new Set(originals.map(item => item.source_path)).size === originals.length, 'Source inventory duplicates an original');
    for (const item of originals) {
      verify(item.source_path?.startsWith('game/assets/source/overnight-20260904/')
        && item.source_path.endsWith('.png'), 'Original inventory must not count native exports or code renders');
      verify(pair(item.size_px, true) && !!item.sha256 && !!item.prompt_path,
        'Original inventory requires measured dimensions, hash and original prompt');
    }
  }
  verify(catalogue.scope === 'dev_only_art_planning_not_runtime_data', 'Catalogue must remain dev-only');
  verify(same(catalogue.conventions?.facing_order, DIRECTIONS), 'Global facing order must be N/E/S/W');
  const families = Array.isArray(catalogue.families) ? catalogue.families : [];
  verify(families.length > 0, 'Catalogue has no families');
  const byId = new Map();
  for (const family of families) {
    verify(typeof family.id === 'string' && /^[a-z][a-z0-9_]*$/.test(family.id), 'Invalid family id');
    verify(!byId.has(family.id), `Duplicate family id: ${family.id}`);
    byId.set(family.id, family);
  }
  const counts = Object.fromEntries([...STATUSES].map(status => [status, 0]));
  let legacy = 0, nativeExports = 0, runtimeExports = 0;
  const runtimeFiles = new Set();
  for (const family of families) {
    const prefix = family.id;
    const geometry = family.native_geometry ?? {};
    const canvas = geometry.canvas_size_px;
    const anchor = geometry.floor_anchor_px;
    const canvasValid = verify(pair(canvas, true), `${prefix}: invalid native canvas`);
    const anchorValid = verify(pair(anchor), `${prefix}: invalid floor anchor`);
    if (canvasValid && anchorValid) verify(anchor[0] >= 0 && anchor[1] >= 0
      && anchor[0] < canvas[0] && anchor[1] < canvas[1], `${prefix}: floor anchor outside native canvas`);
    verify(geometry.grid_size_px === 32, `${prefix}: expected the existing 32px grid`);
    verify(['base', 'decor'].includes(family.base_vs_decor), `${prefix}: unknown assembly kind`);
    verify(['P0', 'P1', 'P2'].includes(family.priority), `${prefix}: invalid priority`);
    verify(DIRECTION_SEMANTICS.has(family.direction_semantics), `${prefix}: direction semantics must be explicit`);
    verify(Array.isArray(family.role_tools) && family.role_tools.length > 0, `${prefix}: missing role tools`);
    const layers = Array.isArray(family.layers) ? family.layers : [];
    verify(layers.length > 0, `${prefix}: missing semantic layers`);
    verify(new Set(layers.map(layer => layer.id)).size === layers.length, `${prefix}: duplicate layer ids`);
    for (const layer of layers) {
      verify(typeof catalogue.layer_contract?.[layer.id] === 'string', `${prefix}: unknown layer ${layer.id}`);
      verify(layer.same_canvas_and_floor_anchor === true, `${prefix}/${layer.id}: layers must share canvas and anchor`);
      verify(STATUSES.has(layer.status), `${prefix}/${layer.id}: invalid lifecycle status`);
    }
    if (family.base_vs_decor === 'decor') {
      const host = byId.get(family.primary_host);
      verify(host?.base_vs_decor === 'base', `${prefix}: primary host must be an existing base`);
      if (host) {
        verify(same(canvas, host.native_geometry?.canvas_size_px), `${prefix}: host canvas mismatch`);
        verify(same(anchor, host.native_geometry?.floor_anchor_px), `${prefix}: host floor-anchor mismatch`);
      }
    } else verify(family.primary_host === null, `${prefix}: base cannot be a host-attached kit`);
    const availability = family.current_availability ?? {};
    if (availability.status === 'legacy_runtime_source_present') {
      legacy += 1;
      if (verify(pair(availability.measured_texture_size_px, true), `${prefix}: missing measured legacy dimensions`)) {
        png(availability.art_path, availability.measured_texture_size_px, `${prefix}: legacy source`);
      }
      if (availability.atlas_cell_px !== null && availability.atlas_cell_px !== undefined) {
        const cell = availability.atlas_cell_px, texture = availability.measured_texture_size_px;
        if (verify(pair(cell, true) && pair(texture, true), `${prefix}: invalid legacy atlas dimensions`)) {
          verify(texture[0] % cell[0] === 0 && texture[1] % cell[1] === 0, `${prefix}: legacy atlas is not cell-aligned`);
          if (availability.atlas_row !== null && availability.atlas_row !== undefined) {
            verify(Number.isSafeInteger(availability.atlas_row) && availability.atlas_row >= 0
              && (availability.atlas_row + 1) * cell[1] <= texture[1], `${prefix}: legacy atlas row is out of bounds`);
          }
        }
      }
    }
    const variants = Array.isArray(family.variants) ? family.variants : [];
    const library = family.art_library_approval;
    const passiveLibrary = library?.scope === 'passive_art_library' && library.runtime_admission === false;
    if (library !== undefined) {
      verify(passiveLibrary && /^\d{4}-\d{2}-\d{2}$/.test(library.acceptance_date ?? ''),
        `${prefix}: passive-library approval requires explicit dated scope and no runtime admission`);
      file(library.review_path, `${prefix}: passive-library review`, true);
      verify(family.production_status === 'approved' && variants.every(v => v.status === 'approved'),
        `${prefix}: passive-library acceptance requires the complete reviewed family`);
      verify(!family.current_runtime_registration && !family.runtime_art_path && !(family.runtime_exports?.length)
        && variants.every(v => !v.runtime_art_path && !v.runtime_evidence_path && !(v.runtime_exports?.length)),
        `${prefix}: passive-library approval cannot declare runtime bindings`);
    }
    const symmetricPassive = family.construction?.method === 'code_native_symmetric_projection_with_generated_material';
    const passiveProjection = symmetricPassive || (family.construction?.method === 'code_native_projection_with_generated_flat_materials'
      && family.construction.no_service_or_actor_gaze === true);
    if (passiveProjection && !symmetricPassive) {
      verify(family.direction_semantics === 'visual_orientation', `${prefix}: passive front is not a service side`);
      verify(same(family.construction.equivalent_pairs, [['east', 'west']])
        && family.construction.distinct_projected_shapes === 3, `${prefix}: closed-end symmetry must retain distinct front and rear`);
      const east = variants.find(v => v.facing === 'east'), west = variants.find(v => v.facing === 'west');
      verify(east?.symmetry_equivalent_to === 'west' && west?.symmetry_equivalent_to === 'east',
        `${prefix}: both closed ends declare equivalence`);
      if (east?.deliverable_availability !== 'missing' || west?.deliverable_availability !== 'missing') verify(
        !!east?.composite_exports?.[0]?.sha256 && east.composite_exports[0].sha256 === west?.composite_exports?.[0]?.sha256,
        `${prefix}: equivalent closed ends must match actual native output`);
    }
    if (symmetricPassive) {
      const construction = family.construction;
      verify(family.direction_semantics === 'visual_orientation' && construction.no_service_or_actor_gaze === true,
        `${prefix}: symmetric passive projection has no employee gaze or service`);
      verify(construction.generated_complete_views === false && construction.generated_originals === 1
        && same(construction.source_drawing_facings, []), `${prefix}: material source is not four generated views`);
      verify(construction.distinct_projected_shapes === 2
        && same(construction.equivalent_pairs, [['north', 'south'], ['east', 'west']]),
        `${prefix}: declare exactly two physical symmetry pairs`);
      verify(construction.runtime_approved === false
        && (variants.every(v => !APPROVED.has(v.status))
          || (passiveLibrary && family.production_status === 'approved' && variants.every(v => v.status === 'approved'))),
        `${prefix}: symmetric passive approval must remain library-only`);
      verify(family.geometry_history?.length > 0 && !!family.native_geometry.contract_path,
        `${prefix}: measured symmetric geometry preserves its planning history`);
      for (const [a, b] of [['north', 'south'], ['east', 'west']]) {
        const first = variants.find(v => v.facing === a), second = variants.find(v => v.facing === b);
        verify(first?.symmetry_equivalent_to === b && second?.symmetry_equivalent_to === a,
          `${prefix}: symmetric slots must name their equivalent view`);
        if (first?.deliverable_availability !== 'missing' || second?.deliverable_availability !== 'missing') {
          verify(!!first?.composite_exports?.[0]?.sha256
            && first.composite_exports[0].sha256 === second?.composite_exports?.[0]?.sha256,
            `${prefix}: declared projected symmetry must match actual exported PNGs`);
        }
      }
    }
    if (family.construction?.method === 'code_native_projection_with_generated_flat_materials') {
      verify(family.construction.generated_complete_views === false,
        `${prefix}: code-native views are not four generated originals`);
      verify(family.geometry_history?.length > 0 && !!family.native_geometry.contract_path,
        `${prefix}: measured replacement must preserve the old planning contract`);
      verify(same(family.construction.source_drawing_facings, ['south']),
        `${prefix}: only the flat South insert is newly drawn`);
      if (family.construction.canonical_integration_passed === false) verify(
        family.construction.runtime_approved === false && variants.every(v => !APPROVED.has(v.status)),
        `${prefix}: a native art study does not authorize canonical runtime admission`);
      if (family.construction.runtime_approved === true) verify(
        variants.every(v => APPROVED.has(v.status)) && !!family.current_runtime_registration,
        `${prefix}: local canonical integration is not production art approval or registration`);
    }
    verify(same(variants.map(variant => variant.facing), DIRECTIONS), `${prefix}: require exactly one ordered N/E/S/W variant`);
    const masks = [];
    for (const [index, variant] of variants.entries()) {
      const name = `${prefix}/${variant.facing}`;
      const status = variant.status;
      verify(STATUSES.has(status), `${name}: invalid lifecycle status ${status}`);
      if (STATUSES.has(status)) counts[status] += 1;
      verify(AVAILABLE.has(variant.deliverable_availability), `${name}: unknown deliverable availability`);
      if (family.direction_semantics === 'service_side') {
        verify(variant.service_side === DIRECTIONS[index], `${name}: service side must match this slot`);
        verify(variant.approach_gaze === DIRECTIONS[(index + 2) % 4], `${name}: approach gaze must oppose service side`);
        verify(same(variant.employee_look_vector, VECTORS[(index + 2) % 4]), `${name}: shared-service employee gaze is not the service front`);
        const interaction = variant.proposed_interaction_cell;
        if (pair(interaction)) verify(interaction[0] * VECTORS[index][0] + interaction[1] * VECTORS[index][1] > 0,
          `${name}: proposed approach must lie on the declared service side`);
      } else {
        verify(variant.service_side === undefined && variant.approach_gaze === undefined,
          `${name}: non-service family must not acquire a fabricated service front`);
        if (passiveProjection) {
          verify(variant.employee_look_vector === undefined && variant.proposed_interaction_cell === null
            && variant.seated_pose_needed === false && same(variant.reference_axis_vector, VECTORS[index]),
            `${name}: passive orientation must not fabricate actor gaze, interaction or seating`);
        } else verify(same(variant.employee_look_vector, VECTORS[index]), `${name}: incorrect employee/reference gaze vector`);
      }
      if (variant.native_geometry) {
        verify(same(variant.native_geometry.canvas_size_px, canvas), `${name}: per-facing canvas drift`);
        verify(same(variant.native_geometry.floor_anchor_px, anchor), `${name}: per-facing anchor drift`);
      }
      const mask = variant.proposed_occupied_cell_offsets;
      const maskValid = verify(Array.isArray(mask) && mask.every(cell => pair(cell)), `${name}: invalid occupied cells`);
      if (maskValid) {
        masks.push(mask);
        verify(new Set(mask.map(cell => cell.join(','))).size === mask.length, `${name}: duplicate occupied cell`);
        const dimensions = mask.length ? [Math.max(...mask.map(p => p[0])) - Math.min(...mask.map(p => p[0])) + 1,
          Math.max(...mask.map(p => p[1])) - Math.min(...mask.map(p => p[1])) + 1] : [0, 0];
        verify(same(dimensions, variant.footprint_cells), `${name}: footprint dimensions do not match the mask`);
        if (family.base_vs_decor === 'decor') verify(mask.length === 0, `${name}: a decor kit adds floor collision`);
        else verify(mask.length > 0, `${name}: a base has no proposed occupied cells`);
        if (variant.proposed_interaction_cell !== null) {
          if (verify(pair(variant.proposed_interaction_cell), `${name}: invalid proposed interaction cell`)) {
            verify(!mask.some(cell => same(cell, variant.proposed_interaction_cell)), `${name}: interaction cell overlaps occupied floor`);
          }
        }
      }
      const legacyFacings = availability.runtime_registered_facings ?? [];
      verify(variant.legacy_runtime_art_for_this_facing === legacyFacings.includes(variant.facing), `${name}: legacy-facing flag contradicts recorded availability`);
      if (family.direction_semantics === 'service_side' && legacyFacings.includes(variant.facing)) {
        verify(availability.runtime_service_side === variant.service_side
          && availability.runtime_approach_gaze === variant.approach_gaze,
        `${name}: legacy shared-service orientation was reinterpreted`);
        if (maskValid) verify(maskKey(variant.proposed_occupied_cell_offsets) === maskKey(availability.runtime_occupied_cells ?? []),
          `${name}: legacy shared-service occupied geometry drifted`);
        verify(same(variant.proposed_interaction_cell, availability.runtime_interaction_cell),
          `${name}: legacy shared-service interaction moved`);
      }
      const missing = variant.deliverable_availability === 'missing';
      const budget = variant.generation_budget ?? variant.source_batch;
      if (budget) {
        const retries = budget.targeted_retries_included ?? budget.targeted_retries;
        const limit = budget.max_targeted_retries ?? budget.retry_limit;
        verify(budget.initial_calls === 1 && limit === 3
          && Number.isSafeInteger(retries) && retries >= 0 && retries <= limit,
        `${name}: recorded source batch must respect initial plus three targeted retries`);
        verify(budget.exhausted === (retries === limit), `${name}: retry-exhaustion claim contradicts completed attempts`);
        verify(variant.source_attempts?.length === budget.initial_calls + retries,
          `${name}: source history does not match recorded completed request count`);
      }
      const sources = [variant.output_path, variant.generated_source_path, variant.preview_path];
      const exports = [];
      for (const field of ['native_exports', 'runtime_exports']) {
        if (variant[field] === undefined) continue;
        if (!verify(Array.isArray(variant[field]), `${name}.${field}: expected an export list`)) continue;
        for (const item of variant[field]) {
          if (!verify(item && typeof item === 'object', `${name}.${field}: invalid export descriptor`)) continue;
          const label = `${name}.${field}/${item.layer ?? 'unknown'}`;
          const layerIds = item.layer_ids ?? [item.layer];
          verify(Array.isArray(layerIds) && layerIds.length > 0
            && layerIds.every(id => layers.some(layer => layer.id === id)), `${label}: unknown export layer`);
          verify(same(item.canvas_size_px, canvas), `${label}: declared canvas must match the family contract`);
          verify(same(item.floor_anchor_px, anchor), `${label}: declared anchor must match the family contract`);
          const grid = item.atlas_grid ?? [1, 1];
          if (verify(pair(grid, true), `${label}: invalid atlas grid`) && canvasValid) {
            if (layerIds.length > 1) verify(grid[0] * grid[1] >= layerIds.length, `${label}: atlas cannot hold all declared layers`);
            png(item.path, [canvas[0] * grid[0], canvas[1] * grid[1]], label);
          }
          exports.push(item);
          if (field === 'native_exports') nativeExports += 1; else runtimeExports += 1;
          if (field === 'runtime_exports') {
            runtimeFiles.add(item.path);
            if (item.source_path) {
              const source = file(item.source_path, `${label}: reviewed source`, true);
              const installed = file(item.path, `${label}: runtime copy`, true);
              if (source && installed) verify(fs.readFileSync(source).equals(fs.readFileSync(installed)),
                `${label}: runtime PNG differs from reviewed source`);
            }
          }
        }
      }
      if (variant.native_export_path) {
        if (canvasValid) png(variant.native_export_path, canvas, `${name}: native export`);
        nativeExports += 1;
      }
      if (variant.runtime_art_path) {
        runtimeFiles.add(variant.runtime_art_path);
        const descriptor = exports.find(item => item.path === variant.runtime_art_path);
        if (!descriptor && canvasValid) png(variant.runtime_art_path, canvas, `${name}: runtime export`);
        if (variant.native_export_path) {
          const reviewed = file(variant.native_export_path, `${name}: reviewed whole reference`, true);
          const installed = file(variant.runtime_art_path, `${name}: installed whole reference`, true);
          if (reviewed && installed) verify(fs.readFileSync(reviewed).equals(fs.readFileSync(installed)),
            `${name}: installed whole reference differs from reviewed native source`);
        }
      }
      const hasCandidate = sources.some(Boolean) || exports.length > 0 || !!variant.native_export_path
        || (variant.component_exports?.length ?? 0) > 0 || (variant.composite_exports?.length ?? 0) > 0;
      if (missing) {
        verify(!hasCandidate && !variant.approved_art_path && !variant.runtime_art_path, `${name}: missing view declares an output or approval`);
        verify(['planned', 'blocked'].includes(status), `${name}: lifecycle claims work exists but availability is missing`);
      } else verify(hasCandidate, `${name}: available view has no actual output/native export`);
      if (status === 'planned') verify(missing, `${name}: generated art must advance beyond planned`);
      if (status === 'blocked' || status === 'rejected') verify(typeof variant.reason === 'string'
        && variant.reason.trim().length > 0, `${name}: blocked/rejected state requires a reason`);
      if (!APPROVED.has(status)) {
        verify(!variant.approved_art_path, `${name}: unreviewed view cannot claim approved art`);
        verify(!variant.runtime_art_path && !(variant.runtime_exports?.length), `${name}: unreviewed view cannot claim runtime exports`);
        verify(!['approved', 'runtime_integrated'].includes(variant.deliverable_availability), `${name}: availability overclaims approval`);
      } else {
        file(variant.approved_art_path, `${name}: approved art`, true);
        file(variant.evidence_path, `${name}: native review evidence`, true);
        const approvedExport = exports.find(item => item.path === variant.approved_art_path);
        if (!approvedExport && canvasValid) png(variant.approved_art_path, canvas, `${name}: approved native art`);
        verify(!missing, `${name}: approved view cannot be missing`);
        const covered = new Set(exports.flatMap(item => item.layer_ids ?? [item.layer]));
        verify(layers.filter(layer => layer.required).every(layer => covered.has(layer.id)), `${name}: approved view is missing required native layer exports`);
        verify(variant.review?.geometry_reviewed === true, `${name}: approval requires explicit geometry review`);
        verify(variant.review?.placement_tests_passed === true, `${name}: approval requires passing placement tests`);
        if (variant.seated_pose_needed) verify(variant.review?.actor_pose_reviewed === true, `${name}: seated view needs actor-pose review`);
        verify(variant.review?.scores !== undefined, `${name}: approval requires the six-category review rubric`);
      }
      if (status === 'native_review_required') verify(exports.length > 0 || !!variant.native_export_path, `${name}: native review needs a declared native export`);
      if (status === 'runtime_integrated') {
        verify(!!variant.runtime_art_path || (variant.runtime_exports?.length ?? 0) > 0, `${name}: runtime integration requires an actual runtime export`);
        file(variant.runtime_evidence_path, `${name}: runtime evidence`, true);
      }
      if (variant.review?.scores) {
        const scores = Object.values(variant.review.scores);
        verify(same(Object.keys(variant.review.scores).sort(), [...RUBRIC].sort())
          && scores.every(score => Number.isInteger(score) && score >= 0 && score <= 3), `${name}: review needs the six named integer0–3 rubric scores`);
        if (APPROVED.has(status)) verify(scores.every(score => score >= 2)
          && scores.reduce((sum, score) => sum + score, 0) / scores.length >= 2.5, `${name}: review scores do not meet the approval threshold`);
      }
    }
    if (masks.length === 4) {
      for (let i = 1; i < 4; i += 1) verify(maskKey(masks[i]) === maskKey(masks[i - 1].map(rotate)), `${prefix}: occupied masks do not rotate exactly about the fixed floor pivot`);
      const footprints = variants.map(variant => variant.footprint_cells);
      if (footprints.every(footprint => pair(footprint))) {
        verify(same(footprints[0], footprints[2]) && same(footprints[1], footprints[3])
          && same(footprints[0], [footprints[1][1], footprints[1][0]]), `${prefix}: N/S and E/W footprint dimensions are inconsistent`);
      }
    }
    if (APPROVED.has(family.production_status)) {
      const acceptedStatus = family.production_status;
      verify(variants.length === 4 && variants.every(variant => variant.status === acceptedStatus),
        `${prefix}: ${acceptedStatus} family lifecycle must match every directional view`);
      verify(layers.filter(layer => layer.required).every(layer => layer.status === acceptedStatus),
        `${prefix}: ${acceptedStatus} family requires matching required layer rollups`);
    }
    const registration = family.current_runtime_registration;
    if (registration) {
      verify(family.production_status === 'runtime_integrated' && variants.every(v => v.status === 'runtime_integrated'),
        `${prefix}: current runtime registration must agree with all direction lifecycles`);
      const catalogueFile = file(registration.catalogue_path, `${prefix}: actual runtime catalogue`, true);
      if (catalogueFile) {
        const actual = JSON.parse(fs.readFileSync(catalogueFile, 'utf8')).furniture?.[registration.runtime_family_id];
        verify(!!actual && same(actual.facings, registration.registered_facings)
          && same(actual.facing_profiles, registration.profiles), `${prefix}: runtime registration snapshot is stale`);
        for (const variant of variants) {
          const profile = registration.profiles?.[variant.facing];
          verify(profile?.status === 'runtime_ready' && profile.review?.art === true && profile.review?.geometry === true,
            `${prefix}/${variant.facing}: runtime profile is not actually reviewed`);
          const recorded = new Set((variant.runtime_exports ?? []).map(e => localPath(e.path)));
          verify(profile?.render_layers?.length === recorded.size
            && profile.render_layers.every(layer => recorded.has(localPath(layer.art))),
          `${prefix}/${variant.facing}: real runtime layer list disagrees with declared copies`);
        }
      }
    }
  }
  const summary = catalogue.summary ?? {};
  const countsExpected = {family_count: families.length, legacy_runtime_families: legacy,
    new_family_proposals: families.length - legacy, base_families: families.filter(f => f.base_vs_decor === 'base').length,
    decor_kit_families: families.filter(f => f.base_vs_decor === 'decor').length,
    required_directions_per_family: 4, planned_directional_deliverables: families.length * 4,
    approved_directional_deliverables: counts.approved + counts.runtime_integrated};
  for (const [key, value] of Object.entries(countsExpected)) verify(summary[key] === value, `summary.${key}: expected ${value}, found ${summary[key]}`);
  const queue = catalogue.production_order?.flatMap(phase => phase.family_ids) ?? [];
  verify(queue.length === byId.size && new Set(queue).size === queue.length
    && queue.every(id => byId.has(id)), 'Production queue must contain every family exactly once');
  return {ok: errors.length === 0, checks, errors, families: families.length,
    directions: Object.values(counts).reduce((sum, n) => sum + n, 0), statuses: counts,
    legacyReferences: legacy, nativeExports, runtimeExports, runtimeFiles: runtimeFiles.size,
    sourceOriginals: originals.length, filesChecked: files.count?.() ?? null};
}

export function galleryMarkdown(catalogue, result, catalogueBytes) {
  const lines = ['# Furniture art gallery', '', '<!-- Generated by dev/tools/validate_art_catalogue.mjs --write-gallery. Do not edit by hand. -->', '',
    `Catalogue: [furniture.json](furniture.json), SHA-256 \`${crypto.createHash('sha256').update(catalogueBytes).digest('hex')}\`.`, '',
    `${result.families} families · ${result.directions} directional slots · ${result.statuses.approved + result.statuses.runtime_integrated} approved · ${result.statuses.planned} planned · ${result.legacyReferences} existing legacy references.`, '',
    'This is a navigation index, not native-size visual approval. Thumbnails below link to real local files only; missing art is never filled with a reference from another direction. Image embeds use this checkout’s absolute paths; regenerate after relocating the project.', '',
    `Frozen checkpoint: **${md(catalogue.frozen_checkpoint_utc ?? 'not recorded')}**. Later in-flight generations are intentionally excluded. The [measured source/master index](../../game/assets/source/overnight-20260904/README.md) preserves originals and failed attempts through this checkpoint.`, '',
    'Directions are employee gaze for workstations/host kits, but explicitly named **service side** for shared-service objects. Their approach gaze is opposite; legacy South service bindings are preserved. Read each family’s semantic label. A retained misdirected source is not a second correctly authored view.', '',
    'Native desk/computer canvases are **192×224**, pivot **[96,160]**; chairs **96×160**, pivot **[48,112]**; coffee **192×256**, pivot **[96,192]**; archives **192×288**, pivot **[96,224]**. Small flat archive-face textures are material inserts, not floor-anchored whole furniture. The legacy **128×112** desk cell remains separate. Native dimensions, component exports and material alternatives do not establish finished directional approval.', '',
    '| Family | Priority | Assembly | North | East | South | West | Legacy source |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- |'];
  function variantLabel(variant) {
    const label = variant.deliverable_availability === 'missing' ? `Missing · ${variant.status}` : variant.status.replaceAll('_', ' ');
    const target = variant.approved_art_path ?? variant.preview_path ?? variant.native_exports?.[0]?.path ?? variant.native_export_path ?? variant.output_path ?? variant.generated_source_path;
    return target ? `[${md(label)}](${linkPath(localPath(target))})` : md(label);
  }
  const fileLink = (label, target) => `[${md(label)}](${linkPath(localPath(target))})`;
  function links(label, targets) {
    if (targets?.length) lines.push(`${label}: ${[...new Set(targets)].map(target => fileLink(path.basename(target), target)).join(' · ')}`, '');
  }
  function exportTable(title, items) {
    if (!items?.length) return;
    lines.push(`**${title}**`, '', '| Export | Canvas / pivot | Actual opaque bounds | Derivation / limits |',
      '| --- | --- | --- | --- |');
    for (const item of items) {
      const canvas = item.canvas_size_px?.join('×') ?? 'See source';
      const pivot = item.floor_anchor_px ? ` / [${item.floor_anchor_px.join(', ')}]` : '';
      const bounds = item.opaque_bounds_px ? `[${item.opaque_bounds_px.join(', ')}]${item.opaque_pixels ? `; ${item.opaque_pixels} pixels` : ''}` : item.alpha ?? 'Not measured here';
      const name = `${item.component ? `${item.component}: ` : ''}${path.basename(item.path)}`;
      lines.push(`| ${fileLink(name, item.path)} | ${canvas}${pivot} | ${md(bounds)} | ${md(item.method ?? item.layer_status ?? item.note ?? item.layer ?? '')} |`);
    }
    lines.push('');
    for (const item of items) links(`${path.basename(item.path)} references`, [item.source_path, item.review_path, item.evidence_path, item.palette_path].filter(Boolean));
  }
  for (const family of catalogue.families) {
    const legacyLink = family.current_availability.art_path ? `[South reference only](#legacy-${family.id})` : 'None recorded';
    lines.push(`| [${md(family.display_name)}](#${family.id}) | ${family.priority} | ${family.base_vs_decor === 'decor' ? `Kit → ${family.primary_host}` : 'Base'} | ${family.variants.map(variantLabel).join(' | ')} | ${legacyLink} |`);
  }
  lines.push('', '## Existing legacy references — not new approvals', '',
    'These seven source registrations are separate from the new N/E/S/W status columns. Atlas previews show complete source sheets, not invented cropped final sprites.', '');
  for (const family of catalogue.families.filter(f => f.current_availability.art_path)) {
    const old = family.current_availability, target = localPath(old.art_path);
    lines.push(`<a id="legacy-${family.id}"></a>`, '', `### ${family.display_name} — legacy south only`, '',
      `${old.measured_texture_size_px.join('×')} historical texture${old.atlas_cell_px ? `; ${old.atlas_cell_px.join('×')} atlas cell${old.atlas_row !== null ? `, row ${old.atlas_row}` : ''}` : ''}. ${family.current_runtime_registration ? 'Retired as the active rendering source; approved current profiles are listed separately below.' : 'New directional approval: **not established**.'}`, '',
      `[![${family.display_name}: legacy source, not a new approved facing](${linkPath(target)})](${linkPath(target)})`, '');
  }
  lines.push('## Family briefs and production outputs', '');
  for (const family of catalogue.families) {
    const geometry = family.native_geometry;
    lines.push(`<a id="${family.id}"></a>`, '', `### ${family.display_name}`, '',
      `${code(family.id)} · ${family.priority} · ${family.role_tags.map(md).join(', ')}.`, '',
      `Direction semantics: **${md(family.direction_semantics.replaceAll('_', ' '))}**.${family.direction_semantics === 'service_side' ? ' Service N/E/S/W uses approach gaze S/W/N/E; this is not workstation-facing.' : ''}`, '',
      md(family.design_brief), '',
      `${geometry.status === 'measured_dev_contract_not_runtime_admission' ? 'Measured dev envelope (not runtime admission)' : 'Proposed envelope'} **${geometry.canvas_size_px.join('×')}**, fixed floor anchor **[${geometry.floor_anchor_px.join(', ')}]**. N/E footprints: **${family.variants[0].footprint_cells.join('×')} / ${family.variants[1].footprint_cells.join('×')} cells**.${family.primary_host ? ` Primary host: ${code(family.primary_host)}; no extra floor collision.` : ''}`, '',
      `Tools: ${family.role_tools.map(md).join('; ')}. Layers: ${family.layers.map(layer => `${code(layer.id)}${layer.required ? '' : ' (optional)'}`).join(', ')}.`, '');
    if (family.construction) {
      const provenance = [family.construction.note ?? family.construction.method, family.passive_direction_note]
        .filter(value => typeof value === 'string' && value.trim()).map(value => md(value).trim()).join(' ');
      lines.push(`Code-native provenance: ${provenance || 'See the linked construction sources and review.'}`, '');
      links('Measured contract / geometry / review', [geometry.contract_path, family.construction.geometry_path,
        family.construction.geometry_source_path, family.construction.export_manifest_path,
        family.construction.review_path, family.construction.evidence_path, family.construction.canonical_review_path].filter(Boolean));
      if (family.construction.equivalent_pairs) lines.push(`Declared physical symmetry: ${family.construction.equivalent_pairs.map(pair => pair.join(' = ')).join('; ')}. Four named exports, ${family.construction.distinct_projected_shapes} projected shapes, ${family.construction.generated_originals} generated material/front original; no actor gaze or service.`, '');
      for (const history of family.geometry_history ?? []) lines.push(`Historical ${history.checkpoint_utc} envelope: ${history.native_geometry.canvas_size_px.join('×')} / pivot [${history.native_geometry.floor_anchor_px.join(', ')}], rise ${history.native_geometry.estimated_max_rise_above_occupied_floor_px}px. ${md(history.note)}`, '');
    }
    let outputs = 0;
    for (const variant of family.variants) {
      const target = variant.approved_art_path ?? variant.preview_path ?? variant.native_exports?.[0]?.path ?? variant.native_export_path ?? variant.output_path ?? variant.generated_source_path;
      const budget = variant.generation_budget ?? variant.source_batch;
      if (budget) lines.push(`**${variant.facing} retained batch:** ${budget.initial_calls} initial + ${budget.targeted_retries_included ?? budget.targeted_retries} targeted retries, limit ${budget.max_targeted_retries ?? budget.retry_limit}; **${budget.exhausted ? 'exhausted' : 'not exhausted at this checkpoint'}**. ${md(budget.note ?? 'Original request history is not reset by reclassification.')}`, '');
      if (!target) {
        if (variant.reason) lines.push(`**${variant.facing}: ${md(variant.status.replaceAll('_', ' '))}; correct view missing.** ${md(variant.reason)}`, '');
        if (variant.review_path) links('Missing-view diagnosis', [variant.review_path]);
        if (variant.source_attempts?.length) {
          links('Retained failed/misdirected sources — not this facing’s deliverable', variant.source_attempts.map(attempt => attempt.source_path));
          links('Original attempt prompts', variant.source_attempts.map(attempt => attempt.prompt_path));
        }
        continue;
      }
      outputs += 1;
      const absolute = localPath(target);
      lines.push(`**${variant.facing}: ${variant.status.replaceAll('_', ' ')}.**${variant.reason ? ` ${md(variant.reason)}` : ''}`, '',
        `[![${family.display_name} ${variant.facing} — ${variant.status}](${linkPath(absolute)})](${linkPath(absolute)})`, '');
      links('Source / prompt', [variant.generated_source_path, variant.source_reference_path, variant.output_path, variant.prompt_path].filter(Boolean));
      links('Review', [variant.review_path, ...(variant.review_paths ?? [])].filter(Boolean));
      links('Native evidence', [variant.evidence_path, ...(variant.evidence_paths ?? [])].filter(Boolean));
      if (variant.export_method) lines.push(`Export method: ${md(variant.export_method)}`, '');
      exportTable('Declared native layers (not automatically approved)', variant.native_exports);
      exportTable('Installed runtime layers — explicit integration evidence required', variant.runtime_exports);
      links('Runtime whole reference / integration evidence', [variant.runtime_art_path, variant.runtime_evidence_path].filter(Boolean));
      exportTable('Independent components and material inserts — not approved assembly masks', variant.component_exports);
      exportTable('Additional composites', variant.composite_exports);
      if (variant.native_export_path) links('Retained native composite / source candidate', [variant.native_export_path]);
      if (variant.reclassification) lines.push(`Direction provenance: **${md(variant.reclassification.note)}**`, '');
      exportTable('Alternative normalization — not a new source generation or directional slot', variant.normalization_alternatives);
      exportTable('Later generated-source candidates — same directional slot, not approved replacements', variant.candidate_alternatives);
      for (const alternative of variant.candidate_alternatives ?? []) {
        exportTable(`${alternative.id}: registered independent components`, alternative.component_exports);
      }
      if (variant.source_attempts?.length) {
        lines.push('**Retained source attempts**', '', '| Source | Actual master | Prompt | Disposition |', '| --- | --- | --- | --- |');
        for (const attempt of variant.source_attempts) {
          lines.push(`| ${fileLink(path.basename(attempt.source_path), attempt.source_path)} | ${attempt.size_px.join('×')} ${md(attempt.channels)}; ${md(attempt.alpha)} | ${fileLink(path.basename(attempt.prompt_path), attempt.prompt_path)} | ${md(attempt.disposition)} |`);
        }
        lines.push('');
      }
    }
    if (!outputs) lines.push('N/E/S/W: no new output recorded. See the status index above; any legacy south reference remains separate.', '');
  }
  if (catalogue.supporting_assets?.length) {
    lines.push('## Supporting assets — outside the 168 directional slots', '',
      'Surface fills are intentionally opaque; character cutouts still require genuine alpha. Alternate normalization and common-view reuse are not new source generations, furniture families, approved layers or runtime integrations.', '');
    for (const material of catalogue.supporting_assets) {
      lines.push(`### ${md(material.id)}`, '', `${md(material.status.replaceAll('_', ' '))}. ${md(material.approval)}`, '');
      links('Source / prompt / review', [material.source_path, material.prompt_path, material.review_path].filter(Boolean));
      const masterSize = material.source_size_px ?? material.size_px;
      if (masterSize) lines.push(`Master: ${masterSize.join('×')} ${md(material.source_channels ?? material.channels)}. ${md(material.source_alpha ?? material.alpha)}`, '');
      else lines.push('Code-native derivative study; no additional generated master. Source/material provenance is retained in the linked review.', '');
      exportTable('Native exports — retain the stated review limits', material.exports);
      exportTable('Preserved-source alternatives — not new generations', material.normalization_alternatives);
      if (material.source_attempts?.length) {
        links('All retained masters', material.source_attempts.map(attempt => attempt.source_path));
        links('All original prompts', material.source_attempts.map(attempt => attempt.prompt_path));
        const budget = material.generation_budget;
        if (budget) lines.push(`Retained batch: ${budget.initial_calls} initial + ${budget.targeted_retries_included} targeted retries; limit ${budget.max_targeted_retries}; ${budget.exhausted ? 'exhausted' : 'not exhausted'}.`, '');
      }
      links('Comparison evidence', [material.evidence_path, material.repeat_evidence_path].filter(Boolean));
      if (material.reused_common_facings?.length) {
        lines.push('**Common archive views reused unchanged — not new role drawings**', '',
          '| Service side / approach gaze | Existing whole and layer references |', '| --- | --- |');
        for (const view of material.reused_common_facings) lines.push(
          `| ${md(view.service_side)} / ${md(view.approach_gaze)} | ${[view.path, ...view.render_layer_paths]
            .map(target => fileLink(path.basename(target), target)).join(' · ')} |`);
        lines.push('');
      }
    }
  }
  if (catalogue.calibration_studies?.length) {
    lines.push('## Supported assembly and mechanism evidence — not art approval', '');
    for (const study of catalogue.calibration_studies) {
      lines.push(`**${md(study.id)}.** ${md(study.note)}`, '');
      links('Review / source / native evidence', [study.review_path, study.source_path, study.evidence_path].filter(Boolean));
      exportTable('Study-only exports — do not complete the parent furniture family', study.exports);
    }
  }
  if (catalogue.source_inventory) {
    lines.push('## Complete retained master inventory', '',
      `${catalogue.source_inventory.original_png_count} original PNGs, measured at ${catalogue.source_inventory.checkpoint_utc}. Exact SHA-256 values live in furniture.json and are validated. Exports, palette variants and code-native renders do not count as original generations.`, '',
      '| Original | Actual dimensions / channels | Alpha fact | Original prompt |', '| --- | --- | --- | --- |');
    for (const item of catalogue.source_inventory.items) lines.push(`| ${fileLink(path.basename(item.source_path), item.source_path)} | ${item.size_px.join('×')} ${md(item.channels)} | ${md(item.alpha)} | ${fileLink(path.basename(item.prompt_path), item.prompt_path)} |`);
    lines.push('');
  }
  lines.push('## Verification boundary', '',
    'The validator checks structure, real paths, source hashes, PNG dimensions and declared review prerequisites. New explicitly measured exports also validate decoded RGBA hashes, alpha, ink bounds and palette counts. These mechanical facts do not prove perspective or visual quality; native in-game review and placement tests remain required in [README.md](README.md).', '');
  return lines.join('\n');
}

function selfTest(catalogue) {
  let passed = 0;
  // Some historical catalogue checkpoints promoted every direction before
  // normalizing the family-level layer rollup. Build an explicit positive
  // fixture in memory so the regression below proves the new invariant rather
  // than depending on the order in which a shared catalogue patch lands.
  const normalizedAccepted = structuredClone(catalogue);
  for (const family of normalizedAccepted.families) {
    if (!APPROVED.has(family.production_status)) continue;
    for (const layer of family.layers) {
      if (layer.required === true) layer.status = family.production_status;
    }
  }
  // Reset lifecycle fields only in memory, so regression cases still work after
  // real production advances the on-disk catalogue beyond its initial draft.
  const baseline = structuredClone(normalizedAccepted);
  baseline.summary.approved_directional_deliverables = 0;
  for (const family of baseline.families) {
    family.production_status = 'planned';
    delete family.current_runtime_registration;
    delete family.art_library_approval;
    for (const variant of family.variants) {
      for (const key of ['output_path', 'generated_source_path', 'native_exports', 'runtime_exports',
        'native_export_path', 'runtime_art_path', 'runtime_evidence_path', 'review', 'reason', 'preview_path',
        'component_exports', 'composite_exports', 'normalization_alternatives', 'candidate_alternatives']) delete variant[key];
      Object.assign(variant, {status: 'planned', deliverable_availability: 'missing',
        approved_art_path: null, evidence_path: null});
    }
  }
  const check = (name, mutate, shouldPass) => {
    const fixture = structuredClone(baseline);
    mutate(fixture);
    const result = validateCatalogue(fixture);
    assert.equal(result.ok, shouldPass, `${name}: ${result.errors.join('; ')}`);
    passed += 1;
  };
  check('current catalogue', () => {}, true);
  {
    const result = validateCatalogue(normalizedAccepted);
    assert.equal(result.ok, true, `normalized accepted-layer fixture: ${result.errors.join('; ')}`);
    passed += 1;
  }
  for (const familyId of ['broadleaf_planter', 'creative_design_kit']) {
    const fixture = structuredClone(normalizedAccepted);
    const family = fixture.families.find(item => item.id === familyId);
    assert.ok(family?.production_status === 'approved', `${familyId}: approved-layer regression fixture is unavailable`);
    family.layers.find(layer => layer.required).status = 'native_review_required';
    const result = validateCatalogue(fixture);
    assert.equal(result.ok, false, `${familyId}: stale required layer rollup was accepted`);
    assert(result.errors.some(error => error.includes(`${familyId}: approved family requires matching required layer rollups`)),
      `${familyId}: missing targeted required-layer rejection: ${result.errors.join('; ')}`);
    passed += 1;
  }
  {
    const fixture = structuredClone(normalizedAccepted);
    const family = fixture.families.find(item => item.id === 'desk');
    assert.ok(family?.production_status === 'runtime_integrated', 'desk: runtime-layer regression fixture is unavailable');
    family.layers.find(layer => layer.required).status = 'approved';
    const result = validateCatalogue(fixture);
    assert.equal(result.ok, false, 'desk: passive layer status was accepted for a runtime-integrated family');
    assert(result.errors.some(error => error.includes('desk: runtime_integrated family requires matching required layer rollups')),
      `desk: missing targeted runtime-layer rejection: ${result.errors.join('; ')}`);
    passed += 1;
  }
  {
    const fixture = structuredClone(normalizedAccepted);
    const family = fixture.families.find(item => item.id === 'mobile_whiteboard');
    const optional = family?.layers.find(layer => layer.required === false);
    assert.ok(optional, 'mobile_whiteboard: optional-layer regression fixture is unavailable');
    optional.status = 'planned';
    const result = validateCatalogue(fixture);
    assert.equal(result.ok, true, `optional future layer must not block passive approval: ${result.errors.join('; ')}`);
    passed += 1;
  }
  const serviceVariant = c => c.families.find(f => f.id === 'coffee_station').variants[0];
  check('service side must not mean operator gaze', c => { serviceVariant(c).approach_gaze = 'north'; }, false);
  check('service gaze vector must be opposite', c => { serviceVariant(c).employee_look_vector = [0, -1]; }, false);
  check('service approach must remain on declared side', c => { serviceVariant(c).proposed_interaction_cell = [0, 1]; }, false);
  check('legacy South service interaction is preserved', c => {
    c.families.find(f => f.id === 'coffee_station').variants[2].proposed_interaction_cell = [0, -1];
  }, false);
  check('legacy service masks cannot be silently reindexed again', c => {
    c.families.find(f => f.id === 'approval_console').variants[2].proposed_occupied_cell_offsets[0] = [4, 4];
  }, false);
  check('service mapping absent from workstation', c => { c.families[0].variants[0].service_side = 'north'; }, false);
  check('every family labels direction meaning', c => { delete c.families[0].direction_semantics; }, false);
  const divider = c => c.families.find(f => f.id === 'acoustic_divider');
  check('passive symmetry cannot invent four drawings', c => { divider(c).construction.generated_complete_views = true; }, false);
  check('passive direction has no employee gaze', c => { divider(c).variants[0].employee_look_vector = [0, -1]; }, false);
  check('passive direction has no interaction point', c => { divider(c).variants[0].proposed_interaction_cell = [0, 1]; }, false);
  check('symmetric projection must declare both pairs', c => { divider(c).construction.equivalent_pairs.pop(); }, false);
  check('symmetric slots retain explicit equivalence', c => { divider(c).variants[0].symmetry_equivalent_to = 'east'; }, false);
  check('symmetry study does not imply production', c => { divider(c).construction.runtime_approved = true; }, false);
  // Exercise the real approved library bundle, not a flag-only empty study.
  if (divider(normalizedAccepted).art_library_approval) {
    const checkLibrary = (name, mutate, expectedError = null) => {
      const fixture = structuredClone(normalizedAccepted);
      mutate(divider(fixture));
      const result = validateCatalogue(fixture);
      assert.equal(result.ok, expectedError === null, `${name}: ${result.errors.join('; ')}`);
      if (expectedError) assert(result.errors.some(error => error.includes(expectedError)),
        `${name}: expected targeted rejection '${expectedError}', got ${result.errors.join('; ')}`);
      passed += 1;
    };
    checkLibrary('exact passive symmetric art may be approved without runtime', () => {});
    checkLibrary('symmetric library requires explicit scope', f => { delete f.art_library_approval; }, 'symmetric passive approval');
    checkLibrary('symmetric library scope cannot be misspelled', f => { f.art_library_approval.scope = 'passive'; }, 'explicit dated scope');
    checkLibrary('library approval requires a date', f => { delete f.art_library_approval.acceptance_date; }, 'explicit dated scope');
    checkLibrary('library review must exist', f => { f.art_library_approval.review_path = 'dev/art-catalogue/nonexistent-passive-review.md'; }, 'passive-library review');
    checkLibrary('library cannot admit runtime', f => { f.art_library_approval.runtime_admission = true; }, 'explicit dated scope');
    checkLibrary('library cannot flip construction readiness', f => { f.construction.runtime_approved = true; }, 'symmetric passive approval');
    checkLibrary('library cannot set whole runtime path', f => { f.variants[0].runtime_art_path = f.variants[0].approved_art_path; }, 'cannot declare runtime bindings');
    checkLibrary('library cannot set runtime exports', f => { f.variants[0].runtime_exports = structuredClone(f.variants[0].native_exports); }, 'cannot declare runtime bindings');
    checkLibrary('library cannot set runtime registration', f => { f.current_runtime_registration = {}; }, 'cannot declare runtime bindings');
    checkLibrary('library cannot invent a service', f => { f.variants[0].service_side = 'north'; }, 'fabricated service front');
    checkLibrary('library cannot invent an interaction', f => { f.variants[0].proposed_interaction_cell = [0, 2]; }, 'fabricate actor gaze');
    checkLibrary('library cannot invent actor gaze', f => { f.variants[0].employee_look_vector = [0, -1]; }, 'fabricate actor gaze');
    checkLibrary('library cannot imply a seated pose', f => { f.variants[0].seated_pose_needed = true; }, 'fabricate actor gaze');
    checkLibrary('library requires all native layers', f => { f.variants[0].native_exports.pop(); }, 'missing required native layer');
    checkLibrary('library rejects a failing visual category', f => { f.variants[0].review.scores.pixel_coherence = 1; }, 'approval threshold');
    checkLibrary('library rejects subthreshold mean', f => {
      for (const key of RUBRIC) f.variants[0].review.scores[key] = 2;
    }, 'approval threshold');
    checkLibrary('approved symmetry still requires exact paired pixels', f => {
      f.variants[0].composite_exports[0] = structuredClone(f.variants[1].composite_exports[0]);
    }, 'declared projected symmetry');
  }
  const shelf = c => c.families.find(f => f.id === 'low_bookshelf');
  check('passive shelf cannot invent a service', c => { shelf(c).direction_semantics = 'service_side'; }, false);
  check('shelf front and back are not symmetric', c => { shelf(c).construction.distinct_projected_shapes = 2; }, false);
  check('measured fit cannot claim requested aspect success', c => { c.supporting_assets.find(a => a.id === 'low-bookshelf-south-measured-fit').strict_target_rejected = false; }, false);
  check('measured fit cannot stretch to requested width', c => { c.supporting_assets.find(a => a.id === 'low-bookshelf-south-measured-fit').measured_native_size_px = [88, 24]; }, false);
  check('measured fit cannot crop source', c => { c.supporting_assets.find(a => a.id === 'low-bookshelf-south-measured-fit').source_crop_applied = true; }, false);
  {
    const changed = structuredClone(normalizedAccepted);
    const family = divider(changed);
    family.variants[0].composite_exports[0] = structuredClone(family.variants[1].composite_exports[0]);
    assert.equal(validateCatalogue(changed).ok, false, 'Declared symmetry rejects different real native projection');
    passed += 1;
  }
  check('missing view cannot hide a native preview', c => {
    c.families[0].variants[0].preview_path = catalogue.families[0].preview_path
      ?? catalogue.families[0].variants[0].preview_path;
  }, false);
  check('missing view cannot claim detached native components', c => {
    const legal = catalogue.families.find(f => f.id === 'lawyer_contract_kit').variants[0];
    // Completed layers may replace the old isolated component list. Keep this
    // negative fixture nonempty as the real family advances through review.
    const exports = legal.component_exports?.length ? legal.component_exports : legal.native_exports;
    assert.ok(exports?.length, 'missing-view regression needs a real declared native component');
    c.families.find(f => f.id === 'lawyer_contract_kit').variants[0].component_exports = structuredClone(exports);
  }, false);
  check('retained source hashes cannot go stale', c => {
    c.families.find(f => f.id === 'lawyer_contract_kit').variants[1].source_attempts[0].sha256 = '0'.repeat(64);
  }, false);
  check('retained master dimensions are measured', c => {
    serviceVariant(c).source_attempts[0].size_px = [1, 1];
  }, false);
  check('exhausted coffee batch cannot be silently reopened', c => {
    c.families.find(f => f.id === 'coffee_station').variants[2].generation_budget.exhausted = false;
  }, false);
  check('completed request count must match retained source history', c => {
    serviceVariant(c).generation_budget.targeted_retries_included = 0;
  }, false);
  check('uncompleted attempts cannot be called exhausted', c => {
    serviceVariant(c).generation_budget.exhausted = true;
  }, false);
  check('targeted retry limit cannot expand', c => {
    serviceVariant(c).generation_budget.max_targeted_retries = 4;
  }, false);
  check('reclassification cannot reopen exhausted legal request', c => {
    c.families.find(f => f.id === 'lawyer_contract_kit').variants[1].source_batch.exhausted = false;
  }, false);
  check('original inventory count stays exact', c => { c.source_inventory.original_png_count += 1; }, false);
  check('duplicate master is not a new generation', c => {
    c.source_inventory.items.push(c.source_inventory.items[0]); c.source_inventory.original_png_count += 1;
  }, false);
  check('native export cannot be counted as a source master', c => {
    c.source_inventory.items[0].source_path = c.families[0].current_availability.art_path;
  }, false);
  check('portrait opaque retry still belongs to original batch', c => {
    c.supporting_assets.find(a => a.id === 'lawyer-portrait').generation_budget.targeted_retries_included = 0;
  }, false);
  check('exhausted side coffee cannot reopen', c => {
    c.families.find(f => f.id === 'coffee_station').variants[1].generation_budget.exhausted = false;
  }, false);
  const support = (c, id) => c.supporting_assets.find(item => item.id === id);
  check('failed mount request cannot reopen exhausted alpha retries', c => {
    support(c, 'mina-north-mount').generation_budget.exhausted = false;
  }, false);
  check('failed mount cannot invent native export', c => {
    support(c, 'mina-north-mount').exports.push(support(c, 'legal-storage-front').exports[0]);
  }, false);
  check('role reuse is not three newly drawn directions', c => {
    support(c, 'legal-storage-front').reused_common_facings[0].is_new_drawing = true;
  }, false);
  check('role variants retain only South original drawing', c => {
    support(c, 'legal-storage-front').source_drawing_facings.push('north');
  }, false);
  check('role decor cannot enable runtime service', c => {
    support(c, 'creative-storage-front').role_service_enabled = true;
  }, false);
  check('role service side is distinct from approach gaze', c => {
    support(c, 'creative-storage-front').reused_common_facings[0].approach_gaze = 'north';
  }, false);
  check('role reuse cannot replace common layer silently', c => {
    support(c, 'creative-storage-front').reused_common_facings[0].render_layer_paths.pop();
  }, false);
  check('zero edge difference does not approve visually failed floor', c => {
    support(c, 'cream-terrazzo-floor-v2').runtime_approved = true;
  }, false);
  check('unified-base floor cannot overclaim visual approval', c => {
    support(c, 'cream-terrazzo-floor-v3').runtime_approved = true;
  }, false);
  check('native alpha counts are decoded, not asserted', c => {
    support(c, 'pedestal-south-front').exports[0].opaque_pixels--;
  }, false);
  check('native ink bounds are decoded', c => {
    support(c, 'engineer-portrait').exports[0].opaque_bounds_px[2]--;
  }, false);
  check('native palette counts are decoded', c => {
    support(c, 'finance-portrait').exports[0].used_colors++;
  }, false);
  check('native RGBA hash is decoded', c => {
    support(c, 'customer-support-portrait').exports[0].decoded_rgba_sha256 = '0'.repeat(64);
  }, false);
  check('code-native views are not four generated originals', c => {
    c.families.find(f => f.id === 'mobile_whiteboard').construction.generated_complete_views = true;
  }, false);
  check('measured geometry retains prior proposal', c => {
    c.families.find(f => f.id === 'rolling_storage_pedestal').geometry_history = [];
  }, false);
  check('art-study endorsement is not runtime admission', c => {
    c.families.find(f => f.id === 'rolling_storage_pedestal').construction.runtime_approved = true;
  }, false);
  for (const [label, change] of [
    ['stale runtime directions', f => { f.current_runtime_registration.registered_facings = ['south']; }],
    ['runtime service gaze drift', f => { f.current_runtime_registration.profiles.north.approach_gaze = 'north'; }],
    ['missing installed layer', f => { f.variants[0].runtime_exports.pop(); }],
    ['runtime whole reference must match reviewed side', f => { f.variants[0].runtime_art_path = f.variants[2].runtime_art_path; }],
    ['approval cannot invent a required shadow', f => { f.layers.find(l => l.id === 'floor_shadow').required = true; }],
    ['legacy South evidence remains historical', f => { f.variants[0].legacy_runtime_art_for_this_facing = true; }],
  ]) {
    const fixture = structuredClone(normalizedAccepted);
    change(fixture.families.find(f => f.id === 'artifact_archive'));
    assert.equal(validateCatalogue(fixture).ok, false, label); passed += 1;
  }
  for (const status of ['generated_unreviewed', 'cleanup_required', 'concept_only', 'rejected']) {
    check(`accept ${status}`, c => {
      Object.assign(c.families[0].variants[0], {status, deliverable_availability: 'generated',
        output_path: c.families[0].current_availability.art_path, reason: 'In-memory validation fixture only.'});
    }, true);
  }
  check('blocked missing', c => Object.assign(c.families[0].variants[0], {status: 'blocked', reason: 'Waiting for generation'}), true);
  check('duplicate direction', c => { c.families[0].variants[1].facing = 'north'; }, false);
  check('invalid status', c => { c.families[0].variants[0].status = 'looks_great'; }, false);
  check('false approval while missing', c => { c.families[0].variants[0].approved_art_path = c.families[0].current_availability.art_path; }, false);
  check('missing actual output', c => Object.assign(c.families[0].variants[0], {status: 'generated_unreviewed', deliverable_availability: 'generated', output_path: 'dev/art-catalogue/this-file-must-not-exist.png'}), false);
  check('anchor outside canvas', c => { c.families[0].native_geometry.floor_anchor_px = [9999, 9999]; }, false);
  check('direction anchor drift', c => { c.families[0].variants[0].native_geometry = {canvas_size_px: [192, 224], floor_anchor_px: [95, 160]}; }, false);
  check('mask drift', c => { c.families[0].variants[1].proposed_occupied_cell_offsets[0] = [99, 99]; }, false);
  check('duplicate mask cell', c => { c.families[0].variants[0].proposed_occupied_cell_offsets.push([0, 0]); }, false);
  check('host mismatch', c => { c.families.find(f => f.base_vs_decor === 'decor').native_geometry.floor_anchor_px[0] -= 1; }, false);
  check('stale approval summary', c => { c.summary.approved_directional_deliverables = 1; }, false);
  check('legacy cell is not new native envelope', c => Object.assign(c.families[0].variants[0], {
    status: 'native_review_required', deliverable_availability: 'native_export',
    native_exports: [{layer: 'rear_structure', path: c.families[0].current_availability.art_path,
      canvas_size_px: [192, 224], floor_anchor_px: [96, 160]}],
  }), false);
  check('unreviewed runtime export', c => Object.assign(c.families[0].variants[0], {
    status: 'generated_unreviewed', deliverable_availability: 'generated', output_path: c.families[0].current_availability.art_path,
    runtime_art_path: c.families[0].current_availability.art_path,
  }), false);
  // Accepted-state prerequisites are exercised with an explicit in-memory file
  // adapter. These virtual test exports never exist in the gallery or on disk.
  const acceptedFixture = status => {
    const c = structuredClone(baseline), family = c.families[0], variant = family.variants[0];
    const exports = family.layers.filter(layer => layer.required).map(layer => ({layer: layer.id,
      path: `dev/art-catalogue/__self_test__/${layer.id}.png`,
      canvas_size_px: family.native_geometry.canvas_size_px,
      floor_anchor_px: family.native_geometry.floor_anchor_px}));
    Object.assign(variant, {status, deliverable_availability: 'native_export', native_exports: exports});
    const virtual = new Map(exports.map(item => [item.path, item.canvas_size_px]));
    if (APPROVED.has(status)) {
      Object.assign(variant, {approved_art_path: exports[0].path,
        evidence_path: 'dev/art-catalogue/__self_test__/native-review.png',
        review: {geometry_reviewed: true, placement_tests_passed: true, actor_pose_reviewed: true,
          scores: Object.fromEntries(RUBRIC.map(key => [key, 3]))}});
      virtual.set(variant.evidence_path, [1280, 720]);
      c.summary.approved_directional_deliverables = 1;
    }
    if (status === 'runtime_integrated') {
      variant.runtime_exports = exports;
      variant.runtime_art_path = exports[0].path;
      variant.runtime_evidence_path = variant.evidence_path;
    }
    const real = realFiles();
    const files = {file: value => virtual.has(value) ? localPath(value) : real.file(value),
      png: value => virtual.get(value) ?? real.png(value)};
    return {c, files, variant};
  };
  for (const status of ['native_review_required', 'approved', 'runtime_integrated']) {
    const fixture = acceptedFixture(status), result = validateCatalogue(fixture.c, fixture.files);
    assert.equal(result.ok, true, `${status}: ${result.errors.join('; ')}`); passed += 1;
  }
  for (const change of [variant => { variant.review.geometry_reviewed = false; },
    variant => { variant.review.actor_pose_reviewed = false; },
    variant => { variant.review.scores.perspective = 1; },
    variant => { variant.evidence_path = null; },
    variant => { variant.native_exports[0].floor_anchor_px = [0, 0]; }]) {
    const fixture = acceptedFixture('approved'); change(fixture.variant);
    assert.equal(validateCatalogue(fixture.c, fixture.files).ok, false); passed += 1;
  }
  const header = Buffer.alloc(33);
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]).copy(header);
  header.writeUInt32BE(13, 8); header.write('IHDR', 12); header.writeUInt32BE(192, 16); header.writeUInt32BE(224, 20);
  assert.deepEqual(parsePngHeader(header), [192, 224]); passed += 1;
  assert.throws(() => parsePngHeader(header.subarray(0, 24))); passed += 1;
  assert.throws(() => parsePngHeader(Buffer.alloc(33))); passed += 1;
  return passed;
}

function main(args) {
  let cataloguePath = DEFAULT_CATALOGUE, writeGallery = false, checkGallery = false, runSelfTest = false;
  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '--write-gallery') writeGallery = true;
    else if (args[i] === '--check-gallery') checkGallery = true;
    else if (args[i] === '--self-test') runSelfTest = true;
    else if (args[i] === '--catalogue' && args[i + 1]) cataloguePath = path.resolve(args[++i]);
    else if (args[i] === '--help') {
      console.log('node dev/tools/validate_art_catalogue.mjs [--catalogue file] [--self-test] [--write-gallery | --check-gallery]'); return;
    } else throw new Error(`Unknown or incomplete argument: ${args[i]}`);
  }
  if (writeGallery && (cataloguePath !== DEFAULT_CATALOGUE || checkGallery)) throw new Error('Gallery writes require the default catalogue and cannot be combined with --check-gallery');
  const bytes = fs.readFileSync(cataloguePath);
  const catalogue = JSON.parse(bytes.toString('utf8'));
  const result = validateCatalogue(catalogue);
  if (!result.ok) { console.error(JSON.stringify(result, null, 2)); process.exitCode = 1; return; }
  if (runSelfTest) result.selfTests = selfTest(catalogue);
  if (writeGallery || checkGallery) {
    const rendered = galleryMarkdown(catalogue, result, bytes);
    if (writeGallery) { fs.writeFileSync(GALLERY, rendered); result.gallery = 'written'; }
    else {
      assert.equal(fs.readFileSync(GALLERY, 'utf8'), rendered, 'Gallery is stale; rerun with --write-gallery');
      result.gallery = 'current';
    }
  }
  console.log(JSON.stringify(result, null, 2));
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(`Art catalogue validation failed: ${error.message}`); process.exitCode = 1; }
}
