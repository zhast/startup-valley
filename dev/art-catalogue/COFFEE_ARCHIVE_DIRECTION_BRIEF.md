# Coffee station and archive: directional production brief

Read-only audit, 2026-09-04 07:43 UTC. Production baseline `9d25e25` plus the current uncommitted directional foundation. **No generation, production changes or new-facing approval in this audit.** The proposed dimensions below are a calibration design, not measurements of accepted replacements.

## Decision

Keep both existing south assets playable. Reuse their identity/material references, the placement/navigation system, and independent ambient loops. Build exact, modular cabinet/counter volumes before commissioning missing tool and cabinet views. Do not shrink or rotate the complete current pictures to fill four slots: their surface depths and physical footprints do not agree.

The archive is currently a functioning Studio destination. Coffee is currently decorative despite a reserved service cell; its missing click behavior is a code/product decision, not an art-generation requirement.

## Native evidence and actual runtime binding

Inspected both full [two-hire](../../game/tests/output/ui-material-audit-after/office-hires-2.png) and [four-hire](../../game/tests/output/ui-material-audit-after/office-hires-4.png) 1280×720 captures, the original masters, both native PNGs and four-frame ambient strips. No wall overlap is visible in those two compositions. Neither screenshot proves moving-actor clearance or new directional correctness.

| Measurement | Coffee station | Artifact archive |
| --- | --- | --- |
| Active PNG | [coffee-station.png](../../game/assets/runtime/office/coffee-station.png) | [artifact-archive.png](../../game/assets/runtime/office/artifact-archive.png) |
| Retained master | [coffee-station-master.png](../../game/assets/source/office-masters/coffee-station-master.png) | [artifact-archive-master.png](../../game/assets/source/office-masters/artifact-archive-master.png) |
| Source canvas / format | 1536×1024 RGBA; binary alpha | 1536×1024 RGBA; binary alpha |
| Native canvas; actual ink rectangle `[x,y,w,h]` | 142×94; `[11,4,120,90]` | 136×90; `[2,4,132,86]` |
| Actual alpha | 9,003 opaque / 4,345 transparent / 0 partial pixels | 10,993 opaque / 1,247 transparent / 0 partial pixels |
| Native sampling | Scale 1, nearest; 64 RGBA colors, no mipmaps | Same |
| Scene sprite offset / canonical layer | `(0,-45)` / one `PropSprite`, relative depth 0 | `(0,-43)` / one `PropSprite`, relative depth 0 |
| Local declared bounds | `[-71,-92,142,94]` | `[-68,-88,136,90]` |
| Actual local ink bounds | `[-60,-88,120,90]` | `[-66,-84,132,86]` |
| Current pivot / grid | `(144,208)` / `[4,6]` | `(144,432)` / `[4,13]` |
| Actual on-screen ink | `[84,120,120,90]` | `[78,348,132,86]` |
| Occupied cells / physical rectangle | Three cells `[-1,0],[0,0],[1,0]`; local `[-48,-16,96,32]` | Same |
| Clearance / service cell | Southern row `[-1,1],[0,1],[1,1]`; service `[0,1]` → `(144,240)` | Same; service world `(144,464)` |
| Work cell | Not declared; resolver falls back to the service cell. No seated station. | Same |
| Existing overlay | Ambient row 0, offset `(20,-66)`, four 32×32 frames at 5 FPS | Ambient row 4, offset `(0,-56)`, same frame contract |
| Availability | Legacy `south` only, unlock at one hire | Same |

The two masters retain magenta RGB beneath **zero alpha**; this is not an opaque checkerboard or proof of failed transparency. Native exports have zero RGB beneath transparent pixels. Both PNG imports use lossless compression and `fix_alpha_border=true`; a future byte-exact layer extraction must test the imported buffer rather than assume the importer preserves invisible RGB.

Runtime sources: [catalogue](../../game/data/furniture_catalog.json), lines 20–32 / 48–60; [layout](../../game/data/office_layout.json), lines 26 / 28; [coffee scene](../../game/props/coffee_station.tscn), lines 9–14; [archive scene](../../game/props/artifact_archive.tscn), lines 9–14. The small collision rectangles in those scenes are **not** the active collision: [TownRoom](../../game/world/town_room.gd), lines 149, 202–213, sets `catalog_collision` and creates one 32×32 collision shape per occupied cell. [OfficeLayout](../../game/world/office_layout.gd), lines 190–205 / 375–404, supplies cell-center anchors, canonical whole-texture layers and fallback work/hit bounds.

