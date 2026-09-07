extends SceneTree
## Provider-free structural, provenance, direction-identity, and accepted-desk
## contact gate for the candidate-only engineer build kit v2.

const KIT := preload("res://tools/engineer_build_kit_v2_geometry.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/engineer-build-kit-v2"
const EVIDENCE := "res://tests/output/engineer-build-kit-v2"
const LEGACY_HASHES := {
	"res://assets/source/overnight-20260904/roles/engineer-mat-north-v1.png": "58d4b551c5e725c3e87bb27b40cd87f152a0b15cefc1560e3eac18ed36813604",
	"res://assets/source/overnight-20260904/roles/engineer-mat-north-v2.png": "e96e938435902bcb1323409177443b3ad56bb7688ba48f32084609ecfc50c7f4",
	"res://assets/source/overnight-20260904/roles/engineer-mat-east-v1.png": "4d5688c0bf757351abb2470d7c52cf0aec3b74cd73a1979762d7c4a1e365f856",
	"res://assets/source/overnight-20260904/roles/engineer-mat-south-v1.png": "a2f5a669cf15d3d465299a562bd6ef503cbf0e7b2563d0decff85c7495ddeed7",
	"res://assets/source/overnight-20260904/roles/engineer-mat-south-v2.png": "8b735f19797d9fe3c46a6a00ebd08372089a6b2239650748862f3785b2d07c93",
	"res://assets/source/overnight-20260904/roles/engineer-mat-west-v1.png": "372f5b5e9fa3bfd4d4031709d36cd230a8dc6f568feb411189d6dbc3a6e89a59",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/north-v1.png": "9a3dcd2447d29cbd301976abb7a6c4923522af620ee3468fae9303cadecfae5d",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/north-v2.png": "78f2877d83d0af0f81f9fff8b670ce8e4621f392b474248eff6a9b15540b7fc0",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/east-v1.png": "a6e2323708bbb64b23c462ee9b3d1317bda9ab8718c38730bbc1eb7ea2874450",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/south-v1.png": "67ded27384c11a703e62b20d987de37f3970cbfea7d5d3775885a12b949899fe",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/south-v2.png": "46494712079df1335e20fc10c9d5913fb2d7129203329d92d46416d436d15e38",
	"res://tests/fixtures/furniture-calibration/engineer-mat-v1/west-v1.png": "2742221f198e1f2f853135e9ec1fdf8c9b92724b0693b844b1d41a9ceff2ff8c",
}

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
			if a.get_pixel(x, y).a > 0.0 and b.get_pixel(x, y).a > 0.0: result += 1
	return result

func contains_color(image: Image, color: Color) -> bool:
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if image.get_pixel(x, y) == color: return true
	return false

func shifted(path: String, delta: Vector2i) -> Image:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	var result := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	result.blit_rect(source, Rect2i(Vector2i.ZERO, KIT.CANVAS), delta)
	return result

func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal: result.flip_x()
	else: result.flip_y()
	return result

func check_identity_pixels(side: String, mat: Image, tray: Image) -> void:
	var red_probe_points := {
		"north": Vector2i(53, 120),
		"east": Vector2i(86, 84),
		"south": Vector2i(137, 118),
		"west": Vector2i(100, 169),
	}
	var usb_points := {
		"north": Vector2i(57, 123),
		"east": Vector2i(85, 88),
		"south": Vector2i(133, 118),
		"west": Vector2i(104, 165),
	}
	var breadboard_points := {
		"north": Vector2i(60, 119),
		"east": Vector2i(92, 91),
		"south": Vector2i(124, 125),
		"west": Vector2i(99, 156),
	}
	var tray_red_points := {
		"north": Vector2i(124, 135),
		"east": Vector2i(85, 157),
		"south": Vector2i(60, 135),
		"west": Vector2i(104, 93),
	}
	check(mat.get_pixelv(red_probe_points[side]) == KIT.PROBE_RED, side + " test mat turns the red probe with worker-left")
	check(mat.get_pixelv(usb_points[side]) == KIT.STEEL, side + " development board USB turns with worker-left")
	check(mat.get_pixelv(breadboard_points[side]) == KIT.BREADBOARD, side + " breadboard occupies the authored far edge")
	check(tray.get_pixelv(tray_red_points[side]) == KIT.PROBE_RED, side + " precision tray turns red-tool placement with worker-left")

func run() -> void:
	check(KIT.SIDES == ["north", "east", "south", "west"], "Exactly one ordered N/E/S/W candidate set")
	check(KIT.CANVAS == Vector2i(192, 224) and KIT.PIVOT == Vector2i(96, 160), "Current accepted desk canvas and floor pivot are exact")
	check(KIT.SPRITE_OFFSET + KIT.CANVAS / 2 == KIT.CANVAS - KIT.PIVOT, "Centered sprite offset resolves fixed floor pivot")
	check(KIT.COLLISION_CELLS.is_empty(), "Engineering surface decor adds zero floor collision")
	check(KIT.LAYERS == ["surface_decor_rear", "surface_decor_front"], "Only reusable required rear/front overlays are exported")
	check(KIT.OBJECTS == ["electronics_test_mat", "debug_instrument", "precision_tool_tray"], "Each direction has a mat, distinct instrument, and precision-tool tray")
	var semantic_identity := " ".join(KIT.OBJECTS)
	for forbidden: String in ["server_rack", "employee", "hire", "backend", "service", "deploy", "metric"]:
		check(forbidden not in semantic_identity, "Passive semantic identity does not imply " + forbidden)
	var geometry_source := FileAccess.get_file_as_string("res://tools/engineer_build_kit_v2_geometry.gd")
	for forbidden_call: String in ["Image.load", "load_from_file", "flip_x(", "flip_y(", "resize(", "draw_string", "Font", "Transform2D"]:
		check(geometry_source.find(forbidden_call) == -1, "Geometry has no source-raster/text transform path " + forbidden_call)
	check(geometry_source.find("engineer-mat-v1") == -1, "Compact active mat is not a hidden crop or scaled old plate")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("engineer-build-kit-v2") == -1, "Candidate has no production furniture registration")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("engineer-build-kit-v2") == -1, "Candidate has no default-layout binding")
	check(LEGACY_HASHES.size() == 12, "Preservation guard covers six source masters and six native mat plates")
	for path: String in LEGACY_HASHES:
		check(FileAccess.file_exists(path), "Retained engineer evidence exists: " + path)
		check(FileAccess.get_sha256(path) == str(LEGACY_HASHES[path]), "Retained engineer evidence remains byte-exact: " + path)
	var old_sizes := {
		"north": Vector2i(32, 20), "east": Vector2i(20, 32),
		"south": Vector2i(32, 20), "west": Vector2i(20, 32),
	}
	var old_paths := {
		"north": "res://tests/fixtures/furniture-calibration/engineer-mat-v1/north-v2.png",
		"east": "res://tests/fixtures/furniture-calibration/engineer-mat-v1/east-v1.png",
		"south": "res://tests/fixtures/furniture-calibration/engineer-mat-v1/south-v2.png",
		"west": "res://tests/fixtures/furniture-calibration/engineer-mat-v1/west-v1.png",
	}
	var expected_left := {"north": "west", "east": "north", "south": "east", "west": "south"}
	var expected_far := {"north": "north", "east": "east", "south": "south", "west": "west"}
	var expected_gaze := {"north": Vector2i.UP, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "west": Vector2i.LEFT}
	var expected_mat_size := {"north": Vector2i(26, 14), "east": Vector2i(14, 26), "south": Vector2i(26, 14), "west": Vector2i(14, 26)}
	var expected_instrument_size := {"north": Vector2i(18, 10), "east": Vector2i(10, 18), "south": Vector2i(18, 10), "west": Vector2i(10, 18)}
	var expected_tray_size := {"north": Vector2i(18, 8), "east": Vector2i(8, 18), "south": Vector2i(18, 8), "west": Vector2i(8, 18)}
	var wholes: Dictionary = {}
	var directional_layers: Dictionary = {}
	for side: String in KIT.SIDES:
		var identity := KIT.direction_identity(side)
		check(identity.employee_look_vector == expected_gaze[side], side + " host gaze is exact")
		check(str(identity.worker_left_edge) == str(expected_left[side]), side + " worker-left edge is physical")
		check(str(identity.board_usb_edge) == str(expected_left[side]) and str(identity.red_probe_side) == str(expected_left[side]) and str(identity.tool_red_side) == str(expected_left[side]), side + " USB, red probe, and red tray tool turn with worker-left")
		check(str(identity.mat_far_edge) == str(expected_far[side]), side + " breadboard far-edge contract turns with gaze")
		var old_mat := Image.load_from_file(ProjectSettings.globalize_path(old_paths[side]))
		check(old_mat.get_size() == old_sizes[side], side + " retained v1 plate keeps its measured legacy dimensions")
		var specs := KIT.specifications(side)
		check(specs.size() == KIT.OBJECTS.size(), side + " declares exactly three independent semantic objects")
		var object_union := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
		object_union.fill(Color(0, 0, 0, 0))
		var seen: Array[Image] = []
		var desk_top: Rect2i = DESK.profile(side).top
		desk_top.position += KIT.PIVOT
		for object_name: String in KIT.OBJECTS:
			var spec: Dictionary = specs[object_name]
			check(str(spec.construction) == "authored_" + side, side + " " + object_name + " is independently constructed")
			var expected_axis := "horizontal" if side in ["north", "south"] else "vertical"
			check(str(spec.axis) == expected_axis, side + " " + object_name + " has the authored screen-axis projection")
			var object := KIT.object_image(side, object_name)
			var bounds := object.get_used_rect()
			check(bounds.has_area() and desk_top.grow(-2).encloses(bounds), side + " " + object_name + " stays on current accepted tabletop ink")
			if object_name == "electronics_test_mat":
				check(bounds.size == expected_mat_size[side], side + " compact mat uses one physical 26x14 / 14x26 contract")
				check(bounds.size != old_mat.get_size(), side + " v2 mat fixes old oversized host fit instead of registering old pixels")
			elif object_name == "debug_instrument": check(bounds.size == expected_instrument_size[side], side + " instrument uses one rotated physical envelope")
			else: check(bounds.size == expected_tray_size[side], side + " tool tray uses one rotated physical envelope")
			for prior: Image in seen: check(opaque_overlap(object, prior) == 0, side + " semantic objects remain disjoint")
			seen.append(object)
			object_union = KIT.binary_over(object_union, object)
		var mat := KIT.object_image(side, "electronics_test_mat")
		var instrument := KIT.object_image(side, "debug_instrument")
		var tray := KIT.object_image(side, "precision_tool_tray")
		check(contains_color(mat, KIT.MAT_BLUE) and contains_color(mat, KIT.BOARD_GREEN) and contains_color(mat, KIT.BREADBOARD) and contains_color(mat, KIT.PROBE_RED), side + " mat retains board, breadboard, and clear probe identity")
		check(contains_color(instrument, KIT.SCREEN_CYAN) and contains_color(instrument, KIT.AMBER), side + " instrument has a blank screen and physical controls without metrics")
		check(contains_color(tray, KIT.TRAY) and contains_color(tray, KIT.STEEL) and contains_color(tray, KIT.PROBE_RED), side + " tray retains two distinct precision-tool materials")
		check_identity_pixels(side, mat, tray)
		var parts := KIT.layers(side)
		var whole := KIT.whole(side)
		wholes[side] = whole
		directional_layers[side] = parts
		for layer_name: String in KIT.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			var descriptor := KIT.descriptor(side, layer_name)
			check(image.get_size() == KIT.CANVAS and facts.opaque_pixels > 0, side + " " + layer_name + " is nonempty on current desk canvas")
			check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, side + " " + layer_name + " has binary alpha and zero hidden RGB")
			check(descriptor.region == [0, 0, 192, 224] and descriptor.offset == [0, -48], side + " " + layer_name + " keeps exact integer desk registration")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/engineer-build-kit-v2/"), side + " " + layer_name + " remains candidate-fixture scoped")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministic fixture rebuilds byte-exact")
		check(KIT.layer_depth(side, "surface_decor_front") > KIT.layer_depth(side, "surface_decor_rear"), side + " preserves rear/front host depth order")
		check(KIT.binary_over(parts.surface_decor_rear, parts.surface_decor_front).get_data() == whole.get_data(), side + " rear/front layers reconstruct whole byte-exact")
		check(object_union.get_data() == whole.get_data(), side + " object masks reconstruct whole byte-exact")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), side + " whole export is deterministic")
		var device_paths := {
			"monitor": "res://assets/runtime/office/workstations-v2/monitor-%s.png" % side,
			"keyboard": "res://assets/runtime/office/workstations-v2/keyboard-%s.png" % side,
			"mouse": "res://assets/runtime/office/workstations-v2/mouse-%s.png" % side,
		}
		var deltas := {"monitor": Vector2i.ZERO, "keyboard": Vector2i.ZERO, "mouse": Vector2i.ZERO}
		if side == "north": deltas = {"monitor": Vector2i(0, -10), "keyboard": Vector2i(0, 4), "mouse": Vector2i(0, 4)}
		elif side == "east": deltas = {"monitor": Vector2i.ZERO, "keyboard": Vector2i(6, 0), "mouse": Vector2i(6, 0)}
		elif side == "south": deltas.monitor = Vector2i(0, 3)
		for device: String in device_paths:
			var accepted_device := shifted(device_paths[device], deltas[device])
			check(opaque_overlap(whole, accepted_device) == 0, side + " complete kit clears current accepted " + device)
			for object_name: String in KIT.OBJECTS: check(opaque_overlap(KIT.object_image(side, object_name), accepted_device) == 0, side + " " + object_name + " clears current accepted " + device)
	for side: String in KIT.SIDES:
		for other: String in KIT.SIDES:
			if side >= other: continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " whole constructions are independently identifiable")
			for layer_name: String in KIT.LAYERS:
				var side_layers: Dictionary = directional_layers[side]
				var other_layers: Dictionary = directional_layers[other]
				check((side_layers[layer_name] as Image).get_data() != (other_layers[layer_name] as Image).get_data(), side + "/" + other + " " + layer_name + " are independently identifiable")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data() and (wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North/South are not finished-raster mirrors")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data() and (wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East/West are not finished-raster mirrors")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened structural result")
	if file != null:
		file.store_string(JSON.stringify({
			"status": "native_review_candidate_not_catalogued_or_runtime_registered",
			"family": "engineer_build_kit", "candidate_revision": "engineer-build-kit-v2",
			"host": "current accepted desk / workstations-v2", "old_planning_host_not_used": "prototype_bench",
			"checks": checks, "failures": failures, "canvas": [192, 224], "pivot": [96, 160],
			"objects_per_facing": KIT.OBJECTS, "layers_per_facing": KIT.LAYERS, "collision_cells": [],
			"legacy_files_hash_guarded": LEGACY_HASHES.size(), "image_generation_calls": 0,
			"generation_budget_changed": false, "runtime_registered": false, "dev_catalogue_registered": false,
			"production_catalogue_registered": false, "engineer_pose_service_or_hire_created": false,
		}, "\t") + "\n")
	print("Engineer build kit v2: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
