# Profit share

## Sub-features

- Read the Train staff card. Each hired teammate except the founder has a one-line hint and a compact secondary Profit share button on the row under Raise.
- Click Profit share. The hint becomes "Sharing · $40 · 10%" for Mina, and the button goes away. The next payday uses that salary. Later sales of a product that stored them pay 10% of the company's cash from that sale, rounded down, and add no fans.
- A second click is not offered. A raise and a profit share do not stack. Let go clears the share, so hiring that person again starts without it.

## How to get to it (user POV)

Open Company Journey after hiring someone. Profit share sits on the Train staff card, under that person's Raise row and above Train. Hire stays the primary action. Profit share is secondary.

A payload without `profitShare` draws no control. The words stay Profit share. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never offers a profit share. A separate save hires Mina, finishes the website milestone, and starts Crypto Alpha Newsletter with Mina on the build for one office day. The helper snaps `92-share-offer.png` on the Train staff card, clicks Profit share, and snaps `93-share-set.png` with the lower salary.

## Gotchas

- The founder fails with "The founder cannot take a profit share."
- An unknown id fails with "Unknown teammate".
- Someone not hired fails with "Mina is not on the team yet." Someone who left fails with "Mina already left."
- A second share fails with "Mina already has a profit share." A raised teammate fails with "Mina already has a raise."
- Pace is applied first. Profit share then subtracts half of the table salary, rounded down, never below zero. Part-time Mina's payday is $0. Switching pace does not clear the share. Craft stays whole.
- Skipping Profit share leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
