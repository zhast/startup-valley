extends SceneTree
## DEV-ONLY native export for deterministic four-facing coffee geometry.
## Outputs remain calibration fixtures until an independent registration choice.
const COFFEE := preload("res://tools/coffee_station_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/coffee-station-candidate"
const EXPORT := "res://tests/fixtures/furniture-calibration/coffee-station-code-v1"
const MATERIALS := "res://tests/fixtures/furniture-calibration/materials/"
const HORIZONTAL := MATERIALS + "oak-horizontal-v1-soft.png"
const VERTICAL := MATERIALS + "oak-vertical-v1-soft.png"
const POWDERCOAT := MATERIALS + "charcoal-powdercoat-v1.png"
const SOURCE_FILES: Array[String] = [
	"res://tools/coffee_station_geometry.gd",
	"res://tools/modular_cabinet_geometry.gd",
	HORIZONTAL, VERTICAL, POWDERCOAT,
]
var checks := 0
var failures: Array[String] = []
var views: Dictionary = {}
var captures: Array[String] = []
var textures: Dictionary = {}

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func texture(path: String) -> Texture2D:
	if not textures.has(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		check(image != null and image.get_size() == Vector2i(32, 32), "Reviewed native material loads " + path)
		textures[path] = ImageTexture.create_from_image(image)
	return textures[path]

func make_view(side: String, visible_layer: String) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = side.capitalize() + visible_layer
	viewport.size = COFFEE.CANVAS
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var station := COFFEE.new()
	station.position = Vector2(COFFEE.PIVOT)
	viewport.add_child(station)
	check(station.configure(side, texture(HORIZONTAL), texture(VERTICAL), texture(POWDERCOAT)), side + " builds export view " + visible_layer)
	if visible_layer != "whole":
		for layer_name: String in COFFEE.LAYERS:
			(station.layers[layer_name] as CanvasItem).visible = layer_name == visible_layer
	return viewport

func save_png(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "Save " + path)
	var roundtrip := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(roundtrip != null and PIXELS.rgba(roundtrip).get_data() == PIXELS.rgba(image).get_data(), "Exact PNG roundtrip " + path)
	captures.append(path)

func settle() -> void:
	for frame: int in range(3): await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw

func layer_descriptor(side: String, layer_name: String, measured: Dictionary) -> Dictionary:
	return {"name": "Coffee" + layer_name,
		"art": EXPORT.path_join(side + "-" + layer_name.to_snake_case() + ".png"),
		"region": [0, 0, COFFEE.CANVAS.x, COFFEE.CANVAS.y], "offset": [0, -64],
		"z_offset": -1 if layer_name == "FloorShadow" else 0,
		"content_bounds": measured.opaque_bounds}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Coffee candidate export requires a rendered backend; run the focused geometry test headlessly.")
		quit(1)
		return
	root.size = Vector2i(960, 320)
	root.content_scale_size = Vector2i(960, 320)
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORT))
	var before_sources: Array[Dictionary] = []
	for path: String in SOURCE_FILES:
		var hash := FileAccess.get_sha256(path)
		check(not hash.is_empty(), "Source provenance exists " + path)
		before_sources.append({"path": path, "sha256": hash})
	for side: String in COFFEE.SIDES:
		views[side] = {}
		for layer_name: String in COFFEE.LAYERS + ["whole"]:
			views[side][layer_name] = make_view(side, layer_name)
	await settle()
	var directions: Array[Dictionary] = []
	var native_sheet := Image.create(COFFEE.CANVAS.x * 4, COFFEE.CANVAS.y, false, Image.FORMAT_RGBA8)
	native_sheet.fill(Color(0, 0, 0, 0))
	var layer_sheet := Image.create(COFFEE.CANVAS.x * 4, COFFEE.CANVAS.y * (COFFEE.LAYERS.size() + 1), false, Image.FORMAT_RGBA8)
	layer_sheet.fill(Color(0, 0, 0, 0))
	for column: int in range(COFFEE.SIDES.size()):
		var side: String = COFFEE.SIDES[column]
		var profile: Dictionary = COFFEE.profile(side)
		var station := ((views[side].whole as SubViewport).get_child(0)) as Node2D
		var order: Array[String] = station.render_order
		var images: Dictionary = {}
		var measurements: Dictionary = {}
		var descriptors: Array[Dictionary] = []
		var union := Image.create(COFFEE.CANVAS.x, COFFEE.CANVAS.y, false, Image.FORMAT_RGBA8)
		union.fill(Color(0, 0, 0, 0))
		for row: int in range(COFFEE.LAYERS.size() + 1):
			var layer_name: String = (COFFEE.LAYERS + ["whole"])[row]
			var image := PIXELS.rgba((views[side][layer_name] as SubViewport).get_texture().get_image())
			var measured := PIXELS.analyze(image)
			check(image.get_size() == COFFEE.CANVAS, side + " " + layer_name + " uses exact common canvas")
			check(measured.opaque_pixels > 0 and measured.transparent_pixels > 0, side + " " + layer_name + " has ink and transparent gutter")
			check(measured.partial_alpha_pixels == 0 and measured.hidden_rgb_pixels == 0, side + " " + layer_name + " has clean binary alpha")
			images[layer_name] = image
			measurements[layer_name] = measured
			layer_sheet.blit_rect(image, Rect2i(Vector2i.ZERO, COFFEE.CANVAS), Vector2i(column * COFFEE.CANVAS.x, row * COFFEE.CANVAS.y))
			var target := EXPORT.path_join(side + "-" + layer_name.to_snake_case() + ".png")
			save_png(image, target)
			if layer_name != "whole": descriptors.append(layer_descriptor(side, layer_name, measured))
		for layer_name: String in order:
			union = PIXELS.binary_over(union, images[layer_name])
		check(union.get_data() == (images.whole as Image).get_data(), side + " ordered semantic layers reconstruct renderer byte-exact")
		var whole_bounds := Rect2i(profile.visual_bounds.position + COFFEE.PIVOT, profile.visual_bounds.size)
		check((images.whole as Image).get_used_rect() == whole_bounds, side + " measured whole equals explicit geometry bounds")
		check(int((measurements.whole.opaque_bounds as Array)[1]) + int((measurements.whole.opaque_bounds as Array)[3]) < COFFEE.CANVAS.y, side + " keeps lower transparent gutter")
		native_sheet.blit_rect(images.whole, Rect2i(Vector2i.ZERO, COFFEE.CANVAS), Vector2i(column * COFFEE.CANVAS.x, 0))
		var detail := (images.whole as Image).duplicate() as Image
		detail.resize(COFFEE.CANVAS.x * 4, COFFEE.CANVAS.y * 4, Image.INTERPOLATE_NEAREST)
		save_png(detail, OUTPUT.path_join(side + "-whole-4x.png"))
		var support_records: Dictionary = {}
		for component: String in COFFEE.COMPONENTS:
			var rect: Rect2i = profile.supports[component]
			support_records[component] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		directions.append({"service_side": side, "approach_gaze": profile.approach_gaze,
			"machine_camera_face": profile.machine_camera_face, "service_controls_visibility": profile.service_controls_visibility,
			"canvas": [COFFEE.CANVAS.x, COFFEE.CANVAS.y], "pivot": [COFFEE.PIVOT.x, COFFEE.PIVOT.y],
			"floor": PIXELS.rect_values(profile.floor), "top": PIXELS.rect_values(profile.top),
			"visual_bounds": PIXELS.rect_values(profile.visual_bounds), "supports": support_records,
			"render_order": order, "render_layers": descriptors, "measurements": measurements,
			"runtime_approved": false})
	save_png(native_sheet, OUTPUT.path_join("registered-four-native.png"))
	save_png(layer_sheet, OUTPUT.path_join("registered-layers-native.png"))
	var enlarged := native_sheet.duplicate() as Image
	enlarged.resize(native_sheet.get_width() * 4, native_sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	save_png(enlarged, OUTPUT.path_join("registered-four-4x.png"))
	for source: Dictionary in before_sources:
		check(FileAccess.get_sha256(source.path) == source.sha256, "Source stayed byte-identical " + str(source.path))
	var manifest := {"id": "coffee-station-code-v1", "status": "calibration_candidate",
		"provenance": "Deterministic typed GDScript geometry on the existing exact modular counter and reviewed native oak/powdercoat tiles. No image generation or semantic raster editing.",
		"checks": checks, "failures": failures, "renderer": DisplayServer.get_name(), "source_files": before_sources,
		"directions": directions, "captures": captures, "pixel_scale": 1, "filter": "nearest", "msaa_2d": "disabled",
		"image_generation": false, "semantic_raster_edit": false, "runtime_registered": false,
		"worker_disabled": true, "save_access": false,
		"limitations": ["Candidate exports are not present in the production furniture catalogue.", "Standing service uses existing locomotion poses; no reaching, pouring or drinking animation is claimed.", "East/west service controls are honestly edge-on; the readable reservoir/vent ends identify the machine without rotating front pixels."]}
	var file := FileAccess.open(EXPORT.path_join("manifest.json"), FileAccess.WRITE)
	check(file != null, "Open candidate export manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	var evidence := FileAccess.open(OUTPUT.path_join("export-results.json"), FileAccess.WRITE)
	check(evidence != null, "Open export evidence manifest")
	manifest.checks = checks
	manifest.failures = failures
	if evidence != null: evidence.store_string(JSON.stringify(manifest, "\t") + "\n")
	for side: String in views:
		for viewport: SubViewport in views[side].values(): viewport.free()
	print("Coffee station native export: %d checks, %d failures; candidate only." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
