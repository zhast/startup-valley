#!/usr/bin/env bash
set -euo pipefail

# Native material normalization only. Geometry and edge lighting belong to
# separate code-native game layers; neither material is a rotated prop image.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/overnight-20260904/materials"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/materials"
scratch_dir="$(mktemp -d -t startup-valley-oak-materials)"
mkdir -p "$output_dir"
magick "$project_root/dev/art-catalogue/oak-material-palette.svg" "$scratch_dir/palette.png"
magick "$project_root/dev/art-catalogue/oak-material-palette-soft.svg" "$scratch_dir/palette-soft.png"
for direction in horizontal vertical; do
  source_path="$source_dir/oak-${direction}-v1.png"
  read -r source_width source_height < <(magick identify -format '%w %h\n' "$source_path")
  if [[ "$source_width" != "$source_height" ]]; then
    printf 'Reject nonsquare material, no arbitrary stretch: %s\n' "$source_path" >&2
    exit 1
  fi
  if [[ "$(magick identify -format '%[opaque]' "$source_path")" != "True" ]]; then
    printf 'Reject transparent material: %s\n' "$source_path" >&2
    exit 1
  fi
  magick "$source_path" -filter point -resize 32x32 -dither None \
    -remap "$scratch_dir/palette.png" -strip -define png:color-type=2 \
    "$output_dir/oak-${direction}-v1.png"
  magick -size 96x96 "tile:$output_dir/oak-${direction}-v1.png" \
    -filter point -resize 400% "$output_dir/oak-${direction}-repeat-4x.png"
  magick identify -format '%f %wx%h %[channels] colors=%k opaque=%[opaque]\n' \
    "$output_dir/oak-${direction}-v1.png"
  # Same pixels/pattern, reduced palette contrast for a native room comparison.
  magick "$output_dir/oak-${direction}-v1.png" -dither None \
    -remap "$scratch_dir/palette-soft.png" -strip -define png:color-type=2 \
    "$output_dir/oak-${direction}-v1-soft.png"
done
printf 'Intermediate export retained: %s\n' "$scratch_dir"
