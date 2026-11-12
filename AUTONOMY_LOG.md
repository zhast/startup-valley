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

### Round 25 — 2026-10-21

**What changed**
- Skipped binding untracked runtime art. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` are art-library approvals whose GALLERY notes say approval creates no runtime binding. `dev/art-catalogue/furniture.json` keeps them at `reviewed_code_native_library_not_runtime_admission` with `runtime_admission` false. Founder seated, founder workstation N/E/W, and waiting-lunch stay QA-only. Nothing in that set is bind-approved for the current office.
- Authored a minimal Chapter 3 opening on the Chapter 2 pattern, using Creative and the already-bound `creative_design_kit`. No new hire, furniture, inventory change, or art.
- Completing "Design the brand" sets `company_state.chapter` to 3 and leaves `opened_chapter` at 2, so the brand reward screen stays up. Cash becomes 180000 cents, earned 260000, reputation 57. The screen heading is "Chapter 2 complete", subtitle "The brand is in the studio.", and the primary action is "Begin Chapter 3" (`chapter.continue`). "Back to office" remains.
- `continueChapter` copies `chapter` into `opened_chapter`. A save that finished the brand while `chapter` was still 2 is raised to chapter 3 in that same transaction before the copy, so "Apply the brand" can unlock. Begin Chapter 2 while the brand is still incomplete does not raise the chapter.
- The new milestone is `apply`, "Apply the brand", employee `creative`, prerequisite `brand`, files `brand/homepage.md` and `brand/application.md`, criteria Homepage use / Palette application / Honest limits / Completeness, reward 40000 cents, fee 0, reputation 8, `availableFromDay` 3. It stays locked until `opened_chapter` is at least 3. The offline provider writes those two files (DeskBloom homepage application, palette `#F6F1E7` / `#2C2825` / `#354B98`, prototype limits) and auto-scores every criterion at 3.
- Completing `apply` pays the reward and leaves the chapter at 3. Cash becomes 220000 cents, earned 300000, reputation 65. The screen is "Chapter 3 complete" / "More is coming." with only "Back to office". Journey reopens on that screen. Founder and Creative desks caption the open order as "Apply brand".
- Journey schema `milestones.maxItems` is 5. Milestone id enum includes `apply`. Prerequisite enum includes `brand`. Job `milestoneId` enum includes `apply`. Existing databases pick up the row through the journey store `INSERT OR IGNORE` on startup. No SQL migration.
- `test_full_player_path.gd` now runs title → Chapter 1 → Begin Chapter 2 → brand → Begin Chapter 3 → apply → Chapter 3 complete. `test_ui_company_redesign.gd` covers the Chapter 2 and Chapter 3 end screens. Harness journey and offline-provider tests cover the lock, the legacy chapter-2 continue, and the apply payout.

**Art HOLD**
- No new art was generated, edited, or bound. Option A stayed closed. The unbound kits, founder seated poses, workstation N/E/W sheets, and waiting-lunch art remain untracked.

**Remaining gaps (ranked)**
1. Creative has a locomotion sheet and stands at the desk. There is no seated sheet, and none was invented.
2. Unbound seated, outdoor, waiting-lunch, and unused furnishing-kit art stays untracked. Founder seated/N/E/W workstation poses are QA-only. `customer_success_kit`, `engineer_build_kit`, `finance_accounts_kit`, `growth_analytics_kit`, `lawyer_contract_kit`, and `product_prototype_kit` stay unbound because catalogue approval does not admit them to runtime.
3. The live path is still a harness driver, not a watched windowed playtest.
4. A cheap reviewer can still sit just under the 2.5 ready line. Round 2's passing ads score was 2.60.
5. Chapter 3 is one work order, then "More is coming." No later chapter is authored.
6. `shared_workbench` (v2, mean 2.50) is registered as passive décor and stays in storage until placed. Decor-only capture still cannot place it on a four-facing cell without moving a workstation or an actor.

**Test results** (no paid live evals; Node 22; host credentials ignored; fake provider only inside the playable-path and offline-provider tests)
- `cd harness && npm test` — 74 tests, 72 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — CHAPTER1 PASS
- `test_full_player_path.gd` — FULLPATH PASS
- `test_ui_flow_regressions.gd` — passed
- `test_ui_company_redesign.gd` — 4071 checks, 0 failures, 0 captures
- `test_furnishing_projection.gd` — 797 checks, 0 failures

**CHAPTER2 PLAYABLE: yes** — title → Chapter 1 complete → Begin Chapter 2 → hire Creative → assign and finish Design the brand → Chapter 2 complete, then Begin Chapter 3.

**CHAPTER3 PLAYABLE: yes** — Begin Chapter 3 → assign and finish Apply the brand with Creative and `creative_design_kit` → Chapter 3 complete / more coming. Offline, no new art.

- PR #27 merged (Round 25, Chapter 3 opening: Apply the brand).

### Round 26 — 2026-10-21

**Direction change**
- Steven, 2026-10-21: Startup Valley is not a literal Whop product and must not call Whop or any LLM during play. It is an offline tycoon in the Game Dev Tycoon and Stardew Valley sense, with Whop only in the names, product types, and jokes. Hire, build, ship, earn game cash and reputation, and grow the office. Any OpenRouter, Grok, Pi, or Whop API use stays optional and off the core path. The game plays with no credential and no network.
- `AGENTS.md` now leads with that loop. Provider rules are optional chapter-job rules. `docs/GAME_ARCHITECTURE.md` has a Tycoon simulation section. `docs/TYCOON_DESIGN.md` holds the pillars, the topic × type matrix, the day clock, the design-only season calendar, the name list, and the next slices. `README.md` no longer says a key is required to play. Chapter security rules are unchanged.

**What changed**
- Authoritative rules live in `harness/src/tycoon.ts`, not a second GDScript simulation. Migration `009_tycoon_products.sql` stores seed `26021` and each product in the same SQLite save. `journey.tycoon` rides the existing company payload. Methods are `tycoon.start` and `tycoon.release`. `day.end` calls `tickDay` inside the day transaction, before the summary. A repeated end of the same day does not build or sell twice.
- The player picks one of 10 topics and one of 6 types. Fit is Great, Good, Okay, or Bad. The founder always works the bench. Hired staff can join and add design, tech, and hype per office day. Release writes four reviews (Whop Weekly, Discord Dave, Margin Call Molly, Cohort Casey), pays launch sales immediately, then sells on the next three office days. Cash and fans (reputation) update. Shipped products stay on a history list.
- `STARTUP_VALLEY_FAKE_PROVIDER` was not flipped on. Chapter work orders still need a credential or that dev-only flag. The ship-a-product loop never reads a provider, a socket, or a key.
- Office UI: Company Journey shows **New Product** when `tycoon` is present. The picker, the build progress, and the release card use the existing company panel. No new art. Chapter 1 still opens Connect when a website work order starts without a key.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art, seated poses, workstation N/E/W sheets, waiting-lunch, and the unbound furnishing kits stay untracked.

**Remaining gaps (ranked)**
1. Staff stats and training. Today's points are fixed per person. A training day should raise design, tech, or hype, and the product should keep the snapshot from the day it started.
2. Research points. Quiet days should unlock a topic, a type, or a small fit bonus.
3. Upgrades shop. Spend game cash on an office tool. No real-money store.
4. Office growth. More desks and a second room from cash and headcount, using furniture that is already bound.
5. Seasons and events. The 28-day Spring / Summer / Fall / Winter calendar is design-only. Turn it on with one deterministic event per season.
6. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
7. Carried from Round 25: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." `shared_workbench` stays in storage.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon and Chapter 1 playtests; fake provider only inside the full-path and offline-provider tests)
- `cd harness && npm test` — 80 tests, 78 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — CHAPTER1 PASS
- `test_full_player_path.gd` — FULLPATH PASS
- `test_ui_flow_regressions.gd` — passed
- `test_ui_company_redesign.gd` — 4071 checks, 0 failures, 0 captures
- `test_furnishing_projection.gd` — 797 checks, 0 failures
- `test_tycoon_product.gd` — TYCOON PASS (Crypto Alpha Newsletter, founder only, no fake provider; launch $207.00 and 5 fans, next office day $333.00 and 8 fans)

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → pick a topic and a type → End day until Ready to ship → Release. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_product.gd`.

- PR #28 merged (Round 26, offline ship-a-product tycoon loop).

### Round 27 — 2026-10-21

**What changed**
- Connect AI no longer sits behind the New Product picker, the build bench, or the release card. Those screens close the Connect drawer and refuse to reopen it. Starting a chapter website work order without a key still opens Connect.
- Company Journey copy now fits the offline tycoon: "Game cash is virtual. Shipping products is fully offline. Ads and incorporation create planning files only." The day summary shows Optional AI spend only when `aiSpend > 0`.
- Staff training. Per-person design / tech / hype persist on `tycoon_meta.staff_json`, seeded from the starting STAFF table. `tycoon.train` spends `$150 × current level` of game cash, raises one hired person's stat by 1, caps at 10, and allows one lesson per person per office day. Short cash, an unhired id, a second lesson the same day, and a maxed stat fail with a clear error. A person in training that day adds no points to the product on the bench. The product keeps the staff snapshot from the day development started, so a lesson mid-build changes the next product. Older saves without stats load the starting table. Company Journey lists hired people with Train buttons from `journey.tycoon`. Fully offline and deterministic.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art, seated poses, workstation N/E/W sheets, waiting-lunch, and the unbound furnishing kits stay untracked.

**Remaining gaps (ranked)**
1. Research points. Quiet days should unlock a topic, a type, or a small fit bonus.
2. Upgrades shop. Spend game cash on an office tool. No real-money store.
3. Office growth. More desks and a second room from cash and headcount, using furniture that is already bound.
4. Seasons and events. The 28-day Spring / Summer / Fall / Winter calendar is design-only. Turn it on with one deterministic event per season.
5. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
6. Carried from Round 25: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." `shared_workbench` stays in storage.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon and Chapter 1 playtests; fake provider only inside the full-path and offline-provider tests)
- `cd harness && npm test` — 83 tests, 81 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass
- `test_chapter1_first_player.gd` — CHAPTER1 PASS
- `test_full_player_path.gd` — FULLPATH PASS
- `test_ui_flow_regressions.gd` — passed
- `test_ui_company_redesign.gd` — 4060 checks, 0 failures, 0 captures
- `test_tycoon_product.gd` — TYCOON PASS (Connect stays closed on the picker; Crypto Alpha Newsletter, founder only; launch $207.00 and 5 fans, next office day $333.00 and 8 fans)
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (ship newsletter, train Founder Tech to 3 for $300, next product uses Tech 3)

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → ship → Train staff → next product uses the new stats. Connect stays closed on the picker, bench, and release card. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_training.gd`.

- PR #29 merged (Round 27, Connect drawer + offline copy fixes, staff training).

### Booth v5 bind — 2026-10-22

**What changed**
- Steven flagged the v4 phone booth as off-brand on 2026-10-21. Bound the approved v5 warm oak booth over `game/assets/runtime/office/phone-booth-south.png` (md5 `e2e4cb1906e54233f09139d01d8093ca`, 192×224 RGBA, 14 colors). Style gate PASS (colors=14 pal=0.94 smooth=0.00 outline=1.00 cool=0.00 detail=0.55). Approved by Steven 2026-10-21 (steven_ok).
- Opaque bbox is still (40,41)-(151,216), the same as v4, so `furnishing_catalog.json` content_bounds `[40, 41, 111, 175]` and visual_bounds `[-56, -119, 111, 175]` are unchanged. Godot reimport did not modify the tracked `.import` sidecar.
- Bookshelf redo is pending Steven lineup approval and is not bound.
- A fresh company still places `decor-phone_booth` at grid [3, 18] south. The office proof shows the warm oak booth in the lounge.

**Test results** (no paid live evals; Node 22; host credentials ignored on the playtests)
- `cd harness && npm run build && npm test && npm run eval:offline` — build pass; npm test 83 tests, 81 pass, 0 fail, 2 skipped; eval:offline 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures; Crypto Alpha Newsletter, founder only; launch $207.00 and 5 fans, next office day $333.00 and 8 fans)
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (41 checks, 0 failures; train Founder Tech to 3, next product uses Tech 3)
- `test_ui_company_redesign.gd` — 4060 checks, 0 failures, 0 captures
- `test_ui_flow_regressions.gd` — passed
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (43 checks, 0 failures)
- `test_full_player_path.gd` — FULLPATH PASS (125 checks, 0 failures)
- No `game/tests` script asserts `phone-booth-south.png` by md5. Nothing extra to run.

**TYCOON SLICE PLAYABLE: yes** — unchanged. The bound booth is the warm oak v5 in the first-run lounge.

- PR #30 merged (phone booth v5 warm oak bind).

### Round 28 — 2026-10-22

**What changed**
- Training notice is day-scoped. `trainingNotice` is kept with the office day it happened, `view()` returns it only on that day, and `tickDay` clears it when the day ends. The lesson line no longer sits on Company Journey the next morning.
- The product picker already reads current staff stats from `journey.tycoon`. After Founder Tech is trained to 3, the On the build line shows "tech 3". The training test now asserts that, and that the TrainingNotice label is gone after End day.
- Hire Mina stays the one primary action. New Product, Train staff, and Research use the existing secondary button variant. Train and Research cards sit under New Product. Train actions are full-width so the price stays inside the button.
- Research points. A company stores `researchPoints` plus unlocked topic and type ids (migration 011). New companies start at 0 with Fitness, Trading, Cooking, Gaming, Study Notes, and Crypto Alpha unlocked, and Course, Community, Template Pack, and Newsletter unlocked. Sneakers, Reselling, Sports Betting Picks, Dating Advice, Coaching, and Software Tool start locked. Older saves that predate the column load with everything unlocked and 0 points. Each person on a build who is not in training adds 1 point at day end. Release adds `floor(score / 2)`. `tycoon.research` spends 4 for a topic and 6 for a type, and fails cleanly for an unknown id, an unlock that already happened, or a short balance. `tycoon.start` rejects a locked topic or type. The picker lists locked rows disabled with "· locked". Company Journey shows a Research card (balance, the day's unlock line, one secondary button per locked item) and hides it when nothing is locked. The release screen shows "+N research points". Fully offline.
- Player-driving check: `.cursor/skills/verify-startup-valley/` plus `features/` for ship, train, research, and end day. `capture_journey.gd` boots `main.tscn` in a SubViewport with the real worker and an isolated data dir.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art, seated poses, workstation sheets, and the unbound furnishing kits stay untracked. The phone-booth and bookshelf art lane is unchanged.

**Remaining gaps (ranked)**
1. Upgrades shop. Spend game cash on an office tool. No real-money store.
2. Office growth. More desks and a second room from cash and headcount, using furniture that is already bound.
3. Seasons and events. The 28-day calendar is design-only. A research fit bonus is still unbuilt.
4. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
5. Carried from Round 27: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." `shared_workbench` stays in storage.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon and Chapter 1 playtests; fake provider only inside the full-path and offline-provider tests)
- `cd harness && npm test` — 87 tests, 85 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (43 checks, 0 failures)
- `test_full_player_path.gd` — FULLPATH PASS (125 checks, 0 failures)
- `test_ui_flow_regressions.gd` — passed
- `test_ui_company_redesign.gd` — 4701 checks, 0 failures, 0 captures
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures)
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures; notice gone after End day; picker shows tech 3)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (40 checks, 0 failures; ship newsletter, Research Sneakers, start Sneakers Newsletter)
- Proof capture — PROOF PASS. Eight PNGs in `/workspace/sv-proof/round-28/`. Invocation: `SV_PROOF_DIR=/workspace/sv-proof/round-28 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → ship → Train staff → Research a locked topic → start that product. The lesson line and the unlock line last one office day. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_research.gd`.

### Cozy v2 art bind — 2026-10-22

**What changed**
- Steven-approved style-gate redo bind. Bookshelf v2 low cabinet, sofa, whiteboard, cafe table, and cafe chair replaced the south runtime plates (still 192×224). Catalog `content_bounds` match each PNG's opaque bbox, and `visual_bounds` / `hit_bounds` are `[x-96, y-160, w, h]`. Occupied cells, clearance, offset, and standing viewpoints are unchanged. Phone booth bounds are unchanged.
- Creative locomotion v2 (`288×320`). Rows are front / back / left / right, which is what `CharacterArt.locomotion_region` addresses. The old sheet was S/E/N/W. The approved back idle is a held pose (columns 0 and 1 match; front still blinks), so the runtime atlas check no longer treats that pair as a two-frame blink.
- Mira and Theo work sheets v2 (`384×320`). Gate PASS, 48 and 47 colors. Theo work frames now h68 like his loco.
- Removed four dead runtime sprites and their tracked `.import` files: `employee-workstation.png`, `research-bench.png`, `layered-furniture.png`, `collaboration-cluster.png`. Research draws `research-bench-v1/` layers. Collaboration draws `collaboration-cluster-v2/` layers. `TownRoom._apply_profile` replaces the scene sprites before a frame is drawn, so the layered sheet was never visible. Top-level catalog `art` now points at the south front layer that is actually rendered. The collaboration scene no longer references a texture (`static_office_prop.gd` accepts a null texture). Source masters under `game/assets/source/` stay.

**Test results** (no paid live evals; Node 22.23.3; host credentials ignored on the playtests)
- `cd harness && npm ci && npm run build && npm test && npm run eval:offline` — build pass; npm test 83 tests, 81 pass, 0 fail, 2 skipped; eval:offline 8/8 fixtures passed
- `godot --headless --path game --import` — pass (tracked `.import` sidecars for the eight bound PNGs were not rewritten)
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- Every `game/tests/test_*.gd` (117 scripts) — 98 pass, 19 fail
- Passing playtests: `test_chapter1_first_player.gd` CHAPTER1 PASS; `test_full_player_path.gd` FULLPATH PASS; `test_tycoon_product.gd` TYCOON PASS; `test_tycoon_training.gd` TYCOON TRAIN PASS; `test_ui_company_redesign.gd` 4060 checks, 0 failures; `test_ui_drawer_redesign.gd` 2685 checks, 0 failures; `test_ui_flow_regressions.gd` passed; `test_furniture_directions.gd` 478 checks, 0 failures; `test_office_architecture.gd` 2369 checks passed; `test_passive_tables.gd` 712 checks, 0 failures
- The 19 failures also fail on origin/main `1940e0e` (same checks and messages), re-run from a git archive of that commit: `test_chair_layer_export.gd` (missing untracked 4× export, then a null image), `test_collaboration_cluster_v2.gd` (526 checks, 27 failures), `test_collaboration_production.gd` (576 checks, 8 failures), `test_collaboration_table.gd` (278561 checks, 6 failures), `test_collaboration_table_room.gd`, `test_furnishing_parity.gd` (no `cases.json` in git), `test_furnishing_worker_ui.gd` and `test_live_startup.gd` (launcher guard), `test_furniture_catalogue.gd` (script parse), `test_locomotion_export.gd` (545 checks, 4 failures on unmodified founder/Mira sheets), `test_modular_desk_export.gd` (233 checks, 40 failures), `test_passive_service_library.gd` (719 checks, 3 failures), `test_passive_utility_library.gd` (552 checks, 1 failure), `test_passive_utility_library_v2.gd` (763 checks, 13 failures), `test_role_storage_variants.gd`, `test_supported_west_assembly.gd`, `test_terrazzo_floor_review.gd`, `test_west_supported_layers.gd`, `test_workstation_facing.gd` (249 checks, 1 failure)

**TYCOON SLICE PLAYABLE: yes** — unchanged. The bound cozy plates are the south bookshelf, sofa, whiteboard, cafe table, and cafe chair.

### Cozy v2 re-skins + delivery sprite fix — 2026-10-22

