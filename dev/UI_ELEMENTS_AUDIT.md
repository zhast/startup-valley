# UI elements audit — 2026-09-03

## Verdict

The notebook/wood direction is worth keeping. The current UI is not yet a
coherent, readable component system: ornament is stronger than information,
different surfaces use different typography, and important actions compete.
This is an audit and redesign specification, **not an implemented UI redesign**.
Production UI, worker behavior, credentials, and company saves are unchanged.

The most important discovery is a real font configuration defect, not simply a
subjective dislike of the typeface. `NunitoSans-Body.tres` requests `"wght": 550`,
but this Godot build recognizes the axis as `"weight"` or numeric tag
`2003265652`. The configured font resolves to the bundled font's default
**ExtraLight 200**. A runtime probe found the current BODY and default font use
the same font RID; a correctly configured weight 550 uses a different RID.
At 16px, one diagnostic string grows from 238px to 250px when corrected.
Changing the weight therefore requires layout review, not just a resource edit.

The real chat and reader controls also resolve normal, bold, italic and mono
font slots to this **same ExtraLight resource**. Markdown emphasis therefore
does not gain a distinct bold face. The retained diagnostic checks controls
inside a ready game scene, not an unparented theme sample.

Recommended order: **prove typography → reflow real content → approve one
component specimen → generate/normalize a small shared art kit → integrate
screen by screen → audit all states again**.

## Scope and evidence

- Inspected the 22 UI captures in the latest 27-state visual review at native
  1280×720, plus UI motion keyframes and current UI implementation.
- The five world-only captures are outside this audit. The new modular room is
  retained, not redesigned again.
- Audited the header/HUD, team rail, employee drawer, chat, Assign, Activity,
  Studio, artifact reader, notifications, world-space labels, and connection
  flow. Additional current company-shell fixtures and a font diagnostic are
  captured specifically for this audit.
- Final additional review: **15 fresh company-shell screenshots** and one
  native font-comparison specimen. In total,37 current UI state screenshots
  were inspected; these are visual fixtures, not37 end-to-end transaction tests.
- Screenshot coordinates below are `(x, y, width, height)` in the 1280×720
  canvas. Paths beginning `visual-review/` or `polish-audit/` are relative to
  `game/tests/output/`.
- Older `dev/UI_PRODUCT_AUDIT.md` is historical. Its blanket visual passes and
  campus-based composition no longer describe the current build. Nominal
  font-size and color checks did not establish readable final rendering.

## Prioritized findings

