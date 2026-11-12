# Let someone go

## Sub-features

- Read the Train staff card. Each hired teammate except the founder has a compact secondary Let go button on the stats row.
- Click Let go. That person leaves the company. The line becomes "Mina left the company." The button is gone. A build that listed them drops them. Days and points already earned stay.
- Payroll no longer includes them. Hiring them again is the usual hire, when the other gates still pass.

## How to get to it (user POV)

Open Company Journey after hiring someone. Let go sits on the Train staff card, beside that person's design, tech, and hype. Hire stays the primary action. Let go is secondary.

A payload without `letGo` draws no control. The words stay Let go. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never dismisses anyone. A separate save hires Mina, finishes the website milestone, and starts Crypto Alpha Newsletter with Mina on the build for one office day. The helper snaps `84-letgo-offer.png` on the Train staff card, clicks Let go, and snaps `85-letgo-done.png` on Mina left the company.

## Gotchas

- The founder fails with "The founder stays."
- An unknown id fails with "Unknown teammate". A bad payload fails with "Invalid protocol request".
- Someone not hired fails with "Mina is not on the team yet."
- A second request fails with "Mina already left."
- Skipping Let someone go leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
