# West chair — alternate uniform height calibration

Reviewed 2026-09-04. **Native alternate candidate, not runtime approval.** This
uses the existing genuine-alpha W2 source only; no ImageGen request, semantic
painting, rotation, mirror, nonuniform stretch or source replacement occurred.

## Why this alternate is legitimate

The original west export made its caster X-span32 px, matching the earlier
calibration target. That yielded a66 px-tall chair with a substantially higher
seat than east. However, a five-spoke caster base is not a rotationally symmetric
disk: its projected X-span need not be identical in every facing. Treating32 px
as an immutable physical width was an overly restrictive calibration assumption.

This independent alternate instead preserves the complete W2 object's aspect
ratio and normalizes its total opaque height to the observed east56 px. Its
smaller horizontal dimensions are measured outputs, not manually prescribed
axis squashing. The original32 px-caster export remains intact for comparison.

## Source and reproducible export

Source: `game/assets/source/overnight-20260904/calibration/chair-west-v2.png`,
1024×1536 RGBA; original thresholded bounds712×1361 at159,66. Original generation
provenance and failed attempts remain in [the baseline review](CHAIR_WEST_REVIEW.md).

```sh
bash dev/tools/build_chair_west_height_calibration.sh
```

The script thresholds genuine alpha, trims the entire object once, point-resizes
uniformly to height56, bounds the undithered palette to32 colors, measures the
lowest15 px caster band's width/center, and places the whole sprite onto the
same96×160 canvas/pivot48,112 with contact boundary128. The source and original
native are not modified.

| Landmark | Baseline W, caster-width normalization | Alternate W, body-height normalization | East reference |
|---|---:|---:|---:|
| Opaque body | 35×66 | **29×56** | 32×56 |
| Opaque origin | 32,62 | **35,72** | 32,72 |
| Caster span | 32 | **27** | 32 |
| Backrest top Y | 62 | **72** | 72 |
| Seat outline / first blue Y | 91 /92 | **97 /98** | 96 /97 |
| Contact boundary | 128 | **128** | 128 |
| Full canvas / pivot | 96×160 /48,112 | **unchanged** | unchanged |

The alternate caster span is X35–61; its integer pixel-center is48. The backrest
overhang reaches X63. The first blue seat row is98, with visible blue X37–54;
the wider cushion is aboutX36–55/Y99–102. These are measured landmarks, not
semantic front/back masks or accepted runtime sockets.

Native export has exactly two alpha values0/1,30 colors including transparency,
and no painted checkerboard. Both native and4× family comparisons were inspected.
It is visually much closer in body/seat proportions to east and the low-back
north/south studies. Its one-pixel lower seat and narrower apparent caster span
remain explicit differences to assess, not reasons to distort the image.

## Evidence and remaining contact work

- [Family comparison at native scale](../../game/tests/output/chair-west-height-study/family-native.png)
- [Same comparison at4× nearest](../../game/tests/output/chair-west-height-study/family-4x.png)
- [Alternate registered native](../../game/tests/fixtures/furniture-calibration/chair-west-v2-height56.png)
- [Alternate4×](../../game/tests/fixtures/furniture-calibration/chair-west-v2-height56-4x.png)
- [In-room support and layer study](SUPPORTED_WEST_ASSEMBLY_REVIEW.md)

Family contact-sheet order is **north, east, south, original west, height56 west**.
All share full96×160 canvases and fixed floor pivots; no visual re-centering or
new downscaling was applied to the references.

The in-room height56 study preserves actor/chair Y0 and tests joint X0/−8/−12
translation from the outside work cell. With that unadjusted support relation,
Mina's hip estimate is2–4 px above the seat and Theo's6–8 px above. The smaller
chair is therefore **not** a drop-in accepted replacement. Per-character seat
support, proper hand/leg depth, near armrests and sit/stand motion remain open.
Theo's one-pixel source head/sole changes are independent of chair normalization.

No production catalogue/pose registry was updated. The alternate is a stronger
direction-consistency candidate; assembly layering still fails the visual gate.
It must not be marked runtime-ready based only on matching height.

## Verification / SHA-256

Builder syntax and repeated export passed. The native image has binary alpha,
the expected29×56 body, measured27 px caster span and fixed contact128. The
alternate in-room harness passed224 headless/1,176 rendered checks; the combined
baseline/alternate evidence suite passed272 checks. Those tests verify evidence
and retained defects, not art approval.

```text
c144d52673deadfc4ef1425864061b064355f398c30260704e5ffc698f666b1a  original west native, unchanged
289aa8c0b15bd08392cae4f91830611c6ff8d5d4785bb4689f5824398a5c63ab  height56 alternate native
```
