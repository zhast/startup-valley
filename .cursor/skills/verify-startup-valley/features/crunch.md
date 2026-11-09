# Crunch

## Sub-features

- Read the card for the product in development. The line is "Crunch · double craft tomorrow, then a rest day and +1 bug".
- Click Crunch. Cash stays put. The line becomes "Crunching · tomorrow's craft counts double" and the button is gone.
- End the office day. The line becomes "Resting · team recovers tomorrow". Personal craft from that armed day was doubled. The next office day adds no personal craft.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Bugs and above New Product, with the publisher deal, the press demo, the feature, and the day plan. Hire stays the primary action. Crunch is secondary.

The word stays Crunch. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never arms Crunch. A separate save starts Crypto Alpha Newsletter with no gifted cash. The helper snaps `66-crunch-offer.png` on the Crunch line, clicks Crunch, ends one office day, and snaps `67-crunch-resting.png` with $0.00, 0 reputation, and "Resting · team recovers tomorrow".

## Gotchas

- Replaying the day or reopening the save keeps an armed or resting crunch. It does not double twice for one armed day.
- Skipping Crunch leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
- With nothing on the bench the call says "No product is on the bench." While the team is resting it says "The team is still tired."
- A payload without `crunch` draws no control.
