# Tycoon design

Startup Valley plays as a small offline tycoon. Whop shows up in the names, the product types, and the jokes. The game does not talk to Whop, and it does not call a model while you ship a product.

The rules in `harness/src/tycoon.ts` are authoritative. This document matches that module. Godot only presents `journey.tycoon`.

## Pillars

1. **Offline.** A new company ships a product with no API key and no network. Providers stay optional, and only on chapter work orders and chat.
2. **The pairing is the decision.** A topic and a product type fit together at Great, Good, Okay, or Bad, in the Game Dev Tycoon way. A bad pairing can still ship. It sells worse.
3. **Days, not a progress bar you click.** Development and sales move when the office day ends. The room stays the cozy Stardew-style office already in the game.
4. **Deterministic.** Reviews and sales are pure functions of the company seed, the product id, the fit, the points, the research bonus stored on the product, the launch price stored on the product, the marketing choice stored on the product, and reputation. The same save replays the same launch.
5. **One product on the bench.** A second idea waits until the first one ships. A shipped product can still be selling while the next one starts.

## Core loop

1. From Company Journey, choose **New Product**.
2. Pick a topic and a product type. The panel shows the fit.
3. The founder is always on the build. Hired teammates can join.
4. **Start development.** The product stores the fit, the staff snapshot, the research bonus, the launch price, and the marketing choice. A paid ad spends game cash here.
5. **End day + save** once for each office day of work. The team adds design, tech, and hype. Progress is `dev days / days required`.
6. When the required days are done, **Release**. Four reviewers score it from 1 to 10. Launch-day sales pay game cash and fans immediately.
7. The next three office days keep selling, once each, when the day ends. The release day does not sell twice.
8. The product moves onto the shelf. Cash and reputation (fans) stay on the company. Ship another.

A newsletter or template pack takes 2 office days. A course, community, or coaching offer takes 3. A software tool takes 4. Two extra office days can still add a little craft. After that, points stop.

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

The ideal for a stat is `days required × 4`. Matching the ideal is full credit. A little extra holds the credit. A large pile of one stat dulls it. Quality is the weighted blend. Fit scales that quality. A researched topic or type adds 6 to that fit's numerator, up to 12, from the bonus stored when development started. The base score maps the result onto 1–10.

Four reviewers then each move that base by −1, 0, or +1. The jitter comes from the company seed and the product id. Scores clamp to 1–10. The headline is the rounded mean, clamped again. Blurbs follow the headline band: 8–10 high, 5–7 mid, 1–4 low. The review is stored on the product, so a later formula change does not rewrite a shipped score.

Reviewers: **Whop Weekly**, **Discord Dave**, **Margin Call Molly**, **Cohort Casey**.

Sales run for 4 days at 100%, 70%, 45%, then 25% of the opening demand. Opening demand is the fit's base units, plus a term from the score, plus a small term from current reputation. A seeded swing of about ±10% lands on each day. Units are at least 1. Cash is units times the unit price. Fans are a fraction of units: 0.4 at score 8+, 0.2 at 5–7, 0.1 below that, and at least 1. Fans add to company reputation.

The catalog price is the default. At Start development the player can leave it, or nudge −20% or +20%. A cheaper price sells more units. A higher price sells fewer. The percents are fixed: 80 / 100 / 120 for price, and 120 / 100 / 80 for units. Units after the nudge are `Math.max(1, Math.round((units * unitPercent) / 100))`. The unit price is `Math.round((catalogCents * pricePercent) / 100)`. Catalog (100) leaves both unchanged, so the first newsletter still pays 20700 cents and 5 fans.

The choice is stored on the product, in `staff_json` as `{staff, researchBonus, pricePercent, marketing}`. Sales use the stored price. An older row that is only a staff array, or a row with no `pricePercent`, sells at catalog. A row with no `marketing` sells with no ad. Stored `sales_cents` are not rewritten.

Composition, in this order, on every sale that is computed:

