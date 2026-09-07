# Engineer mat — actual-room four-facing review

Reviewed 2026-09-04, approximately 09:20 UTC. **Staged concept only; no runtime approval.** No image request, source repaint, production registration, engineer employee, provider session, or save access was made by this review.

## Result

The four opaque mat plates fit the exact calibrated desk in the real GameMain pipeline, but do **not** yet form a polished four-facing active workstation. Keep the current exports as reviewed resting-tool concepts.

- South is the clearest composition, but exposes a real existing seated-shadow depth defect. Hiding that shadow in a separately labeled diagnostic restores the entire mat; the baseline deliberately retains the defect.
- East and West expose most of the mat, but the long circuit board/breadboard can read as a vertical control panel. Their device dimensions also disagree with North/South.
- Centered North is mostly hidden by the existing seated backs. Raising the mat above the character would be physically wrong; this review does not do that.
- None of the existing seated/typing frames holds a probe or performs electronics work. The typing frames are explicitly labeled incompatible pose stress tests, not newly authored tool-use animation.

Start with [all four native views](../../game/tests/output/engineer-mat-composition/all-four-native.png), [South actual room](../../game/tests/output/engineer-mat-composition/south-frame0.png), and the [South shadow-hidden diagnostic](../../game/tests/output/engineer-mat-composition/south-shadow-hidden-diagnostic.png).

## Frozen source and native contract

Masters and prompts remain under `game/assets/source/overnight-20260904/roles/engineer-mat-*`. The unchanged mechanical builder is `dev/tools/build_engineer_mats.sh`; preferred native plates are under `game/tests/fixtures/furniture-calibration/engineer-mat-v1/`.

| Facing | Preferred file | Master dimensions | Native plate | Native colors | Alpha |
|---|---|---:|---:|---:|---|
| North | `north-v2.png` | 1586×992 | 32×20 | 18 | All 640 pixels opaque |
| East | `east-v1.png` | 992×1586 | 20×32 | 20 | All 640 pixels opaque |
| South | `south-v2.png` | 1586×992 | 32×20 | 22 | All 640 pixels opaque |
| West | `west-v1.png` | 992×1586 | 20×32 | 19 | All 640 pixels opaque |

These are intentionally opaque, edge-to-edge indigo work-mat **materials**, not transparent individual tool cutouts. The builder performs uniform point reduction, centering/padding if needed, and ≤24-color quantization. No runtime scale, mirror, image rotation, arbitrary axis stretch, keyed matte, or invented three-dimensional appliance rise is used.

North v1 remains a rejected tiny-object-readability control. North v2 was one targeted readability retry. South v1 remains a rejected up-pointing-probe control; South v2 was one targeted direction retry. East/West were initial independent views. This review adds **zero** generations or retries. Full source/native hashes are in the capture manifest and rebuild results.

### Actual directional identity, not prompt compliance by assumption

All four preserve the major placement relationships: breadboard on the far side, red probe on the worker's left, black on the right, and board USB on the worker's left. That becomes N left USB, E top USB, S right USB, W bottom USB.

However, the native silhouettes do not consistently preserve probe-tip readability. North's two pale upper tips and East's pale right red-probe tip are clear. East's black probe and both West probes lack equally distinct pale end tips. South v2's lower ends do not retain an unambiguous silver needle cluster at native size, so the requested down-pointing correction cannot be treated as fully validated merely because its source prompt says so.

Manually reviewed native object boxes, including their own dark edges/USB but not remote probe cables, show a physical-scale mismatch:

| Facing | Circuit board box, x/y/w/h | Breadboard box, x/y/w/h |
|---|---|---|
| N | 10,8,11,6 | 10,1,12,5 |
| E | 4,8,8,14 | 14,8,5,15 |
| S | 10,3,12,7 | 10,12,12,5 |
| W | 7,8,9,15 | 1,9,5,14 |

These are explicit visual measurement annotations, not automatic semantic segmentation or new extracted assets. A rotated physical counterpart of the N board's 11×6 floor dimensions would exchange axes to approximately 6×11; the 8×14/9×15 side boards are materially larger. Breadboard length increases from 12 to 14–15 pixels. Future correction should pick one native physical object contract and redraw the inconsistent views; do not compensate by shrinking an entire workstation or stretching these plates.

## Actual GameMain placement

