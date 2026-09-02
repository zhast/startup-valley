# Layered game and agent UI

Startup Valley should feel like a cozy office game during movement and like a capable agent product only when the player asks for depth. Do not keep the current full-height work form permanently visible.

## Interface layers

| Layer | Opens when | Purpose | World visibility |
| --- | --- | --- | --- |
| Exploration HUD | Default | Time, company activity, nearby interaction, and four destinations | Nearly all of the office remains visible. |
| Team roster | The player opens Team | Browse current employees and see future hiring capacity | Full-screen menu; returning to the office is one action. |
| Employee profile | The player selects a roster card or inspects an employee | Understand role, work style, current state, memory, and collaborators | Full-screen menu with direct paths to dialogue and work. |
| Team chat rail | Default when chat navigation is available | See the current cast and live status without opening a dashboard | Roughly 82% of the office remains visible. |
| Employee dialogue | The player selects a rail portrait or talks to an employee | Short conversation, roleplay, profile, and entry into a work assignment | Roughly 58% of the office remains visible beside a right drawer. |
| Work journal | A substantial job is assigned or selected | Live state, usage, tool categories, approvals, steering, cancellation, and artifacts | The office remains visible around a centered modal. |

These layers should share the semantic palette in `PALETTE.md`. Cozy character comes from pixel texture, material grain, chunky silhouettes, plants, and personal objects—not from introducing unrelated UI colors.

## Exploration HUD

- Keep normal play free of forms and scroll panes.
- Show only day/time, a compact active-worker count, and contextual interaction text.
- The quick bar opens Team, Work, Studio, and Map; it is navigation, not an inventory clone.
- Employee job state should primarily appear through movement, desk activity, small icons, and room lighting.

## Employee dialogue

- Use the right-side drawer in `chat-drawer-concept.png` as the preferred layout; the older bottom-panel concept is retained only as exploration history.
- Open by selecting a portrait in the chat rail or by talking to an employee in the office. Pause player movement while composing.
- Keep the same narrow portrait rail visible inside the expanded drawer so switching employees is spatially stable.
- Retain only a few recent conversational turns in the visible panel; durable memory remains worker-owned and bounded.
- `Chat` supports character conversation. `Assign Work` reveals title, request, acceptance criteria, optional studio attachment, and budget. `Memory` shows short structured facts—not an infinite transcript.
- After assignment, close back to the office so the employee's physical movement communicates that work began.

## Team chat rail

- A vertical selector is preferable to a horizontal roster because it occupies the space already claimed by the current sidebar and scales without covering the office floor.
- Show current employees only. Future `OPEN ROLE` cards belong in Team/Hiring, where they communicate growth; in Chat they create dead targets.
- At three employees, use portrait cards with name and status. At four to six, reduce card height slightly. Beyond six, use a scrollable rail while preserving the selected employee.
- The compact rail contains no transcript, input field, credentials, work-order form, usage meter, logs, or artifact list.
- Selection uses Vermilion plus a border shape; online and available state uses Chartreuse plus a dot and text label.

## Team roster

- Make current employees feel like a small cast, with large portraits, readable names, concise roles, and live status.
- Reserve locked `OPEN ROLE` cards for future hires so company growth is visible without inventing unavailable characters.
- Use profession icons as recognition aids, not as a substitute for accessible text.
- Selecting a card opens its employee profile. Hiring itself should remain a separate future flow.

## Employee profile

- Replace farming-sim social fields with information that helps the player manage and understand an agent: role, status, morale, work style, skills, current work, recent bounded memory, and collaborators.
- Keep `Profile`, `Memory`, `Work`, and `Artifacts` as stable tabs. `Chat` opens employee dialogue; `Assign Work` opens its structured assignment state.
- Memory summaries must come from the worker's bounded structured memories, never an unbounded transcript.
- Current work and status are live worker projections. Morale already exists in the game model; role, work-style traits, and skills are target fields that need explicit contracts before runtime implementation.
- Do not add likes/dislikes, gift preferences, birthdays, seasons, dating state, or romance hearts unless a future game system gives them real mechanical meaning.

## Work journal

- Show status and observable activity such as thinking, research, writing, and artifact creation; never expose hidden chain-of-thought.
- Put approval requests at the top of the right page with a clear consequence and paired approve/decline actions. Use a Vermilion attention accent plus an icon and label rather than relying on color alone.
- Keep steering available while work is running without replacing the original assignment.
- Treat cancellation as secondary and visually distinct from decline.
- Show token usage as a comprehensible budget strip, with exact counts available in a tooltip or detail view.
- Make artifacts tangible document cards that open the guarded artifact viewer.

## Input and accessibility

- Support mouse, keyboard, and controller focus from the same component hierarchy.
- Do not rely on color alone for active, warning, approval, or completion states.
- Use native Godot text rather than baking labels into textures.
- Keep minimum hit targets large and preserve readable contrast over the detailed office.
- Allow Escape or the journal Close action to return to the office without losing work state.

## Migration from the current sidebar

1. Move time controls into the compact exploration plaque.
2. Route the Team quick-bar destination to the roster, then from each employee card to its profile.
3. Replace the always-open assignment form with employee dialogue and an `Assign Work` tab.
4. Move live events, token usage, approvals, steering, and cancellation into the work journal.
5. Move durable studio files and promotion review into the journal's artifact section.
6. Keep keychain setup as a first-run modal rather than a permanent gameplay control.
