# Collaboration cluster v2 — ordinary production acceptance

Date: September 6, 2026

Runtime revision: `collaboration-cluster-v2`

Disposition: **passes the dedicated ordinary-`GameMain` production gate**. This
review verifies the production registration that already exists; it does not
authorize another redraw, worker/contract change, save migration, or unrelated
catalogue edit.

## Scope and production truth

The dedicated test instantiates the normal `world/main.tscn` scene and reads
`game/data/furniture_catalog.json` plus `game/data/office_layout.json` directly.
It does not install a candidate catalogue, calibration owner, preview permit, or
replacement `OfficeLayout`. Worker startup is disabled and no personal save is
read or written. The ordinary worker-disabled bootstrap materializes only the
authored Mina/Theo workstation records; there is no collaboration override at
startup.

At the start and end of both final passes, the production files were byte-exact:

- `game/data/furniture_catalog.json`: `36f81e5d20ee0894e66657bcfcdb275c69266bd48116f3d324c8df37f484b883`
- `game/data/office_layout.json`: `820d4e7cfe206d8f7543ab421c437de2a5037299f707e5602f6a6faf299078eb`

Production resolves all four independent N/E/S/W profiles with
`profile_kind: collaboration`, `asset_revision: collaboration-cluster-v2`, and
`interaction_enabled: false`. The profiles retain **36 exact native layers** in
total (N 7, E 11, S 7, W 11), ten occupied 32×32 cells and four clear sockets
per direction. No finished layer is rotated, mirrored, flipped, or scaled. The
default placement remains South at grid `[12,14]`, unlocked at the first hire.

## Lifecycle result

The final headless pass is **574 checks / 0 failures**. The final native macOS
pass is **1,056 checks / 0 failures** at an exact **1280×720** viewport. For each
direction, at the same `[12,14]` pivot, the test proves:

- stage 0 contains no cluster; stages 1–4 each contain exactly one valid v2
  cluster;
- the live prop has all exact layers, ten one-cell collision shapes, four
  non-colliding walkable sockets, and matching blocked navigation cells;
- Mina and Theo approach concurrently from their ordinary spawn positions,
  reserve distinct first/second sockets, arrive exactly, ease through the
  140ms contact handoff, and hold stable in the split seated presentation;
- opening Renovate applies the real world-pause policy, and rotating the occupied
  cluster is rejected with two live actor conflicts and no placement or collision
  mutation;
- while Settings keeps the world paused, a real `job.started` record for Theo and
  an ordinary work-phase transition for Mina create desk-return routes without
  changing either actor's physical foot, rendered seat contact, or depth on the
  event frame; eight paused physics ticks remain frozen;
- after resume, both actors retain split chair-contact depth while within 32px of
  their own seat, clear the furniture, navigate safely to distinct desks, and
  settle through the 140ms workstation handoff;
- after both sockets are vacant, the editor commits the next authored facing and
  creates one Undo step. Undo restores the exact prior facing, placement override,
  and ten-shape collision signature: N→E→N, E→S→E, S→W→S, W→N→W.

The gap-free physics probe samples actor position, rendered position, seat
offset, handoff state, split-layer count, navigation safety, and reservations on
every actual physics tick—even while PNG acquisition awaits a render frame. It
records zero unsafe samples and zero reservation conflicts in every approach and
return. Maximum one-tick rendered displacement is **4.47px**, below the unchanged
16px discontinuity ceiling. Per-direction entry maxima for Mina/Theo are N
`4.00/3.00`, E `3.00/3.61`, S `3.00/3.00`, and W `3.16/3.16` pixels. Complete
lunch-to-desk maxima are N `4.47/3.16`, E `3.61/4.24`, S `4.00/3.61`, and W
`3.61/3.61` pixels. Physical movement is bounded to `1.84px` per physics tick.

## Native evidence and 1× review

- [Entry keyframes](../game/tests/output/collaboration-production/entry-keyframes-native.png)
- [Paused work-interrupt/exit keyframes](../game/tests/output/collaboration-production/work-interrupt-keyframes-native.png)
- [Four-facing seated contact details](../game/tests/output/collaboration-production/hold-contact-sheet-native.png)
- [Four unscaled 1280×720 held-room panels](../game/tests/output/collaboration-production/full-room-hold-native-panels.png)
- [Real Settings pause panels](../game/tests/output/collaboration-production/pause-resume-contact-sheet-native.png)
- [Occupied rejection / vacant rotation pairs](../game/tests/output/collaboration-production/rotation-contact-sheet-native.png)
- [Native machine result](../game/tests/output/collaboration-production/actual-room-results.json)
- [Headless machine result](../game/tests/output/collaboration-production/results-headless.json)
- [Dedicated test](../game/tests/test_collaboration_production.gd)

