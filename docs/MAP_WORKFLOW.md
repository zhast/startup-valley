# Maps from one world

Every Startup Valley map uses the existing
[canonical art profile](../dev/art-catalogue/style-profile.json) and
[reference board](../dev/art-catalogue/style-reference-board.png). The
[world profile](../dev/map-catalogue/world-profile.json) applies that visual
language to places. It does not introduce a competing palette or art catalogue.
Follow [ASSET_WORKFLOW.md](ASSET_WORKFLOW.md) for individual images.

## Shared modules, distinct places

Use a 32px square floor grid, the fixed elevated screen-aligned camera, unit
runtime scale, nearest filtering and upper-left lighting. Repeat the reference
wood, paper, equipment and foliage material ramps. Keep each character's own
palette. A new location changes its silhouette, purpose and arrangement, not
its camera angle, contour weight or pixel density.

Compose places from registered architecture and prop modules. Reuse the
existing furniture catalogue's facing-specific layers, ground pivot, footprint,
clearance and interaction socket. Rotate logical placement only; do not rotate
or resize finished furniture sprites. Keep characters, furniture and scenery
separate. A visible path must either lead to implemented travel or end in an
honest boundary. Give each place a readable arrival point, focal activity,
quiet walking lanes and a safe way home.

The office and courtyard use logical JSON layouts. `VillageTerrain` shares
native 32px grass and paving cells plus registered hedge modules between them.
Its recipe declares every atlas crop, origin and contiguous grass patch; the
runtime creates `TileMapLayer` nodes rather than scaling a room painting.
The modest studio's stone apron meets its actual doorway. Courtyard walkable
geometry, story approach and saved spawn remain explicit and independently
validated. See the retained source and transformation history in
`game/assets/source/modular-yard/`. Do not copy third-party game assets.
Low, wide shrubs form sparse authored `terrain_plantings` groups; they must not
be repeated vertically as disconnected stair-step silhouettes. The map gate
rejects any planted cell on legal walking floor.

## Register and validate a map

1. Add a manifest under `dev/map-catalogue/maps/`. Copy the closest existing
   example. Declare its stable identity, actual source, supported adapter,
   narrow rendering modules and dynamically loaded art. These are development
   admission records; the worker remains authoritative for travel, unlocks,
   save location and inventory.
2. Prefer the existing `office_json` adapter. It reads the actual layout and
   catalogue; do not duplicate its grid in the manifest. `courtyard_json` reads
   actual courtyard data and checks its renderer's spawn/approach constants.
   The historical `courtyard_gd` adapter can read literal navigation geometry.
   A different representation needs an explicit adapter and regression tests.
3. Run `node scripts/validate-maps.mjs --preview`. Preview permits missing
   approval, never invalid geometry/references. Run the existing Godot layout,
   projection and navigation tests and production worker persistence tests too.
4. Capture the actual exported Godot scene in Codex's existing in-app browser.
   Do not launch windowed Godot capture tests. Show a reference character,
   arrival/return, interaction affordances, front/behind crossings, and the
   widest relevant state (hires/expansion if applicable). Record a successful
   engine journey through arrival, interaction, return and save/reload. A
   mockup, contact sheet or generated room illustration is not engine evidence.
5. Generate a **candidate**, never an automatic approval:

   ```sh
   node scripts/validate-maps.mjs --candidate courtyard \
     > dev/map-catalogue/reviews/courtyard.json
   ```

6. Retain a compact PNG/JPEG selection and test report in the repository. Fill the
   candidate's `evidence` with repository-relative paths, exact SHA-256 hashes,
   `kind: godot_frame` or `godot_test_report`, and notes identifying the scenario.
   Current browser frames use `capture_method: in_app_browser_godot` and the
   captured export's `build_id`. Headless route reports use `godot_headless`;
   they prove input, state and navigation, never visual appearance. Historical
   native PNGs retain `godot_engine` and must not be relabeled as current browser
   evidence. A reviewer must inspect those
   images against the shared board, name themselves, supply an ISO review date,
   and assess every listed check with a concrete note. Only then change
   `status` to `approved`. Keep one active approval per map; archive superseded
   records outside `reviews/`.
7. Run `npm run maps:check` (or `node scripts/validate-maps.mjs`). Any changed bound layout, renderer,
   used catalogue family, image, world profile or style reference invalidates
   that approval. Recapture and review affected views; do not just refresh hashes.
   `npm run assets:check` runs this gate too, preserving its `--godot` option.
   Normal `npm run build:web` enforces both image and map admission; the build's
   `build-info.json` records map statuses and signatures in `mapReview`.
   `npm run maps:test` runs the focused admission regressions.

If a module looks wrong, fix its source catalogue asset following the existing
ImageGen/provenance workflow, then validate every affected place. Do not cover a
wrong-angle prop with a map-specific resize, recolour or foreground patch. New
generation must use the retained shared brief, board and relevant adjacent
actor/prop references, with the real prompt and output preserved.

## What the gate guarantees

`validate-maps.mjs` discovers logical map JSON in `game/data/` and navigation
renderers in `game/world/`. Unregistered sources fail. The retired `town.json`
reference is explicitly frozen and may not be loaded by runtime GDScript.
Unsupported adapters, missing/escaping resource paths, unregistered prop
families, unsupported or candidate facings, off-floor/overlapping footprints,
invalid grid/scale, blocked spawns and unreachable exits/story approaches fail.

Map signatures bind manifests, source modules, used catalogue families and
their images, explicit dynamic art, plus the canonical style/board references.
The scope is terrain and prop composition; shared actor rendering, dialogue and
UI are covered by the separate asset and engine suites. The signatures
intentionally exclude unrelated UI/gameplay files. Asset admission still
runs independently: a registered image is not necessarily a newly approved
image, and map approval cannot admit an unreviewed changed PNG.

The one-time `baseline.json` inventory permits the exact three maps present
before this framework. Its status and warnings explicitly say **not visual
approval**. Never add future maps or refresh changed hashes there. Pending
review records are honest placeholders until the final engine captures have
been inspected. The current demo should graduate to reviewed map records after
its final acceptance journey; the baseline remains historical migration data.

These checks cannot judge beauty, verify that a person really reviewed an
image, parse arbitrary dynamic GDScript, prove all live actor routing, or certify
every player-authored furniture arrangement. Review new map-loading patterns,
keep adapter coverage current, and retain the authoritative furnishing and
actual-engine tests. Passing the gate is necessary, not a substitute for seeing
the place and playing the route.

## Review checklist

| Check | Required observation |
| --- | --- |
| Universe | Material ramps, outlines and detail density match the board and neighboring map. |
| Camera/scale | Actor, furniture, doors and paving share the same native scale and projection. |
| Composition | Place has a distinct purpose and readable silhouette; scenery supports its route. |
| Depth | Front/behind crossings, tall props, walls and character faces render correctly. |
| Navigation | Actual movement reaches every required activity without clipping or trapping. |
| Spawn/return | Arrival is safe; return and reload preserve the intended location/progress. |
| Interaction readability | Only real actions glow/click; next objective and return are obvious. |
