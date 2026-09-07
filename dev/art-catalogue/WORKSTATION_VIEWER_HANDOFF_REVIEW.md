# Workstation viewer — bounded handoff check

2026-09-04 11:20 UTC. This is a developer launch/input review, not new pose art
approval. The historical entry, fixture and editor remain unchanged.

## Corrected launch — use this command

The new [workstation showroom entry](../../game/tools/play_workstation_showroom.gd)
uses the same isolated fixture and rendering. It waits two startup frames for
the deferred connection callback, then calls the existing `close_drawer(false)`
once and releases keyboard focus. It does not set a fake credential, repeatedly
hide later user-opened panels, replace the editor, or change any worker/save path.

```sh
godot --path game --script res://tools/play_workstation_showroom.gd -- --two-employees
```

Choose an employee's workstation in the left dropdown. **Sit** and **Type** are
visual test controls, not jobs. **Leave** walks the employee away. Use **Rotate**
or **R**, then click the preview to commit. Leave the desk before rotating it;
occupied rotation is deliberately rejected. No key is needed; do not enter one.
This remains a developer fixture with no saving or layout export. Close the
window to discard its local state.

The actual new CLI also passed a30-frame headless launch/clean-exit smoke.
The separate [AFTER probe](../../game/tools/probe_workstation_showroom.gd) calls
the same startup routine, then replays the unchanged real mouse controls:
**29 headless checks /0 failures**, **37 native checks /0 failures**, eight
native PNGs and427frames at30FPS (14.23seconds). Every checkpoint confirms the
drawer stays closed, credential remains absent and null transport has no process.
All eight AFTER images were inspected, including clear initial/settled views,
typing, occupied rejection, leave, rotate and reseat. No label overlap was found.
The retained ordinary idle scheduling means Theo can autonomously sit/wander;
the evidence is not falsely described as pixel-identical actor timing to BEFORE.

- [Clear initial view](../../game/tests/output/workstation-entry-after/initial.png)
- [Settled](../../game/tests/output/workstation-entry-after/settled.png)
- [Occupied rejection](../../game/tests/output/workstation-entry-after/occupied-rotation.png)
- [Reseated West](../../game/tests/output/workstation-entry-after/west-seated.png)
- [AFTER manifest](../../game/tests/output/workstation-entry-after/manifest.json),
  [headless](../../game/tests/output/workstation-entry-after/headless.json),
  [movie](../../game/tests/output/workstation-entry-after/input.avi)

```sh
godot --headless --path game --fixed-fps 30 --script res://tools/probe_workstation_showroom.gd -- --two-employees
godot --path game --fixed-fps 30 --write-movie res://tests/output/workstation-entry-after/input.avi --script res://tools/probe_workstation_showroom.gd -- --two-employees
```

All BEFORE images/manifest/movie below remain unchanged. No speculative late
label guard was added, because the suspected defect was not observed.

## Before finding

The old command starts a valid isolated two-employee room, but its initial and
settled screen opens **Connect AI** over Theo and his right-hand desk. That is
confusing in a viewer whose transport cannot start a worker. The field remains
empty, no credential is read/saved, and no provider request occurs.

Cause: the fixture calls `set_credential_status(false)`, which schedules
`_open_connection_settings` through `call_deferred`. The fixture's synchronous
`close_drawer(false)` runs before that deferred callback. This is a developer
entry ordering issue, not a production connection-panel bug.

The suspected toolbar label overlap was **not reproduced** in the eight actual
sampled states. The temporary toolbar occupies(24,622,1080,90); observed complete
label/pointer rectangles stay above it. The founder's initial feet sit very close
to its top boundary but are visible. No label suppression or new late-layout
guard has been added without evidence.

## Real controls and isolation

The new [probe](../../game/tools/probe_workstation_entry.gd) inherits the actual
old entry and its fixture. It sends mouse motion/down/up through the root viewport
to the visible Sit, Type, Rotate and Leave buttons, then clicks the real placement
preview. It does not call their handlers instead of input.

- **13 headless checks /0 failures**; **21 native checks /0 failures**.
- Eight native1280×720 PNGs and431movieframes at30FPS (14.37seconds).
- Sit walks Mina along the actual route to the authored South seat; Type selects
  the existing diagnostic typing pose. These are art controls, not real AI jobs.
- Occupied South→West rotation is rejected; clicking does not move the seated
  actor or mutate the committed layout. The visible status says Leave desk.
- Leave cancels the rejected preview and walks Mina back home. A subsequent
  rotation and world click commits West, and Sit reaches the new work cell.
- Null transport, no process, no personal-state load and no worker-ready state
  are asserted. Closing the fixture revokes its local calibration admission.
- The old entry works after dismissing the connection panel (or pressing Sit,
  which closes the drawer). The startup obstruction remains documented here.

The initial, settled, seated, typing, occupied-rotation, left, rotated and
West-seated native frames were all inspected. No toolbar text clipping was
observed. The older art limitations still apply: mount/dismount interpolation is
not authored animation; North support is inferred, East has lap/reach limits,
and West has the documented small source variation. This review does not promote
any desk/pose to production or test all possible input/state combinations.

## Preserved before evidence

- [Initial obstruction](../../game/tests/output/workstation-entry-before/initial.png)
- [Seated](../../game/tests/output/workstation-entry-before/seated.png)
- [Occupied rejection](../../game/tests/output/workstation-entry-before/occupied-rotation.png)
- [West after actual rotation and reseat](../../game/tests/output/workstation-entry-before/west-seated.png)
- [Manifest](../../game/tests/output/workstation-entry-before/manifest.json),
  [headless](../../game/tests/output/workstation-entry-before/headless.json),
  [input movie](../../game/tests/output/workstation-entry-before/input.avi)

Historical interactive entry (dismiss Connect AI; never enter a key here):

```sh
godot --path game --script res://tools/play_calibrated_workstation.gd -- --two-employees
```

Bounded repeatable probe:

```sh
godot --headless --path game --fixed-fps 30 --script res://tools/probe_workstation_entry.gd -- --two-employees
godot --path game --fixed-fps 30 --write-movie res://tests/output/workstation-entry-before/input.avi --script res://tools/probe_workstation_entry.gd -- --two-employees
```
