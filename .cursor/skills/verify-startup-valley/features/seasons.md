# Seasons

## Sub-features

- Read the date in plain words. Day 1 is "Spring 1 · Year 1". The next morning is "Spring 2 · Year 1".
- Read the Season card. Spring says "In season: Fitness, Dating Advice". With nobody hired it also says "No payroll yet". Payroll is in `features/payroll.md`. The same card offers a loan; that button is in `features/loans.md`. The same card offers a booth; that button is in `features/expos.md`. The same card offers a town afternoon; that button is in `features/town-day.md`.
- Read the next event. On Spring 2 that line is "Creator Fair in 11 days".
- See "· in season" on a favored topic in the product picker.

## How to get to it (user POV)

Open Company Journey. The date sits on the heading where the day number used to be. The Season card is under Upgrades, in the same card style. Hire stays the primary action. Take loan is a secondary button on that card.

A season is 28 office days. Spring, Summer, Fall, then Winter. The year turns on day 113. Prices and the favored topics are in `docs/TYCOON_DESIGN.md`.

## Driving it with capture_journey.gd

The helper ends the first build day, opens Company Journey, and saves `12-date-label.png` at the top and `11-season-card.png` scrolled to the Season card.

## Gotchas

- The date is derived from the office day. Ending the day moves it forward by one. The summary names the day that just ended.
- Creator Fair is Spring 13. The first newsletter never sells on that day, so the proof does not need the fan bonus.
- A topic outside the favored pair has no "in season" suffix. Crypto Alpha stays plain in Spring.
