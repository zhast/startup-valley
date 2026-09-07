# Mina north seated/typing — staged native review

Reviewed 2026-09-04 06:04 UTC. Status: **native calibration candidate; NOT runtime approved or registered**. No generation is outstanding. Built-in ImageGen was used, once for the requested atlas and once for targeted background extraction. No CLI/API/provider calls, paid jobs, production art replacement or save changes.

## Sources and provenance

References inspected before prompting:

- `game/assets/source/polish/mira-seated-master.png`: existing Mina seated identity/proportions.
- `game/assets/runtime/characters/mira-seated.png`: current native south poses.
- `game/assets/runtime/characters/mira-locomotion.png`: exact north/back hair, outfit and native scale.
- `game/assets/runtime/characters/README.md`:48×80 cells, foot anchor(24,72).

| Version | Request | Returned file | Result |
| --- | --- | --- | --- |
| v1 | Original six-frame north atlas | `game/assets/source/overnight-20260904/characters/mira-north-v1.png` |2172×724 RGB, opaque painted checkerboard. Rejected for alpha; retained. |
| v2 | Background extraction only, preserve poses | `game/assets/source/overnight-20260904/characters/mira-north-v2.png` |2170×725 RGBA with genuine alpha. The model changed canvas dimensions slightly despite the preservation constraint. Used only as a staging source. |

Prompts: `dev/art-catalogue/prompts/mira-north-v1.md` and `mira-north-v2.md`.

Built-in originals remain at `/Users/zhast/.codex/generated_images/01a069ca-1fee-7e63-af23-27e16b028df6/exec-63003b3e-460c-4c50-bca6-e4619f651670.png` and `exec-e5000103-77c9-4650-9db3-98a4aa3e01b7.png`; project copies above are the durable sources.

## Mechanical export

Run `bash dev/tools/build_mira_north_calibration.sh`.

The script adapts the existing workstation export workflow: one shared vertical source crop(y106,height514), one scale to68px character height, one48-color palette, binary alpha threshold, native48×80 cells and bottom alignment at y72. No semantic drawing/retouching was performed outside ImageGen. Normalized output uses43 colors including transparency.

The generated row was **not evenly spaced**. A naive source-width/6 crop clipped the final figure's forearm; that rejected result is preserved as `mira-north-seated-v2-equal-grid-rejected.png`. Alpha-column projection identifies the six actual horizontal bands: `(78,222),(408,220),(745,262),(1103,252),(1438,264),(1783,261)` as x,width. The final export uses these bands with the shared vertical scale, then performs the existing head-center registration. It does not independently change body scale or vertical crop between frames.

Final staged files, under `game/tests/fixtures/furniture-calibration/characters/`:

- `mira-north-seated-v2.png`:288×80, six48×80 frames; native review.
- `mira-north-seated-v2-4x.png`:1152×320, exact nearest-neighbor enlargement; edge review.
- `mira-north-seated-v2-equal-grid-rejected.png`: retained failed equal-cell mechanical export; never consume.

Final atlas SHA-256: `067b7b8781b589bbcdc89a46a69d7531363882faab34ba4cc80e7a2c9718458f`.

## Measurements and inspection

All six native frames were viewed at100% and4× nearest scale. The final atlas contains9025 opaque and14015 fully transparent pixels, with **no intermediate alpha values**, no opaque checkerboard and no chair, table, tool, floor or cast shadow. All six complete frame hashes are distinct.

| Frame | Purpose | Opaque bounds(x,y,w,h) | Upper28px head bounds | Footbaseline |
| --- | --- | --- | --- | --- |
|0|Seated idle A|10,4,29,68|12,4,25,24|72|
|1|Seated idle B|10,4,29,68|12,4,25,24|72|
|2|Typing A|7,4,35,68|12,4,25,24|72|
|3|Typing B|8,4,33,68|12,4,25,24|72|
|4|Typing C|7,4,35,68|12,4,25,24|72|
|5|Typing D|7,4,35,68|11,4,26,24|72|

Head registration uses x24 as the integer center; odd/even head widths differ by half a geometric pixel in frame5. Top opaque pixel remains y4 throughout; bottom opaque row is71. Every frame retains a transparent top row and eight transparent bottom rows, and opaque bounds stay away from both horizontal cell edges. The repaired export includes the final forearm; no silhouette is cut by a cell boundary.

## Visual disposition and limits

- Identity: rear of Mina's high dark-brown bun/gold tie, long hair, olive cardigan, cream trousers and brown shoes match the supplied character. No mirrored face/back-facing fraud.
- Perspective: all six views face away/up, with no three-quarter yaw. Shortened lower legs and broad hip silhouette suggest seating, but **chair/desk compositing is still needed** to distinguish seated support from a compact standing silhouette conclusively.
- Animation: idle frames have tiny body/hair differences; typing frames visibly alternate the exposed hands. Most hands are partly hidden by her back/hair, as expected for a rear view. The transition from idle arms to typing arms and small hair-highlight variations still need animated in-room review; distinct PNG hashes do not prove smooth motion.
- Pixel cleanup: native edges are contained, and binary-alpha/palette normalization removes the obvious soft fringe. The hair remains relatively detailed; confirm flicker/readability at the intended animation cadence.
- Anchors: head top and foot baseline are stable. A north seat socket must be calibrated against real furniture, including hands/desktop contact and the chair back/front layers. No new direction capability was enabled by producing this sheet.

Provisional visual scores: pixel coherence2, projection2, silhouette/readability3, atlas anchors3, within-atlas direction consistency3. Placement/layering is **unscored pending actual room composite**; no overall acceptance mean or runtime-ready claim is justified yet. The south/north pair and all four directional poses still need common-scale review before family approval.

Recommended next action: use this fixture in the north workstation showroom with actual chair/layer metadata, inspect all six frames at native size, then approve or request one focused pose correction. Keep production `CharacterArt` south-only until that gate passes.
