#!/usr/bin/env bash
set -euo pipefail

# DEV-ONLY exact integer cell translation; source/native-v3 remains untouched.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
registration_source="$project_root/game/tests/fixtures/furniture-calibration/characters/theo-west-seated-v3.png"
registration_output="$project_root/game/tests/fixtures/furniture-calibration/characters/theo-west-seated-v3-registered.png"
registration_scratch="$(mktemp -d -t startup-valley-theo-west-registration)"
if [[ "$(magick identify -format '%wx%h' "$registration_source")" != "288x80" ]]; then
  printf 'Expected six48x80 native cells\n' >&2
  exit 1
fi
for registration_frame in 0 1 2 3 4 5; do
  registration_y=0
  if (( registration_frame >= 2 && registration_frame <= 4 )); then registration_y=-1; fi
  registration_geometry="+0+0"
  if (( registration_y < 0 )); then registration_geometry="+0$registration_y"; fi
  magick "$registration_source" -crop "48x80+$((registration_frame*48))+0" +repage \
    "$registration_scratch/source-$registration_frame.png"
  magick -size 48x80 canvas:none "$registration_scratch/source-$registration_frame.png" \
    -geometry "$registration_geometry" -compose Over -composite -strip \
    -define png:color-type=6 "$registration_scratch/frame-$registration_frame.png"
done
magick "$registration_scratch/frame-0.png" "$registration_scratch/frame-1.png" \
  "$registration_scratch/frame-2.png" "$registration_scratch/frame-3.png" \
  "$registration_scratch/frame-4.png" "$registration_scratch/frame-5.png" +append \
  -strip -define png:color-type=6 "$registration_output"
magick "$registration_output" -filter point -resize 400% \
  "$project_root/game/tests/fixtures/furniture-calibration/characters/theo-west-seated-v3-registered-4x.png"
printf 'Preserved intermediate cells: %s\n' "$registration_scratch"
magick identify -format '%f %wx%h opaque=%[opaque]\n' "$registration_output"
