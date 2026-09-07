# East keyboard placement — separate silhouette from reach

**Carry +6px X forward as the cleaner placement candidate; do not call Theo's reach fully approved.** Moving the existing E4 keyboard and mouse toward the fixed monitor removes the pale object directly against both faces. Mina retains clear fingertip/key contact through all six poses. Theo's generated fingers retract enough that three frames reach only the outline/edge, not the inset key bed. +8px is rejected; +4px is a closer reach control but retains head/keyboard adjacency. No character, furniture or device pixels were changed to make these results pass.

## Fixed inputs and changed variable

Harness: `game/tools/capture_east_keyboard_placement.gd`, extending the prior corrected assembly without modifying it. Evidence: `game/tests/output/east-keyboard-placement/`.

- Keep real work foot(-32,0), chair render offset(+12,0), Mina actorY+3, Theo actorY+4, actor source cut52 and the exact existing chair partition/depths.
- Keep native48×80 actor cells, exact32×96 tabletop, E4 keyboard9×31 and mouse9×6, and the monitor's original placement.
- Change **only keyboard and mouse world-space X**, together, by+4/+6/+8. Full192×224 registration and original source hashes remain intact. No image rotation, mirror, resampling, repaint, arm stretch or generated retry occurs.
- Capture a same-pose+0 baseline as well as every pose in the three comparison columns. The keyboard's Sprite2D center correctly includes canvas/2 minus pivot `(0,-48)`; assertions tie actual renderer coordinates to measured image origins.

| Device translation | Keyboard host-local opaque bounds | Empty columns before fixed monitor bounding box | Disposition |
| --- | --- | --- | --- |
|+0 control |X−15..−7, Y−45..−15 |9 | Obvious face/background clutter |
|+4 |X−11..−3, Y−45..−15 |5 | Better, still head-adjacent; closer reach control |
|+6 |X−9..−1, Y−45..−15 |3 | Preferred clean-silhouette candidate; Theo edge-contact caveat |
|+8 |X−7..1, Y−45..−15 |1 | Reject: too far forward and visually tight to monitor |

The mouse moves by the same amount, staying below the keyboard. Actual opaque keyboard/monitor, mouse/monitor and keyboard/mouse intersections are zero for every option. Both devices' complete bounds stay on the tabletop. This is a world-placement comparison, not new art or a universal keyboard socket.

Exact recommendations are **Mina keyboard+mouse(+6,0)** and **Theo keyboard+mouse(+6,0)** relative to their unchanged registered E4 sources. Each yields keyboard opaque host bounds`Rect(-9,-45,9,31)` and mouse`Rect(-9,-11,9,6)`; the monitor stays`Rect(3,-52,12,30)`. Mina's recommendation has stronger reach evidence. Theo's is only the preferred visual candidate with the explicit edge-contact limitation below, not an assertion that both actors have equally complete ergonomic poses.

## Two different reach measurements

The conservative whole-hand metric is retained, but it is not the optimization target: putting every tan forearm pixel over keys recreates the keyboard-under-face problem.

The **fingertip inference** uses source skin samples inX28..43/Y39..49, taking the forwardmost three occupied columns per frame. This selection depends on the original pose, never on the keyboard location. A separate **source-contour inference** includes only actual opaque pixels immediately one column east of those skin samples (within one row), preserving dark fingertip outlines excluded by the skin-color test. It does not fill transparent pixels or claim authored hand segmentation.

For the+6 candidate, these are the six frames0..5:

| Character | Skin-tip pixels on inset key bed / sampled skin tips | Actual inferred contour pixels on keyboard outline | Empty pixels to nearest keyboard pixel |
| --- | --- | --- | --- |
| Mina |4/6, 2/3, 4/6, 4/6, 3/5, 2/4 |8, 5, 7, 7, 9, 6 |0 in every frame |
| Theo |3/3, 0/4, 0/8, 0/5, 1/3, 1/5 |4, 2, 0, 6, 9, 8 |0 in every frame |

For Theo frame2 the inferred dark contour and keyboard are **adjacent pixels**, not overlapping pixels; the zero-empty-gap measurement must not be described as fingers sitting on the key bed. Native4× review confirms this borderline edge reach. At+8, Theo frames1/2 instead have one/two genuinely empty pixels between inferred outline and keys. Mina loses all skin-tip/key-bed overlap at+8 even though some dark edge pixels still touch its border.

This distinction changes the early skin-only interpretation: +6 does not create a large disconnected hand gap, but Theo's contact is less convincing than Mina's. It is a useful placement candidate, not a completed pose correction. Hands, hips and layers stayed fixed throughout; no further art retry was attempted.

## Native visual review

All eight native1280×720 captures were inspected: six poses, baseline and guides. All six+6 detail frames for both actors were inspected at nearest4×, together with frame2+4/+8 alternatives. The remaining per-frame alternative detail crops are available as evidence; no claim is made that every alternative crop was separately opened.

- At frame2, the+0 control has33 Mina /25 Theo projected head pixels behind keyboard ink, including21 /2 sampled face pixels. At+4 this becomes0 /1 head pixels, but10 /6 head pixels remain within a one-pixel neighborhood of keyboard ink. At+6 both direct overlap and one-pixel adjacency are **zero through all six poses**. These are projection measurements: the keyboard draws behind the actor and is not literally painting over the face.
- The+6 column has a readable wood gap between face and keyboard and a separate monitor silhouette. The mouse remains a separate dark shape below. The keyboard is still a strongly vertical pale shape in this camera; placement improves its context but does not prove exact camera consistency with the north version.
- The+4 column looks more crowded beside Mina's face and Theo's head. The+8 column crowds the monitor and visibly weakens hand reach. No alternative changes the existing small upper-lap strip or chair support; those remain as documented in `CORRECTED_EAST_ASSEMBLY_REVIEW.md`.
- The selected layout does not maximize whole-hand overlap: at frame2+6 Mina has6/28 conservative hand samples over keys and Theo0/12, versus23/28 and11/12 at+0. That decrease is intentional evidence of moving keys away from the forearm/face; fingertip/outline evidence and the actual image determine whether the new placement is plausible.
- Caption material, headroom, native geometry and layer continuity remain unchanged. This recording is a short idle/typing loop, not a sit/stand, navigation or production room-placement acceptance test.

## Verification and boundaries

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_east_keyboard_placement.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/east-keyboard-placement/east-keyboard.avi --script res://tools/capture_east_keyboard_placement.gd
```

- Final headless: **537 checks, 0 failures**.
- Final rendered capture with the additional contour assertions: **1,247 checks, 0 failures**, process exited0. ffprobe confirms209 actual frames at30FPS,1280×720. This supersedes the initial1,211-check evidence run; visual placement is unchanged.
- **8 native captures +38 nearest4× details**: six poses ×six station details, plus two baseline details. `manifest.json` and `results-headless.json` retain exact observations and source hashes.
- Every actor/source region preserves exact pixel reunion; every device retains its original pixel hash. No production catalogue, actor registry, save or worker was changed. The production east direction stays unavailable.

For west-facing integration, the analogous idea is to move the independently authored west keys **toward its fixed monitor in negative world X**, then measure its own hands and contours. Neither copying6px blindly nor flipping the east raster is justified by this study.
