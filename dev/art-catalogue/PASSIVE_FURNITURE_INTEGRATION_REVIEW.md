# Canonical passive furniture — final bounded review

Frozen 2026-09-04 10:40 UTC. This is a **working dev-only integration**, not production art admission. Whiteboard and rolling pedestal now use the real OfficeLayout, TownRoom native-layer factory, collision/navigation, painted-surface picking and editor transaction paths. No production catalogue/layout, actor/main/HUD behavior, worker contract, personal data, save, generation, commit or push was added by this pass.

## What changed

- `profile_kind: decorative` requires explicit native layers, occupied/clearance cells, anchor, measured image bounds and ambient attachment list. Interaction, work, seat, service, pose and action fields are rejected. Resolved passive placements do not manufacture zero-cell targets; direct interaction-coordinate lookup returns a non-finite sentinel, and no UI interaction is exposed.
- Optional standing viewpoints are geometry only. Each is inside declared free clearance and encloses the actual conservative48×80 standing source. Headroom is checked against architecture separately from the prop's own image bounds. The test demonstrates a pedestal whose body fits at `(2,5)` but whose North viewer does not; `(2,6)` succeeds.
- Candidate admission is exact-definition, local-model, live-owner and editor-only. Mutation, another owner/model, reconfiguration or teardown invalidates it. Runtime-ready art still requires true art/geometry review. Workstation pose gates and the original seven PackedScene routes remain unchanged.
- Only a validated explicit decorative family can use the neutral Node2D native-layer carrier. Unknown legacy kinds cannot silently receive this factory. Real occupied-cell collision and canonical sprite origins/regions are shared with the existing path.
- The editor omits absent interaction dots/routes and seated wording. The optional passive fixture hides Sit/Type/Leave and refuses export. No standing viewpoint becomes an action or navigation destination.

Implementation: [OfficeLayout](../../game/world/office_layout.gd), [TownRoom](../../game/world/town_room.gd), [editor](../../game/tools/office_layout_editor.gd), [dev profiles](../../game/tools/passive_furniture_profiles.gd), [isolated GameMain fixture](../../game/tools/passive_furniture_fixture.gd), [focused suite/capture](../../game/tests/test_passive_furniture.gd). Approved scope is preserved in [the plan](PASSIVE_FURNITURE_INTEGRATION_PLAN.md).

## Art and registration

The whiteboard uses its frozen seven-layer four-view192×224 exports, pivot96,160, sprite offset0,−48. Only the South FaceInsert is replaced in this dev recipe with [a separately registered candidate](../../game/tests/fixtures/furniture-calibration/passive-furniture-v1/whiteboard-south-planning.png): every pixel of the existing80×48 V3 insert is copied at56,86, with transparent padding and no scaling or repaint. The blank whiteboard exports remain intact. [Mechanical exporter](../../game/tools/export_passive_planning_insert.gd).

The pedestal uses its frozen six-layer four-view96×144 exports, pivot48,96, offset0,−24. Its generated South drawer insert and code-native common rear/sides are not represented as four newly generated faces.

All53 referenced layer imports use lossless native sampling, no mipmaps and `fix_alpha_border=false`. Tests compare complete decoded RGBA, including zero-alpha RGB, against actual source PNGs. The eight native settled views also compare every opaque rendered prop pixel against the ordered source-layer union. No source master or prior prototype PNG was changed.

## Verification and evidence

Final commands, with worker-disabled disposable transport:

```sh
godot --headless --path game --fixed-fps 30 --script res://tests/test_passive_furniture.gd
godot --path game --fixed-fps 30 --write-movie res://tests/output/passive-furniture/world.avi --script res://tests/test_passive_furniture.gd
```

