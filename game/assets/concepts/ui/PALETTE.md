# Startup Valley UI palette

Use this palette for native Godot UI chrome. Character portraits and office illustrations may retain natural skin, hair, plant, and material colors; overlays, panels, borders, controls, status indicators, and navigation should use the tokens below.

| Token | Color | UI role |
| --- | --- | --- |
| `primary` | Vermilion `#FA4616` | Primary action, current selection, and attention accent |
| `surface` | Off-White `#F1F1F1` | Cards, paper panels, fields, and light menu surfaces |
| `ink` | Charcoal `#151515` | Body text, headings, dark frames, and deep UI surfaces |
| `secondary` | Indigo `#354B98` | Navigation tabs, secondary actions, and durable work state |
| `info` | Cerulean `#6196C1` | Informational accents, links, cables, and progress context |
| `positive` | Chartreuse `#C1FA81` | Available, online, completed, and healthy morale states |
| `disabled` | Dust `#B6B5B0` | Locked roles, dividers, disabled controls, and neutral metadata |
| `shadow` | Black `#000000` | Pixel outlines and deepest shadows |
| `highlight` | White `#FFFFFF` | Crisp highlights and high-contrast light details |

## Usage rules

- Vermilion is scarce. Reserve it for the one primary action in a view, the current selection, or an item requiring attention.
- Use Charcoal text on Off-White, Chartreuse, Cerulean, and Vermilion for normal-size production text. White text on Vermilion is acceptable only for large, bold labels after contrast verification.
- Chartreuse always means positive or available. Do not use it as general decoration.
- Dust states must also use a lock icon, disabled treatment, or label so meaning never depends on color alone.
- Preserve the cozy quality through charcoal-stained wood grain, Off-White paper texture, pixel dithering, plants, and lived-in office details.
- Do not apply the limited UI palette destructively to portraits or environment art. It is a system palette, not a requirement to posterize every game asset.
