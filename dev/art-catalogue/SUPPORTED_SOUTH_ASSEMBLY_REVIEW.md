# Supported south assembly — diagnostic, not runtime approval

Reviewed 2026-09-04. The correct legacy seat position fixes the misleading
head-only result from the earlier geometry placeholder. It does **not** prove
the new chair/monitor assembly is ready for gameplay.

## Result

- **Keep the real work foot at desk `(0, -32)`.** With actor render offset zero,
  both employees retain their faces, shoulders and hands in all six frames.
  There is no evidence here that a new tabletop split is required to solve the
  earlier head-only failure; that failure used the wrong `(0, -8)` seat.
- **The zero-offset actor is visibly too high for the new S3 chair.** Estimated
  upper-hip/lap bands sit 5–10 px above its cushion. This is visible with the
  desk and monitor hidden, rather than inferred from a pleasing composite.
- **Actor `+8 Y`, chair `0` is the strongest nearby support hypothesis.** Mina's
  estimated hip band reaches the seat top; Theo's straddles it. The characters'
  heads remain clear of the rear monitor. No physical work cell is moved.
- **Reject `+12 Y` as the preferred calibration.** Hips sink below the cushion
  band, and approximately 85–86% of the measured arm region disappears behind
  the top/monitor. It makes the work action less readable.
- **No hand-to-keyboard contact is certified.** The south candidate contains a
  rear monitor only. A keyboard on the far side may be visually hidden, but an
  absent keyboard is not a measured supported contact. The `+8` pose still has
  visible hand/upper-body changes; exact contact and the eight-pixel sit motion
  remain unresolved.

Production south artwork, sprite pivots, actor behavior, furniture metadata and
saved company data were not changed. No new runtime-ready facing was registered.

## Exact fixture

The approved room architecture supplies the background; its decorative props
are hidden only in this standalone developer scene. There is no `GameMain`,
worker process or save bootstrap.

| Part | Source/geometry | Registration and layer |
|---|---|---|
| Logical work cell | Production `furniture_catalog.json`, desk `[0,-1]` | Desk anchor + `(0,-32)`; adjacent to, not inside, blocked footprint |
| Desk | `modular_desk_geometry.gd`, south | Top `[-48,-48,96,32]`; floor `[-48,-16,96,32]`; top is entirely on front layer |
| Material | `oak-horizontal-v1-soft.png`, `oak-vertical-v1-soft.png` | Generated 32×32 native repeat tiles, no finished-prop rotation |
| Chair | `chair-south-v3.png` | Full 96×160; pivot `(48,112)`; fixed at logical foot; depth `desk Y−33` |
| Employee | Production `mira-seated.png`, `theo-seated.png` | Six 48×80 cells; pivot `(24,72)`; centered sprite offset remains `(0,−32)` plus candidate Y; depth `desk Y−32` |
| Monitor | `kits/computer-south-v3.png` | Full 192×224; pivot `(96,160)`; native housing 32×25 plus stand; no placement shift; depth `desk Y+2` |

All sprites are scale one with nearest filtering. The desk top remains ahead
of the actor; the chair remains behind the actor. No new raster mask, layer cut,
partial character occluder, mirror, rotation or semantic repaint is involved.

The desk floor ends at relative Y+16, while the actor's logical cell spans
Y−48…−16. Screen-space overlap with a raised tabletop is not a floor collision.
S3's cushion top is native Y95, or −17 from its chair pivot; with the real work
foot it appears at desk Y−49. Its floor contact is desk Y−16.

## Native observations and measured limits

Positions below refer to the 1280×720 captures. Mina is the top row; Theo is the
bottom. Desk anchors are X280/584/888, Y300/548. Native assemblies occupy bounded
160×160 review regions `[200+304c,180+248r,160,160]`. Captions are below them and
are asserted against **every** assembly, not just their own column.

| Candidate | Mina estimated hip minus seat Y | Theo estimated hip minus seat Y | Arm-region hidden during four typing frames | Disposition |
|---|---:|---:|---|---|
| Actor 0 / chair 0 | −8…−5 px | −10…−7 px | 0% both | Correct logical baseline; new chair sits low relative to pose |
| Actor +8 / chair 0 | 0…+3 px | −2…+1 px | Mina 33.9–35.4%; Theo 27.0–27.7% | Strongest support study, not approved |
| Actor +12 / chair 0 | +4…+7 px | +2…+5 px | Mina 85.8–86.4%; Theo 85.1–85.8% | Sunk pose and poor hand readability |

