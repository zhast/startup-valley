# West computer components — native candidates

Root generated the original west-use view at06:54 UTC and a targeted alpha extraction at06:56 UTC. No call remains outstanding. Initial source was1162×1353 RGB with a painted checkerboard; v2 is1312×1199 RGBA with real alpha. This used one initial plus one targeted retry, not the three-retry maximum.

Durable masters: `game/assets/source/overnight-20260904/kits/computer-west-v1.png` and `computer-west-v2.png`. Prompts: `prompts/computer-west-v1.md`, `computer-west-v2.md`. Original tool files remain under `/Users/zhast/.codex/generated_images/01a05f6f-b5b9-7f91-9dd4-795832688928/`: `exec-d56ae9ef-c3cf-44fa-bc06-1e207283e8e6.png`, `exec-a95a8fd3-af9f-48f2-8a63-f9dfb91e9971.png`.

The employee is right of the workstation looking left: monitor lit edge faces right, rear mounting bracket left, keyboard long axis vertical, mouse buttons left. Existing E source and native N kit were inspected and supplied as casing/material references; the view was independently generated, not mirrored or rotated. Light remains upper-left.

## Mechanical export

`bash dev/tools/build_computer_west_calibration.sh` crops actual alpha50% source components: monitor422×1083 at(156,26), keyboard289×851 at(804,265), mouse269×170 at(818,47). Each complete independent object receives **one uniform point scale**, targeting the actual north family's30px monitor height,31px keyboard length and approximately6px side mouse height. There is no independent-axis stretching, source repaint, fake alpha or runtime scaling.

Unlike the earlier common-whole-kit normalization, these separately reusable objects do not assume an image-model source pixel represents the same physical unit across all items and masters. Their aspect ratios are preserved; a source with a wrong aspect ratio would still fail. This distinction gives the keyboard11×31 rather than accepting an unnecessarily short common-scale export. Fixed source registration is not preserved across the entire master arrangement; final component sockets are explicit and provisional.

Each output retains full192×224 canvas and host floor pivot(96,160):

| Component | Native opaque bounds `(x,y,w,h)` | Pixels |
|---|---|---:|
| `computer-west-v2-monitor.png` |81,108,12,30|216|
| `computer-west-v2-keyboard.png` |99,115,11,31|337|
| `computer-west-v2-mouse.png` |99,103,9,6|48|

Paths are under `game/tests/fixtures/furniture-calibration/kits/`. Composite `computer-west-v2.png` contains601 opaque and42,407 transparent pixels,26 colors including transparency, and no intermediate alpha. The3 distinct components are disjoint. All exports are candidates, not runtime assets. The main agent inspected source, native component bounds and pale4× comparison. Native keyboard proportion matches N's31×11 in the opposite plane orientation; mouse is1px wider than N's6×8 exchanged dimensions, a remaining minor family difference.

Composite SHA-256: `98f2736b02366345dc9fcb3705c9914ed04ab8953943e604526c39b6b3be7184`.

## Acceptance status

`SUPPORTED_WEST_ASSEMBLY_REVIEW.md` owns native room/contact/occlusion findings. Correct alpha and a matching keyboard outline do not approve a desk, chair, actor socket or typing animation. Geometry/contact must still pass with the registered components and exact tabletop. Production remains unchanged. Preserve RGB v1 as rejected source evidence, not usable transparent art.
