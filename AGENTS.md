# Startup Valley v0 agent guide

Startup Valley v0 is an offline, story-led office tycoon set in the fictional TownSquare community. It should feel like Game Dev Tycoon and Stardew Valley: meet teammates, follow clear goals, ship products, earn game cash and reputation, and grow the office across days. Gameplay is a pure in-game simulation. It must start and play with no API key or network. Keep real-platform branding out of player-facing content. See `docs/TYCOON_DESIGN.md`.

The opening is cute, humble and handmade: a tiny venture in a quiet village,
not a corporate suite or estate. Follow `docs/STARTER_ART_DIRECTION.md`.
New asset briefs declare starter or earned-upgrade context; improvements to
furniture and surroundings should communicate saved player progress.

Keep the two-process boundary intact:

- `game/`: Godot 4.7.2, typed GDScript only. Rendering, input, animation, menus, interpolation, and cached read-only worker views.
- `harness/`: Node.js 22.19+ and TypeScript. SQLite, the tycoon simulation, and optional Pi sessions for chapter work orders. Jobs, constrained tools, credentials, audit, token budgets, and artifacts stay here.
- `web/`: browser-only Worker and SQLite WASM adapters for the shared offline harness core. No provider credentials or Node-only dependencies may enter this bundle.
- `contracts/`: JSON Schemas for every JSONL request, response, job, event, and artifact crossing the process boundary.
- `dev/`: acceptance notes and developer-only artifacts.

The worker is authoritative for the tycoon (products, reviews, sales), employees, memories, relationships, schedules, projects, work orders, approvals, clock state, usage, studio files, and artifacts. SQLite is the game database. Pi session files are never the source of truth for people. Do not duplicate tycoon rules in GDScript.

## Development decisions and checkpoints

- Record consequential design, architecture, asset and workflow decisions in `docs/DECISIONS.md`; link detailed acceptance evidence there.
- The owner works alone and authorizes tested commits directly to `main`. Save significant completed increments promptly; do not require a pull request unless isolation materially helps the work.
- Push tested checkpoints promptly so progress survives loss of this machine. Keep `docs/DEMO_HANDOFF.md` current with source/build state, checks, remaining work and any unpushed commits. Do not wait for the owner to return for routine authorized work.
- Website/public-hosting work is deferred. Use integrated Godot tests and automated worker/export validation. The owner also authorizes browser QA inside Codex's in-app browser; use a disposable localhost origin and supported browser APIs. Do not use OS-level computer control or other browser profiles.
- Refresh the playable web export promptly after each significant passing source checkpoint; do not hold localhost updates until final acceptance is complete. Verify the served build identifier/files and distinguish preview readiness from final gameplay acceptance.
- Treat the opening as a playable tutorial: one clear goal, one relevant action, visual character identity, and progressively revealed complexity. Keep the current goal readable without clipping or requiring a tooltip.

## Exact commands

```sh
cd harness && npm ci
cd harness && npm run build
cd harness && npm test
cd harness && npm run eval:offline
cd harness && npm run live:openrouter # manual; requires the game-saved keychain credential
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
```

For the playable development build:

```sh
cd harness && npm run build
godot --path game
```

## Required boundaries