Motion-sheet row order is North Mina, North Theo, East Mina, East Theo, South
Mina, South Theo, West Mina, West Theo; time runs left to right. The four-facing
detail sheets use North/East on the first row and South/West on the second.
Rotation rows are N/E/S/W, with occupied rejected preview on the left and the
next vacant committed facing on the right.

At original size, the table, four chairs, two distinct occupants, inward gaze,
and direction-specific front/rear occlusion remain readable in every direction.
North/South give the clearest social-table read. East/West remain coherent and
correctly layered, but the long edge and rear-seat reveal are visually tighter.
The exit strips retain the split body around each chair until physical clearance;
there is no exposed standing body left in a chair and no one-frame pop. The pause
sheet honestly shows the normal Settings overlay, so the machine-recorded
eight-tick freeze—not a visible actor comparison beneath that opaque panel—is the
authoritative pause-motion proof.

## Native visual score (0–3)

| Category | Score | Finding |
| --- | ---: | --- |
| Pixel coherence | 3 | Crisp native nearest-neighbor pixels, clean alpha, integer assembly, and no transformed finished raster. |
| Perspective | 2 | All screen-axis projections and inward gazes read correctly; East/West rear-seat clearance remains tighter than the horizontal views. |
| Silhouette/readability | 3 | One collaboration table, four distinct chairs/sockets, and two occupants remain immediate at native scale. |
| Layering/anchors | 3 | Entry, hold, split exit, shadow, chair/body/table sandwiches, 140ms endpoints, and exact anchors all remain coherent. |
| Direction consistency | 3 | N/E/S/W preserve one identity while independently changing axis, seats, props, gaze, and occlusion. |
| Placement/lifecycle | 3 | Stage gating, live collision, concurrent routes, reservations, pause/resume, occupied rejection, vacant rotate+Undo, and safe return all pass. |

Mean **2.83 / 3**, minimum **2 / 3**. The ordinary production acceptance gate
passes without a runtime redraw.

## Preserved failure and capture history

The acceptance history is retained because the first red results were useful
harness failures, not silently discarded evidence:

1. The first headless run reported **570 checks / 5 failures**. One assertion
   incorrectly required an empty startup override dictionary even though the
   normal worker-disabled path intentionally materializes authored workstation
   records. Four desk-anchor assertions sampled before the ordinary 140ms arrival
   handoff had settled. The test was corrected to admit only authored workstation
   bootstrap records, restore that exact starting state, and wait the documented
   settle window. No runtime code changed for these failures.
2. The next headless run passed **574 / 0**.
3. The first native run reported **1,055 checks / 7 failures** at an apparent
   16.40–21.00px exit step (N Mina 19.42; E Mina/Theo 16.40/19.72; S Mina/Theo
   21.00/17.03; W Mina/Theo 17.20/17.20). PNG capture had advanced multiple
   physics ticks between samples, while the comparison still used the pre-pause
   position. The threshold was not relaxed. Sampling moved to a gap-free
   `SceneTree.physics_frame` probe with exact tick IDs.
4. The first corrected native rerun combined that probe with synchronous
   `RenderingServer.force_draw` and stopped making capture progress. It was
   interrupted after roughly five minutes with no assertion output; the complete
   prior failed evidence remained on disk. Removing only the synchronous draw
   request restored ordinary frame-post-draw capture.
5. The gap-free headless rerun passed **574 / 0** and the final native rerun
   completed in 16.6 seconds at **1,056 / 0**. Its true worst one-tick movement is
   4.47px, conclusively identifying the seven earlier motion failures as dropped
   samples rather than runtime body jumps.

## Boundary and limitations

This verifies the current Mina/Theo pair in the first two of four sockets. It
does not prove a larger roster, conversation gestures, meeting UI, table
interaction, or worker-owned collaboration state. The `job.started` record is a
deterministic local event delivered through the ordinary actor API while the
worker is disabled; this is not an end-to-end stdio worker test. N/E/S/W are
tested as session-local valid placement overrides at the production pivot, while
the authored default remains South. The test resets actor state between facing
cases but restores the ordinary placement bootstrap and leaves production files
byte-exact.

Reproduce from the repository root:

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_collaboration_production.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tests/test_collaboration_production.gd
```
