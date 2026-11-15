# Browser simulation runtime

The browser build runs the shared offline TypeScript simulation in a dedicated module Worker. The official SQLite WASM package persists the existing database model in OPFS. Godot remains the presentation layer. Native builds continue to use Node and native SQLite.

## Build and test

Requires Node 22.19+ (Vite requires 22.12+) and an installed Chrome/Chromium for browser tests.

```sh
cd harness && npm ci && npm run build
cd ../web && npm ci && npm run build
CHROME_PATH=/path/to/chrome npm test
npm run preview
```

`CHROME_PATH` defaults to the standard Google Chrome application path on macOS and `/usr/bin/google-chrome` on Linux. Tests launch an isolated temporary profile, serve the actual built files on an ephemeral localhost port, block external network requests, and remove their own data afterward. They do not read the player's browser profile or install a browser.

The standalone page at `http://127.0.0.1:4173/` is a developer runtime check, not the Godot game. It uses real persistent storage. The full export copies `web/dist/` to the game's `dist/web/` directory. Load `web/bridge.js` with a normal script tag, await `StartupValleyWorker.start()`, then start Godot.

## Bridge contract

`window.StartupValleyWorker` exposes:

- `start(): Promise<void>` — resolves after the persistent database opens and migrations finish.
- `request(json: string): void` — sends an existing JSON protocol request; requires readiness.
- `onMessage(callback): unsubscribe` / `offMessage(callback)` — delivers protocol responses as JSON strings.
- `onError(callback): unsubscribe` / `offError(callback)` — reports fatal runtime/storage errors as strings.
- `stop(): Promise<void>` — drains queued requests, closes SQLite, and releases storage ownership.
- `diagnostics()` — returns a detached snapshot of readiness, storage type, pending IDs, errors, and latest real responses keyed by method. It cannot mutate simulation state.

The bridge resolves `worker.js` relative to its own script URL; Vite resolves SQLite assets relative to the worker. Nested hosting paths work. Godot must retain its JavaScript callback references and unregister them when its client is disposed. A page restored from the browser's back-forward cache reloads both halves together.

## Save behavior

The stable pool is `startup-valley-opfs` in OPFS directory `.startup-valley`; the logical database is `/startup-valley.sqlite3`. Neither changes between releases. A Web Lock and SQLite's sync handles ensure one owner per origin. A second tab receives a recoverable error rather than opening a different or empty save.

SQLite opens in exclusive-locking mode before the shared WAL migration. Every adapter statement is finalized, and the worker serializes requests. Unsupported storage, denied access, initialization failure, or quota errors remain explicit errors; there is no memory-only fallback. SQLite's `preserveOnInitFailure` is enabled so initialization errors preserve existing pool data. HTTPS or localhost is required.

New Company validates a separate candidate, preserves `/startup-valley-before-reset.sqlite3`, and writes a durable reset marker outside the VFS directory before replacing the primary. If replacement is interrupted, next startup validates and restores the prior company. Normal replacement errors restore the existing adapter before reporting failure. The backup is retained until another confirmed reset replaces it. The browser's site-data controls can still delete origin storage; a player-facing download/import UI is not part of this runtime yet.

Optional AI jobs and credential operations are explicitly unavailable. No provider SDK, native keyring, Node bootstrap, filesystem access, or HTTP gameplay service enters this bundle. A build-time import-graph check enforces that boundary.

## Verified coverage

The real Chrome/WASM test compares JSON responses against native SQLite through furnishing, product development, duplicate requests, release, sales, research, upgrades, hiring and player saves. It checks second-tab exclusion, reload and full browser restart persistence, New Company, and recovery from an interrupted-reset marker. The harness separately verifies shared-dispatch parity with the native stdio process.

The initial implementation is tested in installed Chrome. Safari/Firefox compatibility and physical quota exhaustion still need device-specific acceptance checks.

SQLite references: [official WASM package](https://github.com/sqlite/sqlite-wasm), [SAH pool persistence and failure handling](https://sqlite.org/wasm/doc/trunk/persistence.md), [synchronous object-oriented API](https://sqlite.org/wasm/doc/trunk/api-oo1.md).
