# Modular office asset contract

Every runtime office prop must follow this contract before it is added to `town.json`.

## Projection

- Oblique orthographic view on a square logical grid; never true diamond isometric.
- Screen X and Y remain the room axes. Long front edges are horizontal and object centerlines are vertical.
- No arbitrary yaw or runtime rotation. A different facing direction requires a separately drawn cardinal sprite.
- Camera elevation, visible top-surface depth, upper-left light, and pixel density must match the approved environment and character sheets.

## Runtime scale and anchor

- One logical tile is 32 × 32 game pixels.
- A standard workstation occupies a 3 × 2 tile collision footprint and renders approximately 96 × 72 opaque pixels.
- The Node2D origin is the bottom-center ground-contact point, not the center of the source canvas.
- Transparent padding is allowed, but scenes must offset the sprite so the bottom of its opaque footprint lands at local Y = 0.

## Layers

- `office-shell-base.png` contains permanent architecture and flooring only.
- Movable furniture and equipment are independent transparent assets and reusable scenes.
- Props and characters use absolute Z order derived from their world-space ground-contact Y.
- Tall objects may split into base and canopy layers when one Y-sorted sprite cannot occlude a character correctly.
- Collision shapes describe the floor footprint independently of the visual bounds.

## Acceptance

- Transparent background with no baked floor, room, text, people, or rectangular backdrop.
- Crisp nearest-neighbor rendering at runtime.
- Correct footprint and bottom-center anchor.
- Reads correctly in front of and behind a live character in the running game.
- Placement and hire threshold live in `res://data/town.json`; never bake placement into the shell art.
