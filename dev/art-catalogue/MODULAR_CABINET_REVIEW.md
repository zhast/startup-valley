# Exact counter/archive geometry: native calibration review

2026-09-04. **Dev-only geometry candidate; not finished furniture or a production-facing approval.** No ImageGen request, whole-prop image edit, production catalogue change, active prop replacement, worker call, save access, or new gameplay interaction occurred in this task.

## Outcome

Both families now have explicit four-service-side geometry, rendered beside native actors inside the approved room. The counter has a 32px rise, the archive a 64px rise; floor depth never substitutes for height. East/west exchange the floor axes while retaining the same rise and fixed upper-left lighting.

The bases intentionally have empty front inserts. They establish a testable support volume for the forthcoming coffee tools and archive panel. They do **not** read as completed coffee/archive destinations yet. North/south bare structures and east/west bare structures are symmetric pairs; that legitimate base symmetry is not four newly authored appliance views. Front-only art is strictly refused on a hidden or edge-on service face.

## Source and API

- Helper: `game/tools/modular_cabinet_geometry.gd`.
- Headless tests: `game/tests/test_modular_cabinet_geometry.gd`.
- Native showroom and registered-layer exporter: `game/tools/capture_modular_cabinet_calibration.gd`.
- Evidence: `game/tests/output/modular-cabinet-calibration/`.

`profile(family, service_side)` supports families `counter` / `archive` and service sides `north`, `east`, `south`, `west`. Its fields include explicit `service_side`, `approach_gaze`, `service_cell`, `clearance`, `occupied`, `floor`, `top`, `top_interior`, `front`, `plinth`, `rise`, `contact_y`, `canvas`, `pivot`, `visual_bounds`, and a south-only `insert_socket`. There is deliberately no `facing`, `work_gaze`, seat anchor, work cell, pose set, or chair metadata.

`configure(family, service_side, horizontal_tile, vertical_tile)` accepts native 32×32 tiles and rejects wrong dimensions or unknown directions without changing the prior view. It uses the existing separately generated soft horizontal/vertical oak material tiles, never a rotated texture or finished prop bitmap.

`set_service_insert(texture)` accepts an exactly sized texture only for service south. It does not scale, mirror, rotate or crop a front to fit another side. Passing null clears the insert. The optional insert's dimension/side/placement behavior is covered headlessly; this first showroom deliberately renders its layer empty rather than creating pretend finished content.

## Exact native geometry

Rectangles use `(x,y,width,height)` relative to the floor-center pivot. Contact values are the **exclusive** near-floor boundary; the last opaque row is one pixel before that boundary.

| Family / service side | Floor | Raised top | Rise | Contact |
|---|---|---|---|---|
| Counter N/S | `(-48,-16,96,32)` | `(-48,-48,96,32)` | 32 | +16 |
| Counter E/W | `(-16,-48,32,96)` | `(-16,-80,32,96)` | 32 | +48 |
| Archive N/S | `(-48,-16,96,32)` | `(-48,-80,96,32)` | 64 | +16 |
| Archive E/W | `(-16,-48,32,96)` | `(-16,-112,32,96)` | 64 | +48 |

- Counter canvas: **192×256**, pivot **(96,192)**. Contact boundaries: canvas y208 N/S, y240 E/W.
- Archive canvas: **192×288**, pivot **(96,224)**. Contact boundaries: canvas y240 N/S, y272 E/W.
- Usable top excludes the actual two-pixel edge: `top.grow(-2)`.
- South counter insert: **Rect(-44,-12,88,24)**.
- South archive insert: **Rect(-44,-44,88,56)**.
- Plinth: last four pixels of the front elevation, with a warm upper edge and charcoal ground contact.
- Visual bounds are the true opaque top-plus-rise silhouette, not the 192px padded canvas.

Service cells and inward approach gaze remain distinct:

| Service side | Service cell | Approach gaze |
|---|---|---|
| North | (0,-1) | South |
| East | (1,0) | West |
| South | (0,1) | North |
| West | (-1,0) | East |

No service cell intersects a cabinet's occupied cells; all three cells in the corresponding service row are separate clearance. This does not change the legacy production assets or their saved direction meaning.

## Layers and depth

Five separately registered layers share each family canvas/pivot: **Carcass, Top, Front, Plinth, Insert**. The first four form the base; Insert is truly transparent until valid front art is supplied. Exports include all five layers and their combined view for each of eight family/side combinations.

