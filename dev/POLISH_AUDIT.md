# Startup Valley visual polish audit

This is the repeatable visual and motion review for the 1280 × 720 founder,
Mina, and Theo vertical slice. It complements `VISUAL_REVIEW.md`: the existing
review protects static layouts, while this audit records transitions, movement,
depth, asset sampling, and state readability.

The audit is deterministic, disables the live worker, spends no model tokens,
and writes all generated evidence under the ignored
`game/tests/output/polish-audit/` directory.

## Runbook

Use the real renderer rather than `--headless` for the capture commands:

```sh
godot --fixed-fps 30 \
  --write-movie res://tests/output/polish-audit/world.avi \
  --path game \
  --script res://tools/capture_polish_audit.gd -- --suite=world

godot --fixed-fps 30 \
  --write-movie res://tests/output/polish-audit/ui.avi \
  --path game \
  --script res://tools/capture_polish_audit.gd -- --suite=ui

godot --headless --path game \
  --script res://tools/validate_polish_audit.gd
```

Each suite writes a movie, six contact sheets, eighteen full-size keyframes,
and a manifest. The root `asset-inventory.json` records source dimensions,
alpha/import facts, live scale, displayed dimensions, and known systemic flags.
The validator rejects missing movies, scenarios, keyframes, contact sheets,
unexpected dimensions, invalid frame ranges, identical sampled frames, runtime
scaling, opaque cutouts, lossy imports, missing font licenses, empty atlas cells,
and static animation groups. Rebuild the normalized runtime art before a capture
with `dev/tools/build_polish_assets.sh`.

## Rubric

Every scenario receives six 0–3 scores:

- **Pixel:** palette, edge treatment, pixel density, and freedom from scaling
  shimmer.
- **Motion:** whether the pose and loop communicate the action without a label.
- **Continuity:** starts, stops, state changes, and UI transitions feel connected.
- **Layering:** anchors, shadows, occlusion, and foreground/background ordering.
- **Text:** hierarchy, wrapping, overflow, and font fit.
- **Feedback:** the player can see that input or a real worker event was accepted.

`0` is missing or contradictory, `1` is functional but conspicuously unfinished,
`2` is coherent with visible polish debt, and `3` is vertical-slice quality. A
scenario passes only when every category is at least 2 and its mean is at least
2.5.

## Baseline result

The baseline produces a 45.7-second world movie and a 16.3-second UI movie at
30 FPS. All twelve scenarios, 36 full-size keyframes, 12 contact sheets, and
both manifests validate. Only the team-drawer scenario currently meets the
polished threshold.

| Scenario | Pixel | Motion | Continuity | Layering | Text | Feedback | Mean | Result |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| World · founder locomotion | 2 | 1 | 1 | 2 | 2 | 1 | 1.50 | Fail |
| World · employee idle cycle | 2 | 1 | 1 | 1 | 2 | 1 | 1.33 | Fail |
| World · job state cycle | 2 | 1 | 1 | 1 | 2 | 2 | 1.50 | Fail |
| World · schedule cycle | 2 | 1 | 1 | 1 | 2 | 2 | 1.50 | Fail |
| World · depth and occlusion | 2 | 1 | 1 | 2 | 2 | 1 | 1.50 | Fail |
| World · office growth | 2 | 0 | 0 | 2 | 2 | 1 | 1.17 | Fail |
| UI · team drawer controls | 3 | 2 | 2 | 3 | 3 | 2 | 2.50 | Pass |
| UI · chat and work order | 3 | 1 | 1 | 3 | 2 | 2 | 2.00 | Fail |
| UI · work controls | 3 | 1 | 1 | 3 | 2 | 2 | 2.00 | Fail |
| UI · Activity and approval | 3 | 1 | 1 | 3 | 2 | 3 | 2.17 | Fail |
| UI · delivery, Studio, reader | 3 | 0 | 1 | 3 | 2 | 3 | 2.00 | Fail |
| UI · queued, errors, overflow | 3 | 0 | 1 | 3 | 2 | 2 | 1.83 | Fail |

World mean: **1.42**. UI mean: **2.08**. Combined mean: **1.75**.

## Remediation result

