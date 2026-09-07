#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/overnight-20260904/characters"
output_dir="$project_root/game/tests/fixtures/character-concepts/additional-v1"
mkdir -p "$output_dir"
for role in engineer finance; do
  magick "$source_dir/$role-portrait-v1.png" -filter point -resize 64x80 \
    -dither None -colors 32 -strip -define png:color-type=2 \
    "$output_dir/$role-portrait-v1.png"
  magick "$output_dir/$role-portrait-v1.png" -filter point -resize 400% -strip \
    "$output_dir/$role-portrait-v1-4x.png"
done
magick "$output_dir/engineer-portrait-v1.png" "$output_dir/finance-portrait-v1.png" \
  +append -strip "$output_dir/native-pair.png"
magick "$output_dir/native-pair.png" -filter point -resize 400% -strip \
  "$output_dir/pair-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
  "$output_dir/engineer-portrait-v1.png" "$output_dir/finance-portrait-v1.png"
