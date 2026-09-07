# Grounded workstation shadows — opt-in correction

2026-09-04, approximately 09:32 UTC. **Code correction implemented and verified; no workstation or mat art promoted.** Original engineer baseline captures and its review remain frozen.

## Outcome

The South engineer mat no longer receives the character's floor shadow. For Mina and Theo, across all six original seated/typing frames, exactly **47 mat pixels** change from shadowed to the original native plate colors. The shadow itself is retained, with its existing texture, source alpha, size and region; it is positioned at the physical ground feet and sorted beneath its own desk/chair layers.

The correction is explicit and default-off. Only the new dev fixture opts in. Shipped furniture, service/archive profiles, existing scene assets, worker methods, navigation, seat offsets, body layers, event effects and timing are unchanged.

[South before/after at native size](../../game/tests/output/grounded-work-shadow/south-before-after-native.png) — left pair original, right pair corrected; first row frame0, second row frame2. [Actual corrected room](../../game/tests/output/grounded-work-shadow/south-frame0.png). [All four views](../../game/tests/output/grounded-work-shadow/all-four-native.png).

## Contract and implementation

Authored profile option:

```gdscript
"grounded_work_shadow": true
```

- `game/world/office_layout.gd`: validates an actual boolean, requires the existing live owner-scoped editor calibration admission, and rejects fabricated `calibration_preview` flags, copied ownerless profiles and `runtime_ready` review-flag shortcuts. Service profiles reject the seated-shadow fields even when a boolean is false. Legacy profiles without the option do not acquire it implicitly. `ground_shadow_z_offset` cannot be authored into a profile.
- `game/world/town_room.gd`: propagates the optional boolean and derives `ground_shadow_z_offset = min(render_layers[*].z_offset) - 1`. This includes the chair, apron and all front/back layers; no arbitrary profile depth is trusted. Current resulting offsets are N **−2**, E **−6**, S **−3**, W **−6** relative to each desk pivot.
- `game/actors/employee_avatar.gd`: validates the enabled metadata against a live calibration pose set and a finite integer derived depth. `_sync_work_shadow()` anchors the original sprite at `position.round() + Vector2(0,-2)`, independent of seat render offset. It uses the derived workstation depth only for valid seated/mount/dismount presentation. Once standing, after pose loss, or after registry revocation, it returns to physical-foot depth and never retains a stale lifted shadow.
- When the option is absent/false, the old `Vector2(0,-2) + seated_render_offset + pixel_snap`, relative depth and z0 behavior remains exact. No shipped profile opts in.

Source anchors: [OfficeLayout admission](../../game/world/office_layout.gd), [TownRoom derivation](../../game/world/town_room.gd), [actor shadow presentation](../../game/actors/employee_avatar.gd). The relevant methods are `resolve_profile`, `_workstation_visual`, `_validated_work_visual`, and `_sync_work_shadow`.

Only `grounded_engineer_mat_fixture.gd` enables the option. It subclasses the frozen engineer mat fixture and changes one explicit profile boolean. It does not change artwork, placement, poses, collision, work cells or original evidence paths.

## Failing-then-passing reproduction

The first focused seven-check reproduction, run before the shared implementation, failed six assertions: metadata did not propagate, South shadows remained lifted, and their inherited depth remained above furniture for both employees. After implementation, the same seven assertions passed. The expanded deterministic suite then covers the full lifecycle below.

This is not merely an oracle change. The original renderer's 47-pixel tabletop shadow is preserved in `engineer-mat-composition/`; the corrected output is separate. The new harness compares those frozen images to new actual GameMain captures and checks that no unrelated source/body/furniture pixels changed.

## Exact native evidence

- **1,351,680 before/after pixel comparisons**: 48 actor/frame crops, each160×176. Zero changes outside the union of each original and corrected shadow rectangle.
- South changes **56 pixels total per actor/frame**: 47 on the mat, plus nine elsewhere within the original shadow footprint. No unrelated body/desk/prop pixels change. The old South shadow rectangle is Mina `(320,242,32,16)` / Theo `(768,242,32,16)`; the grounded rectangle is `(320,230,32,16)` / `(768,230,32,16)`, below all own furniture layers.
- **46,080 mat/furniture/body depth pixel checks** pass. Corrected South has no visible floor-shadow pixel on the mat, retaining all640 original plate pixels.
- **2,486 actually visible floor-shadow pixels** are verified against the original source alpha over the actual room background. Known translucent blending allows one8-bit channel step for CPU/GL rounding; opaque artwork comparisons remain exact.
- N/E/W shadows remain visible where the floor is unobstructed. Across captured states, visible counts per actor are N29–43, E29–55, W18–50. South has0 while correctly occluded beneath its tabletop, but up to25 when standing away from the furniture. This is geometric occlusion, not a hidden or deleted shadow.
- All24 frozen native engineer frame screenshots retain their original SHA256. Source/native mat assets also retain their hashes. The original engineer manifest, screenshots and report are not rewritten by the corrected harness.

