# Low bookshelf South insert — strict target rejected, measured fit staged

2026-09-04. After the frozen116-source catalogue. Root's initial original117 is preserved; this task made no duplicate ImageGen request or retry. **The requested88×24 source target failed.** A separately named70×24 source-preserving native study is available, not yet approved for geometry or runtime.

Contract: [LOW_BOOKSHELF_CONTRACT.md](LOW_BOOKSHELF_CONTRACT.md). Exact initial prompt: [low-bookshelf-south-insert-v1.md](../../game/assets/source/overnight-20260904/kits/low-bookshelf-south-insert-v1.md).

[Strict builder](../tools/build_low_bookshelf_insert.sh) preserves the complete original and requires intentional opacity. The actual2140×735 RGB source has aspect2.9116, not target11:3 (3.6667). Width-only point normalization produces88×30. The builder correctly exited1 before creating output; it did not crop, stretch, pad or fabricate alpha to claim success.

Rejected-target deliverables **remain absent**:

- `game/tests/fixtures/furniture-calibration/low-bookshelf-v1/books-bin-front.png`: opaque88×24 flat front insert. Reserved name avoids the geometry owner's full192×224 `south-insert.png` layer.
- `game/tests/fixtures/furniture-calibration/low-bookshelf-v1/books-bin-front-8x.png`: exact nearest8× inspection copy.

## Separate measured-fit diagnostic

Root authorized the [new measured-fit builder](../tools/build_low_bookshelf_measured_fit.sh), not a retry disguised under a new name. It uniformly point-samples the **entire** original to height24, then globally limits colors to24 without dithering. Ideal width69.877551 rounds to70 at native pixel boundaries:0.1752% aspect quantization, no nonuniform scale operation. No background crop, keying, padding or extension occurs.

- [Native70×24](../../game/tests/fixtures/furniture-calibration/low-bookshelf-v1/books-row-native.png): RGB, all1680 pixels opaque,24 colors, no alpha-padding claims.
- [Exact nearest8×](../../game/tests/fixtures/furniture-calibration/low-bookshelf-v1/books-row-native-8x.png):560×192 inspection only.
- Native PNG SHA256 `edbeaee3cdbeb05d5e9b50c6ac569efb34bed75ab42cf244ce7148803e72400e`; decoded RGBA `9882029d2be7f58a2af383fb50651e5d2b833f9de0933a9a3f965f710132576b`.
- 8× PNG SHA256 `5986d51739b065c479a6d81186828331b7bbfa720f94f35653588669f146cfd1`.
- [Retained original](../../game/assets/source/overnight-20260904/kits/low-bookshelf-south-insert-v1.png) SHA256 `100ad230f3f1dc8c0534b09b61ed87f6abc0c69daf310a0de95c478064131379`.

Both exported PNGs rebuild byte-identically; original SHA remains unchanged and rejected88px output remains absent. No Godot renderer/import was used for this flat-source review.

Dominant dark/background is `#1C1C1A` (RGB28,28,26),762 of1680 pixels. Secondary source darks `#201F1C` and `#20201C` occupy40 and54 pixels respectively; the retained background is not perfectly uniform or exactly the prompt's `#282622`. These are actual globally quantized source colors, not a keyed transparency mask. Company received this measurement to judge the existing bay's side margins in the actual room; no source fill or edge recoloring is performed here.

At native1×, upright colored books, the short horizontal stack and off-white bin remain distinguishable. The tallest spines retain an uneven height rhythm. Most thin source bands and label shapes disappear or become simple marks; the bin's dark handle becomes a two-pixel recess rather than the detailed source rectangle. These reductions are honest native sampling, not missing drawn furniture. The large dark gap above the shorter stack/bin is still in the source and is not cropped out. The24-color palette is appropriate to this tiny decor, but nearby body/wood contrast and final shelf identity need the actual-room composite.

## Geometry decision remains separate

The company-owned contract's opaque dark bay remains88×24 at local(-44,-12), full192×224 coordinate(52,148), pivot(96,160). Root independently viewed both native and8× exports and approved **this bounded actual-room composition study**: center the unchanged70px insert with9px inset on each side, local(-35,-12), full(61,148), leaving the existing geometry's dark bay visible. This is not new background pixels in the source, a successful88px request, a runtime resize or production acceptance. Company owns the geometry change and subsequent native room proof.

No cabinet layer, top/floor/feet, North/East/West drawing, production profile, service, new actor or catalogue slot was authored. North and side faces must not borrow physically hidden South books. The initial request remains one source, zero targeted retries; original117 stays outside the frozen116-source catalogue until a later explicit refresh.
