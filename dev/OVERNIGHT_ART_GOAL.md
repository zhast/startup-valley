# Directional furniture and art-library completion goal

**User revision, September 4, 2026:** the hard deadline is removed. Finish the
work already started. This completion-driven instruction supersedes the old
12-hour window, cutoff times and deadline-blocked status. The original objective
is preserved as history in `dev/art-catalogue/OVERNIGHT_ART_GOAL_20260904_ARCHIVE.md`.
Historical deadlines in reports and old goal summaries are not current stop rules.

## Copyable goal prompt

`/goal` Read and execute this objective in `/Users/zhast/GitHub/startup-valley`. Read `AGENTS.md`, `dev/FURNITURE_DIRECTION_AUDIT.md`, `dev/art-catalogue/README.md`, `dev/art-catalogue/furniture.json`, and `dev/art-catalogue/RUN_LOG.md` before continuing. Use the ImageGen skill for raster generation. Preserve existing uncommitted work.

Make Startup Valley's furniture, characters, architecture and UI feel like one intentional cozy-tech game. First finish the directional furniture foundation and production integration, then complete the reviewed reusable art library already catalogued. Do not stop after writing a plan, producing concept sheets or passing a development-only fixture: implement, generate where necessary, inspect at native game size, test, catalogue, integrate and verify the requested finished state.

### Completion and spending boundary

- There is **no hard deadline, 12-hour cap, arbitrary duration target or instruction to exhaust credit**. Continue across turns until the completion criteria below are actually proved, the user stops the work, or a genuine external blocker prevents further authorized progress. Do not stop because the former overnight deadline has passed.
- Use allowance efficiently for improvements to the requested final state. Do not deliberately waste tokens, repeat equivalent generations or invent busywork. A tool-specific limit may leave useful implementation/review work available; record which capability is blocked and continue safe independent work without bypassing limits.
- Use built-in ImageGen with the existing account. No separate Image API billing, OpenRouter jobs, top-ups, purchases, reset-credit redemption, new subscriptions, alternate accounts, or quota circumvention. Do not change models simply to consume credit.
- Verify incrementally after every material change; final verification is a completion gate, not a scheduled cutoff. Preserve outstanding handles/results during interruption and resume them rather than duplicating work.
- Keep a durable run ledger with current owners, exact source versions, tests, failures and next actions. Use the active goal's continuation mechanism; do not recreate the expired overnight heartbeat or add duplicate recurring work. Read this revised objective before obeying older ledger instructions.

### Resume from the actual unfinished state

1. Read the current revision at the top of `dev/art-catalogue/MORNING_HANDOFF.md` and `NEXT_DESK_ACCEPTANCE.md`. Preserve dated evidence and all existing edits. The resumed 17:55:31 UTC catalogue checkpoint reconciles all 118 original PNGs; do not revert it to the historical 117-source freeze. Index later reviews with their own exact checkpoint and without inventing approvals.
2. Finish the complete-South workstation acceptance begun in `complete_south_workstation_fixture.gd`, `capture_complete_south_workstation.gd` and `test_complete_south_workstation.gd`. Read `dev/art-catalogue/COMPLETE_SOUTH_WORKSTATION_REVIEW.md`: its resumed capture exercises both employees through actual sit, type, failure, pose restoration and leave, but visually fails at 2.17/3 because a standing torso intersects the chair after failure and during leave. Resolve that real state/geometry defect and the separate redundant dev Type-at-seat route before approval; preserve the exact before evidence. Keep functional test success separate from visual acceptance; fix demonstrated defects rather than weakening assertions.
3. Complete South, West, East and North workstation acceptance in that order. Promote reviewed assemblies through an explicit production capability path; do not bypass calibration-owner or art/geometry/pose gates by flipping readiness flags.
4. Continue through the six remaining original active families and the role/decor library. The archive already has four approved production views: retain them and test affected regressions, not regenerate them without a demonstrated defect.
5. Work toward the existing 42-family catalogue as a finite backlog. Do not keep adding unrelated families or alternate whole-room concepts to postpone finishing the requested rotations, contacts, usable placement and coherent presentation.

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

After completing the directional foundation, fill the highest-value missing assets identified by the existing catalogue and repeated in-game audits:

