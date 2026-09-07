# North-facing task-chair study

Status: **partial concept/native study, not production approved**. One initial built-in ImageGen request and two targeted retries were used; this bounded chair batch is finished. No request remains in flight. No runtime/catalogue registrations, layer masks, actor poses, worker calls, saves, commits or pushes were made.

## Outcome

The first source has genuine alpha and a recognizable rear-facing chair. Its mechanical 32px-wide normalization produces a **32×55** silhouette, not the requested approximately **32×68**. The taller second version returned an opaque painted checkerboard; a final background-only extraction retry returned another opaque checkerboard. Neither opaque version was normalized or treated as usable transparent art.

Keep v1 as a real-alpha reference and v2/v3 as rejected generation evidence. Do not stretch v1 into the target ratio, erase the background with an invented mask, or label any of these as an approved north-facing chair.

## Requests and provenance

Times below are UTC start checkpoints and completion observations, not precise server-side timestamps. All calls used the built-in ImageGen tool; no API/CLI fallback, key, subscription or credit reset was used. The imagegen skill and both shared prompting references were read before generation.

| Version | Start checkpoint | Completed by | Tool duration | Prompt / intent | Result |
| --- | --- | --- | --- | --- | --- |
| v1 | 2026-09-04 06:09:11 | 06:10:07 | 34.1s | [Original north/back chair](prompts/chair-north-v1.md) | True RGBA; proportions too short when uniformly normalized |
| v2 | 2026-09-04 06:11:32 | 06:12:09 | 19.4s | [Taller proportion redraw](prompts/chair-north-v2.md), v1 supplied as edit target | Better apparent height/width, but RGB checkerboard; rejected |
| v3 | 2026-09-04 06:12:42 | 06:13:20 | 30.5s | [Background-only extraction](prompts/chair-north-v3.md), v2 supplied as edit target | RGB checkerboard again; rejected; retry limit reached |

Before v1, the existing native `south-workstation.png`, `employee-workstation.png` and normalized empty south desk were inspected as material/scale references. They informed the written charcoal/indigo/cozy-office brief; v1 did not receive a reference-image attachment. V2 and v3 received their preceding local source image as the explicit edit target. No uninspected local image was edited.

Original tool files remain under `/Users/zhast/.codex/generated_images/01a069ca-5125-71e1-9f6c-290ba248abf0/`:

- v1: `exec-955e733e-2dd6-4f2a-b0b5-6f1f0d1bed15.png`
- v2: `exec-c9495d3b-9c80-44d7-9060-d6aa3ccc00b4.png`
- v3: `exec-911223be-507d-4ec2-95b5-848f9b46c09f.png`

Each was copied into the project, leaving the tool original intact:

- [v1 source](../../game/assets/source/overnight-20260904/calibration/chair-north-v1.png)
- [v2 rejected source](../../game/assets/source/overnight-20260904/calibration/chair-north-v2.png)
- [v3 rejected source](../../game/assets/source/overnight-20260904/calibration/chair-north-v3.png)

## Mechanical normalization and measured evidence

[Builder](../tools/build_chair_north_calibration.sh) uses the existing approach: reject fully opaque sources; threshold alpha at 50%; one common trim; uniform point resize to 32px width; binary alpha; a maximum 32-color palette; register on the shared **96×160 canvas** at fixed floor pivot **(48,112)** with contact boundary **y128 = pivot+16**. It does not change projection, rotate/mirror pixels, stretch dimensions or invent rear/front layer masks.

Reproduce the real-alpha study:

```sh
bash dev/tools/build_chair_north_calibration.sh v1
```

The builder was also tested with v2 and correctly exited 1 with `Rejected opaque chair source`. V3 metadata independently confirms the same opaque failure; no v2/v3 native fixtures were created.

