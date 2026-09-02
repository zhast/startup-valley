# Runtime office art

The runtime office is assembled in layers so moving characters can sort correctly around furniture:

- `office-shell-base.png` contains only permanent architecture and flooring.
- `employee-workstation.png` is one reusable transparent prop instantiated per employee.
- `research-bench.png` is one transparent research prop.
- `collaboration-cluster.png` is the first-hire informal meeting area.
- `coffee-station.png` is the first-hire shared coffee counter.
- `approval-console.png` is the third-hire operations review desk.
- `artifact-archive.png` is the fourth-hire completed-work display.
- `prototype-bench.png` is the fourth-hire maker station.
- `main-office-background.png` is retained only as the mature-office composition reference; it is no longer rendered by the game.

The coffee, approval, archive, and prototype source plates use a uniform magenta production key because the image generator would not preserve a clean alpha channel. Their typed prop scenes apply `chroma_key.gdshader` at render time; the keyed color is never visible in game.

`TownRoom` scales the shell to the existing 26 × 18 logical grid, instantiates typed prop scenes from `res://data/town.json`, and covers unavailable wings with collidable renovation panels. Props and live characters receive absolute Z order from their world Y coordinate. A desk's work point is behind its anchor so the employee is visibly occluded by the desk while working.

The current unlock thresholds are deliberately simple and derive from the authoritative employee records returned by the worker:

| Hires | Newly available space |
| --- | --- |
| 0 | Founder studio only |
| 1 | Meeting and coffee wing |
| 2 | Research lab |
| 3 | Operations and approvals |
| 4 | Artifact studio |

The legacy composition reference was produced with the built-in ImageGen tool from the approved office key art. Its final edit prompt was:

> Remove only the three human characters: the blue-jacket worker at the upper-left desk, the green-cardigan worker at the upper-right desk, and the orange-shirt worker at the lower-right desk. Reconstruct the small portions of chairs, desks, monitors, and floor hidden behind them so all three workstations look naturally empty and ready for live game sprites. Preserve the entire office exactly otherwise—same camera, crop, dimensions, aspect ratio, floor plan, walls, windows, plants, furniture, equipment, drone, lighting, palette, pixel-art treatment, object positions, walkways, and visual density. Do not add any people, creatures, text, logos, UI, new props, or new architectural details. Do not move, redesign, crop, relight, or restyle anything. Keep the assignment-board cards abstract and unreadable. No watermark.

The modular shell, workstation, and research bench were produced with the built-in ImageGen tool as separate assets. Their accepted prompt set was:

> Convert the supplied mature office image into an empty office shell for a layered 2D game. Remove every movable object, furniture item, plant, machine, character, and decoration, reconstructing the continuous floor beneath them. Preserve only the permanent architectural shell, exact camera, crop, footprint, walls, windows, pixel-art language, lighting, and palette. No people, text, logos, UI, or watermark.

> Extract only the first computer workstation from the supplied original environment sheet: the far-left wooden desk in the third row with monitor, keyboard, mouse, plant, and books. Preserve its screen-aligned three-quarter-overhead projection, proportions, palette, lighting, and front-facing orientation. Remove every other asset and the atmospheric backdrop. Center it with transparent padding, a horizontal front edge, and a bottom-center anchor. Do not redesign or rotate it.

> Extract only the gray-topped research worktable from the supplied original environment sheet, including its microscope, sample vials, diagram tablet, notebook, books, and tools. Preserve its screen-aligned three-quarter-overhead projection, proportions, palette, lighting, and front-facing orientation. Remove every other asset and the atmospheric backdrop. Center it with transparent padding, a horizontal front edge, and a bottom-center anchor. Do not redesign or rotate it.

The staged social, operations, and artifact props were also produced with the built-in ImageGen tool. The accepted production prompts were:

> Extract only the informal collaboration cluster from the supplied tech props sheet: the three teal, vermilion-orange, and indigo-blue beanbag chairs around the small round walnut table with one succulent. Preserve the exact screen-aligned oblique-orthographic projection, proportions, pixel density, palette, upper-left lighting, horizontal table edge, and front-facing orientation. Remove the baked checkerboard and every other asset. Use genuine transparency with tight padding and a bottom-center floor anchor; no floor, room, wall, halo, people, text, logos, watermark, or added objects.

> Correct the supplied coffee station to strict screen-aligned oblique orthographic projection while preserving its espresso machine, grinder, mugs, plant, walnut counter, proportions, palette, pixel density, and upper-left lighting. Long front and back edges must be horizontal, the centerline vertical, with zero yaw and no perspective convergence. Place exactly one station on a uniform RGB #FF00FF chroma-key field with no gradient, texture, shadow, vignette, glow, halo, noise, or transparency.

> Create one compact approvals console: a walnut and charcoal operations desk with a front-facing indigo display, prominent vermilion approval button, chartreuse status lamp, paper tray, and restrained cables. Match the approved cozy farm-sim startup pixel art and room camera. Use strict screen-aligned oblique orthographic projection and a bottom-center anchor. Place exactly one console on a uniform RGB #FF00FF chroma-key field with no atmosphere, room, people, text, logos, or watermark.

> Create one front-facing artifact archive cabinet combining off-white smart lockers, indigo glass prototype displays, a charcoal frame, walnut drawers, one vermilion accent, and chartreuse status lights. Match the approved pixel density, upper-left lighting, palette, and room camera. Use strict screen-aligned oblique orthographic projection and a bottom-center anchor. Place exactly one cabinet on a uniform RGB #FF00FF chroma-key field with no atmosphere, room, people, text, logos, or watermark.

> Create one compact prototype workbench with a small off-white desktop 3D printer, charcoal tool tray, two tiny finished prototypes, an indigo cutting mat, one vermilion accent, and a chartreuse status lamp. Match the approved cozy startup pixel art and exact room elevation. Keep front and back edges horizontal with zero yaw. Place exactly one workbench on a uniform RGB #FF00FF chroma-key field with a hard silhouette and no atmosphere, room, people, text, logos, or watermark.

Logical coordinates in `res://data/town.json` remain authoritative for movement, prop placement, unlock thresholds, and work destinations. Add future office features as one transparent prop plus one data placement at a time; do not paint them back into the shell. The precise projection, scale, anchor, layering, and acceptance rules live in `ASSET_SPEC.md`.