## Confirmed gaps and disposition

| Priority / evidence | Finding | Remedy |
| --- | --- | --- |
| P0 foundation; catalogue variants | Shared-prop `south` is already ambiguous. Current visible service front points **south**, so the player stands south and looks **north**. The dev catalogue's proposed south instead means **actor gaze south**, puts the service cell north, yet tags that slot as the legacy south art. Coffee variant evidence: `furniture.json:601–632`; archive repeats the pattern. | Preserve legacy label/behavior. Add explicit `service_side` and separate `approach_gaze` for new shared-prop recipes. Correct the future planning mapping, not the old save/placement meaning. Root and integration owner have been notified. |
| P1 geometry; coffee room `(84–204,120–210)` | Visible width is 120 vs 96 physical pixels; the feet, not only the top, extend outside the occupied width. Counter surface runs approximately native `y31–56` (26px depth); near highlight is exactly row56, front apron begins57, lowest ink is93. This is not the demonstrated 32px top-depth / 32px rise calibration. | Rebuild the counter volume with exact floor/top rectangles. Reuse wood/material identity; keep a 32px elevation independent of footprint depth. Do not claim that adding canvas padding corrects perspective. |
| P1 geometry; archive room `(78–210,348–434)` | Cabinet ink is 132px wide over a 96px footprint. Roof depth is approximately native rows4–11 (8px); the tall front dominates. This is a much shallower roof than a 32px-deep physical box. | Rebuild a 96×32-footprint cabinet with an explicit 64px vertical rise and a 32px roof depth. Simplify front contents to fit its new native panel, rather than uniformly reducing the current tiny display gadgets. |
| P1 grounding; both native sprites | Lowest ink ends at local `y+2` exclusive, while the physical floor footprint ends at `y+16`. The old bottom-aligned export does not document a 14px difference between visual ground contact and footprint front. Width overhang plus that offset is a placement/collision risk; no moving-actor failure is claimed from the stills. | Give the replacement a fixed **floor-center pivot** and explicit near-floor contact `+16` N/S or `+48` E/W. Measure contact separately from sprite bounds, furniture height and shadow. Recheck routes/corners before integration. |
| P2 cleanup; [coffee 4×](../../game/tests/output/coffee-archive-audit/coffee-native-4x.png) | 13 purple matte-edge pixels remain in the native coffee image. Examples: `(78,5)=(152,13,158)`, `(21,92)=(152,13,158)`, `(20,93)=(117,10,142)`. All are connected to the main silhouette, not detached islands. Archive has no matching purple pixels. | Targeted matte-edge normalization with native before/after proof; **not** a reason to regenerate the whole coffee station. No cleanup was performed here. |
| P1 functional distinction; `town_room.gd:230–239`, `main.gd:605–607` | Only desks/archive/approval are world hit targets. Archive routes to Studio; coffee does not route anywhere, although metadata says `interaction_kind: coffee`. | Preserve current behavior in the art pass. If coffee later gets an interaction, explicitly specify a break/coffee action and feedback; do not create AI work or claim it exists because a cell is reserved. |
| P1 modularity / motion | Both bases, decor, appliance contacts and baked object shadows are fused. There are no registered structure/tool/shadow layers. Separate ambient loops already exist, but their legacy scene offsets are not portable to other service sides. Archive's loop is a moving document, not a progress meter. | Reuse small steam/document effects after socket review. Split new bases, tool objects and ambient attachments; keep activity decorative or drive it from existing real state. Do not regenerate whole props just to animate steam or claim new work occurred. |

The body images are relatively frontal and have no large diamond-isometric yaw. The actionable mismatch is **top-plane depth, grounding and relative dimensions**, not a need to invent a different numeric camera angle. Existing conservative visual-wall checks remain useful and explain why the shown room does not overlap its walls despite oversized props.

## Fixed-camera replacement contract — proposal only

Keep screen X/Y as floor axes, 32px cells, upper-left light, native 48×80 actors, integer pivots and scale 1. Floor plane axes never rotate with the view. The following directions name the **service side**, not employee gaze:

