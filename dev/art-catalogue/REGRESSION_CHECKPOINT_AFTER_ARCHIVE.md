# Production AFTER-archive regression checkpoint

2026-09-04. Test/source snapshot started **09:30:13 UTC**; graphical evidence completed and was frozen at approximately **09:32 UTC**, after the grounded-shadow owner's shared-source handoff. This is a new checkpoint. [BEFORE 08:49](REGRESSION_CHECKPOINT_0849.md), the 08:37 catalogue snapshot and the 09:12 provenance checkpoint remain historical evidence.

## Result and boundary

**PASS for the exercised regression surface; not blanket art or complete-game approval.** Godot import, project validation, **26 headless suites**, **27 isolated native static captures**, both existing motion recordings, their validator and scaling mathematics completed with exit 0. Counted assertions total **85,150**, plus four suites that emit pass/fail without counts. Many are granular pixel/geometry/state assertions, not 85,150 independent gameplay scenarios.

This checkpoint includes the production archive, the legacy cue/nameplate clearance and sentence-case copy fixes, canonical furniture-layer inventory, and the default-off calibrated grounded-shadow mechanism. No production file, catalogue, worker contract, credential, provider, personal save or source art was edited by this checkpoint. No worker or paid evaluation ran.

Frozen evidence: [results.json](../../game/tests/output/regression-checkpoint-after-archive/results.json), [27 static screens](../../game/tests/output/regression-checkpoint-after-archive/visual-review/), [world manifest](../../game/tests/output/regression-checkpoint-after-archive/polish-audit/world/manifest.json), [UI manifest](../../game/tests/output/regression-checkpoint-after-archive/polish-audit/ui/manifest.json), [copied headless reports](../../game/tests/output/regression-checkpoint-after-archive/headless/). Copies retain original `res://tests/output/…` references; the matching files are preserved in this checkpoint's mirrored directories. Do not substitute later canonical-output overwrites.

## Headless checks

Godot **4.7.2 official** on macOS, `STARTUP_VALLEY_NO_WORKER=1`. All suites used fixed 60 FPS except archive production, which used fixed 30 FPS. Import and validation preceded them. All 26 passed against the same existing-source hashes.

| Script under `game/tests/` | Fresh result |
| --- | --- |
| `run_all.gd` | Passed; no assertion count emitted |
| `test_complete_game.gd` | Passed; no assertion count emitted |
| `test_ui_flow_regressions.gd` | Passed; no assertion count emitted |
| `test_graphics_regressions.gd` | Passed; no assertion count emitted |
| `test_office_layout.gd` | 830 checks, 0 failures |
| `test_office_migration.gd` | 2,468 checks, 0 failures |
| `test_office_architecture.gd` | 477 checks, 0 failures |
| `test_modular_office.gd` | 7,436 checks, 0 failures |
| `test_office_layout_editor.gd` | 140 checks, 0 failures |
| `test_furniture_directions.gd` | 429 checks, 0 failures |
| `test_workstation_facing.gd` | 249 checks, 0 failures |
| `test_world_ui_presentation.gd` | 468 checks, 0 failures |
| `test_ui_foundation.gd` | 196 checks, 0 failures |
| `test_ui_drawer_redesign.gd` | 2,542 checks, 0 failures |
| `test_ui_company_redesign.gd` | 3,668 checks, 0 failures |
| `test_reader_hud_redesign.gd` | 203 checks, 0 failures |
| `test_window_presentation.gd` | 56 checks, 0 failures |
| `test_polish_inventory_layers.gd` | 11 checks, 0 failures |
| `test_service_furniture.gd` | 2,656 checks, 0 failures |
| `test_archive_production.gd` | 1,975 checks, 0 failures |
| `test_calibrated_work_vfx.gd` | 20,031 checks, 0 failures |
| `test_calibrated_thinking.gd` | 8,519 checks, 0 failures |
| `test_calibrated_workstation.gd` | 6,684 checks, 0 failures |
| `test_seat_transition.gd` | 4,671 checks, 0 failures |
| `test_locomotion_export.gd` | 545 checks, 0 failures |
| `test_grounded_work_shadow.gd` | 20,896 checks, 0 failures |

The first 17 are the same broad suite selection as BEFORE. The additional nine exercise complete layer discovery, actual archive/service routing and safe turns, directional workstation gates, quiet-thinking reuse, seat-transition interruption, cue/callout placement, locomotion gutters and grounded-shadow safeguards.

Headless graphics tests skip their rendered-only corner branch despite their generic “rendered corners” success text. This report does not count that branch as executed. `capture_typography_scaling.gd -- --validate-only` additionally passed **8 mathematical checks**; no new fullscreen or resize raster capture was performed. The fresh world-UI count is **468 headless**, not the **480** including rendered checks in the coordinator's separate run.

The archive/service tests use null transport before GameMain is ready and exercise physical routes, not endpoint teleportation. Archive checked **1,590 actual founder physics ticks**; service checked **1,184**. Their assertion totals have grown since their earlier owner reports, so historical counts are not rewritten or presented as this run. Shared-shadow tests prove the opted-in calibration gate and unchanged legacy behavior; the ordinary production screenshots do not enable that calibration flag.

