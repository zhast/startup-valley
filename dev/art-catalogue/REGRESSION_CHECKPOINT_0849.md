# Production regression checkpoint — 2026-09-04 08:49 UTC

## Result and boundary

**PASS for the exercised production regression surface; not blanket art approval.** Godot import, project validation, all 17 selected headless suites, 27 isolated static captures, both existing motion suites and their validator completed with exit 0. No production source, protocol, provider, credential, personal save, or catalogue was modified by this checkpoint. Existing uncommitted work was preserved.

This is the **before-archive-activation** baseline. The production source was held stable through both recordings; the archive owner was released only after the evidence copy completed. Subsequent archive edits must be tested separately against these captures. HEAD was `9d25e25ef26aa4a63b6cc43a337bfeac577d5bb0` with the overnight working-tree changes on top; HEAD alone is not this source snapshot.

Frozen evidence: [results.json](../../game/tests/output/regression-checkpoint-0849/results.json), [static directory](../../game/tests/output/regression-checkpoint-0849/visual-review/), [world manifest](../../game/tests/output/regression-checkpoint-0849/polish-audit/world/manifest.json), [UI manifest](../../game/tests/output/regression-checkpoint-0849/polish-audit/ui/manifest.json). Copied manifests retain their original `res://tests/output/polish-audit` references; the matching files are preserved under the checkpoint's mirrored `polish-audit` directory. Do not confuse a later overwrite of the canonical output with this snapshot.

## Headless verification

Godot 4.7.2 official, macOS, `STARTUP_VALLEY_NO_WORKER=1`. All test scripts used `--headless --path game --fixed-fps 60 --script res://…`. Import and project validation also passed. Counted assertions below sum to **19,104**, plus four suites that report pass/fail without a numeric assertion count.

| Script under `game/tests/` | Result |
| --- | --- |
| `run_all.gd` | `test_worker_walks_to_desk: passed` |
| `test_complete_game.gd` | Complete-game real-input tests passed |
| `test_ui_flow_regressions.gd` | Passed |
| `test_graphics_regressions.gd` | Passed; raster-only branches skipped in headless mode |
| `test_office_layout.gd` | 830 checks, 0 failures |
| `test_office_migration.gd` | 2,468 checks, 0 failures |
| `test_office_architecture.gd` | 477 checks, 0 failures |
| `test_modular_office.gd` | 7,436 checks, 0 failures; 0 rendered captures |
| `test_office_layout_editor.gd` | 128 checks, 0 failures; real injected input, previews, rejection, export/reload and undo |
| `test_furniture_directions.gd` | 429 checks, 0 failures; synthetic geometry, not directional art approval |
| `test_workstation_facing.gd` | 249 checks, 0 failures |
| `test_world_ui_presentation.gd` | 422 checks, 0 failures |
| `test_ui_foundation.gd` | 196 checks, 0 failures |
| `test_ui_drawer_redesign.gd` | 2,542 checks, 0 failures |
| `test_ui_company_redesign.gd` | 3,668 checks, 0 failures |
| `test_reader_hud_redesign.gd` | 203 checks, 0 failures |
| `test_window_presentation.gd` | 56 checks, 0 failures |

Additionally, `capture_typography_scaling.gd -- --validate-only` passed 8 mathematical scaling checks. This is **not** a new fullscreen or fractional-scale raster review.

No worker suite was run: `git diff -- harness contracts` was empty, and the task prohibits starting a real worker. New service/calibrated-fixture tests have their own owner reports; they are not substituted for these production suites.

## Static evidence and native inspection

`capture_visual_review.gd` now emits **27** isolated states, not the original 21. All 27 fresh 1280×720 images were inspected individually at native scale. No new missing art, exposed black backdrop, malformed menu corner, clipped essential button, actor/label overlap with the open drawer, or stale delivery notice across these fresh fixtures was found.

