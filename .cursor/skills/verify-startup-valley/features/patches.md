# Patches

## Sub-features

- One optional patch on a shipped product while it still has remaining sales days.
- Patch · $100 is a secondary button on the Selling card on Company Journey. Hire stays the one primary action.
- A patch spends $100 and adds 1 to the stored score, capped at 10, for the remaining sales days. Already-paid sales stay put.
- Short cash, sales that have ended, and a second patch disable the button with a short reason.
- No patch is the default. The first newsletter still pays 20700 cents and 5 fans.

## How to get to it (user POV)

Start the company. Ship Crypto Alpha Newsletter. On Company Journey the Selling card shows Patch · $100. Press it, or leave it. The card then reads "Patched · +1 score" and "Patched Crypto Alpha Newsletter. −$100".

## Driving it with capture_journey.gd

The helper snaps `24-patch-offer.png` after the first newsletter release, with Patch · $100 on the selling card. It leaves that newsletter unpatched so training cash stays intact. After the contract launch it patches that selling product and snaps `25-patch-applied.png` on the cost line and the patched state.

## Gotchas

- The $100 charge is its own cash line, "Patch: <product>". It is not a cut of later sales.
- Ending the release day does not sell twice after a patch.
- Old rows without `patched` are unpatched and are not rewritten.
