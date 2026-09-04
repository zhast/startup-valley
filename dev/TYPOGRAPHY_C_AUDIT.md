# Typography audit — selected direction C

Date: 2026-09-03. Original preview audit plus production implementation follow-through.

## Production implementation status

C is now integrated into the actual game. The historical findings below remain
as before-evidence; their statements about Acid/Inter being current describe
the original audit, not the current runtime. Production static, interaction,
motion and supported-window checks are complete. T01–T08 are resolved within
the tested desktop slice; limitations are stated below.

The production roles are Slab22 controlled display, Nunito20 section/numeric,
Nunito16 body/actions/identity, Nunito14 metadata, Nunito18 document prose,
and JetBrains Mono16 code/source. All weights and real italic faces are local.
See [font roles and provenance](../game/assets/fonts/README.md).

| Finding | Production disposition | Current evidence |
| --- | --- | --- |
| T01 | Dynamic paths use Nunito Bold20; coverage-based display fallback preserves original names. Bundled Noto Sans/CJK/Symbols/Emoji cover tested accented, punctuation, CJK, Hangul, Greek/Cyrillic and emoji text with no OS fallback. | `reader-hud/results.json`; production Unicode/CJK reader captures; foundation glyph tests. |
| T02 | Spend is pinned outside Activity scrolling. Native raster inspection caught inadequate rivet clearance after the first layout pass; final footer uses 18px horizontal/10px vertical insets. Approval, steering, cancellation and the Work details control fit. | `drawer/spend-ink.json`: running, scrolled, approval and delivery show zero ink outside the safe paper. |
| T03 | Explicit Nunito Bold20 section/numeric roles retain hierarchy; HUD uses native Slab22 with captions above values. | Company large-value/Settings captures; HUD 19-case painted-paper check. |
| T04 | Reader retains Nunito18 reading, heading levels20/22/24, real emphasis, and JetBrains16 source/code. Reopening and changing document kinds preserve these roles. | Reader headless/rendered suite; Markdown/source/CJK production captures. |
| T05 | Quiet actions have a visible resting boundary, disclosures use an authored chevron, End Day is secondary and Override is a danger action. Styling binds press signals once. | Actual-input foundation, drawer and company tests; native screenshots. |
| T06 | Baseline revision fits409px of content into432px without a scrollbar. Sparse modals size to content; expanded evidence and long errors intentionally scroll within a fixed envelope. | Company layout manifests and collapsed-revision native evidence. |
| T07 | TEAM uses Slab22; rail names use Nunito Bold16. Canvas identity/status/speech have explicit fonts, metric-based baselines, real insets and snapped even-width cards. Long unbroken speech tokens are elided safely. | World UI229 checks; drawer refresh/Unicode tests; world-label captures. |
| T08 | Header/status suffixes use sentence case; separators require values; one offline/progress explanation. Evaluating allows Back to office while keeping request actions disabled; reopening preserves the pending evaluation. | Queued/offline/evaluating captures and actual-input company navigation tests. |

The fallback fonts originally inflated ordinary ASCII line boxes because
Godot includes unused fallback metrics in Label minimum heights. Runtime
ascent/descent alignment at UI sizes14–24 fixes this without resizing outlines,
changing advances or rewriting content. Foundation checks compare every
supported line box with Nunito's primary metrics; mixed-script raster evidence
checks the resulting visible glyphs.

Production capture commands (the flag bypasses all preview font overrides):

```sh
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_audit_c.gd -- --production
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_audit_c_shell.gd -- --production
```

Production output folders are `game/tests/output/typography-audit-c-production/`
and `game/tests/output/typography-audit-c-shell-production/`. Their manifests
record effective runtime font resources and reject developer-font paths.
Scoped regression evidence is under `game/tests/output/ui-redesign/`.

## Final acceptance evidence

The production suites contain **44 native 1280×720 PNGs, 43 distinct images**:
30 world/drawer/reader states and 14 company-shell states. The two-/three-hire
office images are identical, not additional unique UI coverage. Every manifest
records `previewOnly: false`, `productionTypography: true` and a disabled worker.
Effective font resources contain no developer-preview paths. All affected UI
screens were reviewed at native size; contact sheets are navigation aids only.

