extends SceneTree
## DEV ONLY. Provider-free fixed visitor-chair export; candidate files only.

const CHAIR := preload("res://tools/visitor_chair_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/visitor-chair-v1"
const EVIDENCE := "res://tests/output/visitor-chair"
const TASK_ROOT := "res://assets/runtime/office/workstations-v2"
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

func save(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Saved " + path)
	var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not disk.is_empty() and disk.get_data() == image.get_data(), "PNG roundtrip is exact: " + path)

func task_chair(side: String) -> Image:
	var suffixes: Array[String] = []
	if side in ["north", "south"]: suffixes.assign([side])
	else: suffixes.assign([side + "-rear", side + "-front"])
	var result := Image.create(96, 160, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	for suffix: String in suffixes:
		var image := Image.load_from_file(ProjectSettings.globalize_path(TASK_ROOT.path_join("chair-" + suffix + ".png")))
		check(image.get_size() == Vector2i(96, 160), side + " accepted task-chair comparison source")
		if not image.is_empty(): result = PIXELS.binary_over(result, image)
	return result

func vector_values(points: Array) -> Array:
	var result: Array = []
	for value: Variant in points:
		var point := Vector2i(value)
		result.append([point.x, point.y])
	return result

func run() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var production_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var catalogue_before := FileAccess.get_sha256(DEV_CATALOGUE)
	var native_sheet := Image.create(CHAIR.CANVAS.x * 4, CHAIR.CANVAS.y, false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	var layer_sheet := Image.create(CHAIR.CANVAS.x * 4, CHAIR.CANVAS.y * CHAIR.LAYERS.size(), false, Image.FORMAT_RGBA8)
	layer_sheet.fill(Color(0, 0, 0, 0))
	var comparison := Image.create(CHAIR.CANVAS.x * 4, 160 + CHAIR.CANVAS.y, false, Image.FORMAT_RGBA8)
	comparison.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(CHAIR.SIDES.size()):
		var side: String = CHAIR.SIDES[column]
		var p := CHAIR.profile(side)
		var parts := CHAIR.layers(side)
		var whole := CHAIR.whole(side)
		var layer_records: Array[Dictionary] = []
		for row: int in range(CHAIR.LAYERS.size()):
			var layer_name: String = CHAIR.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := OUTPUT.path_join("%s-%s.png" % [side, layer_name])
			save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(column * CHAIR.CANVAS.x, row * CHAIR.CANVAS.y))
			var descriptor := CHAIR.descriptor(side, layer_name)
			descriptor["measurements"] = PIXELS.analyze(image)
			descriptor["sha256"] = FileAccess.get_sha256(path)
			descriptor["decoded_rgba_sha256"] = PIXELS.digest(image.get_data())
			layer_records.append(descriptor)
		var whole_path := OUTPUT.path_join(side + "-whole.png")
		save(whole, whole_path)
		native_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(column * CHAIR.CANVAS.x, 0))
		comparison.blit_rect(task_chair(side), Rect2i(0, 0, 96, 160), Vector2i(column * 96, 0))
		comparison.blit_rect(whole, Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(column * 96, 160))
		directions.append({
			"facing": side,
			"footprint_cells": p.footprint,
			"occupied_cell_offsets": p.occupied,
			"employee_look_vector": p.employee_look_vector,
			"proposed_interaction_cell": p.interaction,
			"optional_contact_socket": CHAIR.contact_socket(side),
			"contact_points": vector_values(p.contact_points),
			"layers": layer_records,
			"whole_sha256": FileAccess.get_sha256(whole_path),
			"whole_rgba_sha256": PIXELS.digest(whole.get_data()),
			"whole_measurements": PIXELS.analyze(whole),
		})
	save(native_sheet, EVIDENCE.path_join("candidate-contact-sheet-native.png"))
	save(layer_sheet, EVIDENCE.path_join("candidate-layers-native.png"))
	save(comparison, EVIDENCE.path_join("accepted-task-chair-vs-visitor-native.png"))
	var enlarged := native_sheet.duplicate()
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == production_before, "Exporter leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Exporter leaves default office layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == catalogue_before, "Exporter leaves shared art catalogue byte-exact")
	var manifest := {
		"id": "visitor-chair-v1",
		"catalogue_family": "visitor_chair",
		"status": "native_review_required_not_runtime_registered",
		"asset_scope": "fixed base furniture; no actor pixels",
		"canvas": [CHAIR.CANVAS.x, CHAIR.CANVAS.y],
		"pivot": [CHAIR.PIVOT.x, CHAIR.PIVOT.y],
		"sprite_offset": [CHAIR.SPRITE_OFFSET.x, CHAIR.SPRITE_OFFSET.y],
		"structure": "low upholstered back, padded seat, exposed fixed wood frame, four contacts; no casters, lift column, controls, armrests, or headrest",
		"layers": CHAIR.LAYERS,
		"collision_cells": [[0, 0]],
		"directions": directions,
		"provenance": "Original deterministic code-native guest chair with four independently declared screen-space projections; no generated raster, source extraction, finished-bitmap transform, text, logo, actor, or ergonomic-task-chair pixel reuse.",
		"runtime_registered": false,
		"dev_catalogue_registered": true,
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"worker_disabled": true,
		"evidence": [
			EVIDENCE.path_join("candidate-contact-sheet-native.png"),
			EVIDENCE.path_join("candidate-contact-sheet-4x.png"),
			EVIDENCE.path_join("candidate-layers-native.png"),
			EVIDENCE.path_join("accepted-task-chair-vs-visitor-native.png"),
		],
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Visitor chair export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
