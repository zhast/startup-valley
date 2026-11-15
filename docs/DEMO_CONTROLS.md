# Startup Valley demo

Start a tiny studio, meet Mina, and turn a small idea into your first release.
Everything in the core game is an offline simulation: no API key or account
is required, and all money and reputation are fictional game values.

## Playing

- Click the floor, or use WASD/arrows, to move.
- Click a highlighted person or object to approach and interact.
- Follow the current objective and its action button. Meet Mina, choose a
  project, develop it across days, and release it when ready.
- After the first release, follow the courtyard sign to meet Theo. His makers
  market needs a planning kit; accept the idea, return to the studio and follow
  the new objective to build it through the same project loop.
- Press J to open Company Journey. Press Escape to close the top panel or open
  settings. Menus pause the office clock.
- Company progress saves locally. Start with a new company to see the compact
  starter studio; older companies retain their existing office.

## Running the export

Serve the entire `game/` directory of this ZIP over local HTTP. Do not open
`index.html` as a `file://` URL. For example, with Python 3 installed, run:

```sh
python3 -m http.server 8000 --bind 127.0.0.1 --directory game
```

Then open `http://127.0.0.1:8000` in a browser with WebGL 2. Saves belong to
that browser and origin; use the same address and port to continue. The
repository's `npm run dev:web` is another local development option.

`game/build-info.json` identifies the exact payload. `manifest.json` and the
ZIP's `.sha256` sidecar provide file/archive integrity evidence. The separate
acceptance report records the exact gameplay tests performed.

## Current limitations

Desktop keyboard and pointer input are the primary target. Simulated viewport
or touch checks do not establish physical-phone support. Public hosting and
cross-browser acceptance are deferred; this package does not claim either.
Optional native AI work orders are outside the offline demo and unavailable in
the browser build. Do not clear browser site data if you want to keep its save.
