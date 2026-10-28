# Tycoon design

Startup Valley plays as a small offline tycoon. Whop shows up in the names, the product types, and the jokes. The game does not talk to Whop, and it does not call a model while you ship a product.

The rules in `harness/src/tycoon.ts` are authoritative. This document matches that module. Godot only presents `journey.tycoon`.

## Pillars

1. **Offline.** A new company ships a product with no API key and no network. Providers stay optional, and only on chapter work orders and chat.
2. **The pairing is the decision.** A topic and a product type fit together at Great, Good, Okay, or Bad, in the Game Dev Tycoon way. A bad pairing can still ship. It sells worse.
3. **Days, not a progress bar you click.** Development and sales move when the office day ends. The room stays the cozy Stardew-style office already in the game.
4. **Deterministic.** Reviews and sales are pure functions of the company seed, the product id, the fit, the points, the focus stored on the product, the research bonus stored on the product, the launch price stored on the product, the marketing choice stored on the product, the audience stored on the product, the size stored on the product, whether it was patched, the sequel bonus stored on the product, the engine score bump stored on the product, the shorter day count that follows from the sequel link, the shorter or longer day count that follows from the size, and reputation. Regulars also reads whether a past release used the same topic. A contract bonus is a separate cash line. A patch cost is too. An award fee is too, and its fans are not part of the sales formula. A port fee is a separate cash line. Its one extra sales day uses that same sales formula. An engine fee is a separate cash line, paid once when the engine is bought. They are not extra inputs beyond those. The same save replays the same launch.
5. **One product on the bench.** A second idea waits until the first one ships. A shipped product can still be selling while the next one starts.

## Core loop

1. From Company Journey, choose **New Product**.
2. Pick a topic and a product type. The panel shows the fit.
3. The founder is always on the build. Hired teammates can join.
4. **Start development.** The product stores the fit, the staff snapshot, the research bonus, the launch price, the marketing choice, the engine choice, the focus, the audience, and the size. A paid ad spends game cash here. The engine was already paid when it was bought. The focus spends nothing. The audience spends nothing. The size spends nothing. An accepted contract also stores the client and the bonus.
5. **End day + save** once for each office day of work. The team adds design, tech, and hype. Progress is `dev days / days required`.
6. When the required days are done, **Release**. Four reviewers score it from 1 to 10. Launch-day sales pay game cash and fans immediately. If the product was started under a contract, that release also pays the bonus as its own cash line.
7. The next three office days keep selling, once each, when the day ends. The release day does not sell twice. One optional patch can spend game cash and add 1 to the stored score for those remaining days.
8. The product moves onto the shelf. Cash and reputation (fans) stay on the company. One optional sequel can start from that finished product. One optional award show can spend a little game cash and add fans from the stored score. One optional port can spend a little game cash and pay one extra sales day from the stored score. Ship another.

A newsletter or template pack takes 2 office days. A course, community, or coaching offer takes 3. A software tool takes 4. Those counts are the catalog length. Short takes one fewer office day, and never fewer than one. Long takes one more. Two extra office days can still add a little craft. After that, points stop.

## Topic × type fit

Rows are topics. Columns follow the product types.

| Topic | Course | Community | Template Pack | Coaching | Software Tool | Newsletter |
| --- | --- | --- | --- | --- | --- | --- |
| Fitness | Great | Good | Okay | Great | Bad | Okay |
| Trading | Good | Okay | Great | Good | Good | Great |
| Sneakers | Okay | Great | Good | Okay | Bad | Okay |
| Reselling | Good | Okay | Great | Okay | Okay | Good |
| Sports Betting Picks | Okay | Great | Bad | Good | Okay | Great |
| Cooking | Great | Good | Okay | Great | Bad | Good |
| Gaming | Okay | Great | Good | Okay | Great | Okay |
| Dating Advice | Good | Great | Bad | Great | Okay | Good |
| Study Notes | Great | Okay | Great | Good | Okay | Good |
| Crypto Alpha | Okay | Good | Okay | Good | Great | Great |

Fit changes the score and the opening demand. Great uses 1.12 and 12 base units. Good uses 1.00 and 9. Okay uses 0.84 and 6. Bad uses 0.64 and 3.

The in-game type name for `community` is **Community**. It is the Discord-style group. The title of a product is the topic name plus the type name, for example `Crypto Alpha Newsletter`.

## Points, reviews, sales

Each assigned person adds their current design / tech / hype once per development day. A new company starts from this table:

| Person | Id | Design | Tech | Hype |
| --- | --- | --- | --- | --- |
| Founder | founder | 2 | 2 | 2 |
| Mina | mira | 3 | 2 | 1 |
| Theo | theo | 1 | 2 | 3 |
| Creative | creative | 4 | 1 | 2 |

Those numbers are starting stats. Training raises them. Only hired people can be assigned. The founder is always included. Unhired ids are rejected. Duplicates count once. The product stores the assigned people's stats on the day development starts. Later training does not change that snapshot.

Each type weights those three stats and has a price:

| Type | Days | Price | Design weight | Tech weight | Hype weight |
| --- | --- | --- | --- | --- | --- |
| Course | 3 | $49 | 3 | 1 | 2 |
| Community | 3 | $29 | 2 | 1 | 3 |
| Template Pack | 2 | $19 | 2 | 3 | 1 |
| Coaching | 3 | $79 | 2 | 1 | 2 |
| Software Tool | 4 | $39 | 1 | 3 | 1 |
| Newsletter | 2 | $9 | 1 | 1 | 3 |

The ideal for a stat is `days required × 4`. A sequel's required days are the catalog days minus 1, at least 1, so its ideal shrinks with the shorter build. A short product uses that same shorter count, and a long product uses the catalog days plus 1, so the ideal moves with the size. A sequel ignores size and keeps the sequel count. Matching the ideal is full credit. A little extra holds the credit. A large pile of one stat dulls it. Quality is the weighted blend. Fit scales that quality. A researched topic or type adds 6 to that fit's numerator, up to 12, from the bonus stored when development started. A focus adds 1 to the chosen stat before that quality, and the add stops at 10. Balanced adds nothing. The base score maps the result onto 1–10. A sequel adds its stored score bonus, 0 or 1, to that base. An engine adds its stored score bump, 0 or 1, with that sequel bonus. The sum clamps to 1–10 before the reviewers move it.

