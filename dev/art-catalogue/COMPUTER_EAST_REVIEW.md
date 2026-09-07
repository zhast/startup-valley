# East-use computer toolkit — unapproved calibration candidate

This task produced one independently drawn east-use side-view toolkit, not a mirrored north/south image. **No runtime asset, furniture direction, assembly, actor socket or catalogue approval was enabled.** All three ImageGen attempts are retained. The final permitted correction failed transparency, so the earlier true-alpha version is exported only for calibration.

## Direction and reference contract

The worker stands west/left, looking right. The monitor's display faces west/left and is visible only as a thin blue edge in this fixed camera; the charcoal casing and stand face the camera in profile. The keyboard is left of the monitor, with its long axis vertical. The right-handed mouse is below the keyboard and points right. Screen X/Y stay parallel to the square office grid. No finished image was rotated, mirrored, skewed or independently resized.

Inspected references were the north v2 source, native kit and nearest4× preview, and the south v3 rear-monitor source. The actual north component review subsequently measured a33×30 monitor including its stand,31×11 keyboard and6×8 mouse. These **actual** dimensions supersede the generation prompt's nominal32px monitor width /30×10 keyboard estimate. The source family has charcoal casing, restrained blue screen light, pale keys and upper-left lighting.

This is a camera/proportion comparison, not an assertion of a mathematically exact camera elevation. The real desk's east top is32px wide×96px deep; the registered full canvas remains192×224 with floor pivot(96,160). Device mounting contacts are not floor contacts.

## Generation ledger

| Attempt | UTC timing | Durable source | Actual result | Disposition |
| --- | --- | --- | --- | --- |
| Initial | Started06:47:11; verified by06:48:50 | `game/assets/source/overnight-20260904/kits/computer-east-v1.png` |1161×1354 RGB, baked checkerboard | Rejected alpha; correct left-facing edge, short keyboard and large mouse |
| Targeted retry1 | After06:48:50; verified06:50:05 | `game/assets/source/overnight-20260904/kits/computer-east-v2.png` |1168×1347 RGBA, genuine alpha | Native calibration candidate only; proportions unchanged |
| Targeted retry2/final | Started after06:50:53; recovered/verified06:52:52 | `game/assets/source/overnight-20260904/kits/computer-east-v3.png` |1163×1352 RGB, baked checkerboard | Peripheral proportions improved but transparency rejected; no export |

The final request's response exceeded the model context. Its completed file was recovered from the generated-image directory instead of replaying the request. Initial plus two targeted retries are exhausted for this bounded task. No additional provider, extraction mask or local repaint was used.

Prompts are `dev/art-catalogue/prompts/computer-east-v1.md`, `computer-east-v2.md` and `computer-east-v3.md`. Final generated original: `/Users/zhast/.codex/generated_images/01a069ca-7ec7-7252-827b-8a225a8e6fba/exec-852b0676-510e-44fd-aea7-a9cd1e74e5a5.png`.

## Deterministic native export

```sh
bash dev/tools/build_computer_east_calibration.sh
```

The exporter fails closed on an opaque source. At alpha50%, v2 has three separated objects: monitor309×768@(692,260), keyboard259×512@(239,520), mouse238×150@(235,1061). Their common union is766×951@(235,260). One common point-filter resize to30px width yields a30px-tall monitor/stand. Binary-alpha normalization and a maximum32-color palette follow the existing mechanical workflow. The whole group is placed at(81,108), with no per-component stretch.

Each independent component is then extracted through native transparent gutters to an **identical full192×224 canvas**, preserving registration. These are separate devices, not authored front/rear occlusion layers. Parent assembly work may position the devices independently; the output coordinates are provisional calibration, not an approved workstation socket.

| Export under `game/tests/fixtures/furniture-calibration/kits/` | Actual opaque bounds `[x,y,w,h]` | Opaque pixels |
| --- | --- | --- |
| `computer-east-v2.png` | `[81,108,30,37]` |457 |
| `computer-east-v2-monitor.png` | `[99,108,12,30]` |219 |
| `computer-east-v2-keyboard.png` | `[81,118,10,20]` |186 |
| `computer-east-v2-mouse.png` | `[81,139,9,6]` |52 |

The monitor's final opaque row is137, mounting boundary138 (host-localY−22), not the floor pivotY160. Its screen edge is on the left. Keyboard and mouse remain west of the monitor, with one transparent row between keyboard and mouse. Their current source spacing is not evidence that an east-facing employee can reach the keyboard.

The kit has25 RGBA colors including transparency,457 opaque pixels and42,551 transparent pixels. Actual alpha values are only0/255. Native and nearest4× pale-underlay images were inspected: `computer-east-v2.png`, `computer-east-v2-4x.png`, `computer-east-v2-paper-4x.png`.

## Native findings and remaining gates

- The narrow lit left edge, right-hand stand and vertical keyboard read as an east-use side view without a broad front-facing screen or isometric yaw.
- The keyboard is10×20, compared with the north keyboard's physical31×11 plan dimensions. An axis-exchanged equivalent would be approximately11×31. Its short length and busy maze-like key pattern are visible at native size; do not claim the same exact keyboard geometry.
- The mouse is9×6 compared with an axis-exchanged north8×6. This smaller mismatch is not the originally estimated much-larger gap; the measured north component dimensions matter.
- The monitor's12×30 full profile is a plausible side silhouette, but exact casing thickness versus the north33×30 full front view has not been approved.
- No desk/chair/actor composition or typing-frame hand contact was rendered by this task. The tabletop/contact, occlusion, wall collision and input gates remain untested here. This export cannot enable east-facing furniture by itself.

Provisional scores (0–3): pixel coherence2, perspective2, silhouette2, layering/anchors1, direction consistency2, placement1; mean1.67. This fails the acceptance floor and is intentionally **unapproved**, not a usable production replacement.

## Checks and hashes

- Shell syntax validation passed.
- The builder's actual component reconstruction reports zero differing pixels across the192×224 canvas; all457 opaque pixels are preserved exactly once.
- First reconstruction comparison used an overly strict text check for ImageMagick's metric output (`0` versus actual `0 (0)`), although the pixels were equal. The builder now checks the comparison exit status. This was a development check correction, not an image correction.
- Two complete exports produced the same native PNG hash; `git diff --check` passed for owned text files.
- No Godot renderer, worker, provider job, save, runtime registration, commit or push was used.

```text
df610c06773e64fff4b2ce1b9adc24fc36ae9bfd312173a2e3af5dc416fac179 native computer-east-v2.png
230ba0c49e4481f827f8a61fa93f0640f1002afa249c6a559cd9f8eda666425a rejected source computer-east-v3.png
```
