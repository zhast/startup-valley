# Collaboration table sheet v1

- Built-in ImageGen, 2026-09-04.
- SHA-256: `ab41228c0922bad5ba34301f5c9ab6d40e78c8b45bd399f1ea19e0105fca2d43`
- Measured source: 1254×1254 RGB.
- Disposition: **rejected source; no native export**. Despite the explicit
  transparent-background constraint, the output bakes a light checkerboard.
  The two narrow variants are foreshortened front elevations rather than
  convincing independently authored East/West fixed-camera views. Retain as
  evidence and material/detail reference only.

## Prompt

```text
Use case: stylized-concept
Asset type: production source sheet for a pixel-art game furniture sprite
Primary request: Design one reusable Startup Valley collaboration table, shown as four genuinely authored fixed-camera views: north-facing, east-facing, south-facing, and west-facing. The table is a warm oak five-by-two-cell shared planning table with restrained charcoal metal legs, a subtle indigo inset cable tray, and a few removable-looking paper notes and pencils; no chairs, no people, no plants, no computers.
Input images: Image 1 is the actual game room and authoritative cozy-tech pixel scale/palette context; Image 2 is the authoritative screen-aligned fixed-camera geometry and oak/charcoal material reference; Image 3 shows the cozy lounge color mood only and must not be copied as a baked cluster.
Style/medium: crisp hand-authored 2D pixel art, cozy farming-sim readability blended with a modern Silicon Valley office; original Startup Valley design; hard pixel edges and compact palette.
Composition/framing: one square source sheet with a clean 2x2 grid, one isolated complete view centered in each quadrant with wide empty gutters. Horizontal north/south views share physical size; vertical east/west views share physical size. Maintain the same floor pivot and scale. Draw each view independently for its camera-facing elevation and upper-left light; never rotate or mirror a finished view.
Lighting/mood: warm indoor daylight, upper-left key light, restrained Whop accents.
Color palette: warm medium oak, parchment, Charcoal #151515, Indigo #354B98, very sparse Vermilion #FA4616; do not recolor the whole object orange.
Constraints: genuinely transparent background; no checkerboard, matte, floor, room, shadows baked into the background, labels, letters, UI, watermark, diamond-isometric perspective, perspective vanishing point, diagonal 3/4 yaw, photorealism, anti-aliased blur, chairs, characters, or duplicated objects within a quadrant. Keep every leg and tabletop edge fully visible and leave generous transparent padding around each view.
```

References used:

- `game/tests/output/visual-review/office-hires-4.png`
- `game/tests/output/modular-desk-export/assembled-native.png`
- `game/assets/runtime/office/collaboration-cluster.png`
