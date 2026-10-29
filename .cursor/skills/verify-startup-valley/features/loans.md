# Loans

## Sub-features

- Read the Season card. The offer is "Loan · $500, repay $550 on Spring 28" plus a Take loan button.
- Take the loan. Cash becomes $500. The line is "Loan due · $550 on Spring 28" and the button is gone.
- End the due payday. The summary says "Loan repaid". Cash is $500 minus $550.
- The next morning the offer returns. A second loan can be taken.

## How to get to it (user POV)

Open Company Journey. The Season card is under Office. Hire stays the primary action. Take loan is secondary.

The lender is Whop Treasury in the ledger label only. Amount, fee, and the due payday are in `docs/TYCOON_DESIGN.md`. At most one loan is out at a time.

## Driving it with capture_journey.gd

The main playthrough never takes a loan, so `11-season-card.png` still shows the offer. A separate save starts a fresh company. The helper snaps `42-loan-offer.png` on that Season card, clicks Take loan, and snaps `43-loan-taken.png` with $500.00 and "Loan due · $550 on Spring 28".

## Gotchas

- A loan taken on payday itself waits until the next season, so the same evening does not take the $550 back.
- Replaying the day end or reopening the save never pays or repays twice.
- Skipping the loan leaves cash alone. The first newsletter is still $207 and 5 fans.