| Files under frozen `visual-review/` | Native review outcome |
| --- | --- |
| `office-hires-0.png`, `office-hires-1.png`, `office-hires-2.png`, `office-hires-3.png`, `office-hires-4.png` | Architecture remains continuous; native props stay inside the room. Stage 3 intentionally looks like stage 2 because no extra prop unlock occurs there. Remaining legacy projection/art differences listed below. |
| `ui-team-rail.png`, `ui-founder-hud.png`, `ui-world-speech.png` | HUD, rail and callout paper remain readable and separated. Existing `To Seat` capitalization and bounded generic speech fallback are visible, not new regressions. |
| `ui-chat.png`, `ui-chat-long.png`, `ui-chat-active-readonly.png` | Readable messages and native face miniature; correct work-order action and active-work banner. Top clipping of an old message in the long history is intentional scrolling, not a cropped action. |
| `ui-chat-to-assignment.png`, `ui-work.png`, `ui-keyboard-focus.png` | Title, purpose, attachment disclosure and budget/footer fit. Attachment control at approximately `(807,452,318,44)` is wholly above the footer seam. Long text remains inside its editable scrolling field. |
| `ui-journal-active.png`, `ui-journal-approval.png`, `ui-journal-promotion.png` | Current state, approval, updates/cancel, preview-before-promotion and fixed spend footer remain visible. No thin fragments of buttons at the reading edge. |
| `ui-completion-memo.png`, `ui-notification-dismissed.png` | Toast fits at `(24,18)` and is absent from dismissed fixture; attention badge is removed after the scripted review. |
| `ui-studio.png`, `ui-studio-empty.png` | File row and native 62×47 tray fit; Studio is not represented as a folder inside an employee portrait frame. |
| `ui-artifact.png` | Single reader frame, antialiased body text, clear document structure, scrollbar and close focus. World labels are suppressed under the modal. |
| `ui-empty-team.png` | One full-height paper surface, centered onboarding and visible Journey/hire actions; no previous half-height paper/bare-wood gap. |
| `ui-off-hours.png`, `ui-journal-queued.png` | Off-shift versus queued status is distinct; `Queue for 08:00` and queued-only Activity controls are readable. |
| `ui-connect.png`, `ui-error.png` | Empty key save is disabled; connection-lost recovery offers a real visible Reconnect action without soliciting another saved key. |

## Motion evidence

Both recordings were regenerated using the existing harness, not a separate mockup. Independent `ffprobe` confirmed the actual movie properties:

| Recording | Result |
| --- | --- |
| [world.avi](../../game/tests/output/regression-checkpoint-0849/polish-audit/world.avi) | 1280×720, 30 FPS, **2,455 frames / 81.833333 s**, 6 scenarios, 18 start/middle/end PNGs + 6 contact sheets |
| [ui.avi](../../game/tests/output/regression-checkpoint-0849/polish-audit/ui.avi) | 1280×720, 30 FPS, **1,128 frames / 37.6 s**, 6 scenarios, 18 start/middle/end PNGs + 6 contact sheets + 15 explicit checkpoints |

All 12 scenarios report distinct sampled frames and expected end conditions. The UI manifest contains **54 passing checks** including checkpoint writes. The world harness checked 5,043 actor cells; the UI harness checked 2,922. `validate_polish_audit.gd` passed: both evidence sets, required dispatch order and checkpoint assertions are complete. The runtime inventory contains 145 textures, 12 live sprites, all 3 character atlases and 7 font records, with no flags under its current checks.

Inspected **all 18 native world keyframes**, covering founder locomotion, employee idle/seated/wander, job states, schedules, depth/occlusion and office growth. Also inspected these 12 native UI keyframes/checkpoints:

- `team-drawer-controls-middle.png`
- `chat-and-work-order-chat-waiting.png`, `chat-and-work-order-end.png`
- `work-controls-middle.png`, `work-controls-assignment-disabled.png`
- `journal-and-approval-approval-ledger.png`, `journal-and-approval-work-details-restored.png`, `journal-and-approval-approval-answered.png`
- `delivery-studio-reader-reader-scrolled.png`, `delivery-studio-reader-delivery-promoted.png`
- `queued-errors-and-overflow-worker-reconnecting.png`, `queued-errors-and-overflow-worker-recovered.png`

In particular: restored Work details starts with its **whole** control at about `(807,191,306,44)` and shows the first activity entries without approval-button slivers above it. Answering approval returns the complete status card to about `(807,251,306,66)` and removes the stale world approval cue. The ledger keeps the spend footer at the same footprint; Back restores the prior content. Pending recovery displays `Reconnecting…` with disabled retry, and recovery returns to a queued—not running—state. Reader text scrolling and bounded multiline histories are intentional viewport clipping, not failed menu geometry.

