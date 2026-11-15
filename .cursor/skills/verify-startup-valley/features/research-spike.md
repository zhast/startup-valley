# Research spike

## Sub-features

- Read the card for the product in development. The line is "Research spike · tomorrow's craft becomes research points" with one secondary button, Research spike.
- Click Research spike. The line becomes "Spike set · tomorrow's craft becomes research points" and the button is gone. The day has not started.
- End that office day. The line becomes "Spike done · +6 research points" for a founder-only day. The day counts. Design, tech, and hype stay where they were. The Research card shows the balance, which also includes the usual point per working person.

## How to get to it (user POV)

Open Company Journey while a product is on the bench. The row sits under Team and above New Product, with the publisher deal, the press demo, the feature, the day plan, bugs, crunch, early access, cancel, slip, pivot, playtest, and the team. Hire stays the primary action. Research spike is secondary.

A payload without `researchSpike` draws no control. The words stay Research spike. The rules are in `docs/TYCOON_DESIGN.md`. There is no fee.

## Driving it with capture_journey.gd

The main playthrough never spikes. A separate save starts Crypto Alpha Newsletter and gifts no cash. The helper snaps `80-spike-offer.png` on the Research spike line, clicks Research spike, ends the office day, and snaps `81-spike-done.png` on Spike done · +6 research points.

## Gotchas

- Nothing on the bench fails with "No product is on the bench."
- A second request while the spike is waiting fails with "A research spike is already set."
- A request after the spike day fails with "This build already used its research spike."
- The done line shows the craft converted. The Research card shows the company balance, which is one higher on a founder-only day.
- Skipping Research spike leaves the first newsletter at $207 and 5 fans. The next office day is still $333.
