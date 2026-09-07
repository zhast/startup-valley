# Quiet desk grain v2 — isolated native comparison

2026-09-04. **Staged material improvement; no production or whole-workstation approval.** The old grain, finish-v2 geometry, sockets, poses and catalogue checkpoint remain unchanged. This study made no ImageGen request; root supplied the two first targeted material revisions.

## Native result

The quieter material is clearly preferable to the busy v1 grain in the actual room: it leaves the faces, hands, computers and thin furniture edges easier to distinguish. See the [native desk A/B](../../game/tests/output/desk-grain-v2/grain-before-after-native.png) and [all-four actual assembly A/B](../../game/tests/output/desk-grain-v2/all-four-assembly-before-after-native.png). Columns are N/E/S/W, each with Mina then Theo; top two rows old typing/idle, bottom two new typing/idle. These are diagnostic crops; cut callout text at a crop edge is not a full-scene UI defect.

The candidate is **not a perfectly matched four-direction wood material**. Horizontal retains six small grain strokes. Vertical lost three of the six original marks during the required point sampling; its remaining three 1×2 marks barely read as wood at normal size. Both directions retain recognizable 32px periodicity under deliberate inspection, although it is much less distracting now. No artificial grain marks, tile offsets, rotated raster, extra effects or socket changes were added to disguise that limitation.

| Native 32×32 material | Dark / base / light pixels | Non-base density | Surviving marks | Opposite-edge mismatches |
|---|---:|---:|---|---|
| Old horizontal soft | 191 / 658 / 175 | 35.74% | Dense texture | Not rerated here |
| New horizontal | 16 / 1000 / 8 | 2.34% | Six, 3–5×1px | 0 left/right, 0 top/bottom |
| Old vertical soft | 321 / 403 / 300 | 60.64% | Dense texture | Not rerated here |
| New vertical | 4 / 1018 / 2 | 0.59% | Three, 1×2px | 0 left/right, 0 top/bottom |

Native full scenes inspected: [North idle](../../game/tests/output/desk-grain-v2/north-quiet-pose-0.png), [East typing](../../game/tests/output/desk-grain-v2/east-quiet-pose-3.png), [South typing](../../game/tests/output/desk-grain-v2/south-quiet-pose-3.png), [West typing](../../game/tests/output/desk-grain-v2/west-quiet-pose-3.png), plus all eight actor/direction pairs in both captured poses on the contact sheet. At native coordinates, Mina's tabletop is approximately N/S `(288,224,96,32)` or E/W `(320,192,32,96)`; Theo's equivalent is 448px to the right. These areas are visibly calmer. Existing hand reach, seated support, monitor coverage and plain apron limitations are unchanged, not newly approved.

Bounded material score, 0–3: pixel coherence **2**, readability **3**, continuity **2**, layering **3**, palette/contrast **3**, state distraction **3**; mean **2.67**. This is a static material review, not a motion/whole-game pass. Prefer this quiet direction for further candidate assembly work; defer another generation unless matching wood character across axes is an actual priority. Exact edge equality alone is not visual approval.

## Exact scope and provenance

Root-owned opaque originals and exact prompts:

- [Horizontal source](../../game/assets/source/overnight-20260904/materials/oak-horizontal-v2.png), [prompt](../../game/assets/source/overnight-20260904/materials/oak-horizontal-v2.md), 1254×1254 RGB; SHA256 `b850a0a6f2a989b4518833386633218a6714e7635132adef576953ac613fc023`.
- [Vertical source](../../game/assets/source/overnight-20260904/materials/oak-vertical-v2.png), [prompt](../../game/assets/source/overnight-20260904/materials/oak-vertical-v2.md), 1254×1254 RGB; SHA256 `200b62aca4116c69bd521a2b24de9019c1900fb3ab4153e5ea1a170286c09d88`.

[Mechanical builder](../tools/build_oak_v2_materials.sh) point-samples each complete source to 32×32 and remaps to the unchanged [three-color soft palette](oak-material-palette-soft.svg): `#A75927`, `#B7672C`, `#C47734`. No per-object rescaling, redraw, crop or new palette. [Horizontal native](../../game/tests/fixtures/furniture-calibration/materials-v2/oak-horizontal-v2.png) SHA256 `bcd3ccf8c6411b4ce24997a88b3fabf78f7fa2132b240f66ee1d59ab3e0dded6`; [vertical native](../../game/tests/fixtures/furniture-calibration/materials-v2/oak-vertical-v2.png) `28a84e93bcdd6e026fbd3a56ae598f14a6c74acd07d1c5950a1a2347a1a24fae`.

The [new capture](../../game/tools/capture_desk_grain_v2.gd) and [disposable fixture](../../game/tools/desk_grain_v2_fixture.gd) use the frozen finish-v2 helper with only those materials changed. Eight new registered layers live in [modular-desk-grain-v2](../../game/tests/fixtures/furniture-calibration/modular-desk-grain-v2/README.md), each192×224, pivot96,160, scale1, nearest. Only the inset top material may differ. N/S96×32 and E/W32×96 top planes, all floor/contact/depth/alpha masks, matte-metal finish, rim, apron, legs, seated source layers and physical reservations remain exact. New import sidecars alone disable alpha-border RGB fill so complete imported RGBA matches raw PNG, including transparent padding.

## Verification and reproducibility

| Run | Checks | Failures |
|---|---:|---:|
| [Headless material/profile preflight](../../game/tests/output/desk-grain-v2/results-preflight-headless.json) | 2,055 | 0 |
| [Actual native layer export](../../game/tests/output/desk-grain-v2/results-export.json) | 2,128 | 0 |
| [Headless actual-room fixture](../../game/tests/output/desk-grain-v2/results-room-headless.json) | 3,759 | 0 |
| [Rendered actual-room fixture](../../game/tests/output/desk-grain-v2/results-room.json) | 3,817 | 0 |

- All **344,064** old/new layer pixels checked: **5,026** RGB changes, only within material fill; no alpha, finish or border change. Whole desks reconstruct byte-exact from rear/front.
- **688,128** paired actual-assembly pixels checked: no change outside inset tabletop. Complete imported layer RGBA matches exports.
- Both actors reached original work feet through **1,592** physical ticks. Only idle frame0 and typing phase1 are captured; no continuous motion movie, fullscreen or complete six-frame audit is claimed.
- **23 PNG evidence files**: 16 native1280×720 room captures, four whole desks, native/4× desk A/B and one native all-four assembly sheet. The 4× whole sheet is a nearest enlargement; native images are the readability authority.
- Four material/repeat PNGs rebuilt **byte-identically**. All **39** recorded source/export SHA256 values independently rechecked. Original material/finish/profile/source files remain unchanged.
- First export attempt correctly failed seven layer assertions because reconfiguration recreated hidden layers; the dev capture now reapplies layer isolation after reconfiguration. The successful output replaces only this new study's failed intermediate, not historical evidence or source assets.

```sh
bash dev/tools/build_oak_v2_materials.sh
godot --headless --path game --script res://tools/capture_desk_grain_v2.gd
godot --path game --fixed-fps 30 --script res://tools/capture_desk_grain_v2.gd -- --export
godot --headless --path game --import
godot --headless --path game --fixed-fps 30 --script res://tools/capture_desk_grain_v2.gd -- --room
godot --path game --fixed-fps 30 --script res://tools/capture_desk_grain_v2.gd -- --room
```

Worker disabled throughout; no credentials, provider, saved company, protocol, production catalogue/default, old fixture, commit or push changes. The113-original catalogue cutoff remains frozen; this later source batch is root-owned provenance.
