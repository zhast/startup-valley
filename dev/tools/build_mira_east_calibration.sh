#!/usr/bin/env bash
set -euo pipefail

# Mechanical staging export from the existing seated-asset workflow. No raster
# pose painting, rotation, mirroring, runtime registration or production writes.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_path="$project_root/game/assets/source/overnight-20260904/characters/mira-east-v3.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/characters"
scratch_dir="$(mktemp -d -t startup-valley-mira-east)"
mkdir -p "$output_dir"
source_width="$(magick identify -format '%w' "$source_path")"
source_bounds="$(magick "$source_path" -alpha extract -threshold 50% -format '%@' info:)"
crop_height="${source_bounds#*x}"
crop_height="${crop_height%%+*}"
crop_top="${source_bounds##*+}"

magick "$source_path" -crop "${source_width}x${crop_height}+0+$crop_top" +repage \
  -filter point -resize x68 -channel A -threshold 50% +channel \
  -dither None -colors 48 -unique-colors "$scratch_dir/palette.png"

# Measured contiguous alpha-column bands, not presumed source-width/6 cells.
source_left=(55 330 604 896 1204 1500)
source_span=(258 257 257 258 257 255)
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
  printf 'frame %s: head=%s horizontal-registration=%s\n' "$column" "$head_bounds" "$head_shift"
done

magick "${cell_files[@]}" +append -strip -define png:color-type=6 \
  "$output_dir/mira-east-seated-v3.png"
magick "$output_dir/mira-east-seated-v3.png" -filter point -resize 400% \
  "$output_dir/mira-east-seated-v3-4x.png"
magick "$output_dir/mira-east-seated-v3.png" -crop 48x80+0+0 +repage \
  -filter point -resize 800% "$output_dir/mira-east-frame0-8x.png"
printf 'Staged native and 4x atlas. Source bounds=%s; shared source height=%s; scratch=%s\n' "$source_bounds" "$crop_height" "$scratch_dir"
