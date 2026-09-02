# Startup Valley UI concepts

These 1672 × 941 mockups were generated with the built-in ImageGen tool on 2026-09-02. They form one layered UI direction rather than unrelated alternatives.

- `exploration-hud-concept.png`: quiet world-first HUD with time, company activity, a contextual employee prompt, and four quick destinations.
- `employee-chat-concept.png`: earlier bottom dialogue exploration; superseded by the right-side rail and drawer below.
- `chat-selector-rail-concept.png`: preferred compact gameplay state, with a vertical selector for the three current employees and no persistent form.
- `chat-drawer-concept.png`: preferred expanded state, retaining the vertical selector beside Mina's conversation and actions.
- `team-roster-concept.png`: a collectible team directory with three current employees and restrained `OPEN ROLE` slots for future hires.
- `employee-profile-concept.png`: Mina's work-focused profile, replacing farming-sim social trivia with role, morale, work style, skills, current work, bounded memory, and collaborators.
- `team-roster-brand-palette-concept.png`: preferred roster palette treatment using Vermilion, Off-White, Charcoal, Indigo, Cerulean, Chartreuse, Dust, Black, and White.
- `employee-profile-brand-palette-concept.png`: preferred profile palette treatment using the same semantic color roles.
- `work-journal-concept.png`: focused two-page workspace for live job state, approvals, steering, cancellation, and artifacts.

The current rendered game and clean office background were reference images. The mockups are design targets, not runtime textures; UI should be rebuilt with native Godot controls for responsive layout, accessibility, localization, and real data.

The roster and profile also used two user-provided farming-sim screenshots strictly as visual references for warm portrait-card rhythm and approachable scrapbook hierarchy. Their characters, branding, decorations, layouts, and game-specific fields were explicitly excluded.

## Interactive concept preview

The playable development build exposes a `TEAM [T]` button. It opens the brand-palette roster, lets the player select Mina or `VIEW PROFILE`, returns with `BACK`, and closes with Escape. `ASSIGN WORK` returns to the real worker panel with Mina selected; `CHAT` currently reports that conversation UI remains concept-only.

This preview deliberately uses the generated mockups with native Godot interaction targets so the flow can be evaluated before the responsive implementation. It is not the final UI architecture: production screens must rebuild the layout with native controls and live worker data.

## Final prompt set

Exploration HUD:

> Design a shippable 16:9 desktop gameplay HUD for Startup Valley. Keep the office across roughly 85 percent of the screen with only a day-and-time plaque, tiny company-status cluster, four-slot Team/Work/Studio/Map quick bar, and contextual “Talk to Mina” prompt. Use an original cozy pixel interface with redwood frames, cream paper, moss selection, slate shadows, and restrained teal lights. Avoid a permanent chat panel, dense dashboard, copied interface, logos, and extra text.

Employee conversation:

> Design a shippable 16:9 conversation state with the office visible above a bottom-third dialogue console. Show Mina's original portrait, a short exchange, a single-line input, Send button, and Chat/Assign Work/Memory tabs. Make her feel like a character first and an AI agent second. Use redwood, cream paper, moss, warm gold, slate, and restrained teal in an original handcrafted pixel interface. Avoid a full-screen web chat, terminal styling, copied dialogue boxes, logos, and extra text.

Work journal:

> Design a shippable 16:9 two-page work journal over a softly darkened office. Show Theo, active assignment, token-budget strip, friendly thinking/researching/writing activity markers, an amber approval card, steering input, cancellation, and one artifact. Use warm cream pages, redwood binding, moss success, amber approval, slate ink, and sparing cyan accents. Make agent operations feel like cozy management rather than developer tooling. Avoid browser chrome, code editors, terminals, copied inventory menus, logos, and extra text.

Team roster:

> Create an original 16:9 pixel-art `TEAM` roster for Startup Valley. Use a spacious 3-by-2 collection of warm redwood employee cards: Founder, Mina, and Theo on the first row, followed by exactly three locked `OPEN ROLE` cards. Give each employee a short role, visible work status, and a few tiny profession icons; select Mina with a moss highlight and show a `VIEW PROFILE` action. Use cream paper, brass pixels, restrained teal circuitry, and the established Startup Valley palette. Exclude copied characters, layouts, branding, social-gifting fields, extra names, and illegible filler copy.

Employee profile:

> Create an original 16:9 pixel-art employee profile for Mina. Balance a large framed portrait with spacious workplace panels for role, working status, morale, work style, skills, current work, a recent bounded memory, and collaborators. Include `PROFILE`, `MEMORY`, `WORK`, and `ARTIFACTS` tabs plus `CHAT` and `ASSIGN WORK` actions. Use redwood framing, cream paper, moss, slate, restrained teal technology accents, cable dividers, and terminal indicators. Exclude copied characters, layouts, branding, likes/dislikes, birthdays, seasons, gifts, romance, and filler copy.

Brand-palette edit:

> Recolor only the UI chrome, panels, controls, indicators, borders, and interface accents. Use Vermilion `#FA4616` for primary actions and selection, Off-White `#F1F1F1` for surfaces, Charcoal `#151515` for framing and text, Indigo `#354B98` for navigation, Cerulean `#6196C1` for information, Chartreuse `#C1FA81` for positive status, Dust `#B6B5B0` for disabled and neutral areas, and Black/White for deepest shadows and highlights. Preserve layout, wording, portraits, natural character colors, icons, hierarchy, crop, and dimensions exactly. Retain tactile pixel materials by rendering the frame as charcoal-stained wood. Add or remove nothing.

Compact chat selector:

> Design a shippable 16:9 Startup Valley gameplay state with the actual office occupying roughly 82 percent of the screen and a coherent `TEAM CHAT` rail on the right. Stack exactly three generous portrait cards for Founder, Mina, and Theo, each with a short status and speech indicator. Select Mina with Vermilion and use Chartreuse status dots. Show no transcript or composer until an employee is chosen, and no `OPEN ROLE` cards in Chat. Use the exact brand palette and preserve natural office and portrait colors. Avoid forms, credentials, metrics, logs, unrelated characters, copied assets, and filler text.

Expanded chat drawer:

> Design the expanded version of the same right-side `TEAM CHAT` system. Keep roughly 58 percent of the office visible on the left. Retain a narrow far-right rail for Founder, Mina, and Theo while Mina's drawer shows portrait, role, status, two short message bubbles, one-line composer, `SEND`, `ASSIGN WORK`, and `VIEW PROFILE`. Make it feel like speaking with a game character rather than operating a chatbot dashboard. Use the exact brand palette, compact readable text, and no operational logs, credentials, metrics, open roles, or filler.
