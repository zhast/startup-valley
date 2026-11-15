# Focus

## Sub-features

- One optional focus when a product starts: Balanced, Design, Tech, or Hype. Balanced is the default.
- The choice sits on the New Product picker, under the engine row, in the same secondary choice-row pattern. Hire stays the one primary action. Start development stays the primary action on the picker.
- Design, Tech, or Hype stores +1 on that stat. The add stops at 10. Balanced stores nothing and changes no numbers.
- The effect line and the build line name the choice. A focused product repeats that line on the journey, the bench, the release card, and the shipped list.

## How to get to it (user POV)

Start the company. Open New Product. Pick Crypto Alpha and Newsletter. Under the engine row, Focus offers Balanced, Design, Tech, and Hype. Balanced reads "Balanced · no point bump" and the build line stays "On the build". Choose Design. The line reads "Design · +1 design" and "On the build · Design". Start development. The bench and Company Journey read "On the build · Design · +1 design". The design points show the extra point before the first office day.

## Driving it with capture_journey.gd

The helper runs this after the engine picker shot. It sets the engine back to None, selects Design, and snaps `34-focus-picker.png` on the Focus heading so the bump and the build line are in view. It starts Crypto Alpha Newsletter and snaps `35-focus-journey.png` on the journey line. Hire Mina stays the footer primary. The first newsletter in the run stays Balanced.

## Gotchas

- A payload without `focusOptions` draws no focus control.
- Balanced and an older row with no focus field add nothing. The first newsletter still pays 20700 cents and 5 fans.
- The bump is once on the shown points and on the review. Office days do not add it again.
- A sequel stores no focus.
- The engine and the focus share the picker build line. With both chosen it reads "On the build · Whop Kit Engine · Design". The product lines stay separate.
