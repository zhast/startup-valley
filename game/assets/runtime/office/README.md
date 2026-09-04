# Runtime office art

The runtime office is assembled in layers so moving characters can sort correctly around furniture:

- `architecture/` is the active native tile kit: floor, wall elevation, trim and
  corners, window scenery, and open doorway threshold. Its README/manifest
  document source crops, dimensions, alpha and seam tests.
- `office-shell-base.png` and `campus-surround.png` are retired composition
  references. Neither is rendered in the current game.
- `south-workstation.png` is the active founder/employee workstation: two
  registered 128×112 cells, chair/far tabletop then desk/monitor front. We see the
  monitor's back; the seated employee faces it from the north side.
- `layered-furniture.png` row 1 provides the active research bench layers.
  Its old workstation row 0 is superseded.
- `employee-workstation.png` and `research-bench.png` are retained older
  standalone plates, not rendered by the current prop scenes.
- `collaboration-cluster.png` is the first-hire informal meeting area.
- `coffee-station.png` is the first-hire shared coffee counter.
- `approval-console.png` is the second-hire operations review desk.
- `artifact-archive.png` is the first-hire completed-work display.
- `prototype-bench.png` is the fourth-hire maker station.
- `main-office-background.png` is retained only as the mature-office composition reference; it is no longer rendered by the game.

The coffee, approval, archive, and prototype source plates were generated on uniform magenta production fields because the image generator would not preserve clean alpha. The checked-in runtime images were deterministically matte-converted to genuine transparency, so every prop scene now renders a normal alpha PNG without a special material.

`TownRoom` resolves `res://data/office_layout.json` and
`res://data/furniture_catalog.json` through `OfficeLayout`. The 40 × 23 logical
grid fills the 1280 × 720 composition (the solid final row is partially cropped).
`OfficeArchitecture` renders the same floor/wall definition used by navigation
and collision. Locked areas remain empty. Props and characters use ground-Y
depth. A desk's work point is 32 px north of its anchor; the founder approaches
from a separate south interaction point.

The current unlock thresholds are deliberately simple and derive from the authoritative employee records returned by the worker:

| Hires | Newly available space |
| --- | --- |
| 0 | Founder studio only |
| 1 | Mina, meeting/coffee wing, artifact archive |
| 2 | Theo, research lab, operations/approvals |
| 3 | No additional prop in the two-employee slice |
| 4 | Prototype bench (developer growth preview) |

Rebuild the corrected workstation and seated poses with
`dev/tools/build_workstation_assets.sh`. The desk is normalized once before
splitting at row 45, just above the monitor. The far tabletop stays behind the
typing hands; never trim the layers independently.
Generation prompts and verification: `dev/GRAPHICS_REPAIR.md`.

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

The old `town.json` is retained as a legacy reference, not a runtime authority.
Use the developer placement tool and validate every growth stage before editing
the active office layout. Do not paint furniture or another room background into
the architecture. See `ASSET_SPEC.md` and `dev/MODULAR_OFFICE_IMPLEMENTATION.md`.
