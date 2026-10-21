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

- 15:45 PT Oct 14: Merged PR #7 (founder strategy kit bound to the founder desk). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, founder kit and furnishing projection green.

### Round 6 — 2026-10-14

**What changed**
- Registered the GALLERY-approved `coat_bag_stand` (`coat-bag-stand-v3`, mean 2.83 / min 2 in `PASSIVE_LIGHTING_ENTRY_NATIVE_REVIEW.md`) into the playable furnishing catalog, mirroring `task_floor_lamp`. All four facings are `runtime_ready`. `interaction_kind` is `none`. The profile is decorative, occupies `[[0,0]]`, and uses the authored interaction cell for clearance and the standing viewpoint: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`.
- `decor-coat_bag_stand` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The coat stand stays in storage until the player places it.
- Runtime layers are the already-copied byte-exact v3 PNGs under `game/assets/runtime/office/furnishing-library/coat_bag_stand/`. The dev capture tool lists `decor-coat_bag_stand` at `[19, 18]` facing south and rotates it with the other native décor.

**Art HOLD**
- No new art was generated or edited. `desk_lamp_kit` stays library-approved and unbound. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `desk_lamp_kit` is reviewed and not registered in the playable office.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 219 checks, 0 failures (includes `coat_bag_stand` at `[23, 17]` all facings)
- `test_furniture_directions.gd` — 461 checks, 0 failures
- `test_archive_production.gd` — 3307 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The coat stand is owned starter décor and stays in storage until placed.

- 17:20 PT Oct 14: Merged PR #8 (coat bag stand registered as starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, and furnishing projection green.

### Round 7 — 2026-10-15

**What changed**
- Bound the GALLERY-approved `desk_lamp_kit` (`desk-lamp-kit-v2`, mean 2.67 / min 2 in `dev/PASSIVE_LIGHTING_ENTRY_NATIVE_REVIEW.md`) to the founder desk as a host-surface decor kit. It is not freestanding furniture: zero occupied cells, Kit → desk. It does not replace `founder_strategy_kit`. Lamp overlays are appended after the role-kit layers.
- `furnishing_catalog.json` adds `decor_kits.desk_lamp_kit`, `employee_decor_kits.founder = desk_lamp_kit`, and the fragment's `source_copies`. Runtime PNGs were already tracked and match those SHA-256 hashes. Godot `.import` sidecars for those PNGs are now tracked. No inventory column or furnishing-schema enum was added; the catalog map is enough.
- `office_layout.gd` loads `decor_kits` and `employee_decor_kits`. A placement uses `decor_kit` / `decorKit` when that field is non-empty, otherwise the owner map. Host kind and owner must match. Render layers append and visual bounds union. A mismatch records a direction error, the same way a role kit does.
- The harness unions the decor kit's `visual_bounds` with the desk and the role kit when `employee_decor_kits` names one for that `ownerId` and `host_kind` matches. It still adds no cells.
- Chapter 1, the full player path, and furnishing projection assert the founder desk wears both kits: two strategy layers, then two lamp layers (four furnishing-library kit layers). Mina and Theo stay at two. The dev capture tool checks the same stack on the founder desk.

**Art HOLD**
- No new art was generated or edited. The lamp layers are the already-copied byte-exact v2 PNGs. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 246 checks, 0 failures (founder desk: 2 strategy + 2 lamp layers on every facing; Mina and Theo stay at 2)
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored; founder desk stacks the lamp on the strategy kit)
- `test_full_player_path.gd` — FULLPATH PASS (offline provider, through brand completion and the Chapter 2 end screen; founder desk stacks the lamp on the strategy kit)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The founder desk shows the strategy kit and the desk lamp from day 1.

- 09:22 PT Oct 15: Merged PR #9 (desk_lamp_kit bound to the founder desk as stacked decor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, and furnishing projection green.

### Round 8 — 2026-10-15

**What changed**
- Registered the GALLERY-approved `water_station` (`water-station-v2`, mean 2.50 / min 2 in `dev/PASSIVE_SERVICE_LIBRARY_NATIVE_REVIEW.md`) into the playable furnishing catalog, mirroring `coat_bag_stand`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no dispensing or service). The profile is decorative and occupies two cells per facing, in manifest order: north `[[1,0],[0,0]]`, east `[[0,1],[0,0]]`, south `[[-1,0],[0,0]]`, west `[[0,-1],[0,0]]`. Clearance and the standing viewpoint use the authored approach cell: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`.
- `decor-water_station` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The water station stays in storage until the player places it.
- Runtime layers are byte-exact copies of the water-station-v2 PNGs under `game/assets/runtime/office/furnishing-library/water_station/`. The dev capture tool lists `decor-water_station` at `[24, 8]` facing south and rotates it with the other native décor. `[24, 8]` is the nearest cell that stays valid for every facing while the planter, lamp, coat stand, and pedestal rotate; the south cluster around `[19, 18]`–`[25, 18]` overlaps this two-cell footprint.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 277 checks, 0 failures (includes `water_station` at `[23, 17]` all facings, exact two-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 462 checks, 0 failures
- `test_archive_production.gd` — 3308 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (five native décor rotate through all facings)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The water station is owned starter décor and stays in storage until placed.

- 11:39 PT Oct 15: Merged PR #10 (water_station registered as two-cell starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection, furniture directions, archive production, and decor capture green.

### Round 9 — 2026-10-15

**What changed**
- Registered the GALLERY-approved `resource_cart` (`resource-cart-v1`, mean 2.67 / min 2 in `dev/PASSIVE_SERVICE_LIBRARY_NATIVE_REVIEW.md`) into the playable furnishing catalog, mirroring `water_station`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no cart movement or supply service). The profile is decorative and occupies two cells per facing, in manifest order: north `[[1,0],[0,0]]`, east `[[0,1],[0,0]]`, south `[[-1,0],[0,0]]`, west `[[0,-1],[0,0]]`. Clearance and the standing viewpoint use the authored approach cell: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`.
- `decor-resource_cart` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The supply cart stays in storage until the player places it.
- Runtime layers are byte-exact copies of the resource-cart-v1 PNGs under `game/assets/runtime/office/furnishing-library/resource_cart/`. The dev capture tool lists `decor-resource_cart` at `[4, 18]` facing south and rotates it with the other native décor. `[4, 18]` is the nearest cell that stays valid for every facing while the planter, lamp, coat stand, water station, and pedestal rotate; the south cluster and the cells beside the water station at `[24, 8]` overlap this two-cell footprint.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 308 checks, 0 failures (includes `resource_cart` at `[23, 17]` all facings, exact two-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 463 checks, 0 failures
- `test_archive_production.gd` — 3309 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (six native décor rotate through all facings)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The supply cart is owned starter décor and stays in storage until placed.

- 13:26 PT Oct 15: Merged PR #11 (resource_cart registered as two-cell starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection, furniture directions, archive production, and decor capture green.

### Round 10 — 2026-10-15

**What changed**
- Registered the GALLERY-approved `printer_scanner_station` (`printer-scanner-station-v1`, mean 2.50 / min 2 in `dev/PASSIVE_SERVICE_LIBRARY_NATIVE_REVIEW.md`) into the playable furnishing catalog, mirroring `resource_cart`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no printing, scanning, or service). The profile is decorative and occupies two cells per facing, in manifest order: north `[[1,0],[0,0]]`, east `[[0,1],[0,0]]`, south `[[-1,0],[0,0]]`, west `[[0,-1],[0,0]]`. Clearance and the standing viewpoint use the authored approach cell: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`.
- `decor-printer_scanner_station` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The printer station stays in storage until the player places it.
- Runtime layers are byte-exact copies of the printer-scanner-station-v1 PNGs under `game/assets/runtime/office/furnishing-library/printer_scanner_station/`. The dev capture tool lists `decor-printer_scanner_station` at `[22, 16]` facing south and rotates it with the other native décor. `[22, 16]` is the last four-facing two-cell pocket once the cart occupies `[4, 18]` and the water station occupies `[24, 8]`; the planter relocates to `[32, 13]`, a one-cell east-bay cell valid for every facing beside the approval console.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 339 checks, 0 failures (includes `printer_scanner_station` at `[23, 17]` all facings, exact two-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 464 checks, 0 failures
- `test_archive_production.gd` — 3310 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (seven native décor rotate through all facings)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The printer station is owned starter décor and stays in storage until placed.

- 15:38 PT Oct 15: Merged PR #12 (printer_scanner_station registered as two-cell starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection, furniture directions, archive production, and decor capture green.

### Round 11 — 2026-10-15

**What changed**
- Registered the art-approved `recycling_sorter` (`recycling-sorter-v2`, mean 2.67 / min 2 in `dev/PASSIVE_UTILITY_LIBRARY_V2_NATIVE_REVIEW.md`) into the playable furnishing catalog, mirroring `printer_scanner_station`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no sorting, waste, or service). The profile is decorative and occupies two cells per facing, in manifest order: north `[[1,0],[0,0]]`, east `[[0,1],[0,0]]`, south `[[-1,0],[0,0]]`, west `[[0,-1],[0,0]]`. Clearance and the standing viewpoint use the authored approach cell: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`.
- `decor-recycling_sorter` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The recycling sorter stays in storage until the player places it.
- Runtime layers are byte-exact copies of the recycling-sorter-v2 PNGs under `game/assets/runtime/office/furnishing-library/recycling_sorter/`. Canvas is `[160,176]`, pivot `[80,112]`, sprite offset `[0,-24]`. The dev capture tool lists `decor-recycling_sorter` at `[13, 19]` facing south and rotates it with the other native décor. The cart stays at `[4, 18]`, the water station at `[24, 8]`, and the printer at `[22, 16]`. `[13, 19]` is an open south-floor pocket that stays valid for every facing; west occupies `[13, 18]`, clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places it at `[23, 17]` after the printer returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `tall_storage_cabinet` and `server_cabinet` (passive utility v2, art-approved, mean 2.67 / min 2) are the next registration candidates. They stay out of the playable catalog.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 370 checks, 0 failures (includes `recycling_sorter` at `[23, 17]` all facings, exact two-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 465 checks, 0 failures
- `test_archive_production.gd` — 3311 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (eight native décor rotate through all facings)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The recycling sorter is owned starter décor and stays in storage until placed.

- 17:36 PT Oct 15: Merged PR #13 (recycling_sorter registered as two-cell starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection, furniture directions, archive production, and decor capture green.

### Round 12 — 2026-10-16

**What changed**
- Registered the art-approved `tall_storage_cabinet` (`tall-storage-cabinet-v2`, mean 2.67 / min 2 in `dev/PASSIVE_UTILITY_LIBRARY_V2_NATIVE_REVIEW.md`) into the playable furnishing catalog, mirroring `recycling_sorter`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no storage, inventory, or service). The profile is decorative and occupies two cells per facing, in manifest order: north `[[1,0],[0,0]]`, east `[[0,1],[0,0]]`, south `[[-1,0],[0,0]]`, west `[[0,-1],[0,0]]`. Clearance and the standing viewpoint use the authored approach cell: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`.
- `decor-tall_storage_cabinet` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The supply cabinet stays in storage until the player places it.
- Runtime layers are byte-exact copies of the tall-storage-cabinet-v2 PNGs under `game/assets/runtime/office/furnishing-library/tall_storage_cabinet/`. Canvas is `[160,288]`, pivot `[80,224]`, sprite offset `[0,-80]`. The dev capture tool lists `decor-tall_storage_cabinet` at `[25, 19]` facing south and rotates it with the other native décor. The task floor lamp moved from `[25, 18]` to `[7, 9]` so the cabinet stays inside artwork and standing headroom for every facing. The recycling sorter stays at `[13, 19]`. `[25, 19]` stays valid for every facing; west occupies `[25, 18]`, clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places it at `[23, 17]` after the recycling sorter returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `server_cabinet` (utility v2, art-approved) is the next registration candidate.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 401 checks, 0 failures (includes `tall_storage_cabinet` at `[23, 17]` all facings, exact two-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 466 checks, 0 failures
- `test_archive_production.gd` — 3312 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (nine native décor rotate through all facings)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The supply cabinet is owned starter décor and stays in storage until placed.

- 09:30 PT Oct 16: Merged PR #14 (tall_storage_cabinet registered as two-cell starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection, furniture directions, archive production, and decor capture green.

### Round 13 — 2026-10-16

**What changed**
- Registered the art-approved `server_cabinet` (`server-cabinet-v2`, mean 2.67 / min 2 in `dev/PASSIVE_UTILITY_LIBRARY_V2_NATIVE_REVIEW.md`) into the playable furnishing catalog, mirroring `tall_storage_cabinet`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no server, network, or service). The profile is decorative and occupies two cells per facing, in manifest order: north `[[1,0],[0,0]]`, east `[[0,1],[0,0]]`, south `[[-1,0],[0,0]]`, west `[[0,-1],[0,0]]`. Clearance and the standing viewpoint use the authored approach cell: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`.
- `decor-server_cabinet` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The server cabinet stays in storage until the player places it.
- Runtime layers are byte-exact copies of the server-cabinet-v2 PNGs under `game/assets/runtime/office/furnishing-library/server_cabinet/`. Canvas is `[160,288]`, pivot `[80,224]`, sprite offset `[0,-80]`. The dev capture tool lists `decor-server_cabinet` at `[25, 14]` facing south and rotates it with the other native décor. No other décor moved. `[25, 14]` stays valid for every facing while the other nine décor rotate; west occupies `[25, 13]`, clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places it at `[23, 17]` after the supply cabinet returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. All three passive utility v2 pieces (`recycling_sorter`, `tall_storage_cabinet`, `server_cabinet`) are now registered. No art-approved décor candidate is queued. Reviews still pass unregistered `visitor_chair`, `mobile_whiteboard`, `low_bookshelf`, and `acoustic_divider` (`dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`), `low_coffee_table` and `round_meeting_table` (`dev/art-catalogue/PASSIVE_TABLES_REVIEW_2026-09-06.md`), and `two_seat_sofa` and `lounge_armchair` (`dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`). None of those reviews names a registration order.

**Test results** (no paid live evals; Node 22 / unpaid fake provider)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 432 checks, 0 failures (includes `server_cabinet` at `[23, 17]` all facings, exact two-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 467 checks, 0 failures
- `test_archive_production.gd` — 3313 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (ten native décor rotate through all facings)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The server cabinet is owned starter décor and stays in storage until placed.

- 11:37 PT Oct 16: Merged PR #15 (server_cabinet registered as two-cell starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection, furniture directions, archive production, and decor capture green.

### Round 14 — 2026-10-16

**What changed**
- Registered the art-approved `low_coffee_table` (`low-coffee-table-v1`, mean 2.83 / min 2 in `dev/art-catalogue/PASSIVE_TABLES_REVIEW_2026-09-06.md`, display name "Low lounge table") into the playable furnishing catalog, mirroring `server_cabinet`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no seat, service, or work). The profile is decorative and occupies two cells per facing, in manifest order: north `[[-1,0],[0,0]]`, east `[[0,-1],[0,0]]`, south `[[0,0],[1,0]]`, west `[[0,0],[0,1]]`. The manifest and `passive_table_geometry.gd` leave clearance empty and define no standing cell, so clearance and the standing viewpoint use the same front approach cell as `server_cabinet` and `tall_storage_cabinet`: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`. The standing envelope is `[-24,-76,48,84]`, the same rectangle every other decorative profile uses.
- `decor-low_coffee_table` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The low lounge table stays in storage until the player places it.
- Runtime layers are byte-exact copies of the low-coffee-table-v1 PNGs under `game/assets/runtime/office/furnishing-library/low_coffee_table/`. Canvas is `[160,160]`, pivot `[80,96]`, sprite offset `[0,-16]`. Render regions are the full canvas and layer offsets are that sprite offset, matching how `server_cabinet` maps its manifest. Layer names are `LowCoffeeTableV1` plus facing plus layer, because this manifest has no layer-name field. The dev capture tool lists `decor-low_coffee_table` at `[20, 19]` facing south and rotates it with the other native décor. No four-facing cell stayed free while the previous ten décor kept their cells, so the one-cell coat stand moved from `[19, 18]` to `[32, 19]`. `[20, 19]` then stays valid for every facing; west occupies `[20, 20]`, clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places the table at `[23, 17]` after the server cabinet returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `low_coffee_table` is now registered. From the same passive-tables review, `cafe_table` (v2) and `round_meeting_table` remain passed but unregistered. The catalogue already uses the kind name `cafe_table` for an older one-cell south prop (`res://assets/runtime/office/cafe-table-south.png`); the passed cafe-table-v2 library is still unregistered. Reviews still pass unregistered `visitor_chair`, `mobile_whiteboard`, `low_bookshelf`, and `acoustic_divider` (`dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`), and `two_seat_sofa` and `lounge_armchair` (`dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`). None of those reviews names a registration order.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 463 checks, 0 failures (includes `low_coffee_table` at `[23, 17]` all facings, exact two-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 468 checks, 0 failures
- `test_archive_production.gd` — 3314 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures (low lounge table is in the ordinary catalogue; round meeting table stays out; the older cafe prop is unchanged)
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (eleven native décor rotate through all facings; table at `[20, 19]`, coat stand at `[32, 19]`)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The low lounge table is owned starter décor and stays in storage until placed.

- 13:34 PT Oct 16: Merged PR #16 (low_coffee_table registered as two-cell starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection 463/0, furniture directions 468/0, archive production 3314/0, passive tables 628/0, and decor capture 79/0 green.

### Round 15 — 2026-10-16

**What changed**
- Registered the art-approved `round_meeting_table` (`round-meeting-table-v1`, mean 2.83 in `dev/art-catalogue/PASSIVE_TABLES_REVIEW_2026-09-06.md`, display name "Meeting table") into the playable furnishing catalog, mirroring `low_coffee_table`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no seat, service, or work). The profile is decorative and occupies a 3×3 square in every facing. The pivot cell is `[0,0]`; occupied cells follow the manifest and `passive_table_geometry.gd` order: `[[-1,-1],[0,-1],[1,-1],[-1,0],[0,0],[1,0],[-1,1],[0,1],[1,1]]`. The manifest and geometry leave clearance empty and define no standing cell, so clearance and the standing viewpoint use the front approach cell just outside that square: north `[0,-2]`, east `[2,0]`, south `[0,2]`, west `[-2,0]`. The standing envelope is `[-24,-76,48,84]`, the same rectangle every other decorative profile uses.
- `decor-round_meeting_table` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The meeting table stays in storage until the player places it.
- Runtime layers are byte-exact copies of the round-meeting-table-v1 PNGs under `game/assets/runtime/office/furnishing-library/round_meeting_table/`. Canvas is `[224,288]`, pivot `[112,176]`, sprite offset `[0,-32]`. Render regions are the full canvas and layer offsets are that sprite offset, matching how `low_coffee_table` maps its manifest. Layer names are `RoundMeetingTableV1` plus facing plus layer, because this manifest has no layer-name field. All four composites are rotationally symmetric. The dev capture tool lists `decor-round_meeting_table` at `[7, 7]` facing south and rotates it with the other native décor. No four-facing 3×3 stayed free while the previous eleven décor kept their cells, so the one-cell lamp moved from `[7, 9]` to `[19, 14]`. `[7, 7]` then stays valid for every facing; occupied is `[6,6]` through `[8,8]`, west clearance is `[5, 7]`, clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places the table at `[23, 17]` after the low lounge table returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `low_coffee_table` and `round_meeting_table` are now registered. From the same passive-tables review, `cafe_table` (v2) remains passed but unregistered. The catalogue already uses the kind name `cafe_table` for an older one-cell south prop (`res://assets/runtime/office/cafe-table-south.png`); the passed cafe-table-v2 library is still unregistered. Reviews still pass unregistered `visitor_chair`, `mobile_whiteboard`, `low_bookshelf`, and `acoustic_divider` (`dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`), and `two_seat_sofa` and `lounge_armchair` (`dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`). None of those reviews names a registration order.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 494 checks, 0 failures (includes `round_meeting_table` at `[23, 17]` all facings, exact nine-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 469 checks, 0 failures
- `test_archive_production.gd` — 3315 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures (low lounge table and round meeting table are in the ordinary catalogue; the older cafe prop is unchanged)
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (twelve native décor rotate through all facings; table at `[7, 7]`, lamp at `[19, 14]`)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The meeting table is owned starter décor and stays in storage until placed.

- 15:43 PT Oct 16: Merged PR #17 (round_meeting_table registered as 3x3 starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection 494/0, furniture directions 469/0, archive production 3315/0, passive tables 628/0, and decor capture 79/0 green.

### Round 16 — 2026-10-16

**What changed**
- Registered the art-approved `low_bookshelf` (`low-bookshelf-v1`, mean 2.50 Pass in `dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`, display name "Low resource shelf") into the playable furnishing catalog, mirroring `round_meeting_table`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no seat, service, or work). The profile is decorative. Native canvas is `[192, 224]`, floor pivot `[96, 160]`, sprite offset `[0, -48]`. Layer order is Carcass, Top, Front, Plinth, Insert. East and west are byte-identical closed ends. North is a plain rear. Only south carries the books row. Occupied cells follow the registration proposal order (the same cells as `low_bookshelf_geometry.gd`): north `[[1,0],[0,0],[-1,0]]`, east `[[0,1],[0,0],[0,-1]]`, south `[[-1,0],[0,0],[1,0]]`, west `[[0,-1],[0,0],[0,1]]`. The current registration leaves the interaction cell empty, so clearance and the standing viewpoint use the front approach cell just outside that strip, matching the historical geometry interaction cells and the reference axis: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`. The standing envelope is `[-24,-76,48,84]`, the same rectangle every other decorative profile uses.
- `decor-low_bookshelf` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The low bookshelf stays in storage until the player places it.
- Runtime layers are byte-exact copies of the low-bookshelf-v1 layer and whole PNGs under `game/assets/runtime/office/furnishing-library/low_bookshelf/`. The books-row source and 8x preview were not copied. Render regions are the full canvas and every layer offset is `[0, -48]`. All layers use `z_offset` 0. Layer names are `LowBookshelfV1` plus facing plus layer. The dev capture tool lists `decor-low_bookshelf` at `[7, 13]` facing south and rotates it with the other native décor. No four-facing pocket stayed free while the previous twelve décor kept their cells, so the one-cell rolling pedestal moved from `[7, 13]` to `[32, 6]`. `[7, 13]` then stays valid for every facing. North and south occupy `[6, 13]` through `[8, 13]`; east and west occupy `[7, 12]` through `[7, 14]`. West clearance is `[6, 13]`. Clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places the shelf at `[23, 17]` after the meeting table returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `low_bookshelf` is now registered. From the passive furniture library review, `visitor_chair`, `mobile_whiteboard`, and `acoustic_divider` remain passed but unregistered (`dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`). From the passive-tables review, `cafe_table` (v2) remains passed but unregistered. The catalogue already uses the kind name `cafe_table` for an older one-cell south prop (`res://assets/runtime/office/cafe-table-south.png`); the passed cafe-table-v2 library is still unregistered. Reviews still pass unregistered `two_seat_sofa` and `lounge_armchair` (`dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`). None of those reviews names a registration order.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 533 checks, 0 failures (includes `low_bookshelf` at `[23, 17]` all facings, exact three-cell footprint, 5 native layers)
- `test_furniture_directions.gd` — 470 checks, 0 failures
- `test_archive_production.gd` — 3316 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures (low lounge table and round meeting table stay in the ordinary catalogue; the bookshelf is not a table)
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (thirteen native décor rotate through all facings; shelf at `[7, 13]`, pedestal moved to `[32, 6]`)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The low bookshelf is owned starter décor and stays in storage until placed.

