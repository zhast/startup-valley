extends SceneTree
## Provider-free pixel regression for the measured-gutter locomotion export.
## Checks image content, not merely dimensions or differing frame hashes.

const OUTPUT := "res://tests/output/locomotion-export"
const CELL := Vector2i(48, 80)
const ACTORS: Array[String] = ["founder", "mira", "theo"]
const DIRECTIONS: Array[StringName] = [&"front", &"back", &"left", &"right"]

var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	for actor: String in ACTORS:
		check_actor(actor)
	check_detector()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "workerDisabled": true, "renderer": "none", "cell": [48, 80], "bodyEnvelope": 68, "headCenterX": 24, "footPlaneY": 72, "actors": measurements}, "\t"))
	print("locomotion_export: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_actor(actor: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/characters/%s-locomotion.png" % actor))
	check(image != null and image.get_size() == Vector2i(288, 320), actor + ": native 6×4 grid is 288×320")
	if image == null or image.get_size() != Vector2i(288, 320): return
	var imported := CharacterArt.locomotion_sheet(actor).get_image()
	check(imported != null and imported.get_size() == image.get_size(), actor + ": production texture imports the same atlas grid")
	if imported == null or imported.get_size() != image.get_size(): return
	var palette: Dictionary = {}
	var binary_alpha := true
	var imported_matches := true
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			palette[pixel.to_rgba32()] = true
			if pixel.a != 0.0 and pixel.a != 1.0: binary_alpha = false
			var imported_pixel := imported.get_pixel(x, y)
			if pixel.a != imported_pixel.a or (pixel.a > 0.0 and pixel != imported_pixel): imported_matches = false
	check(binary_alpha, actor + ": alpha is binary; no painted checkerboard or soft matte fringe")
	check(palette.size() <= 48, actor + ": all directions share one bounded 48-color palette")
	check(imported_matches, actor + ": production import uses the corrected pixels, not a stale pre-export texture")
	var rows: Array[Dictionary] = []
	for row: int in range(4):
		var fingerprints: Dictionary = {}
		var min_head := 80
		var max_head := 0
		var min_foot := 80
		var max_foot := 0
		var frame_measurements: Array[Dictionary] = []
		for column: int in range(6):
			var title := "%s %s/%d" % [actor, DIRECTIONS[row], column]
			var region := Rect2i(Vector2i(column * 48, row * 80), CELL)
			var frame := image.get_region(region)
			var bounds := frame.get_used_rect()
			var head := frame.get_region(Rect2i(0, 0, 48, 28)).get_used_rect()
			var components := silhouette_count(frame)
			check(CharacterArt.locomotion_region(DIRECTIONS[row], column) == Rect2(region), title + ": runtime addresses the exact native cell")
			check(components == 1, title + ": exactly one connected character; no neighboring-row boots or isolated islands")
			check(Rect2i(2, 4, 44, 68).encloses(bounds), title + ": full silhouette has top/side/bottom padding and no clipped edge")
			check(bounds.size.y >= 66 and bounds.size.y <= 68, title + ": physical height stays within the 68px envelope, never the old 59px side body")
			check(head.position.x + head.size.x / 2 == 24, title + ": head center remains registered independently of swinging hands")
			check(head.position.y in [4, 5], title + ": head stays at the shared top anchor within one native pixel")
			check(bounds.end.y in [71, 72], title + ": complete shoes remain on or one pixel above the foot plane")
			min_head = mini(min_head, head.position.y)
			max_head = maxi(max_head, head.position.y)
			min_foot = mini(min_foot, bounds.end.y)
			max_foot = maxi(max_foot, bounds.end.y)
			fingerprints[hash(frame.get_data())] = true
			frame_measurements.append({"column": column, "bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "head": [head.position.x, head.position.y, head.size.x, head.size.y], "components": components})
		check(fingerprints.size() == 6, "%s row%d: both idles and four walks retain distinct authored frames" % [actor, row])
		check(max_head - min_head <= 1 and max_foot - min_foot <= 1, "%s row%d: animation has no crop-induced head/foot hopping" % [actor, row])
		rows.append({"row": row, "direction": DIRECTIONS[row], "frames": frame_measurements})
	measurements[actor] = {"paletteSize": palette.size(), "binaryAlpha": binary_alpha, "rows": rows}

func check_detector() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/characters/mira-locomotion.png"))
	var frame := source.get_region(Rect2i(0, 160, 48, 80))
	check(silhouette_count(frame) == 1, "Corrected Mina west idle is a single silhouette")
	# In-memory diagnostic fault only: proves the test catches the historical
	# export shape even when dimensions, native scale and animation hashes pass.
	frame.set_pixel(24, 0, Color.BROWN)
	frame.set_pixel(25, 0, Color.BROWN)
	check(silhouette_count(frame) == 2, "Detector rejects detached above-bun pixels, not just malformed atlas dimensions")

func silhouette_count(image: Image) -> int:
	var seen: Dictionary[Vector2i, bool] = {}
	var result := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var first := Vector2i(x, y)
			if seen.has(first) or image.get_pixelv(first).a < 0.5: continue
			result += 1
			var pending: Array[Vector2i] = [first]
			seen[first] = true
			while not pending.is_empty():
				var current: Vector2i = pending.pop_back()
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var next := current + Vector2i(dx, dy)
						if next.x < 0 or next.y < 0 or next.x >= image.get_width() or next.y >= image.get_height(): continue
						if seen.has(next) or image.get_pixelv(next).a < 0.5: continue
						seen[next] = true
						pending.append(next)
	return result