Four reviewers then each move that base by −1, 0, or +1. The jitter comes from the company seed and the product id. Scores clamp to 1–10. The headline is the rounded mean, clamped again. Blurbs follow the headline band: 8–10 high, 5–7 mid, 1–4 low. The review is stored on the product, so a later formula change does not rewrite a shipped score.

Reviewers: **Whop Weekly**, **Discord Dave**, **Margin Call Molly**, **Cohort Casey**.

Sales run for 4 days at 100%, 70%, 45%, then 25% of the opening demand. Opening demand is the fit's base units, plus a term from the score, plus a small term from current reputation. A seeded swing of about ±10% lands on each day. Units are at least 1. Cash is units times the unit price. Fans are a fraction of units: 0.4 at score 8+, 0.2 at 5–7, 0.1 below that, and at least 1. Fans add to company reputation. A port does not open a fifth day inside that window. It pays one later day at the same 25% step, and `salesDays` stays 4.

The catalog price is the default. At Start development the player can leave it, or nudge −20% or +20%. A cheaper price sells more units. A higher price sells fewer. The percents are fixed: 80 / 100 / 120 for price, and 120 / 100 / 80 for units. Units after the nudge are `Math.max(1, Math.round((units * unitPercent) / 100))`. The unit price is `Math.round((catalogCents * pricePercent) / 100)`. Catalog (100) leaves both unchanged, so the first newsletter still pays 20700 cents and 5 fans.

The choice is stored on the product, in `staff_json` as `{staff, researchBonus, pricePercent, marketing}`. When the product starts on the engine it also stores `engine` and `engineBonus`. When it starts on Design, Tech, or Hype it also stores `focus` and `focusBonus`. When it starts on Regulars or Newcomers it also stores `audience`. When it starts Short or Long it also stores `size`. A sequel also stores `sequelOf`, and the original stores `sequelId` once that sequel starts. `scoreBonus` is 1 only when the carry applies. `engineBonus` is 1 only when `engine` is set. `focusBonus` is 1 only when `focus` is set. Sales use the stored price. An older row that is only a staff array, or a row with no `pricePercent`, sells at catalog. A row with no `marketing` sells with no ad. A row with no `patched` flag sells unpatched. A row with no sequel fields is not a sequel and has not started one. A row with no `award` field has not entered a show. A row with no `port` field has not been ported. A row with no `engine` field started with no engine. A row with no `focus` field started Balanced. A row with no `audience` field started Everyone. A row with no `size` field started at Catalog length. Stored `sales_cents` are not rewritten. Reads do not rewrite `staff_json`.

Composition, in this order, on every sale that is computed:

1. Base units from fit, the sales score, reputation, the sales curve, and the seeded swing. At least 1. The sales score is the stored review score, plus 1 when the product is patched, capped at 10.
2. Launch-price units.
3. Season +20% units, when the topic is favored that day.
4. Marketing units from the snapshot. None is an identity step. Otherwise `Math.max(1, Math.round((units * unitPercent) / 100))`.
5. Audience units from the snapshot. Everyone and Regulars are identity steps. Newcomers uses 90: `Math.max(1, Math.round((units * 90) / 100))`.
6. Size units from the snapshot. Catalog is an identity step. Short uses 90 and Long uses 110: `Math.max(1, Math.round((units * unitPercent) / 100))`.
7. Fans from those units, then the event fan bonus if an event is on, then the audience fan bonus. Regulars adds 2 fans when a past release used the same topic. Newcomers always adds 2 fans. Everyone adds nothing.
8. Launch price on the catalog cents.
9. Nicer Checkout Page +10% on that unit price, when the tool is already owned.
10. Cash is units times that price.

A checkout-page boost still changes only the price. Season still changes only the units. Launch price changes both, from the snapshot. Newcomers then cuts units. Size then scales those units. Catalog leaves them. Fans use the units after size. Regulars and Newcomers add fans after that.

A new company uses seed `26021`, stored in `tycoon_meta`. Product ids are `p1`, `p2`, and so on.

## Training

From Company Journey, spend game cash to train a hired person, including the founder.

- One lesson raises Design, Tech, or Hype by 1.
- Cost is $150 × the current level of that stat. Founder Tech at 2 costs $300. The same stat at 3 costs $450.
- Each stat caps at 10.
- A person can train once per office day. That day they are in training and add no points to a product being built. They also add no research points that day.
- Short cash, an unhired id, a second lesson the same day, and a stat already at 10 fail with a clear error.
- Older saves without stored stats load the starting table.
- The lesson line ("Founder trained Tech to 3. −$300") shows only on that office day. Ending the day clears it.

A newsletter launch pays about $200, then more on the next sales days, so the first founder lesson is one good launch plus a little leftover.

## Research

Research points unlock topics and product types. The harness owns the catalog, the prices, and the points. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

A company stores `researchPoints` and the unlocked topic ids and type ids. New companies start at 0 points with this starter catalog:

| Kind | Unlocked | Locked |
| --- | --- | --- |
| Topics | Fitness, Trading, Cooking, Gaming, Study Notes, Crypto Alpha | Sneakers, Reselling, Sports Betting Picks, Dating Advice |
| Types | Course, Community, Template Pack, Newsletter | Coaching, Software Tool |

Crypto Alpha × Newsletter stays unlocked so the first ship loop still works. A topic costs 4 research points. A type costs 6. Those prices live in `RESEARCH_COST`.

Earning is deterministic:

- At day end, each person on the product in development who is not in training that day adds 1 point. A polish day still pays the point after craft points stop. Ending the same day twice does not pay twice.
- On release, add `floor(score / 2)`.

`tycoon.research` takes `{kind: "topic"|"type", id}`. Unknown ids, an already unlocked id, and a short balance fail with a clear error and spend nothing. `tycoon.start` rejects a locked topic or type and names it.

A topic or type counts as researched only when the player buys it with `tycoon.research`. Starter topics and types are unlocked, and they are not researched. A legacy save that receives the full catalog for free is not researched either. `research_json` stores that list as `researched: {topics, types}`. `spendResearch` writes it. A save with no `researched` field has nothing researched, and it still loads.

Each researched part the product uses adds 6 to the fit numerator inside `baseScore`. The bonus is 0, 6, or 12. Development stores it on the product, in `staff_json` as `{staff, researchBonus}`. Reviews use the stored number. Later research does not change a product already on the bench. An older row that is only a staff array scores as 0. Crypto Alpha × Newsletter stays at 0, so the first launch is still $207 and 5 fans.

