# Browser playtest

The playtest drives the **exported Godot game**, not a replacement HTML UI. It
presses the canvas controls and observes real worker responses through the
bridge's read-only diagnostics. It never sends protocol requests, supplies fake
responses, or calls a provider.

## Reproduce

Build and serve the game using the commands in [README.md](README.md), then run:

```sh
node tests/browser/playtest.mjs
node tests/browser/loading.mjs
```

The test uses the `playwright-core` dependency installed by `npm ci` in `web/`.
It finds an existing Google Chrome installation on macOS or at
`/usr/bin/google-chrome` on Linux. Set `CHROME_PATH` to use another installed
Chromium/Chrome binary (`BROWSER_EXECUTABLE` also works). No browser is
downloaded by this script. `BASE_URL` defaults to `http://127.0.0.1:5177` and must
be localhost. `ARTIFACT_DIR` optionally selects the output directory; otherwise
screenshots and JSON evidence go into a new temporary directory.

A fresh isolated browser context protects existing player saves. The test
closes its browser after either success or failure. A failed check preserves
`failure.png` and `failure.json`, including the observed response and console
errors.

## Coverage

- Load the actual Godot 4.7.2 WebAssembly export and open an OPFS SQLite save.
- Start a company, hire Mina through the canvas, and develop a Fitness Course.
- End three days, release the product, and confirm real sales and game cash.
- Move the founder by clicking the floor.
- Open Settings and Renovate, select the rendered founder desk, move it with
  the keyboard, and confirm the worker's durable save.
- Reload the page and compare the company, hired staff, released product,
  founder coordinates, furnishing placement, and furnishing revision.
- Open a second tab in the same context and verify that it cannot take over the
  active save.
- Fail on JavaScript/Godot console errors or provider/credential mutations.

The fixed 1280×900 browser viewport exercises the game's 1280×720 canvas with
letterboxing. The screenshots are also reviewed for layout and asset problems;
the diagnostics alone cannot prove that the artwork is correct.

## Verified result — November 15, 2026

The complete canvas playtest passed against Godot 4.7.2 in installed headless
Chrome, with zero JavaScript/Godot errors. A Fitness Course developed over three
days, scored 6/10, and earned $1,372 in launch sales and six reputation. After
reloading, SQLite restored that company, Mina, the released product, founder
coordinates `(720, 592)`, and the moved founder desk at grid `(8, 18)` with
furnishing revision 2. A second tab displayed the save-lock explanation while
the first game stayed ready. No credential mutation or provider job occurred.

The session's complete screenshots and JSON evidence were written to
`/private/tmp/startup-valley-game-playtest-accepted/`; the script produces a fresh
equivalent evidence directory on each run. Earlier manual canvas play also
confirmed hiring, development, release, settings, and furniture persistence.
The final rerun includes the corrected character eyes, phone booth, and starter
café arrangement.

The separate real-browser loading suite passed seven cases: nested-path startup,
missing/denied OPFS, worker download failure, SQLite download failure, Godot
download failure, and cancellation while the actual Godot WASM download is held.
In the last case the released download finishes initialization, but the engine
never starts game scripts, the save-owner lock is released, and the original
error and Reload action stay visible. No audio initialization error occurs.

## Findings fixed during the port

1. Missing AI credentials opened a connection modal behind the company title,
   pausing the office and consuming Escape. Hydrating credential status is now
   passive. Explicit AI actions still open the connection flow on desktop.
2. The first real web export drew the team rail through the middle of the room.
   The drawer/rail now explicitly anchors to the viewport's right edge; the
   rebuilt game was visually checked.
3. The browser edition advertised desktop AI work orders, website files, and
   key entry. Browser onboarding now leads to the offline product loop, Settings
   describes available features, and optional AI controls explain that they
   require the desktop edition.
4. The native furnishing fixture assumed four inventory items and a popup with
   no scrolling. It now navigates the real popup using keys, preserves the
   current inventory, and uses a desk position clear of the current planter
   artwork and future office stations. The real worker restart/lost-reply
   integration passes.
5. A cancelled Godot download could later finish and start behind the error
   screen. Loading now separates the public engine initialization and start
   calls, checks cancellation between them, and never starts a cancelled game.

## Scope

This is a desktop Chromium playtest. It does not establish Safari, Firefox,
mobile touch usability, cross-device saves, or offline reopening of an uncached
page. Browser refresh persistence is checked against OPFS; clearing site data
still clears that browser's company. Visual changes are documented separately
in [asset-audit.md](asset-audit.md).
