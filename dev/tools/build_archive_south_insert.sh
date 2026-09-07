#!/usr/bin/env bash
set -euo pipefail

# Uniformly normalize the actual flat panel, not a whole 3D cabinet. The
# generated source is not the requested exact grid: its1478x902 face becomes
# 88x54, so keep one transparent row above/below inside the88x56 socket.
# The host's charcoal front remains visible there; no aspect stretching.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/archive-service-south-insert-v1.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-archive-south)"
mkdir -p "$output_dir"
magick -background none "$project_root/dev/art-catalogue/archive-material-palette.svg" "$scratch_dir/palette.png"
magick "$source_file" -crop 1478x902+46+51 +repage \
  -filter point -resize 88x -dither None -remap "$scratch_dir/palette.png" -strip \
  "$scratch_dir/panel.png"
if [[ "$(magick identify -format '%wx%h' "$scratch_dir/panel.png")" != "88x54" ]]; then
  printf 'Archive front source proportions changed\n' >&2
  exit 1
fi
magick -size 88x56 canvas:none "$scratch_dir/panel.png" \
  -geometry +0+1 -compose Over -composite -strip -define png:color-type=6 \
  "$output_dir/archive-service-south-insert-v1.png"
magick -size 192x288 canvas:none "$output_dir/archive-service-south-insert-v1.png" \
  -geometry +52+180 -compose Over -composite -strip -define png:color-type=6 \
  "$output_dir/archive-service-south-insert-v1-registered.png"
magick -size 88x56 canvas:'#383833' "$output_dir/archive-service-south-insert-v1.png" \
  -compose Over -composite -filter point -resize 800% -strip \
  "$output_dir/archive-service-south-insert-v1-8x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
  "$output_dir/archive-service-south-insert-v1.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