The New Product picker shows "Research bonus: +6 fit" on the chosen pair when that bonus is above 0, and nothing when it is 0. Company Journey names that product above New Product, for example "Sneakers Newsletter · Research bonus +6 fit", on the product in development, or on the latest released product when nothing is on the bench. The product progress line and the shipped-history line stay "Research bonus +6 fit". Hire stays the one primary action.

The same picker lists Price under the fit line: three secondary buttons (−20%, Catalog, +20%) and one line for the chosen step, for example "$9.00 · catalog units" or "$7.20 · +20% units". Catalog starts selected. The bench, the release card, and the shipped-history list repeat that line. Price buttons stay secondary. Start development stays the primary action on that screen.

Older saves that predate the research column load with every topic and type unlocked and 0 points, so an existing company does not lose a pairing. Those free unlocks are not researched. A fresh database gets the starter catalog. Reopening a save does not reset progress. The unlock line ("Unlocked Sneakers. −4 RP") shows only on that office day.

Company Journey lists locked items on a Research card under New Product: the balance, the day's unlock line, and one secondary button per locked item ("Research Sneakers · 4 RP"). The button is disabled when the balance is short. The card hides once everything is unlocked. The product picker still lists locked choices, disabled, with "· locked". The release screen shows "+N research points".

## Upgrades

Spend game cash on office tools. Each tool is bought once and has one effect. The harness owns the catalog, the prices, and the effects. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential. This is not a real-money store.

A company stores owned ids in `tycoon_meta.upgrades_json` (migration `012_tycoon_upgrades.sql`, `TEXT NOT NULL DEFAULT ''`). Each saved row is `{id, day}`. An empty string, corrupt JSON, a duplicate, or an unknown id loads as no upgrade. Older saves that predate the column load with none owned. Reopening a save keeps what was bought.

| Id | Name | Price | Effect |
| --- | --- | --- | --- |
| `standing_desk` | Oak Standing Desk | $250 | +1 design per person per dev day |
| `second_monitor` | Second Monitor | $360 | +1 tech per person per dev day |
| `ring_light` | Ring Light | $400 | +1 hype per person per dev day |
| `checkout_page` | Nicer Checkout Page | $560 | +10% price on later sales |

Blurbs, in the same order: "Sketches land cleaner when you stand." "The build on one screen, the notes on the other." "Launch clips look like a real shop." "The buy button finally looks finished."

`tycoon.buyUpgrade` takes `{id}`. An unknown id, a tool already in the office, and short cash fail with a clear error and spend nothing. A buy deducts the price and records the purchase day. The line "Bought Ring Light. −$400" shows only on that office day. Ending the day clears it. Ownership stays.

An effect applies when the tool is already owned at the moment the tick or the sale is computed. Buy, then end that same day, and that `day.end` tick includes the boost. Days whose ticks already ran are not rewritten. Stored reviews, stored `sales_cents`, and the product's start-day staff snapshot stay as they were.

- A point tool adds +1 of that stat for each person on the product who is not in training that day. Someone in training adds no personal points and no office bonus. The bonus stops on extra polish days, when craft points stop. Research points are unchanged.
- Nicer Checkout Page raises the unit price by 10% on every sale computed after the purchase: `Math.round((priceCents * 110) / 100)`. That `priceCents` is the launch price already on the product, so a catalog $9 newsletter becomes $9.90, and a −20% newsletter becomes $7.92. Units and fans stay on the unboosted-by-checkout formula. Launch-price units, the season boost, and marketing have already run.

Oak Standing Desk is the first tool one Crypto Alpha Newsletter can pay for. Launch is about $207. The second sales day reaches $333. Ring Light fits the third sales day ($414). Nicer Checkout Page ($560) waits for a second product. One newsletter cannot pay for both the first Tech lesson ($300) and a tool.

Company Journey lists an Upgrades card under Research. It shows the heading, one line per owned tool ("Ring Light · +1 hype per person per dev day"), the day's purchase line, and one secondary button per unowned tool ("Buy Ring Light · $400"). Owned tools hide their button. A button is disabled when cash is short. Hire stays the one primary action. The build screen can add "Office bonus · …" for owned point tools. The release screen shows the price effect when the checkout tool is owned.

## Office growth

A bigger office, inside the room that already exists. There is no second-room architecture art, so this slice does not add a room. It adds spare desks on the current floor. A second room is a later art ask.

The harness owns the levels, the price, the hire gate, the desk counts, and the dev bonus. Godot only shows `journey.tycoon.office` and places furniture the harness has granted. Nothing on this path calls a model, the network, or a credential.

`tycoon_meta.office_level` (migration `013_tycoon_office.sql`, `INTEGER NOT NULL DEFAULT 1`) stores the level. An older save loads at level 1. An unknown stored level also reads as level 1. Reopening a save keeps the level that was bought.

| Level | Name | Desks | Cost | Gate | Dev bonus |
| --- | --- | --- | --- | --- | --- |
| 1 | Garage Loft | 4 | start | — | none |
| 2 | Open Floor | 7 | $600 | 2 hires besides the founder | +1 design and +1 tech per accruing dev day, once for the whole team |

Blurbs: "A checkout link and one desk by the garage door." and "Spare desks for the next drop."

Desk capacity is informational. `desks.used` is 1 (the founder, who is not an employees row) plus hired people. `desks.total` is 4 at level 1 and 7 at level 2. The story hires stay on chapter milestones. Mina, Theo, and Creative are not blocked when the count is full. The card says "Desks: 1/4" at the start and "Desks: 3/7" after Mina, Theo, and the expansion.

`tycoon.expandOffice` takes `{}`. The harness checks the hire gate before cash, so the error stays stable. Already at the Open Floor: "The office is already as large as it gets." Fewer than 2 hires: "Hire 2 people before the Open Floor." Short cash: "Not enough game cash. Open Floor costs $600." A success deducts $600, sets level 2, and grants the spare desks. Buying again fails and spends nothing.

The bonus is flat. It is not multiplied by headcount. It applies only while craft points still accrue and at least one assigned person is not in training. It stacks with the per-person upgrade bonuses. It does not apply at level 1, on polish days after the craft window, or when the whole assigned team is in training. It does not rewrite stored points or research points. A founder day at level 1 is still 2/2/2. The same day at level 2 is 3/3/2.

`journey.tycoon.office` is `{level, name, blurb, desks: {used, total}, next}`. `next` is `{name, costCents, requiredHires, enabled, reason}` or null at the max level. The locked reasons on the card are "Hire 2 people first." and "Need $600 game cash." An enabled expansion has an empty reason.