- Directional seated/typing/research/waiting/delivery character poses; original specialist character designs and portraits in staged concept collections.
- Readable four-frame status and ambient overlays, shadows, chair motion and six-frame furniture arrival effects. No fake job progress or decorative animation implying work happened.
- Shared furniture: meeting tables/chairs, bookshelves, storage, filing, couches, lamps, plants, printers, whiteboards, acoustic screens and office equipment, each with useful directional variants.
- Alternative compatible office materials and modular architecture: warm startup loft, bright studio, quiet legal office, workshop and evening lighting. Keep common grid, doorway, wall-height and window contracts; do not bake an entire room behind movable props.
- Optional UI material/style explorations as isolated review sheets and reusable components. Preserve the approved notebook silhouette, typography C, functional live UI and Whop color roles. No silent broad skin replacement, baked body text, giant screenshot-hotspot UI, or extra tiny unreadable labels.

Produce a small batch, inspect it, record problems, fix the most consequential mismatch, then continue. Do not generate fifty inconsistent objects before testing the first. Preserve the existing limit of three unsuccessful targeted retries after an initial request; do not rename exhausted requests to reset their counters. Diagnose exhausted methods, reuse valid components and consider a materially different lawful implementation approach with explicit provenance. If a necessary raster correction genuinely requires fresh authority, ask for that specific change while continuing independent work. An exhausted attempt or a staged prototype is not completed furniture.

### Definition of done

- The seven active furniture families have usable, reviewed N/E/S/W art and geometry in the normal game, with placement/rotation/Undo, walls, corners, approach cells, occupied-actor rejection, collision, depth sorting and existing actions working. The archive's prior acceptance is preserved; the six unfinished families do not inherit it.
- Founder, Mina and Theo have coherent movement and appropriate work/state presentation for supported directions. Both employees pass full workstation contact and sit/stand/state transitions, not just isolated endpoint frames. Fancy animation is optional; clipping, floating, detached shadows or implausible contact are not.
- Complete the in-scope 42-family furniture/toolkit catalogue with actual reviewed native directional deliverables. Symmetric physical objects may explicitly reuse equivalent views, but asymmetric lighting/tools may not be mirrored or bitmap-rotated to fake missing art. Future-role library assets need not invent new hires or backend services; their host placement and four-facing appearance must still be demonstrated. Planned/blocked/cleanup rows are unfinished, not a completion claim.
- Profession sets are visibly distinguishable on compatible bases: founder/planning, product/research, growth/ads, legal, creative, engineering, finance and support. Keep devices, tools, characters and furniture separately reusable. Validate any portrait adaptation at the real rail dimensions before integration.
- Existing office architecture, typography C, notebook UI and Whop color roles remain coherent. Correct actual asset/integration glitches and explicitly review optional material/UI studies; do not replace the approved game with concept backdrops, tiny baked labels or broad unchosen skins.
- The catalogue, source index, gallery and evidence agree on actual files, counts, status, dimensions, anchors, provenance, failed attempts and runtime paths. No completed source remains unindexed. Retain failed masters as evidence, not as usable deliverables.
- All applicable acceptance checks below pass on the final implementation. Final stills, motion and real-input evidence cover the actual integrated game and accessible catalogue/viewers; no dev-only pass is presented as production readiness. Report residual nonblocking limits honestly.
- Only mark the goal complete after requirement-by-requirement verification. If a required item remains missing or blocked, preserve the full scope and report that exact blocker rather than redefining success around finished subsets.

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
- `dev/art-catalogue/RUN_LOG.md`: UTC checkpoints, completed/in-flight work, generation provenance, failed attempts, remaining priorities, actual test results and any genuine blocking condition. Historical deadline outcomes remain history only.
- Original masters under `game/assets/source/overnight-20260904/`; only accepted exports under versioned runtime paths. Preserve originals and source attribution/licenses.
- A browsable contact-sheet/gallery with N/E/S/W coverage and native in-game examples; include rejected/concept status where useful, not just the best source images.
- Tested implementation of directional furniture support where the art/pose prerequisites have been met. Missing directions remain unavailable, never silently substituted.
- A final summary of accepted assets versus optional concepts, fixed bugs, tests, screenshots, any remaining nonblocking limitations, and exact saved paths. Do not claim credit consumption or completion without evidence.

Keep work local. Do not commit, push, publish, modify personal save data, touch credentials, add production dependencies or broaden the worker architecture. Do not mark the goal complete merely because allowance runs out or a turn ends: completion requires the agreed accepted deliverables. The previous hard deadline no longer applies.
