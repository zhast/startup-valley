# Playtest

## Sub-features

- Read the card for the product in development. Before an office day the line is "Playtest · Work one office day first." and there is no button.
- After at least one office day the line is "Playtest · see the likely review band." with one secondary button, Playtest.
- Click Playtest. The line becomes "Playtest: likely mid reviews", or low, or high. The button stays. The look is free to repeat, and the line follows the current band.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Pivot and above New Product, with the publisher deal, the press demo, the feature, the day plan, bugs, crunch, early access, cancel, slip, and pivot. Hire stays the primary action. Playtest is secondary.

A payload without `playtest` draws no control. The word stays Playtest. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee. The band is not stored.

## Driving it with capture_journey.gd

The main playthrough never playtests. A separate save works two office days on Crypto Alpha Newsletter and gifts no cash. The helper snaps `76-playtest-offer.png` on the Playtest line, clicks Playtest, and snaps `77-playtest-result.png` on Playtest: likely mid reviews.

## Gotchas

- Nothing on the bench fails with "No product is on the bench."
- Zero office days fails with "Work one office day first."
- Looking again is free. The line shows the current band.
- Skipping Playtest, and using it, both leave the first newsletter at $207 and 5 fans. The next office day is still $333.
