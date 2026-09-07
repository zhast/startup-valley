# Overnight directional furniture and art-library goal

## Copyable goal prompt

`/goal` Read and execute this objective in `/Users/zhast/GitHub/startup-valley`. Read `AGENTS.md`, `dev/FURNITURE_DIRECTION_AUDIT.md`, `dev/art-catalogue/README.md`, `dev/art-catalogue/furniture.json`, and `dev/art-catalogue/RUN_LOG.md` before continuing. Use the ImageGen skill for raster generation. Preserve existing uncommitted work.

Make Startup Valley's furniture, characters, architecture and UI feel like one intentional cozy-tech game. First fix the directional furniture foundation, then produce a large, reviewed, reusable art library. Do not stop after writing a plan or producing concept sheets: implement, generate, inspect at native game size, test, catalogue, and iterate within the bounded overnight window.

### Time and spending boundary

- This run began **2026-09-04 05:43:14 UTC** (September 3, 10:43:14 PM PDT). The hard stop is **2026-09-04 17:43:14 UTC** (September 4, 10:43:14 AM PDT). Never reset or extend this deadline after a continuation, restart, or compaction.
- Work productively until that deadline or the available account allowance prevents further work, whichever comes first. Do not deliberately waste tokens, repeat equivalent generations, or invent busywork to exhaust a balance. An actually exhausted capability may leave useful code/review work available; record which limit was reached and do not bypass it.
- Use built-in ImageGen with the existing account. No separate Image API billing, OpenRouter jobs, top-ups, purchases, reset-credit redemption, new subscriptions, alternate accounts, or quota circumvention. Do not change models simply to consume credit.
- Check UTC before each substantial batch. Begin verification and closeout no later than 17:13:14 UTC; do not start new image calls after 17:33:14 UTC. If an operation is outstanding at the deadline, preserve its handle/results and report it honestly; do not start more work.
- Keep a durable run ledger and an expiring same-thread scheduled continuation. Never duplicate an outstanding image request or replay an already completed batch. Scheduler ticks are recovery opportunities, not permission for parallel copies of this task.

### P0 — Establish the fixed-camera, four-facing contract

1. Audit active assets separately from retired masters and concept images. Record actual source and runtime paths, native dimensions, alpha, anchor, footprint, draw layers, scale, lighting, perspective, and N/E/S/W availability. Use current in-game screenshots as evidence.
2. Preserve the approved modular office architecture and square 32-pixel logical grid. The camera does not rotate: screen X/Y remain the floor axes; furniture uses screen-aligned orthographic/oblique overhead drawings, not diamond-isometric yaw or perspective vanishing points. Compare top-plane depth and vertical rise using a simple calibration desk and the 48×80 character, not an invented numeric camera angle.
3. Define `facing` unambiguously as the seated worker's gaze toward the worksurface for workstations. Existing south desks have a north seat; preserve that legacy behavior. Store the service/interaction side separately for cabinets and shared props. Draw four true views; never rotate a rendered bitmap by 90 degrees or mirror asymmetric tools and baked light to fake a view.
4. Resolve explicit facing-specific art, local occupied cells, clearance, interaction/work cells, seat anchor, sprite/ground origin, visual bounds, collision, hit test, and layer/depth behavior. Logical cell rotation is allowed; camera-space raster rotation is not. Non-square floor footprints exchange axes in E/W views, but each image has its own checked elevation and anchor.
5. Preserve backward-compatible south-only profiles. Do not expose a facing as selectable or runtime-ready until that facing's art AND geometry AND actor pose have passed review. A schema field listing four directions is not four-direction support.
6. Build a developer rotation showroom and deterministic tests for all valid directions, against each wall, in corners, beside other furniture, with characters walking behind/in front and seated. Fix bootstrap paths that overwrite facing, directionless work-pose selection, unusable seat-depth metadata, and editor previews that disagree with the game.

### P0/P1 — Generate and integrate useful furniture

1. Start with one calibrated, uncluttered workstation base and separate chair in four directions. Keep rear/front occlusion layers registered to a shared full canvas; never trim them independently. Keep characters and role props separate from furniture.
2. Rebuild or correct the seven active families: desks, coffee station, collaboration furniture, artifact archive, research table, approval console, prototype bench. Keep existing usable art until replacements actually pass in the room. Prioritize camera mismatch, actor clipping, inaccessible work points and wall overlap over volume.
3. Build profession-specific toolkits on compatible base surfaces: founder/planning, Mina/product/research, Theo/growth/ads, lawyer, creative/designer, engineer, finance and customer support. Lawyer decor should read as document review and secure files; creative decor as pen display, swatches, camera and design tools. These are visual sets, not authorization to implement new employee backends or real legal/advertising services.
4. Maintain a catalogue of approximately 35–50 useful families, each with N/E/S/W slots, dependencies, dimensions, anchors, placement rules, role, priority, source, prompt, generation/review state, runtime path and screenshot evidence. A planned slot must say missing, not imply an image exists. Prefer modular base + toolkit combinations over repeatedly generating the whole desk.
5. Use genuine alpha where required. Inspect for opaque checkerboards, matte halos, stray islands, smoothing, clipped feet/legs, warped tabletops and inconsistent light. Retain source masters non-destructively and use the project's deterministic export workflow for crops, registration and native pixel normalization; all semantic image corrections go through ImageGen unless the user explicitly permits hand editing. Never use arbitrary runtime downscaling.

