# Broadleaf planter — targeted alpha correction1

Date:2026-09-06. Same initial batch, targeted retry1of3.
Use case: background-extraction.
Input image: broadleaf-planter-fourway-v1.png is the edit target.
Change only the background: remove the entire white/light-gray painted
checkerboard and export real RGBA pixels with alpha0 outside the plants.
Do not show a transparency preview. A drawn checkerboard is not transparency.
Preserve the exact four plants, leaf and branch shapes, pot details, colors,
edge pixels, order, positions and the948×1659pixel canvas. Do not redraw,
rescale, crop or introduce smoothing. Keep enclosed negative spaces between
stems/leaves transparent as well. Preserve opaque white/cream pot pixels.
No caption, shadow, ground or new imagery. The requested deliverable is an
actual transparent sprite sheet, not an illustration of transparency.
