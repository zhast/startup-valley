# Canonical standing-service furniture integration

2026-09-04, 08:46 UTC. **Framework and actual-room calibration tests pass. Archive art remains staged; no production catalogue or personal state changed.** This is the real GameMain/input/navigation/editor counterpart to the separate [archive source and assembly review](ARCHIVE_ASSEMBLY_REVIEW.md).

## What now works

Standing furniture has an explicit `profile_kind: "service"` path through [OfficeLayout](../../game/world/office_layout.gd) and [TownRoom](../../game/world/town_room.gd). It does not pretend to seat a worker, register character poses, or supply a work cell. A selected furniture view names its outward `service_side`; the founder looks in the opposite `approach_gaze` when genuinely reaching that side's authored standing point.

The four archive views use the normal canonical Sprite2D layer construction, physical collision, navigation grid, hit testing, actual R/Move/Undo editor controls and existing Studio action. No parallel cabinet renderer or new service backend replaces those paths. Native layers remain full-canvas, nearest filtered, unit scale and unrotated.

| View / service side | Standing cell relative to host | Arrival gaze | Occupied cells | Native opaque envelope |
| --- | --- | --- | --- | --- |
| North | `(0,-1)` | South | `(-1,0),(0,0),(1,0)` | `(-48,-80,96,96)` |
| East | `(1,0)` | West | `(0,-1),(0,0),(0,1)` | `(-16,-112,32,160)` |
| South | `(0,1)` | North | `(-1,0),(0,0),(1,0)` | `(-48,-80,96,96)` |
| West | `(-1,0)` | East | `(0,-1),(0,0),(0,1)` | `(-16,-112,32,160)` |

All five authored layers share a **192×288 canvas, floor pivot `(96,224)`, centered-sprite offset `(0,-80)` and depth offset zero**. Stable same-depth order is Carcass, Top, Front, Plinth, Insert. Sorting now explicitly preserves declaration order for equal depth; the legacy South canonicalizer is unchanged. The four actual room renders are compared against every opaque pixel of the corresponding registered whole export, with zero mismatches.

## Admission and validation

Every service view must explicitly provide `profile_kind`, `service_side`, `approach_gaze`, `approach_visual_bounds`, `occupied`, `clearance`, `interaction`, `anchor_offset`, `visual_bounds`, `render_layers` and `ambient_overlays`. Common native-layer validation still checks paths/imports, finite integer geometry, source regions, fixed origins, alpha content bounds, exact visual union, and forbidden scale/rotation/mirroring. A service interaction must be one cell beyond its named footprint face and belong to a clear approach strip.

Service profiles reject work/seat/pose fields, including per-employee seating and depth-lock metadata. Conversely, a desk/research profile cannot bypass its existing real actor-pose gate by declaring itself a service prop. Mixed workstation/service semantics are rejected. Production service readiness requires explicit boolean **art and geometry reviews** and `status: "runtime_ready"`; it neither requires nor claims a seated-pose review.

Unreviewed views can enter this editor fixture only through `authorize_calibration_service_profile(kind, facing, owner)`. Admission is bound to a live owner, the particular OfficeLayout instance and the exact validated profile contents. Copying a catalogue, mutating a layer after admission, using a different owner or freeing the owner cannot carry that permit forward. Teardown revokes every candidate. A second independent scene is tested for stale facing, Studio attention and permit leakage. Candidate review flags stay false; the isolated test of the future production gate never writes back to the catalogue or assets.

### Standing headroom is a placement requirement

A free foot cell alone previously allowed a northern visitor's head to appear on the wall. Every explicit service profile must now provide `approach_visual_bounds` containing at least **`(-24,-72,48,80)` relative to its standing point**: the conservative native actor source cell and current foot baseline. Missing, shrunk, fractional, non-finite and malformed envelopes are rejected. Enlarging the envelope cannot bypass architecture checks.

Placement validates every overlapped floor/architecture cell, not just the foot cell. This check intentionally does not reject correct cabinet-over-actor depth occlusion. It does not move actors, manufacture a shorter sprite or alter the authored furniture raster.

For the actual north-west corner, host cell `(2,5)` / pivot **`(80,176)`** has legal cabinet art and feet but fails `service_headroom`. The actual editor rejects it, retains the candidate and previous placement, and gives “Standing visitor would overlap a wall; move service furniture farther inward.” The same preview moved one row inward to `(2,6)` / pivot **`(80,208)`** passes. A real click then routes the founder to `(80,176)` and opens Studio; all four source-cell corners are over floor.

- [Rejected nearest row](../../game/tests/output/calibrated-service/headroom-wall-rejected.png).
- [Accepted inward row](../../game/tests/output/calibrated-service/headroom-inward-accepted.png).
- [Actual inward service arrival](../../game/tests/output/calibrated-service/headroom-north-service.png).

The service-only development toolbar shows a blue visitor envelope in placement preview. Its two visible status lines fit the paper; full five-stage validation details remain in the tooltip and structured result. This fixes diagnostic caption overflow, not the production game UI.

## Exact-arrival behavior and real input

General ground/employee navigation may choose a nearby free destination. An explicit standing-service click must instead end at its actual authored socket. [GameMain](../../game/world/main.gd) rejects an initially substituted endpoint and rechecks exact arrival plus current actor/collision safety before opening the interface. Failure uses the existing invalid-click feedback. [PlayerAvatar.face_direction](../../game/actors/player_avatar.gd) changes only the displayed cardinal pose at successful arrival; legacy props return no explicit gaze and retain their existing behavior.

