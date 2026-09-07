#!/usr/bin/env bash
set -euo pipefail

# Pure atlas-region extraction. No repaint, alpha threshold, palette change,
# resampling or position change is allowed for these existing native pixels.
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
kit_dir="$project_root/game/tests/fixtures/furniture-calibration/kits"
kit_source="$kit_dir/computer-north-v2.png"
kit_evidence="$project_root/game/tests/output/computer-components"
kit_scratch="$(mktemp -d -t startup-valley-computer-components)"
test -f "$kit_source"
mkdir -p "$kit_evidence"
node "$project_root/dev/tools/test_computer_component_calibration.mjs" --source-only

export_region() {
  local component_name="$1" region="$2" placement="$3"
  magick "$kit_source" -crop "$region" +repage "$kit_scratch/$component_name.png"
  magick -size 192x224 xc:none "$kit_scratch/$component_name.png" \
    -geometry "$placement" -compose Over -composite \
    -strip -define png:color-type=6 "$kit_dir/computer-north-v2-$component_name.png"
}

# Row126 is the monitor stand's final outline; row127 begins the keyboard.
# Monitor spans x80..112, including the right bezel pixel that must not be cut.
export_region monitor 192x127+0+0 +0+0
export_region keyboard 31x11+79+127 +79+127
export_region mouse 6x8+112+129 +112+129

magick "$kit_dir/computer-north-v2-monitor.png" \
  "$kit_dir/computer-north-v2-keyboard.png" -compose Over -composite \
  "$kit_dir/computer-north-v2-mouse.png" -compose Over -composite \
  -strip -define png:color-type=6 "$kit_evidence/recombined.png"
node "$project_root/dev/tools/test_computer_component_calibration.mjs"

magick "$kit_source" "$kit_dir/computer-north-v2-monitor.png" \
  "$kit_dir/computer-north-v2-keyboard.png" "$kit_dir/computer-north-v2-mouse.png" \
  "$kit_evidence/recombined.png" +append \
  -strip -define png:color-type=6 "$kit_evidence/components-native.png"
magick "$kit_evidence/components-native.png" -filter point -resize 400% \
  "$kit_evidence/components-4x.png"
printf 'Five panels: original, monitor, keyboard, mouse, exact recombination.\n'
printf 'Region intermediates preserved: %s\n' "$kit_scratch"
