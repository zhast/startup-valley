# West supported layers — preferred static recipe

Reviewed 2026-09-04. This follows the [whole-body comparison](SUPPORTED_WEST_ASSEMBLY_REVIEW.md)
without changing it. **The preferred recipe passes this static contact/layer
review; it is not a runtime-facing approval.** Theo's existing source wobble and
the untested approach/sit/exit/placement integration remain explicit gates.

## Outcome

Use **Mina cut50** and **Theo cut48**, with the height56 chair and per-character
support offsets below. These cuts keep all of the reviewed hand-region pixels
in front of the keyboard while placing the lap/legs behind the desk. The entire
six-frame sequence was inspected at native size and4×. No white trousers or
green knees paint over the desktop with these preferred cuts.

Later cuts are worse: Mina52/54 leave21–49 measured lap pixels over the top;
Theo50/52 leave24–53. Their resulting white/green patches are visible in the
4× captures, not merely a threshold failure. Keep them as rejected comparisons.

The near-arm partition also resolves the earlier whole-chair paint-through:
the cushion/backrest stay behind the lower body, the small near arm is ahead of
the lower body but below the desktop and hands. The exposed-seat captures show
actual hip support; the assembled top is not hiding a known floating gap.

## Exact candidate sockets

All coordinates are native camera-space pixels. No source bitmap is rotated,
mirrored, repainted, resized at runtime, or independently trimmed per layer.

| Property | Mina | Theo |
|---|---|---|
| Physical work cell | `(1,0)` | `(1,0)` |
| Physical work foot relative desk | `(32,0)` | `(32,0)` |
| Chair foot relative physical foot | `(-12,0)` | `(-12,0)` |
| Actor foot relative chair foot | **`(0,4)`** | **`(0,8)`** |
| Actor visual foot relative physical foot | **`(-12,4)`** | **`(-12,8)`** |
| Unchanged actor canvas / pivot | `48×80 / (24,72)` | same |
| Upper source region in each cell | **`[0,0,48,50]`** | **`[0,0,48,48]`** |
| Lower source region in each cell | **`[0,50,48,30]`** | **`[0,48,48,32]`** |
| Candidate atlas | `mira-west-seated-v2.png` | `theo-west-seated-v3.png` |

For atlas frame `f`, add `f*48` to both source-region X coordinates. Upper draw
origin is `actor_visual_foot−(24,72)`; lower draw origin adds its original cut
row. Both use scale1. This retains the inherited full-cell origin instead of
recentering each cropped sprite.

The floor footprint remains `[-16,-48,32,96]` and the raised top remains
`[-16,-80,32,96]`. The physical work cell is outside that blocking footprint.
Only the visual assembly is pulled toward the work surface.

These Y values were checked against the actual source landmarks, not accepted
from an assumed common socket. Height56 W chair has seat outline97/blue98 and
pivot112, giving seat-top Y−15. Mina's estimated hip row53 plus4 minus72 is−15;
Theo's row49 plus8 minus72 is also−15. Their estimated two-pixel support bands
therefore land0…+2 px into the cushion in every staged frame. Estimates are
about±1–2 px and are not an authored skeleton/collision mask.

## Exact chair ownership and depth

Source is the complete `chair-west-v2-height56.png` on its unchanged96×160 canvas
and pivot `(48,112)`. The helper is
`game/tools/calibration_west_chair_layers.gd`, independent from the east helper.

Near-arm regions, measured from **west's actual image**:

- Bar: **`[39,89,13,4]`**. Opaque spans are Y89:X40–50, Y90/91:X39–51,
  Y92:X40–48:46 pixels.
- Stem: **`[44,93,4,10]`**, Y93–102:40 pixels.
- Rear: exact rectangle complement across the entire96×160 canvas.

The near arm owns86 opaque source pixels. Row103's continuous underside is
ambiguous seat/support material and deliberately remains rear. No invented
border or new color is added at that boundary. Every source pixel, including
transparent padding, has exactly one owner. Combining the parts restores the
original decoded RGBA byte-for-byte.

| Layer | Z relative desk anchor |
|---|---:|
| Chair rear/cushion/backrest | −5 |
| Actor lower body | −4 |
| Chair near arm | −3 |
| Desk rear/top | −1 |
| Keyboard/mouse and existing desk front | +1 |
| Actor upper body/hands | +2 |
| Monitor | +3 |

Keeping the lower body **above** the chair rear is essential. Moving the lower
body behind the whole chair would reintroduce a cushion painted across hips.
This is a source-region/depth contract, not a license to mask arbitrary limbs.