Company Journey lists an Office card under Upgrades and above Season. It shows the heading, the office name, the blurb, "Desks: used/total", and, until the max level, "Open Floor · $600" plus one secondary button, "Expand office". The button is disabled while `next.enabled` is false. At the Open Floor the next line and the button are gone. Hire stays the one primary action. A journey payload without `office` leaves the card out, so older UI fixtures still render.

The three spare desks are props already in `office_layout.json`, gated by `required_office_level: 2`, facing south:

| Id | Kind | Grid |
| --- | --- | --- |
| `spare-compact-a` | `compact_desk` | [20, 17] |
| `spare-compact-b` | `compact_desk` | [25, 17] |
| `spare-workbench` | `shared_workbench` | [23, 14] |

They use the bound compact desk and shared workbench art. No new art and no separate chairs. The real game is furnishing-bound, so a layout gate alone does not draw them. `FurnishingStore.sync` grants them only when `office_level` is at least 2, as essential items with grant id `office-level:2`. That is separate from the starter decor ids `decor-compact_desk` and `decor-shared_workbench`, which stay in storage. The grant raises the furnishing inventory cap from 36 to 39 (9 story stations, 27 starter decorations, 3 spare desks). Placement slots stay capped at 32. Level 1 still hides the desks, including at hire stage 4, so the old hire-stage prop counts stay 1, 5, 9, and 10.

## Day and season calendar

The office day clock is unchanged. Work is 08:00–12:30 and 13:30–17:30. Lunch is 12:30–13:30. Ending the day saves, writes the summary, and advances the tycoon by one day. The next morning is 08:00. The ledger still shows that day as a number.

The season is a pure function of the saved day. There is no second clock and no new column. Day 1 is Spring 1, Year 1. A season is 28 office days. A year is 112 days. Day 29 is Summer 1. Day 112 is Winter 28, Year 1. Day 113 is Spring 1, Year 2. The label is `Spring 3 · Year 1`.

| Season | Office days | Favored topics |
| --- | --- | --- |
| Spring | 1–28 | Fitness, Dating Advice |
| Summer | 29–56 | Sneakers, Sports Betting Picks |
| Fall | 57–84 | Study Notes, Trading |
| Winter | 85–112 | Cooking, Gaming |

A product whose topic is favored sells 20 percent more units on each sale computed that season: `Math.max(1, Math.round((units * 120) / 100))`. That `units` value already includes the launch-price unit effect. Marketing, when the product bought an ad, runs after this step. Audience units run after marketing. Size units run after audience. Fans are computed from the units after that, then the audience fan bonus. Cents are the final units times the price. A checkout-page price boost still changes only the price. Stored reviews and earlier sales are not rewritten. A topic outside the pair uses the old formula. Crypto Alpha is not favored in Spring, so the first newsletter's cash is unchanged.

One cozy event per season, on a fixed day. The effect lasts that day only. Names stay inside the simulation.

| Season | Day | Name | Blurb |
| --- | --- | --- | --- |
| Spring | 13 | Creator Fair | The floor is full of shops and first buyers. |
| Summer | 11 | Drop Day | Everyone refreshes the page at the same minute. |
| Fall | 16 | Cohort Kickoff | A new class shows up with notebooks open. |
| Winter | 25 | Cozy Gift Guide | Whop Weekly lists the warm shops. |

Each event adds 2 fans to any product that sells that day. The line is "+2 fans on sales today". Units, price, and the stored review do not change. If nothing sells, the event still shows and adds no fans. The next event is the next one after today. After Winter 25 it wraps to Creator Fair in the following year. `daysUntil` is at least 1.

`journey.tycoon.calendar` carries `season`, `seasonName`, `dayOfSeason`, `year`, `label`, `favoredTopics` (`{id, name}`), `event` (or null), and `nextEvent` (the event fields plus `season`, `dayOfSeason`, and `daysUntil`). The day summary stores `dateLabel` for the day that just ended, so the complete screen does not jump to the next morning. Older summaries without that field still load.

Company Journey shows the label on the heading ("Spring 2 · Year 1 · $0.00 game cash · 0 reputation"). The title continue line and the day complete screen use the same words. A Season card sits under Office: "In season: Fitness, Dating Advice", and either "Creator Fair today. +2 fans on sales today" or "Creator Fair in 11 days". The same card names the next payday. With no hires that line is "No payroll yet". The product picker adds "· in season" on a favored topic, including a locked one. Hire stays the one primary action. No new button.

## Whop-themed names

Topics: Fitness, Trading, Sneakers, Reselling, Sports Betting Picks, Cooking, Gaming, Dating Advice, Study Notes, Crypto Alpha.

Product types: Course, Community, Template Pack, Coaching, Software Tool, Newsletter.

Team: Founder, Mina, Theo, Creative.

Press: Whop Weekly, Discord Dave, Margin Call Molly, Cohort Casey.

Shelf jokes stay in the reviewer blurbs (checkout links, lurkers, margins, welcome modules). They are not a second product catalog.

## Launch price

The catalog type price stays the default. `tycoon.start` takes an optional `pricePercent` of 80, 100, or 120. Omitted is 100. Anything else fails with "Pick −20%, catalog, or +20%." and starts nothing.

`journey.tycoon.priceSteps` is the three rows. Each product carries `pricePercent` and `priceCents` (the chosen unit price, before checkout). The New Product picker shows them as secondary buttons plus the unit-effect line. A payload without `priceSteps` leaves the control out, so older UI fixtures still render.

## Marketing

No ad is the default. `tycoon.start` takes an optional `marketing` of `none`, `small`, or `big`. Omitted is `none`. Anything else fails with "Pick None, Small ad, or Big ad." and starts nothing. There is no new SQL column. The id is stored on the product snapshot.

| Id | Label | Cost | Units |
| --- | --- | --- | --- |
| `none` | None | $0 | unchanged |
| `small` | Small ad | $50 | +20% |
| `big` | Big ad | $150 | +50% |

The small ad is a Whop Weekly spot. The big ad is the louder buy. The cost is game cash, paid when development starts. Short cash fails with "Need $50" or "Need $150", starts nothing, and charges nothing. The unit boost uses the percents 100 / 120 / 150: `Math.max(1, Math.round((units * unitPercent) / 100))`. None leaves units unchanged, so the first newsletter still pays 20700 cents and 5 fans. Fans follow those units. The boost applies on every day of that product's sales window.

