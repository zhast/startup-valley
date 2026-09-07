# Station hover discovery

2026-09-04. Second bounded code-only priority from [the current-runtime review](RUNTIME_PRESENTATION_PRIORITIES.md), built on the accepted [visible-surface picker](VISIBLE_SURFACE_PICKING_REVIEW.md). Existing paper, stepped pointer and Nunito Bold16 only; no new raster, actor pose, office geometry, navigation action, worker method or persistence change.

## What now appears

Hovering the actual visible station surface produces one40px-high paper callout:

| Visible object | Action copy | Native paper body in the reviewed stage4 fixture |
|---|---|---|
| Archive | Studio | `(104,301,80,40)` |
| Founder desk | Company Journey | `(195,587,155,40)` |
| Approval console | Activity / Review approval | `(904,295,81,40)` / `(870,295,148,40)` |
| Employee desk | Assign / Activity | `(296,299,80,40)` / width81 |

Employee desk copy deliberately matches the existing arrival routing: Assign when no active work order exists, Activity when it does. Approval copy becomes “Review approval” only while the cached approval is pending. This does not introduce a new backend operation or change the existing actions.

[Archive](../../game/tests/output/station-hover/artifact-archive.png), [founder desk](../../game/tests/output/station-hover/founder-workstation.png), [employee desk](../../game/tests/output/station-hover/mira-workstation.png), [pending approval](../../game/tests/output/station-hover/pending-approval.png).

The copy is a hover explanation, not a new button. It ignores mouse events, uses the existing hand cursor, and does not invent an E shortcut for stations. Original click-to-walk feedback/actions remain intact. A nearby employee's existing E shortcut still works; only its redundant Chat paper is suppressed while a station callout is visible.

## Placement and lifetime

[GameMain](../../game/world/main.gd) resolves the new alpha/depth picker first. Actual GUI controls above the world suppress hover discovery. The station action/bounds are then sent to [FounderHud](../../game/ui/founder_hud.gd), which measures the complete caption and tries eight positions around the station's real visual bounds. The existing `WorldCalloutSkin` paper/pointer rules check the full painted extent against actor silhouettes, other furniture, HUD, rail, notifications and playfield edges. Employee labels are laid out after reserving the station paper.

The normal archive callout sits above the cabinet. With the founder occupying that space, [the crowded case](../../game/tests/output/station-hover/archive-crowded.png) moves it below to `(104,459,80,40)` without covering the founder or cabinet. The approval label remains clear of the detailed right-side station stack and rail. If every candidate is occupied, the callout hides instead of covering a face; the station's original click action is still available.

The paper disappears on cursor departure, actor-face selection, station removal, drawer/Settings/modal opening, or disabled world input. A small read-only enabled callback also clears it if editor placement disables world input while normal GameMain processing is paused. No station target or proximity action is changed by that guard.

## Evidence and checks

New `game/tests/test_station_hover.gd`: **288 headless checks /0 failures**, **299 native checks /0 failures**; **11 native1280×720 PNGs**, **80-frame30FPS [replay](../../game/tests/output/station-hover/replay.avi)**. [Rendered results](../../game/tests/output/station-hover/results.json) and [headless results](../../game/tests/output/station-hover/headless.json) contain exact body/painted bounds and input coordinates.

- Actual mouse motion updates the cursor queried by production; visible feedback is asserted after one frame plus that frame's normal UI projection. Native macOS needs in-window cursor warping as well as event injection. The test uses even pixel coordinates to avoid host Retina odd-coordinate quantization; its initial non-warp and odd-Y runs were rejected, not counted as passing evidence.
- Real clicks at all four station types still start their existing station route while the callout is present. Bare-floor padding and visible Mina-face movement clear station discovery. Real E still opens nearby Mina Chat with no duplicate Chat paper.
- Paper, complete label, pointer and native integer placement bounds are checked. Every displayed callout avoids all recorded actors/furniture/HUD/rail and yields space before nameplates.
- Drawer, Settings, disabled player input, removed station, cursor departure and an actual interactive UI button over a station clear or block hover. That UI button also owns its actual click without world navigation.
- Initial hover-only state snapshots preserve employee feet, poses, routes, animation, clock and resolved room geometry. The worker is replaced with an inert transport before `GameMain` is added; no real worker or saved company state is accessed.
- `validate_project`, `run_all`, `test_complete_game`, world-UI (**468**) and reader/HUD (**203**) pass. Final focused logs contain no script errors. Picker/native evidence from the earlier task is left unchanged.

All11 native screenshots were inspected at actual1280×720. Labels are readable and point to the correct station without clipping, rail spill or actor overlap. The crowded/removal fixtures intentionally exercise ordinary furniture rebuild effects; their temporary dust is not a new hover visual or an art regression. This is a discrete hover/input replay, not another continuous world-motion audit or proof of every possible furniture layout.

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_station_hover.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/station-hover/replay.avi --script res://tests/test_station_hover.gd
```

Scope remains intentionally small: no persistent labels for decorative coffee/research props, no fake interactions, no station E-binding, no new art or feature approval. Lunch presentation is owned by its separate pass.
