#!/usr/bin/env bash
set -euo pipefail

# Measured alpha crop, one shared scale, palette and registered canvas only.
# No semantic repainting, image rotation, per-component fit or runtime scaling.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/computer-north-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-computer-north)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque computer source\n' >&2
  exit 1
fi
# Alpha50% components: monitor623×575@(455,130), keyboard587×207@(433,721),
# mouse114×147@(1069,758). Their union750×798 fits one shared39px export;
# the monitor becomes32px wide. Its center, not the off-center mouse, registers.
magick "$source_file" -channel A -threshold 50% +channel \
  -crop 750x798+433+130 +repage -filter point -resize 39x \
  -channel A -threshold 50% +channel -dither None -colors 32 \
  "$scratch_dir/kit.png"
native_height="$(magick identify -format '%h' "$scratch_dir/kit.png")"
top_row=$((138 - native_height))
magick -size 192x224 canvas:none "$scratch_dir/kit.png" \
  -geometry "+79+${top_row}" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/computer-north-v2.png"
magick "$output_dir/computer-north-v2.png" -filter point -resize 400% \
  "$output_dir/computer-north-v2-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque]\n' \
  "$output_dir/computer-north-v2.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