The choice is stored in `staff_json` next to `pricePercent` and `researchBonus`. Sales use the stored id. An older row that is only a staff array, or a row with no `marketing`, sells with no ad. Stored `sales_cents` are not rewritten.

Marketing is step 4 of the sale composition above. It runs after launch-price units and the season boost, and before audience units, size units, and fans. It does not change the unit price. Checkout still changes only the price. The spend is the cash paid at the start, not a cut of later sales.

`journey.tycoon.marketingOptions` is the three rows, each with `enabled` and `reason`. The New Product picker shows them under Price as secondary buttons, plus one line, for example "None · $0 · no extra units" or "Small ad · $50 · +20% units". A disabled button reads "Small ad · Need $50". The bench, the release card, and the shipped list repeat that line when an ad was bought. Hire stays the one primary action. A payload without `marketingOptions` leaves the control out, so older UI fixtures still render.

## Contracts

One client offer at a time, on Company Journey. The offer is `contractBySlot(seed, completed)`. `completed` is how many shipped products stored a contract. The office day is not in that formula, so the card does not change overnight. Ignoring the offer leaves it in place. Releasing a contracted product advances the slot immediately. The next offer does not wait out the four-day sales window.

Every pair is in the starter catalog. There is no minimum review score. The bonus always pays once, on release.

| Id | Client | Topic | Type | Bonus |
| --- | --- | --- | --- | --- |
| `nova` | Nova on Whop | Crypto Alpha | Newsletter | $80 |
| `remy` | Remy on Whop | Fitness | Course | $120 |
| `juniper` | Juniper on Whop | Cooking | Newsletter | $70 |
| `pax` | Pax on Whop | Gaming | Community | $100 |
| `kit` | Kit on Whop | Study Notes | Template Pack | $60 |
| `lane` | Lane on Whop | Trading | Newsletter | $90 |

Accept only while the bench is empty. Otherwise the card says "Ship the product on the bench first." and Accept stays disabled. A second accept fails with "A contract is already accepted." The pending accept is `{"id":"..."}` in `tycoon_meta.contract_json` (migration `014_tycoon_contracts.sql`). Empty or unknown means no pending accept.

The next product must use that topic and type. A different pair fails with "This contract is Topic × Type.", starts nothing, and charges no ad. The picker locks to the pair. Other unlocked topics and types are disabled and read "· contract". A research lock still reads "· locked". On a matching start, the product snapshot gains `contract: {id, client, bonusCents}` and the pending accept is cleared. The card then says "On the bench."

On release, one ledger row is written: id `tycoon:contract:<productId>`, cash and earned equal the bonus, reputation 0, label `Contract: <client>`. Sales units, price, fans, and `sales_cents` stay on the old formula. A later sales day does not pay the bonus again. Releasing twice fails because the product already shipped.

No contract is the default. A product started while the offer is ignored stores no `contract` key. An older row that is only a staff array, or that omits the field, pays nothing and is not rewritten. An unknown id pays nothing. A known id with a non-positive stored bonus uses the catalog bonus. A blank client uses the catalog client. Reads do not rewrite `staff_json`.

`journey.tycoon.contract` is always present: `id`, `client`, `topicId`, `typeId`, `topicName`, `typeName`, `bonusCents`, `status` (`offered`, `accepted`, or `building`), `enabled`, and `reason`. Each product carries `contract` as null or `{client, bonusCents}`. A payload without `tycoon.contract` draws no card and leaves the picker free, so older UI fixtures still render.

The Company Journey card is headed "Contract". The lines are the client, "Topic × Type", and "Bonus $80 on release" in whole dollars. Accept contract is a secondary button, and only while the status is `offered`. Hire stays the one primary action. The bench, the release card, and the shipped list show "Contract: Client · +$80" when the product has a contract.

## Patches

One optional patch per shipped product, while it still has remaining sales days. No patch is the default. The harness owns the cost, the score bump, and the refusals. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

`tycoon.patch` takes `{productId}`. Cost is $100. The bump is +1 on the stored review score, capped at 10, and only for sales computed after the patch. Launch sales and any earlier sales day stay as they were. Stored `sales_cents` are not rewritten.

The flag is `patched: true` on the product snapshot in `staff_json`. There is no new SQL column. An older row that is only a staff array, or a row that omits the field, is unpatched. Reads do not rewrite `staff_json`. A successful patch writes the flag and one ledger row: id `tycoon:patch:<productId>`, cash −$100, earned 0, reputation 0, label `Patch: <product>`. Patching twice fails with "Already patched." and charges nothing.

Short cash, a product still on the bench, sales that have ended, and a second patch fail with a clear error and spend nothing. The locked reasons are "Need $100", "Ship this product first.", "Sales have ended.", and "Already patched." A missing id fails with "No product with that id."

The first Crypto Alpha Newsletter still pays 20700 cents and 5 fans when left unpatched. $100 is less than the first Tech lesson and less than Oak Standing Desk, so one newsletter launch can pay for a patch and still have cash left.

`journey.tycoon.patchNotice` is the day's line, "Patched Crypto Alpha Newsletter. −$100". Ending the day clears it. Each shipped product carries `patch` as null on the bench, or `{costCents, scoreBonus, applied, enabled, reason}` after release. A payload without `patch` on a product draws no button, so older UI fixtures still render.

Company Journey shows one Selling card per product that is still selling. The lines are the name, score, cash, fans, and "Sales day 1 of 4". Patch · $100 is a secondary button. A disabled button reads the reason, for example "Patch · Need $100" or "Patch · Already patched." Hire stays the one primary action. After a patch the card adds "Patched · +1 score" and the cost line. The shipped list repeats "Patched · +1 score" when the flag is set.

## Sequels

One optional sequel per finished product. No sequel is the default. The harness owns the day cut, the score carry, and the refusals. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

`tycoon.sequel` takes `{productId}`. It starts development immediately. The sequel keeps the original topic and type. The name is the original name plus " 2". The price is catalog. There is no ad. The start spends no cash.

The crew is the founder plus anyone from the original snapshot who is still hired. Stats are snapshotted today. The research bonus is whatever is researched for that pair today. One product stays on the bench. An accepted contract for a different pair blocks the sequel with "This contract is Topic × Type." and starts nothing. A matching contract is copied onto the sequel and cleared, the same way a normal start consumes it.

Build days are the format's days minus 1, at least 1. A newsletter sequel takes 1 office day. The ideal for a stat stays `days required × 4`, so the shorter build is not a quality penalty.

