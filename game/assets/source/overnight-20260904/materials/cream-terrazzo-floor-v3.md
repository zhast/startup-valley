# Terrazzo material — targeted retry 2: remove repeated quiet bands

Generated 2026-09-04 09:45–09:46 UTC. V2's globally normalized edges pass exactly,
but actual-room review shows wide low-speckle bands every128px. This targeted
art edit addresses density distribution, not the tested room/geometry/UI.
Input: V2 normalized native plate at nearest4×. Initial + two targeted tries
completed; one targeted attempt remains, not automatically required.

Original `exec-22a32c0b-702f-412f-a9e8-7b9912a70caa.png`, preserved alongside
this prompt. Builder `dev/tools/build_terrazzo_v3.sh` retains the uniform128²
12-color-budget export (11 used), shared palette remap (8 used), and a global
base-color collapse (7 used). Exactly13,084 pixels map #E3DCCF→#EAE4D7;
no other pixels change in that last operation. All versions stay separate.
Exact edges pass, but actual-room review finds repeated diagonal scratches
and uneven density: visual score2.33, NOT approved. See
`dev/art-catalogue/TERRAZZO_V3_REVIEW.md`. No further call is queued.

Use case: precise-object-edit. Image1 is the edit target: a128x128-native opaque Startup Valley terrazzo material plate, shown at4x. Correct ONLY its low-speckle border band. The current quiet margin becomes an obvious grid when tiled; remove that broad margin by carrying the SAME sparse fleck density and cream variation right up to one native pixel from all four edges. Uniform density across the whole field, no centered composition, no vignette, no frame, no fade-out near edges. Only the single outermost native pixel row/column stays one flat cream color #EAE4D7, identical on every edge/corner; there must NOT be a2/4/8px blank perimeter. Preserve the existing cream base, small grey/cool/terracotta flecks, calm contrast, crisp pixel clusters, native128x128 square size, opaque background and limited11-color character. Neighboring interior flecks should approach the one-pixel seam on many locations, spread irregularly to avoid repeated bands, but never cross the outermost pixel. No other art, text, furniture, wall, floor-grid, grout, shadow, checkerboard, alpha or photographic noise. This is one seamless original material tile for native1x game rendering. Return uniform crisp enlargement only.
