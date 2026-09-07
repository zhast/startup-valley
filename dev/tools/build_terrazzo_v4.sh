#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v4.png"
output_dir="$project_root/game/tests/fixtures/material-concepts/terrazzo-v4"
[[ "$(magick identify -format '%wx%h:%[opaque]' "$source_file")" == '1254x1254:True' ]]
mkdir -p "$output_dir"
magick "$source_file" -filter point -resize 128x128 -dither None -colors 12 \
  -strip -define png:color-type=2 "$output_dir/cream-terrazzo-floor-v4.png"
# Retain the raw native export. Same existing global palette, no edge editing.
magick "$output_dir/cream-terrazzo-floor-v4.png" -dither None \
  -remap "$project_root/dev/art-catalogue/terrazzo-v2-palette.svg" -strip \
  -define png:color-type=2 "$output_dir/cream-terrazzo-floor-v4-normalized.png"
# Preserve all other palette entries: global base consolidation, never a border.
magick "$output_dir/cream-terrazzo-floor-v4-normalized.png" \
  -fill '#EAE4D7' -opaque '#E3DCCF' -strip -define png:color-type=2 \
  "$output_dir/cream-terrazzo-floor-v4-unified-base.png"
for variant in cream-terrazzo-floor-v4 cream-terrazzo-floor-v4-normalized cream-terrazzo-floor-v4-unified-base; do
  magick "$output_dir/$variant.png" -filter point -resize 400% -strip "$output_dir/$variant-4x.png"
  magick -size 384x384 "tile:$output_dir/$variant.png" -strip "$output_dir/$variant-repeat.png"
  magick identify -format '%f %wx%h %[channels] colors=%k opaque=%[opaque]\n' "$output_dir/$variant.png"
done
