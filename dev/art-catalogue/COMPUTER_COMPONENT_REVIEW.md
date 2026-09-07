# Computer component extraction and south-monitor normalization

Development-only mechanical work. **No ImageGen request, repaint, invented alpha mask, runtime registration or placement approval occurred in this task.** Existing north pixels were separated by explicit atlas rectangles; root's existing true-alpha south source was uniformly normalized. Catalogue and source README were intentionally left unchanged after their previous handoff.

## North: exact registered component extraction

Source: `game/tests/fixtures/furniture-calibration/kits/computer-north-v2.png`,192×224 RGBA. This native source is not resized, thresholded, palette-reduced or moved. All three new component files retain the full192×224 canvas and the shared host floor-pivot coordinate(96,160).

The original source master had separately spaced objects, but point normalization made the stand's last outline row126 adjacent to the keyboard's first outline row127. Connected-component flood filling therefore sees the monitor and keyboard as one object. Explicit, **nonoverlapping atlas crop regions**, checked against native rows and the large source reference, recover the intended parts without cutting their pixels.

| Component | Extraction region `[x,y,w,h]` | Actual opaque bounds | Opaque pixels |
| --- | --- | --- | --- |
| Monitor + its stand | `[0,0,192,127]` | `[80,97,33,30]` | 833 |
| Keyboard | `[79,127,31,11]` | `[79,127,31,11]` | 337 |
| Mouse | `[112,129,6,8]` | `[112,129,6,8]` | 44 |

The monitor's width is **33 opaque pixels**, including its right bezel atx112. It is not safe to trim it to the earlier nominal32px figure. The stand's final row126 belongs to the monitor; row127 belongs to the keyboard. No pixel is shared by two output layers and all1,214 original opaque pixels are covered exactly once.

Files under `game/tests/fixtures/furniture-calibration/kits/`:

- `computer-north-v2-monitor.png`
- `computer-north-v2-keyboard.png`
- `computer-north-v2-mouse.png`

These are **separate objects**, not newly authored rear/front occlusion layers. For the zero-offset reconstruction, each full canvas is drawn at the same host origin `P−(96,160)`. A monitor-only study may add an external offset to that object's draw origin without moving the keyboard/mouse. No such offset is baked into these exports. The drawer study owner was given the paths and exact bounds before starting its independent−10px monitor test; this report does not approve that adjustment.

### Reproduction and tests

```sh
bash dev/tools/build_computer_component_calibration.sh
node dev/tools/test_computer_component_calibration.mjs
```

The source-only preflight requires192×224, binary alpha, no hidden RGB in transparent padding, and exactly one region owner per visible pixel. The full test compares every output byte against its untouched source region, checks object bounds/padding/nonoverlap, and compares both an in-memory union and the ImageMagick-composited evidence to the original decoded RGBA buffer. Negative controls detect a lost keyboard-top pixel and a position-shifted pixel.

Results: **35 focused checks passed**; all43,008 pixels /172,032 RGBA bytes match exactly. The7 preflight checks are included in that35, not an additional coverage count. This is pixel-byte identity; compressed PNG file bytes can differ because encoding/metadata can differ.

Original and recombined decoded-RGBA SHA-256:

```text
8445cf7ae1b560b22baf8bfbee6513374da5ebfa5496e596e96a107022de30c3
```

Evidence in `game/tests/output/computer-components/`:

- `recombined.png`: actual registered composite, pixel-identical to native source.
- `components-native.png`: five192×224 panels in order original / monitor / keyboard / mouse / recombined;960×224 total, visually inspected at native size.
- `components-4x.png`: nearest-enlarged diagnostic sheet, not new art or runtime output.

## South: root source v3 normalized, not newly generated

Source: `game/assets/source/overnight-20260904/kits/computer-south-v3.png`,1402×1122 with genuine alpha. Root owns its generation and prompt `dev/art-catalogue/prompts/computer-kit-south-v3.md`. The complete source was viewed before export: a charcoal rear housing, vents and T-stand, no keyboard/mouse floating above it. This task made no semantic edits to that image.

The nonzero-alpha source extent includes faint residue. At the established50% alpha threshold the actual foreground is **945×909 at(227,126)**. This bounding box includes the housing **and** exposed stand; it must not be labeled the housing-only height. One crop and uniform point resize to32px width produce the native31px total height; palette limiting and binary-alpha normalization follow the existing mechanical workflow.

```sh
bash dev/tools/build_computer_south_calibration.sh
node dev/tools/test_computer_component_calibration.mjs --with-south
```

| Property | Actual native result |
| --- | --- |
| File | `game/tests/fixtures/furniture-calibration/kits/computer-south-v3.png` |
| Canvas / host floor pivot | 192×224 / (96,160) |
| Whole opaque bounds | 32×31 at(80,109) |
| Housing outline | y109–133 inclusive:25px high; full body width32 atx80–111 |
| Exposed stand begins | y134,x93–98 |
| T-stand foot | x90–101,y136–139 |
| Stand mounting-contact boundary | y140, last opaque row139; fixed as requested |
| Alpha / palette | Binary0/1;17 RGBA colors including transparency |
| Opaque components | One8-connected component,856 pixels |
| 4× preview | `computer-south-v3-4x.png`,768×896 |

The housing is32×25, not exactly the nominal32×24 target. The full housing-plus-stand is32×31. Both were measured rather than inferred from the master canvas. The stand's y140 boundary is a **tabletop mounting/contact target within the host canvas**, not the office-floor pivot itself; it lies20px north of host pivoty160.

Native and4× south exports were visually inspected. The housing, vents, central support and stand read as a rear monitor; no stray keyboard or opaque checkerboard remains. Thin charcoal edges need actual tabletop-contrast review. Root must still validate body proportions against the north monitor, host mounting position, actor occlusion and every hand-contact frame. A true-alpha32px export is not a complete assembly pass.

The expanded test run passed **47 checks**: the35 north checks plus12 south decode/geometry/alpha/body-versus-stand/contact checks. Two south exports produced the same PNG hash. Shell syntax validation and `git diff --check` passed. No Godot renderer or worker was run by this task.

## File SHA-256

```text
04f59270edc1e50e6c1342a2781856bdc633833ec15b92ca827ea278faeb5ddb original north native kit, unchanged
237b9e27311a0fc11dc772c0fac9a477f904bb02b7336fc0298c4f6a529f1088 north monitor component
370b661c5d88cab4881f571f4c80a47b0d591cf7b4bc2abe8cc925934067c647 north keyboard component
4e730bbb85f1f13e794a256b75ff297223860bd2d8d439954176674e4d48a6ad north mouse component
ade1a3685651e9babb2ad8d2342ed7d944cac45ce7f33caf7ca0b7b83a41524f south v3 native monitor
```

All generated source versions remain untouched. These component exports and the south native fixture are available for the next controlled study; no catalogue approval, production facing or accepted chair/desk/typing socket is asserted.
