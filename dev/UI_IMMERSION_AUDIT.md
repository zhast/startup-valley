# UI immersion and component consistency audit

Date: 2026-09-03. Final scoped acceptance of `9d25e25` plus the uncommitted
reconnect-copy fix and its regression/audit additions.

## Implementation outcome

I01–I12 are resolved within the tested two-employee desktop slice. The shared
notebook material system is integrated into production, not a preview overlay.
Native visual review and interaction/geometry/raster checks are separate parts
of this acceptance; neither texture filenames nor passing test counts alone
establish aesthetic quality. The result is ready for the user's final visual
approval, which is not implied by this report.

The approved C typography, palette, portrait identities, office assets and HUD
composition remain. Work details, usage, attachments, navigation and close
controls now share stepped corners, restrained lighting and stable geometry.
Fields read as inset paper; cards/dialogue use quiet raised paper. Tabs attach
to the page instead of looking like four orange consequence buttons. World
tags and speech have native pointers, avoid important scenery, and suppress
duplicate selected-employee information.

No worker contracts, persistence, provider behavior, security boundaries or
game mechanics were changed. The diff from the pre-integration checkpoint
`4b6a4e8` contains no changes under `harness/`, `contracts/`, bundled font assets,
office assets or logical game data. `game_fonts.gd` changes only tooltip skin;
font roles are unchanged. World changes read visual bounds for UI placement
and change attention paint ownership, not navigation or event timers.
All fixtures disable the worker; no paid calls or real saves were used.

The requested checkpoint commits are saved locally. This final report and the
narrow reconnect-copy/test changes remain uncommitted; no additional commit or
push is part of acceptance.

## Finding-by-finding disposition

Coordinates are `(x,y,width,height)` in native 1280×720 screenshots. Before
links retain the original evidence; the historical audit follows this section.

