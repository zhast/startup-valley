#!/usr/bin/env bash
set -euo pipefail

# Separate diagnostic: normalize original complete W2 by body height rather
# than caster X extent. Never replace the32px-base calibration or source.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
chair_source="$project_root/game/assets/source/overnight-20260904/calibration/chair-west-v2.png"
chair_output="$project_root/game/tests/fixtures/furniture-calibration"
chair_evidence="$project_root/game/tests/output/chair-west-height-study"
chair_scratch="$(mktemp -d -t startup-valley-chair-west-height)"
mkdir -p "$chair_evidence"
if [[ "$(magick identify -format '%[opaque]' "$chair_source")" == "True" ]]; then
  printf 'Rejected opaque west chair source\n' >&2
  exit 1
fi
magick "$chair_source" -channel A -threshold 50% +channel \
  -trim +repage -filter point -resize x56 \
  -channel A -threshold 50% +channel -dither None -colors 32 \
  "$chair_scratch/native.png"
read -r chair_width chair_height <<< "$(magick identify -format '%w %h' "$chair_scratch/native.png")"
if [[ "$chair_height" != "56" ]]; then
  printf 'Height normalization failed: %s\n' "$chair_height" >&2
  exit 1
fi
# Measured caster band stays in the lowest15px. Its center, not the rightward
# backrest overhang, supplies integer registration. X extent is a result.
read -r chair_caster_width chair_caster_x <<< "$(magick "$chair_scratch/native.png" \
  -crop "${chair_width}x15+0+41" +repage -trim -format '%w %X' info:)"
chair_x="$((48-chair_caster_x-chair_caster_width/2))"
chair_y=72
magick -size 96x160 canvas:none "$chair_scratch/native.png" \
  -geometry "+$chair_x+$chair_y" -compose Over -composite -strip \
  -define png:color-type=6 "$chair_output/chair-west-v2-height56.png"
magick "$chair_output/chair-west-v2-height56.png" -filter point -resize 400% \
  "$chair_output/chair-west-v2-height56-4x.png"
# Fixed common canvases/pivots and unchanged direction references. A diagnostic
# contact sheet only; no new art is synthesized and none is rotated/mirrored.
magick "$chair_output/chair-north-v1.png" "$chair_output/chair-east-v2.png" \
  "$chair_output/chair-south-v3.png" "$chair_output/chair-west-v2.png" \
  "$chair_output/chair-west-v2-height56.png" +append \
  -background '#F1F1F1' -alpha remove -alpha off "$chair_evidence/family-native.png"
magick "$chair_evidence/family-native.png" -filter point -resize 400% \
  "$chair_evidence/family-4x.png"
magick identify -format '%f canvas=%wx%h bounds=%@ opaque=%[opaque] colors=%k\n' \
  "$chair_output/chair-west-v2-height56.png"
printf 'Actual caster width%s; whole width%s; height%s; origin(%s,%s); pivot(48,112); contact128.\n' \
  "$chair_caster_width" "$chair_width" "$chair_height" "$chair_x" "$chair_y"
printf 'Source-preserving export intermediate: %s\n' "$chair_scratch"