The score carry is +1 on the base score, before reviewers move it, when the original's final score is 6 or more. Final score is the stored review, plus 1 if that product was patched, capped at 10. The carry is stored as `scoreBonus` on the sequel. It is 0 when the original finished under 6. The bonus is added, then the base is clamped to 1–10. Reviewers still jitter from the new product id.

The fields live on the product snapshot in `staff_json`: `sequelOf` on the sequel, `sequelId` on the original, and `scoreBonus` when it is 1. There is no new SQL column. An older row that is only a staff array, or a row that omits the fields, is not a sequel and has not started one. Reads do not rewrite `staff_json`.

A sequel can start only when the original has finished its sales days, it is not itself a sequel, it has no sequel yet, the bench is empty, and any accepted contract matches. The locked reasons are "Still selling.", "Already has a sequel.", "This is a sequel.", "Ship this product first.", "Ship the product on the bench first.", and "This contract is Topic × Type." A missing id fails with "No product with that id."

The first Crypto Alpha Newsletter still pays 20700 cents and 5 fans when left without a sequel. That newsletter scores 6, so its sequel stores a carry of 1 and takes 1 office day.

Each product carries `sequel` as null while it is on the bench and is not itself a sequel, or `{scoreBonus, savedDays, isSequel, started, enabled, reason}` after that. `savedDays` is 1. `scoreBonus` is the bonus stored on that product. A payload without `sequel` draws no button, so older UI fixtures still render.

Company Journey shows one Shipped card per product whose sales have finished. The lines are the name, score, cash, fans, and "Sales finished." Sequel is a secondary button. A selling card shows the same button after Patch, disabled, for example "Sequel · Still selling." A disabled button reads the reason. Hire stays the one primary action. The build screen shows "Building · day 0 of 1" for a newsletter sequel, and "Sequel · +1 score" when the carry is 1. The release card and the shipped list repeat that score line.

## Awards

One optional award show per finished product. No entry is the default. The harness owns the fee, the result, and the refusals. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

The show is **Whop Creator Awards**. `tycoon.award` takes `{productId}`. The fee is $40. The result comes from the stored review score, not the patched sales score. 8–10 wins and adds 12 fans. 5–7 is a nominee and adds 4 fans. 1–4 is entered and adds no fans. Sales units, price, fans, and `sales_cents` stay on the old formula.

The entry is `award: {outcome, fans}` on the product snapshot in `staff_json`. `outcome` is `won`, `nominated`, or `entered`. There is no new SQL column. An older row that is only a staff array, or a row that omits the field, has not entered. Reads do not rewrite `staff_json`. A successful entry writes the field and one ledger row: id `tycoon:award:<productId>`, cash −$40, earned 0, reputation equal to the fan bonus, label `Award: Whop Creator Awards`. Entering twice fails with "Already entered." and charges nothing. Fans add once.

A product still on the bench, a product that is still selling, short cash, and a second entry fail with a clear error and spend nothing. The locked reasons are "Ship this product first.", "Still selling.", "Need $40", and "Already entered." A missing id fails with "No product with that id."

The first Crypto Alpha Newsletter still pays 20700 cents and 5 fans when it skips the show. That newsletter scores 6, so entering after sales finish is a nominee and adds 4 fans. The fee waits until sales have finished, so the launch cash and fans do not change.

Each shipped product carries `award` as null on the bench, or `{show, costCents, outcome, fans, entered, enabled, reason}` after release. `show` is Whop Creator Awards. `costCents` is 4000. `outcome` is empty until the product enters. A payload without `award` draws no button, so older UI fixtures still render.

Company Journey shows one Shipped card per product whose sales have finished. The card names the show and the fee, "Whop Creator Awards · $40". Enter award is a secondary button. A selling card shows the same button after Sequel, disabled, for example "Enter award · Still selling." A disabled button reads the reason, for example "Enter award · Need $40" or "Enter award · Already entered." Hire stays the one primary action. After entry the card adds "Award · Won · +12 fans", "Award · Nominated · +4 fans", or "Award · Entered". The shipped list repeats that line.

## Ports

One optional port per finished product. No port is the default. The harness owns the fee, the extra sales day, and the refusals. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

The shelf is **Whop Mobile**. `tycoon.port` takes `{productId}`. The fee is $80. The port pays exactly one extra sales day on the next day end, then it is done. That day uses the stored score after a patch, the same per-day formula as a normal sale, and the last curve step (25%). The seeded swing uses that extra index, so the day is not a copy of the fourth sales day. `salesDays` stays 4. The payout is added to `sales_cents` and to the product's fans. Price, marketing, season, audience, size, event fans, reputation, and the checkout boost all apply as they do on a normal sales day.

The field is `port: {shelf, startedDay}` on the product snapshot in `staff_json` while it is selling, and `port: {shelf, startedDay, cents, fans}` after it pays. `shelf` is Whop Mobile. There is no new SQL column. An older row that is only a staff array, or a row that omits the field, has not been ported. Reads do not rewrite `staff_json`. A successful port writes the field and one ledger row for the fee: id `tycoon:port:<productId>`, cash −$80, earned 0, reputation 0, label `Port: Whop Mobile`. The extra sale is a normal sales row: id `tycoon:<productId>:4`, cash and earned equal to that day's cents, reputation equal to that day's fans, label `Sales · <product>`. Fans add once, on that sales row. Porting twice fails with "Already ported." and charges nothing.

A product still on the bench, a product that is still selling, short cash, a second port, and a port while another port is still unpaid fail with a clear error and spend nothing. The locked reasons are "Ship this product first.", "Still selling.", "Need $80", "Already ported.", and "Another port is still selling." A missing id fails with "No product with that id." Only one port can be selling at a time. After it pays, another finished product can port.

The first Crypto Alpha Newsletter still pays 20700 cents and 5 fans when it skips the port. The fee waits until sales have finished, so the launch cash and fans do not change.

Each shipped product carries `port` as null on the bench, or `{shelf, costCents, phase, cents, fans, enabled, reason}` after release. `shelf` is Whop Mobile. `costCents` is 8000. `phase` is empty until the port starts, `selling` until the next day end, then `sold`. A payload without `port` draws no button, so older UI fixtures still render.

Company Journey shows one Shipped card per product whose sales have finished. The card names the shelf and the fee, "Whop Mobile · $80". Port is a secondary button. A selling card shows the same button, disabled, for example "Port · Still selling." A disabled button reads the reason, for example "Port · Need $80", "Port · Already ported.", or "Port · Another port is still selling." After the port starts the card adds "Port · Whop Mobile · selling 1 day". After the extra day it reads "Port · Whop Mobile · $X", where X is that day's cash. The shipped list repeats that line.

