# Theo west one-pixel registration study

Status: **source-aware registration is the preferred next integration candidate; fixed-cut replacement rejected**. No production assets, facing metadata, source atlas, or prior supported-west study changed. The follow-up preserves the original upper/lower ownership under the translation as well as the pixels themselves. It resolves the foreground stripe described in the first comparison below. This is not a runtime-approved atlas or assembly.

## Preferred follow-up: translate layer ownership too

Run the same harness with `--source-aware-cuts`. Evidence is preserved separately in `game/tests/output/theo-west-registration/source-aware-cuts/`; the first fixed-cut failure remains intact.

| Frame | Atlas Y translation | Registered upper cut | Registered lower region within cell |
|---|---:|---:|---|
| 0 | 0 | 48 | `[0,48,48,32]` |
| 1 | 0 | 48 | `[0,48,48,32]` |
| 2 | −1 | 47 | `[0,47,48,33]` |
| 3 | −1 | 47 | `[0,47,48,33]` |
| 4 | −1 | 47 | `[0,47,48,33]` |
| 5 | 0 | 48 | `[0,48,48,32]` |

Upper regions are `[0,0,48,cut]`; add `frame*48` to atlas X. Lower placement must add its own cut to the shared48×80 cell origin, not recenter the cropped part. The candidate's translation is already baked into its cells: **do not apply the Y translation again at runtime**. The visual foot remains physicalworkfoot+(−12,+8);chair remainsphysicalworkfoot+(−12,0). Existing west chair regions and depths below are unchanged.

This is not a newly guessed anatomical cut. A padded upper mask and padded lower mask are built separately from oldcut48,translated by the exact cellYoffset,and compared byte-for-byte with the newatlas's respective regions. Each mask independently inverts to the original. Full-cell inverse preservation still passes. The62 source checks include these24 additional per-layer ownership checks.

Native outcome: the registered head silhouette stays atrow4 while typing; the fixed-cut green stripe is absent in all6 source-aware assemblies. Foreground lap ROI counts are zero for all12 original/registered samples. All measured hand-region pixels stay above the top, with the same65/64/54/63 typing-key overlap counts as before. Source-aware upper/lower union has no invented seam or missing pixels. The physical hip estimate remains−1…+1px into/around the seat in shifted frames,otherwise0…+2px,which stays within the manually reviewed support tolerance. The exposed-support frames retain a one-pixel shoe/cushion phase difference; this is visible when the desk is removed and is not claimed fixed.

Registration category recommendation: **2 (usable with a minor remaining source variation),previously1** for the preferred assembled seated/typing candidate only. This recommendation is based on six native states and typing5→2/idle→typing endpoint inspection,not on checksums or a broad animation approval. It does not authorize runtime facing metadata; approach,sit/exit,other work states,and full office occlusion remain later integration gates.

Source-aware verification:62 source checks;239 headless assembly checks;674 rendered checks;152 combined source/evidence checks,all zero failures. Output contains6 native screenshots,36 nearest4×details,and3 native contact sheets;the233-frame30FPS1280×720 movie is dimension/frame-count verified. All6 full source-aware screenshots,all3 six-frame native contact sheets,and representative4×assembled/support plus first/last typing details were visually inspected. Actual video playback was not claimed.

Registered native SHA256: `36fcf36849f83ce0a11dbcb60626677fe83cdd05b6aa9b50c9c91174551ad5ad`.

```sh
godot --headless --path game --script res://tools/capture_theo_west_registration.gd -- --source-aware-cuts
godot --path game --fixed-fps 30 --write-movie res://tests/output/theo-west-registration/source-aware-cuts/theo.avi --script res://tools/capture_theo_west_registration.gd -- --source-aware-cuts
godot --headless --path game --script res://tests/test_theo_west_registration.gd -- --verify-capture --source-aware-cuts
```

## First comparison retained: fixed cut48

## Exact operation

- Original: `game/tests/fixtures/furniture-calibration/characters/theo-west-seated-v3.png`.
- Separate candidate: `game/tests/fixtures/furniture-calibration/characters/theo-west-seated-v3-registered.png`.
- Six48×80 cells, unchanged common foot pivot(24,72),288×80 total canvas.
- Integer Y translations by frame: `[0,0,-1,-1,-1,0]`. No rescaling, recoloring, repaint, mirroring, or row substitution.
- Builder: `dev/tools/build_theo_west_registration.sh`; original source checksum remains `889b5163cda84ef4d366acef86ca34133a7ac8133d483871da9cf319498c6dff`.
- Each translated frame preserves all opaque pixels and padding. Inverting its translation reproduces every original RGBA byte:23,040 cell pixels checked in each direction.