| Finding | Implemented correction and classification | Before → current evidence / acceptance |
| --- | --- | --- |
| I01 — button families | Reused the slim control master for lighter quiet/disclosure controls. Primary, secondary, danger, disclosure and navigation remain distinct while sharing corner construction, palette and press behavior. Code + normalized existing art. | [Before Activity](../game/tests/output/ui-material-audit/ui-journal-active.png) → [current Activity](../game/tests/output/ui-material-audit-after/ui-journal-active.png). Work details `(806,498,320,44)` and Usage details `(970,651,150,44)` now belong to the same family as Send update. [Seven-state specimen](../game/tests/output/ui-material-specimen/manifest.json) and foundation checks cover state geometry, source-corner pixels and input. |
| I02 — detached/duplicate employee information | Shared anchored name/speech/attention paper with a fixed eight-pixel pointer. Selected drawer suppresses redundant identity/status. Short intentional ambient sentences replace truncated memory excerpts without rewriting employee memory. Answered approval clears paint immediately, retaining physical pose/timing. Code + narrow authored pointer. | [Before speech](../game/tests/output/ui-material-audit/ui-world-speech.png) → [complete speech clear of the desk](../game/tests/output/ui-material-world/speech-complete-desk-clear.png). [Pending cue](../game/tests/output/ui-material-world/drawer-live-approval-cue.png), [delivery cue](../game/tests/output/ui-material-world/drawer-live-delivery-cue.png), and [answered approval](../game/tests/output/polish-audit/ui/journal-and-approval-approval-answered.png) show distinct states. Real Approve/reopen/tool-resume tests verify no stale cue or timer change. |
| I03 — pasted-on interaction prompt | One painted paper surface, native 26×28 E keycap and target pointer; the clickable body remains 112×44. Placement tests actors, furniture faces, HUD, rail, drawer and other callouts. Code + hand-authored key/pointer. | [Before prompt](../game/tests/output/ui-material-audit/ui-founder-hud.png) → [current prompt](../game/tests/output/ui-material-world/prompt-desk-clear.png), body `(403,472,112,44)`, complete painted bounds `(394,472,121,44)`. Hover/press/focus and real E/click tests pass; a crowded optional prompt may hide, but E still works. |
| I04 — paper hierarchy | Native inset fields/read-only fields, lightly raised cards, related employee/founder bubbles and company cards. Reader keeps one notebook surface without an inner decorative frame. Code + small pixel edge parts. | [Before Assign](../game/tests/output/ui-material-audit/ui-work.png) → [current Assign](../game/tests/output/ui-material-audit-after/ui-work.png); [Chat](../game/tests/output/ui-material-audit-after/ui-chat.png), [Settings](../game/tests/output/ui-material-audit-after-shell/pause-settings.png), [summary](../game/tests/output/ui-material-audit-after-shell/day-summary.png), [reader](../game/tests/output/ui-redesign/reader-hud/reader-top.png). Native inspection confirms distinguishable well/card edges and quiet text centers, not nested heavy wood. |
| I05 — clipped usage/work controls | Usage opens a dedicated ledger; pinned spend remains `(794,639,344,69)`. Back/Escape restores previous Activity context. Work details deliberately aligns at the top reading edge, including a one-event approval timeline. Explicit approval returns to the complete outcome. Code-only layout/state. | [Before clipped approval](../game/tests/output/ui-material-audit/approval-usage-expanded.png) → [ledger](../game/tests/output/ui-material-audit-after/approval-usage-expanded.png) → [restored Work details](../game/tests/output/ui-material-audit-after/work-restored-after-usage.png), toggle `(806,191,308,44)`. [Short approval history](../game/tests/output/ui-redesign/drawer/approval-details-restored.png) and [resolved approval](../game/tests/output/ui-redesign/drawer/approval-resolved.png) prove the newly caught top-edge defect is also fixed. All intersecting interactive controls fit at these deliberate resting positions. |
| I06 — attachment state mismatch | One expanded state drives chevron, heading, picker and trailing paper. Guarded deferred reveals ignore closed/changed drawers and show the complete title→brief→attachment section. Template/employee changes synchronize state; collapsing restores the compact form. Code-only state/layout. | [Before round-trip](../game/tests/output/ui-material-audit/attachment-after-template-roundtrip.png) → [current round-trip](../game/tests/output/ui-material-audit-after/attachment-after-template-roundtrip.png): both arrow and content closed. [Expanded attachment](../game/tests/output/ui-redesign/drawer/attachment-revealed.png) has complete title at y191, toggle `(807,366,306,44)` and picker `(807,447,306,44)`, with no fragment of the purpose dropdown above it. Real popup keyboard selection, rapid open/close, reopening and employee switching pass. |
| I07 — tabs versus actions | Open-bottom notebook-tab silhouette and a narrow Vermilion selected rule; labels and 44px targets preserved. Code + normalized narrow tab parts. | [Before Chat](../game/tests/output/ui-material-audit/ui-chat.png) → [current Chat](../game/tests/output/ui-material-audit-after/ui-chat.png). Four tabs remain `(794,147,344,44)` overall. They attach to the page; Start/Ask/Approve retain consequence-button faces. Repeated restyling does not add signal connections. |
| I08 — close/focus mismatch | Native 16×16 close glyph in a 44×44 quiet-paper target; hollow inset stepped Indigo focus follows corners. Reader reserves 10px left ink clearance. Code + small authored glyph/focus outline. | [Before usage focus](../game/tests/output/ui-material-audit/usage-expanded.png) → [current ledger focus](../game/tests/output/ui-material-audit-after/usage-expanded.png); [close specimen](../game/tests/output/ui-material-specimen/close-focused.png); [reader keyboard focus](../game/tests/output/ui-redesign/reader-hud/reader-keyboard-focus.png). Actual Tab/Shift-Tab/Escape, focus trapping/return and native outline inspection pass. |
| I09 — dropdowns/tracks | Shared popup rim and selection paper, native check glyphs, matched track end caps/thumb depth, retained native slider thumb. Code + narrow normalized/authored parts. | [Before dropdown](../game/tests/output/ui-material-audit/assignment-dropdown-open.png) → [current dropdown](../game/tests/output/ui-material-audit-after/assignment-dropdown-open.png); [Settings](../game/tests/output/ui-material-audit-after-shell/pause-settings.png). Keyboard selection, disabled controls, context menus, sliders and document scrolling retain their behavior. |
| I10 — illegible miniatures | Reused unframed native 32×32 face crops; authored native 24×28 document, 32×24 folder and 16×16 close/check glyphs. Empty Studio renders its existing 62×47 tray without rescaling. Existing activity glyphs use a deliberate 36→18 exact-half reduction, not fractional framed-bust scaling. Art normalization + code. | [Before Chat](../game/tests/output/ui-material-audit/ui-chat.png) → [current Chat](../game/tests/output/ui-material-audit-after/ui-chat.png); [document](../game/tests/output/ui-redesign/reader-hud/reader-top.png); [native tray](../game/tests/output/ui-material-audit-after/ui-studio-empty.png), `(935,227,62,47)`. Native visual review and exact-size/filter checks pass. No new portraits or broad asset generation. |
| I11 — technical information hierarchy | Compact daily spend footer; deliberate ledger separates Today from Selected work and states “Real money, not company cash.” Human event labels keep raw identifiers in tooltips. Side-project, connection and active-chat copy is shorter. Studio leads with title/type/owner and exposes full paths on demand. Code-only hierarchy/copy using the shared kit. | [Before usage](../game/tests/output/ui-material-audit/usage-expanded.png) → [AI ledger](../game/tests/output/ui-material-audit-after/usage-expanded.png); [human activity](../game/tests/output/ui-material-audit-after/work-details-expanded.png); [Studio](../game/tests/output/ui-material-audit-after/ui-studio.png); [connection error](../game/tests/output/ui-material-audit-after/ui-error.png). Live usage refresh preserves footer and reading context; no fake progress or hidden billing consequence. |
| I12 — verification encoded old styling | Replaced flat-style-class expectations with role/material behavior, fixed geometry, rendered edge/ink checks and actual input. Added combined disclosure/live-refresh/short-timeline/rapid-close tests. Isolated evaluation fixtures no longer manufacture absent-worker errors; manifests separate logical expansion from in-tree visibility. Test/audit code. | [Drawer results](../game/tests/output/ui-redesign/drawer/results.json), [foundation results](../game/tests/output/ui-redesign/foundation/results.json), [UI motion checks](../game/tests/output/polish-audit/ui/manifest.json), [main manifest](../game/tests/output/ui-material-audit-after/manifest.json), [valid evaluating capture](../game/tests/output/ui-material-audit-after-shell/journey-evaluating.png). No requirement that a particular StyleBox class is inherently good; all affected screens also receive native visual review. |