- [Production world/drawer/reader manifest](../game/tests/output/typography-audit-c-production/manifest.json)
- [Production company-shell manifest](../game/tests/output/typography-audit-c-shell-production/manifest.json)
- [World/drawer/reader contact sheet](../game/tests/output/typography-audit-c-production/contact-sheet.png)
- [Company-shell contact sheet](../game/tests/output/typography-audit-c-shell-production/contact-sheet.png)

Representative resolved states:

- [Running Activity with pinned spend](../game/tests/output/typography-audit-c-production/ui-journal-active.png)
- [Approval, complete controls and spend](../game/tests/output/typography-audit-c-production/ui-journal-approval.png)
- [Long chat](../game/tests/output/typography-audit-c-production/ui-chat-long.png)
- [Markdown hierarchy and real emphasis](../game/tests/output/typography-audit-c-production/ui-artifact.png)
- [Accented/long filename](../game/tests/output/typography-audit-c-production/ui-artifact-unicode-long-title.png)
- [CJK filename and source](../game/tests/output/typography-audit-c-production/ui-artifact-cjk-source.png)
- [Baseline revision without unnecessary scrolling](../game/tests/output/typography-audit-c-shell-production/journey-revision.png)
- [Evaluating with enabled return navigation](../game/tests/output/typography-audit-c-shell-production/journey-evaluating.png)
- [Saved completed work with Retry evaluation](../game/tests/output/typography-audit-c-shell-production/journey-evaluation-retry.png)
- [Large financial summary](../game/tests/output/typography-audit-c-shell-production/day-summary-large-values.png)

The long-error capture deliberately stress-tests a long notice; it is not a
complete evaluator-recovery fixture. The separate Retry capture uses an active
milestone, completed job, no evaluation verdict and an evaluation error. It
proves the valid saved-work failure presentation without calling the provider.

HUD acceptance compares rendered ink to the actual painted-paper interiors:
19 cases, including day999, 23:59 and large K/M/B/T amounts, have zero pixels
outside the safe paper. Exact abbreviated amounts remain in tooltips. Activity
has the same raster guard for running, scrolled history, approval and delivery;
all four pass with zero outside pixels. These checks include a deliberately
invalid placement to prove the guard detects bleed rather than merely checking
Control rectangles.

Expanded criteria, long errors, long chat and documents intentionally scroll.
Spend and baseline Activity decisions do not depend on scrolling. Repeated
tab/employee changes, dynamic refreshes, document kind changes and reopening
retain the explicit typography roles and original text.

### Verification results

All listed checks pass with zero failures. Headless and rendered totals differ
where image/raster checks require a renderer; they are not additive coverage.

| Suite | Headless | Rendered / evidence |
| --- | ---: | --- |
| UI foundation | 119 | 123; fonts, geometry, contrast, focus and actual input |
| Drawer | 1,432 | 1,452; dynamic refresh, actions, scrolling and four spend-ink cases |
| Company shell | 1,445 | 1,479; 17 captures, modal sizing, busy navigation and refresh |
| Reader/HUD | 182 | 201; 10 captures, 19 HUD-ink cases, documents/source/reopening |
| World typography | 229 | 229; metric-based cards, baselines and speech bounds |
| Window/scaling | 56 policy checks | 174 rendered checks across five actual window modes |
| Office architecture/layout | 477 / 830 | Existing regression suites retained |
| Modular office/editor/migration | 7,436 / 128 / 2,468 | Existing layout/input regression suites retained |
| Gameplay/UI flow/complete-game/graphics | Passed | Existing gameplay and actual-input regressions |
| Import/project validation | Passed | Runtime scenes, art, fonts/licenses and office stages |
| Motion audit | Validator passed | 6 world + 6 UI scenarios; 2,455 + 1,018 frames at30FPS |
| Whitespace validation | `git diff --check` passed | No commit or push |

The regenerated motion recordings use production fonts, native art and the
existing deterministic event paths. All scenario frame markers, distinct
samples, expected states, contact sheets and required actual-input dispatch
orders pass. Inventory reports no native-art scale/alignment flags. Native UI
checkpoints and world label keyframes were visually reviewed; this is not a
claim that every encoded frame received manual inspection.

