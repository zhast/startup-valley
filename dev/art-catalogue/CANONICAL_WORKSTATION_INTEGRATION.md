# Canonical workstation calibration integration

Latest checkpoint: 2026-09-04 08:10 UTC. **Developer fixture, not production art approval.**

## Follow-up: actor-safe editor and reliable ghost textures

The initial integration below is retained as a historical checkpoint. Two additional real-game problems are now fixed in the developer editor:

1. **Occupied placement/rotation/undo is rejected instead of moving a person out of the way.** `TownRoom.placement_actor_conflicts()` compares newly blocking cells with registered live actor feet and the same10px corner samples used by navigation. It is read-only. Reservations alone do not represent a physical obstruction. The editor checks this on preview/commit and before undo; bootstrap/roster migration and `set_placement_overrides()` retain their original semantics. Rejection preserves physical positions, the committed layout, candidate, and undo history. Status says to leave the desk or move the named person clear. The calibration Leave button restores a pending preview before walking away; R/U then succeed once clear. A moving employee whose *future target* changes is safely replanned without changing current feet.
2. **Transparent preview resources stay alive through rendering.** Previously `_preview_layers()` kept newly loaded directional textures only in local variables. Canvas draw commands retained rendering IDs after those temporary references disappeared, so a new view could render as a solid Vermilion192×224quad. A per-editor strong texture cache now retains them. Actual rendered corner-pixel checks confirm the padded transparent area remains unchanged room background. The invalid footprint is still an intentional translucent red ghost, not an accepted placement.

Cancelling a preview also restores its selector to the committed facing. Otherwise a subsequent R press skipped the cancelled direction. Undo now retains its history entry when an actor blocks restoration.

**Final source-frozen tests at08:10:**6,684 headless checks and6,986 rendered checks, zero failures. Existing editor128, OfficeLayout830, modular office7,436, directional249, and generic transition4,671 checks passed. The worker and source artwork were unchanged. The later seated-thinking follow-up is a separate task; this checkpoint intentionally retains the visible thinking fallback described below.

Current output: `game/tests/output/calibrated-workstation/actor-safe-editor/`. Its216PNGs comprise41 full-scene captures,60 start/middle/end markers across20 paths,91 intermediate transition frames, four unscaled all-six-frame pose contacts, and20 native transition strips. The movie contains2,251 actual frames at30FPS,1280×720 (75.03seconds), independently checked with ffprobe. The manifest records physical positions, render offsets, frame counters and rendered hashes; the movie is not claimed as watched in playback.

Native full-screen rejection, leave/rotation, blocked undo, clear undo, founder/teammate obstruction and active-route replan screenshots were inspected. The toolbar and actionable status fit at1280×720; invalid preview alpha now exposes the actual obstructing actor rather than hiding them in a rectangle. Representative current paths:

- `occupied-rotation-rejected.png`, `occupied-undo-blocked.png`
- `founder-placement-blocked.png`, `teammate-placement-blocked.png`
- `route-target-replanned.png`, `clear-undo-restored.png`

Before-fix opaque-preview PNGs and their manifest remain under `game/tests/output/calibrated-workstation/preview-alpha-before/`. Earlier unsafe-rotation and interpolated-depth evidence remain in their original directories. Initial limitation3 below is **resolved for editor commits/undo**; migration behavior deliberately remains unchanged. All art/contact/mounting limitations remain unapproved.

The calibrated desk/chair/computer and real Mina/Theo source atlases now render through the ordinary `GameMain → TownRoom → EmployeeAvatar → CharacterArt` pipeline. This replaces isolated composition-only proof with actual navigation, reservations, prop hit testing, and the existing editor's R/preview/commit logic. The production furniture JSON and legacy pose registry are unchanged.

## Run it

```sh
godot --path game --script res://tools/play_calibrated_workstation.gd
godot --path game --script res://tools/play_calibrated_workstation.gd -- --two-employees
godot --headless --path game --script res://tests/test_calibrated_workstation.gd
godot --path game --fixed-fps 30 --write-movie res://tests/output/calibrated-workstation/actor-safe-editor/live-paths.avi --script res://tests/test_calibrated_workstation.gd -- --motion
```

Run the headless test first to create the movie output directory. Normal project entry does not load this fixture. Its toolbar selects a workstation; **R** rotates its authored facing, **M** enters move preview, a ground click commits a valid preview, **U** attempts a safe undo, and **Escape** cancels. Sit/Type/Leave are explicitly simulated calibration actions. Outside placement mode, ordinary founder movement and employee/prop clicks use GameMain.

