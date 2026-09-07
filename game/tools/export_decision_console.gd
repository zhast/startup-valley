extends SceneTree

const GEOMETRY := preload("res://tools/decision_console_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/decision-console-v1"
const EVIDENCE := "res://tests/output/decision-console-v1"
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
	var sheet := Image.create(GEOMETRY.CANVAS.x * 4, GEOMETRY.CANVAS.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var records: Array[Dictionary] = []
	for index: int in range(GEOMETRY.SIDES.size()):
		var side: String = GEOMETRY.SIDES[index]
		var parts := GEOMETRY.layers(side)
		check(parts.size() == GEOMETRY.LAYERS.size(), side + " owns all layers")
		for label: String in GEOMETRY.LAYERS:
			var path := OUTPUT.path_join(side + "-" + label.to_snake_case() + ".png")
			save(parts[label], path)
		var whole := GEOMETRY.whole(parts)
		save(whole, OUTPUT.path_join(side + "-whole.png"))
		sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, GEOMETRY.CANVAS), Vector2i(index * GEOMETRY.CANVAS.x, 0))
		records.append({"facing": side, "profile": GEOMETRY.profile(side), "whole_sha256": FileAccess.get_sha256(OUTPUT.path_join(side + "-whole.png"))})
	save(sheet, EVIDENCE.path_join("all-directions-native.png"))
	var enlarged := sheet.duplicate()
	enlarged.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	save(enlarged, EVIDENCE.path_join("all-directions-3x.png"))
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"id": "decision-console-v1", "status": "native_review_required", "checks": checks, "failures": failures, "canvas": [GEOMETRY.CANVAS.x, GEOMETRY.CANVAS.y], "pivot": [GEOMETRY.PIVOT.x, GEOMETRY.PIVOT.y], "directions": records, "catalog_entry": GEOMETRY.catalog_entry(), "runtime_registered": false, "provenance": "Original code-native Startup Valley geometry; no raster rotation, mirror or scale."}, "\t") + "\n")
	print("Decision console export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