- [World motion manifest](../game/tests/output/polish-audit/world/manifest.json)
- [UI motion manifest](../game/tests/output/polish-audit/ui/manifest.json)
- [Font/art inventory](../game/tests/output/polish-audit/asset-inventory.json)
- [HUD/reader checks](../game/tests/output/ui-redesign/reader-hud/results.json)
- [Spend painted-paper checks](../game/tests/output/ui-redesign/drawer/spend-ink.json)
- [Scaling manifest](../game/tests/output/typography-scaling/manifest.json)

### Scaling results and honest limits

Checked native1280×720 (1×), 1600×900 (1.25×), 2560×1440 (2×),
1440×1000 (letterboxed 1.125× content), and actual fullscreen on the available
display (3456×2168 window with3456×1944 content, 2.7×). All keep the1280×720
logical geometry, selected fonts and working physical-coordinate input mapping.
Five modes ×13 frozen samples are stable; UI regions also remain stable through
13 one-logical-pixel sprite translations per mode. Forty PNGs include full
content, native/detail crops and motion samples.

- Native and2× keep the intended pixel grid. Fractional scales necessarily
  produce uneven physical pixel widths/motion steps; this pass does not change
  the production window policy or claim fractional pixel perfection.
- Viewport captures omit OS chrome and outer aspect-ratio gutters. Their
  geometry is measured, but the gutters' appearance is not visually verified.
- Input tests inject real Godot mouse/keyboard events through GUI transforms;
  they do not simulate hardware devices at the OS level.
- The frozen-frame probe detects rest shimmer, not all possible animation
  defects. The separate motion audit exercises locomotion and UI sequences.
- All18 world keyframes were reviewed, but their sampling does not visually
  prove every intermediate world status. Temporary name cards can cover desk
  fronts in job/schedule scenes; no text-to-text overlap or glyph clipping was
  found. That existing world-composition debt is outside the typography fixes.
- Other monitors/platforms, all Unicode, localization, bidi layouts and complex
  emoji sequences remain outside acceptance. Bundled fallback coverage is
  deliberate and tested, not universal. Source is monospace for covered code
  glyphs; fallback scripts retain their own appropriate glyph advances.
- No live provider evaluation/retry was run. The worker suite was not rerun for
  this typography-only goal; worker code and protocol were not changed.

### Reproduction

Use Godot4.7.2. Static commands are above. Tests take the normal renderer unless
`--headless` is shown; none of these commands starts a live worker fixture.

```sh
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
godot --path game --resolution 1280x720 --script res://tests/test_ui_foundation.gd
godot --path game --resolution 1280x720 --script res://tests/test_ui_drawer_redesign.gd
godot --path game --resolution 1280x720 --script res://tests/test_ui_company_redesign.gd
godot --path game --resolution 1280x720 --script res://tests/test_reader_hud_redesign.gd
godot --path game --resolution 1280x720 --script res://tests/test_world_ui_presentation.gd
godot --path game --script res://tools/capture_typography_scaling.gd
godot --path game --resolution 1280x720 --fixed-fps 30 --write-movie res://tests/output/polish-audit/world.avi --script res://tools/capture_polish_audit.gd -- --suite=world
godot --path game --resolution 1280x720 --fixed-fps 30 --write-movie res://tests/output/polish-audit/ui.avi --script res://tools/capture_polish_audit.gd -- --suite=ui
godot --headless --path game --script res://tools/validate_polish_audit.gd
sh dev/tools/build_typography_c_contact_sheets.sh
```

No worker contracts, credentials, persistence, provider behavior or game
mechanics were changed. Fixtures disable the worker; no paid calls or real-save
access are part of acceptance. No commits or pushes have been made.

## Original preview audit

## Bottom line

C is a good direction: pixel display lettering with readable Nunito prose.
The remaining work is a complete role/spacing system, not another font search.
The strongest confirmed problems are unsupported characters in dynamic pixel
headings, Activity's partly hidden spend label, and loss of section/reading/code
roles when the chat-only preview rules are applied to other screens.

**C is still a developer preview.** `game/ui/game_fonts.gd` still uses Acid
Grotesk and Inter. Neither the selected C fonts nor the corrected C HUD layout
have been integrated into production. Findings below distinguish proposed-C
regressions from existing UI issues visible with C.

## Evidence and limits

- Rendered 29 world/drawer/reader captures and 13 company-shell captures at
  native 1280×720: 42 images, 41 distinct images. The five world-stage captures
  include identical two-/three-hire views; these are not 42 unique UI screens.
