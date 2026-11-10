# Slip a day

## Sub-features

- Read the card for the product in development. The line is "Slip a day · hold tomorrow. The build does not."
- Click Slip a day. The line becomes "Holding tomorrow" and the button goes away.
- End the office day. The calendar moves. The build stays on day 0 with no new design, tech, or hype. Slip a day is offered again.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Cancel build and above New Product, with the publisher deal, the press demo, the feature, the day plan, bugs, crunch, early access, and cancel. Hire stays the primary action. Slip a day is secondary.

A payload without `slip` draws no control. The words stay Slip a day. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never slips a day. A separate save starts Crypto Alpha Newsletter on day 0 and gifts no cash. The helper snaps `72-slip-offer.png` on the Slip a day line, clicks Slip a day, and snaps `73-slip-held.png` on Holding tomorrow.

## Gotchas

- Nothing on the bench fails with "No product is on the bench."
- The hold is one-shot. It clears after that office day and can be armed again. A second call while it is pending changes nothing.
- A held day still runs payroll, seasons, and sales of products that already shipped. The bench product does not craft. An armed crunch, day plan, or bug fix waits for the next day that is not held.
- Skipping Slip a day leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
