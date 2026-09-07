#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$project_root/game/assets/source/overnight-20260904/roles/lawyer-kit-north-v3.png"
output_dir="$project_root/game/tests/fixtures/furniture-calibration/roles"
scratch_dir="$(mktemp -d -t startup-valley-lawyer-north)"
mkdir -p "$output_dir"
if [[ "$(magick identify -format '%[opaque]' "$source_file")" == "True" ]]; then
  printf 'Rejected opaque legal toolkit source\n' >&2
  exit 1
fi
# Native palette normalization is shared across complete separate objects.
# Actual source top-plane correction was generated, not painted by this tool.
magick "$source_file" -channel A -threshold 50% +channel \
  -dither None -colors 40 "$scratch_dir/source.png"
for component in binders folder pen_cup; do
  case "$component" in
    binders) rectangle=406x441+57+285; geometry=20x; origin=+54+106 ;;
    folder) rectangle=750x552+584+174; geometry=26x; origin=+114+118 ;;
    pen_cup) rectangle=226x380+1397+346; geometry=x12; origin=+60+129 ;;
  esac
  magick "$scratch_dir/source.png" -crop "$rectangle" +repage \
    -filter point -resize "$geometry" -channel A -threshold 50% +channel \
    "$scratch_dir/$component.png"
  magick -size 192x224 canvas:none "$scratch_dir/$component.png" \
    -geometry "$origin" -compose Over -composite -strip \
    -define png:color-type=6 "$output_dir/lawyer-north-v3-$component.png"
done
magick "$output_dir/lawyer-north-v3-binders.png" \
  "$output_dir/lawyer-north-v3-folder.png" -compose Over -composite \
  "$output_dir/lawyer-north-v3-pen_cup.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/lawyer-north-v3.png"
magick -size 192x224 canvas:'#F1F1F1' "$output_dir/lawyer-north-v3.png" \
  -compose Over -composite -filter point -resize 400% \
  "$output_dir/lawyer-north-v3-paper-4x.png"
magick -background none "$project_root/dev/art-catalogue/role-material-palette.svg" \
  "$scratch_dir/brand-palette.png"
for component in binders folder pen_cup; do
  magick "$output_dir/lawyer-north-v3-$component.png" -alpha extract \
    "$scratch_dir/$component-alpha.png"
  magick "$output_dir/lawyer-north-v3-$component.png" -alpha off -dither None \
    -remap "$scratch_dir/brand-palette.png" "$scratch_dir/$component-alpha.png" \
    -alpha off -compose CopyOpacity -composite -strip -define png:color-type=6 \
    "$output_dir/lawyer-north-v3-$component-brand.png"
  if ! magick compare -metric AE \
    "$scratch_dir/$component-alpha.png" \
    \( "$output_dir/lawyer-north-v3-$component-brand.png" -alpha extract \) \
    null: 2> "$scratch_dir/$component-alpha-difference.txt"; then
    printf 'Palette remap changed %s alpha pixels\n' "$component" >&2
    exit 1
  fi
done
magick "$output_dir/lawyer-north-v3-binders-brand.png" \
  "$output_dir/lawyer-north-v3-folder-brand.png" -compose Over -composite \
  "$output_dir/lawyer-north-v3-pen_cup-brand.png" -compose Over -composite \
  -strip -define png:color-type=6 "$output_dir/lawyer-north-v3-brand.png"
magick identify -format '%f %wx%h %[channels] opaque=%[opaque] colors=%k\n' \
  "$output_dir/lawyer-north-v3.png"
printf 'Intermediate export retained: %s\n' "$scratch_dir"
