#!/usr/bin/env bash
set -euo pipefail

# Mechanical dev-only export: preserve source alpha and side geometry. No
# invented masks, raster rotation/mirroring, independent axis scale or registry.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
chair_version="${1:-v2}"
case "$chair_version" in
  v1|v2|v3) ;;
  *) printf 'Expected v1, v2 or v3\n' >&2; exit 2 ;;
esac
chair_source="$project_root/game/assets/source/overnight-20260904/calibration/chair-east-$chair_version.png"
chair_output="$project_root/game/tests/fixtures/furniture-calibration"
test -f "$chair_source"
if [[ "$(magick identify -format '%[opaque]' "$chair_source")" == "True" ]]; then
  printf 'Rejected opaque chair source: %s\n' "$chair_source" >&2
  exit 1
fi
chair_scratch="$(mktemp -d -t startup-valley-chair-east-export)"
mkdir -p "$chair_output"

# Threshold removes generated subpixel haze using the actual source alpha.
# Resize the whole chair uniformly; measure rather than force its height.
magick "$chair_source" -channel A -threshold 50% +channel \
  -trim +repage -filter point -resize 32x \
  -channel A -threshold 50% +channel -dither None -colors 32 \
  "$chair_scratch/native.png"
chair_height="$(magick identify -format '%h' "$chair_scratch/native.png")"
if ((chair_height < 1 || chair_height > 128)); then
  printf 'Chair cannot fit the fixed contact boundary: height=%s\n' "$chair_height" >&2
  exit 1
fi

# Shared96×160 canvas, floor pivot(48,112), near contact boundary128.
magick "$chair_scratch/native.png" -background none -gravity south -extent 96x128 \
  -gravity north -extent 96x160 -strip -define png:color-type=6 \
  "$chair_output/chair-east-$chair_version.png"
magick "$chair_output/chair-east-$chair_version.png" -filter point -resize 400% \
  -strip -define png:color-type=6 "$chair_output/chair-east-$chair_version-4x.png"
magick identify -format '%f canvas=%wx%h alpha-bounds=%@ opaque=%[opaque] colors=%k\n' \
  "$chair_output/chair-east-$chair_version.png"
printf 'Native width32; height%s; top offset about%s; contact boundary+16.\n' \
  "$chair_height" "$((16-chair_height))"
printf 'Intermediate export preserved: %s\n' "$chair_scratch"