| ID | Priority / type | Evidence and problem | Proposed correction / acceptance |
| --- | --- | --- | --- |
| U01 | P0 · font configuration | `game/assets/fonts/nunito-sans/NunitoSans-Body.tres:7`; ExtraLight 200 renders despite the intended 550. Hairline prose throughout `ui-chat`, `ui-work`, `ui-artifact`, status and HUD. | Correct the supported axis key; explicitly bind all font roles; render before/after specimens. Verify the effective face/weight, then reflow every screen. No new font purchase or generated lettering needed. |
| U02 | P0 · typography/layout | All drawer tabs `(800,185,257,41)` use cramped Tiny5 on detailed wood. There is unused space to the right while Activity is squeezed between bevels. `game/ui/job_panel.gd:434`. | Four predictable widths across the available strip, 40–44px targets, quiet label centers. Test a readable medium-weight UI face for tabs/buttons; reserve Tiny5 for short display headings. Never shrink text to fit the old ornament. |
| U03 | P0 · reading-surface asset | `ui-artifact.png` `(366,196,548,420)`: baked dotted rules run through paragraphs and bullets. The texture is stronger than the thin text. | Use an unruled, low-contrast paper center for documents and forms. If notebook rules remain elsewhere, render them independently, faintly, and aligned with content. No decorative rule crosses document text. |
| U04 | P0 · decision hierarchy | `ui-journal-promotion.png` `(814,292,290,214)`: Add to Studio / Keep with job appear before inspectable files; the actual file list is below summary/usage, outside the first view. `job_panel.gd:764`, `:819`, `:2077`. | Delivery starts with file names and Preview, then outcome summary and the decision. The first view must let a player inspect what they are being asked to keep. Reuse current icons; layout first. |
| U05 | P1 · material hierarchy | Assign, Activity, and Studio nest outer wood, parchment, ornate cards, bordered inputs, and another framed footer. Studio's explanatory sentence is dressed like a clickable file. | Heavy wood only for outer structure/rail; one quiet paper layer inside; fine keylines/dividers for grouping. Decorative framing must not imply interactivity. |
| U06 | P1 · layout | `ui-work.png`: header occupies y28–184, tabs end at226, fixed action footer occupies about126px. Optional context and budget fall below the fold while confirmation refers to a hidden configured budget. | Compact header, prioritize title/brief, collapse optional context. Keep current budget visible beside confirmation. Use plain panels to validate the 368px drawer before new art. |
| U07 | P1 · interaction hierarchy | `ui-journal-active.png`: update field `(814,293,289,67)` and full-width Cancel `(814,370,289,40)` precede Current Work; Live Activity starts at y611. | Lead with current state and latest meaningful event; steering follows; make cancellation lower emphasis and clearly destructive. Give the timeline usable space. |
| U08 | P1 · product meaning/layout | `ui-chat.png`: Ask Mina and full-width Create work order are both large orange primaries. The conversion action is detached from the reply that caused it. Read-only Chat still resembles a disabled form. | Ask is the primary conversation action; a quiet contextual Create work order link belongs with the latest reply. For active work, show a purposeful read-only banner and Open Activity action instead of a disabled-looking composer. |
| U09 | P1 · status/usage | `ui-journal-active.png` `(824,482,270,76)`: cost is repeated and a decorative bar resembles job progress without a visible denominator. Queued work also shows an empty bar. | One cost line; optional usage details. If the bar remains, explicitly name it budget consumed and show the configured warning/limit accurately, never invented task progress or an invented dollar cap. |
| U10 | P1 · library/empty state | `ui-studio-empty.png` `(815,239,302,141)` has two explanatory cards and ~320px blank paper; `ui-studio.png` shows only a raw path. | One centered empty state and next action. File rows use readable title, type, owner/context, and secondary path. Reuse folder/tray art; normalize its scale. |
| U11 | P1 · recovery/layout | `ui-error.png` `(798,28,336,429)`: the paper ends halfway down the drawer. The error says retry from Settings while the visible actions are Save connection and Back to game. | A consistent connection surface with explicit missing-key vs worker-unavailable messaging and a matching recovery action. Do not ask players to resave a key for an unrelated worker failure. |
| U12 | P1 · first-use guidance | `ui-empty-team.png`: “Choose a teammate from the rail” appears with no teammates to choose; empty portrait, active tabs and disabled composer imply a broken screen. | Purpose-built first-hire state with one Journey/hire action. Hide controls that cannot yet be used. Reuse portrait frame later; no empty faux portrait. |
| U13 | P1 · state/control assets | Dropdowns, scrollbars, close controls and company buttons use different or identical hover/pressed treatments. Focus is a highly ornamental chartreuse ring, also used as a success accent. | One shared control-state contract: normal, hover, pressed, disabled, focused. Same geometry in every state; separate focus from success. Keep keyboard focus conspicuous, not merely a color shift. |
| U14 | P1 · game shell | `game/ui/company_panel.gd:147`, `:232`: title, Journey, Settings, hiring, day summary and reset all append labels/buttons into the same scrolling VBox. `_milestone_card` creates no visual card. | Shared modal shell, but purpose-specific composition: milestone cards, compact metric rows, settings rows, day-result summary, focused confirmation. Stable header/close/footer, scroll only the content. |
| U15 | P2 · HUD/world labels | `ui-team-rail.png`: tiny time and 14px earnings sit inside a large ledger; below each actor two ornate plaques dominate their sprite. Speech uses thin 14px text. | Retain the ledger silhouette but make values the hierarchy. Replace idle double plaques with a compact name treatment; reveal detail on hover/selection/attention. Reuse state icons with readable text where needed. |
| U16 | P2 · notification | `ui-completion-memo.png` `(24,18,250,120)`: a large paper toast covers the upper-left room for little information; View is a small, differently styled ink button. | Compact toast using the same paper and button vocabulary; one readable title, short detail and clear View action. Keep durable rail attention and existing dismissal behavior. |
| U17 | P2 · reader typography | `game/ui/artifact_viewer.gd:35–82`, `:110`, `:175`: DELIVERY, filename, read-only caption and document heading repeat hierarchy; source code uses a system-dependent font and Markdown fences do not explicitly select monospace. | One file title + small provenance/read-only line; body headings with real weights; deterministic bundled monospace for code and source. Audit long lines and selection/scroll behavior. |
| U18 | P1 · current-step presentation | Fresh `ui-elements-audit/shell/journey-revision.png` and `journey-ready.png`, `(320,229,623,35)`: NEXT says to evaluate even though evaluation already returned revision or readiness. `company_panel.gd:316` checks completed job before evaluation result. | Derive the next action from milestone/evaluation state; pin Revise or Complete above supporting criteria. Presentation fix, no worker change required. |
| U19 | P1 · Journey hierarchy | `shell/journey-available.png`: unavailable Theo heading/button occupies y289–377 above the available website objective. Long review details push the actual decision below the fold. | Current objective card first; collapse future hires/locked milestones; expandable evidence and a stable primary action. Reuse portraits/status primitives. |
| U20 | P1 · settings control | `shell/pause-settings.png`, `(320,397,624,153)`: sliders look like thin scrollbars with tiny same-color handles and no numeric values. | Proper slider track and20–24px knob, at least40px interactive row and live percentage. Settings should fit without losing its heading/exit to scrolling. |
| U21 | P2 · hire/save identity | `shell/hire-confirmation.png` lacks a person's name/portrait; `shell/title-continue.png` lacks saved day/company progress context. Both use the same oversized paper sheet. | Named hire card reusing the portrait; compact Continue card using existing saved fields. Size the composition to its content, not one generic632px-tall panel. |
| U22 | P2 · day-summary hierarchy | `shell/day-summary.png` `(320,128,638,285)`: revenue, reputation, real AI spend and completed work are a flat thin-text log. | Distinct stat blocks with explicit game-money versus real-AI labels, a short activity list and tomorrow's objective. Shared paper/icon components; no new full-screen illustration. |
| U23 | P1 · destructive focus | `shell/reset-confirmation.png` `(320,186,638,46)`: Back up + start new automatically receives focus and uses the same positive treatment as Resume/Start. | Initial focus on Go Back; distinct destructive confirmation hierarchy. Preserve recoverable backup behavior. Verify Escape, Enter and rapid input with a disposable fixture. |

