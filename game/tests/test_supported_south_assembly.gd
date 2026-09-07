extends SceneTree
## DEV-ONLY evidence verification; does not run the game or modify any assets.
const OUTPUT := "res://tests/output/supported-south-assembly"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func load_png(name_value: String) -> Image:
	var image := Image.load_from_file(OUTPUT.path_join(name_value))
	check(image != null and not image.is_empty(), "Evidence exists: " + name_value)
	return image

func differences(a: Image, b: Image) -> int:
	var changed := 0
	for y: int in range(a.get_height()):
		for x: int in range(a.get_width()):
			if a.get_pixel(x, y) != b.get_pixel(x, y): changed += 1
	return changed

func run() -> void:
	var manifest_path := OUTPUT.path_join("manifest.json")
	check(FileAccess.file_exists(manifest_path), "Rendered south manifest exists")
	if not FileAccess.file_exists(manifest_path):
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	check(manifest.status == "diagnostic_not_runtime_approval" and manifest.production_changed == false and manifest.worker_disabled == true, "Evidence cannot imply production approval, mutation, or provider work")
	check(manifest.failures.is_empty() and int(manifest.checks) >= 1010, "Rendered harness has passed geometry, UI isolation, and depth assertions")
	check(int(manifest.logical_work_foot[1]) == -32 and int(manifest.chair_render_y) == 0, "Actual legacy logical foot and fixed chair stay explicit")
	check(manifest.observations.size() == 36 and manifest.captures.size() == 26, "All six frames × two employees × three candidates and14native+12detail captures are recorded")
	for record: Dictionary in manifest.observations:
		check(int(record.head_hidden_by_top_or_monitor) == 0, "Measured head visibility remains intact")
		check(int(record.foot_endpoint_jump_px) == int(record.actor_render_y), "Diagnostic never hides unimplemented sit endpoint displacement")
	var images: Dictionary = {}
	for name_value: String in manifest.captures:
		var image := load_png(name_value)
		images[name_value] = image
		check(image.get_size() == (Vector2i(640, 640) if "4x" in name_value else Vector2i(1280, 720)), "Evidence dimensions are native viewport or exact4×crop")
	var motion: Array[Dictionary] = []
	for row: int in range(2):
		var id_value := "mira" if row == 0 else "theo"
		for column: int in range(3):
			var shift: int = [0, 8, 12][column]
			var area := Rect2i(200 + column * 304, 180 + row * 248, 160, 160)
			var native_frames: Array[Image] = []
			var support_frames: Array[Image] = []
			for frame: int in range(6):
				native_frames.append((images["native-frame%d.png" % frame] as Image).get_region(area))
				support_frames.append((images["support-frame%d.png" % frame] as Image).get_region(area))
			for mode: String in ["native", "support"]:
				var expected: Image = native_frames[2].duplicate() if mode == "native" else support_frames[2].duplicate()
				expected.resize(640, 640, Image.INTERPOLATE_NEAREST)
				check(differences(expected, images["%s-frame2-%s-y%d-4x.png" % [mode, id_value, shift]]) == 0, "Native detail is exactly nearest-neighbor4×, no invented detail")
			var native_diffs: Array[int] = []
			var support_diffs: Array[int] = []
			for frame: int in range(2, 6):
				var next := 2 + (frame - 1) % 4
				native_diffs.append(differences(native_frames[frame], native_frames[next]))
				support_diffs.append(differences(support_frames[frame], support_frames[next]))
				check(support_diffs.back() > 0, "Every typing transition changes actual source pixels when desk/monitor hidden")
			check(differences(native_frames[0], native_frames[1]) > 0, "Idle blink pair is visible at actual native resolution")
			motion.append({"id": id_value, "actor_render_y": shift, "typing_adjacent_native_changed_pixels": native_diffs, "typing_adjacent_unoccluded_changed_pixels": support_diffs, "typing_fully_hidden_steps": native_diffs.count(0), "important": "This measures visible changes, not natural motion quality or hand contact."})
	var report := FileAccess.open(OUTPUT.path_join("verification.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "motion": motion, "meaning": "evidence integrity, not runtime art acceptance"}, "\t"))
	print("supported_south_evidence: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
