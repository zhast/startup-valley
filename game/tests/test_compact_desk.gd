extends SceneTree
## Provider-free structural gate for the candidate-only compact desk base.

const DESK := preload("res://tools/compact_desk_geometry.gd")
const SHARED := preload("res://tools/modular_desk_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/fixtures/furniture-calibration/compact-desk-v1"
const EVIDENCE := "res://tests/output/compact-desk"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

static func expected_occupied(side: String) -> Array:
	return {
		"north": [[-1, 0], [0, 0]],
		"east": [[0, -1], [0, 0]],
		"south": [[1, 0], [0, 0]],
		"west": [[0, 1], [0, 0]],
	}[side]

static func expected_interaction(side: String) -> Array:
	return {"north": [0, 1], "east": [-1, 0], "south": [0, -1], "west": [1, 0]}[side]

static func floor_from_cells(values: Array) -> Rect2i:
	var low := Vector2i(999, 999)
	var high := Vector2i(-999, -999)
	for raw: Variant in values:
		var cell := OfficeLayout.vector(raw)
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	return Rect2i(low * 32 - Vector2i(16, 16), (high - low + Vector2i.ONE) * 32)

static func reflected(source: Image, horizontal: bool) -> Image:
	var result := source.duplicate()
	if horizontal: result.flip_x()
	else: result.flip_y()
	return result

static func visible_pixels(layer_name: String, parts: Dictionary) -> int:
	var index := DESK.LAYERS.find(layer_name)
	var result := 0
	for y: int in range(DESK.CANVAS.y):
		for x: int in range(DESK.CANVAS.x):
			if (parts[layer_name] as Image).get_pixel(x, y).a == 0.0: continue
			var covered := false
			for later: int in range(index + 1, DESK.LAYERS.size()):
				if (parts[DESK.LAYERS[later]] as Image).get_pixel(x, y).a > 0.0:
					covered = true
					break
			if not covered: result += 1
	return result

func run() -> void:
	check(DESK.SIDES == ["north", "east", "south", "west"], "Four facings use the canonical authored order")
	check(DESK.LAYERS == ["floor_shadow", "rear_structure", "front_structure"], "Base exports only the three planned base layers")
	check(DESK.CANVAS == Vector2i(160, 192) and DESK.PIVOT == Vector2i(80, 128), "Planned native canvas and floor anchor are exact")
	check(DESK.SPRITE_OFFSET + DESK.CANVAS / 2 == DESK.CANVAS - DESK.PIVOT, "Centered sprite offset preserves the unchanged floor pivot")
	var furnishing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/furnishing_catalog.json"))
	var compact_entry: Dictionary = furnishing["furniture"]["compact_desk"]
	var compact_passive := str(compact_entry.get("interaction_kind", "")) == "none"
	for side_name: String in DESK.SIDES:
		var shipped: Dictionary = compact_entry["facing_profiles"][side_name]
		compact_passive = compact_passive and str(shipped.get("profile_kind", "")) == "decorative" and str(shipped.get("status", "")) == "runtime_ready"
	check(compact_passive, "compact_desk is passive décor in the furnishing catalogue")
	check(FileAccess.get_file_as_string("res://data/office_layout.json").find("compact_desk") == -1, "Candidate has no default-layout binding")
	var source := FileAccess.get_file_as_string("res://tools/compact_desk_geometry.gd")
	for forbidden: String in ["rotate_", ".rotated(", "flip_x(", "flip_y(", "scale =", "transform ="]:
		check(source.find(forbidden) == -1, "Geometry source contains no raster transform: " + forbidden)
	var wholes := {}
	for side: String in DESK.SIDES:
		var p := DESK.profile(side)
		check(str(p.facing) == side and not p.is_empty(), side + " owns an explicit screen-space declaration")
		check(p.occupied == expected_occupied(side), side + " exact two-cell asymmetric anchor footprint")
		check(p.footprint == ([2, 1] if side in ["north", "south"] else [1, 2]), side + " honest 2x1/1x2 footprint")
		check(p.floor == floor_from_cells(p.occupied), side + " physical floor plane equals the declared occupied cells")
		check(p.clearance == [expected_interaction(side)] and p.interaction == expected_interaction(side), side + " one clear chair/approach cell is explicit")
		check(p.employee_look_vector == [-p.interaction[0], -p.interaction[1]], side + " actor gaze faces from the approach cell toward the desk")
		var shared_top: Rect2i = SHARED.profile(side).top
		var top: Rect2i = p.top
		check(top.get_area() < shared_top.get_area() * 0.65, side + " tabletop area is materially below the accepted shared desk")
		check((top.size == Vector2i(64, 30)) if side in ["north", "south"] else (top.size == Vector2i(30, 64)), side + " compact top is 64px long rather than 96px")
		var overlays := DESK.overlay_contract(side)
		check(overlays.keys().size() == 3 and overlays.has("chair") and overlays.has("device") and overlays.has("role"), side + " explicitly separates chair/device/role ownership")
		check(overlays.chair.owner_family == "ergonomic_chair" and overlays.chair.cell == p.interaction, side + " chair socket follows only the proposed approach cell")
		for kind: String in overlays:
			check(not bool(overlays[kind].included_in_base) and not bool(overlays[kind].adds_base_collision), side + " " + kind + " remains external and collision-free for the base")
		for kind: String in ["device", "role"]:
			check(top.encloses(overlays[kind].surface_zone), side + " compact " + kind + " socket stays on the native tabletop")
		var parts := DESK.layers(side)
		var whole := DESK.whole(side)
		wholes[side] = whole
		check(parts.keys().size() == 3 and whole.get_size() == DESK.CANVAS, side + " has three full-canvas base layers and one whole")
		var reconstructed := DESK.binary_over(DESK.binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure)
		check(reconstructed.get_data() == whole.get_data(), side + " floor/rear/front reconstruct the whole byte-exact")
		var whole_facts := PIXELS.analyze(whole)
		var bounds := OfficeLayout.rectangle(whole_facts.opaque_bounds)
		check(bounds.position.x >= 16 and bounds.position.y >= 16 and bounds.end.x <= DESK.CANVAS.x - 16 and bounds.end.y <= DESK.CANVAS.y - 16, side + " keeps at least 16px transparent canvas padding")
		check(int(bounds.end.y) == DESK.PIVOT.y + int(p.contact_y), side + " visible leg contact ends on the declared floor boundary")
		check(int(whole_facts.partial_alpha_pixels) == 0 and int(whole_facts.hidden_rgb_pixels) == 0, side + " whole has binary alpha and zero hidden RGB")
		for layer_name: String in DESK.LAYERS:
			var image: Image = parts[layer_name]
			var facts := PIXELS.analyze(image)
			check(image.get_size() == DESK.CANVAS and int(facts.opaque_pixels) > 0, side + " " + layer_name + " uses a nonempty full native canvas")
			check(int(facts.partial_alpha_pixels) == 0 and int(facts.hidden_rgb_pixels) == 0, side + " " + layer_name + " has clean binary transparency")
			check(visible_pixels(layer_name, parts) > 0, side + " " + layer_name + " owns visible surface pixels after compositing")
			var descriptor := DESK.descriptor(side, layer_name)
			check(descriptor.region == [0, 0, 160, 192] and descriptor.offset == [0, -32], side + " " + layer_name + " keeps exact integer registration")
			check(not descriptor.has("rotation") and not descriptor.has("scale") and not descriptor.has("flip_h") and not descriptor.has("flip_v"), side + " " + layer_name + " declares no raster transform")
			check(str(descriptor.art).begins_with("res://tests/fixtures/furniture-calibration/compact-desk-v1/"), side + " " + layer_name + " remains candidate-scoped")
			for owner: String in ["chair", "computer", "role"]:
				check(str(descriptor.art).find(owner) == -1 and str(descriptor.name).to_lower().find(owner) == -1, side + " " + layer_name + " does not alias a " + owner + " overlay")
			var disk := Image.load_from_file(ProjectSettings.globalize_path(str(descriptor.art)))
			check(not disk.is_empty() and disk.get_data() == image.get_data(), side + " " + layer_name + " deterministic fixture rebuilds byte-exact")
		var disk_whole := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(side + "-whole.png")))
		check(not disk_whole.is_empty() and disk_whole.get_data() == whole.get_data(), side + " whole fixture rebuilds byte-exact")
	for side: String in DESK.SIDES:
		for other: String in DESK.SIDES:
			if side >= other: continue
			check((wholes[side] as Image).get_data() != (wholes[other] as Image).get_data(), side + "/" + other + " remain independently identifiable")
	check((wholes.north as Image).get_data() != reflected(wholes.south, true).get_data(), "North is not a horizontal mirror of South")
	check((wholes.north as Image).get_data() != reflected(wholes.south, false).get_data(), "North is not a vertical mirror of South")
	check((wholes.east as Image).get_data() != reflected(wholes.west, true).get_data(), "East is not a horizontal mirror of West")
	check((wholes.east as Image).get_data() != reflected(wholes.west, false).get_data(), "East is not a vertical mirror of West")
	var entry := DESK.catalog_entry()
	check(entry.facings == DESK.SIDES and entry.facing_profiles.keys().size() == 4, "Dev-only entry exposes exactly four explicit facings")
	for side: String in DESK.SIDES:
		var profile: Dictionary = entry.facing_profiles[side]
		check(profile.profile_kind == "decorative" and profile.status == "calibration_candidate", side + " can enter only owner-scoped passive calibration")
		check(profile.review == {"art": false, "geometry": false}, side + " does not invent review approval")
		check(not profile.has("interaction") and not profile.has("work_cell") and not profile.has("pose_set"), side + " exposes no fake workstation action or pose")
		check(profile.proposed_workstation_interaction == expected_interaction(side), side + " retains the proposal socket as non-runtime metadata")
	var room_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/office_layout.json"))
	var production: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/furniture_catalog.json"))
	room_data.props = [{"id": "compact-desk-candidate", "kind": "compact_desk", "grid": [12, 13], "facing": "north", "required_hires": 0}]
	room_data.employees = []
	var catalogue: Dictionary = production.furniture.duplicate(true)
	catalogue["compact_desk"] = entry
	var model := OfficeLayout.new()
	model.configure(room_data, catalogue)
	var owner := Node.new()
	root.add_child(owner)
	check(model.enable_calibration_preview(owner), "Live test owner opens only its copied model")
	for side: String in DESK.SIDES:
		check(model.authorize_calibration_decorative_profile("compact_desk", side, owner), side + " exact passive candidate receives owner-scoped calibration admission")
		var resolution := model.resolve_profile("compact_desk", side)
		check(resolution.errors.is_empty() and resolution.profile.calibration_preview, side + " admitted copy resolves without production approval")
		check(not resolution.profile.has("interaction") and resolution.profile.standing_viewpoints.size() == 1, side + " resolved profile remains passive with one geometry-only actor viewpoint")
	var ordinary := OfficeLayout.new()
	ordinary.configure(room_data, catalogue)
	check(ordinary.available_facings("compact_desk").is_empty(), "Copied definitions do not copy the live calibration permit")
	model.disable_calibration_preview(owner)
	check(model.available_facings("compact_desk").is_empty(), "Closing the owner scope makes every candidate facing unavailable again")
	owner.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var file := FileAccess.open(EVIDENCE.path_join("structural-results.json"), FileAccess.WRITE)
	check(file != null, "Opened structural result")
	if file != null:
		file.store_string(JSON.stringify({"status": "passive_starter_decor_registered", "checks": checks, "failures": failures, "canvas": [160, 192], "pivot": [80, 128], "base_layers": DESK.LAYERS, "overlay_owners": ["ergonomic_chair", "computer_kit", "role_tool_kits"], "runtime_registered": true, "dev_catalogue_registered": false, "production_catalogue_registered": true, "interaction_kind": "none"}, "\t") + "\n")
	print("Compact desk structural: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
