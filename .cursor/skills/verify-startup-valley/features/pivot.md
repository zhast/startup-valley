# Pivot

## Sub-features

- Read the card for the product in development. The line is "Pivot · change topic or type. Days and points stay."
- Click Pivot. The topic and type grids from the New Product picker open on this card.
- Pick a new pair and click Change pair. The line becomes "Pivoted · New Name" and the button goes away. Dev days and craft points stay. The name and the fit follow the new pair.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Slip a day and above New Product, with the publisher deal, the press demo, the feature, the day plan, bugs, crunch, early access, cancel, and slip. Hire stays the primary action. Pivot is secondary.

A payload without `pivot` draws no control. The word stays Pivot. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee. At most one pivot per product.

## Driving it with capture_journey.gd

The main playthrough never pivots. A separate save starts Crypto Alpha Newsletter on day 0 and gifts no cash. The helper snaps `74-pivot-offer.png` on the Pivot line, opens the picker, changes the pair to Fitness Course, and snaps `75-pivot-done.png` on Pivoted · Fitness Course.

## Gotchas

- Nothing on the bench fails with "No product is on the bench."
- The same pair fails with "Pick a new topic or type."
- A second pivot fails with "Already pivoted."
- A contract on the product fails with "This contract is Topic × Type."
- Locked topics and types fail with "Name is locked. Research it first."
- Skipping Pivot leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
