# Engineer build kit v2 — deterministic native review

Date: September 6, 2026

Family: `engineer_build_kit`

Candidate revision: `engineer-build-kit-v2`

Disposition: **passes the bounded passive-library agent/native visual gate as a candidate only**. The candidate is not registered in the shared dev catalogue, production furniture data, runtime art, or the default office layout.

## Candidate

The provider-free code-native fixture exports one coherent N/E/S/W set of engineering-build decor on the accepted production desk canvas **192×224**, common floor pivot **(96,160)**, and sprite offset **(0,-48)**. Every facing contains the same three glyph-free objects: a compact blue electronics test mat with a green development board, cream breadboard, red/black probes and steel tips; a separate dark debug instrument with a blank cyan screen and restrained amber/red controls; and a brown precision-tool tray with red/steel tool cues. There is no readable text, logo, fake metric, execution control, baked furniture, or baked character.

Every direction is independently drawn in native screen space. The mat's physical envelope stays 26×14 px in N/S and 14×26 px in E/W; the instrument stays 18×10 or 10×18; and the tray stays 18×8 or 8×18. Breadboard placement follows the far edge of the worker's gaze, while the board USB, red probe, and red tray tool follow the worker's physical left. No finished bitmap is rotated, mirrored, flipped, rescaled, or reused for another facing.

Each facing exports separate nonempty `surface_decor_rear` and `surface_decor_front` true-alpha overlays. The six original generated source masters and six original opaque native mat plates remain byte-exact history. Those plates established the test-mat identity, but they were oversized, directionally inconsistent, and previously composited through a retired workstation fixture that removed the computer. The active v2 art is newly drawn editable GDScript geometry on the current accepted `workstations-v2` desk, not a crop, resize, rotation, or renamed retry. Image generation was not called because the retained identity and editable native construction were sufficient; all original per-direction generation budgets remain unchanged.

## Evidence

- [Native isolated contact sheet](../game/tests/output/engineer-build-kit-v2/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/engineer-build-kit-v2/candidate-contact-sheet-4x.png)
- [Native layer sheet](../game/tests/output/engineer-build-kit-v2/candidate-layers-native.png)
- [Native object sheet](../game/tests/output/engineer-build-kit-v2/candidate-objects-native.png)
- [Native actual-room occupied sheet](../game/tests/output/engineer-build-kit-v2/actual-room-contact-sheet-native.png)
- [4× actual-room occupied inspection](../game/tests/output/engineer-build-kit-v2/actual-room-contact-sheet-4x.png)
- [Native actual-room unoccupied sheet](../game/tests/output/engineer-build-kit-v2/actual-room-unoccupied-contact-sheet-native.png)
- [4× actual-room unoccupied inspection](../game/tests/output/engineer-build-kit-v2/actual-room-unoccupied-contact-sheet-4x.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/engineer-build-kit-v2/manifest.json)
- [Structural result](../game/tests/output/engineer-build-kit-v2/structural-results.json)
- [Actual-room result](../game/tests/output/engineer-build-kit-v2/actual-room-results.json)

The provider-free exporter passes **17 checks / 0 failures**. The focused structural gate passes **298 checks / 0 failures**. It proves exact canvas/pivot/offset registration; three disjoint semantic objects and two nonempty layers in every facing; binary alpha and zero hidden RGB; byte-exact object/layer/whole reconstruction; deterministic fixture rebuild; exact common physical envelopes; accepted tabletop containment; clearance from every accepted monitor, keyboard, and mouse component; zero collision; stable gaze-relative identity; unique whole and layer images; N/S and E/W mirror rejection; absence from production/default layout; and byte-exact preservation of all twelve historical files.

The pre-v2 historical checks also remain green without changing the frozen artifacts: the source/native rebuild audit passes **31 checks / 0 failures**, the old mat composition suite passes **1,994 / 0**, and the resting-North suite passes **1,631 / 0**. These are history-preservation checks, not evidence that the old retired-host composition was accepted.

The actual-room gate passes **111 checks / 0 failures** through actual `GameMain` and production `TownRoom` at native **1280×720**. It cycles `theo-workstation` through the exact accepted `workstations-v2:{facing}` capability and gaze for N/E/S/W, attaches only the two disposable candidate sprites at the common integer anchor, verifies both overlays contribute visible pixels, and preserves the desk's three collision shapes. Theo remains on the authored work point in his accepted directional seated typing presentation. Occupied/unoccupied pairs record an actor delta in every direction.

Measured actor/decor overlap is exactly **47 pixels total**: East rear **47**, and every other direction/layer **0**. This value is recorded rather than manufactured or used as an arbitrary quality threshold. The before/after visibility probe records 83 East-rear pixels covered by the existing assembly or actor together, 34 West-rear pixels covered by the existing assembly or actor together, and zero covered pixels in North/South; it does not invent a host-only split. Native and 4× inspection confirms that the test mat, debug instrument, and tool tray remain separately readable, the computer remains intact, and desk/device/actor depth is coherent in all four views. No worker starts, no save is accessed, and the production catalogue, default layout, and twelve retained engineer images remain byte-exact through capture.

Theo is only an existing host-contact, gaze, scale, and occlusion probe. This passive art review does not assign him an engineer role and does not require or create an engineer employee, engineer-specific pose, service, behavior, interaction, backend, build state, device execution, or hire.

Commands, from the repository root:

```sh
node dev/tools/check_engineer_mat_rebuild.mjs
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_engineer_build_kit_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_engineer_build_kit_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_engineer_build_kit_v2.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, restrained blue/green/cream/steel palette, binary alpha, and no antialiasing or transparent matte. |
| Perspective | 3 | Wide N/S and narrow E/W projections keep exact physical envelopes and sit naturally on the accepted screen-axis tabletop. |
| Silhouette/readability | 2 | The blue mat, dark instrument, and brown tray remain distinct at native size; breadboard holes, probe tips, and tiny tool cues necessarily stay abstract. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; both layers remain visible in every real room and preserve coherent actor/device/desk depth. |
| Direction consistency | 3 | All three motifs track gaze and physical worker-left/far-edge identity; every whole/layer view is unique and neither opposing pair is a mirror product. |
| Placement | 3 | Every object stays inside accepted tabletop ink, clears every accepted computer component, preserves actor contact, and adds no collision. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review candidate gate passes.

## Boundary

This review retains a complete passive-library candidate and its reproducible evidence. It does not edit or authorize the shared dev catalogue, production furniture data, approved/runtime asset paths, default placement, worker, contracts, saves, hiring, role mapping, backend behavior, or device execution. A separate catalogue-owner action may register the exact candidate metadata without implying production activation.
