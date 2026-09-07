# lawyer portrait — alpha extraction retry1

Completed08:48UTC as exec-1a034f91-81a2-4831-b258-1408e9b1f869.png,1122×1402RGB. First targeted retry; identity essentially unchanged but background is STILL an opaque checkerboard. This is not a usable cutout. Source retained; no flood-fill, matte keying or fake alpha.

Use case: background-extraction. Edit only the background of this portrait.
Erase the checkerboard grid completely and replace it with genuine transparent PNG alpha0 pixels. I need an actual cutout layer, not a picture of transparency.
Keep the person unchanged: exact face, eyes, hair, clothing, palette, body crop, pixel edges and canvas composition. Preserve the full visible character and any negative spaces between arms/hair. Do not redraw or improve anything. No white, gray or black background, no checkerboard drawing, no glow or halo. Return a real RGBA PNG whose empty corners and space outside the person have alpha0.
