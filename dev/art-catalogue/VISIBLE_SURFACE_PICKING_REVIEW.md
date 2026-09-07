# Visible-surface world picking

2026-09-04. Implemented the first priority from [the bounded runtime audit](RUNTIME_PRESENTATION_PRIORITIES.md). This is a code-only input correction. No image generation, furniture/character re-export, production direction activation, worker call, persistence change, station-hover feature or lunch-pose change.

## Confirmed before, corrected after

The two earlier source-derived suspicions were reproduced using real `InputEventMouseMotion` and left-button down/up through the viewport, in a fresh worker-blocked `GameMain` instance. They are no longer just screenshot inferences.

| Native point | Before actual click | After actual click |
|---|---|---|
| `(336,234)`, Mina's opaque monitor | Employee `mira` route → Chat | `mira-workstation` route; real arrival opens existing Assign tab |
| `(210,466)`, transparent founder-desk padding over floor | `founder-workstation` route → Journey | No object action; click-to-walk ends at floor cell `(208,464)` |
| `(336,194)`, visible Mina face | Not part of initial reproduction | Employee selection remains available |

[Before input record](../../game/tests/output/visible-surface-picking/baseline.json), [before native scene](../../game/tests/output/visible-surface-picking/before-legacy-seated.png), [after native scene](../../game/tests/output/visible-surface-picking/after-legacy-seated.png), [final input/result record](../../game/tests/output/visible-surface-picking/results.json).

The before/after **128×96 crop at `(272,168)`** containing the actual legacy Mina/desk art is byte-identical: ImageMagick AE **0 of12,288 pixels changed**. This fix changes what the click means, not the South body, desk, pose, depth or artwork. The before fixture preceded a test-only UI projection settle; whole-screen label equality is not claimed.

## Production contract

- [VisibleSurface](../../game/world/visible_surface.gd#L6) asks Godot's native `Sprite2D.is_pixel_opaque()` in the sprite's local coordinates, checking actual visibility and alpha modulation first. Region offsets, centered versus top-left registration and local transforms are handled by the engine. There is no viewport readback or per-frame GPU image extraction in production. See the [official Sprite2D reference](https://docs.godotengine.org/en/stable/classes/class_sprite2d.html#class-sprite2d-method-is-pixel-opaque).
- [EmployeeAvatar](../../game/actors/employee_avatar.gd#L187) contributes only the current standing/seated body and visible split work-pose layers. Hidden full-body fallback, shadows, event cues, names and speech are not employee hit surfaces.
- [TownRoom](../../game/world/town_room.gd#L260) resolves only its canonical registered render layers. Ambient overlays/unlock VFX cannot enlarge prop targets. Opaque decorative furniture participates as an occluder without gaining a new action; clicking it retains ordinary existing ground/collision handling. Interactive props still respect their declared hit bounds, now intersected with actual painted art.
- [GameMain](../../game/world/main.gd#L595) compares the top prop and body candidates by their effective rendered Z, including relative parent depth. Equal-Z ties use actual scene order, not arbitrary employee priority. A separate native two-sprite test verifies the chosen tie against the renderer.
- Existing destinations, click-to-walk/navigation, collision, arrival actions, world pause, worker methods and UI input handling are unchanged. This is scoped to the current single world canvas with explicit Z and no Y-sort/top-level/body shaders. Future cross-canvas/Y-sorted or shader-displaced bodies need an explicit extension; this helper is not advertised as a general Godot picker.

## Verification

`test_visible_surface_picking.gd` completed **32,230 headless checks /0 failures** and **32,269 rendered checks /0 failures**. The native run produced **19 after PNGs**, plus the separately frozen **two before PNGs**, and a **161-frame1280×720/30FPS [replay](../../game/tests/output/visible-surface-picking/replay.avi)**. The replay is an input/pose-checkpoint replay; long approach and departure physics are stepped deterministically between captured endpoints, not recorded as a continuous mount-motion proof.

- **32,065 sampled nontransparent pixels** compared the selected owner with a separate source-image/region oracle across both Mina and Theo, all six idle/typing frames, all four genuine staged directions. The oracle uses source images only in the dev test. It is not the implementation's alpha function. Equal-depth ordering also has a rendered-color proof.
- Both visible employee body clicks and furniture-over-body clicks were dispatched through real mouse events in every facing, both actors. All eight cases contained real hidden-body/foreground overlap: N144/177 sampled pixels, E57/55, S112/133, W61/71 for Mina/Theo in frame0.
- E/W split rows and render-only seated offsets remain registered. Actual departure removes old split targets; the former seated silhouette is not clickable after Mina leaves.
- Real mouse focus on the Chat input stays in the UI; no world route leaks. Clicking Theo's rail card selects Theo without movement. No artificial large transparent hit margin was introduced; rail access remains available when a world character is mostly occluded.
- Dense picking queries leave employee feet, work states, routes, animation timers, render offsets, clock and resolved furniture data unchanged. Catalog/room/locomotion source SHA checks remain identical. Every fixture uses an inert transport; no worker or saved company state is opened.
- Import and `validate_project.gd` pass. Targeted existing provider-free suites pass: `run_all`, `test_complete_game`, `test_graphics_regressions`, `test_workstation_facing` (**249**), `test_furniture_directions` (**429**), `test_world_ui_presentation` (**468**), `test_office_layout` (**830**). First three emit pass/fail rather than a comparable assertion count. No final log contains a script error.

Native review inspected all N/E/S/W frame0/frame2/frame5 and departure captures, the legacy scene and UI-focus screenshot. No body/desk art change or stale visible body layer was introduced. The calibration toolbar remains visibly labeled; these NESW assets are still staged candidates. The frozen UI-focus fixture intentionally stops general per-frame projection after setup, so its world nameplates are not a new full UI-suppression acceptance claim. Existing staged North proportions, side-hand contact, mount-art gaps and grounded-shadow studies remain separate unresolved/qualified art evidence.

### Commands

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_visible_surface_picking.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/visible-surface-picking/replay.avi --script res://tests/test_visible_surface_picking.gd
```

The dev-only `--baseline` switch was used against the pre-fix source and intentionally expects the old defect; it is not a passing post-fix test or a runtime feature. Its original evidence is preserved. Final machine-readable headless and rendered results are separate files in `game/tests/output/visible-surface-picking/`.

## Remaining scope

Station hover/action labels are still the next distinct code-only presentation task. Lunch still needs its separate presentation decision. This input fix neither claims those are solved nor approves any staged desk directions or specialist assets.