These are current findings and proposed remedies, not claims that the remedies
have already passed. A source-level risk is distinguished from a visibly
captured defect where applicable.

## Intended design system

Keep the cozy-tech walnut notebook, Whop accents, employee portraits, right-hand
130px team rail and 368px drawer. The change is a clearer hierarchy inside that
silhouette, not a new decorative theme.

### Typography and layout contract to validate

| Role | Starting specification for the specimen | Rule |
| --- | --- | --- |
| Short display titles | Tiny5 at 20/30px, compared at native scale | Only brief headings, identity, selected HUD values; choose crisp tested sizes, not arbitrary minimums |
| Body / chat / document | Nunito Sans, verified weight 550, 16–18px | Test 18px chat/document versus 16px compact forms; approximately 1.4–1.5 line spacing; charcoal ink |
| Buttons / tabs / form labels | Nunito Sans 600–700, 16px starting point | Sentence case, clear silhouettes; do not compress glyphs or shrink below the approved specimen |
| Secondary metadata | Nunito Sans 550, at least14px | Reserve for secondary facts, never the only explanation of a required action |
| Code | One explicitly bundled mono face, 16px | Same face for fenced code and source; no system-font dependence |

Bind normal/bold/italic/monospace roles explicitly rather than relying on
theme fallback. Resolve actual font resources during the test, not only the
integer `font_size`. Avoid light outlines around prose. Essential text uses
charcoal or a verified dark semantic ink; bright Whop colors are accents,
not thin body text. Contrast must be checked against the actual rendered
surface and state, not only flat palette constants.

