extends SceneTree
## DEV-ONLY verify rendered evidence and make native-size frame contact sheets.
const OUTPUT := "res://tests/output/supported-west-assembly"
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
	check(image != null and not image.is_empty(), "Evidence image exists: " + path)
	image.convert(Image.FORMAT_RGBA8)
	return image

func run() -> void:
	var reports: Array[Dictionary] = []
	for variant: String in ["baseline", "height56"]:
		var folder := OUTPUT if variant == "baseline" else OUTPUT.path_join("height56")
		var path := folder.path_join("manifest.json")
		check(FileAccess.file_exists(path), "Manifest exists: " + variant)
		if not FileAccess.file_exists(path): continue
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(manifest.status == "known_mismatches_not_runtime_approval" and manifest.production_changed == false and manifest.worker_disabled == true, "No misleading runtime/worker approval")
		check(int(manifest.checks) >= 1176 and manifest.failures.is_empty(), "Actual rendered geometry/input fixture assertions passed")
		check(manifest.captures.size() == 40 and manifest.observations.size() == 36, "All16native+24detail images and36actor-frame observations exist")
		check(int(manifest.logical_work_foot[0]) == 32 and int(manifest.logical_work_foot[1]) == 0, "Outside physical cell unchanged")
		var images: Dictionary = {}
		for file: String in manifest.captures:
			var image := load_image(folder.path_join(file))
			images[file] = image
			check(image.get_size() == (Vector2i(512, 640) if "4x" in file else Vector2i(1280, 720)), "Evidence size equals native or exact4× crop")
		var contact_files: Array[String] = []
		for mode: String in ["native", "support"]:
			var sheet := Image.create(768, 960, false, Image.FORMAT_RGBA8)
			for row: int in range(2):
				for column: int in range(3):
					var area := Rect2i(224 + column * 320, 192 + row * 248, 128, 160)
					for frame: int in range(6):
						var frame_image: Image = images["%s-frame%d.png" % [mode, frame]]
						sheet.blit_rect(frame_image, area, Vector2i(frame * 128, (row * 3 + column) * 160))
			var contact := "all-six-%s-native-contact.png" % mode
			check(sheet.save_png(folder.path_join(contact)) == OK, "Save native-resolution frame grid (no rescaling)")
			contact_files.append(contact)
		var source_rows: Dictionary = {}
		for row: int in range(2):
			var id_value := "mira" if row == 0 else "theo"
			for column: int in range(3):
				var shift: int = [0, -8, -12][column]
				var area := Rect2i(224 + column * 320, 192 + row * 248, 128, 160)
				for prefix: String in ["native-frame2", "support-frame2", "whole-chair-front-frame2", "whole-body-below-top-frame2"]:
					var expected: Image = (images[prefix + ".png"] as Image).get_region(area)
					expected.resize(512, 640, Image.INTERPOLATE_NEAREST)
					var detail: Image = images["%s-%s-x%d-4x.png" % [prefix, id_value, shift]]
					check(expected.get_data() == detail.get_data(), "Exact4× crop retains every original rendered pixel")
			for frame: int in range(6):
				var record: Dictionary = manifest.observations.filter(func(value: Dictionary) -> bool: return value.id == id_value and int(value.frame) == frame and int(value.assembly_render_x) == 0)[0]
				source_rows["%s-frame%d" % [id_value, frame]] = [int(record.native_top_row), int(record.native_last_row)]
				check(int(record.head_hidden_by_monitor) == 0, "Monitor does not hide sampled upper head")
				check(int(record.leg_roi_pixels_over_top_if_body_in_front) > 0, "Known whole-body depth conflict remains explicit, not an art approval")
		check(source_rows["theo-frame0"] == [4, 70] and source_rows["theo-frame2"] == [5, 71], "Known Theo head/sole drift preserved exactly")
		reports.append({"variant": variant, "native_contact_sheets": contact_files, "source_rows": source_rows, "columns": "frames0..5", "rows": "MinaX0,-8,-12;TheoX0,-8,-12", "meaning": "No downscale: each128×160 cell is native assembly crop, not full-screen screenshot"})
	var report := FileAccess.open(OUTPUT.path_join("verification.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "variants": reports, "acceptance": "diagnostic integrity only; both assemblies still have known blockers"}, "\t"))
	print("supported_west_evidence: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
