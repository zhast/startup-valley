# Grounded shadow: horizontal seat alignment

2026-09-04, 09:45 UTC. **Second, independently verified default-off correction. No workstation or engineer art approval.** The [first physical-floor-only review](GROUNDED_WORK_SHADOW_REVIEW.md), its captures/movie/manifest, and the original engineer baseline remain unchanged.

## Outcome

The grounded shadow now follows the character's integer-snapped horizontal seating offset while retaining the physical floor Y coordinate. This removes the visible sideways detachment from the East/West chair without lifting a floor shadow onto the desktop. North/South are unchanged.

[East native before/after](../../game/tests/output/grounded-shadow-x-follow/east-before-after-native.png) and [West native before/after](../../game/tests/output/grounded-shadow-x-follow/west-before-after-native.png): left pair is the first floor-only policy, right pair follows seated X; rows show frames0 and2, both employees. [All four corrected views](../../game/tests/output/grounded-shadow-x-follow/all-four-native.png).

## Separate contract

```gdscript
"grounded_work_shadow": true,
"grounded_work_shadow_follow_seat_x": true
```

- `OfficeLayout.resolve_profile()` requires a real boolean, the first grounded-shadow option, and the same live owner-scoped calibration admission. The second flag is included among seated-only fields: service/archive profiles reject it even when false. Copied/forged admission and fake runtime review flags remain rejected.
- `TownRoom._workstation_visual()` propagates it only when explicitly present. Shadow depth still derives from the minimum of **all** own furniture layers minus1; no new authored depth is introduced.
- `EmployeeAvatar._validated_work_visual()` rejects malformed flags and a horizontal-follow request without the admitted grounded policy.
- `EmployeeAvatar._sync_work_shadow()` adds only `seated_render_offset().x` to the grounded shadow. That offset is already integer-snapped and includes the real enter/leave interpolation. Its Y remains `position.round().y - 2`, regardless of seat elevation or per-character body correction.
- Pose/registry loss clears the horizontal offset and custom workstation depth. Standing/walking returns to ordinary physical-floor presentation. The source texture, alpha, visibility, modulation and size are unchanged.
- Missing/false horizontal-follow retains the **first** grounded policy exactly. Missing/false grounded-shadow retains the original legacy behavior exactly. No shipped profile opts into either correction.

The new `horizontal_grounded_mat_fixture.gd` subclasses the first dev fixture and changes only the second flag. It does not modify furniture, actor source regions, collisions, work cells, seat sockets, body depth, worker events, timing or navigation.

## Exact comparison

All six original seated/typing frames for Mina and Theo are compared with the first-policy frozen PNGs, using registered160×176 actor/workstation crops: **1,351,680 pixels** total.

| View | Changed pixels per actor/frame | Changed tabletop pixels | Other changed pixels |
|---|---:|---:|---:|
| North | 0 | 0 | 0 |
| East | 75 | 0 | 0 |
| South | 0 | 0 | 0 |
| West | 70 | 0 | 0 |

“Other” means outside the union of the old and new shadow rectangles. All underlying body, chair, mat and desk pixels remain exact. East moves the shadow+12px X; West−12px; neither moves shadow Y. North/South's zero-X source poses are byte-exact inside every comparison crop, not merely geometrically similar.

**102,400** native mat/depth pixels pass across still and transition checkpoints. The original South tabletop-shadow fix remains intact. **1,548 actually visible floor-shadow pixels** match the unchanged source alpha over the actual room background. Partial-alpha compositing permits one8-bit channel step for CPU/GL rounding; opaque art comparisons are exact. Counts across measured states are N29–43, E27–32, S0–25, W23–25. South's seated shadow is naturally occluded; it visibly returns on open floor after departure.

The visibility oracle temporarily hides the shadow for a **dev-only background readback**, then restores it; saved screenshots always contain the real visible shadow node. Production never hides or substitutes the shadow. Those diagnostic readback frames are present in the AVI; this is technical evidence, not a polished gameplay trailer.

## Full transition and lifecycle evidence

Unlike the first policy movie, this movie films the complete real approach and return routes: **776 continuous scene frames**, stepping both employees for **1,552 physics ticks**. No interpolated frame is skipped during mount/leave. There are96 recorded actor transition/endpoint states: both actors, four facings, enter and leave, six checkpoints each.

East enter X is `0, 2, 6, 10, 12, 12`; West is `0, -2, -6, -10, -12, -12`. Leave reverses through±10,±6,±2,0 before ordinary walking. Y always follows physical ground movement, never the simultaneous vertical seat interpolation. North/South retain zero horizontal shadow shift through their respective vertical transitions. A mid-interpolation pause checks frozen physical feet, body offset, shadow and elapsed transition time together.

