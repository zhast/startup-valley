#!/usr/bin/env bash
set -euo pipefail

# Generated source sheets are illustrations with uneven row/column gutters, not
# uniform grids. Measure real transparent separators before extracting a pose.
# This is normalization only: no pose repainting, rotation or mirroring.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/polish"
output_dir="$project_root/game/assets/runtime/characters"
evidence_dir="$project_root/game/tests/output/locomotion-export"
scratch_dir="$(mktemp -d -t startup-valley-locomotion)"
check_only=false
case "${1:-}" in
  '') ;;
  --check) check_only=true ;;
  *) printf 'Usage: %s [--check]\n' "$0" >&2; exit 1 ;;
esac

alpha_bands() {
  local source="$1"
  local axis="$2"
  local projection='1x!'
  [[ "$axis" == x ]] && projection='x1!'
  magick "$source" -alpha extract -threshold 50% -filter Box \
    -resize "$projection" -threshold 0 \
    -define connected-components:verbose=true -connected-components 4 null: |
    awk -v axis="$axis" '$NF == "srgb(255,255,255)" {
      split($2, box, /[x+]/)
      if (axis == "x") print box[3], box[1]
      else print box[4], box[2]
    }' | sort -n
}

for actor in founder mira theo; do
  actor_dir="$scratch_dir/$actor"
  mkdir -p "$actor_dir"
  prepared="$actor_dir/prepared.png"
  # Preserve the existing master/matte interpretation. Do not trim individual
  # cells: doing so erased their common head/foot registration.
  magick "$source_dir/$actor-locomotion-master.png" -alpha on \
    -bordercolor 'srgb(252,252,252)' -border 1 \
    -fuzz 7% -fill none -draw 'color 0,0 floodfill' -shave 1x1 \
    -channel A -morphology Erode Square:1 -threshold 50% +channel \
    -trim +repage "$prepared"
  prepared_width="$(magick identify -format '%w' "$prepared")"
  row_tops=()
  row_heights=()
  while read -r start span; do
    row_tops+=("$start")
    row_heights+=("$span")
  done < <(alpha_bands "$prepared" y)
  if [[ ${#row_tops[@]} -ne 4 ]]; then
    printf 'Expected four isolated source rows for %s, found %s; refusing guessed cuts.\n' "$actor" "${#row_tops[@]}" >&2
    exit 1
  fi
  # Versioned source-geometry regression: these are measured alpha bands from
  # the retained originals, not equal-grid crop guesses. A changed master must
  # be reviewed before silently changing its scale or extraction topology.
  case "$actor" in
    founder) expected_rows='0:219 240:213 477:208 709:209' ;;
    mira) expected_rows='0:238 256:231 505:213 735:215' ;;
    theo) expected_rows='0:215 235:212 469:206 692:209' ;;
  esac
  measured_rows=''
  for ((row=0; row<4; row++)); do
    measured_rows+="${measured_rows:+ }${row_tops[$row]}:${row_heights[$row]}"
  done
  if [[ "$measured_rows" != "$expected_rows" ]]; then
    printf 'Source row geometry changed for %s: measured [%s], reviewed [%s].\n' "$actor" "$measured_rows" "$expected_rows" >&2
    exit 1
  fi

  normalized_rows=()
  for ((row=0; row<4; row++)); do
    row_source="$actor_dir/row-$row-source.png"
    magick "$prepared" -crop "${prepared_width}x${row_heights[$row]}+0+${row_tops[$row]}" +repage "$row_source"
    # One fixed scale per direction restores the authored 68px physical height
    # across views. Every animation frame within a row uses exactly this scale.
    magick "$row_source" -filter point -resize x68 \
      -channel A -threshold 50% +channel "$actor_dir/row-$row-normalized.png"
    normalized_rows+=("$actor_dir/row-$row-normalized.png")
  done
  magick "${normalized_rows[@]}" -background none -append \
    -dither None -colors 48 -unique-colors "$actor_dir/palette.png"

  output_rows=()
  for ((row=0; row<4; row++)); do
    row_source="$actor_dir/row-$row-source.png"
    column_starts=()
    column_widths=()
    while read -r start span; do
      column_starts+=("$start")
      column_widths+=("$span")
    done < <(alpha_bands "$row_source" x)
    if [[ ${#column_starts[@]} -ne 6 ]]; then
      printf 'Expected six isolated source poses for %s row%s, found %s; refusing guessed cuts.\n' "$actor" "$row" "${#column_starts[@]}" >&2
      exit 1
    fi
    cells=()
    for ((column=0; column<6; column++)); do
      cell="$actor_dir/cell-$row-$column.png"
      if (( column_widths[column] * 68 > row_heights[row] * 44 )); then
        printf 'Source pose exceeds 44px content envelope: %s row%s col%s.\n' "$actor" "$row" "$column" >&2
        exit 1
      fi
      magick "$row_source" \
        -crop "${column_widths[$column]}x${row_heights[$row]}+${column_starts[$column]}+0" +repage \
        -filter point -resize x68 -channel A -threshold 50% +channel \
        -dither None -remap "$actor_dir/palette.png" \
        -background none -gravity south -extent 48x72 \
        -gravity north -extent 48x80 "$cell"
      head_bounds="$(magick "$cell" -crop 48x28+0+0 +repage -alpha extract -format '%@' info:)"
      head_width="${head_bounds%%x*}"
      head_left="${head_bounds#*+}"
      head_left="${head_left%%+*}"
      head_shift=$((24 - head_left - head_width / 2))
      printf -v shift '%+d+0' "$head_shift"
      magick "$cell" -roll "$shift" -channel A -threshold 50% +channel "$cell"
      # The roll is permitted to move transparent padding only. Reject clipping
      # at the native envelope before replacing an exported runtime atlas.
      edge_alpha="$(magick "$cell" -alpha extract -crop 1x80+0+0 +repage -format '%[fx:maxima]' info:)"
      right_alpha="$(magick "$cell" -alpha extract -crop 1x80+47+0 +repage -format '%[fx:maxima]' info:)"
      if [[ "$edge_alpha" != 0 || "$right_alpha" != 0 ]]; then
        printf 'Native cell edge clipping in %s row%s col%s; refusing export.\n' "$actor" "$row" "$column" >&2
        exit 1
      fi
      silhouette_count="$(magick "$cell" -alpha extract -threshold 50% \
        -define connected-components:verbose=true -connected-components 8 null: |
        awk '$NF == "srgb(255,255,255)" {count++} END {print count+0}')"
      if [[ "$silhouette_count" != 1 ]]; then
        printf 'Detached source pixels in %s row%s col%s; refusing export.\n' "$actor" "$row" "$column" >&2
        exit 1
      fi
      cells+=("$cell")
      printf '%s row%s col%s: source=(%s,%s,%s,%s), head=%s shift=%s\n' \
        "$actor" "$row" "$column" "${column_starts[$column]}" "${row_tops[$row]}" \
        "${column_widths[$column]}" "${row_heights[$row]}" "$head_bounds" "$head_shift"
    done
    magick "${cells[@]}" +append "$actor_dir/row-$row.png"
    output_rows+=("$actor_dir/row-$row.png")
  done
  magick "${output_rows[@]}" -append +repage -strip -define png:color-type=6 \
    "$actor_dir/$actor-locomotion.png"
done

# Reviewed eye-only source overlays retain every original alpha, pose and anchor.
# Kept after normalization so the corrected blinks survive a source rebuild.
for actor in founder theo; do
  overlay="$project_root/game/assets/source/web-eye-polish/$actor-blink-overlay.png"
  if [[ -f "$overlay" ]]; then
    dimensions="$(magick identify -format '%wx%h' "$overlay")"
    if [[ "$dimensions" != '288x320' ]]; then
      printf 'Invalid reviewed blink overlay dimensions: %s\n' "$actor" >&2
      exit 1
    fi
    magick "$scratch_dir/$actor/$actor-locomotion.png" "$overlay" -compose Over -composite \
      -strip -define png:color-type=6 "$scratch_dir/$actor/$actor-locomotion.png"
  fi
done

# Only replace outputs after all three sources have passed measured-grid checks.
if [[ "$check_only" == true ]]; then
  for actor in founder mira theo; do
    overlay="$project_root/game/assets/source/web-eye-polish/$actor-blink-overlay.png"
    if [[ -f "$overlay" ]]; then
      # Reviewed overlays may be stored by a different PNG encoder. Compare
      # decoded RGBA, including alpha, rather than compression or metadata.
      if ! magick compare -metric AE -channel RGBA "$scratch_dir/$actor/$actor-locomotion.png" "$output_dir/$actor-locomotion.png" null: >/dev/null 2>&1; then
        printf 'Runtime locomotion pixels differ from reviewed source export: %s.\n' "$actor" >&2
        exit 1
      fi
    elif ! cmp -s "$scratch_dir/$actor/$actor-locomotion.png" "$output_dir/$actor-locomotion.png"; then
      printf 'Runtime locomotion differs from deterministic source export: %s.\n' "$actor" >&2
      exit 1
    fi
  done
  printf 'Locomotion source gutters, 72 isolated cells and pixel-identical rebuild: passed.\n'
  exit 0
fi
mkdir -p "$output_dir" "$evidence_dir"
for actor in founder mira theo; do
  cp "$scratch_dir/$actor/$actor-locomotion.png" "$output_dir/$actor-locomotion.png"
  cp "$output_dir/$actor-locomotion.png" "$evidence_dir/$actor-native.png"
  magick "$output_dir/$actor-locomotion.png" -background '#DFD2BB' -alpha remove -alpha off \
    -filter point -resize 400% "$evidence_dir/$actor-4x.png"
done
magick "$evidence_dir/founder-native.png" "$evidence_dir/mira-native.png" \
  "$evidence_dir/theo-native.png" +append "$evidence_dir/all-native.png"
printf 'Built measured locomotion rows only. Native evidence: %s; scratch: %s\n' "$evidence_dir" "$scratch_dir"
