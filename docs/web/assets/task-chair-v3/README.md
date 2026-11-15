# Wooden task-chair evidence

- `before/`: original runtime chairs in the actual production room, all four facings, empty/seated/typing. The original source PNGs are also retained under `game/assets/source/task-chair-v3/previous-runtime`.
- `after/`: final six runtime modules in the same room; both Mina and Theo, two seated cells and four typing cells per direction. `results.json` records346 passing checks over48 poses. Full frames are1280×720; `-mira`/`-theo` views are exact3× nearest crops.
- `native-48-pose-contact.png`: native-pixel crops arranged from those actual rendered frames; rows are labeled, columns show both seated cells and all typing cells.
- `normalized-four-views.png`:4× nearest source inspection, not an in-game capture.
- `motion/`: actual production navigation/handoff driven by a bounded fixture, not player input. `results.json` contains1200 per-tick actor samples;1388 assertions pass. Entry and exit contacts show both actors in all four directions. Original full endpoint screenshots are retained. The fixture does not reposition actors during a route or alter their seat metadata.
- `workstation-production.log`:273 passing admission checks. `seat-transition.log`:4729 passing transition checks.

All rendering above completed before the user requested that windowed Godot demos stop. No subsequent windowed run is authorized by this evidence workflow. Remaining checks are headless; current normal web exports are owned by the root agent.

The original tall-back sample was rejected. The accepted normalization shortens only the back and keeps the cushion/legs in place; it does not resize the desk or actors. See the retained prompt, raw generated output, deterministic builder and technical report in `game/assets/source/task-chair-v3`.

`collaboration-results.json` / `collaboration-headless.log` record712 passing checks for actual four-facing routing, hold, work interruption, collision, rotation and shared-module pixel equivalence. The new full native collaboration sheet was not saved because the user stopped windowed tests before completion; the source-equivalence proof and headless lifecycle are retained without claiming that missing capture. `reproduction.log` confirms all six runtime modules reproduce byte-for-byte from the retained source.