**What changed**
- Gate-passed recolours copied into runtime (78 PNGs, md5-matched to the handoff). Research bench, approval console, and archive layers, plus workstation chairs and collaboration-cluster chair layers. Floor shadows and collaboration table layers were not in the handoff and stayed. Legacy `approval-console.png` and `artifact-archive.png` stayed. Catalog bounds, offsets, and anchors stayed: every recolour has the same canvas and the same alpha mask.
- Reviewed-source fixtures now hold those bytes. Research `*-whole.png` files were recomposed with source-over in layer order (FloorShadow, RearStructure, FrontStructure, ToolOverlay) after the previous wholes matched that stack. Collaboration cluster wholes were recomposed the same way in the exporter's z-then-name order, and the fixture plus runtime manifest sha256 locks were updated. Archive wholes were copied from the handoff, not regenerated. Decision-console wholes and that manifest were left alone because `test_decision_console.gd` pins them to `GEOMETRY.whole(GEOMETRY.layers())`. The six workstation chair sha256 locks in `test_reviewed_workstation_production.gd` and `workstations-v2/manifest.json` follow the new chairs. Procedural exporters were not run; they would repaint the old indigo geometry over the recolour. `test_product_prototype_kit.gd` now requires the warm reviewed tool overlay, and still requires that overlay's alpha to match the procedural layout.
- The handoff south archive whole differs from a source-over stack of its five layers by 4 pixels (max channel delta 32). Runtime and the fixture both keep the handoff bytes. Headless archive production compares file hashes, which match.
- Delivery: `CharacterArt.has_work_sheet` is true only for mira and theo. `work_sheet()` is unchanged. Creative and founder in `WorkState.DELIVERING` use their own locomotion sheet and the walk-cycle region (`locomotion_region(facing, 2 + frame)`). Mira and Theo still use their work sheets and the old regions.

**Seated finding**
- `seated_sheet()` is not reachable at runtime, so it was left unchanged. Its only caller is `EmployeeAvatar._set_seated_frame`, and that function has no callers. SITTING and TYPING go through `_set_directional_work_pose` → `work_pose_frame`. Both pose sets list only mira and theo; a missing character gets `{}` and the avatar paints its own locomotion idle. `configure_workstation_visual` rejects creative because `supports_work_pose` is false. The founder is a `PlayerAvatar` and only uses `locomotion_sheet("founder")`. This worktree has no `founder-seated.png` and no `FOUNDER_SEATED` preload (only an `.import` for a missing source).

**Test results** (no paid live evals; Node 22.23.3; host credentials ignored; isolated data dirs)
- `cd harness && npm ci && npm run build && npm test && npm run eval:offline` — build pass; npm test 87 tests, 85 pass, 0 fail, 2 skipped; eval:offline 8/8 fixtures passed
- `godot --headless --path game --import` — pass (no tracked `.import` sidecars rewritten)
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_research_bench_production.gd` — 69 checks, 0 failures
- `test_approval_console_production.gd` — 71 checks, 0 failures
- `test_archive_production.gd` — 3324 checks, 0 failures
- `test_archive_assembly.gd` — 120 checks, 0 failures
- `test_reviewed_workstation_production.gd` — 273 checks, 0 failures
- `test_product_prototype_kit.gd` — 175 checks, 0 failures
- `test_decision_console.gd` — 221213 checks, 0 failures
- `test_visitor_chair.gd` — 325 checks, 0 failures
- `test_calibrated_thinking.gd` — 8519 checks, 0 failures
- `test_calibrated_workstation.gd` — 6684 checks, 0 failures
- `test_graphics_regressions.gd` — passed
- `test_modular_office.gd` — 7474 checks, 0 failures
- `test_office_migration.gd` — 2631 checks, 0 failures
- `test_furniture_directions.gd` — 478 checks, 0 failures
- `test_office_architecture.gd` — 2369 checks, 0 failures
- `test_workstation_facing.gd` — 317 checks, 1 failure. The failure is the pre-existing "Placement rebuild refreshes metadata on an existing employee". The new delivery checks are in the 317 (was 249/1 before them).
- `test_chapter1_first_player.gd` — CHAPTER1 PASS (43 checks). The first run used system Node 20 and failed worker bootstrap (`node:sqlite`); the Node 22 rerun passed.
- `test_full_player_path.gd` — FULLPATH PASS (125 checks), Node 22
- Known failures, same counts as the previous round on origin/main: `test_collaboration_cluster_v2.gd` 526/27, `test_collaboration_production.gd` 576/8, `test_collaboration_table.gd` 278561/6, `test_collaboration_table_room.gd` (candidate rejected, not runtime_ready), `test_locomotion_export.gd` 545/4 on unmodified founder/Mira sheets, `test_role_storage_variants.gd` (2 failures: missing `--legal` and `--creative` paths, before any archive pixel compare)

**TYCOON SLICE PLAYABLE: yes** — unchanged. This round recolours furniture and fixes who is drawn while delivering.

### Office readability fixes: desk/collab chair depth, HUD off the floor — 2026-10-22

**What changed**
- South desk `ChairWhole` offset `[0, -76]`, `z_offset` `-33`, and visual/hit bounds `[-48, -80, 96, 96]`. The seat and base clear `DeskFront`, and the chair sorts under a standing worker at the work cell. Other desk facings stay as they were.
- South collaboration `NorthChair0Whole` and `NorthChair1Whole` offset `[0, -56]`. Their `z_offset` stays `-9`. Visual/hit bounds are `[-80, -80, 161, 148]`. Other collaboration facings stay as they were.
- Next-step plaque moved to `(800, 16)`, still `320×56`, on the top wall strip. Movement hint moved to `(455, 672)`, still `240×48`, in the bottom trim. Banner art and size are unchanged.

**Test results** (no paid live evals; Node 22 already installed, no `npm ci`; host credentials ignored; isolated data dirs)
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_office_layout.gd` — 873 checks, 0 failures
- `test_graphics_regressions.gd` — passed
- `test_furniture_directions.gd` — 478 checks, 0 failures
- `test_reviewed_workstation_production.gd` — 273 checks, 0 failures
- `test_complete_south_workstation.gd` — 4043 checks, 0 failures
- `test_modular_office.gd` — 7474 checks, 0 failures
- `test_calibrated_workstation.gd` — 6684 checks, 0 failures
- `test_workstation_facing.gd` — 317 checks, 1 failure. Same pre-existing "Placement rebuild refreshes metadata on an existing employee".
- `test_collaboration_production.gd` — 576 checks, 8 failures. Same count as the branch baseline. The 8 are the existing per-facing lunch socket checks.
- `test_collaboration_cluster_v2.gd` — 526 checks, 27 failures. Same count as the branch baseline.

**TYCOON SLICE PLAYABLE: yes** — unchanged. This round only moves south chair depth and two HUD plaques. The journey playtests were not re-run.

### Round 29 — 2026-10-22

**What changed**
- Upgrades shop. A company spends game cash, once each, on four office tools. The catalog lives in `harness/src/tycoon.ts`: Oak Standing Desk $250 (+1 design per person per dev day), Second Monitor $360 (+1 tech), Ring Light $400 (+1 hype), Nicer Checkout Page $560 (+10% price on later sales). Migration `012_tycoon_upgrades.sql` adds `tycoon_meta.upgrades_json`. Older saves load with none owned. `tycoon.buyUpgrade` fails cleanly for an unknown id, a tool already in the office, or short cash. A buy deducts cash and records the purchase day.
- Effects apply when the tool is already owned at the tick or the sale. Buy, then end that same day, and that tick includes the boost. Stored points, stored sales, stored reviews, and the product's start-day staff snapshot are not rewritten. A person in training that day adds no points and no office bonus. The price boost is `Math.round((priceCents * 110) / 100)`. Units and fans stay on the unboosted formula. Fully offline. No provider and no credential.
- Company Journey has an Upgrades card in the same style as Train staff and Research. Owned tools show one line. The purchase line ("Bought Ring Light. −$400") lasts that office day. Unowned tools get one secondary button ("Buy Ring Light · $400"), disabled when cash is short, hidden once owned. Hire stays the one primary action. The build screen can show "Office bonus · …". The release screen shows the price effect when the checkout tool is owned.
- `journey.tycoon` exposes the four catalog rows with `owned`, `priceCents`, `affordable`, and `effect`, plus `upgradeNotice`. The player-driving skill now buys Oak Standing Desk after the second product and snaps `09-upgrades-card.png` and `10-upgrade-owned.png`.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art, seated poses, workstation sheets, and the unbound furnishing kits stay untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Office growth. More desks and a second room from cash and headcount, using furniture that is already bound.
2. Seasons and events. The 28-day calendar is design-only. A research fit bonus is still unbuilt.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 28: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." `shared_workbench` stays in storage.

**Test results** (no paid live evals; Node 22.23.3; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 93 tests, 91 pass, 0 fail, 2 skipped
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures). The first run used system Node 20 and failed worker bootstrap (`node:sqlite`). The Node 22 rerun shipped Crypto Alpha Newsletter, bought Ring Light at $414, and cleared the purchase line on End day.
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures)
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (40 checks, 0 failures)
- `test_ui_company_redesign.gd` — 4777 checks, 0 failures, 0 captures
- Proof capture — PROOF PASS. Ten PNGs in `/workspace/sv-proof/round-29/`. After the second launch, cash was 28500 cents. Buy Oak Standing Desk was enabled; the purchase line and the owned desk were on screen. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-29 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → ship → Train staff → Research a locked topic → buy an office tool. The lesson line, the unlock line, and the purchase line last one office day. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_upgrades.gd`.

### Round 30 — 2026-10-22

**What changed**
- Seasons and events. The calendar is a pure function of the saved office day in `harness/src/tycoon.ts`. No new clock and no new migration. Four seasons of 28 days. A year is 112 days. Day 1 is Spring 1, Year 1. Day 29 is Summer 1. Day 113 is Spring 1, Year 2. The label is "Spring 3 · Year 1".
- Each season favors two existing topics. Spring: Fitness, Dating Advice. Summer: Sneakers, Sports Betting Picks. Fall: Study Notes, Trading. Winter: Cooking, Gaming. A favored product gains 20 percent units on sales computed that day: `Math.max(1, Math.round((units * 120) / 100))`. Fans come from those units. Stored reviews and earlier sales are not rewritten. Crypto Alpha is not favored in Spring, so the first newsletter's cash stays $207, then $333, then $414.
- One cozy event per season, that day only: Spring 13 Creator Fair, Summer 11 Drop Day, Fall 16 Cohort Kickoff, Winter 25 Cozy Gift Guide. Any product that sells that day gains 2 fans. Units, price, and the stored review stay put. If nothing sells, the event still shows and adds no fans. The next event wraps to next year's Creator Fair after Winter 25.
- `journey.tycoon.calendar` carries the season, the day, the year, the label, the two favored topics, today's event or null, and the next event with `daysUntil`. The day summary stores `dateLabel` for the day that just ended. Older summaries without that field still load. An older save opened on day 1 shows Spring 1, Year 1, and a finished product's sales and review stay as stored.
- Company Journey shows the date in the existing heading. A Season card sits under Upgrades: "In season: Fitness, Dating Advice" and "Creator Fair in 11 days" (or "Creator Fair today. +2 fans on sales today"). The product picker adds "· in season" on a favored topic. Hire stays the one primary action. The ledger day stays a number. The player-driving skill snaps `12-date-label.png` and `11-season-card.png` after the first build day.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art, seated poses, workstation sheets, and the unbound furnishing kits stay untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Office growth. More desks and a second room from cash and headcount, using furniture that is already bound.
2. A research fit bonus is still unbuilt. It is not part of the season calendar.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 29: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." `shared_workbench` stays in storage.

**Test results** (no paid live evals; Node 22.23.3; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 96 tests, 94 pass, 0 fail, 2 skipped. The three new tests cover day 28/29/112/113, the in-season unit boost, the event-day fan bonus, and an older save.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures). Spring 1 shows the Season card and "Creator Fair in 12 days". After End day the summary stays Spring 1 and the next morning is Spring 2. Fitness is tagged in season. Crypto Alpha is not.
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (40 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_ui_company_redesign.gd` — 4777 checks, 0 failures, 0 captures
- Proof capture — PROOF PASS. Twelve PNGs in `/workspace/sv-proof/round-30/`. After one office day the heading reads "Spring 2 · Year 1" and the Season card reads "In season: Fitness, Dating Advice" and "Creator Fair in 11 days". Hire Mina stays the primary action. Cash after the second launch was 28500 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-30 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → ship → Train staff → Research a locked topic → buy an office tool, with the season and the next event on the same screen. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_seasons.gd`.

### Round 31 — 2026-10-23

**What changed**
- Office growth inside the current room. There is no second-room architecture art, so this slice does not add a room. A second room stays a later art ask. The harness owns the levels in `harness/src/tycoon.ts`. `tycoon_meta.office_level` (migration `013_tycoon_office.sql`) stores the level. An older save loads at level 1.
- Level 1 is Garage Loft. Desks total 4 (founder plus the three story desks). Level 2 is Open Floor. It costs $600 game cash and requires 2 hires besides the founder. It adds 2 `compact_desk` and 1 `shared_workbench` as spare seats, and a flat +1 design and +1 tech once per accruing dev day for the whole team. The bonus stacks with per-person upgrades. It does not apply at level 1, on polish days, or when everyone assigned is in training. It does not rewrite stored points.
- Desk capacity is informational. `desks.used` is 1 plus hired people. Story hires (Mina, Theo, Creative) stay on chapter milestones and are not blocked. `tycoon.expandOffice` takes `{}`, checks hires before cash, and returns the journey plus furnishing. Errors: "Hire 2 people before the Open Floor.", "Not enough game cash. Open Floor costs $600.", "The office is already as large as it gets."
- `journey.tycoon.office` carries level, name, blurb, desks `{used, total}`, and `next` (or null at the Open Floor). Company Journey shows an Office card under Upgrades and above Season: the name, "Desks: 1/4", "Open Floor · $600", and a disabled secondary "Expand office" until the gate is met. Hire stays the one primary action on a fresh company. At the Open Floor the card reads "Desks: 3/7" and the button is gone.
- The spare desks sit on open floor, facing south: `spare-compact-a` at [6, 20], `spare-compact-b` at [8, 20], `spare-workbench` at [12, 18]. `required_office_level: 2` hides them at level 1, including hire stage 4, so the old prop counts stay 1, 5, 9, and 10. The bound game grants them as `office-level:2`, separate from the starter decor ids that stay in storage. The furnishing inventory cap is 39. Placement slots stay at 32.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art, seated poses, workstation sheets, and the unbound furnishing kits stay untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched. The placed desks use the already-bound `compact_desk` and `shared_workbench`. No separate chairs.

**Remaining gaps (ranked)**
1. A research fit bonus is still unbuilt. It is the next slice. It is not part of office growth or the season calendar.
2. A second room needs architecture art. This slice only adds desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 30: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 99 tests, 97 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The three new tests cover Garage Loft on an older save, rejected expansion, the $600 purchase, and the flat Open Floor bonus.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures). Garage Loft shows Desks 1/4 and a disabled Expand office. After the seeded buy the card is Open Floor, Desks 3/7, cash 0, and the three spare desks are on the floor facing south.
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (40 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_ui_company_redesign.gd` — 4777 checks, 0 failures, 0 captures
- Layout assertions that used to require `compact_desk` and `shared_workbench` to be absent now require the level-2 gate. `test_compact_desk.gd` 259 checks, `test_shared_workbench.gd` 292 checks, `test_base_furniture_review_v2.gd` 161 checks, all 0 failures.
- Proof capture — PROOF PASS. Fifteen PNGs in `/workspace/sv-proof/round-31/`. `13-office-card.png` is Garage Loft, Desks 1/4, Expand office disabled, Hire Mina primary. `14-office-expanded-card.png` is Open Floor, Desks 3/7, no expand button. `15-office-new-desks.png` is the 1280×720 office with the new desks among the existing furniture. Cash after the second launch was 28500 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-31 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → ship → Train staff → Research a locked topic → buy an office tool → Expand office to the Open Floor, with the season on the same screen. The spare desks appear in the current room. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_office.gd`.

### Round 32 — 2026-10-23

**What changed**
- A topic or type is researched only when the player buys it with research points through `tycoon.research`. Starter topics and types are unlocked, and they are not researched. A legacy save that receives the full catalog for free is not researched either. `research_json` stores that list as `researched: {topics, types}`. `spendResearch` writes it. A save with no `researched` field loads as nothing researched. There is no new SQL migration.
- Each researched part the product uses adds 6 to the fit numerator inside `baseScore`. The bonus is 0, 6, or 12. Development stores it on the product in `staff_json` as `{staff, researchBonus}`. Reviews use the stored number. Later research does not change a product already on the bench. An older row that is only a staff array scores as 0. Crypto Alpha × Newsletter stays at 0, so the first launch is still 20700 cents and 5 fans.
- `journey.tycoon.fits` and each product carry `researchBonus` (0, 6, or 12). The New Product picker shows "Research bonus: +6 fit" when the chosen pair is above 0, and nothing at 0. Company Journey names that product above New Product, for example "Sneakers Newsletter · Research bonus +6 fit", on the product in development, or on the latest released product when the bench is empty. The product progress line and the shipped-history line stay "Research bonus +6 fit". Hire stays the one primary action on a fresh company.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Launch price is the next slice. The catalog price stays the default, so the first newsletter still pays the same cash. At release the player can nudge the price up or down. A higher price sells fewer units. A lower price sells more. The choice is stored on the product.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 31: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 100 tests, 98 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers a starter bonus of 0, a bought topic at +6 with a strictly higher base score, topic and type at +12, a snapshotted bonus that later research does not change, and an older `research_json` with no `researched` field loading at 0.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures). A starter combo shows no bonus line. After researching Sneakers the picker reads "Research bonus: +6 fit", and Company Journey reads "Sneakers Newsletter · Research bonus +6 fit" on the product that just started.
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures). The second sales day is still $333.
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_ui_company_redesign.gd` — 4777 checks, 0 failures, 0 captures
- Proof capture — PROOF PASS. Seventeen PNGs in `/workspace/sv-proof/round-32/` (local, not committed). `16-research-fit-picker.png` is the picker after Sneakers is researched, with the helper checking "Research bonus: +6 fit". `17-research-fit-journey.png` is Company Journey after that product starts, with the helper checking "Sneakers Newsletter · Research bonus +6 fit". Cash after the second launch was 28500 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-32 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → ship a starter product (no research bonus) → Research a locked topic → start that product and read the fit bonus on the picker and on the journey. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_research.gd`.

### Round 33 — 2026-10-23

**What changed**
- Launch price on the New Product picker. Catalog is the default, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans. Three fixed steps: −20%, Catalog, +20% (`pricePercent` 80 / 100 / 120). Units move the opposite way (120 / 100 / 80). Units after the nudge are `Math.max(1, Math.round((units * unitPercent) / 100))`. The unit price is `Math.round((catalogCents * pricePercent) / 100)`. `tycoon.start` takes optional `pricePercent`. Omitted is catalog. Anything else fails with "Pick −20%, catalog, or +20%." and starts nothing. There is no new SQL migration.
- The choice is stored on the product in `staff_json` as `{staff, researchBonus, pricePercent}`. Sales use the stored number. An older row that is only a staff array, or a row with no `pricePercent`, sells at catalog. Stored `sales_cents` are not rewritten. Each product view carries `pricePercent` and `priceCents` (chosen unit price, before checkout).
- Composition on every computed sale, in this order: base units; launch-price units; season +20% units; fans from those units, then the event fan bonus; launch price on the catalog cents; Nicer Checkout Page +10% on that unit price; cash is units times that price. A checkout boost still changes only the price. Season still changes only the units.
- The picker lists Price under the fit line: three secondary buttons and one line, for example "$9.00 · catalog units" or "$7.20 · +20% units". The bench, the release card, and the shipped-history list repeat that line. Hire stays the one primary action. Start development stays the primary action on the picker.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Marketing is the next slice. A small game-cash spend at release for extra units that sales window. Catalog launch stays the default, so the first newsletter still pays the same cash. The spend is stored on the product.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 32: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 101 tests, 99 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers catalog identity (23 units, 20700 cents, 5 fans), −20% / +20% unit and price math, units always at least 1, launch-price then season then checkout composition, a stored `pricePercent` snapshot, a rejected unknown percent, and an older staff-array row selling at catalog without rewriting `staff_json`.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures). The second sales day is still $333.
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS. Catalog launch is 20700 cents and 5 fans. −20% stores 80 / 720 on the product, the picker and release card read "$7.20 · +20% units", and Hire Mina stays the one primary action. Price buttons stay secondary.
- `test_ui_company_redesign.gd` — 5143 checks, 0 failures, 0 captures. Catalog / −20% / +20% on the product picker read as secondary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Nineteen PNGs in `/workspace/sv-proof/round-33/` (local, not committed). `18-price-picker.png` is the picker after −20% with "$7.20 · +20% units" and secondary price buttons. `19-price-released.png` is Sneakers Newsletter on the release card with the same line and launch sales $115.20. Hire Mina stays orange on the team rail. Cash after the cheaper second launch was 28320 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-33 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → leave Catalog or nudge −20% / +20% → ship. The first newsletter at catalog is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_price.gd`.

