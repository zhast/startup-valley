# Terrazzo v2 — exact edge pass, native repetition failure

Reviewed 2026-09-04. **Keep the production wood floor. Do not approve v2 as the replacement.** The normalized tile fixes the mathematical boundary contract, but creates visibly sparse bands every 128 pixels. Native whole-room review, especially the empty office, exposes an unintended large square grid. Passing image/geometry tests does not override this visual failure.

## Evidence and result

- [Empty office, v2 at native 1280×720](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-hires-0-office.png)
- [Two employees, v2](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-hires-2-office.png) / [mature office, v2](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-hires-4-office.png)
- [Open Chat, v2](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-hires-2-chat.png)
- [Baseline / v1 / v2 empty-office overview](../../game/tests/output/terrazzo-floor-review/comparison-hires-0-office.png) and [Chat overview](../../game/tests/output/terrazzo-floor-review/comparison-hires-2-chat.png). Overviews are half-size; the individual files are the native readability evidence.
- [Moving feet and shadows, native v2](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-walk-023-actors-native.png) / [nearest 4×](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-walk-023-actors-4x.png)
- [Actual walking start](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-hires-2-walk-000.png), [crossing](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-hires-2-walk-023.png), [arrival](../../game/tests/output/terrazzo-floor-review/terrazzo-v2-normalized-hires-2-walk-128.png)
- [Full manifest](../../game/tests/output/terrazzo-floor-review/manifest.json), [headless result](../../game/tests/output/terrazzo-floor-review/results-headless.json), [30-FPS movie](../../game/tests/output/terrazzo-floor-review/terrazzo-floor.avi).

Inspected all twelve native static views: baseline, v1 and normalized v2 at 0/2/4 hires plus each open-Chat view. Also inspected all seven native moving actor/shadow strips per material, the v2 enlarged crossing detail and native full-room start/crossing/arrival. The movie was recorded and frame metadata verified; this report does not claim continuous manual video playback or universal game polish.

### Concrete visual findings

| Priority | Native evidence/coordinates | Finding | Disposition |
|---|---|---|---|
| P1 | Empty v2 office, open area `(256,128)`–`(1024,512)`; repeated bands near `x=384,512,640,768` and `y=256,384,512` | Flecks recede near each plate boundary, creating a large faint square grid. This is a spatial density problem, not a one-pixel color discontinuity. It remains visible with furniture and is most obvious founder-only. | **Visual failure; keep staged.** A future source must continue fleck density through the perimeter without a blank moat. Do not fix this by weakening the exact-wrap check or repainting selected edges. |
| P2 | v2 two-employee office, Mina `(356,526)`–`(381,592)` and Theo `(740,526)`–`(766,592)`; name cards around `(336,600)`–`(400,639)` and `(720,600)`–`(784,639)` | The bright floor reduces value separation for cream shoes and paper. Existing dark shoe contours and pixel shadows remain visible; card borders and body text still read. | No actor/UI recoloring justified by this study. Keep the warm wood baseline; reevaluate bright-floor balance after the repeating bands are fixed. |
| Pass, bounded | All 21 walking checkpoint strips; v2 tick23 detail | Founder/Mina/Theo walk across 32px cells and the 512px plate boundary with visible grounded pixel shadows. Shoes do not disappear, and no filtered/smeared floor edge was found in sampled states. | Reuse current native locomotion and shadow source. This does not validate seated calibration shadows or other directions/lighting. |
| Pass, bounded | Three native Chat captures, right drawer `x=784` onward | Warm parchment remains visibly separate from the cooler cream floor; the wood drawer boundary is strong. Opaque paper/body region and HUD/rail ink are unchanged. | No UI material or typography change required for this comparison. |

The eight topmost rows contain **7.03% non-base-color pixels**, versus **15.94%** in the 112×112 interior. This supports the visible sparse-margin observation, but is not itself a perceptual acceptance threshold. The repeated native room and 3×3 source repeat show the actual failure. V1 has a more even overall texture distribution but still fails the exact boundary contract; it is not a valid fallback replacement.

Bounded v2 material score: pixel coherence **2**, perspective **3**, actor/material readability **2**, native registration/layers **3**, repeat consistency **1**, placement **3**. Mean **2.33**, with a category below 2: **fails art acceptance**. The general directional-furniture score is adapted here only to the floor’s repeating surface; there are no N/E/S/W floor drawings or furniture-facing claims.

## Source and mechanical normalization

Root supplied the [v2 master](../../game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v2.png) and adjacent prompt, the [builder](../tools/build_terrazzo_v2.sh) and [11-color palette](terrazzo-v2-palette.svg). This study made no ImageGen requests and changed no source bitmap.

