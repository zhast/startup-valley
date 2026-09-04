# Whop typography implementation — 2026-09-03

Implemented the user-approved Acid Grotesk/Inter pairing across the current
1280×720 game interface. This replaces functional Tiny5/Nunito roles, retains
the approved office/wood/parchment/portrait artwork, and does not change the
worker, contracts, provider, persistence, or game economy.

## Font roles and layout

| Surface | Font and native size |
| --- | --- |
| Company, connection, employee headings | Acid Grotesk Medium, 26px |
| Artifact reader title | Acid Grotesk Medium, 24px |
| Day, time, gross earnings | Inter Semibold, 24px, same row and measured baseline |
| HUD captions | Inter Medium, 14px, aligned Day / Time / Earned |
| Team rail heading and employee labels | Inter Semibold, 18px |
| Sections | Inter Semibold, 20px |
| Tabs, buttons, inputs, chat, instructions | Inter Regular/Medium/Semibold, 16–18px |
| Secondary metadata | Inter Medium, 14px |
| Source code | Existing JetBrains Mono, 16px |

All production UI references use `GameFonts`; explicit overrides and the
shared theme now agree. Real Inter italic and semibold-italic OTFs cover rich
text. Font imports enable antialiasing and disable operating-system fallback.
Pixel-art textures still use nearest filtering. No synthetic bold/slant or
variable-weight lookup is required for the new fonts.

Only the six required OTF files were copied from the official Whop typeface
archive. The archive's trial-named variable font was not bundled. Static Acid's
default double-storey a/g and high ascenders match Whop's specification; the
alternate features are explicitly disabled using numeric OpenType tags.
[Font provenance, hashes, and license references](../game/assets/fonts/README.md)
include the owner's confirmed Whop permission and Inter's OFL.

The HUD keeps gross revenue distinct from company cash and real AI spending.
Values never shrink to fit: day uses its numeric value plus the Day caption,
and larger earnings use K/M/B/T abbreviations with exact cents in the tooltip.
Tests cover days 1/12/123/999, several times and earnings up to trillions.

The wider typefaces required a 100px Ask button and a full 44px header-close
reservation. Long employee names have bounded, tooltip-backed labels. Company
and connection headings use mixed case. Essential instructions, spending
consequences and errors were promoted from 14px metadata to 16px body text.

## Verification and visual evidence

Tests now verify actual font families, static-face weights and rendering IDs,
not only nominal resource names. They check exact role assignments, HUD value
and caption baselines, measured text widths/heights, protected button insets,
long identities, wrapped instructions, input focus, and real mouse/keyboard
events through Godot's viewport.

- Godot import and project validation passed.
- Foundation, drawer, company, and reader/HUD suites passed headlessly and
  with the macOS renderer.
- Main gameplay tests, UI-flow regressions, complete-game real-input tests,
  world-label presentation, window-presentation and graphics regressions passed.
- Recaptured all 27 main stills and 15 company-shell stills at 1280×720,
  plus focused UI evidence. Full-size inspection included Chat, Assign,
  approval, connection, Settings, Journey, reader and large-value HUD.
- Deterministic world/UI motion recordings were refreshed with the worker
  disabled. No paid requests or real saved-company mutations were used.

Final focused checks (all zero failures):

| Suite | Headless | macOS renderer |
| --- | ---: | ---: |
| Foundation | 99 | 103 |
| Drawer | 944 | 954 |
| Company | 928 | 944 |
| Reader / HUD | 132 | 132 |

Motion: 1,018 UI frames and 2,455 world frames, both at 30 FPS and six scenarios
per suite. `validate_polish_audit.gd` passed against both refreshed recordings.

The static harness previously waited a number of frames, which can be shorter
than a fade-in on a fast renderer. It now waits 220ms for the longest 180ms UI
entrance before taking stills. Final captures use fixed 30 FPS as well. This
prevents intermediate opacity from masquerading as poor text contrast; live
animation durations were not changed.

Useful evidence:

- `game/tests/output/whop-typography/typography-comparison.png`: legacy
  reconstruction on the left; actual current ClockPanel and Whop specimens
  on the right. It is not a new mockup pasted into the game.
- `game/tests/output/whop-typography/diagnostics.json`: current font metadata,
  static weights and measured HUD fit.
- `game/tests/output/visual-review/ui-chat.png`: live drawer, rail and HUD.
- `game/tests/output/ui-elements-audit/shell/pause-settings.png`: Settings.
- `game/tests/output/ui-redesign/reader-hud/`: reader, HUD, and regression results.
- `game/tests/output/polish-audit/`: recordings, per-scenario keyframes and manifests.

## Scope of acceptance

The requested font migration and associated readable layout are implemented
and technically verified. The user still owns final visual approval. This is
not a blanket claim that every UI polish issue is fixed: quiet-action
affordances, the small painted close glyph, and filename-first reader hierarchy
from the previous audit remain separate work. No new raster art was generated,
and no commits or push were made for this request.
