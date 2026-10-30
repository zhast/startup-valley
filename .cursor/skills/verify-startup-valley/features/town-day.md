# Town day

## Sub-features

- Read the Season card. The offer is "Town · Whop Block Picnic this Spring · $20, about 2 fans" plus a Take the afternoon button.
- Take the afternoon. Cash drops by $20. Reputation rises by 2. The line is "Afternoon off · Whop Block Picnic" and the button is gone.
- The next season offers the picnic again. The same season does not.

## How to get to it (user POV)

Open Company Journey. The Season card is under Office. Hire stays the primary action. Take the afternoon is secondary, on the same card as Book booth.

The picnic is Whop Block Picnic in copy only. The fee and the fans are in `docs/TYCOON_DESIGN.md`. At most one afternoon per season. It does not spend an office day.

## Driving it with capture_journey.gd

The main playthrough never takes the afternoon, so `11-season-card.png` still shows the rest of the Season card. A separate save starts with $207 of gifted game cash and no shipped product. The helper snaps `50-townday-offer.png` on the town line, clicks Take the afternoon, and snaps `51-townday-taken.png` with $187.00, 2 reputation, and "Afternoon off · Whop Block Picnic".

## Gotchas

- Replaying the day or reopening the save never charges the fee twice or grants the fans twice.
- Skipping the picnic leaves cash alone. The first newsletter is still $207 and 5 fans.
- A company with less than $20 sees "Need $20" and nothing is written.
