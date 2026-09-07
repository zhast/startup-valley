extends SceneTree
## Deterministic code-native export after the bounded ImageGen sheet failed
## transparency/scale. No raster is rotated, mirrored, or resampled.

const GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/collaboration-table-v1"
const EVIDENCE := "res://tests/output/collaboration-table-v1"
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

func analyze(image: Image) -> Dictionary:
	var bounds := image.get_used_rect()
	var partial := 0
	var hidden := 0
	var colors: Dictionary = {}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var p := image.get_pixel(x, y)
			if p.a > 0.0 and p.a < 1.0: partial += 1
			if p.a == 0.0 and (p.r != 0.0 or p.g != 0.0 or p.b != 0.0): hidden += 1
			if p.a > 0.0: colors[p.to_html(true)] = true
	return {"bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "partial_alpha": partial, "hidden_rgb": hidden, "colors": colors.size()}

func save(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Save " + path)
	var loaded := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(loaded != null and loaded.get_size() == image.get_size() and loaded.get_data() == image.get_data(), "Exact PNG roundtrip " + path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var sheet := Image.create(GEOMETRY.CANVAS.x * 4, GEOMETRY.CANVAS.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var manifest_directions: Array[Dictionary] = []
	for index: int in range(GEOMETRY.SIDES.size()):
		var side: String = GEOMETRY.SIDES[index]
		var profile: Dictionary = GEOMETRY.profile(side)
		var parts: Dictionary[String, Image] = GEOMETRY.layers(side)
		check(parts.size() == 3, side + " has all three authored layers")
		var whole := GEOMETRY.whole(parts)
		var whole_measure := analyze(whole)
		check(whole.get_size() == GEOMETRY.CANVAS, side + " full registered canvas")
		check(whole_measure.partial_alpha == 0 and whole_measure.hidden_rgb == 0, side + " clean binary alpha")
		check(whole.get_used_rect().end.x < GEOMETRY.CANVAS.x and whole.get_used_rect().end.y < GEOMETRY.CANVAS.y, side + " unclipped transparent envelope")
		var layer_records: Array[Dictionary] = []
		for layer_name: String in GEOMETRY.LAYERS:
			var layer := parts[layer_name] as Image
			var slug := layer_name.to_snake_case()
			var path := OUTPUT.path_join(side + "-" + slug + ".png")
			save(layer, path)
			var measured := analyze(layer)
			check(measured.partial_alpha == 0 and measured.hidden_rgb == 0, side + " " + layer_name + " exact alpha")
			layer_records.append({"name": layer_name, "path": path, "sha256": FileAccess.get_sha256(path), "measurements": measured})
		save(whole, OUTPUT.path_join(side + "-whole.png"))
		var detail := whole.duplicate() as Image
		detail.resize(GEOMETRY.CANVAS.x * 4, GEOMETRY.CANVAS.y * 4, Image.INTERPOLATE_NEAREST)
		save(detail, EVIDENCE.path_join(side + "-whole-4x.png"))
		sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, GEOMETRY.CANVAS), Vector2i(index * GEOMETRY.CANVAS.x, 0))
		manifest_directions.append({"facing": side, "profile": profile, "whole": {"path": OUTPUT.path_join(side + "-whole.png"), "sha256": FileAccess.get_sha256(OUTPUT.path_join(side + "-whole.png")), "measurements": whole_measure}, "layers": layer_records})
	save(sheet, EVIDENCE.path_join("all-directions-native.png"))
	var enlarged := sheet.duplicate() as Image
	enlarged.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save(enlarged, EVIDENCE.path_join("all-directions-4x.png"))
	var manifest := {"id": "collaboration-table-v1", "status": "native_review_required", "checks": checks, "failures": failures,
		"canvas": [GEOMETRY.CANVAS.x, GEOMETRY.CANVAS.y], "pivot": [GEOMETRY.PIVOT.x, GEOMETRY.PIVOT.y],
		"directions": manifest_directions, "runtime_registered": false,
		"provenance": "Exact code-native geometry using the established Startup Valley oak/charcoal palette after three retained ImageGen sheets failed alpha/scale gates; no finished raster was rotated or mirrored.",
		"source_references": ["res://assets/source/overnight-20260904/furniture/collaboration-table-sheet-v1.png", "res://assets/source/overnight-20260904/furniture/collaboration-table-sheet-v2.png", "res://assets/source/overnight-20260904/furniture/collaboration-table-sheet-v3.png", GEOMETRY.HORIZONTAL_TILE, GEOMETRY.VERTICAL_TILE]}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Open manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Collaboration table export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
