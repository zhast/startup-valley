# Engines

## Sub-features

- One optional in-house engine, Whop Kit Engine. The company buys it once for $120.
- Buy is a secondary button on the Engine card on Company Journey, under Upgrades. Hire stays the one primary action.
- Short cash and a second buy disable the button with a short reason.
- Once it is owned, the New Product picker offers None or Whop Kit Engine. None is the default. A product started on the engine stores +1 score, capped at 10, and names the engine on the build line.
- No engine is the default. The first newsletter still pays 20700 cents and 5 fans.

## How to get to it (user POV)

Start the company. On Company Journey the Engine card shows Whop Kit Engine · $120. The button reads "Buy Whop Kit Engine · Need $120" until a ship covers the price. Press it. The notice reads "Bought Whop Kit Engine. −$120" and the button then reads "Buy Whop Kit Engine · Already owned." Open New Product. Under marketing, Engine offers None and Whop Kit Engine. Choose the kit. The line reads "Whop Kit Engine · +1 score" and "On the build · Whop Kit Engine". Start development. The bench reads "On the build · Whop Kit Engine · +1 score".

## Driving it with capture_journey.gd

The helper snaps `32-engine-offer.png` after Oak Standing Desk is owned, on the Engine card, with the $120 price still on the button. It presses Buy, checks the notice and the second-buy reason, releases the sequel that is still on the bench, opens the picker, selects Whop Kit Engine, and snaps `33-engine-picker.png` on the Engine heading so the +1 score line is in view. It does not start that product. The first newsletter stays on no engine.

## Gotchas

- The picker is hidden until the engine is owned. A new company does not show Engine_none.
- The fee is paid at the buy. Start development does not charge it again.
- A sequel stores no engine. Its score stays on the sequel rules.
- Old rows without an engine field count as no engine and are not rewritten on read.