## Unchanged physical/layer recipe

The comparison deliberately retains the preferred west recipe from `WEST_SUPPORTED_LAYERS_REVIEW.md`: logical work footdesk+(32,0); chair relativeworkfoot(−12,0); Theo relativechair(0,+8); upper rows0–47,lower48–79. The height56 west chair uses exact near-arm regions `[39,89,13,4]` and `[44,93,4,10]`, with its source-preserving complement behind. Depth order is rear chair−5,lower actor−4,near arm−3,desktop−1,key/mouse+1,upper actor+2,monitor+3. No source-aware cut compensation was quietly introduced.

## Native findings

| Measurement | Original | Registered candidate |
|---|---|---|
| Head-top rows,frames0–5 | 4,4,5,5,5,4 | 4,4,4,4,4,4 |
| Last sole rows | 70,71,71,71,71,71 | 70,71,70,70,70,71 |
| Hip-minus-seat estimate | 0…+2px | shifted frames−1…+1px;others0…+2px |
| Foreground lap ROI over top | zero,all6 | 13,13,12pixels inframes2,3,4 |
| Reviewed hand ROI on keybed,typing2–5 | 65,64,54,63 | unchanged65,64,54,63 |

The head no longer drops one pixel in frames2–4; the source and exposed-support six-frame plates make that clear. The lower legs and shoes still have a one-pixel phase difference: registration shifts the typing soles up while frame5 remains at71. Those lower pixels are hidden by the assembled desk but visible in the exposed-support column. Seat support remains within the prior approximate contact band; this does not prove exact skeletal landmarks.

The unchanged upper cut48 now includes old row48 at new row47. It is an actual green/dark lap strip above the tabletop in registered frames2–4, not just a hash difference. In `frame2.png` the defect is the one-pixel horizontal strip around x267–279,y519 in the lower-left assembly; see `frame2-registered-assembly-4x.png` against `frame2-original-assembly-4x.png`. It disappears in unchanged frame5 and reappears at the5→2 loop boundary. Native contact sheets show this phase-dependent stripe. Consequently the same-cut candidate is not a net polish improvement and must not replace the original preferred assembly.

The source-aware follow-up above applies the exact original ownership translation and resolves this specific failure. A universal fixed47cut was not tested or chosen. Do not treat stabilized head extents alone as approval of the whole assembly; the fixed-cut version here remains rejected and must not be integrated.

## Evidence and verification

Output directory: `game/tests/output/theo-west-registration/`.

- `source-verification.json`: exact/inverse integer registration and original-file checksum.
- `manifest.json`: source-aware hand and lap ROIs, all12 variant/frame measurements, unchanged sockets/cuts, evidence paths.
- `frame0.png` through `frame5.png`: six native1280×720 frames, original above/registered below. Columns assembled,exposed support,actor source.
-36 nearest4× crops, no interpolation; six frames×two variants×three columns.
- `all-six-{assembly,support,source}-native.png`: three768×320 contact sheets, frames0–5 left-to-right, original above/registered below, no resizing.
- `theo.avi`: actual233frames,1280×720,30FPS;210 explicit animation frames plus startup/capture settling. Sequence idle0↔1,typing2→3→4→5,returnidle.

Verified:38 translation/inverse checks;227 headless assembly checks;662 rendered checks,all zero failures. The focused test additionally accepts `--verify-capture` to assert evidence sizes and preserve the known stripe regression as a measured outcome rather than silently approving it. This successful diagnostic run means the comparison is reliable, not that the candidate passes visual acceptance.

Visual inspection covered all six full native screenshots,all three unscaled six-frame contact sheets,and representative original/registered assembly and exposed-support4× details includingframe2 andframe5. The recorded sequence was generated and its dimensions/frame count verified; the review is based on its six unique native states and loop endpoints,not a claim that video playback was watched in a UI. No production approach,sit/exit transition,path reservation,approval/research/delivery pose,or other furniture occlusion was validated here.

Reproduce:

```sh
bash dev/tools/build_theo_west_registration.sh
godot --headless --path game --script res://tests/test_theo_west_registration.gd
godot --headless --path game --script res://tools/capture_theo_west_registration.gd
godot --path game --fixed-fps 30 --write-movie res://tests/output/theo-west-registration/theo.avi --script res://tools/capture_theo_west_registration.gd
godot --headless --path game --script res://tests/test_theo_west_registration.gd -- --verify-capture
```
