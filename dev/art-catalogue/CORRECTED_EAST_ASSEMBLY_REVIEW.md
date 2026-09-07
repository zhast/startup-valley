# Corrected east assembly — E4 keyboard and supported character Y

**Preferred calibration candidate: chair X+12/Y0, Mina actor Y+3, Theo actor Y+4, source cut52. Not runtime approved.** Replacing the short E2 keyboard with the actual E4 native export and measuring each character against the unchanged chair improves support without shrinking hands or moving physical work cells. The source-preserving actor/chair layers continue to remove the knees-over-table and whole-chair-through-body defects. All earlier E2 evidence remains frozen.

## Evidence and exact results

New harness: `game/tools/capture_corrected_east_assembly.gd`.

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_corrected_east_assembly.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/corrected-east-assembly/corrected-east.avi --script res://tools/capture_corrected_east_assembly.gd
```

- Headless: **351 checks, 0 failures**; durable `results-headless.json`.
- Rendered: **1,293 checks, 0 failures**, process exited0; durable `manifest.json`.
- **14 native 1280×720 captures +6 nearest-4× detail captures** in `game/tests/output/corrected-east-assembly/`.
- `corrected-east.avi`: **227 actual frames, 30FPS, 1280×720**, confirmed with ffprobe. This includes setup/control captures and a180-frame idle/typing loop; it is not a sit/stand transition test.
- Exact actor source reunion:138,240 tested pixels across36 actor/frame/variant combinations. Actual rendered actor reunion:122,880 cropped pixels, identical.
- Exact chair source reunion:15,360 canvas pixels, each owned once. Actual rendered chair reunion:122,880 cropped pixels, identical.
- No source image, production catalogue, pose registry, actor implementation, navigation, worker or save was changed.

All six native pose frames, guide/support captures, both whole-chair controls, four reunion captures and all six frame2 detail crops were visually inspected. The preferred middle-column frame2 details are `native-frame2-mira-y3-4x.png` and `native-frame2-theo-y4-4x.png`. Captions remain inside their paper surfaces, with actor headroom and no overlap between comparison stations.

## Coordinate and layer contract

The exact existing modular east geometry stays unchanged: tabletop `Rect(-16,-80,32,96)`, floor footprint `Rect(-16,-48,32,96)`, tabletop elevation32px. The physical work foot is host-relative **(-32,0)**, the nearest outside cell of the proposed1×3 footprint on the actual32px grid. The prototype's off-grid(-24,0) seat reference is not used. The roomy showroom origins are presentation locations, not a claim of approved production placements.

| Element | Host-relative attachment | Original source registration |
| --- | --- | --- |
| Logical actor work foot |(-32,0), unchanged | Navigation/reservation location |
| Chair render foot |(-20,0): logical foot+(12,0) |96×160 canvas, pivot(48,112) |
| Mina candidate render foot |(-20,3) |48×80 cell, pivot(24,72) |
| Theo candidate render foot |(-20,4) |48×80 cell, pivot(24,72) |

Each actor has a Y0 control, the preferred adjustment, and one additional pixel downward: Mina0/+3/+4; Theo0/+4/+5. The chair never moves vertically to manufacture a shared socket. Hip observations are source rows53–55 for Mina and52–54 for Theo, measured against the actual chair seat top at sourceY96. The preferred adjustment places each observed hip band at **0..2px below that seat top**, versus Mina−3..−1 and Theo−4..−2 atY0. One extra pixel gives1..3px; native/details offer no reason to prefer the extra drop.

Actor source regions are `[0,0,48,52]` and `[0,52,48,28]`, retaining their full original registration. The existing `calibration_chair_layers.gd` partition is reused unchanged: rear659 opaque pixels, near arm81, exact740-pixel union. No masks, repaint, hidden cushion, mirroring or independent-axis scale are introduced.

| Layer | Depth relative to desk origin |
| --- | --- |
| Chair rear / seat / base |−5 |
| Actor lower body |−4 |
| Chair existing near-arm pixels |−3 |
| Desk tabletop |−1 |
| Desk front / apron / legs |+1 |
| Actor upper body / hands |+2 |
| Monitor |+3 |

The explicit whole-chair-above-lower control reproduces the intrusive blue/gray chair band. The exact near-arm partition keeps only the authored near arm in front of the lower body. The whole-chair-behind control demonstrates why source ownership matters independently of actor support.

## E4 device dimensions and contact

The E4 export and its provenance are recorded separately in `COMPUTER_EAST_V4_REVIEW.md`. This study uses the new registered monitor12×30 at(99,108), keyboard9×31 at(81,115), and mouse9×6 at(81,149), all on the192×224 host canvas with pivot(96,160). The key outline is `Rect(81,115,9,31)` and conservative key bed is `Rect(82,116,7,29)`. These fit the actual32×96 tabletop. The inherited compatibility field named `hand_pixels_over_short_key_bed` now measures this same E4 bed; the explicit `hand_pixels_over_key_bed` and `keyboard_version` fields disambiguate it.

| Preferred adjustment, typing frames2–5 | Conservative hand samples over key bed | Samples outside tabletop | Head pixels hidden by monitor |
| --- | --- | --- | --- |
| Mina Y+3 |23/28, 22/29, 22/29, 25/30 |0 in every frame |0 in every frame |
| Theo Y+4 |11/12, 10/12, 12/14, 12/18 |0 in every frame |0 in every frame |

The sampled tan pixels are a conservative hand/cuff region, not a semantic segmentation or proof of anatomically perfect finger contact. All conservative hand samples stay in the upper actor layer at cut52. The mouse stays screen-down of the keyboard. The monitor has the narrow left-facing screen edge required for an east-looking operator.

## Native visual findings and remaining gates

1. **Resolved in this calibration:** no knees or shoes draw over the tabletop; original pixels reunite exactly. The preferred Y offsets remove the conspicuous light gap above the seat visible in theY0 controls. The monitor does not obscure either head. All six poses preserve the same attachment/layer rules.
2. **Improved, not an exact family match:** the E4 keyboard now reads as a full-length vertical keyboard, versus E2's short10×20 object. It is still **9×31, not north's axis-exchanged11×31**. Its pale edge projects beside the face/torso; the actor draws in front of it, but the close keyboard/face silhouette remains visually busy. A zero monitor-head intersection does not imply zero projected keyboard-head overlap. Do not widen it by stretching or call that discrepancy solved.
3. **Small lap overhang remains:** cut52 preserves hands but leaves23–25 Mina and22–24 Theo conservative upper-lap pixels over the tabletop across frames. In the native image this reads as a small thigh/cuff strip, not the previous whole shin/shoe. Final cut choice needs art-direction acceptance; no source pixel was erased to hide it.
4. **This is an endpoint/loop study only:** logical feet stay fixed while render offsets differ. Enter/exit, interruption, standing shadow recovery, labels/hit targets and real multi-actor workstation reservation must use the separate transition framework and be tested with the eventual approved assembly. The measured endpoint displacement is approximately12.37px for Mina and12.65px for Theo, not proof of a smooth transition.
5. **Production gate remains closed:** approve the complete directional family, geometry/clearance/layer/pose metadata and actual room placement before adding an east-facing runtime profile. These per-character offsets must not be promoted to a universal chair socket.

The static comparison supports carrying the middle-column candidate into the next complete assembly/transition review. It does not authorize enabling a new production facing.