No harness test was needed for changed backend code: `git diff -- harness contracts` was empty. This is not a replacement for lifecycle, provider, real-save or offline-worker evaluation suites.

## Native static review: all 27 screens

Each fresh 1280×720 image was inspected individually at native scale, not solely as a reduced contact sheet. No new missing texture, exposed black backdrop, menu-corner corruption, clipped essential action, or archive-related actor/UI overlap was found in these frames.

| Screens under the frozen static directory | Outcome |
| --- | --- |
| `office-hires-0.png` through `office-hires-4.png` | Continuous architecture and unchanged furniture placement. Archive appears from the first hire at approximately **(96,352,96,96)**; its top/front/plinth/insert align without a visible seam. Stage 3 intentionally shares stage 2's current furniture. Remaining legacy families are not replaced by candidate artwork. |
| `ui-team-rail.png`, `ui-founder-hud.png`, `ui-world-speech.png` | HUD and paper labels remain readable. Founder interaction prompt is separated from Mina's name/status. **“To seat”** now uses sentence case at roughly **(243,632)**. Generic bounded speech remains intentional. |
| `ui-chat.png`, `ui-chat-long.png`, `ui-chat-active-readonly.png` | Face miniature, readable message paper and contextual work-order action fit. Active chat links to Activity instead of changing dispatch meaning. The partial old message at the top of long history is intentional scroll clipping. |
| `ui-chat-to-assignment.png`, `ui-work.png`, `ui-keyboard-focus.png` | Full title, purpose field, attachment action and fixed budget/start footer remain distinct. Collapsed attachment is wholly inside the reading surface at approximately **(807,452,318,44)**. Long draft content is bounded inside its scrollable text editor. |
| `ui-journal-active.png`, `ui-journal-approval.png`, `ui-journal-promotion.png` | State, approval, update/cancel, file preview and promotion controls fit. Fixed spend footer keeps paper clearance. No thin clipped action fragments at the viewport edges. |
| `ui-completion-memo.png`, `ui-notification-dismissed.png` | Toast at **(24,18)** is readable and removed by the explicit dismissed fixture. |
| `ui-studio.png`, `ui-studio-empty.png` | File row/action and native **62×47** tray remain legible; Studio header does not masquerade as an employee portrait. |
| `ui-artifact.png` | One notebook frame, readable heading/list/body hierarchy, scroll rail and close focus; underlying world labels are suppressed. |
| `ui-empty-team.png` | Full-height paper with centered onboarding and accessible Journey/hire actions; no former half-height bare-wood gap. |
| `ui-off-hours.png`, `ui-journal-queued.png` | Off shift, queued and working remain separate. “Queue for 08:00” and queued-only controls fit. |
| `ui-connect.png`, `ui-error.png` | Empty key submission is disabled. Connection-lost recovery offers Reconnect and preserves the saved-key reassurance. No disconnected worker detail replaces job status. |

The normal archive remains South in these scenes. Its four approved service directions and individual runtime layers are exercised by the fresh headless archive test; the prior [four-view production native review](ARCHIVE_PRODUCTION_REVIEW.md) remains the separate evidence for all-direction artwork. This broad static pass does not pretend to render every archive direction again.

## Motion and inventory

Independent `ffprobe` checked the copied actual movie streams:

| Recording | Native properties and evidence |
| --- | --- |
| [world.avi](../../game/tests/output/regression-checkpoint-after-archive/polish-audit/world.avi) | **1280×720, 30 FPS, 2,455 frames, 81.833333 s**; 6 scenarios, 18 keyframes, 6 contact sheets; **5,043 actor-cell checks** |
| [ui.avi](../../game/tests/output/regression-checkpoint-after-archive/polish-audit/ui.avi) | **1280×720, 30 FPS, 1,128 frames, 37.6 s**; 6 scenarios, 18 keyframes, 6 contact sheets, 15 extra checkpoints; **2,922 actor-cell checks** |

All 12 scenarios have distinct sampled frames and expected end-state records. All **54 UI checks** passed, including actual input/dispatch order, disabled duplicate submission, preview-before-promotion, ledger return and approval-result visibility. The validator confirms evidence completeness, not an aesthetic score.

The updated [inventory](../../game/tests/output/regression-checkpoint-after-archive/polish-audit/asset-inventory.json) records **169 textures, 20 live sprites, 17 expected and present furniture layers, 3 actor atlases and 7 font records**, with **0 flags**. The live archive has all five actual layers: Carcass, Top, Front, Plinth and Insert. This is no longer inferred from a loose total-sprite threshold. The dedicated 11-check negative test rejects missing layers, non-native scale, flips, offset errors and mismatched regions.

Inspected all **18 world start/middle/end keyframes** across locomotion, seated/idle/wander, job lifecycle, schedules, depth and growth. Also inspected these **12 native UI frames/checkpoints**:

