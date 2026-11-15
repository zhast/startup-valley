# Startup Valley

Startup Valley is a Godot office-town tycoon. You hire a small team, pick a Whop-flavored topic and product, develop it across office days, and ship it for game cash and reputation. That loop is a deterministic simulation inside the local worker. It does not call Whop or any model API, and it plays with no credential and no network.

Optional chapter work orders can still run bounded AI jobs through the same worker. Those jobs are off the core loop. The worker owns SQLite state and, only when you opt in, Pi sessions, provider access, usage, approvals, and artifacts.

The current chapter starts with the founder alone. Hire Mina, build and evaluate
a website, hire Theo, prepare an advertising experiment, and plan incorporation
across three office days. Company cash, reputation, milestone reviews, shipped
products, and one-time rewards live in SQLite. Existing companies keep their hired employees.

Click the floor to walk, click a person or desk to approach and interact, or use
WASD/arrows. The founder desk (or **J**) opens Company Journey; **Escape** closes
the top screen or opens pause/settings. The archive opens Studio, the approval
console opens Activity, and employee desks open Assign. The right-hand rail is
a shortcut to Chat, Assign, Activity, and Studio. Menus pause the office clock
and movement, but real AI work can keep finishing.

Chat is tool-free. **Create work order** drafts an editable assignment; **Start
work order** authorizes tools/files and AI usage. Activity owns steering,
approval and cancellation. Delivered files can be added to Studio or kept with
their job. Milestone evaluation is a separate bounded, no-tools AI review;
passing results require explicit completion, while weak results offer revision
or a reduced-reward founder override. All revenue and filing fees are fictional
game currency. Ads and incorporation are planning artifacts, not live actions.

## Requirements

- Godot 4.7.2, standard build without C#
- Node.js 22.19 or newer
- No API key is required to play. A Grok / xAI login or an OpenRouter key is optional, and only for chapter work orders and chat.

Dependency versions are deliberately pinned. See [upgrading dependencies](docs/UPGRADING.md) before changing Godot, Node, Pi, or the supporting npm packages.

## Run

```sh
cd harness
npm ci
npm run build
cd ..
godot --path game
```

In the game, **Company Journey → New Product** ships a product with no sign-in. Choose **Sign in with Grok** only when you want a chapter work order to use a model. That work uses your Grok / xAI credits through Pi's `xai` provider and `grok-4.6`. A Grok CLI login already stored in `~/.grok/auth.json` is picked up automatically for those jobs. Disconnect stops that reuse without deleting the CLI login. Pasting an OpenRouter key is still available as a fallback. Tokens stay in the OS keychain (`dev.startup-valley.game`) or the CLI auth file. They are never printed, written to SQLite or a job workspace, or saved in Pi session files.

The credential service is namespaced to Startup Valley. Chapter 1's automated playtest sets `STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1` so it still stops at Connect instead of calling a model.

New assignments start during 08:00–12:30 and 13:30–17:30. Lunch and off-hours
assignments remain visibly queued until the next work window. The HUD clock is
read-only: it shows the worker-owned saved day and time without exposing speed
controls. Completed job files remain scratch artifacts until the player approves
promotion into the canonical `studio/` tree; unfinished promotion decisions and
their completion memo resume after restart.

Once a job has started, **Update active job** sends a bounded correction to that same live Pi session. It does not start another employee or work order.

Chat is deliberately separate from execution. Each reply uses a fresh, tool-free, bounded Pi session built from a small persisted conversation window and structured employee memories. A conversation cannot write files or take actions until the player explicitly turns it into a work order.

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
cd harness && npm run eval:offline
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
godot --headless --fixed-fps 60 --path game --script res://tests/test_complete_game.gd
godot --headless --path game --script res://tests/test_ui_flow_regressions.gd
```

## Repository map

- `game/`: Godot scenes, typed GDScript, UI, deterministic visual test, and project validator.
- `harness/`: TypeScript worker, Pi adapter, SQLite migrations, constrained tools, and tests.
- `contracts/`: JSON Schemas for the stdio JSONL boundary.
- `dev/`: acceptance and live-provider checklists.
- `docs/`: architecture and dependency-upgrade guidance.

See [the architecture](docs/GAME_ARCHITECTURE.md), [vertical-slice acceptance](dev/ACCEPTANCE.md), and [offline evaluation report](dev/eval/OFFLINE_REPORT.md). `npm run eval:live` is optional and makes a paid provider call, so run it only when explicitly requested.

The [complete-game framework audit](dev/COMPLETE_GAME_FRAMEWORK.md) records the
Journey protocol, backup behavior, test coverage, and visual evidence. The
[paid playtest fixes and acceptance report](dev/LIVE_PLAYTEST_FIXES.md) records
the latest live validation and remaining product-research questions.
New Company requires confirmation and moves
the previous database and project into a timestamped `backups/` directory inside
the game's user-data folder; it never deletes the old company.