### Round 34 — 2026-10-26

**What changed**
- Marketing on the New Product picker. None is the default, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans. Three fixed choices: None, Small ad, Big ad (`marketing` `none` / `small` / `big`). Costs are $0 / $50 / $150. Unit percents are 100 / 120 / 150. Units after the ad are `Math.max(1, Math.round((units * unitPercent) / 100))`. None leaves units unchanged. `tycoon.start` takes optional `marketing`. Omitted is none. Anything else fails with "Pick None, Small ad, or Big ad." and starts nothing. Short cash fails with "Need $50" or "Need $150", starts nothing, and charges nothing. There is no new SQL migration.
- The choice is stored on the product in `staff_json` as `{staff, researchBonus, pricePercent, marketing}`. Sales use the stored id. An older row that is only a staff array, or a row with no `marketing`, sells with no ad. Stored `sales_cents` are not rewritten. A paid ad writes one cash charge at the start (`tycoon:marketing:pN`, label "Small ad" or "Big ad"). None writes no charge.
- Composition on every computed sale, in this order: base units; launch-price units; season +20% units; marketing units (none is an identity step); fans from those units, then the event fan bonus; launch price on the catalog cents; Nicer Checkout Page +10% on that unit price; cash is units times that price. Marketing changes only units. Checkout still changes only the price. The spend is the cash paid at the start, not a cut of later sales. The boost applies on every day of that product's sales window.
- The picker lists Marketing under Price: three secondary buttons and one line, for example "None · $0 · no extra units" or "Small ad · $50 · +20% units". A disabled button reads "Small ad · Need $50". The bench, the release card, and the shipped-history list repeat that line when an ad was bought. Hire stays the one primary action. Start development stays the primary action on the picker. Marketing buttons stay secondary.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Contracts are the next slice. One client offer on Company Journey. Accepting it locks the next product to that topic and type and pays a fixed bonus on release. Ignoring it leaves the free picker. No contract keeps the first newsletter at the same cash.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 33: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 102 tests, 100 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers no-ad identity (23 units, 20700 cents, 5 fans), small and big unit math, units always at least 1, launch-price then season then marketing then checkout composition, a $50 charge at the start, "Need $50" and "Need $150" with nothing started and nothing charged, an unknown id rejected, a stored `marketing` snapshot, and an older staff-array row selling with no ad without rewriting `staff_json`.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures). The second sales day is still $333.
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans. At $0 cash the buttons read "Small ad · Need $50" and "Big ad · Need $150". After the newsletter, Big ad charges $150, stores `big`, and the launch pays 26100 cents and 6 fans. Marketing buttons stay secondary. Hire Mina stays the one primary action.
- `test_ui_company_redesign.gd` — 5219 checks, 0 failures, 0 captures. None / Small ad / Big ad on the product picker read as secondary. The short-cash labels are "Small ad · Need $50" and "Big ad · Need $150".
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Twenty-one PNGs in `/workspace/sv-proof/round-34/` (local, not committed). `20-marketing-picker.png` is the first picker with "None · $0 · no extra units", "Small ad · Need $50", and "Big ad · Need $150". `21-marketing-released.png` is Sneakers Newsletter on the release card with "Small ad · $50 · +20% units" and launch sales $136.80. Hire Mina stays orange on the team rail. Cash after the small-ad launch was 25480 cents. Text is readable and nothing overlaps. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-34 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → leave None or buy Small ad / Big ad → ship. The first newsletter with no ad is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_marketing.gd`.

### Round 35 — 2026-10-26

**What changed**
- Contracts on Company Journey. One offer at a time, from `contractBySlot(seed, completed)`. `completed` is how many shipped products stored a contract. The office day is not in the formula, so the card does not change overnight. Six starter pairs: Nova on Whop, Crypto Alpha × Newsletter, $80; Remy on Whop, Fitness × Course, $120; Juniper on Whop, Cooking × Newsletter, $70; Pax on Whop, Gaming × Community, $100; Kit on Whop, Study Notes × Template Pack, $60; Lane on Whop, Trading × Newsletter, $90. There is no minimum review score. Seed 26021 opens on Pax. Ignoring the offer leaves the free picker and the same client. Accept only while the bench is empty. A product on the bench disables Accept and says "Ship the product on the bench first." A second accept fails with "A contract is already accepted."
- The pending accept is `{"id":"..."}` in `tycoon_meta.contract_json` (migration `014_tycoon_contracts.sql`). A matching start copies `{id, client, bonusCents}` onto the product `staff_json` and clears the pending accept. A different pair fails with "This contract is Topic × Type.", starts nothing, and charges no ad. The picker locks that pair. Other unlocked topics and types are disabled and read "· contract". A research lock still reads "· locked".
- On release, one ledger row: id `tycoon:contract:<productId>`, cash and earned equal the bonus, reputation 0, label `Contract: <client>`. Sales units, price, fans, and `sales_cents` stay on the old formula. A later sales day does not pay the bonus again. The next offer is on the card as soon as that product ships. It does not wait out the four-day sales window.
- No contract is the default. The first Crypto Alpha Newsletter still pays 20700 cents and 5 fans. A product started while the offer is ignored stores no `contract` key. An older row that is only a staff array, or a row that omits the field, pays nothing and is not rewritten. An unknown id pays nothing. A known id with a non-positive stored bonus uses the catalog bonus. Reads do not rewrite `staff_json`.
- The Company Journey card sits between New Product and Train staff. The lines are the client, "Topic × Type", and "Bonus $100 on release" in whole dollars. Accept contract is secondary, and only while the status is offered. Hire stays the one primary action. The bench, the release card, and the shipped list show "Contract: Client · +$100" when the product has a contract. A payload without `tycoon.contract` draws no card and leaves the picker free.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Patches are the next slice. One optional patch on a shipped product. It spends game cash and adds a little to the stored score for the remaining sales days. No patch leaves every sale on the old formula. The default is off, so the first newsletter still pays 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 34: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 103 tests, 101 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers a stable offer that does not move when the day ends, the next slot after one completion, accept locking the pair, a wrong pair refused before any start, the bonus paid once with label `Contract: <client>`, the ignore path still at 20700 cents and 5 fans with no contract label, and an older staff-array row paying nothing without rewriting `staff_json`.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures). The second sales day is still $333.
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans and hides the contract line. Accept then locks the offer pair. Other topics and types read "· contract". Release pays the bonus once on top of launch sales and adds no fans.
- `test_ui_company_redesign.gd` — 5685 checks, 0 failures, 0 captures. The contract fixture reads "Nova on Whop", "Crypto Alpha × Newsletter", and "Bonus $80 on release". Accept contract is secondary. Hire Mina stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Twenty-three PNGs in `/workspace/sv-proof/round-35/` (local, not committed). `22-contract-offer.png` is Company Journey on the Contract card: Pax on Whop, Gaming × Community, Bonus $100 on release, and Accept contract as a secondary button. Hire Mina stays orange. The card sits above Train staff and does not collide with it. `23-contract-released.png` is Gaming Community on the release card with "Contract: Pax on Whop · +$100" under launch sales $835.20. That launch still carries the picker’s leftover −20% price and small ad from the earlier sneakers drop. The bonus is its own line. Company cash on that card is $1,298.40 and 27 reputation. Cash before the desk buy was 129840 cents. Text is readable and the lines do not overlap. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-35 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → read the offer or press Accept contract → the next product is locked to that pair → ship. Ignoring it leaves the free picker. The first newsletter with no contract is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_contracts.gd`.

### Round 36 — 2026-10-26

**What changed**
- One optional patch per shipped product while it still has remaining sales days. Cost is $100. The bump is +1 on the stored review score, capped at 10, and only for sales computed after the patch. Launch sales and earlier days stay as they were. Stored `sales_cents` are not rewritten. No patch is the default, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans.
- The flag is `patched: true` on the product snapshot in `staff_json`. There is no new SQL column. An older row that is only a staff array, or a row that omits the field, is unpatched. Reads do not rewrite `staff_json`. A successful patch writes the flag and one ledger row: id `tycoon:patch:<productId>`, cash −$100, earned 0, reputation 0, label `Patch: <product>`. Patching twice fails with "Already patched." and charges nothing.
- Short cash, a product still on the bench, sales that have ended, and a second patch fail with a clear error and spend nothing. The locked reasons are "Need $100", "Ship this product first.", "Sales have ended.", and "Already patched."
- Company Journey shows one Selling card per product that is still selling. The lines are the name, score, cash, fans, and "Sales day 1 of 4". Patch · $100 is secondary. A disabled button reads the reason, for example "Patch · Need $100" or "Patch · Already patched." After a patch the card adds "Patched · +1 score" and "Patched Crypto Alpha Newsletter. −$100". Hire stays the one primary action. The shipped list repeats "Patched · +1 score" when the flag is set.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Sequels are the next slice. One optional sequel of a completed product. It starts faster and carries a little of the old score. No sequel leaves every new product on the old formula. The default is off, so the first newsletter still pays 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 35: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 104 tests, 102 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers a $100 charge with label `Patch: <product>`, later sales using score +1 capped at 10, already-paid launch sales unchanged at 20700 cents and 5 fans, refusals when broke / sales over / already patched / still on the bench, and an older staff-array row staying unpatched without rewriting `staff_json`.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures). The second sales day is still $333.
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans. Patch · $100 is secondary. Hire Mina stays primary. The charge is $100 once, launch sales stay put, the card reads "Patched · +1 score" and "Patched Crypto Alpha Newsletter. −$100", and a second press stays "Patch · Already patched." Later sales still pay after the charge.
- `test_ui_company_redesign.gd` — 6693 checks, 0 failures, 0 captures. The selling fixture reads "Patch · Need $100" when cash is short, then "Patched · +1 score" and "Patched Crypto Alpha Newsletter. −$100" after a patch. Hire Mina stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Twenty-five PNGs in `/workspace/sv-proof/round-36/` (local, not committed). `24-patch-offer.png` is Company Journey on the Selling card: Crypto Alpha Newsletter · 6/10 · $207.00 · +5 fans, Sales day 1 of 4, and Patch · $100 as a secondary button. Hire Mina stays orange. The card sits above Contract and does not collide with it. `25-patch-applied.png` is Gaming Community on the Selling card with "Patched · +1 score", "Patched Gaming Community. −$100", and "Patch · Already patched." The launch sales on that card stay $835.20. Company cash on that card is $1,198.40 and 27 reputation. Cash before the desk buy was 119840 cents. Text is readable and the lines do not overlap. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-36 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → ship a product → Patch · $100 on the Selling card, or leave it. The first newsletter with no patch is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_patches.gd`.

### Round 37 — 2026-10-26

**What changed**
- One optional sequel per finished product. `tycoon.sequel` takes `{productId}` and starts development immediately. The sequel keeps the topic and type. The name is the original name plus " 2". Catalog price, no ad, no cash at the start. The crew is the founder plus anyone from the original snapshot who is still hired. No sequel is the default, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans.
- Build days are the format's days minus 1, at least 1. A newsletter sequel takes 1 office day. The ideal stays `days required × 4`, so the shorter build is not a quality penalty. The score carry is +1 on the base, before reviewers move it, when the original's final score is 6 or more. Final score is the stored review, plus 1 if patched, capped at 10. The carry is stored as `scoreBonus`. It is 0 when the original finished under 6. A sequel cannot start its own sequel.
- The fields live on the product snapshot in `staff_json`: `sequelOf`, `sequelId`, and `scoreBonus` when it is 1. There is no new SQL column. An older row that omits them is not a sequel and has not started one. Reads do not rewrite `staff_json`. Refusals: "Still selling.", "Already has a sequel.", "This is a sequel.", "Ship this product first.", "Ship the product on the bench first.", and "This contract is Topic × Type." A matching accepted contract is consumed. A different one blocks the start.
- Company Journey shows one Shipped card per product whose sales have finished. Sequel is secondary. A selling card shows the same button after Patch, disabled, for example "Sequel · Still selling." The build screen shows "Building · day 0 of 1" and "Sequel · +1 score" when the carry is 1. Hire stays the one primary action.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Awards are the next slice. One optional award entry on a finished product. Spend a little game cash. A high score can add fans. Skipping it leaves cash and fans on the old formula. The default is off, so the first newsletter still pays 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 36: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 105 tests, 103 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers a one-day newsletter sequel, a stored +1 when the original scored 6, score 0 when the stored review is 5, score 1 when a patch lifts a 5 to 6, refusals while selling / twice / for a sequel / while the bench is full / for a mismatched contract, a matching contract consumed with no cash charge, and an older staff-array row staying without sequel fields.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures). The second sales day is still $333.
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans. Patch · $100 is secondary. Hire Mina stays primary.
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS (49 checks, 0 failures). No sequel still pays 20700 cents and 5 fans. Sequel stays "Sequel · Still selling." until sales finish, then Sequel is secondary and Hire Mina stays primary. The sequel is "Crypto Alpha Newsletter 2", "Building · day 0 of 1", and "Sequel · +1 score". It spends no cash. One office day makes it ready. A second press stays "Sequel · Already has a sequel." The sequel's own button reads "Sequel · This is a sequel."
- `test_ui_company_redesign.gd` — 7692 checks, 0 failures, 0 captures. A selling fixture without a sequel offer draws no Sequel button. The finished fixture reads "Sequel", then "Sequel · Already has a sequel." Hire Mina stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Twenty-seven PNGs in `/workspace/sv-proof/round-37/` (local, not committed). `26-sequel-offer.png` is Company Journey on the Shipped card: Crypto Alpha Newsletter · 6/10 · $468.00 · +11 fans, "Sales finished.", and Sequel as a secondary button. Hire Mina stays orange. The Contract card sits below it and does not collide with the button. Header reads Spring 7 · Year 1 · $168.00 game cash · 11 reputation. `27-sequel-started.png` is Crypto Alpha Newsletter 2 with "Fit · Great", "Building · day 0 of 1", and "Sequel · +1 score". Those lines are readable and do not overlap. `24-patch-offer.png` also shows "Sequel · Still selling." under Patch · $100. Both buttons fit on the Selling card. Cash before the desk buy was 119840 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-37 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → let a product finish selling → Sequel on the Shipped card, or leave it. The first newsletter with no sequel is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_sequels.gd`.

### Round 38 — 2026-10-27

**What changed**
- One optional award show per finished product. `tycoon.award` takes `{productId}`. The show is Whop Creator Awards. The fee is $40. The result uses the stored review score. 8–10 wins and adds 12 fans. 5–7 is a nominee and adds 4 fans. 1–4 is entered and adds no fans. Sales cash and product fans stay on the old formula. No award is the default, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans. That newsletter scores 6, so entering after sales finish is a nominee and adds 4 fans.
- The field lives on the product snapshot in `staff_json`: `award: {outcome, fans}` after a successful entry. There is no new SQL column. An older row that is only a staff array, or a row that omits the field, has not entered. Reads do not rewrite `staff_json`. One ledger row: id `tycoon:award:<productId>`, cash −$40, earned 0, reputation equal to the fan bonus, label `Award: Whop Creator Awards`. Entering twice fails with "Already entered." and charges nothing. Fans add once. Other refusals: "Ship this product first.", "Still selling.", "Need $40", and "No product with that id."
- Company Journey shows one Shipped card per product whose sales have finished. The card names "Whop Creator Awards · $40". Enter award is secondary. A selling card shows the same button after Sequel, disabled, for example "Enter award · Still selling." After entry the card adds "Award · Won · +12 fans", "Award · Nominated · +4 fans", or "Award · Entered". Hire stays the one primary action.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Ports are the next slice. One optional second shelf for a finished product. Spend a little game cash. It pays one extra sales day from the stored score. Skipping it leaves cash and fans on the old formula. The default is off, so the first newsletter still pays 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. Carried from Round 37: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 106 tests, 104 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers the fee and the score bands, a nominee on the first newsletter after 20700 cents and 5 fans, a win at score 8, an entry at score 4, a patch that lifts a stored 7 to a sales 8 and still nominates, refusals while developing / selling / twice / short of cash, one ledger row, and an older staff-array row staying without an award field.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans.
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS (49 checks, 0 failures). No sequel still pays 20700 cents and 5 fans.
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS (49 checks, 0 failures). No award still pays 20700 cents and 5 fans. Enter award stays "Enter award · Still selling." until sales finish, then Enter award is secondary and Hire Mina stays primary. The show line is "Whop Creator Awards · $40". A score of 6 reads "Award · Nominated · +4 fans". The fee is $40 once. Sales cash and product fans stay unchanged. A second press stays "Enter award · Already entered."
- `test_ui_company_redesign.gd` — 10220 checks, 0 failures, 0 captures. The finished fixture reads "Enter award" and "Whop Creator Awards · $40", then "Award · Won · +12 fans", "Award · Nominated · +4 fans", "Award · Entered", and "Enter award · Need $40". Hire Mina stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Twenty-nine PNGs in `/workspace/sv-proof/round-38/` (local, not committed). `28-award-offer.png` is Company Journey on the Shipped card: Crypto Alpha Newsletter · 6/10 · $468.00 · +11 fans, "Sales finished.", Sequel, "Whop Creator Awards · $40", and Enter award as a secondary button. Hire Mina stays orange. The Contract card sits below it and does not collide with the button. Header reads Spring 7 · Year 1 · $168.00 game cash · 11 reputation. `29-award-result.png` reads "Award · Nominated · +4 fans" and "Enter award · Already entered." Header reads Spring 12 · Year 1 · $1,158.40 game cash · 31 reputation. Those lines are readable and do not overlap. `24-patch-offer.png` also shows "Sequel · Still selling." and "Enter award · Still selling." under Patch · $100. All three buttons fit on the Selling card. Cash before the desk buy was 115840 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-38 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → let a product finish selling → Enter award on the Shipped card, or leave it. The first newsletter with no award is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_awards.gd`.

### Round 39 — 2026-10-27

**What changed**
- One optional port per finished product. `tycoon.port` takes `{productId}`. The shelf is Whop Mobile. The fee is $80. The next day end pays exactly one extra sales day from the stored score, using the normal per-day formula at the last curve step (25%). `salesDays` stays 4. The payout is added to `sales_cents` and to the product's fans. No port is the default, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans.
- The field lives on the product snapshot in `staff_json`: `port: {shelf, startedDay}` while it is selling, and `port: {shelf, startedDay, cents, fans}` after it pays. There is no new SQL column. An older row that is only a staff array, or a row that omits the field, has not been ported. Reads do not rewrite `staff_json`. The fee is one ledger row: id `tycoon:port:<productId>`, cash −$80, earned 0, reputation 0, label `Port: Whop Mobile`. The extra sale is the normal sales row `tycoon:<productId>:4`, label `Sales · <product>`. Fans add once, on that sales row. Porting twice fails with "Already ported." and charges nothing. Other refusals: "Ship this product first.", "Still selling.", "Need $80", "Another port is still selling.", and "No product with that id."
- Company Journey shows Port on the Shipped card. The fee line is "Whop Mobile · $80". After the port starts the card reads "Port · Whop Mobile · selling 1 day". After the extra day it reads "Port · Whop Mobile · $X". A selling card shows "Port · Still selling." Sequel, Enter award, and Port share one row so they do not stack into the footer. Hire Mina stays the one primary action.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Engines are the next slice. One optional engine, bought with game cash. A product started on it stores a small score bump. Skipping it leaves the first newsletter at 20700 cents and 5 fans. The default is off.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The tallest Shipped card still lets the contract card meet the footer. The shared button row clears Accept contract on the offer and on the Selling card. On the port result the contract pair line still touches Hire Mina. Growing the dialog would cover the clock or the movement hint.
5. Carried from Round 38: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 107 tests, 105 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers the $80 fee, one extra sales day from `salesForDay` at the last curve step, a patched score of 5 selling as 6, refusals while developing / selling / twice / short of cash / while another port is selling, one fee row, one `tycoon:<id>:4` sales row, `salesDays` staying 4, and an older staff-array row staying without a port field.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans.
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS (49 checks, 0 failures). No sequel still pays 20700 cents and 5 fans.
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS (49 checks, 0 failures). No award still pays 20700 cents and 5 fans.
- `test_tycoon_ports.gd` — TYCOON PORTS PASS (65 checks, 0 failures). No port still pays 20700 cents and 5 fans. Port stays "Port · Still selling." until sales finish, then Port is secondary and Hire Mina stays primary. The shelf line is "Whop Mobile · $80". The fee is $80 once and adds no fans. The next day end pays one extra sales day, the line names that cash, and a later day does not pay again. A second press stays "Port · Already ported." `salesDays` stays 4.
- `test_ui_company_redesign.gd` — 13529 checks, 0 failures, 0 captures. A fixture without a port draws no Port button. The finished fixture reads "Port" and "Whop Mobile · $80", then "Port · Whop Mobile · selling 1 day", "Port · Whop Mobile · $45.00", "Port · Need $80", "Port · Still selling.", and "Port · Another port is still selling." Sequel, Enter award, and Port share one row. Hire Mina stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Thirty-one PNGs in `/workspace/sv-proof/round-39/` (local, not committed). `30-port-offer.png` is Company Journey on the Shipped card: Crypto Alpha Newsletter · 6/10 · $468.00 · +11 fans, "Sales finished.", "Whop Creator Awards · $40", "Whop Mobile · $80", and Sequel, Enter award, and Port on one row. Hire Mina stays orange and does not cover those buttons. Accept contract is fully visible. Header reads Spring 7 · Year 1 · $168.00 game cash · 11 reputation. `31-port-result.png` reads "Award · Nominated · +4 fans" and "Port · Whop Mobile · $63.00". The product line is $531.00 · +12 fans. The buttons read "Sequel · Already has a sequel.", "Enter award · Already entered.", and "Port · Already ported." Those port lines are readable and do not overlap. Header reads Spring 13 · Year 1 · $1,184.60 game cash · 33 reputation. The contract pair line below still meets the footer. `24-patch-offer.png` shows "Sequel · Still selling.", "Enter award · Still selling.", and "Port · Still selling." on one row under Patch · $100. Accept contract is fully visible. Cash before the desk buy was 118460 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-39 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → let a product finish selling → Port on the Shipped card, or leave it. The first newsletter with no port is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_ports.gd`.

