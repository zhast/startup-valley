extends SceneTree
## DEV ONLY. Provider-free export into a candidate fixture directory only.

const KIT := preload("res://tools/founder_strategy_kit_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/founder-strategy-kit-v1"
const EVIDENCE := "res://tests/output/founder-strategy-kit"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func save(image: Image, path: String) -> void: check(image.save_png(path) == OK, "Saved " + path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var native := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y, false, Image.FORMAT_RGBA8); native.fill(Color(0, 0, 0, 0))
	var layer_sheet := Image.create(KIT.CANVAS.x * 4, KIT.CANVAS.y * 2, false, Image.FORMAT_RGBA8); layer_sheet.fill(Color(0, 0, 0, 0))
	var records: Array[Dictionary] = []
	for column: int in range(KIT.SIDES.size()):
		var side: String = KIT.SIDES[column]
		var parts := KIT.layers(side); var whole := KIT.whole(side); var descriptors: Array[Dictionary] = []
		for row: int in range(KIT.LAYERS.size()):
			var layer_name: String = KIT.LAYERS[row]; var image: Image = parts[layer_name]
			var path := OUTPUT.path_join("%s-%s.png" % [side, layer_name]); save(image, path)
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(column * KIT.CANVAS.x, row * KIT.CANVAS.y))
			var descriptor := KIT.descriptor(side, layer_name); descriptor.measurements = PIXELS.analyze(image); descriptors.append(descriptor)
		var whole_path := OUTPUT.path_join(side + "-whole.png"); save(whole, whole_path)
		native.blit_rect(whole, Rect2i(Vector2i.ZERO, KIT.CANVAS), Vector2i(column * KIT.CANVAS.x, 0))
		records.append({"facing": side, "objects": KIT.specifications(side), "layers": descriptors, "whole_sha256": FileAccess.get_sha256(whole_path)})
	save(native, EVIDENCE.path_join("candidate-contact-sheet-native.png")); save(layer_sheet, EVIDENCE.path_join("candidate-layers-native.png"))
	var enlarged := native.duplicate(); enlarged.resize(native.get_width() * 4, native.get_height() * 4, Image.INTERPOLATE_NEAREST); save(enlarged, EVIDENCE.path_join("candidate-contact-sheet-4x.png"))
	var manifest := {"id": "founder_strategy_kit-v1", "status": "native_review_candidate_not_runtime_registered", "canvas": [192, 224], "pivot": [96, 160], "sprite_offset": [0, -48], "footprint_cells": [0, 0], "collision_cells": [], "directions": records, "provenance": "Original deterministic code-native screen-axis geometry; no generated source, text, logo, metric, money imagery, finished-raster transform or production binding.", "runtime_registered": false, "production_files_changed": false, "checks": checks, "failures": failures}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE); check(file != null, "Opened fixture manifest"); manifest.checks = checks; manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Founder strategy export: %d checks, %d failures" % [checks, failures.size()]); quit(0 if failures.is_empty() else 1)