| Service side | Physical floor `[x,y,w,h]` | Service cell / approach gaze | Reserved service row |
| --- | --- | --- | --- |
| North | `[-48,-16,96,32]` | `[0,-1]` / south | `[-1,-1],[0,-1],[1,-1]` |
| East | `[-16,-48,32,96]` | `[1,0]` / west | `[1,-1],[1,0],[1,1]` |
| South — legacy visible-front equivalent | `[-48,-16,96,32]` | `[0,1]` / north | `[-1,1],[0,1],[1,1]` |
| West | `[-16,-48,32,96]` | `[-1,0]` / east | `[-1,-1],[-1,0],[-1,1]` |

Counter surface = floor rectangle translated `(0,-32)`. Archive roof = floor rectangle translated `(0,-64)`. Thus N/S counter top is 96×32 at `(-48,-48)`, archive roof 96×32 at `(-48,-80)`; E/W counter top is 32×96 at `(-16,-80)`, archive roof 32×96 at `(-16,-112)`. These are separate physical depth and elevation measurements, not squeezed silhouettes.

Retain the planned padded envelopes: coffee **192×256, floor pivot `(96,192)`**; archive **192×288, floor pivot `(96,224)`**. Every layer shares its family canvas and pivot. N/S near floor contacts are canvas y208 / y240; E/W are y240 / y272. The archive therefore occupies more screen height in E/W without changing its physical height. Actual measured ink supplies `visual_bounds`; blank canvas padding must not become collision or a giant hit region.

Service-side visibility must be honest: south shows controls/doors; north shows the true rear; east/west show the appropriate narrow appliance profile and long roof. Do not yaw a cabinet to expose its doors, rotate front-panel pixels onto a vertical side, or mirror handles/asymmetric devices and their lighting. In this projection some service details will be edge-on or hidden. A hover/interaction cue can identify the destination without falsifying its volume.

### Modular reuse versus new drawings

- **Reuse geometry infrastructure, not unapproved finished furniture:** the explicit plane/rise approach in [modular_desk_geometry.gd](../../game/tools/modular_desk_geometry.gd) is suitable for a new counter/cabinet helper. Do not copy its chair/seat metadata or treat its prototype bar legs as finished cabinetry. Solid cabinet panels/plinths need their own construction.
- **Reuse generated material:** the staged [horizontal](../../game/tests/fixtures/furniture-calibration/materials/oak-horizontal-v1-soft.png) and [vertical](../../game/tests/fixtures/furniture-calibration/materials/oak-vertical-v1-soft.png) 32×32 oak tiles can cover exact geometry without moving floor axes. Their source identity/palette is usable; these remain dev candidates, not a broad production material approval.
- **Coffee:** separate `CounterBody`, front cup-cubby/door insert, machine, grinder, mug and plant; add small contact shadows and independent steam. Current machines/cups/plant are visual references, **not already-clean detachable sprites**: the counter and object-contact shadows occupy the same pixels. A silhouette mask could recover visible pixels only; it cannot reveal the wood hidden behind them or invent a new rear/side. Generate missing N/E/W appliance views; use the south reference to establish a cleaner, less crowded matching set.
- **Archive:** separate opaque carcass/roof/plinth, service-front insert, optional two display objects and terminal/document overlay. Keep off-white lockers, charcoal frame, walnut base and restrained indigo/cerulean glass. Existing tiny drone/VR/printer/camera miniatures are too dense for a 96px-wide file destination; they can remain in the legacy asset or serve as references, not be shrunk into unreadable decorative noise. A simpler front insert is new art; rear/side structure can reuse exact geometry/material, with separately drawn directional details where visible.
- **Occlusion:** ground shadow below body; actual far structure, tools and near structure in explicit reviewed depths. No chair/seated layers for either family. Do not put a whole tall cabinet behind a service actor simply to keep the actor visible. Test walking around both ends and standing at every service side with the existing four-direction standing poses; future reaching/drinking poses remain separate missing work.

## First bounded generation prompts — not executed

Prepare and native-review the code-built base guides first. Use the built-in ImageGen workflow, retain raw sources, then mechanically crop/point-normalize/register. One asset sheet per call, genuine alpha, no runtime scaling; only semantic corrections need ImageGen. Start with visible-front **service south / approach gaze north**, not an ambiguously named “north-facing station.”

### 1. Coffee service-south detachable toolkit

References: existing coffee master for identity; native coffee PNG for pixel density; the exact counter guide and staged soft-oak material for compatibility. The whole coffee reference is not permission to include its table.