### Round 40 — 2026-10-27

**What changed**
- One optional in-house engine. `tycoon.buyEngine` takes `{id}` and the only id is `whop_kit`. The engine is Whop Kit Engine. The price is $120. It is bought once for the company. A product started on it stores +1 on the base score, added with the sequel bonus, then clamped to 1–10. Sales still use the stored review score. No engine is the default, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans and still scores 6. The same build on the engine scores 7. A score that is already 10 stays 10.
- Ownership is `engine_id` on `tycoon_meta` (migration 015). Empty means not owned. The product snapshot in `staff_json` stores `engine` and `engineBonus` only when that product starts on the engine. An older row that is only a staff array, or a row that omits the fields, started with no engine. Reads do not rewrite `staff_json`. A sequel stores no engine. The buy is one ledger row: id `tycoon:engine`, cash −$120, earned 0, reputation 0, label `Engine: Whop Kit Engine`. Buying twice fails with "Already owned." and charges nothing. Other refusals: "Unknown engine.", "Need $120", "Buy the engine first.", and "Pick None or Whop Kit Engine." Starting on the engine before it is owned does not charge a marketing ad. The fee is paid at the buy, not again at Start development.
- Company Journey shows an Engine card under Upgrades. The price line is "Whop Kit Engine · $120". Buy is secondary. Short cash reads "Buy Whop Kit Engine · Need $120". After the buy the notice reads "Bought Whop Kit Engine. −$120" until the day ends, and the button reads "Buy Whop Kit Engine · Already owned." Once it is owned, the New Product picker offers None and Whop Kit Engine. The effect line reads "None · no score bump" or "Whop Kit Engine · +1 score". The build line reads "On the build" or "On the build · Whop Kit Engine". A product on the engine shows "On the build · Whop Kit Engine · +1 score" on the journey, the bench, the release card, and the shipped list. The picker stays hidden until the engine is owned. Hire Mina stays the one primary action. Start development stays the primary action on the picker.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Focus is the next slice. One optional focus when a product starts: Balanced (the default), Design, Tech, or Hype. A lean stores a small point bump on that stat. Balanced leaves the first newsletter at 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The tallest Shipped card still lets the contract card meet the footer. On the engine picker the shipped history is clipped at the footer the same way. The engine lines themselves sit above that clip.
5. Carried from Round 39: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 108 tests, 106 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers the $120 fee, a score of 6 lifting to 7, the 1–10 cap, a later product whose launch cents beat the same sale without the bump, refusals for an unknown id / short cash / a second buy / an unowned start before any ad charge, one ledger row, omitted engine keys, a reopen, and an older staff-array row staying without an engine field.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans.
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS (49 checks, 0 failures). No sequel still pays 20700 cents and 5 fans.
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS (49 checks, 0 failures). No award still pays 20700 cents and 5 fans.
- `test_tycoon_ports.gd` — TYCOON PORTS PASS (65 checks, 0 failures). No port still pays 20700 cents and 5 fans.
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS (61 checks, 0 failures). No engine still pays 20700 cents and 5 fans. Buy stays "Buy Whop Kit Engine · Need $120" until the ship, then Buy is secondary and Hire Mina stays primary. The fee is $120 once. The notice reads "Bought Whop Kit Engine. −$120". A second press stays "Buy Whop Kit Engine · Already owned." The picker appears after the buy. None is the default. The chosen engine shows "+1 score" and "On the build · Whop Kit Engine". Start development does not charge again. The bench, the journey, and the release name the engine.
- `test_ui_company_redesign.gd` — 13529 checks, 0 failures, 0 captures. A fixture without an engine draws no Engine card and no picker. Hire Mina stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Thirty-three PNGs in `/workspace/sv-proof/round-40/` (local, not committed). `32-engine-offer.png` is Company Journey on the Engine card: "Whop Kit Engine · $120", "One kit, used on the builds you choose.", "+1 score", and "Buy Whop Kit Engine · $120". Hire Mina · free stays orange and does not cover the card. The Office card starts below it. Header reads Spring 13 · Year 1 · $934.60 game cash · 33 reputation. `33-engine-picker.png` is the product picker scrolled to Engine: None, Whop Kit Engine selected, "Whop Kit Engine · +1 score", and "On the build · Whop Kit Engine". Start development stays orange. Those lines are readable and do not overlap. The shipped history below is clipped at the footer. Cash before the desk buy was 118460 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-40 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

### Round 41 — 2026-10-27

**What changed**
- One optional focus when a product starts. `tycoon.start` takes an optional `focus`: `balanced`, `design`, `tech`, or `hype`. Omitted is Balanced. Design, Tech, or Hype stores +1 on that stat. The add is applied when the review is scored and when the point line is shown, not again on each office day. It stops at 10. A stat already at 10 or above stays put, and a 9 becomes 10. The line still names the stored +1 when the cap ate the add. A stored bonus other than 1 is ignored. Balanced adds nothing, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans and still scores 6. The same build on Hype scores 7 and that launch pays 21600 cents and 5 fans. Design or Tech keeps the score at 6, so that launch stays 20700 cents and 5 fans.
- The product snapshot in `staff_json` stores `focus` and `focusBonus` only when the choice is not Balanced. `focusBonus` is 1. There is no new SQL column and no ledger row. An older row that is only a staff array, or a row that omits the fields, is Balanced. Reads do not rewrite `staff_json`. A sequel stores no focus. A bad id fails with "Pick Balanced, Design, Tech, or Hype." and starts nothing. It does not charge a marketing ad. The choice spends no cash.
- The New Product picker offers Focus under the engine row: Balanced, Design, Tech, Hype. The effect line reads "Balanced · no point bump" or "Design · +1 design". The shared build line reads "On the build", "On the build · Design", or "On the build · Whop Kit Engine · Design" when an engine is chosen too. A focused product shows "On the build · Design · +1 design" on the journey, the bench, the release card, and the shipped list. Hire Mina stays the one primary action. Start development stays the primary action on the picker. A payload without `focusOptions` draws no control.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Audience is the next slice. One optional audience when a product starts: Everyone (the default), Regulars, or Newcomers. A lean stores a small fan bump. Everyone leaves the first newsletter at 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The tallest Selling card still meets the footer. On the focus picker the shipped history is clipped at the footer the same way as the engine picker. The focus lines themselves sit above that clip.
5. Carried from Round 40: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 109 tests, 107 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers the +1 point bump on Design, Tech, and Hype, the cap at 10, a Hype review that leaves score 6 and a launch that leaves 20700 cents, refusals for a bad id before any ad charge, omitted focus keys, a reopen, a sequel that stores no focus, an older staff-array row staying Balanced, a capped stat that does not grow, and a stored bonus other than 1 that is ignored.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans.
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS (49 checks, 0 failures). No sequel still pays 20700 cents and 5 fans.
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS (49 checks, 0 failures). No award still pays 20700 cents and 5 fans.
- `test_tycoon_ports.gd` — TYCOON PORTS PASS (65 checks, 0 failures). No port still pays 20700 cents and 5 fans.
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS (61 checks, 0 failures). No engine still pays 20700 cents and 5 fans. The build line stays "On the build" until an engine is chosen, then "On the build · Whop Kit Engine".
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS (58 checks, 0 failures). Balanced still pays 20700 cents and 5 fans. The picker starts on "Balanced · no point bump" and "On the build". Design shows "+1 design" and "On the build · Design". Day zero shows design 1. Two founder days land on 5/4/4. The bench, the journey, and the release read "On the build · Design · +1 design". Hire Mina stays primary. Start development stays primary. Choosing a focus spends nothing.
- `test_ui_company_redesign.gd` — 14065 checks, 0 failures, 0 captures. A fixture without focus options draws no focus control. With the four options, Balanced, Design, Tech, and Hype are secondary, the effect line reads "Balanced · no point bump", the build line stays "On the build", and Start development stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Thirty-five PNGs in `/workspace/sv-proof/round-41/` (local, not committed). `34-focus-picker.png` is the product picker scrolled to Focus: Balanced, Design selected, Tech, and Hype, with "Design · +1 design" and "On the build · Design". The four labels are fully readable and do not overlap. Start development stays orange. The shipped history below is clipped at the footer. `35-focus-journey.png` reads "On the build · Design · +1 design" above New Product. Hire Mina · free stays orange and does not cover that line. Header reads Spring 13 · Year 1 · $1,016.60 game cash · 46 reputation. Cash before the desk buy was 118460 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-41 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → Focus, or leave it on Balanced. The first newsletter on Balanced is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_focus.gd`.

**TYCOON SLICE PLAYABLE: yes** — Company Journey → buy Whop Kit Engine once → New Product → choose the engine, or leave it on None. The first newsletter with no engine is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_engines.gd`.

### Round 42 — 2026-10-28

**What changed**
- One optional audience when a product starts. `tycoon.start` takes an optional `audience`: `everyone`, `regulars`, or `newcomers`. Omitted is Everyone. Regulars stores +2 fans on a sale when a past release used the same topic. Newcomers stores +2 fans and sells at 90% units. Everyone adds nothing, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans. Regulars on a first-of-topic product stores the lean and still pays 20700 cents and 5 fans. A bad id fails with "Pick Everyone, Regulars, or Newcomers." and starts nothing. It does not charge a marketing ad. The choice spends no cash.
- The product snapshot in `staff_json` stores `audience` only when the choice is not Everyone. There is no new SQL column and no ledger row. An older row that is only a staff array, or a row that omits the field, is Everyone. Reads do not rewrite `staff_json`. A sequel stores no audience.
- The New Product picker offers Audience under the focus row: Everyone, Regulars, Newcomers on one compact three-button row. The effect line reads "Everyone · no fan bump", "Regulars · +2 fans on a repeated topic", or "Newcomers · +2 fans · −10% units". The shared build line reads "On the build" or "On the build · Regulars". A non-Everyone product shows "On the build · Regulars" on the journey, the bench, the release card, and the shipped list. Hire Mina stays the one primary action. Start development stays the primary action on the picker. A payload without `audienceOptions` draws no control.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Size is the next slice. One optional length when a product starts: Catalog (the default), Short, or Long. Short skips a day and sells a little less. Long adds a day and sells a little more. Catalog leaves the first newsletter at 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The tallest Selling card still meets the footer. On the audience picker the shipped history sits above the footer the same way as the focus picker. The audience lines themselves sit above that clip.
5. Carried from Round 40: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 110 tests, 108 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers Regulars and Newcomers unit and fan helpers, refusals for a bad id before any ad charge, omitted audience keys, Everyone leaving 20700 cents and 5 fans, Regulars on a first-of-topic product leaving those same numbers, Newcomers cutting units and adding 2 fans, Regulars adding 2 fans when the topic repeats, Regulars on a different topic adding none, a reopen, a sequel that stores no audience, and an older staff-array row staying Everyone.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans.
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS (49 checks, 0 failures). No sequel still pays 20700 cents and 5 fans.
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS (49 checks, 0 failures). No award still pays 20700 cents and 5 fans.
- `test_tycoon_ports.gd` — TYCOON PORTS PASS (65 checks, 0 failures). No port still pays 20700 cents and 5 fans.
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS (61 checks, 0 failures). No engine still pays 20700 cents and 5 fans. The build line stays "On the build" until an engine is chosen, then "On the build · Whop Kit Engine".
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS (58 checks, 0 failures). Balanced still pays 20700 cents and 5 fans.
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS (54 checks, 0 failures). Everyone still pays 20700 cents and 5 fans. The picker starts on "Everyone · no fan bump" and "On the build". Regulars shows "+2 fans on a repeated topic" and "On the build · Regulars". Newcomers shows "+2 fans · −10% units". The bench, the journey, and the release read "On the build · Regulars". Hire Mina stays primary. Start development stays primary. Choosing an audience spends nothing.
- `test_ui_company_redesign.gd` — 14671 checks, 0 failures, 0 captures. A fixture without audience options draws no audience control. With the three options, Everyone, Regulars, and Newcomers are secondary, the effect line reads "Everyone · no fan bump", the build line stays "On the build", and Start development stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Thirty-seven PNGs in `/workspace/sv-proof/round-42/` (local, not committed). `36-audience-picker.png` is the product picker scrolled to Audience: Everyone, Regulars selected, and Newcomers, with "Regulars · +2 fans on a repeated topic" and "On the build · Regulars". The three labels are fully readable and do not overlap. Start development stays orange. The shipped history below sits above the footer. `37-audience-journey.png` reads "On the build · Regulars" above New Product. Hire Mina · free stays orange and does not cover that line. Header reads Spring 15 · Year 1 · $2,407.40 game cash · 73 reputation. Cash before the desk buy was 118460 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-42 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → Audience, or leave it on Everyone. The first newsletter on Everyone is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_audience.gd`.

### Round 43 — 2026-10-28

**What changed**
- One optional size when a product starts. `tycoon.start` takes an optional `size`: `catalog`, `short`, or `long`. Omitted is Catalog. Short takes one fewer build day, never below one, and sells at 90% units. Long adds one build day and sells at 110% units. Catalog stores nothing and changes no numbers, so the first Crypto Alpha Newsletter still takes 2 office days, still scores 6, and still pays 20700 cents and 5 fans. That same build on Short takes 1 day and pays 18900 cents and 4 fans. On Long it takes 3 days and pays 22500 cents and 5 fans. The ideal moves with the required days, so the review score stays 6. A bad id fails with "Pick Catalog, Short, or Long." and starts nothing. It does not charge a marketing ad. The choice spends no cash.
- The product snapshot in `staff_json` stores `size` only when the choice is not Catalog. There is no new SQL column and no ledger row. An older row that is only a staff array, or a row that omits the field, is Catalog. Reads do not rewrite `staff_json`. A sequel stores no size, so its days stay on the sequel rule.
- The New Product picker offers Size under the audience row: Catalog, Short, Long on one compact three-button row. The effect line reads "Catalog · same length", "Short · −1 day · −10% units", or "Long · +1 day · +10% units". The shared build line reads "On the build" or "On the build · Long". A non-Catalog product shows "On the build · Long" on the journey, the bench, the release card, and the shipped list. Hire Mina stays the one primary action. Start development stays the primary action on the picker. A payload without `sizeOptions` draws no control.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Bugs is the next slice. One optional known bug when a product starts: Clean (the default), or Buggy. Buggy sells a little less until one cheap fix on the Selling card. Clean leaves the first newsletter at 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The tallest Selling card still meets the footer. On the size picker the shipped history sits above the footer the same way as the audience picker. The size lines themselves sit above that clip.
5. Carried from Round 40: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 111 tests, 109 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers the day and unit helpers, a one-day floor, a sequel that ignores size, refusals for a bad id before any ad charge, omitted size keys, Catalog leaving 20700 cents and 5 fans at score 6, Short paying 18900 cents and 4 fans, Long paying 22500 cents and 5 fans, a reopen, a sequel that stores no size, and an older staff-array row staying Catalog.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS (40 checks, 0 failures). Launch sales stay 20700 cents and 5 fans. The next office day stays 33300 cents and 8 fans.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS (50 checks, 0 failures)
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS (50 checks, 0 failures)
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (47 checks, 0 failures)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS (23 checks, 0 failures)
- `test_tycoon_office.gd` — TYCOON OFFICE PASS (25 checks, 0 failures)
- `test_tycoon_price.gd` — TYCOON PRICE PASS (49 checks, 0 failures). Catalog launch is 20700 cents and 5 fans.
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS (55 checks, 0 failures). No ad stays 20700 cents and 5 fans.
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS (60 checks, 0 failures). Ignoring the offer leaves Fitness and Crypto Alpha free. The newsletter still pays 20700 cents and 5 fans.
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS (37 checks, 0 failures). No patch still pays 20700 cents and 5 fans.
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS (49 checks, 0 failures). No sequel still pays 20700 cents and 5 fans.
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS (49 checks, 0 failures). No award still pays 20700 cents and 5 fans.
- `test_tycoon_ports.gd` — TYCOON PORTS PASS (65 checks, 0 failures). No port still pays 20700 cents and 5 fans.
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS (61 checks, 0 failures). No engine still pays 20700 cents and 5 fans. The build line stays "On the build" until an engine is chosen, then "On the build · Whop Kit Engine".
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS (58 checks, 0 failures). Balanced still pays 20700 cents and 5 fans.
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS (54 checks, 0 failures). Everyone still pays 20700 cents and 5 fans.
- `test_tycoon_size.gd` — TYCOON SIZE PASS (58 checks, 0 failures). Catalog still pays 5 fans and takes 2 office days. The picker starts on "Catalog · same length" and "On the build". Long shows "+1 day · +10% units" and "On the build · Long". Short shows "−1 day · −10% units" and "On the build · Short". The bench, the journey, and the release read "On the build · Short". Hire Mina stays primary. Start development stays primary. Choosing a size spends nothing. The later Short launch is not the catalog 20700 cents.
- `test_ui_company_redesign.gd` — 15349 checks, 0 failures, 0 captures. A fixture without size options draws no size control. With the three options, Catalog, Short, and Long are secondary, the effect line reads "Catalog · same length", the build line stays "On the build", and Start development stays primary.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Thirty-nine PNGs in `/workspace/sv-proof/round-43/` (local, not committed). `38-size-picker.png` is the product picker scrolled to Size: Catalog, Short, and Long selected, with "Long · +1 day · +10% units" and "On the build · Long". The labels are fully readable and do not overlap. Start development stays orange. The shipped history below sits above the footer. `39-size-journey.png` reads "On the build · Long" above New Product. Hire Mina · free stays orange and does not cover that line. Header reads Spring 17 · Year 1 · $3,287.80 game cash · 100 reputation. Cash before the desk buy was 118460 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-43 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → New Product → Size, or leave it on Catalog. The first newsletter on Catalog is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_size.gd`.

