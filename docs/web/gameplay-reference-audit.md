# Small beginnings, a bigger world

Reference and implementation audit, 2026-11-15. This uses official product
descriptions, a developer-published gameplay screenshot, local source inspection,
and native rendering of Startup Valley's room. Neither reference game was run
locally. The current room captures are a one-hire fixture, not a browser save.

## What the references establish

[Game Dev Tycoon's official description](https://www.greenheartgames.com/app/game-dev-tycoon/)
starts with a small garage and simple projects. Experience unlocks additional
options; several releases lead to a larger office and a team. Development focus
affects the result. The developer's [Steam listing](https://store.steampowered.com/app/239820/Game_Dev_Tycoon/)
also names game reports, research, custom engines, larger offices, and achievements.
The published [garage screenshot](https://shared.steamstatic.com/store_item_assets/steam/apps/239820/ss_96e6ab31f1bcd3a879bf7f96fe7e660682c31eef.1920x1080.jpg?t=1737607927)
shows one developer, one active project, and a small room surrounded by open
screen space. These sources support a gradual opening and a visible production
loop; they do not establish an exact first-hour balance or every input gesture.

[Stardew Valley's official introduction](https://www.stardewvalley.net/)
establishes a personal arrival, a place to improve, and a surrounding community.
Its activities include farming, fishing, gathering, crafting, and exploring;
befriending residents is a distinct part of the game. The useful lesson here is
a daily life around production, not copying farm activities into a software office.

Design inference: combine Tycoon's repeated **choose → develop → release →
learn → reinvest** loop with Stardew's **arrive → meet people → choose a day →
notice the place changing** rhythm. Our office and characters keep their own art,
story, and controls.

## What this repo already has

The authoritative worker already supplies topic/format fit, development days,
staff participation, reviews, sales, research, upgrades, office levels, a seasonal
calendar, events, and town-day actions. The browser's new current-goal card,
Mina conversation, simple planning screen, and release celebration give these
systems a much clearer opening.

The remaining weakness is the connection between them. Most production progress
still arrives by ending a day in a panel. Outside life is mostly menu data. The
room does not visibly grow with the early story: `office_layout.json` starts with
a 34×18 floor (614 walkable cells including its entrance), although the first
employee needs only one part of it. Its walls nearly fill the playable screen.
This can feel simultaneously empty and enclosed. That diagnosis is an inference
from the source dimensions and room captures, not a measured player study.

## Implemented bounded improvement

`OfficeDaylight` now adds static, warm window light to the floor. It is clipped to
the actual floor cells, painted under furniture and characters, and made faint
and cool in the evening theme. It makes the existing landscape windows more
connected to the interior. No new art files, click targets, walking cells, props,
or saved coordinates were introduced.

This is a warmth and outside-presence improvement. **The office is not physically
smaller yet, and the entrance does not pretend to lead to a playable town.**

Native before/after/evening captures are produced by
`game/tests/test_office_daylight.gd` under
`game/tests/output/office-daylight-current/`. Checks verify floor clipping,
unchanged furniture/floor geometry, prop layering, theme changes, and all five
hire stages. The existing layout and architecture tests remain relevant gates.

## Proposed playable hybrid, in order

1. **A compact rented studio.** Target an approximately 18×12 playable-cell room
   for the founder and Mina, with two desks, a shared coffee corner, one plant,
   and generous walking space. Show a strip of garden or pavement outside the
   cutaway building so the office reads as one place in a larger world. Keep
   the project desk as the opening's one main destination. Room size is a design
   target to validate with actual furniture envelopes, not an accepted layout.
2. **A meaningful first workday.** Meet Mina, choose a small project, then make
   one concrete craft choice at the desk. Give the player an optional short
   conversation or coffee break before wrapping up. Reuse the existing worker
   day-plan rules; do not make decorative typing create unearned progress.
3. **A release with a consequence.** Keep the current celebration and add a
   concise project report: one thing that worked, one lesson, and one unlocked
   possibility. Tie these to saved fit/review/research data. Let the first earned
   improvement visibly change the studio rather than presenting the entire
   management catalogue at once.
4. **A small outside destination.** Add one actual courtyard/café map and one
   named resident before attempting a whole town. A visit should offer a real
   choice already supported by the worker, such as a town day, an event, or
   learning about a new topic. Returning must preserve the office, player room,
   and day state. A locked door is honest until that map and transition exist.
5. **An earned move.** After several releases, move to the larger current office.
   Introduce more teammates, specialist workspaces, contracts, and deeper project
   options in that phase. Keep story milestones separate from optional long-term
   achievements, with completion derived from durable worker records.

## Safe smaller-office migration

Do not just reduce `floor_rects`. The current definition registers future desks
and research/service stations on its right side. The worker validates furniture
and persists positions; Godot independently verifies the same geometry. Arbitrary
shrinking can invalidate future hires, saved decorations, and player coordinates.

Implement the smaller office as a versioned layout with a worker-owned `layoutId`
and explicit room selection, then:

- Keep existing companies on their current layout until an intentional move.
- Seed new companies from the compact layout's own validated furniture defaults.
- When moving, atomically store the new layout, essential stations, retained
  inventory, and a safe entrance spawn. Unplaced decoration stays in inventory.
- Test every required station, seat, approach, and clearance; run worker/Godot
  geometry parity and path connectivity for each supported room and hire stage.
- Test save/reload, interrupted migration, two-tab ownership, returning from an
  outside map, and a player previously standing where new furniture will go.

The migration should land with the new room, not as a silent change to everyone's
existing coordinates. The current daylight layer deliberately avoids that risk.
