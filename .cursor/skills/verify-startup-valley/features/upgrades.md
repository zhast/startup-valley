# Upgrades

## Sub-features

- See the four office tools, with a price and what each one does.
- Buy one with game cash. The button reads "Buy Ring Light · $400".
- Read "Bought Ring Light. −$400" on that office day only.
- See the owned line the next morning. The buy button for that item is gone.

## How to get to it (user POV)

Open Company Journey. The Upgrades card sits under Research. Hire stays the primary action. Buy buttons are secondary and disabled when the cash is short. Each tool can be bought once.

Oak Standing Desk is $250 and is the first one a newsletter can pay for. Ring Light is $400. Nicer Checkout Page is $560 and waits for a second product. Prices and effects are in `docs/TYCOON_DESIGN.md`.

## Driving it with capture_journey.gd

The helper ships Crypto Alpha Newsletter, trains, researches Sneakers, and starts Sneakers Newsletter. It then finishes that second product. On the release day it scrolls to the Upgrades card and saves `09-upgrades-card.png`, clicks Buy Oak Standing Desk, and saves `10-upgrade-owned.png` with the purchase line on screen.

## Gotchas

- One newsletter cannot pay for both the first lesson and an upgrade. The proof trains first, then uses the second launch.
- The purchase line clears when the office day ends. The owned line stays.
- A point boost shows up on the next dev day that ends after the purchase. It does not rewrite a product that already shipped.