The 2026-09-02 rerun passes all twelve scenarios. Every individual category is
at least 2, every scenario mean is at least 2.5, and the combined mean is
**2.76**. The world suite is **2.61** and the UI suite is **2.92**. The final
recordings contain 1,129 world frames (37.63 seconds) and 488 UI frames (16.27
seconds), both at fixed 30 FPS.

| Scenario | Pixel | Motion | Continuity | Layering | Text | Feedback | Mean | Result |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| World · founder locomotion | 3 | 3 | 3 | 2 | 2 | 3 | 2.67 | Pass |
| World · employee idle cycle | 3 | 3 | 3 | 3 | 2 | 2 | 2.67 | Pass |
| World · job state cycle | 3 | 3 | 3 | 3 | 2 | 3 | 2.83 | Pass |
| World · schedule cycle | 3 | 3 | 2 | 3 | 2 | 2 | 2.50 | Pass |
| World · depth and occlusion | 3 | 3 | 2 | 3 | 2 | 2 | 2.50 | Pass |
| World · office growth | 3 | 2 | 2 | 3 | 2 | 3 | 2.50 | Pass |
| UI · team drawer controls | 3 | 3 | 3 | 3 | 3 | 3 | 3.00 | Pass |
| UI · chat and work order | 3 | 3 | 3 | 3 | 3 | 3 | 3.00 | Pass |
| UI · work controls | 3 | 2 | 3 | 3 | 3 | 3 | 2.83 | Pass |
| UI · Activity and approval | 3 | 3 | 3 | 3 | 3 | 3 | 3.00 | Pass |
| UI · delivery, Studio, reader | 3 | 3 | 3 | 3 | 3 | 3 | 3.00 | Pass |
| UI · queued, errors, overflow | 3 | 2 | 2 | 3 | 3 | 3 | 2.67 | Pass |

Across all scenarios, the category means are: Pixel **3.00**, Motion **2.75**,
Continuity **2.67**, Layering **2.92**, Text **2.50**, and Feedback **2.75**.
The lower 2s are deliberate restraint rather than missing behavior: schedule
and growth transitions reuse the established locomotion language, short world
labels prioritize brevity, and error/control motion avoids distracting loops.

Evidence is written to `game/tests/output/polish-audit/`. The final inventory
reports zero known flags, all three live characters as 48 × 80 cells at scale
1, every inspected modular prop at scale 1, and both bundled font licenses.

## Findings

| ID | Priority | Finding and evidence | Remediation | Disposition |
| --- | --- | --- | --- | --- |
| POL-01 | P0 | Founder, Mina, and Theo use one front-facing concept crop for every direction. Horizontal movement mirrors it; vertical movement does not change pose. Evidence: `world/founder-locomotion-contact-sheet.png`. | Add aligned native locomotion atlases and an animation-state mapper. | Generate new art |
| POL-02 | P0 | Sitting, typing, thinking, research, approval, delivery, lunch, and failure use the same standing portrait plus a 1–2 px bob. State is legible only from movement and labels. Evidence: `world/employee-idle-cycle-contact-sheet.png` and `world/job-state-cycle-contact-sheet.png`. | Add employee work-pose atlases and bind every `WorkState` to a deliberate loop. | Generate new art |
| POL-03 | P0 | All nine modular props are 1254–1536 px generation canvases displayed at scales from 0.085 to 0.112. Most resolve to fractional displayed dimensions, which causes uneven pixel density and movement shimmer. Evidence: `asset-inventory.json`. | Crop and nearest-neighbor re-export the approved props at their authored runtime size; render them at scale 1. | Normalize/re-export existing art |
| POL-04 | P0 | A standing character is placed behind a one-piece desk to imply sitting. The desk and research bench cannot independently occlude torso, hands, chair, and monitor. Evidence: idle and job-state captures. | Create matched rear/front layers with a shared ground anchor; place the seated actor between them. | Generate new art |
| POL-05 | P1 | Real work states have static text/icon feedback but no world-space motion cue. Thinking, tool use, approval, completion, and failure look alike at a glance. | Add one small state-VFX atlas driven only by real worker events. | Generate new art |
| POL-06 | P1 | Coffee, monitors, research equipment, prototype bench, approval console, and archive are completely static. The mature office gains density but not life. Evidence: office-growth movie. | Add optional transparent ambient overlays; retain the approved base props. | Generate new art |
| POL-07 | P1 | Characters use smooth vector circles for shadows, which clash with the surrounding pixel art and do not adapt to seated/walking poses. | Replace with three native pixel shadow footprints. | Generate new art |
| POL-08 | P1 | World labels and UI controls depend on `ThemeDB.fallback_font`; the exact typeface can vary by host and does not carry the pixel-game voice. Body text remains readable but visually generic. | Bundle Tiny5 for display/status and Nunito Sans for long-form chat and documents, with licenses. | Reuse existing art |
| POL-09 | P1 | The drawer has a good 160 ms transition, but tab pages, new chat messages, waiting state, approval cards, spend changes, delivery memo, Studio changes, and artifact modal appear instantly. Evidence: UI movie. | Add short restrained tweens, an animated waiting ellipsis, and one-pixel button depression using existing assets. | Code-only animation/layout fix |
| POL-10 | P1 | Name and status plaques are always visible and are wider than the characters. Around desks they obscure furniture and make the office feel like a debug view. | Keep nameplates on proximity/focus and statuses on change, attention, or active work; fade after a short hold. | Code-only animation/layout fix |
| POL-11 | P2 | Furniture appears instantly when hire count changes. This is acceptable before hiring exists but reads as a pop once office growth becomes playable. | Add a short arrival effect when a newly unlocked prop is instantiated. | Generate new art |

