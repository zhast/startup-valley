# Complete South workstation — combined candidate review

2026-09-04. **FAIL for whole-assembly acceptance; remain dev-only.** The quiet
desk finish and settled work poses are preferable, and all bounded functional
checks pass. However, failure and stand/leave boundaries visibly place an
ordinary standing body inside the chair back. This is an actual combined
presentation defect, not a reason to approve the assembly based on material
scores or to regenerate every asset.

No production profile, source pixel, prior fixture, worker, saved company,
credential, protocol or previous evidence was changed. No image was generated.

## Result at native size

The [six source-frame endpoints](../../game/tests/output/complete-south-workstation/six-poses-review-native.png)
show both employees at two idle and four typing phases. Their faces/outfits
remain clear; the quiet grain no longer competes with the thin computer and
desk edges. The rear monitor naturally hides most hands, keyboard and lower
body. That is expected South-view occlusion, not permission to put hands in
front of the monitor. Small source typing motion remains subtle at 1×.

The blocker is visible in the normal
[failure scene](../../game/tests/output/complete-south-workstation/failure-restored.png)
and [4× inspection crop](../../game/tests/output/complete-south-workstation/failure-restored-4x.png):
the blue chair back crosses Mina's standing waist around **(329–344,209–223)**
and Theo's equivalent around **(777–792,209–223)**. Both actors remain at their
physical work feet, while failure changes the body to side-facing standing
locomotion and removes the seated visual offset. The chair stays in its valid
fixed layer. The resulting silhouette does not read as someone safely standing
beside a seat. It persists after the 140ms visual interpolation has settled.

The same source/depth discontinuity appears briefly during
[actual leave boundaries](../../game/tests/output/complete-south-workstation/leave-review-grid-native.png).
The [entry sequence](../../game/tests/output/complete-south-workstation/enter-review-grid-native.png)
also shows the standing approach body behind the chair immediately before the
front-facing seated source takes over. Missing bespoke bend/turn drawings are
optional polish; an occupied-chair/standing-torso intersection is not.

There is a **separate dev-control limitation**:
[Type from already seated](../../game/tests/output/complete-south-workstation/typing-review-grid-native.png)
briefly reintroduces the standing body and reruns seating. The inherited
editor's Type button calls `send_to_desk(id,true)`, which always calls
`walk_to(...)`, even at the current destination. This is not evidence that the
normal `tool.started(write_file)` path behaves identically: that handler sets
`TYPING` directly when already at the desk. A future diagnostic-control fix
should avoid this redundant route, then prove direct worker events separately.

The later [typing-body-restored scene](../../game/tests/output/complete-south-workstation/typing-restored.png)
still carries the prior failure cue/copy. This is deliberately the existing
dev Type button, **not a simulated successful new job**: it does not emit a new
worker lifecycle or clear the earlier event's timer. Do not report this image
as a new production stale-job-status bug.

### Whole South score, 0–3

| Category | Score | Current basis |
|---|---:|---|
| Pixel coherence | 2 | Native unchanged sources and exact source partitions; the cast remains more detailed than the simple desk frame. |
| Perspective | 3 | Screen-aligned top, fixed rise/contact, authentic rear monitor, no bitmap rotation or perspective distortion. |
| Silhouette/readability | 3 | Both faces/outfits and the computer/desk read clearly at 1× in settled work poses. |
| Layering/anchors | **1** | Standing failure/leave source intersects the occupied chair; clean endpoint depths alone do not resolve this. |
| Direction consistency | 2 | South body/monitor/chair are correctly facing South; this bounded run does not recertify other directions or every state transition. |
| Placement | 2 | Real paths, native feet and separate seats are safe in this two-desk room; no new crowded/all-office-stage proof is claimed. |

**Mean 2.17; minimum 1.** The required minimum≥2 and mean≥2.5 are not met.
This is a fresh whole-assembly score, not an average of older isolated scores.

## Exact frozen recipe

The new [fixture](../../game/tools/complete_south_workstation_fixture.gd) extends
`desk_grain_v2_fixture.gd`, sets `quiet_grain=true`, hires only the two existing
fixture actors, and fixes both desks South. It explicitly adds
`grounded_work_shadow=true` and `grounded_work_shadow_follow_seat_x=true`.
The original quiet-grain fixture **does not itself enable those shadow flags**.
The inherited depth lock, seated-idle thinking alias and cue attachment remain
unchanged; no new production capability is introduced.

- Desk pivots: Mina **(336,272)**, Theo **(784,272)**; physical work feet
  **(336,240)** and **(784,240)**. Original home feet **(336,560)/(784,560)**.
- Natively registered desk layers:192×224, pivot96,160; `modular-desk-grain-v2`
  rear/front. South top96×32; occupied grid and furniture rise unchanged.
- `chair-south-v3`:96×160, pivot48,112; chair+4Y from work foot.
- Both bodies: unchanged South48×80 source cells, pivot24,72; visual+12Y from
  work foot. Cut50 gives upper48×50 and lower48×30, without overlap or omission.
- Relative-to-desk depths: chair−2, desk rear−1, actor lower0, desk front+1,
  keyboard/mouse+2, actor upper+3, monitor+4. Grounded shadow−3, below all own
  furniture. Absolute seated upper depth275. South X-follow adds zero; floor
  shadow Y remains physical-footY−2, never inherits the+12Y visual lift.
- `computer-south-peripherals-v2` keyboard/mouse, unchanged; rear monitor
  `computer-south-v3` shifted+3Y. No kit, body, chair or source region rescaled.
- Both actors use the inherited140ms opt-in seat interpolation. No movement
  speed, physical foot, route, reservation, state handler or pose source was
  repaired to make screenshots pass.

