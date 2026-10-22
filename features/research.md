# Research

## Sub-features

- See the research point balance.
- See one secondary button per locked topic and type, disabled when the balance is short.
- Unlock one item. Read "Unlocked Sneakers. −4 RP" on that office day.
- Start a product on the topic that just unlocked. The picker drops "· locked" for that row.

## How to get to it (user POV)

Open Company Journey. The Research card sits under Train staff. A new company shows "0 research points" and a button such as "Research Sneakers · 4 RP". Points arrive from days spent building and from the release. Press a button you can afford. The card hides when nothing is left to unlock.

Prices, the starter catalog, and what an old save unlocks are in `docs/TYCOON_DESIGN.md`.

## Driving it with capture_journey.gd

On the first journey the helper scrolls to the Research card and saves `02-research-card.png` (the balance is 0, so the buttons are disabled). After the newsletter ships it clicks Research Sneakers and saves `07-research-unlocked.png`. It then starts Sneakers Newsletter and saves `08-sneakers-started.png`.

## Gotchas

- A topic costs more points than one build day. Ship, or keep building, before the button enables.
- The unlock line clears when the office day ends, same as a training notice.
- `tycoon.start` rejects a locked topic or type even if the picker is bypassed.
