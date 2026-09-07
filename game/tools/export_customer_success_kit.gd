extends SceneTree
## DEV ONLY. Provider-free native export; writes candidate fixtures/evidence only.

const KIT := preload("res://tools/customer_success_kit_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/customer-success-kit-v1"
const EVIDENCE := "res://tests/output/customer-success-kit"
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

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var native_sheet := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	var layer_sheet := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y * 2, false, Image.FORMAT_RGBA8)
	layer_sheet.fill(Color(0, 0, 0, 0))
	var directions: Array[Dictionary] = []
	for column: int in range(KIT.SIDES.size()):
		var side: String = KIT.SIDES[column]
		var parts := KIT.layers(side)
		var whole := KIT.whole(side)
		var layers: Array[Dictionary] = []
		for row: int in range(KIT.LAYERS.size()):
			var layer_name: String = KIT.LAYERS[row]
			var image: Image = parts[layer_name]
			var path := OUTPUT.path_join("%s-%s.png" % [side, layer_name])
			save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(column * KIT.CANVAS.x, row * KIT.CANVAS.y))
			var descriptor := KIT.descriptor(side, layer_name)
			descriptor["measurements"] = PIXELS.analyze(image)
			layers.append(descriptor)
		var whole_path := OUTPUT.path_join(side + "-whole.png")
		save(whole, whole_path)
		native_sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(column * KIT.CANVAS.x, 0))
		directions.append({"facing": side, "objects": KIT.specifications(side), "layers": layers, "whole_sha256": FileAccess.get_sha256(whole_path)})
	save(native_sheet, EVIDENCE.path_join("candidate-contact-sheet-native.png"))
	save(layer_sheet, EVIDENCE.path_join("candidate-layers-native.png"))
	var enlarged := native_sheet.duplicate()
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	var manifest := {
		"id": "customer_success_kit-v1",
		"status": "native_review_candidate_not_runtime_registered",
		"host": "accepted desk / workstations-v2",
		"canvas": [KIT.CANVAS.x, KIT.CANVAS.y],
		"pivot": [KIT.PIVOT.x, KIT.PIVOT.y],
		"sprite_offset": [KIT.SPRITE_OFFSET.x, KIT.SPRITE_OFFSET.y],
		"footprint_cells": [0, 0],
		"collision_cells": [],
		"directions": directions,
		"provenance": "Original deterministic code-native customer-support decor: compact headset dock, glyph-free ticket triage cards, and blank conversation/status console on independently declared screen-axis layouts; no image generation, source extraction, finished-bitmap transform, text, number, logo, giant speech bubble, baked actor, or implied support-service implementation.",
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_catalogue_registered": false,
		"production_files_changed": false,
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Opened fixture manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Customer success kit export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
