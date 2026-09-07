extends SceneTree
## Provider-free structural gate for the dev-only growth analytics candidate.

const KIT := preload("res://tools/growth_analytics_kit_geometry.gd")
const THEO := preload("res://tools/theo_campaign_kit_geometry.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/growth-analytics-kit-v1"
const EVIDENCE := "res://tests/output/growth-analytics-kit"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

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

func opaque_symmetric_difference(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if (a.get_pixel(x, y).a > 0.0) != (b.get_pixel(x, y).a > 0.0): result += 1
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

func run() -> void:
	check(KIT.CANVAS == Vector2i(192, 224) and KIT.PIVOT == Vector2i(96, 160), "Accepted desk canvas and pivot are exact")
	check(KIT.SPRITE_OFFSET + KIT.CANVAS / 2 == KIT.CANVAS - KIT.PIVOT, "Centered sprite offset preserves the common floor pivot")
	check(KIT.COLLISION_CELLS.is_empty(), "Attached analytics decor adds zero floor collision")
	check(KIT.LAYERS == ["surface_decor_rear", "surface_decor_front"], "Candidate exports only reusable rear/front overlays")
	check(KIT.OBJECTS == ["measurement_console", "attribution_test_notes", "comparison_overlay"], "Candidate carries explicit measurement/testing semantics")
	for campaign_object: String in THEO.OBJECTS:
		check(campaign_object not in KIT.OBJECTS, "Analytics semantics remain distinct from Theo campaign object " + campaign_object)
	for forbidden_name: String in ["campaign", "audience", "creative", "thumbnail", "logo", "metric", "number"]:
		check(forbidden_name not in " ".join(KIT.OBJECTS), "Object identity does not encode " + forbidden_name)
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("growth_analytics_kit") == -1, "Candidate has no production furniture registration")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("growth_analytics_kit") == -1, "Candidate has no default-layout binding")
	var wholes: Dictionary = {}
	for side: String in KIT.SIDES:
		var specs := KIT.specifications(side)
		check(specs.keys().size() == 3, side + " has exactly the same three semantic objects")
		for object_name: String in KIT.OBJECTS: check(specs.has(object_name), side + " includes " + object_name)
		var object_union := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
		object_union.fill(Color(0, 0, 0, 0))
		var seen: Array[Image] = []
		var desk_top: Rect2i = DESK.profile(side).top
		desk_top.position += KIT.PIVOT
		for object_name: String in KIT.OBJECTS:
			var object := KIT.object_image(side, object_name)
			var bounds := object.get_used_rect()
			check(bounds.has_area() and desk_top.grow(-2).encloses(bounds), side + " " + object_name + " rests inside accepted tabletop ink")
			for prior: Image in seen: check(opaque_overlap(object, prior) == 0, side + " semantic objects remain disjoint")
			seen.append(object)
			object_union = KIT.binary_over(object_union, object)
		var parts := KIT.layers(side)
		var whole := KIT.whole(side)
		var whole_facts := PIXELS.analyze(whole)
		wholes[side] = whole
		check(parts.keys().size() == 2, side + " exports exactly rear/front decor layers")
		check(int(whole_facts.opaque_pixels) < 900, side + " candidate is sparse decor, not baked furniture")
		check(contains_color(whole, KIT.CONSOLE) and contains_color(whole, KIT.CYAN) and contains_color(whole, KIT.AMBER), side + " preserves instrument and comparison palette")
		check(not contains_color(whole, THEO.CHARTREUSE) and not contains_color(whole, THEO.VERMILION) and not contains_color(whole, THEO.PAPER_LIGHT), side + " avoids the campaign candidate's bright palette grammar")
		var campaign := THEO.whole(side)
		check(whole.get_data() != campaign.get_data(), side + " complete composition is byte-distinct from Theo campaign kit")
		check(opaque_symmetric_difference(whole, campaign) > 200, side + " silhouette materially differs from Theo campaign kit")
		for layer_name: String in KIT.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			check(image.get_size() == KIT.CANVAS and facts.opaque_pixels > 0, side + " " + layer_name + " uses common nonempty canvas")
			check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, side + " " + layer_name + " has binary alpha and clean transparent RGB")
			var descriptor := KIT.descriptor(side, layer_name)
			check(descriptor.region == [0, 0, 192, 224] and descriptor.offset == [0, -48], side + " " + layer_name + " keeps integer canvas/anchor")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/growth-analytics-kit-v1/"), side + " " + layer_name + " remains fixture-scoped")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministic fixture rebuilds byte-exact")
		check(KIT.layer_depth(side, "surface_decor_front") > KIT.layer_depth(side, "surface_decor_rear"), side + " preserves ordered rear/front depth")
		check(KIT.binary_over(parts.surface_decor_rear, parts.surface_decor_front).get_data() == whole.get_data(), side + " rear/front reconstruct whole byte-exact")
		check(object_union.get_data() == whole.get_data(), side + " three object masks reconstruct whole byte-exact")
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
			var shifted_device := shifted(device_paths[device], deltas[device])
			check(opaque_overlap(whole, shifted_device) == 0, side + " analytics kit clears accepted " + device)
			for object_name: String in KIT.OBJECTS:
				check(opaque_overlap(KIT.object_image(side, object_name), shifted_device) == 0, side + " " + object_name + " clears accepted " + device)
	for side: String in KIT.SIDES:
		for other: String in KIT.SIDES:
			if side >= other: continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " are independently identifiable")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data(), "North is not a horizontal mirror of South")
	check((wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North is not a vertical mirror of South")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data(), "East is not a horizontal mirror of West")
	check((wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East is not a vertical mirror of West")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened structural result")
	if file != null:
		file.store_string(JSON.stringify({"status": "native_review_candidate_not_runtime_registered", "host": "accepted desk / workstations-v2", "checks": checks, "failures": failures, "canvas": [192, 224], "pivot": [96, 160], "objects_per_facing": KIT.OBJECTS, "layers_per_facing": KIT.LAYERS, "collision_cells": [], "runtime_registered": false, "dev_catalogue_registered": true, "production_catalogue_registered": false}, "\t") + "\n")
	print("Growth analytics kit: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
