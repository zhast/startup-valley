#!/usr/bin/env bash
set -euo pipefail

# Development candidate only. One common crop/nearest scale and palette; no
# per-object resizing, rotation, mirroring, repainting, or invented alpha mask.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/computer-east-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-computer-east)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque east computer source\n' >&2
  exit 1
fi

# Actual alpha50% components: monitor309x768@(692,260), keyboard259x512
# @(239,520), mouse238x150@(235,1061). Their union is766x951@(235,260).
# One30px-wide normalization makes the monitor+stand approximately30px tall,
# matching the north monitor's full30px height. The existing source keyboard
# becomes shorter than north's31x11 keyboard: this is NOT repaired by stretching.
magick "$source_file" -channel A -threshold 50% +channel \
  -crop 766x951+235+260 +repage -filter point -resize 30x \
  -channel A -threshold 50% +channel -dither None -colors 32 \
  "$scratch_dir/kit.png"
magick -size 192x224 canvas:none "$scratch_dir/kit.png" \
  -geometry +81+108 -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/computer-east-v2.png"

# Native transparent gutters separate these actual independent objects. Keep
# each layer on the identical192x224 registration; extract, never trim-to-center.
for component in monitor keyboard mouse; do
  case "$component" in
    monitor) rectangle=14x31+98+108; origin=+98+108 ;;
    keyboard) rectangle=12x21+81+117; origin=+81+117 ;;
    mouse) rectangle=12x8+81+138; origin=+81+138 ;;
  esac
  magick "$output_dir/computer-east-v2.png" -crop "$rectangle" +repage \
    "$scratch_dir/$component.png"
  magick -size 192x224 canvas:none "$scratch_dir/$component.png" \
    -geometry "$origin" -compose Over -composite -strip \
    -define png:color-type=6 "$output_dir/computer-east-v2-$component.png"
done

magick "$output_dir/computer-east-v2-monitor.png" \
  "$output_dir/computer-east-v2-keyboard.png" -compose Over -composite \
  "$output_dir/computer-east-v2-mouse.png" -compose Over -composite \
  "$scratch_dir/recombined.png"
if ! magick compare -metric AE "$output_dir/computer-east-v2.png" \
  "$scratch_dir/recombined.png" null: 2> "$scratch_dir/difference.txt"; then
  printf 'Component extraction lost or shifted native pixels\n' >&2
  exit 1
fi
magick "$output_dir/computer-east-v2.png" -filter point -resize 400% \
  "$output_dir/computer-east-v2-4x.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/computer-east-v2.png" \
  -compose Over -composite -filter point -resize 400% \
  "$output_dir/computer-east-v2-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque]\n' \
  "$output_dir/computer-east-v2.png"
printf 'Native component reconstruction: zero differing pixels\n'
printf 'Intermediate export retained: %s\n' "$scratch_dir"
