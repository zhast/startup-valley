#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
polish_source="$project_root/game/assets/source/polish"
office_source="$project_root/game/assets/source/office-masters"
world_source="$project_root/game/assets/source/world"
character_output="$project_root/game/assets/runtime/characters"
effect_output="$project_root/game/assets/runtime/effects"
office_output="$project_root/game/assets/runtime/office"

if ! command -v magick >/dev/null 2>&1; then
	printf '%s\n' "ImageMagick 7 is required to build the audited pixel assets." >&2
	exit 1
fi

mkdir -p "$character_output" "$effect_output" "$office_output"

build_grid() {
	local source_path="$1"
	local output_path="$2"
	local columns="$3"
	local rows="$4"
	local cell_width="$5"
	local cell_height="$6"
	local content_width="$7"
	local content_height="$8"
	local anchor_y="$9"
	local remove_light_background="${10}"
	local work_dir
	work_dir="$(mktemp -d)"
	local prepared="$work_dir/prepared.png"

	if [[ "$remove_light_background" == "yes" ]]; then
		local background_removed="$work_dir/background-removed.png"
		magick "$source_path" \
			-alpha on -bordercolor 'srgb(252,252,252)' -border 1 \
			-fuzz 7% -fill none -draw 'color 0,0 floodfill' -shave 1x1 \
			-channel A -morphology Erode Square:1 +channel \
			"$background_removed"
		# Generated sheets include generous outer padding that is not part of the
		# logical grid. Trim it before partitioning so edge poses are never clipped.
		magick "$background_removed" -trim +repage "$prepared"
	else
		magick "$source_path" "$prepared"
	fi

	local source_width source_height
	source_width="$(magick identify -format '%w' "$prepared")"
	source_height="$(magick identify -format '%h' "$prepared")"
	local maximum_width=1
	local maximum_height=1
	local index=0

	for ((row = 0; row < rows; row++)); do
		local y0=$((row * source_height / rows))
		local y1=$(((row + 1) * source_height / rows))
		for ((column = 0; column < columns; column++)); do
			local x0=$((column * source_width / columns))
			local x1=$(((column + 1) * source_width / columns))
			local source_cell="$work_dir/source-$index.png"
			local alpha_maximum
			magick "$prepared" -crop "$((x1 - x0))x$((y1 - y0))+$x0+$y0" +repage "$source_cell"
			alpha_maximum="$(magick "$source_cell" -channel A -separate -format '%[fx:maxima]' info:)"
			if awk "BEGIN {exit !($alpha_maximum > 0.01)}"; then
				magick "$source_cell" -trim +repage "$work_dir/trimmed-$index.png"
				local measured_width measured_height
				measured_width="$(magick identify -format '%w' "$work_dir/trimmed-$index.png")"
				measured_height="$(magick identify -format '%h' "$work_dir/trimmed-$index.png")"
				(( measured_width > maximum_width )) && maximum_width="$measured_width"
				(( measured_height > maximum_height )) && maximum_height="$measured_height"
			fi
			index=$((index + 1))
		done
	done

	local scale_percent
	scale_percent="$(awk -v max_w="$maximum_width" -v max_h="$maximum_height" -v out_w="$content_width" -v out_h="$content_height" 'BEGIN {w=100*out_w/max_w; h=100*out_h/max_h; printf "%.6f", (w<h?w:h)}')"

	index=0
	for ((row = 0; row < rows; row++)); do
		for ((column = 0; column < columns; column++)); do
			local final_cell="$work_dir/cell-$index.png"
			if [[ -f "$work_dir/trimmed-$index.png" ]]; then
				magick "$work_dir/trimmed-$index.png" \
					-filter point -resize "${scale_percent}%" \
					-dither None -colors 48 \
					-gravity south -background none -extent "${cell_width}x${anchor_y}" \
					-gravity north -extent "${cell_width}x${cell_height}" \
					"$final_cell"
			else
				magick -size "${cell_width}x${cell_height}" canvas:none "$final_cell"
			fi
			index=$((index + 1))
		done
	done

	local row_images=()
	for ((row = 0; row < rows; row++)); do
		local row_cells=()
		for ((column = 0; column < columns; column++)); do
			row_cells+=("$work_dir/cell-$((row * columns + column)).png")
		done
		magick "${row_cells[@]}" +append "$work_dir/row-$row.png"
		row_images+=("$work_dir/row-$row.png")
	done
	magick "${row_images[@]}" -append -define png:color-type=6 "$output_path"
	rm -rf "$work_dir"
}

normalize_prop() {
	local source_path="$1"
	local output_path="$2"
	local output_width="$3"
	local output_height="$4"
	local content_width="$5"
	local content_height="$6"
	magick "$source_path" -trim +repage \
		-filter point -resize "${content_width}x${content_height}>" \
		-dither None -colors 64 \
		-gravity south -background none -extent "${output_width}x${output_height}" \
		-define png:color-type=6 "$output_path"
}

# Locomotion masters have uneven gutters. Their dedicated measured-band export
# preserves complete boots and prevents pixels leaking from neighboring rows.
bash "$project_root/dev/tools/build_locomotion_assets.sh"
build_grid "$polish_source/mira-work-master.png" "$character_output/mira-work.png" 8 4 48 80 44 68 72 yes
build_grid "$polish_source/theo-work-master.png" "$character_output/theo-work.png" 8 4 48 80 44 68 72 yes

build_grid "$polish_source/world-vfx-master.png" "$effect_output/world-state-vfx.png" 4 6 24 24 22 20 22 no
build_grid "$polish_source/ambient-overlays-master.png" "$effect_output/ambient-office.png" 4 5 32 32 28 28 30 no
build_grid "$polish_source/office-unlock-master.png" "$effect_output/office-unlock.png" 6 1 64 64 58 54 58 no
build_grid "$polish_source/character-shadows-master.png" "$effect_output/character-shadows.png" 3 1 32 16 28 10 13 no

normalize_prop "$office_source/coffee-station-master.png" "$office_output/coffee-station.png" 142 94 138 90
normalize_prop "$office_source/approval-console-master.png" "$office_output/approval-console.png" 132 88 128 84
normalize_prop "$office_source/prototype-bench-master.png" "$office_output/prototype-bench.png" 140 140 136 136
normalize_prop "$office_source/artifact-archive-master.png" "$office_output/artifact-archive.png" 136 90 132 86

# The architectural shell is normalized once so Godot never rescales it every
# frame. The generated campus surround is authored as full-viewport scenery.
magick "$office_source/office-shell-master.png" -filter Lanczos -resize 832x576\! -strip "$office_output/office-shell-base.png"
magick "$world_source/campus-surround-master.png" -filter Lanczos -resize 1280x720^ -gravity center -extent 1280x720 -strip "$office_output/campus-surround.png"

printf '%s\n' "Built audited native pixel assets."
bash "$project_root/dev/tools/build_workstation_assets.sh"
bash "$project_root/dev/tools/build_architecture_assets.sh"
bash "$project_root/dev/tools/build_ui_redesign_assets.sh"
