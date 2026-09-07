# Coffee station v1: production review

2026-09-04 20:12 UTC. **Accepted for four-direction production art and
geometry; deliberately noninteractive.** This promotion implements the
recommendation in the
[code-native candidate review](COFFEE_CODE_NATIVE_CANDIDATE_REVIEW.md). It does
not authorize a coffee action, worker job, persistence record, animation, UI,
sound, pouring, drinking, or consumption state.

## Decision

The reviewed `coffee-station-code-v1` N/E/S/W fixture is copied byte-for-byte
to `game/assets/runtime/office/coffee-station-v1/`. The runtime manifest locks
all 40 semantic layers and four whole-image reconstruction references by
SHA-256. Production registration uses the same **192×256** canvas, floor pivot
**(96,192)**, offset **(0,-64)**, native scale1, nearest filtering, per-side
layer order, exact occupied masks, approach clearance, service sockets, visual
bounds, and tighter non-shadow hit bounds. No layer is mirrored, rotated, or
scaled.

Directions name the service side, and approach gaze remains opposite:

| Service side | Occupied cells | Clear approach | Socket / gaze | Visual bounds | Hit bounds |
|---|---|---|---|---|---|
| North | `(-1,0),(0,0),(1,0)` | `(-1,-1),(0,-1),(1,-1)` | `(0,-1)` / South | `(-48,-68,96,88)` | `(-48,-68,96,84)` |
| East | `(0,-1),(0,0),(0,1)` | `(1,-1),(1,0),(1,1)` | `(1,0)` / West | `(-16,-90,32,142)` | `(-16,-90,32,138)` |
| South | `(-1,0),(0,0),(1,0)` | `(-1,1),(0,1),(1,1)` | `(0,1)` / North | `(-48,-73,96,93)` | `(-48,-73,96,89)` |
| West | `(0,-1),(0,0),(0,1)` | `(-1,-1),(-1,0),(-1,1)` | `(-1,0)` / East | `(-16,-84,32,136)` | `(-16,-84,32,132)` |

The accepted six-category scores are unchanged: **pixel coherence3,
perspective3, silhouette/readability2, layering/anchors3, direction
consistency3, placement2; mean2.67, minimum2**. The score2 placement caveat is
still truthful: all sockets are reachable, but they describe navigation
geometry rather than a coffee interaction.

## Noninteraction boundary

The production family declares `interaction_enabled: false`. `TownRoom`
requires that flag before adding a painted surface to the existing service
interaction map. Coffee therefore retains collision, service-side semantics,
and reachable standing clearance while clicks produce no route, pending
surface action, drawer, company panel, worker request, or save mutation.
Existing interactive service families keep their prior default behavior.

## Verification

The dedicated production regression runs through ordinary `OfficeLayout`,
`TownRoom`, and `GameMain`, without a calibration owner:

- runtime manifest, all 44 SHA-256 entries, source/runtime byte equality, and
  four exact layer recompositions;
- four production profiles and their geometry, registration, layer order,
  offsets, scale, transform, review flags, and candidate fail-closed behavior;
- normal default placement `(4,6)`, four AStar-reachable service sockets, and
  explicit noninteraction through both room and main input paths.

Godot 4.7.2 results at this decision:

- project import: pass;
- project validator: pass;
- `test_coffee_station_production.gd`: **409 checks, 0 failures**;
- `test_furniture_directions.gd`: **429 checks, 0 failures**;
- `test_archive_production.gd`: **3,297 checks, 0 failures, 2,900 physics ticks**;
- `test_service_furniture.gd`: **2,675 checks, 0 failures, 1,184 physics ticks**.

The first shell attempt using the unqualified `godot` command returned127
because this host does not expose it on `PATH`. The same import and all tests
above used the installed 4.7.2 executable at
`/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot`. This was an
environment-path correction, not a project failure. No provider, network,
worker, save, commit, or push was involved.
