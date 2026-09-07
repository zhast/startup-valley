extends SceneTree
## DEV ONLY. Provider-free export of the code-native engineer build kit v2.

const KIT := preload("res://tools/engineer_build_kit_v2_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/engineer-build-kit-v2"
const EVIDENCE := "res://tests/output/engineer-build-kit-v2"
const LEGACY_PATHS: Array[String] = [
	"res://assets/source/overnight-20260904/roles/engineer-mat-north-v1.png",
	"res://assets/source/overnight-20260904/roles/engineer-mat-north-v2.png",
	"res://assets/source/overnight-20260904/roles/engineer-mat-east-v1.png",
	"res://assets/source/overnight-20260904/roles/engineer-mat-south-v1.png",
	"res://assets/source/overnight-20260904/roles/engineer-mat-south-v2.png",
	"res://assets/source/overnight-20260904/roles/engineer-mat-west-v1.png",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/north-v1.png",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/north-v2.png",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/east-v1.png",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/south-v1.png",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/south-v2.png",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/west-v1.png",
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
		"id": "engineer-build-kit-v2",
		"status": "native_review_candidate_not_catalogued_or_runtime_registered",
		"family": "engineer_build_kit",
		"host": "accepted desk / workstations-v2",
		"replaces_proposed_host": "prototype_bench planning envelope only; no production prototype-bench art is changed",
		"canvas": [KIT.CANVAS.x, KIT.CANVAS.y],
		"pivot": [KIT.PIVOT.x, KIT.PIVOT.y],
		"sprite_offset": [KIT.SPRITE_OFFSET.x, KIT.SPRITE_OFFSET.y],
		"footprint_cells": [0, 0],
		"collision_cells": [],
		"directions": directions,
		"legacy_sources_and_native_mats": legacy_records(),
		"retained_generation_budgets": {
			"north": {"initial_calls": 1, "targeted_retries_included": 1, "max_targeted_retries": 3, "exhausted": false},
			"east": {"initial_calls": 1, "targeted_retries_included": 0, "max_targeted_retries": 3, "exhausted": false},
			"south": {"initial_calls": 1, "targeted_retries_included": 1, "max_targeted_retries": 3, "exhausted": false},
			"west": {"initial_calls": 1, "targeted_retries_included": 0, "max_targeted_retries": 3, "exhausted": false},
		},
		"provenance": "Original six generated masters and six native opaque mat plates remain byte-exact history. The compact active mat, debug instrument, and precision-tool tray are new manual typed-GDScript geometry informed by the retained role identity, not crops, resizes, rotations, mirrors, or renamed source attempts.",
		"image_generation_calls": 0,
		"generation_budget_changed": false,
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_catalogue_registered": false,
		"default_layout_registered": false,
		"engineer_pose_service_or_hire_created": false,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Engineer build kit v2 export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
