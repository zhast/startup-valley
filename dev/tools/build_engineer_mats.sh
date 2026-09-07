#!/usr/bin/env bash
set -euo pipefail

# Opaque tool-mat plates. Each facing must have its own generated original;
# never rotate/mirror a finished image or stretch a source to another ratio.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/overnight-20260904/roles"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/engineer-mat-v1"
mkdir -p "$output_dir"
for identity in north-v1 north-v2 east-v1 south-v1 south-v2 west-v1; do
  facing="${identity%-v*}"
  source_file="$source_dir/engineer-mat-$identity.png"
  [[ -f "$source_file" ]] || continue
  case "$facing" in
    north|south) target=32x20 ;;
    east|west) target=20x32 ;;
  esac
  magick "$source_file" -filter point -resize "$target" -background '#354B98' \
    -gravity center -extent "$target" -alpha off -dither None -colors 24 \
    -strip -define png:color-type=2 "$output_dir/$identity.png"
  magick "$output_dir/$identity.png" -filter point -resize 800% \
    "$output_dir/$identity-8x.png"
done
