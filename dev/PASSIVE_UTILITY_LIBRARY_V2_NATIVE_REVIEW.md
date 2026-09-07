# Passive utility library v2 native review — 2026-09-06

## Disposition

`tall_storage_cabinet`, `server_cabinet`, and `recycling_sorter` pass the agent-native gate for the passive art library. This is art approval only. None is registered in the production furniture catalogue or default layout, and no interaction, service, hire, role pose, backend, live server activity, balance, metric, or waste transaction is claimed.

The rejected v1 geometry and evidence remain preserved. V1 used a flat frontal body with only a thin cap and therefore scored perspective 1/3. V2 does not lower that gate: each view now contains an explicit top plane equal to the exact physical occupied-floor rectangle translated upward by one family-wide elevation, followed by a separate camera-front elevation from the plane's near edge to floor contact.

## Visual scores

Scores are from direct inspection of the native and nearest-neighbour 4x candidate sheets plus the actual GameMain actor sheets. The low, rectangular silhouettes are intentionally restrained; silhouette readability is therefore scored 2 rather than inflated.

| Family | Pixel | Perspective | Silhouette | Layers / anchor | Direction | Placement | Mean | Minimum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Tall supply cabinet | 3 | 2 | 2 | 3 | 3 | 3 | 2.67 | 2 |
| Compact server cabinet | 3 | 2 | 2 | 3 | 3 | 3 | 2.67 | 2 |
| Three-stream recycling sorter | 3 | 2 | 2 | 3 | 3 | 3 | 2.67 | 2 |

The top planes read at native scale, remain aligned to the 32px floor axes, and do not collapse into face trim. Perspective is deliberately bounded at 2/3: the exact rectangular floor-axis extrusion is valid and readable but restrained, not an embellished isometric prop. Fixed upper-left highlights and lower/right shade remain screen-stable. Tall storage has a closed supply rear/front/end identity; the server has distinct fan/cable rear, rack front, and vented ends with static unlit marks; the sorter has three color-and-shape-coded apertures physically on its top plane and no text.

## Measured perspective and dimensions

The original canvas, pivot, sprite offset, occupied masks, one-cell approach clearance, and two per-cell collision shapes are unchanged.

| Family | Canvas | Pivot | Offset | Vertical elevation | N/S top depth | E/W top depth | Maximum projected rise | Original planned elevation envelope |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| `tall_storage_cabinet` | 160x288 | 80,224 | 0,-80 | 80px | 32px | 64px | 144px | 160px |
| `server_cabinet` | 160x288 | 80,224 | 0,-80 | 72px | 32px | 64px | 136px | 160px |
| `recycling_sorter` | 160x176 | 80,112 | 0,-24 | 32px | 32px | 64px | 96px | 48px |

The planned `estimated_max_rise_above_occupied_floor_px` is treated as a vertical-elevation envelope, not as top-plane depth. For the sorter, the full projected rise is necessarily 96px in an E/W view: 32px of vertical elevation plus the exact 64px depth of its 1x2 floor rectangle. This is a measured geometry clarification inside the retained canvas, not sprite scaling or a collision-mask change.

The bounded brief also clarifies visual identity: tall storage is closed rather than exposing an open shelf; server identity uses ventilation/rack/cable cues rather than a fake live status panel; the sorter is three-stream and uses shapes/colors rather than the old two labeled openings. No readable text or fabricated live state appears.

## Structural and actual-room evidence

- Deterministic exporter: 120 checks, 0 failures.
- Structural suite: 763 checks, 0 failures. It separately verifies the exact top-plane rectangle/depth, its elevation translation, camera-front contact, whole bounds, alpha, reconstruction, fixed canvas/pivot, distinct independent views, masks, wall model, and byte-exact rejected-v1 history.
- Actual GameMain: three fresh native macOS processes, one family per process, each 196 checks and 0 failures. Each family result records 190 checks before its own result-file close. The combined aggregator verifies all three invocation files and evidence paths.
- Native viewport: 1280x720. Common safe pivot: grid [12,13]. Every facing has two exact 32x32 collision shapes, one safe adjacent approach cell, atomic wall/corner rejection, alpha-aware visible-surface picking, and no action target.

Measured actor/prop overlap is evidence, not a quality threshold:

| Family | North (prop in front) | East | South (actor in front) | West |
| --- | ---: | ---: | ---: | ---: |
| Tall storage | 1,525px | 0px | 1,242px | 0px |
| Server cabinet | 1,342px | 0px | 1,242px | 0px |
| Recycling sorter | 267px | 0px | 1,242px | 0px |

North is `actor_behind_structure`, South is `actor_in_front_of_structure`, and E/W place the actor between rear/front layer depths. The standing founder is only a route, scale, gaze, contact, and occlusion probe; no utility-specific pose exists or is needed for passive art approval.

## Interrupted harness history

The first multi-family utility-v2 native process completed tall/server family files and then made no observable progress before sorter for more than three minutes; it was interrupted. Cause is unknown. A later focused sorter diagnostic completed the 190 family checks but ended at 195/1 because the shared catalogue changed between that run's before/after hash guards. That guard failure does not explain the earlier stall. Both are non-acceptance history and are superseded by the three clean 196/0 isolated runs. Another agent independently observed a similar cross-family lifecycle stall, so final evidence deliberately uses fresh per-family processes.

After the accepted isolated captures, the harness's common-pivot search was changed from “validate every interior cell, then sort” to “sort the same interior cells by distance, then return the first point passing the same all-four-facing predicate.” This preserves the selected [12,13] pivot and every placement assertion while adding phase/elapsed logging and avoiding synchronous exhaustive validation after the nearest valid point is found. Candidate pixels and evidence files are unchanged.

## Evidence paths

- `game/tests/fixtures/furniture-calibration/{tall-storage-cabinet-v2,server-cabinet-v2,recycling-sorter-v2}/manifest.json`
- `game/tests/output/{tall-storage-cabinet-v2,server-cabinet-v2,recycling-sorter-v2}/candidate-contact-sheet-{native,4x}.png`
- `game/tests/output/{tall-storage-cabinet-v2,server-cabinet-v2,recycling-sorter-v2}/actual-room-{base,approach}-contact-sheet-native.png`
- `game/tests/output/{tall-storage-cabinet-v2,server-cabinet-v2,recycling-sorter-v2}/actual-room-approach-contact-sheet-4x.png`
- `game/tests/output/{tall-storage-cabinet-v2,server-cabinet-v2,recycling-sorter-v2}/actual-room-results.json`
- `game/tests/output/passive-utility-library-v2/native-invocation-*.json`
- `game/tests/output/passive-utility-library-v2/actual-room-isolated-aggregate-results.json`

The proposed registrations keep `approved_art_path` limited to the reviewed v2 whole PNG, keep every runtime path/evidence null and `runtime_exports` empty, and retain the rejected v1 registration/evidence as history.
