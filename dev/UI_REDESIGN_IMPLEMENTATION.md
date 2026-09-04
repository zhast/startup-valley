# UI redesign implementation — 2026-09-03

## Scope and design

This implements the 23 findings in `UI_ELEMENTS_AUDIT.md`. The approved walnut
notebook silhouette, 130px right rail, 368px drawer, employee portraits, Whop
accents, 1280×720 canvas and modular office are retained. Heavy wood stays on
outer structures; reading and form surfaces are quiet parchment. Text, values,
controls and state transitions remain native Godot UI, never a flattened mockup.

Existing uncommitted office/graphics work was preserved. No worker protocol,
provider, credential handling, persistence, security boundary or real company
save was changed. All UI tests use deterministic worker-disabled fixtures.
No paid AI job, commit or push was performed.

**Follow-up status: visual acceptance reopened.** The user's subsequent review
and `UI_CONSISTENCY_AUDIT.md` identify unresolved HUD font/baseline consistency,
functional pixel-font readability and control affordance. The blanket visual
acceptance below was too broad. Its technical results and implemented fixes
remain historical evidence, not proof that the current design is approved.

## Typography and component contract

`NunitoSans-Body.tres` now requests Godot's supported `weight` axis at 550.
The effective font RID is tested against an independently created 550 variant
and must differ from the base font's ExtraLight default. Explicit resources
provide 600 emphasis, 700 bold, real italic/bold italic, and JetBrains Mono 450.
Both dynamic chat and document controls bind all five rich-text font roles.

- Prose/forms: Nunito 550, 16px; documents 18px, source/code 16px.
- Actions/tabs: Nunito 700, 16px; metadata Nunito 550/600, 14px minimum.
- Short display headings: Tiny5 at tested 20/30px; no tiny pixel-font paragraphs.
- Quiet charcoal ink; brighter Whop colors are accents, not low-contrast prose.
- Shared 44px controls, 8/12/16px spacing, fixed insets, explicit focus outline.
- Hover/press/disabled states keep the same geometry; button signals bind once
  even after repeated style refreshes. Press feedback is immediate, release 80ms;
  drawer 160ms, tabs 140ms, reader entrance 160ms/exit 120ms.

`CozyUI` owns buttons, inputs, dropdown/context menus, close glyph, focus,
sliders, scrollbars, cards and text roles. `GameFonts` provides the theme and
readable parchment tooltip styling. Keyboard focus is distinct indigo rather
than the green success accent. Connection overlays explicitly trap Tab/ShiftTab
among visible enabled controls; document close returns to its original Preview
control when still usable. World shortcuts do not navigate under open panels.

Font files and OFL licenses are bundled. Exact upstream sources and hashes:
`game/assets/fonts/README.md`.

## Asset decisions and provenance

Actual corrected-font Chat, Assign and reader layouts were captured and inspected
before generation: `game/tests/output/ui-redesign/layout-proof/`.

One original slim walnut control-frame master was generated with the **ImageGen
skill, built-in tool**. Existing paper, outer shell, portraits, rail and ledger
were reused. Flat inputs/cards/focus tracks remain code-native because additional
ornament would reduce clarity. The old ruled document texture is no longer used
as the reading surface.

- Master and exact prompt: `game/assets/source/ui-redesign/`.
- Runtime assets/specification: `game/assets/runtime/ui/cozy-controls/README.md`.
- Rebuild: `bash dev/tools/build_ui_redesign_assets.sh` with ImageMagick on PATH;
  also included in `build_polish_assets.sh`.
- 17 native PNGs: 12 button states at 96×48, three 24×24 slider thumbs, two 16×16 glyphs.
- Button six-pixel slice margins preserve corner geometry at varied widths.
- The generated exterior checkerboard was removed during deterministic cleanup;
  runtime alpha is binary and identical across button states.
- Repeated builds produced identical SHA-256 hashes for all 17 PNGs.
- Source and runtime remain separate; no source master was overwritten.

The first primary pressed color failed the 4.5:1 contrast test. Its replacement
passes even with the actual 0.94 pressed tint. The foundation suite samples every
pixel in each button's text-safe interior and the reused paper's inner field,
not merely flat palette constants. It also compares rendered corners with source
pixels at 96/208/432px widths. A multiline action specimen verifies text-safe
width and height using the actual bundled bold face.

## Finding-by-finding disposition

Evidence paths below are relative to `game/tests/output/`.