## Existing issues and test limitations, not silently fixed

| ID / severity | Evidence and source | Disposition |
| --- | --- | --- |
| B01 / P1 art | `office-hires-4.png`: coffee at roughly `(84,120,120,92)`, archive `(78,348,133,87)`, three legacy desks, research/approval/prototype benches still use their old top-plane depths and inconsistent material density. New desk/chair/computer candidates are intentionally absent. | Existing art issue, not caused by service/cue code. Keep this baseline for archive replacement comparison; remaining families need their own reviewed activation. Passing placement tests cannot establish coherent projection. |
| B02 / P2 legacy cue clearance | `world/job-state-cycle-middle.png`: Mina's nameplate pointer at approximately `(332,155–164)` crowds the tiny typing cue near `(336,166)` directly above the bun. There is little visible separation. `GameMain._world_ui_obstacles()` around line 637 only adds **admitted calibration** cue bounds; default legacy cues return an empty rectangle by design. | Existing legacy clearance limitation; do not broaden the calibrated-only fix within this checkpoint. A later legacy cue/label clearance pass should use actual cue bounds and preserve event meaning. No essential name text is clipped in this image. |
| B03 / P3 copy | `ui-founder-hud.png`: `To Seat` at approximately `(242,632)`. `EmployeeAvatar.presentation_label()` line 632 falls back to `state_label().capitalize()`, which title-cases each word. The same fallback and `to seat` text exist at HEAD before overnight changes. | Confirmed old copy inconsistency, not regression. Later narrow sentence-case wording fix; no need for artwork. |
| B04 / harness limitation | `world/office-growth-*.png` shows furniture unlock stages but an empty rail. `_capture_office_growth()` explicitly removes employee actors, then increments prop hire count. | Tests furniture growth only; it is not proof of a complete hiring UI journey. Complete-game tests separately cover the player flow. |
| B05 / harness limitation | `world/job-state-cycle-end.png` simultaneously shows an earlier `Mina finished` toast and `Needs retry` for a subsequent simulated failure. Lines 209–226 directly inject completion/promotion and start a new fixture job before the 6-second toast interval in `FounderHUD.show_delivery()` expires. | Do not label this as a newly persistent stale-save bug. It is a rapid two-job synthetic fixture with different job IDs; a future harness revision should explicitly record which job owns each notice or separate phases. Static fixtures are isolated and the notification-dismissal input tests passed. |

The new locomotion normalization is an intentional runtime pixel change, not a claim of identical old baselines. Inspected native walking cells show no previous-row boot islands above Mina's bun. This checkpoint does not replace the dedicated alpha-band/export tests or declare every animation frame visually perfect.

## Reproduction and snapshot identity

From the repository root, using the listed Godot 4.7.2 executable (`godot` below is shorthand):

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tools/validate_project.gd
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --fixed-fps 60 --script res://tests/run_all.gd
# Repeat the preceding headless form for each of the other 16 test scripts above.
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 60 --script res://tools/capture_visual_review.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/world.avi --script res://tools/capture_polish_audit.gd -- --suite=world
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/ui.avi --script res://tools/capture_polish_audit.gd -- --suite=ui
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tools/validate_polish_audit.gd
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tools/capture_typography_scaling.gd -- --validate-only
```

Results JSON records complete command outputs and SHA-256 values for the seven relevant shared source/data files. Before activation, `game/data/furniture_catalog.json` was `98811e7adf9726c22cc0165d5775ec826a25f65db781691bab05cf7c18ff783a` (also matches HEAD's old catalogue); `game/world/main.gd` was `063df3a37a1f45913cf7c50b3d0b9a840064f469a070f30ca045b9fe6039203e`. These hashes were checked before releasing the production-edit freeze.

No rendered Company/Settings expansion, full-screen/window-resize raster rerun, OS hardware-input playtest, paid evaluation, worker crash process test or real-save restoration was performed here. UI input tests inject actual Godot input events; they are stronger than calling only handlers, but are not human hardware input. The movies were validated and sampled as documented—not watched frame-by-frame in real time. This checkpoint supports safe continuation; it does not close the overnight art goal.