## Remediation status

| Finding | Resolution | Final evidence |
| --- | --- | --- |
| POL-01 | Resolved with separate native Founder, Mina, and Theo four-direction locomotion atlases. | `world/founder-locomotion-contact-sheet.png`; atlas validation |
| POL-02 | Resolved with Mina and Theo seated, typing, research, approval, and delivery poses selected by `WorkState`. | `world/employee-idle-cycle-contact-sheet.png`; `world/job-state-cycle-contact-sheet.png` |
| POL-03 | Resolved by reproducibly normalizing every modular prop to a native RGBA runtime canvas. | `asset-inventory.json`; zero scale/import flags |
| POL-04 | Resolved with separate rear/front workstation and research layers and an actor work point between their Z values. | `world/depth-and-occlusion-contact-sheet.png`; gameplay test |
| POL-05 | Resolved with six four-frame effects selected only by real worker events. | `world/job-state-cycle-contact-sheet.png`; world movie |
| POL-06 | Resolved with restrained independent monitor, coffee, research, prototype, and archive overlays. | `world/office-growth-contact-sheet.png`; world movie |
| POL-07 | Resolved with native standing, walking, and seated pixel shadows. | founder and employee motion scenarios |
| POL-08 | Resolved with bundled Tiny5 display and Nunito Sans body fonts plus OFL licenses. | static UI captures; `asset-inventory.json` |
| POL-09 | Resolved with 70–180 ms button, tab, message, waiting, spend, card, notification, and modal motion. | all six UI scenarios |
| POL-10 | Resolved with labels limited to proximity, state-change holds, and approval; speech suppresses the redundant plaque. | employee idle and job-state movies |
| POL-11 | Resolved with a six-frame dust/spark arrival effect for newly unlocked furniture. | `world/office-growth-contact-sheet.png`; world movie |

The current notebook/sidebar textures do **not** justify another broad UI asset
batch. Their pixel coherence is the strongest part of the build. The next UI
pass should animate and stage the assets already present.

## Asset briefs and ImageGen prompts

All generated sheets must be original Startup Valley artwork. Use the existing
character, office, and UI concept sheets only for recurring identity, palette,
pixel density, lighting, and oblique-orthographic projection. ImageGen output is
a source master, never a shippable atlas: remove stray pixels, verify alpha,
normalize anchors, cut the exact grid, and resize only with nearest-neighbor
sampling.

### A. Character locomotion atlases — P0

- Deliver three separate transparent PNGs: Founder, Mina, and Theo.
- Exact output per character: 288 × 320 px; 6 columns × 4 rows; 48 × 80 px cells.
- Rows: front, back, left, right.
- Columns 0–1: two-frame breathing idle. Columns 2–5: four-frame walk.
- Every foot-contact anchor is `(24, 72)` within its cell. Keep the bottom eight
  pixels clear. Character opaque bounds must not cross cell gutters.
- No shadow, furniture, held props, text, glow, checkerboard, or backdrop.

Prompt, run once for each named character:

