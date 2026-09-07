# Mina east atlas — targeted alpha extraction

Use case: background-extraction.
Input image is `game/assets/source/overnight-20260904/characters/mira-east-v1.png`, the exact edit target.

Change ONLY the background. Replace every painted white/gray checkerboard pixel with genuinely transparent alpha. Preserve the exact six right-facing seated characters, their identity, silhouettes, pixel colors, clothing, hand poses, hair, body scale, canvas and positions. Do not redraw, recenter, rescale, shift or modify any character. Preserve cream trousers and skin; remove checkerboard from transparent gaps and around all hair/hand/shoe edges without a white/gray halo. Actual RGBA transparency is required, not a checkerboard illustration. No new objects, labels, text, borders, floor, chair, desk or shadow.
