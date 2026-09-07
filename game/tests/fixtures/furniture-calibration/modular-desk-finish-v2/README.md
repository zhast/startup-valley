# Isolated modular desk finish v2

Eight full registered rear/front PNGs,192×224 each, pivot96,160. These are renderer exports from `res://tools/desk_finish_v2_geometry.gd`, which inherits the original v1 geometry and oak material pixels. Only contained leg/apron finish RGB changes; every original layer alpha byte is retained.

`manifest.json` records geometry, native bounds/hashes and canonical-shaped render-layer descriptors. It is not a production profile. Keep the eight `.png.import` sidecars with alpha-border filling disabled for exact imported buffers.

Review: [DESK_FINISH_V2_REVIEW.md](../../../../../dev/art-catalogue/DESK_FINISH_V2_REVIEW.md). Old `modular-desk-v1` files and generated materials remain the baseline. No new source generation or runtime registration occurs here.
