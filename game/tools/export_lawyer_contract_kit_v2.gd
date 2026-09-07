extends SceneTree
## DEV ONLY. Provider-free export of the code-native legal-planning v2 fixture.

const KIT := preload("res://tools/lawyer_contract_kit_v2_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/lawyer-contract-kit-v2"
const EVIDENCE := "res://tests/output/lawyer-contract-kit-v2"
const LEGACY_PATHS: Array[String] = [
	"res://assets/source/overnight-20260904/roles/lawyer-kit-north-v1.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-north-v2.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-north-v3.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v1.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v2.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v3.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v4.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-south-v1.png",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-south-v2.png",
	"res://tests/fixtures/furniture-calibration/roles/lawyer-north-v3-brand.png",
	"res://tests/fixtures/furniture-calibration/roles/lawyer-south-v2.png",
	"res://tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4.png",
]

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func save(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Saved " + path)

func legacy_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for path: String in LEGACY_PATHS:
		result.append({"path": path, "sha256": FileAccess.get_sha256(path), "preserved": true})
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var native_sheet := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	var layer_sheet := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	layer_sheet.fill(Color(0, 0, 0, 0))
	var object_sheet := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y * 3, false, Image.FORMAT_RGBA8)
	object_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(KIT.SIDES.size()):
		var side: String = KIT.SIDES[column]
		var parts := KIT.layers(side)
		var whole := KIT.whole(side)
		var layer_records: Array[Dictionary] = []
		for row: int in range(KIT.LAYERS.size()):
			var layer_name: String = KIT.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := OUTPUT.path_join("%s-%s.png" % [side, layer_name])
			save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(column * KIT.CANVAS.x, row * KIT.CANVAS.y))
			var descriptor := KIT.descriptor(side, layer_name)
			descriptor["measurements"] = PIXELS.analyze(image)
			descriptor["sha256"] = FileAccess.get_sha256(path)
			layer_records.append(descriptor)
		var object_records: Array[Dictionary] = []
		for row: int in range(KIT.OBJECTS.size()):
			var object_name: String = KIT.OBJECTS[row]
			var object := KIT.object_image(side, object_name)
			object_sheet.blit_rect(object, Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(column * KIT.CANVAS.x, row * KIT.CANVAS.y))
			object_records.append({"object": object_name, "measurements": PIXELS.analyze(object)})
		var whole_path := OUTPUT.path_join(side + "-whole.png")
		save(whole, whole_path)
		native_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(column * KIT.CANVAS.x, 0))
		directions.append({
			"facing": side,
			"identity": KIT.direction_identity(side),
			"objects": object_records,
			"layers": layer_records,
			"whole_measurements": PIXELS.analyze(whole),
			"whole_sha256": FileAccess.get_sha256(whole_path),
		})
	save(native_sheet, EVIDENCE.path_join("candidate-contact-sheet-native.png"))
	save(layer_sheet, EVIDENCE.path_join("candidate-layers-native.png"))
	save(object_sheet, EVIDENCE.path_join("candidate-objects-native.png"))
	var enlarged := native_sheet.duplicate()
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	var manifest := {
		"id": "lawyer-contract-kit-v2",
		"status": "native_review_candidate_not_catalogued_or_runtime_registered",
		"family": "lawyer_contract_kit",
		"host": "accepted desk / workstations-v2",
		"canvas": [KIT.CANVAS.x, KIT.CANVAS.y],
		"pivot": [KIT.PIVOT.x, KIT.PIVOT.y],
		"sprite_offset": [KIT.SPRITE_OFFSET.x, KIT.SPRITE_OFFSET.y],
		"footprint_cells": [0, 0],
		"collision_cells": [],
		"directions": directions,
		"legacy_sources_and_candidates": legacy_records(),
		"provenance": "Original manual code-native legal-planning decor. East and West are newly and independently constructed with correct physical leaf/spine/tab direction; North and South are new coherent code constructions while every retained generated master and v1 native candidate remains untouched.",
		"image_generation_calls": 0,
		"east_retry_budget_reopened": false,
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"legal_service_or_hire_created": false,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Lawyer contract kit v2 export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
