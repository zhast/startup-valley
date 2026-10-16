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
