# Main office design

The office is Startup Valley's primary play space: the equivalent of the homestead in a cozy farming game. The town supports exploration and future expansion, but the office is where the player reads the company at a glance and performs the core management loop.

The key art is `startup-valley-main-office-key-art.png`. It is a visual target rather than a runtime tile map.

## Floor plan

Keep the existing 26 × 18 logical grid and a single-floor cutaway view. Exact prop footprints can change during tile-map production, but the relationships should remain stable.

| Zone | Approximate grid | Gameplay purpose |
| --- | --- | --- |
| Entry and dispatch | x 8–17, y 14–17 | Start assignments, see the active work order, and enter the main circulation loop. |
| Central studio | x 6–19, y 5–14 | Three employee desks, quick player access, and visible work-state animation. |
| Collaboration hub | x 10–16, y 7–12 | Social beats, team moments, morale, and a visual resting point. |
| Meeting, kitchen, lounge | x 0–6, y 0–15 | Conversations, breaks, schedule phases, and a warmer counterweight to the machines. |
| Research lab | x 18–25, y 0–6 | Research and specialized tool activity, visible behind glass. |
| Servers and approvals | x 18–25, y 6–11 | Infrastructure status and a distinct amber signal when player approval is required. |
| Artifact workshop | x 18–25, y 11–17 | Review completed output, browse durable studio files, and stage promoted artifacts. |

## Movement rules

- Preserve one obvious loop around the central hub, with primary paths at least two tiles wide.
- Keep the entrance, every desk, and every interaction station reachable without crossing another station's footprint.
- Give each employee a clear desk approach tile and a nearby idle tile.
- Use glass partitions instead of solid walls where activity should remain visible.
- Keep the middle visually quiet enough that character movement and job-state effects remain readable.

## System-to-space mapping

| System event | Physical response |
| --- | --- |
| Assignment created | Dispatch board wakes; assigned employee walks to their desk. |
| Job running | Desk displays animate; employee alternates between desk and relevant specialist station. |
| Research or tool use | Employee visits the lab, maker bench, server room, or archive according to the event. |
| Approval required | East approval console pulses amber and the employee pauses nearby. |
| Artifact created | Artifact station gains a package, printout, or display object that the player can inspect. |
| Job completed | Desk settles, artifact station updates, and the employee returns to an idle or social routine. |
| Lunch or off-hours | Employees favor the kitchen, lounge, meeting room, plants, and central seating. |

## Upgrade hooks

Keep the building shell and circulation fixed while allowing individual modules to improve: desks, lab equipment, server capacity, meeting room, artifact archive, coffee area, planters, and drone dock. This makes progression visible without forcing the player to relearn the floor plan.
