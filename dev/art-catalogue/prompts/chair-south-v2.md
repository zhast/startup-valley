# Chair south v2 — targeted alpha extraction

Mode: built-in ImageGen edit. Target inspected first: `game/assets/source/overnight-20260904/calibration/chair-south-v1.png`. V1 front geometry was acceptable as a study, but it was RGB with an opaque painted checkerboard. This retry changes only background/alpha, not geometry.

## Exact prompt

Use case: background-extraction
Input image 1 is the edit target. Extract exactly this front-facing charcoal and indigo pixel-art task chair onto genuinely transparent alpha. Remove the entire pale checkerboard BACKGROUND, including the background inside every gap around the armrests, stem, lever, spokes and casters. Keep the blue upholstery texture: that is part of the chair, not background.
Preserve the chair's exact silhouette, proportions, colors, pixel clusters, front-facing orientation, seat, backrest, lever on screen left, all five casters and upper-left highlights. Do not redraw, rotate, flip, stretch, add or remove any chair part. Do not add a shadow. One chair only, no labels.
Return a real RGBA PNG with zero-alpha background pixels, not a photograph or drawing of a checkerboard and not a solid-color matte. Transparent open gaps and transparent outside edges are essential.
