# Layered game and agent UI

Startup Valley should feel like a cozy office game during movement and like a capable agent product only when the player asks for depth. Do not keep the current full-height work form permanently visible.

## Interface layers

| Layer | Opens when | Purpose | World visibility |
| --- | --- | --- | --- |
| Exploration HUD | Default | Time, company activity, nearby interaction, and four destinations | Nearly all of the office remains visible. |
| Employee dialogue | The player talks to an employee | Short conversation, roleplay, memory, and entry into a work assignment | The upper two-thirds of the office remains visible. |
| Work journal | A substantial job is assigned or selected | Live state, usage, tool categories, approvals, steering, cancellation, and artifacts | The office remains visible around a centered modal. |

These layers should share the same redwood, cream, moss, slate, warm-gold, and restrained-cyan component language.

## Exploration HUD

- Keep normal play free of forms and scroll panes.
- Show only day/time, a compact active-worker count, and contextual interaction text.
- The quick bar opens Team, Work, Studio, and Map; it is navigation, not an inventory clone.
- Employee job state should primarily appear through movement, desk activity, small icons, and room lighting.

## Employee dialogue

- Open near an employee and pause player movement while composing.
- Retain only a few recent conversational turns in the visible panel; durable memory remains worker-owned and bounded.
- `Chat` supports character conversation. `Assign Work` reveals title, request, acceptance criteria, optional studio attachment, and budget. `Memory` shows short structured facts—not an infinite transcript.
- After assignment, close back to the office so the employee's physical movement communicates that work began.

## Work journal

- Show status and observable activity such as thinking, research, writing, and artifact creation; never expose hidden chain-of-thought.
- Put approval requests at the top of the right page with a clear consequence and paired approve/decline actions.
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
2. Replace the always-open assignment form with employee dialogue and an `Assign Work` tab.
3. Move live events, token usage, approvals, steering, and cancellation into the work journal.
4. Move durable studio files and promotion review into the journal's artifact section.
5. Keep keychain setup as a first-run modal rather than a permanent gameplay control.
