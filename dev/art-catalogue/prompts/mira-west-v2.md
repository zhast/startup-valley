# Mina west atlas — targeted alpha extraction

Use case: background-extraction.

Make a transparent-background PNG cutout of these six existing character sprites. The white and gray checkerboard is currently PAINTED INTO the image; erase that background entirely to actual alpha=0. Keep only the six left-facing seated women. Return genuine RGBA image transparency, not another image of a checkerboard. Preserve all six character silhouettes, details, colors, positions and scale from the supplied v1 original. In particular keep their cream trousers opaque. Do not redraw or change poses; do not add anything. No matte, no halo, no checkerboard pattern, no floor or shadows.

Edit target: `game/assets/source/overnight-20260904/characters/mira-west-v1.png`.
