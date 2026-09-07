#!/usr/bin/env bash
set -euo pipefail

# Mechanical export from the explicitly authorized final alpha extraction.
# Prior v1-v3 RGB sources remain rejected. No local masking or pose repainting.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_path="$project_root/game/assets/source/overnight-20260904/characters/theo-east-v4.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/characters"
scratch_dir="$(mktemp -d -t startup-valley-theo-east)"
channels="$(magick identify -format '%[channels]' "$source_path")"
opaque="$(magick identify -format '%[opaque]' "$source_path")"
printf 'Theo east source: channels=%s fully_opaque=%s\n' "$channels" "$opaque"
if [[ "$opaque" == True ]]; then
  printf '%s\n' 'BLOCKED: genuine source alpha is missing. No fixture or production atlas was written.' >&2
  exit 1
fi
mkdir -p "$output_dir"
source_width="$(magick identify -format '%w' "$source_path")"
source_bounds="$(magick "$source_path" -alpha extract -threshold 50% -format '%@' info:)"
crop_height="${source_bounds#*x}"
crop_height="${crop_height%%+*}"
crop_top="${source_bounds##*+}"

magick "$source_path" -crop "${source_width}x${crop_height}+0+$crop_top" +repage \
  -filter point -resize x68 -channel A -threshold 50% +channel \
  -dither None -colors 48 -unique-colors "$scratch_dir/palette.png"

# Measured real alpha bands, not assumed evenly spaced source cells.
source_left=(71 405 748 1092 1433 1779)
source_span=(284 285 284 284 287 286)
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
  printf 'frame %s: head=%s registration=%s ' "$column" "$head_bounds" "$head_shift"
  magick "$cell_path" -alpha extract -format 'native-bounds=%@\n' info:
done

magick "${cell_files[@]}" +append -strip -define png:color-type=6 \
  "$output_dir/theo-east-seated-v4.png"
magick "$output_dir/theo-east-seated-v4.png" -filter point -resize 400% \
  "$output_dir/theo-east-seated-v4-4x.png"
magick "$output_dir/theo-east-seated-v4.png" -crop 48x80+0+0 +repage \
  -filter point -resize 800% "$output_dir/theo-east-frame0-8x.png"
magick "$output_dir/theo-east-seated-v4.png" -background '#DFD2BB' \
  -alpha remove -alpha off -filter point -resize 400% \
  "$output_dir/theo-east-seated-v4-paper-4x.png"
test "$(magick identify -format '%wx%h' "$output_dir/theo-east-seated-v4.png")" = 288x80
printf 'Staged native and enlarged evidence. Source bounds=%s; shared source height=%s; scratch=%s\n' \
  "$source_bounds" "$crop_height" "$scratch_dir"
