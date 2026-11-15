# Rivals

One competing creator shop per season. Shipping that shop's topic makes the opening quieter.

- Open Company Journey. The Season card names the shop and the topic.
- Open New Product. Select that topic. A short warning says opening demand drops.
- Ship a different topic. The warning stays hidden, and the sale is unchanged.

## Where

The Season card line sits under "In season". In Spring it reads "Rival: Pip's Pop-up is pushing Cooking this season". The picker warning sits under the topic grid, only while that topic is selected. It reads "Rival · opening demand drops." Hire stays the primary action. There is no new button.

The shop and the topic repeat every year. The cut is 90 percent of opening demand, stored once at release. Prices are in `docs/TYCOON_DESIGN.md`.

## Proof

The diary save is still Spring. The helper snaps `58-rival-season.png` on the Season card line, opens the product picker, selects Cooking, and snaps `59-rival-picker.png` with the warning.

## Checks

- Fitness, Trading, and Crypto Alpha show no warning in Spring.
- Cooking shows the warning, and the topic button text stays "Cooking".
- Skipping Cooking leaves the first newsletter at $207 and 5 fans, and the next office day at $333.
