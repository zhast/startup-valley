# Remaining HUD directions

These full-screen mockups keep the approved notebook team sidebar and explore
the remaining in-game UI as one system:

- company title;
- day, time, and money HUD;
- contextual employee interaction prompt;
- job-completion notification;
- movement hint.

They intentionally exclude speed controls, inventory, health, energy, minimaps,
and quest panels. These are concept references, not runtime assets.

| Option | Direction | Strength | Tradeoff |
| --- | --- | --- | --- |
| A | Desk Calendar | Closest material match to the sidebar | Most visually substantial |
| B | Founder's Ledger | Softest, calmest, and most game-world space | Least distinctly technical |
| C | Cozy Terminal | Strongest startup/technology identity | Darker and slightly less pastoral |

Recommendation: use Option C as the system direction, while keeping Option B's
restrained notification size. It best communicates that this is a technology
company simulation without abandoning the cozy walnut-and-parchment language.

## Generation

Mode: built-in ImageGen, reference-image edit. The edit target was the native
Godot capture at `game/tests/output/visual-review/ui-chat.png`.
After generation, the current runtime sidebar was composited back into every
option so that only the HUD direction varies during review.

### Option A — Desk Calendar

```text
Use case: ui-mockup
Asset type: shippable full-screen game UI mockup, Variation A — Desk Calendar
Input image: Image 1 is the edit target and exact composition reference.
Primary request: Redesign only the non-sidebar HUD in Image 1 as one cohesive cozy pixel-art UI system. Keep the office scene, all people, furniture, lighting, camera, and the entire right-side notebook/chat/team sidebar unchanged pixel-for-pixel. Replace the flat top HUD, title treatment, and bottom movement hint; add one small contextual action prompt near Mina and one compact job-completion toast without obscuring gameplay.
Style/medium: crisp handcrafted 2D pixel-art game UI; warm Stardew-like readability without copying any specific game asset; visually identical walnut, parchment, amber bevels, iron rivets, and vermilion/indigo accents to the approved sidebar.
Composition: 1280x720 landscape gameplay screenshot. A compact centered walnut desk-calendar HUD at the top. A restrained wooden title plaque at upper left. Tiny contextual wood-and-parchment key prompt near Mina. Compact parchment notification toast below the title. Small bottom movement strip.
Text (verbatim, exact and only): "STARTUP VALLEY", "DAY 1", "8:01 AM", "$0 EARNED", "E · CHAT", "MINA FINISHED", "launch-brief.md ready", "VIEW", "WASD / ARROWS TO MOVE".
Color palette: #FA4616 vermilion, #F1F1F1 off-white, #151515 charcoal, #354B98 indigo, #6196C1 cerulean, #C1FA81 chartreuse, walnut and aged parchment.
Constraints: preserve Image 1's right sidebar exactly; preserve the office art and layout exactly; no speed controls, pause buttons, inventory, health, energy, minimap, quest list, random icons, extra windows, extra characters, extra text, logos, or watermark. Keep the playfield open and uncluttered.
```

### Option B — Founder's Ledger

```text
Use case: ui-mockup
Asset type: shippable full-screen game UI mockup, Variation B — Founder's Ledger
Input image: Image 1 is the edit target and exact composition reference.
Primary request: Redesign only the non-sidebar HUD in Image 1 as one cohesive, lightweight cozy pixel-art UI system. Keep the office scene, all people, furniture, lighting, camera, and the complete right-side notebook/chat/team sidebar unchanged pixel-for-pixel. Replace the flat top HUD, title treatment, and movement hint; add a small contextual action prompt near Mina and one compact job-completion memo.
Style/medium: crisp handcrafted 2D pixel-art game UI; a soft founder's notebook/ledger aesthetic using cream paper, fine walnut borders, ink dividers, tiny binder rings and restrained rivets. Less bulky and more parchment-forward than the right sidebar, but clearly part of the same visual family.
Composition: 1280x720 landscape gameplay screenshot. Use one slim horizontal open-ledger strip at top center containing the three HUD values. Use an understated ink-and-wood title tag at upper left. The completion notice is a small pinned memo directly below the title. The interaction prompt is a compact paper speech-ribbon by Mina. The movement hint is a narrow paper label at bottom center.
Text (verbatim, exact and only): "STARTUP VALLEY", "DAY 1", "8:01 AM", "$0 EARNED", "E · CHAT", "MINA FINISHED", "launch-brief.md ready", "VIEW", "WASD / ARROWS TO MOVE".
Color palette: warm ivory paper, walnut brown, charcoal ink, #FA4616 vermilion for action, #354B98 indigo for information, #C1FA81 chartreuse only for completion.
Constraints: preserve Image 1's right sidebar exactly; preserve the office art and layout exactly; no speed controls, pause buttons, inventory, health, energy, minimap, quest list, random decorative icons, extra windows, extra characters, extra text, logos, or watermark. Keep the playfield spacious and calm.
```

### Option C — Cozy Terminal

```text
Use case: ui-mockup
Asset type: shippable full-screen game UI mockup, Variation C — Cozy Terminal
Input image: Image 1 is the edit target and exact composition reference.
Primary request: Redesign only the non-sidebar HUD in Image 1 as one cohesive Silicon Valley office-game UI system rooted in warm pixel-art craft. Keep the office scene, all people, furniture, lighting, camera, and the complete right-side notebook/chat/team sidebar unchanged pixel-for-pixel. Replace the flat top HUD, title treatment, and movement hint; add one small contextual prompt near Mina and one compact work-completion notification.
Style/medium: crisp handcrafted 2D pixel-art game UI. Hybrid of walnut cabinetry and 1980s startup-computer hardware: dark indigo enamel display faces, inset parchment labels, tiny amber indicator lights, chunky tactile vermilion buttons, subtle pixel-grid texture. Cozy and approachable, not cyberpunk or sci-fi.
Composition: 1280x720 landscape gameplay screenshot. A compact walnut-cased status terminal at top center with three clearly separated readouts. A small startup badge at upper left. A low-profile terminal notification directly beneath it. A tiny indigo-and-parchment contextual key prompt beside Mina. A narrow dark-enamel movement strip at bottom center.
Text (verbatim, exact and only): "STARTUP VALLEY", "DAY 1", "8:01 AM", "$0 EARNED", "E · CHAT", "MINA FINISHED", "launch-brief.md ready", "VIEW", "WASD / ARROWS TO MOVE".
Color palette: walnut brown, warm parchment, #151515 charcoal, #354B98 indigo, #6196C1 cerulean, #FA4616 vermilion, #C1FA81 chartreuse.
Constraints: preserve Image 1's right sidebar exactly; preserve the office art and layout exactly; no speed controls, pause buttons, inventory, health, energy, minimap, quest list, neon cyberpunk styling, extra windows, extra characters, extra text, logos, or watermark. Keep the HUD compact and the playfield open.
```
