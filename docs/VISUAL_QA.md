# Visual quality and playable-world checks

## Tool choice

Keep the existing Godot engine tests, shared-worker tests and asset/map admission
tools. Add focused checks around a demonstrated failure rather than migrating
the suite to another test framework. The practical stack is:

| Need | Tool and use | Limit |
| --- | --- | --- |
| Responsive game UI | Godot Control anchors, Containers and measured layout assertions | Valid rectangles do not establish good composition or readable copy. |
| Character/furniture scale | Same-scale engine comparison scene, registered pivots, occupied cells and physical landmarks | Total PNG size includes transparent padding and cannot establish object scale. |
| Reusable world | Shared 32px logical grid and TileMapLayer/TileSet resources; registered prop profiles | Visible terrain still needs authoritative movement/travel rules. |
| Regression detection | Versioned screenshots, exact source/build hashes and explicit review; pixel diffs where state is stable | A screenshot matching a bad baseline is still bad. |
| Movement and progression | Headless Godot with actual input and production worker, then in-app browser playthrough | Headless success does not verify browser rendering. |
| Performance | Godot standard profiler/monitors, browser errors and observed frame behavior | A screenshot cannot prove frame pacing or input latency. |

Godot recommends Containers for complex game UI such as RPG and tycoon menus;
they manage child positioning and resize behavior. Use anchors for the outer
safe rectangle and Containers inside it. Do not fight Container layout with
manual child offsets. [Godot Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html),
[anchors](https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html).

Godot recommends saving a shared TileSet as an external resource for reuse
across levels, with separate TileMapLayers where foreground/background or
collision behavior differs. Terrain connections can choose adjoining cells;
the artwork must actually supply the required joins.
[Godot TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html).

