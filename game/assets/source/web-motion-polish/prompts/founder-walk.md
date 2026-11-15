# founder walk correction — built-in ImageGen

Generated 2026-11-15 from the existing runtime locomotion atlas.
Tool option: transparent_background=true. Generation IDs are in ../manifest.json.

Exact prompt:

> Use case: precise-object-edit. Edit target: the attached Founder runtime pixel-art sprite atlas. Correct ONLY the legs and shoes in the walking cells, columns 3–6 of every row (zero-based columns2–5). Keep this exact 6-column by4-row layout, transparent background and character identity. Rows top to bottom face south/front, north/back, west/left, east/right. First2columns idle: preserve exactly. Preserve every head, hair, eye, face, jacket, shirt, backpack, arm, body size and their positions; only pants below the hips and shoes may change. CRITICAL current defect: the walk frames repeat virtually the same split-leg pose. Create an unmistakably alternating four-frame walk cycle in each row: frame1 LEFT-leg-forward contact with RIGHT leg back; frame2 passing with feet nearly together and right knee advancing; frame3 RIGHT-leg-forward contact with LEFT leg back; frame4 passing with feet nearly together and left knee advancing. Side rows must visibly alternate which dark/light trouser leg is forward and must have narrow passing silhouettes between broad contact silhouettes, not four broad split poses. Front/back rows visibly swap the forward/raised shoe to the opposite side by frame3. Feet stay grounded at existing baseline, hips stay fixed; no hopping. Match existing navy trousers, white sneakers, crisp pixel palette and original hard-edged pixel blocks. Native atlas contract288x320, cells48x80, footanchor24,72. Deliver exactly the same tightly registered full atlas or an exact integer enlargement; no added gutters, titles, labels, shadows or extra sprites. Transparent pixels remain transparent. No other art changes.

The full generated atlas was rejected. Only registered lower legs from the two
side-facing rows were retained; front/back poses and all other pixels remain
unchanged. The accepted native source is ../founder-walk-overlay.png.