- Extended the existing fresh-scene fixtures with the same C override policy
  used for the approved preview. No production fixes were smuggled into it.
- Added long accented filenames, HTML source, expanded criterion evidence,
  genuine evidence scrolling, large summary amounts, evaluating/disabled state,
  and a long error notice. The 13 new shell captures are distinct.
- Worker disabled, deterministic simulated state, no paid requests or save edits.
- This is static typography evidence, not a complete click, motion, localization,
  fractional-window-scale, or error-recovery acceptance run.
- Scroll-boundary truncation below is real but does not imply inaccessible text:
  the affected content remains scrollable.

Evidence folders:

- [C world and UI captures](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/manifest.json)
- [C company captures](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c-shell/manifest.json)

All coordinates below are `(x, y, width, height)` in the full 1280×720 image.

## Prioritized findings

### T01 — P1: dynamic pixel titles lose characters

**Confirmed C regression.** In
[the long filename sample](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-artifact-unicode-long-title.png),
the heading around `(384,96,488,26)` replaces accented letters and an en dash
in `résumé–validation…` with missing-glyph boxes. ASCII `launch-brief.md` does
not expose the problem. The chosen Slab face has no system fallback.

Fix: reserve pixel lettering for controlled display copy, or use an explicit
glyph-coverage fallback for dynamic names. Filenames should preferably use a
readable proportional or code face; a friendly document title can have the
display role. Keep full filenames available without shrinking the header.
Verify accents, punctuation, unsupported scripts and truncation markers.

### T02 — P1: Activity spend is partly below the visible paper

**Confirmed C layout regression.** In
[running Activity](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-journal-active.png),
`AI spend today · $0.0198 USD` occupies `(806,694,308,20)` but the content viewport
ends around y702. Only the tops of its letters are visible. The previous
runtime capture showed the line in full. The approval state similarly exposes
a sliver of the next section heading at its lower scroll boundary.

Fix: move spend into a compact persistent Activity footer, or above optional
timeline content. Reserve space using actual Nunito metrics. Keep complete
essential lines visible at rest; do not solve this by shrinking text.

### T03 — P1: section headings and important numbers collapse to body size

**Confirmed C-preview role loss**, not an existing production font bug.
The generic preview changes the `title` role from 20px to 16px. Consequently
“Sound,” “Display,” milestone titles, “Today's work,” and summary amounts have
the same size as ordinary copy and buttons.

Evidence: [Settings](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c-shell/pause-settings.png)
at `(328,235,624,23)` and `(312,396,322,23)`;
[day summary](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c-shell/day-summary.png)
around `(308,210,664,114)`.

Fix: maintain separate display, subsection, body, metadata, action and numeric
roles. Use Nunito Bold around 20px for subsections and an explicit numeric style
for financial summaries; keep paragraph text at 16px.

### T04 — P1: document and source-code roles are being overwritten

**Confirmed C-preview role loss.** The production reader deliberately uses 18px
document prose and 16px monospace source. C's generic RichTextLabel override
makes both normal faces Nunito16. Meanwhile its shared mono role uses a coarse
pixel face left over from the three-option experiment.

Evidence: the code line `Owner: Mina` at approximately `(354,600,190,24)` in
[the Markdown reader](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-artifact.png)
looks unrelated to the surrounding prose;
[HTML source](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-artifact-source.png)
at `(354,198,410,339)` is proportional instead of monospace.

Fix: preserve Nunito18 for reading, proportional bold heading levels, and the
existing JetBrains Mono16 for code/source. Changing the UI font must not erase
content semantics. Keep the reader display heading at native Slab22 if used,
not its old hardcoded 24px.

### T05 — P1: important actions look like ordinary text

**Existing affordance/hierarchy issue, also visible with C.** “Create work
order,” “Attach Studio context,” “Review criterion evidence,” “Override,” and
“End day + save” use bold text with no resting-state visual boundary. Bold is
also used for static headings, so typography alone cannot communicate action.
Disabled quiet controls gain a filled box and can look more button-like than
their enabled state.

Evidence: [Assign](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-work.png)
around `(806,480,320,48)` and
[expanded Journey](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c-shell/journey-revision-actions.png)
around `(308,385,652,109)`.