> Create one original Startup Valley pixel-art toolkit sheet, four separated objects in one row: compact espresso machine, grinder, one cream mug, small leafy plant. All appliance controls face the service side SOUTH/downscreen; a user stands below and looks NORTH. Fixed screen X/Y floor axes, no isometric yaw, no converging edges. Upper-left light stays fixed. Use charcoal/off-white metal, warm coffee/wood-compatible tones, tiny cerulean indicators and restrained chartreuse foliage; no brand names. Each object stands alone on genuine transparent alpha: no table, cabinet, chair, floor, room, person, baked ground shadow, steam, text, labels or checkerboard. Draw at a coherent native pixel scale and present at clean nearest-neighbor 4× enlargement of a 256×64 logical sheet: four 64×64 cells, floor-center pivot `(32,48)` inside each cell. Machine physical top/floor footprint 36×16 and vertical rise28, expected complete 36×44 silhouette; grinder footprint12×12 and rise24, silhouette12×36; mug footprint8×8 and rise6, silhouette8×14; plant footprint12×12 and rise16, silhouette12×28. Keep all feet/contact pixels and generous transparent gutters. These are overhead rectangular top planes plus front elevations, not tilted 3D product photographs. The machine is a compact member of the existing reference family, not a reduced picture of the entire coffee station.

Proposed host sockets, expressed as **top-surface footprint centers relative to the counter floor pivot**, then translated up32px: machine `(-26,-6)`, grinder `(3,-6)`, mug `(18,7)`, plant `(33,-6)`. Their proposed footprints fit inside the 96×32 surface without overlap. Verify actual generated dimensions/contact shadows before using those sockets; source output size and successful alpha do not certify them. Export each independently into the shared 192×256 family canvas after review.

### 2. Archive service-south front insert

References: existing archive master for material/identity; native archive PNG for scale; exact new 96×32/64-rise carcass guide. Generate only the insert so ImageGen cannot change its roof depth or floor anchor.

> Create one original Startup Valley pixel-art cabinet front insert on genuine transparent alpha, no surrounding cabinet. The insert is a flat FRONT ELEVATION facing service SOUTH/downscreen; it will sit inside a separately constructed 96px-wide,64px-high charcoal archive carcass. Target an88×56 native panel, shown as exact 4× nearest-neighbor pixels with transparent padding. Keep every horizontal seam horizontal and every door edge vertical. Arrange a restrained two-column/two-row set of off-white file lockers on the left, one small central charcoal terminal with a simple cream document symbol, and a single indigo-glass display bay on the right containing two readable document/project objects. Use walnut only as a small lower accent; upper-left light, dark pixel outlines, restrained cerulean highlights, one small vermilion control, minimal chartreuse status light. It should read as the shared home of completed company files, not a vending machine or six-miniature electronics shop. No readable text, numbers, progress graph, logos, room, roof, side wall, legs, floor shadow, person, glow, perspective skew or painted checkerboard. Preserve separated locker/terminal/display regions so optional document highlights can later be layered without replacing the cabinet.

Register the reviewed insert inside the service-south 96×64 front, e.g. local `(-44,-44)` with 4px top/bottom structure margins. The north rear is a separate plain-backed construction; east/west cannot reuse this front by rotation. Commission true appliance/profile details only after this first base-plus-insert reads correctly next to an actor.

## Acceptance and audit output

Before any new profile is exposed: show all four service sides beside the same 48×80 actor and exact floor grid; measure roof/counter planes, elevation, near-floor contact and silhouette independently; verify registered layer reconstruction, alpha, nearest/scale 1, wall and furniture clearance, service reachability and behind/in-front sorting. Inspect native and 4× stills plus approach/leave motion. Preserve legacy south until its replacement passes. Visual categories must each be at least 2/3 and average at least 2.5; a source generation or successful import is not approval.

This audit performed local read-only code/pixel inspection, not gameplay tests. Six mechanical evidence crops/enlargements are saved under [coffee-archive-audit](../../game/tests/output/coffee-archive-audit): native room crops preserve original 1280×720 pixels; two sprite and two ambient enlargements use nearest-neighbor 4× only. Useful individual references: [coffee room](../../game/tests/output/coffee-archive-audit/coffee-room-native.png), [archive room](../../game/tests/output/coffee-archive-audit/archive-room-native.png), [archive 4×](../../game/tests/output/coffee-archive-audit/archive-native-4x.png), [coffee steam](../../game/tests/output/coffee-archive-audit/coffee-steam-4x.png), [archive document loop](../../game/tests/output/coffee-archive-audit/archive-ambient-4x.png). No renderer, paid call, save, worker or production file was changed.
