# Theo west seated/typing — native candidate with registration gaps

Reviewed 2026-09-04 06:30 UTC. **Calibration fixture only; not runtime approved or registered.** One original built-in ImageGen request and two targeted alpha-extraction retries were used, the allowed maximum. No image request is outstanding. No local masks, pose repainting, mirroring, production changes, worker jobs, saves, commits or push.

## Identity, reference roles and generation

Inspected before prompting:

- `game/assets/source/polish/theo-seated-master.png`: Theo's curly dark-brown hair, warm brown skin, orange open jacket, white shirt, olive trousers and cream/white sneakers. No seated bag.
- `game/assets/runtime/characters/theo-locomotion.png`: zero-based row2 is the actual west/left profile; identity/direction reference only, not its standing pose or satchel.
- `game/tests/fixtures/furniture-calibration/characters/mira-west-seated-v2.png`, its4× enlargement and `dev/art-catalogue/MIRA_WEST_REVIEW.md`: measured seated geometry reference, not Theo identity or runtime approval.

| Attempt | UTC timing | Durable source under `game/assets/source/overnight-20260904/characters/` | Result |
| --- | --- | --- | --- |
| Original | Start06:24:22; returned/verified by06:25:41 | `theo-west-v1.png` |2172×724 RGB; strong left seated pose but opaque checkerboard. Rejected alpha. |
| Retry1 | After06:25:41; returned/verified by06:26:41 | `theo-west-v2.png` |2137×736 RGB; another checkerboard and changed canvas. Rejected alpha. |
| Retry2 | Start06:26:54; returned/verified by06:28:06 | `theo-west-v3.png` |2172×724 RGBA; genuine transparency. Staging source. |

The final retry used the original v1 again and a shorter background-removal instruction. All prompts are retained as `dev/art-catalogue/prompts/theo-west-v1.md`, `theo-west-v2.md`, `theo-west-v3.md`. Generated extraction preserves the recognizable poses/outfit but is not pixel-identical preservation; opaque contour/highlight changes remain visible.

Built-in originals remain under `/Users/zhast/.codex/generated_images/01a069ca-7ec7-7252-827b-8a225a8e6fba/`:

- v1:`exec-00eb45c2-8716-4ec2-9f15-015171dbaad4.png`
- v2:`exec-f6ff6178-b39c-4630-b165-f4a63cc1e00d.png`
- v3:`exec-036c218d-4e66-4c61-b0e9-b8563f9c4cb4.png`

## Reproducible native export

Run `bash dev/tools/build_theo_west_calibration.sh`. The script follows the existing seated/Mina export: shared source crop y79/height544, one point resize to68px, a shared48-color palette, binary-alpha normalization, fixed48×80 cells and upper-hair horizontal registration. It does not stretch individual limbs, normalize each body's height separately, manufacture an opposite direction, or repaint the background.

Actual source alpha-column bands `(x,width)` are `(55,279)`, `(414,278)`, `(787,281)`, `(1151,283)`, `(1504,275)`, `(1832,280)`. All frames use the same vertical crop and scale. Horizontal head registration shifts each frame−5px. Transparent source gutters, not equal source-width divisions, define the crops.

Evidence under `game/tests/fixtures/furniture-calibration/characters/`:

- `theo-west-seated-v3.png`:288×80, six native48×80 frames; first2 idle, next4 typing.
- `theo-west-seated-v3-4x.png`:1152×320, exact nearest enlargement.
- `theo-west-frame0-8x.png`:384×640, native-frame enlargement for anatomy/landmarks.
- `theo-west-seated-v3-paper-4x.png`: diagnostic-only pale underlay for fringe inspection, not a runtime texture.

Native SHA-256:`889b5163cda84ef4d366acef86ca34133a7ac8133d483871da9cf319498c6dff`.

## Measurements and native review

