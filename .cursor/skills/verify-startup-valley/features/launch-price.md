# Launch price

## Sub-features

- Three steps on the product picker: −20%, Catalog, +20%. Catalog is the default.
- One line under the buttons names the unit price and the unit effect, for example "$7.20 · +20% units".
- The choice is stored on the product when development starts. A cheaper price sells more units. A higher price sells fewer. Units stay at least 1. Fans follow units.
- Price buttons stay secondary. Hire stays the one primary action on Company Journey.

## How to get to it (user POV)

Start the company. On Company Journey press New Product. Choose Crypto Alpha and Newsletter. Catalog is already selected and the line reads "$9.00 · catalog units". Press −20% to see "$7.20 · +20% units". Press Start development.

## Driving it with capture_journey.gd

The helper leaves the first newsletter on Catalog. After Sneakers is researched it clicks −20%, saves `18-price-picker.png` on the unit-effect line, starts that product, and after Release saves `19-price-released.png` with "$7.20 · +20% units".

## Gotchas

- Skipping the price buttons keeps the first newsletter at 20700 cents and 5 fans.
- The checkout-page upgrade still boosts only the unit price, after the launch-price percent.
- Season +20% units runs after the launch-price unit effect.
