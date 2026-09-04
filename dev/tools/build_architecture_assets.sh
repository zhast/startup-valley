#!/usr/bin/env bash
set -euo pipefail

# Build-time normalization of retained ImageGen masters. No generated material
# is redrawn in code and no production dependency is added.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/architecture"
output_dir="$project_root/game/assets/runtime/office/architecture"
scratch_dir="$(mktemp -d -t startup-valley-architecture)"
mkdir -p "$output_dir"

# Symmetric four-pixel edge normalization preserves the authored interior while
# making opposite edge pixels identical. Point sampling and palette reduction
# happen before normalization; quantize again afterward without dithering.
seam_x() {
  magick "$1" -channel RGB -fx 'i<4 ? u*(i/4)+(u+u.p{w-1-i,j})/2*(1-i/4) : (i>=w-4 ? u*((w-1-i)/4)+(u+u.p{w-1-i,j})/2*(1-(w-1-i)/4) : u)' +channel "$2"
}
seam_y() {
  magick "$1" -channel RGB -fx 'j<4 ? u*(j/4)+(u+u.p{i,h-1-j})/2*(1-j/4) : (j>=h-4 ? u*((h-1-j)/4)+(u+u.p{i,h-1-j})/2*(1-(h-1-j)/4) : u)' +channel "$2"
}
finish_opaque() {
  magick "$1" -alpha off -dither None -colors 32 -strip -define png:color-type=2 "$2"
}

# Continuous floor material, addressed as sixteen 32px regions. The full 128px
# material repeats; individual cells are not randomly rotated/mirrored.
magick "$source_dir/floor-master.png" -filter point -resize 128x128! \
  -modulate 100,52,100 -brightness-contrast -1x-20 -dither None -colors 32 "$scratch_dir/floor-native.png"
seam_x "$scratch_dir/floor-native.png" "$scratch_dir/floor-x.png"
seam_y "$scratch_dir/floor-x.png" "$scratch_dir/floor-xy.png"
finish_opaque "$scratch_dir/floor-xy.png" "$output_dir/floor.png"

# Preserve the entire generated wall elevation. Its three height bands remain
# distinct rows; only horizontal edges repeat, not cornice-to-baseboard.
magick "$source_dir/wall-master.png" -filter point -resize 128x96! \
  -modulate 100,82,100 -dither None -colors 32 "$scratch_dir/wall-native.png"
seam_x "$scratch_dir/wall-native.png" "$scratch_dir/wall-x.png"
finish_opaque "$scratch_dir/wall-x.png" "$output_dir/wall.png"

# The window master has a baked near-white checker exterior. Remove only its
# connected matte; the dark frame isolates and preserves clouds inside panes.
magick "$source_dir/window-master.png" -alpha on -bordercolor white -border 1 \
  -fuzz 12% -fill none -draw 'color 0,0 floodfill' -shave 1x1 \
  -channel A -morphology Erode Square:1 +channel -trim +repage \
  -filter point -resize 156x88! -channel A -threshold 50% +channel \
  -dither None -colors 64 -background none -gravity center -extent 160x96 \
  -strip -define png:color-type=6 "$output_dir/window.png"

# Raw trim cells contain gutters and broad plaster infills. Select their
# authored walnut cap bands rather than shrinking each framed sample. Crops
# deliberately exclude the source's 8px outside/gutter borders.
magick "$source_dir/trim-master.png" -crop 154x428+490+8 +repage -filter point -resize 32x32! "$scratch_dir/west-raw.png"
magick "$source_dir/trim-master.png" -crop 154x428+235+8 +repage -filter point -resize 32x32! "$scratch_dir/east-raw.png"
magick "$source_dir/trim-master.png" -crop 428x49+894+218 +repage -filter point -resize 32x32! "$scratch_dir/south-raw.png"
magick "$source_dir/trim-master.png" -crop 428x428+1337+8 +repage -filter point -resize 32x32! "$scratch_dir/mass-raw.png"
seam_y "$scratch_dir/west-raw.png" "$scratch_dir/west.png"
seam_y "$scratch_dir/east-raw.png" "$scratch_dir/east.png"
seam_x "$scratch_dir/south-raw.png" "$scratch_dir/south.png"
seam_x "$scratch_dir/mass-raw.png" "$scratch_dir/mass-x.png"
seam_y "$scratch_dir/mass-x.png" "$scratch_dir/mass.png"

# Keep the generated bends, cropping to the shared cap width so no full cream
# square appears at a corner. NW/NE are at the lower end of the north wall face.
magick "$source_dir/trim-master.png" -crop 160x160+8+450 +repage -filter point -resize 32x32! "$scratch_dir/nw.png"
magick "$source_dir/trim-master.png" -crop 159x160+721+450 +repage -filter point -resize 32x32! "$scratch_dir/ne.png"
magick "$source_dir/trim-master.png" -crop 160x156+894+724 +repage -filter point -resize 32x32! "$scratch_dir/sw.png"
magick "$source_dir/trim-master.png" -crop 154x156+1612+724 +repage -filter point -resize 32x32! "$scratch_dir/se.png"

