#!/usr/bin/env bash
set -euo pipefail
# Narrow native-pixel extensions to the existing authored walnut kit.
# No generated lettering or whole-screen mockups; every text label stays live.
repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
target_dir="$repo_dir/game/assets/runtime/ui/materials"
base_dir="$repo_dir/game/assets/runtime/ui/cozy-controls"
mkdir -p "$target_dir"

# Reuse exact walnut corners. Quiet actions have paper-colored centers;
# the same material, not an unrelated one-pixel web-button border.
for state in normal hover pressed disabled; do
  color='#f4e3c5'
  case "$state" in
    hover) color='#fff9ee' ;;
    pressed) color='#e6cfaa' ;;
    disabled) color='#ded7c9' ;;
  esac
  magick "$base_dir/secondary-normal.png" -fill "$color" -opaque '#fff4df' -strip "PNG32:$target_dir/quiet-$state.png"
  for selected in active inactive; do
    face='#ead1aa'
    if [[ "$selected" == active ]]; then face='#fff4df'; fi
    if [[ "$state" == hover ]]; then face='#fff9ee'; fi
    if [[ "$state" == pressed ]]; then face='#e6cfaa'; fi
    if [[ "$state" == disabled ]]; then face='#ded7c9'; fi
    magick "$base_dir/secondary-normal.png" -fill "$face" -opaque '#fff4df' \
      -fill "$face" -draw 'rectangle 6,42 89,47' \
      -fill '#a98252' -draw 'rectangle 0,42 1,47 rectangle 94,42 95,47' \
      -strip "PNG32:$target_dir/tab-$selected-$state.png"
    if [[ "$selected" == active && "$state" != disabled ]]; then
      magick "$target_dir/tab-$selected-$state.png" -fill '#fa4616' -draw 'rectangle 8,4 87,6' -strip "PNG32:$target_dir/tab-$selected-$state.png"
    fi
  done
done

# Native 48px nine-patches: shared stepped corners, readable calm centers.
# Raised sheets get a light upper edge and shallow bottom shadow; fields invert it.
for kind in card field readonly bubble-employee bubble-player popup selection; do
  fill='#fff4df'; edge='#b3976f'; top='#fffbed'; bottom='#ac895c'
  case "$kind" in
    field) fill='#fff9ec'; edge='#9b7951'; top='#b99b74'; bottom='#f7e8cb' ;;
    readonly) fill='#eee0c7'; edge='#b3a187'; top='#c6b598'; bottom='#f6e6c9' ;;
    bubble-employee) fill='#faeacb' ;;
    bubble-player) fill='#fff7e8' ;;
    popup) edge='#805c37'; bottom='#805c37' ;;
    selection) fill='#dfe7f4'; edge='#354b98'; top='#f5f7fc'; bottom='#6196c1' ;;
  esac
  magick -size 48x48 xc:none +antialias -fill "$edge" \
    -draw 'polygon 3,0 44,0 47,3 47,44 44,47 3,47 0,44 0,3' \
    -fill "$top" -draw 'polygon 3,1 44,1 46,3 46,43 43,46 3,46 1,44 1,3' \
    -fill "$bottom" -draw 'rectangle 3,44 44,46 rectangle 45,4 46,43' \
    -fill "$fill" -draw 'polygon 4,3 43,3 44,4 44,42 42,44 4,44 3,43 3,4' \
    -strip "PNG32:$target_dir/$kind.png"
done

# Hollow stepped focus ring follows the same protected six-pixel corners.
magick -size 48x48 xc:none +antialias -fill none -stroke '#354b98' -strokewidth 2 \
  -draw 'path "M 6,2 L 41,2 L 45,6 L 45,41 L 41,45 L 6,45 L 2,41 L 2,6 Z"' \
  -strip "PNG32:$target_dir/focus.png"

# Track wells and grips use the same small stepped material, sampled at1x.
for kind in track thumb thumb-hover thumb-pressed; do
  fill='#dbc39e'; edge='#a58256'; light='#f9eacb'
  case "$kind" in
    thumb) fill='#b18c58'; edge='#785431' ;;
    thumb-hover) fill='#d7b57d'; edge='#785431' ;;
    thumb-pressed) fill='#ac895c'; edge='#785431' ;;
  esac
  magick -size 12x24 xc:none +antialias -fill "$edge" \
    -draw 'polygon 2,0 9,0 11,2 11,21 9,23 2,23 0,21 0,2' \
    -fill "$light" -draw 'rectangle 2,1 9,21' -fill "$fill" -draw 'rectangle 2,3 9,21' \
    -strip "PNG32:$target_dir/$kind.png"
  if [[ "$kind" != track ]]; then
    magick "$target_dir/$kind.png" -fill '#785431' -draw 'rectangle 4,9 7,9 rectangle 4,12 7,12' -strip "PNG32:$target_dir/$kind.png"
  fi
  magick "$target_dir/$kind.png" -rotate 90 -strip "PNG32:$target_dir/$kind-horizontal.png"
done
magick "$target_dir/track-horizontal.png" -fill '#354b98' -opaque '#dbc39e' -strip "PNG32:$target_dir/track-filled.png"

# Deliberately authored small glyphs, with no runtime downscaling.
magick -size 24x28 xc:none +antialias -fill '#805c37' \
  -draw 'polygon 3,1 15,1 21,7 21,26 3,26' -fill '#fff4df' \
  -draw 'polygon 5,3 14,3 19,8 19,24 5,24' -fill '#b3976f' \
  -draw 'polygon 14,2 14,8 20,8' -fill '#805c37' \
  -draw 'rectangle 7,12 16,13 rectangle 7,16 16,17 rectangle 7,20 13,21' -strip "PNG32:$target_dir/document.png"
magick -size 32x24 xc:none +antialias -fill '#805c37' \
  -draw 'polygon 2,2 12,2 15,5 29,5 30,7 30,21 28,23 3,23 1,21 1,4' \
  -fill '#fff4df' -draw 'polygon 3,4 11,4 14,7 28,7 28,9 3,9' \
  -fill '#ead1aa' -draw 'rectangle 3,11 28,20' \
  -fill '#fffbed' -draw 'rectangle 3,10 28,11' \
  -fill '#ac895c' -draw 'rectangle 3,21 28,21' -strip "PNG32:$target_dir/folder.png"
magick -size 16x16 xc:none +antialias -fill '#805c37' \
  -draw 'polygon 3,2 12,2 14,4 14,11 12,13 3,13 1,11 1,4' \
  -fill '#fff4df' -draw 'rectangle 3,4 12,11' -strip "PNG32:$target_dir/unchecked.png"
magick "$target_dir/unchecked.png" +antialias -fill none -stroke '#354b98' -strokewidth 2 \
  -draw 'path "M 4,7 L 7,10 L 12,4"' -strip "PNG32:$target_dir/checked.png"
magick "$target_dir/checked.png" -colorspace Gray -strip "PNG32:$target_dir/checked-disabled.png"
magick -size 16x16 xc:none +antialias -stroke '#151515' -strokewidth 2 \
  -draw 'line 2,2 13,13 line 13,2 2,13' -strip "PNG32:$target_dir/close.png"
printf 'Native UI material assets built: %s\n' "$target_dir"
