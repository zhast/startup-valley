# Modular office implementation

## Outcome and scope

The office is now one interior-first, native-pixel space. `main.tscn` no longer
layers `campus-surround.png` behind a separate `office-shell-base.png`. Both old
images remain historical references, not runtime architecture. Exterior art is
limited to the two window panes; the center wall is kept clear behind the HUD.

The approved notebook UI, portraits, corrected south-facing workstation,
seated/typing sheets, employee IDs, worker/provider/security boundary, company
database and job contracts are preserved. All verification uses worker-disabled
fixtures or provider-free worker tests. No paid work order, commit or push.

## One source of geometry

- `game/data/office_layout.json`: 40×23 cells at 32px, floor rectangles, wall
  cutouts, windows, entrance, reserved circulation, employee spawns, placements
  and hire thresholds. The 1280×720 view crops only the last solid wall row.
  Every entrance cell is fully visible and physically reachable.
- `game/data/furniture_catalog.json`: authored facings, occupied floor cells,
  chair/interaction clearance, work and interaction cells, art paths/atlas cells,
  native sprite offsets, visual bounds, anchors and occlusion layer offsets.
- `OfficeLayout`: resolves the above to shared placement records and validates
  each stage. It rejects wall/prop intersections, unsupported facings, blocked
  entrances/aisles, obstructed seats, unreachable interactions and disconnected
  floor. Furniture overhang is separate from physical occupancy; intentional
  employee/desk occlusion remains supported.
- `OfficeArchitecture`: selects native floor, wall and corner regions from the
  floor-cell definition and draws declared window/door modules. No room bitmap.
- `TownRoom`: creates each typed prop at its resolved anchor, applies catalog
  art/atlas/layer metadata, creates collision from occupied cells, and supplies
  the same interaction/work destinations to `GameMain` and employees.
- `OfficeNavigation`: constructs wall collision from exact non-floor cells and
  AStar occupancy from exact resolved furniture cells. No collision rectangles
  independently inferred from a source image.

Current workstation: three occupied cells, north chair clearance, separate
south founder interaction. Both 128×112 layers share one origin; rear depth is
anchor Y−40, employee seat is one cell north, and desktop front is anchor Y+1.
Furniture stays native, screen-aligned and south-facing. Other facings require
new authored art, not sprite rotation or mirroring.

## Growth, migration and recovery

Stages 0/1/2/3/4 contain 1/5/8/8/9 props. Founder-only, Mina, and Mina+Theo are
the playable arrangements; stages 3–4 retain developer growth previews.

Worker-owned desk coordinates are validated as a complete batch first, so a
valid joint desk swap is preserved. If the batch is invalid, individually safe
legacy coordinates are retained and invalid coordinates use the authored bay.
`migration_notes` explains rejected legacy coordinates; no database rewrite is
required. Employee identities and ownership are never inferred from proximity.

Room-file loads validate a temporary model across all stages before replacing
the current room. Invalid imports and rejected placement previews leave the
live arrangement/navigation unchanged.

Growth cancels stale founder movement, safely relocates actors only when their
footprints become invalid, refreshes employee destinations and renews routes
after the whole roster is registered. Saved founder coordinates take precedence
over temporary NPC spawn locations: exact safe coordinates are retained and
intersecting NPCs move instead. The full foot footprint is checked, not only its
center. Company finances, milestones and other worker state are untouched.

Employees keep their exact authored desk destination. An occupied/reserved seat
causes a paused-aware retry, not a new desk position on nearby floor. Failure and
schedule changes cancel obsolete retries.

## Developer authoring workflow

```sh
godot --path game --script res://tools/edit_office_layout.gd
```

This standalone, worker-free tool is not referenced by the production scene.
Its native room preview has a separate inspector. Select a stage and furniture;
press **M**, move the pointer for a snapped translucent preview, and click to
commit only a valid placement. **Escape** cancels, **Ctrl+Z** undoes, **Ctrl+S**
exports. Toggles show grid, occupied cells, clearance, walls/entrance/circulation,
interaction points, navigation routes, image bounds and depth layers.

