extends SceneTree
## Provider-free structural, direction-identity, and host-contact gate for the
## candidate-only lawyer contract kit v2.

const KIT := preload("res://tools/lawyer_contract_kit_v2_geometry.gd")
const DESK := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/lawyer-contract-kit-v2"
const EVIDENCE := "res://tests/output/lawyer-contract-kit-v2"
const LEGACY_HASHES := {
	"res://assets/source/overnight-20260904/roles/lawyer-kit-north-v1.png": "f7d813ec9a169ebd2cf134cc42c70dd246b5066663b20ad84652ce0a5505d2da",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-north-v2.png": "2688874c455e9321342abeb41fa606333cce3c74e4284604c94eb1b1766f3847",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-north-v3.png": "5551319e0cc60e339b76991c9cedb68a10aef523180a138b7a315fe46819c7ec",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v1.png": "e7803c933077384c69424b2640283fe31ecd0e2465fb21b52ee1b02374f3ed9e",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v2.png": "becc03eede387e6a57e82c8062a9a3e531081aa7fdbf0aa249207da405624e14",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v3.png": "66caac7bbd9bebed7ff8aa93c6b854047fed8e7919efbc56c7d19379d7850d4d",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-east-v4.png": "2433507ee40add344a53bcb931cc12b2fc5cc66d711dd46e589ef4512a8c0335",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-south-v1.png": "db41ae7fe4d5687eb2280f9abd722d2b374ff1ad57fb7298d799c41f48f3abc2",
	"res://assets/source/overnight-20260904/roles/lawyer-kit-south-v2.png": "773cf2b3e25e04c32c1a2d212a61111863c69ab8818bff8dc6f6764faf96f67c",
	"res://tests/fixtures/furniture-calibration/roles/lawyer-north-v3-brand.png": "85580dcbaa1acd26a806195623342f91bac33dfd8c9098fcc610972287342aff",
	"res://tests/fixtures/furniture-calibration/roles/lawyer-south-v2.png": "ae1250d0d5cf3228faea287c74083601ddce371a0be0c01e49fb1e055ce1bfc6",
	"res://tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4.png": "48bb6bd9c349ab76347bc6e95927ad6a77c8c9092f3c68687935012783720f4e",
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

func check_identity_pixels(side: String, binder: Image, folder: Image, cup: Image) -> void:
	var spine_points := {
		"north": Vector2i(53, 116),
		"east": Vector2i(102, 84),
		"south": Vector2i(137, 116),
		"west": Vector2i(84, 167),
	}
	var tab_points := {
		"north": [Vector2i(140, 119), Vector2i(140, 123), Vector2i(140, 127)],
		"east": [Vector2i(98, 163), Vector2i(102, 163), Vector2i(106, 163)],
		"south": [Vector2i(50, 119), Vector2i(50, 123), Vector2i(50, 127)],
		"west": [Vector2i(84, 84), Vector2i(88, 84), Vector2i(92, 84)],
	}
	var pen_points := {
		"north": [Vector2i(54, 128), Vector2i(59, 129)],
		"east": [Vector2i(86, 85), Vector2i(89, 87)],
		"south": [Vector2i(137, 128), Vector2i(132, 129)],
		"west": [Vector2i(105, 149), Vector2i(102, 151)],
	}
	check(binder.get_pixelv(spine_points[side]) == KIT.BINDER_SPINE, side + " binder paints its authored physical spine edge")
	var tabs: Array = tab_points[side]
	check(folder.get_pixelv(tabs[0]) == KIT.TAB_GREEN and folder.get_pixelv(tabs[1]) == KIT.CERULEAN and folder.get_pixelv(tabs[2]) == KIT.TAB_GOLD, side + " folder tabs occupy the authored outer edge in stable order")
	var pens: Array = pen_points[side]
	check(cup.get_pixelv(pens[0]) == KIT.PEN_RED and cup.get_pixelv(pens[1]) == KIT.CERULEAN, side + " cup preserves the turned red/blue pen order")

func run() -> void:
	check(KIT.SIDES == ["north", "east", "south", "west"], "Exactly one ordered N/E/S/W candidate set")
	check(KIT.CANVAS == Vector2i(192, 224) and KIT.PIVOT == Vector2i(96, 160), "Accepted desk canvas and floor pivot are exact")
	check(KIT.SPRITE_OFFSET + KIT.CANVAS / 2 == KIT.CANVAS - KIT.PIVOT, "Centered sprite offset resolves the fixed floor pivot")
	check(KIT.COLLISION_CELLS.is_empty(), "Legal surface decor adds zero floor collision")
	check(KIT.LAYERS == ["surface_decor_rear", "surface_decor_front"], "Only reusable rear/front surface overlays are exported")
	check(KIT.OBJECTS == ["contract_binder", "tabbed_review_folder", "pen_cup"], "Every facing carries the bounded legal-planning identity")
	var semantic_identity := " ".join(KIT.OBJECTS)
	for forbidden: String in ["gavel", "court", "filing_service", "employee", "hire", "signature_execution"]:
		check(forbidden not in semantic_identity, "Semantic identity does not imply " + forbidden)
	var geometry_source := FileAccess.get_file_as_string("res://tools/lawyer_contract_kit_v2_geometry.gd")
	for forbidden_call: String in ["flip_x(", "flip_y(", "resize(", "draw_string", "Font", "Transform2D"]:
		check(geometry_source.find(forbidden_call) == -1, "Geometry has no finished-raster/text transform path " + forbidden_call)
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("lawyer_contract_kit") == -1, "Candidate has no production furniture registration")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("lawyer_contract_kit") == -1, "Candidate has no default-layout binding")
	check(LEGACY_HASHES.size() == 12, "Preservation guard covers all nine legal masters and three retained native candidates")
	for path: String in LEGACY_HASHES:
		check(FileAccess.file_exists(path), "Retained legal evidence exists: " + path)
		check(FileAccess.get_sha256(path) == str(LEGACY_HASHES[path]), "Retained legal evidence remains byte-exact: " + path)
	var expected_left := {"north": "west", "east": "north", "south": "east", "west": "south"}
	var expected_checklist := {"north": "east", "east": "south", "south": "west", "west": "north"}
	var expected_axis := {"north": "screen_horizontal", "east": "screen_vertical", "south": "screen_horizontal", "west": "screen_vertical"}
	var expected_gaze := {"north": Vector2i.UP, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "west": Vector2i.LEFT}
	var expected_binder_size := {"north": Vector2i(20, 12), "east": Vector2i(12, 20), "south": Vector2i(20, 12), "west": Vector2i(12, 20)}
	var expected_folder_size := {"north": Vector2i(18, 14), "east": Vector2i(14, 18), "south": Vector2i(18, 14), "west": Vector2i(14, 18)}
	var wholes: Dictionary = {}
	var directional_layers: Dictionary = {}
	for side: String in KIT.SIDES:
		var identity := KIT.direction_identity(side)
		check(identity.employee_look_vector == expected_gaze[side], side + " host gaze is exact")
		check(str(identity.worker_left_edge) == str(expected_left[side]), side + " worker-left edge turns physically with host gaze")
		check(str(identity.binder_spine_edge) == str(expected_left[side]), side + " binder spine stays on worker left")
		check(str(identity.folder_blank_leaf) == str(expected_left[side]), side + " blank leaf stays on worker left")
		check(str(identity.folder_checklist_leaf) == str(expected_checklist[side]) and str(identity.folder_tab_edge) == str(expected_checklist[side]), side + " checklist and tabs stay on the worker-right outer leaf")
		check(str(identity.page_mark_axis) == str(expected_axis[side]), side + " checklist marks turn with the physical page")
		var specs := KIT.specifications(side)
		check(specs.size() == KIT.OBJECTS.size(), side + " declares exactly three semantic objects")
		var object_union := Image.create(KIT.CANVAS.x, KIT.CANVAS.y, false, Image.FORMAT_RGBA8)
		object_union.fill(Color(0, 0, 0, 0))
		var seen: Array[Image] = []
		var desk_top: Rect2i = DESK.profile(side).top
		desk_top.position += KIT.PIVOT
		for object_name: String in KIT.OBJECTS:
			check(specs.has(object_name), side + " includes " + object_name)
			var spec: Dictionary = specs[object_name]
			check(str(spec.construction) == "authored_" + side, side + " " + object_name + " is an explicit facing construction")
			var expected_object_axis := "upright" if object_name == "pen_cup" else ("horizontal" if side in ["north", "south"] else "vertical")
			check(str(spec.axis) == expected_object_axis, side + " " + object_name + " uses the authored screen-space projection")
			var object := KIT.object_image(side, object_name)
			var bounds := object.get_used_rect()
			check(bounds.has_area() and desk_top.grow(-2).encloses(bounds), side + " " + object_name + " rests wholly on accepted tabletop ink")
			if object_name == "contract_binder":
				check(bounds.size == expected_binder_size[side], side + " binder preserves the common 20x12 / 12x20 physical contract")
			elif object_name == "tabbed_review_folder":
				check(bounds.size == expected_folder_size[side], side + " folder preserves the common 18x14 / 14x18 physical contract")
			else:
				check(bounds.size == Vector2i(10, 14), side + " upright pen cup keeps one common silhouette envelope")
			for prior: Image in seen:
				check(opaque_overlap(object, prior) == 0, side + " semantic objects remain disjoint")
			seen.append(object)
			object_union = KIT.binary_over(object_union, object)
		var binder := KIT.object_image(side, "contract_binder")
		var folder := KIT.object_image(side, "tabbed_review_folder")
		var cup := KIT.object_image(side, "pen_cup")
		check(contains_color(binder, KIT.BINDER) and contains_color(binder, KIT.PAPER), side + " binder retains cover, spine, and page cues")
		check(contains_color(folder, KIT.PAPER_LIGHT) and contains_color(folder, KIT.TAB_GREEN) and contains_color(folder, KIT.TAB_GOLD), side + " folder retains blank pages, checklist marks, and three tabs")
		check(contains_color(cup, KIT.CUP) and contains_color(cup, KIT.PEN_RED) and contains_color(cup, KIT.CERULEAN), side + " pen cup retains vessel and two pen colors")
		check_identity_pixels(side, binder, folder, cup)
		var parts := KIT.layers(side)
		var whole := KIT.whole(side)
		wholes[side] = whole
		directional_layers[side] = parts
		check(parts.size() == 2, side + " exports exactly two semantic layers")
		for layer_name: String in KIT.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			var descriptor := KIT.descriptor(side, layer_name)
			check(image.get_size() == KIT.CANVAS and facts.opaque_pixels > 0, side + " " + layer_name + " is nonempty on the common canvas")
			check(facts.partial_alpha_pixels == 0 and facts.hidden_rgb_pixels == 0, side + " " + layer_name + " has binary alpha and zero hidden RGB")
			check(descriptor.region == [0, 0, 192, 224] and descriptor.offset == [0, -48], side + " " + layer_name + " keeps integer anchor registration")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/lawyer-contract-kit-v2/"), side + " " + layer_name + " remains candidate-fixture scoped")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no raster transform")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministic fixture rebuilds byte-exact")
		check(KIT.layer_depth(side, "surface_decor_front") > KIT.layer_depth(side, "surface_decor_rear"), side + " preserves rear/actor/front depth ordering")
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
		if side == "north":
			deltas = {"monitor": Vector2i(0, -10), "keyboard": Vector2i(0, 4), "mouse": Vector2i(0, 4)}
		elif side == "east":
			deltas = {"monitor": Vector2i.ZERO, "keyboard": Vector2i(6, 0), "mouse": Vector2i(6, 0)}
		elif side == "south":
			deltas.monitor = Vector2i(0, 3)
		for device: String in device_paths:
			var accepted_device := shifted(device_paths[device], deltas[device])
			check(opaque_overlap(whole, accepted_device) == 0, side + " legal kit clears accepted " + device)
			for object_name: String in KIT.OBJECTS:
				check(opaque_overlap(KIT.object_image(side, object_name), accepted_device) == 0, side + " " + object_name + " clears accepted " + device)
	for side: String in KIT.SIDES:
		for other: String in KIT.SIDES:
			if side >= other:
				continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " whole constructions are independently identifiable")
			for layer_name: String in KIT.LAYERS:
				var side_layers: Dictionary = directional_layers[side]
				var other_layers: Dictionary = directional_layers[other]
				check((side_layers[layer_name] as Image).get_data() != (other_layers[layer_name] as Image).get_data(), side + "/" + other + " " + layer_name + " are independently identifiable")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data(), "North is not a horizontal mirror of South")
	check((wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North is not a vertical mirror of South")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data(), "East is not a horizontal mirror of West")
	check((wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East is not a vertical mirror of West")
	var old_west := Image.load_from_file(ProjectSettings.globalize_path("res://tests/fixtures/furniture-calibration/roles/lawyer-west-reclassified-v4.png"))
	for side: String in ["east", "west"]:
		var current: Image = wholes[side]
		check(current.get_data() != old_west.get_data(), side + " v2 is materially different from the misdirected legacy candidate")
		check(current.get_data() != reflected(old_west, true).get_data() and current.get_data() != reflected(old_west, false).get_data(), side + " v2 is not a reflected legacy candidate")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened structural result")
	if file != null:
		file.store_string(JSON.stringify({
			"status": "native_review_candidate_not_catalogued_or_runtime_registered",
			"family": "lawyer_contract_kit",
			"candidate_revision": "lawyer-contract-kit-v2",
			"host": "accepted desk / workstations-v2",
			"checks": checks,
			"failures": failures,
			"canvas": [192, 224],
			"pivot": [96, 160],
			"objects_per_facing": KIT.OBJECTS,
			"layers_per_facing": KIT.LAYERS,
			"collision_cells": [],
			"legacy_files_hash_guarded": LEGACY_HASHES.size(),
			"image_generation_calls": 0,
			"east_retry_budget_reopened": false,
			"runtime_registered": false,
			"dev_catalogue_registered": false,
			"production_catalogue_registered": false,
			"legal_service_or_hire_created": false,
		}, "\t") + "\n")
	print("Lawyer contract kit v2: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
