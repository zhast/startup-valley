#!/usr/bin/env bash
set -euo pipefail

# Mechanical dev fixture export only. No semantic redraw, masks, raster turns,
# runtime registry or approval. Keep every source and versioned output.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
chair_version="${1:-v1}"
case "$chair_version" in
  v1|v2|v3) ;;
  *) printf 'Expected v1, v2 or v3\n' >&2; exit 2 ;;
esac
chair_source="$project_root/game/assets/source/overnight-20260904/calibration/chair-north-$chair_version.png"
chair_output="$project_root/game/tests/fixtures/furniture-calibration"
chair_scratch="$(mktemp -d -t startup-valley-chair-export)"
test -f "$chair_source"
mkdir -p "$chair_output"

if [[ "$(magick identify -format '%[opaque]' "$chair_source")" == "True" ]]; then
  printf 'Rejected opaque chair source: %s\n' "$chair_source" >&2
  exit 1
fi

# Threshold preserves genuine alpha while removing subpixel matte residue.
# One common crop and uniform point resize; no geometry distortion or layers.
magick "$chair_source" -channel A -threshold 50% +channel \
  -trim +repage -filter point -resize 32x \
  -channel A -threshold 50% +channel -dither None -colors 32 \
  "$chair_scratch/native.png"
chair_height="$(magick identify -format '%h' "$chair_scratch/native.png")"
if ((chair_height < 1 || chair_height > 128)); then
  printf 'Chair cannot fit the fixed contact boundary: height=%s\n' "$chair_height" >&2
  exit 1
fi

# 96x160 canvas; pivot(48,112); one-cell front contact is pivot+16=128.
magick "$chair_scratch/native.png" -background none -gravity south -extent 96x128 \
  -gravity north -extent 96x160 -strip -define png:color-type=6 \
  "$chair_output/chair-north-$chair_version.png"
magick "$chair_output/chair-north-$chair_version.png" -filter point -resize 400% \
  -strip -define png:color-type=6 "$chair_output/chair-north-$chair_version-4x.png"
magick identify -format '%f canvas=%wx%h alpha-bounds=%@ opaque=%[opaque] colors=%k\n' \
  "$chair_output/chair-north-$chair_version.png"
printf 'Native width32; height%s; backrest top offset about%s; contact boundary+16.\n' \
  "$chair_height" "$((16-chair_height))"
printf 'Intermediate export preserved: %s\n' "$chair_scratch"
