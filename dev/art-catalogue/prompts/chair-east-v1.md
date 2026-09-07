# Chair east v1 — reference-guided side view

Mode: built-in ImageGen, independent redraw. All three references were inspected first. Images1–2 establish chair identity; image3 is Mina's east-facing seated pose for physical support, not content to include.

References:

- `game/assets/source/overnight-20260904/calibration/chair-north-v1.png`
- `game/assets/source/overnight-20260904/calibration/chair-south-v3.png`
- `game/tests/fixtures/furniture-calibration/characters/mira-east-seated-v3-4x.png`

## Exact prompt

Use case: stylized-concept
Asset type: one transparent pixel-art furniture sprite for Startup Valley.
Reference roles: Image1 is the north/rear chair and image2 is its south/front study. Treat them as the same charcoal-and-indigo low-back ergonomic chair family. Image3 shows the right-facing seated employee pose the chair needs to support; do NOT include any person or body part in the output.
Primary request: independently draw the EAST-facing side profile of this chair. A seated person would look RIGHT. Backrest is on the LEFT; seat extends RIGHT, under the person's horizontal thigh. Fixed raised screen-aligned orthographic camera; true side view, no diagonal yaw and no perspective vanishing point. This must be a new side drawing, never a mirrored or rotated north/south bitmap.
Keep the family: charcoal shell/frame, low rounded indigo cushion, restrained woven pixel texture, small gray metal highlights, matching padded armrest, central gas-lift and five-star caster base. The left/rear backrest should support the employee's upright torso; the seat should have a clear, almost horizontal top support plane. Show only the correct near-side profile and any genuinely visible far-side support, not two front-facing armrests pasted together.
Native calibration: maximum caster base width32px; approximately55px total visible height, preserving a low-back chair. It will be exported on a96×160 canvas with floor pivot(48,112), nearest caster contact boundary y128. Aim for the seat's hip-support surface aroundy88,24px above the floor pivot. This is a seat-height calibration target, not permission to stretch the object. Preserve a plausible compact chair and report visually clear seat/backrest/caster landmarks. Leave ample transparent margins for mechanical registration.
Lighting remains upper-left in screen space, regardless of chair direction. Crisp cozy-game pixel clusters, small restrained palette, not photorealistic.
Background must be genuinely transparent alpha, including all open gaps. Only one complete chair: no character, desk, floor, cast shadow, room, text, labels, guides, logos, watermark or additional views. Deliver a real transparent PNG sprite.
