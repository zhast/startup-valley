# Tycoon design

Startup Valley plays as a small offline tycoon. Whop shows up in the names, the product types, and the jokes. The game does not talk to Whop, and it does not call a model while you ship a product.

The rules in `harness/src/tycoon.ts` are authoritative. This document matches that module. Godot only presents `journey.tycoon`.

## Pillars

1. **Offline.** A new company ships a product with no API key and no network. Providers stay optional, and only on chapter work orders and chat.
2. **The pairing is the decision.** A topic and a product type fit together at Great, Good, Okay, or Bad, in the Game Dev Tycoon way. A bad pairing can still ship. It sells worse.
3. **Days, not a progress bar you click.** Development and sales move when the office day ends. The room stays the cozy Stardew-style office already in the game.
4. **Deterministic.** Reviews and sales are pure functions of the company seed, the product id, the fit, the points, and reputation. The same save replays the same launch.
5. **One product on the bench.** A second idea waits until the first one ships. A shipped product can still be selling while the next one starts.

## Core loop

1. From Company Journey, choose **New Product**.
2. Pick a topic and a product type. The panel shows the fit.
3. The founder is always on the build. Hired teammates can join.
4. **Start development.** The product stores the fit and the staff snapshot.
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

The ideal for a stat is `days required × 4`. Matching the ideal is full credit. A little extra holds the credit. A large pile of one stat dulls it. Quality is the weighted blend. Fit scales that quality. The base score maps the result onto 1–10.

Four reviewers then each move that base by −1, 0, or +1. The jitter comes from the company seed and the product id. Scores clamp to 1–10. The headline is the rounded mean, clamped again. Blurbs follow the headline band: 8–10 high, 5–7 mid, 1–4 low. The review is stored on the product, so a later formula change does not rewrite a shipped score.

Reviewers: **Whop Weekly**, **Discord Dave**, **Margin Call Molly**, **Cohort Casey**.

Sales run for 4 days at 100%, 70%, 45%, then 25% of the opening demand. Opening demand is the fit's base units, plus a term from the score, plus a small term from current reputation. A seeded swing of about ±10% lands on each day. Units are at least 1. Cash is units times the type price. Fans are a fraction of units: 0.4 at score 8+, 0.2 at 5–7, 0.1 below that, and at least 1. Fans add to company reputation.

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

Older saves that predate this column load with every topic and type unlocked and 0 points, so an existing company does not lose a pairing. A fresh database gets the starter catalog. Reopening a save does not reset progress. The unlock line ("Unlocked Sneakers. −4 RP") shows only on that office day.

Company Journey lists locked items on a Research card under New Product: the balance, the day's unlock line, and one secondary button per locked item ("Research Sneakers · 4 RP"). The button is disabled when the balance is short. The card hides once everything is unlocked. The product picker still lists locked choices, disabled, with "· locked". The release screen shows "+N research points".

## Day and season calendar

What ships now is the office day clock already in the game. Work is 08:00–12:30 and 13:30–17:30. Lunch is 12:30–13:30. Ending the day saves, writes the summary, and advances the tycoon by one day. The next morning is 08:00.

Seasons are design-only in this slice. The planned calendar is Stardew-shaped and not implemented:

- Four seasons of 28 office days: Spring, Summer, Fall, Winter. A year is 112 days.
- The season is derived from the saved day number. It does not replace the clock.
- A later slice can let the season nudge demand (a fitness course in Spring, a study pack in Fall) and host one small event per season. Events stay inside the simulation. They do not call out.

## Whop-themed names

Topics: Fitness, Trading, Sneakers, Reselling, Sports Betting Picks, Cooking, Gaming, Dating Advice, Study Notes, Crypto Alpha.

Product types: Course, Community, Template Pack, Coaching, Software Tool, Newsletter.

Team: Founder, Mina, Theo, Creative.

Press: Whop Weekly, Discord Dave, Margin Call Molly, Cohort Casey.

Shelf jokes stay in the reviewer blurbs (checkout links, lurkers, margins, welcome modules). They are not a second product catalog.

## Roadmap

Shipped in this slice: the fit table, office-day development, a deterministic review, a four-day sales curve, game cash, fans, a product history list, staff training, and research points. The entries are **New Product**, **Train staff**, and **Research** on Company Journey.

Next slices, in order:

1. **Upgrades shop.** Spend game cash on an office tool that boosts one stat or one price. No real-money store.
2. **Office growth.** More desks and a second room when cash and headcount earn them. Use furniture that is already bound.
3. **Seasons and events.** Turn on the 28-day calendar and one cozy event per season. Demand modifiers stay deterministic. A small fit bonus from research is still unbuilt.

Chapter work orders still ask for a key unless the dev-only fake provider is on. That path is not part of these slices. Do not fold it into the tycoon, and do not make it the default.
