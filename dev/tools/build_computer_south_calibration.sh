#!/usr/bin/env bash
set -euo pipefail

# Dev-only uniform mechanical normalization of root's true-alpha S3 source.
# No redraw, source overwrite, part movement, reflection or runtime approval.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/computer-south-v3.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-computer-south)"
test -f "$source_file"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque computer source\n' >&2
  exit 1
fi
measured_bounds="$(magick "$source_file" -channel A -threshold 50% +channel -format '%@' info:)"
if [[ "$measured_bounds" != "945x909+227+126" ]]; then
  printf 'Source geometry changed: expected945x909+227+126, got%s\n' "$measured_bounds" >&2
  exit 1
fi
mkdir -p "$output_dir"
magick "$source_file" -channel A -threshold 50% +channel \
  -crop 945x909+227+126 +repage -filter point -resize 32x \
  -channel A -threshold 50% +channel -dither None -colors 32 "$scratch_dir/monitor.png"
native_height="$(magick identify -format '%h' "$scratch_dir/monitor.png")"
top_row="$((140-native_height))"
magick -size 192x224 xc:none "$scratch_dir/monitor.png" \
  -geometry "+80+$top_row" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/computer-south-v3.png"
magick "$output_dir/computer-south-v3.png" -filter point -resize 400% \
  -strip -define png:color-type=6 "$output_dir/computer-south-v3-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] bounds=%@ colors=%k\n' \
  "$output_dir/computer-south-v3.png"
printf 'Shared canvas192x224; pivot(96,160); stand contact boundary140; nativeheight%s.\n' "$native_height"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
