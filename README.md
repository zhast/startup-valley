# Startup Valley

Startup Valley is a Godot office-town where AI employees perform real, bounded work through a constrained local TypeScript worker. The game renders the town and work activity; the worker owns SQLite state, Pi sessions, OpenRouter access, usage, approvals, and artifacts.

The current vertical slice is a persistent studio. The player can use the canned Mina/Theo assignments or write a freeform work order for either employee, optionally attaching one studio file as bounded read-only context. Finished scratch artifacts wait for an explicit Approve or Discard decision even after quit/reopen. Approved files appear in the durable studio browser, where they can be opened in-game and attached to later work.

## Requirements

- Godot 4.7.2, standard build without C#
- Node.js 22.19 or newer
- One OpenRouter API key

Dependency versions are deliberately pinned. See [upgrading dependencies](docs/UPGRADING.md) before changing Godot, Node, Pi, or the supporting npm packages.

## Run

```sh
cd harness
npm ci
npm run build
cd ..
godot --path game
```

In the game, paste an OpenRouter API key and choose **Save securely**. The local worker stores it under the `dev.startup-valley.game` service in the OS keychain/Credential Manager. The key is never printed, written to SQLite or a job workspace, or saved in Pi session files.

The credential service is namespaced to Startup Valley, so the key must be saved once for this game.

New assignments start during 08:00–12:30 and 13:30–17:30. Lunch and off-hours assignments remain visibly queued until the next work window. The clock controls pause, 1×, 4×, and 16× speed. Completed job files remain scratch artifacts until the player approves promotion into the canonical `studio/` tree; unfinished promotion decisions resume after restart.

## Live provider check

After saving the key through the game, run one real bounded smoke job:

```sh
cd harness
npm run live:openrouter
```

It writes `hello.md` under `harness/.startup-valley-live/company-project/jobs/<job-id>/` and verifies the real event chain, nonzero tokens, estimated cost, and exact artifact content without printing the key. See [the live run record](dev/LIVE_OPENROUTER.md).

## Validate

```sh
cd harness && npm run check && npm test
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
```

## Repository map

- `game/`: Godot scenes, typed GDScript, UI, deterministic visual test, and project validator.
- `harness/`: TypeScript worker, Pi adapter, SQLite migrations, constrained tools, and tests.
- `contracts/`: JSON Schemas for the stdio JSONL boundary.
- `dev/`: acceptance and live-provider checklists.
- `docs/`: architecture and dependency-upgrade guidance.

See [the architecture](docs/GAME_ARCHITECTURE.md) and [vertical-slice acceptance](dev/ACCEPTANCE.md).
