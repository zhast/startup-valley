# Train staff

## Sub-features

- See each hired person with design, tech, and hype.
- Pay game cash to raise one stat by 1. The button reads "Train Tech · $300.00" for Founder Tech at 2.
- Read the lesson line on that office day only.
- See the new stat on the next product's picker line ("tech 3").

## How to get to it (user POV)

Open Company Journey. The Train staff card sits under New Product. Hire Mina stays the primary action in the footer. Train buttons are secondary. One lesson per person per office day. Ending the day clears the lesson line.

The first Tech lesson costs $300. A newsletter launch plus the next sales days covers it.

## Driving it with capture_journey.gd

After the newsletter release, the helper ends two more office days, clicks Train Tech, and saves `05-trained-notice.png` while "Founder trained Tech to 3. −$300" is on screen. It then ends the day and saves `06-notice-gone.png` with that line absent.

## Gotchas

- The train card prints "T 3". The picker prints "tech 3". Check the picker for the trained stat.
- A person in training that day adds no craft points and no research points.
- The lesson does not change the product already on the bench.
