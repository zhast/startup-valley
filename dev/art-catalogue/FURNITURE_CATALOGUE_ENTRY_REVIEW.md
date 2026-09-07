# Safe interactive furniture catalogue

2026-09-04. New dev-only entry, not production furniture admission. Existing
showrooms, source exports, passive fixtures, runtime code and prior reports are
unchanged. No images were generated or modified by this task.

## Try it

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --path game --script res://tools/play_furniture_catalogue.gd
```

Use the bottom-left prototype menu to choose **Planning whiteboard**, **Rolling
pedestal**, **Acoustic divider**, or **Low resource shelf**. Only one candidate
is in the room at a time. **Switching starts a fresh local layout and clears
Undo**, as disclosed in the menu tooltip and opening status. It also restores
the disposable scene's starting actors; it is not a persistent design session.

Choose a facing, or press **R**. **M** enters movement preview; click a valid
floor cell to commit. **Escape** cancels the preview; **U** undoes the last
committed local placement. Invalid wall, occupied-footprint and actor clearance
remain the existing canonical editor's responsibility. Close the window to exit.
Normal world movement remains available outside editing; no new gameplay action
is assigned to these passive props.

Connect, chat-send and assignment controls are explicitly disabled and labeled
as a preview. The null transport is installed before GameMain enters the tree;
no worker process/pipe, credential read, saved-company bootstrap, save or layout
export is opened. Even direct `export_layout()` refuses. Headless use without
`--smoke-test` deliberately exits **2** before creating a scene.

## Implementation and safety

- [New fixture](../../game/tools/furniture_catalogue_fixture.gd) resolves the
  existing exact four-facing profile provider for the selected family only.
  It uses the already-tested owner-scoped decorative admission. All art and
  geometry review flags remain false; no production catalogue is modified.
- [New entry](../../game/tools/play_furniture_catalogue.gd) replaces and frees
  the prior scene on selection; every former model loses its live permit.
  Multiple requests before deferred setup coalesce to the last requested type.
  Setup itself is synchronous; no unfinished setup coroutine can later free
  a newer scene. Tests cover a three-request burst, one final fixture, exactly
  two employees and one active owner, plus permit revocation on close.
- Real canonical placement, validation, native layer rendering, collision and
  Undo are reused. The picker displays human names rather than developer IDs.
  A one-line note states each prop's actual visibility limitations.
- The prior entry's late-priority Node is reused to place complete employee
  cards/pointers around the dev toolbar, then invalidate the label drawing.
  Popup ownership also blocks polled world movement while a menu is open.
- Toolbar rectangle `(24,600,1080,112)` stays left of the rail and within the
  viewport. Actual label lines and control rectangles are checked, not merely
  a generously allocated blank Label region. The founder starts at the
  existing clear circulation cell `(17,16)`, world `(560,528)`, instead of the
  ordinary entrance hidden under the optional dev toolbar. This changes only
  the disposable viewer's initial position; all three actors are fully visible.

## Verification and native review

[Focused test](../../game/tests/test_furniture_catalogue.gd): **370 headless
checks / 0 failures**, **395 native checks / 0 failures**. The final recording
contains **342 frames at 30 FPS**, 1280×720, and **25 native screenshots**.
[Headless manifest](../../game/tests/output/furniture-catalogue/headless.json),
[native manifest](../../game/tests/output/furniture-catalogue/manifest.json),
[movie](../../game/tests/output/furniture-catalogue/catalogue.avi).

Real viewport key events open the native menu, move its focus and confirm each
selection. Real R/M/Escape/U and mouse-button events exercise all four committed
facings, moving to a validated free cell, wall rejection, cancellation and exact
Undo for every family. These are not direct calls to selection or commit
handlers. The separate rapid-request test deliberately calls the request queue
to check lifecycle coalescing; it is not presented as a simultaneous human
mouse gesture. Occupied navigation cells and native sprite scale/rotation/flip
settings are asserted. This does not repeat all historical per-pixel source or
actor-path suites; their frozen evidence remains the art/geometry foundation.

Reviewed at native size: all four South views, final catalogue, whiteboard East
and rejected shelf wall placement. Toolbar names, status and per-type notes are
readable; actor paper/pointers do not touch the toolbar. The invalid red ghost
is intentional and never committed. Not every frame of the movie or every
one of the 25 PNGs was manually inspected.

- [Whiteboard](../../game/tests/output/furniture-catalogue/mobile_whiteboard-south.png)
- [Pedestal](../../game/tests/output/furniture-catalogue/rolling_storage_pedestal-south.png)
- [Divider](../../game/tests/output/furniture-catalogue/acoustic_divider-south.png)
- [Shelf / final scene](../../game/tests/output/furniture-catalogue/final-catalogue.png)
- [True thin board edge](../../game/tests/output/furniture-catalogue/mobile_whiteboard-east.png)
- [Rejected placement](../../game/tests/output/furniture-catalogue/low_bookshelf-invalid-wall.png)

The shelf and divider's simple construction and subdued side identity remain
the documented art limitations. Divider N/S and E/W are equivalent pairs;
shelf E/W are equivalent closed ends. Whiteboard notes, pedestal drawers and
shelf books appear only from South. This entry does not invent hidden front
art or claim four generated originals. No new service, storage backend, job,
work pose or employee was added.

## Reproduce the automated proof

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --fixed-fps 30 --script res://tests/test_furniture_catalogue.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --write-movie res://tests/output/furniture-catalogue/catalogue.avi --script res://tests/test_furniture_catalogue.gd
```

Early dev diagnostics caught a fixed test destination occupied by a naturally
moving employee and a stale picker reference after replacing its owning scene.
The test now chooses a genuinely validated unoccupied destination before the
real click and drives the popup through focus/Space/arrows/Enter. Neither issue
required a production fix. The initial toolbar also covered the founder's
entrance; the final dev-only spawn/toolbar adjustment above corrects that
observed native presentation issue. Final logs contain no script errors or
ObjectDB leak warnings. All renderer processes exited; source is frozen.
