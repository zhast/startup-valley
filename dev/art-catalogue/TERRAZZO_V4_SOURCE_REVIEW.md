# Terrazzo V4 — final source/native review

2026-09-04. Source 118 is a new, separately dated study, outside the frozen 117-source catalogue. **Staged for an actual-room comparison, not approved.** Production still uses wood. The existing series is closed: one initial request plus three targeted retries; no further requests or renamed continuation.

## Source and deterministic export

The unchanged [original](../../game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v4.png) is 1254×1254 opaque RGB, SHA256 `9527d36fd99e864e14cba0589b4b3bb74e5c836094b96d59a01f80cb07de5953`. [Exact prompt and provenance](../../game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v4.md) retain the original provider identifier and exhausted retry history.

[Builder](../tools/build_terrazzo_v4.sh) runs full-source uniform point sampling to 128×128 with no dithering and a 12-color ceiling. It preserves that raw native image, then separately remaps to the [existing V2 palette](terrazzo-v2-palette.svg), and separately consolidates the two cream base colors globally. No crop, nonuniform stretching, edge-specific painting, mirrored tile, blended seam, or changed source is involved.

| Export | Actual colors | Base pixels | Opposite edges X/Y |
|---|---:|---:|---:|
| [Raw native](../../game/tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4.png) | 11 | 14,813 `#E6DED2` | 1 / 1 |
| [V2-palette normalized](../../game/tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4-normalized.png) | 8 | 14,813 `#E3DCCF` | 1 / 1 |
| [Unified-base candidate](../../game/tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4-unified-base.png) | 7 | 15,935 `#EAE4D7` | 0 / 0 |

All three are opaque 128×128 RGB: 16,384 opaque pixels, no partial alpha or hidden RGB. The final global `#E3DCCF` → `#EAE4D7` substitution changes exactly 14,813 pixels; **zero other pixels change**. It merges the pale perimeter into the base without targeting any border or changing chip positions.

Unified-base SHA256: `ed48b4cd1a1605e80a28d42f75a92e3059bb5abfeb37b162f1800d7469a865fc`; decoded RGBA SHA256: `a9dc513c33a47f0daecc72e9ef2ce0b0a8e476c0b3c67d1cfd0d4548b02a6e69`.

## Native visual findings

Inspected the original, raw and unified native 4× plates, and the [3×3 repeat at native pixel scale](../../game/tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4-unified-base-repeat.png). [Nearest 4× candidate](../../game/tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4-unified-base-4x.png).

- V4 replaces the conspicuous long V3 scratch chains with much shorter chip clusters. At native size it reads as sparse terrazzo, not stitching. Small repeated diagonal pairs remain; the tile cannot be called pattern-free.
- The unmodified raw export still has a pale perimeter and a different central base. Raw and palette-only exports are diagnostic alternatives, **not** the recommended room comparison. Global base consolidation visibly removes that rectangular wash.
- The unified candidate has 449 nonbase pixels (2.7405%). Top eight rows: 2.7344%; central 112×112: 2.7663%; eight-pixel perimeter band: 2.6563%. The earlier broad empty-border density defect is substantially reduced. This says nothing about exact chip distribution or the visibility of repeated motifs across a full room.
- The exact same motifs recur every 128 pixels. The standalone repeat is calmer than the previous failed candidates, but brightness against the office, actors, and notebook must be judged in actual GameMain. No complete-game polish score or approval is awarded here.

## Verification and handoff

Ran the builder twice: all **9 PNG derivatives byte-identical**, source unchanged. Each version keeps a native tile, nearest 4× view, and 384×384 exact 3×3 repeat. [Machine-readable measurements](../../game/tests/fixtures/material-concepts/terrazzo-v4/source-review.json) include all three native hashes, decoded-buffer facts, full palettes, density definitions, opposite-edge mismatch counts, and the exact global substitution count.

Rebuild: `bash dev/tools/build_terrazzo_v4.sh`.

Handed the **unified-base** native path to the separate nine-screen baseline/V3/V4 actual-room study. That study and its conclusions were pending at this report's freeze. No Godot renderer, provider, real worker, save, production default, old material asset, or frozen catalogue was changed by this export task.
