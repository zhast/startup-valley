#!/usr/bin/env bash
set -euo pipefail

# Separate source objects become separate native assets. Each receives one
# uniform point scale to its reviewed physical size; no aspect stretching,
# raster turning/mirroring, semantic repainting or manufactured alpha.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/computer-west-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-computer-west)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque west computer source\n' >&2
  exit 1
fi
magick "$source_file" -channel A -threshold 50% +channel \
  -dither None -colors 32 "$scratch_dir/source.png"

# Measured true-alpha source objects: monitor422x1083@(156,26),
# keyboard289x851@(804,265), mouse269x170@(818,47). Their source ratios differ
# from the north kit's enlarged master. Do not pretend one source pixel is a
# shared physical unit across independently generated assets. Normalize each
# complete reusable object uniformly, retaining its shape and common palette.
for component in monitor keyboard mouse; do
  case "$component" in
    monitor) rectangle=422x1083+156+26; height=30; origin=+81+108 ;;
    keyboard) rectangle=289x851+804+265; height=31; origin=+99+115 ;;
    mouse) rectangle=269x170+818+47; height=6; origin=+99+103 ;;
  esac
  magick "$scratch_dir/source.png" -crop "$rectangle" +repage \
    -filter point -resize "x$height" -channel A -threshold 50% +channel \
    "$scratch_dir/$component.png"
  magick -size 192x224 canvas:none "$scratch_dir/$component.png" \
    -geometry "$origin" -compose Over -composite -strip \
    -define png:color-type=6 "$output_dir/computer-west-v2-$component.png"
done
magick "$output_dir/computer-west-v2-monitor.png" \
  "$output_dir/computer-west-v2-keyboard.png" -compose Over -composite \
  "$output_dir/computer-west-v2-mouse.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/computer-west-v2.png"
magick "$output_dir/computer-west-v2.png" -filter point -resize 400% \
  "$output_dir/computer-west-v2-4x.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/computer-west-v2.png" \
  -compose Over -composite -filter point -resize 400% \
  "$output_dir/computer-west-v2-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque]\n' \
  "$output_dir/computer-west-v2.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
