#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/coffee-service-north-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-coffee-north)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque north coffee source\n' >&2
  exit 1
fi
magick "$source_file" -channel A -threshold 50% +channel \
  -dither None -colors 48 "$scratch_dir/source.png"
for component in espresso grinder mug plant; do
  case "$component" in
    espresso) rectangle=355x555+197+155; geometry=x44; origin=+107+129 ;;
    grinder) rectangle=195x474+702+202; geometry=x30; origin=+86+136 ;;
    mug) rectangle=208x206+1009+440; geometry=10x; origin=+72+143 ;;
    plant) rectangle=246x403+1330+253; geometry=x24; origin=+55+147 ;;
  esac
  magick "$scratch_dir/source.png" -crop "$rectangle" +repage \
    -filter point -resize "$geometry" -channel A -threshold 50% +channel \
    "$scratch_dir/$component.png"
  magick -size 192x256 canvas:none "$scratch_dir/$component.png" \
    -geometry "$origin" -compose Over -composite -strip \
    -define png:color-type=6 "$output_dir/coffee-service-north-v2-$component.png"
done
magick "$output_dir/coffee-service-north-v2-espresso.png" \
  "$output_dir/coffee-service-north-v2-grinder.png" -compose Over -composite \
  "$output_dir/coffee-service-north-v2-mug.png" -compose Over -composite \
  "$output_dir/coffee-service-north-v2-plant.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/coffee-service-north-v2.png"
magick -size 192x256 canvas:'#F1F1F1' "$output_dir/coffee-service-north-v2.png" \
  -compose Over -composite -filter point -resize 400% -strip \
  "$output_dir/coffee-service-north-v2-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
  "$output_dir/coffee-service-north-v2.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