## Final evidence coverage

The final production captures contain **37 main images (32 UI states + five
office stages), 14 company-shell states, and seven specimen states**. These are
46 UI-state captures, not 51 unique UI screens; stages two and three are identical.
All main/shell images and specimen states were inspected at native size by the
reviewing agents. The root reviewer also compared original/current problem
states and all seven specimens/five office stages. Contact sheets are indexes,
not substitutes for native review.

- [Main production manifest](../game/tests/output/ui-material-audit-after/manifest.json) / [contact sheet](../game/tests/output/ui-material-audit-after/contact-sheet.png): rail, Chat/long/read-only, chat-to-Assign, attachments/popup/focus, running/queued/approval/usage/combined details, delivery/promotion/dismissal, Studio/list/empty, reader, connection/error, founder-only and off-hours. Waiting/send feedback is additionally captured in the UI motion suite.
- [Company production manifest](../game/tests/output/ui-material-audit-after-shell/manifest.json) / [contact sheet](../game/tests/output/ui-material-audit-after-shell/contact-sheet.png): title, onboarding, available/revision/evidence, evaluating/retry, long error, Settings, closing, ordinary/large day summary and reset confirmation.
- [Production component specimen](../game/tests/output/ui-material-specimen/manifest.json): normal, hover, pressed, expanded/focused, close focus, quiet focus and actual open dropdown. Disabled and native miniature examples remain present throughout.
- Focused suites add 21 drawer, 17 company, 11 reader/HUD, 12 world-callout and five foundation captures. These overlap main coverage; their counts are not additional unique screens.

Real Godot `InputEvent` tests exercise mouse motion/down/up, keyboard popup
selection, text entry, focus navigation, disabled clicks, rapid close/reopen,
employee/tab changes, ledger Back/Escape, steering, approval, file preview,
promotion and reader scroll/reopen. Dispatch spies verify chat→`chat.send`,
assignment→`job.start`, Activity update→`job.steer`; no provider is invoked.
Styling refreshes bind feedback once. Press feedback is immediate; release is
80ms and existing drawer/modal transitions remain 120–160ms without control
scaling. Contrast checks sample actual textured text-safe interiors, including
pressed tint, and require 4.5:1. Pixel-edge review complements those checks.

Late visual review found and corrected four additional regressions: a tiny
rescaled Studio tray, the purpose dropdown's top-edge fragment after attachment
reveal, Approve/Deny fragments above a short expanded timeline, and a stale red
world cue after approval. The current evidence includes all four corrections.
Evaluation capture hydration was also fixed rather than concealing a fixture
worker error. These issues were not dismissed because earlier tests passed.
The final source review also caught “Reconnecting the local worker…” in a
transient state: it now says “Reconnecting…”. A real Retry click captures the
[pending connection](../game/tests/output/ui-redesign/drawer/worker-reconnecting.png),
checks disabled duplicate submission and retains a reachable Back action.
The first new motion assertion correctly failed because the fixture still
called the real worker-disabled rejection handler. Retry is now observed at
the same simulated boundary as other worker actions, with an explicit one-click
dispatch assertion before the pending capture and simulated successful response.
No production worker behavior was changed to make the fixture pass.