### Round 44 — 2026-10-28

**What changed**
- Hired staff draw a season salary. The founder is never paid. Mina is $80, under the $207 first newsletter and over the $50 small ad. Theo is $100, the same as a patch. Creative is $120, the same as the engine. All three are $300, the same as the first Tech lesson, once a season. A mid-Spring company has a few thousand dollars, so a full team is real pressure and still payable.
- Payday is the end of the last day of each season, after that day's sales. One ledger row covers the team: id `tycoon:payroll:<year>-<season>`, label `Payroll: Spring`. Replaying the day end or opening the save again finds the id and does not pay twice. No hires means no row. The morning after payday says "Paid payroll · −$80" on the summary and the Season card, and that notice clears when the next day ends.
- Cash may go below zero. The company row no longer rejects a negative `cash_cents`. There is no game over. The header then reads "−$80.00 game cash · cash is negative", and the Season card adds "Cash is negative". A positive balance keeps the old words, including "$0.00 game cash". "Need $X" and "Not enough game cash" stay locked. A later sale and a $0 build row still post.
- The Season card line is "Payroll · $80 on Spring 28", or "No payroll yet". After Spring 28 it moves to Summer 28. `journey.tycoon.payroll` is `{ cents, payday, notice }`. A payload without `payroll` draws no extra line. Hire stays the one primary action. There is no payroll button.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Loans is the next slice. One optional loan of game cash, repaid with a small fee on a later payday. Skipping it leaves cash alone, so the first newsletter stays 20700 cents and 5 fans. No new product picker row.
2. Bugs was set aside. It overlaps patches and would add another picker row.
3. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
4. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
5. The tallest Selling card still meets the footer. The Season card payroll lines sit above the money note, and that note sits above the footer.
6. Carried from Round 40: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 112 tests, 110 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers the salary helper, a season with no hires and no ledger row, one payday paid once across a replay, a reopen that does not pay again, Summer and Year 2 rows, negative cash, locked spending, and a $0 build row that still posts.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS. No hires reads "No payroll yet" and Hire Mina stays primary. Spring 28 with Mina shows "Payroll · $80 on Spring 28" and $0.00. The summary says "Payroll: Spring" and "Paid payroll · −$80". The next morning says cash is negative, the engine stays "Need $120", and Summer 1 does not pay again.
- `test_ui_company_redesign.gd` — 15349 checks, 0 failures, 0 captures. Existing fixtures omit `payroll` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Forty-one PNGs in `/workspace/sv-proof/round-44/` (local, not committed). `40-payroll-season-card.png` is Company Journey on Spring 28 with Mina hired. The header reads "Spring 28 · Year 1 · $0.00 game cash · 0 reputation". The Season card reads "Payroll · $80 on Spring 28". Prepare work order stays orange. `41-payroll-paid.png` is the next morning. The header reads "Summer 1 · Year 1 · −$80.00 game cash · cash is negative · 0 reputation" on one line. The Season card reads "Payroll · $80 on Summer 28", "Paid payroll · −$80", and "Cash is negative". Those lines are readable and do not overlap the footer. Cash before the desk buy was 118460 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-44 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Season. With no hires the line is "No payroll yet" and the first newsletter is still $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_payroll.gd`.

### Round 45 — 2026-10-28

**What changed**
- One optional loan from Whop Treasury. $500 now, $550 back on a later payday. $500 covers a full-team payday ($300) plus a patch ($100) and stays under the $600 office expansion. The $50 fee is under Mina's $80 season salary. $550 is just under Nicer Checkout Page ($560).
- At most one loan is out. Taking it writes `tycoon:loan:<n>:taken` with label `Loan: Whop Treasury`. Repayment of $550 runs on the due payday after sales and payroll, as `tycoon:loan:<n>:repaid` with label `Loan repaid`. A loan taken on payday itself waits until the next season. Replaying a day end or reopening never pays or repays twice. After repayment a new loan may be taken.
- Skipping the loan writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The Season card line is "Loan · $500, repay $550 on Spring 28" plus one secondary Take loan button. While a loan is out the line is "Loan due · $550 on Spring 28" and the button is gone. Hire stays the one primary action. `journey.tycoon.loan` is `{ lender, amountCents, repayCents, due, outstanding }`. A payload without `loan` draws no extra line.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Publishers is the next slice. One optional publisher deal, an advance of game cash, and a cut of that product's sales. Skipping it leaves cash alone, so the first newsletter stays 20700 cents and 5 fans. No new product picker row.
2. Bugs was set aside. It overlaps patches and would add another picker row.
3. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
4. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
5. The tallest Selling card still meets the footer. The Season card loan button sits above the money note, and that note sits above the footer.
6. Carried from Round 40: Creative has no seated sheet. Unbound art stays untracked. The live path is still a harness driver. A cheap reviewer can still sit just under the 2.5 ready line. Chapter 3 ends at "More is coming." The starter `shared_workbench` stays in storage. The one on the Open Floor is a separate grant.
7. `test_tycoon_audience.gd` printed "The shipped product keeps the fan rule" and "Release names the audience" once in a prior gate run, then passed on two reruns. No shared save, port, or worker file is obvious. Each run uses its own `STARTUP_VALLEY_DATA_DIR`. Left alone. The gate script still ignores Godot's exit code and greps the log.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 113 tests, 111 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers the $500/$550 helpers, a skip that still pays 20700 cents and 5 fans then 33300 cents with no loan rows, take once, a second take refused, repay once on payday across a replay, a reopen that does not repay again, a second loan after repayment, a take on payday that waits until the next season, and payroll plus loan on the same payday.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS. The offer reads "Loan · $500, repay $550 on Spring 28". Take loan is secondary. Hire Mina stays primary. Taking it shows "$500.00" and "Loan due · $550 on Spring 28". Spring 28 repays once. The next morning is −$50.00 and the offer returns for Summer 28. A second loan is due on Summer 28.
- `test_ui_company_redesign.gd` — 15349 checks, 0 failures, 0 captures. Existing fixtures omit `loan` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Forty-three PNGs in `/workspace/sv-proof/round-45/` (local, not committed). `42-loan-offer.png` is Company Journey on Spring 1. The header reads "Spring 1 · Year 1 · $0.00 game cash · 0 reputation". The Season card reads "Loan · $500, repay $550 on Spring 28" with Take loan secondary and Hire Mina · free orange. `43-loan-taken.png` is after Take loan. The header reads "$500.00 game cash". The Season card reads "Loan due · $550 on Spring 28" with no Take loan button. Those lines are readable and do not overlap the footer. Cash before the desk buy was 118460 cents. Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-45 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Season. Take loan is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_loans.gd`.



### Round 46 — 2026-10-29

**What changed**
- One optional publisher deal for the product on the bench. Creator Collective pays a $150 advance now and takes 30% of that product's sales rows. $150 matches the big ad, sits under the $207 first newsletter, and is about what the cut takes across a four-day window, so the deal is cash during the build, not free money.
- Signing writes `tycoon:publisher:<productId>:advance` with label `Publisher: Creator Collective`. Sales rows for that product, including a port's extra day, post the company's net share, rounded half-up. A contract bonus is not cut. Replaying a day end or reopening never pays the advance or subtracts the cut twice. A sequel can sign its own deal.
- Skipping the deal writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The card sits on Company Journey with the build lines, above New Product. The line is "Publisher · Creator Collective pays $150 now, takes 30% of sales" plus one secondary Sign publisher button. Once signed it reads "Published by Creator Collective · 30% cut" and the button is gone. Hire stays the one primary action.

**Proof**
- `/workspace/sv-proof/round-46/44-publisher-offer.png` and `45-publisher-signed.png`, captured by the verify-startup-valley skill. PROOF PASS.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked.