| Finding | Implemented correction | Evidence / acceptance |
| --- | --- | --- |
| U01 font configuration | Supported weight 550; explicit bold/italic/code; reflowed all screens | `ui-redesign/foundation/results.json`; real-control role checks in drawer/reader/company suites |
| U02 cramped tabs | Four equal 86px native buttons, 44px targets, Nunito 700 | `ui-redesign/drawer/chat.png`; real tab-click regression |
| U03 ruled reading surface | One unruled paper sheet; rich text has empty inset style | `ui-redesign/reader-hud/reader-top.png` |
| U04 delivery decision order | Files and Preview precede summary/keep decisions; unloaded files offer Load files | `ui-redesign/drawer/delivery-preview-first.png`; recorded Preview→reader→promotion dispatch order |
| U05 nested ornament | Outer walnut reused; flat paper cards, fine keylines and quiet inputs | Chat/Assign/Activity/Studio final captures |
| U06 hidden assignment budget | 112px employee header, optional context disclosure, pinned budget and charge confirmation | `ui-redesign/drawer/assign.png`; required controls visible and bounded |
| U07 Activity hierarchy | Current state/events first; steering follows; lower-emphasis destructive cancel | Activity static/motion checkpoints; `job.steer` channel assertions |
| U08 competing chat actions | Ask primary; conversion beside latest reply; active Chat is a read-only Activity invitation | `ui-redesign/drawer/chat.png`, `active-chat.png` |
| U09 misleading usage bar | Removed visible progress-like token bar; one real cost line and Usage details | Activity usage/queued captures; hidden legacy projection never presented as progress |
| U10 Studio rows/empty state | Title/type/context/path and Open; one empty action | `ui-redesign/drawer/studio.png`, `visual-review/ui-studio-empty.png` |
| U11 recovery mismatch | Separate missing-key, saved-key replacement and offline-worker surfaces; Reconnect never asks to resave key | `ui-redesign/drawer/connection-configured.png`, worker error/recovered movie checkpoints; focus-cycle and empty-key rejection tests |
| U12 empty team | Purpose-built first-hire guidance leading to Journey; unusable drawer controls hidden | `ui-redesign/drawer/first-hire.png` with actual founder-only world |
| U13 inconsistent control states | One generated frame family plus shared quiet controls, authored glyphs and focus | `ui-redesign/foundation/` real normal/hover/press/focus/disabled and context-menu captures |
| U14 generic company shell | Purpose-sized screens; stable header/footer; only content scrolls | All 15 `ui-elements-audit/shell/` fixtures and company input suite |
| U15 HUD/world labels | Values lead HUD; one contextual name card; cached business attention survives delivery arrival and bootstrap without changing movement | HUD/world-label specimen; 51 integrated state checks; whole labels suppressed if notebook/rail/modal overlaps |
| U16 oversized notification | Compact 84px paper toast with usable View; durable rail attention retained | `ui-redesign/reader-hud/hud-and-toast.png`; real View/dismissal test |
| U17 reader hierarchy/code | Single file title/provenance, explicit Markdown weights and bundled monospace | Reader top/source/scrolled captures; full-path tooltips and focus restoration |
| U18 wrong Journey next step | Evaluation state determines Revise/Complete/Retry action | `ui-elements-audit/shell/journey-revision.png`, `journey-ready.png`; real action tests |
| U19 future content above objective | Current objective first; expandable roadmap/evidence; pinned decision | Journey captures and long-evidence wheel/fixed-footer test |
| U20 unclear sliders | Native 24px thumb, 44px row, live percentage, shared focus | `ui-elements-audit/shell/pause-settings.png`; keyboard slider tests |
| U21 hire/save identity | Named portrait hire card and saved day/chapter/team Continue context | `hire-confirmation.png`, `title-continue.png` shell fixtures |
| U22 flat day log | Distinct game revenue/reputation/real-AI metrics, work list and next objective | `ui-elements-audit/shell/day-summary.png` |
| U23 dangerous reset focus | Go back receives initial focus; differentiated destructive secondary action | `reset-confirmation.png`; real Enter/Escape and single-dispatch tests, no save access |

## Verification and reproduction

Run from the repository root with Godot 4.7.2 (`godot` below denotes the installed
executable). Each renderer-based suite also runs headless where applicable;
headless result manifests do not replace rendered evidence.

```sh
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
godot --headless --path game --fixed-fps 60 --script res://tests/test_complete_game.gd
godot --headless --path game --fixed-fps 60 --script res://tests/test_ui_flow_regressions.gd
godot --path game --fixed-fps 60 --script res://tests/test_graphics_regressions.gd
godot --path game --fixed-fps 60 --script res://tests/test_ui_foundation.gd
godot --path game --fixed-fps 60 --script res://tests/test_ui_drawer_redesign.gd
godot --path game --fixed-fps 60 --script res://tests/test_ui_company_redesign.gd
godot --path game --fixed-fps 60 --script res://tests/test_reader_hud_redesign.gd
godot --headless --path game --script res://tests/test_window_presentation.gd
godot --headless --path game --fixed-fps 60 --script res://tests/test_world_ui_presentation.gd
godot --path game --fixed-fps 60 --script res://tools/capture_visual_review.gd
godot --path game --script res://tools/capture_ui_shell_audit.gd
godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/ui.avi --script res://tools/capture_polish_audit.gd -- --suite=ui
godot --path game --fixed-fps 30 --write-movie res://tests/output/polish-audit/world.avi --script res://tools/capture_polish_audit.gd -- --suite=world
godot --headless --path game --script res://tools/validate_polish_audit.gd
godot --path game --script res://tools/play_ui_redesign.gd
```

