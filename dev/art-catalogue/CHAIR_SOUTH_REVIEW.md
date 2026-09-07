# South-facing task chair — bounded calibration study

Status: **native study only; not a matching four-view approval**. One initial request and two targeted retries were used. No further requests are pending. No catalogue, production registry, collision, actor poses or runtime-facing capability were changed.

The built-in ImageGen skill generated the original art. The north v1 source was inspected and attached to the first south request to establish identity; the south view was independently drawn, never a raster flip or rotation. Two reference/edit outputs painted opaque checkerboards. The final request omitted those backdrop-bearing attachments and described the established chair. That recovered true alpha, but changed some chair geometry, so the result must not be represented as the same finished chair from both directions.

## Requests and provenance

Times are UTC observations, not inferred service timestamps. All sources were copied into the repository without deleting the tool originals.

| Version | Before-call checkpoint | Completion observed | Tool duration | Result |
| --- | --- | --- | --- | --- |
| v1 | 2026-09-04 06:19:44 | 06:20:23 | 21.7s | 957×1644 RGB; front view reads correctly, opaque checkerboard rejected |
| v2 | 2026-09-04 06:20:48 | 06:21:15 | 15.9s | 956×1645 RGB; alpha-only retry still opaque, rejected |
| v3 | 2026-09-04 06:21:44 | 06:22:30 | 33.7s | 1101×1429 RGBA; true-alpha front-view study, native export available |

Sources: `game/assets/source/overnight-20260904/calibration/chair-south-v{1,2,3}.png`.

Exact prompts: [v1](prompts/chair-south-v1.md), [v2](prompts/chair-south-v2.md), [v3](prompts/chair-south-v3.md).

Tool original directory: `/Users/zhast/.codex/generated_images/01a069ca-5125-71e1-9f6c-290ba248abf0/`.

- v1: `exec-8f271d8d-ce01-49ff-8b5c-da604943bdda.png`
- v2: `exec-6ee4785c-5a73-46c4-877e-2c3c463e487a.png`
- v3: `exec-a80c590e-2c53-4b9e-b1ee-b3c79a9b03fe.png`

## Reproducible native export

```sh
bash dev/tools/build_chair_south_calibration.sh v3
```

The script rejects opaque sources, thresholds existing alpha at50%, crops once, uniformly point-resizes to32px wide, limits the palette to32 colors without dithering, then registers the whole sprite on the common canvas. It does not invent an alpha cutout, separate chair parts, stretch axes independently, mirror, rotate, recolor semantically or approve anything. V1/v2 have no native exports. An explicit v1 run failed as expected with `Rejected opaque chair source`.

| Property | Measured v3 export |
| --- | --- |
| Canvas | 96×160 RGBA |
| Floor pivot | (48,112) |
| Opaque bounding box | 32×52 at(32,76) |
| Bottom contact | Last opaque row127; exclusive boundary128 = pivot+16 |
| Top | y76 = pivot−36 |
| Alpha | Binary0/1, exactly two values; no opaque background |
| Palette | 30 RGBA colors including transparency |
| Opaque connected components | One8-connected component,891 pixels |
| Enclosed transparent gap | 6×2 at(45,92), between back and seat |
| Native file | `game/tests/fixtures/furniture-calibration/chair-south-v3.png` |
| 4× point preview | `game/tests/fixtures/furniture-calibration/chair-south-v3-4x.png` (384×640) |

Native and4× files were visually inspected. Two independent builder runs produced the same native SHA-256. The original v3 nonzero-alpha extent was916×1200 at(49,149), including faint generated residue; the thresholded foreground, not that residue, determines the native silhouette.

## Landmarks for composition, not seat approval

Coordinates below refer to the full96×160 canvas; ranges are visual landmark estimates, not authored layer masks.

- Back cushion top is y76; rounded indigo front and charcoal rim extend to abouty91. There is no rear adjustment bracket on the front cushion.
- Two upright supports and the genuine transparent opening separate back and seat aroundy92–94.
- Seat top and its near edge occupy roughlyy95–105, centered nearx48. Armrests sit on either side above the seat, with support arms continuing beside it.
- The height lever remains on screen left below the seat. The central gas-lift stem occupies approximatelyy108–116; caster spokes/feet continue throughy127.
- These are **not** a `seat_anchor` or body/hand socket. Root still needs to compare the actual48×80 actor, production frame origin−32 and directional seated poses. The same contact baseline alone cannot establish a correct seat height.

For an exploratory composition at a walkable seat pivotP, draw this entire canvas at `P−(48,112)`. This is visual calibration only: do not place a blocking chair prop on the desk's reserved `work_cell`. A final work chair is a visual assembly associated with that socket.

## Comparison with north v1 and remaining gaps

North v1 is32×55 with topy73 and the same bottom contact128. South v3 is3px shorter, has a rounder/shorter exposed back cushion and an open gap between back and seat; north's rear silhouette is more enclosed. Some change is expected from the opposite view, but the current amount has **not** been proven as one consistent 3D object. The v3 upholstery highlights are also a little brighter. Both share charcoal/indigo materials, armrests, a five-star base and upper-left lighting, but the backrest identity and seat-plane height need a common redraw before a directional pair can be approved.

At native size the seat and chair front remain recognizable. The checker-like cloth texture is busy, and the thin lift stem/casters must be checked against actual floor values. No in-room or seated-actor screenshot was produced by this subtask; root is performing that separate calibration. There are no registered rear/front layers, occlusion masks, idle/working poses or runtime acceptance claims.

Disposition: retain v3 for **scale/front-seat composition testing**; retain v1/v2 as rejected provenance. This bounded asset attempt is finished, not the four-view chair family.

## SHA-256

```text
9af922e1e5b87d76b626020581b0e1d99dd986a5b27d1d7462baf44d7fb2cc4f chair-south-v1 source
3d2fbacb2badc90441a4ffcdf9fa4418fd0b0ce05199290596c6cd2412361bd7 chair-south-v2 source
2e1f303c4f5eaab64d65a02c6ea003776efc72fd38c0b9a6a61cf4d9c95f248b chair-south-v3 source
5f38ea8b91ec3e2e80c23df4cb2c7b3d1b0f5f30afb27201c614f39e5f23d448 chair-south-v3 native
```
