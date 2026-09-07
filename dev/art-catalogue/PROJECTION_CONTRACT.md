# Fixed-camera furniture projection contract

Read-only review started at 2026-09-04 06:01:13 UTC, against the in-progress overnight source tree based on `9d25e25`. This is a geometric model and integration review, **not four-direction art approval**. This reviewer changed only this document; the runtime owner addressed the padding finding in parallel, as recorded below. The hard stop remains 2026-09-04 17:43:14 UTC.

## Decision

Use a fixed, screen-aligned 2D floor projection. A floor cell is 32×32 pixels in both axes; vertical height shifts image pixels **up screen**, regardless of furniture facing. Rotate the floor geometry and redraw the furniture; never rotate the rendered image, its height vector or its baked lighting.

The calibrated desk fits that model. A 3×1 north/south footprint has a nominal 96×32 top plane plus approximately 32px of vertical rise. Turn its **floor footprint** east/west and the top becomes 32×96, still with the same upward 32px height projection. Its whole silhouette is approximately 32×128—not a sideways 64×96 rotation of the north/south sprite.

This is a chosen, testable game-space projection, not a recovered camera angle or claim that every existing prop already follows it. If the studio later chooses compressed floor depth, that requires a coordinated floor/prop model change; it must not happen silently in one east-facing asset.

## Evidence and what was actually measured

- [Current normalized south candidate](../../game/tests/fixtures/furniture-calibration/desk-south-v2.png): PNG canvas **192×224**, alpha bounding box **96×66 at (48,110)**; measured with ImageMagick metadata and visually inspected as an existing local image.
- [Calibration fixture notes](../../game/tests/fixtures/furniture-calibration/README.md) and [deterministic export script](../tools/build_directional_calibration.sh): width normalized to 96px, contact boundary at y176, pivot at (96,160), alpha threshold and point resampling; source master preserved.
- [Current calibration manifest](../../game/tests/output/furniture-calibration/manifest.json): explicitly `native_review_only_not_runtime_approved`, south only, seated occlusion untested.
- [East-generation brief](prompts/calibration-desk-east-v1.md): requests a real fixed-camera 1×3-cell view, approximately 32×128 visible geometry.
- [Proposed catalogue](furniture.json): `desk` has a 192×224 padded envelope and pivot (96,160), with 3×1 versus 1×3 occupied masks.
- [Runtime direction resolver](../../game/world/office_layout.gd:196), [actor transform](../../game/actors/employee_avatar.gd:134), and [calibration actor helper](../../game/tools/capture_furniture_calibration.gd:39) were read, not executed or changed by this review.

The source desk top appears about 29px deep inside its rim, with approximately 32px of leg/apron rise. Those are raster observations, not subpixel physical measurements. The complete 66px alpha height is two pixels taller than the idealized 64px model; this may be rim/outline/export registration, and does not by itself prove wrong perspective. The 128×112 legacy workstation cell and the new 192×224 padded candidate are different storage envelopes; neither defines physical desk size by itself.

## Five separate quantities

| Quantity | Meaning | Desk example |
| --- | --- | --- |
| Floor footprint | Solid occupied ground cells, before height projection | N/S: 3×1 cells; E/W: 1×3 cells |
| Floor/sort pivot | Stable local reference mapped to a world grid-cell center | Canvas (96,160), local floor (0,0); **not** lowest opaque pixel |
| Top-plane elevation | Image-space upward translation from ground to tabletop | Nominal 32px; it stays vertical in screen space |
| Opaque visual bounds | Actual union of visible furniture pixels/approved obstruction region | Current S: (48,110,96,66); ideal E/W: (80,80,32,128) |
| Export canvas | Transparent registration space shared by all layers/views | 192×224; extra space is not collision or artwork |

Use half-open rectangle edges throughout: an extent ending at y176 contains a last possible pixel row of 175. Thus “contact bottom +16” means the floor boundary at pivot 160+16=176, not a demand to place an opaque pixel on row 176. The current candidate's last opaque row is 175.

For a local occupied-cell set `M`, cell size `s=32`, pivot `A=(ax,ay)`, and nominal elevation `h`:

