# Founder strategy kit — deterministic native review

Date: September 4, 2026\
Family: `founder_strategy_kit`\
Disposition: **passes the bounded visual gate as a native-review candidate only**. It is not production-approved or runtime-registered.

## Candidate

The code-native fixture exports four independently declared screen-axis views on the accepted workstation canvas **192×224**, with common floor pivot **(96,160)**. Every view contains the same three icon-only objects: an open roadmap notebook, three small planning cards, and a tabbed decision folder. The notebook uses abstract color blocks and a route line rather than readable copy. There is no text, logo, currency, fake metric, chart, or baked workstation/actor.

Each direction exports `surface_decor_rear` and `surface_decor_front` as separate true-alpha RGBA overlays that can be attached to the existing workstation base. North/South use horizontal surface projections; East/West use narrow vertical projections. Object placement follows the host's gaze, while the screen-space upper-left lighting is stable. No completed bitmap is rotated, mirrored, flipped, rescaled, or reused as another facing.

## Evidence

- [Native isolated contact sheet](../game/tests/output/founder-strategy-kit/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/founder-strategy-kit/candidate-contact-sheet-4x.png)
- [Native actual-room contact sheet](../game/tests/output/founder-strategy-kit/actual-room-contact-sheet-native.png)
- [4× actual-room inspection](../game/tests/output/founder-strategy-kit/actual-room-contact-sheet-4x.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/founder-strategy-kit-v1/manifest.json)
- [Structural result](../game/tests/output/founder-strategy-kit/structural-results.json)
- [Actual-room result](../game/tests/output/founder-strategy-kit/actual-room-results.json)

The structural gate passes **120 checks / 0 failures**: binary alpha and zero hidden RGB; integer registration; one common canvas, pivot, and sprite offset; exactly three disjoint objects and two nonempty layers per facing; byte-exact object/layer/whole reconstruction; deterministic disk rebuild; accepted tabletop containment; accepted monitor/keyboard/mouse clearance; zero new collision cells; unique directions; and explicit N/S plus E/W mirror rejection.

The native actual-room gate passes **61 checks / 0 failures** through an actual `GameMain` and production `TownRoom`. It cycles the production `founder-workstation` through N/E/S/W, attaches only two disposable fixture sprites to the real desk node, preserves its three collision shapes exactly, and captures native **1280×720** rooms plus exact registered **192×224** crops. Both layers contribute visible pixels in every direction. The existing workstation/actor assembly covers 42 rear-layer pixels in East and West; all source pixels remain visible in North and South. No worker starts, and no save, production catalogue, runtime binding, or default layout is changed.

The actual founder `PlayerAvatar` is placed on the authored work cell as a standing scale and occlusion probe. This is not evidence of a seated or working founder pose, and no such capability is introduced by this candidate.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_founder_strategy_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_founder_strategy_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_founder_strategy_kit.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, fixed palette, binary alpha, and no antialiasing or matte. |
| Perspective | 3 | Horizontal and vertical variants sit cleanly on the accepted screen-axis desk planes with consistent upper-left light. |
| Silhouette/readability | 2 | The notebook, planning cards, and folder separate at native size, but their intentionally tiny icon grammar stays abstract. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; both disposable layers remain visible and the E/W rear occlusion behaves coherently in the real room. |
| Direction consistency | 3 | All three motifs persist while placement follows gaze; every view is unique and neither opposing pair is a mirror product. |
| Placement | 2 | The kit clears the production computer and adds no collision in actual `GameMain`, but the founder evidence is a standing probe rather than a validated seated/work pose. |

Mean **2.67 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review authorizes retaining the fixture and captures for human/native review only. It does not authorize catalogue insertion, gallery/index generation, production asset registration, runtime binding, layout changes, role behavior, interaction, animation, or collision. The stationery is static founder identity decor and does not imply automatic strategy, business progress, funding, or measured outcomes.