The fixture replaces the worker leaf with an inert transport before GameMain enters the tree. It does not read personal bootstrap/settings/save data or launch a worker. It clears only the temporary worker-disabled starter roster, then creates employees from explicit fixture spawn records. The clock is held at08:00; audio is muted. No credentials, saves, protocol, worker contracts, or source artwork are mutated.

## Minimal implementation contract

- `CharacterArt.register_calibration_pose_set()` accepts actual textures and source regions under a unique `dev-calibration-…` ID owned by one live editor fixture. It validates native integer rows/columns/frame counts and optional per-character cut rows. It cannot replace legacy IDs. Another owner cannot unregister or borrow this admission.
- `OfficeLayout.enable_calibration_preview(owner)` is per-model and editor-only. `calibration_candidate` profiles are admitted only when their actual pose registry belongs to that same owner. Their three review flags remain false. All source, alpha bounds, occupied-cell, wall, clearance, route, native scale, and hit-bound validation remains active.
- `seat_anchor_by_employee` contains full rendered offsets relative to each physical work cell, not extra additive corrections. TownRoom resolves the actual employee before forwarding metadata.
- `seat_layer_z_offsets` names prop-relative `upper` and `lower` depths. CharacterArt returns source region plus its original top-left cell offset. EmployeeAvatar uses non-centered Sprite2Ds so a47px/33px split never introduces a half-pixel origin. Recombining the parts must reproduce the original full48×80cell byte for byte.
- `seat_pose_depth_lock` is a validated optional boolean, absent/false by default and presently permitted only in scoped editor calibration. The fixture sets it true. Seated whole/upper/lower bodies immediately take their declared prop-relative depth; non-seated bodies immediately sort at physical-foot depth. Visual XY still uses the existing140ms integer-snapped easing.
- Teardown removes the pose registry, closes model admission, restores the prior worker-disabled environment value, and shuts down fixture audio. Tests instantiate independent scenes and attempt cross-owner access. No stale fixture registration becomes a global catalogue capability.

The old south registry still returns its original texture/region pair. The default legacy metadata, full character sprite, and generic seat-preview depth interpolation are unchanged. Existing direction and generic transition suites remain green; this checkpoint does not claim a new full-frame legacy screenshot comparison.

## Actual candidate recipes

All desks use192×224registered layers with pivot(96,160). Chairs retain96×160/pivot(48,112). Actor cells remain48×80 with the existing foot baseline72. Each physical work foot is exactly one32px grid cell opposite the worker gaze.

| Facing | Physical work offset | Chair from physical foot | Mina from physical foot | Theo from physical foot | Actor source cuts |
|---|---:|---:|---:|---:|---|
| North | (0,+32) | (0,−12) | (0,−20) | (0,−16) | Whole bodies |
| East | (−32,0) | (+12,0) | (+12,+3) | (+12,+4) | Both52 in all six frames |
| South | (0,−32) | (0,+4) | (0,+12) | (0,+12) | Both50 in all six frames |
| West | (+32,0) | (−12,0) | (−12,+4) | (−12,+8) | Mina50; Theo48,48,47,47,47,48 |

Theo West uses the separately registered v3 source whose Y translations are already baked into the candidate atlas. The runtime does not apply them twice. Variable cuts preserve the original upper/lower pixel ownership under that registration.

North monitor moves−10Y independently; its keyboard/mouse move+4Y. East keyboard/mouse move+6X toward the fixed monitor; Theo reach remains borderline. West device pixels remain at their independently authored W2 positions. South uses the authored S peripherals and rear monitor S3 shifted+3Y.

Prop-relative layers:

- North: desk rear−1/front+1; devices+2; actor+20; whole rear chair+21.
- South: whole chair−2; desk rear−1; lower body0; desk front+1; keyboard/mouse+2; upper body+3; monitor+4.
- East/West: chair rear−5; lower body−4; near arm−3; desk rear−1/front+1; keyboard/mouse+1; upper body+2; monitor+3.

Exact file paths, alpha-union bounds, complete source regions and character recipes are executable in `game/tools/calibrated_workstation_fixture.gd`; no generated textures are referenced by production constants.

## Initial integration verification and evidence (07:57 checkpoint)

Final focused run:

- **2,255 headless checks; zero failures.**
- **2,477 rendered checks; zero failures.**
- Existing `test_workstation_facing.gd`:249/0.
- Existing `test_seat_transition.gd`:4,671/0.
- `run_all.gd` gameplay smoke passed; project validation passed; `git diff --check` clean at this checkpoint.