> Using the attached Startup Valley character identity sheet as visual reference, create one production-ready locomotion sprite sheet for **[Founder / Mina / Theo]** in original cozy contemporary startup pixel art. Output a truly transparent 288 by 320 pixel PNG arranged as an exact 6-column by 4-row grid of 48 by 80 pixel cells. Rows are front, back, left, right. In every row, cells 1–2 are a subtle two-frame breathing idle and cells 3–6 are a seamless four-frame walk cycle with clear alternating foot contact. Preserve the character’s established face, hair, skin tone, clothing colors, bag, and proportions. Align every frame to the identical bottom-center ground anchor at x 24, y 72, with the bottom 8 pixels empty. Use crisp hard pixel edges, consistent upper-left lighting, and Startup Valley’s warm cozy-tech palette. No background, checkerboard, floor, shadow, furniture, props, text, labels, logos, glow, antialiasing, blur, extra poses, overlap, or uneven gutters.

### B. Employee work-pose atlases — P0

- Deliver one 384 × 320 transparent PNG for Mina and one for Theo.
- Exact grid: 8 columns × 4 rows; 48 × 80 px cells; anchor `(24, 72)`.
- Row 1: seated idle ×2, typing ×4, waiting-for-approval ×2.
- Row 2: researching ×4, whiteboard thinking ×4.
- Rows 3–4: carrying-delivery walk, four frames each for front, back, left,
  and right.
- Poses contain the character and small handheld object only—never the desk,
  chair, monitor, whiteboard, or floor.

Prompt, run once for Mina and once for Theo:

> Using the attached Startup Valley character sheet for **[Mina / Theo]**, create an original production work-animation atlas on a truly transparent 384 by 320 pixel canvas, exactly 8 columns by 4 rows of 48 by 80 pixel cells. Row 1 contains two seated-idle frames, four laptop-typing frames with restrained hand motion, and two patient approval-wait frames. Row 2 contains four research-tool frames and four whiteboard-thinking frames. Row 3 contains four front-facing and four back-facing walking frames while carrying one plain cream document folder. Row 4 contains four left-facing and four right-facing versions of that delivery walk. Preserve identity, clothes, proportions, pixel density, and upper-left lighting. Use a shared bottom-center anchor at x 24, y 72. Draw only the character and the small folder where specified. No desk, chair, computer, whiteboard, floor, shadow, background, checkerboard, text, logos, glow, overlap, antialiasing, or irregular spacing.

### C. Layered workstation and research furniture — P0

- Deliver a 256 × 192 transparent sheet: 2 columns × 2 rows of 128 × 96 px.
- Row 1 is workstation rear and workstation front; row 2 is research-bench
  rear and research-bench front.
- Every cell uses ground anchor `(64, 88)`. Rear + actor + front must reconstruct
  one complete prop without doubled edges or gaps.

Prompt:

> Using the attached Startup Valley office and approved workstation art, redraw two original native-size layered furniture sets for seated character occlusion. Output a truly transparent 256 by 192 pixel PNG with an exact 2-column by 2-row grid of 128 by 96 pixel cells. Top-left is the workstation rear layer containing only elements behind the seated employee; top-right is its matching front layer containing only the desktop lip, front fascia, and foreground elements that must cover the employee. Bottom-left and bottom-right are equivalent rear and front layers for the research bench. All four cells share bottom-center ground anchor x 64, y 88 and reconstruct their complete prop without doubled outlines, missing pixels, seams, or shifted perspective. Match the game’s oblique orthographic projection, native pixel density, upper-left light, walnut, charcoal, Indigo, Cerulean, and restrained Vermilion accents. No characters, floor, backdrop, text, logos, glow, rotation, antialiasing, overlap, or baked shadows outside the footprint.

### D. Real-event world VFX atlas — P1

- Deliver 96 × 144 px, 4 columns × 6 rows of 24 × 24 px cells.
- Rows: thinking, typing, research, approval, completion, failure.
- Four-frame seamless loop or one-shot per row; bottom-center anchor `(12, 22)`.

Prompt:

> Create an original Startup Valley world-state VFX atlas on a truly transparent 96 by 144 pixel canvas, exactly 4 columns by 6 rows of 24 by 24 pixel cells. Each row is a coherent four-frame animation: thoughtful dots with a tiny idea spark, keyboard-key motion, a Cerulean research scan, a Vermilion approval ping, a Chartreuse completion sparkle, and a restrained charcoal failure puff. Use crisp hard-edged cozy-tech pixel art, consistent upper-left light, and the Whop palette: Vermilion #FA4616, Indigo #354B98, Cerulean #6196C1, Chartreuse #C1FA81, Off-White #F1F1F1, and Charcoal #151515. Align effects to bottom-center x 12, y 22. No words, letters, numbers, logos, characters, background, checkerboard, floor, glow bloom, antialiasing, overlap, or irregular gutters.

### E. Ambient office overlays — P1

- Deliver 128 × 160 px, 4 columns × 5 rows of 32 × 32 px cells.
- Rows: coffee steam, workstation monitor activity, research scan, prototype
  pulse, archive file activity.
- The base props remain static; overlays must work independently.

Prompt:

> Create five subtle original Startup Valley office ambience loops as transparent pixel-art overlays. Output exactly 128 by 160 pixels, a 4-column by 5-row grid of 32 by 32 pixel cells. Each row is a seamless four-frame loop: warm coffee steam, Indigo workstation monitor cursor activity, Cerulean research scan, restrained Vermilion prototype pulse, and a small cream document movement for the artifact archive. The effects must overlay existing props without drawing the prop itself. Use hard pixel edges, minimal motion, consistent upper-left light, and the established warm wood plus Whop accent palette. No furniture bodies, people, floor, backdrop, text, logos, checkerboard, large glow, antialiasing, overlap, or uneven cells.

### F. Character shadow set — P1

- Deliver 96 × 16 px, 3 columns × 1 row of 32 × 16 px cells.
- Cells: standing, walking, seated. Center anchor `(16, 8)`.

Prompt:

> Create three original soft-edged-but-pixelated contact shadows for Startup Valley characters on a truly transparent 96 by 16 pixel canvas, exactly three 32 by 16 pixel cells in one row: standing, walking, and seated. Use stepped charcoal pixels with restrained alpha, no smooth vector edges, and a consistent center anchor at x 16, y 8. The shadows should ground a 48 by 80 character without resembling a solid circle. No character, feet, furniture, floor color, background, checkerboard, text, glow, blur filter, overlap, or irregular gutters.

### G. Deterministic typography — P1

- Vendor [Tiny5](https://github.com/Gissio/font_Tiny5) and its OFL license for display labels, buttons, tabs, clock,
  nameplates, and short statuses.
- Vendor [Nunito Sans](https://github.com/google/fonts/tree/main/ofl/nunitosans) and its OFL license for chat, forms, event descriptions,
  and artifact content.
- Disable antialiasing for Tiny5 and use integer font sizes; retain normal
  antialiasing for Nunito Sans body copy.
- This is a sourced-font task, not an ImageGen request.

### H. Office unlock effect — P2

- Deliver 384 × 64 px, 6 columns × 1 row of 64 × 64 px cells.
- One restrained assembly puff: dust, two small brass sparks, then clear.
- Center-bottom anchor `(32, 58)`.

Prompt:

> Create one original Startup Valley furniture-arrival animation on a truly transparent 384 by 64 pixel canvas, exactly six 64 by 64 pixel frames in one row. Animate a restrained cozy workshop assembly puff: a small warm dust bloom, two tiny brass and Vermilion sparks, quick settling particles, then a fully clear final frame. Keep the center-bottom anchor at x 32, y 58 and leave room for a furniture prop to appear behind the effect. Match the game’s hard-edged pixel density, upper-left lighting, warm wood neutrals, Vermilion #FA4616, and brass highlights. No furniture, people, words, logos, floor, backdrop, checkerboard, large explosion, smoke cloud, bloom, antialiasing, overlap, or uneven gutters.

## Acceptance for the next polish pass

- No runtime character or modular prop relies on heavy fractional downscaling.
- Every movement direction and meaningful `WorkState` has an authored pose or
  deliberately reused loop.
- Seated characters render between matched furniture layers.
- Real worker events alone control work-state VFX; no fake progress animation.
- World labels reveal context without permanently covering the office.
- UI motion uses restrained 100–180 ms transitions and respects input focus.
- Rerunning this audit raises every scenario to at least 2 and the combined mean
  to at least 2.5 before the vertical slice is called polished.