### Verification results

All listed suites exited successfully with zero failures on the integration.
The final one-line reconnect-copy change was then verified with fresh drawer,
UI-flow and UI-motion runs; unrelated component/world results are from the
unchanged integration code. Headless/rendered totals overlap and must not be
added as distinct coverage.

| Suite | Headless | Rendered / inspected evidence |
| --- | ---: | --- |
| Godot import and project validation | Passed | Runtime scenes, art, fonts/licenses and office stages valid |
| UI foundation | 196 checks | 200 checks, five captures; native corners, roles, contrast, input and bind-once |
| Drawer | 2,542 checks | 2,571 checks, 21 captures; real interactions and combined/dynamic states |
| Company | 3,668 checks | 3,702 checks, 17 captures; modal sizing/focus, busy navigation and refresh |
| Reader/HUD | 203 checks | 222 checks, 11 captures; Markdown/source/fallbacks/reopening and safe HUD ink |
| World presentation | 422 checks | 434 checks, 12 captures; anchored labels, placement, live attention and E/click behavior |
| Gameplay, complete-game and UI flow | Passed | Real-input assertions included; no live startup/worker run |
| Graphics regression | Passed | Rendered corner, workstation, seated-pose and scale-safe-feedback suite passed |
| Window policy | 56 checks | 174 scaling checks across five modes |
| Office architecture / layout | 477 / 830 checks | Existing world composition and validation preserved |
| Modular office / editor / migration | 7,436 / 128 / 2,468 checks | Existing layout/input regression suites preserved |
| Motion audit | Validator passed | Six world + six UI scenarios; 2,455 + 1,128 movie frames at 30FPS |
| Art inventory / builder | No inventory flags | 145 textures; 35 material PNGs reproduce byte-for-byte |
| Whitespace / scope | `git diff --check` passed | No worker/contracts/font/office/data changes in this integration |

[Spend ink](../game/tests/output/ui-redesign/drawer/spend-ink.json) reports zero
outside-paper pixels in four running/scrolled/approval/delivery cases.
[HUD/reader results](../game/tests/output/ui-redesign/reader-hud/results.json)
report zero outside-paper pixels across 19 HUD cases, including large amounts.
The guards include invalid-placement negative checks; they measure painted ink,
not just container rectangles.

Motion manifests retain all frame markers, expected states, distinct samples,
contact sheets and actual-input checks. All 18 world and 18 UI keyframes plus
the 15 UI checkpoints were visually reviewed. The UI sequence now
specifically checks stable approval-ledger footprint, restored work context,
no partial action controls, cleared answered-approval cue and visible outcome.
It also records the actual Retry dispatch, disabled pending state and distinct
recovery, rather than skipping straight from an error to a fabricated result.

- [World movie](../game/tests/output/polish-audit/world.avi) / [manifest](../game/tests/output/polish-audit/world/manifest.json)
- [UI movie](../game/tests/output/polish-audit/ui.avi) / [manifest](../game/tests/output/polish-audit/ui/manifest.json)
- [Texture/native-scale inventory](../game/tests/output/polish-audit/asset-inventory.json)
- [Window/scaling manifest](../game/tests/output/typography-scaling/manifest.json)

### Honest limits and intentional behavior

- User aesthetic approval remains separate. This is a scoped implementation
  and visual-review result, not a promise of perfection in every future state.
- Native 1280×720 and integer 2560×1440 retain the intended pixel grid.
  1600×900 (1.25×), 1440×1000 with 1440×810 content (1.125×), and available
  fullscreen 3456×2168 with 3456×1944 content (2.7×) preserve layout and input,
  but fractional scales necessarily produce uneven physical pixel widths.
  All five modes have zero changed frames in 13-sample frozen UI probes and
  stable UI regions during 13 one-logical-pixel sprite translations. This is
  rest-shimmer evidence, not proof of every animation frame.
- Viewport captures omit OS chrome and outer letterbox gutters. Their geometry
  is measured, not their visual appearance. Events enter Godot, not physical
  OS hardware. Other monitors/platforms and universal Unicode/bidi coverage
  were not tested.
- Long chat, documents, criteria and text-entry contents intentionally scroll.
  The synthetic `journey-long-error` capture has a partial noninteractive money
  explanation at the reading boundary around `(292,522,682,10)`; the recovery
  notice/actions are complete. Baseline revision and valid Retry show the full
  explanation. This is not the half-action-control defect fixed by I05/I06.
