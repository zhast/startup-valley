# Size

## Sub-features

- One optional length when a product starts: Catalog, Short, or Long. Catalog is the default.
- The choice sits on the New Product picker, under the audience row, in the same secondary choice-row pattern. Three buttons share one compact row. Hire stays the one primary action. Start development stays the primary action on the picker.
- Short takes one fewer build day, never below one, and sells at 90% units. Long adds one build day and sells at 110% units. Catalog stores nothing and changes no numbers.
- The effect line and the build line name the choice. A non-Catalog product repeats that line on the journey, the bench, the release card, and the shipped list.

## How to get to it (user POV)

Start the company. Open New Product. Pick Crypto Alpha and Newsletter. Under Audience, Size offers Catalog, Short, and Long. Catalog reads "Catalog · same length" and the build line stays "On the build". Choose Long. The line reads "Long · +1 day · +10% units" and "On the build · Long". Start development. The bench and Company Journey read "On the build · Long".

## Driving it with capture_journey.gd

The helper runs this after the audience journey shot. It releases the Regulars newsletter still on the bench, sets the engine back to None, the focus back to Balanced, and the audience back to Everyone, selects Long, and snaps `38-size-picker.png` on the Size heading so the day and unit lines are in view. It starts Crypto Alpha Newsletter and snaps `39-size-journey.png` on the journey line. Hire Mina stays the footer primary. The first newsletter in the run stays Catalog.

## Gotchas

- A payload without `sizeOptions` draws no size control.
- Catalog and an older row with no size field add nothing. The first newsletter still takes 2 office days and still pays 20700 cents and 5 fans.
- Short on that same first newsletter takes 1 office day and pays 18900 cents and 4 fans. Long takes 3 office days and pays 22500 cents and 5 fans. The review score stays 6. The ideal moves with the required days, so the ratio does not.
- A sequel stores no size. Its days stay on the sequel rule.
- The engine, the focus, the audience, and the size share the picker build line. With only Long chosen it reads "On the build · Long". The product lines stay separate.
