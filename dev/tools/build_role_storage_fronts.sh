#!/usr/bin/env bash
set -euo pipefail

# Mechanically fit opaque fronts to the reviewed cabinet's native socket.
# No silhouette inference, camera transform, independent-axis stretch or repaint.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/overnight-20260904/kits"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/role-storage-v1"
scratch_dir="$(mktemp -d -t startup-valley-role-storage)"
mkdir -p "$output_dir"
magick -background none "$project_root/dev/art-catalogue/archive-material-palette.svg" "$scratch_dir/palette.png"
for role in legal creative; do
  source_file="$source_dir/$role-storage-front-v1.png"
  magick "$source_file" -filter point -resize 88x56 -background '#383833' \
    -gravity center -extent 88x56 -alpha off -dither None \
    -remap "$scratch_dir/palette.png" -strip -define png:color-type=2 \
    "$output_dir/$role-front.png"
  magick -size 192x288 canvas:none "$output_dir/$role-front.png" \
    -geometry +52+180 -compose Over -composite -strip -define png:color-type=6 \
    "$output_dir/$role-south-insert.png"
  magick "$output_dir/$role-front.png" -filter point -resize 400% -strip \
    "$output_dir/$role-front-4x.png"
done
magick "$output_dir/legal-front.png" "$output_dir/creative-front.png" +append \
  -strip "$output_dir/fronts-native.png"
magick "$output_dir/fronts-native.png" -filter point -resize 400% -strip \
  "$output_dir/fronts-4x.png"