| File | Canvas | Channels / opacity | Measured alpha bounds | Disposition |
| --- | --- | --- | --- | --- |
| v1 source | 971×1619 | RGBA, not opaque | Nonzero-alpha bounds include faint exterior residue: 952×1528 at (0,19) | Preserve original; threshold during mechanical native export |
| v2 source | 971×1619 | RGB, fully opaque | Entire canvas | Rejected checkerboard |
| v3 source | 971×1620 | RGB, fully opaque | Entire canvas | Rejected checkerboard |
| [v1 native](../../game/tests/fixtures/furniture-calibration/chair-north-v1.png) | 96×160 | RGBA, alpha exactly 0 or 1 | **32×55 at (32,73)** | Native study only; wrong target height |
| [v1 4× nearest preview](../../game/tests/fixtures/furniture-calibration/chair-north-v1-4x.png) | 384×640 | RGBA, nearest 4× | Corresponding 128×220 visible region | Review magnification, never a runtime asset |

The native output has 28 RGBA colors, two alpha levels (minimum 0, maximum 1), and one 8-connected opaque component of 1,006 pixels. The mechanical threshold leaves no detached alpha islands in this native sample. This does not prove animation, pose occlusion or contrast on every possible office floor.

### Native and 4× views

![North chair v1 at native canvas size; incomplete proportion study](/Users/zhast/GitHub/startup-valley/game/tests/fixtures/furniture-calibration/chair-north-v1.png)

![The same native study enlarged exactly four times with nearest sampling](/Users/zhast/GitHub/startup-valley/game/tests/fixtures/furniture-calibration/chair-north-v1-4x.png)

Both were inspected directly. There is no room render or seated actor in these images, and no visual approval is implied by the transparent export.

## Landmarks and art critique

Measured coordinates refer to the native 96×160 canvas; feature ranges below are approximate visual observations, not authored seat sockets.

- **Backrest top:** first opaque row y73, or **−39px** relative to the floor pivot. Requested top was about y60/−52; the study is 13px too low/short.
- **Rear identity:** dark perimeter frame, rear lumbar/adjustment support and exposed center stem are visible. This reads as the chair's back, consistent with a north-facing worker looking away/up.
- **Back panel:** approximately y76–104; blue fabric and charcoal frame remain distinguishable at native size. Its mesh/check pattern is busier than the existing plain charcoal chair, so exact material-family coherence still needs room review.
- **Seat indication:** small indigo shoulders around y95–104 peek around the lower rear frame. The actual seating plane is mostly hidden; no reliable actor/hand socket can be inferred from this image alone.
- **Lift/base:** narrow center post around y110–117, with caster/leg cluster continuing to row127. The source has readable metal highlights; the thin native stem still needs an in-room contrast check.
- **Ground contact:** exclusive bottom boundary y128 equals floor pivot+16; last opaque row127. This registration is correct even though the overall height is not.
- **Projection:** straight rear alignment, no obvious diamond-isometric yaw or rotated bitmap. No other views exist to establish four-facing consistency.

The target and observed silhouettes differ substantially: target 32×68 (ratio 2.125), observed 32×55 (ratio 1.719). Preserving a uniform resize is more important than forcing the requested number by distortion. The taller opaque attempts are not a basis for claiming that difference fixed.

## Integration gates still missing

1. A true-alpha north view with the agreed height/seat relationship, or an explicit design decision to revise those target proportions.
2. Matched south/east/west redraws and their native review; no bitmap rotation/mirroring shortcut.
3. Separate reviewed chair back/front layers, all registered to the same full canvas; no masks were invented here.
4. Actual directional seated/typing poses and safe hand/torso/backrest occlusion.
5. A room fixture with the exact production employee transform, not a differently anchored stand-in.
6. Chair assembly on a walkable/reserved seat socket. Do not insert a blocking chair footprint into the workstation's `work_cell`.

No final rubric score or runtime-ready state is assigned because placement, actor/layer behavior and cross-direction consistency have not been tested. This batch uses the allowed two targeted retries and leaves those limits explicit.

## SHA-256 preservation record

```text
45ceab8ce0fac6aef44bc1aaf8858246c6f1405b256b963bd6652e74eaa7d448  source/chair-north-v1.png
1debad5ea62ed05fd3417e244f0a9b1acf8193391c4eb453c2f94dfb5a7bc027  source/chair-north-v2.png
930b6555142bb94f6b0b3457ec2b8aafc942933250ab1ee341df9352f5cd8f1b  source/chair-north-v3.png
4959e5da8909cdc791fc2f1a41d637c7b291f5b23b380a1538ee99db66939642  fixture/chair-north-v1.png
```
