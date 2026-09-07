extends SceneTree
## DEV ONLY. Provider-free compact-desk base export. No catalogue/runtime write.

const DESK := preload("res://tools/compact_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/compact-desk-v1"
const EVIDENCE := "res://tests/output/compact-desk"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const SHARED_ROOT := "res://assets/runtime/office/workstations-v2"
const SHARED_CANVAS := Vector2i(192, 224)
const SHARED_PIVOT := Vector2i(96, 160)
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
	var raw := DESK.overlay_contract(side)
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
	var native_sheet := Image.create(DESK.CANVAS.x * 4, DESK.CANVAS.y, false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	var layer_sheet := Image.create(DESK.CANVAS.x * 4, DESK.CANVAS.y * DESK.LAYERS.size(), false, Image.FORMAT_RGBA8)
	layer_sheet.fill(Color(0, 0, 0, 0))
	var comparison_sheet := Image.create(SHARED_CANVAS.x * 4, SHARED_CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	comparison_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(DESK.SIDES.size()):
		var side: String = DESK.SIDES[column]
		var p := DESK.profile(side)
		var parts := DESK.layers(side)
		var whole := DESK.whole(side)
		var layer_records: Array[Dictionary] = []
		for row: int in range(DESK.LAYERS.size()):
			var layer_name: String = DESK.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := OUTPUT.path_join("%s-%s.png" % [side, layer_name])
			save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, DESK.CANVAS), Vector2i(column * DESK.CANVAS.x, row * DESK.CANVAS.y))
			var descriptor := DESK.descriptor(side, layer_name)
			descriptor["measurements"] = PIXELS.analyze(image)
			descriptor["sha256"] = FileAccess.get_sha256(path)
			layer_records.append(descriptor)
		var whole_path := OUTPUT.path_join(side + "-whole.png")
		save(whole, whole_path)
		native_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, DESK.CANVAS), Vector2i(column * DESK.CANVAS.x, 0))
		var shared_rear_path := SHARED_ROOT.path_join("desk-%s-rear.png" % side)
		var shared_front_path := SHARED_ROOT.path_join("desk-%s-front.png" % side)
		var shared_rear := Image.load_from_file(ProjectSettings.globalize_path(shared_rear_path))
		var shared_front := Image.load_from_file(ProjectSettings.globalize_path(shared_front_path))
		check(shared_rear.get_size() == SHARED_CANVAS and shared_front.get_size() == SHARED_CANVAS, side + " loads the accepted shared base for direct scale evidence")
		var shared_whole := PIXELS.binary_over(shared_rear, shared_front)
		comparison_sheet.blit_rect(shared_whole, Rect2i(Vector2i.ZERO, SHARED_CANVAS), Vector2i(column * SHARED_CANVAS.x, 0))
		var compact_origin := Vector2i(column * SHARED_CANVAS.x, SHARED_CANVAS.y) + SHARED_PIVOT - DESK.PIVOT
		comparison_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, DESK.CANVAS), compact_origin)
		directions.append({
			"facing": side,
			"footprint_cells": p.footprint,
			"occupied_cell_offsets": p.occupied,
			"clearance_cell_offsets": p.clearance,
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
			"accepted_shared_base": {"rear_path": shared_rear_path, "front_path": shared_front_path, "whole_opaque_bounds": PIXELS.analyze(shared_whole).opaque_bounds},
		})
	save(native_sheet, EVIDENCE.path_join("candidate-contact-sheet-native.png"))
	save(layer_sheet, EVIDENCE.path_join("candidate-layers-native.png"))
	save(comparison_sheet, EVIDENCE.path_join("accepted-shared-vs-compact-native.png"))
	var enlarged := native_sheet.duplicate()
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == catalog_before, "Exporter leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Exporter leaves default office layout byte-exact")
	var manifest := {
		"id": "compact-desk-v1",
		"catalogue_family": "compact_desk",
		"status": "native_review_candidate_not_runtime_registered",
		"asset_scope": "base furniture only",
		"canvas": [DESK.CANVAS.x, DESK.CANVAS.y],
		"pivot": [DESK.PIVOT.x, DESK.PIVOT.y],
		"sprite_offset": [DESK.SPRITE_OFFSET.x, DESK.SPRITE_OFFSET.y],
		"directions": directions,
		"separation": {"base_layers": DESK.LAYERS, "external_overlay_owners": ["ergonomic_chair", "computer_kit", "role_tool_kits"], "chair_device_role_pixels_baked_into_base": false},
		"provenance": "Original deterministic code-native compact oak/charcoal base; four screen-space declarations, no generated raster source, finished-bitmap rotation, mirroring, scaling, baked chair, device, role equipment, text, or logo.",
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"worker_disabled": true,
		"evidence": [EVIDENCE.path_join("candidate-contact-sheet-native.png"), EVIDENCE.path_join("candidate-contact-sheet-4x.png"), EVIDENCE.path_join("candidate-layers-native.png"), EVIDENCE.path_join("accepted-shared-vs-compact-native.png")],
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Compact desk export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
