# Small beginnings, a bigger world

Reference and implementation audit, 2026-11-15. This uses official product
descriptions, a developer-published gameplay screenshot, local source inspection,
and native rendering of Startup Valley's room. Neither reference game was run
locally. The room captures are native fixtures for new, first-hire and expanded states, not a browser save.

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
original `office_layout.json` starts with a 34×18 floor (614 walkable cells
including its entrance), although the first employee needs only one part of it.
Its walls nearly fill the playable screen. This can feel simultaneously empty
and enclosed. That diagnosis is an inference from the source dimensions and
room captures, not a measured player study. New companies now use the compact
layout described below; existing companies retain their original geometry.

## Implemented room changes

`OfficeDaylight` now adds static, warm window light to the floor. It is clipped to
the actual floor cells, painted under furniture and characters, and made faint
and cool in the evening theme. It makes the existing landscape windows more
connected to the interior. No new art files, click targets, walking cells, props,
or saved coordinates were introduced.

New companies now start in `office_layout_starter.json`: a 23×12 main room
with an entrance alcove, **288 walkable cells rather than 614**. Two windowed
workstations, a coffee/archive side and a shared-table side divide the space.
The existing café table, chair and plant are placed from owned inventory. They
can still be moved or stored through the normal furnishing system.

The building is surrounded by the existing native-size `campus-surround.png`,
revealing trees, a garden path and water. Its pixels are unchanged; this is reuse
of legacy artwork, not a new generation or a claim about its original author.
The cutaway floor, north walls, trim and door still come from the same logical
geometry as navigation. **The garden is scenery; outdoor travel is not yet
implemented.** Clicking it hits the existing non-walkable-cell rejection, and
keyboard movement meets the same architecture collision as any other wall.

`game/tests/test_starter_office.gd` produces new-company, first-hire and expanded
native captures in `game/tests/output/starter-office-current/`. It verifies
actual interaction paths, exterior collision, atomic projection rejection and
layout changes. Worker migration and rollback checks live in
`harness/test/compact-office.test.ts`; browser SQLite parity also starts with the
compact identity. Retained native room-composition captures: [new company](assets/starter-office/02-new-company.png), [first hire](assets/starter-office/01-starter-with-mina.png), and [expanded studio](assets/starter-office/03-expanded-studio.png). These captures record this layout checkpoint; character-art acceptance is tracked separately.

Native before/after/evening captures are produced by
`game/tests/test_office_daylight.gd` under
`game/tests/output/office-daylight-current/`. Checks verify floor clipping,
unchanged furniture/floor geometry, prop layering, theme changes, and all five
hire stages. The existing layout and architecture tests remain relevant gates.

## Proposed playable hybrid, in order

1. **A compact rented studio — implemented.** The original 18×12 target was
   expanded to a validated 23×12 main room and small entrance alcove so the real
   furniture, chair poses and shared-table headroom remain clear. The founder
   and Mina start here; existing companies are never silently shrunk.
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
5. **An earned move.** The current implementation moves to the larger office
   when the existing hiring progression needs a third studio member or the
   player purchases office level 2. A future story pass can put this move after
   several releases if the authoritative progression rules change.
   Introduce more teammates, specialist workspaces, contracts, and deeper project
   options in that phase. Keep story milestones separate from optional long-term
   achievements, with completion derived from durable worker records.

## Save and expansion contract

Migration 017 adds one durable `office_layout_state` identity per company.
Existing companies receive `startup-office`. Only a database without prior
company/schema records receives `starter-cottage-v1`; that selection commits
with the schema migration, so an interrupted first boot cannot change its mind
on restart. The worker includes the identity in the furnishing projection.
Godot admits only the two shipped definitions and validates the entire incoming
inventory/placement snapshot before replacing any visible or physical state.
Old projections without an identity still mean `startup-office`.

The cottage supports the founder and Mina. Hiring another teammate, reaching
two hired teammates, or obtaining office level 2 selects the existing full room
inside the same transaction as the grant/hire/upgrade. Essential stations move
as a complete validated batch. Compatible placed decorations stay in place;
others remain owned in storage. The saved player moves to a safe entrance while
settings and onboarding fields remain intact. The furnishing revision advances,
so stale edits cannot apply to the new room. A failed write rolls back hiring,
charges, grants, layout, placements and player coordinates together.

The larger room never automatically shrinks after staff leave. Existing saves
retain exact compatible furniture and player coordinates. Neither layout adds
a new API dependency, production rule, achievement, or playable outside map.
