# Awards

## Sub-features

- One optional entry in the Whop Creator Awards for a finished product. A product enters once.
- Enter award is a secondary button on the Shipped card on Company Journey. Selling cards show the same button disabled. Hire stays the one primary action.
- The fee is $40. A stored review of 8 or more wins and adds 12 fans. A score of 5–7 is a nominee and adds 4 fans. A lower score reads "Award · Entered" and adds no fans.
- Short cash, a product that is still selling, and a second entry disable the button with a short reason.
- No award is the default. The first newsletter still pays 20700 cents and 5 fans.

## How to get to it (user POV)

Start the company. Ship Crypto Alpha Newsletter and let the four sales days finish. On Company Journey the Shipped card shows Whop Creator Awards · $40 and Enter award. Press it. The card then reads "Award · Nominated · +4 fans" because that newsletter scores 6.

## Driving it with capture_journey.gd

The helper snaps `28-award-offer.png` after the first newsletter finishes selling, with Enter award on the Shipped card. It does not press it yet, so the later cash checks stay on the old path. After the sequel starts it presses Enter award on that same newsletter and snaps `29-award-result.png` on the nominee line.

## Gotchas

- While the product is still selling the button reads "Enter award · Still selling."
- A second press reads "Enter award · Already entered." Fans are added once.
- The band uses the stored review score. A patch does not move it.
- Old rows without an award field count as not entered and are not rewritten on read.
