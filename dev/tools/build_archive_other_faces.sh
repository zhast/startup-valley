#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/overnight-20260904/kits"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-archive-faces)"
mkdir -p "$output_dir"
magick -background none "$project_root/dev/art-catalogue/archive-material-palette.svg" "$scratch_dir/palette.png"
for side in north-back east-locker-end west-display-end; do
  case "$side" in
    north-back) width=88; height=56; y=0; registration=+52+180 ;;
    *) width=24; height=50; y=3; registration=+84+212 ;;
  esac
  magick "$source_dir/archive-service-$side-v1.png" \
    -filter point -resize "${width}x" -dither None -remap "$scratch_dir/palette.png" \
    -strip "$scratch_dir/$side.png"
  if [[ "$(magick identify -format '%wx%h' "$scratch_dir/$side.png")" != "${width}x${height}" ]]; then
    printf 'Actual %s face ratio changed\n' "$side" >&2
    exit 1
  fi
  magick -size "${width}x56" canvas:none "$scratch_dir/$side.png" \
    -geometry "+0+$y" -compose Over -composite -strip -define png:color-type=6 \
    "$output_dir/archive-service-$side-v1.png"
  magick -size 192x288 canvas:none "$output_dir/archive-service-$side-v1.png" \
    -geometry "$registration" -compose Over -composite -strip -define png:color-type=6 \
    "$output_dir/archive-service-$side-v1-registered.png"
  magick -size "${width}x56" canvas:'#383833' "$output_dir/archive-service-$side-v1.png" \
    -compose Over -composite -filter point -resize 800% -strip \
    "$output_dir/archive-service-$side-v1-8x.png"
done
printf 'Intermediate export retained: %s\n' "$scratch_dir"