- Crowded optional world tags/prompts can hide when all safe slots are blocked;
  E and the rail remain usable. Important attention remains in the rail/Activity.
  The reviewed world samples show no callout/actor/furniture overlap, but three
  samples per scenario do not prove every frame. The synthetic job-cycle end
  can show the preceding completed-job toast while a subsequent job fails;
  that is sequential fixture context, not completion of the failed job.
- Narrow focused world fixtures prove cue ownership, not full job-copy
  hydration; use main/static and UI-motion captures for complete screen copy.
- No paid provider, live evaluation/retry, OS keychain or real-save behavior
  was exercised. The unchanged worker suite was not rerun for this UI goal.
  Generated evidence is local and ignored by Git; commands below reproduce it.

### Reproduction

Godot 4.7.2; run from the repository root. Set the executable on PATH or use
its full local path. Contact sheets also require ImageMagick (`magick`) on PATH
and Node at `/opt/homebrew/bin/node`, as specified in the helper script.
These commands capture production skins/fonts, not the
old typography preview. Do not use `test_live_startup.gd` here: it deliberately
unsets worker-disabled mode and requires its own disposable worker launcher.

```sh
export STARTUP_VALLEY_NO_WORKER=1
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
godot --headless --path game --script res://tests/test_complete_game.gd
godot --headless --path game --script res://tests/test_ui_flow_regressions.gd
for suite in test_ui_foundation test_ui_drawer_redesign test_ui_company_redesign test_reader_hud_redesign test_world_ui_presentation test_graphics_regressions; do
  godot --headless --path game --script "res://tests/$suite.gd" || exit 1
  godot --path game --resolution 1280x720 --script "res://tests/$suite.gd" || exit 1
done
for suite in test_window_presentation test_office_architecture test_office_layout test_modular_office test_office_layout_editor test_office_migration; do
  godot --headless --path game --script "res://tests/$suite.gd" || exit 1
done
godot --path game --resolution 1280x720 --script res://tools/capture_ui_material_specimen.gd
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_ui_material_audit.gd -- --after
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_audit_c_shell.gd -- --material-after
godot --path game --resolution 1280x720 --fixed-fps 30 --write-movie res://tests/output/polish-audit/world.avi --script res://tools/capture_polish_audit.gd -- --suite=world
godot --path game --resolution 1280x720 --fixed-fps 30 --write-movie res://tests/output/polish-audit/ui.avi --script res://tools/capture_polish_audit.gd -- --suite=ui
godot --headless --path game --script res://tools/validate_polish_audit.gd
godot --path game --script res://tools/capture_typography_scaling.gd
sh dev/tools/build_ui_immersion_contact_sheets.sh
```

## Original audit

Historical before-evidence only. Present-tense descriptions, line references,
counts and the final “remain open” statement below describe the pre-integration
audit, not the accepted implementation above.

## Verdict

The user's examples are confirmed. The current interface has a coherent outer
notebook, but its inner controls and world overlays still use incompatible
visual treatments. Typography C improved reading; it did not make the whole
interface feel authored as one game. The previous technical acceptance should
not have been presented as complete aesthetic acceptance.

This is not a reason to change fonts or regenerate the office. The main issue
is a split in the shared component layer: primary/secondary/danger buttons use
the slim walnut raster frame; quiet actions use flat one-pixel rectangles.
Cards, inputs, popups and world nameplates reuse similarly plain shapes. These
are explicitly styled controls, **not unskinned Godot defaults**—but they read
like application widgets inserted into illustrated scenery.

Keep C's readable type, current HUD, portraits, office, and notebook silhouette.
Build one small material/component family and apply it consistently. Different
functions should remain distinguishable; consistency does not mean framing
every label in thick wood.

## Evidence and scope

- Regenerated 36 world/drawer captures and 14 company-shell captures at native
  1280×720, using production fonts and skins with no preview overrides. Five
  are world-only stages: **45 UI captures**, not 50 unique UI screens.
- Added actual Godot pointer-driven hover, press and expansion captures for
  usage/work disclosures, approval with usage open, and an actually visible
  dropdown. The audit refuses to click hidden controls.
- Reproduced attachment-chevron desynchronization through the same purpose
  selection methods used by the UI; this specific transition is a fixture
  method probe, not a hardware-input test.
- Inspected component source, live button style classes, existing raster assets,
  focused native screenshots and company/world/reader reviews. This is not a
  new comprehensive gameplay, motion, OS-input or provider test.
