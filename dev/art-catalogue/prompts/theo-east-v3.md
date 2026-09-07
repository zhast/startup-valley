# Theo east atlas — final targeted alpha-extraction retry

Use case: background-extraction.
Edit target: `game/assets/source/overnight-20260904/characters/theo-east-v1.png`. The original is reused because v2 failed to return alpha; do not introduce another generation of failed cleanup.

Make a transparent-background PNG cutout of the six existing character sprites. The white/gray checkerboard is currently PAINTED INTO the image; erase that background entirely to actual alpha=0. Keep only the six right-facing seated men. Return genuine RGBA image transparency, not another image of a checkerboard. Preserve all six character silhouettes, details, colors, positions and scale from this original. In particular keep the white shirts and cream sneakers opaque, preserve olive trousers and low typing hands. Do not redraw, resize, recenter, change poses or add anything. No matte, halo, checkerboard pattern, floor, cast shadow, text or grid. Output actual transparent pixels outside all characters.
