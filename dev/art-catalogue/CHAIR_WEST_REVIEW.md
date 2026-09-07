# West-facing task chair — dimension-mismatch study

Status: **true-alpha native study; not a matching-view approval**. The bounded batch used one initial request and two targeted retries. No ImageGen call remains in flight. V2 supplies a real-alpha side sprite, but its proportions do not match the east chair at equal caster-base width. The final correction request lost transparency. This task stopped at the agreed limit without inventing alpha or stretching the raster.

## Generation and reference roles

The imagegen skill's built-in tool was used. Before the first request, both referenced sources were viewed:

- `game/assets/source/overnight-20260904/calibration/chair-east-v2.png` — side proportions, armrest, frame and base.
- `game/assets/source/overnight-20260904/calibration/chair-south-v3.png` — cushion and material identity for the same provisional ergonomic family.

West was independently generated with backrestright and seatleft. No local flip or rotation operation was used. Highlights remain concentrated on screen-upper-left surfaces, including the newly exposed cushion; the lighting was not intentionally mirrored with the geometry.

| Version | Before-call UTC checkpoint | Completion observed UTC | Duration | Disposition |
| --- | --- | --- | --- | --- |
| v1 | 2026-09-04 06:30:29 | 06:31:18 | 26.9s | 948×1659 RGB; opaque checkerboard rejected |
| v2 | 2026-09-04 06:31:33 | 06:32:37 | 37.2s | 1024×1536 RGBA; real alpha, taller-than-target study retained |
| v3 | 2026-09-04 06:33:30 | 06:34:01 | 21.2s | 948×1659 RGB; targeted proportion correction lost alpha, rejected |

Exact prompts: [v1](prompts/chair-west-v1.md), [v2](prompts/chair-west-v2.md), [v3](prompts/chair-west-v3.md). V2 requested background removal only; framing and color brightness changed, so pixel-preserving extraction is not claimed. V3 asked for a shorter lift/backrest while keeping base width and orientation, but its opaque result cannot be used as a transparent native asset.

Preserved sources: `game/assets/source/overnight-20260904/calibration/chair-west-v{1,2,3}.png`.

Tool originals remain in `/Users/zhast/.codex/generated_images/01a069ca-5125-71e1-9f6c-290ba248abf0/`:

- v1: `exec-5dd5d10b-f957-4878-90b2-bb518bd3cb96.png`
- v2: `exec-2da42d18-da64-4c02-9a1a-810f542d9a13.png`
- v3: `exec-ee318a57-e74c-4d06-8823-444575717263.png`

## Reproducible export and why whole width differs

```sh
bash dev/tools/build_chair_west_calibration.sh v2
```

The exporter uses genuine alpha at50% threshold, one whole-object crop, one uniform point scale, a bounded undithered palette and a shared registered canvas. It never synthesizes a semantic mask, trims future layers independently, mirrors, rotates or squashes a bitmap.

Unlike east, west's backrest extends horizontally beyond its caster base. The source's thresholded whole bounds are712×1361 at(159,66); the measured caster band (sourcey1120 downward) is657px wide. Scaling the **whole** width to32 would silently make the base too narrow. The builder therefore uniformly scales657px caster width to32px and registers the floor pivot to that base's center, preserving the rightward overhang. The native base width is asserted after export. This produces a35px-wide whole sprite, not an arbitrary32px fit.

| Property | Actual v2 native |
| --- | --- |
| Canvas | 96×160 RGBA |
| Floor pivot | (48,112), centered on caster base |
| Whole opaque bounds | 35×66 at(32,62) |
| Caster-base width | 32px, measured in the lowest15px band |
| Ground contact | Last opaque row127; exclusive boundary128 = pivot+16 |
| Backrest top | y62 = pivot−50 |
| Alpha | Binary0/1, exactly two values |
| Palette | 30 RGBA colors including transparency |
| Opaque connectivity | One8-connected component,938 pixels |
| Native output | `game/tests/fixtures/furniture-calibration/chair-west-v2.png` |
| 4× point preview | `game/tests/fixtures/furniture-calibration/chair-west-v2-4x.png`,384×640 |

Native and4× files were visually inspected. Source v2 has faint alpha haze outside the chair (nonzero extent879×1432 at49,62); thresholding the actual alpha removes it in the native export. Two runs produced identical native SHA-256. Shell syntax validation passed; an explicit v3 export attempt failed as expected with `Rejected opaque chair source`. No native outputs exist for v1/v3.

## Landmarks and explicit mismatch

Full-canvas coordinates below are observed features, not new semantic layer masks or approved actor sockets.

| Feature | West v2 | East v2 comparison |
| --- | --- | --- |
| Backrest top | y62 | y72: west10px taller |
| Back cushion blue pixels | x56–62,y63–88 | Narrow opposite-facing side cushion |
| Seat support outline | Abouty91 | Abouty96 |
| Seat blue top | y92,x36–54 | y97,x40–60: west5px higher |
| Seat cushion | x33–57,y93–98 | x39–62,y98–101 |
| Near armrest | Aboutx38–51,y82–86 | Higher than east armrest |
| Caster contact | y127 (boundary128) | Same128 boundary |

The prescribed target was opaqueheight56 and seatplane96–97 at32px caster width. This candidate isheight66 and seatplane91–92. **Both targets remain unmet**; the builder reports those dimensions instead of concealing the mismatch with nonuniform resize or a false floor anchor. A correct left-facing silhouette alone is not sufficient to approve the four-view set.

The west art still reads clearly as the same charcoal/indigo ergonomic design family, and there is no opaque backdrop in the native study. However, its taller back/lift and brighter blue need a future bounded correction or deliberate family redesign. No further correction is authorized within this completed batch.

## Integration limitations

- Keep this file available for diagnostic room/pose composition only, not production registration or catalogue approval. West remains unavailable as a reviewed runtime facing.
- At a trial walkable seat pivotP, the full-canvas origin is `P−(48,112)`. Do not move the physical collision/work cell to hide height mismatch.
- A work chair is visual assembly art on a reserved/walkable seat socket, not a blocking prop placed over the desk work cell.
- Real48×80 west seated actors, the desk, near-armrest occlusion, side hand placement and walk/sit transitions were not composited by this subtask. There are no front/back layer masks or reviewed `seat_anchor` values.
- Provisional isolated-art scores: pixel coherence2, projection3, silhouette3, native registration3, direction-consistency1 for the substantial height/seat mismatch. Placement and layering remain unscored; no acceptance mean is claimed.

## SHA-256

```text
fa42040db5276566b4142961bd88c4348a544140345763b6eb6726bffaec5346 chair-west-v1 source
d9398af92fb0b4585b69c818dc5b3ab9193d5ae8cdff3c6041841f80a2db02f5 chair-west-v2 source
154c86c538fc421b2db03c2c4e6749e153981ae0b6795c2d462e8d62a3cb1cbd chair-west-v3 source
c144d52673deadfc4ef1425864061b064355f398c30260704e5ffc698f666b1a chair-west-v2 native
```
