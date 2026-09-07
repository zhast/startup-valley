# Complete South workstation — seat-state correction review

2026-09-04. **PASS for the complete South calibration assembly; not yet a
production-facing admission.** The original chair-through-torso blocker is
resolved without changing any source pixels, physical feet, navigation cells,
worker terminal semantics, or saved data. This review supersedes only the
visual disposition of the preserved failing review in
`COMPLETE_SOUTH_WORKSTATION_REVIEW.md`; that before evidence remains intact.

## Native result

The corrected [failure scene](../../game/tests/output/complete-south-workstation-after-handoff/failure-restored.png)
and [4× crop](../../game/tests/output/complete-south-workstation-after-handoff/failure-restored-4x.png)
keep Mina and Theo in an idle seated source after `job.failed`. Business state
still terminates immediately: `has_live_job=false`, state is `IDLE`, the route
is cleared, and the navigation reservation is released. The render-only rest
cannot be mistaken for typing and is revoked when its pose capability goes
away.

The [entry grid](../../game/tests/output/complete-south-workstation-after-handoff/enter-review-grid-native.png)
now includes every final approach and seat-interpolation frame. Within the
declared 32-pixel chair envelope, the ordinary body is sorted above the chair
and below `DeskFront`; the former standing torso behind the blue chair no
longer appears. The [leave grid](../../game/tests/output/complete-south-workstation-after-handoff/leave-review-grid-native.png)
uses the same bounded depth sandwich until the actor clears it. Initial facing
comes from the first route waypoint, eliminating the old front-facing flash
before the real side step.

The deterministic Type action now sends the ordinary `job.started` then
`tool.started(write_file)` presentation sequence. It reacquires the exact desk
reservation without routing or restarting the seat interpolation. The updated
[typing scene](../../game/tests/output/complete-south-workstation-after-handoff/typing-restored.png)
and [returned-home scene](../../game/tests/output/complete-south-workstation-after-handoff/left.png)
also prove that a real new activity clears the prior `Work stopped` override.
Only neutral contextual name callouts remain.

The six exact registered endpoints are collected in
[six-poses-review-native.png](../../game/tests/output/complete-south-workstation-after-handoff/six-poses-review-native.png).
At native size the typing motion is intentionally restrained. Entry and exit
still use a discrete locomotion/work-source handoff rather than bespoke
stand-up drawings, but the one-frame source change is readable and contains no
chair, desk, shadow, or body intersection.

## Required six-category score, 0–3

| Category | Score | Basis |
|---|---:|---|
| Pixel coherence | 2 | Exact native registered pixels and nearest sampling; cast detail remains richer than the quiet desk frame. |
| Perspective | 3 | Screen-aligned top, fixed rise and South-facing chair/computer contact remain coherent. |
| Silhouette/readability | 3 | Both employees, chair, monitor and desk remain distinct at 1× in every terminal and work state. |
| Layering/anchors | 3 | Entry, seated work, terminal rest and departure keep the body in the authored layer sandwich with unchanged physical feet. |
| Direction consistency | 2 | South is internally correct; this bounded review does not certify the other three directions. |
| Placement | 2 | Both real paths, reservations and separate desks pass; crowded production stages are a later integration gate. |

**Mean 2.50; minimum 2.** This meets the goal's assembly-review threshold.
An independent motion-oriented re-score was 2.33/3 because it additionally
penalized the discrete source swap, subtle typing, and bottom-edge diagnostic
nameplate placement. Those are recorded polish limits, not hidden as a 3/3
animation claim.

## Deterministic evidence

| Run | Checks | Failures | Physics ticks | Engine frames |
|---|---:|---:|---:|---:|
| [Headless manifest](../../game/tests/output/complete-south-workstation-after-handoff/results-headless.json) | 4,041 | 0 | 302 | 336 |
| [Native manifest](../../game/tests/output/complete-south-workstation-after-handoff/results.json) | 4,125 | 0 | 302 | 336 |

The [native movie](../../game/tests/output/complete-south-workstation-after-handoff/complete-south.avi)
contains 337 decoded 1280×720 frames at 30 FPS. Captured transition evidence
contains 18 inbound and 15 outbound frame pairs. The harness uses actual
keyboard/mouse input and manually steps each real actor once per fixed physics
tick while automatic actor physics is disabled.

Negative checks cover malformed/non-finite/fractional/out-of-range clearance
and lower-depth metadata, production-pose forgery, repeated terminal events,
exact-target reservation reacquisition, and live pose-registry revocation.
Every actor position stays walkable, all render transforms are integer-snapped,
the floor shadow never inherits seat Y, and no worker process or company
bootstrap is created.

Source snapshot:

| File | SHA256 |
|---|---|
| `complete_south_workstation_fixture.gd` | `f17511675930a57a5cae5f7ad3c8e12fcee32cb88b38f0868be079b99c7a4809` |
| `capture_complete_south_workstation.gd` | `77ff72fde7fd6ab5c533844deb467d867845aa622bdce0fb5426f4f4d0b2497c` |
| `calibrated_workstation_fixture.gd` | `51385499bb1a1587b77740bf28bbc83c99d8981487ff02829ad848e17902c217` |
| `employee_avatar.gd` | `907d33c88cab4015dae88ca987cffb972b7dc4a38863c4bd1dac01f60a129b44` |
| `character_art.gd` | `400522327d04af8211e7cf71e2dd4b2a44a88667013968932fe55d081b9e3ac9` |

## Boundary and next gate

This is a truthful dev calibration pass, not permission to flip review flags.
`seat_state_handoff`, depth lock, grounded shadow and the temporary directional
pose registry remain owner-scoped editor capabilities. The next gate is the
complete West native review, followed by one explicit production pose/art
contract for accepted South and West assemblies. No raster was generated or
semantically edited in this correction.
