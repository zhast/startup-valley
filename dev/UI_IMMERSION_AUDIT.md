# UI immersion and component consistency audit

Date: 2026-09-03. Original audit plus an implementation checkpoint.

## Checkpoint status — implementation saved, final acceptance pending

The findings below preserve the original before-evidence, not the current
implementation state. A user-requested Git checkpoint now includes the shared
notebook material family, native small glyphs/portrait crops, screen integration,
anchored world callouts, and regression/capture tooling. The approved C font
roles, office, worker contracts, persistence and provider behavior are unchanged.

Implemented changes include the separate Activity ledger with a stable spend
footer and Back/Escape restoration, synchronized attachment disclosures, full
collapsed Assign controls, full-height founder-only onboarding paper, clearer
connection/usage copy, and single approval/delivery cues during drawer pause.
Shared styling covers tabs, quiet actions, input/card/dialogue surfaces, focus,
close controls, dropdown marks, scrollbars and slider tracks.

Focused rendered verification passes: foundation 200, drawer 2,223, company 3,702,
reader/HUD 222, and world 419 checks, all with zero failures. The latest drawer
run has 17 native captures and all four spend-ink cases contain zero pixels
outside the safe paper; the latest world run has 10 captures including actual
approval and completion events. Headless runs cover the same components plus
gameplay/UI flow and project validation. These counts establish specific
technical properties, not final human aesthetic approval.

Current focused evidence (generated locally, excluded from Git):

- [Drawer results](../game/tests/output/ui-redesign/drawer/results.json)
- [World-callout results](../game/tests/output/ui-material-world/results.json)
- [Native material specimen](../game/tests/output/ui-material-specimen/manifest.json)

The broader 37-state main capture, 14-state shell capture, motion audit and
five-mode scaling run passed before the last Assign/onboarding/copy and live
attention-cue fixes. They must be refreshed and reviewed before final acceptance.
The latest live-event world images also catch part of the drawer entrance fade;
they prove the world cue, not a settled whole-screen composition. All 12 audit
findings still require final evidence-backed dispositions. No paid calls or
real-save changes were made. This checkpoint is not completion of the goal.

Reproduce production evidence without overwriting the original audit captures:

```sh
godot --path game --resolution 1280x720 --script res://tools/capture_ui_material_specimen.gd
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_ui_material_audit.gd -- --after
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_audit_c_shell.gd -- --material-after
sh dev/tools/build_ui_immersion_contact_sheets.sh
```

## Original audit

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
