#!/usr/bin/env bash
set -euo pipefail

# Dev-only reclassification of a misdirected E request. No new generation,
# rotation, mirroring, repainting or changes to the retained source/E exports.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/roles/lawyer-kit-east-v4.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/roles"
scratch_dir="$(mktemp -d -t startup-valley-lawyer-west)"
prefix="lawyer-west-reclassified-v4"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque reclassified legal toolkit source\n' >&2
  exit 1
fi
magick -background none "$project_root/dev/art-catalogue/role-material-palette.svg" "$scratch_dir/palette.png"
for component in binders folder pen_cup; do
  case "$component" in
    binders) rectangle=227x610+178+148; geometry=12x; origin=+86+70 ;;
    folder) rectangle=409x586+645+170; geometry=19x; origin=+83+147 ;;
    pen_cup) rectangle=170x346+1325+337; geometry=x12; origin=+103+74 ;;
  esac
  magick "$source_file" -channel A -threshold 50% +channel \
    -crop "$rectangle" +repage -filter point -resize "$geometry" \
    -channel A -threshold 50% +channel "$scratch_dir/$component-native.png"
  magick "$scratch_dir/$component-native.png" -alpha extract "$scratch_dir/$component-alpha.png"
  magick "$scratch_dir/$component-native.png" -alpha off -dither None \
    -remap "$scratch_dir/palette.png" "$scratch_dir/$component-alpha.png" \
    -alpha off -compose CopyOpacity -composite -strip -define png:color-type=6 \
    "$scratch_dir/$component-brand.png"
  if ! magick compare -metric AE "$scratch_dir/$component-alpha.png" \
    \( "$scratch_dir/$component-brand.png" -alpha extract \) null: \
    2> "$scratch_dir/$component-alpha-difference.txt"; then
    printf 'Palette remap changed %s alpha pixels\n' "$component" >&2
    exit 1
  fi
  magick -size 192x224 canvas:none "$scratch_dir/$component-brand.png" \
    -geometry "$origin" -compose Over -composite -strip -define png:color-type=6 \
    "$output_dir/$prefix-$component.png"
done
magick "$output_dir/$prefix-binders.png" "$output_dir/$prefix-folder.png" \
  -compose Over -composite "$output_dir/$prefix-pen_cup.png" \
  -compose Over -composite -strip -define png:color-type=6 "$output_dir/$prefix.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/$prefix.png" \
  -compose Over -composite -filter point -resize 400% -strip "$output_dir/$prefix-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' "$output_dir/$prefix.png"
printf 'Reclassification only; intermediate export retained: %s\n' "$scratch_dir"
