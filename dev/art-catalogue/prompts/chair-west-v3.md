# Chair west v3 — final targeted proportion correction

Built-in ImageGen edit. Inspected target: `game/assets/source/overnight-20260904/calibration/chair-west-v2.png`. V2 has genuine alpha, but its thresholded712×1361 silhouette relative to657px caster-base width would normalize to about35×66 rather than the east32×56. No nonuniform local resizing was used.

## Exact prompt

Edit only the vertical proportions of this transparent west-facing pixel-art chair to match our compact low-back family. Keep the caster base exactly its current width and shape. Lower the seat toward the caster base by shortening the gas-lift/under-seat rise by about15%; also shorten the upright backrest height by about15%. The chair should become compact, not narrow or stretched. Preserve seat depth, backrest thickness, armrest construction and their horizontal positions. The target total height is56 units for a32-unit caster-base width; the seat top is31 units above the lowest caster contact. Thus the seat/backrest/lift geometry must be redrawn, not globally squashed.
Keep the west orientation unchanged: backrest RIGHT and seat extending LEFT. Preserve charcoal frame, indigo fabric texture, current palette and fixed upper-left light; do not mirror anything or brighten the blue. One complete chair, no person, desk, floor, shadow or labels.
Keep the background genuinely transparent, including all gaps. Return a real transparent PNG cutout, with no background pixels or glow outside the chair.
