#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v2.png"
output_dir="$project_root/game/tests/fixtures/material-concepts/terrazzo-v2"
mkdir -p "$output_dir"
# Uniform nearest normalization and a bounded palette only. No edge painting.
magick "$source_file" -filter point -resize 128x128 \
  -dither None -colors 12 -strip -define png:color-type=2 \
  "$output_dir/cream-terrazzo-floor-v2.png"
magick -size 384x384 "tile:$output_dir/cream-terrazzo-floor-v2.png" -strip \
  "$output_dir/cream-terrazzo-floor-v2-repeat.png"
magick "$output_dir/cream-terrazzo-floor-v2.png" -filter point -resize 400% -strip \
  "$output_dir/cream-terrazzo-floor-v2-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
  "$output_dir/cream-terrazzo-floor-v2.png"
# Global palette normalization merges the almost identical #EBE4D5/#EAE4D7
# cream pair everywhere, not only at the boundary. Preserve the 12-color export.
magick "$output_dir/cream-terrazzo-floor-v2.png" -dither None \
  -remap "$project_root/dev/art-catalogue/terrazzo-v2-palette.svg" \
  -strip -define png:color-type=2 "$output_dir/cream-terrazzo-floor-v2-normalized.png"
magick -size 384x384 "tile:$output_dir/cream-terrazzo-floor-v2-normalized.png" -strip \
  "$output_dir/cream-terrazzo-floor-v2-normalized-repeat.png"
magick "$output_dir/cream-terrazzo-floor-v2-normalized.png" -filter point -resize 400% -strip \
  "$output_dir/cream-terrazzo-floor-v2-normalized-4x.png"
