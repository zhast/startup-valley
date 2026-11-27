# Startup Valley game architecture

## Runtime boundary

Startup Valley v0 has exactly two processes:

```text
Godot 4.7.2 game  <— stdio JSONL —>  Node/TypeScript worker
  render/input                         SQLite tycoon simulation
  animation/UI                         optional Pi for chapter jobs
```

Godot owns presentation and short-lived read-only projections. The worker owns durable people, products, and work state. SQLite is authoritative for the tycoon, employees, memories, schedules, relationships, morale, clock state, projects, work orders, studio-file provenance, approvals, event history, usage, and scratch artifacts. A Pi session is in-memory, scoped to one running work order, and disposed at its end. Chapter jobs are the only path that can open one, and only when a credential or the dev-only fake provider is present. The ship-a-product loop never does.

Employee chat follows the same ownership rule without becoming another work runtime. SQLite stores bounded player/employee messages and their usage. Each reply creates a fresh tool-free Pi session from recent messages and structured memories, then disposes it. Chat can clarify intent and seed a work-order draft; only an explicit work order receives tools.

The worker is a child process connected through `OS.execute_with_pipe`. There is no local HTTP listener. Closing the game closes and terminates the child.

## Job sequence

1. Godot submits a validated `JobSpec` containing an employee, title, assignment, acceptance criteria, token cap, and optionally one studio-relative attachment path. Canned and freeform work orders share this path.
2. During lunch or off shift the worker creates a queued work order. It emits `job.started` only when the persisted clock enters a work window.
3. The employee walks to their desk because that event arrived—not because a timer guessed that work began.
4. The worker prefers a Grok / xAI access token (in-game device login, or a refreshed `~/.grok/auth.json` session) and injects it only through Pi `ModelRuntime.setRuntimeApiKey("xai", …)` for `grok-4.6`. An OpenRouter key in the OS credential vault is the fallback. Tokens are never logged.
5. A new Pi session receives a bounded employee/assignment context and only the custom allowlisted tools. If the player attached a studio file, the worker validates it through the independent studio path guard, persists the relative path in SQLite, and includes bounded read-only content in the context pack.
6. Pi tool events become `tool.started` and `tool.completed`. Godot maps file edits to typing and web tools to the research table.
7. Writes create durable artifact rows and `artifact.created` events. Usage totals and cost estimates create `usage.updated` events.
8. The session is disposed. The completed job remains pending for an Approve or Discard promotion decision across restart. Approval moves guarded copies from `company-project/jobs/<job id>/` scratch into canonical `company-project/studio/` paths and records provenance; discard resolves the pending decision without copying.
9. Later jobs can read the studio through an independently guarded, read-only `studio/` tool namespace. They cannot mutate it without another completed-artifact promotion.

## Tycoon simulation

The playable core is an offline tycoon. Rules live in `harness/src/tycoon.ts`. Migration `009_tycoon_products.sql` stores the seed and each product. `JourneyStore` attaches `journey.tycoon` on every company payload, so the Godot company panel can present it without a second simulation or a second save file.

`tycoon.start` puts one product on the bench (topic, type, fit, and the staff snapshot) and rejects a locked topic or type. `tycoon.train` spends game cash to raise one hired person's design, tech, or hype; a person in training that day adds no points, and the product keeps the snapshot from the day it started. `tycoon.letGo` dismisses one hired teammate, drops them from a build still in development, and leaves earned days, points, and sales in place. `tycoon.setPace` sets a hired teammate to full time or part-time; part-time halves later snapshot craft and season salary, and it leaves days already posted alone. `tycoon.giveRaise` gives one hired teammate a raise, once. Season salary rises by half of the paced salary, rounded down, and later office days add 1 to that person's lowest stored craft stat. The founder cannot take one. Let go clears it. `tycoon.offerProfitShare` gives one hired teammate a profit share, once. Season salary drops by half of the table salary, rounded down, and later sales of a product that stored them pay 10% of the company's cash from that sale, rounded down, with no fans. A raise and a profit share do not stack. The founder cannot take one. Let go clears it. `tycoon.listCatalog` lists one finished product and `tycoon.delistCatalog` clears that listing. A later payday pays the stored review score times 200 cents as cash and adds no fans. The training line is kept with the office day and cleared when that day ends. `tycoon.research` spends research points to unlock a topic or a type. `tycoon.buyUpgrade` spends game cash once on an office tool (migration `012_tycoon_upgrades.sql`). Point tools add to later dev-day ticks, and the checkout tool raises the price of later sales. The purchase line clears when that office day ends. Older saves load with no upgrades. Each `day.end` calls `TycoonStore.tickDay` inside the existing day transaction, before the day summary. That tick adds design, tech, and hype while the product is in development, or applies the next sales day after release, and adds one research point for each person on the build who is not in training. Ending a day that already has a summary does not tick again. `tycoon.release` writes the four reviews, pays launch-day sales immediately, and adds `floor(score / 2)` research points. Later `day.end` calls pay the rest of the four-day curve. The release day does not pay twice.

Reviews and sales are pure functions of the saved seed (`26021` on a new company), the fit, the points, and the staff. No provider, socket, or credential is consulted. `STARTUP_VALLEY_FAKE_PROVIDER` remains an opt-in switch for chapter work orders only. It stays off unless that env var is `1`.

Player-facing topics, the fit table, the day loop, and the slices not built yet are in `docs/TYCOON_DESIGN.md`.

## Security levels

Prompt restrictions are guidance, not isolation. The file-tool root checks reject absolute paths, parent traversal, NULs, Windows drive/UNC paths, and symlinks. Web tools resolve and reject localhost, private, link-local, multicast, and other non-public addresses on every request and redirect. These checks reduce exposure but are not OS isolation.

MVP A therefore removes the general-purpose shell entirely. The session passes an explicit allowlist containing only:

- `read_file`, `write_file`, `edit_file`, `list_files`, `search_files`
- `web_search`, `web_fetch`
- `create_artifact`, `request_player_approval`

There is no bash, PowerShell, subprocess, package installer, test runner, Playwright, visible browser, raw MCP, provider SDK, employee-messaging tool, or token inside Godot.

MVP B may add an OS sandbox and shell later. It must not weaken the MVP A default.

## Repository map

- `game/`: typed GDScript scenes, logical grid, worker client, validator, and deterministic visual test.
- `harness/`: Pi adapter, SQLite database, keychain, constrained tools, JSONL daemon, and tests.
- `contracts/`: draft 2020-12 schemas for jobs, artifacts, worker events, and protocol envelopes.
- `dev/`: acceptance criteria and developer notes.

The logical world is `game/data/town.json`. Scenes never contain hand-edited packed TileMap data.