The native playtest script disconnects credential, assignment, file and company
mutations before presenting local fixtures. Its chat reply is simulated and
clearly identifies itself as a preview. It never starts a worker or reads real
company saves. It exists only for developer visual/input verification.

Focused evidence:

- Foundation: 82 rendered / 78 headless checks, zero failures. Effective faces, actual pointer
  states, real text context menu, contrast, alpha/import and resized corners.
- Drawer: 492 rendered / 482 headless checks, zero failures; real tabs, contextual
  conversion, Preview-before-decision, first hire, connection focus/recovery,
  long names, dynamic font roles and word wrapping.
- Company: 431 rendered / 419 headless checks, zero failures; rapid actions, safe
  reset, evaluated Journey outcomes, long evidence scrolling, sliders and money.
- Reader/HUD: 65 checks in each mode, zero failures. Wheel scrolling, focus loop,
  close/reopen/source switching, prior-focus restoration, reachable tooltips,
  large HUD values and real toast View dispatch. Identical Markdown is reopened
  through Preview and Studio; tests assert nonempty parsed text and laid-out
  document height, not merely reader visibility.
- Startup window policy: 56 headless checks; preserves explicit geometry,
  capture fixtures, editor modes and subsequent user resizing.
- World UI state projection: 51 headless integrated checks. Pending delivery
  survives physical arrival and save hydration; queued/off-shift, approval,
  retry and restored-running wording follow the drawer's business state.
  Every projection also checks that movement, route and animation are unchanged.
- Existing gameplay/UI and graphics regressions pass, including workstation
  layering, fixed menu corners, UI/world click isolation and modal label masking.

Motion acceptance was strengthened rather than inferred from differing images:
visible-control prerequisites, actual dropdown selection/typing, disabled input,
reader wheel release/close/reopen, exact chat/work/steer dispatch records,
Preview-before-promotion and separate failure/recovered checkpoints. A missing
synthetic wheel release was found and fixed in the harness; no production reader
workaround was needed for wheel input. The final visual review did expose a
separate real reader bug: `RichTextLabel.clear()` removed rendered items without
resetting its cached text property, so setting identical Markdown again did not
rebuild it. Four focused assertions failed before resetting that property and
passed afterward. The blank-page evidence remains at
`ui-redesign/reader-hud/repeated-document-before.png`; corrected repeated-content
captures and explicit movie checks prevent that false pass from returning.

The same review caught an independently stale world label: after a delivery
walk ended, physical idle state rendered “Available” while Activity retained
“Delivery ready.” The label now consumes the existing UI presentation model,
leaving locomotion and work animations authoritative to their original events.
An integrated test completes the real deterministic delivery route before
checking the label, and separately verifies pending-delivery hydration.

## Native-window acceptance

The **Computer Use skill** exercised the actual macOS Godot window with the
worker-free playtest script. Mouse input selected employees, typed and sent a
local chat message, converted a reply to a draft, selected a budget, opened a
Studio file, scrolled its document, closed/reopened it, opened Settings and
cycled connection focus. No provider call, credential replacement or real save
transaction was dispatched.

The native check found the default 1280×720 physical window occupied only
640×360 logical points on this Retina display. `WindowPresentation` now chooses
a one-time DPI-aware startup size, retaining the internal 1280×720 canvas and
aspect ratio. The observed startup was 2560×1440 native pixels at display scale
2.00. Explicit geometry, embedded/editor/movie modes and later manual resizes
are untouched; other platforms retain their existing policy.

After the fix, windowed Chat and Assign were inspected at 1280 logical pixels
wide. Maximizing/restoring preserved the draft. Manual narrower and taller
resizes preserved controls and reader bounds. Letterbox bars in non-16:9
windows are intentional outside the game canvas, not holes in the office.

Evidence under `game/tests/output/ui-redesign/native/` includes
`retina-windowed-chat.jpg`, `retina-assign.jpg`,
`retina-maximized-assign.jpg`, `resized-assign.jpg`,
`resized-tall-assign.jpg` and `resized-reader.jpg`. These are native-window JPEG
captures; lossless internal PNGs remain the pixel/corner acceptance evidence.
Earlier native interaction captures establish typing, dropdown selection,
context menus and focus restoration. The file named `reader-tooltip.jpg` does
not show an open tooltip and is not used as proof of tooltip rendering.

