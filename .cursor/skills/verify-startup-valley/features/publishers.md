# Publishers

## Sub-features

- Read the card for the product in development. The offer is "Publisher · Creator Collective pays $150 now, takes 30% of sales" plus a Sign publisher button.
- Sign the deal. Cash becomes $150. The line is "Published by Creator Collective · 30% cut" and the button is gone.
- That product's sales pay the company 70%. Fans stay on the old sale.
- After release the card is gone. A later product can sign its own deal.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The card sits with the build lines, above New Product. Hire stays the primary action. Sign publisher is secondary.

The publisher is Creator Collective in copy only. The advance, the cut, and the ledger row are in `docs/TYCOON_DESIGN.md`. At most one deal per product, and only while it is in development.

## Driving it with capture_journey.gd

The main playthrough never signs a publisher. A separate save starts Crypto Alpha Newsletter and leaves the deal unsigned. The helper snaps `44-publisher-offer.png` on that card, clicks Sign publisher, and snaps `45-publisher-signed.png` with $150.00 and "Published by Creator Collective · 30% cut".

## Gotchas

- Replaying a day end or reopening the save never pays the advance twice or takes the cut twice.
- Skipping the deal leaves cash alone. The first newsletter is still $207 and 5 fans.
