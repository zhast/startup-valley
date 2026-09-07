#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/pedestal-south-front-v1.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/pedestal-front-v1"
mkdir -p "$output_dir"
magick "$source_file" -filter point -resize 24x24 -dither None -colors 12 \
  -strip -define png:color-type=2 "$output_dir/south-front.png"
magick "$output_dir/south-front.png" -filter point -resize 800% -strip \
  "$output_dir/south-front-8x.png"
fixture_dir="$project_root/game/tests/fixtures/furniture-calibration/pedestal-v1"
mkdir -p "$fixture_dir"
cp "$output_dir/south-front.png" "$fixture_dir/drawer-front.png"
magick identify -format '%f %wx%h %[channels] colors=%k\n' "$output_dir/south-front.png"
