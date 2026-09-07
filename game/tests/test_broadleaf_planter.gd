extends SceneTree
## Provider-free structural, alpha, identity and registration gate for the
## dev-only broadleaf planter candidate.

const PLANT := preload("res://tools/broadleaf_planter_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/broadleaf-planter-v1"
const EVIDENCE := "res://tests/output/broadleaf-planter"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal:
		result.flip_x()
	else:
		result.flip_y()
	return result

func contains_color(image: Image, color: Color) -> bool:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y) == color:
				return true
	return false

func opaque_overlap(a: Image, b: Image) -> int:
	var result := 0
	for y: int in range(PLANT.CANVAS.y):
		for x: int in range(PLANT.CANVAS.x):
			if a.get_pixel(x, y).a > 0.0 and b.get_pixel(x, y).a > 0.0:
				result += 1
	return result

func run() -> void:
	check(PLANT.CANVAS == Vector2i(128, 224), "Planned native canvas is exact")
	check(PLANT.PIVOT == Vector2i(64, 176), "Planned common floor pivot is exact")
	check(PLANT.SPRITE_OFFSET + PLANT.CANVAS / 2 == PLANT.CANVAS - PLANT.PIVOT, "Centered sprite offset reconstructs the common floor pivot")
	check(PLANT.OCCUPIED == [Vector2i.ZERO], "Planter blocks exactly one floor cell")
	check(PLANT.LAYERS == ["floor_shadow", "rear_structure", "front_structure"], "Every facing exposes the planned three reusable layers")
	var geometry_source := FileAccess.get_file_as_string("res://tools/broadleaf_planter_geometry.gd")
	check(geometry_source.find("Image.load_from_file") == -1 and geometry_source.find("load(PLANT.SOURCE") == -1, "Native geometry never loads generated source pixels")
	check(geometry_source.find("get_pixel") == -1 and geometry_source.find("flip_x") == -1 and geometry_source.find("flip_y") == -1, "Geometry has no sampling, keying, flipping or masking route")
	check(geometry_source.find("draw_string") == -1 and geometry_source.find("Font") == -1, "Planter geometry cannot bake text or logos")
	var source_v1 := Image.load_from_file(ProjectSettings.globalize_path(PLANT.SOURCE_V1))
	var source_v2 := Image.load_from_file(ProjectSettings.globalize_path(PLANT.SOURCE_V2))
	check(FileAccess.get_sha256(PLANT.SOURCE_V1) == "1ef554d7ba1ef82a43e406ffadf46c9eef1147035e4aab0d7b0fc4bfd642346b", "Failed v1 source is preserved byte-exact")
	check(FileAccess.get_sha256(PLANT.SOURCE_V2) == "3ce72e2dcbc0f4a3983e6bf5bda5f5b556de0c918cf6467193e14ab2e7330e77", "Failed v2 retry source is preserved byte-exact")
	check(source_v1.get_size() == Vector2i(948, 1659) and source_v1.get_format() == Image.FORMAT_RGB8, "Failed v1 decodes as 948x1659 RGB without alpha")
	check(source_v2.get_size() == Vector2i(949, 1658) and source_v2.get_format() == Image.FORMAT_RGB8, "Failed v2 decodes as 949x1658 RGB without alpha")
	check(FileAccess.file_exists(PLANT.PROMPT_V1) and FileAccess.file_exists(PLANT.PROMPT_V2), "Both generated-source prompts remain attributable")
	var wholes: Dictionary = {}
	var rear_layers: Dictionary = {}
	var front_layers: Dictionary = {}
	var expected := {
		"north": {"interaction": [0, 1], "look": [0, -1]},
		"east": {"interaction": [-1, 0], "look": [1, 0]},
		"south": {"interaction": [0, -1], "look": [0, 1]},
		"west": {"interaction": [1, 0], "look": [-1, 0]},
	}
	for side: String in PLANT.SIDES:
		var p := PLANT.profile(side)
		check(p.facing == side and p.footprint == [1, 1] and p.occupied == [[0, 0]], side + " keeps one-cell authored geometry")
		check(p.interaction == expected[side].interaction and p.employee_look_vector == expected[side].look, side + " keeps directional probe contact and gaze")
		check(p.leaves.size() == 6, side + " declares six individually modeled broad leaves")
		var rear_count := 0
		var front_count := 0
		var leaf_signatures: Dictionary = {}
		for leaf: Dictionary in p.leaves:
			var base: Vector2i = leaf.base
			var tip: Vector2i = leaf.tip
			check(base.x >= 48 and base.x <= 76 and base.y >= 137 and base.y <= 146, side + " leaf joins a plausible central stem crown")
			check(tip.x >= 16 and tip.x <= 112 and tip.y >= 55 and tip.y <= 128, side + " leaf tip stays within transparent padding and plant rise")
			check(int(leaf.width) >= 10 and int(leaf.width) <= 14 and base.distance_to(tip) >= 35.0, side + " leaf has broad organic proportion")
			check(str(leaf.layer) in ["rear_structure", "front_structure"], side + " leaf has an explicit depth layer")
			if str(leaf.layer) == "rear_structure": rear_count += 1
			else: front_count += 1
			leaf_signatures[str([base, tip, leaf.width, leaf.bend])] = true
		check(rear_count == 4 and front_count == 2 and leaf_signatures.size() == 6, side + " splits unique leaf geometry 4 rear / 2 front")
		var parts := PLANT.layers(side)
		var whole := PLANT.whole(side)
		wholes[side] = whole
		rear_layers[side] = parts.rear_structure
		front_layers[side] = parts.front_structure
		check(parts.keys().size() == 3, side + " exports exactly three native layers")
		for layer_name: String in PLANT.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			check(image.get_size() == PLANT.CANVAS and int(facts.opaque_pixels) > 0, side + " " + layer_name + " is nonempty on the common canvas")
			check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, side + " " + layer_name + " has binary alpha and zero hidden RGB")
			var descriptor := PLANT.descriptor(side, layer_name)
			check(descriptor.region == [0, 0, 128, 224] and descriptor.offset == [0, -64], side + " " + layer_name + " preserves exact integer registration")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/broadleaf-planter-v1/"), side + " " + layer_name + " remains candidate-fixture scoped")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no finished-raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministically rebuilds byte-exact")
		var facts := PIXELS.analyze(whole)
		var bounds := whole.get_used_rect()
		check(int(facts.opaque_pixels) >= 5500 and int(facts.opaque_pixels) <= 7200 and int(facts.opaque_colors) >= 15, side + " has dense, multi-tone plant detail rather than placeholder geometry")
		check(bounds.position.x >= 16 and bounds.position.y >= 48 and PLANT.CANVAS.x - bounds.end.x >= 16 and PLANT.CANVAS.y - bounds.end.y >= 32, side + " preserves safe transparent padding")
		check(PLANT.PIVOT.y - bounds.position.y <= 128 and bounds.end.y >= PLANT.PIVOT.y, side + " stays inside planned rise and grounds across the floor pivot")
		check(contains_color(whole, PLANT.LEAF_DARK) and contains_color(whole, PLANT.LEAF_LIGHT) and contains_color(whole, PLANT.LEAF_GLEAM), side + " retains outline, foliage facet and vein/highlight values")
		check(contains_color(whole, PLANT.POT) and contains_color(whole, PLANT.POT_LIGHT) and contains_color(whole, PLANT.POT_SHADE), side + " retains fixed-lit ceramic material")
		check(contains_color(whole, PLANT.SOIL) and contains_color(whole, PLANT.STEM) and contains_color(whole, PLANT.STEM_LIGHT), side + " retains soil and articulated stems")
		check(opaque_overlap(parts.rear_structure, parts.front_structure) > 100, side + " rear/front structure overlaps enough to demonstrate ordered reconstruction")
		check(PLANT.binary_over(PLANT.binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure).get_data() == whole.get_data(), side + " layers reconstruct the whole byte-exact")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), side + " whole fixture rebuilds byte-exact")
		check(PLANT.layer_depth("floor_shadow") < PLANT.layer_depth("rear_structure") and PLANT.layer_depth("rear_structure") < PLANT.layer_depth("front_structure"), side + " uses strict floor/rear/front depth order")
	for side: String in PLANT.SIDES:
		for other: String in PLANT.SIDES:
			if side >= other:
				continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " whole silhouettes are direction-identifiable")
			check((rear_layers[side] as Image).get_data() != (rear_layers[other] as Image).get_data(), side + "/" + other + " rear structures are independently authored")
			check((front_layers[side] as Image).get_data() != (front_layers[other] as Image).get_data(), side + "/" + other + " front structures are independently authored")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data(), "North is not a horizontal mirror of South")
	check((wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North is not a vertical mirror of South")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data(), "East is not a horizontal mirror of West")
	check((wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East is not a vertical mirror of West")
	var entry := PLANT.catalog_entry()
	check(entry.facings == PLANT.SIDES and entry.interaction_kind == "none" and entry.wall_mount == "none", "Disposable catalogue entry remains passive and four-facing")
	for side: String in PLANT.SIDES:
		var profile: Dictionary = entry.facing_profiles[side]
		check(profile.profile_kind == "decorative" and profile.status == "calibration_candidate", side + " injection uses a dev-only decorative candidate profile")
		check(profile.occupied == [[0, 0]] and profile.clearance == [expected[side].interaction], side + " injected collision and clearance match authored geometry")
		check(profile.render_layers.size() == 3 and profile.ambient_overlays.is_empty(), side + " injects only the exact three reviewed layers")
		check(profile.standing_viewpoints.size() == 1 and profile.standing_viewpoints[0].cell == expected[side].interaction, side + " actor probe occupies only the declared clear cell")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var result := {
		"status": "native_review_candidate_not_runtime_registered",
		"checks": checks,
		"failures": failures,
		"canvas": [PLANT.CANVAS.x, PLANT.CANVAS.y],
		"pivot": [PLANT.PIVOT.x, PLANT.PIVOT.y],
		"layers_per_facing": PLANT.LAYERS,
		"leaves_per_facing": 6,
		"occupied_cell_offsets": [[0, 0]],
		"source_v1_sha256": FileAccess.get_sha256(PLANT.SOURCE_V1),
		"source_v2_sha256": FileAccess.get_sha256(PLANT.SOURCE_V2),
		"source_pixels_used": false,
		"image_generation_used_for_native_candidate": false,
		"runtime_registered": false,
		"dev_catalogue_registered": false,
	}
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened structural result")
	result.checks = checks
	result.failures = failures
	if file != null:
		file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Broadleaf planter structural: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
