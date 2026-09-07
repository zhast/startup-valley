extends SceneTree
## Provider-free structural/contact gate for the dev-only creative-design kit.

const KIT := preload("res://tools/creative_design_kit_geometry.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/creative-design-kit-v1"
const EVIDENCE := "res://tests/output/creative-design-kit"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func opaque_overlap(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if a.get_pixel(x, y).a > 0.0 and b.get_pixel(x, y).a > 0.0:
				result += 1
	return result

func contains_color(image: Image, color: Color) -> bool:
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if image.get_pixel(x, y) == color:
				return true
	return false

func shifted(path: String, delta: Vector2i) -> Image:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	var result := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	result.blit_rect(source, Rect2i(Vector2i.ZERO, KIT.CANVAS), delta)
	return result

func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal:
		result.flip_x()
	else:
		result.flip_y()
	return result

func run() -> void:
	check(KIT.CANVAS == Vector2i(192, 224) and KIT.PIVOT == Vector2i(96, 160), "Accepted desk canvas and pivot are exact")
	check(KIT.SPRITE_OFFSET + KIT.CANVAS / 2 == KIT.CANVAS - KIT.PIVOT, "Centered sprite offset preserves common floor pivot")
	check(KIT.COLLISION_CELLS.is_empty(), "Attached creative decor adds zero floor collision")
	check(KIT.LAYERS == ["surface_decor_rear", "surface_decor_front"], "Only reusable rear/front overlays are exported")
	check(KIT.OBJECTS == ["pen_display", "swatch_fan", "stylus_tool_tray"], "Every facing carries the same bounded creative-tool identity")
	var identity := " ".join(KIT.OBJECTS)
	for forbidden: String in ["label", "logo", "metric", "employee", "portrait", "hire", "backend"]:
		check(forbidden not in identity, "Semantic object identity does not encode " + forbidden)
	var source := FileAccess.get_file_as_string("res://tools/creative_design_kit_geometry.gd")
	check(source.find("draw_string") == -1 and source.find("Font") == -1, "Geometry has no font or text-rendering path")
	check(source.find("Image.load_from_file") == -1 and source.find("load(") == -1, "Geometry draws native pixels without loading a raster source")
	check(FileAccess.get_sha256(KIT.HISTORICAL_NORTH_SOURCE) == "93d3295cf53f652397ea664cf457600852ca9cefbc1f36c88c0f9e619f28ffc0", "Historical generated North source is preserved byte-exact")
	check(FileAccess.file_exists(KIT.HISTORICAL_NORTH_PROMPT), "Historical North prompt remains present")
	check(FileAccess.file_exists(KIT.HISTORICAL_NORTH_REVIEW), "Historical North native review remains present")
	check(FileAccess.file_exists(KIT.HISTORICAL_NORTH_COMPOSITION_REVIEW), "Historical North composition review remains present")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("creative_design_kit") == -1, "Candidate has no production furniture registration")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("creative_design_kit") == -1, "Candidate has no default-layout binding")
	var wholes: Dictionary = {}
	var directional_layers: Dictionary = {}
	for side: String in KIT.SIDES:
		var specs := KIT.specifications(side)
		check(specs.keys().size() == KIT.OBJECTS.size(), side + " declares exactly three creative objects")
		var axis := "horizontal" if side in ["north", "south"] else "vertical"
		var desk_top: Rect2i = DESK.profile(side).top
		desk_top.position += KIT.PIVOT
		var seen: Array[Image] = []
		var object_union := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
		object_union.fill(Color(0, 0, 0, 0))
		for object_name: String in KIT.OBJECTS:
			check(specs.has(object_name), side + " includes " + object_name)
			check(str(specs[object_name].axis) == axis, side + " " + object_name + " uses authored screen axis")
			var object := KIT.object_image(side, object_name)
			var bounds := object.get_used_rect()
			check(bounds.has_area() and desk_top.grow(-2).encloses(bounds), side + " " + object_name + " rests inside accepted tabletop")
			for prior: Image in seen:
				check(opaque_overlap(object, prior) == 0, side + " creative objects remain disjoint")
			seen.append(object)
			object_union = KIT.binary_over(object_union, object)
		var display := KIT.object_image(side, "pen_display")
		var swatches := KIT.object_image(side, "swatch_fan")
		var tools := KIT.object_image(side, "stylus_tool_tray")
		check(contains_color(display, KIT.SCREEN) and contains_color(display, KIT.BEZEL) and contains_color(display, KIT.CERULEAN), side + " pen display retains bezel, blank canvas and fixed highlight")
		check(contains_color(swatches, KIT.PAPER) and contains_color(swatches, KIT.VERMILION) and contains_color(swatches, KIT.METAL), side + " swatch fan retains paper, shared palette and binding pin")
		check(contains_color(tools, KIT.METAL) and contains_color(tools, KIT.GOLD), side + " tool tray retains stylus and design-tool materials")
		var parts := KIT.layers(side)
		var whole := KIT.whole(side)
		wholes[side] = whole
		directional_layers[side] = parts
		check(parts.keys().size() == 2, side + " exports exactly rear/front layers")
		check(int(PIXELS.analyze(whole).opaque_pixels) < 800, side + " remains sparse passive decor")
		for layer_name: String in KIT.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			check(image.get_size() == KIT.CANVAS and facts.opaque_pixels > 0, side + " " + layer_name + " is nonempty on common canvas")
			check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, side + " " + layer_name + " has binary alpha and clean transparent RGB")
			var descriptor := KIT.descriptor(side, layer_name)
			check(descriptor.region == [0, 0, 192, 224] and descriptor.offset == [0, -48], side + " " + layer_name + " keeps exact integer registration")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/creative-design-kit-v1/"), side + " " + layer_name + " remains fixture-scoped")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministic fixture rebuilds byte-exact")
		check(KIT.layer_depth(side, "surface_decor_front") > KIT.layer_depth(side, "surface_decor_rear"), side + " preserves rear/front depth")
		check(KIT.binary_over(parts.surface_decor_rear, parts.surface_decor_front).get_data() == whole.get_data(), side + " layers reconstruct whole byte-exact")
		check(object_union.get_data() == whole.get_data(), side + " object masks reconstruct whole byte-exact")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), side + " whole fixture rebuilds deterministic pixels")
		var device_paths := {
			"monitor": "res://assets/runtime/office/workstations-v2/monitor-%s.png" % side,
			"keyboard": "res://assets/runtime/office/workstations-v2/keyboard-%s.png" % side,
			"mouse": "res://assets/runtime/office/workstations-v2/mouse-%s.png" % side,
		}
		var deltas := {"monitor": Vector2i.ZERO, "keyboard": Vector2i.ZERO, "mouse": Vector2i.ZERO}
		if side == "north":
			deltas = {"monitor": Vector2i(0, -10), "keyboard": Vector2i(0, 4), "mouse": Vector2i(0, 4)}
		elif side == "east":
			deltas = {"monitor": Vector2i.ZERO, "keyboard": Vector2i(6, 0), "mouse": Vector2i(6, 0)}
		elif side == "south":
			deltas.monitor = Vector2i(0, 3)
		for device: String in device_paths:
			var accepted_device := shifted(device_paths[device], deltas[device])
			check(opaque_overlap(whole, accepted_device) == 0, side + " creative kit clears accepted " + device)
			for object_name: String in KIT.OBJECTS:
				check(opaque_overlap(KIT.object_image(side, object_name), accepted_device) == 0, side + " " + object_name + " clears accepted " + device)
	for side: String in KIT.SIDES:
		for other: String in KIT.SIDES:
			if side >= other:
				continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " wholes are direction-identifiable")
			for layer_name: String in KIT.LAYERS:
				var side_layers: Dictionary = directional_layers[side]
				var other_layers: Dictionary = directional_layers[other]
				check((side_layers[layer_name] as Image).get_data() != (other_layers[layer_name] as Image).get_data(), side + "/" + other + " " + layer_name + " are direction-identifiable")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data(), "North is not horizontal mirror of South")
	check((wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North is not vertical mirror of South")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data(), "East is not horizontal mirror of West")
	check((wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East is not vertical mirror of West")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var result := {
		"status": "native_review_candidate_not_runtime_registered",
		"host": "accepted desk / workstations-v2",
		"checks": checks,
		"failures": failures,
		"canvas": [192, 224],
		"pivot": [96, 160],
		"objects_per_facing": KIT.OBJECTS,
		"layers_per_facing": KIT.LAYERS,
		"collision_cells": [],
		"historical_north_source_sha256": FileAccess.get_sha256(KIT.HISTORICAL_NORTH_SOURCE),
		"image_generation_used": false,
		"runtime_registered": false,
		"dev_catalogue_registered": false,
		"production_catalogue_registered": false,
		"creative_role_or_backend_added": false,
	}
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened structural result")
	result.checks = checks
	result.failures = failures
	if file != null:
		file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Creative design kit: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