```text
floor x edges = ax + min/max(M.x)*s ± s/2
floor y edges = ay + min/max(M.y)*s ± s/2
top plane     = floor rectangle translated by (0, -h)
opaque box    ⊆ union(top plane, visible supports down to floor contacts)
```

The actual alpha may occupy less than this conservative box. Feet, knobs, leaves and lamp arms may also require explicit authored overhangs; they must not be hidden by changing the logical cell mask or clipping the image to it.

## Desk coordinates under the nominal 32px elevation

These coordinates are a model to draw and inspect against—not approved images of missing facings.

| Facing group | Occupied floor edges | Top plane | Support/contact range | Nominal full bounds |
| --- | --- | --- | --- | --- |
| North/south | x48..144, y144..176 | x48..144, y112..144 | legs extend down to y176; near support rise y144..176 | (48,112,96,64) |
| East/west | x80..112, y112..208 | x80..112, y80..176 | supports extend vertically down to their floor feet, at most y208 | (80,80,32,128) |

N/S contact boundary is pivot+16. E/W has three occupied y-cells centered at 128,160,192, so its south contact boundary is pivot+48=208. Using +16 for all four directions would lift or clip the east/west legs by 32px. Conversely, aligning every image's bottom to the pivot would make both groups float.

The current measured south bounds (48,110,96,66) fit the same canvas, with top shifted 2px above the ideal model and the same contact boundary. Its correct full-canvas Sprite2D offset is `canvas/2 − floor_anchor = (0,-48)`. The actual base must not be enlarged to fill 192×224.

## Seating and draw order

Facing is the employee's gaze. The simple desk's candidate work cells are:

| Facing | Gaze | Logical work cell relative to desk pivot | Screen feet before a pose-specific visual offset |
| --- | --- | --- | --- |
| North | (0,-1) | (0,1) | (96,192) |
| East | (1,0) | (-1,0) | (64,160) |
| South | (0,1) | (0,-1) | (96,128) |
| West | (-1,0) | (1,0) | (128,160) |

These are floor destinations, not sufficient seat-art coordinates. Preserve the navigable/reserved work cell and apply only a reviewed `seat_anchor` to the rendered pose. Never shift navigation/collision to make an uncalibrated seated bitmap appear to fit.

Important practical constraints:

- A 48px-wide actor next to a 32px-wide east/west desk is not automatically an error. Its full frame extends 24px on each side of the logical feet; a worker 16px from the table edge can overlap that edge by 8px in image space. Forearms may overlap intentionally; head/torso clipping may not. Only actual directional poses establish the correct hand and torso socket.
- Production employees currently center a 48×80 frame at local `(0,-32)`, so the frame rectangle runs from feet−72 to feet+8, **not** feet−80 to feet. Visible boot pixels, not the canvas bottom, are the final reference.
- The calibration helper now uses production's `foot+(0,-32)` transform for its centered 48×80 frame: frame top is feet−72 and frame bottom is feet+8. This corrects the earlier eight-pixel discrepancy from using−40. Matching that transform makes the stand-in scale comparison meaningful, but still does not establish an actual directional seated pose or a reviewed seat socket.
- `seat_z_offset` is relative to the furniture's ground pivot, not a replacement height offset. N/S logical work-cell y naturally differs by±32; E/W is at the pivot y. Copying a south seat depth of−32 into east/west causes incorrect ordering. Actual layer and actor depth must be authored and tested per view.
- Separate rear structure, chair back, body, hands/top-edge interactions and near structure. A single global z-order cannot be assumed to solve every shape. East/west near legs reach +48 in ground depth; do not blindly reuse south's +16 contact interpretation.
- The runtime still requires actual pose capabilities before exposing new desk/research facings. The new geometry does not make missing north/east/west seated art available.
- A separately authored chair is reusable **art**, but naively placing it as another blocking 1×1 object on the desk work cell is incompatible with today's placement rules: `work_cell_blocked` will reject it. Use a workstation visual assembly with a walkable/reserved seat socket, or design and test explicit seat-occupancy semantics later. Do not turn off collision globally to evade this constraint.

## Runtime validator review: source canvas is not obstruction

The new resolver correctly requires explicit directional geometry, art and pose review; rejects missing resources and raster scale/rotation/flip fields; verifies integer regions/offsets; and keeps unsupported directions unavailable. The legacy south profile remains separate.

