# South seated assembly — supported source-layer candidate

Reviewed 2026-09-04. **Staged integration candidate, not production approval.**
This study combines the exact modular desk with existing production south
seated poses, the independent south chair and rear monitor, and the newly
drawn south keyboard/mouse. No production pose, furniture profile or save was
changed.

## Preferred next integration recipe

The physical work foot stays at desk origin + **(0,−32)**, outside the blocking
footprint. Use actor visual correction **(0,+12)** and chair correction
**(0,+4)** from that physical foot. These corrections are not navigation moves.
Both Mina and Theo retain their original six 48×80 cells and pivot **(24,72)**.
Upper rows **0–49** and lower rows **50–79** keep their original cell origin;
the lower draw position adds 50 rather than centering its cropped region.

| Piece | Z relative to desk origin | Native source / placement |
| --- | ---: | --- |
| Whole chair | −2 | `chair-south-v3.png`, 96×160, pivot (48,112) |
| Actor lower | 0 | Original seated atlas, rows 50–79 |
| Desk front/top | +1 | Exact south modular geometry |
| Keyboard and mouse | +2 | South peripherals v2, 192×224, pivot (96,160) |
| Actor upper/hands | +3 | Original seated atlas, rows 0–49 |
| Rear monitor | +4 | South computer v3, same canvas/pivot, origin Y +3 |

The real keyboard is **31×13**, not the north keyboard's 31×11. Its rectangle
is desk-relative (−16,−48,31,13), fully on the top. The monitor's support rows
remain on the desktop after its +3 shift. The rear monitor naturally hides
most typing hands and keys from this camera. Do not move hands in front of
the monitor simply to make the animation conspicuous.

## What the comparison actually shows

Columns compare actor/chair offsets +8/0, +12/+4 and +16/+8. Moving the chair
with the actor preserves the same estimated hip support, unlike the earlier
fixed-chair experiment: Mina is approximately 0…+3 px into the seat, Theo
−2…+1 px. Those are visual landmarks with a roughly 1–2 px tolerance, not an
authored skeleton. +12/+4 is the preferred moderate pull-in; +8/0 does not put
the sampled arm region over the keyboard, while +16/+8 adds unnecessary
occlusion without a demonstrated benefit.

For +12/+4, Mina's sampled warm arm pixels intersect the key rectangle in all
six frames (18–29 samples); Theo has 19–24 intersections. **Theo's orange
sleeves also satisfy that color filter**, so these counts are not proof of
exact fingertip contact. Native review confirms a coherent head/shoulder
silhouette above the monitor and no legs painted over the tabletop. The
whole-behind control hides additional upper-body pixels; the split preserves
the original hands above the desk while retaining normal monitor occlusion.

Source upper/lower reunification preserves every original byte for all 36
actor/frame/offset combinations. No pixels were erased, repainted, stretched,
mirrored or generated for the existing south actors. Native six-frame contact
review shows only subtle existing typing motion. Approach, actual sit/exit,
shadows, reservations, neighboring props and runtime pose switching remain
unverified by this endpoint study.

Provisional endpoint scores (0–3): pixel coherence **2**, perspective **3**,
silhouette **3**, layering/anchors **2**, directional consistency **2**,
placement **2**; mean **2.33**. This does not meet the complete runtime-facing
acceptance threshold. Finish and transition integration remain explicit work.

## Evidence and verification

- [Native six-frame preferred assembly](../../game/tests/output/south-actor-layers/contact-actor12-chair4-native.png)
- [Three-offset native comparison](../../game/tests/output/south-actor-layers/layered-frame2.png)
- [Exposed chair support](../../game/tests/output/south-actor-layers/support-frame2.png)
- [Whole-behind control](../../game/tests/output/south-actor-layers/whole-behind-frame2.png)
- [Measurements and limitations](../../game/tests/output/south-actor-layers/manifest.json)
- [204-frame, 30-FPS recording](../../game/tests/output/south-actor-layers/south-layers.avi)

`capture_south_actor_layers.gd` passed **74 headless** and **538 rendered**
checks, zero failures. Eight 1280×720 stills and the actual 204-frame movie
were saved. The preferred 960×320 contact sheet is six direct native crops
per actor, no scaling. Its initial ImageMagick montage emitted a missing-font
error despite writing an image; it was rebuilt successfully using plain
image append with no font dependency. Review is based on the native unique
frames and endpoint comparisons, not a claim of watching video playback.

All runs explicitly disable the worker and use an isolated TownRoom, never
GameMain or a personal save. No runtime approval flag was changed.
