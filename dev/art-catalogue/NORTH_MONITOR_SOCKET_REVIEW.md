# North monitor and character-specific seat sockets

Status: **provisional assembly candidate, not runtime approval**. All 14 final native captures inspected on 2026-09-04. The earlier `SUPPORTED_NORTH_ASSEMBLY_REVIEW.md` and its evidence remain unchanged as the shared-offset baseline.

## Outcome

The best displayed combination is **chair −12Y from the unchanged logical work foot; Mina −8Y relative to that chair; Theo −4Y relative to that chair; monitor −10Y relative to the desk kit reference; keyboard and mouse +4Y**. This is an external arrangement of the original registered pixels, not a taller/redrawn monitor or a rotated character.

Moving the monitor to the back of the real tabletop solves the major screen obstruction without moving the keyboard or introducing an unsupported stand. Its actual last three support rows occupy source-reference **y114–116**, entirely inside the exact tabletop's **y112–143**. Mina obscures only 3–4% of sampled lit screen pixels; corrected Theo obscures 0%. The north seat plane is still inferred from the visible east-chair family, so the character/chair relationship remains a candidate until an exposed north seat layer establishes actual support.

## Evidence and commands

New dev-only harness: `game/tools/capture_north_monitor_socket.gd`, inheriting fixture/metric helpers from `capture_supported_north_assembly.gd` without modifying that baseline.

```sh
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_north_monitor_socket.gd
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/north-monitor-socket/north-monitor.avi --script res://tools/capture_north_monitor_socket.gd
```

Final results under `game/tests/output/north-monitor-socket/`:

- `results-headless.json`: **327 checks, zero failures**.
- `manifest.json`: **1,741 rendered checks, zero failures**. This includes repeated per-capture caption/assembly non-intersection checks, not 1,741 independent aesthetic judgments.
- `north-monitor.avi`: **287 frames at 30 FPS**, including capture setup plus a 240-frame diagnostic endpoint/typing/guides sequence.
- `native-frame0.png` through `native-frame5.png`: both idle frames and all four typing frames.
- `guides-frame0.png` through `guides-frame5.png`: same frames with 22%-opaque chair and explicit support guides.
- `standing-endpoint.png`, `standing-guides.png`: unchanged logical-foot endpoint, exposing the unimplemented sit/stand displacement.

Rows: **Mina seat −8**, **Theo seat −8 control**, **Theo seat −4 candidate**. Columns: absolute monitor origins **+4**, **−6**, **−10**, corresponding to movement **0**, **−10**, **−14** from the previous whole-kit +4 baseline. Every chair remains −12 and every keyboard/mouse remains +4.

Native desk pivots are x280/584/888 at y210/390/570. Example detail regions: Mina final column `Rect(840,137,96,109)`, Theo control final column `Rect(840,317,96,109)`, Theo corrected final column `Rect(840,497,96,109)`.

The first rendered layout had captions that covered the following row's raised monitors. That evidence was rejected, the dev-only row spacing changed to 180px, and all final captures were regenerated. Every caption is now checked against every assembly's complete native region before each capture. The final files above—not the first run—are authoritative.

## Actual component geometry

The company/reader agent's exact split components are full **192×224** transparent canvases retaining pivot **(96,160)**:

| Source fixture in `game/tests/fixtures/furniture-calibration/kits/` | Actual nontransparent bounds | Relevant contact |
|---|---|---|
| `computer-north-v2-monitor.png` | `(80,97,33,30)` | Last outline row126; last three base rows `(89,124,14,3)` |
| `computer-north-v2-keyboard.png` | `(79,127,31,11)` | Whole keyboard outline retained, including top row127 |
| `computer-north-v2-mouse.png` | `(112,129,6,8)` | Whole mouse retained |

The Godot harness converts decoded images to RGBA8 and verifies the registered alpha-mask union exactly equals every original RGBA byte before applying any offset. No source pixels, scaling, palette, projection, or transparency are altered.

| Absolute monitor origin Y | Base support rows in original desk-canvas coordinates | Distance of first base row from tabletop back edge y112 | Support result |
|---|---|---|---|
| +4 | 128–130 | 16px | Fully supported, but screen obstructed |
| −6 | 118–120 | 6px | Fully supported; useful intermediate |
| −10 | 114–116 | 2px | Fully supported; clearest selected candidate |

The monitor body projects above the back edge because it is vertical; **its base**, not the whole screen silhouette, must lie on the tabletop. At −10, the base is `Rect(-7,-46,14,3)` relative to the desk pivot, enclosed by top `Rect(-48,-48,96,32)`. The keyboard remains `Rect(-17,-29,31,11)` and mouse `Rect(16,-27,6,8)`, also enclosed. None is resting on an apron or floating beyond the table.

## Screen visibility and support

Lit-screen occlusion across typing frames2–5:

| Row / actor-from-chair offset | Monitor +4 | Monitor −6 | Monitor −10 | Hip range versus inferred seat |
|---|---|---|---|---|
| Mina / −8 | 55–56% | 15–16% | 3–4% | −1 to +1px |
| Theo control / −8 | 79–80% | 20–21% | 3% | −5 to −3px: not supported by current hypothesis |
| Theo candidate / −4 | 54–56% | 3% | 0% | −1 to +1px |

`native-frame2.png` shows the final monitor clearly at approximately `(888,147)` for Mina and `(888,507)` for corrected Theo. The corrected support relationship is visible in `guides-frame2.png` around Theo `(888,574)`, not merely concealed behind the normal chair. Compare the middle-row control around `(888,390)`, where the hip remains above its seat plane at y394. Character-specific registration fixes that four-pixel difference without shifting the chair, desk, keys, or logical actor destination.

The exact monitor translation leaves keyboard samples invariant within each row. Mina's typing samples over the keybed are **7/16, 6/12, 8/11, 8/16**. Theo's corrected row is **3/7, 5/6, 2/11, 1/1**. These are selected visible skin-color samples, not whole-hand masks; especially Theo frame5's 1/1 is one bright pixel, not proof of complete hand contact. The low sample count in frame4 and partial key contact remain reasons not to certify the finished typing pose from a percentage alone.

## Remaining acceptance work

1. **Expose the actual north chair seat.** The cyan plane comes from an east-family measurement; amber hips have approximate anatomical bounds. Split or author the seat/back/front layers and verify real support without using the foreground backrest to hide a mismatch.
2. **Check whole hands and readable typing motion.** The current arrangement is visibly better and preserves native pixels, but projected hands still sit partly beside the narrow keybed. Verify both wrists/fingertips across all four frames against a reviewed contact mask or improve an explicitly authored pose/keyboard asset. Do not silently equate a few sampled pixels with ergonomic contact.
3. **Provide a sit/pull-in/stand sequence.** Mina's render-foot endpoint is 20px inward from the logical standing foot; corrected Theo's is 16px inward. The diagnostic movie deliberately snaps between endpoints. A production state transition must explain those movements and handle chair depth; it cannot teleport the standing actor into furniture or corrupt its navigation position.
4. **Verify layered chair and desk occlusion in motion.** The current whole chair is still foreground, and exact desk control colors are not the final material. Monitor ordering is physically consistent—nearer heads still occlude the screen where pixels overlap—but that does not validate the full chair or approach path.

No production registry or worker/game state was changed. This study narrows the next north assembly candidate; it does not approve it for runtime use.