# Register the edge strips to their actual neighbor materials. This is source
# texture compositing, not a second painted geometry or a runtime transform.
magick "$scratch_dir/west.png" -crop 32x1+0+0 +repage "$scratch_dir/west-edge.png"
magick "$scratch_dir/east.png" -crop 32x1+0+0 +repage "$scratch_dir/east-edge.png"
magick "$scratch_dir/south.png" -crop 1x32+0+0 +repage "$scratch_dir/south-edge.png"
magick "$output_dir/wall.png" -crop 1x32+32+64 +repage "$scratch_dir/north-west-edge.png"
magick "$output_dir/wall.png" -crop 1x32+95+64 +repage "$scratch_dir/north-east-edge.png"
magick "$scratch_dir/nw.png" "$scratch_dir/west-edge.png" -geometry +0+31 -composite "$scratch_dir/north-west-edge.png" -geometry +31+0 -composite "$scratch_dir/nw.png"
magick "$scratch_dir/ne.png" "$scratch_dir/east-edge.png" -geometry +0+31 -composite "$scratch_dir/north-east-edge.png" -geometry +0+0 -composite "$scratch_dir/ne.png"
magick "$scratch_dir/sw.png" "$scratch_dir/south-edge.png" -geometry +31+0 -composite "$scratch_dir/west-edge.png" -geometry +0+0 -composite "$scratch_dir/sw.png"
magick "$scratch_dir/se.png" "$scratch_dir/south-edge.png" -geometry +0+0 -composite "$scratch_dir/east-edge.png" -geometry +0+0 -composite "$scratch_dir/se.png"
magick "$scratch_dir/west.png" "$scratch_dir/east.png" "$scratch_dir/south.png" "$scratch_dir/mass.png" +append "$scratch_dir/trim-top.png"
magick "$scratch_dir/nw.png" "$scratch_dir/ne.png" "$scratch_dir/sw.png" "$scratch_dir/se.png" +append "$scratch_dir/trim-bottom.png"
magick "$scratch_dir/trim-top.png" "$scratch_dir/trim-bottom.png" -append \
  -modulate 100,82,100 -dither None -colors 32 -alpha off -strip -define png:color-type=2 "$output_dir/trim.png"

# The generated doorway included unwanted upright wall wings. Retain only the
# lower open passage, brass threshold and indigo mat; discard both wall wings.
magick "$source_dir/door-master.png" -crop 800x282+488+554 +repage \
  -filter point -resize 64x32! -modulate 100,72,100 -alpha off \
  -dither None -colors 32 -strip -define png:color-type=2 "$output_dir/door.png"

assert_equal_edges() {
  local input="$1" axis="$2" width height result
  width="$(magick identify -format '%w' "$input")"
  height="$(magick identify -format '%h' "$input")"
  if [[ "$axis" == x ]]; then
    magick "$input" -crop "1x${height}+0+0" +repage "$scratch_dir/edge-a.png"
    magick "$input" -crop "1x${height}+$((width - 1))+0" +repage "$scratch_dir/edge-b.png"
  else
    magick "$input" -crop "${width}x1+0+0" +repage "$scratch_dir/edge-a.png"
    magick "$input" -crop "${width}x1+0+$((height - 1))" +repage "$scratch_dir/edge-b.png"
  fi
  if ! result="$(magick compare -metric AE "$scratch_dir/edge-a.png" "$scratch_dir/edge-b.png" null: 2>&1)"; then
    printf 'Seam check failed: %s %s (%s)\n' "$input" "$axis" "$result"
    exit 1
  fi
}
assert_equal_edges "$output_dir/floor.png" x
assert_equal_edges "$output_dir/floor.png" y
assert_equal_edges "$output_dir/wall.png" x
for spec in 'west:0:0:y' 'east:32:0:y' 'south:64:0:x' 'mass:96:0:x' 'mass:96:0:y'; do
  IFS=: read -r name x y axis <<< "$spec"
  magick "$output_dir/trim.png" -crop "32x32+$x+$y" +repage "$scratch_dir/seam-trim.png"
  assert_equal_edges "$scratch_dir/seam-trim.png" "$axis"
done
magick "$output_dir/floor.png" "$output_dir/floor.png" +append "$scratch_dir/floor-repeat-row.png"
magick "$scratch_dir/floor-repeat-row.png" "$scratch_dir/floor-repeat-row.png" -append "$scratch_dir/floor-repeat-proof.png"
printf 'Built native architecture kit; floor/wall/trim repeat edges are exact. Scratch: %s\n' "$scratch_dir"
shasum -a 256 "$output_dir/floor.png" "$output_dir/wall.png" "$output_dir/window.png" "$output_dir/trim.png" "$output_dir/door.png"
