#!/usr/bin/env bash
set -euo pipefail

# Root-authorized E4 follow-up: independently reusable whole objects receive
# uniform point scales to a native physical family size. No independent-axis
# stretching, turns, mirroring, repainting, or manufactured transparency.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/computer-east-v4.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-computer-east-v4)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque east-v4 source\n' >&2
  exit 1
fi
magick "$source_file" -channel A -threshold 50% +channel \
  -dither None -colors 32 "$scratch_dir/source.png"

# Actual alpha50% bounds. Source object ratios do not define a universal world
# unit. Keep each complete object's aspect ratio; normalize monitor/stand30high,
# keyboard31long and mouse6high. E4 keyboard is narrower than north's11px depth.
for component in monitor keyboard mouse; do
  case "$component" in
    monitor) rectangle=345x830+709+165; height=30; origin=+99+108 ;;
    keyboard) rectangle=229x816+266+186; height=31; origin=+81+115 ;;
    mouse) rectangle=194x128+280+1039; height=6; origin=+81+149 ;;
  esac
  magick "$scratch_dir/source.png" -crop "$rectangle" +repage \
    -filter point -resize "x$height" -channel A -threshold 50% +channel \
    "$scratch_dir/$component.png"
  magick -size 192x224 canvas:none "$scratch_dir/$component.png" \
    -geometry "$origin" -compose Over -composite -strip \
    -define png:color-type=6 "$output_dir/computer-east-v4-$component.png"
done
magick "$output_dir/computer-east-v4-monitor.png" \
  "$output_dir/computer-east-v4-keyboard.png" -compose Over -composite \
  "$output_dir/computer-east-v4-mouse.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/computer-east-v4.png"
magick "$output_dir/computer-east-v4.png" -filter point -resize 400% \
  "$output_dir/computer-east-v4-4x.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/computer-east-v4.png" \
  -compose Over -composite -filter point -resize 400% \
  "$output_dir/computer-east-v4-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque]\n' \
  "$output_dir/computer-east-v4.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
