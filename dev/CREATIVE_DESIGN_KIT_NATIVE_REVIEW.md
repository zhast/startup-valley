# Creative design kit — deterministic native review

Date: September 6, 2026\
Family: creative_design_kit\
Disposition: **passes the bounded visual gate as a native-review candidate only**. It is not approved, runtime-registered, or placed in the default office.

## Candidate and preserved North history

The provider-free code-native fixture exports four independently authored
screen-axis views on the accepted desk canvas **192×224** with the common floor
pivot **(96,160)**. Every facing carries the same passive identity:

- one low pen display with a blank abstract color canvas;
- one bound fan of physical color swatches;
- one small tray holding a stylus and generic design tool.

North/South use wide surface projections and East/West use narrow surface
projections. Object placement and stand exposure follow the host gaze, while
highlights remain fixed at screen upper-left. No completed bitmap is rotated,
mirrored, flipped, resampled, or used as another facing. The exports contain no
readable text, logo, fake metric, baked actor, or live tool state.

The earlier generated North source remains byte-exact at
game/assets/source/overnight-20260904/roles/creative-north-v1.png (SHA-256
93d3295cf53f652397ea664cf457600852ca9cefbc1f36c88c0f9e619f28ffc0).
Its [prompt](art-catalogue/prompts/creative-north-v1.md), original
[native review](art-catalogue/CREATIVE_NORTH_REVIEW.md), later
[composition review](art-catalogue/CREATIVE_NORTH_COMPOSITION_REVIEW.md), one
completed source attempt, and extracted tablet/swatch/camera components remain
historical provenance. They were neither overwritten nor transformed into the
new facings. No new raster generation was needed or performed: the four-facing
library is original editable code-native geometry.

## Evidence

- [Isolated native contact sheet](../game/tests/output/creative-design-kit/candidate-contact-sheet-native.png)
- [Isolated 4× inspection](../game/tests/output/creative-design-kit/candidate-contact-sheet-4x.png)
- [Native rear/front layer sheet](../game/tests/output/creative-design-kit/candidate-layers-native.png)
- [Mina/Theo actual-room contact sheet](../game/tests/output/creative-design-kit/actual-room-contact-sheet-native.png)
- [Mina/Theo actual-room 4× inspection](../game/tests/output/creative-design-kit/actual-room-contact-sheet-4x.png)
- [Unoccupied comparison sheet](../game/tests/output/creative-design-kit/actual-room-unoccupied-contact-sheet-native.png)
- [Four unscaled 1280×720 room panels](../game/tests/output/creative-design-kit/actual-room-full-panels-native.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/creative-design-kit-v1/manifest.json)
- [Structural result](../game/tests/output/creative-design-kit/structural-results.json)
- [Corrected native result](../game/tests/output/creative-design-kit/actual-room-results.json)
- [Preserved initial failed result](../game/tests/output/creative-design-kit/actual-room-results-initial-failure.json)

The exporter passes **16 checks / 0 failures**. The focused structural gate passes
**227 checks / 0 failures**: exact canvas/pivot, two nonempty reusable layers,
binary alpha, zero hidden RGB, integer transforms, zero collision, tabletop
containment, accepted monitor/keyboard/mouse clearance, three disjoint semantic
objects in every direction, deterministic disk reconstruction, distinct whole
and layer hashes, and explicit opposing-view mirror rejection. It also locks the
historical North source hash and confirms the old prompt and both reviews remain.

The corrected native gate passes **168 checks / 0 failures** through actual
GameMain and production TownRoom at **1280×720**. Both mira-workstation and
theo-workstation cycle through the real accepted
workstations-v2:{north,east,south,west} profiles. Mina and Theo use only their
existing seated typing presentations at each authored work point as scale,
gaze, contact, and host-depth probes. Both disposable overlays contribute
visible pixels at both desks in every direction, their native integer transforms
and z offsets remain exact, and the desk collision count is unchanged.
Production furniture data, the default layout, and the shared dev catalogue
remain byte-exact during capture; no worker starts and no save is accessed.

Direct actor/overlay pixel intersection is honestly **0 for Mina and 0 for
Theo**. The tools occupy valid clear tabletop edge space, so manufacturing an
intersection would make the composition worse. The initial native run preserved
**154 checks / 2 failures** because it incorrectly required nonzero intersection
for each proxy; every other assertion passed. Visual inspection found no art
defect, the art stayed unchanged, and only that acceptance rule was replaced by
the appropriate requirements: exact anchored actor contact, accepted
directional capability, ordered host depth, and visible rear/front contribution.

Commands, from the repository root:

~~~sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_creative_design_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_creative_design_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_creative_design_kit.gd
~~~

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp native integer edges, binary alpha, clean transparent RGB, restrained shared palette, and fixed screen-space highlights. |
| Perspective | 3 | Wide and narrow authored projections sit on the accepted desk planes; display stands and tool axes follow host gaze without rotating finished pixels. |
| Silhouette/readability | 2 | The pen display and swatch fan read at native size; the deliberately small stylus tray is subtle and competes with the ordinary computer assembly. |
| Layering/anchors | 3 | One canvas and pivot reconstruct exactly; actual-room evidence proves ordered rear/front contribution at both proxy desks in every facing. |
| Direction consistency | 3 | All three objects persist while placement, display aspect, stand exposure, swatch fan, and tray details remain direction-specific and non-mirrored. |
| Placement | 3 | Every object stays within the accepted tabletop, clears accepted computer components and actors, and adds no floor collision. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review authorizes only a non-production full-family proposal. It adds no
creative employee, portrait, pose, active pen animation, role behavior, backend,
worker authority, provider, interaction, runtime binding, save state, or default
placement. Mina and Theo are existing proxies, not stand-ins for a new accepted
role. The display’s abstract blocks and physical swatches are static decoration,
not live design data or fabricated progress.
