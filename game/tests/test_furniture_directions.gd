extends SceneTree
## Geometry/renderer contract tests, NOT an art-acceptance showroom. Directional
## fixtures deliberately reuse labeled pieces of existing south artwork. They
## register synthetic pose capabilities only on isolated developer models.

const EDITOR: Script = preload("res://tools/office_layout_editor.gd")
const TEST_POSES := "test-only-direction-geometry"
const ART := "res://assets/runtime/office/collaboration-cluster-v2/east-table_front_structure.png"
const GRID := Vector2i(10, 8)
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var source := OfficeLayout.new()
	check(source.load_files(), "Production layout loads")
	_test_legacy(source)
	var model := _fixture(source)
	_test_resolution(model)
	_test_gates(source)
	_test_padded_content(source)
	await _test_room_and_editor(source)
	print("Furniture directions: %d checks, %d failures (synthetic geometry only; no directional art approval)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _fixture(source: OfficeLayout) -> OfficeLayout:
	var room := source.data.duplicate(true)
	room.props = [{"id": "mira-workstation", "kind": "desk", "grid": [GRID.x, GRID.y], "facing": "south", "owner_id": "mira", "required_hires": 0}]
	var catalog := source.catalog.duplicate(true)
	catalog.desk.facings = OfficeLayout.FACINGS.duplicate()
	catalog.desk.facing_profiles = {}
	for facing: String in OfficeLayout.FACINGS:
		catalog.desk.facing_profiles[facing] = _variant(facing)
	var model := OfficeLayout.new()
	model.configure(room, catalog)
	model.test_pose_capabilities[TEST_POSES] = OfficeLayout.FACINGS.duplicate()
	return model

func _variant(facing: String) -> Dictionary:
	var gaze := {"north": Vector2i.UP, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "west": Vector2i.LEFT}[facing] as Vector2i
	var axis := Vector2i(-gaze.y, gaze.x)
	var occupied: Array = []
	var clearance: Array = []
	for distance: int in range(-1, 2):
		var cell := axis * distance
		occupied.append([cell.x, cell.y])
		var lane := cell - gaze
		clearance.append([lane.x, lane.y])
	clearance.append([gaze.x, gaze.y])
	var row := 1 if facing in ["east", "west"] else 0
	return {
		"status": "runtime_ready", "review": {"art": true, "geometry": true, "poses": true},
		"fixture_notice": "SYNTHETIC GEOMETRY TEST: reused south plates are not directional artwork",
		"occupied": occupied, "clearance": clearance,
		"interaction": [gaze.x, gaze.y], "work_cell": [-gaze.x, -gaze.y],
		"anchor_offset": [0, 0], "visual_bounds": [-64, -80, 128, 96],
		# Reused plate ink sits at cell (24, 64); center this rect there so picking hits paint.
		"hit_bounds": [-48, -24, 16, 16], "work_facing": facing,
		"seat_anchor": [2, -3], "seat_z_offset": -gaze.y * 32, "pose_set": TEST_POSES,
		"render_layers": [
			{"name": "FixtureRear", "art": ART, "region": [0, row * 96, 128, 96], "content_bounds": [0, 0, 128, 96], "offset": [0, -32], "z_offset": -64},
			{"name": "FixtureFront", "art": ART, "region": [128, row * 96, 128, 96], "content_bounds": [0, 0, 128, 96], "offset": [0, -32], "z_offset": 40},
		],
		"ambient_overlays": [],
	}

func _test_legacy(source: OfficeLayout) -> void:
	for kind: String in source.catalog:
		var expected: Array[String] = []
		expected.assign(OfficeLayout.FACINGS if kind in ["artifact_archive", "approval_console", "coffee_station", "collaboration_cluster", "desk", "prototype_bench", "research_table", "broadleaf_planter", "task_floor_lamp", "coat_bag_stand", "water_station", "resource_cart", "printer_scanner_station", "recycling_sorter", "tall_storage_cabinet", "server_cabinet", "low_coffee_table", "round_meeting_table", "low_bookshelf", "acoustic_divider", "mobile_whiteboard", "visitor_chair", "two_seat_sofa", "lounge_armchair", "break_table", "compact_desk", "shared_workbench", "rolling_storage_pedestal"] else ["south"])
		check(source.available_facings(kind) == expected, "%s exposes only its genuinely reviewed shipped art" % kind)
	for stage: int in range(5):
		var placements := source.resolve_placements(stage)
		check(source.validate_placements(placements).valid, "Legacy stage %d remains valid" % stage)
		for placement: Dictionary in placements:
			var profile: Dictionary = source.catalog[placement.kind]
			if placement.get("profile_kind", "") == "collaboration":
				check(not placement.has("work_position") and not placement.has("work_cell"), "Reviewed collaboration cluster exposes shared sockets, not a workstation")
				check(placement.grid == Vector2i(12, 14) and placement.facing == "south", "Collaboration cluster starts in its four-facing validated South bay")
				check(placement.collaboration_slots.size() == 4 and placement.interaction == placement.collaboration_slots[0].cell, "Collaboration cluster exposes four deterministic sockets and a truthful reference interaction")
				for slot: Dictionary in placement.collaboration_slots:
					check(slot.position == source.world(slot.cell), "Collaboration socket keeps logical feet on its authored clear cell")
				continue
			if placement.get("profile_kind", "") == "service":
				check(not placement.has("work_position"), "Reviewed %s is standing service, not an invented seat" % placement.kind)
				if placement.kind == "artifact_archive":
					check(placement.grid == Vector2i(4, 13) and placement.facing == "south", "Archive visual promotion preserves default South bay")
				elif placement.kind == "approval_console":
					check(placement.grid == Vector2i(29, 13) and placement.facing == "south", "Decision-console promotion preserves its default South bay")
				elif placement.kind == "coffee_station":
					check(placement.grid == Vector2i(4, 6) and placement.facing == "south" and not bool(placement.profile.get("interaction_enabled", true)), "Coffee promotion preserves its default South bay and remains noninteractive")
				elif placement.kind == "prototype_bench":
					check(placement.grid == Vector2i(29, 18) and placement.facing == "south", "Prototype-bench promotion preserves its default South bay")
				else:
					check(placement.grid == Vector2i(10, 13) and placement.facing == "south", "Collaboration table promotion preserves its default South bay")
				var reviewed_service: Dictionary = source.resolve_profile(str(placement.kind), str(placement.facing)).profile
				check(placement.occupied == OfficeLayout._offset_cells(reviewed_service.occupied, placement.grid) and placement.clearance == OfficeLayout._offset_cells(reviewed_service.clearance, placement.grid), "%s physical footprint and access match its reviewed view" % placement.kind)
				continue
			if placement.kind == "desk":
				var reviewed: Dictionary = source.resolve_profile("desk", str(placement.facing)).profile
				check(placement.visual_bounds == OfficeLayout.rectangle(reviewed.visual_bounds), "Reviewed desk uses its direction's measured native bounds")
				check(placement.anchor == source.world(placement.grid) + Vector2(OfficeLayout.vector(reviewed.anchor_offset)), "Reviewed desk keeps an explicit direction-local ground origin")
				check(placement.work_position == source.world(placement.work_cell), "Reviewed desk socket never shifts logical feet")
				continue
			check(placement.visual_bounds == OfficeLayout.rectangle(profile.visual_bounds), "Legacy native art bounds are unchanged")
			check(placement.anchor == source.world(placement.grid) + Vector2(OfficeLayout.vector(profile.anchor_offset)), "Legacy ground origin is unchanged")
			check(placement.work_position == source.world(placement.work_cell), "Logical work destination is not shifted by pose anchors")
	var desk := source.placement_by_id("mira-workstation", 2)
	check(desk.work_cell == Vector2i(10, 7) and desk.seat_z_offset == 3, "Reviewed South desk keeps its north logical seat and explicit assembly depth")
	check(desk.visual_bounds.end.y == 16, "Measured +16px overhang is not reinterpreted as its ground anchor")
	check(desk.pose_set == CharacterArt.REVIEWED_WORKSTATION_POSE_SET, "Production metadata maps to the reviewed actor registry")
	var layer_names: Array[String] = []
	for layer: Dictionary in desk.render_layers: layer_names.append(str(layer.name))
	check(layer_names.has("DeskRear") and layer_names.has("DeskFront") and layer_names.has("ChairWhole"), "Reviewed assembly exposes independent desk and chair layers")

func _test_resolution(model: OfficeLayout) -> void:
	check(model.available_facings("desk") == OfficeLayout.FACINGS, "Explicit test-only pose capability enables all geometry fixtures")
	for facing: String in OfficeLayout.FACINGS:
		for stage: int in range(5):
			var result := model.validate_candidate("mira-workstation", GRID, facing, stage)
			check(result.valid, "%s fixture is reachable in stage %d: %s" % [facing, stage, result.errors])
			var placement: Dictionary = result.candidate
			var source: Dictionary = model.catalog.desk.facing_profiles[facing]
			check(placement.occupied == OfficeLayout._offset_cells(source.occupied, GRID), "Resolved occupied cells use the selected direction")
			check(placement.clearance == OfficeLayout._offset_cells(source.clearance, GRID), "Resolved clearance uses the selected direction")
			check(placement.work_cell == GRID + OfficeLayout.vector(source.work_cell), "Work cell follows facing, not last travel direction")
			check(placement.work_position == model.world(placement.work_cell), "Synthetic nonzero render anchor never changes logical feet")
			check(placement.seat_anchor == Vector2(2, -3) and placement.work_facing == facing, "Pose metadata stays separate and explicit")
			check(placement.render_layers[0].region == source.render_layers[0].region, "Art lookup uses selected region instead of rotating south bitmap")
		for invalid: Vector2i in [Vector2i(0, 10), Vector2i(10, 3), Vector2i(34, 10), Vector2i(10, 21), Vector2i(0, 3), Vector2i(34, 21), Vector2i(17, 10)]:
			check(not model.validate_candidate("mira-workstation", invalid, facing, 4).valid, "%s cannot rotate into walls/corners/circulation at %s" % [facing, invalid])
		var occupied := model.resolve({"id": "obstacle", "kind": "desk", "grid": [GRID.x, GRID.y], "facing": "south"})
		var candidate := model.resolve({"id": "candidate", "kind": "desk", "grid": [GRID.x, GRID.y], "facing": facing})
		check(not model.validate_placements([occupied, candidate]).valid, "Rotated furniture cannot overlap a second workstation")

func _test_gates(source: OfficeLayout) -> void:
	var model := _fixture(source)
	model.test_pose_capabilities.clear()
	check(model.available_facings("desk").is_empty(), "Review flags and a invented pose name alone never enable a direction")
	model = _fixture(source)
	var approved: Dictionary = model.catalog.desk.facing_profiles.east.duplicate(true)
	for field: String in OfficeLayout.DIRECTION_FIELDS:
		var broken := approved.duplicate(true)
		broken.erase(field)
		model.catalog.desk.facing_profiles.east = broken
		check(not model.available_facings("desk").has("east"), "Missing %s cannot inherit south metadata" % field)
	for gate: String in ["art", "geometry", "poses"]:
		var broken := approved.duplicate(true)
		broken.review[gate] = false
		model.catalog.desk.facing_profiles.east = broken
		check(not model.available_facings("desk").has("east"), "Missing %s review keeps facing unavailable" % gate)
	var mutations: Array[Dictionary] = [
		{"status": "generated_unreviewed"}, {"work_facing": "south"}, {"pose_set": "legacy-office-v1"},
		{"occupied": "bad"}, {"occupied": [[0.25, 0]]}, {"clearance": [[0, "bad"]]},
		{"seat_anchor": [0.5, 0]}, {"seat_z_offset": 1.5}, {"hit_bounds": [-200, 0, 400, 80]},
		{"ambient_overlays": [{"row": 99, "offset": [0, 0], "z_offset": 1}]},
	]
	for mutation: Dictionary in mutations:
		var broken := approved.duplicate(true)
		broken.merge(mutation, true)
		model.catalog.desk.facing_profiles.east = broken
		check(not model.available_facings("desk").has("east"), "Malformed or unreviewed direction is rejected: %s" % mutation)
		check(not model.validate_candidate("mira-workstation", GRID, "east", 2).valid, "Malformed direction also fails the full transaction safely")
	for mutation: Dictionary in [{"art": "res://missing-direction.png"}, {"region": [240, 0, 128, 96]}, {"rotation": 90}, {"flip_h": true}, {"scale": 0.5}]:
		var broken := approved.duplicate(true)
		broken.render_layers[0].merge(mutation, true)
		model.catalog.desk.facing_profiles.east = broken
		check(not model.available_facings("desk").has("east"), "Invalid layer cannot pass native art checks: %s" % mutation)
	model.catalog.desk.facing_profiles.east = approved.duplicate(true)
	model.catalog.desk.facing_profiles.east.render_layers.reverse()
	var ordered := model.resolve({"id": "layers", "kind": "desk", "grid": [GRID.x, GRID.y], "facing": "east"})
	check(ordered.render_layers[0].name == "FixtureRear", "Canonical layer ordering uses depth, not incidental JSON order")
	model.catalog.desk.facing_profiles.east = approved
	model.catalog.desk.facings = ["south"]
	check(not model.available_facings("desk").has("east"), "Reviewed profile remains gated until explicitly declared available")
	model.catalog.desk.facings = ["south", "east"]
	model.catalog.desk.facing_profiles.erase("east")
	check(not model.available_facings("desk").has("east"), "Listing east without a facing profile is not direction support")
	check(not model.validate_candidate("mira-workstation", GRID, "east", 2).valid, "Unsupported direction fails placement transaction")

func _test_padded_content(source: OfficeLayout) -> void:
	# This existing unapproved calibration source is used ONLY to prove alpha
	# geometry. Its source dimensions remain intact; no art is promoted/modified.
	const PADDED_ART := "res://tests/fixtures/furniture-calibration/desk-south-v2.png"
	var model := _fixture(source)
	var layer := {"name": "PaddedCalibrationOnly", "art": PADDED_ART, "region": [0, 0, 192, 224], "offset": [0, -48], "z_offset": 0}
	var ink := OfficeLayout.measured_layer_ink_bounds(layer)
	check(ink == Rect2(48, 110, 96, 66), "Calibration source has measured 96x66 ink inside its registered 192x224 canvas")
	var variant := _variant("south")
	variant.render_layers = [layer]
	variant.visual_bounds = [-48, -50, 96, 66]
	variant.hit_bounds = variant.visual_bounds.duplicate()
	model.catalog.desk.facing_profiles.south = variant
	var candidate := model.validate_candidate("mira-workstation", Vector2i(3, 5), "south", 2)
	check(candidate.valid, "Transparent canvas may cross architecture while all actual art/feet/clearance remain safely inside")
	check(candidate.candidate.render_layers[0].region == [0, 0, 192, 224], "Content bounds never trim or shift the full registered render region")
	check(candidate.candidate.world_visual_bounds == Rect2(64, 126, 96, 66), "Placement obstruction follows measured visible ink")
	var canvas := Rect2(model.world(Vector2i(3, 5)) + Vector2(-96, -160), Vector2(192, 224))
	check(not model.is_floor(model.cell_at(canvas.position)), "Padded fixture genuinely exercises an otherwise false-positive wall intersection")
	check(not model.validate_candidate("mira-workstation", Vector2i(3, 3), "south", 2).valid, "Actual opaque art entering a wall is still rejected")
	var conservative := variant.duplicate(true)
	conservative.render_layers[0].content_bounds = [46, 108, 100, 70]
	conservative.visual_bounds = [-50, -52, 100, 70]
	conservative.hit_bounds = conservative.visual_bounds.duplicate()
	model.catalog.desk.facing_profiles.south = conservative
	check(model.validate_candidate("mira-workstation", Vector2i(3, 5), "south", 2).valid, "A conservative protected box enclosing all ink is permitted")
	var undersized := variant.duplicate(true)
	undersized.render_layers[0].content_bounds = [48, 110, 16, 16]
	undersized.visual_bounds = [-48, -50, 16, 16]
	undersized.hit_bounds = undersized.visual_bounds.duplicate()
	model.catalog.desk.facing_profiles.south = undersized
	check(not model.available_facings("desk").has("south"), "Undersized declared content cannot conceal actual opaque artwork")
	check(not model.validate_candidate("mira-workstation", Vector2i(3, 3), "south", 2).valid, "Lying content metadata never permits a wall-clipping placement")
	var outside := variant.duplicate(true)
	outside.render_layers[0].content_bounds = [-1, -1, 194, 226]
	model.catalog.desk.facing_profiles.south = outside
	check(not model.available_facings("desk").has("south"), "Protected content cannot extend outside its registered layer region")

func _test_room_and_editor(source: OfficeLayout) -> void:
	root.size = Vector2i(1600, 800)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.gui_embed_subwindows = true
	var editor := EDITOR.new() as DevOfficeLayoutEditor
	root.add_child(editor)
	await _frames()
	var fixture := _fixture(source)
	editor.model.configure(fixture.data, fixture.catalog)
	editor.model.test_pose_capabilities = fixture.test_pose_capabilities.duplicate(true)
	editor.room.navigation.configure(editor.model.navigation_data(), editor.room.global_position)
	editor.room.architecture.configure(editor.model)
	editor.set_stage(2)
	editor.select_placement("mira-workstation")
	check(editor._facing_picker.item_count == 4, "Editor lists only validated model directions")
	for facing: String in OfficeLayout.FACINGS:
		check(editor.room.set_placement_overrides({"mira-workstation": {"grid": [GRID.x, GRID.y], "facing": facing}}), "Runtime accepts tested %s fixture" % facing)
		var placement := editor.room.placement_by_id("mira-workstation")
		var prop := editor.room.prop_node("mira-workstation")
		var preview := editor._preview_layers(placement)
		check(prop.rotation == 0 and prop.scale == Vector2.ONE, "Prop has zero raster rotation and native scale")
		for index: int in range(placement.render_layers.size()):
			var layer: Dictionary = placement.render_layers[index]
			var sprite := prop.get_node(NodePath(layer.name)) as Sprite2D
			check(sprite.texture == preview[index].texture and sprite.region_rect == preview[index].source, "Editor and runtime share actual art/region")
			check(Rect2(sprite.global_position - sprite.region_rect.size * 0.5, sprite.region_rect.size) == preview[index].destination, "Editor/runtime native layer rectangles agree")
			check(sprite.z_index == prop.z_index + layer.z_offset and not sprite.z_as_relative, "Resolved absolute layer depth is applied once")
			check(sprite.rotation == 0 and sprite.scale == Vector2.ONE and not sprite.flip_h and not sprite.flip_v, "Each layer remains unrotated and unmirrored")
			check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Native layer filtering stays nearest")
		for cell: Vector2i in placement.occupied:
			check(not editor.room.navigation.walkable(cell), "Resolved rotated occupancy reaches navigation")
		check(editor.room.navigation.walkable(placement.work_cell), "Rotated workstation leaves logical seat walkable")
		var metadata := editor.room.employee_workstation_visual("mira")
		check(metadata.prop_anchor == prop.global_position and metadata.work_position == editor.room.grid_to_world_position(placement.work_cell), "Actor metadata separates world prop anchor from logical feet")
		var inside: Vector2 = editor.room.global_position + placement.world_hit_bounds.get_center()
		check(editor.room.interaction_at(inside).get("id") == "mira-workstation", "Runtime hit testing follows selected native hit bounds")
		var outside: Vector2 = editor.room.global_position + placement.world_visual_bounds.position + Vector2.ONE
		check(editor.room.interaction_at(outside).is_empty(), "Transparent visual margin is not treated as interactive")
		var record := EmployeeRecord.new()
		record.id = "mira"
		record.display_name = "Mina"
		record.desk_grid = placement.grid
		editor.room.configure_employee_desks([record])
		check(editor.room.placement_by_id("mira-workstation").facing == facing, "Roster refresh preserves %s orientation" % facing)
	check(editor.room.set_placement_overrides({}), "Fixture resets before real input")
	editor.overrides.clear()
	editor._refresh_placements()
	editor.select_placement("mira-workstation")
	await _frames()
	await _key(KEY_R)
	check(editor.placement_active and editor.preview_facing == "west", "Real R key begins a clockwise next-authored-direction preview")
	check(editor.preview_result.valid, "Rotated preview validates before commitment")
	await _click(editor.ROOM_ORIGIN + editor.model.world(GRID))
	check(not editor.placement_active and editor.room.placement_by_id("mira-workstation").facing == "west", "Real click commits rotation atomically")
	var output := DevOfficeLayoutEditor.EXPORT_DIRECTORY + "/test-only-direction-layout.json"
	check(editor.export_layout(output), "Directional layout exports only to developer output")
	var exported: Dictionary = OfficeLayout._read_json(output)
	var reloaded := _fixture(source)
	reloaded.configure(exported, fixture.catalog)
	check(reloaded.placement_by_id("mira-workstation", 2).facing == "west", "Exported rotation survives a fresh isolated model reload")
	check(reloaded.validate_placements(reloaded.resolve_placements(2)).valid, "Reloaded geometry validates with explicit test-only capability, not production art")
	await _key(KEY_Z, true)
	check(editor.room.placement_by_id("mira-workstation").facing == "south", "Real undo restores the prior facing")
	await _key(KEY_R)
	editor.preview_at(Vector2i(0, 3))
	check(not editor.commit_preview(), "Invalid wall rotation cannot commit")
	check(editor.room.placement_by_id("mira-workstation").facing == "south", "Rejected rotation preserves rendered state")
	await _key(KEY_ESCAPE)
	check(not editor.placement_active, "Escape cancels rotation without modifying production files")
	editor.queue_free()
	await _frames()

func _frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func _key(code: Key, control: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.ctrl_pressed = control
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(1)
	await _frames()

func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await _frames()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(1)
	await _frames()
