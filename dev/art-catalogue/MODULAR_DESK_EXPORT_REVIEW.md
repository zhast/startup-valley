# Modular desk v1 — registered native layer export

**Development raster pipeline complete; furniture art and assembly approval remain absent.** These PNGs are a rendered export of the existing code-native modular desk and selected soft oak material, not newly generated furniture, repainted source pixels or rotated finished rasters. No production profile, active room, character, catalogue status, worker or save was changed.

## Reproduce

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game \
  --script res://tests/test_modular_desk_export.gd -- --preflight
STARTUP_VALLEY_NO_WORKER=1 godot --path game \
  --script res://tools/export_modular_desk_layers.gd
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --import
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game \
  --script res://tests/test_modular_desk_export.gd
```

The exporter creates twelve isolated transparent 192×224 `SubViewport`s: one whole desk, rear-only, and front-only for each explicit N/E/S/W profile. Each instantiates unchanged `modular_desk_geometry.gd` at pivot **(96,160)**, scale one, rotation zero, nearest material sampling and no 2D MSAA. The selected horizontal and vertical soft oak tiles are each native 32×32. No visible background, paper, actor, floor, text or shadow enters an exported layer.

Outputs under `game/tests/fixtures/furniture-calibration/modular-desk-v1/` are eight full-canvas PNGs, `north/east/south/west-rear/front.png`, plus `manifest.json`. The manifest stores actual per-layer ink bounds, alpha/pixel counts, explicit original top/floor/rail/leg rectangles and colors, source file hashes, and canonical-shaped `render_layers` descriptors. The whole-desk renders and contact sheets stay in test evidence, not active furniture.

## Geometry and layer ownership

All bounds below are `[x,y,width,height]` in the full 192×224 PNG. Floor contact is an exclusive pixel boundary; it is not the top-plane edge or a new actor seat socket.

| Direction | Rear ink / opaque pixels | Front ink / opaque pixels | Whole ink / opaque pixels | Near floor contact |
| --- | --- | --- | --- | --- |
| North | [48,112,96,32] / 3,072 | [48,144,96,32] / 720 | [48,112,96,64] / 3,792 | 176 = pivot +16 |
| East | [80,80,32,96] / 3,072 | [80,84,32,124] / 780 | [80,80,32,128] / 3,576 | 208 = pivot +48 |
| South | [52,114,88,30] / 360 | [48,112,96,64] / 4,296 | [48,112,96,64] / 4,296 | 176 = pivot +16 |
| West | [80,80,32,96] / 3,072 | [80,84,32,124] / 780 | [80,80,32,128] / 3,576 | 208 = pivot +48 |

N/S top plane is exactly 96×32 at canvas (48,112); E/W top is 32×96 at (80,80). Floor planes lie 32 screen pixels below them. The top belongs to rear for N/E/W and front for S. East's right dark cable rail and west's left highlighted rail remain on their original front layer, so their front ink bounds extend almost the full tabletop height. The south rear legs are deliberately occluded by the whole front surface when reunited; they are not missing export pixels.

E/W rear PNGs are byte-identical because their independently specified helper profiles genuinely contain the same top and far-support pixels. Their front rails differ and the whole views differ. This is an unchanged code construction, not a rotated or mirrored raster pretending to supply another view.

The canonical-style descriptors use full `region: [0,0,192,224]`, centered sprite `offset: [0,-48]`, and original relative depths −1/+1. Thus `offset − canvas/2 = (−96,−160)`: the declared floor pivot lands exactly on the parent origin. `content_bounds` contains measured ink, not transparent padding. These descriptors are ready for a later reviewed assembly to consume; they intentionally lack runtime-ready flags, occupancy migration, accepted actor poses or approved seat metadata. The geometry helper's obsolete off-grid `seat_reference` placeholders are expressly **not** exported as usable sockets.

## Reconstruction and native review

Every output has binary alpha 0/255, real transparent surroundings, zero hidden RGB in transparent pixels, and no clipping at the canvas edges. For each whole desk, the two independently rendered layers are reconstructed by selecting front RGBA bytes wherever its alpha is 255, otherwise rear bytes. This avoids blend arithmetic and compares **all 43,008 pixels / 172,032 RGBA bytes** against the independently rendered whole desk. The four comparisons cover 172,032 pixels / 688,128 bytes; overlap is correct ordered occlusion, not a disjoint ownership claim.

PNG save/reload is also byte-exact in decoded RGBA. The manifest's reconstruction digest is SHA-256 of decoded RGBA bytes, distinct from compressed PNG hashes. A negative-control test changes a real front pixel in memory and requires the reconstruction comparison to fail. No negative-control pixels are written to disk.

The eight retained `.png.import` sidecars use lossless compression, no mipmaps and `process/fix_alpha_border=false`. An extra consumer check discovered that Godot's default border-fill changes invisible RGB in otherwise transparent pixels. Disabling it only for these new dev layers preserves **the entire imported RGBA buffer**, not just visible ink. Existing source materials and production import settings were not altered. Keep these sidecars with the PNGs when re-exporting or copying the fixture.

Evidence in `game/tests/output/modular-desk-export/`:

- `assembled-native.png`: 768×224, N/E/S/W, each full canvas unscaled.
- `assembled-4x.png`: exact 3072×896 nearest enlargement, not a new asset.
- `layers-native.png`: 768×672; rows whole/rear/front, columns N/E/S/W.
- Four `*-whole.png` 192×224 original whole renders and four `*-whole-4x.png` 768×896 nearest details.
- `results-preflight.json`, `results-headless.json`; export results live in the fixture manifest.

Native assembled and layer sheets plus all four individual 4× whole-desk crops were inspected: fixed straight floor axes, preserved top-plane proportions, consistent upper-left edge lighting, no detached pixels or edge smoothing. The full 3072-wide sheet was resized by the image viewer, so the four individual 768×896 details were also opened without that downsampling. Enlarged evidence makes the remaining art limitation clear: the legs are simple flat outlined bars and the front apron/side rails are austere calibration geometry. The three-color grain is preserved but remains repetitive at enlarged scale. This export does not promote that prototype finish to polished production art, nor does a clean split prove chair/hip/hand occlusion in a complete workstation.

## Final verification

- Rendered exporter: **143 checks, zero failures**. All eight native PNG SHA-256 hashes are identical across two exports; the second run adds the individual 4× diagnostic crops without changing any layer pixels.
- Headless preflight: **71 checks, zero failures**. Final full export/consumer test: **233 checks, zero failures**, including imported texture bytes and the existing canonical layer-reader interface.
- Original geometry tests: **166 checks, zero failures**. Godot import, project validation and `git diff --check` passed.
- Independent Node/ImageMagick decoding compared **688,128 RGBA bytes** across the four rear/front unions and verified their standard decoded-byte SHA-256 digests against the manifest; zero differences.
- The first full test used direct equality between integer dictionaries and JSON-decoded numeric dictionaries, producing twelve false measurement mismatches. It now compares explicit integer fields and geometric rectangles. The eight later import-byte failures were real default border-fill behavior and were fixed in these new dev import sidecars, not waived.

These results establish the export pipeline and preserve the visible art limitations. They are not art-acceptance scores, gameplay input tests, runtime-facing enablement or a completed furniture family.

## Source provenance and limits

Geometry: `game/tools/modular_desk_geometry.gd`. Material inputs: `oak-horizontal-v1-soft.png` and `oak-vertical-v1-soft.png` under the material calibration fixtures. The underlying independently generated 1254×1254 oak masters and soft palette remain unchanged; see [material review](OAK_MATERIAL_REVIEW.md). The manifest hashes those sources, the helper, and exporter before/after execution.

This is a dev export only. Complete seated assembly, walking/behind/in-front tests, accepted lower/upper actor depth, shadows, furniture finish and final runtime integration remain separate gates. No ImageGen request, provider call, source repaint, production registration, commit or push was made by this task.
