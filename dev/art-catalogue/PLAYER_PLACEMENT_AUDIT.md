# Player furniture placement audit

## Current production addendum — September6,2026

All seven active families now have reviewed N/E/S/W production profiles,
including coffee, research and the seated collaboration-cluster-v2. The older
South-only/missing-chair rows below describe the dated September4audit only.
See `PRODUCTION_AND_LIBRARY_CHECKPOINT_20260906.md` and
`../COLLABORATION_PRODUCTION_REVIEW.md` for actual production acceptance.
Renovate remains session-local; Undo, occupied-seat protection, walls and
actor-safe placement pass. No restart persistence, purchasing or new service is
implied. The passive catalogue library is separate from the placed inventory.

## Historical September4audit

Audit date: 2026-09-04. Scope: the ordinary `GameMain` scene at 1280×720,
the production furniture catalogue, wall/corner admission, actor safety, real
mouse/keyboard input, and Undo. This is not an art-approval report and it does
not promote any candidate asset.

## Result

Before this pass, furniture placement existed only in development fixtures.
`DevOfficeLayoutEditor` correctly previewed, validated, rotated, committed and
undid layouts, but the normal game never instantiated it and Settings offered
no route to it. A player could click furniture only to open its work/service
interface. In other words, catalogue tests demonstrated placement while the
actual game did not expose placement at all.

The normal game now has **Settings → Renovate office**. It opens a small
parchment toolbar over the live room and supports:

- click a painted furniture pixel or choose an unlocked item from the selector;
- **M** / Move, then a snapped world click to commit;
- **R** / Rotate through reviewed source views only;
- **U** or **Ctrl/Cmd+Z** to undo a successful edit made during this visit;
- **Escape** to cancel a preview, then Escape again to leave Renovate;
- a green/red native-size ghost, physical-cell outline and plain-language
  rejection feedback.

The full-screen renovation input surface prevents toolbar, rail and placement
clicks from leaking into founder movement. The world clock, schedules and actor
movement pause, while the worker remains independent as it does for other game
UI. Room commits still flow through `TownRoom.set_placement_overrides`, so the
existing navigation rebuild and `GameMain` actor replan path remain canonical.

Native evidence:

- [Settings entry](../../game/tests/output/office-renovation/settings-entry.png)
- [Renovation open](../../game/tests/output/office-renovation/renovation-open.png)
- [Authored West archive preview](../../game/tests/output/office-renovation/authored-rotation-preview.png)
- [Wall/corner rejection](../../game/tests/output/office-renovation/wall-rejection.png)

## What already protects placement

`OfficeLayout.validate_placements` is substantially stronger than the previous
normal-game surface suggested. Every commit checks all office stages 0–4, not
just the room currently visible.

| Risk | Existing authoritative check used by Renovate |
|---|---|
| Physical wall or room-edge overlap | Every occupied cell must be floor and inside the room |
| Art painted into architecture | The exact resolved native `visual_bounds` may cover floor cells only |
| Furniture collision | Occupied cells cannot overlap another placement |
| Misleading near-overlap | Measured/protected visual bounds cannot overlap another furniture visual bound |
| Blocked chair or service side | Clearance, interaction and work cells must remain floor and unoccupied |
| Blocked entrance/main aisle | Entrance and reserved circulation cells cannot be occupied |
| Unreachable station | Interaction and work cells must remain connected to an entrance |
| Room split in two | Every unoccupied floor cell must remain in the entrance component |
| Tall visitor in a wall | Service props validate a native 48×80 standing headroom envelope |
| Passive viewing position in a wall | Each authored standing viewpoint validates its own actor envelope |
| Actor under the new footprint | Live founder/employee foot samples reject the transaction without teleporting anyone |
| Occupied employee desk | Renovate also rejects moving/rotating a workstation while its owner is still at its work cell |
| Furniture changed during travel | The room rebuild cancels/replans founder and employee routes against the new grid |

Invalid previews retain the last committed prop in room state and enter no Undo
record. Cancel restores hidden art. Undo is also transactional and pauses if a
live actor now occupies the layout it would restore.

## Direction inventory in the normal game

