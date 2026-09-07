# East-facing task chair — staged native side-view review

Status: **native calibration candidate, not runtime approved**. The output is an independently drawn east/right-facing chair, not a rotation or mirror. No actor, desk, floor, runtime registry, catalogue approval or semantic layer masks were added. No request remains in flight. This batch used one initial request and one targeted retry; the second allowed retry was not spent merely to force a numeric seat height before a real composite exists.

## Generation and references

Built-in ImageGen was used under the imagegen skill. References were inspected before generation:

1. `game/assets/source/overnight-20260904/calibration/chair-north-v1.png` — rear shell, hardware and material identity.
2. `game/assets/source/overnight-20260904/calibration/chair-south-v3.png` — front cushion/seat and open support detail. Root assessed north/south as a provisional same ergonomic family, direction-consistency2 pending side comparisons; the3px top difference remains a calibration risk, not an automatic rejection.
3. `game/tests/fixtures/furniture-calibration/characters/mira-east-seated-v3-4x.png` — seated east pose for physical support only. No person is included in the chair.

| Version | Before-call UTC checkpoint | Completion observed UTC | Tool duration | Result |
| --- | --- | --- | --- | --- |
| v1 | 2026-09-04 06:25:39 | 06:26:18 | 19.9s | 971×1620 RGB; correct side orientation, opaque painted checkerboard rejected |
| v2 | 2026-09-04 06:26:33 | 06:27:23 | 36.2s | 1024×1536 RGBA; genuine alpha with faint source haze; native export available |

Exact prompts: [v1](prompts/chair-east-v1.md), [v2](prompts/chair-east-v2.md). V2 is a short background-extraction-only request. The generated image changed framing and brightness slightly; exact pixel preservation is not claimed.

Source files: `game/assets/source/overnight-20260904/calibration/chair-east-v1.png` and `chair-east-v2.png`.

Tool originals remain under `/Users/zhast/.codex/generated_images/01a069ca-5125-71e1-9f6c-290ba248abf0/`:

- v1: `exec-38c31251-a25e-4d9b-a4bc-a3ba52a41055.png`
- v2: `exec-64c97e8e-c62d-4cec-a51f-d66219e9a742.png`

## Export and actual measurements

```sh
bash dev/tools/build_chair_east_calibration.sh v2
```

The exporter rejects opaque sources, uses the real source alpha at50% threshold, applies one whole-object crop and uniform point resize to32px width, limits the palette without dithering, and registers the full sprite to the shared floor pivot. No independent part scaling, image turn, invented cutout or seat repositioning occurs. V1 fails with an explicit opaque-source error and has no native output.

| Property | Actual native v2 |
| --- | --- |
| Canvas | 96×160 RGBA |
| Fixed floor pivot | (48,112) |
| Opaque bounds | 32×56 at(32,72) |
| Backrest top | y72 = pivot−40 |
| Near caster contact | Last opaque row127; exclusive boundary128 = pivot+16 |
| Alpha | Exactly0/1, no partial pixels |
| Palette | 28 RGBA colors including transparency |
| Opaque components | One8-connected component,740 pixels |
| Native file | `game/tests/fixtures/furniture-calibration/chair-east-v2.png` |
| 4× point preview | `game/tests/fixtures/furniture-calibration/chair-east-v2-4x.png`,384×640 |

Source v2 has genuine partial alpha and a faint halo (nonzero extent841×1348 at111,54); the native threshold removes that haze. Native and4× exports were visually inspected. The intact silhouette contains the left backrest, right-projecting seat, near armrest, central stem and caster base. Two exports produced the identical native SHA-256. Shell syntax validation passed; rejection of v1 returned exit1 as expected.

## Seat/backrest landmarks and Mina support

Coordinates are full-canvas pixels. They describe observed features, not authored segmentation masks or approved sockets.

| Feature | Observed native location |
| --- | --- |
| Backrest shell | Left of seat, aboutx32–41; topy72 |
| Indigo back cushion | Measured blue pixelsx36–40,y73–93 |
| Near armrest | Aboutx45–57,y89–92, above the seat |
| Seat top support edge | Dark top outline aroundy96; blue top beginsy97,x40–60 |
| Seat cushion and near edge | Blue pixelsx39–62,y98–101; dark underside below |
| Gas lift and stem | Approximately centeredx48, below seat throughabouty117 |
| Caster base | Reaches the common32px width and contactrow127 |

The requested seat target wasy88 (pivot−24); this candidate's support edge is approximatelyy96–97 (pivot−16/−15), **8–9px lower than requested**. It was not warped upward to conceal that difference.

There is a reason to test the actual candidate before changing it: Mina's production-aligned cell top is `P.y−72`, her hip center is aboutcell y53, and her support underside aboutcell y55. At the shared floor pivotP=(48,112), that places the hip aroundy93 and underside aroundy95. The current chair surfacey96–97 sits1–2px below that underside. Horizontally her hip is aboutP.x−1 and the chair seat spans roughlyP.x−9 toP.x+15. This is promising **unshifted stand-in geometry**, not acceptance: real `seat_anchor`, hand/table contact, all six poses, armrest occlusion and walk/sit transitions may change the result.

The seat plane is also close to the south study's visible seat bandy95–105. Thus forcingy88 immediately could worsen N/S/E consistency. Root is performing the actual room/actor composite; this subtask did not render one or modify actor offsets.

## Visual disposition and remaining checks

- Correct cardinal side view: backrestleft, exposed cushion facesright, seat extendsright. No diagonal furniture yaw or mirrored screen-space lighting.
- Charcoal frame and indigo upholstery remain in the same provisional ergonomic family. East's cushion is a narrow side section, appropriately unlike a broad front or rear panel. Opaque heights are north55, south52, east56; corresponding top rows73,76,72 share contact128. Small size differences remain calibration risks.
- The near armrest crosses the prospective actor area and will need separate reviewed occlusion/layer treatment; one whole sprite cannot prove a proper body/arm relationship.
- The native gray stem/casters are thin and should be checked against actual floor contrast. Source extraction brightened the upholstery, so palette matching is still a visual review item.
- Do not place the chair as a blocking object on a desk work cell. Draw a visual assembly at a walkable/reserved seat socket. For a stand-in only, full-canvas origin is `P−(48,112)`.

Provisional isolated-art assessment: pixel coherence2, projection3, silhouette/readability3, native registration3, family consistency2. **Placement and actor layering are unscored**, so no acceptance mean or runtime-ready claim is made. West is still missing from this chair study.

## SHA-256

```text
1ebf116ec056feb11e487d7c087bf334458d2aebeaef35fad8227e3d4e334443 chair-east-v1 source
7776485322bf0a0863c4e3312618ba085bcdf5ee02287e93b749ea49f3323de8 chair-east-v2 source
758c7809813fe1510c4cb99a1f53c90bb7f9e34256f3fb1e0e940bd74936c23e chair-east-v2 native
```
