---
name: verify-startup-valley
description: Drive the Startup Valley Godot game through a headless SubViewport and save PNG proof of the real Company Journey buttons. Use when a tycoon or journey change needs a player-level check with the real worker, or when a flow needs screenshot evidence.
---

# Verify Startup Valley

The Godot game presents `journey.tycoon`. The harness in `harness/` is authoritative. This skill boots `game/world/main.tscn` inside a SubViewport, clicks the real buttons, and writes PNGs. It does not call a model, the network, or a credential.

Rules and prices live in `docs/TYCOON_DESIGN.md`. Player steps live in `features/` beside this file. Do not restate them here.

## Launch

Godot 4.7.2 is `/home/box/.local/bin/godot` (`godot` on PATH). Node 22 is `/home/box/.local/node22/bin`. `res://` is rooted at `game/`, so a script outside `game/` is passed as an absolute `--script` path. `--path game` still loads the project, and `preload("res://...")` resolves.

From the repo root, after the harness build in Doctor:

```bash
export PATH=/home/box/.local/node22/bin:/home/box/.local/bin:$PATH
export STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1
SV_PROOF_DIR=/workspace/sv-proof/round-51 \
  xvfb-run -a -s "-screen 0 1280x720x24" \
  godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd
```

Do not add `--headless`. The SubViewport texture is blank without a display. `xvfb-run` is that display. Do not use `res://../.cursor/...`.

If Godot rejects the absolute script, copy the helper to `/tmp/capture_journey.gd` and pass that path. Delete the copy when the run finishes. Do not leave a copy under `game/`.

## Doctor

- `cd harness && npm run build` so `harness/dist/main.js` exists. The game refuses to boot without it.
- `godot --version` prints 4.7.2. `node --version` prints v22.
- `xvfb-run` is installed.
- `STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1` is set. Unset `STARTUP_VALLEY_NO_WORKER` and `STARTUP_VALLEY_FAKE_PROVIDER`.
- `STARTUP_VALLEY_DATA_DIR` is a fresh directory. The helper sets one under the temp dir when it is unset. Do not point it at a real save.
- `SV_PROOF_DIR` is set. The helper exits with `PROOF FAIL` when it is empty.

## Drive

`capture_journey.gd` is a `SceneTree` script. It instances `main.tscn` in a 1280×720 SubViewport, sets the day clock speed to 0, and pushes mouse and key events at the live controls.

The run ships Crypto Alpha Newsletter at catalog price with no ad, no engine, Balanced focus, Everyone as the audience, and Catalog size, trains Founder Tech, ends the day, researches Sneakers, starts Sneakers Newsletter at −20% with a small ad, ships that second product, and buys Oak Standing Desk. After the desk it buys Whop Kit Engine, releases the sequel still on the bench, and selects the engine on the next picker without starting that product. It then clears the engine, selects Design, and starts that newsletter so the journey line names the focus. It releases that focused build, then selects Regulars and starts another newsletter so the journey line names the audience. It releases that audience build, selects Long, and starts another newsletter so the journey line names the size. After the first build day it checks the Season card and the date label. The fresh company also snaps the locked Office card. It then boots a separate company with Mina hired on Spring 28, snaps the Season card payroll line, ends that day, and snaps the paid notice with the lower cash. It then boots a fresh company, snaps the loan offer on the Season card, takes that loan, and snaps the due line with the higher cash. It then boots a company with Crypto Alpha Newsletter on the bench, snaps the publisher offer, signs it, and snaps the signed line with the higher cash. It then boots a company with $207 of gifted game cash, snaps the expo offer on the Season card, books the booth, and snaps the booked line with cash at $147. It then boots a company whose Crypto Alpha Newsletter has finished selling, snaps the translate line on that Shipped card, translates it, and snaps the bought line with cash $50 lower. It then boots a company with $207 of gifted game cash, snaps the town day line and Take the afternoon on the Season card, takes the afternoon, and snaps the taken line with lower cash and higher reputation. It then boots a company with Crypto Alpha Newsletter on the bench and $207 of gifted game cash, snaps the press demo line and Show preview, shows the preview, and snaps the taken line with lower cash and higher reputation. It then boots a company whose Crypto Alpha Newsletter is selling, with the launch cash and fans and no gifted extra, snaps the trailer line and Make trailer on the Selling card, makes the trailer, and snaps the made line with lower cash and higher fans. It then boots a seeded team, clicks Expand office, and snaps the Open Floor card and the new desks in the room. On the first picker it snaps the marketing control while both ads are short of cash. After Sneakers is researched it snaps the picker bonus, the price control, buys the small ad, starts that product, and snaps the journey bonus line. After the cheaper Sneakers release it snaps the chosen price line and the marketing line. After the first newsletter release it snaps the Patch button on the Selling card and leaves that product unpatched. After that newsletter finishes selling it snaps Sequel on the Shipped card and leaves it unpressed, then snaps Enter award on that same card and leaves it unpressed, then snaps Port on that same card and leaves it unpressed. After the contract launch it patches that selling product and snaps the cost line, then starts the newsletter sequel and snaps the shorter build, then enters the award show and snaps the result line, then ports that finished newsletter, ends the day, and snaps the port line. Button names and the order are in the feature files. Scroll the journey with the same reveal the tests use before clicking a card that sits below New Product.

