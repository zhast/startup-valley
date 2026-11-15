# Launch trailer

## Sub-features

- Read the Selling card. The offer is "Trailer · Whop Creator Cut · $25, about 6 fans" plus a Make trailer button.
- Make the trailer. Cash drops by $25. Reputation rises by 6. The line is "Trailer made · Whop Creator Cut" and the button is gone.
- The next product offers the trailer again while it is selling. The same product does not.

## How to get to it (user POV)

Open Company Journey while a product is selling. The line sits on that Selling card, after the sales-day line and before Patch. Hire stays the primary action. Make trailer is secondary.

The trailer is Whop Creator Cut in copy only. The fee and the fans are in `docs/TYCOON_DESIGN.md`. At most one trailer per product, and only while it is selling. It does not spend an office day.

## Driving it with capture_journey.gd

The main playthrough never makes a trailer. A separate save releases Crypto Alpha Newsletter and leaves the trailer unmade. The helper snaps `54-trailer-offer.png` on that line, clicks Make trailer, and snaps `55-trailer-made.png` with $182.00, 11 reputation, and "Trailer made · Whop Creator Cut".

## Gotchas

- Replaying the day or reopening the save never charges the fee twice or grants the fans twice.
- Skipping the trailer leaves cash alone. The first newsletter is still $207 and 5 fans.
- A company with less than $25 sees "Need $25" and nothing is written.
- Six fans after the launch sale move company reputation from 5 to 11. Later sales days then use one extra base unit. The trailer row earns 0.
