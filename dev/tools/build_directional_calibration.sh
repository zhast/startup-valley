#!/usr/bin/env bash
set -euo pipefail

# Deterministic pixel export only: no invented art, mirroring or projection edits.
# Generated source masters remain untouched. All output is a developer fixture,
# not a production furniture registration or approval.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
calibration_source="$project_root/game/assets/source/overnight-20260904/calibration"
calibration_output="$project_root/game/tests/fixtures/furniture-calibration"
calibration_scratch="$(mktemp -d -t startup-valley-directional-export)"
mkdir -p "$calibration_output"

export_single() {
  local source_file="$1"
  local output_name="$2"
  local native_width="$3"
  local ground_contact_offset="$4"
  local pivot_correction_x="${5:-0}"
  local opaque_state
  opaque_state="$(magick identify -format '%[opaque]' "$source_file")"
  if [[ "$opaque_state" == "True" ]]; then
    printf 'Rejected opaque source: %s\n' "$source_file" >&2
    return 1
  fi
  # One shared crop/scale precedes any future layer split. Binary alpha removes
  # antialias fringes; it does not erase background content or repair geometry.
  magick "$source_file" -channel A -threshold 50% +channel \
    -trim +repage -filter point -resize "${native_width}x" \
    -channel A -threshold 50% +channel -dither None -colors 48 \
    "$calibration_scratch/$output_name.png"
  local native_height
  native_height="$(magick identify -format '%h' "$calibration_scratch/$output_name.png")"
  local contact_row=$((160 + ground_contact_offset))
  local pivot_shift
  printf -v pivot_shift '%+d+0' "$pivot_correction_x"
  if ((native_height > contact_row || native_width > 192)); then
    printf 'Rejected clipped native export: %s\n' "$output_name" >&2
    return 1
  fi
  magick "$calibration_scratch/$output_name.png" \
    -background none -gravity south -extent "192x${contact_row}" \
    -gravity north -extent 192x224 -roll "$pivot_shift" \
    -strip -define png:color-type=6 \
    "$calibration_output/$output_name.png"
  magick identify -format '%f %wx%h %[channels] opaque=%[opaque]\n' \
    "$calibration_output/$output_name.png"
}

# Footprint pivot is (96,160). It is NOT the opaque bottom: a3x1 table's
# southmost floor contact is16px beyond its center cell, matching its footprint.
export_single "$calibration_source/desk-south-v2.png" desk-south-v2 96 16
export_single "$calibration_source/desk-north-v2.png" desk-north-v2 96 16
# Side silhouettes include a4px external tray. The body, not the total alpha
# box, is centered at the floor pivot; correction keeps its32px top centered.
export_single "$calibration_source/desk-east-v3.png" desk-east-v3 36 48 +2
export_single "$calibration_source/desk-west-v3.png" desk-west-v3 36 48 -2
printf 'Intermediate export files retained: %s\n' "$calibration_scratch"