- 17:32 PT Oct 16: Merged PR #18 (low_bookshelf registered as starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection 533/0, furniture directions 470/0, archive production 3316/0, passive tables 628/0, and decor capture 79/0 green.

### Round 17 — 2026-10-19

**What changed**
- Registered the art-approved `acoustic_divider` (acoustic-divider-v1, mean 2.50 Pass in `dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`, display name "Acoustic divider") into the playable furnishing catalog, mirroring `low_bookshelf`. All four facings are `runtime_ready`. `interaction_kind` is `none` (no seat, service, work, or acoustic simulation). The profile is decorative. Native canvas is `[192, 224]`, floor pivot `[96, 160]`, sprite offset `[0, -48]` (`canvas / 2 - pivot`, also the geometry tool's catalog offset). Layer order is RearSupport, Panel, FrontFoot. North and south are byte-identical. East and west are byte-identical. Occupied cells follow the registration proposal order (the same cells as `acoustic_divider_geometry.gd`; south and west reverse that tool's shared order): north `[[-1,0],[0,0],[1,0]]`, east `[[0,-1],[0,0],[0,1]]`, south `[[1,0],[0,0],[-1,0]]`, west `[[0,1],[0,0],[0,-1]]`. The proposal leaves the interaction cell empty and the geometry tool's clearance list is empty, so clearance and the standing viewpoint use the reference-axis front cell: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`. Neither source authors a standing envelope, so the viewpoint uses `[-24,-76,48,84]`, the same rectangle every other decorative profile uses. Visual and hit bounds are the proposal opaque bounds minus the floor pivot (the measured layer union): north/south `[-44,-67,88,83]`, east/west `[-16,-108,32,148]`.
- `decor-acoustic_divider` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The acoustic divider stays in storage until the player places it.
- Runtime layers are byte-exact copies of the acoustic-divider-v1 layer and whole PNGs under `game/assets/runtime/office/furnishing-library/acoustic_divider/`. Render regions are the full canvas and every layer offset is `[0, -48]`. All layers use `z_offset` 0. Layer names are `AcousticDividerV1` plus facing plus layer. The dev capture tool lists `decor-acoustic_divider` at `[23, 6]` facing south and rotates it with the other native décor. No four-facing pocket stayed free while the previous thirteen décor kept their cells, and moving any one of them left that piece without a home. The water station moves from `[24, 8]` to `[22, 13]` and the printer moves from `[22, 16]` to `[22, 17]`, which leaves `[23, 6]` valid for every facing. North and south occupy `[22, 6]` through `[24, 6]`; east and west occupy `[23, 5]` through `[23, 7]`. West clearance is `[22, 6]`. Clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places the divider at `[23, 17]` after the low bookshelf returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `acoustic_divider` is now registered. From the passive furniture library review, `visitor_chair` and `mobile_whiteboard` remain passed but unregistered (`dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`). From the passive-tables review, `cafe_table` (v2) remains passed but unregistered. The catalogue already uses the kind name `cafe_table` for an older one-cell south prop (`res://assets/runtime/office/cafe-table-south.png`); the passed cafe-table-v2 library is still unregistered. Reviews still pass unregistered `two_seat_sofa` and `lounge_armchair` (`dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`). None of those reviews names a registration order.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 564 checks, 0 failures (includes `acoustic_divider` at `[23, 17]` all facings, exact three-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 471 checks, 0 failures
- `test_archive_production.gd` — 3317 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures (low lounge table and round meeting table stay in the ordinary catalogue; the divider is not a table)
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (fourteen native décor rotate through all facings; divider at `[23, 6]`, water station moved to `[22, 13]`, printer moved to `[22, 17]`)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The acoustic divider is owned starter décor and stays in storage until placed.

- 10:23 PT Oct 19: Merged PR #19 (acoustic_divider registered as starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, chapter1, full_player_path, furnishing projection 564/0, furniture directions 471/0, archive production 3317/0, passive tables 628/0, acoustic divider 66/0, and decor capture 79/0 green.

### Round 18 — 2026-10-19

**What changed**
- Registered the art-approved `mobile_whiteboard` (mobile-whiteboard-v1, mean 2.50 Pass in `dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`, display name "Mobile whiteboard") into the playable furnishing catalog, mirroring `acoustic_divider`. The older unrelated `whiteboard` kind is unchanged. All four facings are `runtime_ready`. `interaction_kind` is `none` (no writing, service, work, or planning action). The profile is decorative. Native canvas is `[192, 224]`, floor pivot `[96, 160]`, sprite offset `[0, -48]` (`canvas / 2 - pivot`, also the geometry tool's sprite position). Layer order is GroundBase, RearSupports, FarTray, BoardFrame, FaceInsert, NearTray, NearSupports. `face_insert` is a registered blank layer of the base board in the output manifest and the proposal native exports (opaque pixels 0, bounds `[0, 0, 0, 0]` on every facing), so it is included. The optional South planning composite `south-planning-whole.png` and the `-4x` images are not registered. North and south wholes are not byte-identical. East and west wholes are not byte-identical. Occupied cells follow the registration proposal order (the same cells as `mobile_whiteboard_geometry.gd`; north and east reverse that tool's shared order): north `[[1,0],[0,0],[-1,0]]`, east `[[0,1],[0,0],[0,-1]]`, south `[[-1,0],[0,0],[1,0]]`, west `[[0,-1],[0,0],[0,1]]`. Clearance and the standing viewpoint use the proposal interaction cell, which matches the geometry tool's visitor offset: north `[0,-1]`, east `[1,0]`, south `[0,1]`, west `[-1,0]`. The geometry tool and contract author the standing envelope `[-24,-72,48,80]`, so that rectangle is used instead of the taller decorative pad. Visual and hit bounds are the proposal opaque-union bounds minus the floor pivot: north/south `[-48,-82,96,98]`, east/west `[-16,-124,32,172]`.
- `decor-mobile_whiteboard` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The mobile whiteboard stays in storage until the player places it.
- Runtime layers are byte-exact copies of the mobile-whiteboard-v1 blank-board layer and whole PNGs under `game/assets/runtime/office/furnishing-library/mobile_whiteboard/`. Render regions are the full canvas and every layer offset is `[0, -48]`. All layers use `z_offset` 0. Layer names are `MobileWhiteboardV1` plus facing plus layer. The dev capture tool lists `decor-mobile_whiteboard` at `[7, 13]` facing south and rotates it with the other native décor. No four-facing pocket stayed free while the previous fourteen décor kept their cells, and moving any one-cell piece left this board without a home. The low bookshelf moves from `[7, 13]` to `[25, 8]`, which leaves `[7, 13]` valid for every facing. North and south occupy `[6, 13]` through `[8, 13]`; east and west occupy `[7, 12]` through `[7, 14]`. West clearance is `[6, 13]`. Clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places the whiteboard at `[23, 17]` after the acoustic divider returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `mobile_whiteboard` is now registered. From the passive furniture library review, `visitor_chair` remains passed but unregistered (`dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md`). From the passive-tables review, `cafe_table` (v2) remains passed but unregistered. The catalogue already uses the kind name `cafe_table` for an older one-cell south prop (`res://assets/runtime/office/cafe-table-south.png`); the passed cafe-table-v2 library is still unregistered. Reviews still pass unregistered `two_seat_sofa` and `lounge_armchair` (`dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`). None of those reviews names a registration order.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 611 checks, 0 failures (includes `mobile_whiteboard` at `[23, 17]` all facings, exact three-cell footprint, 7 native layers)
- `test_furniture_directions.gd` — 472 checks, 0 failures
- `test_archive_production.gd` — 3318 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures (low lounge table and round meeting table stay in the ordinary catalogue; the whiteboard is not a table)
- `test_acoustic_divider.gd` — 66 checks, 0 failures
- `test_mobile_whiteboard.gd` — 1628 checks, 0 failures
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (fifteen native décor rotate through all facings; whiteboard at `[7, 13]`, low bookshelf moved to `[25, 8]`)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The mobile whiteboard is owned starter décor and stays in storage until placed.

- 11:55 PT Oct 19: Merged PR #20 (mobile_whiteboard registered as starter décor). Verified harness 72/0, eval:offline 8/8, validate, run_all, furnishing projection 611/0, furniture directions 472/0, archive production 3318/0, chapter1, full_player_path, passive tables 628/0, acoustic divider 66/0, mobile whiteboard 0 failures (1628 and 2433 checks across two runs; count varies with physics steps), passive furniture 1219/0, and decor capture 79/0 green.

### Round 19 — 2026-10-19

**What changed**
- Registered the art-approved `visitor_chair` (visitor-chair-v2, mean 2.83, "Pass after shadow-only correction" in `dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md` and `dev/art-catalogue/VISITOR_CHAIR_V2_REVIEW_2026-09-06.md`, display name "Visitor chair") into the playable furnishing catalog, mirroring `mobile_whiteboard`. Visitor-chair-v1 is not registered. All four facings are `runtime_ready`. `interaction_kind` is `none`. There is no Sit action, seat anchor, seated pose, reservation, or worker use. The optional contact socket and Mina seated probe stay out of the runtime profile. The profile is decorative. Native canvas is `[96, 144]`, floor pivot `[48, 96]`, sprite offset `[0, -24]`. Layer order is floor_shadow, seat_back, seat_front. `z_offset` values are `-8`, `-6`, and `5`. Occupied cells are `[[0, 0]]` on every facing. Clearance and the standing viewpoint use the geometry tool's interaction cell, which matches the proposal contact cell and is opposite the seated gaze: north `[0, 1]`, east `[-1, 0]`, south `[0, -1]`, west `[1, 0]`. The reference axis (screen_y for north/south, screen_x for east/west) is source context and is not a catalog key. The geometry tool authors the standing envelope `[-24, -72, 48, 80]`, which equals `OfficeLayout.STANDING_SOURCE_BOUNDS`, so that rectangle is used. Visual and hit bounds are the v2 composite opaque bounds minus the floor pivot: north `[-16, -48, 32, 64]`, east `[-18, -48, 36, 64]`, south `[-17, -48, 34, 64]`, west `[-18, -48, 36, 64]`. The `-4x` images are not registered.
- `decor-visitor_chair` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The visitor chair stays in storage until the player places it.
- Runtime layers are byte-exact copies of the visitor-chair-v2 layer and whole PNGs under `game/assets/runtime/office/furnishing-library/visitor_chair/`. Render regions are the full canvas and every layer offset is `[0, -24]`. Layer names are `VisitorChairV2` plus facing plus layer. The dev capture tool lists `decor-visitor_chair` at `[32, 8]` facing south and rotates it with the other native décor. A four-facing cell stayed free while the previous fifteen décor kept their cells, so none of them move. `[32, 8]` is on the east edge, between the pedestal at `[32, 6]` and the planter at `[32, 13]`. South clearance is `[32, 7]`. Clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places the chair at `[23, 17]` after the mobile whiteboard returns to storage.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `visitor_chair` (v2) is now registered as passive décor with no Sit action. From the passive-tables review, `cafe_table` (v2) remains passed but unregistered. The catalogue already uses the kind name `cafe_table` for an older one-cell south prop (`res://assets/runtime/office/cafe-table-south.png`); the passed cafe-table-v2 library is still unregistered. Reviews still pass unregistered `two_seat_sofa` and `lounge_armchair` (`dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`). None of those reviews names a registration order.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 642 checks, 0 failures (includes `visitor_chair` at `[23, 17]` all facings, exact one-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 473 checks, 0 failures
- `test_archive_production.gd` — 3319 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures (low lounge table and round meeting table stay in the ordinary catalogue; the chair is not a table)
- `test_acoustic_divider.gd` — 66 checks, 0 failures
- `test_mobile_whiteboard.gd` — 2353 checks, 0 failures
- `test_passive_furniture.gd` — 1219 checks, 0 failures
- `test_visitor_chair.gd` — 312 checks, 1 failure. The failure is the existing developer-catalogue assertion that `visitor_chair` `production_status` is `native_review_required`. `dev/art-catalogue/furniture.json` has said `approved` since c88ada6, and this round did not edit that file. The same run's checks that `furniture_catalog.json` and `office_layout.json` contain no `visitor_chair` passed.
- `test_visitor_chair_v2.gd` — 105 checks, 0 failures
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (sixteen native décor rotate through all facings; chair at `[32, 8]`; no other décor moved)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The visitor chair is owned starter décor and stays in storage until placed.


- 13:35 PT Oct 19: Merged PR #21 (visitor_chair v2 registered as passive starter décor). Verified harness 72/0, eval:offline 8/8, import, validate, run_all, furnishing projection 642/0, furniture directions 473/0, archive production 3319/0, chapter1, full_player_path, passive tables, acoustic divider, mobile whiteboard, passive furniture, visitor chair v2 105/0, and decor capture green. test_visitor_chair.gd (v1) still has 1 pre-existing failure (dev catalogue production_status now approved).

### Round 20 — 2026-10-19

**What changed**
- Fixed the stale `test_visitor_chair.gd` developer-catalogue assertion. `dev/art-catalogue/furniture.json` records `visitor_chair` `production_status` `approved` (since c88ada6). The test now checks that approval and that the family still has no Sit action, seat anchor, or reservation (`art_library_approval.scope` is `passive_art_library`, `runtime_admission` is false, every variant has `seated_pose_needed` false, and any optional contact socket has `runtime_capability` false). `furniture_catalog.json` and `office_layout.json` still contain no `visitor_chair`. That file was not edited.
- Registered the art-approved `two_seat_sofa` (two-seat-sofa-v3, mean 2.50, "Pass as passive art-library object" in `dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`, display name "Two-seat sofa") into the playable furnishing catalog, mirroring `visitor_chair`. V1 and v2 are not registered. `-4x` images are not registered. All four facings are `runtime_ready`. `interaction_kind` is `none`. There is no Sit action, seat anchor, seated pose, reservation, break behavior, or worker use. Native canvas is `[192, 224]`, floor pivot `[96, 144]`, sprite offset `[0, -32]`. Layer order is floor_shadow, rear_structure, front_structure. `z_offset` values are `-8`, `-6`, and `5`. Occupied cells are the v3 manifest / geometry tool order: north `[[-1, -1], [0, -1], [1, -1], [-1, 0], [0, 0], [1, 0]]`, east `[[0, -1], [1, -1], [0, 0], [1, 0], [0, 1], [1, 1]]`, south `[[-1, 0], [0, 0], [1, 0], [-1, 1], [0, 1], [1, 1]]`, west `[[-1, -1], [0, -1], [-1, 0], [0, 0], [-1, 1], [0, 1]]`. The proposal interaction cell is null and `lounge_seating_geometry.gd` lists `clearance: []`, so clearance is empty and there is no standing viewpoint. Visual and hit bounds are the v3 composite opaque bounds minus the floor pivot: north `[-48, -54, 96, 77]`, east `[-14, -108, 58, 149]`, south `[-48, -60, 96, 101]`, west `[-44, -108, 58, 149]`. The older south-only `lounge_sofa` kind is unchanged.
- `decor-two_seat_sofa` is a starter inventory grant. New companies and existing saves receive it through the same `starter-decor-v1` insert as the other starter décor. It is not auto-placed. The phone booth remains the only first-run lounge placement. The sofa stays in storage until the player places it.
- Runtime layers are byte-exact copies of the two-seat-sofa-v3 layer and whole PNGs under `game/assets/runtime/office/furnishing-library/two_seat_sofa/`. Render regions are the full canvas and every layer offset is `[0, -32]`. Layer names are `TwoSeatSofaV3` plus facing plus layer. The dev capture tool lists `decor-two_seat_sofa` at `[33, 7]` facing south and rotates it with the other native décor. No four-facing 3x2 pocket stayed free while the previous sixteen décor kept their cells, so two one-cell pieces move: the rolling pedestal from `[32, 6]` to `[26, 6]`, and the visitor chair from `[32, 8]` to `[10, 19]`. Occupied union at `[33, 7]` is `[32, 6]` through `[34, 8]`. Clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The projection test places the sofa at `[23, 17]` after the visitor chair returns to storage.
- `test_lounge_seating.gd` now expects `two_seat_sofa` in the ordinary production catalogue as passive décor (`interaction_kind` `none`, no Sit/seat_anchor). `lounge_armchair` stays absent. No-seating checks on the geometry-tool calibration copy are unchanged.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `two_seat_sofa` (v3) is now registered as passive décor with no Sit action. `lounge_armchair` and `cafe_table` (v2) remain passed-but-unregistered. The catalogue already uses the kind name `cafe_table` for an older one-cell south prop (`res://assets/runtime/office/cafe-table-south.png`); the passed cafe-table-v2 library is still unregistered. The older south-only `lounge_sofa` kind is separate from this v3 two-seat sofa.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 673 checks, 0 failures (includes `two_seat_sofa` at `[23, 17]` all facings, exact six-cell footprint, 3 native layers)
- `test_furniture_directions.gd` — 474 checks, 0 failures
- `test_archive_production.gd` — 3320 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (stops at Connect; host credentials ignored)
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures (low lounge table and round meeting table stay in the ordinary catalogue; the sofa is not a table)
- `test_acoustic_divider.gd` — 66 checks, 0 failures
- `test_mobile_whiteboard.gd` — 2443 checks, 0 failures
- `test_passive_furniture.gd` — 1261 checks, 0 failures
- `test_visitor_chair.gd` — 325 checks, 0 failures (stale `native_review_required` assertion updated to `approved` plus no-seating checks)
- `test_visitor_chair_v2.gd` — 105 checks, 0 failures
- `test_lounge_seating.gd` — 322 checks, 0 failures
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures (seventeen native décor rotate through all facings; sofa at `[33, 7]`; pedestal moved to `[26, 6]`; chair moved to `[10, 19]`)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The two-seat sofa is owned starter décor and stays in storage until placed.
- 15:34 PT Oct 19: Merged PR #22 (two_seat_sofa v3 registered as passive starter décor; stale test_visitor_chair.gd assertion fixed). Verified harness 72/0, eval:offline 8/8, import, validate, run_all, furnishing projection 673/0, furniture directions, archive production, chapter1, full_player_path, passive tables, acoustic divider, mobile whiteboard, passive furniture, visitor chair 325/0, visitor chair v2, lounge seating 322/0, and decor capture green.

### Round 21 — 2026-10-19

**What changed**
- Registered the art-approved `lounge_armchair` (lounge-armchair-v3, mean 2.50, "Pass as passive art-library object" in `dev/art-catalogue/LOUNGE_SEATING_REVIEW_2026-09-06.md`, display name "Lounge armchair") into the playable furnishing catalog as passive starter décor, mirroring Round 20's `two_seat_sofa`. V1 and v2 are not registered. All four facings are `runtime_ready`. `interaction_kind` is `none`. There is no Sit action, seat anchor, seated pose, reservation, break behavior, or worker use. Native canvas is `[160, 208]`, floor pivot `[80, 128]`, sprite offset `[0, -24]`. Layer order is floor_shadow, rear_structure, front_structure, with `z_offset` `-8`, `-6`, `5`. Occupied cells follow the v3 manifest / lounge geometry tool: north `[[-1, -1], [0, -1], [-1, 0], [0, 0]]`, east `[[0, -1], [1, -1], [0, 0], [1, 0]]`, south `[[0, 0], [1, 0], [0, 1], [1, 1]]`, west `[[-1, 0], [0, 0], [-1, 1], [0, 1]]`. Clearance is empty (proposal interaction cell is null), so there is no standing viewpoint.
- `decor-lounge_armchair` is a starter inventory grant after `decor-two_seat_sofa`, delivered through the same `starter-decor-v1` insert. It is not auto-placed and stays in storage until the player places it.
- Runtime layers and whole PNGs are byte-exact copies of the v3 files under `game/assets/runtime/office/furnishing-library/lounge_armchair/`; `source_copies` records their sha256.
- Hiring Creative now puts 9 stations plus 24 starter decorations in inventory (33 items), so `contracts/furnishing.schema.json` inventory `maxItems` goes from 32 to 33. The placement cap stays 32.
- Dev capture places `decor-lounge_armchair` at `[33, 17]` facing south (four-facing union `[32, 16]` through `[34, 18]`). No four-facing 2x2 pocket stayed free while the other seventeen décor kept their cells, so six pieces move: coat stand `[32, 19]` to `[19, 19]`, floor lamp `[19, 14]` to `[32, 13]`, planter `[32, 13]` to `[19, 13]`, resource cart `[4, 18]` to `[22, 19]`, printer `[22, 17]` to `[4, 17]`, low coffee table `[20, 19]` to `[6, 19]`. All clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. Capture strings now say eighteen native décor.
- `test_lounge_seating.gd` now expects `lounge_armchair` in the ordinary production catalogue as passive décor (no Sit/seat_anchor); geometry-tool calibration checks are unchanged. `test_furnishing_projection.gd`, `test_archive_production.gd`, and `test_furniture_directions.gd` include the armchair.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `lounge_armchair` (v3) is now registered as passive décor with no Sit action. `cafe_table` (v2) remains passed-but-unregistered because the catalogue already uses `cafe_table` for an older one-cell south prop.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 74 tests, 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 704 checks, 0 failures
- `test_furniture_directions.gd` — 475 checks, 0 failures
- `test_archive_production.gd` — 3321 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 628 checks, 0 failures
- `test_acoustic_divider.gd` — 66 checks, 0 failures
- `test_mobile_whiteboard.gd` — 2423 checks, 0 failures
- `test_passive_furniture.gd` — 1231 checks, 0 failures
- `test_visitor_chair.gd` — 325 checks, 0 failures
- `test_visitor_chair_v2.gd` — 105 checks, 0 failures
- `test_lounge_seating.gd` — 350 checks, 0 failures
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The armchair is owned starter décor and stays in storage until placed.
- 09:07 PT Oct 20: Merged PR #23 (lounge_armchair v3 registered as passive starter décor; inventory cap 33). Verified harness 72/0, eval:offline 8/8, import, validate, run_all, furnishing projection 704/0, furniture directions 475/0, archive production 3321/0, chapter1, full_player_path, passive tables, acoustic divider, mobile whiteboard, passive furniture, visitor chair 325/0, visitor chair v2, lounge seating 350/0, and decor capture green.

### Round 22 — 2026-10-20

**What changed**
- Registered the art-approved cafe-table-v2 ("Pass after support-contact correction", mean 2.83, in `dev/art-catalogue/PASSIVE_TABLES_REVIEW_2026-09-06.md`) into the playable furnishing catalog as passive starter décor under a new kind, `break_table` (display name "Two-person break table", matching GALLERY.md). The older one-cell south-only `cafe_table` prop is untouched. All four facings are `runtime_ready` and `decorative`. `interaction_kind` is `none`. There are no chairs, seats, food, reservation, break behavior, or worker use. Native canvas is `[160, 240]`, floor pivot `[80, 160]`, sprite offset `[0, -40]`. Layer order is floor_shadow, rear_structure, front_structure, with `z_offset` `-2`, `-1`, `1`. Occupied cells follow the v2 manifest / passive table geometry tool: north `[[-1, -1], [0, -1], [-1, 0], [0, 0]]`, east `[[0, -1], [1, -1], [0, 0], [1, 0]]`, south `[[0, 0], [1, 0], [0, 1], [1, 1]]`, west `[[-1, 0], [0, 0], [-1, 1], [0, 1]]`. Clearance is empty (proposal interaction cell is null), so there is no standing viewpoint.
- `decor-break_table` is a starter inventory grant after `decor-lounge_armchair`, delivered through the same `starter-decor-v1` insert. It is not auto-placed and stays in storage until the player places it.
- Runtime layers and whole PNGs are byte-exact copies of the v2 fixtures under `game/assets/runtime/office/furnishing-library/break_table/`; `source_copies` records their sha256.
- Hiring Creative now puts 9 stations plus 25 starter decorations in inventory (34 items), so `contracts/furnishing.schema.json` inventory `maxItems` goes from 33 to 34. The placement cap stays 32.
- Dev capture places `decor-break_table` at `[2, 19]` facing south (four-facing union `[1, 18]` through `[3, 20]`), the only four-facing pocket that stayed free while the other eighteen décor kept their cells, so nothing else moved. Clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. Capture strings now say nineteen native décor.
- `test_passive_tables.gd` now expects `break_table` in the ordinary catalogue as decorative, runtime_ready, with no interaction, service side, work cell, seat anchor, pose set, or action. `test_furnishing_projection.gd`, `test_archive_production.gd`, and `test_furniture_directions.gd` include the break table.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. All passed passive tables and lounge seating are now registered as passive décor with no Sit or use actions.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 74 tests, 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 735 checks, 0 failures
- `test_furniture_directions.gd` — 476 checks, 0 failures
- `test_archive_production.gd` — 3322 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 656 checks, 0 failures
- `test_acoustic_divider.gd` — 66 checks, 0 failures
- `test_mobile_whiteboard.gd` — 2433 checks, 0 failures
- `test_passive_furniture.gd` — 1219 checks, 0 failures
- `test_visitor_chair.gd` — 325 checks, 0 failures
- `test_visitor_chair_v2.gd` — 105 checks, 0 failures
- `test_lounge_seating.gd` — 350 checks, 0 failures
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The break table is owned starter décor and stays in storage until placed.
- 11:11 PT Oct 20: Merged PR #24 (cafe-table-v2 registered as passive break_table starter décor; inventory cap 34). Verified harness 72/0, eval:offline 8/8, import, validate, run_all, furnishing projection 735/0, furniture directions 476/0, archive production 3322/0, chapter1, full_player_path, passive tables 656/0, acoustic divider, mobile whiteboard, passive furniture, visitor chair 325/0, visitor chair v2, lounge seating 350/0, and decor capture green.

### Round 23 — 2026-10-20

**What changed**
- Registered the art-approved compact-desk-v2 ("Mean 2.67 / 3 — pass for reusable base-library art", in `dev/art-catalogue/BASE_FURNITURE_BASE_ONLY_REVIEW_2026-09-06.md`; also `dev/COMPACT_DESK_NATIVE_REVIEW.md`) into the playable furnishing catalog as passive starter décor. Kind `compact_desk`, display name "Compact starter desk" (GALLERY.md / `dev/art-catalogue/furniture.json`). All four facings are `runtime_ready` and `decorative`, with `review` `{art: true, geometry: true}` and `source_review` that 2026-09-06 review. `interaction_kind` is `none`. It is not a workstation: no chair, devices, role tools, seat anchor, work cell, job, worker use, or hiring change. Native canvas is `[160, 192]`, floor pivot `[80, 128]`, sprite offset `[0, -32]`. Layer order is floor_shadow, rear_structure, front_structure, with `z_offset` `-2`, `-1`, `1`. Occupied cells follow the v2 manifest / `compact_desk_geometry.gd`: north `[[-1, 0], [0, 0]]`, east `[[0, -1], [0, 0]]`, south `[[1, 0], [0, 0]]`, west `[[0, 1], [0, 0]]`. Clearance is the manifest front cell: north `[[0, 1]]`, east `[[-1, 0]]`, south `[[0, -1]]`, west `[[1, 0]]`.
- `visual_bounds` and `hit_bounds` have no authored catalogue numbers. They are the opaque union of the three layer content boxes shifted by the pivot (sprite dest position is offset minus region/2, which is `-pivot`): north `[-48, -48, 64, 64]`, east `[-16, -80, 32, 96]`, south `[-16, -48, 64, 64]`, west `[-16, -48, 32, 96]`. That union matches the whole-sprite opaque rect minus the pivot. Hit bounds equal visual bounds. Clearance is non-empty, so each facing keeps one standing viewpoint on the clearance cell with `OfficeLayout.STANDING_SOURCE_BOUNDS` `[-24, -72, 48, 80]`, the same envelope Rounds 20–22 used when clearance exists. Manifest layer names are not facing-qualified, so runtime layer names are `CompactDeskV2{Facing}{FloorShadow|RearStructure|FrontStructure}`, the same pattern as `BreakTableV2` and `VisitorChairV2`. `anchor_offset` is `[0, 0]`.
- `decor-compact_desk` is a starter inventory grant immediately after `decor-break_table`, delivered through the same `starter-decor-v1` insert. It is not auto-placed and stays in storage until the player places it.
- Runtime layers and whole PNGs are byte-exact copies of the v2 fixtures under `game/assets/runtime/office/furnishing-library/compact_desk/` (16 PNGs); `source_copies` records their sha256 (16 entries; catalogue `source_copies` length 392).
- Hiring Creative now puts 9 stations plus 26 starter decorations in inventory (35 items), so `contracts/furnishing.schema.json` inventory `maxItems` goes from 34 to 35. The placement cap stays 32.
- No four-facing cell stayed free while the previous nineteen décor kept their cells, and moving only one- and two-cell décor left the displaced piece without a home. Dev capture therefore moves four pieces and places the desk: `decor-low_bookshelf` `[25, 8]` → `[10, 19]`, `decor-recycling_sorter` `[13, 19]` → `[25, 8]`, `decor-visitor_chair` `[10, 19]` → `[3, 9]` (north clearance `[3, 10]` sits on the circulation aisle), `decor-rolling_storage_pedestal` `[26, 6]` → `[12, 6]` because west-facing recycling art at `[25, 8]` overlaps `[26, 6]`, and `decor-compact_desk` at `[13, 19]` facing south. At `[13, 19]`, north occupies `[12, 19]` and `[13, 19]`; east occupies `[13, 18]` and `[13, 19]` (`[13, 18]` sits between Mina and Creative); south occupies `[13, 19]` and `[14, 19]`; west occupies `[13, 19]` and `[13, 20]`. Clear of Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, and the founder capture cell `[17, 18]`. The furnishing-projection check uses `[23, 17]` only; west there would occupy Theo, so capture does not. Capture strings now say twenty native décor.
- `test_passive_tables.gd` now expects `compact_desk` in the ordinary catalogue as decorative, runtime_ready, with no interaction, service side, work cell, seat anchor, pose set, or action. `test_furnishing_projection.gd`, `test_archive_production.gd`, and `test_furniture_directions.gd` include the compact desk. Production-catalogue absence checks in `test_compact_desk.gd` and `test_base_furniture_review_v2.gd` now expect passive `compact_desk` in `furnishing_catalog.json`. `office_layout.json` and the dev calibration catalogue stay without it.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `compact_desk` (v2) is now registered as passive décor with no Sit or workstation use. `shared-workbench-v2` (mean 2.50 in the same base-only review) stays passed-but-unregistered.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 74 tests, 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 766 checks, 0 failures
- `test_furniture_directions.gd` — 477 checks, 0 failures
- `test_archive_production.gd` — 3323 checks, 0 failures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 684 checks, 0 failures
- `test_acoustic_divider.gd` — 66 checks, 0 failures (one earlier full-suite process missed founder-front by about 20px at the 180-tick cap; two isolated reruns passed; the saved log is a pass; starter décor is not auto-placed in that room)
- `test_mobile_whiteboard.gd` — 2443 checks, 0 failures
- `test_passive_furniture.gd` — 1226 checks, 0 failures
- `test_visitor_chair.gd` — 325 checks, 0 failures
- `test_visitor_chair_v2.gd` — 105 checks, 0 failures
- `test_lounge_seating.gd` — 350 checks, 0 failures
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures, 0 native captures

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The compact desk is owned starter décor and stays in storage until placed.

- PR #25 merged (Round 23, compact-desk-v2 passive decor).

### Round 24 — 2026-10-21

**What changed**
- Registered the art-approved shared-workbench-v2 ("Mean 2.50 / 3 — minimum pass for reusable base-library art", in `dev/art-catalogue/BASE_FURNITURE_BASE_ONLY_REVIEW_2026-09-06.md`) into the playable furnishing catalog as passive starter décor. Kind `shared_workbench`, display name "Two-person workbench" (GALLERY.md / `dev/art-catalogue/furniture.json`). All four facings are `runtime_ready` and `decorative`, with `review` `{art: true, geometry: true}` and `source_review` that 2026-09-06 review. `interaction_kind` is `none`. It is not a workstation: no chair, devices, role tools, seat anchor, work cell, job, worker use, or hiring change. Native canvas is `[256, 304]`, floor pivot `[128, 208]`, sprite offset `[0, -56]` (`shared_workbench_geometry.gd` / the family entry). Layer order is floor_shadow, rear_structure, front_structure, with `z_offset` `-2`, `-1`, `1`. Occupied cells follow the v2 manifest / `shared_workbench_geometry.gd`: north `[[-2, 0], [-1, 0], [0, 0], [1, 0], [2, 0]]`, east `[[0, -2], [0, -1], [0, 0], [0, 1], [0, 2]]`, south `[[2, 0], [1, 0], [0, 0], [-1, 0], [-2, 0]]`, west `[[0, 2], [0, 1], [0, 0], [0, -1], [0, -2]]`. Clearance is the geometry tool's three front cells: north `[[-1, 1], [0, 1], [1, 1]]`, east `[[-1, -1], [-1, 0], [-1, 1]]`, south `[[1, -1], [0, -1], [-1, -1]]`, west `[[1, 1], [1, 0], [1, -1]]`.
- `visual_bounds` and `hit_bounds` have no authored catalogue numbers. They are the opaque union of the three layer content boxes shifted by the pivot (sprite dest position is offset minus region/2, which is `-pivot`), the same derivation Rounds 20–23 used: north `[-77, -54, 155, 70]`, east `[-14, -77, 30, 157]`, south `[-77, -54, 154, 70]`, west `[-14, -77, 28, 157]`. Hit bounds equal visual bounds. Clearance is non-empty, so each facing keeps three standing viewpoints on those clearance cells with `OfficeLayout.STANDING_SOURCE_BOUNDS` `[-24, -72, 48, 80]`. Manifest layer names are not facing-qualified, so runtime layer names are `SharedWorkbenchV2{Facing}{FloorShadow|RearStructure|FrontStructure}`. `anchor_offset` is `[0, 0]`. `ambient_overlays` is `[]`.
- `decor-shared_workbench` is a starter inventory grant immediately after `decor-compact_desk`, delivered through the same `starter-decor-v1` insert. It is not auto-placed and stays in storage until the player places it.
- Runtime layers and whole PNGs are byte-exact copies of the v2 fixtures under `game/assets/runtime/office/furnishing-library/shared_workbench/` (16 PNGs); `source_copies` records their sha256 (16 entries; catalogue `source_copies` length 408). East rear and west rear are the same bytes in the v2 manifest, so they share one sha256.
- Hiring Creative now puts 9 stations plus 27 starter decorations in inventory (36 items), so `contracts/furnishing.schema.json` inventory `maxItems` goes from 35 to 36. The placement cap stays 32.
- Furnishing projection places the workbench from storage at `[24, 6]` for every facing while hire-2 stations stay put and the founder, Mina, and Theo desks face west. North and south occupy `[22, 6]` through `[26, 6]`. East and west occupy `[24, 4]` through `[24, 8]`. That cell does not touch Mina `[11, 18]`, Creative `[14, 18]`, Theo `[23, 18]`, or the founder `[17, 18]`.
- Decor-only capture cannot take the same cell, or any other four-facing cell, without moving a workstation or an actor. Eighteen pivots stay inside artwork, circulation, and standing headroom, clear of those four people, and clear of the hire-2 stations plus `include_future` creative `[14, 8]` and prototype `[29, 18]`: `[24, 6]`, `[24, 7]`, `[21, 14]`, `[22, 14]`, `[23, 14]`, `[24, 14]`, `[21, 15]`, `[22, 15]`, `[23, 15]`, `[24, 15]`, `[21, 16]`, `[22, 16]`, `[24, 16]`, `[3, 17]`, `[4, 17]`, `[21, 17]`, `[3, 18]`, `[4, 18]`. Each one collides with other starter décor. Moving only those colliding pieces left them without a four-facing home, and enumerating every décor layout reachable by sliding one piece through open floor (3024 states) never opened a pivot. `capture_furnishing_runtime.gd` is unchanged, still places twenty décor, and does not place `decor-shared_workbench`.
- `test_passive_tables.gd` now expects `shared_workbench` in the ordinary catalogue as decorative, runtime_ready, with no interaction, service side, work cell, seat anchor, pose set, or action. `test_furnishing_projection.gd`, `test_archive_production.gd`, and `test_furniture_directions.gd` include the workbench. Production-catalogue absence checks in `test_shared_workbench.gd` and `test_base_furniture_review_v2.gd` now expect passive `shared_workbench` in `furnishing_catalog.json`. `office_layout.json`, `furniture_catalog.json`, and `dev/art-catalogue/furniture.json` stay without a production binding.

**Art HOLD**
- No new art was generated or edited. No sitting, outdoor scene, new hire, Chapter 3, founder-seated pose, or unused role kit was added.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only, not bind-approved. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. After the Chapter 2 end screen, ordinary work orders continue. No Chapter 3 content is authored.
6. `shared_workbench` (v2, mean 2.50) is registered as passive décor in the working tree and stays in storage until placed. Decor-only capture still cannot place it on a four-facing cell without moving a workstation or an actor, so the capture scene is still the Round 23 twenty-décor layout.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider not set)
- `cd harness && npm test` — 74 tests, 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_furnishing_projection.gd` — 797 checks, 0 failures
- `test_furniture_directions.gd` — 478 checks, 0 failures
- `test_archive_production.gd` — 3324 checks, 0 failures, 0 captures
- `test_chapter1_first_player.gd` — CHAPTER1 PASS
- `test_full_player_path.gd` — FULLPATH PASS
- `test_passive_tables.gd` — 712 checks, 0 failures
- `test_acoustic_divider.gd` — 66 checks, 0 failures, 0 captures
- `test_mobile_whiteboard.gd` — 2393 checks, 0 failures, 0 actual actor pixel checks
- `test_passive_furniture.gd` — 1249 checks, 0 failures, 0 captures
- `test_visitor_chair.gd` — 325 checks, 0 failures
- `test_visitor_chair_v2.gd` — 105 checks, 0 failures
- `test_lounge_seating.gd` — 350 checks, 0 failures
- `capture_furnishing_runtime.gd --diagnose --decor-only` — 79 checks, 0 failures, 0 native captures (twenty décor; workbench not placed)

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete / more coming. The two-person workbench is owned starter décor and stays in storage until placed.

- PR #26 merged (Round 24, shared-workbench-v2 passive decor).
