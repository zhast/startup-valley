# Rolling storage pedestal — measured construction contract

2026-09-04. **Dev-only construction/art brief, not a runtime family or drawer interaction.** The parent approved the 32px-rise side-storage version below. The catalogue's 48px rise was only an untested upper envelope; no catalogue values are changed here.

## Size and projection

Use one **96×144 RGBA canvas**, fixed floor pivot **(48,96)** and centered sprite offset **(0,−24)**. A square **32×32 occupied floor cell** contains the separate caster base. The cabinet body is **28×24** in N/S, **24×28** in E/W. Rotate these physical floor dimensions, never the raster, vertical-rise vector or baked light.

The top is **32px above the floor**, matching the calibrated desk surface. The body underside is **4px above the floor**; the near vertical face is therefore 28px high. This is desk-height **side storage**. It is not promised to fit under a 32px desk, and its occupied cell may not overlap a desk or actor socket.

| Quantity, host-relative | N/S | E/W |
|---|---|---|
| Reserved floor | `(-16,-16,32,32)` | same |
| Body ground projection | `(-14,-12,28,24)` | `(-12,-14,24,28)` |
| Top plane | `(-14,-44,28,24)` | `(-12,-46,24,28)` |
| Near body face | `(-14,-20,28,28)` | `(-12,-18,24,28)` |
| Protected near-face inset | `(-12,-18,24,24)` | `(-10,-16,20,24)` |
| Top field, inside 2px rim | `(-12,-42,24,20)` | `(-10,-44,20,24)` |

The four caster mounts lie at (±11,±13) in N/S and exchange floor axes to (±13,±11) in E/W, inside the common one-cell base. Their code-native fork/wheel silhouettes keep fixed upper-left illumination and stay inside x±16; the nearest contact boundary is y14 in N/S and y12 in E/W, not the transparent canvas bottom. Rear wheels are allowed to be naturally hidden by the solid carcass. Do not paste all four wheels in front merely to make their count visible. The cabinet has no object-level cast-shadow asset in this first prototype; existing actor shadows remain unchanged.

## Physical faces versus service side

`service_side` means the direction in which the real drawer front opens. The visitor stands on that side and looks in the opposite direction. It is not an employee's seated work gaze.

| Service side | Fixed camera sees | Proposed visitor cell | Approach gaze |
|---|---|---|---|
| North | structural rear | `(0,-1)` | South |
| East | left side panel; drawer edge at screen right | `(1,0)` | West |
| South | two-drawer service front | `(0,1)` | North |
| West | right side panel; drawer edge at screen left | `(-1,0)` | East |

One occupied cell `(0,0)` and one clear visitor cell are required. The conservative standing envelope is **(-24,-72,48,80)** relative to the visitor's floor socket; the original 48×80 actor sources and their foot anchor are unchanged. Check body/visible caster ink against room architecture independently of floor collision, and check the visitor's whole visual envelope without shrinking it to pass a wall.

This proposal exposes no actual drawer action, files, inventory or storage state. The dev room may exercise navigation around the occupied cell and inspect standing scale; it must not borrow the archive's Studio action or add fake persistence to imply functionality.

## Art request: one opaque South front

**Requested native file:** `game/tests/fixtures/furniture-calibration/pedestal-v1/drawer-front.png`, exactly **24×24**, opaque RGB. Preserve its original generated master and prompt separately under the overnight source tree. Root owns the generation and mechanical normalization.

This is a flat material/face insert, **not an entire cabinet**. It occupies canvas **(36,78,24,24)** in the full registered South assembly. The surrounding 2px charcoal frame, top, caster base and perspective are provided by the geometry helper.

Draw two simple stacked drawers in a restrained charcoal/powdercoat family, separated clearly, with horizontal recessed pulls and one tiny muted role-color label tab on the upper drawer. No words, glyphs, people, desk, caster, outer 3D silhouette, top plane, background scene or transparent margin. Favor 2-native-pixel meaningful separations and pull thickness; a subtle 3×2 tab can carry restrained Cerulean or Indigo. Avoid tiny screws as the sole identity feature. Upper-left light is fixed screen-space. Native acceptance requires two drawers to remain distinct at 1×, not merely at source resolution.

North rear and both side panels reuse the existing charcoal powdercoat source with independently specified code-native seams/fasteners. They are **reused material + new geometry**, not three new generated images. East and West draw the front-edge seam on opposite sides while keeping the highlight on screen upper-left. They must not reuse the South handles as if drawers opened sideways through both walls.

## Registered layer and validation plan

Use six complete 96×144 layers with the same origin, in order: `CasterRear`, `CasterFront`, `Carcass`, `Top`, `NearFace`, `FaceInsert`. Both caster assemblies are drawn before the solid body so the carcass naturally covers their upper forks. Retain all source pixels and verify that their ordered union equals the whole native export. Solid furniture stays at its floor-pivot depth; standing/walking actors retain their physical-foot depth. No seated pose, actor body split or runtime scale is introduced.

Headless checks cover every exact floor/top/face/socket rectangle, one-cell occupancy, opposite gaze, visitor clearance, no stretched/mirrored raster, binary alpha and common canvas, insert-only changes, source hashes, and round-trip PNG reconstruction. An isolated actual GameMain room will show all four views, actor scale and path vicinity, protected near-wall/corner geometry, and no new worker/action or registry leakage. Any absent canonical production family support remains a separate explicit limitation; this prototype does not broaden the framework silently.
