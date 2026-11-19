# Raise

## Sub-features

- Read the Train staff card. Each hired teammate except the founder has a one-line hint and a compact secondary Give raise button on the row under Let go and Part-time.
- Click Give raise. The hint becomes "Raised · $120 · +1 hype" for Mina, and the button goes away. The next payday uses that salary. Later office days add 1 to the lowest craft stat stored on the build.
- A second click is not offered. Let go clears the raise, so hiring that person again starts without it.

## How to get to it (user POV)

Open Company Journey after hiring someone. Give raise sits on the Train staff card, under that person's Let go and Part-time row and above Train. Hire stays the primary action. Give raise is secondary.

A payload without `raise` draws no control. The words stay Give raise. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never gives a raise. A separate save hires Mina, finishes the website milestone, and starts Crypto Alpha Newsletter with Mina on the build for one office day. The helper snaps `90-raise-offer.png` on the Train staff card, clicks Give raise, and snaps `91-raise-given.png` with the new salary.

## Gotchas

- The founder fails with "The founder cannot take a raise."
- An unknown id fails with "Unknown teammate".
- Someone not hired fails with "Mina is not on the team yet." Someone who left fails with "Mina already left."
- A second raise fails with "Mina already has a raise."
- Part-time halves the table salary first. The raise adds half of that paced salary, rounded down. Switching pace does not clear the raise.
- The +1 uses the snapshot's lowest stat before the half. A tie prefers design, then tech, then hype.
- Skipping Raise leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
