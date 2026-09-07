extends SceneTree

const Geometry = preload("res://tools/research_bench_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/research-bench-v1/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var failures: Array[String] = []
	for side: String in Geometry.SIDES:
		var parts: Dictionary[String, Image] = Geometry.layers(side)
		for layer: String in Geometry.LAYERS:
			var file := side + "-" + layer.to_snake_case() + ".png"
			if parts[layer].save_png(OUTPUT + file) != OK: failures.append(file)
		if Geometry.whole(parts).save_png(OUTPUT + side + "-whole.png") != OK: failures.append(side + "-whole.png")
	print("Research bench export: %d failures" % failures.size())
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
