# Growth analytics kit — deterministic native review

- Date: September 4, 2026
- Family: `growth_analytics_kit`
- Candidate revision: `growth_analytics_kit-v1`
Disposition: **passes the bounded visual gate and is catalogued in the existing `growth_analytics_kit` family as a non-production native-review candidate only**. It is not production-approved or runtime-bound.

## Candidate

The code-native fixture exports four independently declared screen-axis views on the accepted desk canvas **192×224**, with common floor pivot **(96,160)** and sprite offset **(0,-48)**. Every view contains the same three icon-only objects: a dark compact measurement console with non-numeric traces, linked attribution/test chips on a small note, and a sparse paired comparison bracket. The charcoal instrument silhouette, cool trace palette, and restrained state-comparison grammar are deliberately separate from Theo's light campaign-card stack, audience marks, and creative-thumbnail sheet. There is no text, logo, platform mark, number, fake metric, baked actor, or baked furniture.

Each direction exports `surface_decor_rear` and `surface_decor_front` as separate true-alpha RGBA overlays for the accepted `workstations-v2` desk. North/South use horizontal tabletop projections; East/West use narrow vertical projections. Object placement follows Theo's gaze while upper-left screen lighting remains fixed. No completed bitmap is rotated, mirrored, flipped, rescaled, or reused as another facing. The comparison marks are static visual grammar only; this candidate introduces no animation, event binding, data source, or changing runtime state.

## Evidence

- [Native isolated contact sheet](../game/tests/output/growth-analytics-kit/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/growth-analytics-kit/candidate-contact-sheet-4x.png)
- [Native actual-room contact sheet](../game/tests/output/growth-analytics-kit/actual-room-contact-sheet-native.png)
- [4× actual-room inspection](../game/tests/output/growth-analytics-kit/actual-room-contact-sheet-4x.png)
- [Native actual-room contact sheet without actor](../game/tests/output/growth-analytics-kit/actual-room-unoccupied-contact-sheet-native.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/growth-analytics-kit-v1/manifest.json)
- [Structural result](../game/tests/output/growth-analytics-kit/structural-results.json)
- [Actual-room result](../game/tests/output/growth-analytics-kit/actual-room-results.json)

The structural gate passes **204 checks / 0 failures**: exact accepted canvas, pivot and integer anchor; exactly three disjoint semantic objects and two nonempty reusable layers per facing; binary alpha and zero hidden RGB; byte-exact object/layer/whole reconstruction and fixture rebuild; accepted tabletop containment; individual and whole-kit clearance from the production monitor, keyboard and mouse; zero added collision; explicit absence from production and default-layout registration; palette and silhouette separation from Theo's campaign kit; unique directions; and explicit N/S plus E/W mirror rejection.

The native actual-room gate passes **81 checks / 0 failures** through actual `GameMain` and production `TownRoom` at **1280×720**. It cycles Theo's accepted `workstations-v2:{facing}` desk and seated typing capability through N/E/S/W, keeps him at the authored physical work point, and attaches only two disposable fixture sprites. Both overlays contribute visible pixels in every direction and all three production collision shapes remain unchanged. Paired occupied/unoccupied crops measure 35 pixels of real Theo/rear-layer occlusion in East; N/S/W remain actor-unobstructed at their selected object positions, while the existing assembly covers a bounded part of the E/W rear layer. No worker starts, no save is accessed, and hashes verify the production furniture catalogue and default layout remain byte-exact.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_growth_analytics_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_growth_analytics_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_growth_analytics_kit.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, controlled instrument palette, binary alpha, and no antialiasing or transparent matte. |
| Perspective | 3 | Horizontal and vertical variants sit cleanly on the accepted screen-axis desktop planes with stable upper-left light. |
| Silhouette/readability | 2 | Console, linked test note and comparison bracket separate at native size, but the deliberately tiny attribution/state grammar remains abstract. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; both reusable layers stay visible, with coherent East actor contact and ordered depth in every real room. |
| Direction consistency | 3 | All three motifs persist while placement follows gaze; every view is unique and neither opposing pair is a mirror product. |
| Placement | 3 | Every object stays inside the accepted tabletop, clears each production device, preserves Theo's accepted seated work point, and adds no collision. |

Mean **2.83 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review and its dev-catalogue/gallery registration authorize retaining the focused geometry, fixture, tests, captures, and evidence for human/native review only. They do not authorize production furniture registration, approved/runtime assets or bindings, default-layout changes, worker or contract changes, role behavior, interaction, animation, analytics collection, attribution logic, experiments, or collision. The abstract console marks communicate a visual specialization only; they do not represent real results or measured outcomes.
