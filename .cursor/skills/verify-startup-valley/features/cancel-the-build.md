# Cancel the build

## Sub-features

- Read the card for the product in development. The line is "Cancel · drop this build. Days worked are gone."
- Click Cancel build. The card asks "Drop this build? Days worked are gone." Keep building takes focus. Drop the build clears the bench.
- Start a New Product after the drop. The days already worked are gone. There is no review and no sales.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Early access and above New Product, with the publisher deal, the press demo, the feature, the day plan, bugs, and crunch. Hire stays the primary action. Cancel build is secondary. Keep building and Drop the build are secondary too.

A payload without `cancel` draws no control. The words stay Cancel. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never cancels. A separate save starts Crypto Alpha Newsletter, works one office day, and gifts no cash. The helper snaps `70-cancel-offer.png` on the Cancel line, clicks Cancel build, clicks Drop the build, and snaps `71-cancel-done.png` on New Product.

## Gotchas

- Nothing on the bench fails with "No product is on the bench." The same string comes back after a cancel and after a release.
- The dropped product is deleted. It is not a shipped history row. A contract on it fails and the same offer returns. A publisher advance already paid stays spent.
- Skipping Cancel leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
