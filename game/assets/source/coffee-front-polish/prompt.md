# Espresso front panel — built-in OpenAI ImageGen

Canonical profile: `startup-valley-cozy-pixel-v1`.
Generated 2026-11-15. Tool option: `transparent_background=true`.

Inputs, in order:

1. The historical south espresso front crop `[81,134,31,31]`.
2. `dev/art-catalogue/style-reference-board.png`, used for style, palette and pixel density.
3. The rejected whole-machine candidate, used only for its recognizable brewing details.

Exact final prompt:

> Use case: precise-object-edit. Canonical style profile: startup-valley-cozy-pixel-v1. Input1 is the exact square31×31pixel FRONT PANEL edit target for a tiny espresso machine. Input2 is our game's canonical style reference board: copy its native pixel density, warm handcrafted material treatment, one-pixel dark outlines and restrained cream/charcoal palette; do not copy its pictured characters or furniture. Input3 is an earlier design direction showing a recognizable cup, spout, pressure gauge and drip tray, but its tall full-body format is NOT the target. Return ONLY a redesigned SQUARE FRONT PANEL that fills the square canvas edge to edge. The top plane, sidewalls and surrounding counter ALREADY EXIST separately and must NOT be redrawn. Fit a small round cream pressure gauge and brass knob across the TOP QUARTER, a readable dark recessed brew bay with a short chrome group-head/spout in the MIDDLE, ONE warm white espresso cup visibly directly under that spout, and a slim steel drip tray along the BOTTOM. This is31×31nativepixels: strong readable clusters, avoid excessive tiny details. Squared dark charcoal teal perimeter, entire square filled opaque. Straight-on FRONT plane, horizontal edges/vertical sides, NO perspective, no roof or 3D side panels. Match the provided gameboard's pixel art, no glossy rendering, no blurred edges. Palette #202326,#343536,#3b4b52,#27343a,#c9c7b9,#777f7e,#f0e2bd,#d4a85e,#754426. Output same square31×31 or exactinteger enlargement, no padding, no border outside the machine, no background, no labels/text/logo, no extras. Panel should unmistakably read as a COFFEE ESPRESSO MACHINE at native31pixel width.

Generation session: `01a1e146-9490-71d0-99d4-d5691e91d349`.
Selected output: `exec-b3c1930a-e729-4fb6-87d4-5050bbd9fe55.png`, retained unmodified as `generated-front-panel.png`.

The first whole-machine attempt, `exec-7f1ac564-639a-4665-948a-546f8aeb05ba.png`, is retained as `rejected-whole-machine.png`. Its cup/spout were useful, but its whole-machine proportions did not preserve the exact top-plane geometry. It was not installed.

Exact rejected prompt:

> Use case: precise-object-edit. Input1 is the edit target: a tiny31×46pixel south-facing espresso appliance for a cozy Stardew-like office game. Input2 shows its existing counter assembly for context. Redesign ONLY the appliance inside Input1's exact rectangular silhouette; do not draw the counter, grinder, plant, room, people or any other object. Current defect: it reads like a flat electronic control box. Make it unmistakably a compact ESPRESSO MACHINE: clear dark recessed brewing bay, short chrome group-head/spout, one visible warm white demitasse cup under the spout, a distinct metallic drip tray at the bottom, a small round pressure gauge and warm brass control knob. The top15nativepixels are a visible TOP plane/cup warmer in this game's orthographic raised camera; the bottom31pixels are the upright FRONT plane. Keep both horizontal planes screen-horizontal and vertical sides vertical: this is a square-grid top-down/front game view, NOT diamond isometric, no diagonal skew, no wide perspective. Keep overall31pixelwidth and46pixelheight, same filled outer rectangular body and baseline. Preserve existing charcoal teal casing, muted steel shades and warm cream/brass accents; no bright saturated new colors. Source palette references: #202326,#343536,#3b4b52,#27343a,#c9c7b9,#777f7e,#f0e2bd,#d4a85e,#754426. Use readable native-pixel clusters, hard edges, no gradients or smooth rendered texture. Deliver only the machine on transparentbackground, same31:46aspectratio or exactinteger enlargement, entiremachinefills targetboundsexactly, no extra padding, labels, text, logo, border or cast shadow. Keep fixed silhouette and viewpoint; add only appliance-detail clarity.
