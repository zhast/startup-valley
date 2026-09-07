# Runtime presentation closeout checkpoint

2026-09-04, **10:38:25–10:39:22 UTC**. New evidence; prior AFTER-archive, shadow, picking, hover, lunch, founder, and window reviews remain frozen.

## Outcome

**All 22 affected headless suites, import, project validation, 27 native static captures, both motion recordings, ffprobe checks and strict motion/inventory validator passed.** Counted headless assertions: **40,610**, plus four suites that emit pass/fail without a count. These are granular geometry/state/pixel assertions, not 40,610 separate player scenarios.

The aggregate runner itself returned **1**, solely because its deliberately broad source guard noticed an unrelated new dev capture script changing. That raw result is retained; it has not been rewritten as exit 0. The precisely reviewed exclusion is below. No production or executed-checkpoint dependency changed during the snapshot, and no Godot command failed in the final run.

Evidence root: `game/tests/output/regression-checkpoint-runtime-closeout/`:

- `results.json`: original commands, logs, timestamps and before/after source hashes, including the raw guard warning.
- `analysis.json`: all 78 image comparisons, exact counts, excluded nondependency and bookkeeping limitations.
- `logs/`: complete output from each process.
- `visual-review/`: 27 fresh 1280×720 screens.
- `polish-audit/`: actual world/UI AVI streams, manifests, contact sheets, keyframes, checkpoints and runtime inventory. Their recorded paths point directly into this new checkpoint, not later-overwritable canonical outputs.

No worker/provider/credential/personal save or backend contract was exercised. `git diff -- harness contracts` remained empty. New staged materials after the catalogue's 113-source checkpoint are outside the runtime-only texture inventory.

## Affected headless surface

Godot 4.7.2 official, worker disabled. Fixed 60 FPS except service/archive/passive at fixed 30 FPS.

| Script under `game/tests/` | Final result |
|---|---:|
| `test_audit_output_scope.gd` | 15 / 0 failures |
| `run_all.gd` | Passed |
| `test_complete_game.gd` | Passed |
| `test_ui_flow_regressions.gd` | Passed |
| `test_graphics_regressions.gd` | Passed; rendered-only branch not run |
| `test_office_layout.gd` | 830 / 0 |
| `test_office_migration.gd` | 2,468 / 0 |
| `test_office_architecture.gd` | 477 / 0 |
| `test_office_layout_editor.gd` | 140 / 0 |
| `test_furniture_directions.gd` | 429 / 0 |
| `test_workstation_facing.gd` | 249 / 0 |
| `test_world_ui_presentation.gd` | 468 / 0 |
| `test_window_presentation.gd` | 56 / 0 |
| `test_polish_inventory_layers.gd` | 11 / 0 |
| `test_grounded_shadow_x_follow.gd` | 21,057 / 0 |
| `test_station_hover.gd` | 288 / 0 |
| `test_lunch_standing.gd` | 2,238 / 0 |
| `test_founder_occlusion.gd` | 27 / 0 |
| `test_passive_furniture.gd` | 850 / 0 |
| `test_service_furniture.gd` | 1,592 / 0 |
| `test_archive_production.gd` | 1,979 / 0 |
| `test_modular_office.gd` | 7,436 / 0 |

The headless graphics suite originally failed because it still asserted the removed sitting-sheet LUNCH fallback. Root corrected only that stale test to check standing locomotion, native 48×80 region, and standing shadow, then this final run passed. The first failed attempt remains in `attempt-1/`; no production fix was made to satisfy the old assertion.

This selection covers changed actor shadow/pose gates, real alpha/depth picking and hover, lunch, founder occlusion, decorative admission/factory, archive/service geometry/navigation/editor, and current gameplay/UI integration. The larger unchanged calibrated-source oracles and unrelated UI styling suites were not redundantly rerun. It is not a live-worker, paid evaluation, crash-recovery, or real-save restoration test.

## Native evidence and visible changes

Independent ImageMagick absolute-error comparison against `regression-checkpoint-after-archive` examined **78 full-resolution PNGs**: 27 static, 18 world keyframes, and 33 UI keyframes/checkpoints. **75 are pixel-identical**; every difference is recorded in `analysis.json`.

- **All 27 static images are pixel-identical.** The already reviewed architecture, notebook corners, fonts, actions, reader and static attention states have not visually regressed in these fixtures. This is exact image evidence, not a claim that every old asset is now ideal.
- **World lunch is the sole changed world keyframe.** `world/schedule-cycle-middle.png` changes 3,176 pixels. Mina and Theo now stand beside the lounge at approximately (336,432) and (368,432), instead of floating in a seated work pose without a chair. Their feet/shadows remain on the floor and the label avoids their faces. This is an honest standing fallback, **not** a new supported lounge-seating animation.
- **Two UI rail samples differ locally.** `team-drawer-controls-middle.png` changes 1,692 pixels, confined to the Mina portrait area (1183,100,64,88); `...-end.png` changes 4,764 pixels inside Theo's rail card (1168,229,94,143). Inspected both at native size: framing, content, targets and surrounding geometry remain intact. These transient rail presentation samples are not byte-identical; no new source-art or layout approval is inferred from them.
- **All other UI keyframes/checkpoints are identical.** Native inspection additionally confirmed the answered approval card has no stale world approval cue, and the pending approval and artifact frames remain clear.

