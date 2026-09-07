extends SceneTree
## Dev-only export contract/evidence checks; no production-facing approval.
const EXPORT := preload("res://tools/export_modular_desk_layers.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
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

func array_rect(values: Array) -> Rect2i:
	return Rect2i(int(values[0]), int(values[1]), int(values[2]), int(values[3]))

func image_at(path: String) -> Image:
	check(FileAccess.file_exists(path), "Evidence exists: " + path)
	if not FileAccess.file_exists(path): return Image.create(192, 224, false, Image.FORMAT_RGBA8)
	return EXPORT.rgba(Image.load_from_file(ProjectSettings.globalize_path(path)))

func expected_bounds(direction: String, layer: String) -> Rect2i:
	if direction in ["east", "west"]:
		return Rect2i(80, 80 if layer != "front" else 84, 32, 96 if layer == "rear" else (124 if layer == "front" else 128))
	if direction == "south" and layer == "rear": return Rect2i(52, 114, 88, 30)
	if direction == "north" and layer == "rear": return Rect2i(48, 112, 96, 32)
	if direction == "north" and layer == "front": return Rect2i(48, 144, 96, 32)
	return Rect2i(48, 112, 96, 64)

func preflight() -> void:
	check(EXPORT.CANVAS == Vector2i(192, 224) and EXPORT.PIVOT == Vector2i(96, 160), "All views share full192×224 / pivot96,160")
	check(EXPORT.explicit_profile("diagonal").is_empty(), "Unknown geometry remains unavailable")
	for source: Dictionary in EXPORT.source_records():
		check(not str(source.sha256).is_empty(), "Provenance source readable: " + str(source.path))
	for path: String in [EXPORT.HORIZONTAL, EXPORT.VERTICAL]:
		var tile := Image.load_from_file(ProjectSettings.globalize_path(path))
		check(tile.get_size() == Vector2i(32, 32), "Selected material is native32×32")
		var measured := EXPORT.analyze(tile)
		check(measured.opaque_pixels == 1024 and measured.partial_alpha_pixels == 0, "Surface material is intentionally opaque")
		check(measured.opaque_colors == 3, "Selected soft tile uses measured three-color palette")
	for direction: String in DESK.DIRECTIONS:
		var p: Dictionary = DESK.profile(direction)
		var record := EXPORT.explicit_profile(direction)
		check(array_rect(record.top_plane) == p.top and array_rect(record.floor_plane) == p.floor, direction + " explicit top/floor preserved")
		check(record.top_layer == p.top_layer and record.material_axis == p.material_axis, direction + " explicit top ownership/material axis preserved")
		check(p.floor.position.y - p.top.position.y == 32, direction + " unchanged32px elevation")
		check(not record.has("seat_anchor") and not record.has("seat_reference"), direction + " rejected helper seat placeholder not exported as socket")
		for layer: String in ["rear", "front"]:
			var d := EXPORT.layer_descriptor(direction, layer, {"opaque_bounds": EXPORT.rect_values(expected_bounds(direction, layer))})
			check(array_rect(d.region) == Rect2i(Vector2i.ZERO, EXPORT.CANVAS), direction + layer + " full native region")
			check(Vector2i(d.offset[0], d.offset[1]) - EXPORT.CANVAS / 2 == -EXPORT.PIVOT, direction + layer + " centered canonical offset preserves pivot")
			check(d.z_offset == (-1 if layer == "rear" else 1), direction + layer + " original relative depth")
			check(not d.has("scale") and not d.has("rotation") and not d.has("flip_h") and not d.has("flip_v"), direction + layer + " no rotation, scale or mirror capability")
			check(record.geometry_parts[layer].size() == p[layer].size(), direction + layer + " all explicit leg/rail/apron pieces retained")

func verify_exports() -> void:
	var manifest_path := EXPORT.OUTPUT.path_join("manifest.json")
	check(FileAccess.file_exists(manifest_path), "Export manifest exists")
	if not FileAccess.file_exists(manifest_path): return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	check(manifest.status == "dev_candidate_not_runtime_ready" and not manifest.assembly_approval and not manifest.runtime_registered, "Export cannot imply production/art approval")
	check(manifest.worker_disabled and manifest.filter == "nearest" and manifest.pixel_scale == 1, "Worker-free native sampling declared")
	check(manifest.failures.is_empty(), "Renderer export checks passed")
	check(manifest.directions.size() == 4, "Exactly four explicit export directions")
	for source: Dictionary in manifest.source_files:
		check(FileAccess.get_sha256(str(source.path)) == str(source.sha256), "Geometry/material provenance unchanged since export")
	var sheet := image_at(EXPORT.EVIDENCE.path_join("assembled-native.png"))
	var large := image_at(EXPORT.EVIDENCE.path_join("assembled-4x.png"))
	var layers_sheet := image_at(EXPORT.EVIDENCE.path_join("layers-native.png"))
	check(sheet.get_size() == Vector2i(768, 224), "Four unchanged full canvases form native contact sheet")
	check(layers_sheet.get_size() == Vector2i(768, 672), "Layer proof preserves whole/rear/front rows")
	var expected_large := sheet.duplicate() as Image
	expected_large.resize(3072, 896, Image.INTERPOLATE_NEAREST)
	check(large.get_size() == Vector2i(3072, 896) and large.get_data() == expected_large.get_data(), "4× sheet is exact point enlargement, no smoothing")
	for column: int in range(DESK.DIRECTIONS.size()):
		var direction: String = DESK.DIRECTIONS[column]
		var record: Dictionary = manifest.directions[column]
		check(record.facing == direction, "Manifest N/E/S/W order")
		check(array_rect(record.top_plane) == DESK.profile(direction).top, direction + " recorded top geometry")
		var rear := image_at(EXPORT.OUTPUT.path_join(direction + "-rear.png"))
		var front := image_at(EXPORT.OUTPUT.path_join(direction + "-front.png"))
		var whole := image_at(EXPORT.EVIDENCE.path_join(direction + "-whole.png"))
		var images: Array[Image] = [whole, rear, front]
		for row: int in range(3):
			var layer: String = ["whole", "rear", "front"][row]
			var image := images[row]
			check(image.get_size() == EXPORT.CANVAS, direction + layer + " full padded export")
			var measured := EXPORT.analyze(image)
			check(measured.partial_alpha_pixels == 0 and measured.transparent_pixels > 0 and measured.hidden_rgb_pixels == 0, direction + layer + " true clean binary alpha")
			check(array_rect(measured.opaque_bounds) == expected_bounds(direction, layer), direction + layer + " measured ink bounds match unchanged geometry")
			var declared: Dictionary = record.measurements[layer]
			var same_measurements := array_rect(measured.opaque_bounds) == array_rect(declared.opaque_bounds)
			for key: String in ["opaque_pixels", "transparent_pixels", "partial_alpha_pixels", "hidden_rgb_pixels", "opaque_colors"]:
				same_measurements = same_measurements and int(measured[key]) == int(declared[key])
			check(same_measurements, direction + layer + " decoded measurements agree with JSON numeric values")
			check(image.get_data() == layers_sheet.get_region(Rect2i(column * 192, row * 224, 192, 224)).get_data(), direction + layer + " layer contact crop byte-exact")
		var joined := EXPORT.binary_over(rear, front)
		check(joined.get_data() == whole.get_data(), direction + " rear/front union reconstructs actual whole-render RGBA byte-exact")
		check(whole.get_data() == sheet.get_region(Rect2i(column * 192, 0, 192, 224)).get_data(), direction + " native sheet is not scaled/recentered")
		check(EXPORT.digest(joined.get_data()) == record.reconstruction_rgba_sha256, direction + " reconstruction digest")
		var detail := image_at(EXPORT.EVIDENCE.path_join(direction + "-whole-4x.png"))
		var expected_detail := whole.duplicate() as Image
		expected_detail.resize(768, 896, Image.INTERPOLATE_NEAREST)
		check(detail.get_size() == Vector2i(768, 896) and detail.get_data() == expected_detail.get_data(), direction + " native4× detail is exact point enlargement")
		check(int(record.measurements.whole.opaque_bounds[1]) + int(record.measurements.whole.opaque_bounds[3]) == EXPORT.PIVOT.y + int(record.contact_boundary_y), direction + " exact near floor contact")
		var canonical := OfficeLayout.render_layers({"render_layers": record.render_layers}, "desk")
		check(canonical.size() == 2 and canonical[0].name == "ModularDeskRear" and canonical[1].name == "ModularDeskFront", direction + " existing canonical layer reader preserves descriptor order")
		for layer_index: int in range(2):
			var d: Dictionary = record.render_layers[layer_index]
			var measured := EXPORT.analyze(rear if layer_index == 0 else front)
			check(array_rect(d.content_bounds) == array_rect(measured.opaque_bounds), direction + " canonical content bounds do not include padding")
			var texture := load(str(d.art)) as Texture2D
			check(texture != null and texture.get_size() == Vector2(EXPORT.CANVAS), direction + " native layer is importable without resizing")
			check(texture != null and EXPORT.rgba(texture.get_image()).get_data() == (rear if layer_index == 0 else front).get_data(), direction + " import preserves exact exported pixels")
			var settings := ConfigFile.new()
			var loaded := settings.load(str(d.art) + ".import") == OK
			check(loaded and settings.get_value("params", "compress/mode", -1) == 0 and settings.get_value("params", "process/fix_alpha_border", true) == false and settings.get_value("params", "mipmaps/generate", true) == false, direction + " tracked lossless/no-border-fill/no-mipmap import policy")
		# Prove the comparison would fail if a real native output lost one pixel.
		var damaged := front.duplicate() as Image
		var bounds := expected_bounds(direction, "front")
		var changed := false
		for y: int in range(bounds.position.y, bounds.end.y):
			for x: int in range(bounds.position.x, bounds.end.x):
				if damaged.get_pixel(x, y).a > 0.0:
					damaged.set_pixel(x, y, Color(1, 0, 1, 1))
					changed = true
					break
			if changed: break
		check(EXPORT.binary_over(rear, damaged).get_data() != whole.get_data(), direction + " negative control detects modified layer pixel")

func run() -> void:
	preflight()
	if not OS.get_cmdline_user_args().has("--preflight"): verify_exports()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORT.EVIDENCE))
	var file := FileAccess.open(EXPORT.EVIDENCE.path_join("results-preflight.json" if OS.get_cmdline_user_args().has("--preflight") else "results-headless.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"checks": checks, "failures": failures, "worker_disabled": true, "runtime_approved": false, "renderer": DisplayServer.get_name()}, "\t") + "\n")
	print("Modular desk export tests: %d checks, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