- Worker disabled, no paid requests or real-save changes. Only this report,
  the dev-only capture script and generated audit evidence were added/updated.
  No production UI/asset implementation, commits or pushes.

Evidence:

- [Main manifest with live styles and expansion state](../game/tests/output/ui-material-audit/manifest.json)
- [Main contact sheet—overview only](../game/tests/output/ui-material-audit/contact-sheet.png)
- [Company production manifest](../game/tests/output/typography-audit-c-shell-production/manifest.json)
- [Capture script](../game/tools/capture_ui_material_audit.gd)

Main screenshots below live in `game/tests/output/ui-material-audit/`; company
screenshots live in `game/tests/output/typography-audit-c-shell-production/`.
Coordinates are `(x,y,width,height)` in the full native screenshot. Priorities
are relative to this polish pass; no P0 crash/data-loss issue was established.

## Findings

### I01 — P1: Two incompatible button families

In [running Activity](../game/tests/output/ui-material-audit/ui-journal-active.png),
Send update `(806,409,320,44)` has an authored walnut edge, while Work details
`(806,505,320,44)` and Usage details `(970,651,150,44)` have thin flat borders.
The latter look like unfinished placeholders beside the other buttons.

Confirmed affected controls: Work details, Usage details, Attach Studio context,
Create work order, Keep with job, E · Chat, icon-only Close, Review criterion
evidence, Show chapter roadmap, Title screen and Back to office.
`CozyUI.control_style()` at `game/ui/cozy_ui.gd:51` explicitly branches quiet
away from the raster family; `disclosure()` at line112 always chooses quiet.

**Correction:** a restrained secondary/disclosure treatment sharing the same
corner construction, edge palette, lighting and press depth as the main button.
Use a chevron for expanders; keep consequence buttons distinct from navigation.
Reuse/normalize the current slim-control master first. A broad new asset pack
is unnecessary. Classification: shared component code + existing art.

### I02 — P1: Floating employee information looks like a debug overlay

[Activity](../game/tests/output/ui-material-audit/ui-journal-active.png) shows
Mina/To desk around `(302,600,132,54)` in a plain cream rectangle. The same name
and working context already appear in the open drawer. `employee_avatar.gd:471`
draws `CozyUI.card()` directly, while `world/main.gd:131` keeps selected-employee
highlight active throughout the open drawer.

[Speech](../game/tests/output/ui-material-audit/ui-world-speech.png) uses a
different, riveted 188×64 sheet around `(274,388,188,64)`, with no tail and a large
gap to the speaker. Its short memory is visibly cut to “one cl…”. Readable glyphs
do not fix the detached visual association or interrupted thought.

**Correction:** one world-callout family: compact anchored identity tag on
hover/approach; brief state cue only when useful; a speech variant with a fixed
native tail. Suppress redundant expanded name/status while that employee's
drawer is open, retaining approval/delivery attention through the existing cue.
Use short intentional ambient lines or make their full text available. Avoid
restoring two permanently stacked plaques.

Existing `operations/world-nameplate.png` (96×34) and
`operations/world-speech-bubble.png` (148×73) are candidates, not drop-in fixes.
Their outlined material/tail can be normalized into compact parts. Classification:
existing-art normalization + label visibility/placement code. No new characters.

### I03 — P1: Interaction prompts resemble buttons pasted on furniture

[Founder interaction](../game/tests/output/ui-material-audit/ui-founder-hud.png):
E · Chat `(224,477,112,44)` covers the desk face and does not clearly point to
Mina. `founder_hud.gd:87–105` creates textured paper, then covers its whole area
with an opaque quiet button. Placement considers actors but not important prop
faces (`founder_hud.gd:177–190`).

**Correction:** one visible prompt surface, with a compact E keycap, action and
target pointer. Include important furniture faces in placement priorities;
retain clickability and the existing interaction rules. Classification: shared
callout art + code layout. This does not require regenerating furniture.

### I04 — P1: Paper interiors have no consistent physical hierarchy

Chat bubbles, editable fields, status cards and Studio rows are almost the same
flat cream rectangle. Examples: [Assign](../game/tests/output/ui-material-audit/ui-work.png)
inputs `(806,297,320,44)` / `(806,351,320,122)`; Studio row
`(806,210,320,84)`; [Settings](../game/tests/output/typography-audit-c-shell-production/pause-settings.png)
Sound card `(312,266,656,153)`; day-summary metric cards `(292,225,696,104)`.
Sources: `cozy_ui.gd:40–41,121–132`, `company_panel.gd:128`,
`job_panel.gd:1460,2385`.

