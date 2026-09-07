# Mina product kit — deterministic native review

Date: September 4, 2026

Catalogue family: `mina_discovery_kit`

Candidate revision: `mina_product_kit-v1`

Disposition: **passes the bounded visual gate and is catalogued under the existing `mina_discovery_kit` family as a non-production native-review candidate only**. It is not production-approved or runtime-bound.

## Candidate

The code-native fixture exports four independently declared screen-axis views on the accepted workstation canvas **192×224**, with common floor pivot **(96,160)**. Every view contains the same three icon-only product/research tools: an open insight notebook with abstract affinity marks and a lens, a connected pair of prototype wireframes, and three material-testing tokens. The cool indigo/cerulean/mint/lilac palette and paper-tool silhouette are deliberately separate from Theo's campaign stationery and from the shared research bench's large machine, structure, footprint, and interaction.

Each direction exports `surface_decor_rear` and `surface_decor_front` as separate true-alpha RGBA overlays for the accepted desk. North/South use horizontal surface projections; East/West use narrow vertical projections. Object placement follows Mina's gaze while upper-left screen lighting stays fixed. No completed bitmap is rotated, mirrored, flipped, rescaled, or reused for another facing.

## Evidence

- [Native isolated contact sheet](../game/tests/output/mina-product-kit/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/mina-product-kit/candidate-contact-sheet-4x.png)
- [Native actual-room contact sheet](../game/tests/output/mina-product-kit/actual-room-contact-sheet-native.png)
- [4× actual-room inspection](../game/tests/output/mina-product-kit/actual-room-contact-sheet-4x.png)
- [Native actual-room contact sheet without actor](../game/tests/output/mina-product-kit/actual-room-unoccupied-contact-sheet-native.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/mina-product-kit-v1/manifest.json)
- [Structural result](../game/tests/output/mina-product-kit/structural-results.json)
- [Actual-room result](../game/tests/output/mina-product-kit/actual-room-results.json)

The structural gate passes **178 checks / 0 failures**: binary alpha and zero hidden RGB; integer registration; one common canvas, pivot, and sprite offset; exactly three disjoint objects and two nonempty fixture-scoped layers per facing; byte-exact object/layer/whole reconstruction; deterministic fixture rebuild; accepted tabletop containment; accepted monitor/keyboard/mouse clearance down to every individual object; zero new collision cells; explicit absence from the production catalogue and default layout; visual and semantic separation from Theo's campaign kit and the shared research bench; unique directions; and explicit N/S plus E/W mirror rejection.

The native actual-room gate passes **81 checks / 0 failures** through actual `GameMain` and production `TownRoom` at **1280×720**. It cycles Mina's accepted `workstations-v2:{facing}` desk and seated typing capability through N/E/S/W, adds only two disposable fixture sprites, verifies her logical feet remain on the authored work point, preserves the desk's three collision shapes exactly, and captures both decor layers contributing visible pixels in every direction. Paired occupied/unoccupied crops measure five pixels of natural Mina/rear-layer occlusion in East; the other chosen placements remain actor-unobstructed. Existing desk/computer geometry covers another 18 rear pixels in East and 9 in West. No worker starts, and hashes verify the production furniture catalogue and default layout stay byte-exact.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_mina_product_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_mina_product_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_mina_product_kit.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, controlled palette, binary alpha, and no antialiasing or transparent matte. |
| Perspective | 3 | Horizontal and vertical variants sit cleanly on the accepted screen-axis desk planes with consistent upper-left light. |
| Silhouette/readability | 2 | Notebook, connected screen flow, and sample tokens separate at native size, but the intentionally tiny research grammar remains abstract. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; both reusable layers stay visible, and paired room captures verify the real actor-depth interaction. |
| Direction consistency | 3 | The three motifs persist while physical placement follows gaze; every view is unique and neither opposing pair is a mirror product. |
| Placement | 3 | All ink remains inside the accepted tabletop, clears every accepted production computer component, keeps Mina on her real seat, and adds no collision. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review and the dev-catalogue registration authorize retaining and indexing the focused geometry, fixture, tests, and evidence for human/native review only. The candidate revision remains `mina_product_kit-v1`, transparently mapped to the pre-existing `mina_discovery_kit` family; it does not add a family or alter `product_prototype_kit`. Neither action authorizes production furniture registration, approved/runtime assets or bindings, default-layout changes, worker or contract changes, role behavior, interaction, animation, or collision. The tools are static product/research identity decor; they do not imply live customer data, automated product decisions, experiment results, or measured outcomes.
