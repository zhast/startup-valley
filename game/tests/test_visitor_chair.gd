extends SceneTree
## Provider-free structural, raster, collision-profile, and contact-contract gate
## for the dev-only visitor-chair candidate.

const CHAIR := preload("res://tools/visitor_chair_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/visitor-chair-v1"
const EVIDENCE := "res://tests/output/visitor-chair"
const DEV_CATALOGUE := "res://../dev/art-catalogue/furniture.json"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal: result.flip_x()
	else: result.flip_y()
	return result

func contains_color(image: Image, color: Color) -> bool:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y) == color: return true
	return false

func visible_pixels(layer_name: String, parts: Dictionary) -> int:
	var index := CHAIR.LAYERS.find(layer_name)
	var count := 0
	for y: int in range(CHAIR.CANVAS.y):
		for x: int in range(CHAIR.CANVAS.x):
			if (parts[layer_name] as Image).get_pixel(x, y).a == 0.0: continue
			var covered := false
			for above: int in range(index + 1, CHAIR.LAYERS.size()):
				if (parts[CHAIR.LAYERS[above]] as Image).get_pixel(x, y).a > 0.0:
					covered = true
					break
			if not covered: count += 1
	return count

func task_chair(side: String) -> Image:
	var result := Image.create(96, 160, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var suffixes: Array[String] = []
	if side in ["north", "south"]: suffixes.assign([side])
	else: suffixes.assign([side + "-rear", side + "-front"])
	for suffix: String in suffixes:
		var part := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/office/workstations-v2/chair-" + suffix + ".png"))
		if not part.is_empty(): result = PIXELS.binary_over(result, part)
	return result

func catalogue_family() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DEV_CATALOGUE))
	if not data is Dictionary: return {}
	for raw: Variant in data.get("families", []):
		if raw is Dictionary and str(raw.get("id", "")) == "visitor_chair": return raw as Dictionary
	return {}

