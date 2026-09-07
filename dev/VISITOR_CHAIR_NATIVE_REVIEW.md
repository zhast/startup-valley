# Visitor chair — deterministic native candidate review

Date: September 4, 2026\
Candidate revision: `visitor-chair-v1`\
Existing catalogue family: `visitor_chair`\
Disposition: **registered in the developer catalogue as a native-review candidate only**. It passes the bounded visual gate but is not approved, production-registered, runtime-bound, or present in the default office.

## Candidate

The fixture exports a compact fixed guest chair in four independently authored screen-space projections. Every facing uses the planned **96×144** RGBA canvas, common floor pivot **(48,96)**, centered-sprite offset **(0,-24)**, and one occupied 32×32 floor cell. The three reusable base layers are `floor_shadow`, `seat_back`, and `seat_front`.

The visual identity is a low sage upholstered back and seat on an exposed warm-wood four-leg frame. There are no casters, five-star base, lift column, adjustment controls, armrests, or headrest. The anchor-aligned comparison against the accepted blue ergonomic task chair makes the difference explicit. The family contains no actor pixels, text, logos, or generated/source-extracted raster material.

North, East, South, and West are direct screen-axis declarations. Lighting stays on the screen upper-left while the back, seat, frame, visible contacts, shadow, and contact geometry change for each direction. No finished bitmap is rotated, mirrored, flipped, or scaled to produce another view.

## Structural and raster evidence

- [Native isolated four-facing sheet](../game/tests/output/visitor-chair/candidate-contact-sheet-native.png)
- [4× isolated inspection](../game/tests/output/visitor-chair/candidate-contact-sheet-4x.png)
- [Native layer sheet](../game/tests/output/visitor-chair/candidate-layers-native.png)
- [Accepted task chair / visitor chair comparison](../game/tests/output/visitor-chair/accepted-task-chair-vs-visitor-native.png)
- [Export manifest](../game/tests/fixtures/furniture-calibration/visitor-chair-v1/manifest.json)
- [Structural result](../game/tests/output/visitor-chair/structural-results.json)

The export gate passes **50 checks / 0 failures**. The structural gate passes **312 checks / 0 failures**. Together they prove:

- exact common canvas, pivot, integer sprite offset, and one-cell footprint;
- three nonempty layers per facing with binary alpha and zero RGB under transparent pixels;
- at least 16px transparent padding and a maximum 48px rise above the floor cell;
- four painted fixed-leg contact declarations per view;
- byte-exact layer-to-whole reconstruction and byte-exact deterministic disk rebuild;
- all twelve directional layers and all four wholes remain individually identifiable;
- North/South and East/West are neither horizontal nor vertical mirror products;
- direct pixel inequality against the accepted rolling task chair in every facing;
- owner-scoped passive admission only, with no interaction, work cell, seat anchor, pose set, or runtime seating capability.

## Actual GameMain evidence

- [Base-only actual-room sheet](../game/tests/output/visitor-chair/actual-room-base-contact-sheet-native.png)
- [Standing contact sheet](../game/tests/output/visitor-chair/actual-room-standing-contact-sheet-native.png)
- [Seated contact sheet](../game/tests/output/visitor-chair/actual-room-seated-contact-sheet-native.png)
- [4× seated inspection](../game/tests/output/visitor-chair/actual-room-seated-contact-sheet-4x.png)
- [Four unscaled 1280×720 GameMain panels](../game/tests/output/visitor-chair/actual-gamemain-contact-sheet-native.png)
- [Machine-readable actual-room result](../game/tests/output/visitor-chair/actual-room-results.json)

The native actual-room gate passes **221 checks / 0 failures** through the real `GameMain`, production `TownRoom` architecture, generic layered-prop factory, navigation graph, collision bodies, and alpha-aware visible-surface picker. Each of the four unscaled source panels is **1280×720**.

At common grid pivot `[12,13]`, every facing creates exactly one neutral prop, three native untransformed sprites, and one 32×32 `CollisionShape2D`. The occupied cell is non-walkable. Every layer owns a genuinely visible pickable pixel, transparent padding is not pickable, and all chair hits remain actionless. Before actor contact, all **1,422–1,880** opaque candidate pixels per facing match the exported layer union exactly in the room.

The same optional physical socket supports two deliberately limited probes:

- Standing mode places existing Mina on the clear adjacent cell, points her ordinary directional gaze toward the chair, preserves zero seat offset, and proves a safe real navigation position/reservation.
- Seated mode leaves Mina's physical feet and reservation on that same clear cell, then uses her already accepted `reviewed-workstations-v2` directional seated art with the candidate's integer visual mount. The rendered foot lands within three pixels of the chair pivot. This is contact/depth evidence, not a new pose or seating behavior.

Every seated view records both sides of the depth sandwich. Mina overlaps **303–978** opaque `seat_back` pixels and is always in front of them; she overlaps **62–102** opaque `seat_front` pixels and is always behind them. Wrong-depth count is zero for all eight comparisons. Switching standing/seated probe modes leaves collision geometry unchanged.

Safe near-wall placements exist at one or two cells from architecture, depending on facing. Grid `[1,3]`, adjacent to two wall axes, is rejected for all four directions by visual-wall, actor-headroom, and/or wall-clearance validation. Each rejected transaction preserves the prior committed chair.

The capture never starts the worker or accesses a save. Hash checks confirm that the production furniture catalogue and default layout remain byte-exact and that the developer catalogue is not mutated by the capture. The evidence records the current developer-catalogue registration separately from production/runtime admission.

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 2 | Crisp integer edges, restrained upholstery/frame palette, and clean alpha; the dithered floor shadow and broad flat cushions still merit final art-direction polish. |
| Perspective | 2 | Fixed-camera rise and floor contact are coherent in all views, though the orthogonal cushion planes are intentionally simple rather than richly modeled. |
| Silhouette/readability | 3 | Immediately reads as low fixed guest seating and remains clearly distinct from the tall blue caster task chair. |
| Layering/anchors | 3 | Common pivot, exact reconstruction, visible ownership of all layers, exact collision center, and measured rear/body/front occlusion all pass. |
| Direction consistency | 3 | Gaze, back placement, side profiles, lighting, and contact sockets agree; all layers are unique and opposing views are not mirror products. |
| Placement/contact | 3 | Four actual-room placements, near-wall acceptance, corner rejection, safe physical socket/reservation, and both standing and seated contact probes pass. |

Mean **2.67 / 3**, minimum **2 / 3**: the bounded native-review gate passes.

## Boundary and remaining work

This review authorizes retaining the exact fixture and its four exact directional records at `native_review_required` / `native_export` in the developer catalogue only. Approved and runtime paths remain null; production data, runtime art bindings, default layout, worker/contracts, and saves are unchanged.

The optional contact socket is geometry metadata, not a callable interaction or seating capability. No sit/leave action, reservation lifecycle, approach animation, employee ownership, guest behavior, role behavior, or default placement has been implemented. Production promotion would require a separate catalogue decision plus full seated transition/lifecycle review; this bounded evidence must not be cited as that approval.

Commands, from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_visitor_chair.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_visitor_chair.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_visitor_chair.gd
```