**Correction:** define a small paper family: inset editable field, readable
paper card, and dialogue bubble. Share restrained stepped edges/shadows and
quiet centers; editable versus read-only should be apparent without hover.
Keep the reader's uncluttered document paper. A narrow notebook/header detail
for Journey/Settings may be worth a specimen, but adding a heavy wooden border
to every modal or card is not a blanket requirement. Classification: code +
existing art; new small edge patches only if reuse fails native-size review.

### I05 — P1: Expanded usage visibly cuts a neighboring control

[Approval with Usage details open](../game/tests/output/ui-material-audit/approval-usage-expanded.png)
has an Activity scroll bottom at y611. Work details occupies `(806,585,308,44)`,
ending at629: its bottom18px are outside the content viewport. It looks cut
off above the footer. The control remains reachable by scrolling; this is not
lost content or an inaccessible approval action.

With [both disclosures open](../game/tests/output/ui-material-audit/work-and-usage-expanded.png),
the first timeline row also appears as a sliver below Latest activity.
Usage expansion grows the pinned footer inward (`job_panel.gd:975–1006`), but
the surrounding first-view layout was accepted only with usage collapsed.

**Correction:** keep the summary/footer footprint stable or put expanded billing
details in a dedicated popover/sheet; reserve sufficient space or deliberately
scroll/reveal the opened content. Never leave half a button visible at rest.
Classification: code-only layout/state; no missing texture.

### I06 — P1: A disclosure can claim it is open when its content is closed

[Attachment after a template round-trip](../game/tests/output/ui-material-audit/attachment-after-template-roundtrip.png):
the Attach Studio row `(806,483,320,44)` shows an up-chevron, but its picker is
hidden. Manifest confirms `attachmentArrowExpanded:true` and
`attachmentContentVisible:false`. Before switching, both are true.

Reproduction: expand attachment → select a preset purpose → return to custom.
`job_panel.gd:1799–1800` hides the picker without resetting the chevron/state
established at `785–789`.

**Correction:** derive disclosure presentation from a single expanded state on
every purpose/employee/draft refresh. Classification: code-only state bug.

### I07 — P2: Navigation looks like four adjacent action buttons

Drawer tabs `(794,147,344,44)` use the same full push-button frame and selected
orange face as Start work order/Approve. `job_panel.gd:560–567,1099–1101`
applies the generic button variants directly.

**Correction:** a notebook-tab silhouette visibly attached to the selected
page, retaining the current readable labels, target sizes and keyboard behavior.
Selected orange is fine; navigation and committing an action should not have
identical silhouettes. Classification: existing tab-art normalization + code.

### I08 — P2: Close/focus treatment exposes the application-widget layer

Drawer close `(1092,32,44,44)` and reader close around `(883,87,46,46)` are plain
square buttons with a small black X. Indigo focus is a separate expanded
rectangle ignoring the authored corners; see
[Usage expanded](../game/tests/output/ui-material-audit/usage-expanded.png)
and [Settings](../game/tests/output/typography-audit-c-shell-production/pause-settings.png).
Sources: `cozy_ui.gd:43–49,163–171`.

**Correction:** compact tab/beveled-paper close and a stepped/inset focus shape
following the component silhouette. Keep at least44px hit targets and strong
keyboard focus. Classification: shared skin + existing glyph/code pixel work.
Do not remove focus or shrink hit targets for aesthetics.

### I09 — P2: Dropdowns and tracks do not match their surrounding controls

[Open purpose selector](../game/tests/output/ui-material-audit/assignment-dropdown-open.png):
the closed field has a walnut rim, but the popup `(806,286,320,140)` is a plain
box with generic circular selection marks. Reader scrollbar around
`(916,192,12,432)` is flat; Settings pairs a crafted thumb with flat tracks at
`(440,332,448,6)` and `(440,382,448,6)`. Sources:
`cozy_ui.gd:149–161,228–248`.

**Correction:** match popup edge, selected check/radio mark, track end caps and
thumb depth to the shared kit. Reuse normalized existing scroll assets and
current slider thumb where appropriate. Classification: code + existing art;
tiny authored selected-state glyph if needed.

### I10 — P2: Miniature assets lose their identity

Chat portraits are32×38 including9px frame insets, leaving roughly14×20 for a
large bust (`job_panel.gd:1443–1452`). They look like noisy ornaments beside
readable text. The reader document icon is a46×58 asset fit into24×28 and looks
like a blank tiny note (`artifact_viewer.gd:42–46`).

**Correction:** native small portrait crops with lighter small frames; a native
24×28 document glyph with clear folded corner/lines. Classification: normalize
existing art or manually author tiny glyphs; no new portrait generation.

