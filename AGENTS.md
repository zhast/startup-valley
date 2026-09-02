# Startup Valley v0 agent guide

Startup Valley v0 is a desktop office-town whose workers run real AI jobs. Keep the two-process boundary intact:

- `game/`: Godot 4.7.2, typed GDScript only. Rendering, input, animation, menus, interpolation, and cached read-only worker views.
- `harness/`: Node.js 22.19+ and TypeScript. Pi sessions, SQLite, jobs, constrained tools, credentials, audit, token budgets, and artifacts.
- `contracts/`: JSON Schemas for every JSONL request, response, job, event, and artifact crossing the process boundary.
- `dev/`: acceptance notes and developer-only artifacts.

The worker is authoritative for employees, memories, relationships, schedules, projects, work orders, approvals, usage, transcripts, and artifacts. SQLite is the game database. Pi session files are never the source of truth for people.

## Exact commands

```sh
cd harness && npm ci
cd harness && npm run build
cd harness && npm test
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

- The game communicates with the worker only over stdio JSONL for v0. Do not add an unauthenticated HTTP listener.
- OpenRouter is the only provider in v0. Put its key in the OS keychain/Credential Manager and inject it with Pi `setRuntimeApiKey` only.
- Create a bounded Pi session for each substantial work order and dispose it at job end. Do not create an immortal employee conversation.
- Default concurrency is one job. Every job has a token cap and usage audit events.
- The Godot UI refuses a second assignment while one is active and exposes cancellation. A worker exit fails the active projection, returns the employee to idle, and is recovered durably as failed on worker restart.
- Pi built-in tools, including bash, must stay disabled. Only the explicitly constrained custom tools may be enabled.
- File tools are rooted inside the current job directory and must reject absolute paths, `..`, NUL bytes, Windows drive/UNC paths, and symlink escapes.
- Web tools must reject localhost, link-local, private, multicast, and otherwise non-public destinations before every request and redirect.
- Text artifacts are read through the worker's guarded `artifact.read` method and rendered in Godot; the game must not bypass the worker with an arbitrary filesystem open.
- On `job.completed`, Godot must request `job.remember`. SQLite writes at most three structured assignment/artifact/outcome memories. The next employee context uses bounded memories and recent teammate artifact paths/summaries, never an infinite shared transcript.
- Teammate artifacts may be copied into the new job's `handoffs/` directory for rooted read access. There is no `message_employee` tool or recursive agent dispatch.

## Prohibited mutations

- No API keys, provider SDKs, raw shell execution, MCP servers, or external-service tokens in Godot.
- No unrestricted `bash`, PowerShell, subprocess, package-install, browser automation, or test-runner tool in the worker.
- Do not hand-edit `TileMapLayer.tile_map_data` packed byte arrays. Paint in the editor or generate the logical grid from JSON with a tool script.
- Do not turn the legacy Swift chat showcase or any third-party chat application into the game shell.
- Do not add Docker as a player prerequisite.
- Do not add C#, Electron, Unity, Unreal, Bevy, MonoGame, Omnigent, OpenHands, Letta, or a remote cloud instance to v0.

Dev-only Godot MCP or editor automation may assist scene editing, but it must not ship in production exports.
