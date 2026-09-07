extends SceneTree
## DEV-ONLY rendered evidence integrity and exact-native six-frame contact grids.
const OUTPUT := "res://tests/output/west-supported-layers"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func load_image(path: String) -> Image:
	var image := Image.load_from_file(path)
	check(image != null and not image.is_empty(), "Image exists: " + path)
	image.convert(Image.FORMAT_RGBA8)
	return image

func run() -> void:
	var path := OUTPUT.path_join("manifest.json")
	check(FileAccess.file_exists(path), "Rendered layer manifest exists")
	if not FileAccess.file_exists(path):
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(manifest.status == "source_preserving_supported_candidates_not_runtime_approved" and manifest.production_or_source_changed == false and manifest.worker_disabled == true, "No false production or art approval")
	check(manifest.failures.is_empty(), "Rendered source-reunion assertions passed")
	check(manifest.observations.size() == 36 and manifest.captures.size() == 39, "Two employees × three cuts × six frames,27stills+12details")
	check(int(manifest.source_actor_pixels_compared) == 138240 and int(manifest.source_chair_pixels_compared) == 15360, "Every source frame/cut and whole chair verified byte-exact")
	check(int(manifest.rendered_actor_reunion_pixels_compared) == 737280 and int(manifest.rendered_chair_reunion_pixels_compared) == 122880, "Actual renderer reunions cover every actor frame and every chair assembly")
	var images: Dictionary = {}
	for file: String in manifest.captures:
		var image := load_image(OUTPUT.path_join(file))
		images[file] = image
		check(image.get_size() == (Vector2i(512, 640) if "4x" in file else Vector2i(1280, 720)), "Evidence is native viewport or exact4× detail")
	for mode: String in ["native", "support"]:
		var sheet := Image.create(768, 960, false, Image.FORMAT_RGBA8)
		for row: int in range(2):
			var id_value := "mira" if row == 0 else "theo"
			for column: int in range(3):
				var cut := (50 if row == 0 else 48) + column * 2
				var area := Rect2i(224 + column * 320, 192 + row * 248, 128, 160)
				for frame: int in range(6):
					var frame_image: Image = images["%s-frame%d.png" % [mode, frame]]
					sheet.blit_rect(frame_image, area, Vector2i(frame * 128, (row * 3 + column) * 160))
				var expected: Image = (images["%s-frame2.png" % mode] as Image).get_region(area)
				expected.resize(512, 640, Image.INTERPOLATE_NEAREST)
				check(expected.get_data() == (images["%s-frame2-%s-cut%d-4x.png" % [mode, id_value, cut]] as Image).get_data(), "Detail is exact nearest4×, not rerendered artwork")
		check(sheet.save_png(OUTPUT.path_join("all-six-%s-native-contact.png" % mode)) == OK, "Save all six frames at unchanged native scale")
	for record: Dictionary in manifest.observations:
		check(int(record.hand_roi_below_cut) == 0, "Reviewed hand-region pixels are preserved by every candidate cut")
		check(int(record.hip_minus_seat[0]) == 0 and int(record.hip_minus_seat[1]) == 2, "Actual per-character offsets agree with source hip/cushion estimates")
		if int(record.cut) == (50 if record.id == "mira" else 48):
			check(int(record.upper_lap_roi_pixels_still_over_top) == 0, "First per-character cut removes measured foreground lap conflict in every frame")
			check(int(record.hand_roi_on_key_bed) > 0, "Every preferred-cut frame has actual opaque hand-region overlap with key bed")
	# Expose every preferred-cut source frame at4× without creating a huge
	# downscaled sheet. Two three-frame strips per person include loop endpoints.
	for row: int in range(2):
		var id_value := "mira" if row == 0 else "theo"
		for half: int in range(2):
			var strip := Image.create(384, 160, false, Image.FORMAT_RGBA8)
			for index: int in range(3):
				var frame := half * 3 + index
				strip.blit_rect(images["native-frame%d.png" % frame], Rect2i(224, 192 + row * 248, 128, 160), Vector2i(index * 128, 0))
			strip.resize(1536, 640, Image.INTERPOLATE_NEAREST)
			check(strip.save_png(OUTPUT.path_join("preferred-%s-frames%d-%d-4x.png" % [id_value, half * 3, half * 3 + 2])) == OK, "Save exact4× preferred-cut loop evidence")
	var report := FileAccess.open(OUTPUT.path_join("verification.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "contact_columns": "frames0..5", "contact_rows": "Mina cuts50/52/54, Theo cuts48/50/52", "scope": "exact source/pixel registration, contact estimates and fixture evidence; not a runtime walking/animation approval"}, "\t"))
	print("west_supported_layer_evidence: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
