#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
for version in 1 2 3; do
  output_dir="$project_root/game/tests/fixtures/furniture-calibration/whiteboard-v$version"
  mkdir -p "$output_dir"
  magick "$project_root/game/assets/source/overnight-20260904/kits/planning-board-content-v$version.png" \
    -filter point -resize 80x48 -dither None -colors 12 -strip \
    -define png:color-type=2 "$output_dir/planning-content.png"
  magick "$output_dir/planning-content.png" -filter point -resize 400% -strip \
    "$output_dir/planning-content-4x.png"
  magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
    "$output_dir/planning-content.png"
done