Hip rows are approximate anatomical observations, not authored collision masks:
Mina source rows47–50, Theo45–48. The arm measurement is deliberately an opaque
**rectangle sample**, rows40–47 and X≤19 or X≥28; it includes sleeve pixels and
is not an exact hand collider. The numeric head sample is source rows0–31,
not every long-hair pixel. All faces and upper heads were also visually checked
in every native frame.

The monitor's top is desk Y−51 and its last stand pixel is Y−21 (exclusive
contact Y−20), so its stand remains on the top plane. The housing hides the
middle lower torso as expected for this camera-facing rear shell; it does not
cut through faces. At `+8`, inspect Mina around `(568,250)` and Theo around
`(568,498)` for the visible thin hand band at the monitor's top edge.

All adjacent typing transitions produce changed pixels in the actual native
assembly crops, and the idle blink is visible. This is **not** a proof of clean
hand motion: source shading/outline pixels change too. For the `+8` candidate,
native typing transitions change 359–448 pixels for Mina and559–714 for Theo;
the monitor does not make two consecutive full composites identical.

The movie deliberately switches between standing and seated endpoints without
a fabricated tween. `+8` therefore reveals an unimplemented eight-pixel sit
displacement. Only visual registration is being studied; pathfinding, seat
entry, chair pull-in and safe exit are not accepted by this harness.

## Evidence and reproduction

All14 native stills and all12 frame2 nearest-neighbor detail crops were inspected.
The source atlases were also inspected at native and4× sizes.

- [Baseline and offset comparison, first typing frame](../../game/tests/output/supported-south-assembly/native-frame2.png)
- [Unoccluded chair support comparison](../../game/tests/output/supported-south-assembly/support-frame2.png)
- [Exact top/floor/seat guides](../../game/tests/output/supported-south-assembly/guides-frame2.png)
- [Mina +8 native assembly detail](../../game/tests/output/supported-south-assembly/native-frame2-mira-y8-4x.png)
- [Theo +8 native assembly detail](../../game/tests/output/supported-south-assembly/native-frame2-theo-y8-4x.png)
- [Mina baseline unsupported hips](../../game/tests/output/supported-south-assembly/support-frame2-mira-y0-4x.png)
- [Mina +8 support](../../game/tests/output/supported-south-assembly/support-frame2-mira-y8-4x.png)
- [Theo +8 support](../../game/tests/output/supported-south-assembly/support-frame2-theo-y8-4x.png)
- [Movie](../../game/tests/output/supported-south-assembly/south.avi): 257 total frames, 30 FPS, 1280×720; includes capture settling plus210 explicitly sequenced frames.
- [Manifest: every captured path and all36 measurements](../../game/tests/output/supported-south-assembly/manifest.json)
- [Independent pixel/crop verification](../../game/tests/output/supported-south-assembly/verification.json)

```sh
godot --headless --path game --script res://tools/capture_supported_south_assembly.gd
godot --path game --fixed-fps 30 \
  --write-movie res://tests/output/supported-south-assembly/south.avi \
  --script res://tools/capture_supported_south_assembly.gd
godot --headless --path game --script res://tests/test_supported_south_assembly.gd
```

Verification: **186 headless harness checks**, **1,010 rendered checks**, and
**171 independent evidence checks**, all zero failures. `ffprobe` independently
confirms1280×720,30/1FPS,257frames. The evidence test verifies every file/size,
all36 measurement records, each native-to4× crop's exact pixels, real idle/typing
frame differences, explicit endpoint offsets and non-approval status.

These checks validate the diagnostic, not production acceptance. No provider
calls, save access, runtime integration, image generation or production edits
occurred in this task. The next focused test should retain the real work cell,
evaluate an explicit `+8` sit/stand transition and establish a real keyboard
contact plane or consciously approved occluded-work presentation. Do not change
the legacy south renderer or cut the top solely to reproduce the old placeholder.
