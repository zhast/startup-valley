# Broadleaf planter — rejected raster sources

September 6, 2026. Both original built-in ImageGen outputs are retained byte for
byte. Neither is a native asset, alpha cutout, approved view, or runtime binding.

| Source | Measured size | Channels | Finding |
| --- | --- | --- | --- |
| `plants/broadleaf-planter-fourway-v1.png` | 948×1659 | RGB | Painted checkerboard instead of transparency; dimensions do not match the requested 1024×1792 four-cell sheet. |
| `plants/broadleaf-planter-fourway-v2.png` | 949×1658 | RGB | Alpha-only edit still paints a checkerboard, changes the canvas by one pixel on both axes, and redraws the plant rather than preserving it. |

Both files live below `game/assets/source/overnight-20260904/`. Exact SHA-256
values, dimensions and prompt paths are in the source inventory in `furniture.json`.

The batch used one initial request and one targeted retry out of the permitted
three retries. Its budget is **not exhausted**. Equivalent alpha-only retries are
not justified by these two results. There was no separately billed fallback,
purchase, reset, background keying, masking, pixel cleanup or runtime export.

The useful identity is a small original broadleaf plant in an off-white ceramic
pot with a restrained indigo inlay. A separately authored editable code-native
candidate may use that identity as a design reference. It must establish its own
native geometry, organic silhouette, true alpha, four views, fixed screen-space
lighting, pot collision and actual-room layering. That independent construction
does not rehabilitate either failed raster source. Until reviewed, all four
family slots remain unfinished.
