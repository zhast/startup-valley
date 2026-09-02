# Live OpenRouter gate

Status: **PASSED 2026-09-02**

The key was saved through the Startup Valley game UI and read back only through the game's namespaced OS-keychain service. No credential value was printed, copied into the repository, or stored in SQLite.

The first credentialed attempt exposed a smoke-check ordering bug: Pi emitted valid zero-usage events before tool work and nonzero usage afterward. The job itself completed. The checker now selects the nonzero post-tool usage event and has a regression test.

Passing rerun on 2026-09-02: `job.started` → `tool.started` → `artifact.created` → `tool.completed` → nonzero `usage.updated` → `job.completed`. The verified totals were 827 input tokens, 50 output tokens, and estimated cost `$0.000845`. The generated `hello.md` contained exactly the required two-sentence note.

The in-game persistence flow also passed on 2026-09-02. Mina completed and promoted `studio/design-note.md` using 844 input tokens, 923 output tokens, and estimated cost `$0.004786`. After quitting and reopening Godot, the saved clock, completed status, memory, and design note restored. Theo's review was submitted off-hours, remained queued with Theo visibly off shift, started after the clock crossed 08:00, read the studio note, and completed `review.md` using 2,897 input tokens, 487 output tokens, and estimated cost `$0.004518`. After approved promotion and another restart, both studio files and Theo's completed status restored.

## Checked manual step

- [x] Save an OpenRouter key from the game, without logging or copying it elsewhere.
- [x] Run `cd harness && npm run live:openrouter`.
- [x] Confirm the command reports `job.started`, tool events, `artifact.created`, a `usage.updated` event with nonzero input/output tokens and an estimated cost, then `job.completed`.
- [x] Confirm its final `PASS artifact=.../hello.md` path exists and contains exactly two sentences.
- [x] In the game, run the canned Mina job and confirm the same event chain, readable artifact, token count, and visible estimated cost.

The command exits nonzero if the credential is absent, the provider/model path fails, events are missing or out of order, usage is zero, cost is unavailable, or the artifact content is wrong. No secrets belong in this file.
