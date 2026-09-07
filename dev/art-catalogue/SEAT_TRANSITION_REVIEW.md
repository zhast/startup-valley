# Default-off seat-transition mechanism

Status: **implemented and mechanism-tested; dev-only, no new art/facing approved**. This does not change the current playable south office's default behavior.

## Interface and scope

`EmployeeAvatar.set_seat_transition_preview(enabled: bool, duration_ms: float = 140.0) -> bool` is an explicit opt-in. Enabling is refused outside an editor-capable development binary. Duration must be finite and between **80 and 180 milliseconds**. The default is disabled; nothing in production `GameMain` enables it.

Resolved workstation metadata may include **`seat_correction: Vector2`**. The value must be finite and is normalized to whole pixels. Missing means zero, never a former employee's value. Under the dev gate only, the target visual offset is `seat_anchor + seat_correction`. For the north-inspired synthetic mechanism fixture this is shared chair anchor `(0,-12)` plus Mina `(0,-8)` or Theo `(0,-4)`, yielding −20/−16 pixels. Those numbers are not registered as accepted production north art or chair geometry.

For a new calibration, enable the preview before entering the seated state, and configure metadata while the actor is standing. Turning it on for an already seated actor preserves the existing visible endpoint and smoothly applies the new correction. Explicitly disabling it returns to exact legacy rendering.

`seated_render_offset()` returns the current **integer-snapped interpolated visual offset**, including while standing back up. `render_position()` is the one snapped world origin for character, shadow, event effect, callout painting, label bounds and employee hit tests. Main's hit-test change was coordinated with the root owner; its click-approach destination still uses physical `employee.position + (0,40)`.

## Implementation behavior

- One manually advanced smoothstep interpolation state, not multiple Godot Tweens. Repeated identical worker events, metadata refreshes and preview calls do not restart it or create signals/tweens.
- Retargets from the actual current unrounded interpolation value when interrupted or reentered. Painted positions are always rounded; the internal accumulator remains continuous.
- Near/far depth interpolates from the current depth bias to the explicit prop-relative seated depth, or back to ordinary physical Y on exit. No overshoot.
- Movement, failure/cancellation, delivery, approval, research, lunch, stale seated states away from their desk, and changed/omitted correction metadata all remove the former correction.
- World pause freezes the transition while preserving its pending target. Existing worker/VFX event processing is unchanged.
- The mechanism never writes actor feet, collision transforms, desk destinations, paths, reservations or worker state. Ordinary navigation continues according to its existing logic during stand-up; paired preview/legacy actors move identically.
- Existing unsupported directions remain rejected by the actual pose registry. No `CharacterArt` registry change was made for this mechanism.

## Verification

Headless commands use the existing local Godot binary, `--headless --path game`, and the named `--script`:

| Suite | Result |
|---|---|
| `res://tests/test_seat_transition.gd` | **4,671 checks, 0 failures** |
| `res://tests/test_workstation_facing.gd` | **249 checks, 0 failures**; legacy metadata, pixels, anchors and support gate preserved |
| `res://tests/test_world_ui_presentation.gd` | **422 checks, 0 failures** |
| `res://tests/run_all.gd` | Passed |
| `res://tests/test_graphics_regressions.gd` | Passed headlessly |
| `res://tests/test_complete_game.gd` with `--fixed-fps 60` | Passed |
| `res://tools/validate_project.gd` | Passed |

Focused tests exercise 80/140/180ms durations, both characters, positive and negative depth changes, integer positions, shared effect/shadow/callout origin, main hit tests at moving body tops, unchanged physical click destinations, in-flight interruption through real existing event methods, repeated events/metadata, changed corrections, pause/resume, stale positions and preview disable. Cancellation uses the existing `job.failed` event with `Cancelled by player`; no protocol was added. Two independently navigated preview/legacy actors also walk at full speed and retain identical positions, paths and reservations throughout the transition.

Machine-readable results and per-step offset/depth traces are at `game/tests/output/seat-transition/results-headless.json`. All fixtures disable the worker and do not access saved company state or a provider.

## Native mechanism evidence

```sh
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 60 --write-movie res://tests/output/seat-transition/seat-transition.avi --script res://tools/capture_seat_transition.gd
```

Rendered result: **1,188 checks, zero failures**, `results-rendered.json`; **67-frame movie at 60 FPS**. All nine native 1280×720 PNGs inspected:

- `standing.png`, `seat-start.png`, `seat-middle.png`, `seated.png`
- `stand-start.png`, `stand-middle.png`, `stand-complete.png`
- `interrupted-current-position.png`, `interrupted-standing.png`

Mina's unchanged physical foot is `(400,360)`, Theo's `(816,360)`. Blue rectangles retain the original 48×80 cell; red crosses retain physical feet. At the entry midpoint, the actual body/effect/callout offsets are −9/−7px; the seated endpoints are −20/−16px. Stand-up begins from those same endpoints, reverses through −11/−9px and returns to zero. The interrupted entry reverses from −6/−5px rather than jumping to either endpoint. Synthetic near/far depths resolve to z344/z376 while physical feet remain y360, then return to z360.

These captures deliberately use existing **south-facing** sprites without furniture to isolate the mechanism. They are not a visual claim about a supported north chair, final callout material, seated-body anatomy, hand-to-keyboard contact or layering. A pose image still changes at the semantic state boundary; smooth offset interpolation is not a newly authored sit/stand animation. The next artwork/layer study must validate actual chair support, upper/lower body occlusion and a believable assembly transition before any new direction is enabled.

Production source changed in this bounded step: `game/actors/employee_avatar.gd`. New focused test/capture: `game/tests/test_seat_transition.gd`, `game/tools/capture_seat_transition.gd`. The root owner independently updated main hit geometry. No commits, provider calls, saves, generated pixels or production facing registrations.
