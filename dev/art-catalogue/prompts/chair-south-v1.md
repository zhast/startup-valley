# Chair south v1 — independent front-view study

Mode: built-in ImageGen, reference-guided generation. Reference image inspected before use: `game/assets/source/overnight-20260904/calibration/chair-north-v1.png`. The north source establishes chair identity and material; it is not a bitmap to rotate or mirror. Output remains unapproved calibration art.

## Exact prompt

Use case: stylized-concept
Asset type: one original Startup Valley pixel-art furniture sprite, true-alpha PNG.
Input image 1 is a STYLE AND OBJECT-IDENTITY REFERENCE: the REAR/north view of our low-back ergonomic task chair. Independently draw the SOUTH/front view of exactly this chair. Do not flip, rotate or repeat the rear raster.
Camera and facing: fixed screen-aligned raised orthographic game camera, no diagonal yaw and no vanishing point. South means a person sitting in this chair would look down toward the viewer. We now see the FRONT cushion surface of the backrest, the seat top and front seat edge, both armrests, central lift stem and caster base. The rear adjustment bracket seen in the reference is behind the backrest and must NOT appear on its front cushion.
Identity and style: same low-back silhouette, charcoal frame, restrained indigo upholstery, small gray hardware highlights, five-star caster base, cozy-tech pixel-art cluster language. Keep the backrest and seat proportions consistent with the reference. Clear simple shapes at native size, not photorealistic.
Native export target: a 32-pixel-wide and approximately 55-pixel-tall chair, matching the reference's normalized scale. This is a low-back chair, not a tall executive chair. It will be registered on a 96×160 transparent canvas with floor pivot (48,112), lowest caster contact boundary at y=128. Preserve the full object with ample transparent margins; exact canvas registration will be mechanical afterward. Backrest, seat and caster scale must stay consistent with the reference rather than stretching the chair taller.
Lighting: fixed upper-left light in screen space, small crisp highlights; do not reverse the lighting with the facing.
Background: genuinely transparent alpha outside the chair, including all open gaps between arms, stem and casters. No painted checkerboard, no opaque background.
Constraints: one complete chair only. No person, desk, floor, cast shadow, scene, text, labels, logo, watermarks, dimension lines or additional views. Every caster remains inside frame. Deliver actual transparent PNG.
