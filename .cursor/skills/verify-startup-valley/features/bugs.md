# Bugs

## Sub-features

- Read the card for the product in development. The line is "Bugs · 0 · build looks balanced" on a balanced build, or "Bugs · N · Fix bugs spends tomorrow's craft" when live bugs remain.
- Click Fix bugs when count is above 0. Cash stays put. The line becomes "Fixing bugs · next office day clears craft into bugfix" and the button is gone.
- End the office day. Personal craft clears into bugsCleared. The line returns to the remaining count or the balanced line.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Day plan and above New Product, with the publisher deal, the press demo, and the feature. Hire stays the primary action. Fix bugs is secondary.

The word stays Bugs. The rules are in `docs/TYCOON_DESIGN.md`. A balanced founder newsletter stays at 0 bugs. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never arms Fix bugs. A separate save starts Crypto Alpha Newsletter, picks Design for the day plan, ends one office day so the live count is at least 1, snaps `64-bugs-offer.png`, clicks Fix bugs, and snaps `65-bugs-fixing.png` with $0.00 and 0 reputation.

## Gotchas

- Replaying the day or reopening the save keeps bugsCleared. It does not clear twice for one armed day.
- Skipping Fix bugs on a balanced build leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
- With nothing on the bench the call says "No product is on the bench." With 0 live bugs it says "No bugs to fix."
- A payload without `bugs` draws no control.
