# Dev diary

One optional writeup after a product's sales finish.

- Open Company Journey. The Shipped card for a finished product offers it.
- Read the line. The offer is "Diary · Whop Post-Mortem · $15, about 1 fan" plus a Write diary button.
- Write the diary. Cash drops by $15. Reputation rises by 1. The line is "Diary written · Whop Post-Mortem" and the button is gone.
- The next finished product offers the diary again. The same product does not.

## Where

Open Company Journey after a product's four sales days. The line sits on that Shipped card, after "Sales finished." and before the four-button shelf row. Hire stays the primary action. Write diary is secondary.

The diary is Whop Post-Mortem in copy only. The fee and the fans are in `docs/TYCOON_DESIGN.md`. At most one diary per product, and only after sales finish. It does not spend an office day.

## Proof

The main playthrough never writes a diary. A separate save finishes Crypto Alpha Newsletter's sales window and leaves the diary unwritten. The helper snaps `56-diary-offer.png` on that line, clicks Write diary, and snaps `57-diary-written.png` with $453.00, 12 reputation, and "Diary written · Whop Post-Mortem".

## Checks

- Skipping the diary leaves cash alone. The first newsletter is still $207 and 5 fans.
- A product still selling, or still on the bench, has no line.
- One fan after the four-day window moves company reputation from 11 to 12. The diary row earns 0.
