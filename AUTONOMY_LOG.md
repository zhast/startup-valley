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

### Round 2 — 2026-10-14

**What changed**
- `OPENROUTER_API_KEY` resolves to the OpenRouter provider and wins over a Grok login and a keychain OpenRouter key. `STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1` still suppresses that key, so Chapter 1 and the full-player path stay unpaid.
- Default OpenRouter model is `openai/gpt-4o-mini` (Pi catalog, no reasoning tax). Override with `STARTUP_VALLEY_OPENROUTER_MODEL`.
- Connect shows "Connected with OpenRouter." when the key comes from the environment, including when a Grok login is also present.
- Stub credential stores do not inherit the host key. Only `KeychainCredentialStore` applies the environment key.
- Review prompt: an on-page prototype link that says signup is not open scores as a usable call to action, and a specific internal plan can score 3 without being launched.
- `npm run live:chapter` walks website → promote → evaluate → Theo → ads → incorporate against the live provider, with job budgets 10000 / 8000 / 8000.

**Live result: PASS** (attempt 3 of 3). Model `openai/gpt-4o-mini`. Chapter advanced to 2.
- Passing playthrough: 6444 input + 2019 output = 8463 tokens, usage-derived catalog cost **$0.002178**. This is Pi catalog rates times provider usage tokens, not OpenRouter's raw `usage.cost` field.
- Website ready 2.75, ads ready 2.60, incorporate ready 2.50. No revision was required on the passing run.
- Attempt 1 failed: website revise 2.00. The reviewer treated an honest "signup is not open" note as a broken signup. Spend 5536 tokens, $0.001654.
- Attempt 2 failed: website ready 2.50, ads revise 2.40 (every criterion ≥ 2, average under 2.5). Spend 9076 tokens, $0.002442.
- Three attempts together: 23075 tokens, **$0.006274**.

