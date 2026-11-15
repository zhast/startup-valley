# Office growth

## Sub-features

- See the current office: Garage Loft, then Open Floor.
- Read "Desks: used/total". The count is informational. Story hires are not blocked.
- Buy the Open Floor for $600 game cash after two hires besides the founder. The button reads "Expand office".
- See two compact desks and one shared workbench appear on the existing floor. They face south.

## How to get to it (user POV)

Open Company Journey. The Office card sits under Upgrades and above Season. Hire stays the primary action. Expand office is secondary. It is disabled with "Hire 2 people first." until Mina and Theo are hired, then with "Need $600 game cash." until the cash is there. At the Open Floor the button is gone.

The new desks are spare seats in this room. A second room needs architecture art and is not in this slice. Prices, the headcount gate, and the dev bonus are in `docs/TYCOON_DESIGN.md`.

## Driving it with capture_journey.gd

On the fresh company the helper scrolls to the Office card and saves `13-office-card.png` before any expansion. After the rest of the loop it seeds a company with Mina, Theo, and $600, clicks Expand office, and saves `14-office-expanded-card.png`. It then closes the panel and saves `15-office-new-desks.png` at the normal 1280×720 game view.

## Gotchas

- Theo's hire in the real chapter waits on the website milestone. The proof seeds that flag offline. It does not turn on the fake provider.
- One newsletter cannot pay the $600. The expansion uses seeded game cash.
- The desks use furniture that is already bound. No new art is loaded for this shot.
