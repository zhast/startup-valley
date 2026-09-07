# East computer v4 — recovered alpha and proportion-aware native export

**Native calibration candidate, not a production or assembly approval.** Root used the remaining third/final objective-level targeted retry to extract genuine alpha from the better-proportioned v3. This is the same asset's final retry, not a reset of the two-retry subtask. This export task made no ImageGen call and leaves all v1–v3 sources, v2 fixtures and old assembly evidence unchanged.

Source: `game/assets/source/overnight-20260904/kits/computer-east-v4.png`, **1182×1330 RGBA**. Root owns its generation; prompt `dev/art-catalogue/prompts/computer-east-v4.md` records the final extraction. The source was viewed before export. It contains the monitor's narrow left-facing blue edge, long vertical pale keyboard to its left, and a right-pointing mouse below. There is no furniture/actor/floor or baked checkerboard. The alpha-source success and export were independently verified by07:14:47UTC. No further ImageGen attempt is permitted for this asset.

## Export contract

```sh
bash dev/tools/build_computer_east_v4_calibration.sh
```

The root explicitly authorized per-object **uniform** normalization for these independently reusable complete devices, rather than assuming generated source pixels define a common physical scale. Each object's aspect ratio stays intact. There is no separate-axis stretching, turning, mirroring, contour painting or invented alpha mask. A common source palette is limited to32 colors before point normalization, with binary-alpha thresholding.

| Object | Actual alpha50% source crop `[x,y,w,h]` | Uniform native target | Actual native opaque bounds `[x,y,w,h]` | Opaque pixels |
| --- | --- | --- | --- | --- |
| Monitor including stand | `[709,165,345,830]` |30px full height | `[99,108,12,30]` |217 |
| Keyboard | `[266,186,229,816]` |31px length | `[81,115,9,31]` |275 |
| Mouse | `[280,1039,194,128]` |6px height | `[81,149,9,6]` |50 |

All components retain a **192×224 canvas and shared host pivot(96,160)**. Export paths under `game/tests/fixtures/furniture-calibration/kits/`:

- `computer-east-v4-monitor.png`
- `computer-east-v4-keyboard.png`
- `computer-east-v4-mouse.png`
- `computer-east-v4.png` — registered component union
- `computer-east-v4-4x.png` and `computer-east-v4-paper-4x.png` — nearest diagnostic enlargements

Monitor mounting boundary remainsY138 (host-local−22), with its last opaque row137. Keyboard occupies host-localX−15..−7,Y−45..−15. Mouse remains below it atY−11..−6, separated by three fully transparent rows. Components are disjoint and independently movable in a later assembly. Their current placement is a calibration composition, not an approved reach/socket.

## Native review and remaining difference

The full native kit and4× pale-underlay version were inspected. The left-facing lit monitor edge is intact; the long keyboard reads more consistently as a full-size device than v2's10×20 outline. The v4 outline is **9×31**, however, not an exact axis-exchanged match for north's actual31×11 keyboard: it remains2px narrower. No width-only expansion conceals that difference. Mouse is9×6 versus the axis-exchanged north8×6; monitor profile is12×30 versus north's front33×30 including stand.

The source family keeps charcoal casing, pale keys and restrained blue light. Keys are simplified at native scale; there is no claim of exact key-count correspondence. Native dimensions, source perspective and materials are plausible enough for the next supported-assembly comparison, but character hand contact, exact seat Y, depth and complete directional family consistency remain unapproved. The existing unapproved status does not silently become a runtime-facing capability.

## Checks

- Source has real alpha; exporter rejects opaque input.
- Native kit has **23 RGBA colors**, **542 opaque pixels**, **42,466 transparent pixels**, and alpha values only0/255.
- Exactly three8-connected opaque components have the measured bounds above. Their opaque pixel counts sum217+275+50=542, without overlap or missing pixels in the union.
- Two complete runs generated identical native PNG hashes. Shell syntax validation and owned-file diff checks passed.
- No Godot renderer, production registration, save or worker was used for this export.

```text
cd87fe5ae791ede80a7e845bd223153a04bca4a31a140860a77d4aa7758d2ef8 source computer-east-v4.png
f118ca230f2d962ae3b487a28812aa82937d48afa451a4508fb7fb8d2aeac7f2 native computer-east-v4.png
```
