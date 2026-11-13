# Back catalog

## Sub-features

- Read the Season card after a product has shipped. The row under payroll names that product and the next catalog check.
- Click List in catalog. The line gains "Listed". The button reads Delist. Later paydays pay the stored review score times $2. Fans stay. Posted sales stay.
- Click Delist. The offer returns. Later paydays pay nothing.

## How to get to it (user POV)

Ship a product, then open Company Journey. The row sits on the Season card, under payroll and above the loan. Hire stays the primary action. List in catalog and Delist are secondary.

A payload without `catalog` draws no control. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never lists a product. A separate save ships a founder-only Crypto Alpha Newsletter, hires Mina, and finishes the website milestone. The helper snaps `88-catalog-offer.png` on the Season card, clicks List in catalog, and snaps `89-catalog-listed.png` with the listed product and the next check.

## Gotchas

- An unknown id, including a cancelled build, fails with "No product with that id."
- A product still on the bench fails with "This product is not finished."
- Listing the same product fails with "Already listed." Listing a different one fails with "A product is already listed." and does not swap.
- Delisting an empty slot fails with "Nothing is listed."
- A listing made on payday waits until the next season.
- Skipping Back catalog leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
