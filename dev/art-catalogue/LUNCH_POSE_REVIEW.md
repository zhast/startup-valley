# Lunch presentation: actual schedule and standing-idle comparison

2026-09-04. Bounded diagnostic after the visible-surface picking source freeze. **Production remains unchanged.** No worker, provider, credential, personal save, new artwork, collision, schedule or catalogue mutation.

## Recommendation

Use the existing directional locomotion idle for a simple **standing break**. Remove only the stationary `LUNCH` override in [EmployeeAvatar](../../game/actors/employee_avatar.gd#L826), allowing its existing default branch to select the two idle frames and standing shadow. Do not change arrival facing, move either employee onto a beanbag, reuse a typing gesture as eating, or claim that lounge seating exists.

The native preview removes the visibly unsupported cross-legged floor pose and returns to walking without a height-changing seated-to-standing switch. It is a modest, honest fallback—not a finished social, eating or coffee-break animation. The lounge seats still remain unused; authored relaxed poses and supported seat sockets would be a separate future feature.

## Reproduction and source cause

- [Current lunch](../../game/tests/output/lunch-pose-review/runtime-lunch-idle-0.png): two empty-side lounge positions at physical feet **Mina `(336,464)`, Theo `(368,464)`**. The old work-sheet bodies occupy approximately `(320,404,32,60)` and `(353,407,30,57)`, below the empty beanbags around `(272,364)`–`(397,418)`. Their cross-legged pose has no supporting lounge attachment. This reproduces the frozen [original finding](RUNTIME_PRESENTATION_PRIORITIES.md#3-p2--lunch-uses-a-floor-sitting-work-pose-in-front-of-the-lounge).
- [TownRoom `lunch_position`](../../game/world/town_room.gd#L348) returns the collaboration cluster's generic interaction position. Navigation reserves separate nearby cells; it does not resolve lounge seats.
- [EmployeeAvatar `set_schedule_phase`](../../game/actors/employee_avatar.gd#L365) routes actual lunch at **12:30**, keeps the `LUNCH` state both while travelling and resting, and returns to work at **13:30**. The existing live-job/delivery guard is unchanged.
- At rest, [lines 826–828](../../game/actors/employee_avatar.gd#L826) explicitly select **row 0 of `mira-work.png` / `theo-work.png`**, with seated shadow index 2. This is not even the separate current `mira-seated.png` / `theo-seated.png` desk atlas. Changing navigation or replacing desk assets would not fix this branch.
- The existing default branch at [lines 845–849](../../game/actors/employee_avatar.gd#L845) already has the correct safe fallback: native 48×80 directional locomotion cells, idle columns 0–1 when not travelling, walk columns 2–5 while travelling, standing shadow index 0 and walking shadow index 1.

## Native comparison

All 14 scene keyframes were inspected at **1280×720**, including both passes' pre-lunch, approach, two stationary idle frames, paused break, return and restored seated desk states. Four additional crops preserve native lounge pixels without scaling.

| Checkpoint | Actual production | Isolated visual preview | Observation |
|---|---|---|---|
| 12:29 at desks | [Before](../../game/tests/output/lunch-pose-review/runtime-before-lunch.png) | [Preview before](../../game/tests/output/lunch-pose-review/standing-preview-before-lunch.png) | Same real south desk poses and positions. |
| 12:30 approaching | [Walk](../../game/tests/output/lunch-pose-review/runtime-walking-to-lounge.png) | [Preview walk](../../game/tests/output/lunch-pose-review/standing-preview-walking-to-lounge.png) | Same native walk cells and route around the desk ends. |
| 12:30 resting | [Floor seated](../../game/tests/output/lunch-pose-review/runtime-lunch-idle-0.png) | [Standing break](../../game/tests/output/lunch-pose-review/standing-preview-lunch-idle-0.png) | Preview feet do not move. Mina/Theo retain their actual left-facing arrival and use 68px standing bodies; no chair claim or floor clipping. |
| Second idle frame | [Old idle](../../game/tests/output/lunch-pose-review/runtime-lunch-idle-1-lounge-native.png) | [Standing idle](../../game/tests/output/lunch-pose-review/standing-preview-lunch-idle-1-lounge-native.png) | Both use their real two-frame source cycle, no image rotation or synthesized pose. |
| Paused lunch | [Production paused](../../game/tests/output/lunch-pose-review/runtime-lunch-paused.png) | [Preview paused](../../game/tests/output/lunch-pose-review/standing-preview-lunch-paused.png) | Physical positions remain fixed; existing idle animation timing continues. No claim that this pass changes pause policy. |
| 13:30 returning | [Return](../../game/tests/output/lunch-pose-review/runtime-returning-to-work.png) | [Preview return](../../game/tests/output/lunch-pose-review/standing-preview-returning-to-work.png) | Same direction, native walk frame and physical position on the first sampled return. |
| Back at desks | [Restored](../../game/tests/output/lunch-pose-review/runtime-work-restored.png) | [Preview restored](../../game/tests/output/lunch-pose-review/standing-preview-work-restored.png) | Mina `(336,240)` / Theo `(656,240)`; real separate seated atlases restored, not idle-work row 0. |

The standing bodies' measured source ink is 68px tall, compared with the lunch work frames' 60px/57px. The taller head position is a posture change around unchanged bottom foot registration—not a navigational translation. The pair looks like employees waiting near the lounge; both happen to face left because that is their actual arrival direction. Rotating them to face each other would be a new behavioral choice, not part of this fix.

## Deterministic evidence

New diagnostic [capture helper](../../game/tools/capture_lunch_pose_review.gd) and [headless entry](../../game/tests/test_lunch_pose_review.gd) instantiate real `GameMain` with a blocked `NullWorker`. The clock and employee state/nav paths are production code. Other scene processing is frozen, and exactly **500 actual employee-physics ticks per pass** are advanced at 1/30 second. The second pass overrides only stationary lunch's body texture/region and shadow after each tick; it never edits the production script or a texture.

- **4,083 headless checks / 0 failures**: [results-headless.json](../../game/tests/output/lunch-pose-review/results-headless.json).
- **4,115 rendered checks / 0 failures**, 14 full-scene PNGs + 4 native crops: [results.json](../../game/tests/output/lunch-pose-review/results.json).
- The complete two-pass trace is identical for employee position, facing, state, phase, requested/actual destinations, route, reservations and timers—not only the final positions.
- Every sampled cell is walkable; employees reach distinct reserved destinations; a repeated lunch clock event does not restart the route or timer; pausing keeps feet fixed; 13:30 restores work and actual desk seating.
- Every capture records exact source sheet, 48×80 region, source ink bounds, physical/render position, shadow region and active work-layer count. No stale work layers or workstation seat corrections remain at the break.
- Shared source and all six used character sheets are hashed in the manifests and remain unchanged through the run. EmployeeAvatar source SHA256: `8465256f283a3e603ca952a37acd4b9f57a287d928afd088843fe7e00dcf72f4`.
- Rendered results SHA256: `ab19649297dedfb7f984c5a34d88b38310c1936553f8040a56266480ec4bc751`.
- Headless results SHA256: `647c2f673a31823120c197b1c1d5c4d02821cb6401bd12e3deaaa9f1f3ae0530`.

```sh
godot --headless --path game --fixed-fps 30 --script res://tests/test_lunch_pose_review.gd
godot --path game --fixed-fps 30 --script res://tools/capture_lunch_pose_review.gd
```

These are isolated simulated schedule keyframes, **not a recorded movie, live job, full input playtest or production acceptance**. The diagnostic deliberately pins today's floor-seated baseline; after an approved production correction, its baseline expectations must be preserved as an explicitly reconstructed old comparison or migrated rather than silently accepted as the new runtime.

## Exact implementation and acceptance proposal

1. Delete only the three-line `elif not walking and work_state == WorkState.LUNCH` branch and add a short comment beside the default branch explaining standing break reuse. Keep `LUNCH`, paths, reservation cells, `_facing`, timer speed and worker events unchanged.
2. Add a focused production test covering both employees, all four arrival directions, idle frames 0/1, walking cells, stationary standing shadow, zero stale seat layers/offsets, repeated phase updates and paused physical position. Check actual sheet and region—not just the state enum.
3. Retain the real 12:29 → 12:30 arrival → 13:30 return trace above, with both idle frames and restored actual seated desk sheet. Verify active work and delivery still respect the existing schedule guard, and terminal work during lunch returns to the same break presentation.
4. Rename the misleading existing `test_complete_game.gd:356` assertion message from “separate lunch seats” to “separate lunch destinations.” That test currently proves arrival only, not support by a seat. `run_all.gd:361–364` similarly checks phase/state but not art. The motion audit's schedule scenario samples lunch → off shift → next morning, so add same-day lunch return evidence rather than treating its existing end frame as that proof.
5. Rerun focused tests and the existing schedule motion scenario, inspect actual lunch/return native frames and preserve this before evidence. Do not regenerate furniture, add eating VFX or broaden the lounge system in this small pass.
