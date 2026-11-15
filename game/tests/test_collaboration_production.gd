extends SceneTree
## Ordinary-production acceptance for collaboration-cluster-v2. This test loads
## GameMain's real catalogue/default layout and never installs a fixture profile.
## Native runs retain unscaled entry/hold/work-interrupt keyframes; headless runs
## exercise the same lifecycle, navigation, collision, stage and Renovate paths.

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const GEOMETRY := preload("res://tools/collaboration_table_geometry.gd")
const OUTPUT := "res://tests/output/collaboration-production"
const PRODUCTION_CATALOG := "res://data/furniture_catalog.json"
const DEFAULT_LAYOUT := "res://data/office_layout.json"
const ART_ROOT := "res://assets/runtime/office/collaboration-cluster-v2"
const ACTOR_IDS: Array[String] = ["mira", "theo"]
const MAX_ROUTE_FRAMES := 900
const SETTLE_FRAMES := 16
const MAX_VISUAL_STEP_PX := 16.0
const ACTOR_CROP := Vector2i(128, 144)

var main: GameMain
var checks := 0
var failures: Array[String] = []
var observations: Dictionary = {}
var captures: Array[String] = []
var entry_sequences: Dictionary = {}
var exit_sequences: Dictionary = {}
var hold_details: Dictionary = {}
var full_holds: Dictionary = {}
var rotation_details: Dictionary = {}
var pause_proofs: Dictionary = {}
var motion_probe: Dictionary = {}
var catalog_hash_before := ""
var layout_hash_before := ""
var starting_overrides: Dictionary = {}

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for _index: int in range(count):
		await process_frame

func cell_values(cell: Vector2i) -> Array[int]:
	return [cell.x, cell.y]

func point_values(point: Vector2) -> Array[float]:
	return [point.x, point.y]

func begin_motion_probe(label: String, targets: Dictionary = {}) -> void:
	var previous_render: Dictionary = {}
	var previous_position: Dictionary = {}
	var max_visual_step := {"mira": 0.0, "theo": 0.0}
	var max_physical_step := {"mira": 0.0, "theo": 0.0}
	var max_visual_sample := {"mira": {}, "theo": {}}
	var split_contact_seen := {"mira": false, "theo": false}
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		previous_render[actor_id] = actor.render_position()
		previous_position[actor_id] = actor.position
	motion_probe = {
		"active": true,
		"label": label,
		"targets": targets.duplicate(true),
		"previous_render": previous_render,
		"previous_position": previous_position,
		"max_visual_step": max_visual_step,
		"max_physical_step": max_physical_step,
		"max_visual_sample": max_visual_sample,
		"split_contact_seen": split_contact_seen,
		"physics_samples": 0,
		"unsafe_samples": 0,
		"reservation_conflicts": 0,
	}

func sample_motion_frame() -> void:
	# SceneTree.physics_frame is emitted once before every physics traversal.
	# Reading the prior traversal's final actor state here gives a gap-free
	# per-tick sequence even while native PNG acquisition awaits a render frame.
	if not bool(motion_probe.get("active", false)) or not is_instance_valid(main): return
	var previous_render := motion_probe.previous_render as Dictionary
	var previous_position := motion_probe.previous_position as Dictionary
	var max_visual_step := motion_probe.max_visual_step as Dictionary
	var max_physical_step := motion_probe.max_physical_step as Dictionary
	var max_visual_sample := motion_probe.max_visual_sample as Dictionary
	var split_contact_seen := motion_probe.split_contact_seen as Dictionary
	var targets := motion_probe.targets as Dictionary
	var tick := Engine.get_physics_frames()
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		if actor == null: continue
		var current_render := actor.render_position()
		var current_position := actor.position
		var visual_step := current_render.distance_to(previous_render.get(actor_id, current_render))
		var physical_step := current_position.distance_to(previous_position.get(actor_id, current_position))
		if visual_step > float(max_visual_step.get(actor_id, 0.0)):
			max_visual_step[actor_id] = visual_step
			max_visual_sample[actor_id] = {
				"physics_tick": tick,
				"from": point_values(previous_render.get(actor_id, current_render)),
				"to": point_values(current_render),
				"position": point_values(current_position),
				"seat_offset": point_values(actor.seated_render_offset()),
				"has_target": actor._has_target,
				"collaboration_handoff": actor._uses_collaboration_handoff(),
				"split_layers": actor._active_work_pose_layers.size(),
			}
		max_physical_step[actor_id] = maxf(float(max_physical_step.get(actor_id, 0.0)), physical_step)
		previous_render[actor_id] = current_render
		previous_position[actor_id] = current_position
		if targets.has(actor_id) and actor._has_target and actor.position.distance_to(targets[actor_id]) < 32.0 and actor._active_work_pose_layers.size() == 2:
			split_contact_seen[actor_id] = true
		if not main.room.navigation.position_is_safe(actor.position, actor_id):
			motion_probe.unsafe_samples = int(motion_probe.unsafe_samples) + 1
	var reservations := main.room.navigation.reservations
	if reservations.has("mira") and reservations.has("theo") and reservations.mira == reservations.theo:
		motion_probe.reservation_conflicts = int(motion_probe.reservation_conflicts) + 1
	motion_probe.physics_samples = int(motion_probe.physics_samples) + 1

