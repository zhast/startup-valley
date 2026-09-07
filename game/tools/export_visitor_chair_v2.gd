extends SceneTree
## DEV ONLY. Provider-free shadow-only visitor chair v2 export.

const V2 := preload("res://tools/visitor_chair_review_v2.gd")
const CHAIR := preload("res://tools/visitor_chair_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/visitor-chair-v2"
const EVIDENCE := "res://tests/output/visitor-chair-v2"
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
	check(image.save_png(path) == OK, "Saved " + path)
	var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not disk.is_empty() and disk.get_data() == image.get_data(), "Exact PNG roundtrip " + path)
	var facts := PIXELS.analyze(image)
	return {
		"path": path.trim_prefix("res://../"),
		"canvas_size_px": [image.get_width(), image.get_height()],
		"floor_anchor_px": [CHAIR.PIVOT.x, CHAIR.PIVOT.y],
		"opaque_bounds_px": facts.opaque_bounds,
		"opaque_pixels": facts.opaque_pixels,
		"partial_alpha_pixels": facts.partial_alpha_pixels,
		"hidden_rgb_pixels": facts.hidden_rgb_pixels,
		"used_colors": facts.opaque_colors,
		"decoded_rgba_sha256": PIXELS.digest(image.get_data()),
		"verify_decoded_facts": true,
		"sha256": FileAccess.get_sha256(path),
	}

func run() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var before := {
		"production": FileAccess.get_sha256(PRODUCTION_CATALOG),
		"layout": FileAccess.get_sha256(DEFAULT_LAYOUT),
		"catalogue": FileAccess.get_sha256(DEV_CATALOGUE),
	}
	var native := Image.create(CHAIR.CANVAS.x * 4, CHAIR.CANVAS.y, false, Image.FORMAT_RGBA8)
	native.fill(Color(0, 0, 0, 0))
	var comparison := Image.create(CHAIR.CANVAS.x * 4, CHAIR.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	comparison.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for index: int in range(CHAIR.SIDES.size()):
		var side: String = CHAIR.SIDES[index]
		var old_parts := CHAIR.layers(side)
		var parts := V2.layers(side)
		var whole := V2.whole(side)
		var exports: Array[Dictionary] = []
		for layer_name: String in CHAIR.LAYERS:
			var record := save(parts[layer_name], OUTPUT.path_join("%s-%s.png" % [side, layer_name]))
			record.layer = layer_name
			record.source_layer = layer_name
			record.z_offset = CHAIR.layer_depth(layer_name)
			record.source_path = "game/tools/visitor_chair_review_v2.gd" if layer_name == "floor_shadow" else "game/tools/visitor_chair_geometry.gd"
			record.review_path = "dev/art-catalogue/VISITOR_CHAIR_V2_REVIEW_2026-09-06.md"
			record.method = "Shadow-only authored contact marks" if layer_name == "floor_shadow" else "Byte-identical visitor-chair-v1 structure layer"
			exports.append(record)
		var whole_record := save(whole, OUTPUT.path_join(side + "-whole.png"))
		whole_record.method = "Byte-exact ordered union of v2 contact shadow and unchanged v1 chair structure."
		native.blit_rect(whole, Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(index * CHAIR.CANVAS.x, 0))
		comparison.blit_rect(CHAIR.whole(side), Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(index * CHAIR.CANVAS.x, 0))
		comparison.blit_rect(whole, Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(index * CHAIR.CANVAS.x, CHAIR.CANVAS.y))
		check((parts.seat_back as Image).get_data() == (old_parts.seat_back as Image).get_data(), side + " rear structure remains byte-identical to v1")
		check((parts.seat_front as Image).get_data() == (old_parts.seat_front as Image).get_data(), side + " front structure remains byte-identical to v1")
		directions.append({
			"facing": side,
			"footprint_cells": CHAIR.profile(side).footprint,
			"occupied_cell_offsets": CHAIR.profile(side).occupied,
			"contact_points": (CHAIR.profile(side).contact_points as Array).map(func(point: Vector2i) -> Array: return [point.x, point.y]),
			"contact_shadow_rects": V2.contact_mark_rects(side).map(func(rect: Rect2i) -> Array: return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]),
			"native_exports": exports,
			"composite_exports": [whole_record],
		})
	var native_record := save(native, EVIDENCE.path_join("candidate-contact-sheet-native.png"))
	var enlarged := native.duplicate()
	enlarged.resize(native.get_width() * 4, native.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var enlarged_record := save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	var comparison_record := save(comparison, EVIDENCE.path_join("v1-v2-before-after-native.png"))
	var comparison_4x := comparison.duplicate()
	comparison_4x.resize(comparison.get_width() * 4, comparison.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var comparison_4x_record := save(comparison_4x, EVIDENCE.path_join("v1-v2-before-after-4x.png"))
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == before.production, "Production catalogue unchanged")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == before.layout, "Default layout unchanged")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == before.catalogue, "Developer catalogue unchanged")
	var manifest := {
		"id": V2.REVISION,
		"status": "shadow_cleanup_candidate_not_runtime_registered",
		"catalogue_family": "visitor_chair",
		"canvas": [CHAIR.CANVAS.x, CHAIR.CANVAS.y],
		"pivot": [CHAIR.PIVOT.x, CHAIR.PIVOT.y],
		"sprite_offset": [CHAIR.SPRITE_OFFSET.x, CHAIR.SPRITE_OFFSET.y],
		"directions": directions,
		"preserved_revision": "visitor-chair-v1",
		"changed_layer": "floor_shadow",
		"worker_disabled": true,
		"runtime_registered": false,
		"production_catalogue_mutated": false,
		"default_layout_mutated": false,
		"evidence": [native_record.path, enlarged_record.path, comparison_record.path, comparison_4x_record.path],
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened v2 manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Visitor chair v2 export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
