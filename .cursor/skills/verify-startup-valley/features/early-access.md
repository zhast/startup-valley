# Early access

## Sub-features

- Read the card for the product in development. After one office day the line is "Early access · ship now, −1 score".
- Click Ship early. The release card says "Early access". Sales start that day. The score is a point lower than a full build.

## How to get to it (user POV)

Open Company Journey while a product is on the bench and still short of its required days, after at least one office day. The row sits under Crunch and above New Product, with the publisher deal, the press demo, the feature, the day plan, and bugs. Hire stays the primary action. Ship early is secondary.

Before that first office day the line says why it waits, and there is no button. Once the required days are done the line points at Release, and there is no button.

The words stay Early access. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never ships early. A separate save starts Crypto Alpha Newsletter, works one office day, and gifts no cash. The helper snaps `68-early-offer.png` on the Early access line, clicks Ship early, and snaps `69-early-released.png` on the release card.

## Gotchas

- Day 0 fails with "Work one office day first." A finished build fails with "Required days are done. Use Release." Nothing on the bench fails with "No product is on the bench."
- Skipping Early access leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
- The penalty is 1 score point per missing day, capped at 3. The score does not go below 1.
- A payload without `earlyAccess` draws no control.