The focused test uses real mouse-motion/down/up and R/M/U/Escape events through the viewport. It then steps the actual PlayerAvatar physics/navigation deterministically at fixed 30 FPS; it does not invoke destination handlers directly or teleport the founder to force a successful interaction. Recorded scenarios cover:

- Every view: actual rotation/commit, image hit, path start, middle and end, exact arrival, opposite standing gaze, Studio only after arrival, and click isolation inside the open drawer.
- Leave and return movement, with safe-foot and native-source assertions at every actual physics tick.
- Rotation blocked by the founder or Mina: current feet, committed facing, undo history and candidate are preserved; actionable identity-specific feedback is visible.
- Real Move previews against a wall and corner, plus north headroom rejection/inward acceptance.
- An occupied standing point rejects the click rather than opening Studio from a nearby free cell. The test clicks an exposed cabinet region, so it does not mistake the intentionally higher-priority employee hit target for a prop hit.
- Rotation while the founder is already travelling changes the service target and cancels stale intent without moving the actor. Undo restores the prior layout.
- A deterministic transient navigation obstruction is injected **after** a real service click. The actual player replans and reaches a fallback point, but the arrival gate refuses Studio. This is a controlled socket-blockage case, not a claim that a moving employee independently caused that obstruction.
- An unreachable wall click causes neither a false action nor an artificial facing change.

## Native review and limitations

[All four full-resolution game views](../../game/tests/output/calibrated-service/all-four-native.png) are an unscaled 2×2 arrangement of the original 1280×720 captures, ordered N/E over S/W. The [capture manifest](../../game/tests/output/calibrated-service/manifest.json) lists every source image and all eleven movement scenarios.

Native inspection covered all four plain room views and their four nearest-neighbor 4× crops, all four Studio arrivals, founder/employee rotation rejection, headroom rejection/inward arrival, each cardinal approach midpoint, late-socket midpoint, and the inward north route midpoint. The source panels have no observed layer seam or wall overlap. The sparse calibration fixture deliberately separates the legacy desks from the new archive; it is not a finished office composition. Initial snapshots with employee nameplates partly behind the development toolbar are retained under `before-toolbar-clearance/`; the final fixture moves only its initial staging row and keeps those labels visible.

The following are **honest remaining art/product limitations**, not hidden rendering fixes:

- The tall north-facing cabinet correctly occludes nearly the entire founder at its closest rear service point; only the hair remains above the top. Headroom now keeps that visible part off the wall, but does not make the person artificially render in front. This is a readability tradeoff for independent visual acceptance.
- East and West are physically distinct end panels but are dark and understated at native size. A restrained end identifier would be optional polish; no arbitrary contrast or semantic source repaint was made here.
- Standing arrival reuses existing locomotion idle poses. No drawer-opening, reaching, archive animation or new interaction backend is claimed.
- Service headroom is checked against room architecture, not arbitrary actor/prop image overlap. Existing floor occupancy, clearance, actor safety and ordinary depth rules remain independently enforced.
- The movie was recorded and its scenario stills inspected; all 903 movie frames were not individually watched. Per-tick checks prove the tested physical routes, not every possible future office layout or actor schedule.

The separate assembly review's bounded art scores are **3/3/2/3/2/2 (mean 2.5)**. This task closes the missing canonical placement/input/headroom gate; it does not silently change those art scores or mark the asset runtime-approved. An explicit production recipe/location and independent final art decision remain with the coordinator.

## Verification and reproduction

- [Focused source](../../game/tests/test_service_furniture.gd): **1,573 headless checks, zero failures**.
- [Final rendered run](../../game/tests/output/calibrated-service/manifest.json): **1,745 checks, zero failures; 55 PNG captures; 649 actual founder physics ticks**.
- Eleven paths each contain start/middle/end samples: **33 samples and 33 distinct image SHA-256 values**. Four additional 4× crops are included in the 55-image inventory; the derived unscaled four-view sheet is separate.
- [Movie](../../game/tests/output/calibrated-service/service.avi): `ffprobe` confirms **1280×720, 30 FPS, 903 frames, 30.1 seconds**.
- Existing direction test **429/0**, layout **830/0**, editor **128/0**, migration **2,468/0**, modular office **7,436/0**. `validate_project`, `run_all` and complete-game real-input tests all pass.
- Production catalogue/room JSON, source art, approval metadata, worker contracts and persistence remain unchanged by this integration. The fixture replaces the worker transport before GameMain enters the tree; no worker process/pipe is started. No personal bootstrap, save or credential is loaded.

```sh
godot --headless --fixed-fps 30 --path game \
  --script res://tests/test_service_furniture.gd
godot --fixed-fps 30 --path game \
  --write-movie res://tests/output/calibrated-service/service.avi \
  --script res://tests/test_service_furniture.gd -- --motion
```

The reusable actual-game fixture is [calibrated_service_fixture.gd](../../game/tools/calibrated_service_fixture.gd). Its explicit candidate recipes use the frozen exports in [modular-archive-v1](../../game/tests/fixtures/furniture-calibration/modular-archive-v1/manifest.json), without modifying their recorded approval status.

## Subsequent production promotion — 2026-09-04

The coordinator later independently approved the archive's bounded visual scores and authorized its four views for production. [Archive production integration](ARCHIVE_PRODUCTION_REVIEW.md) records the exact 24 runtime copies, unchanged South bay/unlock/physical mask, all five normal office stages, real four-view editor/navigation/Studio checks, and final source hashes. This is a later, separate acceptance decision; the calibration counts, candidate metadata and limitations above remain accurate historical evidence rather than being retroactively labeled production-approved.
