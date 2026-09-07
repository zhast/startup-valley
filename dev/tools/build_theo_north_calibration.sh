#!/usr/bin/env bash
set -euo pipefail

# Mechanical staging export only. No semantic repainting or background masks.
# The generated alpha is preserved and normalized with the existing seated-
# atlas shared scale, palette, head registration and native foot baseline.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_path="$project_root/game/assets/source/overnight-20260904/characters/theo-north-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/characters"
scratch_dir="$(mktemp -d -t startup-valley-theo-north)"
mkdir -p "$output_dir"

source_width="$(magick identify -format '%w' "$source_path")"
source_bounds="$(magick "$source_path" -alpha extract -threshold 50% -format '%@' info:)"
crop_height="${source_bounds#*x}"
crop_height="${crop_height%%+*}"
crop_top="${source_bounds##*+}"
test "$(magick identify -format '%[opaque]' "$source_path")" = False

magick "$source_path" -crop "${source_width}x${crop_height}+0+$crop_top" +repage \
  -filter point -resize x68 -channel A -threshold 50% +channel \
  -dither None -colors 48 -unique-colors "$scratch_dir/palette.png"

# Actual alpha projections, not equal source-width divisions: the sixth figure
# is farther right. All six use one shared vertical crop and resize factor.
source_left=(54 419 772 1138 1492 1881)
source_span=(222 224 244 242 248 242)
cell_files=()
for ((column=0; column<6; column++)); do
  x0="${source_left[$column]}"
  cell_width="${source_span[$column]}"
  cell_path="$scratch_dir/cell-$column.png"
  magick "$source_path" -crop "${cell_width}x${crop_height}+$x0+$crop_top" +repage \
    -filter point -resize x68 -channel A -threshold 50% +channel \
    -dither None -remap "$scratch_dir/palette.png" \
    -background none -gravity south -extent 48x72 \
    -gravity north -extent 48x80 "$cell_path"
  head_bounds="$(magick "$cell_path" -crop 48x28+0+0 +repage -alpha extract -format '%@' info:)"
  head_width="${head_bounds%%x*}"
  head_left="${head_bounds#*+}"
  head_left="${head_left%%+*}"
  head_shift=$((24 - head_left - head_width / 2))
  printf -v shift_geometry '%+d+0' "$head_shift"
  magick "$cell_path" -roll "$shift_geometry" "$cell_path"
  cell_files+=("$cell_path")
  printf 'frame %s: source-x=%s width=%s head=%s registration=%s ' \
    "$column" "$x0" "$cell_width" "$head_bounds" "$head_shift"
  magick "$cell_path" -alpha extract -format 'native-bounds=%@\n' info:
done

magick "${cell_files[@]}" +append -strip -define png:color-type=6 \
  "$output_dir/theo-north-seated-v2.png"
magick "$output_dir/theo-north-seated-v2.png" -filter point -resize 400% \
  "$output_dir/theo-north-seated-v2-4x.png"
test "$(magick identify -format '%wx%h' "$output_dir/theo-north-seated-v2.png")" = 288x80
printf 'Staged native and 4x atlas. Source bounds=%s; shared source height=%s; scratch=%s\n' \
  "$source_bounds" "$crop_height" "$scratch_dir"
