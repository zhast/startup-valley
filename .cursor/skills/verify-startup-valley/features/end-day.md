# End day

## Sub-features

- End day + save from Company Journey, or from the product bench.
- Read the day summary, then press Begin next day.
- Clear the training lesson line, the research unlock line, and the upgrade purchase line.
- Award one research point for each person on the build who is not in training.

## How to get to it (user POV)

Press End day + save. The notebook shows the day summary. Press Begin next day. The office clock returns to 08:00 on the next day. The journey no longer shows yesterday's lesson or unlock line.

On the bench, End day + save is the way a product gains a build day. Two of those days make a newsletter ready to release.

## Driving it with capture_journey.gd

The helper presses End day + save and Begin next day between every step that needs a new office day: the two build days, the two sales days that pay for training, and the day that clears the lesson line before `06-notice-gone.png`. It sets the day-clock speed to 0 so the clock does not race ahead.

## Gotchas

- Ending a day that already has a summary does not tick the tycoon again and does not award another research point.
- Begin next day closes the notebook. Press J, or open Company Journey from the office, to see the next cards.
- Active AI work blocks End day. The tycoon proof never starts a work order, so the button stays available.
