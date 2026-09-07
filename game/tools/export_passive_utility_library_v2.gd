extends SceneTree
## DEV ONLY. Provider-free v2 export for three rejected-v1 passive bases.

const ART := preload("res://tools/passive_utility_library_v2_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUTS := {
	"tall_storage_cabinet": "res://tests/output/tall-storage-cabinet-v2",
	"server_cabinet": "res://tests/output/server-cabinet-v2",
	"recycling_sorter": "res://tests/output/recycling-sorter-v2",
}
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
const V1_REVIEW := "res://../dev/PASSIVE_UTILITY_LIBRARY_NATIVE_REVIEW.md"
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

static func preserved_v1_files(family: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var roots: Array[String] = [str(ART.V1_ROOTS[family]), "res://tests/output/" + family.replace("_", "-")]
	for root_path: String in roots:
		var absolute := ProjectSettings.globalize_path(root_path)
		for file_name: String in DirAccess.get_files_at(absolute):
			if file_name.ends_with(".png") or file_name == "manifest.json" or file_name.ends_with("results.json"):
				var path := root_path.path_join(file_name)
				result.append({"path": path.replace("res://", "game/"), "sha256": FileAccess.get_sha256(path)})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.path) < str(b.path))
	return result

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
			"top_plane_px": rect_values(p.top),
			"camera_front_elevation_px": rect_values(p.front),
			"solid_bounds_px": rect_values(p.solid_bounds),
			"contact_boundary_y": p.contact_y,
			"vertical_elevation_px": p.elevation,
			"top_plane_depth_px": p.top_plane_depth,
			"projected_opaque_rise_px": p.projected_opaque_rise,
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
		"id": family.replace("_", "-") + "-v2",
		"family": family,
		"status": "native_review_candidate_without_runtime_binding",
		"supersedes_rejected_revision": family.replace("_", "-") + "-v1",
		"v1_rejection_review_path": V1_REVIEW.trim_prefix("res://../"),
		"v1_rejection_review_sha256": FileAccess.get_sha256(V1_REVIEW),
		"preserved_v1_files": preserved_v1_files(family),
		"canvas": [size.x, size.y],
		"pivot": [ART.pivot(family).x, ART.pivot(family).y],
		"sprite_offset": [ART.sprite_offset(family).x, ART.sprite_offset(family).y],
		"layers": ART.LAYERS,
		"directions": directions,
		"dimension_review": ART.dimension_review(family),
		"material_sources": material_records,
		"provenance": "Editable typed-GDScript vertical extrusion with a physical-footprint top plane and separate camera-front elevation; reviewed native oak/powdercoat tiles are retained materials only. No generated full view, transformed finished raster, provider call, text, logo, fake metric, baked actor, or service implementation.",
		"image_generation_calls": 0,
		"source_attempts_created": 0,
		"runtime_registered": false,
		"dev_catalogue_registration": "Not asserted. This exporter only verifies byte-exact shared-catalogue immutability during its own run.",
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"service_backend_or_interaction_created": false,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(fixture_root.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened " + family + " v2 fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")

func run() -> void:
	var production_before := FileAccess.get_sha256(PRODUCTION_CATALOG)
	var layout_before := FileAccess.get_sha256(DEFAULT_LAYOUT)
	var dev_before := FileAccess.get_sha256(DEV_CATALOGUE)
	for family: String in ART.FAMILIES: export_family(family)
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == production_before, "V2 exporter leaves production furniture catalogue byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_before, "V2 exporter leaves default office layout byte-exact")
	check(FileAccess.get_sha256(DEV_CATALOGUE) == dev_before, "V2 exporter leaves shared dev catalogue byte-exact")
	print("Passive utility library v2 export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