`game/tools/engineer_mat_fixture.gd` subclasses the existing calibrated workstation fixture. It uses its real OfficeLayout profile validation, TownRoom sprites, navigation, owner-scoped CharacterArt registry, chair layers, body cuts, and logical work cells. It removes the ordinary **monitor, keyboard and mouse** for this isolated mat-only comparison. Existing exact oak desks, chairs and actor sockets are unchanged.

| Facing | Mat bounds relative to desk pivot | True wood bounds | Empty wood margin L/T/R/B |
|---|---|---|---|
| N/S | `(-16,-42,32,20)` | `(-46,-46,92,28)` | 30/4/30/4 px |
| E/W | `(-10,-48,20,32)` | `(-14,-78,28,92)` | 4/30/4/30 px |

The wood bounds exclude the two-pixel outer tabletop rim. Every mat has at least four actual wood pixels of gap, exceeding the requested two. The 32×20 mat and 20×32 mat use their full native opaque rectangle as their flat contact. There is no extra collision and no substitute workstation geometry.

Desk pivots are `(336,272)` for Mina and `(784,272)` for Theo. Native mat rectangles are:

- N/S Mina `(320,230,32,20)`, Theo `(768,230,32,20)`.
- E/W Mina `(326,224,20,32)`, Theo `(774,224,20,32)`.

Mat depth is desk+2 for N/S and desk+1 for E/W. Existing upper/lower actor ordering remains intact. South's lower body may project onto the mat's source rectangle but is correctly behind the tabletop; a raw bounding-box intersection is not itself a visible clipping failure. The tests therefore compare the actual rendered mat pixels against live source layers and their absolute depths.

## Findings and disposition

| ID | Severity / type | Evidence | Finding and next action |
|---|---|---|---|
| EM01 | P0, code presentation | `south-frame0.png`, mat bottom around Mina `(330,245)` / Theo `(778,245)`; all six frames | Exactly **47** visible floor-shadow pixels paint over each mat in every seated/typing frame. `_sync_render_transform()` applies the seated render offset to the shadow and leaves it at the actor's inherited depth. The calibrated South actor is above the tabletop. Introduce a separate, explicit grounded-shadow policy for opt-in calibrated profiles; preserve legacy behavior until tested. Do not alter tool art to hide this. |
| EM02 | P1, composition / pose | `north-all-six-native.png` | Only **133–169 of 640** mat pixels remain visible (20.8–26.4%). Existing hair/back occludes the board and breadboard. Suitable as visible vacant-desk decor, not a legible centered active station. A later lateral resting-mat placement or separately authored working pose is required; no foreground-layer cheat. |
| EM03 | P1, asset identity | Four native plates, all-four contact | Circuit board and breadboard physically grow in E/W. Normalize the **object drawing contract**, not runtime scale. Keep current plates staged. |
| EM04 | P1, asset readability | Native preferred S/E/W plates and 8× proofs | Several probe tips lose distinct metallic ends. South v2 is not a confirmed native tip-direction pass. Any future correction must preserve cable/handle/tip order with a clear 1–2-pixel needle cluster. |
| EM05 | P1, interaction art | Frames2–5 for both actors/all facings | Existing typing poses tap near a plate edge rather than grasp probes. No probe-use animation exists. Keep only quiet resting/seated presentation for this concept until appropriate authored hand poses exist. |
| EM06 | P2, material/perspective readability | `east-mira-frame2-4x.png`, `west-theo-frame2-4x.png` | Bright tall E/W breadboards and green boards read like a small upright panel next to the face. The mathematically flat plate has no added height, but code geometry alone does not solve the visual reading. Reduce inconsistent object elongation first, then re-review with true flat-tool cues. |
| EM07 | P2, evidence export | Rebuild results | The frozen builder's six 8× derivative PNGs retain changing metadata; decoded RGBA is identical. Original masters and native exports are byte-identical. Future housekeeping can strip the derivative metadata; no native-art defect. |

### Shadow diagnostic is evidence, not a production fix

The initial rendered depth oracle omitted translucent shadows and correctly reported 47 mismatches on South for both employees, all six frames. Inspection showed these pixels came from the existing floor shadow, not corrupt mat texture. The final oracle includes the actual shadow, retaining the visible defect in all baseline captures and recording `shadow_on_mat_is_visual_defect=true`.

