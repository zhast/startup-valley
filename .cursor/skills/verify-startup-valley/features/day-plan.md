# Day plan

## Sub-features

- Read the card for the product in development. The line is "Day plan · Even · design, tech, and hype as usual" plus Even, Design, Tech, and Hype.
- Pick Design. Cash stays put. The line is "Day plan · Design · today's craft goes to design" and Design stays selected.
- Pick Even again. The line returns to the even split. The same plan twice does not error.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits with the publisher deal, the press demo, and the feature, above New Product. Hire stays the primary action. The four choices are secondary.

The stat names stay Design, Tech, and Hype. The rules are in `docs/TYCOON_DESIGN.md`. Even is the default. An emphasis spends that day's personal craft on one stat. Tool and office bonuses stay on their own stats. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never changes the day plan. A separate save starts Crypto Alpha Newsletter with no gifted cash. The helper snaps `62-dayplan-offer.png` on the Even line, clicks Design, and snaps `63-dayplan-design.png` with $0.00, 0 reputation, and "Day plan · Design · today's craft goes to design".

## Gotchas

- Replaying the day or reopening the save keeps the plan that was set. It does not apply the emphasis twice for one office day.
- Skipping the plan leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
- With nothing on the bench the call says "No product is on the bench."
- A payload without `dayPlan` and without `dayPlanOptions` draws no control.
