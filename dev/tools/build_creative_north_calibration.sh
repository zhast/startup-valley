#!/usr/bin/env bash
set -euo pipefail

# Source-faithful mechanical normalization only. Complete objects use uniform
# point scaling; no raster rotation, mirror, painted alpha or semantic repair.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/roles/creative-north-v1.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/roles"
scratch_dir="$(mktemp -d -t startup-valley-creative-north)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque creative toolkit source\n' >&2
  exit 1
fi
magick -background none "$project_root/dev/art-catalogue/role-material-palette.svg" \
  "$scratch_dir/palette.png"
for component in tablet swatches camera; do
  case "$component" in
    tablet) rectangle=707x455+72+240; width=24; origin=+83+127 ;;
    swatches) rectangle=336x348+837+336; width=12; origin=+58+128 ;;
    camera) rectangle=378x369+1219+273; width=12; origin=+124+119 ;;
  esac
  magick "$source_file" -channel A -threshold 50% +channel \
    -crop "$rectangle" +repage -filter point -resize "${width}x" \
    -channel A -threshold 50% +channel "$scratch_dir/$component-native.png"
  magick "$scratch_dir/$component-native.png" -alpha extract "$scratch_dir/$component-alpha.png"
  magick "$scratch_dir/$component-native.png" -alpha off -dither None \
    -remap "$scratch_dir/palette.png" "$scratch_dir/$component-alpha.png" \
    -alpha off -compose CopyOpacity -composite -strip -define png:color-type=6 \
    "$scratch_dir/$component-palette.png"
  if ! magick compare -metric AE "$scratch_dir/$component-alpha.png" \
    \( "$scratch_dir/$component-palette.png" -alpha extract \) null: \
    2> "$scratch_dir/$component-alpha-difference.txt"; then
    printf 'Palette remap changed %s alpha pixels\n' "$component" >&2
    exit 1
  fi
  magick -size 192x224 canvas:none "$scratch_dir/$component-palette.png" \
    -geometry "$origin" -compose Over -composite -strip -define png:color-type=6 \
    "$output_dir/creative-north-v1-$component.png"
done
magick "$output_dir/creative-north-v1-tablet.png" \
  "$output_dir/creative-north-v1-swatches.png" -compose Over -composite \
  "$output_dir/creative-north-v1-camera.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/creative-north-v1.png"
magick "$output_dir/creative-north-v1.png" -filter point -resize 400% \
  "$output_dir/creative-north-v1-4x.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/creative-north-v1.png" \
  -compose Over -composite -filter point -resize 400% \
  "$output_dir/creative-north-v1-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
  "$output_dir/creative-north-v1.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
