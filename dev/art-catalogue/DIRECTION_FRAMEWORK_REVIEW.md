# Direction framework: rendered baseline and integration review

Reviewed 2026-09-04, final native run completed by 06:09 UTC. This is a code/compatibility review, **not approval of new directional furniture or character art**. Production data still exposes south only for all seven furniture families.

## Results

- `capture_furniture_direction_baseline.gd`: **84 rendered checks, 0 failures; 11 native captures; 12 pixel comparisons**. Headless counterpart: **60 checks, 0 failures**.
- Each Mina/Theo south seated/typing frame was compared in a 160×144-pixel room crop against an independent reconstruction of the pre-direction texture/region/origin/depth math. All **276,480 compared pixels matched**: zero changed pixels across the 12 samples.
- `test_furniture_directions.gd`: **429 checks, 0 failures**, including the padded-canvas correction below.
- Post-fix `test_world_ui_presentation.gd`: **422 checks, 0 failures**. Project validation and diff whitespace checks passed.
- Earlier combined foundation batch passed actor-facing 249, architecture 477, layout 830, modular 7,436, editor 128, migration 2,468, `run_all`, and complete-game tests. The new geometry/content-bound checks and FounderHud pointer fix were subsequently rerun through their directly affected suites.
- Final post-fix compatibility rerun also passed layout 830, editor 128, migration 2,468, `run_all`, and complete-game real-input tests. All processes exited normally.
- No worker/provider was launched, no saved company loaded, no production catalog/art enabled, and no commit/push performed. Every captured game fixture checks absent worker stdio/process and unloaded company state.

Machine-readable output: [results-rendered.json](../../game/tests/output/furniture-direction-baseline/results-rendered.json), [results-headless.json](../../game/tests/output/furniture-direction-baseline/results-headless.json).

## What the pixel comparison proves

The harness instantiates an actual fresh `GameMain`, freezes actor motion/ambient overlays, and captures production south desks plus Mina/Theo in all two seated-idle and four typing cells. It then independently reapplies the old explicit constants to that same fixture:

- south-workstation texture, two registered128×112 regions, `(0,-40)` sprite offset;
- rear depth=`desk ground Y−40`, front depth=`desk ground Y+1`;
- actor48×80 regions, `(0,-32)` character offset, foot-Y actor sorting;
- seated32×16 shadow at `(0,-2)`.

The reference does not call the new facing resolver, work-pose registry or seat-depth helper. The comparison isolates an accidental south pixel/depth regression from unrelated clock/UI/idle variation. It is **not** a historical whole-screen Git baseline and does not judge the artistic quality of missing directions.

Compared room coordinates: Mina `[256,160,160,144]`, Theo `[576,160,160,144]`.

| Evidence | Native review |
| --- | --- |
| [South seated, current](../../game/tests/output/furniture-direction-baseline/south-seated-current.png) / [independent reference](../../game/tests/output/furniture-direction-baseline/south-seated-legacy-reference.png) | Existing front-facing bodies remain behind the desktop and in front of the rear chair layer; no new desk seam/anchor shift. |
| [South typing, current](../../game/tests/output/furniture-direction-baseline/south-typing-current.png) / [independent reference](../../game/tests/output/furniture-direction-baseline/south-typing-legacy-reference.png) | Registered hands/desk pixels preserve the baseline; all four typing regions also compared programmatically. |
| [Shifted socket hover](../../game/tests/output/furniture-direction-baseline/shifted-socket-hover.png) | Geometry-only `(16,-8)` render offset demonstrates shifted mouse hit and anchored E prompt. This deliberately offset seat is not an accepted furniture arrangement. |
| [Click → approach → Chat](../../game/tests/output/furniture-direction-baseline/shifted-socket-chat-open.png) | Actual mouse click outside the old actor rectangle selects Mina, founder path reaches the physical interaction area, Chat opens, and redundant world identity disappears. |
| [Failure reset](../../game/tests/output/furniture-direction-baseline/failure-seat-reset.png) | Actual simulated terminal worker event restores standing character/shadow/label origins and foot-Y depth immediately. |
| [Delivery reset](../../game/tests/output/furniture-direction-baseline/delivery-seat-reset.png) | Actual simulated completion clears the seated offset before delivery movement. Toast capture waits240ms for its existing entrance animation; no production timing change. |
| [Missing-facing rejection](../../game/tests/output/furniture-direction-baseline/editor-missing-direction-rejected.png) | Real R key cannot offer/commit N/E/W while production art is unavailable; it explains the restriction. |
| [South preview](../../game/tests/output/furniture-direction-baseline/editor-south-move-preview.png) / [placed](../../game/tests/output/furniture-direction-baseline/editor-south-move-placed.png) | Actual M/mouse/click moves existing art from `(10,8)` to `(12,7)`. Both registered regions, native origins and textures match the ghost exactly; Ctrl+Z restores the station. |