Validation covers **all stages**, including future unlocked furniture, before
commit or export. Specific rejection reasons are shown in the inspector.
Only authored facings are available. Exports are restricted to
`game/tests/output/office-layout/*.json`; the tool cannot overwrite production
layout or company saves.

Review the exported JSON diff, then intentionally apply desired `grid`/`facing`
changes to `game/data/office_layout.json`. Re-run layout/editor/integration tests
and rendered captures before accepting it. This is development tooling, not a
player-facing decorating or economy feature.

## Architecture art and provenance

The blockout and a complete approach→sit→type→leave workstation bay were tested
and visually inspected **before** generation. Evidence was retained under
`game/tests/output/modular-office/blockout/`.

Five original masters were generated with the built-in ImageGen tool using the
ImageGen skill. Exact prompts: `game/assets/source/architecture/PROMPTS.md`.
Masters stay in that directory. Runtime crops, palette preparation, anchors and
alpha modes: `game/assets/runtime/office/architecture/README.md` and `manifest.json`.

| Runtime asset | Native size | Use |
| --- | --- | --- |
| floor.png | 128×128 | Sixteen 32px regions, continuous repeating oak material |
| wall.png | 128×96 | Four columns × three rows, cornice/plaster/wainscot/baseboard |
| trim.png | 128×64 | West/east/south/mass plus four corner modules |
| window.png | 160×96 | Garden scenery inside a transparent walnut frame |
| door.png | 64×32 | Open entrance threshold and indigo mat |

Generated output needed cleanup: the window had a baked checkerboard exterior,
the doorway included unwanted wall wings, and trim samples included gutters and
plaster fields. The deterministic preparation script removes those defects and
registers native tile edges. Repeat-edge checks require exact pixel equality;
two successive builds produced identical SHA-256 hashes for all five assets.

```sh
bash dev/tools/build_architecture_assets.sh
godot --headless --path game --import
```

The full `build_polish_assets.sh` also invokes this builder. ImageMagick remains
development tooling only. Runtime art is lossless, nearest-sampled, native-size,
without mipmaps; the window has binary alpha and other architecture is opaque.
Existing character, workstation, research, coffee, archive, collaboration,
approval and prototype art is reused. Ambient overlays keep their own textures
and offsets rather than inheriting furniture normalization.

## Verification commands and evidence

Run from the repository root (substitute the local Godot executable as needed):

```sh
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/test_office_layout.gd
godot --headless --path game --fixed-fps 60 --script res://tests/test_office_migration.gd
godot --headless --path game --script res://tests/run_all.gd
godot --headless --path game --fixed-fps 60 --script res://tests/test_complete_game.gd
godot --headless --path game --fixed-fps 60 --script res://tests/test_ui_flow_regressions.gd
godot --path game --fixed-fps 60 --script res://tests/test_office_architecture.gd
godot --path game --fixed-fps 60 --script res://tests/test_office_layout_editor.gd
godot --path game --fixed-fps 60 --script res://tests/test_modular_office.gd
godot --path game --fixed-fps 60 --script res://tests/test_graphics_regressions.gd
godot --path game --fixed-fps 60 --script res://tools/capture_visual_review.gd
godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/world.avi --script res://tools/capture_polish_audit.gd -- --suite=world
godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/ui.avi --script res://tools/capture_polish_audit.gd -- --suite=ui
godot --headless --path game --script res://tools/validate_polish_audit.gd
```

The actual rendered integration suite covers all stages, exact model/navigation/
physical collision agreement, growth relocation, saved positions, keyboard
movement, click movement/cancellation, employee/station clicks, UI isolation,
chair layering, visible typing and chair exit. It captures 1280×720 and 1600×900.
Headless checks write a separate manifest so they cannot erase rendered evidence.

The architecture test verifies native dimensions/imports, exact repeat seams,
clean alpha, actual rendered floor registration, catalog-driven art/atlas changes,
and independent ambient offsets. The graphics regression also verifies approved
menu corners survive resizing and dropdown input still uses the authored surface.

