#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/characters/customer-support-portrait-v1.png"
output_dir="$project_root/game/tests/fixtures/character-concepts/customer-support-v1"
mkdir -p "$output_dir"
magick "$source_file" -filter point -resize 64x80 -dither None -colors 32 \
  -strip -define png:color-type=2 "$output_dir/portrait.png"
magick "$output_dir/portrait.png" -filter point -resize 400% -strip \
  "$output_dir/portrait-4x.png"
magick identify -format '%f %wx%h %[channels] colors=%k\n' "$output_dir/portrait.png"