Coverage includes visible Sit input, actual R/ground-click placement commit, keyboard Escape cancellation, UI/ground click isolation, real employee hit-test/founder path creation, both employees/four directions/all six idle/typing source frames, loop return, wall/corner rejection, exact source reconstruction, integer transform preservation, physical feet on walkable cells, distinct final reservations, malformed profile/registry rejection, interrupted leave/return, pause mid-tween, and thinking fallback. It does not claim a full founder-arrival-to-chat walkthrough or aesthetic acceptance of every work state.

Final output: `game/tests/output/calibrated-workstation/pose-depth-lock/`.

- `manifest.json`: scenario paths, source-state limitations,11 movement sequences with33 start/middle/end markers and distinct rendered SHA-256 values, plus82 actual transition snapshots with physical/rendered positions and process-frame counters.
- `live-paths.avi`:718 frames at30FPS,1280×720;23.93seconds. Encoding metadata checked independently with ffprobe. Actual physics ticks are rendered during the walk, not collapsed into a single end-state still. Playback was not claimed as watched.
- 35 whole-scene stills cover the first desk, four-direction six-frame paired scenes, loop returns, interrupted leave/return, pause and unavailable thinking art.
- Four `contact-*-native.png` sheets crop those scenes without scaling. Each pair is Mina/Theo, frames0/1/2 across the top and3/4/5 below. Edge-clipped nameplates in these diagnostic crops are not clipped in the source full-scene screenshots.
- Eleven `transition-*-native.png` strips show all sampled intermediate visual offsets followed by the settled endpoint. The complete165PNG inventory is35 scene stills+33 path markers+82 transient frames+4 pose contacts+11 transient contacts.

Inspected native evidence includes all four paired six-frame contact sheets, full native direction scenes, South/North/East/West transition strips, paused-mid-seat, thinking fallback, and representative real walking markers. Source identity and repeated frame boundaries are checked independently of image differences.

## Real defect found and corrected

The original generic developer seat preview interpolated Z as well as XY. Because chair/table layers remain at fixed prop-relative depths, the torso briefly crossed them during the140ms settle. South's blue chair visibly passed through Mina's chest even though the final seated endpoint looked correct.

- Before: `game/tests/output/calibrated-workstation/transition-00-native.png` and corresponding `motion-00-transition-*.png`.
- After: `game/tests/output/calibrated-workstation/pose-depth-lock/transition-00-native.png`.

The explicit pose-depth lock removes that incorrect intermediate ordering. Tests assert every intermediate seated frame takes the same declared layer order, while walking/thinking immediately regain physical-foot sorting. The earlier failure strips/movie are retained in the parent output directory. The before fixture used the reused starter spawn; the corrected fixture creates its explicitly declared spawn. That changes walking length but not the South seated layer comparison.

## Remaining limitations — no runtime approval

1. **Actual mounting art is missing.** The140ms XY mechanism slides/raises an already seated pose into support. North rises20/16px and can briefly expose feet below the rear chair; E/W turn from a walking facing and slide sideways. These are visible intermediate pose limitations, not new source-layer seams. Dedicated mounting/turning poses or a reviewed transition policy remain necessary before claiming polished seating.
2. **Thinking/research/approval/delivery coverage is incomplete.** This set supplies seated and typing only. The honest standing thinking fallback is visibly occluded by the South chair at the physical work socket (`thinking-fallback.png`). It correctly uses a standing source and physical-foot depth, but that is not finished work-state presentation. It needs a supported seated-thinking pose or an actual clear standing destination, not an invented claim that all actions are implemented.
3. **Occupied rotation can reposition an actor.** Existing GameMain placement-change handling sends an actor inside a newly blocked cell to `navigation.safe_position()` before replanning. North→East makes the former seat a blocked desk cell, so a discrete safety relocation can occur. These tests prove blocked feet are avoided, not a smooth vacate-before-rotation flow. A later policy should reject occupied rotation or move actors clear before committing it.
4. **North contact remains inferred.** The whole chair hides hips and some hand support. A successful path and valid alpha bounds do not prove ergonomics.
5. **East/West contact limitations remain.** East has the known small upper lap strip and Theo's borderline key-edge reach. West keyboard placement is still head-adjacent; Theo retains a one-pixel visible sole/cushion variation. The translated source-aware West cuts do not reintroduce the earlier green lap stripe.
6. **Desk finish remains calibration art.** Simple legs, repeated material grain, empty office composition, and the dev toolbar are not approved final room design. No other furniture family, specialist hire behavior, or new production-facing option is enabled.

The result is a reusable, tested, actual-game calibration entry and a corrected layer-order mechanism—not a declaration that all four art directions or all workplace actions have passed final review.
