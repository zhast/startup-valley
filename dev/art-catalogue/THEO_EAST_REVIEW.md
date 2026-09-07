# Theo east seated/typing — final-alpha native candidate

Updated 2026-09-04 06:35 UTC. **Native calibration candidate only; not runtime approved or registered.** The initial batch stopped after one generation plus two failed targeted retries at06:23. Root subsequently explicitly authorized one final, third targeted retry; it succeeded with genuine alpha. All three earlier opaque outputs are retained and remain rejected. No request is outstanding. No local masks, semantic pixel painting, fake transparency or production changes were used.

## Inputs and intended contract

Inspected the established Theo seated master, his native locomotion atlas's east/right bottom row, Mina's native/4× east sheet, and `dev/art-catalogue/MIRA_EAST_REVIEW.md` before prompting.

- Theo identity: curly dark-brown hair, warm brown skin, orange open jacket, white shirt, olive trousers, cream/white sneakers. No seated satchel.
- Pose reference only: `game/tests/fixtures/furniture-calibration/characters/mira-east-seated-v3.png`. It is a calibration candidate, not runtime-approved art.
- Requested cell:48×80; shared68px character height; top y4; pivot(24,72).
- Requested geometry: strict right-facing seated profile; upright torso, horizontal thigh, right knee bend, vertical shin. Hip around(23,53); hands inside x29–39/y43–49; tiny finger alternation while head/torso/shoulders remain still. No high-arm shrug.

These are requested targets. Actual final native measurements and remaining acceptance limits appear below; source-alpha success alone does not certify animation or placement.

## Requests and durable outputs

All source paths below are under `game/assets/source/overnight-20260904/characters/`.

| Attempt | UTC timing | Source | Actual result |
| --- | --- | --- | --- |
| Original | Start06:20:07; returned/verified by06:21:02 | `theo-east-v1.png` |2172×724 RGB; useful east seated pose; painted checkerboard, rejected alpha. |
| Targeted retry1 | After06:21:02; returned/verified by06:21:58 | `theo-east-v2.png` |2172×724 RGB; background changed to another checkerboard; rejected. |
| Targeted retry2 | After06:21:58; returned/verified by06:22:44 | `theo-east-v3.png` |2172×724 RGB; checkerboard remains and character scale/position drifted slightly; rejected. |
| Explicitly authorized targeted retry3, final | Start06:32:03; returned/verified by06:33:24 | `theo-east-v4.png` |2172×724 RGBA; actual transparency, used for staging. |

Prompts: `dev/art-catalogue/prompts/theo-east-v1.md`, `theo-east-v2.md`, `theo-east-v3.md`, `theo-east-v4.md`. Both the second and third targeted retries used v1 again to avoid compounding failed cleanup. Retry3 used the short direct background-removal wording that succeeded for Theo west. No fourth targeted retry was made or is permitted for this asset.

Built-in originals are under `/Users/zhast/.codex/generated_images/01a069ca-7ec7-7252-827b-8a225a8e6fba/`:

- v1:`exec-5dbd18d7-b4e7-49e8-9960-bcd8b90fda9d.png`
- v2:`exec-3eb6185d-e686-4632-a354-3b5b10ada811.png`
- v3:`exec-09080a98-96c3-45c5-9087-71ee606e03fa.png`
- v4:`exec-9557d5e8-299b-4378-8f59-4a65e96a144e.png`

## Source-level visual observations

- v1 shows all six characters in a clear right-facing side profile with bent seated legs; it is not a mirrored south view.
- Orange/white/olive/cream clothing matches Theo, with no bag, desk, chair, keyboard, floor or prop.
- Arms stay low beside the waist and extend horizontally to the right. The source avoids the north candidate's shoulder-height hand/shrug issue.
- The first two idle poses are very similar. Later frames alternate the fingers and a small wrist reach. Hair highlights and hand reach vary; that is not proof of animation smoothness.
- The shoes project forward/right of the hip, as in Mina's side-view geometry. A future exporter must preserve this and not force the visible shoe center onto the inherited(24,72) pivot.
- v3 visibly changes source framing/scale despite background-only instructions; v1 remains the preferred pose source for any later authorized extraction attempt.

The earlier observations above were made at source size when alpha was still missing. Final native review follows; no in-room or motion approval is claimed.

## Final native export and reproduction

