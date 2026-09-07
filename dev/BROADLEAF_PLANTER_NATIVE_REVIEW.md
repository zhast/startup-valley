# Broadleaf planter native review — 2026-09-06

## Outcome

`broadleaf-planter-v1` passes the bounded native-review gate as a non-production candidate. It is an original deterministic code-native four-facing base-furniture asset on the planned `128x224` canvas and `[64,176]` floor pivot. It is not approved, runtime registered, or placed by default.

The native/4x sheets read as a small ceramic floor pot with six broad, organic leaves, articulated stems and soil. The silhouette is materially closer to the intended physical identity than a vector-like placeholder. The pot stays deliberately stable and symmetric while independently declared leaf arrangements carry N/E/S/W identity; that direction cue is subtle, so direction consistency scores `2/3` rather than `3/3`.

## Source disposition and provenance

- `game/assets/source/overnight-20260904/plants/broadleaf-planter-fourway-v1.png` is preserved at SHA-256 `1ef554d7ba1ef82a43e406ffadf46c9eef1147035e4aab0d7b0fc4bfd642346b`. It decodes as `948x1659 RGB8`, with no alpha channel and painted checkerboard cells.
- `game/assets/source/overnight-20260904/plants/broadleaf-planter-fourway-v2.png` is preserved at SHA-256 `3ce72e2dcbc0f4a3983e6bf5bda5f5b556de0c918cf6467193e14ab2e7330e77`. It decodes as `949x1658 RGB8`, again with no alpha channel and painted checkerboard cells.
- Both prompts remain under `dev/art-catalogue/prompts/`. Batch one has an initial attempt and one retry; the overall retry allowance is not claimed exhausted, but repeating the same alpha-only method is closed as ineffective.
- The failed images are physical-identity references only. `broadleaf_planter_geometry.gd` contains no image-loading or source-sampling path. No checkerboard key, crop, mask, trace, recolor, transform, or relabel operation contributes to any candidate pixel.
- The native candidate was authored as editable integer pixel geometry. No provider call or ImageGen raster was used because this established code-native furniture workflow was sufficient.

## Authored geometry

- Common canvas: `128x224 RGBA8`.
- Common floor pivot: `[64,176]`; centered sprite offset `[0,-64]`.
- Footprint/collision: one `32x32` cell at `[[0,0]]` for every facing.
- Layers: `floor_shadow` at `-8`, `rear_structure` at `-4`, and `front_structure` at `+5` relative to the neutral prop carrier.
- Every facing declares six separate leaves: four rear and two front. Base/tip, width, curvature, branch position, pot profile and screen-axis composition are authored per direction. No finished bitmap is rotated, mirrored, flipped, scaled, or resampled.
- Leaves use stepped outlines, multiple green facets, broken midribs and alternating branch veins. Brown stems carry fixed screen-left highlights. The ceramic pot uses a stepped taper, soil/rim separation, fixed upper-left glaze and lower/right shading. Alpha is binary and transparent RGB is zero.
- Proposed passive contact cells preserve the existing plan: North `[0,1]`, East `[-1,0]`, South `[0,-1]`, West `[1,0]`, with gaze toward the pot. These are capture/viewpoint metadata only and create no interaction.

## Deterministic and structural evidence

- Export: `42 checks, 0 failures`.
- Structural/alpha/identity gate: `281 checks, 0 failures`.
- All 12 native layer PNGs and four composite PNGs rebuild byte-exact from editable geometry.
- Each composite uses `15+` opaque colors and `6,060–6,402` opaque pixels, remains inside the planned `128 px` rise and at least `16 px` side padding, and reconstructs exactly from its three ordered layers.
- All four wholes, rear layers, and front layers are pairwise distinct. Opposing composites are neither horizontal nor vertical mirrors.
- Source-format checks prove both historical generations are RGB-without-alpha, while every candidate export has binary alpha and zero hidden RGB.

Evidence:

