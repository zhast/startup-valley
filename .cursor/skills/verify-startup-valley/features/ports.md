# Ports

## Sub-features

- One optional port of a finished product onto Whop Mobile. A product ports once.
- Port is a secondary button on the Shipped card on Company Journey. Selling cards show the same button disabled. Sequel, Enter award, and Port share one row. Hire stays the one primary action.
- The fee is $80. The next day end pays one extra sales day from the stored score, using the normal sales formula, then the port is done.
- Short cash, a product that is still selling, a second port, and another port that is still selling disable the button with a short reason.
- No port is the default. The first newsletter still pays 20700 cents and 5 fans.

## How to get to it (user POV)

Start the company. Ship Crypto Alpha Newsletter and let the four sales days finish. On Company Journey the Shipped card shows Whop Mobile · $80 and Port. Press it. The card reads "Port · Whop Mobile · selling 1 day". End the day. The card then reads "Port · Whop Mobile" and the cash from that extra day.

## Driving it with capture_journey.gd

The helper snaps `30-port-offer.png` after the first newsletter finishes selling, with Port on the Shipped card. It does not press it yet, so the later cash checks stay on the old path. After the award result it presses Port on that same newsletter, ends the day, and snaps `31-port-result.png` on the dollar line.

## Gotchas

- While the product is still selling the button reads "Port · Still selling."
- A second press reads "Port · Already ported." The extra day pays once.
- The extra day uses the stored score, including a patch. It does not add a fifth day to the sales window.
- Old rows without a port field count as not ported and are not rewritten on read.
