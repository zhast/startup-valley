extends SceneTree

const GEOMETRY := preload("res://tools/decision_console_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/decision-console-v1"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	for side: String in GEOMETRY.SIDES:
		var p := GEOMETRY.profile(side)
		check(p.facing == side, side + " declared independently")
		check(p.occupied.size() == 6 and p.clearance.size() == 3, side + " exact six-cell footprint and service aisle")
		check(p.interaction in p.clearance, side + " interaction belongs to service aisle")
		var parts := GEOMETRY.layers(side)
		check(parts.size() == 4, side + " has four authored layers")
		var whole := GEOMETRY.whole(parts)
		check(whole.get_size() == GEOMETRY.CANVAS and whole.get_used_rect().has_area(), side + " native image fits its envelope")
		for y: int in range(whole.get_height()):
			for x: int in range(whole.get_width()):
				var alpha := whole.get_pixel(x, y).a
				check(alpha == 0.0 or alpha == 1.0, side + " uses clean binary alpha")
		var path := OUTPUT.path_join(side + "-whole.png")
		check(FileAccess.file_exists(path), side + " export exists")
		if FileAccess.file_exists(path):
			var disk := Image.load_from_file(ProjectSettings.globalize_path(path))
			check(disk.get_data() == whole.get_data(), side + " deterministic export is byte-exact")
	check(GEOMETRY.profile("diagonal").is_empty(), "No diagonal or rotated fallback")
	print("Decision console: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
