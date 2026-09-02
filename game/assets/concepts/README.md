# Startup Valley concept sheets

These original RGBA sheets were generated with the built-in ImageGen tool on 2026-09-02. They establish a cozy top-down, 16-bit office-town direction without copying characters, buildings, tiles, UI, or palettes from an existing game.

- `office-town-environment-sheet.png`: terrain, interior architecture, office furniture, research props, plants, and town dressing.
- `office-town-characters-sheet.png`: original founder, Mina, and Theo direction/locomotion/desk pose studies.

Both files are 1536 × 1024 and contain real alpha transparency. They are source sheets, not runtime atlases: generated cell spacing and pose anchors are visually coherent but not mathematically uniform. Before wiring them into scenes, select the strongest assets, clean them to an exact pixel grid, assign deterministic rectangles and anchors, and validate nearest-neighbor import settings. The existing code-rendered game remains unchanged until that cleanup is approved.

## Final prompt set

Environment sheet:

> Create one original cohesive office-town pixel-art asset sheet containing modular grass, dirt, stone and wood tiles; interior wall pieces, a door and window; desks, chair, computers, research table, filing cabinet, package, mailbox, plants, tree, bench, streetlamp and notice board. Use a crisp hand-authored-looking 16-bit style, three-quarter overhead view, readable silhouettes, hard pixel edges, warm moss/walnut/slate/cream/terracotta palette, orthographic alignment, and a genuinely transparent background with isolated assets and clean gutters. No text, labels, logos, watermark, UI, overlap, gradients, anti-aliasing, or recognizable designs from another game.

Character sheet:

> Create three distinct original office-town pixel-art characters: a blue-jacket player founder, Mina in a moss-green cardigan with dark hair, and Theo in a rust-orange overshirt with curly hair. Show front, back, left and right idle views, two-frame directional walks, seated-at-desk and typing poses. Use consistent proportions and anchors, crisp hard-edged 16-bit pixel art, a coordinated muted palette, and a genuinely transparent background with isolated poses and clean gutters. No text, labels, logos, watermark, extra characters, overlap, gradients, anti-aliasing, or recognizable character designs or animations from another game.

The final extraction pass requested that only the atmospheric backdrop and glow be removed while preserving all sprites, positions, scale, palette, hard pixel edges, and canvas dimensions.
