#!/usr/bin/env bash
set -euo pipefail
# Full-source uniform point normalization only; no crop, extent, distortion or
# semantic editing. A wrong native aspect is a rejected source, not a fit task.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/low-bookshelf-south-insert-v1.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/low-bookshelf-v1"
if [[ ! -f "$source_file" ]]; then
  printf 'Source pending: %s\n' "$source_file" >&2
  exit 2
fi
read -r source_width source_height opaque < <(magick identify -format '%w %h %[opaque]\n' "$source_file")
printf 'Original: %sx%s opaque=%s; target88x24, uniform width-only point normalization\n' "$source_width" "$source_height" "$opaque"
if [[ "$opaque" != 'True' ]]; then
  printf 'Reject unexpected source transparency; no alpha fabrication permitted\n' >&2
  exit 1
fi
native_size="$(magick "$source_file" -filter point -resize 88x -format '%wx%h' info:)"
if [[ "$native_size" != '88x24' ]]; then
  printf 'Reject source aspect: uniform native result is %s, not88x24. No pixels exported.\n' "$native_size" >&2
  exit 1
fi
mkdir -p "$output_dir"
magick "$source_file" -filter point -resize 88x -dither None -colors 24 \
  -strip -define png:color-type=2 "$output_dir/books-bin-front.png"
magick "$output_dir/books-bin-front.png" -filter point -resize 800% -strip \
  "$output_dir/books-bin-front-8x.png"
magick identify -format '%f %wx%h %[channels] colors=%k opaque=%[opaque]\n' \
  "$output_dir/books-bin-front.png"