Use a 4px spacing rhythm with 8/12/16px common gaps. Validate 40–44px minimum
important hit targets, stable control heights, and text-safe content insets.
Prototype a shorter employee header before locking measurements. Essential
form fields and the budget/confirmation summary take priority over oversized
portraits, decorative spacers and repeated help text.

### New-art decisions

Most existing concepts already exist in the runtime. More isolated decorative
assets would not solve the current failures. Build **one coordinated kit** and
reuse it across all screens; keep live text and values in Godot.

| Component family | Disposition | Initial native contract, to lock after layout |
| --- | --- | --- |
| Outer walnut shell, rail structure, portraits, ledger frame | Reuse; normalize only where required | Preserve approved silhouette and fixed corners; never rescale whole screens |
| Quiet paper and subtle inner panel | Normalize existing paper first; generate only if cleanup cannot preserve a clean center | 64×64 nine-slice frame with protected12px edges; optional32×32 low-detail paper repeat; no baked text/rules/rivets in reading area |
| Buttons and tabs | Redesign as one shared asset family | 96×48 nine-slice buttons; 80×40 tab prototype; aligned normal/hover/pressed/disabled states, fixed border thickness and baseline |
| Input/dropdown/close/focus/scroll controls | Redesign coordinated primitives | 96×48 input nine-slice; separate16×16 chevron/close glyph; 44×44 close target; 2px focus outline; restrained scrollbar with independent track/thumb |
| Chat bubbles | Simplify/normalize, then generate if needed | 64×64 extensible body plus separate small fixed tail; calm center, thinner border, consistent content margins; no oversized gold frame around every utterance |
| File/delivery/milestone cards | Code/layout using common paper and dividers | Same title/metadata/status/action slots; no separate screen bitmap or ornament for each worker state |
| Status and small action icons | Normalize current icons; generate only missing/illegible symbols | One native16×16 or20×20 grid after specimen approval; distinct shapes for available, working, queued, approval, delivered, failed, off-shift |
| World labels and toast | Simplify using shared paper; small new assets only if necessary | Compact name plaque and attention state; toast sized around real text; no repeated stacked medal-like borders |
| Settings sliders | Small new control only if existing scrollbar parts cannot read as a slider | Fixed-height track, independent thumb, same focus/disabled language; numeric value in code |

For any generated family: retain the original master, exact prompt, native
dimensions, alpha policy, slice margins, content-safe inset, state alignment,
and deterministic normalization command. Require original Startup Valley art,
front-facing orthographic pixels, consistent light direction/palette, no text,
logos, fake transparency checkerboards, or complete composited UI screens.
State variants must not change geometry when hovered or pressed.

## Implementation sequence after approval

1. **Typography proof and central tokens.** Fix the supported weight axis in a
   branch, bind every text role, render real strings on current paper at100%.
   Compare the proposed type sizes before committing to a new font family.
2. **One complete drawer specimen, with plain surfaces first.** Chat, Assign,
   Activity and Studio use the corrected fonts and consistent spacing. Validate
   long content and decision hierarchy, especially Preview before promotion.
3. **Approve one UI kit.** Show shared buttons, tabs, input, paper, bubble,
   status, focus and scroll primitives together at native size. Generate only
   the families still needing art; do not generate another broad batch first.
