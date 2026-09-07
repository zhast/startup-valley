# Catalogue browser review — September6,2026

This is a real-browser review of the developer catalogue, **not** a Godot
gameplay acceptance claim. The ordinary game remains unchanged. The local
read-only server and a fresh ephemeral headless Chrome profile were used; no
personal browser profile, worker, credentials, saves or external requests.

## Final frozen acceptance

**30 real-browser checks pass**, eight screenshots, all inspected by root,
at 1280×720 and 960×720. The final catalogue shows 42 families / 168 accepted
views: 36 runtime-integrated, 132 approved passive, zero staged or missing
family views. Evidence:
`game/tests/output/art-catalogue-browser-final-20260906-v2/results.json`.

- Catalogue SHA-256: `ea1c950e82025a935ecf536c9d7b0514289797065b936e66dd0d9c7844285c65`.
- HTML SHA-256: `4abf4d778b03b35f64d56671532a08650575f0d513feaee76dd182a143c0a1d2`.
- Browser: isolated Chrome 152.0.7977.82; 23 local requests, no external
  requests, script errors, worker starts or personal-save access.
- Source validator: 30,626 checks and 107 self-tests; builder: 56 self-tests,
  972 previews, 5,518 valid local links and 1,730 distinct linked files.
  Explicit generated-HTML freshness check passes.

Two closeout defects in the review tooling were caught and corrected:

1. The old builder self-test assumed at least one incomplete family existed.
   All-accepted inventory exposed an `undefined.id` error. It now explicitly
   checks 168/0/0 and uses synthetic accepted and mixed missing/staged records
   for positive/negative filter coverage. No absent branch is silently skipped.
2. An early `art-catalogue-browser-final-20260906` run passed 24 interaction
   checks against stale 136-view HTML. It is preserved as an incomplete
   snapshot review, **not final acceptance**. The browser test now binds the
   embedded source hash, served HTML bytes, every rendered direction's exact
   lifecycle, visible totals, and unchanged source/HTML bytes throughout.
   `art-catalogue-stale-snapshot-20260906/failure.json` proves stale HTML is
   rejected. The final v2 run above passes only after regeneration.

Native/4× previews, actual Open PNG/back, filter typing, native select input,
empty states, reset, host navigation, keyboard focus and both responsive widths
were retested. The checker grid is explicitly the viewer background, not
opaque image transparency. Optional supporting experiments stay outside the
42-family counts, even when no staged family matches the filter.

## Historical result and correction

**23 real-browser checks pass**,8 screenshots, at1280×720 and960×720.
The main agent inspected native/4× cafe previews and the responsive layout.
Mouse search/zoom/reset/host links and keyboard type-ahead/Enter/Tab focus work.
All42families/168slots are present; filtered statuses match the actual JSON.
Accepted library and runtime labels remain distinct. Native image dimensions
are exact and enlargement is exactly4× with nearest-style pixel sampling.

One genuine layout defect was corrected: a long unbroken historical study
paragraph extended to1291.84px in a1280px viewport, producing12px of page-level
horizontal overflow. `p,code{overflow-wrap:anywhere}` in the HTML builder fixes
the text flow without hiding overflow or shrinking images. Native images still
scroll inside their own previews; page-level overflow is now zero at both widths.

Two failed test versions are preserved:

- Initial browser fixture assumed synthetic arrow navigation would control a
  macOS headless native select popup; it did not. Actual keyboard type-ahead
  selects the visible Staged option correctly. This was a fixture issue, not a
  catalogue repair. The fixture also corrected its expected-state field from
  nonexistent `generation_status` to the actual `status` before relying on it.
- Second run reached the responsive check and correctly failed on the12px
  paragraph overflow. Third run passes after the narrow CSS correction.

## Frozen evidence

- `game/tests/output/art-catalogue-browser-20260906-2007/failure.json`
- `game/tests/output/art-catalogue-browser-20260906-2007-v2/failure.json`
- `game/tests/output/art-catalogue-browser-20260906-2007-v3/results.json`
- The third directory contains header, native/4×, staged, empty, keyboard focus
  and two responsive screenshots.

Chrome152.0.7977.82; catalogue SHA
`0d243b4bfc1cd8c43886ffbf2376c512fea0db0142efb0ece89629b621b0aef7`;
HTML SHA`e1dacbf24cc7d3274d5ee173bafb175967affc834f80e4fa9aab4a69033c3ad0`.
This frozen run covers120accepted/4staged/44missing slots. Later catalogue
approvals require a fresh browser run and must not inherit these exact counts.

The test uses bundled Playwright via an explicit module path and the installed
browser executable. It adds no project or production dependency. Entry point:
`dev/tools/test_art_catalogue_browser.mjs`. The existing local-only
`dev/tools/serve_art_catalogue.mjs` is a dev review tool, not a worker listener.

A fourth frozen run adds one real **Open PNG** click and decoded-dimension
assertion:24checks/0, same catalogue/HTML hashes, evidence under
`game/tests/output/art-catalogue-browser-20260906-2007-v4/`. The exact native
PNG opens and browser Back restores the catalogue. The third23-check result
above remains valid history rather than being silently rewritten.