All eight game images are1280×720. The three developer-editor images are its intentional native1600×800 tool canvas, not a gameplay scaling claim. All11 initial images were inspected at native size; the corrected four interaction/reset images were inspected again after the final rerun.

## Real issues found and fixed

### FDR-01 — interaction prompt ignored the rendered seat socket

The first native shifted-socket capture showed the E Chat pointer targeting original x336 while Mina's rendered origin moved to x352. Actor nameplates/hit-testing were updated, but `FounderHud.update_interaction()` still used physical feet for silhouette avoidance, prompt placement and pointer target.

The new precise assertion failed before the change: **60 checks, 1 failure**. The fix changes only those three presentation calculations to `employee.render_position()`. Proximity still measures `employee.position`; navigation, reservations and interaction distance are unchanged. Final native capture points at x352; headless60/0 and rendered84/0 pass.

Source: `game/ui/founder_hud.gd`, `update_interaction()`; regression in `game/tools/capture_furniture_direction_baseline.gd`, `_shifted_actor_input()`.

### FDR-02 — transparent registered canvas incorrectly counted as obstructing artwork

Initial explicit-profile validation required `visual_bounds` to equal the complete render-layer canvas union. A registered192×224 source with only96×66 actual desk ink would be rejected near a wall because its transparent padding crossed the wall.

Explicit directions now preserve their full registered render regions and derive obstruction bounds from the actual nontransparent content. Optional per-layer `content_bounds` are region-local and may conservatively enclose that ink, but validation checks every nonzero-alpha pixel is contained and the box stays within the region. Declaring an artificially small obstruction cannot allow opaque wall clipping. Flat legacy south profiles retain their existing bounds unchanged.

The test uses the existing, unapproved `desk-south-v2.png` calibration source without modifying it: canvas192×224; measured ink `[48,110,96,66]`; layer offset`[0,-48]`; derived local obstruction`[-48,-50,96,66]`. Placement at `(3,5)` passes with actual world art bounds`[64,126,96,66]` even though transparent padding touches architecture. Moving actual ink into a wall fails; undersized or out-of-region declared content fails. This is geometry evidence, not promotion of that desk into production.

Source: `OfficeLayout.measured_layer_ink_bounds()`, `layer_content_bounds()`, `_validate_direction_profile()`; `test_furniture_directions.gd`, `_test_padded_content()`.

## Remaining gates / limitations

1. N/E/W remain unavailable until actual native art, geometry and required actor poses pass review. Four synthetic direction fixtures are not four accepted views.
2. The south baseline is intentionally unchanged. This pass does not claim to fix the visual-camera quality of every existing coffee/research/approval prop.
3. Registry lookups reject missing identities, missing sets and missing work poses. Older generic `locomotion_sheet()`/`work_sheet()` helpers still choose legacy placeholders for unknown IDs in non-registry standing/delivery paths. Future specialist runtime hiring must explicitly handle those identities; no such employee is enabled by this goal's concept assets.
4. Current station interactions still use the existing supported kinds. New specialist/fun decoration needs explicit interaction capabilities before it becomes functional rather than decorative.
5. Native crops prove the existing south baseline and selected state transitions. They do not replace the upcoming four-facing seated/walking depth showroom, broad motion audit, or wall/corner placement review using accepted new art.
6. Research metadata currently controls pose/facing lookup, but the actor's render-offset/depth helper only applies the workstation socket while seated/typing at the desk. The current research offset is zero and baseline sorting is unchanged. New research art requiring a nonzero working socket needs a separately tested research render-offset/depth path; do not assume `seat_anchor` is already applied to a standing research pose.

## Reproduce

```sh
cd /Users/zhast/GitHub/startup-valley
export STARTUP_VALLEY_NO_WORKER=1
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_furniture_directions.gd
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --fixed-fps 60 --script res://tools/capture_furniture_direction_baseline.gd
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 60 --script res://tools/capture_furniture_direction_baseline.gd
```
