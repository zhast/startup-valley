# Verification record

Date: November 15, 2026. Baseline: `zhast/startup-valley` at `c4d1829df5ce2924ef68964bf16b7c1c369e0e46`. Work is saved in [PR #74](https://github.com/zhast/startup-valley/pull/74).

## Completed

| Area | Result |
| --- | --- |
| Checkout | Shallow, runtime-focused sparse clone; required concept sheet and import sidecar retained |
| Engine | Existing 4.7.2 pin is the latest stable checked; official editor download verified with SHA256 and SHA512 |
| Web tooling | 32 tests passed: configuration, export validation/rollback, static server, shell lifecycle, template ZIP integrity |
| Loading shell | Desktop, mobile portrait, and mobile landscape checks passed; no horizontal overflow |
| Native dependencies/build | Committed harness lock installed unchanged; TypeScript build passed |
| Native harness after fixes | 139 passed, 0 failed, 2 real-Godot tests skipped in the general run and exercised separately below |
| Portable harness parity | 3 tests passed, including native stdio comparison, deduplication, schema errors, provider unavailability and reset rollback |
| Offline evaluation | 8/8 fixtures, 27 checks passed; no live provider calls |
| Godot import/validator | Passed after art corrections; runtime scenes, art, and modular office stages valid |
| Godot main suite | Passed, including revised missing-credential behavior |
| Real Godot startup | Passed with the verified editor binary |
| Real Godot furnishing | Passed all four phases, including UI input, restart persistence, and lost-acknowledgment recovery |
| Worker clean install/build | Lockfile install and TypeScript/Vite builds passed; bundle guard excludes native/provider modules |
| Real browser SQLite | Chrome/WASM/OPFS responses match native SQLite through furnishing, product development, release, sales, research, upgrades, hiring and saving |
| Browser persistence | Same state after page reload and complete Chrome restart; second owner rejected; confirmed reset and interrupted-reset recovery passed |
| Full Godot web export | Passed; includes Godot HTML/JS/WASM/PCK, authored JSON, bridge, Worker and SQLite assets |
| Actual canvas gameplay | Passed startup, hiring, product development, release, movement, furnishing, reload and second-tab protection with zero JS/Godot errors |
| Browser loading failures | 7/7 scenarios passed: nested-path game boot, unsupported/denied OPFS, failed Worker/SQLite/Godot downloads, and actual delayed-WASM cancellation |

Tests used Node 24.22.1 (satisfies the 22.19+ minimum), Godot 4.7.2, and installed Google Chrome. Browser automation uses isolated temporary profiles. Host credentials are ignored in native tests; no paid-provider checks ran.

## Bugs fixed during playtesting

- Missing credentials automatically opened Connect AI behind the company title and disrupted Escape/settings navigation. Status is now passive until explicitly opened.
- The furnishing UI fixture assumed four inventory rows; the current catalog has 28. It now selects through actual keyboard navigation and compares inventory contents.
- A fixture moved a desk into newly occupied artwork. Its input sequence now targets a validated free location, retaining save/restart assertions.
- Browser onboarding advertised unavailable AI and real-file work. Browser copy and controls now describe the offline product loop.
- The team sidebar rendered in the middle of the exported game. Explicit viewport anchoring keeps it at the right edge.
- A failed Godot WASM download left the loading screen stuck because an internal rejection did not reject `startGame`. Scoped error recovery and a progress watchdog now expose Reload and preserve the committed save.
- SQLite download failure displayed Emscripten internals. The player now receives a concise connection/reload message.
- A shared-dispatch await allowed simultaneous native New Company requests to overlap. Reset ownership is now reserved before yielding, with a regression proving one backup and preservation of the old company.
- A late-loading engine could outlive an earlier startup failure. The shell now separates engine initialization from starting game scripts, rechecks cancellation, closes the Worker, and preserves the first error.
- Founder/Theo blink artifacts and the phone booth's mismatched camera angle were corrected using reviewed image-model output. See the [illustrated asset audit](asset-audit.md).

The real canvas test released a Fitness Course for $1,372 and 6 reputation, moved the founder desk, and restored company, product, staff, player position, and furniture after reload. The final run includes the corrected eyes, phone booth, and café layout from merged PR #1. The test only reads bridge diagnostics; all gameplay actions use mouse/keyboard input. See [playtest details](playtest.md).

## Coverage limits

Desktop Chrome is the initial verified browser. Firefox, Safari, physical mobile devices, actual quota exhaustion and low-end-device performance remain untested. The responsive loading shell alone does not establish mobile gameplay support.

The standalone locomotion audit still reports four pre-existing failures, reproduced against the original assets: Founder/Mina palette-count limits and two Founder back-frame anchor/jitter checks. The eye edits introduce no new failures and preserve alpha, silhouettes, and all unaffected frames. The source-art rebuild requires the original masters omitted by this sparse checkout; script syntax and decoded output comparisons were checked.

No remote site has been deployed. Browser saves are local to the origin; clearing site data removes them. Save-file download/import and PWA caching are not implemented.

## Reproduce

Follow [the setup guide](README.md), then run:

```sh
npm run test:web
npm --prefix harness test
npm --prefix harness run eval:offline
CHROME_PATH=/path/to/chrome npm --prefix web test
npm run build:web
CHROME_PATH=/path/to/chrome npm run test:web:loading
npm run dev:web
# In another terminal, while the server is running:
CHROME_PATH=/path/to/chrome npm run test:web:play
```

The real native Godot integration tests require the editor executable and harness build. See [AGENTS.md](../../AGENTS.md) and the [playtest guide](playtest.md).

Temporary session logs include `/private/tmp/startup-valley-web-export.log`, `/private/tmp/startup-valley-loading-accepted.log`, `/private/tmp/startup-valley-reset-full-tests.log`, `/private/tmp/startup-valley-offline-eval.log`, and `/private/tmp/startup-valley-cafe-furnishing-integration.log`. Actual canvas evidence is under `/private/tmp/startup-valley-game-playtest-accepted/`. These are local evidence, not required project inputs.
