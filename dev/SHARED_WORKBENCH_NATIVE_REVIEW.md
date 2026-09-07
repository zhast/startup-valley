# Shared workbench native candidate review

Date: 2026-09-04

Candidate revision: `shared-workbench-v1`

Catalogue family: existing `shared_workbench` (registered cleanup-required after the bounded build)

Verdict: **cleanup-required dev-catalogue candidate only — no approval, production, runtime, or default-layout binding**

## What this candidate proves

`shared-workbench-v1` is a deterministic code-native base with independently
declared North, East, South, and West screen-space geometry. Every facing uses a
256×304 RGBA canvas, floor pivot `[128,208]`, centered-sprite offset `[0,-56]`,
nearest sampling, integer placement, and no finished-bitmap rotation, mirroring,
scaling, text, or logo.

The candidate exports only these reusable base layers:

- `floor_shadow`
- `rear_structure`
- `front_structure`

It deliberately contains no chair, device, role tool, actor, or job-state pixels.
Its two chair cells and four surface zones are proposal sockets owned by
`ergonomic_chair`, `computer_kit`, and `role_tool_kits`; they do not add base
collision. The long oak-and-charcoal base has two independently addressable bays
and a centered structural cable well. It is visibly and geometrically distinct
from the short two-cell compact desk and the tall, equipment-heavy prototype and
research benches.

## Geometry

| Facing | Footprint | Occupied offsets | Proposed bay work cells | Clear approach cells | Primary interaction proposal | Look vector |
|---|---:|---|---|---|---|---|
| North | 5×1 | `[-2,0] [-1,0] [0,0] [1,0] [2,0]` | `[-1,1] [1,1]` | `[-1,1] [0,1] [1,1]` | `[0,1]` | `[0,-1]` |
| East | 1×5 | `[0,-2] [0,-1] [0,0] [0,1] [0,2]` | `[-1,-1] [-1,1]` | `[-1,-1] [-1,0] [-1,1]` | `[-1,0]` | `[1,0]` |
| South | 5×1 | `[2,0] [1,0] [0,0] [-1,0] [-2,0]` | `[1,-1] [-1,-1]` | `[1,-1] [0,-1] [-1,-1]` | `[0,-1]` | `[0,1]` |
| West | 1×5 | `[0,2] [0,1] [0,0] [0,-1] [0,-2]` | `[1,1] [1,-1]` | `[1,1] [1,0] [1,-1]` | `[1,0]` | `[-1,0]` |

The North/South top is 154×32 pixels and the East/West top is 28×154 pixels.
All facings occupy exactly five 32×32 grid cells. The two bay work cells remain
walkable and the center approach cell is outside base collision. These are
geometry proposals only; the passive candidate exposes no interaction or work
action.

## Actual GameMain/TownRoom evidence

The native harness instantiated the real `GameMain` and production `TownRoom` at
1280×720 with the worker disabled. It copied the production room model in memory
and admitted an owner-scoped passive candidate without writing production data.

- Common four-facing safe pivot: grid `[12,14]`.
- Each view created exactly five 32×32 `CollisionShape2D` cells and three native
  render sprites using the exported floor/rear/front layers.
- Every declared occupied cell became non-walkable in the real navigation graph.
- Alpha-aware `TownRoom.surface_at` and `VisibleSurface.top` found a genuinely
  visible pixel owned by every layer in every facing.
- Every visible hit remained passive: no interaction, job, workstation, or
  service action was synthesized.
- Grid `[1,3]` touches two wall axes. Every facing was rejected there with real
  wall/visual/headroom/clearance issue codes, and the failed placement transaction
  retained the previously committed prop.
- Both proposed bay cells had real navigation routes. From `[17,18]`, the founder
  also followed an 8–10-point route to the center approach cell, remained clear
  of all five collision cells, and traveled roughly 248–315 pixels depending on
  facing.
- The founder is only a standing scale, route, contact, and occlusion probe. This
  is not evidence for two actors, chair fit, reservation, seated pose, work
  animation, or entry/exit lifecycle.

Evidence:

- Isolated native sheet: `game/tests/output/shared-workbench/candidate-contact-sheet-native.png`
- Isolated 4× inspection: `game/tests/output/shared-workbench/candidate-contact-sheet-4x.png`
- Direct compact/workbench/prototype comparison: `game/tests/output/shared-workbench/compact-workbench-prototype-native.png`
- Base-only actual-room sheet: `game/tests/output/shared-workbench/actual-room-base-contact-sheet-native.png`
- Founder approach sheet: `game/tests/output/shared-workbench/actual-room-approach-contact-sheet-native.png`
- Nearest-neighbor approach inspection: `game/tests/output/shared-workbench/actual-room-approach-contact-sheet-4x.png`
- Per-facing 1280×720 frames: `game/tests/output/shared-workbench/room-{north,east,south,west}.png`
- Machine-readable manifest/results: `game/tests/fixtures/furniture-calibration/shared-workbench-v1/manifest.json`, `game/tests/output/shared-workbench/structural-results.json`, and `game/tests/output/shared-workbench/actual-room-results.json`

## Honest visual score

| Gate | Score / 3 | Review note |
|---|---:|---|
| Pixel coherence | 2 | Crisp integer oak/charcoal pixels, clean binary alpha, and zero hidden RGB; the ordered-dither shadow and sparse empty top still need art-direction review. |
| Perspective | 2 | The horizontal views read as a broad shared surface and the vertical views preserve the authored footprint; the very narrow side elevations remain visually austere. |
| Silhouette readability | 2 | Five-cell length, three supports, two bays, and the center cable well separate it from compact and machine benches, but the empty base has limited role identity. |
| Layering and anchors | 3 | Three exposed layers, byte-exact reconstruction, a common pivot, exact collision centers, and real alpha-aware surface picking all pass. |
| Direction consistency | 2 | Materials, light, bay order, and structural grammar persist across four unique non-mirrored declarations; opposing views remain deliberately subtle. |
| Placement | 2 | Real room placement, wall/corner rejection, both bay routes, and founder approach pass; paired attachments and multi-actor lifecycle do not. |

Mean: **2.17 / 3**. The exact exports and evidence are registered as a
cleanup-required candidate, not advanced to native review, approval, production,
or runtime integration.

## Reproducible checks

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/export_shared_workbench.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_shared_workbench.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_shared_workbench.gd
```

Final focused results at review time:

- Export: 51 checks, 0 failures.
- Structural/asset/admission gate: 292 checks, 0 failures.
- Actual GameMain/TownRoom gate: 462 checks, 0 failures.

The exporter and capture hash-check `game/data/furniture_catalog.json`,
`game/data/office_layout.json`, and `dev/art-catalogue/furniture.json` before and
after their work. The later bounded registration changes only the dev catalogue
and its generated/current-truth documents. No runtime asset, production/default
layout, worker, contract, save, interaction, or gameplay code is changed.

## Remaining promotion gates

1. Fit and review two compatible `ergonomic_chair` assemblies in every facing,
   including collision ownership, hand/seat contact, and enter/exit paths.
2. Fit two device and two role-tool overlays inside the declared surface zones;
   verify rear/front occlusion and that no surface pixels float or clip.
3. Exercise two-actor reservation, simultaneous approach, seated/typing/work,
   cancellation, and departure lifecycle in actual `GameMain`.
4. Review the sparse top treatment, dithered shadow, and narrow side silhouettes
   against final art direction.
5. Only after those gates, consider advancing the exact registered cleanup
   candidate. Any production family or default-layout proposal remains a
   separate decision.