- `team-drawer-controls-middle.png`
- `chat-and-work-order-chat-waiting.png`, `chat-and-work-order-end.png`
- `work-controls-middle.png`, `work-controls-assignment-disabled.png`
- `journal-and-approval-approval-ledger.png`, `journal-and-approval-work-details-restored.png`, `journal-and-approval-approval-answered.png`
- `delivery-studio-reader-reader-scrolled.png`, `delivery-studio-reader-delivery-promoted.png`
- `queued-errors-and-overflow-worker-reconnecting.png`, `queued-errors-and-overflow-worker-recovered.png`

Work details restores with its whole control at approximately **(807,191,306,44)** and its first activity entry visible; no approval-button slivers remain above it. Answering approval returns the whole result card near **(807,251,306,66)** and removes the stale world approval cue. The ledger's spend footer remains fixed. Pending recovery reads **“Reconnecting…”**, disables retry and returns to **Queued**, not Working. Reader and timeline text scroll intentionally; no essential interactive control is half-clipped in these reviewed rest states.

## BEFORE findings: resolved versus retained

| Prior finding | AFTER disposition |
| --- | --- |
| **B01 / P1 legacy projection/material inconsistency** | **Archive portion resolved** by the active modular asset at **(96,352)**. Existing coffee near **(84,120)**, desks, research near **(884,124)**, approval and prototype still use old art. Their differing top-plane depths/detail density remain visible in `office-hires-4.png`; passing this regression does not approve their staged replacements. |
| **B02 / P2 legacy typing cue/nameplate crowding** | **Resolved in the fresh native frame.** `world/job-state-cycle-middle.png` places Mina's paper at about **(238,126,62,30)**, clearly left of the typing cue near **(336,166)**. [GameMain](../../game/world/main.gd#L637) now includes actual visible cue bounds via [EmployeeAvatar](../../game/actors/employee_avatar.gd#L204), rather than calibration-only bounds. The world-UI tests cover the corresponding collision behavior. |
| **B03 / P3 “To Seat” copy** | **Resolved.** Fresh `ui-founder-hud.png` reads “To seat”; [presentation_label](../../game/actors/employee_avatar.gd#L649) preserves sentence case. No artwork change was needed. |
| **B04 / growth harness limitation** | **Retained and explicit.** The motion growth fixture removes employee actors and advances furniture stages. Its empty rail is not proof of the hiring journey. Separate complete-game input tests passed. |
| **B05 / rapid synthetic job/toast overlap** | **Retained and explicit.** `world/job-state-cycle-end.png` still shows a previous completed-job toast while the next injected failure says Needs retry. The harness starts the second job before the six-second toast expires. This is not newly discovered persistent save contamination; no such real-save test ran here. |

There is no new regression requiring a production fix from this checkpoint. Existing unapproved workstation contact, motion and other-family art gaps remain in their dedicated reviews. The default-off [grounded-shadow study](GROUNDED_WORK_SHADOW_REVIEW.md) has separate native before/after proof; this checkpoint reran its headless mechanism test and checked default production output after that shared change, not the opted-in study's entire movie.

## Snapshot integrity and reproduction

HEAD remained `9d25e25ef26aa4a63b6cc43a337bfeac577d5bb0` with the existing dirty overnight worktree. **HEAD alone is not the tested snapshot.** Results JSON records before/pre-render/after SHA-256 snapshots for **326 existing production source/data/runtime image and dev/test script files**. All 326 remained byte-identical from before import through capture freeze. Three newly added role-storage dev scripts are recorded separately as unexercised additions, not a covert shared-source change.

Results also records full command/stdout/exit data, 12 copied fresh headless result files, and hashes/byte sizes for **108 evidence files**: **90 PNGs**, 2 movies, 2 scenario manifests, inventory, 12 headless results and the generated output ignore marker. PNG dimensions are recorded. No duplicate-byte copies are counted as new independent tests.

The coordinator authorized a later, separately gated horizontal shadow-projection refinement **after this source/evidence freeze**. This checkpoint covers the first physical-foot grounded-shadow policy only; it does not include or validate that subsequent refinement. Its later source changes must not be compared to this snapshot as if they had existed during these tests.

Use the Godot executable at `/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot`, from the repo root:

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tools/validate_project.gd
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --fixed-fps 60 --script res://tests/run_all.gd
# Repeat for the other listed suites; archive production uses --fixed-fps 30.
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 60 --script res://tools/capture_visual_review.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/world.avi --script res://tools/capture_polish_audit.gd -- --suite=world
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/ui.avi --script res://tools/capture_polish_audit.gd -- --suite=ui
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tools/validate_polish_audit.gd
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tools/capture_typography_scaling.gd -- --validate-only
```

Limits: no new Company/Settings rendered expansion, fullscreen/window-resize raster proof, OS hardware-input playtest, real worker restart/crash, provider/evaluator run or personal-save restoration. Input tests inject real Godot events; this is not human hardware input. Movies were recorded, validated and sampled as listed—not watched frame-by-frame. No blanket “no glitches anywhere” or complete overnight-goal acceptance is implied.
