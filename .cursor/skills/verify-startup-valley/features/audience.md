# Audience

## Sub-features

- One optional audience when a product starts: Everyone, Regulars, or Newcomers. Everyone is the default.
- The choice sits on the New Product picker, under the focus row, in the same secondary choice-row pattern. Hire stays the one primary action. Start development stays the primary action on the picker.
- Regulars stores +2 fans on a sale when a past release used the same topic. Newcomers stores +2 fans and sells at 90% units. Everyone stores nothing and changes no numbers.
- The effect line and the build line name the choice. A non-Everyone product repeats that line on the journey, the bench, the release card, and the shipped list.

## How to get to it (user POV)

Start the company. Open New Product. Pick Crypto Alpha and Newsletter. Under Focus, Audience offers Everyone, Regulars, and Newcomers. Everyone reads "Everyone · no fan bump" and the build line stays "On the build". Choose Regulars. The line reads "Regulars · +2 fans on a repeated topic" and "On the build · Regulars". Start development. The bench and Company Journey read "On the build · Regulars".

## Driving it with capture_journey.gd

The helper runs this after the focus journey shot. It releases the Design newsletter still on the bench, sets the engine back to None and the focus back to Balanced, selects Regulars, and snaps `36-audience-picker.png` on the Audience heading so the bump and the build line are in view. It starts Crypto Alpha Newsletter and snaps `37-audience-journey.png` on the journey line. Hire Mina stays the footer primary. The first newsletter in the run stays Everyone.

## Gotchas

- A payload without `audienceOptions` draws no audience control.
- Everyone and an older row with no audience field add nothing. The first newsletter still pays 20700 cents and 5 fans.
- Regulars on a first-of-topic product stores the lean and still pays the old cash and fans. The +2 fans wait for a later product that repeats the topic.
- A sequel stores no audience.
- The engine, the focus, and the audience share the picker build line. With Regulars chosen it reads "On the build · Regulars". The product lines stay separate.