**Test results**
- `cd harness && npm test` — 71 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — pass (still stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — pass (offline provider)
- `test_ui_drawer_redesign.gd` — pass
- `test_ui_flow_regressions.gd` — pass

**Remaining gaps (ranked)**
1. After chapter complete there is still no authored Chapter 2 loop.
2. Creative remains registered art/kit, not a hire. Unbound seated/outdoor art stays untracked.
3. The live path is a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line; the passing ads score was 2.60.

### Round 3 — 2026-10-14

**What changed**
- Chapter complete is no longer a dead end. `chapter.continue` sets `company_state.opened_chapter` (migration 008, default 1) without putting that flag on the projected company object. The complete screen's primary action is Begin Chapter 2. Incorporation still shows that screen first; Creative and the brand work order stay locked until the player continues.
- Chapter 2 opening copy: hire Creative, then assign Journey · Design the brand (`brand/identity.md`, `brand/palette.md`). Reward $800, reputation 12, available from day 3 after incorporation. The offline provider can write those files; the full-path test stops at the hire and the desk.
- Creative is a free journey candidate (`Design + brand`) once chapter 2 is opened. Desk `creative-workstation` is south at [14, 8], `required_hires` 3, grant `hire:creative`, role kit `creative_design_kit`. Locomotion uses the existing `creative-locomotion.png`. No new art was added. Layout roster order stays Mina, Theo, Creative.
- Hire-stage furniture counts are now 1, 5, 8, 9, 10. The team rail fits three people. Furnishing actors allow four ids, including creative.
- The all-stage Mina desk-move fixture moved from [12, 7] to [24, 8]. [12, 7] south overlaps Creative's clearance once that desk exists. `test_office_layout` still accepts [12, 7] at hire stage 2 only.

**Test results** (no paid live evals)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (still stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS (offline provider, through Creative hire and desk)
- `test_ui_drawer_redesign.gd` — 2685 checks, 0 failures
- `test_ui_flow_regressions.gd` — pass
- `test_ui_company_redesign.gd` — 3880 checks, 0 failures, 0 captures
- `test_office_migration.gd` — 2631 checks passed

**Remaining gaps (ranked)**
1. The brand work order is authored, and the offline provider can complete it, but the headless full path does not finish that milestone or present a Chapter 2 end state.
2. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
3. Dev capture tools that assume a two-person layout roster (`capture_creative_design_kit.gd` and the other kit captures, plus `play_furniture_catalogue.gd` and `probe_workstation_entry.gd`) still expect `_employees.size() == 2`. They are outside the required suites.
4. Unbound seated, outdoor, and unused furnishing-kit art stays untracked.
5. The live path is still a harness driver, not a watched windowed playtest.
6. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.

- 01:55 PT Oct 14: Merged PR #4 (OpenRouter env key preferred; live Chapter 1 PASS on openai/gpt-4o-mini, passing run $0.002178 / 8463 tok, all 3 attempts $0.006274) and PR #5 (Chapter 2 opening + Creative hire/desk). Verified harness 72/0, validate, run_all, full_player_path green. Requested scope done; credits not exhausted.

### Round 4 — 2026-10-14

**What changed**
- Finishing Journey · Design the brand presents a Chapter 2 end screen: heading "Chapter 2 complete", subtitle "More is coming.", and Back to office. It does not offer Begin Chapter 2 again. Reopening Journey returns to that screen. The office hint names the same end state. Chapter stays 2. Reward is $800 and reputation 12 (cash 180000, reputation 57 after the offline chapter).
- The offline provider test now evaluates and completes the brand files, not only writes them.
- `test_full_player_path.gd` continues title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish the brand work order → Chapter 2 end state, then closes and reopens that screen.
- Dev capture tools that assumed `_employees.size() == 2` accept the authored roster of Mina, Theo, and optional Creative. No new art was added. Untracked seated, outdoor, and furnishing-kit files were left untracked.

**Test results** (no paid live evals)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (still stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS (offline provider, through brand completion and the Chapter 2 end screen)
- `test_ui_drawer_redesign.gd` — 2685 checks, 0 failures
- `test_ui_flow_regressions.gd` — pass
- `test_ui_company_redesign.gd` — 3965 checks, 0 failures, 0 captures
- `test_office_migration.gd` — 2631 checks passed

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, and unused furnishing-kit art stays untracked. Code does not reference it.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming, with Back to office and no dead end, verified headless with the offline provider and no paid model call.

- 13:35 PT Oct 14: Merged PR #6 (Chapter 2 brand work order finishes on a Chapter 2 complete / more coming screen). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, drawer, flow, company, and office migration green.

### Round 5 — 2026-10-14

**What changed**
- Bound the already-accepted `founder_strategy_kit` to `founder-workstation`. GALLERY and `ROLE_LIBRARY_ACCEPTANCE_20260906.md` mark the four facings approved (mean 2.67, min 2). The runtime PNGs are byte-exact copies of the reviewed `founder-strategy-kit-v1` fixtures. The founder desk already exists from day 1 (`owner_id` founder, south at `[8, 17]`).
- `furnishing_catalog.json` maps `founder` → `founder_strategy_kit`. New companies grant the kit on first insert; existing saves with an empty founder `role_kit` are backfilled. The furnishing schema enum now includes the kit.
- Chapter 1, the full player path, and furnishing projection tests assert the founder desk wears the two native overlay layers. No new art was generated, edited, or invented.

**Art left untracked (no safe bind)**
- `founder-seated.png` and `workstations-v2/founder-{east,north,west}.png`: QA captures call them measured PASS candidates and explicitly not bind-approved. The player still uses locomotion only; sitting would be new gameplay.
- `characters/waiting-lunch/`: no PASS record and no code path. Lunch already uses standing locomotion idle.
- `customer_success_kit` and the other unused furnishing-library kits (`engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, `product_prototype_kit`): library-approved or still candidate, but no matching hire/desk in the current chapters. `test_customer_success_kit.gd` keeps that kit fixture-scoped.
- Outdoor campus tiles and leftover `desk_lamp_kit` import sidecars: no playable outdoor scene.

**Test results** (no paid live evals)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (still stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS (offline provider, through brand completion and the Chapter 2 end screen; founder desk wears the strategy kit)
- `test_ui_drawer_redesign.gd` — 2685 checks, 0 failures
- `test_ui_flow_regressions.gd` — pass
- `test_ui_company_redesign.gd` — 3965 checks, 0 failures, 0 captures
- `test_office_migration.gd` — 2631 checks passed
- `test_founder_strategy_kit.gd` — 120 checks, 0 failures
- `test_furnishing_projection.gd` — 192 checks, 0 failures

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The founder desk now shows the accepted strategy kit from day 1.
