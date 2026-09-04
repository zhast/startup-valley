#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/polish"
output_dir="$project_root/game/assets/runtime"
scratch_dir="$(mktemp -d -t startup-valley-workstation)"

# Remove only the connected exterior matte; keep light books and desk details.
magick "$source_dir/south-workstation-master.png" -alpha on \
  -bordercolor white -border 1 -fuzz 6% -fill none -draw 'color 0,0 floodfill' \
  -shave 1x1 -channel A -morphology Erode Square:2 +channel \
  -trim +repage -filter point -resize 120x104 \
  -channel A -threshold 50% +channel -dither None -colors 48 \
  -background none -gravity south -extent 128x112 "$scratch_dir/workstation.png"

# Both layers use precisely the same origin and normalization. Never trim them
# independently: the split must reconstruct the original workstation exactly.
# The far tabletop/keyboard belongs behind the employee's forearms; the monitor
# back and near apron belong in front. This keeps typing hands visible.
magick "$scratch_dir/workstation.png" -crop 128x45+0+0 +repage \
  -background none -gravity north -extent 128x112 "$scratch_dir/rear.png"
magick "$scratch_dir/workstation.png" -crop 128x67+0+45 +repage \
  -background none -gravity south -extent 128x112 "$scratch_dir/front.png"
magick "$scratch_dir/rear.png" "$scratch_dir/front.png" +append \
  -strip -define png:color-type=6 "$output_dir/office/south-workstation.png"

for employee in mira theo; do
  source_width="$(magick identify -format '%w' "$source_dir/$employee-seated-master.png")"
  # One shared scale and baseline per row. A fixed full-sheet vertical crop
  # preserves head anchors; transparent side padding is centered below.
  source_bounds="$(magick "$source_dir/$employee-seated-master.png" -alpha extract -threshold 50% -format '%@' info:)"
  crop_height="${source_bounds#*x}"
  crop_height="${crop_height%%+*}"
  crop_top="${source_bounds##*+}"
  magick "$source_dir/$employee-seated-master.png" \
    -crop "${source_width}x${crop_height}+0+$crop_top" +repage \
    -filter point -resize x68 -channel A -threshold 50% +channel \
    -dither None -colors 48 -unique-colors "$scratch_dir/$employee-palette.png"
  cell_files=()
  for ((column=0; column<6; column++)); do
    x0=$((column * source_width / 6))
    x1=$(((column + 1) * source_width / 6))
    magick "$source_dir/$employee-seated-master.png" \
      -crop "$((x1-x0))x${crop_height}+$x0+$crop_top" +repage \
      -filter point -resize x68 -channel A -threshold 50% +channel \
      -dither None -remap "$scratch_dir/$employee-palette.png" \
      -background none -gravity south -extent 48x72 \
      -gravity north -extent 48x80 "$scratch_dir/$employee-$column.png"
    # Align the hair silhouette, not hands whose extent changes while typing.
    # Rolling only transparent side padding preserves a fixed head/foot center.
    head_bounds="$(magick "$scratch_dir/$employee-$column.png" -crop 48x28+0+0 +repage -alpha extract -format '%@' info:)"
    head_width="${head_bounds%%x*}"
    head_left="${head_bounds#*+}"
    head_left="${head_left%%+*}"
    head_shift=$((24 - head_left - head_width / 2))
    printf -v head_shift_geometry '%+d+0' "$head_shift"
    magick "$scratch_dir/$employee-$column.png" -roll "$head_shift_geometry" "$scratch_dir/$employee-$column.png"
    cell_files+=("$scratch_dir/$employee-$column.png")
  done
  magick "${cell_files[@]}" +append -strip -define png:color-type=6 \
    "$output_dir/characters/$employee-seated.png"
done

printf 'Built registered workstation and seated atlases. Intermediate files: %s\n' "$scratch_dir"
