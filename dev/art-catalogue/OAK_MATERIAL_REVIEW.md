# Oak materials — staged native texture tiles

Generated06:38–06:39 UTC with built-in ImageGen as two independent opaque material tiles. They are not desk sprites and do not encode furniture geometry or perspective. Fixed-camera edge lighting remains in the separate native geometry prototype.

Sources under `game/assets/source/overnight-20260904/materials/`: `oak-horizontal-v1.png` and `oak-vertical-v1.png`, both1254×1254 RGB. Horizontal original: `exec-eb6bde2e-5102-4e9b-8584-3aec2510ebd9.png`; vertical original: `exec-5e769b8e-0a2d-45a2-a0ff-f09fe283f588.png`, in the root thread's generated-images directory. Exact prompts are the matching `prompts/material-oak-*-v1.md` files.

`bash dev/tools/build_oak_materials.sh` verifies opaque square sources, uses nearest export to32×32 and a shared seven-color palette from `oak-material-palette.svg`. Each actual tile uses five palette colors. No raster rotation, mirroring, object reshaping or runtime downscaling. Both are intentionally opaque because they fill a clipped surface, not surround a prop.

Outputs: `game/tests/fixtures/furniture-calibration/materials/oak-horizontal-v1.png` and `oak-vertical-v1.png`; each has a `-repeat-4x.png` proof showing3×3 exact repeats enlarged4×. Main inspected both proofs. The native grain is restrained enough to test; repetition is visible enlarged, so do not claim a final seamless-material approval without the actual desk comparison. No blank seams or background are present.

Status: native material candidate. Not furniture approval, runtime registration or a replacement of the approved room. Next gate is100% desk-view review with the two matched material tiles, then functional/layered seat tests. Generated textures supply the surface; code supplies exact native top/leg/anchor geometry.

## Native room comparison —06:48 UTC

`game/tools/capture_desk_material_room.gd` renders both material treatments in the existing approved room at1280×720, with native48×80 founder scale. `game/tests/output/desk-material-room/two-palettes-native.png` shows the original five-used-color exports above and a three-color midtone normalization below. The latter retains the generated grain positions, using `oak-material-palette-soft.svg` and the same point export; no semantic texture edit or rotation occurred.

The main agent inspected the native capture and prefers the lower-contrast soft treatment for subsequent staged desk assemblies: it competes less with the floor and the small actors. Outputs are `oak-horizontal-v1-soft.png` and `oak-vertical-v1-soft.png`. Geometry remains exact in both rows, but leg finish and the complete seated/layered assembly still need review. This is a material-selection checkpoint, not approval of a new production desk or room skin. Import and the worker-disabled room capture exited0.
