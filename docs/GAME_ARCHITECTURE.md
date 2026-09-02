# Startup Valley game architecture

## Runtime boundary

Startup Valley v0 has exactly two processes:

```text
Godot 4.7.2 game  <— stdio JSONL —>  Node/TypeScript worker
  render/input                         SQLite + Pi + keychain
  animation/UI                         SQLite/studio/jobs/tools/audit
```

Godot owns presentation and short-lived read-only projections. The worker owns durable people and work state. SQLite is authoritative for employees, memories, schedules, relationships, morale, clock state, projects, work orders, studio-file provenance, approvals, event history, usage, and scratch artifacts. A Pi session is in-memory, scoped to one running work order, and disposed at its end.

Employee chat follows the same ownership rule without becoming another work runtime. SQLite stores bounded player/employee messages and their usage. Each reply creates a fresh tool-free Pi session from recent messages and structured memories, then disposes it. Chat can clarify intent and seed a work-order draft; only an explicit work order receives tools.

The worker is a child process connected through `OS.execute_with_pipe`. There is no local HTTP listener. Closing the game closes and terminates the child.

## Job sequence

1. Godot submits a validated `JobSpec` containing an employee, title, assignment, acceptance criteria, token cap, and optionally one studio-relative attachment path. Canned and freeform work orders share this path.
2. During lunch or off shift the worker creates a queued work order. It emits `job.started` only when the persisted clock enters a work window.
3. The employee walks to their desk because that event arrived—not because a timer guessed that work began.
4. The worker reads the OpenRouter key from the OS credential vault and injects it only through Pi `ModelRuntime.setRuntimeApiKey`.
5. A new Pi session receives a bounded employee/assignment context and only the custom allowlisted tools. If the player attached a studio file, the worker validates it through the independent studio path guard, persists the relative path in SQLite, and includes bounded read-only content in the context pack.
6. Pi tool events become `tool.started` and `tool.completed`. Godot maps file edits to typing and web tools to the research table.
7. Writes create durable artifact rows and `artifact.created` events. Usage totals and cost estimates create `usage.updated` events.
8. The session is disposed. The completed job remains pending for an Approve or Discard promotion decision across restart. Approval moves guarded copies from `company-project/jobs/<job id>/` scratch into canonical `company-project/studio/` paths and records provenance; discard resolves the pending decision without copying.
9. Later jobs can read the studio through an independently guarded, read-only `studio/` tool namespace. They cannot mutate it without another completed-artifact promotion.

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