The preserved [12-color native export](../../game/tests/fixtures/material-concepts/terrazzo-v2/cream-terrazzo-floor-v2.png) and [11-color normalized candidate](../../game/tests/fixtures/material-concepts/terrazzo-v2/cream-terrazzo-floor-v2-normalized.png) are each **128×128 RGB, fully opaque**. The second step globally merges only `#EBE4D5 → #EAE4D7`: exactly **10,536 pixels** differ, with **zero other changes**. It is not a selectively painted border. Both versions and their source remain preserved.

| Material | Colors | Different opposite-edge rows / columns | Mean linear luminance | Status |
|---|---:|---:|---:|---|
| Existing wood | 20 | 0 / 0 | 0.379 | Current production unchanged |
| Terrazzo v1 | 12 | 33 / 23 | 0.792 | Prior staged failure preserved |
| Normalized terrazzo v2 | 11 | 0 / 0 | 0.768 | Technical edge pass; visual repetition failure |

The existing 32px geometry samples this 128px image at native scale, with nearest filtering and no mipmaps or runtime scaling. Raw/decoded RGBA equivalence is asserted. Only the six newly staged v2 images were imported during preparation; no production art import setting changed.

## Actual-room and movement verification

New dev entry point: [`capture_terrazzo_floor_review.gd`](../../game/tools/capture_terrazzo_floor_review.gd), with [`test_terrazzo_floor_review.gd`](../../game/tests/test_terrazzo_floor_review.gd). It inherits only the existing isolated actual-GameMain setup and shared measurements from the original floor study. Output is a separate directory; the original v1 study remains frozen.

- Final headless: **1,383 checks, zero failures**.
- Final rendered: **1,562 checks, zero failures**, **2,657,633 actual pixel comparisons**, **33 states**, **79 PNGs**.
- Movie: **504 frames**, **30 FPS**, **1280×720**, **16.8 seconds**, independently confirmed with `ffprobe`.
- Twelve static states and seven movement checkpoints per material. Stage4 means mature furniture with the supported founder/Mina/Theo roster, not two fictional extra employees.
- Founder starts a real route from mouse input. Employees use the actual scheduled `walk_to` path API. Their production movement methods are stepped deterministically at 30Hz; the fixture disables automatic scene physics between steps. No actor is repositioned along the route and no walking source frame is invented.
- Initial walking feet are `(432,368)`, `(432,464)`, `(432,560)`; targets are the corresponding points at `x=624`. Every step is navigation-safe, each route finishes at its target, and sampled poses/positions contain at least three distinct source cells/positions per actor. Sampling avoids simply revisiting one phase of the 8Hz gait.
- Across all three materials, sampled physical positions, sprite regions, shadow regions and integer render positions are identical. Existing standing/walking shadow behavior is used; no new default-off seated-shadow policy is enabled.
- Floor samples spanning both 32px and 128px boundaries equal the native texture. Outside-floor architecture pixels, HUD/rail ink, and the opaque Chat paper/body region remain byte-identical to the matching baseline. Geometry/navigation/layout signatures are unchanged by material selection.
- Production floor, logical JSON, v1/v2 native textures, v2 original master and architecture source hashes are preserved. Production floor SHA-256 remains `6202478639de33fe7f8b548b49a20dddff6b69b59300300bcc89cfa064f2d0bd`; normalized staged v2 is `13d436fdb317409d10dc4d68a9f1e4008a836d43fb271c3433ab7b5f597fd089`.
- No worker, credential read/write or personal save is used. Credential-ready is only an explicit local UI projection inherited from the old fixture. Existing onboarding/UI mechanics are not tested through a live backend.

The first batch is retained under `game/tests/output/terrazzo-floor-review-initial`. Native inspection caught two fixture-only evidence defects: a tall actor crop included a neighbor at its edge, and total scene freeze stopped the normal half-second click-marker timeout. Final crops use 96×112 per actor; the fixed step advances the existing click-feedback timer and asserts expiry. All twelve final static PNGs remain byte-identical to the first batch. No material, character, production UI, path, or geometry changed to correct these evidence defects.

```sh
godot --headless --fixed-fps 30 --path game \
  --script res://tests/test_terrazzo_floor_review.gd
godot --fixed-fps 30 --path game \
  --write-movie res://tests/output/terrazzo-floor-review/terrazzo-floor.avi \
  --script res://tests/test_terrazzo_floor_review.gd
```

No catalogue approval, production floor replacement or new UI/furniture interaction was made. The next useful art correction is uniform fleck density through the tile boundaries, followed by the same native empty/full-room review—not another broad material batch or an automatic promotion based on test counts.