Sequel, Enter award, and Port share one row on the card. Patch stays on its own line while the product is selling. Hire Mina stays the one primary action in the footer. That row is what keeps the orange Hire button from sitting on top of a stack of secondary buttons.

## Engines

One optional in-house engine. No engine is the default. The harness owns the price, the score bump, and the refusals. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

The engine is **Whop Kit Engine**. `tycoon.buyEngine` takes `{id}` and the only id is `whop_kit`. The price is $120. It is bought once for the company. A product can then start on it. The bump is +1 to the base score, added with the sequel bonus, then the score clamps to 1–10. Sales still use the stored review score. The engine is not a new input to the per-day sales formula.

Ownership is `engine_id` on `tycoon_meta`. Empty means not owned. The product snapshot in `staff_json` stores `engine` and `engineBonus` only when that product starts on the engine. `engine` is `whop_kit`. `engineBonus` is 1. An older row that is only a staff array, or a row that omits the fields, started with no engine. Reads do not rewrite `staff_json`. A sequel stores no engine, so its score stays on the sequel rules. The buy is one ledger row: id `tycoon:engine`, cash −$120, earned 0, reputation 0, label `Engine: Whop Kit Engine`. Buying twice fails with "Already owned." and charges nothing. An unknown id fails with "Unknown engine." Short cash fails with "Need $120".

Starting on the engine before it is owned fails with "Buy the engine first." and does not charge a marketing ad. Any other id fails with "Pick None or Whop Kit Engine." The fee is paid at the buy, not again at Start development.

The first Crypto Alpha Newsletter still pays 20700 cents and 5 fans when it starts with no engine. That newsletter scores 6. The same build on the engine scores 7 before the 1–10 cap. A score that is already 10 stays 10.

`journey.tycoon.engine` is `{id, name, blurb, priceCents, scoreBonus, owned, enabled, reason}`. `priceCents` is 12000. `scoreBonus` is 1. The blurb is "One kit, used on the builds you choose." `engineOptions` is None, then Whop Kit Engine. None is always enabled and adds no bump. The kit is enabled only when it is owned. Otherwise its reason is "Buy it first." The buy button is enabled only when the company can pay and does not already own it. The reasons are "Need $120" and "Already owned."

Company Journey shows an Engine card under Upgrades. The price line is "Whop Kit Engine · $120". Buy is a secondary button. After the buy the notice reads "Bought Whop Kit Engine. −$120" until the day ends, and the button reads "Buy Whop Kit Engine · Already owned." Hire stays the one primary action.

Once the engine is owned, the New Product picker offers Engine under marketing, with the same choice-row pattern. The default is None. The effect line reads "None · no score bump" or "Whop Kit Engine · +1 score". The build line reads "On the build" or "On the build · Whop Kit Engine". A product on the engine shows "On the build · Whop Kit Engine · +1 score" on the journey, the build screen, the release card, and the shipped list. The picker stays hidden until the engine is owned, so a new company still starts the first newsletter with no engine. A payload without `engine` draws no card and no picker, so older UI fixtures still render.

## Focus

One optional focus when a product starts. Balanced is the default. The harness owns the bump and the refusal. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

`tycoon.start` takes an optional `focus`: `balanced`, `design`, `tech`, or `hype`. Omitted is Balanced. Any other value fails with "Pick Balanced, Design, Tech, or Hype." and starts nothing. The choice spends no cash. A bad id does not charge a marketing ad.

| Focus | Stored bump |
| --- | --- |
| Balanced | none |
| Design | +1 design |
| Tech | +1 tech |
| Hype | +1 hype |

The bump is added when the review is scored and when the point line is shown. It is not added again on each office day. The office-day columns stay the days' work. The add stops at 10. A stat already at 10 or above stays where the office days left it, and a 9 becomes 10. The review still clamps to 1–10. The line still names the stored +1 when the cap ate the add. A stored `focusBonus` other than 1 is ignored, and the bump stays 1. Reads do not rewrite `staff_json`.

Balanced adds nothing, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans and scores 6. The same build on Hype scores 7, and that launch pays 21600 cents and 5 fans. Design or Tech keeps the score at 6, so that launch stays 20700 cents and 5 fans.

The fields are `focus` and `focusBonus` on the product snapshot in `staff_json`. There is no new SQL column. `focus` is `design`, `tech`, or `hype`. `focusBonus` is 1. Balanced omits both keys. An older row that is only a staff array, or a row that omits the fields, is Balanced. A sequel stores no focus.

`journey.tycoon.focusOptions` is the four rows: Balanced, Design, Tech, and Hype. Each product's `focus` is null, or `{id, label, stat, bonus}` with `bonus` 1.

The New Product picker offers Focus under the engine row, with the same choice-row pattern. The effect line reads "Balanced · no point bump" or "Design · +1 design". The shared build line reads "On the build", "On the build · Design", or "On the build · Whop Kit Engine · Design" when an engine is chosen too. A focused product shows "On the build · Design · +1 design" on the journey, the build screen, the release card, and the shipped list. Hire stays the one primary action. Start development stays the primary on the picker. A payload without `focusOptions` leaves the control out, so older UI fixtures still render.

## Audience

One optional audience when a product starts. Everyone is the default. The harness owns the fan bump, the Newcomers unit cut, and the refusal. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

`tycoon.start` takes an optional `audience`: `everyone`, `regulars`, or `newcomers`. Omitted is Everyone. Any other value fails with "Pick Everyone, Regulars, or Newcomers." and starts nothing. The choice spends no cash. A bad id does not charge a marketing ad.

| Audience | Stored rule |
| --- | --- |
| Everyone | none |
| Regulars | +2 fans on a sale when a past release used the same topic |
| Newcomers | +2 fans, and 90% units |

The bump is added when the sale is computed. Regulars looks at other products that have already shipped, not at this one. A first-of-topic Regulars product stores the lean and still pays the old cash and fans. Newcomers always applies the unit cut and the fan bump. Units use `Math.max(1, Math.round((units * 90) / 100))`. Everyone adds nothing, so the first Crypto Alpha Newsletter still pays 20700 cents and 5 fans.

The field is `audience` on the product snapshot in `staff_json`. There is no new SQL column. `audience` is `regulars` or `newcomers`. Everyone omits the key. An older row that is only a staff array, or a row that omits the field, is Everyone. A sequel stores no audience. Reads do not rewrite `staff_json`.

