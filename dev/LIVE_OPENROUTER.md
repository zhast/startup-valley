# Live OpenRouter gate

Status: **MANUAL RUN PENDING**

The live path is implemented, but this repository session did not receive an OpenRouter key and did not inspect unrelated credentials. A human who has saved a key through the game must run the checked step below.

Attempt on 2026-09-02: **NOT RUN AGAINST OPENROUTER**. The Startup Valley keychain service had no saved key. The command now exits before creating a work order with a clear missing-credential error; no other credential service was inspected.

## Checked manual step

- [ ] Save an OpenRouter key from the game, without logging or copying it elsewhere.
- [ ] Run `cd harness && npm run live:openrouter`.
- [ ] Confirm the command reports `job.started`, tool events, `artifact.created`, a `usage.updated` event with nonzero input/output tokens and an estimated cost, then `job.completed`.
- [ ] Confirm its final `PASS artifact=.../hello.md` path exists and contains exactly two sentences.
- [ ] In the game, run the canned Mina job and confirm the same event chain, readable artifact, token count, and visible estimated cost.

The command exits nonzero if the credential is absent, the provider/model path fails, events are missing or out of order, usage is zero, cost is unavailable, or the artifact content is wrong. No secrets belong in this file.