Motion auditing now walks real navigable front/back routes around furniture,
checks actor occupancy during recorded frames, captures every growth stage and
opens the visible assignment dropdown with actual pointer/keyboard events.

### Final results — 2026-09-03

All final captures were regenerated **after** the modular architecture was
integrated. The earlier blockout evidence is separate and is not the final
visual acceptance evidence.

| Check | Result |
| --- | --- |
| Godot import, project validation, existing gameplay and UI suites | Passed |
| Layout model | 830 checks passed |
| Migration, exact-seat recovery and roster/growth integration | 2,468 checks passed |
| Architecture | 477 headless / 3,538 rendered checks passed |
| Placement editor | 128 headless / 133 rendered checks passed |
| Modular-office integration | 7,436 headless / 7,451 rendered checks; 14 rendered captures; no failures |
| Workstation/typing and menu-corner graphics regressions | Passed |
| Isolated static review | All 27 captures regenerated and reviewed |
| World motion | 2,455 frames at 30 FPS; 5,043 actor-cell checks |
| UI motion | 537 frames at 30 FPS; 1,149 actor-cell checks |
| Motion evidence validator | All 12 scenarios complete with distinct sampled frames |
| Asset inventory | Five architecture assets match declared size/alpha/import; all five growth stages valid; no inventory flags |
| Provider-free worker regression | Build passed; 49 tests passed, one optional production Godot smoke test skipped; offline evaluation 8/8 |
| Repository checks | `git diff --check` passed; no harness or contract changes |

The final visual review inspected full-resolution room/chat captures, seated
and typing frames, depth and work-state sequences, office growth, dropdowns,
and the document reader. The room has one continuous floor/wall composition;
no duplicated shell/campus, furniture/wall intersection, baked window matte,
or new architecture seam was found in these reviewed states. Workstation
fronts occlude seated bodies while heads and typing hands remain visible.
Future layout/art changes still require the same visual review.

The native playtest launched the normal game with
`STARTUP_VALLEY_NO_WORKER=1`, not only a test viewport. Ground clicks moved the
founder around furniture; clicking the founder desk opened Journey on arrival;
clicking Mina in the world opened her chat. Rail selection and Escape worked.
Windowed and maximized views retained the room composition. The maximized
window can have intentional aspect-preserving letterbox bars outside the
1280×720 canvas; these are not gaps within the room. All test/playtest Godot
processes were closed afterward.

Evidence paths (relative to the repository):

- `game/tests/output/modular-office/integration-manifest.json`: rendered checks
  and 14 screenshot paths; `integration-headless.json` is separate.
- `game/tests/output/modular-office/bay-seated.png` and `bay-typing-0.png`
  through `bay-typing-3.png`: actual registered workstation and animated pose.
- `game/tests/output/modular-office/native-windowed.png`,
  `native-maximized.png`, `native-founder-station.png`, and
  `native-employee-interaction.png`: normal-game native-window playtest.
- `game/tests/output/office-layout/`: editor previews, rejection/placement
  evidence, nonzero-anchor regression captures, and validated layout exports.
- `game/tests/output/visual-review/` and
  `game/tests/output/ui-product-audit/contact-sheet.png`: final static review.
- `game/tests/output/polish-audit/world.avi` and `ui.avi`: final recordings;
  the corresponding `world/` and `ui/` directories contain scenario manifests,
  keyframes and contact sheets. `asset-inventory.json` identifies the active
  modular kit, native sprite sizes, and 614 floor cells.

No paid provider request, user-save reset, worker/security change, commit or
push was performed. Pre-existing uncommitted graphics/UI repairs were retained.

## Deliberate limitations

- This is the two-employee desktop slice, not a full decorating game or campus.
- Only authored south-facing furniture is enabled.
- Native internal composition remains 1280×720; larger windows preserve aspect.
- Archived shell/concept art remains on disk for provenance, not as active art.
- Generated future materials still need human/agent visual review after the
  automatic geometry, alpha and seam checks; passing those checks alone is not
  an aesthetic approval.
