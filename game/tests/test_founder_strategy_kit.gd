extends SceneTree
## Provider-free structural/contact gate for the dev-only founder kit.

const KIT := preload("res://tools/founder_strategy_kit_geometry.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/founder-strategy-kit-v1"
const EVIDENCE := "res://tests/output/founder-strategy-kit"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func overlap(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if a.get_pixel(x, y).a > 0.0 and b.get_pixel(x, y).a > 0.0: result += 1
	return result

func shifted(path: String, delta: Vector2i) -> Image:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	var result := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8); result.fill(Color(0, 0, 0, 0))
	result.blit_rect(source, Rect2i(Vector2i.ZERO, KIT.CANVAS), delta)
	return result

func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal: result.flip_x()
	else: result.flip_y()
	return result

func run() -> void:
	check(KIT.CANVAS == Vector2i(192, 224) and KIT.PIVOT == Vector2i(96, 160), "Accepted workstation canvas/pivot are exact")
	check(KIT.SPRITE_OFFSET + KIT.CANVAS / 2 == KIT.CANVAS - KIT.PIVOT, "Common centered offset resolves the fixed floor anchor")
	check(KIT.COLLISION_CELLS.is_empty(), "Reusable surface overlays add zero collision cells")
	var wholes: Dictionary = {}
	for side: String in KIT.SIDES:
		var specs := KIT.specifications(side)
		check(specs.size() == KIT.OBJECTS.size(), side + " declares exactly three founder objects")
		var object_union := Image.create(192, 224, false, Image.FORMAT_RGBA8); object_union.fill(Color(0, 0, 0, 0))
		var prior: Array[Image] = []
		var top: Rect2i = DESK.profile(side).top; top.position += KIT.PIVOT
		for object_name: String in KIT.OBJECTS:
			check(specs.has(object_name), side + " includes " + object_name)
			var object := KIT.object_image(side, object_name); var bounds := object.get_used_rect()
			check(bounds.has_area() and top.grow(-2).encloses(bounds), side + " " + object_name + " contacts only accepted tabletop interior")
			for previous: Image in prior: check(overlap(object, previous) == 0, side + " object silhouettes are disjoint")
			prior.append(object); object_union = KIT.binary_over(object_union, object)
		var parts := KIT.layers(side); var whole := KIT.whole(side); wholes[side] = whole
		check(parts.size() == 2, side + " exports exactly rear/front overlays")
		for layer_name: String in KIT.LAYERS:
			var image: Image = parts[layer_name]; var facts := PIXELS.analyze(image); var descriptor := KIT.descriptor(side, layer_name)
			check(image.get_size() == KIT.CANVAS and facts.opaque_pixels > 0, side + " " + layer_name + " is nonempty on common canvas")
			check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, side + " " + layer_name + " has binary alpha and clean transparent RGB")
			check(descriptor.region == [0, 0, 192, 224] and descriptor.offset == [0, -48], side + " " + layer_name + " uses integer registered coordinates")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " has no raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " rebuilds byte-exact")
		check(KIT.binary_over(parts.surface_decor_rear, parts.surface_decor_front).get_data() == whole.get_data(), side + " rear/front reconstruct whole")
		check(object_union.get_data() == whole.get_data(), side + " three semantic masks reconstruct whole")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), side + " deterministic whole export matches")
		var device_paths := {"monitor": "res://assets/runtime/office/workstations-v2/monitor-%s.png" % side, "keyboard": "res://assets/runtime/office/workstations-v2/keyboard-%s.png" % side, "mouse": "res://assets/runtime/office/workstations-v2/mouse-%s.png" % side}
		var deltas := {"monitor": Vector2i.ZERO, "keyboard": Vector2i.ZERO, "mouse": Vector2i.ZERO}
		if side == "north": deltas = {"monitor": Vector2i(0, -10), "keyboard": Vector2i(0, 4), "mouse": Vector2i(0, 4)}
		elif side == "east": deltas = {"monitor": Vector2i.ZERO, "keyboard": Vector2i(6, 0), "mouse": Vector2i(6, 0)}
		elif side == "south": deltas.monitor = Vector2i(0, 3)
		for device: String in device_paths: check(overlap(whole, shifted(device_paths[device], deltas[device])) == 0, side + " clears accepted " + device)
	for side: String in KIT.SIDES:
		for other: String in KIT.SIDES:
			if side < other: check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " retain direction identity")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data() and (wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North/South are not mirror-derived")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data() and (wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East/West are not mirror-derived")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE); check(file != null, "Opened structural result")
	if file != null: file.store_string(JSON.stringify({"status": "native_review_candidate_not_runtime_registered", "checks": checks, "failures": failures, "canvas": [192, 224], "pivot": [96, 160], "objects_per_facing": KIT.OBJECTS, "layers_per_facing": KIT.LAYERS, "collision_cells": [], "runtime_registered": false}, "\t") + "\n")
	print("Founder strategy kit: %d checks, %d failures" % [checks, failures.size()]); quit(0 if failures.is_empty() else 1)