The whole solid cabinet uses its physical floor depth. Sublayers use the same depth in stable construction order. An actor north of the cabinet therefore goes behind its opaque silhouette; an actor in front remains in front. The tall archive is not put behind every actor merely to preserve character visibility.

Actual north-service evidence:

- Counter: **253** of 1,315 opaque actor samples are correctly hidden by the counter.
- Archive: **1,046** of 1,467 opaque actor samples are correctly hidden by the archive.
- Every checked painted actor pixel matched either its original sprite color or the higher-depth cabinet color: **82,770 samples, zero mismatches**.

The archive's north service pose leaves primarily the head visible. That is an honest consequence of the fixed camera and 64px rise, not a direction-art failure to fix by moving the whole cabinet behind the actor. A production interaction would need discoverable cues, and possibly a deliberately designed view/interaction accommodation. No such gameplay change is claimed here.

## Defects caught during the study

1. The first fixture demanded occlusion even for short counters with walkers far enough north that their pixels never overlapped. The assertion now uses actual projected opaque pixels; nearest north-service poses still require nonzero real occlusion. No geometry was changed to satisfy the original over-assertion.
2. Native inspection then caught the rightmost walk-around path outside the room's east wall. The final showroom uses true grid-center columns **208/464/720/976** and rows **272/560**. Cabinet ink corners and every actor foot sample are checked against the actual `OfficeLayout.is_floor()` grid. This was a dev evidence-layout fix, not a production wall or movement change.

The final screenshot walkthrough shows no cabinet/wall overlap, detached layer seam, clipped prop, false front details, or caption covering the walking actors. Static captions are intentionally hidden during traversal. The plain facades are unfinished, not a glitch disguised as finished art.

## Verification and evidence

From repository root, using `/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot`:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_modular_cabinet_geometry.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/modular-cabinet-calibration/cabinet-calibration.avi --script res://tools/capture_modular_cabinet_calibration.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/validate_project.gd
```

- **344 headless checks, zero failures**, rerun after final capture changes.
- **7,065 rendered checks, zero failures**, final process exited 0.
- Project validation passed.
- **82 PNGs:** 10 native 1280×720 room views, 24 nearest-neighbor 4× room crops, 48 registered layer/whole exports.
- **187 movie frames at 30 FPS**; harness reports 186 scripted/settling frames, plus the engine's initial frame.
- Every family/side's five registered layer images reconstruct its combined renderer output byte-for-byte.
- Layer alpha is binary with zero hidden RGB; the optional Insert is genuinely empty in all eight exports.
- Actual combined ink bounds and last opaque contact row match the explicit geometry for all eight views.
- 32 material samples confirm native tile repetition and no resampling.
- Scripted walk-around feet stay outside the cabinets and inside the real room floor map. **This is visual traversal evidence, not production AStar, click-hit-testing or reservation acceptance.**

Native views inspected: `all-eight-bare`, `standing-scale`, `service-approach`, `geometry-guides`, `behind-cabinets`, `in-front-cabinets`, `walk-segment-0`, `walk-segment-1`, `walk-segment-2`, and `final-service`. All eight service-approach 4× crops were also opened individually, covering every family/service side. The remaining 16 enlarged crops and individual component PNGs are generated evidence, not individually visually inspected; their composition/alpha/registration is tested. The movie is retained for playback; the review used its deterministic still checkpoints, not a claim of watching every encoded frame.

Primary files:

- `all-eight-bare.png`: dimensions and honest empty bases.
- `standing-scale.png`: native 48×80 character comparison.
- `service-approach.png` / `final-service.png`: actual inward gaze and depth.
- `geometry-guides.png`: physical floor, top interior, service cell, contact and south insert.
- `walk-segment-2.png`: corrected east-wall traversal clearance.
- `manifest.json`: exact profiles, layer alpha measurements, per-checkpoint occlusion counts and test results.
- `results-headless.json`: focused geometry results.

## Acceptance disposition and next gates

The geometry is suitable for **further dev composition**, not active furniture replacement. As a finished-art candidate it still fails silhouette/identity completeness because inserts, coffee tools, contextual cues and final finish are missing. Do not label these eight empty volumes as eight completed coffee/archive assets.

Next steps are to compose independently authored south coffee tools on the unchanged top interior, supply a true flat archive service-south insert, then inspect those assemblies at native size. North/east/west appliance details require their own real views or honest hidden/edge-on behavior. Contact shadows and existing ambient overlays need explicit attachment review. Production placement/collision/input, wall/corner variants, workflow behavior and art scoring remain separate gates before any replacement is enabled.
