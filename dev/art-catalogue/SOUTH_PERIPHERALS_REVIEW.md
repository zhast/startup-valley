# South keyboard and mouse — native candidates

Generated at07:01–07:03 UTC using built-in ImageGen. One original plus one background-extraction retry; no further call outstanding. V1 is1605×980 RGB with a checkerboard. V2 is1921×819 RGBA with actual transparency. Sources are `game/assets/source/overnight-20260904/kits/computer-south-peripherals-v{1,2}.png`; exact prompts are `prompts/computer-south-peripherals-v{1,2}.md`.

Original files remain under `/Users/zhast/.codex/generated_images/01a05f6f-b5b9-7f91-9dd4-795832688928/`: `exec-24d056f1-d402-40d1-b85a-4792ca0d3644.png` and `exec-1a125085-95b7-4232-8b7d-555aa76aa721.png`.

The keyboard is viewed for an employee north of the desk looking south: spacebar at the top, mouse buttons at bottom. These are new original views, not a reflected north keyboard. The existing native N kit was inspected and supplied only as material and camera reference. No monitor/furniture was generated as part of this peripheral sheet.

## Export and measurements

`bash dev/tools/build_south_peripherals_calibration.sh` takes the measured alpha50% objects (keyboard1197×485 at156,159; mouse272×429 at1534,181). A shared32-color palette precedes one uniform nearest resize for each complete component: keyboard31px width, mouse8px height. No aspect stretch, rotation, mirror, semantic repaint or manufactured transparency.

Actual native outputs share192×224 canvas, host pivot(96,160), under `game/tests/fixtures/furniture-calibration/kits/`:

| Output | Actual opaque bounds | Pixels |
|---|---|---:|
| `computer-south-peripherals-v2-keyboard.png` |31×13 at(80,112)|402|
| `computer-south-peripherals-v2-mouse.png` |5×8 at(69,113)|36|

The keyboard is **31×13, not the requested31×11**; the mouse is5×8 versus N6×8. Preserve these actual differences in review rather than silently squashing the art. The composite has438 opaque/42,570 transparent pixels,25 colors including transparency, and binary alpha. Native4× pale-underlay review shows the correct opposite key arrangement and no checkerboard, but the key grid is busy. It is a staged calibration component, not an approved four-view match.

Composite SHA-256: `89cca2082e07b5e784d81636930d7da942535d4ea3af92ddff59986ba4e63dc5`.

The separate rear monitor remains `computer-south-v3.png`; this sheet does not supersede its source. The new `capture_south_actor_layers.gd` places the real keyboard on the exact tabletop for the supported-chair study. From this fixed camera a correctly placed rear monitor naturally hides most of the far-side keyboard and hand pixels. An invisible keyboard is not a visible typing-contact claim; acceptance should verify its physical plane and retain honest occlusion rather than drawing hands through the monitor.