Native full sequences: [North enter](../../game/tests/output/grounded-shadow-x-follow/north-enter-native.png), [North leave](../../game/tests/output/grounded-shadow-x-follow/north-leave-native.png), [East enter](../../game/tests/output/grounded-shadow-x-follow/east-enter-native.png), [East leave](../../game/tests/output/grounded-shadow-x-follow/east-leave-native.png), [South enter](../../game/tests/output/grounded-shadow-x-follow/south-enter-native.png), [South leave](../../game/tests/output/grounded-shadow-x-follow/south-leave-native.png), [West enter](../../game/tests/output/grounded-shadow-x-follow/west-enter-native.png), [West leave](../../game/tests/output/grounded-shadow-x-follow/west-leave-native.png). Read each sheet as sequential pairs Mina/Theo, three pairs per row. Final leave crops are empty because the actual actor has reached its home elsewhere in the full room; the full endpoint screenshot verifies that destination.

Focused headless tests pass **21,057 checks / 0 failures**, with **3,940 real physics ticks**. They inherit all first-policy owner/admission/source/depth/navigation/pause/terminal-event/pose-loss/registry-loss tests, and add malformed horizontal flags, service rejection, propagation, explicit-false first-policy restoration, and unchanged non-shadow state snapshots. A completion guard requires all four lifecycle cases to finish: an early GDScript exception cannot produce a misleading partial green result. Invalid-type injection initially exposed an unsafe int/bool comparison in the new gate; that was corrected before final validation, and final logs contain no script errors.

Final additional headless results: first policy **20,896/0**, workstation facing **249/0**, furniture directions **429/0**. No broad-regression claim is made here; the parent's previous AFTER snapshot predates this second policy.

## Visual review and limitations

Inspected all four all-six-frame sheets, all eight enter/leave sequence sheets, both native before/after comparisons, and the all-four native contact. Also inspected actual1280×720 East entry/leave, West leave, South returned-home screens, plus East Mina typing and West Theo paused at4×. The disconnected side shadow is now aligned under the visible seated body/chair; South's mat remains clear. Final captions reflect the same captured physics tick, after a capture-only one-frame caption timing fix.

This does **not** solve the existing pose-to-pose mount animation: the actor still interpolates existing standing/seated art rather than having an authored bend/sit sequence. Existing chair/feet overlaps and source silhouette changes during those transitions remain separate art/mechanism review concerns; no body or chair pixels were altered here. The North mat remains largely occluded, engineer board sizes/probe tips still differ across directions, and typing is not a probe-use animation. See the frozen [engineer review](ENGINEER_MAT_COMPOSITION_REVIEW.md). The corrected shadow is a presentation improvement, not a reason to approve those assets or enable these workstations in production.

## Reproduction and frozen result

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_grounded_shadow_x_follow.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/grounded-shadow-x-follow/grounded-shadow-x.avi --script res://tools/capture_grounded_shadow_x_follow.gd
```

Final native: **10,833 checks / 0 failures, 257 PNGs** =80 native scenes,160 nearest4× crops,17 contacts/comparisons. `ffprobe` confirms **956 AVI frames,30FPS,1280×720**:776 continuous route frames,160 intentional capture/readback frames,20 fixture/setup frames. Renderer exited0 and was released. `git diff --check` passes. The fixture's NullWorker blocks actual transport, user bootstrap and saves; there were no providers, production opt-ins, source-art edits or new image calls.

Evidence: [headless results](../../game/tests/output/grounded-shadow-x-follow/results-headless.json), [native manifest](../../game/tests/output/grounded-shadow-x-follow/manifest.json), [movie](../../game/tests/output/grounded-shadow-x-follow/grounded-shadow-x.avi). All24 first-policy frame-image hashes and all referenced source-art hashes are checked unchanged by the new harness.

Shared source SHA256 at freeze:

```text
dfea0c6d4d412c66d55bc690601929926366d99148ef63de75a2960907f076ae  game/world/office_layout.gd
aa329cf398bae96226d2717ddec60fb50c2ac982943f5044a885697cc34ff78e  game/world/town_room.gd
d3460c26cde72c5b441819b8b8896ddb6629dbfb70b524b12171669ebbf18488  game/actors/employee_avatar.gd
```

New dev files: `horizontal_grounded_mat_fixture.gd`, `capture_grounded_shadow_x_follow.gd`, `test_grounded_shadow_x_follow.gd`, and this review. The first test file gained only overridable fixture/output hooks plus removal of the second optional flag during its existing legacy-equivalence check; its original fixture/results remain unchanged.
