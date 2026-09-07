# Theo campaign kit — deterministic native review

Date: September 4, 2026\
Family: `theo_campaign_kit`\
Disposition: **passes the bounded visual gate and is catalogued as a native-review candidate only**. It is not production-approved or runtime-registered.

## Candidate

The code-native fixture exports four independently declared screen-axis views on the accepted desk canvas **192×224** with common floor pivot **(96,160)**. Every view contains the same three icon-only objects: a staggered campaign-card stack, an audience-note card with two abstract person marks, and a three-panel generic creative-thumbnail sheet. There is no readable text, logo, platform mark, chart, performance number, or baked desk/actor.

Each direction exports `surface_decor_rear` and `surface_decor_front` as separate true-alpha RGBA layers. North/South use horizontal paper projections; East/West use narrow vertical surface projections. Object placement follows Theo's gaze, while highlights remain at the screen upper-left. No completed bitmap is rotated, mirrored, flipped, rescaled, or used as another facing.

## Evidence

- [Native isolated contact sheet](../game/tests/output/theo-campaign-kit/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/theo-campaign-kit/candidate-contact-sheet-4x.png)
- [Native actual-room contact sheet](../game/tests/output/theo-campaign-kit/actual-room-contact-sheet-native.png)
- [4× actual-room inspection](../game/tests/output/theo-campaign-kit/actual-room-contact-sheet-4x.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/theo-campaign-kit-v1/manifest.json)
- [Structural result](../game/tests/output/theo-campaign-kit/structural-results.json)
- [Actual-room result](../game/tests/output/theo-campaign-kit/actual-room-results.json)

The structural gate passes **122 checks / 0 failures**: binary alpha and zero hidden RGB; integer registration; one common canvas, pivot, and sprite offset; exactly three disjoint objects and two nonempty layers per facing; byte-exact object/layer/whole reconstruction; deterministic disk rebuild; accepted tabletop containment; accepted monitor/keyboard/mouse clearance; zero new collision cells; unique directions; and explicit N/S plus E/W mirror rejection.

The native actual-room gate passes **61 checks / 0 failures** through an actual `GameMain` and production `TownRoom`. It cycles Theo's accepted `workstations-v2:{facing}` desk and pose capability through N/E/S/W, adds only two disposable fixture sprites, preserves the desk's three collision shapes exactly, and captures both decor layers contributing visible pixels. The seated actor naturally covers 18 rear-layer pixels in East and 28 in West; North/South remain unobstructed at the chosen object positions. No worker starts and no save or production catalogue is changed.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_theo_campaign_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_theo_campaign_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_theo_campaign_kit.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, fixed palette, binary alpha, and no antialiasing or matte. |
| Perspective | 3 | Horizontal and vertical views sit cleanly on the accepted screen-axis desk planes with consistent upper-left light. |
| Silhouette/readability | 2 | All three motifs separate at native size, but the deliberately tiny card and audience-note objects rely on color/block grammar rather than fine detail. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; actual-room rear/front depth and E/W actor occlusion behave coherently. |
| Direction consistency | 3 | The three motifs persist while physical placement follows gaze; every view is unique and the opposing pairs are not mirror products. |
| Placement | 3 | All opaque pixels stay inside the accepted tabletop, clear all production computer parts, and add no collision in actual `GameMain`. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review authorizes retaining and indexing the fixture for human/native review. The dev catalogue and its generated gallery/index now record the N/E/S/W candidate, but `game/data`, runtime assets, worker code, role behavior and production capabilities remain unchanged. The campaign objects are static identity decor; they do not imply a live ad platform, real campaign execution, audience data, or measured results.
