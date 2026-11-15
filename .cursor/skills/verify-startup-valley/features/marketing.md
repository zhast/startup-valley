# Marketing

## Sub-features

- Three choices on the product picker: None, Small ad, Big ad. None is the default and spends nothing.
- One line under the buttons names the cost and the unit effect, for example "Small ad · $50 · +20% units".
- A paid ad spends game cash when development starts. Short cash disables the button with "Need $50" or "Need $150".
- The extra units last for that product's sales window. Units stay at least 1. Fans follow units.
- Marketing buttons stay secondary. Hire stays the one primary action on Company Journey.

## How to get to it (user POV)

Start the company. On Company Journey press New Product. Choose Crypto Alpha and Newsletter. None is already selected. With no cash, Small ad reads "Small ad · Need $50" and Big ad reads "Big ad · Need $150". The line reads "None · $0 · no extra units". After a launch pays cash, press Small ad. The line reads "Small ad · $50 · +20% units". Press Start development.

## Driving it with capture_journey.gd

The helper snaps `20-marketing-picker.png` on the first picker, while both ads are short of cash. It leaves that newsletter on None. After Sneakers is researched it buys the small ad on the −20% newsletter, and after Release snaps `21-marketing-released.png` on "Small ad · $50 · +20% units".

## Gotchas

- Skipping the ad buttons keeps the first newsletter at 20700 cents and 5 fans.
- The $50 charge happens at Start development, not at Release.
- Marketing units run after the season boost and before fans. Checkout still changes only the price.
