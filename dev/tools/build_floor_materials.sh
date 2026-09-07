#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/overnight-20260904/materials"
output_dir="$project_root/game/tests/fixtures/material-concepts/overnight-v1"
mkdir -p "$output_dir"
for name in cream-terrazzo-floor walnut-floor warm-cork-floor; do
  source_file="$source_dir/$name-v1.png"
  magick "$source_file" -filter point -resize 128x128 \
    -dither None -colors 12 -strip -define png:color-type=2 \
    "$output_dir/$name-v1.png"
  magick -size 384x384 "tile:$output_dir/$name-v1.png" -strip \
    "$output_dir/$name-v1-repeat.png"
  magick "$output_dir/$name-v1.png" -filter point -resize 400% -strip \
    "$output_dir/$name-v1-4x.png"
  magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
    "$output_dir/$name-v1.png"
done