func end_motion_probe() -> Dictionary:
	if motion_probe.is_empty(): return {}
	motion_probe.active = false
	var result := motion_probe.duplicate(true)
	result.erase("active")
	result.erase("previous_render")
	result.erase("previous_position")
	motion_probe.clear()
	return result

func event(kind: StringName) -> WorkerEventRecord:
	var value := WorkerEventRecord.new()
	value.type = kind
	return value

func collision_shapes(node: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	if node is CollisionShape2D:
		result.append(node as CollisionShape2D)
	for child: Node in node.get_children():
		result.append_array(collision_shapes(child))
	return result

func collision_signature(prop: Node2D) -> Array[String]:
	var result: Array[String] = []
	for collision: CollisionShape2D in collision_shapes(prop):
		var rectangle := collision.shape as RectangleShape2D
		var size := rectangle.size if rectangle != null else Vector2.ZERO
		var world_position := prop.global_position + collision.position
		result.append("%.1f,%.1f:%.1f,%.1f" % [world_position.x, world_position.y, size.x, size.y])
	result.sort()
	return result

func viewport_image() -> Image:
	if DisplayServer.get_name() == "headless": return Image.new()
	await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image != null and image.get_size() == Vector2i(1280, 720), "Native GameMain capture remains exactly 1280x720")
	return image

func actor_crop(image: Image, target: Vector2) -> Image:
	if image == null or image.is_empty(): return Image.new()
	var origin := Vector2i(target.round()) - Vector2i(ACTOR_CROP.x / 2, 104)
	origin.x = clampi(origin.x, 0, image.get_width() - ACTOR_CROP.x)
	origin.y = clampi(origin.y, 0, image.get_height() - ACTOR_CROP.y)
	return image.get_region(Rect2i(origin, ACTOR_CROP))

func placement_crop(image: Image, placement: Dictionary) -> Image:
	if image == null or image.is_empty(): return Image.new()
	var origin := Vector2i(main.room.global_position + Vector2(placement.anchor)) - GEOMETRY.PIVOT
	return image.get_region(Rect2i(origin, GEOMETRY.CANVAS))

func save_image(image: Image, path: String) -> void:
	if image == null or image.is_empty(): return
	check(image.save_png(path) == OK, "Saved native production evidence: " + path)
	captures.append(path)

func append_limited(values: Array, image: Image, limit: int) -> void:
	if image == null or image.is_empty(): return
	values.append(image.duplicate())
	while values.size() > limit: values.pop_front()

func pad_sequence(values: Array, count: int) -> Array:
	var result := values.duplicate()
	if result.is_empty(): return result
	while result.size() < count: result.append((result[-1] as Image).duplicate())
	while result.size() > count: result.pop_front()
	return result