Audience is step 5 of the sale composition above. Newcomers units run after marketing. Size units run after that. Audience fans run after the unit fans and the event bonus. Regulars does not change units. Checkout still changes only the price.

`journey.tycoon.audienceOptions` is the three rows: Everyone, Regulars, and Newcomers. Each product's `audience` is null, or `{id, label, fans, unitPercent}` with `fans` 2.

The New Product picker offers Audience under the focus row, with the same choice-row pattern, three buttons on one compact row. The effect line reads "Everyone · no fan bump", "Regulars · +2 fans on a repeated topic", or "Newcomers · +2 fans · −10% units". The shared build line reads "On the build" or "On the build · Regulars". A non-Everyone product shows "On the build · Regulars" on the journey, the build screen, the release card, and the shipped list. Hire stays the one primary action. Start development stays the primary on the picker. A payload without `audienceOptions` leaves the control out, so older UI fixtures still render.

## Size

One optional length when a product starts. Catalog is the default. The harness owns the day change, the unit change, and the refusal. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

`tycoon.start` takes an optional `size`: `catalog`, `short`, or `long`. Omitted is Catalog. Any other value fails with "Pick Catalog, Short, or Long." and starts nothing. The choice spends no cash. A bad id does not charge a marketing ad.

| Size | Days | Units |
| --- | --- | --- |
| Catalog | catalog days | 100% |
| Short | catalog days − 1, at least 1 | 90% |
| Long | catalog days + 1 | 110% |

Short and Long change the days required. The ideal is still `days required × 4`, so it shrinks or grows with that length. Working every required day with the same team keeps the same stat ratios, so the review score stays the catalog score. The sales difference is the unit percent. Units use `Math.max(1, Math.round((units * unitPercent) / 100))`. Catalog is an identity step, so the first Crypto Alpha Newsletter still takes 2 office days, still scores 6, and still pays 20700 cents and 5 fans. That same build on Short takes 1 day and pays 18900 cents and 4 fans. On Long it takes 3 days and pays 22500 cents and 5 fans.

The field is `size` on the product snapshot in `staff_json`. There is no new SQL column. `size` is `short` or `long`. Catalog omits the key. An older row that is only a staff array, or a row that omits the field, is Catalog. A sequel stores no size, so its days stay on the sequel rule. Reads do not rewrite `staff_json`.

Size is step 6 of the sale composition above. It runs after audience units and before fans. Catalog does not change units. Checkout still changes only the price. A port's extra day uses the same step.

`journey.tycoon.sizeOptions` is the three rows: Catalog, Short, and Long. Each product's `size` is null, or `{id, label, dayDelta, unitPercent}`. `dayDelta` is −1 or 1. `unitPercent` is 90 or 110.

The New Product picker offers Size under the audience row, with the same choice-row pattern, three buttons on one compact row. The effect line reads "Catalog · same length", "Short · −1 day · −10% units", or "Long · +1 day · +10% units". The shared build line reads "On the build" or "On the build · Long". A non-Catalog product shows "On the build · Long" on the journey, the build screen, the release card, and the shipped list. Hire stays the one primary action. Start development stays the primary on the picker. A payload without `sizeOptions` leaves the control out, so older UI fixtures still render.

## Payroll

Hired staff draw a salary. The founder does not. The harness owns the amount, the payday, and the ledger row. Godot only shows `journey.tycoon`. Nothing on this path calls a model, the network, or a credential.

Each season is one payday, on the last office day of that season (day 28, 56, 84, 112, and the same days in later years). Pay runs at the end of that day, after that day's sales. One ledger row covers the whole team. The id is `tycoon:payroll:<year>-<season>`, for example `tycoon:payroll:1-spring`. The label is `Payroll: Spring`. Replaying that day end, or opening the save again, finds the id and does not pay a second time. A season with nobody hired writes no row.

| Person | Season salary | Why |
| --- | --- | --- |
| Founder | $0 | The founder is not on the payroll. |
| Mina | $80 | Under the $207 first newsletter, and over the $50 small ad. |
| Theo | $100 | The same as a patch. |
| Creative | $120 | The same as the engine. |

All three together are $300, the same as the first Tech lesson, once a season. A mid-Spring company has a few thousand dollars, so a full team is real pressure and still payable. A company at $0 with only Mina ends the season at −$80.

Cash may go below zero. The company row no longer rejects a negative `cash_cents`. There is no game over. The header then reads "−$80.00 game cash · cash is negative", and the Season card adds "Cash is negative". A positive balance keeps the old words, including "$0.00 game cash". Spending that already says "Need $X" or "Not enough game cash" stays locked while cash is short. A later sale, and a $0 build row, still post.

The morning after payday shows "Paid payroll · −$80" on the day-end summary and on the Season card. That notice clears when the next office day ends. It lives in memory, so a reopen keeps the cash and the ledger row and drops the notice.

The Season card line is "Payroll · $80 on Spring 28", or "No payroll yet" when the total is $0. After Spring 28 the line moves to Summer 28. `journey.tycoon.payroll` is `{ cents, payday, notice }`. `cents` is the next payday total. `payday` is the current season's last day, such as "Spring 28". `notice` is empty except on the morning after payday. A payload without `payroll` draws no extra line. Hire stays the one primary action. There is no payroll button.

## Roadmap

Shipped in this slice: the fit table, office-day development, a deterministic review, a four-day sales curve, game cash, fans, a product history list, staff training, research points, a research fit bonus, the upgrades shop, the season calendar, office growth inside the current room, launch price, marketing, contracts, patches, sequels, awards, ports, engines, focus, audience, size, and payroll. The entries are **New Product**, **Selling**, **Shipped**, **Contract**, **Train staff**, **Research**, **Upgrades**, **Engine**, **Office**, and **Season** on Company Journey. Price, marketing, the engine choice, the focus, the audience, and the size live on the New Product picker. The engine buy lives on the Engine card. The award show and the port live on the Shipped card. Payroll is one line on the Season card.

Next slice:

1. **Loans.** One optional loan of game cash, repaid with a small fee on a later payday. Skipping it leaves cash alone, so the first newsletter stays 20700 cents and 5 fans. No new product picker row.

Later art ask: a second room. Office growth shipped as spare desks on the current floor (`compact_desk` and `shared_workbench`, already bound). There is no second-room architecture art, so that room waits.

Chapter work orders still ask for a key unless the dev-only fake provider is on. That path is not part of these slices. Do not fold it into the tycoon, and do not make it the default.