### P1/P2 — Expand only after the directional foundation is demonstrated

Use remaining time for the highest-value missing assets found during repeated in-game audits:

- Directional seated/typing/research/waiting/delivery character poses; original specialist character designs and portraits in staged concept collections.
- Readable four-frame status and ambient overlays, shadows, chair motion and six-frame furniture arrival effects. No fake job progress or decorative animation implying work happened.
- Shared furniture: meeting tables/chairs, bookshelves, storage, filing, couches, lamps, plants, printers, whiteboards, acoustic screens and office equipment, each with useful directional variants.
- Alternative compatible office materials and modular architecture: warm startup loft, bright studio, quiet legal office, workshop and evening lighting. Keep common grid, doorway, wall-height and window contracts; do not bake an entire room behind movable props.
- Optional UI material/style explorations as isolated review sheets and reusable components. Preserve the approved notebook silhouette, typography C, functional live UI and Whop color roles. No silent broad skin replacement, baked body text, giant screenshot-hotspot UI, or extra tiny unreadable labels.

Produce a small batch, inspect it, record problems, fix the most consequential mismatch, then continue. Do not generate fifty inconsistent objects before testing the first. Limit unsuccessful targeted retries for one asset to three, then mark the blocker and move to another useful catalogue item.

### Quality and acceptance

- Every runtime-ready directional asset must be visually reviewed at native size in the actual room and at enlarged nearest-neighbor scale; show all four views together, not only an attractive source render.
- No wall/furniture image overlap outside explicitly permitted actor occlusion; no blocked interaction/seat cell; no actor clipping or seat hopping; no unregistered front/back layer seam; no rotation-induced collision or click-through errors.
- Palette: warm existing woods/parchment and restrained Whop Vermilion `#FA4616`, Off-White `#F1F1F1`, Charcoal `#151515`, Indigo `#354B98`, Cerulean `#6196C1`, Chartreuse `#C1FA81`, Dust `#B6B5B0`. Respect existing art contrast; do not recolor every prop orange.
- Score pixel coherence, perspective, silhouette/readability, layering/anchors, direction consistency and placement from 0–3. Runtime acceptance requires every category ≥2 and mean ≥2.5; functional placement/collision tests must all pass. Concept-only work is clearly labeled.
- Run Godot import, project validation, gameplay tests, modular office/layout/migration/editor tests, directional tests, affected UI tests and static/motion audits with worker disabled. Run the worker suite if relevant shared contracts change; avoid such changes in this art-focused goal.
- Inspect 1280×720 plus existing aspect-preserving scale cases for clipping, shimmer, stale labels, overlaps and UI/world hit testing. Preserve the current playable loop and real-worker boundary.

### Deliverables and handoff

- `dev/FURNITURE_DIRECTION_AUDIT.md`: evidence-backed defects, priorities, remediation and final disposition.
- `dev/art-catalogue/furniture.json` and `README.md`: truthful four-facing catalogue, reusable recipes, acceptance/status definitions and generation queue.
- `dev/art-catalogue/RUN_LOG.md`: UTC checkpoints, completed/in-flight work, generation provenance, failed attempts, remaining priorities, actual test results and quota/deadline outcome.
- Original masters under `game/assets/source/overnight-20260904/`; only accepted exports under versioned runtime paths. Preserve originals and source attribution/licenses.
- A browsable contact-sheet/gallery with N/E/S/W coverage and native in-game examples; include rejected/concept status where useful, not just the best source images.
- Tested implementation of directional furniture support where the art/pose prerequisites have been met. Missing directions remain unavailable, never silently substituted.
- A morning summary of accepted assets versus concepts/missing slots, fixed bugs, tests, screenshots, remaining gaps, and exact saved paths. Do not claim the entire account credit was spent without evidence.

Keep work local. Do not commit, push, publish, modify personal save data, touch credentials, add production dependencies or broaden the worker architecture. Do not mark the goal complete merely because a time/quota limit was reached: completion requires the agreed accepted deliverables; otherwise hand off the exact partial state and leave the remaining work explicit.
