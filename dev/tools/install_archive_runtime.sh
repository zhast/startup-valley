#!/usr/bin/env bash
set -euo pipefail

# Mechanical promotion only: never repaint, trim, scale, rotate, or overwrite
# the old artifact-archive.png. Original calibration exports remain intact.
archive_repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
archive_source_dir="$archive_repo_root/game/tests/fixtures/furniture-calibration/modular-archive-v1"
archive_runtime_dir="$archive_repo_root/game/assets/runtime/office/archive-v1"
mkdir -p "$archive_runtime_dir"
for archive_side in north east south west; do
  for archive_part in carcass top front plinth insert whole; do
    archive_name="$archive_side-$archive_part.png"
    test -f "$archive_source_dir/$archive_name"
    cp "$archive_source_dir/$archive_name" "$archive_runtime_dir/$archive_name"
    cmp "$archive_source_dir/$archive_name" "$archive_runtime_dir/$archive_name"
  done
done
printf 'Copied and byte-verified 24 registered archive PNGs; no catalogue approval is changed by this script.\n'
