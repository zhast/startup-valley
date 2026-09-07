#!/usr/bin/env bash
set -euo pipefail
# Mechanical point sampling and old three-color remap only; originals untouched.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/overnight-20260904/materials"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/materials-v2"
scratch_dir="$(mktemp -d -t startup-valley-oak-v2)"
mkdir -p "$output_dir"
magick "$project_root/dev/art-catalogue/oak-material-palette-soft.svg" "$scratch_dir/palette.png"
for direction in horizontal vertical; do
  source_path="$source_dir/oak-${direction}-v2.png"
  [[ "$(magick identify -format '%wx%h:%[opaque]' "$source_path")" == '1254x1254:True' ]]
  magick "$source_path" -filter point -resize 32x32 -dither None \
    -remap "$scratch_dir/palette.png" -strip -define png:color-type=2 \
    "$output_dir/oak-${direction}-v2.png"
  magick -size 96x96 "tile:$output_dir/oak-${direction}-v2.png" \
    -filter point -resize 400% -strip "$output_dir/oak-${direction}-repeat-4x.png"
  magick identify -format '%f %wx%h %[channels] colors=%k opaque=%[opaque]\n' \
    "$output_dir/oak-${direction}-v2.png"
done