The review identified a concrete padded-art integration defect in [OfficeLayout's layer validation](../../game/world/office_layout.gd:246). Before the runtime owner's parallel correction:

1. It computed each destination rectangle from the complete declared layer region.
2. It required `visual_bounds` to equal the union of those destination rectangles.
3. Placement validation used those bounds to reject art/wall overlaps.

Declaring the full 192×224 canvas therefore forced bounds `[-96,-160,192,224]` relative to the pivot—even though the south desk actually draws only `[-48,-50,96,66]`. Transparent padding could reject valid neighbors and near-wall placements, and a default hit rectangle could accept clicks on empty air.

**Current code disposition:** the runtime owner has now implemented separately measured/protected content bounds. I reread the changed source:

- Full source regions and their registered origins remain intact; no independent rear/front trimming is needed.
- `measured_layer_ink_bounds()` measures every nonzero-alpha pixel inside the selected source region, in region-local coordinates.
- Optional `layer.content_bounds` is a region-local integer rectangle. It may conservatively exceed the alpha bounds inside the region, but must enclose every painted pixel and may not extend outside the region.
- Explicit profile `visual_bounds` now equals the world-local union of measured/protected content, not transparent canvas padding. Hit bounds remain inside those visual bounds.
- Legacy flat south definitions retain their prior full-frame visual bounds; existing placement is not silently migrated.

The owner reports 429 passing direction checks, including the real unapproved 192×224 calibration source, its 96×66 alpha extent, conservative protection and rejected undersized/out-of-region protection. This reviewer inspected the source/test cases, but did not rerun Godot. That validation proves alpha-bound handling, not the desk's final aesthetics or pose readiness.

For reference, an alternative compatible rendering representation would have used one common region `[48,110,96,66]` across every layer with `offset = region.position + region.size/2 − floor_anchor = [0,-17]`; that also preserves the source pivot. It is unnecessary with the new measured-content path. Never trim layers independently or use smaller declared content bounds to conceal real painted overlap.

The catalogue validator checks file existence, header dimensions, masks, anchors and declared review gates. It does not measure alpha or infer that a raw source has the right projection. Likewise, runtime placement checks cannot establish a correct desk perspective from a valid rectangle.

## Whole-catalogue envelope check

I evaluated all 30 base families using their explicit four-direction masks and `estimated_max_rise_above_occupied_floor_px`: floor-cell bounding rectangle plus the recorded upward rise, measured against each declared canvas and pivot. **No base envelope is mathematically too small under those recorded assumptions.** Every base retains at least 16px of padding; several retain 32px. No catalogue dimensions were edited.

The rise column is a conservative maximum, **not a drawing instruction**. In particular the desk's stored 96px maximum is not its calibrated 32px tabletop height. Forcing artists to make a 96px-tall desk would triple the intended physical rise even though it still fits the padded canvas.

Margins below are the smallest left/top/right/bottom margin across all four directions, in pixels.

| Base family | Canvas | Floor pivot | Recorded max rise | Minimum L / T / R / B | Result |
| --- | --- | --- | ---: | --- | --- |
| `desk` | 192×224 | 96, 160 | 96 | 48 / 16 / 48 / 16 | Fits |
| `coffee_station` | 192×256 | 96, 192 | 128 | 48 / 16 / 48 / 16 | Fits |
| `collaboration_cluster` | 256×272 | 128, 176 | 80 | 48 / 16 / 48 / 16 | Fits |
| `artifact_archive` | 192×288 | 96, 224 | 160 | 48 / 16 / 48 / 16 | Fits |
| `research_table` | 192×288 | 96, 208 | 128 | 48 / 32 / 48 / 32 | Fits |
| `approval_console` | 192×288 | 96, 208 | 128 | 48 / 32 / 48 / 32 | Fits |
| `prototype_bench` | 192×320 | 96, 240 | 160 | 48 / 32 / 48 / 32 | Fits |
| `compact_desk` | 160×192 | 80, 128 | 64 | 32 / 16 / 32 / 16 | Fits |
| `shared_workbench` | 256×304 | 128, 208 | 112 | 48 / 16 / 48 / 16 | Fits |
| `ergonomic_chair` | 96×160 | 48, 112 | 64 | 32 / 32 / 32 / 32 | Fits |
| `visitor_chair` | 96×144 | 48, 96 | 48 | 32 / 32 / 32 / 32 | Fits |
| `two_seat_sofa` | 192×224 | 96, 144 | 64 | 48 / 32 / 48 / 32 | Fits |
| `lounge_armchair` | 160×208 | 80, 128 | 48 | 32 / 32 / 32 / 32 | Fits |
| `low_coffee_table` | 160×160 | 80, 96 | 32 | 32 / 16 / 32 / 16 | Fits |
| `round_meeting_table` | 224×288 | 112, 176 | 64 | 32 / 32 / 32 / 32 | Fits |
| `mobile_whiteboard` | 192×320 | 96, 256 | 192 | 48 / 16 / 48 / 16 | Fits |
| `rolling_storage_pedestal` | 96×144 | 48, 96 | 48 | 32 / 32 / 32 / 32 | Fits |
| `low_bookshelf` | 192×224 | 96, 160 | 96 | 48 / 16 / 48 / 16 | Fits |
| `tall_storage_cabinet` | 160×288 | 80, 224 | 160 | 32 / 16 / 32 / 16 | Fits |
| `acoustic_divider` | 192×288 | 96, 224 | 160 | 48 / 16 / 48 / 16 | Fits |
| `broadleaf_planter` | 128×224 | 64, 176 | 128 | 48 / 32 / 48 / 32 | Fits |
| `task_floor_lamp` | 128×256 | 64, 208 | 160 | 48 / 32 / 48 / 32 | Fits |
| `water_station` | 160×240 | 80, 176 | 112 | 32 / 16 / 32 / 16 | Fits |
| `coat_bag_stand` | 128×256 | 64, 208 | 160 | 48 / 32 / 48 / 32 | Fits |
| `printer_scanner_station` | 160×208 | 80, 144 | 80 | 32 / 16 / 32 / 16 | Fits |
| `recycling_sorter` | 160×176 | 80, 112 | 48 | 32 / 16 / 32 / 16 | Fits |
| `server_cabinet` | 160×288 | 80, 224 | 160 | 32 / 16 / 32 / 16 | Fits |
| `phone_booth` | 256×416 | 128, 304 | 192 | 48 / 32 / 48 / 32 | Fits |
| `cafe_table` | 160×240 | 80, 160 | 80 | 32 / 32 / 32 / 32 | Fits |
| `resource_cart` | 160×208 | 80, 144 | 80 | 32 / 16 / 32 / 16 | Fits |

The 12 decor kits have matching primary-host canvas and floor anchor and zero extra collision, but their rise/actual bounds are not measured. They cannot receive an opaque-fit verdict yet. The computer, desk lamp, growth display and tall specialist tools especially need a combined-host silhouette check; “host-compatible canvas” does not guarantee readable placement or no off-canvas tool pixels.

Other limits to record before generation:

- For multi-row/even-sized masks, the pivot may be the center of the chosen reference cell rather than the center of the whole footprint. Example: the north 3×2 mask has rows −1 and 0, so its box center is 16px north of the pivot; east moves that offset to the right. Do not independently recenter each drawing after rotating the mask.
- Plants, lamps, boards, chairs and cabinets are not literal extrusions of their collision rectangles. Their real silhouettes can overhang the floor mask; the current numeric pass does not bound ungenerated leaves, shades, backs or handles.
- A tall padded envelope fitting on disk says nothing about room fit, reachable seats or clean world-label placement. Large phone booths/boards and tall cabinets still need wall/corner/neighbor tests in the actual room.
- “No failing envelopes found” must not be reported as 42 completed art families or four-direction runtime acceptance.

## Required next evidence, without changing scope

1. Review N/E/S/W redraws together beside a real employee using the exact production transform; reject mirrored lighting and raster rotations.
2. Mark floor pivot, all cell edges, top plane, true ground contacts and alpha/content bounds on a developer-only comparison.
3. Add the separate chair and real supported directional poses; demonstrate arrival, idle/seated, typing and exit without foot hopping or torso clipping.
4. Use common layer registration and correct per-direction render crop/depth; prove wall/neighbor tests operate on meaningful content, not transparent padding.
5. Capture and record the native room result before setting any new runtime-facing review flags. The present south calibration remains unapproved.
