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

## Tech-town direction

The 2026-09-02 tech-town pass uses the supplied city image only as a mood reference for optimistic density, drones, and rooftop infrastructure. Its text, company marks, crypto imagery, buildings, and composition were explicitly excluded.

- `startup-valley-tech-town-key-art.png`: the preferred visual target—a walkable garden campus with glass-and-redwood offices, a maker garage, visible servers, drones, solar roofs, parcel lockers, scooters, EV charging, and community plots.
- `startup-valley-main-office-key-art.png`: the primary game-space target—a compact cutaway office organized around assignment, employee work, research, approvals, artifact review, and social downtime.
- `startup-valley-tech-props-concept-sheet.png`: a prop-design reference for desks, networking, fabrication, drone logistics, mobility, coffee, and collaboration spaces.
- `startup-valley-tech-characters-concept-sheet.png`: updated founder, Mina, and Theo studies with contemporary startup clothing, bags, headphones, laptops, and whiteboard poses.

The key art is an opaque environment painting by design. The two tech sheets are also RGB concept references: ImageGen baked its transparency preview grid into the pixels despite two background-extraction passes. Do not slice them directly into runtime scenes. Redraw or manually extract approved items onto an exact grid before import. The earlier `office-town-*-sheet.png` files remain the clean-alpha source sheets.

### Tech-town prompt set

Town key art:

> Create an original cozy Silicon Valley startup town as a readable 16-bit pixel-art game environment. Use a three-quarter overhead view with a walkable plaza, startup garage, low-rise glass-and-redwood office campus, maker lab, visible server room, solar roofs, antennas, delivery drones, EV charging, scooters, parcel lockers, coffee cart, community gardens, benches, trees, and fiber utility boxes. Balance dense technology detail with abundant greenery and warm gathering spaces in a sunny Bay Area palette of eucalyptus, moss, redwood, warm concrete, cream, teal glass, cyan, and amber. Use the supplied city image only for optimistic tech-city mood and the existing environment sheet for palette and rendering language. Make every design original; include no text, logos, brands, trademarks, crypto symbols, UI, watermark, copied buildings or characters, photorealism, smooth 3D rendering, or diamond-isometric layout.

Tech props:

> Create an original pixel-art concept sheet containing a laptop standing desk, dual-monitor desk, ergonomic chair, server rack, network cabinet, abstract wall display, maker bench, compact fabrication machine, drone charging pad and delivery drones, smart parcel locker, solar modules, rooftop antenna, EV charger, scooter rack, fiber junction box, espresso bar, beanbag nook, glass meeting pod, and succulent. Use crisp hard-edged 16-bit rendering, a three-quarter overhead view, generous gutters, and the established moss, redwood, slate, cream, teal, cyan, and amber palette. Use the supplied city image only for technology mood and the existing environment sheet for visual language. Include no text, readable writing, logos, brands, trademarks, watermark, overlap, or copied designs.

Tech characters:

> Update the three original recurring characters with subtle contemporary Bay Area startup cues while preserving their identities and compact pixel-art proportions: the founder in a navy technical jacket with messenger bag, Mina in a moss cardigan and cream trousers with laptop sleeve and headphones, and Theo in a rust overshirt and olive trousers with cross-body tech bag and smartwatch. Show directional idles, two-frame walks, laptop work, typing, and whiteboard thinking poses in aligned rows with generous gutters. Use the existing character sheet for identity and rendering language and the supplied city image only for technology-culture mood. Include no text, logos, brands, trademarks, watermark, badges with writing, or recognizable copied characters or animations.

Main office:

> Design the main game location as one compact, welcoming Silicon Valley startup office—the indoor equivalent of a cozy farming game's homestead. Use a single rectangular 26-by-18 logical-tile floor with cutaway walls, three personalized desks around an open center, a southern assignment station, central collaboration space, western meeting room, kitchen and lounge, northern windows and planters, and eastern research lab, server room, approval console, artifact archive, maker bench, and drone dock. Keep one obvious circulation loop, two-tile-wide paths, distinct landmarks, short travel from the center, and upgrade room at the perimeter. Render the entire office in crisp original 16-bit three-quarter overhead pixel art using eucalyptus, moss, redwood, walnut, warm concrete, cream, slate, teal glass, cyan, and amber. Include exactly three small recurring workers for scale. Use the approved garden-campus image for palette and architecture, the tech-prop sheet for object vocabulary, and the original character sheet for silhouettes. Include no text, logos, brands, crypto imagery, UI, watermark, copied designs, cubicle farm, sterile laboratory, excessive neon, photorealism, or diamond-isometric layout.