func build_motion_sheet(source: Dictionary, filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var rows := GEOMETRY.SIDES.size() * ACTOR_IDS.size()
	var sheet := Image.create(ACTOR_CROP.x * 8, ACTOR_CROP.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("151515"))
	var row := 0
	for side: String in GEOMETRY.SIDES:
		for actor_id: String in ACTOR_IDS:
			var values: Array = pad_sequence(source.get(side + "/" + actor_id, []), 8)
			for index: int in range(values.size()):
				sheet.blit_rect(values[index] as Image, Rect2i(Vector2i.ZERO, ACTOR_CROP), Vector2i(index * ACTOR_CROP.x, row * ACTOR_CROP.y))
			row += 1
	save_image(sheet, OUTPUT.path_join(filename))

func build_four_facing_sheet(source: Dictionary, filename: String) -> void:
	if source.size() != GEOMETRY.SIDES.size(): return
	var sample := source[GEOMETRY.SIDES[0]] as Image
	if sample == null or sample.is_empty(): return
	var sheet := Image.create(sample.get_width() * 2, sample.get_height() * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("151515"))
	for index: int in range(GEOMETRY.SIDES.size()):
		var side: String = GEOMETRY.SIDES[index]
		sheet.blit_rect(source[side] as Image, Rect2i(Vector2i.ZERO, sample.get_size()), Vector2i(index % 2 * sample.get_width(), index / 2 * sample.get_height()))
	save_image(sheet, OUTPUT.path_join(filename))

func build_rotation_sheet() -> void:
	if DisplayServer.get_name() == "headless": return
	var sample := rotation_details.get("north-occupied") as Image
	if sample == null or sample.is_empty(): return
	var sheet := Image.create(sample.get_width() * 2, sample.get_height() * GEOMETRY.SIDES.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("151515"))
	for row: int in range(GEOMETRY.SIDES.size()):
		var side: String = GEOMETRY.SIDES[row]
		for column: int in range(2):
			var state := "occupied" if column == 0 else "vacant"
			var value := rotation_details.get(side + "-" + state) as Image
			if value != null and not value.is_empty():
				sheet.blit_rect(value, Rect2i(Vector2i.ZERO, sample.get_size()), Vector2i(column * sample.get_width(), row * sample.get_height()))
	save_image(sheet, OUTPUT.path_join("rotation-contact-sheet-native.png"))

func production_contract() -> Dictionary:
	var result: Dictionary = {}
	check(not starting_overrides.has("collaboration-cluster"), "Ordinary GameMain begins with no collaboration candidate/session override")
	for id: String in starting_overrides:
		var override := starting_overrides[id] as Dictionary
		var authored := main.room.layout_model.placement_by_id(id, 4, {})
		check(id.ends_with("-workstation") and not authored.is_empty(), "Ordinary worker-disabled bootstrap only materializes authored workstation records: " + id)
		check(OfficeLayout.vector(override.get("grid", [])) == authored.grid and str(override.get("facing", "")) == str(authored.facing), "Bootstrap workstation override remains equal to authored production truth: " + id)
	check(not main.room.layout_model.calibration_preview_enabled(), "Ordinary production model has no calibration owner or candidate permit")
	check(main.room.layout_model.available_facings("collaboration_cluster") == GEOMETRY.SIDES, "Production catalogue directly admits exactly N/E/S/W collaboration views")
	var raw_layout: Dictionary = main.room.layout_model.data
	var raw_cluster: Dictionary = {}
	for item: Variant in raw_layout.get("props", []):
		if item is Dictionary and str((item as Dictionary).get("id", "")) == "collaboration-cluster":
			raw_cluster = item as Dictionary
			break
	check(not raw_cluster.is_empty() and OfficeLayout.vector(raw_cluster.get("grid", [])) == Vector2i(12, 14), "Default production collaboration pivot is the reviewed [12,14] cell")
	check(str(raw_cluster.get("facing", "")) == "south" and int(raw_cluster.get("required_hires", -1)) == 1, "Default production keeps South and unlocks at the first hire")
	for side: String in GEOMETRY.SIDES:
		var resolution := main.room.layout_model.resolve_profile("collaboration_cluster", side)
		var profile: Dictionary = resolution.profile
		check((resolution.errors as Array).is_empty(), side + " production profile resolves without candidate injection: " + str(resolution.errors))
		check(str(profile.get("status", "")) == "runtime_ready" and str(profile.get("profile_kind", "")) == "collaboration", side + " is an ordinary runtime collaboration profile")
		check(str(profile.get("asset_revision", "")) == "collaboration-cluster-v2" and str(profile.get("reference_gaze", "")) == side, side + " resolves the reviewed v2 screen-axis identity")
		check(profile.get("interaction_enabled") == false, side + " collaboration surface is explicitly noninteractive")
		check(not profile.has("calibration_preview") and not profile.has("calibration_owner_id"), side + " contains no dev-only admission metadata")
		check((profile.get("collaboration_slots", []) as Array).size() == 4, side + " retains four authored sockets")
		check((profile.get("occupied", []) as Array).size() == 10, side + " retains ten exact collision cells")
		var specs := GEOMETRY.cluster_specs(side, ART_ROOT)
		check_shared_chair_registration(side, specs)
		var layers: Array = profile.get("render_layers", [])
		check(layers.size() == specs.size(), side + " production profile retains every reviewed v2 layer")
		for index: int in range(mini(layers.size(), specs.size())):
			var layer := layers[index] as Dictionary
			var expected := specs[index] as Dictionary
			check(str(layer.get("name", "")) == str(expected.name) and str(layer.get("art", "")) == str(expected.art), side + " layer path/order is exact: " + str(expected.name))
			check(OfficeLayout.rectangle(layer.region) == OfficeLayout.rectangle(expected.region) and OfficeLayout.vector(layer.offset) == OfficeLayout.vector(expected.offset) and int(layer.z_offset) == int(expected.z_offset), side + " layer region/registration/depth matches shared source: " + str(expected.name))
			check(not layer.has("rotation") and not layer.has("scale") and not layer.has("flip_h") and not layer.has("flip_v"), side + " layer has no finished-bitmap transform: " + str(expected.name))
		result[side] = {"layers": layers.size(), "slots": (profile.collaboration_slots as Array).size(), "occupied": (profile.occupied as Array).size()}
	return result

func check_shared_chair_registration(side: String, specs: Array[Dictionary]) -> void:
	var legacy_layers := GEOMETRY.cluster_layers(side)
	var count := 0
	for spec: Dictionary in specs:
		if str(spec.name).begins_with("Table"): continue
		count += 1
		check(str(spec.art).begins_with("res://assets/runtime/office/workstations-v2/chair-"), side + " reuses the workstation chair module")
		check(spec.region == [0, 0, 96, 160], side + " retains native chair canvas")
		var source := Image.load_from_file(ProjectSettings.globalize_path(spec.art))
		var direct := Image.create(GEOMETRY.CANVAS.x, GEOMETRY.CANVAS.y, false, Image.FORMAT_RGBA8)
		var offset := Vector2i(int(spec.offset[0]), int(spec.offset[1]))
		direct.blend_rect(source, Rect2i(Vector2i.ZERO, GEOMETRY.CHAIR_CANVAS), GEOMETRY.PIVOT + offset - GEOMETRY.CHAIR_CANVAS / 2)
		var legacy := legacy_layers[str(spec.name)] as Image
		check(direct.get_data() == legacy.get_data(), side + " shared module matches registered composite pixel-for-pixel: " + str(spec.name))
		var shifted := Image.create(GEOMETRY.CANVAS.x, GEOMETRY.CANVAS.y, false, Image.FORMAT_RGBA8)
		shifted.blend_rect(source, Rect2i(Vector2i.ZERO, GEOMETRY.CHAIR_CANVAS), GEOMETRY.PIVOT + offset - GEOMETRY.CHAIR_CANVAS / 2 + Vector2i(1, 0))
		check(shifted.get_data() != legacy.get_data(), side + " negative control detects one-pixel registration drift")
	check(count == (4 if side in ["north", "south"] else 8), side + " uses every chair part")

func stage_contract(side: String, pivot: Vector2i) -> Dictionary:
	var proposed := {"collaboration-cluster": {"grid": cell_values(pivot), "facing": side}}
	var stages: Dictionary = {}
	for stage: int in range(5):
		var placements := main.room.layout_model.resolve_placements(stage, proposed)
		var validation := main.room.layout_model.validate_placements(placements)
		check(bool(validation.get("valid", false)), side + " production placement validates at stage %d: %s" % [stage, str(validation.get("errors", []))])
		var clusters: Array[Dictionary] = []
		for placement: Dictionary in placements:
			if str(placement.get("id", "")) == "collaboration-cluster": clusters.append(placement)
		check(clusters.size() == (0 if stage == 0 else 1), side + " has the exact stage-%d collaboration presence" % stage)
		if not clusters.is_empty():
			check(str(clusters[0].get("facing", "")) == side and str((clusters[0].profile as Dictionary).get("asset_revision", "")) == "collaboration-cluster-v2", side + " stage-%d resolves the production v2 facing" % stage)
		stages[str(stage)] = {"valid": bool(validation.get("valid", false)), "cluster_count": clusters.size()}
	return stages

func reset_actors() -> Dictionary[String, Vector2]:
	var navigation := main.room.navigation
	navigation.actors.clear()
	navigation.reservations.clear()
	main.player.set_physics_process(false)
	main.player.cancel_route()
	main.player.hide()
	main.player.position = navigation.safe_position(main.room.grid_to_world_position(main.room.player_spawn), "founder")
	navigation.actors["founder"] = main.player.position
	# The current production placeholder roster also includes Creative. Keep
	# this two-person motion probe bounded without changing roster/socket order.
	for actor_id: String in main._employees:
		if actor_id in ACTOR_IDS: continue
		main.get_employee(actor_id).set_physics_process(false)
		main.get_employee(actor_id).hide()
	var starts: Dictionary[String, Vector2] = {}
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		actor.show()
		actor.set_physics_process(true)
		actor.world_paused = false
		actor.labels_suppressed = true
		actor._label_layer.hide()
		actor._effect_sprite.hide()
		actor.has_live_job = false
		actor.schedule_phase = "work"
		actor.work_state = EmployeeAvatar.WorkState.IDLE
		actor._has_target = false
		actor._waiting_for_desk = false
		actor._route_requires_desk = false
		actor._route.clear()
		actor._collaboration_handoff_active = false
		actor._collaboration_seat_rest = false
		actor._terminal_seat_rest = false
		actor._seat_handoff_active = false
		actor._seat_transition_active = false
		actor._seat_visual_offset = Vector2.ZERO
		actor._seat_visual_depth_bias = 0.0
		actor.position = navigation.safe_position(main.room.employee_spawn_position(actor_id), actor_id)
		navigation.actors[actor_id] = actor.position
		navigation.reservations[actor_id] = navigation.cell_at(actor.position)
		actor._update_character_frame()
		starts[actor_id] = actor.position
	return starts

func verify_live_geometry(side: String, placement: Dictionary, prop: Node2D) -> Array[String]:
	check(str(placement.get("facing", "")) == side and str((placement.profile as Dictionary).get("asset_revision", "")) == "collaboration-cluster-v2", side + " live GameMain prop is the production v2 facing")
	check(str(placement.get("profile_kind", "")) == "collaboration", side + " live prop retains collaboration semantics")
	check((placement.collaboration_slots as Array).size() == 4, side + " live prop resolves four world-space sockets")
	var signature := collision_signature(prop)
	check(signature.size() == 10, side + " live prop owns ten collision shapes")
	var collision_cells: Array[Vector2i] = []
	for collision: CollisionShape2D in collision_shapes(prop):
		var rectangle := collision.shape as RectangleShape2D
		check(rectangle != null and rectangle.size == Vector2(32, 32), side + " collision shape stays one native grid cell")
		collision_cells.append(main.room.navigation.cell_at(prop.global_position + collision.position))
	for cell: Vector2i in placement.occupied:
		check(collision_cells.has(cell) and not main.room.navigation.walkable(cell), side + " live collision/navigation agree at " + str(cell))
	for slot: Dictionary in placement.collaboration_slots:
		check(main.room.navigation.walkable(slot.cell) and not (placement.occupied as Array).has(slot.cell), side + " collaboration socket remains clear/walkable at " + str(slot.cell))
	for layer: Dictionary in placement.render_layers:
		var sprite := prop.get_node_or_null(NodePath(str(layer.name))) as Sprite2D
		var expected_canvas := GEOMETRY.CANVAS if str(layer.name).begins_with("Table") else GEOMETRY.CHAIR_CANVAS
		check(sprite != null and sprite.texture != null and sprite.texture.get_size() == Vector2(expected_canvas), side + " live layer loads its native module canvas: " + str(layer.name))
		if sprite != null:
			check(sprite.scale == Vector2.ONE and is_zero_approx(sprite.rotation) and not sprite.flip_h and not sprite.flip_v, side + " live layer stays untransformed: " + str(layer.name))
	return signature

func route_to_lunch(side: String, placement: Dictionary, collision_before: Array[String]) -> Dictionary:
	var navigation := main.room.navigation
	var targets: Dictionary[String, Vector2] = {}
	var roster: Array = main.room._employee_names.keys()
	roster.sort()
	for index: int in range(ACTOR_IDS.size()):
		var actor_id := ACTOR_IDS[index]
		var slot := placement.collaboration_slots[roster.find(actor_id)] as Dictionary
		targets[actor_id] = main.room.lunch_position(actor_id)
		check(targets[actor_id] == main.room.grid_to_world_position(slot.cell), side + " " + actor_id + " resolves its deterministic production socket")
	for actor_id: String in ACTOR_IDS: navigation.release(actor_id)
	begin_motion_probe(side + " lunch entry", targets)
	for actor_id: String in ACTOR_IDS: main.get_employee(actor_id).set_schedule_phase("lunch")
	check(navigation.reservations.get("mira") != navigation.reservations.get("theo"), side + " concurrent lunch routes reserve distinct destinations")
	var rolling := {"mira": [], "theo": []}
	var sequences := {"mira": [], "theo": []}
	var arrival_seen := {"mira": false, "theo": false}
	var frame_count := 0
	while frame_count < MAX_ROUTE_FRAMES:
		await physics_frame
		frame_count += 1
		var needs_capture := false
		for actor_id: String in ACTOR_IDS:
			if main.get_employee(actor_id).position.distance_to(targets[actor_id]) < 42.0: needs_capture = true
		var picture := await viewport_image() if needs_capture and DisplayServer.get_name() != "headless" else Image.new()
		var all_arrived := true
		for actor_id: String in ACTOR_IDS:
			var actor := main.get_employee(actor_id)
			if not picture.is_empty() and actor.position.distance_to(targets[actor_id]) < 42.0:
				append_limited(rolling[actor_id], actor_crop(picture, targets[actor_id]), 4)
			if not actor._has_target and actor.position.distance_to(targets[actor_id]) <= 0.5 and not bool(arrival_seen[actor_id]):
				arrival_seen[actor_id] = true
				sequences[actor_id] = (rolling[actor_id] as Array).duplicate()
			if actor._has_target or actor.position.distance_to(targets[actor_id]) > 0.5: all_arrived = false
		if all_arrived: break
	check(frame_count < MAX_ROUTE_FRAMES, side + " both employees reach lunch through ordinary production navigation")
	for _settle: int in range(SETTLE_FRAMES):
		await physics_frame
		var picture := await viewport_image() if DisplayServer.get_name() != "headless" else Image.new()
		for actor_id: String in ACTOR_IDS:
			if not picture.is_empty(): append_limited(sequences[actor_id], actor_crop(picture, targets[actor_id]), 8)
	var probe := end_motion_probe()
	var max_visual_step := probe.max_visual_step as Dictionary
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		var visual := main.room.collaboration_visual(actor_id)
		check(bool(arrival_seen[actor_id]) and not actor._has_target and actor.position == targets[actor_id], side + " " + actor_id + " reaches the exact physical socket")
		check(actor.schedule_phase == "lunch" and actor.work_state == EmployeeAvatar.WorkState.LUNCH and actor._uses_collaboration_visual(), side + " " + actor_id + " holds the reviewed seated lunch presentation")
		check(actor.seated_render_offset() == Vector2(visual.seat_anchor) and not actor._seat_transition_active, side + " " + actor_id + " reaches its exact seat anchor after the 140ms settle window")
		check(float(max_visual_step[actor_id]) <= MAX_VISUAL_STEP_PX, side + " " + actor_id + " entry has no one-frame visual jump (max %.2fpx)" % float(max_visual_step[actor_id]))
		check((actor._active_work_pose_layers as Array).size() == 2 and not actor._character_sprite.visible, side + " " + actor_id + " seated endpoint uses exact split reviewed art")
		entry_sequences[side + "/" + actor_id] = sequences[actor_id]
	check(int(probe.unsafe_samples) == 0 and int(probe.reservation_conflicts) == 0, side + " lunch approach has zero unsafe samples and reservation conflicts")
	check(collision_signature(main.room.prop_node("collaboration-cluster")) == collision_before, side + " lunch approach leaves collision byte-exact")
	return {"targets": targets, "frames": frame_count, "motion_probe": probe}

func hold_and_reject_rotation(side: String, placement: Dictionary, collision_before: Array[String], targets: Dictionary) -> Dictionary:
	var positions := {}
	var render_positions := {}
	var depths := {}
	var reservations := main.room.navigation.reservations.duplicate(true)
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		positions[actor_id] = actor.position
		render_positions[actor_id] = actor.render_position()
		depths[actor_id] = actor.z_index
	for _frame: int in range(24): await physics_frame
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		check(actor.position == positions[actor_id] and actor.render_position() == render_positions[actor_id] and actor.z_index == int(depths[actor_id]), side + " " + actor_id + " held lunch remains physically/visually/depth stable")
		check(main.room.navigation.reservations.get(actor_id) == main.room.navigation.cell_at(targets[actor_id]), side + " " + actor_id + " holds its socket reservation")
	check(main.room.navigation.reservations == reservations and collision_signature(main.room.prop_node("collaboration-cluster")) == collision_before, side + " held lunch changes neither reservations nor collision")
	var hold_picture := await viewport_image()
	if not hold_picture.is_empty():
		full_holds[side] = hold_picture
		hold_details[side] = placement_crop(hold_picture, placement)
	var before_overrides := main.room.placement_overrides.duplicate(true)
	preload("res://tests/renovation_transport_fixture.gd").bind_layout_only(main)
	main.office_renovation.open()
	await frames(2)
	main._process(0.0)
	main.office_renovation.select_placement("collaboration-cluster")
	main.office_renovation.rotate_preview()
	var rejection := main.office_renovation.preview_result
	check(main._world_paused() and ACTOR_IDS.all(func(actor_id: String) -> bool: return main.get_employee(actor_id).world_paused), side + " Renovate applies the actual GameMain pause policy")
	check(main.office_renovation.placement_active and not bool(rejection.get("valid", true)), side + " occupied collaboration rotation is rejected")
	var conflicts: Array = rejection.get("actor_conflicts", [])
	check(conflicts.any(func(value: Dictionary) -> bool: return ACTOR_IDS.has(str(value.get("actor_id", "")))), side + " occupied rotation names a live collaborator conflict")
	check(not main.office_renovation.commit_preview() and main.room.placement_overrides == before_overrides, side + " rejected occupied rotation mutates no placement")
	var rejected_picture := await viewport_image()
	if not rejected_picture.is_empty(): rotation_details[side + "-occupied"] = placement_crop(rejected_picture, placement)
	main.office_renovation.cancel_preview()
	main.office_renovation.close()
	main._process(0.0)
	await frames(2)
	check(not main._world_paused() and ACTOR_IDS.all(func(actor_id: String) -> bool: return not main.get_employee(actor_id).world_paused), side + " closing Renovate resumes the actual world")
	return {"conflicts": conflicts.size(), "status": str(main.office_renovation._status.text)}

func interrupt_for_work(side: String, collision_before: Array[String], targets: Dictionary) -> Dictionary:
	var before_positions := {}
	var before_render := {}
	var before_offsets := {}
	var before_depths := {}
	var sequences := {"mira": [], "theo": []}
	var picture := await viewport_image()
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		before_positions[actor_id] = actor.position
		before_render[actor_id] = actor.render_position()
		before_offsets[actor_id] = actor.seated_render_offset()
		before_depths[actor_id] = actor.z_index
		if not picture.is_empty(): append_limited(sequences[actor_id], actor_crop(picture, targets[actor_id]), 8)
	main.company_panel.present("settings")
	await frames(2)
	main._process(0.0)
	check(main._world_paused() and ACTOR_IDS.all(func(actor_id: String) -> bool: return main.get_employee(actor_id).world_paused), side + " settings applies actual pause before incoming work")
	begin_motion_probe(side + " lunch work interruption", targets)
	main.get_employee("theo").apply_worker_event(event(&"job.started"), main.player.position)
	main.get_employee("mira").set_schedule_phase("work")
	var immediate_jumps := {}
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		immediate_jumps[actor_id] = actor.render_position().distance_to(before_render[actor_id])
		check(actor._has_target and actor.position == before_positions[actor_id], side + " " + actor_id + " accepts a work-return route without moving during the event frame")
		check(actor.render_position() == before_render[actor_id] and actor.seated_render_offset() == before_offsets[actor_id] and actor.z_index == int(before_depths[actor_id]), side + " " + actor_id + " work interruption preserves the rendered chair contact on its event frame")
	for _paused: int in range(8): await physics_frame
	picture = await viewport_image()
	if not picture.is_empty(): pause_proofs[side] = picture
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		check(actor.position == before_positions[actor_id] and actor.render_position() == before_render[actor_id], side + " " + actor_id + " route and 140ms handoff remain frozen while paused")
	main.company_panel.hide()
	main._process(0.0)
	await frames(2)
	for exit_frame: int in range(14):
		await physics_frame
		picture = await viewport_image() if DisplayServer.get_name() != "headless" else Image.new()
		for actor_id: String in ACTOR_IDS:
			var actor := main.get_employee(actor_id)
			if not picture.is_empty() and exit_frame % 2 == 0: append_limited(sequences[actor_id], actor_crop(picture, targets[actor_id]), 8)
	var route_frames := 0
	while route_frames < MAX_ROUTE_FRAMES:
		var complete := true
		for actor_id: String in ACTOR_IDS:
			var actor := main.get_employee(actor_id)
			if actor._has_target or actor.position.distance_to(actor.desk_position) > 0.5: complete = false
		if complete: break
		await physics_frame
		route_frames += 1
	check(route_frames < MAX_ROUTE_FRAMES, side + " both work interruptions leave lunch and reach their own desks")
	# Arrival begins the ordinary workstation handoff. Sample beyond the same
	# 140ms transition used at lunch before asserting its final desk anchor.
	for _settle: int in range(SETTLE_FRAMES): await physics_frame
	var probe := end_motion_probe()
	var max_visual_step := probe.max_visual_step as Dictionary
	var split_contact_seen := probe.split_contact_seen as Dictionary
	for actor_id: String in ACTOR_IDS:
		var actor := main.get_employee(actor_id)
		check(bool(split_contact_seen[actor_id]), side + " " + actor_id + " uses split locomotion depth while clearing its own chair")
		check(float(max_visual_step[actor_id]) <= MAX_VISUAL_STEP_PX, side + " " + actor_id + " exit has no one-frame visual jump (max %.2fpx at %s)" % [float(max_visual_step[actor_id]), str((probe.max_visual_sample as Dictionary).get(actor_id, {}))])
		exit_sequences[side + "/" + actor_id] = sequences[actor_id]
		check(not actor._has_target and actor.position == actor.desk_position, side + " " + actor_id + " finishes at its exact production desk")
		check(not actor._uses_collaboration_visual() and not actor._uses_collaboration_handoff(), side + " " + actor_id + " clears all collaboration presentation after leaving")
		check(actor.seated_render_offset() == Vector2(actor._workstation_visual.seat_anchor), side + " " + actor_id + " settles into its ordinary reviewed desk anchor")
	check(int(probe.unsafe_samples) == 0 and int(probe.reservation_conflicts) == 0, side + " work-return routes have zero unsafe samples and reservation conflicts")
	check(collision_signature(main.room.prop_node("collaboration-cluster")) == collision_before, side + " work interruption leaves collaboration collision byte-exact")
	return {"immediate_visual_jump": immediate_jumps, "route_frames": route_frames, "motion_probe": probe}

func vacant_rotate_and_undo(side: String, collision_before: Array[String], placement: Dictionary) -> Dictionary:
	var before_overrides := main.room.placement_overrides.duplicate(true)
	var before_facing := str(placement.facing)
	preload("res://tests/renovation_transport_fixture.gd").bind_layout_only(main)
	main.office_renovation.open()
	await frames(2)
	main._process(0.0)
	main.office_renovation.select_placement("collaboration-cluster")
	main.office_renovation.rotate_preview()
	var rotated := main.office_renovation.preview_facing
	check(bool(main.office_renovation.preview_result.get("valid", false)), side + " vacant rotation validates across stages 0-4")
	check(rotated != before_facing and main.office_renovation.commit_preview(), side + " vacant rotation commits the next authored production facing")
	var rotated_placement := main.room.placement_by_id("collaboration-cluster")
	check(str(rotated_placement.facing) == rotated and collision_signature(main.room.prop_node("collaboration-cluster")).size() == 10, side + " committed vacant rotation rebuilds exact ten-cell collision")
	var picture := await viewport_image()
	if not picture.is_empty(): rotation_details[side + "-vacant"] = placement_crop(picture, rotated_placement)
	check(main.office_renovation._history.size() == 1, side + " successful vacant rotation creates exactly one Undo step")
	main.office_renovation.undo()
	var restored := main.room.placement_by_id("collaboration-cluster")
	check(str(restored.facing) == before_facing and main.room.placement_overrides == before_overrides, side + " Undo restores the exact prior facing/override")
	check(collision_signature(main.room.prop_node("collaboration-cluster")) == collision_before, side + " Undo restores the exact prior collision signature")
	main.office_renovation.close()
	main._process(0.0)
	await frames(2)
	return {"from": before_facing, "to": rotated, "undo_restored": str(restored.facing)}

func run_side(side: String, pivot: Vector2i) -> void:
	print("Collaboration production: %s contract/placement" % side)
	var stages := stage_contract(side, pivot)
	check(main.room.set_placement_overrides({"collaboration-cluster": {"grid": cell_values(pivot), "facing": side}}), side + " commits through ordinary production placement overrides")
	await frames(3)
	var placement := main.room.placement_by_id("collaboration-cluster")
	var prop := main.room.prop_node("collaboration-cluster")
	check(not placement.is_empty() and prop != null, side + " ordinary GameMain builds the collaboration prop")
	if placement.is_empty() or prop == null: return
	var collision_before := verify_live_geometry(side, placement, prop)
	reset_actors()
	print("Collaboration production: %s two-actor lunch entry" % side)
	var approach := await route_to_lunch(side, placement, collision_before)
	print("Collaboration production: %s hold/occupied rotation" % side)
	var hold := await hold_and_reject_rotation(side, placement, collision_before, approach.targets)
	print("Collaboration production: %s paused work interruption/return" % side)
	var departure := await interrupt_for_work(side, collision_before, approach.targets)
	# Clear Theo's synthetic job without allowing the lunch schedule to reassert.
	main.get_employee("theo").schedule_phase = "work"
	main.get_employee("theo").apply_worker_event(event(&"job.failed"), main.player.position)
	main.get_employee("mira").set_schedule_phase("work")
	await frames(SETTLE_FRAMES)
	print("Collaboration production: %s vacant rotation/Undo" % side)
	var editor := await vacant_rotate_and_undo(side, collision_before, main.room.placement_by_id("collaboration-cluster"))
	observations[side] = {"stages": stages, "approach": approach, "hold_and_occupied_rotation": hold, "work_interruption": departure, "vacant_rotation": editor}

func save_report() -> void:
	var renderer := DisplayServer.get_name()
	var path := OUTPUT.path_join("results-headless.json" if renderer == "headless" else "actual-room-results.json")
	var report := {
		"status": "production_acceptance_passed" if failures.is_empty() else "production_acceptance_failed",
		"scene": "ordinary GameMain/TownRoom loaded directly from production furniture_catalog.json and office_layout.json; no injected catalogue or calibration owner",
		"renderer": renderer,
		"worker_disabled": true,
		"save_access": false,
		"catalogue_injected": false,
		"runtime_revision": "collaboration-cluster-v2",
		"default_grid": [12, 14],
		"native_viewport": [1280, 720],
		"entry_exit_settle_ms": 140,
		"observations": observations,
		"captures": captures,
		"checks": checks,
		"failures": failures,
		"production_catalog_sha256": catalog_hash_before,
		"default_layout_sha256": layout_hash_before,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "Opened collaboration production result manifest")
	report.checks = checks
	report.failures = failures
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.close()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	catalog_hash_before = FileAccess.get_sha256(PRODUCTION_CATALOG)
	layout_hash_before = FileAccess.get_sha256(DEFAULT_LAYOUT)
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)
		root.unfocusable = true
		root.mouse_passthrough = true
	main = MAIN_SCENE.instantiate() as GameMain
	root.add_child(main)
	await frames(6)
	physics_frame.connect(sample_motion_frame)
	starting_overrides = main.room.placement_overrides.duplicate(true)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.job_panel.close_drawer(false)
	main.company_panel.hide()
	main.founder_hud.dismiss_movement_hint()
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Ordinary GameMain starts with the worker disabled")
	observations["production_contract"] = production_contract()
	var default_cluster := main.room.placement_by_id("collaboration-cluster")
	var pivot := default_cluster.grid as Vector2i if not default_cluster.is_empty() else Vector2i(12, 14)
	for side: String in GEOMETRY.SIDES: await run_side(side, pivot)
	if DisplayServer.get_name() != "headless":
		build_motion_sheet(entry_sequences, "entry-keyframes-native.png")
		build_motion_sheet(exit_sequences, "work-interrupt-keyframes-native.png")
		build_four_facing_sheet(hold_details, "hold-contact-sheet-native.png")
		build_four_facing_sheet(full_holds, "full-room-hold-native-panels.png")
		build_four_facing_sheet(pause_proofs, "pause-resume-contact-sheet-native.png")
		build_rotation_sheet()
	check(main.room.set_placement_overrides(starting_overrides), "Production test restores the ordinary worker-disabled bootstrap placement")
	check(FileAccess.get_sha256(PRODUCTION_CATALOG) == catalog_hash_before, "Production test leaves furniture_catalog.json byte-exact")
	check(FileAccess.get_sha256(DEFAULT_LAYOUT) == layout_hash_before, "Production test leaves office_layout.json byte-exact")
	await save_report()
	if physics_frame.is_connected(sample_motion_frame): physics_frame.disconnect(sample_motion_frame)
	main.game_audio.shutdown()
	main.free()
	print("Collaboration production: %d checks, %d failures (%s)" % [checks, failures.size(), DisplayServer.get_name()])
	quit(0 if failures.is_empty() else 1)
