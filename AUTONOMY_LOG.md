# Startup Valley autonomy log

Started 2026-10-13 ~22:55 PT. Mandate (Steven, Oct 13): carry the game to playable or until Grok Build credits run out. Grok Build CLI only.

## Playable bar
A new player can: (1) start a company from the title screen, (2) understand the goal from on-screen guidance, (3) progress through Chapter 1 (hire Mina, assign + complete/resolve website work order, end day), (4) continue into the next content (Theo hire / Chapter 2 milestone), and (5) reach a win/end state (chapter-complete screen) — with no dead ends, softlocks, or crashes, verified by headless Godot tests and harness tests (no paid model calls).

## Rounds
- 22:55 PT: Merged PR #2 (playability/chapter1-pass) into main as 248a1c6.

### Round 1 — 2026-10-13

**Gaps found (title → end of authored content)**
1. Website / ads / incorporate jobs required a live Grok or OpenRouter call. Headless Chapter 1 stopped at Connect; a new player without a key could not complete or resolve work.
2. After the website, Theo hire and the ads milestone were unreachable without that paid job completing.
3. The win state existed only as a Journey card when `chapter > 1`. Completing incorporation never presented a dedicated chapter-complete screen.
4. No headless test proved title → website resolve → Theo/ads → incorporate → end state without a model.

**What I fixed**
- Worker offline/fake provider (`STARTUP_VALLEY_FAKE_PROVIDER=1`): completes jobs with canned milestone files through `write_file`, injects a passing evaluation, canned chat. No credentials, no paid model. `credential.status` reports `configured` + `offline`.
- Godot Connect copy for the offline provider; Connect auto-closes when that provider is active.
- Dedicated `complete` screen (“Chapter complete”) when chapter 2 is reached after incorporation.
- `game/tests/test_full_player_path.gd` drives the real worker through title, Mina, website (assign, Add to Studio, evaluate, complete), Theo hire, ads, incorporate, and the chapter-complete screen.

**Test results** (no paid live evals)
- `cd harness && npm run build && npm test` — 70 pass, 0 fail, 2 skipped (live Godot cases needing `GODOT_BINARY`)
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (still stops at Connect without a key)
- `test_ui_drawer_redesign.gd` — 2561 checks, 0 failures
- `test_ui_flow_regressions.gd` — pass
- `test_full_player_path.gd` — FULLPATH PASS
- `test_ui_company_redesign.gd` — 3859 checks, 0 failures

**Remaining gaps (ranked)**
1. Live play still needs Sign in with Grok or an OpenRouter key. The offline provider is test-only (`STARTUP_VALLEY_FAKE_PROVIDER=1`).
2. After chapter complete, there is no authored Chapter 2 loop; the office continues with ordinary work orders.
3. Creative remains registered art/kit, not a hire. Unbound seated/outdoor art stays untracked.
4. Checks are headless input, not a watched windowed playtest.

**PLAYABLE: yes** — title → goal guidance → Chapter 1 website resolve → Theo/ads → incorporate → chapter-complete screen, verified headless with the offline provider and no paid model call.

- 23:45 PT: Verified PR #3 locally (harness 70 pass/0 fail; validate, run_all, chapter1, full_player_path all exit 0). Merged PR #3. Playable bar met (headless, offline fake provider). Stopped: bar met, not credits.