The selector calls `OfficeLayout.available_facings`; it never changes a
`Sprite2D.rotation`, flips a texture, mirrors asymmetric lighting, or displays
an unreviewed candidate. At this checkpoint the production-facing inventory is:

| Active family | Normal-game source views | Remaining directional gap |
|---|---|---|
| Desk | North, East, South, West | Complete shared workstation base |
| Artifact archive | North, East, South, West | Complete |
| Coffee station | South | North, East and West |
| Collaboration furniture | North, East, South, West base profiles | Multi-seat chairs/contact/poses and S/W cluster-pivot reconciliation |
| Research table | South | North, East and West |
| Approval console | North, East, South, West | Complete standing service base; no reaching/animated-screen pose claim |
| Prototype bench | North, East, South, West | Complete shared base; profession host kits/use poses remain separate |

This is intentionally an honest runtime inventory, not a count of source-folder
experiments. New options appear automatically only after the exact profile,
native art, geometry, review state and any required character pose capability
pass the production resolver.

## Wall and corner findings

1. Current floor furniture is safely conservative near architecture. Both its
   physical footprint and complete protected art box must remain over floor.
   The invalid native capture shows that moving the founder desk against the
   upper-left wall is rejected before any runtime mutation.
2. A corner is not a separate bitmap orientation today. It is simply a cardinal
   view whose footprint, clearance, art bounds and approach envelope all fit.
   None of the seven active families has a dedicated diagonal/corner source.
3. There is no honest wall-mounted-furniture contract. The protected-art rule
   rejects a shelf/sign intended to rise over a wall cell. If wall-mounted art
   becomes desirable, add an explicit attachment plane and wall-cell contract;
   do not weaken the floor-furniture rule globally.
4. Visual overlap remains conservative. Two items cannot overlap protected art
   boxes even where an artist might expect depth sorting to make the composition
   plausible. This is preferable to clipping for the current catalogue; a later
   decoration system would need authored overlap groups rather than a tolerance.
5. Actor admission is physical, not a ban on natural perspective occlusion.
   Foot samples block furniture materializing through an actor, while tall art
   may still draw in front of an actor who stands behind it. That is the desired
   top-down rule.

## Remaining product gaps

These do not invalidate the runtime placement interaction, but they remain
before Renovate is a complete long-term furnishing system:

- **P1 — persistence:** placement overrides are session-local. The existing
  `game.save` protocol stores player/UI/audio state, not room overrides. Do not
  claim restart persistence until a bounded schema, database migration,
  bootstrap field and new-company reset are implemented and tested.
- **P1 — directional catalogue:** coffee and research remain South-only. The
  collaboration table exposes four validated base views, but its planned
  multi-seat cluster still lacks accepted chairs, contact and poses. The player
  correctly sees fewer choices instead of fake rotations where profiles are
  absent.
- **P1 — durable Undo policy:** Undo history intentionally lasts for one open
  Renovate visit. Cross-restart or cross-session history needs persisted layout
  revisions and is not present.
- **P2 — inventory/economy:** players may relocate unlocked placed furniture;
  there is no owned inventory, purchase, duplicate, sell or storage loop.
- **P2 — discovery:** Settings is explicit but there is no in-world renovation
  station or onboarding beat. Add one only if it earns a place in the game loop;
  do not restore the old permanent prototype plaque.
- **P2 — gamepad/touch:** this pass targets the declared desktop mouse/keyboard
  slice. Controller navigation and drag/touch placement are untested.

## Verification

`res://tests/test_office_renovation.gd` instantiates the ordinary `GameMain`
with the worker disabled and drives real pointer/key events. Headless: **35
checks, zero failures**. Native Metal renderer: **39 checks, zero failures**,
including the three screenshots above. It proves Settings access, full-screen
input ownership, clock/movement pause, alpha-aware world selection, authored
rotation, in-place commit, exact Undo, wall/corner rejection, actor rejection,
cancel restoration, and refusal to fake a missing direction.

The project import and `validate_project.gd` also pass at this checkpoint. The
production-registry pass was concurrently updating legacy assertions in broader
tests; its unrelated stale test expectations are owned by that pass rather than
being hidden or rewritten here.
