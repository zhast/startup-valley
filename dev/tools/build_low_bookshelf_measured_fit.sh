#!/usr/bin/env bash
set -euo pipefail
# Separate diagnostic, NOT a successful88x24 target. Full original preserved.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/low-bookshelf-south-insert-v1.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/low-bookshelf-v1"
[[ "$(magick identify -format '%wx%h:%[opaque]' "$source_file")" == '2140x735:True' ]]
[[ "$(magick "$source_file" -filter point -resize x24 -format '%wx%h' info:)" == '70x24' ]]
mkdir -p "$output_dir"
magick "$source_file" -filter point -resize x24 -dither None -colors 24 \
  -strip -define png:color-type=2 "$output_dir/books-row-native.png"
magick "$output_dir/books-row-native.png" -filter point -resize 800% -strip \
  "$output_dir/books-row-native-8x.png"
magick identify -format '%f %wx%h %[channels] colors=%k opaque=%[opaque]\n' \
  "$output_dir/books-row-native.png"