## Final acceptance results

| Gate | Result and authoritative evidence |
| --- | --- |
| Import and project validation | Passed with Godot 4.7.2; new fonts, controls and scripts load |
| Effective fonts, control states, contrast and fixed corners | Foundation: 82 rendered / 78 headless checks, no failures; `ui-redesign/foundation/results.json` and `results-headless.json` |
| Drawer interaction, long content, connection and delivery ordering | 492 rendered / 482 headless checks, no failures; `test_ui_drawer_redesign.gd` and ten final drawer screenshots |
| Company-shell interaction and stress content | 431 rendered / 419 headless checks, no failures; `ui-redesign/company/manifest.json` and `manifest-headless.json` |
| Reader/HUD and repeated-document regression | 65 checks in each mode, no failures; seven corrected captures and both result manifests under `ui-redesign/reader-hud/` |
| World presentation and startup sizing | 51 integrated world-state checks and 56 pure window-policy checks, no failures |
| Existing gameplay and UI behavior | `run_all.gd`, `test_complete_game.gd`, `test_ui_flow_regressions.gd` and rendered `test_graphics_regressions.gd` passed on final production code |
| Static screen coverage | 27 isolated main captures plus 15 company-shell captures: 37 UI states and five world stages; all reviewed, with full-size scrutiny of text-heavy and changed states |
| UI motion | 1,018 frames, 1280×720, 30 FPS; six scenarios, 41 explicit assertions, 2,592 actor-cell checks, no failures |
| World motion regression | 2,455 frames, 1280×720, 30 FPS; six scenarios, 5,043 actor-cell checks, no failures |
| Motion evidence integrity | Strict validator passed; required checkpoints, actual dispatch order, distinct frames, visible controls, repeated-document text/layout and separate error/recovery states are present |
| Native display/input | Actual macOS windowed, maximized/restored and manually resized playtest; DPI startup corrected; retained keyboard/mouse behavior and readable composition |
| Asset reproducibility | All 17 runtime PNG hashes unchanged after rebuilding; master SHA-256 matches retained provenance |
| Worker compatibility | Build passed; 49 provider-free tests passed, zero failures; one optional production startup test skipped because `GODOT_BINARY` was unset; offline evaluator 8/8 |
| Scope and repository hygiene | No `harness/` or `contracts/` changes; `git diff --check` passed; all test/playtest processes closed; no paid worker job, real-save mutation, commit or push |

Worker regression reproduction, from the repository root:

```sh
cd harness && npm run build && npm test && npm run eval:offline
```

### Final evidence index

Paths below are relative to the repository:

- `game/tests/output/visual-review/`: all 27 final main screenshots.
- `game/tests/output/ui-product-audit/contact-sheet.png`: regenerated overview.
- `game/tests/output/ui-elements-audit/shell/`: 15 company screens, contact
  sheet and isolated-fixture manifest. These are visual fixtures, not 15 real
  company transactions.
- `game/tests/output/polish-audit/ui.avi` and `world.avi`: final recordings.
  The `ui/` and `world/` subdirectories each contain their own `manifest.json`,
  start/middle/end keyframes and six scenario contact sheets.
- `game/tests/output/ui-redesign/`: foundation, drawer, company, reader/HUD,
  native-window evidence, retained pre-generation layouts and font baseline.
- `game/assets/source/ui-redesign/`: unchanged generated master and exact prompt.
- `game/assets/runtime/ui/cozy-controls/`: consumed runtime kit and slice/alpha
  contract; rebuilt by `dev/tools/build_ui_redesign_assets.sh`.

The initial visual inspection reported no unresolved instance of U01–U23 in
the covered screens; that conclusion is superseded for typography and control
clarity by `UI_CONSISTENCY_AUDIT.md`. Body text is visibly heavier,
document rules no longer cross prose, long content stays within scroll surfaces,
delivery decisions follow inspectable files, focus and corners remain stable,
and the same document remains readable after repeated opening. World labels
agree with durable business attention while physical animations remain unchanged.

### Deliberate limits

- This remains the two-employee, keyboard-and-mouse, 1280×720 internal slice.
  Native verification was on macOS; no Windows/Linux display claim is made.
- Very narrow windows necessarily reduce the aspect-preserved canvas. Non-16:9
  windows have intentional outer letterboxing; responsive rearrangement and
  localization are not part of this pass.
- Long file names elide in compact headings; full paths remain in reachable
  tooltips and document content scrolls. Source is displayed safely as text,
  not executed or rendered as a web page.
- Worker fixtures prove UI state and dispatch behavior, not live provider
  quality. Existing save/transaction tests remain separate from visual fixtures.
- Existing outer art and portraits are intentionally retained. Future content
  changes still need the same native-size visual and input review.
