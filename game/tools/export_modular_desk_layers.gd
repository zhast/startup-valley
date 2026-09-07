extends SceneTree
## DEV-ONLY native raster export of existing code geometry and generated tiles.
## No ImageGen, semantic bitmap edit, production registration, worker or save.

const GEOMETRY := preload("res://tools/modular_desk_geometry.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/modular-desk-v1"
const EVIDENCE := "res://tests/output/modular-desk-export"
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const HORIZONTAL := "res://tests/fixtures/furniture-calibration/materials/oak-horizontal-v1-soft.png"
const VERTICAL := "res://tests/fixtures/furniture-calibration/materials/oak-vertical-v1-soft.png"
const SOURCE_FILES: Array[String] = [
	"res://tools/modular_desk_geometry.gd", "res://tools/export_modular_desk_layers.gd", HORIZONTAL, VERTICAL,
	"res://assets/source/overnight-20260904/materials/oak-horizontal-v1.png",
	"res://assets/source/overnight-20260904/materials/oak-vertical-v1.png",
	"res://../dev/art-catalogue/oak-material-palette-soft.svg",
]

var checks := 0
var failures: Array[String] = []
var views: Dictionary = {}

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

static func rect_values(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

static func rgba(image: Image) -> Image:
	var result := image.duplicate() as Image
	result.convert(Image.FORMAT_RGBA8)
	return result

static func analyze(image: Image) -> Dictionary:
	var pixels := rgba(image).get_data()
	var low := image.get_size()
	var high := Vector2i(-1, -1)
	var opaque := 0
	var partial := 0
	var hidden_rgb := 0
	var colors: Dictionary = {}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var at := (y * image.get_width() + x) * 4
			var alpha := int(pixels[at + 3])
			if alpha == 0:
				if pixels[at] != 0 or pixels[at + 1] != 0 or pixels[at + 2] != 0:
					hidden_rgb += 1
				continue
			opaque += 1
			if alpha != 255: partial += 1
			low = Vector2i(mini(low.x, x), mini(low.y, y))
			high = Vector2i(maxi(high.x, x), maxi(high.y, y))
			colors[pixels.slice(at, at + 4).hex_encode()] = true
	return {"opaque_bounds": rect_values(Rect2i(low, high - low + Vector2i.ONE)) if opaque > 0 else [0, 0, 0, 0],
		"opaque_pixels": opaque, "transparent_pixels": image.get_width() * image.get_height() - opaque,
		"partial_alpha_pixels": partial, "hidden_rgb_pixels": hidden_rgb, "opaque_colors": colors.size()}

static func binary_over(rear: Image, front: Image) -> Image:
	# Both layers are renderer-produced binary alpha. Select exact original RGBA
	# bytes, avoiding arithmetic color-space/rounding differences from blend_rect.
	var back := rgba(rear).get_data()
	var near := rgba(front).get_data()
	var result := back.duplicate()
	for at: int in range(0, result.size(), 4):
		if near[at + 3] != 0:
			for channel: int in range(4): result[at + channel] = near[at + channel]
	return Image.create_from_data(rear.get_width(), rear.get_height(), false, Image.FORMAT_RGBA8, result)

static func digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

static func layer_descriptor(direction: String, layer: String, measured: Dictionary) -> Dictionary:
	return {"name": "ModularDesk" + layer.capitalize(),
		"art": OUTPUT.path_join(direction + "-" + layer + ".png"),
		"region": [0, 0, CANVAS.x, CANVAS.y], "offset": [0, -48],
		"z_offset": -1 if layer == "rear" else 1,
		"content_bounds": measured.opaque_bounds}

static func explicit_profile(direction: String) -> Dictionary:
	var original: Dictionary = GEOMETRY.profile(direction)
	if original.is_empty(): return {}
	var pieces: Dictionary = {}
	for layer: String in ["rear", "front"]:
		var parts: Array[Dictionary] = []
		for part: Dictionary in original[layer]:
			parts.append({"rect": rect_values(part.rect), "color_rgba": (part.color as Color).to_html(true)})
		pieces[layer] = parts
	return {"facing": direction, "canvas_size_px": [CANVAS.x, CANVAS.y],
		"floor_anchor_px": [PIVOT.x, PIVOT.y], "top_plane": rect_values(original.top),
		"floor_plane": rect_values(original.floor), "contact_boundary_y": int(original.contact_y),
		"top_layer": original.top_layer, "material_axis": original.material_axis, "geometry_parts": pieces,
		"seat_reference_status": "Original geometry helper seat_reference is a rejected/off-grid placeholder; deliberately not exported as a usable socket."}

static func source_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for path: String in SOURCE_FILES:
		result.append({"path": path, "sha256": FileAccess.get_sha256(path)})
	return result

func make_view(direction: String, visible_layer: String) -> SubViewport:
	var view := SubViewport.new()
	view.name = direction.capitalize() + visible_layer.capitalize()
	view.size = CANVAS
	view.transparent_bg = true
	view.disable_3d = true
	view.msaa_2d = Viewport.MSAA_DISABLED
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	view.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var desk := GEOMETRY.new()
	desk.position = Vector2(PIVOT)
	view.add_child(desk)
	var h := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(HORIZONTAL)))
	var v := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(VERTICAL)))
	check(desk.configure(direction, h, v), direction + " uses unchanged native geometry and materials")
	check(desk.scale == Vector2.ONE and desk.rotation == 0.0, direction + " native transform")
	check(desk.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, direction + " nearest material sampling")
	if visible_layer == "rear": desk.front.hide()
	if visible_layer == "front": desk.rear.hide()
	return view

