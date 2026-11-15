#!/usr/bin/env bash
set -euo pipefail

# Apply a reviewed native-resolution replacement, including transparent pixels.
# Usage: apply_character_motion.sh ACTOR EXISTING_ATLAS OUTPUT_ATLAS
actor="${1:?actor required}"
input="${2:?input atlas required}"
output="${3:?output atlas required}"
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
source_dir="$project_root/game/assets/source/web-motion-polish"
overlay="$source_dir/$actor-walk-overlay.png"
mask="$source_dir/walk-replacement-mask.png"
if [[ ! -f "$overlay" ]]; then
  printf 'Missing reviewed walk correction for %s\n' "$actor" >&2
  exit 1
fi
for image in "$input" "$overlay" "$mask"; do
  if [[ "$(magick identify -format '%wx%h' "$image")" != '288x320' ]]; then
    printf 'Invalid walk correction dimensions: %s\n' "$image" >&2
    exit 1
  fi
done
# Clearing first is essential: a passing leg exposes background where the old
# permanently spread leg stood. Over alone would leave that old leg behind.
magick "$input" "$mask" -alpha set -compose DstOut -composite \
  "$overlay" -compose Over -composite -strip -define png:color-type=6 "$output"
