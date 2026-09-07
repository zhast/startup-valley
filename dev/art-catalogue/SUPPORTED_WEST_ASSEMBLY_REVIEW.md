# Supported west assembly — known blockers retained

Reviewed 2026-09-04. This is a developer diagnostic using the actual 32 px grid,
new west computer components, staged west poses, and two chair normalizations.
**Neither assembly is runtime approved.** No production profile, actor atlas,
renderer, logical cell, worker process or save was changed.

## Findings

1. **The logical seat belongs at desk `(+32,0)`, not the old off-grid `(+24,0)`
   reference.** The proposed 1×3 floor footprint is a logical axis exchange of
   the current three-cell desk footprint. The nearest open cell to its right is
   `(1,0)`. West-facing employees gaze left toward the top.
2. **An entire foreground actor cannot supply correct desk depth.** At X−8/−12
   render translation, the hands reach farther over the keyboard, but knees,
   shoes and some chair pixels paint over the tabletop. At X−12, the measured
   lower-body region overlaps the top by 206–220 pixels for Mina and214–221 for
   Theo during typing. This is visible in the native and4× evidence.
3. **Putting the whole actor below the top does not fix the work pose.** It hides
   the offending lower body but also cuts off hands/forearms where they should
   meet the keyboard. A complete-sprite Z change is insufficient.
4. **Putting the entire chair in front is also not a valid mask.** It paints the
   seat cushion across the actor's thighs and the armrest across their body.
   Keeping the whole chair behind loses appropriate near-armrest occlusion.
   These are layer-design issues, not missing floor collision.
5. **The height-normalized chair is a more coherent family candidate, not an
   automatic seat solution.** See [height study](CHAIR_WEST_HEIGHT_REVIEW.md).
   At unchanged actor/chair Y, Mina's estimated hip band is 2–4 px above the
   smaller chair and Theo's is6–8 px above. Support-preserving, per-character
   socket work is still required.
6. **Theo's source registration gap remains real.** Its first idle has hair at
   row4 and sole70; first typing has hair5 and sole71. The inherited pivot72
   does not remove that one-pixel wobble. There is no animation approval from
   merely having six different images.

## Exact comparison

Both runs retain logical work foot `(+32,0)`. Chair and body move together by
X0,−8,−12, with Y0 and no actor-relative-chair translation. This preserves their
relative pose relation while exposing hand reach. It does not move collisions
or reservations and does not claim those static endpoints are a polished sit.

| Part | Geometry/asset | Native registration |
|---|---|---|
| Desk | `modular_desk_geometry.gd`, west, generated soft oak | Top `[-16,-80,32,96]`; floor `[-16,-48,32,96]`; elevation32 |
| Monitor | `computer-west-v2-monitor.png` | Full192×224, pivot96,160; ink12×30 at81,108 |
| Keyboard | `computer-west-v2-keyboard.png` | Full192×224, pivot96,160; ink11×31 at99,115 |
| Mouse | `computer-west-v2-mouse.png` | Full192×224, pivot96,160; ink9×6 at99,103 |
| Mina | `mira-west-seated-v2.png` | Six48×80 cells, pivot24,72, no new scaling/registration |
| Theo | `theo-west-seated-v3.png` | Same cell/pivot; known one-pixel source wobble preserved |
| Baseline chair | `chair-west-v2.png` | Full96×160, pivot48,112; ink35×66 at32,62; caster span32 |
| Alternative chair | `chair-west-v2-height56.png` | Same full canvas/pivot; ink29×56 at35,72; caster span27 |

Computer components are complete independently generated objects, each uniformly
normalized to the actual family device dimensions. They are not nonuniformly
squashed or turned copies. The 11×31 keyboard is a meaningful improvement over
the separate east study's still-short keyboard: it exchanges the native north
keyboard's31×11 axes. All three west padded layers recombine byte-for-byte in
decoded RGBA to their registered whole kit; their absolute pixel coordinates
are preserved in the study.

Default diagnostic order is desk rear/top, chair, keyboard/mouse, actor,
monitor; desk front legs/apron stay foreground. Two extra controls deliberately
move either the entire chair in front or the entire actor+chair behind the top.
They expose why a single ordering cannot represent near/far limbs. No semantic
character cut, new mask or furniture layer was authored by this task.

## Contact measurements and limitations

Hip/underside rows are estimates, not skeletal metadata: Mina53–55, Theo49–51.
The baseline chair's observed outline/blue seat band is91–92; the smaller
alternative is97–98. All use chair pivot112.

