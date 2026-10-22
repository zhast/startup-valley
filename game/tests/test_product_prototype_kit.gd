extends SceneTree
## Provider-free structural gate for the dev-only product prototype candidate.

const KIT := preload("res://tools/product_prototype_kit_geometry.gd")
const MINA := preload("res://tools/mina_product_kit_geometry.gd")
const RESEARCH := preload("res://tools/research_bench_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/product-prototype-kit-v1"
const EVIDENCE := "res://tests/output/product-prototype-kit"
const RUNTIME_BASE := "res://assets/runtime/office/research-bench-v1"
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

func unsupported_pixels(object: Image, support: Image) -> int:
	var result := 0
	for y: int in range(KIT.CANVAS.y):
		for x: int in range(KIT.CANVAS.x):
			if object.get_pixel(x, y).a > 0.0 and support.get_pixel(x, y).a == 0.0: result += 1
	return result

func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal: result.flip_x()
	else: result.flip_y()
	return result

func run() -> void:
	check(KIT.CANVAS == Vector2i(192, 320) and KIT.PIVOT == Vector2i(96, 240), "Accepted research-table canvas and pivot are exact")
	check(KIT.CANVAS == RESEARCH.CANVAS and KIT.PIVOT == RESEARCH.PIVOT, "Overlays share the accepted research-bench registration")
	check(KIT.SPRITE_OFFSET + KIT.CANVAS / 2 == KIT.CANVAS - KIT.PIVOT, "Centered sprite offset preserves the common floor pivot")
	check(KIT.COLLISION_CELLS.is_empty(), "Attached surface decor adds zero floor collision")
	check(KIT.OBJECTS == ["prototype_fixture", "test_parts", "inspection_gauge"], "Candidate carries explicit making/testing semantics")
	for discovery_object: String in MINA.OBJECTS:
		check(discovery_object not in KIT.OBJECTS, "Prototype semantics remain distinct from Mina discovery's " + discovery_object)
	for forbidden_name: String in ["analyzer", "microscope", "research_bench", "notebook", "wireframes"]:
		check(forbidden_name not in " ".join(KIT.OBJECTS), "Candidate does not rename shared/discovery equipment as " + forbidden_name)
	check(not RESEARCH.profile("north").occupied.is_empty() and KIT.COLLISION_CELLS.is_empty(), "Overlays do not inherit the shared bench footprint")
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("product_prototype_kit") == -1, "Candidate has no production furniture registration")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("product_prototype_kit") == -1, "Candidate has no default-layout binding")
	var wholes: Dictionary = {}
	for side: String in KIT.SIDES:
		var specs := KIT.specifications(side)
		check(specs.keys().size() == 3, side + " has exactly the same three semantic objects")
		for object_name: String in KIT.OBJECTS: check(specs.has(object_name), side + " includes " + object_name)
		var base := RESEARCH.layers(side)
		var support := KIT.binary_over(base.RearStructure, base.FrontStructure)
		var runtime_tool := Image.load_from_file(ProjectSettings.globalize_path(RUNTIME_BASE.path_join(side + "-tool_overlay.png")))
		var reviewed_tool := Image.load_from_file(ProjectSettings.globalize_path("res://tests/fixtures/furniture-calibration/research-bench-v1".path_join(side + "-tool_overlay.png")))
		var procedural_tool := base.ToolOverlay as Image
		var alpha_mismatch := 0
		if not runtime_tool.is_empty() and not procedural_tool.is_empty() and runtime_tool.get_size() == procedural_tool.get_size():
			for y: int in range(runtime_tool.get_height()):
				for x: int in range(runtime_tool.get_width()):
					if runtime_tool.get_pixel(x, y).a != procedural_tool.get_pixel(x, y).a:
						alpha_mismatch += 1
		check(not runtime_tool.is_empty() and not reviewed_tool.is_empty() and runtime_tool.get_data() == reviewed_tool.get_data(), side + " runtime tool overlay matches the warm reviewed source")
		check(alpha_mismatch == 0, side + " warm tool overlay keeps the accepted research-bench layout alpha")
		var object_union := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
		object_union.fill(Color(0, 0, 0, 0))
		var seen: Array[Image] = []
		for object_name: String in KIT.OBJECTS:
			var object := KIT.object_image(side, object_name)
			check(object.get_used_rect().has_area(), side + " " + object_name + " has native ink")
			check(unsupported_pixels(object, support) == 0, side + " " + object_name + " rests entirely on accepted bench structure")
			check(opaque_overlap(object, runtime_tool) == 0, side + " " + object_name + " clears shared research-bench tools")
			for prior: Image in seen: check(opaque_overlap(object, prior) == 0, side + " semantic objects remain disjoint")
			seen.append(object)
			object_union = KIT.binary_over(object_union, object)
		var parts := KIT.layers(side)
		var whole := KIT.whole(side)
		var whole_facts := PIXELS.analyze(whole)
		wholes[side] = whole
		check(parts.keys().size() == 2, side + " exports exactly rear/front overlays")
		check(int(whole_facts.opaque_pixels) < 900, side + " candidate is sparse decor, not baked furniture")
		check(opaque_overlap(whole, runtime_tool) == 0, side + " complete kit clears the shared research tool overlay")
		for layer_name: String in KIT.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			check(image.get_size() == KIT.CANVAS and facts.opaque_pixels > 0, side + " " + layer_name + " uses common nonempty canvas")
			check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, side + " " + layer_name + " has binary alpha and clean transparent RGB")
			var descriptor := KIT.descriptor(side, layer_name)
			check(descriptor.region == [0, 0, 192, 320] and descriptor.offset == [0, -80], side + " " + layer_name + " keeps integer canvas/anchor")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/product-prototype-kit-v1/"), side + " " + layer_name + " remains fixture-scoped")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministic fixture rebuilds byte-exact")
		check(KIT.layer_depth(side, "surface_decor_front") > KIT.layer_depth(side, "surface_decor_rear"), side + " preserves ordered rear/front depth")
		check(KIT.binary_over(parts.surface_decor_rear, parts.surface_decor_front).get_data() == whole.get_data(), side + " rear/front reconstruct whole byte-exact")
		check(object_union.get_data() == whole.get_data(), side + " three object masks reconstruct whole byte-exact")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), side + " whole export is deterministic")
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
		file.store_string(JSON.stringify({"status": "native_review_candidate_not_runtime_registered", "host": "accepted research_table / research-bench-v1", "checks": checks, "failures": failures, "canvas": [192, 320], "pivot": [96, 240], "objects_per_facing": KIT.OBJECTS, "layers_per_facing": KIT.LAYERS, "collision_cells": [], "runtime_registered": false, "dev_catalogue_registered": false, "production_catalogue_registered": false}, "\t") + "\n")
	print("Product prototype kit: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
