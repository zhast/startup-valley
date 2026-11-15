# Startup Valley — web port groundwork

This guide and the web-delivery scaffold now live in the Startup Valley repository on branch `codex/web-port-scaffold`. The original game README and architecture remain the baseline; gameplay has not been rewritten.

**Recommended architecture: Godot web client → browser Worker → existing TypeScript simulation → SQLite WASM.** The current game launches a native Node subprocess; exporting Godot alone will not make it playable in a browser.

Godot owns presentation. The harness owns the simulation and saves. Preserve this boundary, the shared protocol, and offline play. Do not move the tycoon rules into GDScript or introduce a hosted backend for the core game.

## Start here

- [Repository audit](repository-audit.md): actual engine, assets, blockers, and commit-pinned evidence.
- [Architecture decision](architecture.md): why the existing Godot/TypeScript split should be retained.
- [Browser runtime plan](browser-runtime-plan.md): concrete transport, SQLite, and module seams.
- [Porting guide](porting.md): order of work and acceptance criteria.
- [Verification record](verification.md): current scaffold and native baseline results.
- [Asset audit](asset-audit.md): art quality, technical checks, and in-game evidence.

## Where the original project left off

The original [README](../../README.md) covers setup and controls, [AGENTS.md](../../AGENTS.md) defines development boundaries, and [AUTONOMY_LOG.md](../../AUTONOMY_LOG.md) is the latest progress trail. Its last entry is Round 68, November 12, 2026: the offline tycoon and back-catalog royalty feature are playable; staff raises are the next planned gameplay slice, and a second room needs architecture art. Earlier [PLAYTEST-NOTES.md](../../PLAYTEST-NOTES.md) focuses on Chapter 1 and is less current.

The original log reports 134 passing harness tests, 2 skipped, and 8/8 offline fixtures at that checkpoint. Those are historical results, separate from verification performed in this workspace.

Godot 4.7.2 is also the latest stable release checked on November 15; 4.8 is still a beta, so no engine upgrade is needed for this baseline. [Official release archive](https://godotengine.org/download/archive/)

## What is built

- Custom Godot loading shell with progress, browser checks, fullscreen, and failure recovery.
- Dependency-free local static server with correct WASM MIME and real 404s.
- Preflight checks for the engine version, renderer, and web export preset.
- Staged release export that preserves a previous build on failure.
- Structural output validation and tests for the tools and loading lifecycle.

**Still to implement:** the browser transport and persistent SQLite worker using the real harness, the active web preset, and gameplay/parity tests. The shell is not a replacement game. Passing preflight does not prove native game code is browser-compatible.

## Preview and test

Use Node.js 22.19+ (the repository minimum). The web scaffold has no npm dependencies.

```sh
node scripts/serve.mjs
node --test tests/*.test.mjs
```

Open <http://127.0.0.1:5177>. Until an export exists, this displays a clearly marked **loading-screen preview**, not gameplay. This loopback server serves static files only; it exposes no worker API or game-state endpoint.

`godot-web.config.json` targets `game` and pins **Godot 4.7.2**, matching the repository. The scripts do not install Godot or its templates.

## Clone layout

This is a shallow, runtime-focused sparse clone of [zhast/startup-valley](https://github.com/zhast/startup-valley). Code, schemas, migrations, runtime assets, and the referenced character concept sheet are included. Generated test captures, original source-art packs, and unused concept images are omitted from the working tree. Their Git references remain available; some developer visual tests require restoring omitted files.

To fetch the complete working tree later, from the repository root:

```sh
git sparse-checkout disable
```

That can add roughly another gigabyte of uncompressed content. Sparse configuration is local and does not delete remote files.

## Delivery commands, after browser-runtime integration

```sh
node scripts/doctor.mjs
node scripts/export-web.mjs
node scripts/validate-web.mjs
node scripts/serve.mjs
```

Set `GODOT_BIN` to the matching executable if it is not on PATH, for example:

```sh
GODOT_BIN='/Applications/Godot.app/Contents/MacOS/Godot' node scripts/doctor.mjs
```

`game/web/shell.html` is the optional shell template; it is an additive template and has not replaced an existing shell. `templates/export_presets.web.cfg` is a reference, not an active preset. It includes `data/*.json` because the game reads authored JSON at runtime.

Output goes to `dist/`. Deploy that directory as one HTTPS release only after runtime and persistence acceptance. Generated `_headers` files apply only on hosts supporting that convention. No remote deployment, credential access, or paid-provider test is performed by this scaffold.