- `game/tests/fixtures/furniture-calibration/broadleaf-planter-v1/manifest.json`
- `game/tests/output/broadleaf-planter/structural-results.json`
- `game/tests/output/broadleaf-planter/candidate-contact-sheet-native.png`
- `game/tests/output/broadleaf-planter/candidate-contact-sheet-4x.png`
- `game/tests/output/broadleaf-planter/candidate-layers-native.png`

## Actual GameMain evidence

The native macOS renderer ran actual `GameMain` and production `TownRoom` at `1280x720`, with the candidate admitted only into a disposable owner-scoped duplicate catalogue/layout. Result: `207 checks, 0 failures`.

- A common `[12,13]` pivot accepts all N/E/S/W facings.
- Each facing produces exactly one real `32x32` collision shape, blocks its exact AStar cell, leaves its declared adjacent contact cell walkable, and remains stable after the founder route.
- Each facing has a valid placement one or two cells from production architecture. A real two-axis corner is rejected atomically with wall/headroom issue codes.
- Alpha-aware picking finds a visible surface on all three layers and rejects transparent canvas padding. No surface creates an action or seat target.
- Before actor contact, the actual-room image matches every opaque composite source pixel: North `6,402`, East `6,060`, South `6,314`, West `6,187`, all with zero mismatch.
- The existing founder is only a standing scale, gaze, route and depth probe. He reaches the exact adjacent cell without entering collision: North is in front of the plant, South is behind it, and East/West are bracketed by rear/front layers.
- Natural actor/plant intersections are North `1,436`, East `413`, South `1,385`, West `486` pixels, with `0` wrong-depth pixels in every facing. These overlaps arose from the declared adjacent geometry; the artwork was not moved to manufacture a counter.
- The run starts no worker, reads/writes no save, and leaves production catalogue, default layout and shared art catalogue byte-exact.

Evidence:

- `game/tests/output/broadleaf-planter/actual-room-results.json`
- `game/tests/output/broadleaf-planter/actual-room-base-contact-sheet-native.png`
- `game/tests/output/broadleaf-planter/actual-room-actor-contact-sheet-native.png`
- `game/tests/output/broadleaf-planter/actual-room-actor-contact-sheet-4x.png`
- `game/tests/output/broadleaf-planter/actual-gamemain-contact-sheet-native.png` — four unscaled `1280x720` panels.

## Native visual score

| Criterion | Score (0–3) | Review |
| --- | ---: | --- |
| Pixel coherence | 3 | Clean stepped contours, readable veins/stems and restrained dithering at 1x/4x. |
| Perspective | 3 | Pot, rim, soil, stems and floor contact agree with the fixed office camera. |
| Silhouette readability | 3 | Immediately reads as a broadleaf floor plant rather than generic blocks. |
| Layering and anchors | 3 | One stable floor pivot; floor/rear/front order is correct around all actor contacts. |
| Direction consistency | 2 | Four independent leaf arrangements are identifiable, but the intentionally symmetric pot makes the rotation cue subtle. |
| Placement | 3 | Scale, wall clearance, one-cell collision and room-floor contact are coherent. |

Mean `2.83/3`; minimum `2/3`. This passes the bounded native-review threshold. It is not production acceptance.

## Remaining limits

- Main-agent visual approval and catalogue promotion remain outstanding.
- No production furniture registration, runtime art installation, default-layout placement, renovation availability, plant interaction, service behavior, hire, animation or backend is claimed.
- Because an organic planter has no obvious service face, N/E/S/W identity is carried mainly by leaf occlusion and branch arrangement. If a later art review demands stronger rotational identity, revise the pot seam or branch crown directly; do not mirror or rotate a finished export.
- The two failed generated RGB sheets remain failed historical attempts and must not be treated as usable transparency.

## Rerun

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_broadleaf_planter.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_broadleaf_planter.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --script res://tools/capture_broadleaf_planter.gd
```
