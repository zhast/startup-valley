# Standing lunch fallback — production implementation

2026-09-04. Implements the bounded recommendation approved after [the lunch audit](LUNCH_POSE_REVIEW.md). The original audit helper, report, 18 PNGs and result manifests remain frozen; all new output is under `lunch-standing-after`.

## Change

- Removed only the stationary `LUNCH` work-sheet/seated-shadow branch from [EmployeeAvatar](../../game/actors/employee_avatar.gd#L817). The existing default branch now selects the actual arrival-facing locomotion idle, with its existing standing shadow. A short comment explains the intentionally simple break presentation.
- No schedule, route, foot anchor, reservation, facing, timer, pose registry, worker method, production artwork, collision or lounge attachment changed. Walking lunch still uses the original four directional walk cells. Active work and delivery retain their existing schedule priority.
- Corrected `test_complete_game.gd`'s misleading assertion copy from “lunch seats” to “lunch destinations.” It still tests the same arrival condition.
- Added [production regression/capture helper](../../game/tools/capture_lunch_standing.gd) and [focused test](../../game/tests/test_lunch_standing.gd). The previous `test_lunch_pose_review.gd` test entry now forwards to this production check instead of permanently asserting the removed defect. The original `capture_lunch_pose_review.gd` is retained as the old diagnostic source, not rerun over its historical output.

This is **standing idle during a break**, not an authored eating, coffee, conversation or beanbag-seating animation. Unused lounge seats remain an explicit future content opportunity.

## Native acceptance

All seven new 1280×720 scene states and both native lounge crops were inspected. The actual production result matches the previously reviewed isolated standing preview, not the old floor-sitting state.

- [12:29 desks](../../game/tests/output/lunch-standing-after/before-lunch.png): real separate seated desk atlases retained.
- [Approach](../../game/tests/output/lunch-standing-after/walking-to-lounge.png): ordinary native walking art, no seated body sliding toward the lounge.
- [Lunch idle 0](../../game/tests/output/lunch-standing-after/lunch-idle-0.png) and [idle 1](../../game/tests/output/lunch-standing-after/lunch-idle-1.png): Mina and Theo remain at physical feet **`(336,464)` / `(368,464)`**, facing their actual leftward arrival. Standing shoes remain grounded; no cross-legged floor pose or workstation layer persists. The bodies remain visually separate, with the same existing lounge and label placement.
- [Paused break](../../game/tests/output/lunch-standing-after/lunch-paused.png): no physical movement or seat-offset drift. Existing idle animation policy is unchanged.
- [13:30 return](../../game/tests/output/lunch-standing-after/returning-to-work.png): original route and directional walk frames.
- [Desk seating restored](../../game/tests/output/lunch-standing-after/work-restored.png): actual `mira-seated.png` / `theo-seated.png` at `(336,240)` / `(656,240)`, with no lunch state or shadow leaking into desk presentation.

A read-only comparison of the before-preview and after manifests confirms **140/140 actor fields match exactly** across seven states and two actors: physical/render position, work state, schedule phase, facing, travelling flag, source texture, atlas region, shadow region and work-layer count. This is not a claim that every whole-screen pixel is identical across unrelated station-hover changes.

## Tests run

| Test | Result |
|---|---|
| `test_lunch_standing.gd`, headless | **2,238 checks / 0 failures** |
| Compatibility entry `test_lunch_pose_review.gd`, final headless replay | **2,238 checks / 0 failures** |
| `capture_lunch_standing.gd`, native 1280×720 | **2,254 checks / 0 failures; 7 scene PNGs + 2 native crops** |
| `test_workstation_facing.gd`, headless | **249 checks / 0 failures** |
| `test_world_ui_presentation.gd`, headless | **468 checks / 0 failures** |
| `run_all.gd`, headless | **Passed**, exit 0 |
| `test_complete_game.gd`, headless fixed 60 FPS | **Real-input tests passed**, exit 0 |
| `validate_project.gd`, headless | **Runtime scenes, art and modular office stages valid**, exit 0 |

Focused coverage includes actual 12:29 → 12:30 lounge arrival → repeated lunch clock → pause → 13:30 desk return, with 500 production physics ticks and no body override. Isolated open-floor tests additionally execute real approaches from all four directions for both employees; verify every idle 0/1 and walk 2–5 source cell; and assert correct standing/walking shadow, native transforms, unchanged feet/facing/timers, cleared prior desk offset/depth, and hidden stale cached work layers. Injected stale layers and nonzero prior-seat offsets are explicitly geometry-only test fixtures, not invented lounge art.

Actual actor event paths cover active typing across lunch, incoming `job.failed` / `job.blocked` while paused, job completion, protected delivery while lunch is active, paused delivery, and eventual standing-break arrival. No worker process is created; the actual room uses `NullWorker`, and isolated event records do not dispatch transport methods.

## Evidence / source snapshot

- [Headless results](../../game/tests/output/lunch-standing-after/results-headless.json): SHA256 `8d216a890ef9c5f18aef489726b55ed9113de1251df57390d28c4386b3e57e8c`.
- [Rendered results](../../game/tests/output/lunch-standing-after/results.json): SHA256 `73487b011450efd9317b78c889009a564eec9ef61e1f5746363535efdece0cfd`.
- Production EmployeeAvatar after SHA256: `da8eb02de50c64a439c029d0632b84ec1422bb3b0547ca38e2e583945730d16e`.
- Historical before manifest remains SHA256 `ab19649297dedfb7f984c5a34d88b38310c1936553f8040a56266480ec4bc751`; old headless manifest remains `647c2f673a31823120c197b1c1d5c4d02821cb6401bd12e3deaaa9f1f3ae0530`.
- Per-capture filenames, hashes, poses and full shared-source hashes are in the new manifests. All source/art files were stable through the final runs.

```sh
godot --headless --path game --fixed-fps 30 --script res://tests/test_lunch_standing.gd
godot --path game --fixed-fps 30 --script res://tools/capture_lunch_standing.gd
```

No new image generation, full motion-audit rerun, paid job, personal save, fullscreen variant, commit or push occurred in this bounded change. Native evidence is keyframes of real simulated schedule movement, not a newly recorded movie. A combined production motion pass can recapture this lunch state alongside the independently implemented station-hover and picking changes.
