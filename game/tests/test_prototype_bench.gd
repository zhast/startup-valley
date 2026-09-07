extends SceneTree
const G := preload("res://tools/prototype_bench_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/prototype-bench-v1"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	for side: String in G.SIDES:
		var p := G.profile(side); check(p.occupied.size() == 6 and p.interaction in p.clearance, side + " service geometry")
		var whole := G.whole(G.layers(side)); check(whole.get_size() == G.CANVAS and whole.get_used_rect().has_area(), side + " native image")
		for y: int in range(whole.get_height()):
			for x: int in range(whole.get_width()):
				var alpha := whole.get_pixel(x, y).a; check(alpha == 0 or alpha == 1, side + " binary alpha")
		var path := OUTPUT.path_join(side + "-whole.png"); check(FileAccess.file_exists(path), side + " export exists")
		if FileAccess.file_exists(path): check(Image.load_from_file(ProjectSettings.globalize_path(path)).get_data() == whole.get_data(), side + " deterministic export")
	check(G.profile("diagonal").is_empty(), "No diagonal fallback")
	print("Prototype bench: %d checks, %d failures" % [checks, failures.size()]); quit(0 if failures.is_empty() else 1)
