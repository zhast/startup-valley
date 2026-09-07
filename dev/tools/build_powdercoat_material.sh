#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/materials/charcoal-powdercoat-v1.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/materials"
scratch_dir="$(mktemp -d -t startup-valley-powdercoat)"
mkdir -p "$output_dir"
magick -background none "$project_root/dev/art-catalogue/powdercoat-material-palette.svg" "$scratch_dir/palette.png"
magick "$source_file" -filter point -resize 32x32 \
  -dither None -remap "$scratch_dir/palette.png" -strip \
  -define png:color-type=2 "$output_dir/charcoal-powdercoat-v1.png"
magick -size 96x96 "tile:$output_dir/charcoal-powdercoat-v1.png" \
  -filter point -resize 800% -strip "$output_dir/charcoal-powdercoat-v1-repeat-8x.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