- Final fixed30FPS headless: **850 checks, zero failures**.
- Final rendered: **935 checks, zero failures**,31 PNGs:22 full native1280×720 states and9 nearest4× details.
- Movie:384 actual30FPS frames,12.8seconds. Two real-input routes have distinct start/halfway/end physical positions and image hashes. The second route is `(784,464) → (816,516) → (816,592)`; its middle is no longer an endpoint mislabeled by a fixed tick count.
- Real mouse/keyboard popup focus, arrow selection and Enter; allNESW R previews and click commits; invalid wall rollback, Escape restoration, founder and other-employee obstruction, safe Undo, export refusal, painted passive occlusion of Mina, unchanged archive service picking, real click-to-move around both props and teardown followed by a new ordinary scene.
- All0–4 furniture-unlock stages validate. Native captures show0/1/2 actual employees; stages3/4 keep the two-employee slice while testing later furniture composition. Normal unlock particles may remain visible in the immediate stage snapshots; they are not baked into the new art.
- Existing GameMain behavior is preserved: a layout rebuild cancels an old founder route. Moving a pedestal into a *future* route cell is allowed when no live actor occupies it; a new real ground click computes the safe replacement route. This pass does not claim automatic route continuation.
- Project validation, direction429 and service5950 headless checks passed during development. The parent/reader's separate22-suite/static/motion checkpoint covers the frozen shared runtime. Its original test hash predates only the final passive **test assertion** adjustment described below; no production code changed afterward.

Evidence: [final manifest](../../game/tests/output/passive-furniture/manifest.json), [headless report](../../game/tests/output/passive-furniture/headless.json), [movie](../../game/tests/output/passive-furniture/world.avi), [South whiteboard](../../game/tests/output/passive-furniture/dev-whiteboard-south.png), [South pedestal](../../game/tests/output/passive-furniture/dev-pedestal-south.png), [East whiteboard detail](../../game/tests/output/passive-furniture/dev-whiteboard-east-4x.png), [occupied rotation rejected](../../game/tests/output/passive-furniture/occupied-rotation-rejected.png), [actual Mina occlusion](../../game/tests/output/passive-furniture/passive-occludes-employee.png), [mature layout](../../game/tests/output/passive-furniture/office-stage-4.png).

## Native inspection and limits

All22 native states and9 enlarged details were inspected across the final art/layout sequence; the final replay's invalid-wall and corrected three route frames were rechecked after the capture-only corrections. No layer seam, opaque matte, bitmap rotation, furniture-wall overlap or unexpected picking-through was found in those views. The South planning insert has complete boxes/arrows, and the pedestal's two handles/divider remain legible. These are bounded observations, not a claim that every game state is polished.

The whiteboard frame/casters remain schematic. Its East/West view is honestly a thin structural edge, not a readable planning face. The pedestal's plain dark rear/side view carries weaker identity than its South drawers. North-side actor concealment behind the tall whiteboard is natural depth, not a missing sprite. The dev toolbar intentionally overlays the bottom of the room and can hide the founder's feet at the original spawn; it is not a proposed production HUD.

The prior construction reviews' provisional scores remain appropriate: pixel coherence3, perspective3, silhouette/readability2, layering/anchors3, directional consistency2, placement2 (mean2.5). They are **not approval flags**. Both families remain `calibration_candidate` with art=false and geometry=false in the local recipe; neither is added to production or the catalogue's approved paths.

## Harness corrections, kept honest

The first native batch is preserved at [passive-furniture-initial](../../game/tests/output/passive-furniture-initial/). Its invalid-placement explanation crossed the old toolbar boundary; moving the optional toolbar up12px fixed the visible text. A later strict check used the entire Label allocation, including blank height retained after popup relayout, instead of the two rendered text lines. The final test bounds actual line height/count against paper and viewport; the final native frame is visually inside its paper. No font size was reduced and no validation reason was removed from the tooltip/result.

Headless counts without `--fixed-fps 30` depend on how often the engine advances collision ticks while synthetic input settles, so the fixed-FPS command is the repeatable comparison. Test count alone is not acceptance. A GDScript warning about raw `Image.load_from_file` is confined to this dev source-identity check; runtime sprites use imported Texture2D resources.
