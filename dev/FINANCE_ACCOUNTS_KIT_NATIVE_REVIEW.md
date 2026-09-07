# Finance accounts kit — deterministic native review

- Date: September 4, 2026
- Family: `finance_accounts_kit`
- Candidate revision: `finance_accounts_kit-v1`
Disposition: **passes the bounded visual gate and is catalogued in the existing `finance_accounts_kit` family as a non-production native-review candidate only**. It is not production-approved or runtime-bound.

## Candidate

The code-native fixture exports four independently declared screen-axis views on the accepted desk canvas **192×224**, with common floor pivot **(96,160)** and sprite offset **(0,-48)**. Every view contains the same three icon-only objects: a closed green ledger folio with abstract non-numeric bands, a compact glyph-free keypad-like planning device, and a framed two-tier tray holding blank receipt slips. Burgundy and brass filing cues distinguish the deliberately restrained paperwork set from the founder strategy kit's bright roadmap palette. There is no readable text, number, balance, fake account value, banking logo, transaction state, execution control, baked actor, or baked furniture.

Each direction exports `surface_decor_rear` and `surface_decor_front` as separate true-alpha RGBA overlays for the accepted `workstations-v2` desk. North/South use horizontal tabletop projections; East/West use narrow vertical projections. Object placement follows the desk user's gaze while upper-left screen lighting remains fixed. Every complete view and every corresponding layer is byte-distinct across directions. No completed bitmap is rotated, mirrored, flipped, rescaled, or reused as another facing. These are static paperwork/planning cues only; the candidate introduces no account data, calculator behavior, finance action, event binding, or changing runtime state.

## Evidence

- [Native isolated contact sheet](../game/tests/output/finance-accounts-kit/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/finance-accounts-kit/candidate-contact-sheet-4x.png)
- [Native isolated layer sheet](../game/tests/output/finance-accounts-kit/candidate-layers-native.png)
- [Native actual-room contact sheet](../game/tests/output/finance-accounts-kit/actual-room-contact-sheet-native.png)
- [4× actual-room inspection](../game/tests/output/finance-accounts-kit/actual-room-contact-sheet-4x.png)
- [Native actual-room contact sheet without proxy actor](../game/tests/output/finance-accounts-kit/actual-room-unoccupied-contact-sheet-native.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/finance-accounts-kit-v1/manifest.json)
- [Structural result](../game/tests/output/finance-accounts-kit/structural-results.json)
- [Actual-room result](../game/tests/output/finance-accounts-kit/actual-room-results.json)

The structural gate passes **217 checks / 0 failures**: exact accepted canvas, pivot and integer anchor; exactly three disjoint semantic objects and two nonempty reusable layers per facing; binary alpha and zero hidden RGB; byte-exact object/layer/whole reconstruction and fixture rebuild; accepted tabletop containment; individual and whole-kit clearance from the production monitor, keyboard and mouse; zero added collision; explicit absence from production and default-layout registration; palette and silhouette separation from the founder strategy kit; byte-distinct layers and whole compositions across all directions; and explicit N/S plus E/W mirror rejection.

The native actual-room gate passes **81 checks / 0 failures** through actual `GameMain` and production `TownRoom` at **1280×720**. It cycles the accepted `workstations-v2:{facing}` desk through N/E/S/W and attaches only two disposable fixture sprites. Both overlays contribute visible pixels in every direction and all three production collision shapes remain unchanged. Paired occupied/unoccupied crops measure 5 pixels of real Mina/rear-layer occlusion in East; the other views remain actor-unobstructed at the selected object positions, while the existing E/W assembly covers a bounded part of the rear decor. No worker starts, no save is accessed, and hashes verify the production furniture catalogue and default layout remain byte-exact.

Mina is used only because the current game has no finance employee or accepted finance-role pose. Her existing directional seated typing presentation verifies physical scale, desk contact, depth, and occlusion; it does **not** assign her a finance role, validate finance animation or behavior, or imply that this decor executes account work.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_finance_accounts_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_finance_accounts_kit.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_finance_accounts_kit.gd
```

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp one-pixel outlines, controlled paper/filing palette, binary alpha, and no antialiasing or transparent matte. |
| Perspective | 3 | Horizontal and vertical variants sit cleanly on the accepted screen-axis desktop planes with stable upper-left light. |
| Silhouette/readability | 2 | Ledger, keypad-like tool, and receipt trays remain separable at native size, though their deliberately tiny glyph-free detail stays abstract. |
| Layering/anchors | 3 | Shared registration reconstructs exactly; both reusable layers stay visible, with measured East proxy occlusion and ordered depth in every real room. |
| Direction consistency | 3 | All three motifs persist while placement follows gaze; each layer is unique and neither opposing pair is a mirror product. |
| Placement | 2 | Every object stays inside the accepted tabletop, clears production devices, and adds no collision, but only a non-finance Mina proxy—not a finance-role pose—is available for contact review. |

Mean **2.67 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary

This review and its dev-catalogue/gallery registration authorize retaining the focused geometry, fixtures, tests, captures, and evidence for human/native review only. They do not authorize production furniture registration, approved/runtime assets or bindings, default-layout changes, worker or contract changes, employee-role mapping, account access, calculation, payments, transaction execution, interaction, animation, or collision. The blank slips and keypad-like marks communicate paperwork/planning specialization only; they do not represent balances, real account data, or executable controls.
