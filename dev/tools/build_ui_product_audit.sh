#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
review_directory="$project_root/game/tests/output/visual-review"
output_directory="$project_root/game/tests/output/ui-product-audit"
font_path="/System/Library/Fonts/Supplemental/Arial.ttf"

if ! command -v magick >/dev/null 2>&1; then
	echo "ImageMagick is required to build the UI product contact sheet." >&2
	exit 1
fi
if [ ! -d "$review_directory" ]; then
	echo "Run the Godot visual-review capture before building the contact sheet." >&2
	exit 1
fi

mkdir -p "$output_directory"
magick montage "$review_directory"/*.png \
	-thumbnail 384x216 \
	-tile 3x \
	-geometry +10+30 \
	-background '#151515' \
	-fill '#f1f1f1' \
	-font "$font_path" \
	-pointsize 14 \
	-set label '%t' \
	"$output_directory/contact-sheet.png"

echo "UI product audit contact sheet: $output_directory/contact-sheet.png"
