# Product prototype kit — deterministic native review

Date: September 4, 2026\
Family: `product_prototype_kit`\
Candidate revision: `product_prototype_kit-v1`\
Disposition: **passes the bounded visual gate and is catalogued in the existing `product_prototype_kit` family as a non-production native-review candidate only**. It is not production-approved or runtime-bound.

## Candidate

The code-native fixture exports four independently declared screen-axis views on the accepted `research_table` canvas **192×320**, with common floor pivot **(96,240)** and sprite offset **(0,-80)**. Every view contains the same three icon-only physical prototyping tools: a steel assembly fixture with clamps and a bright test body, three loose fit-test parts with distinct profiles, and a small dial-and-probe inspection gauge. The steel, indigo, cerulean, teal, amber, and coral grammar is deliberately separate from Mina's notebook/wireframe/material-token discovery kit and from the shared research bench's large analyzer and built-in tool overlay. There is no text, logo, fake metric, baked actor, or baked furniture.

Each direction exports `surface_decor_rear` and `surface_decor_front` as separate true-alpha RGBA overlays for the accepted `research-bench-v1` host. North/South use horizontal tabletop projections; East/West use narrow vertical projections. Object placement follows the worker's gaze while upper-left screen lighting remains fixed. No completed bitmap is rotated, mirrored, flipped, rescaled, or reused as another facing.

## Evidence

- [Native isolated contact sheet](../game/tests/output/product-prototype-kit/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/product-prototype-kit/candidate-contact-sheet-4x.png)
- [Native actual-room contact sheet](../game/tests/output/product-prototype-kit/actual-room-contact-sheet-native.png)
- [4× actual-room inspection](../game/tests/output/product-prototype-kit/actual-room-contact-sheet-4x.png)
- [Native actual-room contact sheet without actor](../game/tests/output/product-prototype-kit/actual-room-unoccupied-contact-sheet-native.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/product-prototype-kit-v1/manifest.json)
- [Structural result](../game/tests/output/product-prototype-kit/structural-results.json)
- [Actual-room result](../game/tests/output/product-prototype-kit/actual-room-results.json)

The structural gate passes **171 checks / 0 failures**: exact accepted canvas, pivot, and anchor; exactly three disjoint semantic objects and two nonempty reusable layers per facing; binary alpha and zero hidden RGB; byte-exact object/layer/whole reconstruction and fixture rebuild; integer-only registration with no raster transform; accepted research-table support beneath every opaque pixel; clearance from the complete production `ToolOverlay`; zero added collision; explicit semantic separation from Mina's discovery kit and the shared research equipment; unique directions; and explicit N/S plus E/W mirror rejection.

The native actual-room gate passes **90 checks / 0 failures** through actual `GameMain` and production `TownRoom` at **1280×720**. It finds one collision-valid pivot for every accepted facing, cycles the production `research-bench` through N/E/S/W, presents Mina's accepted directional research pose at the authored work point, and attaches only two disposable fixture sprites. Both overlays contribute visible pixels in every direction and all six production collision shapes remain unchanged. Paired occupied/unoccupied crops measure 16 pixels of real Mina/rear-layer occlusion in East and 90 in West; N/S remain naturally unobstructed at the chosen positions. Existing assembly or actor depth also covers a bounded portion of the decor while leaving both layers visibly exercised. No worker starts, no save is accessed, and hashes verify the production furniture catalogue and default layout remain byte-exact.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_product_prototype_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_product_prototype_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_product_prototype_kit.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, controlled material palette, binary alpha, and no antialiasing or transparent matte. |
| Perspective | 3 | Horizontal and vertical variants sit cleanly on the accepted screen-axis research surfaces with stable upper-left light. |
| Silhouette/readability | 2 | The clamp fixture, loose parts, and dial/probe separate at native size, but their deliberately tiny physical-tool grammar remains abstract. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; both reusable layers stay visible, with coherent E/W actor contact and ordered N/S depth in the real room. |
| Direction consistency | 3 | All three motifs persist while placement follows gaze; every view is unique and neither opposing pair is a mirror product. |
| Placement | 3 | Every opaque pixel rests on accepted bench structure, clears the built-in research tools, preserves Mina's authored work point, and adds no collision. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review and the dev-catalogue registration authorize retaining and indexing the focused geometry, fixture, tests, captures, and evidence for human/native review only. They do not authorize production furniture registration, approved/runtime assets or bindings, default-layout changes, worker or contract changes, role behavior, interaction, animation, or collision. The objects are static product-prototyping decor; they do not imply live experiments, automated product decisions, device telemetry, quality certification, or measured outcomes.