`south-shadow-hidden-diagnostic.png` hides only the two shadow sprites, retains frame0/pose/geometry/tool source, then restores shadow visibility. All **640** mat pixels become visible with **0** shadow pixels. This diagnostic does not modify any production policy, actor source, toolkit or baseline placement.

The final 42,240-pixel oracle checks 41,676 pixels exactly. The remaining **564** source-shadow blend pixels allow at most one 8-bit channel step to accommodate CPU-versus-GL blend rounding; all 564 are the known South 47-pixel shadow footprint × two actors × six frames. Opaque art/source reconstruction remains exact. A green invariant suite is **not** a visual acceptance of EM01.

## Native review / scoring

0–3 per category; passing would require every category ≥2 and mean ≥2.5. These are review judgments, separate from deterministic invariant tests.

| View | Pixel coherence | Perspective | Readability | Layering/anchor | Direction consistency | Placement | Mean | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| N | 2 | 2 | 1 | 2 | 1 | 2 | 1.67 | Staged; active mat mostly hidden |
| E | 2 | 2 | 2 | 2 | 1 | 3 | 2.00 | Staged; device size/tip cleanup |
| S baseline | 2 | 2 | 2 | 1 | 1 | 3 | 1.83 | Staged; shadow and tip blockers |
| W | 2 | 2 | 2 | 2 | 1 | 3 | 2.00 | Staged; device size/tip cleanup |

Viewed at actual native resolution: all four complete frame0 screens, South's complete diagnostic screen, all four all-six-frame contact sheets (48 actor/frame appearances), and the all-four contact. Viewed enlarged: all four preferred source plates at 8×; N Mina frame0 and Theo frame2; E Mina frame2 and Theo frame4; S Mina frame0 and the shadow-hidden diagnostic; W Mina frame5 and Theo frame2 at 4×. No entire-movie playback claim; the movie is a deterministic sequence of sampled states, not a continuous filmed navigation journey.

The original two idle and four typing frames remain unmodified, including pre-existing seated sprite/hip limitations recorded in the calibrated workstation review. Plate layering does not cover a character's face; tiny source intersections in the conservative upper-36-row boxes remain behind the upper body. N's correct body-first occlusion is the reason the role props are unreadable, not a reason to reverse depth.

## Verification and reproducibility

- Frozen builder replay: **31 checks, 0 failures**. Six original master and six native-file hashes exactly preserved; all eighteen files including 8× derivatives have exactly equal decoded RGBA before/after replay.
- Godot import: exit0.
- Focused actual-scene headless run: **1,994 checks, 0 failures**.
- Final rendered run: **2,443 checks, 0 failures**; **42,240** actual mat/actor/furniture depth pixel comparisons; **105 PNGs** (33 native scenes, 66 nearest 4× crops, six contact sheets).
- Movie: **119 frames, 30 FPS, 1280×720**, confirmed with `ffprobe`; manifest `frames=99` counts only the three-frame screenshot settles, while the AVI includes fixture setup frames too.
- Every direction starts in a fresh GameMain/OfficeLayout/CharacterArt owner scope; teardown removes its temporary pose capability.
- Real navigation and seat transitions are stepped deterministically to/from unchanged desk/home cells. The movie samples their end states, not every navigation tick. Source region unions reconstruct each unmodified actor frame. Repeated source and native hashes remain unchanged.
- NullWorker is installed before GameMain readiness. A bootstrap UI `chat.history` attempt is explicitly **blocked and recorded** in each fixture; no transport, provider, state load, credential read, or personal save exists. Do not describe this as zero attempted UI methods.
- `git diff --check`: pass. No production source/catalogue/registry mutation in this task.

```sh
node dev/tools/check_engineer_mat_rebuild.mjs
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_engineer_mat_composition.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/engineer-mat-composition/engineer-mats.avi --script res://tools/capture_engineer_mat_composition.gd
```

Evidence: [manifest](../../game/tests/output/engineer-mat-composition/manifest.json), [headless results](../../game/tests/output/engineer-mat-composition/results-headless.json), [rebuild results](../../game/tests/output/engineer-mat-composition/rebuild-results.json), [movie](../../game/tests/output/engineer-mat-composition/engineer-mats.avi).

New dev-only files: `engineer_mat_fixture.gd`, `capture_engineer_mat_composition.gd`, `test_engineer_mat_composition.gd`, `check_engineer_mat_rebuild.mjs`, and this report. Source/native exports, existing fixture and production code stay unchanged.
