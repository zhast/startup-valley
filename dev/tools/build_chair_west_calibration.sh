#!/usr/bin/env bash
set -euo pipefail

# Dev-only source normalization. No semantic cutout, layer split, mirror,
# rotation, independent-axis scaling, production registry or approval.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
chair_version="${1:-v2}"
case "$chair_version" in
  v1|v2|v3) ;;
  *) printf 'Expected v1, v2 or v3\n' >&2; exit 2 ;;
esac
chair_source="$project_root/game/assets/source/overnight-20260904/calibration/chair-west-$chair_version.png"
chair_output="$project_root/game/tests/fixtures/furniture-calibration"
test -f "$chair_source"
if [[ "$(magick identify -format '%[opaque]' "$chair_source")" == "True" ]]; then
  printf 'Rejected opaque chair source: %s\n' "$chair_source" >&2
  exit 1
fi
if [[ "$chair_version" != "v2" ]]; then
  printf 'No measured caster calibration for %s\n' "$chair_version" >&2
  exit 3
fi
chair_scratch="$(mktemp -d -t startup-valley-chair-west-export)"
mkdir -p "$chair_output"

# V2 caster band was visually identified at sourcey1120..1535, beneath the
# stem. Measuring this band is not a semantic edit or a generated layer mask.
# The backrest extends beyond the base, so whole-object width is NOT basewidth.
chair_caster_source_width="$(magick "$chair_source" -channel A -threshold 50% +channel \
  -crop 1024x416+0+1120 +repage -trim -format '%w' info:)"
if [[ "$chair_caster_source_width" != "657" ]]; then
  printf 'Source caster calibration changed: expected657, got%s\n' "$chair_caster_source_width" >&2
  exit 1
fi
chair_scale_percent="$(awk 'BEGIN { printf "%.9f%%", 3200/657 }')"
magick "$chair_source" -channel A -threshold 50% +channel \
  -trim +repage -filter point -resize "$chair_scale_percent" \
  -channel A -threshold 50% +channel -dither None -colors 32 \
  "$chair_scratch/native.png"
chair_height="$(magick identify -format '%h' "$chair_scratch/native.png")"
if ((chair_height < 16 || chair_height > 128)); then
  printf 'Chair cannot fit fixed contact boundary: height=%s\n' "$chair_height" >&2
  exit 1
fi

# Measure the registered raster's lowest15px caster band. Keep the floor
# anchor on that base center rather than on the asymmetric whole silhouette.
read -r chair_caster_width chair_caster_x <<< "$(magick "$chair_scratch/native.png" \
  -crop "35x15+0+$((chair_height-15))" +repage -trim -format '%w %X' info:)"
if [[ "$chair_caster_width" != "32" ]]; then
  printf 'Native caster width drifted: expected32, got%s\n' "$chair_caster_width" >&2
  exit 1
fi
chair_x="$((48-chair_caster_x-chair_caster_width/2))"
chair_y="$((128-chair_height))"
magick -size 96x160 xc:none "$chair_scratch/native.png" \
  -geometry "+$chair_x+$chair_y" -composite -strip -define png:color-type=6 \
  "$chair_output/chair-west-$chair_version.png"
magick "$chair_output/chair-west-$chair_version.png" -filter point -resize 400% \
  -strip -define png:color-type=6 "$chair_output/chair-west-$chair_version-4x.png"
magick identify -format '%f canvas=%wx%h alpha-bounds=%@ opaque=%[opaque] colors=%k\n' \
  "$chair_output/chair-west-$chair_version.png"
printf 'Casterwidth%s; opaqueheight%s; whole-origin(%s,%s); pivot(48,112); contact128.\n' \
  "$chair_caster_width" "$chair_height" "$chair_x" "$chair_y"
printf 'Intermediate export preserved: %s\n' "$chair_scratch"