## Hands, seams and remaining issues

The older baseline skin-color filter was too sparse for Theo. This study instead
uses opaque pixels inside visually reviewed local rectangles: MinaX10–21/Y43–49,
TheoX7–21/Y39–47. They are conservative hand/wrist areas, not exact hand colliders.
All their opaque pixels remain in the preferred upper region in all six frames.

During typing, Mina has39–44 of73–79 sampled pixels over the inset key bed; Theo
has54–65 of96–111. Wrists need not all fall on keys, so these fractions are not a
progress or quality score. More importantly, native and4× inspection confirms
the fingertips reach the keyboard while the forearms retain a coherent shape.
No hand clipping is introduced by the preferred cut at the last→first typing
loop boundary, and source-image reunion is exact for every frame/cut.

The following are **not accepted by this study**:

- Theo's source hair/sole still changes by1 px between frames: frame0 has top4,
  sole70; frame2 has top5, sole71. The new partition preserves that defect; it
  does not create or solve it. Mina also has small original hair/face variations.
- These are static/six-frame supported endpoints, not approach, reservation,
  chair pull-in, sit-down, exit, or wall/corner collision tests. The visual
  `(-12,4/8)` displacement must be integrated with a real sit transition.
- The current production actor API's single sprite/Z ordering cannot simply
  receive one `seat_z_offset` and reproduce these layers. Runtime integration
  must preserve all region origins and the explicit depth ordering.
- West research/approval/delivery poses are outside this seated/typing review.
- No runtime catalogue/pose registration was changed. The source identity and
  original frames remain the same staged candidates, not newly approved art.

## Evidence and verification

Output: `game/tests/output/west-supported-layers/`. Native full screenshots,
all-frame contact sheets, exposed support and preferred4× loop strips were
reviewed. The full body/whole-chair baselines remain in their earlier folders.

- [Native three-cut comparison](../../game/tests/output/west-supported-layers/native-frame2.png)
- [Exposed chair support](../../game/tests/output/west-supported-layers/support-frame2.png)
- [All six native assembled frames](../../game/tests/output/west-supported-layers/all-six-native-native-contact.png)
- [All six native support frames](../../game/tests/output/west-supported-layers/all-six-support-native-contact.png)
- [Mina preferred cut50,4×](../../game/tests/output/west-supported-layers/native-frame2-mira-cut50-4x.png)
- [Theo preferred cut48,4×](../../game/tests/output/west-supported-layers/native-frame2-theo-cut48-4x.png)
- [Mina frames0–2,4×](../../game/tests/output/west-supported-layers/preferred-mira-frames0-2-4x.png)
- [Mina frames3–5,4×](../../game/tests/output/west-supported-layers/preferred-mira-frames3-5-4x.png)
- [Theo frames0–2,4×](../../game/tests/output/west-supported-layers/preferred-theo-frames0-2-4x.png)
- [Theo frames3–5,4×](../../game/tests/output/west-supported-layers/preferred-theo-frames3-5-4x.png)
- [Manifest with all36 records and region/depth definitions](../../game/tests/output/west-supported-layers/manifest.json)
- [Independent evidence checks](../../game/tests/output/west-supported-layers/verification.json)
- [296-frame30-FPS movie](../../game/tests/output/west-supported-layers/west.avi)

Each native contact grid has six columns (frames0–5) and six rows (Mina50/52/54,
Theo48/50/52). Every128×160 cell is a direct native crop; no scene is downscaled
to make a flaw disappear. The4× strips are exact nearest-neighbor enlargements.

```sh
godot --headless --path game --script res://tools/capture_west_supported_layers.gd
godot --path game --fixed-fps 30 \
  --write-movie res://tests/output/west-supported-layers/west.avi \
  --script res://tools/capture_west_supported_layers.gd
godot --headless --path game --script res://tests/test_west_supported_layers.gd
```

Results: **339 headless checks**, **2,175 rendered checks**, **198 independent
evidence checks**, all zero failures.27 native stills and12 primary4× details
were captured, plus the evidence test's native contact grids/four loop strips.
The movie has296 actual frames at30 FPS, including210 explicitly sequenced
frames plus capture settling.

Source reunion covers138,240 actor pixels (every frame and candidate cut) and
15,360 chair pixels including padding. Actual rendered reunion covers737,280
actor crop pixels across all six frames and122,880 chair crop pixels; every
decoded RGBA byte matches its original render. This proves registration and
ownership, not universal gameplay polish. There were no provider calls, save
accesses, source raster edits, new generated images or production changes.
