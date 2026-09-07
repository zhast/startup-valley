# Complete West workstation — native lifecycle review

2026-09-04. **PASS for the complete West calibration assembly; not yet a
production-facing admission.** This is the first full West lifecycle review,
covering real selection input, approach, seat interpolation, idle, typing,
thinking, terminal failure rest, activity recovery and physical departure for
both Mina and Theo.

## Native result

The [six-pose sheet](../../game/tests/output/complete-west-workstation/six-poses-review-native.png)
shows both employees using the exact registered West sources at 1×. The narrow
screen-aligned desk, left-facing monitor, keyboard and mouse read as one fixed-
camera assembly. Mina and Theo keep distinct silhouettes while their hands and
gaze meet the worksurface.

The [entry grid](../../game/tests/output/complete-west-workstation/enter-review-grid-native.png)
and [leave grid](../../game/tests/output/complete-west-workstation/leave-review-grid-native.png)
prove the chair/actor/desktop depth sandwich for every captured physical tick.
Inside the declared 32-pixel envelope the ordinary actor is temporarily sorted
between the chair rear and desk front. Departure changes directly from seated
West to the true first walking direction; there is no intermediate wrong-facing
frame, torso paint-through, detached shadow, or fake route.

The [failure scene](../../game/tests/output/complete-west-workstation/failure-restored.png)
keeps the terminal employee in a readable render-only seated rest while the
business job, route and reservation are already terminated. The subsequent
[typing scene](../../game/tests/output/complete-west-workstation/typing-restored.png)
uses a real deterministic write event and clears the `Work stopped` override.
The [returned-home scene](../../game/tests/output/complete-west-workstation/left.png)
contains only neutral contextual labels.

## Required six-category score, 0–3

| Category | Score | Basis |
|---|---:|---|
| Pixel coherence | 2 | Native nearest-sampled pixels are crisp; minor source-level hair and Theo sole/cushion phase variation remains. |
| Perspective | 3 | Desk, monitor, chair, peripherals and actor contact consistently read West in the fixed camera. |
| Silhouette/readability | 3 | Both employees and seated/typing states remain distinct at 1×. |
| Layering/anchors | 3 | Entry, settled work, failure rest and departure preserve the authored chair/actor/desktop sandwich. |
| Direction consistency | 3 | Every settled work pose faces left toward the West monitor; no raster is merely rotated or mirrored. |
| Placement | 2 | Both routes and stations are separated and collision-safe; dense normal-office/corner placement remains the production integration gate. |

**Mean 2.67; minimum 2.** This passes the goal's bounded assembly-review
threshold. The source turns at the final sit and initial stand ticks are
visibly discrete because no bespoke turn/sit animation exists. They do not
teleport or intersect geometry and are recorded as future P2 motion polish,
not concealed as a perfect animation score.

## Deterministic evidence

| Run | Checks | Failures | Physics ticks | Engine frames |
|---|---:|---:|---:|---:|
| [Headless manifest](../../game/tests/output/complete-west-workstation/results-headless.json) | 3,177 | 0 | 230 | 264 |
| [Native manifest](../../game/tests/output/complete-west-workstation/results.json) | 3,261 | 0 | 230 | 264 |

The [native movie](../../game/tests/output/complete-west-workstation/complete-west.avi)
contains 265 decoded 1280×720 frames at 30 FPS. Evidence includes every
inbound and outbound physical transition frame, native endpoint captures and
nearest-neighbor crops. The harness sends actual keyboard/mouse input, uses
navigation and reservations, and manually steps real actors with their
automatic physics disabled.

Independent review found no stale failure UI, chair/desk departure glitch,
floating contact, cushion paint-through, desk inversion, or wrong-facing
workstation element. Partial callout fragments appearing only at the edge of
tight contact crops are crop-boundary artifacts; the complete 1280×720 frames
retain the full text.

Source snapshot:

| File | SHA256 |
|---|---|
| `complete_west_workstation_fixture.gd` | `73596a00f88c712ff4e1eb7676410d09e452d8ec82581e4a65faf2e77a73f3f4` |
| `capture_complete_west_workstation.gd` | `531a8693eb6cd42e1c744d574eb3ae37ff502f945858d5c136daacd0eb7183f2` |
| `calibrated_workstation_fixture.gd` | `51385499bb1a1587b77740bf28bbc83c99d8981487ff02829ad848e17902c217` |
| `employee_avatar.gd` | `907d33c88cab4015dae88ca987cffb972b7dc4a38863c4bd1dac01f60a129b44` |
| `character_art.gd` | `400522327d04af8211e7cf71e2dd4b2a44a88667013968932fe55d081b9e3ac9` |

## Boundary and next gate

This accepts the reviewed West art/geometry/pose combination as a calibration
candidate. It does not make `calibration_preview` a production permission or
turn review booleans into capabilities. Production admission requires exact
versioned runtime assets, an explicit reviewed pose/capability registry, normal
`GameMain` use without a calibration owner, and wall/corner/crowding evidence.
No new raster was generated or semantically edited for this pass.
