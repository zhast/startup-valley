# Mina east seated/typing — staged native review

Reviewed 2026-09-04 06:11 UTC. **Native calibration candidate, not runtime approved or registered.** No ImageGen request remains in flight. Production CharacterArt and all north assets are unchanged.

## Generation and provenance

The imagegen skill's built-in path was used: one original atlas request and two targeted alpha-extraction retries, the allowed maximum. No CLI/API fallback, worker calls, saves, commits or pushes.

References were inspected before prompting: `game/assets/source/polish/mira-seated-master.png` for Mina's identity and sitting proportions; `game/assets/runtime/characters/mira-seated.png` for native scale; and row 3 (zero-based) of `mira-locomotion.png` for the existing east/right profile. Native contract: six 48×80 cells, 68px character height, export pivot (24,72).

| Attempt | Source under `game/assets/source/overnight-20260904/characters/` | Actual output | Disposition |
| --- | --- | --- | --- |
| v1 | `mira-east-v1.png` | 2046×769 RGB; opaque painted checkerboard | Pose reference only; rejected alpha |
| v2 | `mira-east-v2.png` | 2043×770 RGB; still opaque checkerboard | Failed targeted background extraction; retained |
| v3 | `mira-east-v3.png` | 2057×765 RGBA; genuine alpha | Staged native source; framing changed despite preservation instruction |

Requests: `dev/art-catalogue/prompts/mira-east-v1.md`, `mira-east-v2.md`, `mira-east-v3.md`. The final retry reused v1 as its target, avoiding another generation of the unsuccessful v2 framing drift.

Built-in originals remain under `/Users/zhast/.codex/generated_images/01a069ca-1fee-7e63-af23-27e16b028df6/` as `exec-fcfe6147-2332-4628-8e89-d8b2d83807d4.png`, `exec-5b944852-f5dd-4a62-9b2d-323b51f8e560.png` and `exec-53f77026-a484-4168-9168-9a999cf5e143.png`. Project copies above are the durable deliverables.

## Export and evidence

Run `bash dev/tools/build_mira_east_calibration.sh`. It adapts the existing seated export process without semantic painting: shared vertical crop y106/height545, one scale to 68px, one palette, binary-alpha normalization and fixed head registration. Source figures are not evenly spaced, so measured alpha bands are used: `(55,258),(330,257),(604,257),(896,258),(1204,257),(1500,255)` as x,width. All cells keep the same vertical crop and scale.

Staged files in `game/tests/fixtures/furniture-calibration/characters/`:

- `mira-east-seated-v3.png`: native 288×80 atlas, six 48×80 frames.
- `mira-east-seated-v3-4x.png`: exact 1152×320 nearest enlargement; all six frames inspected.
- `mira-east-frame0-8x.png`: exact 384×640 enlargement for landmark inspection.

Final native SHA-256: `1bcf88f00b52b635bd5cda51a29f7eb769f9b579eca47fcdb09b7e69080f0dd0`.

The native atlas has 47 colors including transparency, 6,531 fully opaque pixels and 16,509 fully transparent pixels. There are no intermediate alpha values. All six frame hashes differ. Every cell has identical opaque bounds `(12,4,32,68)` and head-region bounds `(13,4,22,24)`. Therefore head center is x24, top opaque row is y4 and bottom opaque row is y71 in every frame. Bottom eight rows and right four columns are fully transparent throughout; no forearm, knee, shoe or bun is clipped. The final native review shows no residual painted checkerboard, chair, desk, floor or shadow.

## Side-view landmarks for socket calibration

Coordinates below are in an individual native 48×80 cell. Head/opaque bounds are measured alpha bounds; anatomical landmarks are visual pixel estimates from the native/8× export, with roughly ±1px ambiguity at shaded edges.

| Landmark | Native coordinate/region | Interpretation |
| --- | --- | --- |
| Head registration | x24; head-region top y4 | Fixed across all six frames |
| Visible shoulder | about (22,35) | Upper cardigan at base of neck |
| Near elbow | about (22,47) | Bent arm beside torso, not a hanging standing arm |
| Hand contact band | x29–39, y43–49; neutral near (34,47) | Small alternating wrist/finger motion; use a surface slightly below the fingers |
| Hip/seat center | about (23,53) | Start of forward horizontal thigh; candidate chair-support location |
| Seat support underside | approximately x19–31 at y55 | Chair should support this region, not the shoes |
| Knee bend | about (37,54) | Thigh extends right then lower leg drops vertically |
| Ankle | about (36,66) | Lower leg ends above shoe |
| Shoe ground contact | x34–43, bottom opaque row y71 | Feet naturally project forward/right from the seated hips |
| Export pivot | (24,72) | Inherited cell-origin convention, **not the literal center of the east-facing shoes** |

That final distinction matters: forcing the drawn shoes to x24 would move the head/hips and break established registration. The north/east/south chair comparison must explicitly choose its socket and render offset while keeping navigation feet/reservations untouched. Do not call this pivot calibrated merely because the image has the expected dimensions.

## Visual disposition

- Correct right-facing profile and recognizably original Mina: high bun/gold tie, long dark hair, olive cardigan, cream trousers and brown shoes. No mirrored south pixels or three-quarter yaw.
- Seated silhouette is clear: horizontal thighs, bent knees, vertical lower legs and upright torso. It does not read as stretched standing legs or a walking pose.
- Hand reach stays compact and below shoulders/above thighs. Frames 4–5 (zero-based) visibly raise/alternate the wrists more than frames 0–3; hand/table contact and the loop seam require real animation review.
- Head and silhouette bounds are stable, but small face/hair-highlight differences remain between generated frames. Pixel/hash distinction is not a smooth-motion guarantee.
- True alpha extraction succeeded only on the last retry. Binary-alpha/palette normalization removes the source's visible soft fringe at native scale; retain the original for any later ImageGen correction.

Provisional scores: pixel coherence2, projection3, silhouette/readability3, atlas anchors3, within-atlas direction consistency3. Placement/layering remains **unscored** until the east chair/workstation composite is inspected at native scale. No overall runtime acceptance mean is claimed.

Next: composite all six frames with the east-facing desk/chair and tune explicit chair seat depth/anchor—not raster rotation or limb stretching. Inspect idle→typing→standing and the loop seam before enabling an east pose set. No further ImageGen retry was used in this bounded task.
