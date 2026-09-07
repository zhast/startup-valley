extends SceneTree

const GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/collaboration-table-v1"
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

func run() -> void:
	for side: String in GEOMETRY.SIDES:
		var p := GEOMETRY.profile(side)
		check(not p.is_empty() and p.facing == side, side + " is independently declared")
		check(p.top.size == (Vector2i(160, 64) if side in ["north", "south"] else Vector2i(64, 160)), side + " exact five-by-two top plane")
		check(p.floor.position.y - p.top.position.y == 32, side + " common32px elevation")
		check(p.occupied.size() == 10 and p.clearance.size() == 3, side + " explicit footprint and approach")
		var parts := GEOMETRY.layers(side)
		check(parts.size() == 3, side + " three reusable layers")
		var whole := GEOMETRY.whole(parts)
		check(whole.get_size() == GEOMETRY.CANVAS and whole.get_used_rect().has_area(), side + " native whole exists")
		for y: int in range(whole.get_height()):
			for x: int in range(whole.get_width()):
				var pixel := whole.get_pixel(x, y)
				check(pixel.a == 0.0 or pixel.a == 1.0, side + " binary alpha")
		check(FileAccess.file_exists(OUTPUT.path_join(side + "-whole.png")), side + " exported whole exists")
		if FileAccess.file_exists(OUTPUT.path_join(side + "-whole.png")):
			var disk := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
			check(disk.get_data() == whole.get_data(), side + " export rebuilds byte-exact")
	check(GEOMETRY.profile("diagonal").is_empty(), "No fake diagonal/rotated fallback")
	print("Collaboration table tests: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