func run() -> void:
	check(CHAIR.CANVAS == Vector2i(96, 144), "Planned visitor-chair canvas is exact")
	check(CHAIR.PIVOT == Vector2i(48, 96), "Planned visitor-chair floor pivot is exact")
	check(CHAIR.SPRITE_OFFSET + CHAIR.CANVAS / 2 == CHAIR.CANVAS - CHAIR.PIVOT, "Centered sprite offset preserves the common floor pivot")
	check(CHAIR.LAYERS == ["floor_shadow", "seat_back", "seat_front"], "Candidate exports exactly the three planned base layers")
	check(CHAIR.OCCUPIED == [Vector2i.ZERO], "Base owns exactly one 32px floor cell")
	var source := FileAccess.get_file_as_string("res://tools/visitor_chair_geometry.gd")
	for forbidden: String in ["flip_x(", "flip_y(", "rotate_90(", "Image.load_from_file", "task-chair-v", "chair-north.png"]:
		check(source.find(forbidden) == -1, "Geometry source has no finished-raster transform/reuse path: " + forbidden)
	check(FileAccess.get_file_as_string("res://data/furniture_catalog.json").find("visitor_chair") == -1, "Candidate has no production furniture registration")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("visitor_chair") == -1, "Candidate has no default-layout binding")
	var registered := catalogue_family()
	check(not registered.is_empty() and str(registered.get("production_status", "")) == "approved", "Developer catalogue records visitor_chair art approval")
	var approval: Dictionary = registered.get("art_library_approval", {})
	check(str(approval.get("scope", "")) == "passive_art_library" and approval.get("runtime_admission", true) == false, "Developer catalogue approval does not admit seating")
	for raw_variant: Variant in registered.get("variants", []):
		if not raw_variant is Dictionary: continue
		var variant: Dictionary = raw_variant
		var facing := str(variant.get("facing", ""))
		check(variant.get("seated_pose_needed", true) == false, facing + " records no seated pose")
		check(not variant.has("action") and not variant.has("seat_anchor") and not variant.has("reservation"), facing + " has no Sit action, seat anchor, or reservation")
		var socket: Variant = variant.get("optional_contact_socket", {})
		if socket is Dictionary and not (socket as Dictionary).is_empty():
			check((socket as Dictionary).get("runtime_capability", true) == false, facing + " contact socket is not seating admission")
	var registered_geometry: Dictionary = registered.get("native_geometry", {})
	check(OfficeLayout.vector(registered_geometry.get("canvas_size_px", [])) == CHAIR.CANVAS and OfficeLayout.vector(registered_geometry.get("floor_anchor_px", [])) == CHAIR.PIVOT, "Candidate preserves the registered shared canvas/anchor contract")
	var wholes := {}
	var directional_layers := {}
	for side: String in CHAIR.SIDES:
		var p := CHAIR.profile(side)
		var socket := CHAIR.contact_socket(side)
		check(not p.is_empty() and not socket.is_empty(), side + " has independent geometry and optional contact metadata")
		check(p.footprint == [1, 1] and p.occupied == [[0, 0]], side + " exact one-cell footprint")
		check(socket.physical_cell == p.interaction and socket.actor_gaze == p.employee_look_vector, side + " contact socket preserves planned direction semantics")
		var physical := OfficeLayout.vector(socket.physical_cell) * 32
		var render_offset := OfficeLayout.vector(socket.seated_render_offset)
		check(physical + render_offset == OfficeLayout.vector(socket.mounted_render_foot), side + " seated mount reconstructs from one walkable physical socket")
		check(Rect2i(-4, -4, 8, 8).has_point(OfficeLayout.vector(socket.mounted_render_foot)), side + " mounted render foot lands at the chair center")
		check((p.contact_points as Array).size() == 4, side + " declares four fixed leg contacts rather than a caster column")
		var parts := CHAIR.layers(side)
		var whole := CHAIR.whole(side)
		wholes[side] = whole
		directional_layers[side] = parts
		var whole_facts := PIXELS.analyze(whole)
		check(whole.get_size() == CHAIR.CANVAS and int(whole_facts.opaque_pixels) > 350, side + " chair is a nonempty native base")
		check(int(whole_facts.partial_alpha_pixels) == 0 and int(whole_facts.hidden_rgb_pixels) == 0, side + " whole has binary alpha and clean transparent RGB")
		var bounds := whole.get_used_rect()
		check(bounds.position.x >= 16 and bounds.position.y >= 16 and bounds.end.x <= CHAIR.CANVAS.x - 16 and bounds.end.y <= CHAIR.CANVAS.y - 16, side + " whole retains at least 16px transparent canvas padding")
		check(bounds.position.y >= CHAIR.PIVOT.y - 48 and bounds.end.y <= CHAIR.PIVOT.y + 16, side + " visible rise/contact remain within the planned one-cell envelope")
		check(contains_color(whole, CHAIR.FABRIC) or contains_color(whole, CHAIR.FABRIC_LIGHT), side + " visibly reads as upholstered guest seating")
		check(contains_color(whole, CHAIR.FRAME) and contains_color(whole, CHAIR.FRAME_LIGHT), side + " exposed fixed frame remains legible")
		for contact_value: Variant in p.contact_points:
			var contact := Vector2i(contact_value)
			check(Rect2i(-16, -16, 32, 32).has_point(contact), side + " fixed foot contact lies inside its exact collision cell")
			check(whole.get_pixelv(contact + CHAIR.PIVOT).a > 0.0, side + " fixed foot contact is actually painted")
		for layer_name: String in CHAIR.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			check(image.get_size() == CHAIR.CANVAS and int(facts.opaque_pixels) > 0, side + " " + layer_name + " uses a nonempty common canvas")
			check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, side + " " + layer_name + " has binary alpha and zero hidden RGB")
			check(visible_pixels(layer_name, parts) > 0, side + " " + layer_name + " retains a visible surface after reconstruction")
			var descriptor := CHAIR.descriptor(side, layer_name)
			check(descriptor.region == [0, 0, 96, 144] and descriptor.offset == [0, -24], side + " " + layer_name + " keeps integer canvas/anchor registration")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no raster transform")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/visitor-chair-v1/"), side + " " + layer_name + " remains fixture-scoped")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministic fixture rebuilds byte-exact")
		var rebuilt := CHAIR.binary_over(CHAIR.binary_over(parts.floor_shadow, parts.seat_back), parts.seat_front)
		check(rebuilt.get_data() == whole.get_data(), side + " ordered three layers reconstruct the whole byte-exact")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), side + " whole fixture rebuilds byte-exact")
		var padded := Image.create(96, 160, false, Image.FORMAT_RGBA8)
		padded.fill(Color(0, 0, 0, 0))
		padded.blit_rect(whole, Rect2i(Vector2i.ZERO, CHAIR.CANVAS), Vector2i(0, 16))
		check(padded.get_data() != task_chair(side).get_data(), side + " fixed guest chair is pixel-distinct from the accepted rolling task chair")
	for side: String in CHAIR.SIDES:
		for other: String in CHAIR.SIDES:
			if side >= other: continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " are direction-identifiable")
			for layer_name: String in CHAIR.LAYERS:
				check((directional_layers[side][layer_name] as Image).get_data() != (directional_layers[other][layer_name] as Image).get_data(), side + "/" + other + " " + layer_name + " remain independently authored")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data(), "North is not a horizontal mirror of South")
	check((wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North is not a vertical mirror of South")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data(), "East is not a horizontal mirror of West")
	check((wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East is not a vertical mirror of West")
	var entry := CHAIR.catalog_entry()
	check(entry.facings == CHAIR.SIDES and entry.facing_profiles.keys().size() == 4, "Dev-only entry exposes exactly four explicit facings")
	var room_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/office_layout.json"))
	var production: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/furniture_catalog.json"))
	room_data.props = [{"id": "visitor-chair-candidate", "kind": "visitor_chair", "grid": [12, 13], "facing": "north", "required_hires": 0}]
	room_data.employees = []
	var catalogue: Dictionary = production.furniture.duplicate(true)
	catalogue["visitor_chair"] = entry
	var model := OfficeLayout.new()
	model.configure(room_data, catalogue)
	var owner := Node.new()
	root.add_child(owner)
	check(model.enable_calibration_preview(owner), "Live test owner opens only its copied model")
	for side: String in CHAIR.SIDES:
		check(model.authorize_calibration_decorative_profile("visitor_chair", side, owner), side + " exact passive definition receives owner-scoped calibration admission")
		var resolution := model.resolve_profile("visitor_chair", side)
		check(resolution.errors.is_empty() and resolution.profile.calibration_preview, side + " admitted copy resolves without production approval")
		check(not resolution.profile.review.art and not resolution.profile.review.geometry, side + " admission does not invent art or geometry approval")
		for field: String in OfficeLayout.SEATED_FIELDS + ["interaction", "service_side", "approach_gaze", "action"]:
			check(not resolution.profile.has(field), side + " passive candidate exposes no runtime capability field " + field)
		check(resolution.profile.standing_viewpoints.size() == 1 and resolution.profile.optional_contact_socket.runtime_capability == false, side + " preserves one geometry-only optional standing/seated probe socket")
		var placement := model.resolve({"id": "probe", "kind": "visitor_chair", "grid": [12, 13], "facing": side})
		check(placement.occupied == [Vector2i(12, 13)] and placement.clearance == [Vector2i(12, 13) + OfficeLayout.vector(CHAIR.contact_socket(side).physical_cell)], side + " resolves exact collision and clear contact cells")
	var ordinary := OfficeLayout.new()
	ordinary.configure(room_data, catalogue)
	check(ordinary.available_facings("visitor_chair").is_empty(), "Copied definition has no production or unowned calibration admission")
	model.disable_calibration_preview(owner)
	check(model.available_facings("visitor_chair").is_empty(), "Closing owner scope revokes every candidate facing")
	owner.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened structural result")
	if file != null:
		file.store_string(JSON.stringify({
			"status": "approved_passive_art_no_seating_admission",
			"checks": checks,
			"failures": failures,
			"canvas": [96, 144],
			"pivot": [48, 96],
			"layers": CHAIR.LAYERS,
			"collision_cells": [[0, 0]],
			"contact_socket_modes": ["standing_probe", "seated_probe"],
			"actor_pixels_baked": false,
			"runtime_registered": false,
			"dev_catalogue_registered": true,
			"production_catalogue_registered": false,
		}, "\t") + "\n")
	print("Visitor chair structural: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