1. Base units from fit, score, reputation, the sales curve, and the seeded swing. At least 1.
2. Launch-price units.
3. Season +20% units, when the topic is favored that day.
4. Marketing units from the snapshot. None is an identity step. Otherwise `Math.max(1, Math.round((units * unitPercent) / 100))`.
5. Fans from those units, then the event fan bonus if an event is on.
6. Launch price on the catalog cents.
7. Nicer Checkout Page +10% on that unit price, when the tool is already owned.
8. Cash is units times that price.

A checkout-page boost still changes only the price. Season still changes only the units. Launch price changes both, from the snapshot.

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

A product whose topic is favored sells 20 percent more units on each sale computed that season: `Math.max(1, Math.round((units * 120) / 100))`. That `units` value already includes the launch-price unit effect. Marketing, when the product bought an ad, runs after this step. Fans are computed from the units after marketing. Cents are the final units times the price. A checkout-page price boost still changes only the price. Stored reviews and earlier sales are not rewritten. A topic outside the pair uses the old formula. Crypto Alpha is not favored in Spring, so the first newsletter's cash is unchanged.

One cozy event per season, on a fixed day. The effect lasts that day only. Names stay inside the simulation.

| Season | Day | Name | Blurb |
| --- | --- | --- | --- |
| Spring | 13 | Creator Fair | The floor is full of shops and first buyers. |
| Summer | 11 | Drop Day | Everyone refreshes the page at the same minute. |
| Fall | 16 | Cohort Kickoff | A new class shows up with notebooks open. |
| Winter | 25 | Cozy Gift Guide | Whop Weekly lists the warm shops. |

Each event adds 2 fans to any product that sells that day. The line is "+2 fans on sales today". Units, price, and the stored review do not change. If nothing sells, the event still shows and adds no fans. The next event is the next one after today. After Winter 25 it wraps to Creator Fair in the following year. `daysUntil` is at least 1.

`journey.tycoon.calendar` carries `season`, `seasonName`, `dayOfSeason`, `year`, `label`, `favoredTopics` (`{id, name}`), `event` (or null), and `nextEvent` (the event fields plus `season`, `dayOfSeason`, and `daysUntil`). The day summary stores `dateLabel` for the day that just ended, so the complete screen does not jump to the next morning. Older summaries without that field still load.

Company Journey shows the label on the heading ("Spring 2 · Year 1 · $0.00 game cash · 0 reputation"). The title continue line and the day complete screen use the same words. A Season card sits under Office: "In season: Fitness, Dating Advice", and either "Creator Fair today. +2 fans on sales today" or "Creator Fair in 11 days". The product picker adds "· in season" on a favored topic, including a locked one. Hire stays the one primary action. No new button.

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

Marketing is step 4 of the sale composition above. It runs after launch-price units and the season boost, and before fans. It does not change the unit price. Checkout still changes only the price. The spend is the cash paid at the start, not a cut of later sales.

`journey.tycoon.marketingOptions` is the three rows, each with `enabled` and `reason`. The New Product picker shows them under Price as secondary buttons, plus one line, for example "None · $0 · no extra units" or "Small ad · $50 · +20% units". A disabled button reads "Small ad · Need $50". The bench, the release card, and the shipped list repeat that line when an ad was bought. Hire stays the one primary action. A payload without `marketingOptions` leaves the control out, so older UI fixtures still render.

## Roadmap

Shipped in this slice: the fit table, office-day development, a deterministic review, a four-day sales curve, game cash, fans, a product history list, staff training, research points, a research fit bonus, the upgrades shop, the season calendar, office growth inside the current room, launch price, and marketing. The entries are **New Product**, **Train staff**, **Research**, **Upgrades**, **Office**, and **Season** on Company Journey. Price and marketing live on the New Product picker.

Next slice:

1. **Contracts.** One client offer on Company Journey. Accepting it locks the next product to that topic and type and pays a fixed bonus on release. Ignoring it leaves the free picker. No contract keeps the first newsletter at the same cash.

Later art ask: a second room. Office growth shipped as spare desks on the current floor (`compact_desk` and `shared_workbench`, already bound). There is no second-room architecture art, so that room waits.

Chapter work orders still ask for a key unless the dev-only fake provider is on. That path is not part of these slices. Do not fold it into the tycoon, and do not make it the default.