The floor-visibility oracle takes one temporary **dev-only** hidden-shadow background readback, restores visibility, and compares it with the saved scene containing the true shadow. Production code never hides/removes the shadow or alters its alpha. Every saved corrected screenshot includes the original visible shadow node.

## Real lifecycle tests

`game/tests/test_grounded_work_shadow.gd` passes **20,896 checks**, stepping **3,940 actual physics ticks**. It exercises both employees in all four facings:

- Explicit metadata propagation and derived min-own-layer depth, including chairs.
- Invalid booleans, authored-depth bypass, unowned calibration, forged calibration markers, fake production review flags, and service-profile rejection.
- All five shipped office stages remain free of the new fields; no implicit feature activation.
- Real navigation to each unchanged work cell; mount, seated, typing, pause, leave interpolation and return home. No actor crosses blocked ground.
- Before/after snapshots of physical positions, work targets, routes, reservations, pose regions/layers, cue position/region/activity, and timers remain identical when only the option toggles.
- Real `job.failed` and `job.completed` actor event paths restore ordinary floor shadow depth after departure; no worker session is involved.
- Explicit registry revocation, and a separately re-registered dev definition with typing absent, both remove custom workstation shadow depth without retaining seat lift.
- Shadow source, visibility, modulation and native scale remain intact.

Existing focused regressions also pass: `test_workstation_facing.gd` **249/0**, `test_furniture_directions.gd` **429/0**. The parent’s broader AFTER-archive regression is a separate run; this report does not claim its unfinished result.

## Visual inspection and remaining limits

Reviewed natively: the before/after pair, all-four contact, all four all-six-frame contact sheets (both characters/all48 pose samples), South frame0 full room, East frame2 full room, West leave-transition full room, and North returned-idle full room. Reviewed at4×: South Mina frame2, North Theo frame0, East Mina leave-transition and West Theo paused.

South’s erroneous dark oval at the mat/breadboard edge is gone. The chair, body, desk and tool silhouettes remain unchanged. The North back still occludes most of its centered mat; tool-size/probe-tip issues from [the engineer review](ENGINEER_MAT_COMPOSITION_REVIEW.md) remain unresolved. None of the typing frames becomes a probe-use animation.

**Residual socket discrepancy:** E/W have existing±12px visual seat X offsets relative to the logical work-cell feet. The explicitly requested physical-foot shadow therefore appears beside the visual chair/torso in some enlarged views rather than exactly under its visual center. See [West paused](../../game/tests/output/grounded-work-shadow/west-theo-paused-4x.png) and [East departure](../../game/tests/output/grounded-work-shadow/east-mira-leave-transition-4x.png). This correction deliberately does not move physical feet or reinterpret horizontal seat placement. A future independently reviewed ground-contact/socket policy may be appropriate; do not claim these chairs are fully polished because the depth regression is fixed.

The movie samples six pose states, pause, one real departure interpolation frame and standing per facing. Headless tests step full paths/transitions; the movie is not a continuous filmed playthrough of all3,940 ticks. No new input/UI/backend functionality is claimed.

## Reproduction and paths

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_grounded_work_shadow.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/grounded-work-shadow/grounded-shadow.avi --script res://tools/capture_grounded_work_shadow.gd
```

Final native run: **3,207 checks, 0 failures**, **115 PNGs** (36 native scenes,72 nearest4× crops,seven contact/comparison sheets), **200 AVI frames at30FPS,1280×720**. The manifest counts180 deliberate settle/readback frames; the AVI additionally includes20 fixture/setup frames. `ffprobe` confirms200 frames. `git diff --check` passes. Renderer exited0 and was explicitly released to the broad regression agent.

Evidence: [headless results](../../game/tests/output/grounded-work-shadow/results-headless.json), [native manifest](../../game/tests/output/grounded-work-shadow/manifest.json), [movie](../../game/tests/output/grounded-work-shadow/grounded-shadow.avi).

New dev files: `game/tools/grounded_engineer_mat_fixture.gd`, `game/tools/capture_grounded_work_shadow.gd`, `game/tests/test_grounded_work_shadow.gd`, and this report. Shared edits are limited to the described shadow metadata/presentation in OfficeLayout, TownRoom and EmployeeAvatar. No asset or production catalogue changes, provider calls, personal save access, commits or pushes.