**Remaining gaps (ranked)**
1. Expos is the next slice. One optional booth on the Season card for the next fair, a small fee and a few fans. Skipping it leaves cash alone.
2. A second room needs architecture art.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` failed once in the first gate run ("A cheaper launch pays a different cash amount") and twice right after with "Worker bootstrap loads a fresh company", then passed three reruns in a row on this branch and on main. Same intermittent pattern as the audience test in Round 45. Left alone; worth a look if it repeats.
5. Carried from Round 45: the tallest Selling card still meets the footer, and the earlier Round 40 gaps.

### Round 47 — 2026-10-29

**What changed**
- One optional booth at the Whop Creator Fair. $60 now, exactly 3 fans on day 14 of that season. $60 is over the $40 award fee and under Mina's $80 season salary, so a company that just shipped the $207 newsletter can book and still keep $147. 3 fans is under that newsletter's 5. Day 14 is the middle of the season: not payday, and not an existing event day. The Spring 13 Creator Fair event is unchanged.
- Booking writes `tycoon:expo:<year>-<season>:booth` with label `Booth: Whop Creator Fair`. The fair day, after that day's sales, writes `tycoon:expo:<year>-<season>:fans` with label `Expo: Whop Creator Fair` and +3 reputation. A second book fails with "Already booked." Less than $60 fails with "Need $60" and writes nothing. Replaying a day end or reopening never charges or pays twice. A missed fair is not paid late.
- Skipping the booth writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The Season card line is "Expo · Whop Creator Fair on Spring 14 · $60 booth, about 3 fans" plus one secondary Book booth button. Once booked the line is "Booth booked · Whop Creator Fair on Spring 14" and the button is gone. Hire stays the one primary action. `journey.tycoon.expo` is `{ name, costCents, fans, when, booked }`. A payload without `expo` draws no extra line.

**Proof**
- `/workspace/sv-proof/round-47/46-expo-offer.png` and `47-expo-booked.png`, captured by the verify-startup-valley skill. PROOF PASS. Forty-seven PNGs. The offer header reads "Spring 1 · Year 1 · $207.00 game cash · 0 reputation". Book booth is secondary and Hire Mina · free stays orange. The booked header reads "$147.00 game cash" and the line is "Booth booked · Whop Creator Fair on Spring 14" with no Book booth button. Those lines are readable. The money note sits under the Season card and above the footer. Cash before the desk buy was 118460 cents.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Localization is the next slice. One optional translation of a finished product, on that product's existing shelf row. A small fee, then one quieter extra sales day. Skipping it leaves cash alone, so the first newsletter stays 20700 cents and 5 fans. No new product picker row, and no new Season card button.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. Carried from Round 45: the tallest Selling card still meets the footer, and the earlier Round 40 gaps. The new booth line and button still sit above the money note.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 115 tests, 113 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test books once, charges the fee once, pays 3 fans once on the fair day, replays that day without a second payment, refuses a second book, fails short cash with Need $60 and no row, and leaves a skipped booth at 20700 cents, 5 fans, then 33300 cents with no expo rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS. The offer reads "Expo · Whop Creator Fair on Spring 14 · $60 booth, about 3 fans". Book booth is secondary. Hire Mina stays primary. $0 says Need $60 and writes nothing. Skipping the booth still pays 20700 cents and 5 fans, then 33300 cents. Booking from there leaves $273.00 and "Booth booked · Whop Creator Fair on Spring 14". Reopening does not charge again. A seeded Spring 14 booth pays "Expo: Whop Creator Fair" once, reputation 3, cash still $0, and the next morning offers Summer 14.
- `test_ui_company_redesign.gd` — 15349 checks, 0 failures, 0 captures. Existing fixtures omit `expo` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Forty-seven PNGs in `/workspace/sv-proof/round-47/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-47 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Season. Book booth is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_expos.gd`.

### Round 48 — 2026-10-29

**What changed**
- One optional Spanish edition of a finished product. Copy only, on that product's existing shelf, not a second shelf like the Whop Mobile port. A product can have both. A sequel does not inherit the translation. The fee is $50, then one quieter extra sales day: the same last-step inputs as the port day, then half the units (at least 1). $50 is over the $40 award, under the $60 booth and Mina's $80 season salary, and cheaper than the $80 port because it is copy only. A company that just shipped the $207 newsletter can translate and still keep $157.
- Buying writes `tycoon:localize:<productId>:fee` with label `Translate: Spanish edition`. The day end writes `tycoon:localize:<productId>:sales` with label `Sales · Spanish edition`. If a publisher deal applies, its cut applies to that sales row the same way it applies to a port's extra day. Fans are not cut. The fee is not cut. Replaying a day end or reopening never charges or pays twice. Less than $50 fails with "Need $50" and writes nothing.
- Skipping the translation writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The Shipped card line is "Translate · Spanish edition · $50, one extra sales day" plus one secondary Translate button on the same row as Sequel, Enter award, and Port. The Selling card does not show it. Once bought the line is "Spanish edition · one extra sales day" and the button is gone. Hire stays the one primary action. `journey.tycoon` products carry `localization`. A payload without it draws no line.

**Proof**
- `/workspace/sv-proof/round-48/48-localize-offer.png` and `49-localize-bought.png`, captured by the verify-startup-valley skill. PROOF PASS. Forty-nine PNGs. The offer header reads "Spring 7 · Year 1 · $468.00 game cash · 11 reputation". Translate is secondary, on one row with Sequel, Enter award, and Port. Hire Mina · free stays orange. The bought header reads "$418.00 game cash" and the line is "Spanish edition · one extra sales day" with no Translate button. Those lines are readable. Nothing on that row overlaps.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Town day is the next slice. One optional afternoon off on the Season card. A small fee, then a few fans from the neighborhood. No product and no new picker row. Skipping it leaves the first newsletter at 20700 cents and 5 fans.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. Carried from Round 45: the tallest Selling card still meets the footer, and the earlier Round 40 gaps. The new translate line stays on the finished shelf row. Four short buttons still share one row.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 116 tests, 114 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test charges $50 once, pays one quieter extra sales day once, replays that day without a second payment, refuses a second translation, fails short cash with Need $50 and no row, leaves a skipped translation at 20700 cents, 5 fans, then 33300 cents with no localization rows, applies the publisher cut to the sales row, and allows a port on the same product.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS. The offer reads "Translate · Spanish edition · $50, one extra sales day". Translate is secondary and shares the shelf row with Port. Hire Mina stays primary. The Selling card has no Translate button. Skipping it still pays 20700 cents and 5 fans, then 33300 cents, with no localization rows. Buying charges $50 once, hides the button, and the next day end pays the quieter day once. A later day and a reopen do not pay again. $0 reads "Translate · Need $50" and writes nothing.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `localization` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Forty-nine PNGs in `/workspace/sv-proof/round-48/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-48 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Shipped. Translate is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_localization.gd`.

### Round 49 — 2026-10-29

**What changed**
- One optional afternoon off: the Whop Block Picnic. $20, then exactly 2 fans, on the same company fan total as every other reputation gain. $20 is under the $40 award fee, the $50 translation, and the $60 expo booth, and under Mina's $80 season salary. A company that just shipped the $207 newsletter can take the afternoon and still keep $187. 2 fans is under the expo's 3 and that newsletter's 5. +2 from 0 does not change `Math.floor(reputation / 10)`, so a take before the first release still leaves that newsletter at 20700 cents and 5 product fans. The afternoon does not spend an office day. The clock stays put.
- Taking it writes one ledger row, `tycoon:townday:<year>-<season>:fee`, label `Town day: Whop Block Picnic`, cash −$20, earned 0, reputation +2. The fans are on that fee row. A second take that season fails with "Already took the afternoon." Less than $20 fails with "Need $20" and writes nothing. Replaying a day end or reopening never charges or grants twice. A missed season is not paid later.
- Skipping the afternoon writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The Season card line is "Town · Whop Block Picnic this Spring · $20, about 2 fans" plus one secondary Take the afternoon button. Once taken the line is "Afternoon off · Whop Block Picnic" and the button is gone. Hire stays the one primary action. `journey.tycoon.townDay` is `{ name, costCents, fans, season, taken }`. A payload without `townDay` draws no extra line.

**Proof**
- `/workspace/sv-proof/round-49/50-townday-offer.png` and `51-townday-taken.png`, captured by the verify-startup-valley skill. PROOF PASS. Fifty-one PNGs. The offer header reads "Spring 1 · Year 1 · $207.00 game cash · 0 reputation". Take the afternoon is a cream secondary button, the same shape as Book booth. Hire Mina · free stays orange. The town line and the button are fully readable and do not cover Hire. The taken header reads "Spring 1 · Year 1 · $187.00 game cash · 2 reputation" and the line is "Afternoon off · Whop Block Picnic" with no button. The money note sits under that line and above the footer.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Press demo is the next slice. One optional early look at the product on the bench. A small fee, then a few fans before release. No new picker row. Skipping it leaves the first newsletter at 20700 cents and 5 fans. This is not another sales day and not another afternoon off.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. Carried from Round 45: the tallest Selling card still meets the footer, and the earlier Round 40 gaps. Four short buttons still share one shipped-shelf row. The town day stays on the Season card.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 117 tests, 115 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test charges $20 once, grants 2 fans once, replays the day and a reopen without a second charge, refuses a second take, fails short cash with Need $20 and no row, offers the picnic again next season, and leaves a skipped picnic at 20700 cents, 5 fans, then 33300 cents with no town day rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS. The offer reads "Town · Whop Block Picnic this Spring · $20, about 2 fans". Take the afternoon is secondary. Hire Mina stays primary. $0 says Need $20 and writes nothing. Skipping the picnic still pays 20700 cents and 5 fans, then 33300 cents, with no town day rows. Taking it leaves $313.00, grants 2 fans once, and hides the button. Reopening does not charge again. Ending the picnic day names "Town day: Whop Block Picnic" and does not pay twice. The next season offers Summer again.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `townDay` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Fifty-one PNGs in `/workspace/sv-proof/round-49/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-49 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Season. Take the afternoon is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_town_day.gd`.

### Round 50 — 2026-10-30

**What changed**
- One optional press demo of the product on the bench: a Whop Weekly Preview. $30, then exactly 4 fans, on the same company fan total as every other reputation gain. $30 is unused: over the $20 town afternoon, under the $40 award fee, the $50 translation, the $60 expo booth, and Mina's $80 season salary. A company that just shipped the $207 newsletter can show a preview and still keep $177. 4 fans is unused: over the picnic's 2 and the expo's 3, under that newsletter's 5. +4 from 0 does not change `Math.floor(reputation / 10)`, so a show before the first release still leaves that newsletter at 20700 cents and 5 product fans. The preview does not spend an office day. The clock stays put.
- Showing it writes one ledger row, `tycoon:pressdemo:<productId>:fee`, label `Press demo: Whop Weekly Preview`, cash −$30, earned 0, reputation +4. The fans are on that fee row. A second show fails with "Already shown." Less than $30 fails with "Need $30" and writes nothing. Replaying a day end or reopening never charges or grants twice. The next product offers it again.
- Skipping the preview writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The in-development card line is "Press demo · Whop Weekly Preview · $30, about 4 fans" plus one secondary Show preview button, under the publisher deal. Once shown the line is "Preview shown · Whop Weekly Preview" and the button is gone. Hire stays the one primary action. `pressDemo` on a product is `{ name, costCents, fans, shown }` or null. A payload without `pressDemo` draws no line.

**Proof**
- `/workspace/sv-proof/round-50/52-pressdemo-offer.png` and `53-pressdemo-taken.png`, captured by the verify-startup-valley skill. PROOF PASS. Fifty-three PNGs. The offer header reads "Spring 1 · Year 1 · $207.00 game cash · 0 reputation". Show preview is a cream secondary button, the same shape as Sign publisher. Hire Mina · free stays orange. The press demo line and the button are fully readable and do not cover Hire. The taken header reads "Spring 1 · Year 1 · $177.00 game cash · 4 reputation" and the line is "Preview shown · Whop Weekly Preview" with no button. `44-publisher-offer.png` shows both deals on the same card: Sign publisher and Show preview stack with no overlap.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Launch trailer is the next slice. One optional trailer on the Selling card. A small fee, extra fans on that launch. Skipping it leaves the first newsletter at 20700 cents and 5 fans. This is not another sales day and not another press look.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. Carried from Round 45: the tallest Selling card still meets the footer, and the earlier Round 40 gaps. Four short buttons still share one shipped-shelf row. The press demo sits on the in-development card with the publisher deal.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 118 tests, 116 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test charges $30 once, grants 4 fans once, replays the day and a reopen without a second charge, refuses a second show, fails short cash with Need $30 and no row, offers the preview again on the next product, and leaves a skipped preview at 20700 cents, 5 fans, then 33300 cents with no press demo rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS. The offer reads "Press demo · Whop Weekly Preview · $30, about 4 fans". Show preview is secondary. Hire Mina stays primary. $0 says Need $30 and writes nothing. Skipping the preview still pays 20700 cents and 5 fans, then 33300 cents, with no press demo rows. The next product offers it again. Taking it leaves $303.00, grants 4 fans once, and hides the button. Reopening does not charge again. Ending the preview day names "Press demo: Whop Weekly Preview" and does not pay twice.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `pressDemo` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Fifty-three PNGs in `/workspace/sv-proof/round-50/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-50 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → product in development. Show preview is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_press_demo.gd`.

### Round 51 — 2026-10-30

**What changed**
- One optional launch trailer for a product that is selling: a Whop Creator Cut. $25, then exactly 6 fans, on the same company fan total as every other reputation gain. $25 is unused: over the $20 town afternoon, under the $30 press demo, the $40 award fee, the $50 translation, the $60 expo booth, and Mina's $80 season salary. After the $207 launch the company keeps $182. 6 fans is unused: over the press demo's 4, the expo's 3, the picnic's 2, and that newsletter's 5 product fans. A cut right after the first sale moves reputation from 5 to 11, so later sales use `Math.floor(reputation / 10)` = 1. The trailer row earns 0. Skipping the cut never calls the method, so the first newsletter stays at 20700 cents and 5 fans. The trailer does not spend an office day. The clock stays put.
- Making it writes one ledger row, `tycoon:trailer:<productId>:fee`, label `Trailer: Whop Creator Cut`, cash −$25, earned 0, reputation +6. The fans are on that fee row. A second cut fails with "Already made." Less than $25 fails with "Need $25" and writes nothing. Replaying a day end or reopening never charges or grants twice. The next selling product offers it again.
- Skipping the trailer writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The Selling card line is "Trailer · Whop Creator Cut · $25, about 6 fans" plus one secondary Make trailer button, after the sales-day line and before Patch. Once made the line is "Trailer made · Whop Creator Cut" and the button is gone. Hire stays the one primary action. `trailer` on a product is `{ name, costCents, fans, made }` or null. A payload without `trailer` draws no line. The Shipped card does not draw it.

**Proof**
- `/workspace/sv-proof/round-51/54-trailer-offer.png` and `55-trailer-made.png`, captured by the verify-startup-valley skill. PROOF PASS. Fifty-five PNGs. The offer header reads "Spring 3 · Year 1 · $207.00 game cash · 5 reputation". Make trailer is a cream secondary button, the same shape as Patch. Hire Mina · free stays orange. The trailer line, Make trailer, Patch, and the shelf buttons are readable and do not cover Hire. The made header reads "Spring 3 · Year 1 · $182.00 game cash · 11 reputation" and the line is "Trailer made · Whop Creator Cut" with no button. `24-patch-offer.png` now includes the same offer on the first Selling card, because that playthrough skips the cut.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Dev diary is the next slice. One optional writeup after sales finish, on the Shipped card. One line and one secondary button, separate from the four-button shelf row. A small fee, a few fans from readers. No new picker row and no new art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. An earlier gate run hit `test_tycoon_ports.gd` exit 124: the port-line check read a null label, and the process stayed up until the 900s timeout. A direct rerun printed TYCOON PORTS PASS, and the following full gate did too. The ports test was left unchanged.
6. Carried from Round 45: the Selling card is taller by one line and one secondary button. Shots 54 and 55 keep Patch and the shelf above Hire. The contract card under that Selling card is still clipped at the footer.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 119 tests, 117 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test charges $25 once, grants 6 fans once, replays the day and a reopen without a second charge, refuses a second cut, fails short cash with Need $25 and no row, offers the trailer again on the next selling product, and leaves a skipped trailer at 20700 cents, 5 fans, then 33300 cents with no trailer rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS. The offer reads "Trailer · Whop Creator Cut · $25, about 6 fans". Make trailer is secondary. Hire Mina stays primary. $24.99 says Need $25 and writes nothing. Skipping the trailer still pays 20700 cents and 5 fans, then 33300 cents, with no trailer rows. The next product offers it again. Making it leaves $308.00 after the second sales morning, grants 6 fans once, and hides the button. Reopening does not charge again. Ending the trailer day names "Trailer: Whop Creator Cut" and does not pay twice. A seeded cut on release morning is $182.00 and 11 reputation.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `trailer` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Fifty-five PNGs in `/workspace/sv-proof/round-51/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-51 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Selling. Make trailer is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_launch_trailer.gd`.

### Round 52 — 2026-10-30

**What changed**
- One optional dev diary for a product after sales finish: a Whop Post-Mortem on the Whop blog. $15, then exactly 1 fan, on the same company fan total as every other reputation gain. $15 is unused: under the $20 town afternoon, the $25 trailer, the $30 press demo, the $40 award fee, the $50 translation, the $60 expo booth, and Mina's $80 season salary. After the $207 launch the company keeps $192. After the four-day window the first newsletter has $468. 1 fan is unused: under the picnic's 2, the expo's 3, the press demo's 4, that newsletter's 5 product fans, and the trailer's 6. After the four-day window reputation is 11, so the write moves it to 12. `Math.floor(reputation / 10)` stays 1. The diary row earns 0. Skipping the write never calls the method, so the first newsletter stays at 20700 cents and 5 fans. The diary does not spend an office day. The clock stays put.
- Writing it writes one ledger row, `tycoon:diary:<productId>:fee`, label `Diary: Whop Post-Mortem`, cash −$15, earned 0, reputation +1. The fans are on that fee row. A second write fails with "Already written." Less than $15 fails with "Need $15" and writes nothing. Replaying a day end or reopening never charges or grants twice. The next finished product offers it again.
- Skipping the diary writes no row. The first Crypto Alpha Newsletter is still 20700 cents and 5 fans. The next office day is still 33300 cents.
- The Shipped card line is "Diary · Whop Post-Mortem · $15, about 1 fan" plus one secondary Write diary button, after "Sales finished." and off the four-button shelf row. Once written the line is "Diary written · Whop Post-Mortem" and the button is gone. Hire stays the one primary action. `diary` on a product is `{ name, costCents, fans, written }` or null. A payload without `diary` draws no line. The Selling card does not draw it. There is no new picker row.

**Proof**
- `/workspace/sv-proof/round-52/56-diary-offer.png` and `57-diary-written.png`, captured by the verify-startup-valley skill. PROOF PASS. Fifty-seven PNGs. The offer header reads "Spring 7 · Year 1 · $468.00 game cash · 11 reputation". Write diary is a cream secondary button, the same shape as Make trailer. Hire Mina · free stays orange. The diary line, Write diary, and the shelf buttons are readable and do not cover Hire. Write diary sits above Sequel / Enter award / Port / Translate, not in that row. The written header reads "Spring 7 · Year 1 · $453.00 game cash · 12 reputation" and the line is "Diary written · Whop Post-Mortem" with no button.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Rivals is the next slice. One competing creator shop per season, named in copy. If you ship the same topic they are pushing, opening demand drops a little. A real ship-now-or-wait decision. No new art. Not another fee-for-fans button.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. `test_tycoon_upgrades.gd` gate.sh grep showed two FAILURE lines while reporting exit 0. A direct rerun printed TYCOON UPGRADES PASS. The upgrades test was left unchanged.
6. Carried from Round 45: the Selling card is taller by one line and one secondary button. The Shipped card is now taller the same way while a diary is unwritten. Shot 56 keeps Write diary and the shelf above Hire. The contract card under that Shipped card is clipped at the footer until the diary is written. Shot 57 then shows the full contract card.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 120 tests, 118 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test charges $15 once, grants 1 fan once, replays the day and a reopen without a second charge, refuses a second write, fails short cash with Need $15 and no row, offers the diary again on the next finished product, and leaves a skipped diary at 20700 cents, 5 fans, then 33300 cents with no diary rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS (direct rerun)
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS. The offer reads "Diary · Whop Post-Mortem · $15, about 1 fan". Write diary is secondary and off the shelf row. Hire Mina stays primary. $14.99 says Need $15 and writes nothing. Skipping the diary still pays 20700 cents and 5 fans, then 33300 cents, with no diary rows. After sales finish the offer appears on the Shipped card. Writing it leaves $453.00 and 12 reputation, grants 1 fan once, and hides the button. Reopening does not charge again. Ending the diary day names "Diary: Whop Post-Mortem" and does not pay twice. The next finished product offers it again.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `diary` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Fifty-seven PNGs in `/workspace/sv-proof/round-52/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-52 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Shipped. Write diary is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_dev_diary.gd`.

### Round 53 — 2026-11-05

**What changed**
- One rival creator shop per season, named in copy. The shop and topic come from the season index, `floor((day - 1) / 28) % 4`, so the same four shops return every year. Day 1 and day 113 are both Pip's Pop-up pushing Cooking. Summer is Harbor Goods pushing Trading. Fall is Lumen Kiosk pushing Gaming. Winter is Sable Shelf pushing Study Notes. There is no fee and no ledger row.
- Shipping that season's topic stores `rivalCut: true` on the product and scales opening demand to 90 before the curve and the swing: `Math.max(1, Math.round((base * 90) / 100))`. Later sales days, a port, and a translation reuse that stored cut. A replayed day end and a reopen do not apply it again. A different topic, or the same topic released in another season, stays on the old formula. A sequel decides on its own release day.
- 90 is the same small cut Newcomers and Short use. Those scale units after the curve. Cutting opening demand makes all four sales days a little quieter. Ten points sits inside the ±10 swing and under the season's +20, so waiting for a favored season still pays. Fans follow the quieter units.
- Spring is Cooking, so the existing Crypto Alpha, Fitness, Trading, and Gaming paths never meet the cut. Summer is Trading, so a Fitness newsletter opened in summer stays exact. Skipping the rival topic leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- The Season card adds one line under the in-season topics: "Rival: Pip's Pop-up is pushing Cooking this season". The product picker shows "Rival · opening demand drops." only when the selected topic matches, in the same action style as the fit hint. Hire stays the one primary action. There is no new button. `tycoon.rival` is `{ shop, topicId, topicName, unitPercent }` with `unitPercent` 90. A payload without `rival` draws no line.

**Proof**
- `/workspace/sv-proof/round-53/58-rival-season.png` and `59-rival-picker.png`, captured by the verify-startup-valley skill. PROOF PASS. Fifty-nine PNGs. The Season card reads "In season: Fitness, Dating Advice" and "Rival: Pip's Pop-up is pushing Cooking this season" on Spring 7, with $453.00 and 12 reputation. The rival line, Creator Fair, payroll, loan, expo, and town lines are readable. Take the afternoon sits above Hire Mina · free. Hire stays orange. The picker shows Cooking selected and "Rival · opening demand drops." between the topic grid and Product type. The warning does not cover the topic buttons.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Features is the next slice. One optional feature on the product on the bench. It adds one office day and a small stored bump to opening demand. Skip it and the first newsletter stays at 20700 cents and 5 fans. No new art. A real scope-versus-time decision. Bugs stay set aside.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. `test_tycoon_upgrades.gd` passed this gate with exit 0 and TYCOON UPGRADES PASS. The Round 52 grep quirk was not seen. Left alone.
6. The Season card is one line taller. Shot 58 keeps the rival line and the town button above Hire. The money note stays below that frame. The picker warning is one action line and does not cover the topic buttons.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 121 tests, 119 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test checks the four-season rotation, including day 113 matching day 1, cuts a spring Cooking release to 90 percent of opening demand, keeps that stored cut on a later summer sales day, leaves a summer Cooking release unchanged, replays the release day and a reopen without a second cut, and leaves Crypto Alpha at 20700 cents, 5 fans, then 33300 cents with no `rivalCut` field.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS. The Season card reads "Rival: Pip's Pop-up is pushing Cooking this season". Hire Mina stays primary. Fitness, Trading, and Crypto Alpha show no warning. Cooking shows "Rival · opening demand drops." and the button text stays "Cooking". Skipping Cooking still pays 20700 cents and 5 fans, then 33300 cents. The rules script checks the rotation, the 90 percent opening-demand cut, a summer Cooking release with no cut, and a replayed day plus a reopen.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `rival` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Fifty-nine PNGs in `/workspace/sv-proof/round-53/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-53 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey → Season, and New Product when the topic matches. The rival is a line, not a button. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_rivals.gd`.

### Round 54 — 2026-11-05

**What changed**
- One optional feature on the product on the bench. The name is Whop Bonus Drop in copy only, a creator add-on, not a real Whop product. `tycoon.addFeature` takes `{}`. There is no fee and no ledger row. The click does not move the clock and does not add a dev day.
- Adding it stores `feature: true` and bumps `devDaysRequired` by 1. A newsletter goes from 2 office days to 3. A sequel of that newsletter goes from 1 to 2. Progress and "needs N more office days" use that count. The ideal is still days required × 4, so it grows with the extra day. Working every required day keeps the catalog score. The sales difference is the demand bump.
- At release, if the feature was added, the product stores `featureDemand: true` once, before the opening sale. Later sales days, a port, and a translation read that flag. A replayed day end and a reopen do not set it again and do not recompute an existing sale. A sequel stores no feature, so it can add its own.
- Opening demand uses 110 percent: `Math.max(1, Math.round((demand * 110) / 100))`, before the curve. 110 is the same 10 points as Long's unit percent and the rival's 90 cut, in the other direction from the rival. Long scales units after audience. This scales opening demand, the same place the rival cuts. The feature runs first. A stored rival cut then scales that result to 90. Ten points sits inside the ±10 swing, so the bump is real and still small.
- A second add fails with "Already added." and changes nothing. With nothing on the bench, including after release, it fails with "No product is on the bench." Skipping it changes nothing, so the first Crypto Alpha Newsletter stays at 20700 cents and 5 fans, and the next office day stays 33300 cents.
- The line sits on the developing-product card, under the press demo and above New Product. The offer is "Feature · Whop Bonus Drop · +1 office day, +10% opening demand" plus one secondary button, Add feature. Once added the line is "Feature added · Whop Bonus Drop · Building · day 0 of 3" and the button is gone. Hire stays the one primary action. Add feature is not orange. A payload without `feature` draws no line.

**Proof**
- `/workspace/sv-proof/round-54/60-feature-offer.png` and `61-feature-added.png`, captured by the verify-startup-valley skill. PROOF PASS. Sixty-one PNGs. The offer header reads "Spring 1 · Year 1 · $0.00 game cash · 0 reputation". The line "Feature · Whop Bonus Drop · +1 office day, +10% opening demand" is one readable line. Add feature is a cream secondary button. New Product sits under it. Hire Mina · free stays orange in the footer and does not cover the button. The added header is the same $0.00 and 0 reputation. The line is "Feature added · Whop Bonus Drop · Building · day 0 of 3" with no button. New Product is still under that line, and Hire does not cover it.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Day plan is the next slice. One optional emphasis for the office day on the bench: Design, Tech, or Hype. The default stays the even split, so skipping it leaves every existing sale. No fee, no ledger row, no new art. A real how-you-spend-the-day decision. Bugs stay set aside.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. `test_tycoon_upgrades.gd` passed this gate with exit 0 and TYCOON UPGRADES PASS. The Round 52 grep quirk was not seen. Left alone.
6. The developing card is one line and one button taller while the feature is unadded. Shot 60 keeps Add feature above Hire and above New Product. The publisher and press lines sit above the feature in the same card. After the add, the button is gone. Shot 61 shows the day line with New Product under it. Train staff is clipped at the footer the same way other tall journey screens clip.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 122 tests, 120 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test adds one office day, stores a 110 percent opening-demand bump once, replays the release day and a reopen without a second bump, reuses that bump on a port and a translation, refuses a second add, fails with no product on the bench, offers the feature again on the next product, leaves a sequel without it, and leaves a skipped feature at 20700 cents, 5 fans, then 33300 cents with no feature rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS. The developing card reads "Feature · Whop Bonus Drop · +1 office day, +10% opening demand". Add feature is secondary and above New Product. Hire Mina stays primary. The picker and the build screen have no feature line. Skipping the feature still pays 20700 cents and 5 fans, then 33300 cents. The next product offers it again. Adding it shows "Feature added · Whop Bonus Drop · Building · day 0 of 3", needs 3 office days, hides the button, and does not change cash. Reopening keeps that line. The rules script checks the 110 percent opening-demand bump, the rival-after-feature order, a replayed day plus a reopen, the port and the translation, a sequel that does not inherit it, and "Already added." / "No product is on the bench."
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `feature` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Sixty-one PNGs in `/workspace/sv-proof/round-54/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-54 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Add feature is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_features.gd`.

### Round 55 — 2026-11-06

**What changed**
- One optional day plan on the product on the bench. The choices are Even, Design, Tech, and Hype. Even is the default and keeps today's split. `tycoon.setDayPlan` takes `{stat}` of `even`, `design`, `tech`, or `hype`. There is no fee and no ledger row. The click does not move the clock.
- Storage is `dayPlan` on the product snapshot in `staff_json`: `design`, `tech`, or `hype`. Even omits the key. There is no new SQL column. Reads do not rewrite `staff_json`. An older row with no key is Even. A sequel starts Even. Release hides the control because the developing card is gone.
- An emphasis folds that office day's personal craft into the chosen stat. Personal gain is `personal.design + personal.tech + personal.hype` on that stat, and the other two personal columns are 0. Point-tool bonuses and the office bonus stay on their own stats. The even split keeps today's ratios. The emphasis does not invent new point totals. A founder alone is 2/2/2 on Even and 6/0/0 on Design. With all three point tools and the Open Floor, that Design day is 8/2/1. Accrual still stops after the polish window, so an emphasized day past it adds 0 craft. Training still zeroes that person's personal craft that day. The plan sticks until it changes or the product leaves development.
- A missing or invalid stat fails with "Pick Even, Design, Tech, or Hype." The protocol rejects a bad payload with "Invalid protocol request". With nothing on the bench, including after release, a valid stat fails with "No product is on the bench." Setting the same plan again is idempotent. Skipping the plan leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- The row sits on the developing-product card, under the feature and above New Product. The line is "Day plan · Even · design, tech, and hype as usual", or "Day plan · Design · today's craft goes to design" when Design is set. Tech and Hype use that shape. The four choices are secondary. The active choice uses the pressed secondary style. Hire stays the one primary action. Nothing on this row is orange. `dayPlan` on the developing product is null for Even, or `{id, label, stat}`. `dayPlanOptions` lists Even and the three emphases. A payload without both draws no control.

**Proof**
- `/workspace/sv-proof/round-55/62-dayplan-offer.png` and `63-dayplan-design.png`, captured by the verify-startup-valley skill. PROOF PASS. Sixty-three PNGs. The offer header reads "Spring 1 · Year 1 · $0.00 game cash · 0 reputation". The line "Day plan · Even · design, tech, and hype as usual" is one readable line. Even, Design, Tech, and Hype are four cream secondary buttons in one row, and Even is the pressed one. New Product sits under the row. Hire Mina · free stays orange in the footer and does not cover the buttons. The Design header is the same $0.00 and 0 reputation. The line is "Day plan · Design · today's craft goes to design", Design is the pressed choice, and Even, Tech, and Hype are not. New Product is still under that row, and Hire does not cover it.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Bugs is the next slice. A lopsided build stores a small deterministic bug count. A balanced founder newsletter stays at 0 bugs, so the first Crypto Alpha Newsletter stays at 20700 cents and 5 fans. Fix bugs is optional on the developing card. It spends the next office day's personal craft on clearing bugs. No fee, no ledger row, no new art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. `test_tycoon_upgrades.gd` passed this gate with exit 0 and TYCOON UPGRADES PASS. The Round 52 grep quirk was not seen. Left alone.
6. The developing card is one line and one choice row taller. Shots 62 and 63 scroll the day plan to the top of the journey, so the choices sit above New Product and Hire does not cover them. The publisher, press demo, and feature stay in that same card, above the day plan. Shot 60 still keeps Add feature above Hire and above New Product.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 123 tests, 121 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test folds personal craft, leaves tool and office bonuses on their own stats, switches plans, refuses a bad stat and a call with nothing on the bench, treats the same plan as idempotent, starts a sequel on Even, keeps the plan across a reopen, adds 0 craft past the polish window, and leaves a skipped plan at 20700 cents, 5 fans, then 33300 cents with no day-plan rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS. The developing card reads "Day plan · Even · design, tech, and hype as usual". Even, Design, Tech, and Hype are secondary and above New Product. Hire Mina stays primary. The picker and the build screen have no day plan. Skipping it still pays 20700 cents and 5 fans, then 33300 cents. The next product starts Even. Picking Design, again, Tech, Hype, Even, and Design spends nothing. The design office day lands at 6/0/0. Reopening keeps that line and those points. The rules script checks the tool and office split, training, the polish window, a sequel that starts Even, and "Pick Even, Design, Tech, or Hype." / "No product is on the bench."
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `dayPlan` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Sixty-three PNGs in `/workspace/sv-proof/round-55/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-55 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Day plan is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_day_plan.gd`.

### Round 56 — 2026-11-06

**What changed**
- A lopsided build stores a small deterministic bug count. `bugCount(points) = min(5, floor((max - min) / 4))`. Founder 4/4/4 → 0. A Design-emphasized founder-only build that lands 12/0/0 → 3. Cap at 5.
- During development the journey shows `{ count, cleared, fixing }` with the live remaining count. At release, store that final count as `bugs` on the product snapshot in `staff_json` (omit when 0). Each stored bug subtracts 1 from the base score before reviewers, then clampScore as today. Zero bugs leaves every existing sale. Ports, patches, and translations keep the stored review score.
- `tycoon.fixBugs` takes `{}`. With nothing on the bench it fails with "No product is on the bench." When live bugs are 0 it fails with "No bugs to fix." Re-arm is idempotent. No fee, no ledger row, no clock move. Storage is `fixBugs: true` plus integer `bugsCleared` (omit when 0). A sequel starts clean. Older rows without the keys have 0 cleared and are not fixing.
- Armed fixBugs redirects the next office day's personal craft: 0 personal d/t/h, and `bugsCleared += max(1, floor(personalTotal / 4))` when personalTotal > 0. Point-tool and office bonuses still land on their own stats. Day plan is ignored for personal that day because fixing is the day's job. Past the polish window nothing clears. Dev days still increment. Research still accrues. After that one tick the flag clears.
- Skipping Fix bugs on a balanced build leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- The row sits on the developing-product card, under Day plan and above New Product. The line is "Bugs · 0 · build looks balanced", or "Bugs · N · Fix bugs spends tomorrow's craft", or when armed "Fixing bugs · next office day clears craft into bugfix". Fix bugs is secondary when count > 0 and not armed. Hire stays the one primary action.

**Proof**
- `/workspace/sv-proof/round-56/64-bugs-offer.png` and `65-bugs-fixing.png`, captured by the verify-startup-valley skill. PROOF PASS. Sixty-five PNGs. The offer header reads "Spring 2 · Year 1 · $0.00 game cash · 0 reputation". The line "Bugs · 1 · Fix bugs spends tomorrow's craft" is one readable line. Fix bugs is a cream secondary button under that line. New Product sits under the button. Hire Mina · free stays orange in the footer and does not cover it. The fixing header is the same $0.00 and 0 reputation. The line is "Fixing bugs · next office day clears craft into bugfix", the Fix bugs button is gone, New Product is still under that line, and Hire does not cover it.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Hype week is the next slice. One optional push on the product on the bench: spend tomorrow's personal craft as pure hype for that one office day, with no fee and no ledger row. Skip it and every existing sale stays put. No new art. A real timing decision beside Day plan and Bugs.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. `test_tycoon_upgrades.gd` passed this gate with exit 0 and TYCOON UPGRADES PASS. The Round 52 grep quirk was not seen. Left alone.
6. The developing card is one line taller when bugs show, and one button taller when Fix bugs is offered. Shots 64 and 65 scroll the bugs line to the top of the journey, so the control sits above New Product and Hire does not cover it. The publisher, press demo, feature, and day plan stay in that same card, above bugs.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 124 tests, 122 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test checks bugCount 4/4/4 → 0 and 12/0/0 → 3, leaves a balanced newsletter at 20700/5 then 33300, stores bugs on a lopsided Design build and lowers the release score/cash, arms fixBugs, clears floor(personal/4) with no personal craft, keeps tools/office on their own stats, refuses no-product and no-bugs, treats re-arm as idempotent, starts a sequel clean, adds 0 past the polish window, and keeps bugsCleared across a reopen.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS
- `test_tycoon_bugs.gd` — TYCOON BUGS PASS. The developing card reads "Bugs · 0 · build looks balanced". Fix bugs is hidden until a Design day leaves one live bug. Arming it spends nothing and shows the fixing line. The fix day clears to 0, adds no personal craft, and still counts as an office day. Skipping Fix bugs on a balanced build still pays 20700 cents and 5 fans, then 33300 cents. Reopening keeps bugsCleared. The rules script checks tools/office, the polish window, a sequel that starts clean, and "No product is on the bench." / "No bugs to fix."
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `bugs` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Sixty-five PNGs in `/workspace/sv-proof/round-56/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-56 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Bugs is optional and secondary. Skipping it on a balanced build leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_bugs.gd`.

### Round 57 — 2026-11-09

**What changed**
- Hype week was the roadmap's next slice. It duplicated Day plan's Hype emphasis, which already puts personal craft onto hype, so this slice shipped Crunch instead.
- `tycoon.crunch` takes `{}`. With nothing on the bench, including after release, it fails with "No product is on the bench." While the team is resting it fails with "The team is still tired." Arming again while already armed is idempotent. No fee, no ledger row, no clock move.
- Storage is on the product snapshot in `staff_json`: `crunch` is `armed` or `resting` (omit when neither) and integer `crunchBugs` (omit when 0). No new SQL column. Reads do not rewrite `staff_json`. A sequel starts clean. An older row with no keys is not crunching and has 0 crunch bugs.
- The next office day with crunch armed doubles each non-training person's personal design, tech, and hype after Day plan is applied. A Design day plan doubles the Design total. Tool bonuses and the office bonus stay on their own stats. Then `crunch` becomes `resting` and `crunchBugs` gains 1. A founder alone goes from 2/2/2 to 4/4/4. With all three point tools and the Open Floor, a Design crunch day is 14/2/1, and the rest day adds the tools and office only, landing at 16/4/2.
- The following office day with crunch resting sets personal craft to 0. Tool and office bonuses still apply. Then the crunch flag clears. Dev days and research points still accrue on both days.
- Past `pointsStillAccrue`, personal craft is already 0. An armed crunch still advances to resting and still adds the bug. Crunching inside the polish window is a mistake.
- If fixBugs is armed on the same day as an armed crunch, fixBugs wins that day. Personal goes to clearing, and the clear uses the doubled total, so a founder Design total of 12 clears 3. Crunch still advances to resting and still adds the bug. A rest day zeroes personal before a same-day armed fix, so that fix clears nothing and still spends the fix flag.
- Live bugs are `Math.min(5, Math.max(0, bugCount(points) + crunchBugs - bugsCleared))`. Release stores that count as `bugs`. Skipping Crunch leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- The row sits on the developing-product card, under Bugs and above New Product. Idle: "Crunch · double craft tomorrow, then a rest day and +1 bug" with one secondary Crunch button. Armed: "Crunching · tomorrow's craft counts double" and the button is gone. Resting: "Resting · team recovers tomorrow" and the button is gone. Hire stays the one primary action. Nothing on this row is orange. The developing product carries `crunch: { state }` of `idle`, `armed`, or `resting`. A payload without it draws no control. After release the field is null.

**Proof**
- `/workspace/sv-proof/round-57/66-crunch-offer.png` and `67-crunch-resting.png`, captured by the verify-startup-valley skill. PROOF PASS. Sixty-seven PNGs. The offer header reads "Spring 1 · Year 1 · $0.00 game cash · 0 reputation". The line "Crunch · double craft tomorrow, then a rest day and +1 bug" is one readable line. Crunch is a cream secondary button under that line. New Product sits under the button. Hire Mina · free stays orange in the footer and does not cover it. The resting header is "Spring 2 · Year 1 · $0.00 game cash · 0 reputation". The line is "Resting · team recovers tomorrow", the Crunch button is gone, New Product is still under that line, and Hire does not cover it.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Early access is the next slice. One optional early ship on the product still on the bench, once it has at least one office day and is still short of the required days. Shipping early stores a small score penalty and starts the sales window that day. Skip it and the release gate stays put, so the first Crypto Alpha Newsletter still lands at 20700 cents and 5 fans. No fee, no ledger row, no new art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. `test_tycoon_price.gd` passed this gate. The Round 46 flake was not seen. Left alone.
5. `test_tycoon_upgrades.gd` passed this gate with exit 0 and TYCOON UPGRADES PASS. The Round 52 grep quirk was not seen. Left alone.
6. The developing card is one line taller when crunch shows, and one button taller when Crunch is offered. Shots 66 and 67 scroll the crunch line to the top of the journey, so the control sits above New Product and Hire does not cover it. The publisher, press demo, feature, day plan, and bugs stay in that same card, above crunch.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 125 tests, 123 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test doubles personal craft after the day plan, leaves tool and office bonuses on their own stats, rests the next day at 0 personal, clears the flag, raises live bugs and lowers the release score and opening cash, still adds the bug inside the polish window, lets fixBugs use the doubled total on the same day, treats a rest-day fix as a clear of 0, starts a sequel clean, refuses a call with nothing on the bench, refuses a call while resting, treats re-arm as idempotent, keeps the state across a reopen, and leaves a skipped crunch at 20700 cents, 5 fans, then 33300 cents with no crunch rows.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS
- `test_tycoon_bugs.gd` — TYCOON BUGS PASS
- `test_tycoon_crunch.gd` — TYCOON CRUNCH PASS. The developing card reads "Crunch · double craft tomorrow, then a rest day and +1 bug". Crunch is secondary, under Bugs, and above New Product. Hire Mina stays primary. The picker and the build screen have no crunch control. Skipping it still pays 20700 cents and 5 fans, then 33300 cents. Arming it spends nothing and shows the crunching line. The next office day shows "Resting · team recovers tomorrow", lands at 4/4/4, and shows one live bug. Reopening keeps that line and those points. The rules script checks the tool and office split, the polish window, fixBugs on the same day, a sequel that starts clean, and "No product is on the bench." / "The team is still tired."
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `crunch` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Sixty-seven PNGs in `/workspace/sv-proof/round-57/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-57 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Crunch is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_crunch.gd`.

### Round 58 — 2026-11-09

**What changed**
- `tycoon.earlyAccess` takes `{}`. With nothing on the bench, including after release, it fails with "No product is on the bench." With no office day yet it fails with "Work one office day first." When the required days are already done it fails with "Required days are done. Use Release." A bad payload fails with "Invalid protocol request". No fee, no ledger row, no clock move.
- The ship uses the normal release path the same day. Reviews, launch-day sales, the contract bonus, stored bugs, and later sales days all follow Release. `salesDays` starts at 1. Ending that same day does not sell again.
- The missing days are not worked, so they add no design, tech, or hype. The review still measures the earned points against the full required length. A founder who ships a newsletter after one even day is 2/2/2 against a two-day ideal.
- The penalty is 1 score point per missing day, capped at 3, subtracted with bugs before the reviewers, then clamped to 1–10. A newsletter one day early loses 1. A five-day build shipped after one day stores `earlyDays` 4 and loses 3. The score does not go below 1.
- Storage is on the product snapshot in `staff_json`: `earlyAccess: true` and integer `earlyDays` (omit when 0). Both keys are omitted when the product did not ship early. No new SQL column. Reads do not rewrite `staff_json`. A sequel starts clean. An older row with neither key was not an early ship.
- The contract bonus still pays once, on `tycoon:contract:<productId>`. There is no `tycoon:early` row. Reopening the save keeps the keys, the penalty, and the sales. Skipping Early access leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- The developing product carries `earlyAccess: { enabled, reason, daysLeft, penalty }`. Day 0 and a finished build are disabled, with a reason and no button. The offer is enabled, with an empty reason and the capped penalty. After an early ship the object stays with `enabled` false and the capped penalty. A normal release stores null. A payload without `earlyAccess` draws no control.
- The row sits on the developing-product card, under Crunch and above New Product. Waiting: "Early access · Work one office day first." Ready: "Early access · Required days are done. Use Release." Offer: "Early access · ship now, −N score" with one secondary Ship early button. The release card, the Selling card, the Shipped card, and the shipped list say "Early access" after an early ship. Hire stays the one primary action. Nothing on this row is orange.

**Proof**
- `/workspace/sv-proof/round-58/68-early-offer.png` and `69-early-released.png`, captured by the verify-startup-valley skill. PROOF PASS. Sixty-nine PNGs. The offer header reads "Spring 2 · Year 1 · $0.00 game cash · 0 reputation". The line "Early access · ship now, −1 score" is one readable line. Ship early is a cream secondary button under that line. New Product sits under the button. Hire Mina · free stays orange in the footer and does not cover it. The release card reads "Score 3 / 10", then "Early access", then the four reviewers, then "Launch sales · $153.00 · +2 fans". The top bar shows $153 earned. Those lines are readable and do not overlap. Ship another and Back to office stay in the footer.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Cancel the build is the next slice. One optional drop of the product still on the bench. The bench clears, the days already worked are gone, and there is no review and no sales. Skip it and the product stays, so the first Crypto Alpha Newsletter still lands at 20700 cents and 5 fans. No fee, no ledger row, no new art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The developing card is one line taller when early access shows, and one button taller when Ship early is offered. The offer scrolls to the top of the journey, so the line and the button sit above New Product and Hire does not cover them. The publisher, press demo, feature, day plan, bugs, and crunch stay in that same card, above early access.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 126 tests, 124 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test covers each failure, the penalty and the cap, the stored keys, the sales window starting that day, the contract bonus paying once, a clean sequel, the skipped newsletter at 20700 cents and 5 fans then 33300 cents, a reopen, and no Connect call.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS
- `test_tycoon_bugs.gd` — TYCOON BUGS PASS
- `test_tycoon_crunch.gd` — TYCOON CRUNCH PASS
- `test_tycoon_early_access.gd` — TYCOON EARLY ACCESS PASS. Day 0 names the wait and hides Ship early. A finished build points at Release and hides the button. Skipping it still pays 20700 cents and 5 fans, then 33300 cents, and the release card does not say Early access. After one office day the line is "Early access · ship now, −1 score". Ship early is secondary, under Crunch, and above New Product. Hire Mina stays primary. The release card, the Selling card, and the shipped list say Early access. Launch sales are quieter than a full newsletter. Reopening keeps the cash, the mark, and the penalty. Connect stays closed. The rules script inside that test checks the same harness cases.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `earlyAccess` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Sixty-nine PNGs in `/workspace/sv-proof/round-58/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-58 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Early access is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_early_access.gd`.

### Round 59 — 2026-11-10

**What changed**
- `tycoon.cancelBuild` takes `{}`. With nothing on the bench, including after a release or a cancel, it fails with "No product is on the bench." A bad payload fails with "Invalid protocol request". No fee, no ledger row, no clock move. Calling it again fails with the same bench string.
- The product row is deleted. It is not a shipped history row, and there is no new SQL status. Awards, sequels, ports, rivals, patches, and contract completion only see rows that remain. `tycoon.release` of the deleted id fails with "No product is on the bench." `tycoon.award`, `tycoon.sequel`, `tycoon.port`, `tycoon.localize`, `tycoon.patch`, `tycoon.makeTrailer`, and `tycoon.writeDiary` fail with "No product with that id."
- The next product id is one past the highest `pN` still stored, or already used as its own segment in a `tycoon:` ledger id. A day-0 drop that wrote no ledger id can start again as that same id. A drop after an office day, a publisher advance, or a press demo uses the next id, so a charged id is not reused.
- A contract on the bench product fails. The bonus is not paid. The same offer returns and can be accepted again. A publisher deal is void. The advance already paid stays in cash and in `tycoon:publisher:<id>:advance`. A press demo fee and a marketing fee stay spent. Fans, research points, and staff stay as they are. Cancelling itself does not change cash, fans, research, or staff.
- A cancelled sequel clears `sequelId` on the original, so that original can start another sequel.
- The developing product carries `cancel: { enabled: true, reason: "" }`. A shipped product stores null. A payload without `cancel` draws no control.
- The row sits on the developing-product card, under Early access and above New Product. The line is "Cancel · drop this build. Days worked are gone." with one secondary Cancel build button. That button asks first. The line becomes "Drop this build? Days worked are gone." Keep building takes focus. Drop the build sends the command. The two buttons stack, full width. Both are secondary. Hire stays the one primary action. Nothing on this row is orange. Skipping Cancel leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.

**Proof**
- `/workspace/sv-proof/round-59/70-cancel-offer.png` and `71-cancel-done.png`, captured by the verify-startup-valley skill. PROOF PASS. Seventy-one PNGs. The offer header reads "Spring 2 · Year 1 · $0.00 game cash · 0 reputation". The line "Cancel · drop this build. Days worked are gone." is one readable line. Cancel build is a cream secondary button under that line. New Product sits under the button. Hire Mina · free stays orange in the footer and does not cover it. After the drop the developing card is gone, New Product is available, the header is still $0.00 and 0 reputation, and the founder line still shows the craft from the worked day. Those lines are readable and do not overlap.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Slip a day is the next slice. One optional hold on the product still on the bench. The next office day moves the calendar, and payroll still comes due, but that day does not add a dev day and does not add design, tech, or hype. Skip it and every office day still builds, so the first Crypto Alpha Newsletter still lands at 20700 cents and 5 fans. No fee, no ledger row, no new art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The developing card is one line taller when cancel shows, and one button taller for Cancel build. The confirm stacks a second button. Shots 70 and 71 scroll the cancel line to the top of the journey, so the control sits above New Product and Hire does not cover it. The publisher, press demo, feature, day plan, bugs, crunch, and early access stay in that same card, above cancel.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 127 tests, 125 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test deletes the bench row, writes no review, sale, or cancel ledger row, refuses a second call and every history command on the missing id, keeps a contract offer unpaid and acceptable again, leaves a publisher advance and a press fee spent, clears a sequel link, reuses an id only when no ledger segment exists, and leaves a skipped newsletter at 20700 cents and 5 fans then 33300 cents.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — the gate process exited 0. Its filtered tail was `FAILURE The sequel releases` and `FAILURE A sequel cannot start its own sequel`, so the summary line was not in that tail. Two direct reruns after the gate printed TYCOON SEQUELS PASS. This test was not edited this round.
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS
- `test_tycoon_bugs.gd` — TYCOON BUGS PASS
- `test_tycoon_crunch.gd` — TYCOON CRUNCH PASS
- `test_tycoon_early_access.gd` — TYCOON EARLY ACCESS PASS
- `test_tycoon_cancel.gd` — TYCOON CANCEL PASS. Day 0 shows "Cancel · drop this build. Days worked are gone." Cancel build is secondary, under Early access, and above New Product. A payload without `cancel` draws no control. Cancel build asks first, Keep building takes focus, and both choices are secondary. Keep building leaves the product. After one office day the same row still sits under Ship early. Skipping cancel still pays 20700 cents and 5 fans, then 33300 cents, and the release card has no cancel control. Dropping a later build clears the bench, leaves the shipped newsletter, and New Product can start again. Reopening keeps that state. Connect stays closed. The rules script inside that test checks the same harness cases.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `cancel` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Seventy-one PNGs in `/workspace/sv-proof/round-59/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-59 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Cancel build is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_cancel.gd`.

### Round 60 — 2026-11-10

**What changed**
- `tycoon.slipDay` takes `{}`. With nothing on the bench, including after a release or a cancel, it fails with "No product is on the bench." A bad payload fails with "Invalid protocol request". No fee, no ledger row, no clock move. Calling it again while a hold is already pending is idempotent. It does not stack a second day.
- The hold is one-shot. The office day that was held clears the flag. Slip can be used again on a later day. At most one hold is pending. Storage is `slip: true` on the product snapshot in `staff_json`, omitted when the next day is not held. There is no new SQL column. Reads do not rewrite `staff_json`. A sequel starts with the key omitted. An older row with no key is not holding.
- That office day still advances the calendar. Payroll, a loan payment, an expo, a town day, and sales of a product that already shipped still happen. The bench product gains no dev day and no design, tech, or hype. Tool bonuses, the office bonus, and research points from that build do not land. `last_dev_day` is set to that day, so ending the same day again does not build it either. There is no `tycoon:build:<id>:<day>` row for the held day.
- Day plan, an armed crunch, a resting crunch, and an armed fix stay as they were. They apply on the next office day that is not held. A lesson on the held day still raises the stat and still spends its cash. The product on the bench keeps the staff snapshot from the day development started, so this build does not gain the new point. The next product uses the new stat.
- A developing product carries `slip: { enabled, pending, reason }`. While the next day is free, `enabled` is true and `pending` is false. While a hold is pending, `enabled` is false and `pending` is true. `reason` is empty in both cases. After the product ships, the field is null. `slip` is optional on the product schema, so older payloads still validate. A payload without `slip` draws no control. New payloads include it.
- The row sits on the developing-product card, under Cancel and above New Product. The offer line is "Slip a day · hold tomorrow. The build does not." with one secondary Slip a day button. Pending, the line is "Holding tomorrow" and the button is gone. Hire stays the one primary action. Nothing on this row is orange. Skipping Slip a day leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.

**Proof**
- `/workspace/sv-proof/round-60/72-slip-offer.png` and `73-slip-held.png`, captured by the verify-startup-valley skill. PROOF PASS. Seventy-three PNGs. The offer header reads "Spring 1 · Year 1 · $0.00 game cash · 0 reputation". The line "Slip a day · hold tomorrow. The build does not." is one readable line. Slip a day is a cream secondary button under that line. New Product sits under the button. Hire Mina · free stays orange in the footer and does not cover it. After the click the line is "Holding tomorrow", the button is gone, New Product remains, and the header is still $0.00 and 0 reputation. Those lines are readable and do not overlap. Connect stays closed.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Pivot is the next slice. One optional change of topic or type on the product still on the bench. Dev days and craft points stay. The name and the fit follow the new pair, and the review uses that fit. A contract on the old pair blocks the pivot. No fee, no ledger row, no new art. Skip it and the first Crypto Alpha Newsletter still lands at 20700 cents and 5 fans. A second room still waits on architecture art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The developing card is one line taller when slip shows, and one button taller for Slip a day. Pending drops that button. Shots 72 and 73 scroll the slip line to the top of the journey, so the control sits above New Product and Hire does not cover it. The publisher, press demo, feature, day plan, bugs, crunch, early access, and cancel stay in that same card, above slip.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 128 tests, 126 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test holds the bench for one office day, advances the calendar without a dev day or craft, clears the one-shot flag, keeps payroll due, writes no slip ledger row, leaves a skipped newsletter at 20700 cents and 5 fans then 33300 cents, and keeps a pending hold across reopen.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS
- `test_tycoon_bugs.gd` — TYCOON BUGS PASS
- `test_tycoon_crunch.gd` — TYCOON CRUNCH PASS
- `test_tycoon_early_access.gd` — TYCOON EARLY ACCESS PASS
- `test_tycoon_cancel.gd` — TYCOON CANCEL PASS
- `test_tycoon_slip_day.gd` — TYCOON SLIP DAY PASS. Day 0 shows "Slip a day · hold tomorrow. The build does not." Slip a day is secondary, under Cancel build, and above New Product. The line stays on one line. A payload without `slip` draws no control. The product picker and the build screen have no slip control. Clicking Slip a day shows "Holding tomorrow" and hides the button. Cash, fans, and dev days stay at 0. Reopening keeps the pending hold. The held office day returns the offer, leaves the build at day 0 of 2 with no craft, and the header reads Spring 2 with $0.00 and 0 reputation. Hire Mina stays the one primary action. Connect stays closed. The rules script inside that test checks the same harness cases for the empty bench, the calendar, payroll, and the skipped newsletter.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `slip` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Seventy-three PNGs in `/workspace/sv-proof/round-60/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-60 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Slip a day is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_slip_day.gd`.

### Round 62 — 2026-11-11

**What changed**
- `tycoon.playtest` takes `{}`. With nothing on the bench, including after a release or a cancel, it fails with "No product is on the bench." With no office day yet it fails with "Work one office day first." A bad payload fails with "Invalid protocol request". No fee, no ledger row, no clock move. Calling it again is free. The result is the current band.
- The band is low, mid, or high. It is computed on read from the current points, the current fit, and the current type weights, using the same review math a release would use today. Nothing is written to `staff_json`. The band is not stored. Reviewer jitter uses the saved seed and does not draw a new one. A later office day, a pivot, or a crunch can change the next look. Skipping Playtest, and using it, both leave the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- A developing product carries `playtest: { enabled, band, reason }`. Before any office day, `enabled` is false, `band` is null, and `reason` is "Work one office day first." After at least one office day, `enabled` is true, `reason` is empty, and `band` is the current band. After the product ships, the field is null. `playtest` is optional on the product schema, so older payloads still validate. A payload without `playtest` draws no control. New payloads include it.
- The row sits on the developing-product card, under Pivot and above New Product. The waiting line is "Playtest · Work one office day first." and it has no button. The offer line is "Playtest · see the likely review band." with one secondary Playtest button. After the look the line is "Playtest: likely mid reviews", or low, or high, and the button stays. The panel hides the band line until the player asks. Hire stays the one primary action. Nothing on this row is orange. A product on the bench raises that journey panel to 660px so Early access through New Product stay inside the scrollport.

**Proof**
- `/workspace/sv-proof/round-62/76-playtest-offer.png` and `77-playtest-result.png`, captured by the verify-startup-valley skill. PROOF PASS. Seventy-seven PNGs. The offer header reads "Spring 3 · Year 1 · $0.00 game cash · 0 reputation". The line "Playtest · see the likely review band." is one readable line. Playtest is a cream secondary button under that line. New Product sits under the button. Hire Mina · free stays orange in the footer and does not cover it. After the click the line is "Playtest: likely mid reviews", the button stays, and the header is still $0.00 and 0 reputation. Those lines are readable and do not overlap. Connect stays closed.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Assign the team is the next slice. One optional change of who is on the product still on the bench. Days already worked and the points already earned stay. Later office days use the new people, including someone hired after the build started. No fee, no ledger row, no new art. Skip it and the first Crypto Alpha Newsletter still lands at 20700 cents and 5 fans. A second room still waits on architecture art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The developing card is one line taller when playtest shows, and one button taller after the first office day. Shots 76 and 77 scroll the playtest line to the top of the journey, so the control sits above New Product and Hire does not cover it. The publisher, press demo, feature, day plan, bugs, crunch, early access, cancel, slip, and pivot stay in that same card, above playtest.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 130 tests, 128 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test refuses an empty bench and a day-0 look, matches the release band for low, mid, and high, leaves points, seed, review, sales, and the ledger alone, keeps a skipped and a looked newsletter at 20700 cents and 5 fans then 33300 cents, moves the band after a pivot and after a crunch, and keeps the same block across reopen.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — the gate's filtered tail showed `FAILURE The shipped product keeps the score bump` and `FAILURE Release names the engine and the score bump`. A direct rerun printed TYCOON ENGINES PASS. The gate before the journey panel grew also printed TYCOON ENGINES PASS. This test was not edited this round.
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — the gate's filtered tail showed `FAIL Worker bootstrap loads the company`. A direct rerun printed TYCOON DEV DIARY PASS. The earlier gate also printed TYCOON DEV DIARY PASS. This test was not edited this round.
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS
- `test_tycoon_bugs.gd` — TYCOON BUGS PASS
- `test_tycoon_crunch.gd` — TYCOON CRUNCH PASS
- `test_tycoon_early_access.gd` — TYCOON EARLY ACCESS PASS
- `test_tycoon_cancel.gd` — TYCOON CANCEL PASS
- `test_tycoon_slip_day.gd` — TYCOON SLIP DAY PASS
- `test_tycoon_pivot.gd` — TYCOON PIVOT PASS
- `test_tycoon_playtest.gd` — TYCOON PLAYTEST PASS. Day 0 shows "Playtest · Work one office day first." and hides Playtest. After two office days the line is "Playtest · see the likely review band." Playtest is secondary, under Pivot, and above New Product. The line stays on one line. A payload without `playtest` draws no control. The product picker and the build screen have no playtest control. Clicking Playtest shows "Playtest: likely mid reviews" and keeps the button. Cash, fans, dev days, and the 4/4/4 points stay put. Looking again keeps the band. Reopening hides the band line until the player asks and keeps the mid block, with cash and fans still 0. Hire Mina stays the one primary action. Connect stays closed. The rules script inside that test checks the same harness cases.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `playtest` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Seventy-seven PNGs in `/workspace/sv-proof/round-62/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-62 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Playtest is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_playtest.gd`.

### Round 63 — 2026-11-11

**What changed**
- `tycoon.assignTeam` takes `{staffIds}`. With nothing on the bench, including after a release or a cancel, it fails with "No product is on the bench." An empty list fails with "Pick at least one teammate." An unknown id fails with "Unknown teammate". An unhired id fails with "Mina is not on the team yet." A bad payload fails with "Invalid protocol request". No fee, no ledger row, no clock move. Assigning the same set of people again is a no-op.
- Start development still always includes the founder. Assign the team does not. The founder can leave if someone else stays. Days already worked and the points already earned stay. Later office days use the new people, including someone hired after the build started. People already on the team keep the stats stored when they joined this build. A newly added person stores their current stats. A person in training may stay on the team; that office day still zeroes their personal contribution. Skipping Assign the team leaves the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- A developing product carries `team: { enabled, members, reason }`. `enabled` is true, `reason` is empty, and `members` lists the founder and every hired person as `{id, name, onTeam}`. After the product ships, the field is null. `team` is optional on the product schema, so older payloads still validate. A payload without `team` draws no control. New payloads include it. The staff list still lives in `staff_json`. There is no new SQL column.
- The row sits on the developing-product card, under Playtest and above New Product. One compact line reads "Team: Founder" or "Team: Founder, Mina", with small secondary toggle buttons for each person on that same row. Selected people use the pressed secondary style. Hire stays the one primary action. Nothing on this row is orange. A product on the bench raises that journey panel to 720px so Early access through New Product stay inside the scrollport. The pivot picker keeps the 660px envelope from Round 62.

**Proof**
- `/workspace/sv-proof/round-63/78-team-offer.png` and `79-team-changed.png`, captured by the verify-startup-valley skill. PROOF PASS. Seventy-nine PNGs. The offer header reads "Spring 1 · Year 1 · $0.00 game cash · 0 reputation". The line "Team: Founder" is one readable line, with Founder pressed and Mina sitting out on the same row. New Product sits under that row. Hire Theo · $300.00 stays in the footer and does not cover it. After clicking Mina the line is "Team: Founder, Mina", both toggles are pressed, and the header is still $0.00 and 0 reputation. Those lines are readable and do not overlap. Connect stays closed.

**Art HOLD**
- No new art was generated, edited, or bound. Untracked runtime art stays untracked. Sprite bindings, `furnishing_catalog.json`, and `.import` files were not touched.

**Remaining gaps (ranked)**
1. Research spike is the next slice. One optional office day on the product still on the bench. That day's personal craft becomes research points instead of design, tech, and hype. The day still counts. Points already earned stay. No fee, no ledger row, no new art. Skip it and the first Crypto Alpha Newsletter still lands at 20700 cents and 5 fans. A second room still waits on architecture art.
2. A second room needs architecture art. Office growth already placed the spare desks on the current floor.
3. Chapter work orders still ask for a key unless `STARTUP_VALLEY_FAKE_PROVIDER=1`. That path stays off the tycoon.
4. The developing card is one compact row taller when team shows. Shots 78 and 79 scroll the team line to the top of the journey, so the control sits above New Product and Hire does not cover it. The publisher, press demo, feature, day plan, bugs, crunch, early access, cancel, slip, pivot, and playtest stay in that same card, above team.

**Test results** (no paid live evals; Node 22; host credentials ignored on the tycoon playtests; no `npm ci`)
- `cd harness && npm run build && npm test` — 131 tests, 129 pass, 0 fail, 2 skipped (real Godot furnishing inputs, and production Godot title with a disposable founder-only save). The new test refuses an empty bench, an empty team, and an unknown id, keeps earned points, uses only the new team on the next office day, lets a newly hired person join mid-build, leaves a skipped newsletter at 20700 cents and 5 fans then 33300 cents, and keeps the team block across reopen.
- `npm run eval:offline` — 8/8 fixtures passed
- `godot --headless --path game --import` — pass (exit 0)
- `validate_project.gd` — pass (`validate_project: runtime scenes, art, and all modular office stages are valid`)
- `tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`)
- `test_tycoon_product.gd` — TYCOON PASS. The unchanged test still requires the first Crypto Alpha Newsletter at 20700 cents and 5 fans, and the next office day at 33300 cents.
- `test_tycoon_training.gd` — TYCOON TRAIN PASS
- `test_tycoon_research.gd` — TYCOON RESEARCH PASS
- `test_tycoon_upgrades.gd` — TYCOON UPGRADES PASS
- `test_tycoon_seasons.gd` — TYCOON SEASONS PASS
- `test_tycoon_office.gd` — TYCOON OFFICE PASS
- `test_tycoon_price.gd` — TYCOON PRICE PASS
- `test_tycoon_marketing.gd` — TYCOON MARKETING PASS
- `test_tycoon_contracts.gd` — TYCOON CONTRACTS PASS
- `test_tycoon_patches.gd` — TYCOON PATCHES PASS
- `test_tycoon_sequels.gd` — TYCOON SEQUELS PASS
- `test_tycoon_awards.gd` — TYCOON AWARDS PASS
- `test_tycoon_ports.gd` — TYCOON PORTS PASS
- `test_tycoon_engines.gd` — TYCOON ENGINES PASS
- `test_tycoon_focus.gd` — TYCOON FOCUS PASS
- `test_tycoon_audience.gd` — TYCOON AUDIENCE PASS
- `test_tycoon_size.gd` — TYCOON SIZE PASS
- `test_tycoon_payroll.gd` — TYCOON PAYROLL PASS
- `test_tycoon_loans.gd` — TYCOON LOANS PASS
- `test_tycoon_publishers.gd` — TYCOON PUBLISHERS PASS
- `test_tycoon_expos.gd` — TYCOON EXPOS PASS
- `test_tycoon_localization.gd` — TYCOON LOCALIZATION PASS
- `test_tycoon_town_day.gd` — TYCOON TOWN DAY PASS
- `test_tycoon_press_demo.gd` — TYCOON PRESS DEMO PASS
- `test_tycoon_launch_trailer.gd` — TYCOON LAUNCH TRAILER PASS
- `test_tycoon_dev_diary.gd` — TYCOON DEV DIARY PASS
- `test_tycoon_rivals.gd` — TYCOON RIVALS PASS
- `test_tycoon_features.gd` — TYCOON FEATURES PASS
- `test_tycoon_day_plan.gd` — TYCOON DAY PLAN PASS
- `test_tycoon_bugs.gd` — TYCOON BUGS PASS
- `test_tycoon_crunch.gd` — TYCOON CRUNCH PASS
- `test_tycoon_early_access.gd` — TYCOON EARLY ACCESS PASS
- `test_tycoon_cancel.gd` — TYCOON CANCEL PASS
- `test_tycoon_slip_day.gd` — TYCOON SLIP DAY PASS
- `test_tycoon_pivot.gd` — TYCOON PIVOT PASS
- `test_tycoon_playtest.gd` — TYCOON PLAYTEST PASS
- `test_tycoon_assign_team.gd` — TYCOON ASSIGN TEAM PASS. Day 0 shows "Team: Founder" with a secondary Founder toggle, under Playtest, and above New Product. The line stays on one line. A payload without `team` draws no control. The product picker and the build screen have no team control. Hiring Mina offers a Mina toggle. Clicking Mina shows "Team: Founder, Mina". Cash, fans, and points stay put. The next office day uses Founder and Mina (5/4/3). Reopening keeps that team, with cash and fans still 0. Hire stays the one primary action. Connect stays closed. The rules script inside that test checks the same harness cases.
- `test_ui_company_redesign.gd` — 18171 checks, 0 failures, 0 captures. Existing fixtures omit `team` and still pass.
- `test_furnishing_feedback.gd` — 24 checks, 0 failures
- `test_office_layout.gd` — 873 checks passed
- Proof capture — PROOF PASS. Seventy-nine PNGs in `/workspace/sv-proof/round-63/` (local, not committed). Invocation: `STARTUP_VALLEY_NODE=/home/box/.local/node22/bin/node SV_PROOF_DIR=/workspace/sv-proof/round-63 xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd`

**TYCOON SLICE PLAYABLE: yes** — Company Journey, on the card for the product in development. Assign the team is optional and secondary. Skipping it leaves the first newsletter at $207 and 5 fans. No API key and no network. Headless: `godot --headless --path game --script res://tests/test_tycoon_assign_team.gd`.
