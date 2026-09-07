#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
output_dir="$project_root/game/tests/fixtures/material-concepts/terrazzo-v3"
mkdir -p "$output_dir"
magick "$project_root/game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v3.png" \
  -filter point -resize 128x128 -dither None -colors 12 -strip \
  -define png:color-type=2 "$output_dir/cream-terrazzo-floor-v3.png"
# Same global material palette as v2, never edge-specific pixel editing.
magick "$output_dir/cream-terrazzo-floor-v3.png" -dither None \
  -remap "$project_root/dev/art-catalogue/terrazzo-v2-palette.svg" -strip \
  -define png:color-type=2 "$output_dir/cream-terrazzo-floor-v3-normalized.png"
# The source still gives the interior base a different cream from the edge.
# Collapse that one palette entry globally, preserving every fleck pixel.
magick "$output_dir/cream-terrazzo-floor-v3-normalized.png" \
  -fill '#EAE4D7' -opaque '#E3DCCF' -strip -define png:color-type=2 \
  "$output_dir/cream-terrazzo-floor-v3-unified-base.png"
for variant in cream-terrazzo-floor-v3 cream-terrazzo-floor-v3-normalized cream-terrazzo-floor-v3-unified-base; do
  magick -size 384x384 "tile:$output_dir/$variant.png" -strip "$output_dir/$variant-repeat.png"
  magick "$output_dir/$variant.png" -filter point -resize 400% -strip "$output_dir/$variant-4x.png"
done
