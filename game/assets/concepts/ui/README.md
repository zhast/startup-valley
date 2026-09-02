# Startup Valley UI concepts

These 1672 × 941 mockups were generated with the built-in ImageGen tool on 2026-09-02. They form one layered UI direction rather than unrelated alternatives.

- `exploration-hud-concept.png`: quiet world-first HUD with time, company activity, a contextual employee prompt, and four quick destinations.
- `employee-chat-concept.png`: bottom dialogue console that presents an employee as a character while supporting natural-language chat and structured work assignment.
- `team-roster-concept.png`: a collectible team directory with three current employees and restrained `OPEN ROLE` slots for future hires.
- `employee-profile-concept.png`: Mina's work-focused profile, replacing farming-sim social trivia with role, morale, work style, skills, current work, bounded memory, and collaborators.
- `team-roster-brand-palette-concept.png`: preferred roster palette treatment using Vermilion, Off-White, Charcoal, Indigo, Cerulean, Chartreuse, Dust, Black, and White.
- `employee-profile-brand-palette-concept.png`: preferred profile palette treatment using the same semantic color roles.
- `work-journal-concept.png`: focused two-page workspace for live job state, approvals, steering, cancellation, and artifacts.

The current rendered game and clean office background were reference images. The mockups are design targets, not runtime textures; UI should be rebuilt with native Godot controls for responsive layout, accessibility, localization, and real data.

The roster and profile also used two user-provided farming-sim screenshots strictly as visual references for warm portrait-card rhythm and approachable scrapbook hierarchy. Their characters, branding, decorations, layouts, and game-specific fields were explicitly excluded.

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
