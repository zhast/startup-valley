# Native modular architecture kit

These are runtime components, not a furnished-room image. The room model decides
where floor, wall, boundary, corner, window, and doorway cells exist. All output
is displayed at native size with nearest sampling and a top-left pixel anchor.

Rebuild from retained original ImageGen masters:

```sh
bash dev/tools/build_architecture_assets.sh
godot --headless --path game --import
```

No ImageGen request or production dependency is needed for rebuilding. Prompts
and original generated masters are in `game/assets/source/architecture/`.
The script uses development-time ImageMagick and preserves those masters.

## Runtime layout

| File | Native dimensions | Addressing | Alpha |
| --- | --- | --- | --- |
| `floor.png` | 128×128 | 4×4 cells of 32×32, addressed by room x/y modulo 4 | Opaque |
| `wall.png` | 128×96 | 4×3 cells; horizontal repeat, cornice/plaster/wainscot elevation | Opaque |
| `window.png` | 160×96 | One five-by-three-cell window; 2px horizontal and 4px vertical transparent padding | Binary alpha |
| `trim.png` | 128×64 | Row 0: west, east, south, wall mass. Row 1: northwest, northeast, southwest, southeast | Opaque |
| `door.png` | 64×32 | Two-cell open threshold and indigo mat | Opaque |

Do not rotate floor cells randomly, mirror furniture to match architecture, or
scale the architecture to fit a new room. Change the logical cells instead.
Windows show exterior scenery only inside their panes. The doorway contains no
upright wall wings or closed door leaf.

## Exact preparation

All listed crop rectangles use `[x, y, width, height]` in master-image pixels.
Point resampling occurs once during the build. Palette reduction disables
dithering. Output files strip metadata for deterministic bytes.

- **Floor:** entire 1254×1254 master → 128×128. Saturation 52%, brightness −1,
  contrast −20. Normalize opposite edges with a four-pixel symmetric blend,
  first x then y; reduce to at most 32 colors. The quiet desaturated oak lets
  characters and furniture remain visually dominant.
- **Wall:** entire 1024×1536 master → 128×96. Saturation 82%; normalize the
  horizontal seam only. The plaster's subtle stippled pattern is authored
  material, not transparency. Cornice and baseboard must not repeat vertically.
- **Window:** the generated RGB master had a near-white checker exterior.
  Flood-fill only its connected outside matte with 12% fuzz; the dark window
  frame protects the white clouds inside. Erode alpha by one source pixel,
  trim the exterior, normalize to 156×88, threshold alpha at 50%, and center on
  160×96. At most 64 colors. The output has exactly two alpha values (0 and 1)
  and fully transparent outer padding.
- **Straight trim:** west `[490,8,154,428]`; east `[235,8,154,428]`; south
  `[894,218,428,49]`; wall mass `[1337,8,428,428]`. Each becomes 32×32. These
  crops extract the authored cap bands, not the source's framed sample cells,
  and exclude its eight-pixel gutters. West and east use their respective
  generated facing; neither is a mirrored substitute. Normalize the repeating
  axis (west/east y, south x, mass x and y).
- **Corners:** NW `[8,450,160,160]`; NE `[721,450,159,160]`; SW
  `[894,724,160,156]`; SE `[1612,724,154,156]`, each → 32×32. Retain the
  generated right-angle cap bends. Register narrow edge strips to the
  neighboring generated cap/elevation material, then quantize the assembled
  atlas at saturation 82% and at most 32 colors. No full plaster sample is
  repeated along the side boundaries. Mixed corner/elevation joins still
  require in-game visual inspection; a repeating-edge assertion alone does not
  establish that every corner composition looks good.
- **Door:** `[488,554,800,282]` from the generated 1774×887 master → 64×32.
  This keeps the lower open passage, brass threshold, and indigo mat while
  excluding both unwanted upright wall wings. Saturation 72%; at most 32 colors.

## Verification

The builder asserts exact pixel equality (ImageMagick AE = 0) on both repeating
floor edges, the repeating wall edge, and each repeating trim axis. It exits
nonzero if a seam changes. Its temporary directory includes a 2×2 floor-repeat
proof image for inspection.

Two successive complete builds were run and produced identical SHA-256 hashes
for all five PNGs. Native sizes, opaque-vs-binary-alpha format, and window
padding were checked. This verifies deterministic normalization, not final
in-game visual acceptance; inspect the modular-office captures after import.
