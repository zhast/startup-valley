# Persistent studio + day-cycle acceptance

The slice is complete when a developer can perform this flow without Claude Code, Codex, Cursor, Grok Bot, Docker, or another subscription:

1. Install Godot 4.7.2 and Node.js 22.19 or newer.
2. Run `cd harness && npm ci && npm run build`.
3. Run `godot --path game`.
4. Paste one OpenRouter key. Confirm the UI reports that it is stored in the OS keychain.
5. Confirm the restored clock, most recent work-order status, employees, and any existing studio files appear after boot.
6. During a work window, pick Mina and the canned **Inventory keyboard navigation design note** work order, then assign it. Confirm the canned Theo review remains available too.
7. Observe Mina walk to her desk only after `job.started`, and type only while a real `write_file` or `edit_file` event is active.
8. Observe real input/output token totals and estimated cost, followed by `artifact.created` and `job.completed`.
9. Leave the finished artifact unpromoted, quit Godot, and reopen. Confirm the finished work returns with **Approve** and **Discard** choices. Exercise Discard with a test artifact and confirm it does not return on another reopen.
10. Approve Mina's artifact promotion. Confirm `studio/design-note.md` appears in **Studio files**, opens in the in-game text panel, and exists under the durable company project `studio/` directory.
11. Quit and reopen again. Confirm the clock, Mina's memories, completed status, and clickable `studio/design-note.md` listing are restored.
12. Choose **Custom work order…**, select Theo, enter a title and instruction body, and attach `studio/design-note.md` as read context. Submit it and confirm the SQLite work-order row preserves the exact title, instructions, and attached relative path.
13. Confirm the custom job receives a fresh bounded Pi session with Theo's persona, bounded memories, and the attached file content. It must use the same guarded tools and produce a scratch artifact for explicit promotion.
14. While Theo is actively working, send a correction through **Update active job**. Confirm it is delivered to the same job and Pi session without creating a second work order.
15. Approve Theo's new artifact, then open it from the durable **Studio files** list in the current artifact text viewer.
16. Pick the canned **Review Mina's inventory note** and confirm it still selects Theo, reads `studio/design-note.md`, and produces `review.md`.
17. Wait for or restore the saved clock to 12:30 or after 17:30, submit a freeform work order, and confirm it remains queued with no walking or typing. Let the clock cross 13:30 or 08:00 and confirm `job.started` then moves the employee to their desk. The player HUD must not expose speed controls.
18. Try to submit a protocol work order with a missing attached studio path. Confirm it fails before a work-order row is created.
19. With no live job, confirm on-shift employees only sit, wander, or show one memory line; at lunch they go to lunch, and after 17:30 they display off shift.
20. Quit during a work order. Confirm the worker child exits, the last status restores as blocked/cancelled, and no Pi process remains.

Live-provider gate before the UI flow:

```sh
cd harness && npm run live:openrouter
```

The command must report `job.started`, tool events, `artifact.created`, nonzero token usage with estimated cost, and `job.completed`, then print a passing `hello.md` path. If no key was supplied for development, [the live run record](LIVE_OPENROUTER.md) remains an explicit unchecked human step rather than using another credential.

Crash spot check: during a work order, terminate the Node worker child. The UI must synthesize `job.failed`, return the employee to idle, re-enable assignment, restart the worker once, and show the interrupted SQLite work order as failed after restart. No Pi subprocess may remain.

Automated gates:

```sh
cd harness && npm test
cd harness && npm run eval:offline
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
```

The worker suite includes explicit no-provider tests for promotion resume, discard, exact freeform instruction persistence, off-hours freeform queuing, fail-closed missing attachments, simultaneous assignment submission, malformed JSONL recovery, missing credentials, and SIGKILL during think/read/write/approval/complete/promote. The process tests verify the worker PID is gone, and terminal recovery clears the employee assignment.

The offline evaluator must report 8/8 fixtures. Its objective checkers cover create, exact edit, attached context, off-hours queue, missing attachment, path traversal, direct studio-write denial, and approved promotion with provenance. It hashes the studio file tree and compares SQLite studio records before and after; any unapproved mutation fails the run. See [the checked-in report](eval/OFFLINE_REPORT.md).

Security spot checks:

- No OpenRouter key appears in SQLite, worker logs, environment dumps, Pi sessions, prompts, or Godot project files.
- Pi reports only the custom allowlisted tools. There is no `bash`, PowerShell, subprocess, package installer, test runner, Playwright, or visible browser tool.
- File tool tests reject absolute paths, parent traversal, Windows drive paths, and symlink escapes.
- The worker opens no localhost listener.
- Completion memory writeback creates only structured assignment, artifact, and outcome rows. Pi session JSONL is not employee memory.
- Theo receives Mina's SQLite summary and canonical `studio/design-note.md` path. No transcript or recursive employee messaging is shared.
- Job tools cannot write directly to `studio/`; only player-approved promotion crosses from guarded job scratch into the independently guarded durable tree.
