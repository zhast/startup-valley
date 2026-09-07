# Terrazzo V4 — final targeted revision

Generated2026-09-04 around11:24UTC using built-in ImageGen. Edit target was
V3 original, inspected by root before dispatch. Initial plus three targeted
attempts is now exhausted; no V5 or renamed continuation of this tile.
Original exec-d215cf34-79c0-4a5f-ac3b-ceb72f81e2b0.png is preserved unchanged.
Native export and source review are complete; actual-room review remains pending.
Wood remains production default.
This is source118, not a new furniture family or runtime approval.

## Measured export facts

- Original: 1254×1254 opaque RGB; SHA256 `9527d36fd99e864e14cba0589b4b3bb74e5c836094b96d59a01f80cb07de5953`.
- Full-source uniform point sampling to 128×128, no dithering, 12-color ceiling: 11 actual colors. No cropping, edge edits, rotations, mirrors, blending, or source mutation.
- Separate existing V2-palette normalization uses 8 colors. The separate unified-base candidate globally replaces `#E3DCCF` with `#EAE4D7`: exactly 14,813 pixels change; every other pixel is unchanged. The candidate uses 7 colors and remains fully opaque.
- Raw/normalized opposite-edge mismatches are 1 horizontal and 1 vertical; unified-base mismatches are 0/0. These checks do not establish visual acceptance.
- Unified-base nonbase density: 449/16,384 pixels (2.7405%); top eight rows 2.7344%, central 112×112 interior 2.7663%, eight-pixel perimeter band 2.6563%.
- All nine versioned PNG derivatives reproduce byte-identically; the original hash remains unchanged. Native/4×/3×repeat views preserve raw and normalized alternatives alongside the candidate.
- Builder: [`build_terrazzo_v4.sh`](../../../../../dev/tools/build_terrazzo_v4.sh). Review: [`TERRAZZO_V4_SOURCE_REVIEW.md`](../../../../../dev/art-catalogue/TERRAZZO_V4_SOURCE_REVIEW.md). Native study only; this source remains outside the frozen 117-source catalogue checkpoint.

## Exact prompt

Use case: precise-object-edit.
Asset type: original Startup Valley pixel-art seamless cream terrazzo floor material, 128x128 native pixels, shown at uniform crisp enlargement.
Image 1 is the edit target: the existing V3 cream terrazzo material. Make ONE targeted correction: replace its long diagonal scratch/stitch chains with SHORT irregular compact stone-chip clusters, each only 1–3 native pixels across. Keep the existing muted cream, dusty grey, a few desaturated terracotta flecks, and calm value contrast. Sparse little chips should be evenly scattered at the SAME density in the center and near every edge, without repeating rows, strings, swirls or a focal composition. Keep a single uniform cream base #EAE4D7; no mottled wash, gradient, paper texture or shadows. Preserve square top-down material-only framing, fully opaque image, native128x128 design and limited 11-color pixel-art character. All four outermost native pixel rows/columns must match the base #EAE4D7, only ONE pixel wide; do not add a blank 2/4/8px border, vignette or frame. Chips should approach that one-pixel seam irregularly all around without touching the edge. No diagonal chain longer than 3pixels; no lines, scratches, grout, floor grid, border, perspective, furniture, labels, letters, room, alpha checkerboard, photographic noise or watermark. Return one original seamless tile only, crisp nearest-style uniform enlargement, not a tiling presentation sheet. This is the third and final targeted retry in this existing material series; keep the color identity while fixing only the shape and distribution of the chip marks.
