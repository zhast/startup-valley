extends SceneTree
## DEV ONLY. Deterministic export for two passive upholstered lounge families.

const SEATING := preload("res://tools/lounge_seating_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/lounge-seating-v3"
const PRESERVE := ["res://data/furniture_catalog.json", "res://data/office_layout.json", "res://../dev/art-catalogue/furniture.json"]
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
	return {"path": path.trim_prefix("res://../"), "canvas_size_px": [image.get_width(), image.get_height()], "opaque_bounds_px": facts.opaque_bounds, "opaque_pixels": facts.opaque_pixels, "partial_alpha_pixels": facts.partial_alpha_pixels, "hidden_rgb_pixels": facts.hidden_rgb_pixels, "used_colors": facts.opaque_colors, "decoded_rgba_sha256": PIXELS.digest(image.get_data()), "sha256": FileAccess.get_sha256(path), "verify_decoded_facts": true}

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
	var preserved := {}
	for path: String in PRESERVE: preserved[path] = FileAccess.get_sha256(path)
	var families := {}
	for family: String in SEATING.FAMILIES:
		var size := SEATING.canvas(family)
		var anchor := SEATING.pivot(family)
		var sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0, 0, 0, 0))
		var directions: Array[Dictionary] = []
		var hashes := {}
		for index: int in range(SEATING.SIDES.size()):
			var side: String = SEATING.SIDES[index]
			var profile := SEATING.profile(family, side)
			var parts := SEATING.layers(family, side)
			var whole := SEATING.whole(family, side)
			check(mask_rect(profile) == profile.floor, family + " " + side + " mask equals physical floor envelope")
			check(parts.size() == 3 and whole.get_size() == size, family + " " + side + " exact registered canvas")
			var used := whole.get_used_rect()
			check(used.position.x > 0 and used.position.y > 0 and used.end.x < size.x and used.end.y < size.y, family + " " + side + " protected transparent padding")
			var rebuilt := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			rebuilt.fill(Color(0, 0, 0, 0))
			var exports: Array[Dictionary] = []
			for layer_name: String in SEATING.LAYERS:
				var layer: Image = parts[layer_name]
				var record := save(layer, SEATING.output_root(family) + side + "-" + layer_name + ".png")
				record.layer = layer_name
				record.floor_anchor_px = [anchor.x, anchor.y]
				record.z_offset = SEATING.layer_depth(layer_name)
				record.source_path = "game/tools/lounge_seating_geometry.gd"
				record.method = "Deterministic native screen-axis upholstery and structure; no finished-raster transform."
				check(int(record.partial_alpha_pixels) == 0 and int(record.hidden_rgb_pixels) == 0, family + " " + side + " " + layer_name + " clean alpha")
				if layer_name == "floor_shadow": check(int(record.opaque_pixels) > 0 and int(record.opaque_pixels) <= 40, family + " " + side + " support-local contact marks stay bounded")
				exports.append(record)
				rebuilt.blend_rect(layer, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
			check(rebuilt.get_data() == whole.get_data(), family + " " + side + " exact ordered reconstruction")
			var whole_record := save(whole, SEATING.output_root(family) + side + "-whole.png")
			whole_record.floor_anchor_px = [anchor.x, anchor.y]
			whole_record.method = "Byte-exact ordered union of support-local contact, rear upholstery and front upholstery."
			directions.append({"facing": side, "footprint_cells": profile.footprint, "occupied_cell_offsets": profile.occupied, "axis": profile.axis, "equivalent_view": profile.equivalent_view, "native_exports": exports, "composite_exports": [whole_record]})
			hashes[side] = whole_record.decoded_rgba_sha256
			sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, size), Vector2i(index * size.x, 0))
		check(hashes.north != hashes.south and hashes.east != hashes.west and hashes.north != hashes.east, family + " retains distinct rear/front/side drawings")
		var native_record := save(sheet, OUTPUT.path_join(family + "-native.png"))
		var enlarged := sheet.duplicate()
		enlarged.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
		var enlarged_record := save(enlarged, OUTPUT.path_join(family + "-4x.png"))
		families[family] = {"revision": SEATING.revision(family), "canvas": [size.x, size.y], "pivot": [anchor.x, anchor.y], "sprite_offset": [SEATING.sprite_offset(family).x, SEATING.sprite_offset(family).y], "directions": directions, "evidence": [native_record.path, enlarged_record.path]}
		var manifest := FileAccess.open(SEATING.output_root(family) + "manifest.json", FileAccess.WRITE)
		check(manifest != null, "Opened " + family + " manifest")
		if manifest != null: manifest.store_string(JSON.stringify({"id": SEATING.revision(family), "status": "staged_unapproved_passive_art", "catalogue_family": family, "canvas": [size.x, size.y], "floor_pivot": [anchor.x, anchor.y], "sprite_offset": [SEATING.sprite_offset(family).x, SEATING.sprite_offset(family).y], "layer_order": SEATING.LAYERS, "directions": directions, "runtime_registered": false, "worker_disabled": true, "claims": "Bare passive lounge art only; no interaction, seat socket, actor pose, reservation or runtime admission."}, "\t") + "\n")
	for path: String in preserved: check(FileAccess.get_sha256(path) == preserved[path], "Exporter leaves " + path + " byte-identical")
	var result := {"status": "two_passive_lounge_candidates_not_runtime_registered", "date": "2026-09-06", "worker_disabled": true, "families": families, "checks": checks, "failures": failures}
	var file := FileAccess.open(OUTPUT.path_join("export-results.json"), FileAccess.WRITE)
	check(file != null, "Opened lounge export result")
	result.checks = checks
	result.failures = failures
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Lounge seating export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
