# Modular desk finish v2 — isolated native study

The v2 finish is a restrained improvement over the flat v1 legs: small joints and dark foot caps make the same six-pixel bars read as matte metal, and the apron has a clearer shallow seam. **Prefer it for the next calibration comparison, not as an approved production workstation.** The orange, 32px-period oak grain is unchanged and still visibly repetitive, especially on the tall E/W surface. No extra grain, rivets or frame thickness was added to disguise that limitation.

This is code-native finish work, not an ImageGen request or a repaint of the retained generated oak. All old helper/source/export/evidence files remain unchanged. The frozen 113-master catalogue is not updated by this study.

## Exact retained contract

- Full PNG canvas **192×224**, floor pivot **(96,160)**, centered sprite offset **(0,−48)**, native scale1 and nearest filtering.
- N/S tabletop `(48,112,96,32)`, floor `(48,144,96,32)`, near contact boundary y176. E/W tabletop `(80,80,32,96)`, floor `(80,112,32,96)`, near contact boundary y208. Rise remains32px.
- Top remains on Rear for N/E/W and Front for S. Rear/Front relative depths remain−1/+1; E/W side rails keep their original lighting and ownership.
- Exact old alpha mask for **each** layer, including occluded far-leg pixels. No geometry, blocking cell, approach, seat correction, pose, chair, device, shadow, cue or hit-bound change.
- The near-leg finish begins below the original apron. Metal cannot paint through the wood merely because both belong to the Front layer. Every new rectangle is contained by the old visible structure.

The new helper inherits the original profile and appends only inset face planes, short joints, foot caps and the seam. It uses one new matte intermediate shade (`#44443E`); all other finish colors already exist in the helper. Exported layers use4–9 colors. Top-plane pixels, including their original generated grain and bevels, are byte-identical to v1.

## Deliverables and reproduction

New helper: `game/tools/desk_finish_v2_geometry.gd`. New disposable fixture: `game/tools/desk_finish_v2_fixture.gd`. It replaces only the two desk art paths in a copied calibration profile; all other profile fields are proven equal to the original.

Eight separate PNGs and their import sidecars live in `game/tests/fixtures/furniture-calibration/modular-desk-finish-v2/`. Its `manifest.json` records full canonical-shaped layer descriptors, measured ink, compressed/decoded hashes, exact geometry and old/new source provenance. The manifest remains dev-only, with no runtime-ready flag or production registration.

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tests/test_desk_finish_v2.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --script res://tools/capture_desk_finish_v2.gd -- --export
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --fixed-fps 30 --script res://tests/test_desk_finish_v2.gd -- --room
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --script res://tools/capture_desk_finish_v2.gd -- --room
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tests/test_desk_finish_v2.gd -- --contacts
```

Keep the supplied eight new sidecars: `process/fix_alpha_border=false` preserves full imported RGBA, including empty transparent RGB. No old import setting changed. The final contacts/index method was added after the room run and only reads its frozen captures; geometry, export and fixture logic did not change afterward.

## Native visual review

Evidence: [before/after desk-only plate](../../game/tests/output/desk-finish-v2/finish-before-after-native.png), [North actual room](../../game/tests/output/desk-finish-v2/north-v2-pose-2.png), [East](../../game/tests/output/desk-finish-v2/east-v2-pose-2.png), [South](../../game/tests/output/desk-finish-v2/south-v2-pose-2.png), [West](../../game/tests/output/desk-finish-v2/west-v2-pose-2.png).

All four paired six-frame contacts were inspected at native size: [N](../../game/tests/output/desk-finish-v2/north-assembly-before-after-native.png), [E](../../game/tests/output/desk-finish-v2/east-assembly-before-after-native.png), [S](../../game/tests/output/desk-finish-v2/south-assembly-before-after-native.png), [W](../../game/tests/output/desk-finish-v2/west-assembly-before-after-native.png). Top two rows are v1, bottom two v2; each frame pairs Mina/Theo. Paper nameplates can be cut by these diagnostic crops; the linked1280×720 originals show their actual unclipped layout.

Confirmed:

- North joints around `(292,262)` and `(374,262)` and the unchanged bottom contact at y288 are readable but quiet. The metal remains subordinate to the employee and computer.
- South apron around `(288,256,96,10)` gains an underside seam without becoming a drawer. No metal extends through that apron.
- E/W legs retain their height/width and contact; no additional brace blocks the character approach. The finish does not conceal unchanged knees, chair or monitor relationships.
- The same grain repeats three times along the long surface. The v2 finish does **not** fix that source-material repetition or make a complete workstation look finished by itself.

Bounded finish comparison scores: pixel coherence2, perspective3, silhouette2, layering/anchors3, directional consistency3, placement2 — **mean2.5**. This is a reviewer recommendation for the isolated finish, not coordinator approval of the assembled furniture family. Original seat support, hand/contact, authored mount and separate floor-shadow limitations remain open.

## Verification and limits

- Preflight: **2,598 checks /0 failures**. Every finish rectangle is within existing ink; exact geometry and disposable-profile equivalence pass.
- Native exporter: **2,682 /0**, comparing **344,064 layer pixels**. **988 layer RGBA pixels change**, including some far-leg pixels hidden in the final whole. All alpha bytes and all material/top pixels remain identical. Four rear/front unions reconstruct their independent whole renders byte-exactly; PNG save/load preserves RGBA.
- Actual GameMain comparison: **5,910 headless /6,134 rendered checks, zero failures**; **64 native1280×720 captures**. Both employees, four facings, two seated idle frames and four typing frames use the exact original authored regions. Two-person standing/arrival/leave states are included.
- **2,752,512 native assembly pixels** compared between v1/v2. Differences are confined to permitted finish rectangles; actor, chair, device, floor and surrounding pixels inside the paired assembly regions remain unchanged.
- **3,104 actual deterministic navigation ticks** check physical safety and exact desk endpoints; leaving clears seated layer ownership. Imported Sprite2D textures match the complete new RGBA buffers. No new click/menu, live worker, fullscreen or continuous-motion recording is claimed by this bounded visual study.
- Four CPU-only native contact sheets: **2,655 /0** including source proof and index write. Total evidence is **77 PNGs**:64 room states, four whole exports, four4× details, one desk A/B plate and four assembly contact sheets. These are not77 new assets.
- Existing v1 export suite remains **233 /0**; Godot import and project validation pass. Independent manifest source/export hash check: **27 /0**. No source or production file changed, and no catalogue lifecycle was promoted.

The next useful refinement, if selected, is a separate quieter material study on this unchanged geometry. Random tile offsets, artificial edge moats, whole-object regeneration and shifting actor sockets would not address the observed finish issue reliably.
