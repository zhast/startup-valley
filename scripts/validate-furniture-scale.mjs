import fs from 'node:fs';
import { ROOT, localFile, sha256 } from './lib/art-reference.mjs';
import { nativePngFacts, parsePngHeader } from '../dev/tools/validate_art_catalogue.mjs';

export const SCALE_CONTRACT = 'dev/art-catalogue/furniture-scale-contracts.json';
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);

/** Enforces a reviewed registration and declared anthropometric landmarks.
 * Pixels can still be ugly or mislabeled; actual Godot visual admission remains
 * separate. Never infer art approval from these mechanical checks. */
export function validateFurnitureScale({ root = ROOT, contract } = {}) {
  const errors = [];
  const check = (ok, message) => { if (!ok) errors.push(message); };
  const read = p => fs.readFileSync(localFile(root, p));
  const bound = record => check(record && sha256(read(record.path)) === record.sha256, `Scale reference changed: ${record?.path}`);
  try {
    contract ??= JSON.parse(read(SCALE_CONTRACT));
    check(contract.schema_version === 1 && contract.grid_px === 32 && contract.runtime_scale === 1 && contract.camera_profile === 'office-square-grid-v1', 'Scale contract must retain the native32px camera');
    check(contract.calibration?.kind === 'godot_same_scale', 'Scale calibration must be an actual Godot same-scale capture');
    bound(contract.calibration); bound(contract.calibration.report);
    const report = JSON.parse(read(contract.calibration.report.path));
    check(report.engine?.major === 4 && Array.isArray(report.failures) && report.failures.length === 0 && report.checks > 0, 'Scale calibration needs passing actual-engine evidence');
    check(contract.actor_references?.length >= 2, 'Scale calibration needs established character references');
    for (const actor of contract.actor_references ?? []) bound(actor);
    const ids = new Set();
    const range = (value, name, kind) => {
      const limits = contract.ranges?.[name];
      check(Number.isFinite(value) && Array.isArray(limits) && value >= limits[0] && value <= limits[1], `${kind}: ${name} outside shared range`);
    };
    for (const family of contract.families ?? []) {
      const { kind } = family;
      check(!ids.has(kind), `Duplicate scale family: ${kind}`); ids.add(kind);
      const catalog = JSON.parse(read(family.catalog));
      const profile = catalog.furniture?.[kind]?.facing_profiles?.[family.facing];
      check(profile?.status === 'runtime_ready', `${kind}: registered facing is missing`);
      if (!profile) continue;
      check(sha256(JSON.stringify(profile)) === family.profile_sha256, `${kind}: scale profile changed without review`);
      check(profile.preview_art === `res://${family.art.slice(5)}` && profile.render_layers.length === 1, `${kind}: wrong art or layer count`);
      const layer = profile.render_layers[0];
      const bytes = read(family.art), facts = nativePngFacts(bytes);
      check(sha256(bytes) === family.art_sha256, `${kind}: scale artwork changed without review`);
      check(equal(parsePngHeader(bytes), family.canvas), `${kind}: canvas changed`);
      check(equal(layer.offset, family.canvas.map((n, i) => n / 2 - family.ground_pivot[i])), `${kind}: ground pivot disagrees with sprite offset`);
      check(equal(layer.region, [0, 0, ...family.canvas]), `${kind}: scale/region workaround is not allowed`);
      check(!['scale', 'rotation', 'flip_h', 'flip_v'].some(key => key in layer), `${kind}: runtime transforms are not allowed`);
      check(facts.partial_alpha_pixels === 0 && equal(facts.opaque_bounds_px, layer.content_bounds), `${kind}: painted bounds or binary alpha changed`);
      const ink = facts.opaque_bounds_px;
      check(equal(profile.visual_bounds, [ink[0] - family.ground_pivot[0], ink[1] - family.ground_pivot[1], ink[2], ink[3]]), `${kind}: actual pixels disagree with registered bounds`);
      check(Array.isArray(family.contacts) && family.contacts.length >= 3, `${kind}: declare actual ground contacts`);
      for (const contact of family.contacts ?? []) check(profile.occupied.some(([x, y]) => contact[0] >= x * 32 - 18 && contact[0] <= x * 32 + 18 && contact[1] >= y * 32 - 18 && contact[1] <= y * 32 + 18), `${kind}: ground contact leaves occupied footprint`);
      if (family.seat) {
        const s = family.seat;
        check(s.width >= 28 && s.width <= 32 && s.front_y > s.back_y, `${kind}: usable seat width/plane is invalid`);
        range(s.back_floor_y - s.back_y, 'seat_rise', kind); range(s.front_floor_y - s.front_y, 'seat_rise', kind);
        range(family.back?.floor_y - family.back?.top_y, 'chair_back_rise', kind);
      }
      if (family.tabletop) {
        const s = family.tabletop;
        check(s.width === ink[2] && s.front_y > s.back_y, `${kind}: tabletop plane is invalid`);
        range(s.back_floor_y - s.back_y, 'tabletop_rise', kind); range(s.front_floor_y - s.front_y, 'tabletop_rise', kind);
      }
      if (family.opening) {
        const o = family.opening, [x, y, width, height] = profile.visual_bounds;
        check(o.left >= x && o.left + o.width <= x + width && o.top >= y && o.floor_y <= y + height, `${kind}: doorway leaves painted structure`);
        check(equal(profile.occupied, [[-1, 0], [0, 0]]), `${kind}: two-cell booth footprint is required`);
        range(o.width, 'opening_width', kind); range(o.floor_y - o.top, 'opening_height', kind);
        range(family.structure?.floor_y - family.structure?.top_y, 'booth_front_rise', kind);
      }
    }
    check(ids.size >= 3, 'Scale contract is missing admitted standalone families');
  } catch (error) { errors.push(error.message); }
  return { ok: errors.length === 0, scope: 'reviewed standalone furniture registration and declared landmarks', errors };
}
