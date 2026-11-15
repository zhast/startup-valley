# Interaction and story audit — 2026-11-15

Scope: actual exported Godot game at localhost:5177, fresh isolated Chrome profiles, no providers or credentials. This records the **pre-fix** build observed before the story, walking-art, and click-feedback changes in progress. It is not acceptance evidence for those later changes.

## What to borrow from Stardew Valley

The [official site](https://www.stardewvalley.net/) leads with a personal arrival story and becoming part of a community. Its linked [controls documentation](https://stardewvalleywiki.com/Controls) separates walking from actions; PC uses WASD movement, while the [options documentation](https://stardewvalleywiki.com/Options) identifies right-click/X for interaction and left-click/C for tools. Startup Valley's click-to-walk can remain a deliberate convenience; it should not be described as Stardew's PC control scheme.

The useful convention is understandable targeting. Stardew exposes an affected-tile indicator and contextual software cursors; its options distinguish a hardware cursor that remains an arrow. UI scale and world zoom are separate options. These documented conventions support clear target feedback and readable controls, not a requirement to copy its artwork or exact mappings. No Stardew executable was playtested in this audit.

## Captured flow and highest-impact changes

1. **Before hiring Mina:** the notebook shows hiring, End day + save, New Product, a partially clipped Contract, and Back to office together. “Free onboarding hire” describes implementation rather than a person. Introduce Mina through one short line in her voice and one invitation; reveal the management options as the player needs them.
2. **Immediately after hiring:** two near-duplicate paragraphs both direct the player to Company Journey → New Product. “Company Journey” competes with “Meet Mina”; the latter merely closes the modal. Give this beat one clear continuation and make meeting Mina produce dialogue.
3. **Clicking Mina:** Chat / Assign / Activity / Studio tabs appear, although the default Chat content explains desktop-only functionality. The composer text is clipped and unavailable, and product guidance repeats in the rail, body, and footer. For the browser story loop, show authored dialogue and the next relevant choice first. Advanced management belongs behind an intentional secondary action.
4. **Moving:** actual timed player captures show correct translation and facing. Sideways walking keeps almost the same split-leg silhouette, while front/back foot phases visibly change. Native actor-frame checks by the logic owner independently found that the animation clock advances. The fix should improve the art phases, with a new timed browser check afterward.
5. **Clicking the floor:** a click at logical (801,609) produces a green marker centered at (816,624). This is a 15-pixel displacement on both axes at 1280×720. The marker displays a navigation-cell destination rather than the actual click. Keep the immediate click acknowledgement at the pointer hotspot; if a path endpoint needs separate feedback, give it distinct styling. The main.gd owner is correcting this.
6. **Hovering:** the canvas changes to `pointer` on the visible founder desk and back to `default` on floor at all four sampled sizes. The baseline lacks the requested object glow. The new glow should use the same visible-surface picker as click handling, avoiding invisible furniture rectangles and occluded objects. This implementation was still awaiting browser export verification when this audit finished.

## Scale and coordinate evidence

The Godot canvas occupies the full browser viewport; its 1280×720 game content is letterboxed with preserved aspect ratio. The same founder-desk location remains a hand-cursor target across these sizes. No broad CSS/viewport coordinate drift was reproduced.

| Browser viewport | Content scale | Vertical letterbox | Ground click, screen pixels | Marker center, screen pixels |
| --- | ---: | ---: | --- | --- |
| 1280×720 | 1 | 0 | (801,609) | (816,624) |
| 960×600 | 0.75 | 30 | (600.75,486.75) | (587.5,498) |
| 1440×900 | 1.125 | 45 | (901.125,730.125) | (918,747) |
| 390×844 | 0.3047 | 312.31 | (244.05,497.87) | (249,492) |

The smaller-size samples selected an adjacent navigation cell near a boundary. This requires rechecking after raw-click feedback lands; it is not evidence that cursor artwork has an incorrect hotspot. Native OS cursor artwork is omitted from Playwright screenshots, so this test measured known input coordinates, visible feedback pixels, and computed cursor shape.

At 390×844 the whole office is only about 390×219 pixels and body text becomes roughly 5 pixels high. That is a major phone usability limit even when coordinate mapping works. A near-term desktop/landscape recommendation is honest; a real phone version needs responsive dialogue, larger controls, and deliberate touch navigation. Do not label this a finished mobile experience.

## Additional visual check

A fresh sequence captured Mina at her desk, including closed-eye and open-eye frames. The first eight close-ups show face alternation; this audit did not positively identify a monitor/chair layer crossing her face. The art owner received those exact frames for comparison with the atlas. Later frames show her standing and leaving, so they are not seated-blink evidence.

## Priority and roadmap

- **Now:** one story action for hiring/meeting Mina; remove repeated instructions and unavailable browser chat controls; acknowledge clicks at the actual input point; ship matching hover glow; correct visibly weak side-walk phases and verify the seated blink.
- **Next:** character-specific dialogue tied to the current day and product milestone, a readable short journal objective, keyboard/touch-equivalent interactions, and independent UI scale.
- **Later:** richer relationships, authored events, a more lived-in office, and broader day-to-day activities. These are product direction, not bugs established by this test.

The notebook style, readable character portraits, and existing short path from hire to first product are useful foundations. Keep that visual identity while reducing simultaneous choices.

## Evidence and rerun notes

Local evidence from this run (not shipped game assets):

- `/private/tmp/startup-valley-hiring-audit/`: ordered `01-title`, `02-before-hire`, `03-after-hire`, `04-office`, `05-mina-panel` PNGs and result.json.
- `/private/tmp/startup-valley-walk-moving/`: 8 timed full-canvas frames per direction, founder-contact.png, positions, logs. Later employee captures here were seated and should not be used as walking evidence.
- `/private/tmp/startup-valley-coordinate-audit/`: before/click/hover images for each viewport, result.json, measurements.json.
- `/private/tmp/startup-valley-mina-motion/`: 32 early natural-walk frames, 24 desk-region captures, seated-contact.png, timestamps, errors.

Reusable capture scripts are `/private/tmp/startup-valley-hiring-audit.mjs`, `startup-valley-walk-qa.mjs`, `startup-valley-coordinate-audit.mjs`, and `startup-valley-mina-motion.mjs`. They launch fresh profiles and use real canvas input. Their onboarding coordinates must be updated after the story redesign. The permanent `tests/browser/playtest.mjs` and `tests/browser/loading.mjs` remain the core gameplay/lifecycle checks; the scripts above add focused visual evidence.

Limits: no screen-reader or color-contrast certification, no physical touchscreen/controller check, no Safari/Firefox pass, no Stardew executable comparison. Fresh captures are required after the in-flight changes; do not substitute these baseline screenshots for final acceptance.
