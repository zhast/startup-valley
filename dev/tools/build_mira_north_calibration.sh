#!/usr/bin/env bash
set -euo pipefail

# Mechanical staging export only. Reuses build_workstation_assets.sh's shared
# row scale/palette/head registration; never paints or invents semantic pixels.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_path="$project_root/game/assets/source/overnight-20260904/characters/mira-north-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/characters"
scratch_dir="$(mktemp -d -t startup-valley-mira-north)"
mkdir -p "$output_dir"

source_width="$(magick identify -format '%w' "$source_path")"
source_bounds="$(magick "$source_path" -alpha extract -threshold 50% -format '%@' info:)"
crop_height="${source_bounds#*x}"
crop_height="${crop_height%%+*}"
crop_top="${source_bounds##*+}"

magick "$source_path" -crop "${source_width}x${crop_height}+0+$crop_top" +repage \
  -filter point -resize x68 -channel A -threshold 50% +channel \
  -dither None -colors 48 -unique-colors "$scratch_dir/palette.png"

cell_files=()
# Alpha-projection inspection found six separate figures, but not equal source
# cells. Use their measured horizontal bands so the sixth forearm is not cut by
# a naive2170/6 partition. Vertical crop and scale remain identical throughout.
source_left=(78 408 745 1103 1438 1783)
source_span=(222 220 262 252 264 261)
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
  "$output_dir/mira-north-seated-v2.png"
magick "$output_dir/mira-north-seated-v2.png" -filter point -resize 400% \
  "$output_dir/mira-north-seated-v2-4x.png"
printf 'Staged native and4x atlas. Sourcebounds=%s; sharedsourceheight=%s; scratch=%s\n' "$source_bounds" "$crop_height" "$scratch_dir"
