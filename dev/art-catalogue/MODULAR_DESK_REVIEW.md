# Grid-locked modular desk — first geometry prototype

Reviewed 2026-09-04 06:45 UTC. **Dev-only construction study, not runtime-approved furniture or calibrated seating.** No production catalogue, room geometry, collision, pose registry, worker or save was changed. This is code-built native geometry surfaced with generated material tiles, not a transformed/flattened generated prop image.

## Deliverables and interface

- `game/tools/modular_desk_geometry.gd`: explicit independently specified N/E/S/W geometry helper.
- `game/tools/modular_desk_calibration.gd`: isolated1280×720 renderer; never instantiates `GameMain` or a worker.
- `game/tests/test_modular_desk_calibration.gd`: focused provider-free geometry tests.

Preload the helper, instantiate it, and call `configure(facing, horizontal_tile, vertical_tile)`. Material arguments are optional32×32 `Texture2D` values. Without both materials it is explicitly a flat placeholder; wrong-sized supplied tiles or unknown directions fail without replacing the current view. `profile(facing)` returns the authoritative dev geometry. The helper origin is the shared floor pivot `(0,0)`, not its opaque bottom.

| Facing | Native top `(x,y,w,h)` | Native floor `(x,y,w,h)` | Contact Y | Top layer |
| --- | --- | --- | --- | --- |
| North |−48,−48,96,32|−48,−16,96,32|+16|Rear|
| East |−16,−80,32,96|−16,−48,32,96|+48|Rear|
| South |−48,−48,96,32|−48,−16,96,32|+16|Front|
| West |−16,−80,32,96|−16,−48,32,96|+48|Rear|

Top and floor share screen-aligned axes with a32px vertical elevation. Legs and apron are integer rectangles with fixed charcoal/wood colors. Screen top/left edges stay lighter; bottom/right stay darker in every direction. N/S apron height and E/W access-side edge strips are explicitly authored separately; no node, image, or completed prop is rotated/mirrored.

`Rear` and `Front` are separately drawn `Node2D` children at relative z−1/+1, with body references placed between them at z0. Caller backgrounds must be below `Rear`, or the whole desk parent must sit above the background depth. Scale is1 and rotation0. Placeholder `seat_reference` values are **not reviewed sockets** and must not enter runtime data.

## Materials and native pixel behavior

Root supplied separately generated horizontal and vertical opaque32×32 oak material tiles:

- `res://tests/fixtures/furniture-calibration/materials/oak-horizontal-v1.png` for N/S.
- `res://tests/fixtures/furniture-calibration/materials/oak-vertical-v1.png` for E/W.

The interior top repeats native tile pixels, clipped inside a2px authored rim. There is no stretched full-desk bitmap, source rotation, mirrored baked light, runtime downscale, or local semantic raster editing. Materials are loaded as images in this dev tool so it does not depend on a particular import preview or production registry.

At native scale the wood is visibly denser than the simple flat charcoal leg/rim geometry. This is acceptable for testing the construction mechanism, not proof of final style coherence. No blank tiling seam was observed in the native top surfaces; larger repeated-grain perception is not eliminated by that observation.

## Verification and a real bug caught by native review

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_modular_desk_calibration.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 60 --script res://tools/modular_desk_calibration.gd -- --horizontal=res://tests/fixtures/furniture-calibration/materials/oak-horizontal-v1.png --vertical=res://tests/fixtures/furniture-calibration/materials/oak-vertical-v1.png
```

- Import:passed.
- Headless geometry:166 checks,0 failures. Covers exact top/floor/contact, fixed elevation, all part extents, true positive rectangle areas, native material sizes, distinct layers, no transform, and fail-closed invalid input.
- Final rendered run:exited0, five1280×720 captures, **180 actual material-pixel checks passed**. Each capture samples nine interior top pixels in every bare direction and compares them to the expected native tile pixel within0.01 per RGB channel; this proves those sampled pixels are not hidden, stretched or substituted.
- `git diff --check`:passed.
- All five final PNGs were inspected at native size. No renderer remains open.

The first capture was wrong despite passing data-only geometry tests: the opaque showroom background had z0 and hid `Rear` z−1, causing N/E/W tabletops to disappear while South's front-layer tabletop remained. The harness now places the backdrop at z−100, and the new actual-pixel checks prevent the same hidden-layer regression. Final captures replace those failed initial captures; the failure is recorded here rather than concealed by test counts.

## Final evidence

`game/tests/output/modular-desk-calibration/`:

- `four-view-mira-idle.png`
- `four-view-geometry-guides.png`
- `four-view-mira-typing.png`
- `four-view-theo-idle.png`
- `four-view-theo-typing.png`
- `manifest.json` — material paths, dimensions, layers, all four explicit profiles, unapproved seat references, capture names and180 painted-top checks.

All final images show native48×80 body frames. Top-row standing Founder/Theo are scale references only; bottom-row Mina/Theo are staged directional seated references. Seated captures sample idle frame0 and typing frame2, **not all animation frames or complete loops**.

## Native findings and next bounded work

1. **Geometry foundation demonstrated:** all four actual tops are visible and match the requested screen-aligned dimensions/contact lines. The desks stay rectangular instead of inheriting a generated vanishing point or diamond yaw.
2. **South occlusion is not approved:** in the lower South comparison at approximatelyx752–848,y518–556, the whole top is in `Front` and obscures the seated body's hands/torso. Only the upper head remains visible. A far/near top split or a separately calibrated seat socket is needed; never interpret the geometry pass as a seated layering pass.
3. **North still requires chair support:** body references nearx160,y524–590 are deliberately unsupported because this study contains no chair. Root's separate supported-north assembly owns chair/actor/kit alignment. The high hands in Theo north and long hair in Mina must be checked against that actual composite.
4. **East/West anatomy remains a real gate:** approximate bottom-row stripsx464–496 andx1104–1136 confirm the direction is built on the exchanged32×96 top, but body/seat offsets here are placeholders. Theo west's known one-pixel registration wobble and different hip height are not fixed by the desk.
5. **Art finish is still provisional:** simple legs, thin rims and prominent repeated material grain need a separate style/edge review in the real office. No corners/wall placement/collision/editor transaction was exercised by this isolated specimen.

This first bounded prototype is complete. Do not add it to a production facing list, synthesize a runtime-ready review record, or count it as four approved workstation assets. Next: finish the supported north desk/chair/actor/kit assembly, then resolve the South top split and E/W socket/layer behavior before any real-room production integration.
