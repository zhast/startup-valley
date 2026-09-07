# Compact desk native candidate review

Date: 2026-09-04\
Candidate revision: `compact-desk-v1`\
Catalogue family: existing `compact_desk` (registered as cleanup-required after this bounded review)\
Verdict: **cleanup-required native candidate only — no approval or production/default-layout binding**

## What this candidate proves

`compact-desk-v1` is a deterministic code-native base with independently declared North, East, South, and West screen-space geometry. Every facing uses a 160×192 RGBA canvas, floor pivot `[80,128]`, centered-sprite offset `[0,-32]`, nearest sampling, integer placement, and no raster rotation, mirroring, scaling, text, or logo.

The base exports only:

- `floor_shadow`
- `rear_structure`
- `front_structure`

Chair, device, and role equipment are not pixels in those layers. The manifest names their separate owners as `ergonomic_chair`, `computer_kit`, and `role_tool_kits`; each facing has a proposed chair cell and compact surface zones, but those are compatibility sockets rather than accepted attachments. The base adds exactly two collision cells regardless of optional overlays.

## Geometry

| Facing | Footprint | Occupied offsets | Proposed approach / future work cell | Look vector | Native top |
|---|---:|---|---|---|---|
| North | 2×1 | `[-1,0] [0,0]` | `[0,1]` | `[0,-1]` | `[-48,-48,64,30]` |
| East | 1×2 | `[0,-1] [0,0]` | `[-1,0]` | `[1,0]` | `[-16,-80,30,64]` |
| South | 2×1 | `[1,0] [0,0]` | `[0,-1]` | `[0,1]` | `[-16,-48,64,30]` |
| West | 1×2 | `[0,1] [0,0]` | `[1,0]` | `[-1,0]` | `[-14,-48,30,64]` |

The accepted shared workstation is 3×1/1×3 with a 96px-long top. This candidate is 2×1/1×2 with a 64px-long top. The direct anchor-aligned comparison is `game/tests/output/compact-desk/accepted-shared-vs-compact-native.png`; the reduction is geometry, not a scaled bitmap.

## Actual GameMain/TownRoom evidence

The native harness instantiated the real `GameMain` at 1280×720 with the worker disabled, copied the production room model in memory, and owner-scoped the unreviewed family through the passive calibration gate. It did not write production data.

- Common four-facing safe pivot: grid `[12,13]`.
- Each view created one neutral generic prop with three native sprites and exactly two 32×32 `CollisionShape2D` cells.
- Each declared occupied cell became non-walkable in the real navigation graph.
- Alpha-aware `TownRoom.surface_at` and `VisibleSurface.top` found a genuinely visible pixel owned by each floor/rear/front layer.
- Every painted hit remained passive: no interaction, employee, job, or service action was synthesized.
- Grid `[1,3]` is adjacent to two wall axes. Every facing was rejected there for real footprint, visual, viewpoint, and/or clearance reasons; the failed transaction preserved the committed prop.
- From `[17,18]`, the founder followed a real 9–11-point navigation route for each view, remained physically safe on every tick, and stopped exactly on the proposed clear approach cell outside both collision cells.
- The founder is a standing 48×80 scale/contact/occlusion probe only. This is not evidence for a compact chair socket or seated pose.

Evidence:

- Base-only actual-room sheet: `game/tests/output/compact-desk/actual-room-base-contact-sheet-native.png`
- Founder approach sheet: `game/tests/output/compact-desk/actual-room-approach-contact-sheet-native.png`
- Nearest-neighbor approach inspection: `game/tests/output/compact-desk/actual-room-approach-contact-sheet-4x.png`
- Per-facing 1280×720 frames: `game/tests/output/compact-desk/room-{north,east,south,west}.png`
- Machine-readable results: `game/tests/output/compact-desk/actual-room-results.json`

## Honest visual score

| Gate | Score / 3 | Review note |
|---|---:|---|
| Pixel coherence | 2 | Crisp integer oak/charcoal pixels and clean binary alpha; the narrow ordered-dither shadow is functional but still needs art-direction review. |
| Perspective | 2 | Matches the shared top-down/front-elevation grammar; side views remain deliberately simple and boxy. |
| Silhouette readability | 2 | Reads immediately as a small desk base, though empty surfaces depend on future independent overlays for role identity. |
| Layering and anchors | 3 | Three exposed layers, exact reconstruction, common pivot, exact collision centers, and actual alpha picking all pass. |
| Direction consistency | 2 | All views share material/light logic and remain byte-distinct/non-mirrored; opposite views are mostly edge/apron and pivot changes. |
| Placement | 2 | Four real room placements, wall/corner rejection, and founder approach pass; no chair, device, role, seated, transition, or production-layout acceptance exists. |

Mean: **2.17 / 3**. The exact exports are retained as `cleanup_required`, not
`native_review_required`, approved or runtime-integrated. The explicit blocker
is missing compatible compact chair/device/role overlays plus seated lifecycle
review.

## Reproducible checks

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_compact_desk.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_compact_desk.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_compact_desk.gd
```

Final focused results at review time:

- Export: 47 checks, 0 failures.
- Structural/asset/admission gate: 259 checks, 0 failures.
- Actual GameMain/TownRoom gate: 438 checks, 0 failures.

The harness hash-checks `game/data/furniture_catalog.json`, `game/data/office_layout.json`, and `dev/art-catalogue/furniture.json` before/after capture. No runtime asset, default layout, worker, contract, save, or shared catalogue/document was changed.

## Remaining promotion gates

1. Review a compact-specific chair fit and the actual seated/typing lifecycle for Mina and Theo; do not assume the accepted full-size workstation sockets transfer.
2. Review compact device and role overlays inside the declared surface zones, including hand contact, top-plane support, and rear/front occlusion.
3. Decide whether the dithered shadow and simplified side aprons meet final art direction.
4. Only after those gates, consider advancing the exact registered cleanup
   candidate to native review; any production family/default-layout proposal
   remains a separate decision.