4. **Apply shared components throughout.** Drawer, rail and ledger; then reader,
   toast/world labels; then Journey, Settings, connection, day summary and title.
   Preserve chat/work/steering contracts and all worker behavior.
5. **Visual and interaction acceptance.** Re-capture all states, compare against
   approved specimens, exercise actual input and keep fixes within the UI.

## Acceptance must be stronger than the existing tests

The old checks can pass while text still looks wrong: they test nominal sizes
and a few flat color pairs, not the effective variable-font weight or texture
behind the text. Some motion scenario descriptions are broader than their
actions. Distinct image hashes only prove that images differ.

Required additions for the implementation pass:

- Resolve font family/weight for normal, bold, italic, button, tab and code in
  every visible state. Check body versus metadata roles separately. Include
  dynamically created chat, file rows, modal buttons and company cards.
- Render long names, large earnings, long file paths, multiline button copy,
  long chat, many files and full criterion evidence. Check real content bounds,
  safe insets and clipping after the heavier font changes width.
- Check actual text/background pairs across normal/hover/focus/disabled/error
  surfaces; no small text directly on high-detail wood or dotted rules.
- Every important screen has one clear next action. Delivery files can be
  previewed before Add to Studio; empty team, Studio and error states lead
  somewhere useful; spending information is visible before confirmation.
- Capture each control state with the control actually visible and enabled as
  intended. Input focus assertions must verify visibility and focus ownership.
- Replace claimed-but-unexercised motion cases: actually open/select a dropdown,
  type into a visible field, disable a control, scroll/close/reopen a long
  reader, preview then promote a delivery, and preserve separate error and
  recovered checkpoints. Never count a hidden steering/title field as tested.
- Include all company-shell states and milestone outcomes in the regular
  regression harness. The existing27 stills omit them; this audit's new15
  shell fixtures now provide a baseline, not behavioral acceptance.
- Review normal1280×720 and aspect-preserved native windows at practical size.
  No screenshot zoom should be required to understand body copy or labels.
- Preserve existing transitions, focus trapping, UI/world click isolation,
  dispatch contracts and safe save behavior. No paid AI is required for this UI
  verification.

## Audit artifacts

Run the two dev-only evidence tools from the repository root with the actual
renderer (not `--headless`):

```sh
godot --path game --script res://tools/audit_ui_typography.gd
godot --path game --script res://tools/capture_ui_shell_audit.gd
```

They use `STARTUP_VALLEY_NO_WORKER=1`. The font comparison creates corrected
variants in memory only. The shell capture uses fresh scenes with explicit
company projections; it does not click transaction buttons or access real
saved-company state. All renderer processes exited after capture.

- `game/tests/output/ui-elements-audit/typography/diagnostics.json`: supported
  axes, effective resource identities for real controls, and glyph metrics.
- `game/tests/output/ui-elements-audit/typography/font-comparison.png`: current
  weight200 (left), intended550 (middle), candidate600 (right), on flat paper
  and the existing parchment texture. The existing parchment is already usable
  with corrected weight; the document's separate ruled texture remains a
  problem.
- `game/tests/output/ui-elements-audit/shell/manifest.json`:15 current captures,
  fixture modes, hires, scroll positions and paths. Includes title/new/continue,
  hiring, onboarding/available/active/revision/ready Journey, Settings top/bottom,
  closing, summary and reset confirmation.

The final recommendation is **Nunito550 prose first**, with600–700 for compact
labels/actions, restrained Tiny5 display titles, and substantially quieter
interior framing. The first implementation should prove the real corrected
fonts in the drawer before any asset generation. A code-native diagnostic is
more reliable for typography approval than text painted into an AI mockup.

Only this report and the two dev-only evidence scripts were added for the
audit. No runtime UI/resource was changed, no new art was generated, and no
paid job, save mutation, commit or push was performed. Existing uncommitted
work was preserved. `git diff --check` passed.
