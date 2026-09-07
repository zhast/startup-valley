# Current runtime window review

2026-09-04. **Bounded pass: 232 rendered checks, 0 failures; 8 headless geometry checks, 0 failures.** No new scaling-specific defect found in the reviewed world/rail, Chat drawer, or artifact reader. This is a controlled dev-window audit after station-hover and lunch presentation changes, not an approval of all furniture art or every gameplay state.

## Scope and evidence

- Harness: `game/tools/capture_runtime_window_review.gd`, reusing only dev helpers from `capture_typography_scaling.gd`.
- Results: `game/tests/output/runtime-window-review/manifest.json`.
- Nine full content captures: `{native,integer2x,letterbox}-{world-hover,drawer,reader}.png`; nine `-detail.png` crops preserve the actual captured pixels without resizing.
- Fresh `GameMain` per size, worker replaced with `NullWorker` before `_ready`, no loaded state, worker process, credential, provider, or save access. Four-hire architecture with the real two-employee cast; day 12, 08:00, gross earned $123.5K. The disconnected UI is intentional, not a simulated working provider.
- World processing is frozen, while actual mouse/focus events and settled UI tweens remain functional. The reader contains local fixture Markdown and an exact mixed-script filename (`company/会社の計画—résumé.md`), not a filesystem read.
- No production code, artwork, window policy, preference, or fullscreen changes. The temporary window size and position are restored before the process exits.

| Requested window | Actual content | Scale | Content origin in window |
|---|---|---|---|
| 1280×720 | 1280×720 | 1× | (0, 0) |
| 2560×1440 | 2560×1440 | 2× | (0, 0) |
| 1600×1000 | 1600×900 | 1.25× | (0, 50) |

The tall window therefore reserves 50 pixels above and below its aspect-preserved composition. Godot's viewport texture excludes these outer bands: the saved PNG is 1600×900, **not a photograph of the entire 1600×1000 client window**. Their geometry and input transform are verified; their actual OS-composited color is not claimed from this capture. Intentional outer letterboxing is distinct from missing world pixels inside the composition.

## Checked and visually inspected

1. **World and callout.** Actual window-cursor motion to logical (128, 400) selects the visible archive surface and shows Studio. Its paper, pointer, and archive remain separated and readable at all sizes. A real mouse click starts the archive route. Native callout occupies approximately (105, 302)–(183, 350), above archive (96, 352)–(192, 448). Five explicit interior floor probes remain nonblack; visual inspection of the full compositions found no exposed black canvas. This is not a blanket test against legitimate charcoal art.
2. **UI mapping and isolation.** A physical-coordinate portrait click selects Mina and opens the drawer without a world route. Station hover clears beneath the drawer. HUD remains at logical (371, 8, 408, 68), rail at (1150, 0, 130, 720), and the settled drawer at (782, 0, 368, 720), contiguous with the rail. One draft assertion still expected obsolete x=784; it was corrected to the actual zero-gap production geometry, not by changing the screen.
3. **Reader.** The frame stays within logical (316, 60, 648, 600); filename, provenance, heading/body hierarchy, close control and scroll track remain readable and contained. Physical-coordinate wheel events scroll the long document and clicking the rendered close control closes it at each size. Logical control rectangles and semantic font sizes agree across all cases.
4. **Native sampling.** Current employee sprites and all resolved prop layers retain scale (1, 1), nearest filtering, and integer-snapped logical positions. ImageMagick absolute-error comparisons between the final native image point-enlarged 2× and the final 2× image returned **0** for the archive sample (36,864 physical pixels) and floor sample (51,200 pixels). These validate world raster sampling, not identical antialiased body-text rasters.
5. **At-rest stability.** Four repeated frozen-world frames per size have identical SHA-256 values. This rules out stationary drift in these cases. It does not test moving actors, camera motion, every animation, or long-duration timing.

Independently inspected all nine full compositions. The 2560×1440 full images were viewer-downsampled, so all three corresponding actual-pixel crops were also inspected: 440×500 world, 996×1440 drawer/rail, and 1296×1200 reader. Native and 1600×900 full captures were inspectable without that reduction. No clipped text, detached pointer, internal black gap, half-pixel logical sprite placement, or size-dependent click offset was observed in this set.

## Limits and next action

- **Fractional scaling is not pixel-perfect.** At 1.25×, a logical art pixel cannot always occupy an equal integer number of display pixels; repeated edges can alternate physical widths. The current aspect-preserving `canvas_items` policy deliberately permits this. Static readability is acceptable in the sampled composition, but no claim of native-grid equivalence or motion shimmer elimination is made.
- This is a macOS controlled-window result. OS fullscreen, display switching, browser scaling, other OSes, and persisted player preferences were not changed or retested.
- Only one station, one portrait, and reader wheel/close were exercised per shape. Crowded/rail placement and the broader input state space remain covered by their separate focused hover/picking suites, not newly revalidated here.
- Root independently found a founder-body occluder omission while this review ran. This frozen snapshot **precedes that picking correction**; its station/portrait mapping success does not refute that separate semantic bug. Keep its before/after evidence separate.
- No production scaling change is justified by this bounded result. If uniform physical pixel widths at arbitrary windows become a product requirement, explicitly evaluate integer-only letterboxing as a separate policy decision rather than silently shrinking or altering this layout.

## Reproduction and frozen source

```sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_runtime_window_review.gd
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --script res://tools/capture_runtime_window_review.gd
```

Final process exited 0. Final replay log: `/tmp/runtime-window-review-final.log`. Source hashes captured at its completion, before the founder-occluder correction:

| File | SHA-256 |
|---|---|
| `game/tools/capture_runtime_window_review.gd` | `d96abfb842705f2f150df55a3cc8da9279eb074efa8e8fa730342cfda2bf84c1` |
| `game/world/main.gd` | `8c5a6e71ba3da30d9b1525fff6d7c623da2da9020fb728203844c9f343e8ed12` |
| `game/world/town_room.gd` | `1d0865c1b88453494dffee6caf4d5f563326ac2432274e2bbb2b43a5e9225406` |
| `game/actors/employee_avatar.gd` | `da8eb02de50c64a439c029d0632b84ec1422bb3b0547ca38e2e583945730d16e` |
| `game/actors/player_avatar.gd` | `8e3736788ac99fbe15195ccae5450e6da4994e2d64dad3598af38bf65dee810d` |
| `game/ui/founder_hud.gd` | `08689f280a9306f64dcc7998d17bec7a050b7b9f22f67749635b551caf985441` |
