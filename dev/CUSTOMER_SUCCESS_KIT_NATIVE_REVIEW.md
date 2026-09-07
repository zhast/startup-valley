# Customer success kit — deterministic native review

Date: September 4, 2026\
Family: `customer_success_kit`\
Disposition: **passes the bounded visual gate and is catalogued as a native-review candidate only**. It is not production-approved, runtime-registered, or placed in the default office.

## Candidate

The provider-free code-native fixture exports four independently placed screen-axis views on the accepted desk canvas **192×224** with common floor pivot **(96,160)**. Every view carries the same three small, glyph-free objects: an upright compact headset on its dock, three stepped ticket-triage cards, and a small conversation/status console with a blank screen and simple state lamps. There is no readable label, number, metric, logo, platform mark, giant speech bubble, baked furniture, or baked character.

Each direction exports reusable `surface_decor_rear` and `surface_decor_front` RGBA layers. North/South use wide surface projections; East/West use narrow surface projections. Object placement follows host gaze while lighting remains fixed at screen upper-left. No finished bitmap is rotated, mirrored, flipped, scaled, or reused as another facing.

## Evidence

- [Native isolated contact sheet](../game/tests/output/customer-success-kit/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/customer-success-kit/candidate-contact-sheet-4x.png)
- [Native layer sheet](../game/tests/output/customer-success-kit/candidate-layers-native.png)
- [Native actual-room occupied contact sheet](../game/tests/output/customer-success-kit/actual-room-contact-sheet-native.png)
- [Native actual-room unoccupied contact sheet](../game/tests/output/customer-success-kit/actual-room-unoccupied-contact-sheet-native.png)
- [4× actual-room inspection](../game/tests/output/customer-success-kit/actual-room-contact-sheet-4x.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/customer-success-kit-v1/manifest.json)
- [Structural result](../game/tests/output/customer-success-kit/structural-results.json)
- [Actual-room result](../game/tests/output/customer-success-kit/actual-room-results.json)

The structural gate passes **222 checks / 0 failures**: true/binary alpha and zero hidden RGB; integer registration; one canvas, pivot, and sprite offset; exactly three disjoint semantic objects and two nonempty layers per facing; byte-exact object/layer/whole reconstruction; deterministic disk rebuild; accepted tabletop containment; monitor/keyboard/mouse clearance for every object; zero new collision cells; unique whole and layer identities; and explicit opposing-view mirror rejection.

The actual-room gate passes **83 checks / 0 failures** through an actual `GameMain` and production `TownRoom` at native **1280×720**. It cycles `mira-workstation` through the accepted `workstations-v2:{facing}` capabilities, adds only two disposable fixture sprites, preserves the desk's three collision shapes in every view, and proves both overlays contribute visible pixels. Occupied/unoccupied pairs confirm Mina at the exact authored work point with her accepted directional seated typing presentation. The East rear headset-dock cradle records **3 actor-occluded pixels**, exercising the intended actor/decor depth relationship without sacrificing object or device clearance. Production furniture data and the default layout remain byte-exact through capture; no worker starts and no save is accessed.

Mina is an existing employee used only as a scale, seat-contact, gaze, and occlusion probe. The actual `GameMain` roster remains exactly Mina and Theo. There is no customer-success/support hire, portrait, role behavior, role-specific pose, service authority, or implied future employee in this candidate.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_customer_success_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_customer_success_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_customer_success_kit.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp single-pixel edges, restrained material palette, binary alpha, and no antialiasing or matte. |
| Perspective | 3 | Wide and narrow projections sit cleanly on the accepted screen-axis desk planes with consistent upper-left light. |
| Silhouette/readability | 2 | The docked headset and stepped tickets read at native size; the deliberately small console remains a generic indicator surface rather than communicating fine detail. |
| Layering/anchors | 3 | Common registration reconstructs exactly; room evidence proves both layers and a measured East actor/rear-layer occlusion. |
| Direction consistency | 3 | All three motifs persist while placement follows gaze; every whole/layer view is unique and neither opposing pair is a mirror product. |
| Placement | 3 | Every opaque pixel remains inside the accepted tabletop, clears all accepted computer components, and adds no collision. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review authorizes retaining and indexing the fixture for later human/native review only. The dev catalogue and its generated gallery/index now record the N/E/S/W candidate at `native_review_required`; `game/data`, runtime art bindings, the default layout, worker/contracts, saves, hiring, and role behavior remain unchanged. The colored card tabs and console lamps are decorative state cues only; they do not represent real tickets, customer conversations, response metrics, or a functioning support service.
