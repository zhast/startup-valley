# Theo north atlas — targeted alpha extraction (retry 1)

Use case: background-extraction.
Input image: `game/assets/source/overnight-20260904/characters/theo-north-v1.png`, the exact edit target.

Change ONLY the background: remove every painted white/gray checkerboard pixel and replace it with genuinely transparent alpha. Preserve all SIX characters, their exact silhouettes, pixel colors, curly brown hair, orange jackets, olive trousers, cream/white sneakers, hand details, frame positions, scale and 2172×724 canvas. Do not move, recenter, resize or redraw the characters; do not change their poses. Remove checkerboard between limbs and around edges too. Output an actual transparent RGBA PNG, with no white/gray matte, halo or checkerboard graphic. Preserve the white sneakers and skin; only the background becomes transparent. No extra objects, text, arrows, labels, cast shadows, grid lines or decorations.
