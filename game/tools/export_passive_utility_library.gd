extends SceneTree
## DEV ONLY. Provider-free export for three existing passive-library families.

const ART := preload("res://tools/passive_utility_library_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUTS := {
	"tall_storage_cabinet": "res://tests/output/tall-storage-cabinet",
	"server_cabinet": "res://tests/output/server-cabinet",
	"recycling_sorter": "res://tests/output/recycling-sorter",
}
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
const MATERIALS := {
	"charcoal_powdercoat": ART.POWDERCOAT,
	"oak_horizontal": ART.OAK_HORIZONTAL,
	"oak_vertical": ART.OAK_VERTICAL,
}

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func save(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Saved " + path)
	var decoded := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(decoded != null and decoded.get_data() == image.get_data(), "PNG roundtrip is exact: " + path)

static func rect_values(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func export_family(family: String) -> void:
	var fixture_root := str(ART.ROOTS[family])
	var evidence_root := str(OUTPUTS[family])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_root))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_root))
	var size := ART.canvas(family)
	var native_sheet := Image.create(size.x * 4, size.y, false, Image.FORMAT_RGBA8)
	var layer_sheet := Image.create(size.x * 4, size.y * ART.LAYERS.size(), false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	layer_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(ART.SIDES.size()):
		var side: String = ART.SIDES[column]
		var p := ART.profile(family, side)
		var parts := ART.layers(family, side)
		var whole := ART.whole(family, side)
		var layer_records: Array[Dictionary] = []
		for row: int in range(ART.LAYERS.size()):
			var layer_name: String = ART.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := fixture_root.path_join("%s-%s.png" % [side, layer_name])
			save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, size), Vector2i(column * size.x, row * size.y))
			var descriptor := ART.descriptor(family, side, layer_name)
			descriptor["measurements"] = PIXELS.analyze(image)
			descriptor["sha256"] = FileAccess.get_sha256(path)
			layer_records.append(descriptor)
		var whole_path := fixture_root.path_join(side + "-whole.png")
		save(whole, whole_path)
		native_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, size), Vector2i(column * size.x, 0))
		directions.append({
			"facing": side,
			"service_side": p.service_side,
			"approach_gaze": p.approach_gaze,
			"employee_look_vector": p.employee_look_vector,
			"proposed_interaction_cell": p.interaction,
			"footprint_cells": p.footprint,
			"occupied_cell_offsets": p.occupied,
			"clearance_cell_offsets": p.clearance,
			"floor_plane_px": rect_values(p.floor),
			"body_plane_px": rect_values(p.body),
			"contact_boundary_y": p.contact_y,
			"camera_face_identity": p.camera_face_identity,
			"role_identity": p.role_identity,
			"dimension_review": p.dimension_review,
			"layers": layer_records,
			"whole_measurements": PIXELS.analyze(whole),
			"whole_sha256": FileAccess.get_sha256(whole_path),
		})
	save(native_sheet, evidence_root.path_join("candidate-contact-sheet-native.png"))
	save(layer_sheet, evidence_root.path_join("candidate-layers-native.png"))
	var enlarged := native_sheet.duplicate()
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, evidence_root.path_join("candidate-contact-sheet-4x.png"))
	var material_records := {}
	for material_name: String in MATERIALS:
		var path := str(MATERIALS[material_name])
		material_records[material_name] = {"path": path, "sha256": FileAccess.get_sha256(path), "retained_unchanged": true}
	var manifest := {
		"id": family.replace("_", "-") + "-v1",
		"family": family,
		"status": "passive_library_art_without_runtime_binding",
		"canvas": [size.x, size.y],
		"pivot": [ART.pivot(family).x, ART.pivot(family).y],
		"sprite_offset": [ART.sprite_offset(family).x, ART.sprite_offset(family).y],
		"layers": ART.LAYERS,
		"directions": directions,
		"dimension_review": ART.dimension_review(family),
		"material_sources": material_records,
		"provenance": "Editable typed-GDScript construction with retained reviewed oak/powdercoat native material tiles where relevant. No generated full view, transformed finished raster, provider call, text, logo, fake metric, baked actor, or service implementation.",
		"image_generation_calls": 0,
		"source_attempts_created": 0,
		"runtime_registered": false,
		"dev_catalogue_registration": "Not asserted. This exporter only verifies that the shared catalogue stays byte-exact during its own run.",
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"service_backend_or_interaction_created": false,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(fixture_root.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened " + family + " fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "	") + "\n")

func run() -> void:
	var production_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var dev_before := FileAccess.get_sha256(DEV_CATALOGUE)
	for family: String in ART.FAMILIES: export_family(family)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == production_before, "Exporter leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "Exporter leaves default office layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == dev_before, "Exporter leaves shared dev catalogue byte-exact")
	print("Passive utility library export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
