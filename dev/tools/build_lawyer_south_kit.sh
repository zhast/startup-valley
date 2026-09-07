#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/roles/lawyer-kit-south-v2.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/roles"
scratch_dir="$(mktemp -d -t startup-valley-lawyer-south)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque south legal toolkit source\n' >&2
  exit 1
fi
magick -background none "$project_root/dev/art-catalogue/role-material-palette.svg" "$scratch_dir/palette.png"
for component in binders folder pen_cup; do
  case "$component" in
    binders) rectangle=405x464+105+236; geometry=20x; origin=+122+106 ;;
    folder) rectangle=677x475+608+214; geometry=26x; origin=+51+117 ;;
    pen_cup) rectangle=210x365+1375+332; geometry=x12; origin=+126+131 ;;
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
    "$output_dir/lawyer-south-v2-$component.png"
done
magick "$output_dir/lawyer-south-v2-binders.png" \
  "$output_dir/lawyer-south-v2-folder.png" -compose Over -composite \
  "$output_dir/lawyer-south-v2-pen_cup.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/lawyer-south-v2.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/lawyer-south-v2.png" \
  -compose Over -composite -filter point -resize 400% \
  "$output_dir/lawyer-south-v2-paper-4x.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' "$output_dir/lawyer-south-v2.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
