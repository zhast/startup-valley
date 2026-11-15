# Sale price

## Sub-features

- Read the Selling card. The line is "Sale price · $9.00 · remaining days" for a catalog newsletter, with secondary buttons for the percents that are not current.
- Click −20%. The line becomes "Sale price · −20% · $7.20" and the buttons are gone. Posted sales stay. The clock does not move.
- Later sales days use the new percent. Days already sold stay at the launch percent.

## How to get to it (user POV)

Open Company Journey while a product is selling. The row sits under the launch trailer line and above Patch. Hire stays the primary action. The price buttons are secondary.

A payload without `salePrice` draws no control. The words stay Sale price. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never changes a sale price. A separate save releases Crypto Alpha Newsletter at catalog and gifts no extra cash. The helper snaps `82-saleprice-offer.png` on the sale price line, clicks −20%, and snaps `83-saleprice-set.png` on Sale price · −20% · $7.20.

## Gotchas

- Nothing selling fails with "No product is selling."
- A second request fails with "A sale price was already set."
- The same percent as the launch price fails with "Price is unchanged."
- An invalid percent fails with "Pick −20%, catalog, or +20%." A bad payload fails with "Invalid protocol request".
- A port and a translation keep the launch percent.
- Skipping Sale price leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
