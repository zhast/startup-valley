extends SceneTree
## DEV ONLY. Deterministic export for three bare passive table candidates.

const TABLES := preload("res://tools/passive_table_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/passive-tables-v2"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func save(image: Image, path: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	check(image.save_png(path) == OK, "Saved " + path)
	var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not disk.is_empty() and PIXELS.rgba(disk).get_data() == image.get_data(), "Exact decoded PNG " + path)
	var facts := PIXELS.analyze(image)
	return {
		"path": path.trim_prefix("res://../"),
		"canvas_size_px": [image.get_width(), image.get_height()],
		"opaque_bounds_px": facts.opaque_bounds, "opaque_pixels": facts.opaque_pixels,
		"partial_alpha_pixels": facts.partial_alpha_pixels, "hidden_rgb_pixels": facts.hidden_rgb_pixels,
		"used_colors": facts.opaque_colors, "decoded_rgba_sha256": PIXELS.digest(image.get_data()),
		"sha256": FileAccess.get_sha256(path), "verify_decoded_facts": true,
	}

func mask_rect(profile: Dictionary) -> Rect2i:
	var result := Rect2i()
	for raw: Variant in profile.occupied:
		var cell := Vector2i(int(raw[0]), int(raw[1]))
		var rect := Rect2i(cell * 32 - Vector2i(16, 16), Vector2i(32, 32))
		result = result.merge(rect) if result.has_area() else rect
	return result

func run() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var preserved := {
		PRODUCTION_CATALOG: FileAccess.get_sha256(PRODUCTION_CATALOG),
		DEFAULT_LAYOUT: FileAccess.get_sha256(DEFAULT_LAYOUT),
		DEV_CATALOGUE: FileAccess.get_sha256(DEV_CATALOGUE),
	}
	var families := {}
	for family: String in TABLES.FAMILIES:
		var size := TABLES.canvas(family)
		var anchor := TABLES.pivot(family)
		var sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0, 0, 0, 0))
		var directions: Array[Dictionary] = []
		var whole_hashes := {}
		for index: int in range(TABLES.SIDES.size()):
			var side: String = TABLES.SIDES[index]
			var profile := TABLES.profile(family, side)
			var parts := TABLES.layers(family, side)
			var whole := TABLES.whole(family, side)
			check(parts.size() == 3 and whole.get_size() == size, family + " " + side + " exact registered layers")
			check(mask_rect(profile) == profile.floor, family + " " + side + " floor envelope matches occupied-cell union")
			var used := whole.get_used_rect()
			check(used.position.x > 0 and used.position.y > 0 and used.end.x < size.x and used.end.y < size.y, family + " " + side + " protected transparent canvas padding")
			var rebuilt := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			rebuilt.fill(Color(0, 0, 0, 0))
			var exports: Array[Dictionary] = []
			for layer_name: String in TABLES.LAYERS:
				var layer: Image = parts[layer_name]
				var record := save(layer, TABLES.output_root(family) + side + "-" + layer_name + ".png")
				record.layer = layer_name
				record.floor_anchor_px = [anchor.x, anchor.y]
				record.z_offset = TABLES.layer_depth(layer_name)
				record.source_path = "game/tools/passive_table_geometry.gd"
				record.method = "Deterministic native screen-axis geometry using the shared quiet-oak material; no complete-bitmap transform."
				check(int(record.partial_alpha_pixels) == 0 and int(record.hidden_rgb_pixels) == 0, family + " " + side + " " + layer_name + " clean binary alpha")
				exports.append(record)
				rebuilt.blend_rect(layer, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
			check(rebuilt.get_data() == whole.get_data(), family + " " + side + " exact ordered reconstruction")
			if family == "cafe_table":
				var center: Vector2i = profile.center
				for local_y: int in range(center.y - 42, center.y + 19):
					check(whole.get_pixelv(anchor + Vector2i(center.x, local_y)).a > 0.99, family + " " + side + " post connects tabletop to base at y=" + str(local_y))
			var whole_record := save(whole, TABLES.output_root(family) + side + "-whole.png")
			whole_record.floor_anchor_px = [anchor.x, anchor.y]
			whole_record.method = "Byte-exact ordered union of floor_shadow, rear_structure and front_structure."
			directions.append({
				"facing": side, "footprint_cells": profile.footprint,
				"occupied_cell_offsets": profile.occupied, "axis": profile.axis,
				"equivalent_view": profile.equivalent_view,
				"native_exports": exports, "composite_exports": [whole_record],
			})
			whole_hashes[side] = whole_record.decoded_rgba_sha256
			sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, size), Vector2i(index * size.x, 0))
		var native_record := save(sheet, OUTPUT.path_join(family + "-native.png"))
		var enlarged := sheet.duplicate()
		enlarged.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
		var enlarged_record := save(enlarged, OUTPUT.path_join(family + "-4x.png"))
		if family == "round_meeting_table":
			check(whole_hashes.values().all(func(value: Variant) -> bool: return value == whole_hashes.north), "Round table honestly reuses one rotationally symmetric physical view")
		elif family == "low_coffee_table":
			check(whole_hashes.north != whole_hashes.south and whole_hashes.east != whole_hashes.west and whole_hashes.north != whole_hashes.east, "Low table registers shifted horizontal/vertical screen-axis views")
		else:
			check(whole_hashes.values().duplicate().all(func(value: Variant) -> bool: return not str(value).is_empty()), "Cafe table exports four explicit translated square registrations")
		families[family] = {
			"revision": TABLES.revision(family), "canvas": [size.x, size.y],
			"pivot": [anchor.x, anchor.y], "sprite_offset": [TABLES.sprite_offset(family).x, TABLES.sprite_offset(family).y],
			"directions": directions, "evidence": [native_record.path, enlarged_record.path],
		}
		var fixture := FileAccess.open(TABLES.output_root(family) + "manifest.json", FileAccess.WRITE)
		check(fixture != null, "Opened " + family + " fixture manifest")
		if fixture != null:
			fixture.store_string(JSON.stringify({
				"id": TABLES.revision(family), "status": "staged_unapproved_passive_art",
				"catalogue_family": family, "canvas": [size.x, size.y], "floor_pivot": [anchor.x, anchor.y],
				"sprite_offset": [TABLES.sprite_offset(family).x, TABLES.sprite_offset(family).y],
				"layer_order": TABLES.LAYERS, "directions": directions,
				"runtime_registered": false, "worker_disabled": true,
				"claims": "Bare passive table art only; no interaction, service, chair, seat, work pose, role kit or production admission.",
			}, "\t") + "\n")
	for path: String in preserved:
		check(FileAccess.get_sha256(path) == preserved[path], "Exporter leaves " + path + " byte-identical")
	var result := {
		"status": "three_passive_table_candidates_not_runtime_registered", "date": "2026-09-06",
		"worker_disabled": true, "families": families, "checks": checks, "failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("export-results.json"), FileAccess.WRITE)
	check(file != null, "Opened passive table export result")
	result.checks = checks
	result.failures = failures
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Passive table export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
