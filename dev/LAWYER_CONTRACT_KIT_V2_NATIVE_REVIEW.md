# Lawyer contract kit v2 — deterministic native review

Date: September 6, 2026

Family: `lawyer_contract_kit`

Candidate revision: `lawyer-contract-kit-v2`

Disposition: **passes the bounded passive-library agent/native visual gate as a candidate only**. The candidate is not registered in the dev catalogue, production furniture data, runtime art, or the default office layout.

## Candidate

The provider-free code-native fixture exports one coherent N/E/S/W set of legal-planning decor on the accepted workstation canvas **192×224**, common floor pivot **(96,160)**, and sprite offset **(0,-48)**. Every facing contains the same three glyph-free objects: a navy contract binder with a visible spine and page block, an open review folder with blank/checklist leaves and green/blue/gold index tabs, and a small cup with red/blue pens. There is no readable text, logo, signature, gavel, court cue, fake case state, execution control, baked furniture, or baked character.

Every direction is independently drawn in native screen space. The binder spine and blank folder leaf stay on the worker's physical left; the checklist leaf and tabs stay on the worker's right; the page marks change from horizontal in N/S to vertical in E/W; and the pen order turns with the host gaze while screen-space lighting stays fixed. East is a new true-East construction, and West corrects the prior misdirected identity. No completed bitmap is rotated, mirrored, flipped, rescaled, or reused for another facing.

Each facing exports separate nonempty `surface_decor_rear` and `surface_decor_front` true-alpha overlays. All twelve prior legal source/candidate images remain present and byte-exact, including the original North/South native candidates and the reclassified West evidence. Image generation was not called and the failed East retry budget was not reopened.

## Evidence

- [Native isolated contact sheet](../game/tests/output/lawyer-contract-kit-v2/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/lawyer-contract-kit-v2/candidate-contact-sheet-4x.png)
- [Native layer sheet](../game/tests/output/lawyer-contract-kit-v2/candidate-layers-native.png)
- [Native object sheet](../game/tests/output/lawyer-contract-kit-v2/candidate-objects-native.png)
- [Native actual-room occupied sheet](../game/tests/output/lawyer-contract-kit-v2/actual-room-contact-sheet-native.png)
- [4× actual-room occupied inspection](../game/tests/output/lawyer-contract-kit-v2/actual-room-contact-sheet-4x.png)
- [Native actual-room unoccupied sheet](../game/tests/output/lawyer-contract-kit-v2/actual-room-unoccupied-contact-sheet-native.png)
- [4× actual-room unoccupied inspection](../game/tests/output/lawyer-contract-kit-v2/actual-room-unoccupied-contact-sheet-4x.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/lawyer-contract-kit-v2/manifest.json)
- [Structural result](../game/tests/output/lawyer-contract-kit-v2/structural-results.json)
- [Actual-room result](../game/tests/output/lawyer-contract-kit-v2/actual-room-results.json)

The structural gate passes **312 checks / 0 failures**. It proves exact canvas/pivot/offset registration; three disjoint semantic objects and two nonempty layers in every facing; binary alpha and zero hidden RGB; byte-exact object/layer/whole reconstruction; deterministic fixture rebuild; exact common object envelopes; accepted tabletop containment; clearance from the accepted monitor, keyboard, and mouse down to every object; zero collision; stable physical-left/right identity; unique whole and layer images; N/S and E/W mirror rejection; materially new East/West pixels; absence from production/default layout; and byte-exact preservation of nine failed/source masters plus three retained native candidates.

The actual-room gate passes **111 checks / 0 failures** through actual `GameMain` and production `TownRoom` at native **1280×720**. It cycles `mira-workstation` through the exact accepted `workstations-v2:{facing}` capability and gaze for N/E/S/W, attaches only the two disposable candidate sprites at the common integer anchor, verifies both overlays contribute visible pixels, and preserves the desk's three collision shapes. Mina remains on the authored work point in her accepted directional seated typing presentation. Occupied/unoccupied pairs record an actor delta in every direction. The intentionally edge-placed legal tools do not intersect Mina's pixels, so measured actor/decor overlap is honestly **0** rather than being manufactured as a quality proxy; the production assembly naturally masks 19 rear pixels in East and 25 in West, and visual inspection confirms coherent desk/device/actor depth in all four views. No worker starts, no save is accessed, and the production catalogue, default layout, and twelve retained legal images remain byte-exact through capture.

Mina is only an existing host-contact, gaze, scale, and occlusion probe. This passive art review does not assign her a legal role and does not require or create a legal employee, legal-specific pose, service, behavior, interaction, animation, case data, signature flow, or hire.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_lawyer_contract_kit_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_lawyer_contract_kit_v2.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_lawyer_contract_kit_v2.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, controlled navy/paper/brass palette, binary alpha, and no antialiasing or transparent matte. |
| Perspective | 3 | Wide N/S and narrow E/W projections sit cleanly on the accepted screen-axis tabletop with stable upper-left light. |
| Silhouette/readability | 2 | Binder, tabbed open folder, and two-pen cup remain separable at native size; the deliberately small checklist and page cues stay abstract. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; both layers remain visible in every real room and preserve coherent actor/device/desk depth without forcing overlap. |
| Direction consistency | 3 | All three motifs turn with physical worker-left/right identity; every whole/layer view is unique and neither opposing pair is a mirror product. |
| Placement | 3 | Every object stays inside accepted tabletop ink, clears each accepted computer component, preserves actor contact, and adds no collision. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review candidate gate passes.

## Boundary

This review retains a complete passive-library candidate and its reproducible evidence. It does not edit or authorize the shared dev catalogue, production furniture data, approved/runtime asset paths, default placement, worker, contracts, saves, hiring, role mapping, or legal workflow. A separate catalogue-owner action may register the exact candidate metadata without implying production activation.
