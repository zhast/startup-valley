# Modular office asset contract

Every runtime office prop must follow this contract before it is added to
`office_layout.json` with a profile in `furniture_catalog.json`.

## Projection

- Oblique orthographic view on a square logical grid; never true diamond isometric.
- Screen X and Y remain the room axes. Long front edges are horizontal and object centerlines are vertical.
- No arbitrary yaw or runtime rotation. A different facing direction requires a separately drawn cardinal sprite.
- Camera elevation, visible top-surface depth, upper-left light, and pixel density must match the approved environment and character sheets.

## Runtime scale and anchor

- One logical tile is 32 × 32 game pixels.
- A standard workstation occupies three floor cells in one row. Its separate
  north chair lane and south interaction point stay walkable. Its art uses two
  registered 128 × 112 atlas cells; no runtime downscaling.
- The Node2D origin is the bottom-center ground-contact point, not the center of the source canvas.
- Transparent padding is allowed, but scenes must offset the sprite so the bottom of its opaque footprint lands at local Y = 0.

## Layers

- `architecture/` contains native 32px floor/wall/corner materials and window/
  doorway modules. Architecture and wall collision derive from `OfficeLayout`.
- Old shell/campus images are retained references, never layered into the game.
- Movable furniture and equipment are independent transparent assets and reusable scenes.
- Props and characters use absolute Z order derived from their world-space ground-contact Y.
- Tall objects may split into base and canopy layers when one Y-sorted sprite cannot occlude a character correctly.
- Collision shapes are generated from catalog occupied floor cells. Clearance,
  interaction/work cells, native image bounds, sprite offsets, and layer depth
  offsets are explicit catalog fields consumed by the renderer and navigation.
- Furniture image bounds must not intersect walls or other furniture. Employee
  occlusion by the desk's front layer is intentional, not a placement conflict.

## Acceptance

- Transparent background with no baked floor, room, text, people, or rectangular backdrop.
- Crisp nearest-neighbor rendering at runtime.
- Correct footprint and bottom-center anchor.
- Reads correctly in front of and behind a live character in the running game.
- Placement and hire threshold live in `res://data/office_layout.json`; never
  bake placement into architecture art. Validate stages 0–4 and reachability.
- Only authored south facings currently ship. Add a new authored atlas/profile
  before enabling another facing; never rotate or mirror a workstation.
