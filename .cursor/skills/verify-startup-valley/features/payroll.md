# Payroll

## Sub-features

- Read the Season card. With no hires the line is "No payroll yet".
- With Mina hired, the line is "Payroll · $80 on Spring 28".
- End Spring 28. The summary says "Payroll: Spring" and "Paid payroll · −$80".
- The next morning the header says cash is negative, and the Season card still shows the paid notice. The next line is "Payroll · $80 on Summer 28".
- End that next day. The notice is gone. Cash is still −$80.

## How to get to it (user POV)

Open Company Journey. The Season card is under Office. Hire stays the primary action. There is no payroll button.

Salaries, the payday, and the ledger id are in `docs/TYCOON_DESIGN.md`. The founder is not paid.

## Driving it with capture_journey.gd

The main playthrough never hires, so `11-season-card.png` still shows "No payroll yet". A separate save hires Mina and sets the clock to Spring 28. The helper snaps `40-payroll-season-card.png` on that Season card, ends the day, and snaps `41-payroll-paid.png` the next morning.

## Gotchas

- Payday is the last day of the season. Ending Spring 27 does not pay.
- The notice is the morning after payday. Ending that next day clears it. Reopening the save keeps the debt and drops the notice.
- Cash can go below zero. The engine button then says "Need $120". There is no game over.