func save_png(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Save " + path)
	var loaded := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(not loaded.is_empty() and rgba(loaded).get_data() == rgba(image).get_data(), "PNG roundtrip preserves exact bytes: " + path)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native desk export needs a real rendered backend; use test_modular_desk_export.gd -- --preflight for headless checks.")
		quit(1)
		return
	root.size = Vector2i(800, 320)
	root.content_scale_size = Vector2i(800, 320)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var sources := source_records()
	for source: Dictionary in sources: check(not str(source.sha256).is_empty(), "Provenance file exists: " + str(source.path))
	for direction: String in GEOMETRY.DIRECTIONS:
		views[direction] = {}
		for layer: String in ["whole", "rear", "front"]:
			views[direction][layer] = make_view(direction, layer)
	for frame: int in range(3): await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var profiles: Array[Dictionary] = []
	var native_sheet := Image.create(4 * CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	var layers_sheet := Image.create(4 * CANVAS.x, 3 * CANVAS.y, false, Image.FORMAT_RGBA8)
	layers_sheet.fill(Color(0, 0, 0, 0))
	for column: int in range(GEOMETRY.DIRECTIONS.size()):
		var direction: String = GEOMETRY.DIRECTIONS[column]
		var images: Dictionary = {}
		var measurements: Dictionary = {}
		var descriptors: Array[Dictionary] = []
		for row: int in range(3):
			var layer: String = ["whole", "rear", "front"][row]
			var view: SubViewport = views[direction][layer]
			var image := rgba(view.get_texture().get_image())
			check(image.get_size() == CANVAS, direction + " " + layer + " full registered canvas")
			images[layer] = image
			var measured := analyze(image)
			measurements[layer] = measured
			check(measured.opaque_pixels > 0 and measured.transparent_pixels > 0, direction + " " + layer + " real transparent surround")
			check(measured.partial_alpha_pixels == 0, direction + " " + layer + " binary alpha avoids blend rounding")
			check(measured.hidden_rgb_pixels == 0, direction + " " + layer + " transparent RGB is zero")
			layers_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, CANVAS), Vector2i(column * CANVAS.x, row * CANVAS.y))
			if layer == "whole":
				save_png(image, EVIDENCE.path_join(direction + "-whole.png"))
				var detail := image.duplicate() as Image
				detail.resize(CANVAS.x * 4, CANVAS.y * 4, Image.INTERPOLATE_NEAREST)
				save_png(detail, EVIDENCE.path_join(direction + "-whole-4x.png"))
				native_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, CANVAS), Vector2i(column * CANVAS.x, 0))
			else:
				save_png(image, OUTPUT.path_join(direction + "-" + layer + ".png"))
				descriptors.append(layer_descriptor(direction, layer, measured))
		var reconstructed := binary_over(images.rear, images.front)
		check(reconstructed.get_data() == (images.whole as Image).get_data(), direction + " rear+front reconstruct whole renderer byte-exact")
		var profile := explicit_profile(direction)
		var bound: Array = measurements.whole.opaque_bounds
		check(int(bound[1]) + int(bound[3]) == PIVOT.y + int(profile.contact_boundary_y), direction + " opaque floor contact is exact")
		check(bound[0] > 0 and bound[1] > 0 and int(bound[0]) + int(bound[2]) < CANVAS.x and int(bound[1]) + int(bound[3]) < CANVAS.y, direction + " unclipped transparent envelope")
		profile["render_layers"] = descriptors
		profile["measurements"] = measurements
		profile["reconstruction_rgba_sha256"] = digest(reconstructed.get_data())
		profile["hash_format"] = "SHA-256 of decoded RGBA bytes; not compressed PNG hash"
		profiles.append(profile)
	save_png(native_sheet, EVIDENCE.path_join("assembled-native.png"))
	save_png(layers_sheet, EVIDENCE.path_join("layers-native.png"))
	var enlarged := native_sheet.duplicate() as Image
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save_png(enlarged, EVIDENCE.path_join("assembled-4x.png"))
	check(source_records() == sources, "Geometry and source material files remain unchanged")
	var manifest := {"id": "modular-desk-v1", "status": "dev_candidate_not_runtime_ready",
		"provenance": "Renderer export of existing code-native geometry with generated soft oak material. No new image generation or semantic bitmap alteration.",
		"worker_disabled": true, "renderer": DisplayServer.get_name(), "checks": checks, "failures": failures,
		"source_files": sources, "directions": profiles, "pixel_scale": 1, "filter": "nearest", "msaa_2d": "disabled",
		"assembly_approval": false, "runtime_registered": false,
		"limitations": ["Flat prototype leg finish is not approved finished art.", "No chair, actor, socket or walking/typing contact approval.", "Layers retain the helper's explicit per-facing top/apron/cable rail/leg geometry; a reviewed assembly must select final actor depths."],
		"evidence": [EVIDENCE.path_join("assembled-native.png"), EVIDENCE.path_join("assembled-4x.png"), EVIDENCE.path_join("layers-native.png")]}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Open dev manifest")
	manifest["checks"] = checks
	manifest["failures"] = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	for direction: String in GEOMETRY.DIRECTIONS:
		for layer: String in ["whole", "rear", "front"]:
			(views[direction][layer] as SubViewport).free()
	print("Modular desk native export: %d checks, %d failures; no production approval." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
