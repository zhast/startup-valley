# v0 vertical-slice acceptance

The slice is complete when a developer can perform this flow without Claude Code, Codex, Cursor, Grok Bot, Docker, or another subscription:

1. Install Godot 4.7.2 and Node.js 22.19 or newer.
2. Run `cd harness && npm ci && npm run build`.
3. Run `godot --path game`.
4. Paste one OpenRouter key. Confirm the UI reports that it is stored in the OS keychain.
5. Pick Mina and the canned **Inventory keyboard navigation design note** work order, then assign it.
6. Observe Mina walk to her desk only after `job.started`, and type only while a real `write_file` or `edit_file` event is active.
7. While work is active, confirm the assign control says one job at a time and use **Cancel** once to verify `job.failed`, Mina returning to idle, and the control becoming available again. Reassign the work order.
8. Observe real input/output token totals and estimated cost, followed by `artifact.created` and `job.completed`.
9. Open `design-note.md` with **Read in game** and confirm the plain-text panel contains the requested note. Confirm the file also lives under `company-project/jobs/<job id>/`.
10. Pick the canned **Review Mina's inventory note** work order. It selects Theo. Assign it and confirm Theo walks to his different desk and produces `review.md` after reading the staged Mina handoff.
11. Open `review.md` in game. Restart the game, assign Mina another job, and confirm the prior assignment/artifact/outcome memories are present in the bounded worker context without a shared transcript.

Live-provider gate before the UI flow:

```sh
cd harness && npm run live:openrouter
```

The command must report `job.started`, tool events, `artifact.created`, nonzero token usage with estimated cost, and `job.completed`, then print a passing `hello.md` path. If no key was supplied for development, [the live run record](LIVE_OPENROUTER.md) remains an explicit unchecked human step rather than using another credential.

Crash spot check: during a work order, terminate the Node worker child. The UI must synthesize `job.failed`, return the employee to idle, re-enable assignment, restart the worker once, and show the interrupted SQLite work order as failed after restart. No Pi subprocess may remain.

Automated gates:

```sh
cd harness && npm test
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
```

Security spot checks:

- No OpenRouter key appears in SQLite, worker logs, environment dumps, Pi sessions, prompts, or Godot project files.
- Pi reports only the custom allowlisted tools. There is no `bash`, PowerShell, subprocess, package installer, test runner, Playwright, or visible browser tool.
- File tool tests reject absolute paths, parent traversal, Windows drive paths, and symlink escapes.
- The worker opens no localhost listener.
- Completion memory writeback creates only structured assignment, artifact, and outcome rows. Pi session JSONL is not employee memory.
- Theo receives Mina's SQLite summary and artifact path plus a rooted `handoffs/` copy. No transcript or recursive employee messaging is shared.