Fix: add an intentional disclosure treatment to expanders and bounded secondary
buttons to consequential actions. Keep the current readable action type; do
not try to distinguish buttons merely by changing font families.

### T06 — P2: baseline Journey copy needs an unnecessary tiny scroll

**Confirmed C layout regression.** In
[collapsed revision](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c-shell/journey-revision.png),
the final explanation occupies `(292,528,684,49)` but scrolling content ends
near y557, hiding “files only.” This is ordinary scroll clipping, not text
painting outside its container.

Fix: recover roughly 20px from accumulated gaps/padding, preserving 16px copy.
Check actual shaped line heights and footer space after text changes. Expanded
evidence should still scroll normally; the baseline summary should fit cleanly.

### T07 — P2: rail and world type do not have explicit shared roles

**Confirmed coverage gap.** TEAM uses Slab22 while MINA/THEO use Nunito16.
That split can be intentional, but the preview currently chooses a rail font
conditionally on whether it fits. Names must not change family when their
length or container size changes. World nameplates and speech are directly
drawn with production GameFonts, so they still use Inter under the C overlay.

Evidence: [rail and world speech](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-world-speech.png),
rail header `(1165,18,100,52)`, names near `(1173,185,84,32)` and
`(1173,332,84,32)`; world card near the employee. No world-text clipping was
established in these samples.

Fix: declare the accepted rail-header/name split explicitly and migrate canvas
labels separately, using the same Nunito metrics and existing snapped origins.
Recheck fixed nameplate/speech baselines rather than applying a global scale.

### T08 — P2: case, separators and repetition add visual noise

**Existing copy polish.** Header statuses are uppercase while world statuses
are sentence case. A queued activity entry shows `queued ·` with an empty
reason. The offline page repeats the same explanation in black and red. The
evaluating screen repeats progress in guidance, status, disabled action and
footer.

Evidence: [queued activity](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-journal-queued.png)
around `(840,410,150,26)`;
[offline](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c/ui-error.png)
at `(814,89,304,70)` and `(814,237,304,45)`;
[evaluating](/Users/zhast/GitHub/startup-valley/game/tests/output/typography-audit-c-shell/journey-evaluating.png).

Fix: sentence-case status copy, no separator without a value, one primary state
message, and red reserved for additional actionable failure information.

## What already looks good

- Corrected C HUD: caption/value rows stay inside the paper.
- Sampled employee headings, tabs, Ask, Start/Queue, approval/promotion buttons,
  Studio file row, empty state and connection controls are readable.
- Existing prose contrast is not an observed problem in these samples; this
  pass did not perform a fresh exhaustive contrast calculation.
- C shell headlines fit. Large values `$123,456,789.00`, `+123456` and
  `$1234.5678` fit their summary cards. The two-line error notice and disabled
  copy fit. These captures prove typography fit, not retry behavior.
- Long chat is expected to scroll. The original 81-word comparison deliberately
  started at the top; its hidden conversion action does not prove a broken live
  auto-scroll. The normal long-history fixture shows the latest reply/action.

## Recommended implementation sequence

1. Codify C in production with explicit roles: Slab22 controlled display;
   Nunito20 subsection; Nunito16 body/actions; Nunito14 metadata; Nunito18
   documents; JetBrains Mono16 source/code. Give rail names and numeric displays
   explicit roles instead of conditional font selection. Preserve real bold
   and italic font variants and ship the selected Slab license.
2. Fix T01–T04 first: dynamic title coverage, always-readable spend, hierarchy,
   and document/code semantics. Implement C's corrected HUD geometry too.
3. Refit vertical spacing and action treatments, then normalize copy/casing.
   No new raster asset batch is necessary for these fixes.
4. Replace tests that hardcode Acid/Inter families, 24/26px display sizes, or
   antialiasing for every face with semantic C assertions. Retain meaningful
   effective-font, weight, italic, contrast and geometry checks. Extend the HUD
   painted-paper check to critical cards and distinguish intentional scrolling
   from overflow. Verify dynamic refreshes, tooltips/popups, long Studio paths,
   and window scaling before calling the migration complete.

Reproduction:

```sh
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_audit_c.gd
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_audit_c_shell.gd
```

The audit helpers under `game/tools/` apply ephemeral overrides only. Existing
production scripts, worker contracts, credentials and saves were not changed.
