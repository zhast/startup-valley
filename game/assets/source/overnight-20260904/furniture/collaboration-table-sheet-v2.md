# Collaboration table sheet v2

- Built-in ImageGen targeted retry 1, 2026-09-04.
- SHA-256: `ee8749c5252eb5b9c7b534ec1a406e66de00e4a0652900e13657902957378f14`
- Measured source: 1254×1254 RGB.
- Disposition: **cleanup source; no native export yet**. East/West now use the
  correct vertical screen axis and the four silhouettes are isolated, but the
  requested alpha correction again returned an opaque baked checkerboard.
  Direction-specific note arrangements are present; N/S and E/W structure is
  deliberately equivalent and must be reviewed after a lawful alpha export.

## Prompt

```text
Use case: precise-object-edit
Asset type: production source sheet for a pixel-art game furniture sprite
Input images: Image 1 is the edit target; Image 2 is the authoritative fixed-camera N/E/S/W projection guide.
Primary request: Correct only two defects in Image 1. First, remove the entire pale checkerboard/background and return genuine transparency. Second, redraw the top-right and bottom-right objects as true long-axis East and West views of the same five-by-two-cell collaboration table: their long tabletop axis must run vertically on screen like the two narrow vertical desk views in Image 2, while remaining fully visible. Keep the top-left North and bottom-left South table designs, materials, proportions, note placement language, and compact pixel style unchanged.
Composition/framing: retain a clean 2x2 grid with North top-left, East top-right, South bottom-left, West bottom-right; wide transparent gutters; equal physical scale and shared floor-pivot logic.
Constraints: change only background transparency and the two side projections; no chairs, people, plants, computers, extra objects, labels, letters, UI, watermark, floor, room, checkerboard, matte halo, diagonal yaw, vanishing-point perspective, blur, anti-aliasing, rotated or mirrored finished bitmaps. Upper-left light remains consistent while asymmetric notes and cable tray are authored for each direction.
```

References used:

- `game/assets/source/overnight-20260904/furniture/collaboration-table-sheet-v1.png`
- `game/tests/output/modular-desk-export/assembled-native.png`
