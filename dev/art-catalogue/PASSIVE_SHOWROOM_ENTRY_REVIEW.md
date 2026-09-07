# Interactive passive showroom: toolbar label follow-up

2026-09-04. This is a dev-only entry correction after the frozen runtime closeout checkpoint. It does not change the passive fixture, production callout solver, employee art, worker, or saved placements.

## Reproduced problem and narrow correction

The retained [original native smoke](../../game/tests/output/passive-showroom/smoke-before.png) shows paper pointers near Mina `(369,605)` and Theo `(752,605)` while their corresponding name cards are hidden underneath the dev toolbar, whose rectangle is `(24,610,1080,102)`. The employee bodies are above the toolbar; it is the label body that is obscured. This is not an employee sprite clipping defect.

The original entry called the inherited `place_editor_labels()` through a deferred `SceneTree._process` callback. Production `GameMain` also computes labels every frame, without knowledge of this optional dev toolbar. In addition, the inherited dev helper assigns `labels_suppressed` directly when no candidate fits, without invalidating the cached label drawing on that branch. Therefore neither callback activity alone nor the final logical rectangle proves the current drawn label is correct.

`game/tools/play_passive_furniture.gd` now installs a late-priority Node (`process_priority=10000`) that runs the existing toolbar-aware placement after the main scene, then explicitly invalidates each employee's `LabelLayer`. No production node, solver, actor position, or drawing material was changed. The entry still uses the disposable real-GameMain passive fixture and revokes its candidate admission when closed.

The smoke tests check the full `world_label_rect()` including the pointer at initial, settled, ongoing, and rendered checkpoints, rather than checking only the allocated name-card rectangle. New captures use `smoke-after-*.png`; `smoke.png` and its byte-identical `smoke-before.png` copy remain untouched.

## Input bug found while checking the interactive entry

Real key-event smoke exposed an independent production configuration defect: Left and Right were assigned the Godot codes for Insert and Pause. The entry does not substitute a temporary InputMap.

The new `game/tests/test_directional_input.gd` records engine constants, loaded action mappings, real `Input.parse_input_event` behavior, founder displacement, cancellation of a real mouse-created route, key release, and focused Chat isolation for all eight WASD/arrow keys. It also rejects movement from Insert/Pause. No `Input.action_press` shortcut is used. Explicit calls to the actual player physics method make headless sampling deterministic; inputs still come solely from the parsed events and the shipped action map.

The preserved [BEFORE manifest](../../game/tests/output/directional-input/before-headless.json) has **56 checks / 10 failures**: both horizontal arrows fail action activation, movement, and route cancellation; Insert/Pause each incorrectly activate movement and move the founder. WASD, Up/Down, actual ground route creation, release handling, and focused Chat isolation pass. Godot 4.7.2 reports Left `4194319`, Right `4194321`, Insert `4194311`, Pause `4194313`.

Root corrected exactly those two `game/project.godot` event constants. The identical test then passed **56 headless checks / 0 failures** and **56 native-window checks / 0 failures**. [Headless AFTER](../../game/tests/output/directional-input/after-headless.json), [native AFTER](../../game/tests/output/directional-input/after-native.json), and all logs sit beside the preserved failing BEFORE. The old combined runtime checkpoint remains frozen and does not claim to include this later correction.

## Final showroom evidence

- **16 headless checks / 0 failures**, **25 native checks / 0 failures**. [Native manifest](../../game/tests/output/passive-showroom/smoke-native.json).
- [Initial native frame](../../game/tests/output/passive-showroom/smoke-after-initial.png): actors remain at the original starting poses. Mina's complete callout is `(336,477,64,40)`; Theo's is `(653,542,72,32)`. Both cards and pointers are clear of the toolbar. Therefore the fix is not merely an artifact of the actors later walking away.
- [Settled native frame](../../game/tests/output/passive-showroom/smoke-after-settled.png): the same two complete callouts remain correctly drawn; no detached tips.
- [Ongoing native frame](../../game/tests/output/passive-showroom/smoke-after.png): actors have advanced naturally, and both callouts remain above the toolbar at `(336,550,64,41)` and `(720,550,64,41)`.
- All three new 1280×720 captures inspected at native size. The run observed 42 late-layout ticks and 84 explicit label redraws.
- Actual Right-arrow movement, M preview, R authored-facing rotation, Escape cancellation, and U with empty history passed. Undo with committed history remains covered by the separate frozen passive fixture suite, not claimed as new coverage here.
- Worker transport/process absent throughout; local candidate permit revoked after teardown. Headless launch without `--smoke-test` deliberately exits **2**, before fixture construction.

The original `smoke.png` and `smoke-before.png` both retain SHA-256 `c4174cc2c1829ed23eebc7f3e6be49554678061fe41ffdb8da8d570437ef8c85`. Native logs have no script errors or ObjectDB leak warnings. This limited showroom proof is not production art approval or an assertion that all possible toolbar/actor configurations have been exhaustively sampled.

After the two-line mapping fix, Godot import, `validate_project.gd`, `test_complete_game.gd`, and `tests/run_all.gd` all completed **exit 0** with the worker disabled. Their logs are preserved under `game/tests/output/directional-input/`; the two gameplay suites report pass rather than a total assertion count. No broad visual/motion checkpoint was overwritten or rerun. Source freeze hashes: `project.godot` `fd09d6dd9625ad876f3877e5499d17f83725a465cc2859e15290211ed07827dd`; `play_passive_furniture.gd` `1b3af1b186fa437faca6b32b86c2613d1427c40e96cd47adf20cc489f0ca7cd4`; `test_directional_input.gd` `e9f67a0cb1c6717cbbf1859512b175819ef8da2306c5980de730da5cef59530f`.

## Replay

With `STARTUP_VALLEY_NO_WORKER=1`:

```sh
godot --headless --path game --fixed-fps 30 --script res://tests/test_directional_input.gd
godot --path game --fixed-fps 30 --script res://tests/test_directional_input.gd
godot --headless --path game --fixed-fps 30 --script res://tools/play_passive_furniture.gd -- --smoke-test
godot --path game --fixed-fps 30 --script res://tools/play_passive_furniture.gd -- --smoke-test
```

Interactive entry: `godot --path game --script res://tools/play_passive_furniture.gd`. It displays locally admitted candidate props but disables layout export and never starts a worker or opens personal game state. No production furniture catalogue opt-in was added.
