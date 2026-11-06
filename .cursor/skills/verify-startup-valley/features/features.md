# Features

## Sub-features

- Read the card for the product in development. The offer is "Feature · Whop Bonus Drop · +1 office day, +10% opening demand" plus an Add feature button.
- Add the feature. Cash stays put. The line is "Feature added · Whop Bonus Drop · Building · day 0 of 3" and the button is gone. The build needs one more office day.
- The next product offers the feature again. The same product does not.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The line sits with the publisher deal and the press demo, above New Product. Hire stays the primary action. Add feature is secondary.

The feature is Whop Bonus Drop in copy only. The extra day and the opening-demand bump are in `docs/TYCOON_DESIGN.md`. At most one feature per product, and only while it is in development. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never adds a feature. A separate save starts Crypto Alpha Newsletter with no gifted cash and leaves the feature unadded. The helper snaps `60-feature-offer.png` on that line, clicks Add feature, and snaps `61-feature-added.png` with $0.00, 0 reputation, and "Feature added · Whop Bonus Drop · Building · day 0 of 3".

## Gotchas

- Replaying the day or reopening the save never adds the feature twice or applies the demand bump twice.
- Skipping the feature leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
- With nothing on the bench the call says "No product is on the bench." A second add says "Already added."