Playwright's `toHaveScreenshot()` is a reasonable future browser-CI choice when
we provision a fixed browser runner. Its documentation warns that screenshots
vary with operating system, browser settings, hardware and headless mode. Keep
baseline and actual captures in the same environment. The current interactive
browser review uses Codex's supported in-app browser APIs; it is not evidence
that a new Playwright screenshot suite has been installed.
[Playwright visual comparisons](https://playwright.dev/docs/test-snapshots).

Use the standard Godot profiler and monitors for game cost and memory. Its
Visual Profiler is unsupported with the Compatibility renderer on macOS, so it
is not our promised profiling path. Keep exact engine/backend information in
performance reports. [Godot debugger and profilers](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html).

## Non-disruptive execution

The owner explicitly asked us to stop opening Godot windows. Run engine tests
with `--headless`; use the existing Codex in-app browser tab for new visual
checks, without bringing this chat forward. Do not use OS-level control or
open another browser profile. Previous native captures remain useful recorded
evidence, but do not label a changed build verified by an old screenshot.

Use a disposable localhost origin for the playthrough so the owner's save is
not reset. Keep normal `dist` on the last accepted build while assets/maps are
being reviewed; isolate candidate exports. Rebuild the normal preview promptly
once its admission checks pass, then verify the served build ID and payloads.

## The review loop

1. **State the visible outcome.** For Mina: centered within the whole game
   canvas, portrait and role visible, short introduction, one obvious action,
   no large unused header or unnecessary scrolling. For furniture: consistent
   camera/materials, usable seat and desk heights, feet on the same floor.
2. **Capture the current failure.** Preserve the exact screenshot, viewport,
   source/build identity, save/scenario, renderer, date and observed behavior.
   A cropped comparison helps analysis; retain the full context as well.
3. **Change the source contract.** Fix layout rules, art registration or the
   shared module instead of placing a one-off patch over the symptom. Keep
   generation prompts and transformations reproducible. Explicitly distinguish
   generated, manually adjusted, code-native and unknown legacy artwork.
4. **Run focused automated checks.** Check geometry and actual interactions,
   invalid cases and persistence. Avoid tests that merely assert the new
   constant equals itself. A useful test should fail when the defect returns.
5. **Inspect the rendered result.** Compare before/after at matching size and
   state. Inspect the whole room and a native-pixel crop, then move through the
   relevant interaction. Do not approve a generation source or contact sheet
   as a substitute for the actual game composition.
6. **Save a tested checkpoint.** Record what is approved and what remains open,
   commit and push. Refresh the normal preview after the complete gate passes.
   Before demo delivery, run the full journey on one unchanged build.

## Required views and assertions

| Surface | Automated check | Rendered/play check |
| --- | --- | --- |
| Invite / welcome / Theo dialogue | 1280×720, 1440×900, 1024×576; centered safe bounds, no clipped/overlapping labels, visible portrait and action, no unwanted scroll | Person, role and next action understood at a glance; balanced spacing; focus visible |
| Workstations | Four facings, each actor, idle/blink/typing frames, actual entry/exit and wrong-depth negative control | Chair back, face, hands, desk and legs occlude in the correct order |
| Standalone props | Native scale, ground pivot, painted bounds, collision footprint, seat/table/opening landmarks | Same-scale actors beside props; no floating feet, giant chairs or implausibly small doors |
| Maps | Grid coordinates, supported modules, spawn/return reachability, no off-floor footprints | Continuous path at threshold, coherent terrain density, no implied unavailable exits, front/behind crossings |
| Opening journey | Actual input, hire, start, day advancement, release, rewards and save/reopen | Obvious current goal, responsive clicks, readable feedback, no rendering artifacts |
| Browser delivery | Export/payload identity, provider-free bundle, no game/runtime errors | Actual WebGL game running; movement, dialogue, release and persistence on the served build |

For scale, measure floor contacts and vertical rise separately from floor
projection. A 160px canvas does not mean the chair is 160px tall. Use the
same actor reference and camera in all comparisons. A chair and desk should
share plausible seat/table relationships, even though this is a stylized game.

For animated defects, capture a timed sequence rather than a single attractive
frame. A face may look correct with eyes open but break for every blink. For
static screenshot diffs, hold game time, actors, hover and focus stable; record
any masked region and test its animation separately. Never mask an entire
character to hide an unresolved blink or layering defect.

The existing `run_all.gd` screenshot comparator downsamples to 160×90. Treat it
as a coarse composition alarm only: it can miss one-pixel eyes, chair edges and
small text clipping. Focused native-resolution checks and actual browser review
must cover those failures. Baseline updates require inspecting the new image;
do not automatically accept every diff or change frozen legacy inventories.

## Current implementation and evidence

- [Compact invitation](web/compact-invitation.md): 680×256 logical card,
  full-canvas horizontal centering, 144×160 portrait frame, no empty header.
  The retained native layout run passed 250 checks across three sizes. The
  headless rerun passes 241 (native-only capture assertions are omitted).
- `game/tests/test_story_dialogue_layout.gd` measures content and action bounds,
  checks real pointer activation and avoids stale furnishing reward messages.
- `game/tests/test_furnishing_rewards_projection.gd` checks that authoritative
  inventory arrives before reward completion, old responses preserve the room,
  and the arrival visitor retains her exact collision under her protocol ID.
- [Asset workflow](ASSET_WORKFLOW.md), [map workflow](MAP_WORKFLOW.md), and
  `scripts/validate-furniture-scale.mjs` define complementary admission gates.
  Reviewed image hashes do not certify every scene or all legacy assets.
- [World composition audit](WORLD_COMPOSITION_AUDIT.md) records the rejected
  garden/office mismatch. Replacement terrain must get new rendered evidence;
  passing navigation alone cannot close this defect.

These checks do not establish complete accessibility. In particular, screenshot
review cannot prove screen-reader support, keyboard coverage or input latency.
Check visible contrast, focus, text size and hit targets, then report exactly
which actual controls and input modes were exercised.
