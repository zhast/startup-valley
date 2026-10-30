# Press demo

## Sub-features

- Read the card for the product in development. The offer is "Press demo · Whop Weekly Preview · $30, about 4 fans" plus a Show preview button.
- Show the preview. Cash drops by $30. Reputation rises by 4. The line is "Preview shown · Whop Weekly Preview" and the button is gone.
- The next product offers the preview again. The same product does not.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The line sits with the publisher deal, above New Product. Hire stays the primary action. Show preview is secondary.

The preview is Whop Weekly Preview in copy only. The fee and the fans are in `docs/TYCOON_DESIGN.md`. At most one press demo per product, and only while it is in development. It does not spend an office day.

## Driving it with capture_journey.gd

The main playthrough never shows a preview. A separate save starts Crypto Alpha Newsletter with $207 of gifted game cash and leaves the preview unshown. The helper snaps `52-pressdemo-offer.png` on that line, clicks Show preview, and snaps `53-pressdemo-taken.png` with $177.00, 4 reputation, and "Preview shown · Whop Weekly Preview".

## Gotchas

- Replaying the day or reopening the save never charges the fee twice or grants the fans twice.
- Skipping the preview leaves cash alone. The first newsletter is still $207 and 5 fans.
- A company with less than $30 sees "Need $30" and nothing is written.
