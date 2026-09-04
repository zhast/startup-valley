#!/usr/bin/env bash
set -euo pipefail

# Development-only normalization; no image tooling ships with the game.
repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
source_file="$repo_dir/game/assets/source/ui-redesign/slim-control-master.png"
target_dir="$repo_dir/game/assets/runtime/ui/cozy-controls"
mkdir -p "$target_dir"
work_dir="$(mktemp -d)"

# The generated master contains a baked checkerboard outside its silhouette.
# Crop the authored frame, sample to native size, and remove only near-white
# exterior pixels. Its warm cream center is not in the neutral matte range.
magick "$source_file" -crop 1550x675+112+106 +repage -filter point -resize 96x48! \
  -alpha on -channel A -fx '(r>0.9 && g>0.9 && b>0.9)?0:1' +channel \
  -fill '#fff4df' -fuzz 12% -opaque '#f6e8cf' -fuzz 0 \
  -strip "PNG32:$work_dir/base.png"

for variant in secondary primary danger; do
  for state in normal hover pressed disabled; do
    color='#fff4df'
    case "$variant:$state" in
      secondary:hover) color='#fff9ee' ;;
      secondary:pressed) color='#e6cfaa' ;;
      primary:normal) color='#fa4616' ;;
      primary:hover) color='#ff663b' ;;
      primary:pressed) color='#f94a1d' ;;
      danger:normal) color='#fce5d7' ;;
      danger:hover) color='#fff9ee' ;;
      danger:pressed) color='#e6cfaa' ;;
    esac
    if [[ "$state" == disabled ]]; then color='#ded7c9'; fi
    magick "$work_dir/base.png" -fill "$color" -opaque '#fff4df' \
      -strip "PNG32:$target_dir/$variant-$state.png"
  done
done

# Reuse the same generated corners for a native 24x24 slider thumb. Opposite
# corners stay pixel-identical; only the quiet center and straight edges extend.
magick -size 24x24 xc:none \
  \( "$target_dir/secondary-normal.png" -crop 6x6+0+0 +repage \) -geometry +0+0 -composite \
  \( "$target_dir/secondary-normal.png" -crop 6x6+90+0 +repage \) -geometry +18+0 -composite \
  \( "$target_dir/secondary-normal.png" -crop 6x6+0+42 +repage \) -geometry +0+18 -composite \
  \( "$target_dir/secondary-normal.png" -crop 6x6+90+42 +repage \) -geometry +18+18 -composite \
  \( "$target_dir/secondary-normal.png" -crop 1x6+48+0 +repage -scale 12x6! \) -geometry +6+0 -composite \
  \( "$target_dir/secondary-normal.png" -crop 1x6+48+42 +repage -scale 12x6! \) -geometry +6+18 -composite \
  \( "$target_dir/secondary-normal.png" -crop 6x1+0+24 +repage -scale 6x12! \) -geometry +0+6 -composite \
  \( "$target_dir/secondary-normal.png" -crop 6x1+90+24 +repage -scale 6x12! \) -geometry +18+6 -composite \
  -fill '#fff4df' -draw 'rectangle 6,6 17,17' \
  -fill '#8b6745' -draw 'rectangle 10,8 10,15 rectangle 13,8 13,15' \
  -strip "PNG32:$target_dir/slider-normal.png"
magick "$target_dir/slider-normal.png" -fill '#fff9ee' -opaque '#fff4df' -strip "PNG32:$target_dir/slider-hover.png"
magick "$target_dir/slider-normal.png" -fill '#ded7c9' -opaque '#fff4df' -strip "PNG32:$target_dir/slider-disabled.png"

# Simple glyphs extend the code-authored control vocabulary, not generated art.
magick -size 16x16 xc:none -fill '#151515' -draw 'rectangle 3,5 4,6 rectangle 5,7 6,8 rectangle 7,9 8,10 rectangle 9,7 10,8 rectangle 11,5 12,6' -strip "PNG32:$target_dir/chevron.png"
magick -size 16x16 xc:none -fill '#151515' -draw 'rectangle 3,3 4,4 rectangle 5,5 6,6 rectangle 7,7 8,8 rectangle 9,9 10,10 rectangle 11,11 12,12 rectangle 11,3 12,4 rectangle 9,5 10,6 rectangle 5,9 6,10 rectangle 3,11 4,12' -strip "PNG32:$target_dir/close.png"
printf 'UI control assets normalized to %s\n' "$target_dir"
