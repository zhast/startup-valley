# Mina north atlas — targeted alpha extraction

Use case: background-extraction.
Input image: `game/assets/source/overnight-20260904/characters/mira-north-v1.png`, the exact edit target.

Change ONLY the background of this image: remove every painted white/gray checkerboard pixel and replace it with genuinely transparent alpha. Preserve all SIX characters, their exact silhouettes, pixel colors, hair/hand details, frame positions, scale and 2172×724 canvas. Do not move, recenter, resize or redraw the characters; do not change poses. Remove the checkerboard between fingers/limbs and around edges as well. Output an actual transparent RGBA PNG, with no white/gray matte, halo or checkerboard graphic. Preserve cream trousers and skin; only the background becomes transparent. No extra objects, text, arrows, labels, shadows, grid lines or decorations.
