# Runtime office art

`main-office-background.png` is the character-free runtime rendering of the mature office. `TownRoom` scales it to the existing 26 × 18 logical grid, then covers unavailable wings with collidable renovation panels.

The current unlock thresholds are deliberately simple and derive from the authoritative employee records returned by the worker:

| Hires | Newly available space |
| --- | --- |
| 0 | Founder studio only |
| 1 | Meeting and coffee wing |
| 2 | Research lab |
| 3 | Operations and approvals |
| 4 | Artifact studio |

The background was produced with the built-in ImageGen tool from the approved office key art. Final edit prompt:

> Remove only the three human characters: the blue-jacket worker at the upper-left desk, the green-cardigan worker at the upper-right desk, and the orange-shirt worker at the lower-right desk. Reconstruct the small portions of chairs, desks, monitors, and floor hidden behind them so all three workstations look naturally empty and ready for live game sprites. Preserve the entire office exactly otherwise—same camera, crop, dimensions, aspect ratio, floor plan, walls, windows, plants, furniture, equipment, drone, lighting, palette, pixel-art treatment, object positions, walkways, and visual density. Do not add any people, creatures, text, logos, UI, new props, or new architectural details. Do not move, redesign, crop, relight, or restyle anything. Keep the assignment-board cards abstract and unreadable. No watermark.

The image is a runtime background, not a source tileset. Logical coordinates in `res://data/town.json` remain authoritative for movement and work destinations.
