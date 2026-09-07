# Mobile whiteboard — measured dev prototype contract

2026-09-04. **Geometry/showroom prototype only: no canonical placement, service, worker action, writing pose or runtime approval.** This replaces the catalogue’s untested 192px rise as a proposed physical model; it does not edit the catalogue or claim new shipped art.

## Fixed camera and dimensions

The room uses square32px floor cells. A physical vertical height translates upward on screen, independent of facing. The board is 88px wide,56px high,4px thick; its lower edge is24px above its local ground and upper edge80px. A standing48×80 source cell contains about68px of visible person, so the board top is modestly taller—not almost three people high.

Every layer/view uses canvas192×224, floor/sort pivot(96,160), and centered Sprite offset(0,−48). No per-view rotation, mirroring or scaling is used.

| View | Caster-base floor rectangle, host-relative | Main visible board | Exact conservative ink union | Face visible |
|---|---|---|---|---|
| N | `(-48,-16,96,32)` | `(-44,-78,88,56)` plus4px top thickness | `(-48,-82,96,98)` | Structural rear, not the writing face |
| E | `(-16,-48,32,96)` | `(-2,-124,4,144)` | `(-16,-124,32,172)` | True thin edge; no readable notes |
| S | `(-48,-16,96,32)` | `(-44,-78,88,56)` plus4px top thickness | `(-48,-82,96,98)` | Blank or separate planning face |
| W | `(-16,-48,32,96)` | `(-2,-124,4,144)` | `(-16,-124,32,172)` | True thin edge; no readable notes |

The long E/W edge is the projection of an88px ground-axis board width plus56px vertical height. It is not a172px-high board, and it is not the South image rotated sideways. Its top lies at−44−80=−124; the near end’s lower corner lies at44−24=20; the near casters end at+48. N/S caster contact ends at+16. Half-open rectangle edges are used throughout.

## Registered layers and shared material rules

[`mobile_whiteboard_geometry.gd`](../../game/tools/mobile_whiteboard_geometry.gd) independently specifies the screen-space rectangles for each view. It builds native RGBA images from code-native rectangular geometry. These are a faithful calibration prototype, not a claim that a generated four-view caster/frame family exists.

All seven layers retain the full canvas and the same pivot, in this draw order:

1. `GroundBase`: paired narrow floor rails and caster blocks. N/S rails atx±42 with far wheel bounds10×7 and near12×8; E/W rails aty±42 with independently specified left8×10/right8×12 blocks.
2. `RearSupports`: N/S posts atx±42, fromy−24 to10, plus lower cross brace; E/W far post fromy−66 to−38.
3. `FarTray`: N only,host`(-40,-32,80,9)`. It is fully hidden by the structural back; removing this layer does not change the North union.
4. `BoardFrame`: N/S4px top cap`(-44,-82,88,4)` and full88×56 face. N reuses the existing32px charcoal powdercoat material with quiet cross braces. S has a blank warm-white field. E/W use the genuine4px edge.
5. `FaceInsert`: S only, optional exact80×48 at host`(-40,-74)`, canvas`(56,86)`. No other view accepts the insert.
6. `NearTray`: S`(-40,-22,80,9)`; E`(2,-64,8,80)`; W`(-10,-64,8,80)`. Restrained native marker bars follow the actual tray axis.
7. `NearSupports`: E/W near post fromy18 to46; empty for N/S, whose common supports already remain visible below the board.

Every part stays at the host’s floor-sort depth. Whole actors sort by physical feet; no body split, borrowed seat fields or screen-height sorting is introduced. Highlights remain on screen upper-left in every view. N/E/W necessarily lack a readable planning diagram; that is honest camera visibility, not missing substituted front art.

The blank field is **#F4F1ED**, measured from the actual V3 planning insert, not falsely labeled literal#F1F1F1. The surrounding4px frame remains protected. Parent-supplied [V3 planning content](../../game/tests/fixtures/furniture-calibration/whiteboard-v3/planning-content.png) is opaque80×48; the prototype copies it byte-exactly into the optional layer. V1/V2 stroke-weight failures and all parent-generated sources remain preserved separately. No ImageGen call or semantic raster correction was made by this prototype task.

## World and visitor clearance

Occupied floor cells are`(-1,0),(0,0),(1,0)` for N/S and`(0,-1),(0,0),(0,1)` for E/W. The study includes a matching physical rectangle collider and passes these exact additional cells into the existing `OfficeNavigation.rebuild_placements` on a disposable instance. It never changes normal room JSON or mislabels the whiteboard as an archive.

Conservative visitor references are N(0,−32),E(32,0),S(0,32),W(−32,0), each with the unchanged48×80 standing envelope`(-24,-72,48,80)`. They are measured viewing positions, not exposed service interactions. Board ink and visitor headroom must both lie inside the actual room floor, separately from collision. At the current top wall,grid-centerY208 is the first safe proposed N/S row and240 the first E/W row atx112. One row nearer the wall fails; these checks do not shrink the visitor to make placement pass.

For the actual-room prototype,host(784,432) keeps the board clear of existing furniture and the main circulation lane. Actors walk behind, in front and around the blocked base using their existing movement, collision, source animations and physical-foot sorting. The route and native depth results will be recorded in the companion review after rendered inspection.

## Deliberate integration boundary

Current `TownRoom.PROP_SCENES` admits only existing families, and explicit canonical profiles presently describe either workstations or standing services. There is no accepted noninteractive visual-orientation family contract. This prototype therefore stops at a faithful additive showroom in real GameMain. It does **not** add a fake service profile, borrow the archive ID, open Studio, enable a canonical editor entry or persist the board. A later scoped implementation decision is required before a reviewed whiteboard can become a real placeable production family.
