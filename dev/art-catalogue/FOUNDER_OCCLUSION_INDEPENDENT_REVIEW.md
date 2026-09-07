# Founder occlusion — independent review

2026-09-04. **No production correction requested.** The narrow founder-body addition follows the existing alpha/depth contract and removes the two demonstrated hidden-target actions without making the founder interactive.

## Code and frozen evidence reviewed

- `game/actors/player_avatar.gd:41`: returns only the actual character sprite when `VisibleSurface.painted` accepts its source pixel. Shadow, transparent atlas padding, and callouts are not part of the body mask.
- `game/world/main.gd:620`: props and employees first establish their actual top surface; the founder suppresses its action only when the founder's body is in front. It does not globally prioritize the player over visible foreground furniture/employees.
- `game/world/visible_surface.gd`: native `Sprite2D.is_pixel_opaque`, ancestor modulation, effective Z, then scene order. No new image readback or synthetic body rectangle is introduced.
- `game/world/main.gd:596`: an empty interaction retains normal ground-click handling. Walkable ground may route; blocked ground gives invalid feedback. It neither substitutes a hidden object's socket nor creates a founder menu.
- `game/tools/capture_founder_occlusion.gd` and the test alias: real mouse events, exact native visible-pixel comparison, hidden/self-alpha controls, foreground founder over station/employee, and background founder control.
- Frozen manifests: BEFORE 8 headless / 12 native checks; AFTER 27 headless / 33 native checks, all with zero recorded failures. Independently inspected all three AFTER native PNGs. The recorded pixels (336, 238), (464, 398), and (464, 364) agree with the intended foreground/body ownership. Images and manifests were not overwritten.

The root fixture intentionally forces overlapping actors to test picking; it is not evidence that navigation should allow those final positions. Native click events use viewport coordinates; scaled physical-window mapping is covered separately by `RUNTIME_WINDOW_REVIEW.md`.

## Additional independent probe

New dev-only `game/tools/probe_founder_occlusion_review.gd` extends the inert fixture setup, writes only `game/tests/output/founder-occlusion-review/headless.json`, and refuses graphical execution. **57 checks / 0 failures**, repeated across three fresh `GameMain` instances:

- Real transparent founder atlas pixel at (472.5, 422.5) leaves visible Mina selectable through actual click dispatch.
- Opaque overlap at (470.5, 431.5) suppresses Mina; parent alpha zero restores her selection.
- Real shadow-only pixel at (465.5, 466.5) is not part of the founder body.
- Equal effective Z respects scene order in both branch orders; neither actor gets an arbitrary fixed priority.
- Clicking founder-covered walkable ground retains a route to the clicked coordinate, not the hidden employee's destination.
- A measured blocked overlap at (346.5, 287.5) produces neither a hidden desk action nor a route.
- Each `GameMain` instance is destroyed, root has no remaining fixture nodes, and orphan Node count remains **0 → 0** after all three cycles.

One first-draft probe assumption was wrong: root's (336, 238) monitor point lies above the desk's physical floor footprint and is walkable ground. The final probe searches an actual blocked cell rather than conflating visible image overhang with collision. No production change was needed.

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --verbose --path game --script res://tools/probe_founder_occlusion_review.gd
```

Final process exited 0; `/tmp/founder-occlusion-independent-review-final.log` contains no ObjectDB/leak warning. The separate output records exact tested points and counts. No worker, provider, saved state, or rendering session was used.

## Teardown and coverage limits

The historical two-instance native BEFORE shutdown warning cannot be attributed from its manifest alone. The independent verbose **headless** replay is clean after fixture destruction and a short drain for transient UI timers, but that does not prove the lost native warning was harmless or identify those two objects. A future native failure should retain its verbose shutdown log; do not claim the warning was fixed by the picking change.

The shared picker remains intentionally scoped to the present single world canvas, native source-alpha sprites and explicit Z ordering. Partial-alpha blending, custom shader masks, multiple CanvasLayers, and Y-sort hierarchies are not newly supported or required here. Current founder source art has the expected native alpha mask. Broader UI-over-world isolation and all-direction workstation coverage remain in their original focused suites.

## Adjacent decorative branch read

At the company agent's request, also read the current `OfficeLayout` decorative schema/admission and `TownRoom` factory/picking path. No concrete admission leak or fabricated live interaction found: the permit is exact-definition and live-owner bound, reconfiguration/dead owners revoke it, production requires art/geometry review, explicit geometry is validated, generic carriers are created only after successful resolution, and passive foreground surfaces suppress underlying actions. Decorative profiles reject seat/service/action metadata; their resolved placement has no interaction coordinate, and the room returns an infinite sentinel/no workstation pose rather than an invented socket. Optional `standing_viewpoints` remain geometry-only. This was source/test inspection, not independent execution of the company's evolving passive suite.
