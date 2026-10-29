# Expos

## Sub-features

- Read the Season card. The offer is "Expo · Whop Creator Fair on Spring 14 · $60 booth, about 3 fans" plus a Book booth button.
- Book the booth. Cash drops by $60. The line is "Booth booked · Whop Creator Fair on Spring 14" and the button is gone.
- End the fair day. The summary says "Expo: Whop Creator Fair". Reputation rises by 3. Cash does not.
- The next morning the line moves to the next fair and Book booth is back.

## How to get to it (user POV)

Open Company Journey. The Season card is under Office. Hire stays the primary action. Book booth is secondary, on the same card as Take loan.

The fair is Whop Creator Fair in copy only. The fee, the fans, and the fair day are in `docs/TYCOON_DESIGN.md`. At most one booth per fair.

## Driving it with capture_journey.gd

The main playthrough never books a booth, so `11-season-card.png` still shows the offer once the company has reached that card. A separate save starts with $207 of gifted game cash and no shipped product. The helper snaps `46-expo-offer.png` on that Season card, clicks Book booth, and snaps `47-expo-booked.png` with $147.00 and "Booth booked · Whop Creator Fair on Spring 14".

## Gotchas

- Replaying the fair day or reopening the save never charges the fee twice or pays the fans twice.
- Skipping the booth leaves cash alone. The first newsletter is still $207 and 5 fans.
- A company with less than $60 sees "Need $60" and nothing is written.
