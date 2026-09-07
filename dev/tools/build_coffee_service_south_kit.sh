#!/usr/bin/env bash
set -euo pipefail

# Independent appliances, not a finished counter bitmap. Uniform point scaling
# preserves each source object's measured proportions; all outputs share the
# counter canvas and pivot. Service south means controls face the viewer.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/kits/coffee-service-south-v4.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
scratch_dir="$(mktemp -d -t startup-valley-coffee-south)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque south coffee source\n' >&2
  exit 1
fi
magick "$source_file" -channel A -threshold 50% +channel \
  -dither None -colors 48 "$scratch_dir/source.png"
for component in espresso grinder mug plant; do
  case "$component" in
    espresso) rectangle=367x548+235+156; geometry=x44; origin=+56+116 ;;
    grinder) rectangle=184x448+745+205; geometry=x30; origin=+94+130 ;;
    mug) rectangle=193x196+1055+437; geometry=10x; origin=+109+161 ;;
    plant) rectangle=248x365+1321+280; geometry=16x; origin=+121+136 ;;
  esac
  magick "$scratch_dir/source.png" -crop "$rectangle" +repage \
    -filter point -resize "$geometry" -channel A -threshold 50% +channel \
    "$scratch_dir/$component.png"
  magick -size 192x256 canvas:none "$scratch_dir/$component.png" \
    -geometry "$origin" -compose Over -composite -strip \
    -define png:color-type=6 "$output_dir/coffee-service-south-v4-$component.png"
done
magick "$output_dir/coffee-service-south-v4-espresso.png" \
  "$output_dir/coffee-service-south-v4-grinder.png" -compose Over -composite \
  "$output_dir/coffee-service-south-v4-mug.png" -compose Over -composite \
  "$output_dir/coffee-service-south-v4-plant.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/coffee-service-south-v4.png"
magick -size 192x256 canvas:'#F1F1F1' "$output_dir/coffee-service-south-v4.png" \
  -compose Over -composite -filter point -resize 400% -strip \
  "$output_dir/coffee-service-south-v4-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
  "$output_dir/coffee-service-south-v4.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
