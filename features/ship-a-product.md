# Ship a product

## Sub-features

- Pick a topic and a product type. Locked rows stay on the list with "· locked" and cannot be selected.
- Read the fit line and who is on the build, including current design, tech, and hype.
- Start development, end office days until the bench says Ready to ship, then Release.
- Read the score, launch sales, fans, and "+N research points".

## How to get to it (user POV)

Start the company. On Company Journey press New Product. Choose an unlocked topic and an unlocked type. Press Start development. Press End day + save, then Begin next day, until the bench is ready. Press Release.

Crypto Alpha and Newsletter are unlocked on a new company. Fitness × Software Tool is the opening pair, and Software Tool starts locked, so Start development stays off until an unlocked type is chosen.

## Driving it with capture_journey.gd

The helper opens New Product, checks Sneakers is disabled and labeled locked, and saves `03-picker-locked.png`. It then clicks Crypto Alpha, Newsletter, and Start development. After two End day clicks it clicks Release and saves `04-release-research.png`, which includes the "+3 research points" line for this seed.

## Gotchas

- Connect stays closed on the picker, the bench, and the release card.
- The product keeps the staff snapshot from the day development started.
- A second Start development is refused while a product is still on the bench.
