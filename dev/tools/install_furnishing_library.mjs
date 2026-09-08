// Exact approved-art promotion only: no raster rendering, resizing or generation.
// --install copies accepted library bytes and writes the canonical registration.
// Default is read-only freshness/hash verification.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const catalogue = JSON.parse(fs.readFileSync(path.join(root, "dev/art-catalogue/furniture.json"), "utf8"));
const selected = ["broadleaf_planter", "task_floor_lamp", "rolling_storage_pedestal", "mina_discovery_kit", "theo_campaign_kit"];
const result = { schema_version: 1, source_catalogue: "dev/art-catalogue/furniture.json", starter_decor: [], employee_role_kits: { mira: "mina_discovery_kit", theo: "theo_campaign_kit" }, role_kits: {}, furniture: {} };
const copies = [];
const hash = bytes => crypto.createHash("sha256").update(bytes).digest("hex");
const normalize = value => value.replace(/^res:\/\//, "game/");
function copyDescriptor(source, destination, expectedHash) {
  source = normalize(source);
  const bytes = fs.readFileSync(path.join(root, source));
  if (expectedHash && hash(bytes) !== expectedHash) throw new Error(`Unreviewed bytes: ${source}`);
  copies.push({ source, destination, sha256: hash(bytes) });
  return "res://" + destination.replace(/^game\//, "");
}
for (const id of selected) {
  const family = catalogue.families.find(item => item.id === id);
  if (!family || !["approved", "runtime_integrated"].includes(family.production_status)) throw new Error(`Family is not approved: ${id}`);
  const role = family.asset_kind === "decor_kit";
  const entry = { display_name: family.display_name, facings: ["north", "east", "south", "west"], facing_profiles: {} };
  if (role) {
    entry.host_kind = "desk";
    entry.owner_id = id === "mina_discovery_kit" ? "mira" : "theo";
  } else {
    entry.interaction_kind = "none";
    result.starter_decor.push({ id: `decor-${id}`, kind: id });
  }
  for (const facing of entry.facings) {
    const variant = family.variants.find(item => item.facing === facing);
    if (!["approved", "runtime_integrated"].includes(variant?.status)) throw new Error(`Facing is not approved: ${id}/${facing}`);
    const native = variant.native_exports;
    if (!native?.length) throw new Error(`No native approved layers: ${id}/${facing}`);
    const layers = [];
    let bounds;
    for (const item of native) {
      const source = normalize(item.path);
      const size = item.canvas_size_px;
      const pivot = item.floor_anchor_px;
      const descriptor = item.render_descriptor ?? {
        name: `${id}_${item.source_layer}`,
        region: [0, 0, ...size], offset: [size[0] / 2 - pivot[0], size[1] / 2 - pivot[1]], z_offset: item.z_offset,
      };
      const art = copyDescriptor(source, `game/assets/runtime/office/furnishing-library/${id}/${path.basename(source)}`, item.sha256);
      const layer = { ...descriptor, art, content_bounds: item.opaque_bounds_px };
      layers.push(layer);
      const [x, y, w, h] = item.opaque_bounds_px;
      if (w && h) {
        const local = [x - pivot[0], y - pivot[1], x - pivot[0] + w, y - pivot[1] + h];
        bounds = bounds ? [Math.min(bounds[0], local[0]), Math.min(bounds[1], local[1]), Math.max(bounds[2], local[2]), Math.max(bounds[3], local[3])] : local;
      }
    }
    const visual = [bounds[0], bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1]];
    const preview = normalize(variant.approved_art_path);
    const profile = {
      status: "runtime_ready", review: { art: true, geometry: true },
      source_review: variant.review_path, preview_art: copyDescriptor(preview, `game/assets/runtime/office/furnishing-library/${id}/${path.basename(preview)}`),
      visual_bounds: visual, render_layers: layers,
    };
    if (!role) Object.assign(profile, {
      profile_kind: "decorative", occupied: variant.proposed_occupied_cell_offsets, clearance: [variant.proposed_interaction_cell],
      anchor_offset: [0, 0], hit_bounds: visual, ambient_overlays: [],
      standing_viewpoints: [{ cell: variant.proposed_interaction_cell, visual_bounds: [-24, -76, 48, 84] }],
    });
    entry.facing_profiles[facing] = profile;
  }
  (role ? result.role_kits : result.furniture)[id] = entry;
}
result.source_copies = copies;
const destination = path.join(root, "game/data/furnishing_catalog.json");
const expected = JSON.stringify(result, null, 2) + "\n";
if (process.argv.includes("--install")) {
  for (const file of copies) {
    const target = path.join(root, file.destination);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(path.join(root, file.source), target);
  }
  fs.writeFileSync(destination, expected);
} else {
  if (fs.readFileSync(destination, "utf8") !== expected) throw new Error("Furnishing registration is stale");
  for (const file of copies) if (hash(fs.readFileSync(path.join(root, file.destination))) !== file.sha256) throw new Error(`Runtime copy drift: ${file.destination}`);
}
console.log(`Furnishing library: ${selected.length} approved families, ${copies.length} exact native copies; ${process.argv.includes("--install") ? "installed" : "verified"}.`);
