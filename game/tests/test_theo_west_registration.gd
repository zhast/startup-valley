extends SceneTree
const SOURCE := "res://tests/fixtures/furniture-calibration/characters/theo-west-seated-v3.png"
const REGISTERED := "res://tests/fixtures/furniture-calibration/characters/theo-west-seated-v3-registered.png"
const OUTPUT := "res://tests/output/theo-west-registration"
const Y_OFFSETS: Array[int] = [0, 0, -1, -1, -1, 0]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func opaque_count(image: Image) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.5: count += 1
	return count

func run() -> void:
	var source := Image.load_from_file(SOURCE)
	var candidate := Image.load_from_file(REGISTERED)
	source.convert(Image.FORMAT_RGBA8)
	candidate.convert(Image.FORMAT_RGBA8)
	check(source.get_size() == Vector2i(288, 80) and candidate.get_size() == Vector2i(288, 80), "Both atlases retain six48×80 cells")
	check(FileAccess.get_sha256(SOURCE) == "889b5163cda84ef4d366acef86ca34133a7ac8133d483871da9cf319498c6dff", "Original native-v3 unchanged")
	var observations: Array[Dictionary] = []
	for frame: int in range(6):
		var original := source.get_region(Rect2i(frame * 48, 0, 48, 80))
		var actual := candidate.get_region(Rect2i(frame * 48, 0, 48, 80))
		var expected := Image.create(48, 80, false, Image.FORMAT_RGBA8)
		expected.blit_rect(original, Rect2i(0, 0, 48, 80), Vector2i(0, Y_OFFSETS[frame]))
		check(expected.get_data() == actual.get_data(), "Candidate is only the explicit integer translation, frame%d" % frame)
		var inverse := Image.create(48, 80, false, Image.FORMAT_RGBA8)
		inverse.blit_rect(actual, Rect2i(0, 0, 48, 80), Vector2i(0, -Y_OFFSETS[frame]))
		check(inverse.get_data() == original.get_data(), "Inverse translation reproduces every source RGBA byte")
		check(opaque_count(original) == opaque_count(actual), "No opaque pixels clipped or invented")
		var before := original.get_used_rect()
		var after := actual.get_used_rect()
		check(after.position.y == 4, "Measured opaque head top stabilizes at row4")
		check(Rect2i(1, 1, 46, 78).encloses(after), "Every nontransparent pixel remains inside native padding")
		check(after.position.x == before.position.x and after.size == before.size, "No horizontal shift or image scaling")
		for part: String in ["upper", "lower"]:
			var original_part := Image.create(48, 80, false, Image.FORMAT_RGBA8)
			var original_region := Rect2i(0, 0, 48, 48) if part == "upper" else Rect2i(0, 48, 48, 32)
			original_part.blit_rect(original, original_region, original_region.position)
			var shifted_cut := 48 + Y_OFFSETS[frame]
			var shifted_region := Rect2i(0, 0, 48, shifted_cut) if part == "upper" else Rect2i(0, shifted_cut, 48, 80 - shifted_cut)
			var actual_part := Image.create(48, 80, false, Image.FORMAT_RGBA8)
			actual_part.blit_rect(actual, shifted_region, shifted_region.position)
			var expected_part := Image.create(48, 80, false, Image.FORMAT_RGBA8)
			expected_part.blit_rect(original_part, Rect2i(0, 0, 48, 80), Vector2i(0, Y_OFFSETS[frame]))
			check(expected_part.get_data() == actual_part.get_data(), "Translated %s preserves original layer ownership in frame%d" % [part, frame])
			var inverse_part := Image.create(48, 80, false, Image.FORMAT_RGBA8)
			inverse_part.blit_rect(actual_part, Rect2i(0, 0, 48, 80), Vector2i(0, -Y_OFFSETS[frame]))
			check(inverse_part.get_data() == original_part.get_data(), "Inverse %s translation restores original source region" % part)
		var shifted_lap_start := 48 + Y_OFFSETS[frame]
		observations.append({"frame": frame, "translation_y": Y_OFFSETS[frame], "before_head_row": before.position.y, "after_head_row": after.position.y, "before_sole_row": before.end.y - 1, "after_sole_row": after.end.y - 1, "source_pants_roi_start_after_translation": shifted_lap_start, "unchanged_upper_cut": 48, "registration_only": true})
	if "--verify-capture" in OS.get_cmdline_user_args():
		verify_capture()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var file := FileAccess.open(OUTPUT.path_join("source-verification.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "source_unchanged": true, "pixels_checked_each_direction": 23040, "separate_layer_mask_pixels_checked_each_direction": 46080, "candidate": REGISTERED, "observations": observations, "approval": "No runtime approval; preferred source-aware cuts and native limits documented in THEO_WEST_REGISTRATION_REVIEW.md"}, "\t"))
	print("theo_west_registration: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func verify_capture() -> void:
	var aware := "--source-aware-cuts" in OS.get_cmdline_user_args()
	var evidence_path := OUTPUT.path_join("source-aware-cuts") if aware else OUTPUT
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence_path.path_join("manifest.json")))
	check(manifest.failures.is_empty() and manifest.worker_disabled and not manifest.production_changed, "Rendered comparison remains an isolated successful dev fixture")
	check(manifest.observations.size() == 12, "All six frames of both variants were measured")
	check(manifest.captures.size() == 45, "Six native images,36 nearest details,three native contacts exist")
	var expected_lap: Array[int] = [0, 0, 13, 13, 12, 0]
	var key_counts: Dictionary = {}
	for result: Dictionary in manifest.observations:
		var frame := int(result.frame)
		var expected_cut := 48 + (Y_OFFSETS[frame] if aware and result.variant == "registered" else 0)
		check(int(result.cut) == expected_cut and result.actor_from_logical == [-12.0, 8.0], "Socket and explicit per-frame layer cut stay declared")
		check(int(result.hand_roi_below_cut) == 0, "No reviewed hand-region pixel moves under the top")
		if result.variant == "original":
			key_counts[frame] = result.hand_roi_on_keys
			check(int(result.foreground_lap_roi_pixels) == 0, "Original preferred cut has no foreground lap ROI")
		else:
			check(int(result.foreground_lap_roi_pixels) == (0 if aware else expected_lap[frame]), "Source-aware analysis retains exact observed lap ownership outcome")
			check(result.hand_roi_on_keys == key_counts[frame], "One-pixel shift retains same measured key overlap, not invented contact")
	for path: String in manifest.captures:
		var image := Image.load_from_file(evidence_path.path_join(path))
		var expected := Vector2i(512, 640) if path.ends_with("-4x.png") else Vector2i(768, 320) if path.begins_with("all-six-") else Vector2i(1280, 720)
		check(image != null and image.get_size() == expected, "Evidence has declared native/detail dimensions: " + path)