- Native builds communicate with the worker over stdio JSONL. Web builds use JavaScriptBridge and a dedicated browser Worker with the same request/response envelopes. Do not add an unauthenticated HTTP listener. Keep offline rules in the shared harness core and platform storage in adapters.
- The core loop is offline. `tycoon.start`, `tycoon.release`, `tycoon.acceptContract`, `tycoon.patch`, `tycoon.sequel`, `tycoon.award`, `tycoon.port`, `tycoon.localize`, `tycoon.train`, `tycoon.letGo`, `tycoon.setPace`, `tycoon.listCatalog`, `tycoon.delistCatalog`, `tycoon.research`, `tycoon.buyUpgrade`, `tycoon.buyEngine`, `tycoon.expandOffice`, `tycoon.takeLoan`, `tycoon.signPublisher`, `tycoon.bookBooth`, `tycoon.takeTownDay`, `tycoon.showPressDemo`, `tycoon.makeTrailer`, `tycoon.writeDiary`, and the `day.end` product tick must not read a credential, call a provider, or use the network. A missing key must never block shipping a product.
- Model providers are optional and off the core path. They exist only for chapter work orders and chat when the player opts in. Grok / xAI is the primary optional provider. Sign in with Grok (or reuse `~/.grok/auth.json`) and inject the access token with Pi `setRuntimeApiKey("xai", …)` for `grok-4.6`. An OpenRouter key in the OS keychain remains a fallback. `STARTUP_VALLEY_FAKE_PROVIDER=1` is the dev-only offline stand-in for those jobs. It is not the default, and it is not the tycoon. Never log or print tokens.
- Create a bounded Pi session for each substantial work order and dispose it at job end. Do not create an immortal employee conversation.
- Active-job steering is bounded to 2,000 characters and must call `steer()` on that work order's existing live Pi session. It must not create a replacement session or a second job.
- Freeform and canned assignments use the same `JobSpec`, SQLite work-order row, queue, event stream, token cap, and fresh Pi session. A freeform job may attach one studio-relative text file; validate and read it through the studio path guard, persist its path, and bound its context before prompting.
- Default concurrency is one running-or-queued job. Every job has a token cap and usage audit events.
- The Godot UI refuses a second assignment while one is active and exposes cancellation. A worker exit fails the active projection, returns the employee to idle, and is recovered durably as failed on worker restart.
- Pi built-in tools, including bash, must stay disabled. Only the explicitly constrained custom tools may be enabled.
- File tools write only inside current job scratch. They may read the durable `studio/` tree through an independently guarded root. Both roots reject absolute paths, `..`, NUL bytes, Windows drive/UNC paths, and symlink escapes.
- Web tools must reject localhost, link-local, private, multicast, and otherwise non-public destinations before every request and redirect.
- Completed artifacts enter `studio/` only after an explicit player promotion decision. Promotion uses guarded source and destination paths, and studio files are read through `studio.read`; Godot never opens arbitrary filesystem paths.
- A completed job with scratch artifacts stays `pending` for promotion across quit/reopen. Bootstrap must return pending decisions. Approve copies through both guards and records provenance; Discard clears the pending decision without promoting it.
- On `job.completed`, Godot must request `job.remember`. SQLite writes at most three structured assignment/artifact/outcome memories. The next employee context uses bounded memories and recent teammate artifact paths/summaries, never an infinite shared transcript.
- The saved clock has three schedule phases: work (08:00–12:30 and 13:30–17:30), lunch (12:30–13:30), and off shift. Lunch/off-hours submissions stay queued and must emit `job.started` only after a work window opens.
- On-shift idle animation may sit, wander, or surface one bounded memory line. It must never show typing/coding without live tool events. Lunch and off-shift states are presentation-only and do not spawn agents.
- On graceful game shutdown, the worker blocks an in-flight work order, aborts/disposes Pi, and exits after stdin closes. Unclean worker crashes remain recoverable as failed. There is no `message_employee` tool or recursive agent dispatch.
- The lifecycle suite must cover unclean exit during think/read/write/approval/complete/promote, missing credentials, malformed JSONL, vanished queued attachments, and simultaneous assignment submission. No case may leave an employee assigned after terminal recovery or leave the tested Node worker alive.
- `npm run eval:offline` must remain provider-free and enforce exact studio immutability for every fixture without promotion approval. `npm run eval:live` is optional and must run only when a person explicitly requests the paid provider check.

## Prohibited mutations

- No API keys, provider SDKs, raw shell execution, MCP servers, or external-service tokens in Godot.
- No unrestricted `bash`, PowerShell, subprocess, package-install, browser automation, or test-runner tool in the worker.
- Do not hand-edit `TileMapLayer.tile_map_data` packed byte arrays. Paint in the editor or generate the logical grid from JSON with a tool script.
- Do not turn the legacy Swift chat showcase or any third-party chat application into the game shell.
- Do not add Docker as a player prerequisite.
- Do not add C#, Electron, Unity, Unreal, Bevy, MonoGame, Omnigent, OpenHands, Letta, or a remote cloud instance to v0.

Dev-only Godot MCP or editor automation may assist scene editing, but it must not ship in production exports.

## Runtime art changes

Follow `docs/ASSET_WORKFLOW.md` before adding or replacing runtime art. Keep
generation sources/prompts and source-to-runtime transforms, explicit camera,
canvas, shared anchor and layer contracts, and current in-game evidence. Do not
infer visual approval from passing geometry tests. Run `npm run assets:check`
and the relevant Godot placement/animation tests. New or changed runtime PNGs
need a hash-bound review in `dev/art-catalogue/runtime-reviews/`; do not refresh
the frozen legacy baseline to bypass review. Record code-native and unknown
legacy origins honestly rather than calling every image AI-generated.

New or changed maps follow `docs/MAP_WORKFLOW.md`. Register actual map sources
in `dev/map-catalogue/maps`, reuse the canonical style and registered catalogue
modules, and pass `npm run maps:check`. Changed composition requires hash-bound
actual-Godot visual evidence; never refresh the frozen map baseline to bypass
review. Keep `docs/ASSET_STATUS.md` current with open defects and the exact scope
of completed art repairs; an approved image does not certify every animation.