## Evidence

The helper writes these PNGs into `SV_PROOF_DIR` and prints `SNAP` plus the file name:

- `01-journey.png` — Company Journey at the top
- `02-research-card.png` — Research card on day 1
- `03-picker-locked.png` — locked topics and types in the picker
- `04-release-research.png` — release screen with the research line
- `05-trained-notice.png` — the lesson line on the training day
- `06-notice-gone.png` — the next office day, lesson line gone
- `07-research-unlocked.png` — the unlock line
- `08-sneakers-started.png` — Sneakers Newsletter on the bench
- `09-upgrades-card.png` — Upgrades card with Buy Oak Standing Desk enabled
- `10-upgrade-owned.png` — the purchase line and the owned desk
- `11-season-card.png` — Season card, favored topics, and the next event
- `12-date-label.png` — the date label, "Spring 2 · Year 1", after one office day
- `13-office-card.png` — Office card before the expansion, Garage Loft, desks 1/4, Expand office disabled
- `14-office-expanded-card.png` — Office card after Expand office, Open Floor, desks 3/7
- `15-office-new-desks.png` — the office at the normal game size, with the new desks among the existing furniture
- `16-research-fit-picker.png` — the picker fit line with "Research bonus: +6 fit" after Sneakers is researched
- `17-research-fit-journey.png` — Company Journey with "Sneakers Newsletter · Research bonus +6 fit" on the product that just started
- `18-price-picker.png` — the price control on the picker with the unit-effect line
- `19-price-released.png` — a released product showing the chosen price and unit effect
- `20-marketing-picker.png` — the marketing control on the first picker, with the cost line and an unaffordable ad
- `21-marketing-released.png` — a released product showing the bought ad and its unit effect
- `22-contract-offer.png` — Company Journey on the Contract card, Accept contract secondary
- `23-contract-released.png` — a released product showing the contract bonus line
- `24-patch-offer.png` — Company Journey with Patch · $100 on a selling product
- `25-patch-applied.png` — the patch cost line and the patched state on the Selling card
- `26-sequel-offer.png` — Company Journey with Sequel on a finished product
- `27-sequel-started.png` — the sequel building, with the shorter day line and the carried score
- `28-award-offer.png` — Company Journey with Enter award on a finished product
- `29-award-result.png` — the award result line after that product enters
- `30-port-offer.png` — Company Journey with Port on a finished product
- `31-port-result.png` — the port line after its extra sales day
- `32-engine-offer.png` — Engine card with Whop Kit Engine at $120, before the buy
- `33-engine-picker.png` — the product picker with Whop Kit Engine selected and the +1 score line
- `34-focus-picker.png` — the product picker with Design selected and the +1 design line
- `35-focus-journey.png` — Company Journey with the build line naming Design
- `36-audience-picker.png` — the product picker with Regulars selected and the +2 fans line
- `37-audience-journey.png` — Company Journey with the build line naming Regulars
- `38-size-picker.png` — the product picker with Long selected and the +1 day line
- `39-size-journey.png` — Company Journey with the build line naming Long
- `40-payroll-season-card.png` — Season card with Mina hired, "Payroll · $80 on Spring 28", before payday
- `41-payroll-paid.png` — the morning after payday, with the paid notice and cash below zero
- `42-loan-offer.png` — Season card with the loan offer and Take loan
- `43-loan-taken.png` — after taking the loan, with higher cash and the Loan due line
- `44-publisher-offer.png` — the developing product's card, with the publisher offer and Sign publisher
- `45-publisher-signed.png` — after signing, with higher cash and the Published by line
- `46-expo-offer.png` — Season card with the expo offer and Book booth
- `47-expo-booked.png` — after booking, with lower cash and the Booth booked line
- `48-localize-offer.png` — Shipped card with the translate line and Translate
- `49-localize-bought.png` — after translating, with lower cash and the Spanish edition line
- `50-townday-offer.png` — Season card with the town day line and Take the afternoon
- `51-townday-taken.png` — after taking the afternoon, with lower cash, higher fans, and the taken line
- `52-pressdemo-offer.png` — the developing product's card, with the press demo line and Show preview
- `53-pressdemo-taken.png` — after showing the preview, with lower cash, higher fans, and the taken line
- `54-trailer-offer.png` — Selling card with the trailer line and Make trailer
- `55-trailer-made.png` — after making the trailer, with lower cash, higher fans, and the made line

A finished run prints `PROOF PASS` or `PROOF FAIL` and a `FAILURE` line for each miss. Open the PNGs. A black frame means the display server did not render the SubViewport.

## Cleanup

The helper's data dir is under the OS temp directory. Leave it. Do not commit `SV_PROOF_DIR`, `game/assets/runtime/`, or a `.uid` created beside a copied script. Do not commit a helper copy under `game/tools/`.

## Helpers

The only helper is `.cursor/skills/verify-startup-valley/capture_journey.gd`. It reads `SV_PROOF_DIR` and isolates `STARTUP_VALLEY_DATA_DIR`. Headless gameplay checks that do not need PNGs stay the Godot `--script res://tests/...` commands in `AGENTS.md`.