### I11 — P2: Technical information still dominates some game surfaces

[Usage expanded](../game/tests/output/ui-material-audit/usage-expanded.png)
shows an entire Usage details button plus repeated work cost/raw tokens. The
idle approval fixture says “Usage details ·0tokens” under Usage details.
The source mixes “This work order” and “Usage details” prefixes across live,
restored and initial states (`job_panel.gd:1820–1821,2115,2244,2310`).
Expanded activity exposes event identifiers such as `job.started`.
Assign leads with “Ordinary work · does not advance Journey.” Studio repeats
filename/path metadata and puts a folder in the portrait frame.

**Correction:** show one compact ledger-like “AI spend today” summary, distinguish
today versus selected-work totals inside a deliberate details surface, and
retain honest real-money/token disclosures. Never imply that AI spend is game
currency or hide costs. Use employee-facing event language (“Started work”),
with raw identifiers in optional diagnostics. “Side project” can lead the
non-Journey path; “Mina is working—send changes in Activity” can replace a long
architecture explanation. Studio can show a document title + owner first and
full path on demand. Classification: code-only copy/hierarchy plus shared kit.

### I12 — P1 verification: Existing tests protect some of these inconsistencies

`test_ui_drawer_redesign.gd:248` requires a `StyleBoxFlat` for Create work order.
The earlier gates correctly tested fonts, safe ink, clicks and specific geometry,
but did not establish coherent materials. Usage expansion was toggled closed
before approval geometry checks (`:312–329`), missing I05's combined state.

**Correction:** separate semantic/interaction checks from visual approval.
Check roles and coherent edge/state behavior without requiring one particular
StyleBox class. Test combined open states and dynamic refreshes. A technically
valid flat shape may be fine if it actually belongs to the approved family;
texture use alone is not proof of quality. Classification: audit/test code.

## Recommended implementation sequence

1. **Approve one native component/state specimen, not another whole-screen
   illustration.** Put primary, secondary, disclosure, input, popup, tab,
   close/focus, card, world tag and speech bubble beside the existing drawer.
   Compare normal, hover, pressed, disabled, focused and expanded states. Retain
   C fonts and current readable sizes throughout.
2. **Implement the shared kit and the two reproduced state/layout defects.**
   Unify material/corner/edge construction; fix I05/I06 without sacrificing
   pinned spend or readable text. Apply across Chat, Assign, Activity, Studio,
   Journey, Settings, connection, day summary and reader—not just the examples.
3. **Integrate world-callout behavior and small-asset normalization.** One
   contextual tag system, connected speech/prompt pointers, fewer duplicated
   labels, furniture-aware placement, native miniature portraits/icons.
4. **Recapture and obtain visual acceptance in the actual game.** Review
   matched component states plus flows at100%; preserve typography, contrast,
   44px controls, click isolation, signal-bind-once behavior, deterministic
   worker-disabled fixtures and the existing worker contracts.

### Asset scope

Start with the existing slim button master, notebook tabs, world nameplate and
speech bubble, portraits, scroll assets and slider thumb. Normalize corners,
slice margins, native size and quiet centers rather than re-enabling all legacy
art blindly. At most a small supplementary edge/tail/glyph kit should be needed
after specimen review. No fonts, baked text, new office, whole-screen bitmap UI,
or broad ImageGen batch is proposed.

### Acceptance additions

- Every interactive family shares the approved corner scale, light direction,
  rim/shadow palette and fixed geometry across its states.
- Disclosures retain their lighter hierarchy, visible affordance and correct
  arrow/content state through purpose changes, employee switching and reopening.
- Approval + usage open and both Activity disclosures open produce no half
  controls or orphaned first-row slivers. Long content remains intentionally
  scrollable and the next action is discoverable.
- World overlays are visibly anchored, don't duplicate the open drawer, and
  avoid covering important actors/prop faces in the tested configurations.
- Small portraits, document icons and selection marks read at native size;
  no arbitrary downscale of heavily framed artwork.
- Keep accessibility and accurate billing explanations. No disappearing focus,
  tiny targets, invented progress or cost/currency ambiguity.
- Record technical checks separately from human aesthetic approval. Do not
  close this audit based solely on a font test count or matching asset paths.

## Reproduce this audit

```sh
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_ui_material_audit.gd
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_audit_c_shell.gd -- --production
```

Both capture runs completed successfully with the worker disabled. Their success
means evidence was captured, not that the UI passed this audit. All12 findings
remain open; production fixes await the next implementation request.
