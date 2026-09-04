# UI consistency re-audit — 2026-09-03

**Follow-up:** the user chose Whop's Acid Grotesk/Inter pairing and confirmed
font permission. The typography/HUD corrections are now implemented; see
[Whop typography implementation](WHOP_TYPOGRAPHY_IMPLEMENTATION.md). This audit
is historical: its Nunito-only recommendation was superseded by that choice.
Quiet-action affordances, the small close glyph, and reader filename hierarchy
are separate remaining polish items, not claimed fixed by the font migration.
Current shared capture folders have been refreshed; the original comparison
remains under `game/tests/output/ui-consistency-audit/`.

## Verdict

The user's criticism is supported by the current rendered game. Day, time and
money are deliberately assigned different fonts, sizes and vertical layouts.
Tiny5 also remains on functional labels throughout the interface. Correct font
loading and minimum font sizes did not make that combination visually coherent
or sufficiently readable.

The previous report's blanket visual acceptance was too broad. Its functional
fixes and regression results remain useful, but **typography and first-glance
control clarity are reopened**, not accepted on the strength of test counts.

Recommendation: use **Nunito Sans for every functional UI label and value**.
Keep the cozy pixel identity in the wood, paper, portraits, icons and office
art. Tiny5 should not carry day/time, employee identities, navigation or modal
headings. An optional future title logo is a separate branding decision.

This was an audit, not another production redesign. No runtime UI, font asset,
worker, credential, save, or gameplay source was changed. The comparison's
candidate overrides exist only inside a developer diagnostic scene.

## Evidence reviewed

- Regenerated all 27 main captures and all 15 company-shell captures with the
  actual Godot 4.7.2 renderer, worker disabled: 37 UI states plus five office
  stages. Full-size inspection focused on HUD, Chat, connection, Journey,
  Settings, day summary, reset and reader; overview coverage came from the
  complete capture sets and independent reviewers.
- Inspected current font resources, role assignments, control geometry and
  the tests that produced the previous acceptance claims.
- Created `game/tools/audit_ui_consistency.gd`, a read-only 1280×720 specimen
  using actual `ClockPanel` instances and bundled fonts. It records effective
  HUD assignments and an in-memory candidate in
  `game/tests/output/ui-consistency-audit/diagnostics.json` and
  `typography-comparison.png`.
- Existing native-window evidence confirms the same visual split outside the
  fixtures. No new OS-level native playtest or paid job was needed for this
  audit; no claim of a new native-input pass is made.

Coordinates below are `(x, y, width, height)` in the 1280×720 canvas. Main
captures are under `game/tests/output/visual-review/`; shell captures are under
`game/tests/output/ui-elements-audit/shell/`.

## Findings and proposed corrections

| ID | Priority | Observed problem and evidence | Proposed correction |
| --- | --- | --- | --- |
| C01 | P0 | **The HUD has two incompatible numeric systems.** Day/time use Tiny5 30px; money uses Nunito Bold 20px, with a Body 14px caption. Day/time center inside 42px-high rows; money has a separate upper value row. See `ui-chat.png`, HUD `(371,8,408,68)`, and `clock_panel.gd:30–34`. | One family, weight, size and value baseline across all three fields. Prototype Bold 24px values plus consistent 14px captions: Day, Time, Earned. Rename the awkward “Game earned” caption without confusing gross earnings with cash. Keep exact values accessible and test their fit. |
| C02 | P0 | **Pixel lettering is still doing essential reading work.** Blocky/detached-looking letterforms are conspicuous at native size in Mina/Theo, TEAM, rail names, CONNECT AI, COMPANY JOURNEY, PAUSED and day/reset headings. Employee name `(890,48,190,40)`, rail `(1165,18,100,366)`, connection heading `(814,48,290,40)`, Journey heading `(290,84,325,32)`. Reader and subsection headings meanwhile use smooth Nunito. | Remove Tiny5 from functional UI. Use Nunito Bold 24–26px for screen/employee headings, 20px for sections, 16–18px for rail labels. Use sentence case consistently. Do not solve this by simply enlarging the same pixel font again. |
| C03 | P1 | **Some required instructions are still classified as metadata.** Settings movement help and “Real AI work can still finish,” evaluation-spend explanation, and footer errors use the 14px meta role. See `pause-settings.png`, `(312,448,655,38)`; `company_panel.gd:140,186,245,424`. | Reserve 14px for secondary provenance, timestamps and compact captions. Use at least 16px for instructions, spending consequences and recovery messages. Reflow the layout if they require another line. |
| C04 | P1 | **Quiet actions often look like noninteractive labels.** Create work order, Review criterion evidence, Show chapter roadmap, End day + save and Override lack a persistent border, underline or disclosure marker. Different consequences share the same bold-text appearance. See `ui-chat.png`, `(850,407,270,64)`; `journey-revision.png`, `(308,356,664,94)` and `(292,477,694,44)`; `cozy_ui.gd:62`, `company_panel.gd:402`. | Define distinct persistent affordances: chevron for disclosures, underline or icon for contextual links, a restrained secondary button for navigation, and differentiated treatment for override. Hover feedback alone is insufficient to tell players what is clickable. |
| C05 | P2 | **Close targets are technically large but visually weak.** The 44px button contains a 16px texture whose nontransparent glyph is only 10×10px. It resembles a stray mark next to parchment fasteners. Settings target `(924,84,44,44)`, reader `(882,86,48,48)`; `cozy_ui.gd:147`. | Increase the painted X to about 14–16px and/or give it a quiet persistent control surface. Keep the 44px hit target and keyboard focus. Test visible glyph bounds separately from button bounds. |
| C06 | P2 | **The reader is still file-system-first.** A large, truncated kebab-case filename dominates its header; a similarly prominent document heading appears immediately below. A tooltip preserves data but does not improve first-glance hierarchy. See `ui-redesign/reader-hud/reader-top.png`, filename `(386,88,490,44)` and document heading `(354,201,550,32)`; `artifact_viewer.gd:51,106`. | Prefer a human-readable artifact or document title when available; keep filename/path and provenance secondary. For source files, the filename can remain the title. Avoid redundant equally prominent titles. This can remain presentation-only. |
| C07 | P1 | **The acceptance tests encode the questionable design.** Company tests require Tiny5 for display roles; drawer tests call an allowed face plus minimum size “readable.” HUD tests check money fit, not group coherence. | Separate technical conformance from visual acceptance. Replace the Tiny5 requirement with functional-role rules; assert matching HUD font/weight/size and value baselines. Review native-size glyphs and first-glance action meaning, then obtain user acceptance before calling the look complete. |

