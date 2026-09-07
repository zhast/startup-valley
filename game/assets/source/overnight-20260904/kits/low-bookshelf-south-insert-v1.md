# Low bookshelf South insert v1

Built-in ImageGen; first original request, prepared 2026-09-04 11:04 UTC.
State: completed and copied by 11:06 UTC. Target opaque 88×24 rectangular front-plane
insert, not a full cabinet. No alpha extraction, whole-object rotation or runtime
downscaling is planned. This is after the frozen 116-source checkpoint.

Original117: `exec-24833441-1019-4255-a126-8fc031e329b3.png`, copied unchanged
as `low-bookshelf-south-insert-v1.png`. Actual2140×735RGB, not the requested11:3
aspect. SHA256 `100ad230f3f1dc8c0534b09b61ed87f6abc0c69daf310a0de95c478064131379`.
The source is intentionally opaque. No checkerboard/alpha extraction is needed.
Its aspect failure is explicit: the strict88×24 recipe must reject it. A separate
full-source70×24 proportional native study is being reviewed as a possible
centered decoration in the unchanged88×24 bay. No stretch, crop, extension or
new retry has been authorized; no native/room acceptance yet.

References (style/palette only, not edit targets):

- `game/tests/fixtures/furniture-calibration/kits/archive-service-south-insert-v1-8x.png`
- `game/tests/fixtures/furniture-calibration/materials-v2/oak-horizontal-v2.png`

## Exact prompt

Use case: stylized-concept. Asset type: one original Startup Valley game furniture insert, not a whole furniture sprite. Input image 1 is a pixel-art detail/readability reference from our existing archive, NOT an edit target and NOT the requested cabinet. Input image 2 is our warm oak palette reference only. Generate a NEW wide rectangular flat front-view bookshelf interior insert. Target composition exactly 88 by 24 native pixels, 11:3 canvas aspect, displayed at a uniform integer enlargement. The entire rectangle is an opaque deep warm charcoal shelf interior (#282622); no transparent background is needed for this rectangular inset. One low row of chunky upright reference books across the left two thirds, a short horizontal book stack beside them, and one small off-white fabric resource bin at the right. Books vary modestly in height, no object taller than 21 of the 24 native rows. Bottoms sit on the same baseline with a little dark space above. Restrained indigo, cerulean, muted green, parchment and a single warm vermilion spine; upper-left one-pixel highlights, dark separations, clear simple silhouettes at native size, roughly 16-24 colors. Pixel clusters, no antialiasing or subpixel details. The frame/shelf/cabinet and its top plane are made separately in code: do NOT draw any outer wooden border, legs, cabinet top, floor, room, shadows outside the rectangle, labels, readable writing, UI or characters. This is a FLAT rectangular material insert for the South-visible vertical plane, so all book spines are front-facing, edges parallel to image axes, no perspective convergence, isometric yaw, camera tilt, or 3D mockup. Original cozy-tech art, no logos or watermark. Preserve the requested 11:3 whole-canvas aspect without outer blank margins.
