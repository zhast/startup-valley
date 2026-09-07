#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/materials/indigo-acoustic-felt-v1.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/acoustic-felt-v1"
mkdir -p "$output_dir"
magick "$source_file" -filter point -resize 32x32 -dither None -colors 6 \
  -strip -define png:color-type=2 "$output_dir/felt.png"
magick "$output_dir/felt.png" -filter point -resize 800% -strip "$output_dir/felt-8x.png"
magick -size 96x96 "tile:$output_dir/felt.png" -strip "$output_dir/repeat-native.png"
magick "$output_dir/repeat-native.png" -filter point -resize 400% -strip "$output_dir/repeat-4x.png"
magick -size 88x56 "tile:$output_dir/felt.png" -strip "$output_dir/panel-native.png"
magick "$output_dir/panel-native.png" -filter point -resize 800% -strip "$output_dir/panel-8x.png"