These seven findings are not seven missing asset packs. C01–C04 and C06–C07
are primarily typography, layout, component semantics and verification work.
C05 needs only a small code-authored glyph/control adjustment. A broad new
ImageGen batch would not address the central problem.

## Exact current typography inventory

| Surface | Current effective assignment | Source |
| --- | --- | --- |
| Day / time | Tiny5, 30px | `game/ui/clock_panel.gd:30–31` |
| Earned amount | Nunito Sans weight 700, 20px | `game/ui/clock_panel.gd:32–33` |
| Earned caption | Nunito Sans weight 550, 14px | `game/ui/clock_panel.gd:34` |
| Team title and rail names | Tiny5, 20px; names uppercase | `game/ui/job_panel.gd:277,1152` |
| Employee identity | Tiny5, 30px | `game/ui/job_panel.gd:514` |
| Connection heading | Tiny5, 30px through display role | `game/ui/job_panel.gd:337` |
| Every Company modal heading | Tiny5, 30px through display role | `game/ui/company_panel.gd:133`, `game/ui/cozy_ui.gd:160` |
| Reader file title / section headings | Nunito Bold, 22px / 20px | `game/ui/artifact_viewer.gd:51`, `game/ui/cozy_ui.gd:165` |
| Actions / body / metadata | Nunito 700 at 16px / 550 at 16–18px / 550–600 at 14px | Shared components and font resources |

Not every `DISPLAY` search hit is active. Chat's preliminary size override is
replaced by shared button styling. Founder HUD helper calls replace their
initial display face with Nunito. World labels are already Nunito. Future
changes should use semantic helpers directly instead of temporary overrides
that make a source-only inventory misleading.

Tiny5's import disables antialiasing, hinting and subpixel positioning. The
comparison shows the current letterforms at their actual 20/30px sizes; this
is not merely a low-contrast or small-window issue. This audit does not claim
that Tiny5 is universally unusable—it is unsuitable for the current functional
UI and the user's readability requirement.

The old ExtraLight defect has **not** returned: the diagnostic confirms BODY's
effective RID equals an independently constructed weight-550 variant. The
base font's family-name metadata can still include “ExtraLight”; it is not
proof of the applied variation weight. Likewise, measured DAY 1/12/123/999
strings all fit the 116px day field. The HUD finding is inconsistent visual
hierarchy, not an invented clipping failure for those values.

## Recommended next implementation pass

1. **Approve one native typography specimen.** Start with the right side of
   `typography-comparison.png`: one Nunito family for functional UI. It is an
   audit prototype, not approved or integrated production art.
2. **Fix the shared roles and HUD together.** Common values/baselines/captions;
   functional headings in Nunito; remove active Tiny5 overrides throughout
   rail, drawer and Company. Preserve the approved wood/paper composition.
3. **Fix text semantics and affordances.** Promote essential 14px instructions,
   distinguish links/disclosures/buttons, improve the visible close glyph,
   and simplify the reader title hierarchy.
4. **Replace the misleading gates.** Keep effective-font, clipping, contrast,
   focus and dispatch checks, but add role-based checks, coordinated HUD
   geometry and painted-icon bounds. Existing gameplay behavior stays intact.
5. **Review the actual game before broad acceptance.** Show Chat+HUD, Journey,
   Settings, connection, day summary and reader at 100% scale with representative
   content. Test different times/currency values, long titles and focus states.
   Check practical native windows too. Report what was technically verified
   separately from what was visually approved; do not substitute test counts
   for the user's readability judgement.

Suggested typography contract to validate, not silently impose:

| Role | Candidate |
| --- | --- |
| HUD values | Nunito 700, 24px, one aligned value row |
| Functional screen/employee headings | Nunito 700, 24–26px |
| Section headings | Nunito 700, 20px |
| Actions/tabs/rail | Nunito 700, 16–18px |
| Prose, instructions and errors | Nunito 550–600, 16–18px |
| Secondary metadata/captions | Nunito 550–600, 14px |
| Source code | Bundled JetBrains Mono, 16px |

## Verification performed in this audit

```sh
godot --path game --fixed-fps 60 --script res://tools/capture_visual_review.gd
godot --path game --fixed-fps 60 --script res://tools/capture_ui_shell_audit.gd
godot --path game --fixed-fps 60 --script res://tools/audit_ui_consistency.gd
git diff --check
```

All capture commands exited successfully. The close texture's alpha bounds
were measured as `10x10+3+3`. No production fix, new generated art, paid job,
real-save change, commit or push was performed. All renderer processes started
for this audit exited. Existing work was preserved.
