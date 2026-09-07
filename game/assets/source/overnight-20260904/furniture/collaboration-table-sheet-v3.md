# Collaboration table sheet v3

- Built-in ImageGen targeted retry 2 (final bounded retry), 2026-09-04.
- SHA-256: `ca5fc5929a7f8d62721f05dfbe1932ee979220e4d0ace8666e7ba8096003ab4f`
- Measured source: 1536×1024 RGBA; alpha range 0–254.
- Disposition: **rejected source; request exhausted; no native export**. The
  background is technically transparent over most pixels, but the edit changed
  the canvas, object positions and scale despite an exact-preservation request.
  Horizontal and vertical views no longer share one physical pixel scale, so
  normalizing them would require direction-specific rescaling that violates the
  fixed-camera contract. This source may inform palette and joinery only.
- Next method: exact code-native geometry on the established 32-pixel grid,
  using the already accepted oak/charcoal material vocabulary. This is a
  materially different deterministic construction, not a renamed fourth image
  retry.

## Prompt

```text
Use case: background-extraction
Asset type: production source sheet for a pixel-art game furniture sprite
Input images: Image 1 is the sole edit target.
Primary request: Extract the four table sprites exactly from Image 1 and make every background/checkerboard pixel genuinely transparent.
Constraints: change only the background alpha. Preserve every table pixel, shape, position, scale, color, hard edge, note, cable tray, leg, quadrant, and gutter exactly. Output one PNG with a real alpha channel. No visible checkerboard, white/off-white matte, halo, floor, shadow, room, text, watermark, new pixels, smoothing, restyling, resizing, repositioning, object edits, or extra elements.
```

Reference used:

- `game/assets/source/overnight-20260904/furniture/collaboration-table-sheet-v2.png`
