# Startup Valley — browser build

The browser build uses the existing Godot scenes, GDScript, assets, TypeScript simulation, SQL migrations, and protocol. Native builds retain Node/stdio. Work is on branch `codex/web-port-scaffold`.

**Godot web client → JavaScriptBridge → browser Worker → shared TypeScript simulation → SQLite WASM/OPFS.** The browser never launches a subprocess or needs a hosted game server. Optional AI/provider work is unavailable in this edition.

Godot owns presentation. The harness owns the simulation and saves. Preserve this boundary, the shared protocol, and offline play. Do not move the tycoon rules into GDScript or introduce a hosted backend for the core game.

## Start here

- [Repository audit](repository-audit.md): actual engine, assets, blockers, and commit-pinned evidence.
- [Architecture decision](architecture.md): why the existing Godot/TypeScript split should be retained.
- [Browser runtime](../../web/README.md): implemented transport, storage behavior, and parity tests.
- [Original runtime plan](browser-runtime-plan.md): design rationale and module seams.
- [Porting guide](porting.md): order of work and acceptance criteria.
- [Verification record](verification.md): current scaffold and native baseline results.
- [Asset audit](asset-audit.md): art quality, technical checks, and in-game evidence.

## Where the original project left off

The original [README](../../README.md) covers setup and controls, [AGENTS.md](../../AGENTS.md) defines development boundaries, and [AUTONOMY_LOG.md](../../AUTONOMY_LOG.md) is the latest progress trail. Its last entry is Round 68, November 12, 2026: the offline tycoon and back-catalog royalty feature are playable; staff raises are the next planned gameplay slice, and a second room needs architecture art. Earlier [PLAYTEST-NOTES.md](../../PLAYTEST-NOTES.md) focuses on Chapter 1 and is less current.

The original log reports 134 passing harness tests, 2 skipped, and 8/8 offline fixtures at that checkpoint. Those are historical results, separate from verification performed in this workspace.

Godot 4.7.2 is also the latest stable release checked on November 15; 4.8 is still a beta, so no engine upgrade is needed for this baseline. [Official release archive](https://godotengine.org/download/archive/)

## Build and run

Install the standard **Godot 4.7.2** editor and **Node.js 22.19+**. From the repository root:

```sh
npm --prefix harness ci
npm --prefix harness run build
npm --prefix web ci
npm run setup:web
npm run build:web
npm run dev:web
```

Open <http://127.0.0.1:5177>. Set `GODOT_BIN` if the matching editor is not on PATH, for example:

```sh
export GODOT_BIN='/Applications/Godot.app/Contents/MacOS/Godot'
```

`setup:web` downloads only the matching single-threaded web templates from the official release and verifies ZIP integrity. It does not install the editor. Templates, dependencies, and build output are ignored by Git. `build:web` bundles the Worker, imports the game, exports Godot, and publishes all files together to `dist/`. A failed export preserves the previous complete build.

The active preset is `game/export_presets.cfg`; its shell is `game/web/shell.html`. Authored `data/*.json` is included in the export. Threading, native extensions, and PWA caching are disabled.

## Implemented

- Custom Godot loading shell with progress, browser checks, fullscreen, and failure recovery.
- Dependency-free local static server with correct WASM MIME and real 404s.
- Preflight checks for the engine version, renderer, and web export preset.
- Staged release export that preserves a previous build on failure.
- Structural output validation and tests for the tools and loading lifecycle.
- Browser transport in WorkerClient, preserving the native stdio path.
- Shared offline simulation with native/browser parity tests.
- Persistent SQLite WASM saves with one-tab ownership, explicit storage errors, and reset recovery.

See the [verification record](verification.md) for current tested coverage and limitations. A successful export alone does not verify every gameplay path.

## Tests and shell preview

The root delivery scripts use built-in Node modules. The Worker has its own pinned dependencies and lockfile under `web/`.

```sh
npm run test:web
npm --prefix harness test
npm --prefix harness run eval:offline
CHROME_PATH=/path/to/chrome npm --prefix web test
```

Browser tests launch an isolated temporary Chrome profile. Until an export exists, `npm run dev:web` displays a clearly marked **loading-screen preview**, not gameplay. The loopback server serves static files only; it exposes no worker API or game-state endpoint.

## Browser saves and hosting

Saves stay in the browser's OPFS storage for the site's origin. Keep that origin stable between releases. Another tab cannot open the same save concurrently. Storage failures are shown explicitly; the game never silently falls back to a temporary save. Clearing site data removes browser saves. Download/import of saves is a future feature.

The first tested browser is desktop Chrome. Other browsers and mobile gameplay need their own acceptance pass. HTTPS or localhost, WebGL 2, WebAssembly, OPFS, and Web Locks are required.

Deploy the whole `dist/` directory as one HTTPS release. Enable compression, correct WASM MIME, and real 404 responses. Generated `_headers` files apply only on hosts supporting that convention. No remote deployment or paid-provider test is performed by the build scripts.

## Clone layout

This is a shallow, runtime-focused sparse clone of [zhast/startup-valley](https://github.com/zhast/startup-valley). Code, schemas, migrations, runtime assets, and the referenced character concept sheet are included. Generated test captures, original source-art packs, and unused concept images are omitted from the working tree. Their Git references remain available; some developer visual tests require restoring omitted files.

To fetch the complete working tree later, from the repository root:

```sh
git sparse-checkout disable
```

That can add roughly another gigabyte of uncompressed content. Sparse configuration is local and does not delete remote files.

## Delivery diagnostics

```sh
node scripts/doctor.mjs
node scripts/export-web.mjs
node scripts/validate-web.mjs
node scripts/serve.mjs
```

`templates/export_presets.web.cfg` remains a generic reference for integrating another project; this repository uses the active preset under `game/`.
