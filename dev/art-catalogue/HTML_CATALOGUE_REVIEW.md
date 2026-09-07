# Offline catalogue browser review

Reviewed 2026-09-04 at approximately 10:00–10:12 UTC in the Codex in-app
browser, at its native 1280×720 viewport. This is a developer reference page,
not a redesign of the game UI or a new approval of its staged assets.

## Verified

- The header clearly distinguishes 42 families / 168 directional slots,
  4 accepted runtime views, 22 staged views and 142 missing/blocked views.
  The 105-master source cutoff is dated; later work links to the run ledger.
- Approved filtering shows one family and four archive views. Lawyer role
  filtering shows six families and 24 slots. Combining Lawyer with Approved
  correctly yields no family. A nonsense search also gives the explicit
  no-results state and an available Reset button.
- Native N/E/S/W archive previews remain unscaled and side by side. Missing
  directions use a written absence state, never a borrowed South picture.
- Search focus is visible; text and controls fit the tested viewport. This
  was not a phone, narrow-window or accessibility-assistive-technology audit.
- The initial 4× button hid South in transparent upper-left canvas padding.
  The corrected builder measures native opaque bounds, centers the enlarged
  pane on the object, preserves its full canvas and uses exact nearest 4×.
  Root rechecked the actual browser: cabinet detail is now immediately visible;
  zoom-out returns to the normal 1× preview and its 4× button.
- The builder reports 45 self-tests, deterministic HTML, 150 measured preview
  bounds, 127 bounds matching existing catalogue metadata, and 1,120 valid
  local links. Those filesystem checks are separate from browser navigation.

## Browser limitation

The in-app browser blocked direct navigation to a linked local Markdown prompt
with `ERR_BLOCKED_BY_CLIENT`. No bypass was attempted. The prompt exists and
its contents were independently read from the project; this is not evidence
that the source file is missing. The HTML/native-image review is complete,
but a browser-rendered Markdown-document navigation pass is **not claimed**.
The linked Markdown files remain directly openable as project documents.

## Rebuild and local preview

```sh
node dev/tools/build_art_catalogue_html.mjs --write --self-test
node dev/tools/serve_art_catalogue.mjs 8765
```

The preview server is read-only, binds only 127.0.0.1, and serves a restricted
set of project art/developer files. It is not a worker listener or a shipped
dependency. Stop it with Ctrl-C when review is finished. The standalone
`index.html` also retains relative links for an offline project copy.

Files: [catalogue](index.html), [builder](../tools/build_art_catalogue_html.mjs),
[local preview server](../tools/serve_art_catalogue.mjs).
