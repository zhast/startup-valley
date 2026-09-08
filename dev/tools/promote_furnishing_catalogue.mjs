// Promote only already-reviewed source art with passing production-room evidence.
// This updates dev provenance, not runtime images, worker state or approval scores.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const read = name => JSON.parse(fs.readFileSync(path.join(root, name), 'utf8'));
const file = 'dev/art-catalogue/furniture.json';
const catalogue = read(file);
const runtime = read('game/data/furnishing_catalog.json');
const evidence = read('game/tests/output/furnishing-runtime/manifest.json');
const decorEvidence = read('game/tests/output/furnishing-runtime/decor-manifest.json');
const review = 'dev/art-catalogue/FURNISHING_RUNTIME_REVIEW_20260908.md';
if (evidence.failures.length || evidence.captures.length !== 73 || !evidence.worker_disabled) throw new Error('Full passing native furnishing evidence is required');
if (decorEvidence.failures.length || decorEvidence.captures.length !== 4 || !decorEvidence.worker_disabled) throw new Error('Four-facing native decor evidence is required');
if (!fs.existsSync(path.join(root, review))) throw new Error('Explicit visual review is required');
const selected = [...Object.keys(runtime.furniture), ...Object.keys(runtime.role_kits)];
for (const id of selected) {
  const family = catalogue.families.find(item => item.id === id);
  const role = id in runtime.role_kits;
  const entry = (role ? runtime.role_kits : runtime.furniture)[id];
  if (!family || !['approved', 'runtime_integrated'].includes(family.production_status)) throw new Error(`Unapproved family: ${id}`);
  if (!family.historical_availability_before_furnishing) family.historical_availability_before_furnishing = structuredClone(family.current_availability);
  if (family.art_library_approval) {
    family.historical_art_library_approval = family.art_library_approval;
    delete family.art_library_approval;
  }
  family.production_status = 'runtime_integrated';
  for (const layer of family.layers) if (layer.required) layer.status = 'runtime_integrated';
  family.current_availability = {
    status: 'runtime_furnishing_integrated', runtime_family_id: id,
    runtime_registered_facings: [], current_runtime_facings: entry.facings,
    art_path: entry.facing_profiles.south.preview_art,
    direction_art_review: 'Exact accepted native layers now bound to the worker-owned furnishing inventory. Historical passive approval is retained separately; no pixels were regenerated.',
    production_review_path: review,
  };
  family.gameplay_scope = role
    ? 'Native rear/front role overlays granted once with the existing employee; no new tool authority, employee role, work pose or service is added.'
    : 'One starter inventory copy, place/rotate/store through Renovate with the same validated native geometry. Decoration only; no service action, new economy or employee pose.';
  family.native_geometry.production_registration = 'game/data/furnishing_catalog.json';
  if (family.construction) family.construction.runtime_approved = true;
  for (const variant of family.variants) {
    const profile = entry.facing_profiles[variant.facing];
    if (!variant.historical_reason_before_furnishing) variant.historical_reason_before_furnishing = variant.reason;
    variant.status = 'runtime_integrated';
    variant.deliverable_availability = 'runtime_integrated';
    if (variant.production_status) variant.production_status = 'runtime_integrated';
    variant.runtime_art_path = profile.preview_art.replace(/^res:\/\//, 'game/');
    variant.runtime_evidence_path = role
      ? `game/tests/output/furnishing-runtime/${variant.facing}-${entry.owner_id}-typing.png`
      : `game/tests/output/furnishing-runtime/decor-${variant.facing}.png`;
    variant.runtime_review_path = review;
    variant.reason = 'Accepted exact native artwork integrated through the production furnishing projection, with worker/Godot geometry parity and actual-room lifecycle review. No additional generated pixels or fake service action.';
    variant.runtime_exports = variant.native_exports.map((native, index) => ({
      ...native, path: profile.render_layers[index].art.replace(/^res:\/\//, 'game/'),
      source_path: native.path, method: 'Byte-exact approved native layer copy; shared pivot, authored depth, scale one, no bitmap rotation or mirror.',
    }));
  }
  family.current_runtime_registration = {
    catalogue_path: 'game/data/furnishing_catalog.json', catalogue_section: role ? 'role_kits' : 'furniture',
    runtime_family_id: id, registered_facings: entry.facings, profiles: entry.facing_profiles,
    production_review_path: review, evidence_path: 'game/tests/output/furnishing-runtime/manifest.json',
    ...(role ? { owner_id: entry.owner_id } : {}),
  };
}
const stamp = catalogue.furnishing_checkpoint_utc ?? new Date().toISOString();
if (!catalogue.historical_production_truth_before_furnishing) catalogue.historical_production_truth_before_furnishing = structuredClone(catalogue.current_production_truth);
catalogue.furnishing_checkpoint_utc = stamp;
catalogue.frozen_checkpoint_utc = stamp;
catalogue.current_production_truth.checkpoint_utc = stamp;
catalogue.current_production_truth.furnishing_library = {
  status: 'runtime_integrated', catalogue_path: 'game/data/furnishing_catalog.json',
  furniture_families: Object.keys(runtime.furniture), employee_role_kits: runtime.employee_role_kits,
  native_copies: runtime.source_copies.length, new_directional_runtime_bindings: selected.length * 4,
  production_review_path: review, evidence_path: 'game/tests/output/furnishing-runtime/manifest.json',
  note: 'Only three starter decorations and existing Mina/Theo desk kits are playable. The rest of the accepted library remains unbound. New role/service behavior and economy are out of scope.',
};
catalogue.current_production_truth.renovation = {
  status: 'worker_owned_versioned_layout', persistence: true,
  implementation_path: 'dev/FURNISHING_IMPLEMENTATION.md',
  note: 'The furnishing implementation supersedes the historical session-local Renovate limit. Worker SQLite is authoritative; frontend changes are acknowledged snapshots. End-to-end durability evidence is documented separately from art approval.',
};
for (const key of ['passive_role_library', 'passive_furniture_library']) {
  const group = catalogue.current_production_truth[key];
  group.families = group.families.filter(id => !selected.includes(id));
  group.note = `${group.families.length * 4} accepted library-only directions remain unbound. The five selected furnishing families are recorded separately as current runtime integrations; no future employee/service behavior is implied.`;
}
const observation = catalogue.current_production_truth.active_catalogue_observation;
observation.family_count = 10;
observation.facing_profile_count = 40;
for (const id of Object.keys(runtime.furniture)) observation.facing_profiles[id] = runtime.furniture[id].facings;
catalogue.current_production_truth.supplemental_catalogue_path = 'game/data/furnishing_catalog.json';
catalogue.current_production_truth.reviewed_workstation_base.note = 'The shared workstation remains unchanged. Mina and Theo now receive their accepted role overlays through furnishing inventory; other profession-specific kits remain library-only.';
const current = catalogue.current_production_truth.current_library_review;
current.review_path = review;
current.runtime_integrated_slots = 56;
current.approved_passive_slots = 112;
current.historical_art_completion_regression_path = current.final_regression_path ?? catalogue.historical_production_truth_before_furnishing.current_library_review.final_regression_path;
current.historical_art_completion_headless_path = current.final_headless_results_path ?? catalogue.historical_production_truth_before_furnishing.current_library_review.final_headless_results_path;
delete current.final_regression_path;
delete current.final_headless_results_path;
current.verification_status = 'All168 native catalogue views remain accepted:56 runtime-integrated and112 passive-library directions. The five furnishing integrations have fresh native and geometry-parity evidence. Historical art-completion/browser evidence is preserved; broader furnishing gameplay/restart/UI acceptance is documented in dev/FURNISHING_IMPLEMENTATION.md.';
const bytes = JSON.stringify(catalogue, null, 2) + '\n';
if (process.argv.includes('--write')) fs.writeFileSync(path.join(root, file), bytes);
else if (fs.readFileSync(path.join(root, file), 'utf8') !== bytes) throw new Error('Catalogue furnishing registration is stale; review evidence and run --write');
console.log(`Furnishing catalogue: ${selected.length} families / ${selected.length * 4} runtime views ${process.argv.includes('--write') ? 'registered' : 'verified'}.`);
