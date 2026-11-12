# Part-time

## Sub-features

- Read the Train staff card. Each hired teammate except the founder has a compact secondary Part-time button on the stats row, beside Let go.
- Click Part-time. That person's line gains "· part-time". The button reads Full time. Later office days add half their design, tech, and hype, rounded down. Season salary is half, rounded down. Days already worked stay.
- Click Full time. The hint goes away and the next days and the next payday use the full pace again.

## How to get to it (user POV)

Open Company Journey after hiring someone. Part-time sits on the Train staff card, beside that person's design, tech, and hype, and beside Let go. Hire stays the primary action. Part-time and Full time are secondary.

A payload without `pace` draws no control. The words stay Part-time and Full time. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never changes pace. A separate save hires Mina, finishes the website milestone, and starts Crypto Alpha Newsletter with Mina on the build for one office day. The helper snaps `86-parttime-offer.png` on the Train staff card, clicks Part-time, and snaps `87-parttime-set.png` with the part-time status.

## Gotchas

- The founder fails with "The founder stays full time."
- An unknown id fails with "Unknown teammate". A bad pace fails with "Pick full time or part-time."
- Someone not hired fails with "Mina is not on the team yet." Someone who left fails with "Mina already left."
- The same pace fails with "Mina is already full time." or "Mina is already part-time."
- Let go clears a part-time pace. Hiring that person again starts them full time.
- Skipping Part-time leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
