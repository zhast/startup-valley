#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/computer-south-peripherals-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-south-peripherals)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque south peripheral source\n' >&2
  exit 1
fi
magick "$source_file" -channel A -threshold 50% +channel \
  -dither None -colors 32 "$scratch_dir/source.png"
for component in keyboard mouse; do
  case "$component" in
    keyboard) rectangle=1197x485+156+159; geometry=31x; origin=+80+112 ;;
    mouse) rectangle=272x429+1534+181; geometry=x8; origin=+69+113 ;;
  esac
  # One uniform native export per complete independent object; no stretching,
  # reflection, angle correction, repaint or synthetic alpha.
  magick "$scratch_dir/source.png" -crop "$rectangle" +repage \
    -filter point -resize "$geometry" -channel A -threshold 50% +channel \
    "$scratch_dir/$component.png"
  magick -size 192x224 canvas:none "$scratch_dir/$component.png" \
    -geometry "$origin" -compose Over -composite -strip \
    -define png:color-type=6 "$output_dir/computer-south-peripherals-v2-$component.png"
done
magick "$output_dir/computer-south-peripherals-v2-keyboard.png" \
  "$output_dir/computer-south-peripherals-v2-mouse.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/computer-south-peripherals-v2.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/computer-south-peripherals-v2.png" \
  -compose Over -composite -filter point -resize 400% \
  "$output_dir/computer-south-peripherals-v2-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque]\n' \
  "$output_dir/computer-south-peripherals-v2.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