Fresh native images directly inspected by the checkpoint owner: `visual-review/office-hires-4.png`, `ui-journal-approval.png`, `ui-artifact.png`; world `schedule-cycle-middle.png`; UI `team-drawer-controls-middle.png`, `team-drawer-controls-end.png`, and `journal-and-approval-approval-answered.png`. The remaining exact matches reuse the documented native visual review of the frozen AFTER-archive images rather than falsely claiming another fresh manual review of every unchanged image. The company agent also independently inspected **all 18 new world keyframes**: lunch standing is correct, writing/failure cues and nameplates are separated, archive sorting remains clear, and no new depth/growth clipping was found. This was native keyframe review, not continuous movie playback.

### Motion and inventory

| Stream | Actual ffprobe result |
|---|---|
| `world.avi` | 1280×720, 30 FPS, 2,455 frames, 81.833333 seconds |
| `ui.avi` | 1280×720, 30 FPS, 1,128 frames, 37.6 seconds |

Six scenarios per movie; all expected start/middle/end files and six contact sheets per suite are present. UI has 15 additional checkpoints and **54 passing checks**. Actor-cell safety checks: **5,043 world**, **2,922 UI**. The strict validator confirms expected states, distinct sampled motion, real UI dispatch ordering, preview-before-promotion, approval clearing and retry/error/recovery checkpoint order.

Inventory: **169 runtime textures, 20 live sprites, all 17 expected furniture layers, three character atlases, seven font records, zero flags**. The production archive's five actual layers are enumerated rather than inferred from a total count.

### Remaining limits, not newly approved art

- The ordinary production fixture still uses legacy desk/coffee/research/approval/prototype artwork. Different top-plane depths and density remain visible, e.g. coffee near (84,120), desks around (284,184), research near (884,124). The passed framework does not approve staged replacements.
- Default-off calibrated shadow/desk features and passive candidates are intentionally absent from normal production screenshots. Their focused tests prove isolation/admission; their standalone native studies are separate.
- The growth movie still tests prop stages after removing employees, not a complete hiring UI journey. In `world/job-state-cycle-end.png`, the old “Mina finished / launch-brief.md ready” toast at approximately (24,19)–(356,100) coexists with a newer Needs retry state. The harness shows the completed job's toast, then starts a distinct failure job and fails it 20 frames later (`capture_polish_audit.gd:216`). This remains a confusing sequential fixture carryover; it is not evidence of contradictory state for the same job, nor grounds for a universal no-stale-toast claim.
- Movies were validated and sampled, not watched frame-by-frame in real time. Current OS/window-size evidence is the separate `RUNTIME_WINDOW_REVIEW.md` (232 rendered checks), not newly repeated here.

## Snapshot chronology and preservation

1. First checkpoint attempt stopped on the stale lunch test. Its log/results were preserved; root changed only the obsolete assertion.
2. Company froze passive production and its 850-check headless test. This combined source snapshot and its movies use that version.
3. A concurrent standalone passive native replay found a **test-only allocated-label-bound** failure: 935 checks / 1 failure. An initially overbroad report-preservation map temporarily restored its prior manifest. The actual 935/1 file was recovered byte-for-byte, restored to its owner, and preserved here under `concurrent-passive-replay/manifest.json`; it is **not** represented as a passing headless result. No PNG/movie was overwritten. Future runner preservation now targets headless/export report paths only.
4. Company's later actual-line toolbar-bound assertion correction and standalone replay occur **after** this combined snapshot. They change no production behavior but must not be silently backdated into it.
5. The source guard recorded one nondependency change: `game/tools/capture_desk_finish_v2.gd`, from `b27fd2c39a1f6d56580665f8b25810fd4474ba4e28b98d84a25d2e889e37eecc` to `2a24544921ba6c9bb08fb2620f38aaa9681baab680fb3896fae09510fc5c2b62`. This is a separate new staged-material capture, not production code, an executed suite, or a checkpoint dependency. Root approved that explicit exclusion. All other existing-source hashes match. `analysis.json` records zero unexpected source changes while retaining the original aggregate warning.

## Reproduction

`node dev/tools/run_runtime_closeout.mjs` performs the serialized provider-free suite and captures; `node dev/tools/analyze_runtime_closeout.mjs` performs image/count analysis. The three existing audit scripts accept `STARTUP_VALLEY_AUDIT_OUTPUT_ROOT=res://tests/output/<checkpoint>` only as a strict descendant: absolute paths, traversal, empty/dot path segments, backslashes and control characters are rejected before IO. Their defaults remain unchanged. The guard's 15 cases pass, and all three entrypoints were independently verified to reject a traversal override with exit 2.

No commits, push, new assets, production opt-in or worker/backend mutation were part of this checkpoint. Renderer released after completion.
