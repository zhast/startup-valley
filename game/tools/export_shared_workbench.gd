extends SceneTree
## DEV ONLY. Provider-free shared-workbench base export. No catalogue/runtime write.

const BENCH := preload("res://tools/shared_workbench_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/shared-workbench-v1"
const EVIDENCE := "res://tests/output/shared-workbench"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const COMPACT_ROOT := "res://tests/fixtures/furniture-calibration/compact-desk-v1"
const COMPACT_CANVAS := Vector2i(160, 192)
const COMPACT_PIVOT := Vector2i(80, 128)
const PROTOTYPE_ROOT := "res://tests/fixtures/furniture-calibration/prototype-bench-v1"
const PROTOTYPE_CANVAS := Vector2i(192, 320)
const PROTOTYPE_PIVOT := Vector2i(96, 240)
const COMPARISON_CELL := Vector2i(256, 320)
const COMPARISON_PIVOT := Vector2i(128, 240)
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

static func rect_values(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

static func serial_overlay_contract(side: String) -> Dictionary:
	var raw := BENCH.overlay_contract(side)
	var result := {}
	for kind: String in raw:
		var item: Dictionary = raw[kind].duplicate(true)
		if item.get("surface_zone") is Rect2i: item.surface_zone = rect_values(item.surface_zone)
		result[kind] = item
	return result

func run() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var catalog_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var native_sheet := Image.create(BENCH.CANVAS.x * 4, BENCH.CANVAS.y, false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	var layer_sheet := Image.create(BENCH.CANVAS.x * 4, BENCH.CANVAS.y * BENCH.LAYERS.size(), false, Image.FORMAT_RGBA8)
	layer_sheet.fill(Color(0, 0, 0, 0))
	var comparison_sheet := Image.create(COMPARISON_CELL.x * 4, COMPARISON_CELL.y * 3, false, Image.FORMAT_RGBA8)
	comparison_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(BENCH.SIDES.size()):
		var side: String = BENCH.SIDES[column]
		var p := BENCH.profile(side)
		var parts := BENCH.layers(side)
		var whole := BENCH.whole(side)
		var layer_records: Array[Dictionary] = []
		for row: int in range(BENCH.LAYERS.size()):
			var layer_name: String = BENCH.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := OUTPUT.path_join("%s-%s.png" % [side, layer_name])
			save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, BENCH.CANVAS), Vector2i(column * BENCH.CANVAS.x, row * BENCH.CANVAS.y))
			var descriptor := BENCH.descriptor(side, layer_name)
			descriptor["measurements"] = PIXELS.analyze(image)
			descriptor["sha256"] = FileAccess.get_sha256(path)
			layer_records.append(descriptor)
		var whole_path := OUTPUT.path_join(side + "-whole.png")
		save(whole, whole_path)
		native_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, BENCH.CANVAS), Vector2i(column * BENCH.CANVAS.x, 0))
		var compact_path := COMPACT_ROOT.path_join(side + "-whole.png")
		var prototype_path := PROTOTYPE_ROOT.path_join(side + "-whole.png")
		var compact := Image.load_from_file(ProjectSettings.globalize_path(compact_path))
		var prototype := Image.load_from_file(ProjectSettings.globalize_path(prototype_path))
		check(compact.get_size() == COMPACT_CANVAS, side + " loads the exact compact-desk comparison")
		check(prototype.get_size() == PROTOTYPE_CANVAS, side + " loads the exact prototype-bench comparison")
		var column_origin := Vector2i(column * COMPARISON_CELL.x, 0)
		comparison_sheet.blit_rect(compact, Rect2i(Vector2i.ZERO, COMPACT_CANVAS), column_origin + COMPARISON_PIVOT - COMPACT_PIVOT)
		comparison_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, BENCH.CANVAS), column_origin + Vector2i(0, COMPARISON_CELL.y) + COMPARISON_PIVOT - BENCH.PIVOT)
		comparison_sheet.blit_rect(prototype, Rect2i(Vector2i.ZERO, PROTOTYPE_CANVAS), column_origin + Vector2i(0, COMPARISON_CELL.y * 2) + COMPARISON_PIVOT - PROTOTYPE_PIVOT)
		directions.append({
			"facing": side,
			"footprint_cells": p.footprint,
			"occupied_cell_offsets": p.occupied,
			"clearance_cell_offsets": p.clearance,
			"work_cell_offsets": p.work_cells,
			"proposed_interaction_cell": p.interaction,
			"employee_look_vector": p.employee_look_vector,
			"floor_plane": rect_values(p.floor),
			"top_plane": rect_values(p.top),
			"top_layer": p.top_layer,
			"contact_boundary_y": p.contact_y,
			"overlay_contract": serial_overlay_contract(side),
			"layers": layer_records,
			"whole_sha256": FileAccess.get_sha256(whole_path),
			"whole_rgba_sha256": PIXELS.digest(whole.get_data()),
			"distinct_scale_references": {"compact_desk_path": compact_path, "compact_bounds": PIXELS.analyze(compact).opaque_bounds, "prototype_bench_path": prototype_path, "prototype_bounds": PIXELS.analyze(prototype).opaque_bounds},
		})
	save(native_sheet, EVIDENCE.path_join("candidate-contact-sheet-native.png"))
	save(layer_sheet, EVIDENCE.path_join("candidate-layers-native.png"))
	save(comparison_sheet, EVIDENCE.path_join("compact-workbench-prototype-native.png"))
	var enlarged := native_sheet.duplicate()
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == catalog_before, "Exporter leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Exporter leaves default office layout byte-exact")
	var manifest := {
		"id": "shared-workbench-v1",
		"catalogue_family": "shared_workbench",
		"status": "native_review_candidate_not_runtime_registered",
		"asset_scope": "base furniture only",
		"canvas": [BENCH.CANVAS.x, BENCH.CANVAS.y],
		"pivot": [BENCH.PIVOT.x, BENCH.PIVOT.y],
		"sprite_offset": [BENCH.SPRITE_OFFSET.x, BENCH.SPRITE_OFFSET.y],
		"directions": directions,
		"separation": {"base_layers": BENCH.LAYERS, "external_overlay_owners": ["ergonomic_chair", "computer_kit", "role_tool_kits"], "two_independent_bays": true, "chair_device_role_pixels_baked_into_base": false},
		"provenance": "Original deterministic code-native paired oak/charcoal workbench base with two bays and one structural cable well; four screen-space declarations, no generated raster source, finished-bitmap rotation, mirroring, scaling, baked chair, device, role equipment, text, or logo.",
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"worker_disabled": true,
		"evidence": [EVIDENCE.path_join("candidate-contact-sheet-native.png"), EVIDENCE.path_join("candidate-contact-sheet-4x.png"), EVIDENCE.path_join("candidate-layers-native.png"), EVIDENCE.path_join("compact-workbench-prototype-native.png")],
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Shared workbench export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