| Chair | Mina hip minus seat | Theo hip minus seat | Interpretation at unchanged Y |
|---|---:|---:|---|
| Original32 px caster calibration | +2…+4 px | −2…0 px | Chair is visually tall, Mina's upper-hip band extends below its front edge |
| Uniform56 px body-height calibration | −4…−2 px | −8…−6 px | Better family proportions, but poses sit high, especially Theo |

The hand measurement uses a small left-side rectangle, X7–22/Y39–50, plus a
color filter. **It is not an exact hand collider or a fair cross-character
score.** It selects35–46 Mina pixels in typing frames but only1–5 Theo pixels
because the palettes differ. No decision that Theo cannot reach keys is derived
from that filter. Native4× views show his fingertips crossing the keyboard at
X−12; the lower-body/top collision is the reliable visible blocker.

Lower-body overlap counts use opaque pixels from source row51 onward against
the exact projected top rectangle. They describe wrong image depth while the
logical seat stays outside the blocked cells. They do not mean the navigation
body actually moved into a blocked cell.

## Evidence

Baseline output: `game/tests/output/supported-west-assembly/`.
Alternative output: its `height56/` subdirectory. Each contains16 native1280×720
stills,24 exact4× detail crops and a263-frame30-FPS movie. The file manifests
list36 measurements (two employees × three positions × six source frames).

The four **native-resolution** contact sheets were inspected to review every
idle/typing frame, with and without desk/kit, in both chair variants. No cell is
resized: each128×160 cell is a crop from the actual screenshot. Columns are
frames0–5; rows are MinaX0/−8/−12, then TheoX0/−8/−12.

- [Baseline: all six assembled frames](../../game/tests/output/supported-west-assembly/all-six-native-native-contact.png)
- [Baseline: all six support frames](../../game/tests/output/supported-west-assembly/all-six-support-native-contact.png)
- [Height56: all six assembled frames](../../game/tests/output/supported-west-assembly/height56/all-six-native-native-contact.png)
- [Height56: all six support frames](../../game/tests/output/supported-west-assembly/height56/all-six-support-native-contact.png)
- [Native comparison screen](../../game/tests/output/supported-west-assembly/height56/native-frame2.png)
- [Theo knees over desktop,4×](../../game/tests/output/supported-west-assembly/height56/native-frame2-theo-x-12-4x.png)
- [Mina knees over desktop,4×](../../game/tests/output/supported-west-assembly/height56/native-frame2-mira-x-12-4x.png)
- [Whole-body-below loses hands](../../game/tests/output/supported-west-assembly/height56/whole-body-below-top-frame2-theo-x-12-4x.png)
- [Whole-chair-front cuts into thighs](../../game/tests/output/supported-west-assembly/height56/whole-chair-front-frame2-mira-x-12-4x.png)
- [Baseline manifest](../../game/tests/output/supported-west-assembly/manifest.json)
- [Height56 manifest](../../game/tests/output/supported-west-assembly/height56/manifest.json)
- [Independent evidence checks](../../game/tests/output/supported-west-assembly/verification.json)

Representative full screens were inspected at native size to check context and
captions; all frame contact sheets plus six representative alternative4× crops
were inspected for support/depth. Captions have automated bounds checks against
every native assembly. This is not a claim that every one of48 detail crops was
manually inspected, nor a production walking/corner/wall test.

## Reproduce and next step

```sh
godot --headless --path game --script res://tools/capture_supported_west_assembly.gd
godot --path game --fixed-fps 30 \
  --write-movie res://tests/output/supported-west-assembly/west.avi \
  --script res://tools/capture_supported_west_assembly.gd
godot --headless --path game --script res://tools/capture_supported_west_assembly.gd -- --height-normalized-chair
godot --path game --fixed-fps 30 \
  --write-movie res://tests/output/supported-west-assembly/height56/west.avi \
  --script res://tools/capture_supported_west_assembly.gd -- --height-normalized-chair
godot --headless --path game --script res://tests/test_supported_west_assembly.gd
```

Each fixture passes224 headless and1,176 rendered checks. The independent
evidence suite passes272 checks across both variants, including exact4× crops,
known source drift, file/dimension coverage and native contact-sheet generation.
`ffprobe` independently confirms263 frames,30/1FPS,1280×720 for the alternative.
Passing checks validate the diagnostic while intentionally retaining its known
art/layer defects.

Keep west unavailable in production. The next bounded study should use the
height56 candidate, preserve its measured per-character support relation, and
evaluate registered upper/lower actor layers plus near-chair occlusion. Do not
solve the problem by moving logical feet into the desktop, scaling the actor,
mirroring east art, or declaring obscured contact a pass.