Asset paths, file SHA256, decoded South body hashes, layer offsets/depths and
the complete resolved profile are in the
[rendered manifest](../../game/tests/output/complete-south-workstation/results.json).
Source snapshot:

| Source | SHA256 |
|---|---|
| `complete_south_workstation_fixture.gd` | `526d760ac26586a973f7008704a7ffebc783ed5e88d1239adee3012d3b9de4f0` |
| `capture_complete_south_workstation.gd` | `ae3131fa78e0969c7221b90bf86a85cfc8ff3f657b604b57c3cb27caa08e7852` |
| `desk_grain_v2_fixture.gd` | `cce3d17516581c09d8c2c5512601d53bcba771c36b69d7e022fba67d1e6894e4` |
| `calibrated_workstation_fixture.gd` | `b9f673bc86294815df7a462a5fb8d0a3ead391c34f326a4464f989522bac7abe` |
| `employee_avatar.gd` | `da8eb02de50c64a439c029d0632b84ec1422bb3b0547ca38e2e583945730d16e` |
| `character_art.gd` | `400522327d04af8211e7cf71e2dd4b2a44a88667013968932fe55d081b9e3ac9` |

## What the run proves

| Run | Checks | Failures | Scope |
|---|---:|---:|---|
| [Headless](../../game/tests/output/complete-south-workstation/results-headless.json) | 4,021 | 0 | Actual controls, navigation, every stepped state/depth, source regions and teardown |
| [Native](../../game/tests/output/complete-south-workstation/results.json) | 4,113 | 0 | Same plus saved native scenes and every transition-tick image |

- **312 physics ticks**, both actors stepped once per tick through their real
  `_physics_process(1/30)`, with automatic actor physics disabled to prevent
  double-stepping. Real Space/arrow/Enter selector input and actual mouse
  down/up on Sit, Type and Leave; no direct action-handler shortcuts.
- **339 movie frames at1280×720/30fps**, independently counted with `ffprobe`,
  below the360-frame limit. The manifest's338-frame delta excludes the one
  startup frame. The movie includes every stepped tick; extra frames are
  zero-time UI/boundary/static-pose presentation, not collapsed movement.
- **10 full native scene checkpoints**, each with native320×208 paired-actor
  crop and nearest4× inspection crop. The six exact source endpoints use
  explicit animation-phase sampling after the actual Sit/Type state and
  arrival; these samples are not claimed as naturally elapsed idle loops.
- **47 transition pairs**: enter10, Type12, failure4, reenter11, leave10.
  All47 were inspected at native size in the five review grids. The movie
  also contains the action boundaries and settled endpoints. Six additionally
  decoded movie frames128–133 confirm the actual pre-seat approach sequence.
- All six paired endpoints, initial/failure/body-restored/left full scenes,
  transition grids and selected4× body/device views were inspected. The full
  movie was not watched frame-by-frame outside those focused transitions.
- Every stepped physical position remains walkable. Every mounted source is
  split once; standing states restore the single body. Source region union,
  global integer transforms, absolute body/shadow sorting and visible shadow
  invariants pass. Returning home restores zero seat offset.
- Injected ordinary `job.failed` events clear live-job state and restore the
  standing source without changing feet. This catches the visual blocker;
  test success is **not** a no-clipping oracle. Registry-loss/approval/research/
  lunch/delivery/all-office-stage checks were not redundantly rerun here.
- Worker is replaced before GameMain readiness. No process or stdio transport,
  no new blocked worker requests during actions, no company bootstrap; scoped
  pose ownership is revoked on fixture teardown. No production direction is
  enabled. Connect remains an inherited dev control but was not used; even
  that fixture transport has no real provider or persistence path.

[Final movie](../../game/tests/output/complete-south-workstation/complete-south.avi)
and focused [failure progression](../../game/tests/output/complete-south-workstation/failure-review-grid-native.png)
are the primary follow-up evidence. Cropped callout words at contact-sheet
edges are diagnostic crop boundaries, not full-scene text clipping.

The initial headless result is preserved as `results-headless-initial-failed.json`:
444 test errors came from checking fractional **local** compensation instead
of the correctly snapped global sprite coordinate; four from checking native
selector ownership before its deferred callback settled. Only this new test
was corrected. An initial native run passed4,066 checks but forced-draw stills
skipped movie frames; its manifest/279-frame movie are preserved under
`first-recording/`. Final capture waits for normal post-draw instead, preserving
every transition. Earlier historical South/material/shadow evidence is intact.

## Precise next step / production boundary

Do **one source-preserving seat-state lifecycle correction next**, before any
new asset batch or production admission. It must keep worker failure semantics
and physical reservations unchanged while preventing the ordinary standing
torso from appearing inside the occupied chair. A seated resting visual after
a terminal event is a plausible candidate only if it remains clearly idle/
failed, not typing; the subsequent real leave still needs a proven safe visual
handoff as feet clear the chair. Merely changing Z, hiding the chair/shadow,
teleporting feet or suppressing the failure checkpoint is not an acceptable fix.

Separately make the dev Type-at-current-seat action preserve the seated pose,
then compare genuine write/thinking events. Reuse this exact asset recipe and
before proof, rerun both actors' boundaries, and re-score whole South. Dedicated
mount drawings are optional **only after** the simple transition is genuinely
non-intersecting and readable.

Only then consider the explicit reviewed production capability path described
in [NEXT_DESK_ACCEPTANCE](NEXT_DESK_ACCEPTANCE.md). Current calibration owner,
editor and false-review gates remain required; replacing them with true flags
does not constitute a production-safe pose/art loader.

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --fixed-fps 30 \
  --script res://tests/test_complete_south_workstation.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 \
  --write-movie res://tests/output/complete-south-workstation/complete-south.avi \
  --script res://tests/test_complete_south_workstation.gd
```
