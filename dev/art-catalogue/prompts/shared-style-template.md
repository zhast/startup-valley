# Shared generation brief — Startup Valley

Use this block for every new generated asset, then fill the specific asset
contract. Attach `dev/art-catalogue/style-reference-board.png` and the existing
target/reference asset. The board conveys style; the asset contract supplies
exact geometry. Record the prompt actually sent, including any changes.

```text
Style profile: startup-valley-cozy-pixel-v1
Camera profile: office-square-grid-v1

Create original Startup Valley game art matching the attached canonical
reference board. Aim for the warmth, readable everyday objects and expressive
characters of a Stardew-inspired life sim, using Startup Valley's own visual
identity and existing silhouettes.

Use a fixed elevated, screen-aligned orthographic camera. Floor axes remain
horizontal/vertical on screen; front edges are horizontal; height rises up
screen. No diamond-isometric yaw or per-object camera changes. One logical
floor tile is 32×32 native pixels. Characters use 48×80 cells and foot anchor
(24,72). Preserve the exact canvas, floor pivot and contact planes below.

Use crisp intentional pixel clusters and approximately one native pixel of
warm dark/material-dark contour. Match the board's pixel density, upper-left
light, restrained highlights and quiet texture. No blur, antialiased fringe,
sticker border, glossy 3D shading, photorealism or oversized fine detail.

Keep related palette families: warm oak/walnut, cream paper/fabric, charcoal
equipment and muted foliage. Character outfits and accent colors can differ;
their saturation, shading steps and contour weight must feel like the same
world. Do not force every object or person into one identical palette.

Prioritize a recognizable native-scale silhouette and clear purpose. Preserve
the existing character identity and costume. For animation, preserve stable
anchors and head size while making the requested pose changes unmistakable.
Draw each requested cardinal facing independently; never rotate or mirror the
finished raster. Keep furniture, characters, floor shadows and effects as
the separate layers requested below. Use real transparent background.

ASSET CONTRACT
Asset/family and purpose: [fill]
Existing target and references: [fill; list attached image roles]
Native canvas / frame grid: [fill]
Shared floor pivot or foot anchor: [fill]
Occupied floor cells / support plane: [fill]
Facing and visible front/back features: [fill]
Required layers and occlusion order: [fill]
Palette family / identity colors to preserve: [fill]
Allowed changes: [fill]
Pixels/geometry that must stay unchanged: [fill]
Delivery: [one sprite / registered layers / exact animation cells]
```

The output remains a candidate. Inspect it at native scale in the actual room,
retain its exact source/prompt/output identifier, and complete a hash-bound
runtime review. Prompt compliance is not evidence of visual correctness.