All six frames were viewed at100%,4× and on the pale diagnostic underlay; frame0 additionally at8×. The atlas contains6,346 opaque and16,694 fully transparent pixels, **no intermediate alpha**, and46 colors including transparency. All six full-frame hashes differ. No painted checkerboard, chair, desk, keyboard, floor or cast shadow remains. No opaque pixel touches any cell edge, although the forward shoes leave only1px of left gutter in five frames.

| Frame | Opaque bounds `(x,y,w,h)` | Upper28px head bounds | Last opaque foot row |
| --- | --- | --- | --- |
|0|1,4,35,67|12,4,24,24|70|
|1|1,4,35,68|12,4,24,24|71|
|2|1,5,35,67|13,5,23,23|71|
|3|1,5,35,67|13,5,23,23|71|
|4|2,5,34,67|13,5,23,23|71|
|5|1,4,35,68|13,4,23,24|71|

The inherited export pivot remains `(24,72)` and the shared normalization height is68px. **This does not mean every opaque body is68px or every head/sole is stationary:** frame0 has a one-pixel higher sole; typing frames2–4 begin their hair at y5 instead of y4. These differences are retained and reported, not silently stretched away. Odd-width heads also have a half-pixel geometric-center difference despite integer x24 registration.

## Actual landmarks and deviations from requested Mina geometry

The following are visual pixel estimates (roughly±1–2px) from the native/8× evidence, not validated socket or collision metadata.

| Landmark | Theo west observed native region | Calibration consequence |
| --- | --- | --- |
| Head | x24 integer registration, topy4–5 | One-pixel inter-frame vertical change still needs correction/review. |
| Shoulder | approximately(26,31–33) | Theo lacks Mina's tall bun; equal overall height does not align anatomy automatically. |
| Near elbow / wrist | about(25,43)/(18,44) | Low beside torso, not shoulder-height shrug. |
| Idle hands | approximatelyx10–22,y41–46 | Slightly above requested Mina bandy43–49. |
| Typing fingertips | approximatelyx7–21,y39–47 | Some frames extend/lift more than a tiny finger twitch; verify keyboard contact and loop seam. |
| Hip / seat center | approximately(24,49) | About4px above Mina's measured hip≈y53. Do not blindly share a seat socket. |
| Seat underside | approximatelyx14–27,y50–51 | Chair support needs actual composite review. |
| Knee | approximately(9,49–52) | Clear horizontal leftward thigh and bent knee. |
| Ankle / sole | ankle≈(8,65), shoe x1–14, sole y70–71 | Shoes intentionally project left of inherited pivot. |

The requested landmarks were hip≈(25,53), hands x10–21/y43–49, stationary head/torso and baseline. The actual native sheet **does not fully meet that anatomy/registration request**, even though identity, alpha and left-facing seating are useful. It should not be registered as a shared calibrated west pose set until those differences are evaluated with the actual chair/desk.

## Visual disposition and remaining gates

- True newly generated left-facing profile, with correct curly hair and orange/white/olive/cream outfit; no east raster reflection was used. Highlights remain on upper portions rather than being mechanically reversed.
- Upright torso, horizontal thigh, right-angle knee and forward-left shoes read clearly as seated.
- Native pale-background inspection shows no prominent red/green alpha fringe after the shared point/palette/binary-alpha normalization. Original masters remain available for a later explicit ImageGen correction.
- Source-level tiny variations become visible one-pixel head/foot changes and several-pixel hand reach at native size. Distinct frame hashes are not a smooth-animation guarantee.
- The different hip/hand height is a real calibration gap. Do not cure it by arbitrary runtime scaling or changing physical navigation feet. A reviewed per-character visual socket may address static placement; it does not by itself remove inter-frame wobble.

Provisional scores: pixel coherence2, projection3, silhouette/readability3, atlas registration1, within-atlas direction consistency3. **Registration does not pass the polished threshold. Placement/layering and motion remain unscored** until the actual west workstation assembly. No overall mean or runtime-ready claim is made.

The bounded task stops here with its retry budget exhausted. Next decision belongs to the root assembly review: retain this as pose reference, or authorize a narrowly specified registration/landmark correction later. Production remains south-only until real art and pose gates pass.
