extends SceneTree
const G := preload("res://tools/prototype_bench_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/prototype-bench-v1"
const EVIDENCE := "res://tests/output/prototype-bench-v1"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func save(image: Image, path: String) -> void: check(image.save_png(path) == OK, "Saved " + path)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)); DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var sheet := Image.create(G.CANVAS.x * 4, G.CANVAS.y, false, Image.FORMAT_RGBA8); sheet.fill(Color.TRANSPARENT)
	for index: int in range(G.SIDES.size()):
		var side: String = G.SIDES[index]; var parts := G.layers(side); check(parts.size() == 4, side + " layers")
		for label: String in G.LAYERS: save(parts[label], OUTPUT.path_join(side + "-" + label.to_snake_case() + ".png"))
		var whole := G.whole(parts); save(whole, OUTPUT.path_join(side + "-whole.png")); sheet.blit_rect(whole, Rect2i(Vector2i.ZERO, G.CANVAS), Vector2i(index * G.CANVAS.x, 0))
	save(sheet, EVIDENCE.path_join("all-directions-native.png"))
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE); file.store_string(JSON.stringify({"id": "prototype-bench-v1", "status": "native_review_required", "checks": checks, "failures": failures, "catalog_entry": G.catalog_entry(), "runtime_registered": false, "provenance": "Original code-native geometry; no raster rotation/mirror/scale."}, "\t") + "\n")
	print("Prototype bench export: %d checks, %d failures" % [checks, failures.size()]); quit(0 if failures.is_empty() else 1)