At06:23 the exporter deliberately exited1 and wrote no fixture because v3 was RGB/opaque. After the explicitly authorized successful extraction, `bash dev/tools/build_theo_east_calibration.sh` now consumes only v4, retains the opaque-source rejection guard, and reproduces the native calibration files. It does not consume v1–v3 or mask their checkerboards.

The mechanical process uses one shared source vertical crop y67/height564, one point scale to68px, a shared48-color palette, binary-alpha normalization and fixed48×80 cells. Measured alpha-column bands `(x,width)` are `(71,284)`, `(405,285)`, `(748,284)`, `(1092,284)`, `(1433,287)`, `(1779,286)`. Actual transparent gutters, not equal source-width divisions, define the six crops. Hair registration shifts frames0–3/5 by+4px and frame4 by+5px; no per-frame vertical stretching or semantic redraw.

Evidence in `game/tests/fixtures/furniture-calibration/characters/`:

- `theo-east-seated-v4.png`:288×80 native atlas, six48×80 frames.
- `theo-east-seated-v4-4x.png`:1152×320 exact nearest enlargement.
- `theo-east-frame0-8x.png`:384×640 enlargement for anatomy/landmarks.
- `theo-east-seated-v4-paper-4x.png`: diagnostic pale underlay, not a runtime texture.

Native SHA-256:`bcf40180294d72954a8e038c456fdc0db7faec9b5e2b99ac6ce59202b6096db8`.

## Measurements and actual native review

All six frames were inspected at100%,4× and on the pale diagnostic underlay; frame0 additionally at8×. The atlas has6,564 opaque and16,476 fully transparent pixels, zero intermediate alpha values and47 colors including transparency. All six complete frame hashes differ. No painted checkerboard, chair, desk, keyboard, floor or cast shadow remains.

| Frames | Opaque bounds `(x,y,w,h)` | Upper28px head bounds | Last opaque foot row |
| --- | --- | --- | --- |
|0–3,5|11,4,34,68|11,4,26,24|71|
|4|11,4,35,68|11,4,26,24|71|

Every frame has top opaque rowy4, last opaque rowy71,68px opaque height and head-centerx24. Bottom eight rows are transparent. Foremost shoe/finger pixels leave at least2px of right gutter. Unlike the west candidate, this row has no measured top/sole vertical wobble; small internal hair/face/highlight changes remain and still need animation review.

Approximate native anatomical landmarks (visual estimates,±1–2px):

| Landmark | Actual native region | Relation to requested Mina reference |
| --- | --- | --- |
| Shoulder | about(23,32–34) | Slightly above Mina's shoulder≈y35; character proportions differ. |
| Near elbow / wrist | about(24,45)/(29,46) | Low beside torso; no shoulder-height shrug. |
| Idle hands | approximatelyx29–38,y43–49 | Within the intended band. |
| Typing fingertips | approximatelyx29–41,y42–48 | Small reach can extend2px beyond requested x39; verify keyboard contact. |
| Hip / seat center | about(24,52) | Near Mina's≈(23,53), not proof of an identical socket. |
| Seat underside | approximatelyx18–31,y54–55 | Candidate chair-support band, not a collision definition. |
| Knee | about(35,53–55) | Clear horizontal thigh and90-degree bend. |
| Ankle / shoe | ankle≈(36,65), shoesx31–45 withsoley71 | Right-projecting feet, not centered on pivot. |
| Export pivot |(24,72)|Inherited cell convention, not the literal shoe center. |

## Disposition and final asset stop

- Correct genuine right-facing seated profile and Theo orange/white/olive/cream outfit; no raster mirroring or rotation was used.
- Alpha is now valid. Native pale-underlay inspection shows no prominent checkerboard or colored matte fringe after the shared normalizer. The original generated extraction can alter contour/highlight pixels, so source preservation is not asserted pixel-for-pixel.
- Native bounding registration is consistent. Hand reach/loop seam and internal hair/face variation still need cadence review; distinct hashes are not proof of smooth motion.
- Static hip/hand landmarks are close to the Mina reference, but exact support, desk contact and limb occlusion require an actual chair/desk composite. Do not change navigation feet or shrink the raster to force a fit.

Provisional still scores: pixel coherence2, projection3, silhouette/readability3, atlas anchors3, direction consistency3. Placement/layering and motion remain unscored. No overall runtime acceptance mean is claimed.

The asset stops here: one original request plus exactly three targeted retries total, all provenance retained. No additional retry, production registration, registry mutation, renderer, worker or save operation was performed. Root's assembly review owns any future enablement decision.
