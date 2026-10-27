# Sequels

## Sub-features

- One optional sequel of a finished product. A sequel cannot start its own sequel.
- Sequel is a secondary button on the Shipped card on Company Journey. Selling cards show the same button disabled. Hire stays the one primary action.
- The sequel keeps the niche and format. Its name is the original name plus " 2". It takes one fewer build day, at least 1. A newsletter sequel takes 1 office day.
- It carries +1 score when the original's final score is 6 or more. The build screen reads "Sequel · +1 score". A lower finish carries nothing.
- No sequel is the default. The first newsletter still pays 20700 cents and 5 fans.

## How to get to it (user POV)

Start the company. Ship Crypto Alpha Newsletter and let the four sales days finish. On Company Journey the Shipped card shows Sequel. Press it. The next screen is "Crypto Alpha Newsletter 2", "Building · day 0 of 1", and "Sequel · +1 score".

## Driving it with capture_journey.gd

The helper snaps `26-sequel-offer.png` after the first newsletter finishes selling and Sneakers is researched, with Sequel on the Shipped card. It does not press it yet, so the sneakers product can still start. After the contract patch it presses Sequel on that same newsletter and snaps `27-sequel-started.png` on the shorter build line and the carried score.

## Gotchas

- While the product is still selling the button reads "Sequel · Still selling."
- A second press reads "Sequel · Already has a sequel." A sequel's own button reads "Sequel · This is a sequel."
- Old rows without sequel fields count as no sequel and are not rewritten on read.
