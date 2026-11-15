# Assign the team

## Sub-features

- Read the card for the product in development. The line is "Team: Founder" while only the founder is on the build, with one secondary toggle per hired person.
- Click a person who is sitting out. They join. The line becomes "Team: Founder, Mina". Days and points already earned stay.
- Click a person who is on the build. They leave, unless they are the last person. At least one person stays.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Playtest and above the research spike, with the publisher deal, the press demo, the feature, the day plan, bugs, crunch, early access, cancel, slip, pivot, and playtest. Hire stays the primary action. Team toggles are secondary.

A payload without `team` draws no control. The word stays Team. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never assigns the team. A separate save starts Crypto Alpha Newsletter, hires Mina, and gifts no cash. The helper snaps `78-team-offer.png` on the Team line, clicks Mina, and snaps `79-team-changed.png` on Team: Founder, Mina.

## Gotchas

- Nothing on the bench fails with "No product is on the bench."
- An empty list fails with "Pick at least one teammate."
- An unknown id fails with "Unknown teammate".
- Assigning the same people again is a no-op.
- Skipping Assign the team leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
