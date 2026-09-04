#!/bin/sh
# Navigation overview only. Native PNGs remain the typography acceptance source.
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
font_path="$project_root/game/assets/fonts/nunito-sans/NunitoSans-Variable.ttf"
for suite in typography-audit-c-production typography-audit-c-shell-production; do
  evidence="$project_root/game/tests/output/$suite"
  test -f "$evidence/manifest.json"
  # These deterministic capture suites own only their named PNGs and this sheet.
  set -- "$evidence"/office-*.png "$evidence"/ui-*.png
  if [ "$suite" = typography-audit-c-shell-production ]; then
    set -- "$evidence"/title-*.png "$evidence"/journey-*.png "$evidence"/pause-*.png "$evidence"/day-*.png "$evidence"/reset-*.png
  fi
  magick montage "$@" -filter point -thumbnail 640x360 -tile 2x \
    -geometry +12+28 -background '#151515' -fill '#f1f1f1' \
    -font "$font_path" -pointsize 16 -set label '%t' "$evidence/contact-sheet.png"
done
