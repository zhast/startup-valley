extends SceneTree
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const OUTPUT := "res://tests/output/calibrated-workstation/actor-safe-editor"
var fixture: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var sampled_frames: Array[Dictionary] = []
var motion_paths: Array[Dictionary] = []
var contact_sheets: Array[String] = []
var motion_frames := 0
var record_motion := false
var all_direction_checks_completed := false
var registry_checks_completed := false
var actor_conflict_checks_completed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for tick: int in range(count): await process_frame

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await frames()

func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
	await frames()

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(3)
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Actual GameMain capture remains native1280×720")
	check(image.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save canonical scene " + name_value)
	if name_value == "occupied-rotation-rejected":
		var before := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join("single-south-seated.png")))
		for point: Vector2i in [Vector2i(244, 116), Vector2i(250, 124), Vector2i(425, 116), Vector2i(425, 328)]:
			check(image.get_pixelv(point) == before.get_pixelv(point), "Rendered preview preserves transparent canvas padding instead of a solid tinted fallback quad")
		check(fixture.editor._preview_texture_cache.size() >= 7, "Drawn preview resources remain strongly held after the draw callback returns")
	captures.append(name_value + ".png")
	sampled_frames.append({"scenario": name_value, "path": name_value + ".png", "motion_tick": motion_frames})

func advance_actor(actor: EmployeeAvatar, ticks := 600) -> void:
	var path_number := motion_paths.size()
	var path_evidence := {"employee": actor.employee_id, "facing": str(actor._workstation_visual.get("work_facing", "south")), "start_tick": motion_frames, "samples": [], "transition_samples": []}
	var path_distance := 0.0
	var waypoint := actor.position
	for point: Vector2 in actor._route:
		path_distance += waypoint.distance_to(point)
		waypoint = point
	var middle_tick := maxi(1, int(path_distance / actor.walk_speed * 15.0))
	for tick: int in range(ticks):
		actor._physics_process(1.0 / 30.0)
		check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Actor physical feet never enter a blocked cell")
		if actor._has_target:
			check(actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "Movement never leaves duplicate seated body layers visible")
		elif actor._uses_seated_visual() and actor._workstation_visual.work_facing != "north":
			check(actor._active_work_pose_layers.size() == 2 and not actor._character_sprite.visible, "Every seating transition frame has exactly one source-owned upper/lower body")
			for part: Dictionary in actor._active_work_pose_layers:
				var sprite: Sprite2D = actor._work_pose_layer_sprites[str(part.name)]
				check(sprite.position == sprite.position.round(), "Intermediate source layers stay integer-snapped")
		if actor._uses_seated_visual():
			check(actor.z_index == roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_z_offset), "Every seated transition frame locks declared pose depth without crossing chair/table layers")
		else:
			check(actor.z_index == int(actor.position.y), "Walking restores physical-foot sorting at the pose boundary")
		if record_motion:
			motion_frames += 1
			await process_frame
			if tick == 0 or tick == middle_tick:
				path_evidence.samples.append(save_motion_sample(actor, path_number, "start" if tick == 0 else "middle"))
			if actor._seat_transition_active:
				path_evidence.transition_samples.append(save_motion_sample(actor, path_number, "transition-%02d" % path_evidence.transition_samples.size()))
		if not actor._has_target and not actor._waiting_for_desk and not actor._seat_transition_active: break
	if record_motion:
		path_evidence.samples.append(save_motion_sample(actor, path_number, "end"))
		path_evidence["end_tick"] = motion_frames
		check(path_evidence.samples.size() == 3, "Motion path contains actual start, middle, end rendered markers")
		if path_evidence.samples.size() == 3:
			check(path_evidence.samples[0].sha256 != path_evidence.samples[1].sha256 and path_evidence.samples[1].sha256 != path_evidence.samples[2].sha256, "Actual walk/sit frames have distinct rendered pixels")
		motion_paths.append(path_evidence)
		build_transition_contact(actor, path_number, path_evidence)

func build_transition_contact(actor: EmployeeAvatar, path_number: int, path_evidence: Dictionary) -> void:
	var samples: Array = path_evidence.transition_samples.duplicate()
	samples.append(path_evidence.samples[-1])
	var anchor := Vector2i(actor._workstation_visual.prop_anchor)
	var crop := Rect2i(anchor - Vector2i(80, 112), Vector2i(160, 176))
	var contact := Image.create(samples.size() * 160, 176, false, Image.FORMAT_RGBA8)
	for index: int in range(samples.size()):
		var image := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join(samples[index].path)))
		contact.blit_rect(image, crop, Vector2i(index * 160, 0))
	var path := "transition-%02d-native.png" % path_number
	check(contact.save_png(OUTPUT.path_join(path)) == OK, "Save every sampled transition stage plus settled endpoint at native pixels")
	path_evidence["transition_contact"] = path
	path_evidence["transition_crop"] = [crop.position.x, crop.position.y, crop.size.x, crop.size.y]

func save_motion_sample(actor: EmployeeAvatar, path_number: int, marker: String) -> Dictionary:
	RenderingServer.force_draw(false)
	var pixels := root.get_texture().get_image()
	var path := "motion-%02d-%s.png" % [path_number, marker]
	check(pixels.save_png(OUTPUT.path_join(path)) == OK, "Save real motion marker " + path)
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(pixels.get_data())
	return {"path": path, "tick": motion_frames, "engine_frame": Engine.get_process_frames(), "position": [actor.position.x, actor.position.y], "render_offset": [actor.seated_render_offset().x, actor.seated_render_offset().y], "work_state": actor.work_state, "sha256": hash_context.finish().hex_encode()}

func build_native_contacts() -> void:
	if DisplayServer.get_name() == "headless": return
	for facing: String in OfficeLayout.FACINGS:
		var contact := Image.create(960, 416, false, Image.FORMAT_RGBA8)
		for frame: int in range(6):
			var source := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT.path_join("two-%s-frame-%d.png" % [facing, frame])))
			var target := Vector2i((frame % 3) * 320, int(frame / 3) * 208)
			contact.blit_rect(source, Rect2i(256, 128, 160, 208), target)
			contact.blit_rect(source, Rect2i(704, 128, 160, 208), target + Vector2i(160, 0))
		var name_value := "contact-%s-native.png" % facing
		check(contact.save_png(OUTPUT.path_join(name_value)) == OK, "Save all-six-frame native crop evidence without resampling")
		contact_sheets.append(name_value)

func verify_registry_rejection(owner: Node) -> void:
	var valid: Dictionary = owner.pose_registry()
	var stranger := Node.new()
	check(not CharacterArt.unregister_calibration_pose_set(owner.pose_set_id, stranger), "Another scene cannot unregister this fixture's textures")
	var foreign_model := OfficeLayout.new()
	foreign_model.enable_calibration_preview(stranger)
	foreign_model.configure(owner.model.data, owner.model.catalog)
	check(foreign_model.available_facings("desk").is_empty(), "An independent scene cannot borrow another owner's calibration admission")
	stranger.free()
	for field: String in ["frames", "row", "column"]:
		for invalid: Variant in [null, "0", 1.5, INF]:
			var malformed := valid.duplicate(true)
			malformed.facings.south.seated[field] = invalid
			check(not CharacterArt.register_calibration_pose_set("dev-calibration-invalid", malformed, owner), "Registry rejects non-native " + field)
	for invalid: Variant in [[0, 50], [80, 50], [50], [50.5, 50], "50"]:
		var malformed := valid.duplicate(true)
		malformed.facings.south.seated.cuts_by_character.mira = invalid
		check(not CharacterArt.register_calibration_pose_set("dev-calibration-invalid", malformed, owner), "Registry rejects invalid per-frame cut ownership")
	check(not CharacterArt.register_calibration_pose_set(CharacterArt.LEGACY_WORK_POSE_SET, valid, owner), "Calibration cannot replace the immutable legacy registry")
	check(not CharacterArt.register_calibration_pose_set(owner.pose_set_id, valid, owner), "Duplicate registry identity is rejected")
	for field: String in ["seat_anchor_by_employee", "seat_layer_z_offsets", "calibration_limitations"]:
		var original: Variant = owner.model.catalog.desk.facing_profiles.south[field]
		owner.model.catalog.desk.facing_profiles.south[field] = "invalid"
		check(not owner.model.validate_candidate("mira-workstation", Vector2i(10, 8), "south", 1).valid, "Malformed " + field + " fails without crashing a placement")
		owner.model.catalog.desk.facing_profiles.south[field] = original
	for invalid: Variant in ["true", 1, null]:
		owner.model.catalog.desk.facing_profiles.south.seat_pose_depth_lock = invalid
		check(not owner.model.validate_candidate("mira-workstation", Vector2i(10, 8), "south", 1).valid, "Depth lock requires an explicit boolean")
	owner.model.catalog.desk.facing_profiles.south.seat_pose_depth_lock = true
	var invalid_actor: Dictionary = owner.main.get_employee("mira")._workstation_visual.duplicate(true)
	invalid_actor.seat_pose_depth_lock = "true"
	check(not owner.main.get_employee("mira").configure_workstation_visual(invalid_actor), "Actor rejects untyped depth lock without changing current visuals")
	invalid_actor.seat_pose_depth_lock = true
	invalid_actor.pose_set = CharacterArt.LEGACY_WORK_POSE_SET
	check(not owner.main.get_employee("mira").configure_workstation_visual(invalid_actor), "Depth lock cannot silently activate on ordinary legacy poses")
	registry_checks_completed = true

func verify_interrupted_depth(main: GameMain, actor: EmployeeAvatar) -> void:
	actor.has_live_job = true # Prevent unrelated idle wandering in this bounded pose diagnostic.
	actor.walk_to(actor.home_position, EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
	actor._physics_process(1.0 / 30.0)
	check(actor._has_target and actor._active_work_pose_layers.is_empty(), "Interrupted leave removes seated layers immediately")
	check(actor.z_index == int(actor.position.y), "Interrupted leave restores physical-foot depth immediately")
	await capture("interrupted-leave")
	actor.walk_to(actor.desk_position, EmployeeAvatar.WorkState.WALKING_TO_DESK, EmployeeAvatar.WorkState.SITTING)
	for tick: int in range(60):
		actor._physics_process(1.0 / 30.0)
		if actor._uses_seated_visual(): break
	check(actor._uses_seated_visual() and actor._seat_transition_active, "Immediate return re-enters the real seat tween from its current visible offset")
	actor._physics_process(1.0 / 30.0)
	main.set_process(false)
	actor.world_paused = true
	var paused_offset := actor.seated_render_offset()
	var paused_depth := actor.z_index
	for tick: int in range(6): actor._physics_process(1.0 / 30.0)
	check(actor.seated_render_offset() == paused_offset and actor.z_index == paused_depth, "Pause freezes intermediate XY without changing discrete pose depth")
	check(actor.z_index == roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_z_offset), "Paused body retains the declared seated layer order")
	await capture("paused-mid-seat")
	actor.world_paused = false
	main.set_process(true)
	for tick: int in range(6): actor._physics_process(1.0 / 30.0)
	check(not actor._seat_transition_active, "Resumed seat transition settles without a restart or depth tween")
	actor.work_state = EmployeeAvatar.WorkState.WORKING
	actor._activity = &"thinking"
	actor._update_character_frame()
	check(actor._active_work_pose_layers.size() == 2 and not actor._character_sprite.visible, "Explicit quiet thinking reuse keeps source-owned seated layers")
	check(actor.z_index == roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_z_offset), "Quiet seated thinking retains supported pose depth")
	check(actor._character_sprite.texture == CharacterArt.seated_sheet(actor.employee_id), "Quiet thinking reuses the actual South seated-idle source, not typing or invented art")
	await capture("thinking-seated-reuse")
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	actor._update_character_frame()
	for tick: int in range(6): actor._physics_process(1.0 / 30.0)
	actor.has_live_job = false
	check(actor.position == actor.desk_position and actor.seated_render_offset() == Vector2(0, 12), "Leave/return/pause/quiet-thinking cycle preserves the canonical physical seat and supported South endpoint")
	await capture("interrupted-return-settled")

func verify_source_layers(actor: EmployeeAvatar, facing: String, source_frame: int) -> void:
	var pose := "seated" if source_frame < 2 else "typing"
	var phase := source_frame if source_frame < 2 else source_frame - 2
	actor.work_state = EmployeeAvatar.WorkState.SITTING if source_frame < 2 else EmployeeAvatar.WorkState.TYPING
	actor._animation_elapsed = (float(phase) + 0.01) / (1.5 if source_frame < 2 else 8.0)
	actor._blink_elapsed = (3.2 if actor.employee_id == "mira" else 2.45) if source_frame == 1 else 0
	actor._update_character_frame()
	var authored := CharacterArt.work_pose_frame(actor.employee_id, actor._workstation_visual.pose_set, facing, pose, phase)
	var atlas: Image = authored.texture.get_image()
	var source := atlas.get_region(Rect2i(authored.region))
	check(actor._character_sprite.region_rect == authored.region, "Actual live pose resolves exact source frame " + facing)
	check(actor._character_sprite.scale == Vector2.ONE and not actor._character_sprite.flip_h and not actor._character_sprite.flip_v, "No actor scaling or raster mirroring")
	if facing == "north":
		check(actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "North retains its whole source body behind the whole chair")
		return
	var reconstructed := Image.create(48, 80, false, Image.FORMAT_RGBA8)
	var covered := Rect2i()
	for part: Dictionary in authored.layers:
		var layer: Sprite2D = actor._work_pose_layer_sprites[str(part.name)]
		var rect := Rect2i(part.region)
		var destination := Vector2i(part.offset)
		reconstructed.blit_rect(atlas, rect, destination)
		check(layer.visible and layer.region_rect == part.region and layer.texture == authored.texture, "Actual source layer texture/region is retained")
		check(not layer.centered and layer.scale == Vector2.ONE and layer.rotation == 0 and layer.position == layer.position.round(), "Split layers retain integer top-left origins with no transform distortion")
		var body_region := Rect2i(destination, rect.size)
		check(not covered.has_area() or not covered.intersects(body_region), "Upper/lower source ownership never overlaps")
		covered = covered.merge(body_region) if covered.has_area() else body_region
	check(covered == Rect2i(0, 0, 48, 80) and reconstructed.get_data() == source.get_data(), "Every live upper/lower frame recombines byte-identically")
	if facing == "west" and actor.employee_id == "theo":
		var expected := 47 if source_frame in [2, 3, 4] else 48
		check(int(authored.layers[0].region.size.y) == expected, "Registered Theo preserves translated ownership instead of reintroducing a lap stripe")

func verify_two_employee_facings() -> void:
	var both := FIXTURE.new()
	both.employee_ids.assign(["mira", "theo"])
	both.initial_facing = "north"
	root.add_child(both)
	await frames()
	check(both.ready_ok, "Independent two-employee candidate room validates")
	if not both.ready_ok:
		both.free()
		return
	var main: GameMain = both.main
	main.player.set_physics_process(false)
	for actor: EmployeeAvatar in main._employees.values(): actor.set_physics_process(false)
	for facing: String in OfficeLayout.FACINGS:
		for id: String in ["mira", "theo"]:
			var actor := main.get_employee(id)
			both.editor.select_placement(id + "-workstation")
			if str(main.room.placement_by_id(id + "-workstation").facing) != facing:
				await click(both.editor.action_buttons["Leave"].get_global_rect().get_center())
				await advance_actor(actor)
				await key(KEY_R)
				check(both.editor.placement_active and both.editor.preview_facing == facing, "Real R selects next authored facing for " + id)
				await click(both.model.world(main.room.placement_by_id(id + "-workstation").grid))
				check(not both.editor.placement_active, "Real click commits canonical two-desk rotation")
			await click(both.editor.action_buttons["Sit"].get_global_rect().get_center())
			await advance_actor(actor)
			check(actor.position == actor.desk_position and actor.work_state == EmployeeAvatar.WorkState.SITTING, "Real employee path arrives in " + facing)
			check(actor.seated_render_offset() == Vector2(OfficeLayout.vector(both.profile(facing).seat_anchor_by_employee[id])), "Actual owner-specific visual socket forwards through TownRoom")
			check(actor.navigation.reservations.get(id) == actor.navigation.cell_at(actor.desk_position), "Physical work cell stays reserved, not rendered socket")
			check(not main.room.interaction_at(main.room.placement_by_id(id + "-workstation").world_hit_bounds.get_center()).is_empty(), "Canonical generated art owns a real prop click target")
		check(main.get_employee("mira").navigation.reservations.mira != main.get_employee("theo").navigation.reservations.theo, "Two employees never finish on the same reservation")
		for source_frame: int in range(6):
			for actor: EmployeeAvatar in main._employees.values(): verify_source_layers(actor, facing, source_frame)
			await capture("two-%s-frame-%d" % [facing, source_frame])
		# First frame after the last uses the same explicit source ownership.
		for actor: EmployeeAvatar in main._employees.values(): verify_source_layers(actor, facing, 0)
		await capture("two-%s-loop-return" % facing)
		# Invalid world placement must keep the old room, routes, and authored view.
		var before := main.room.placement_overrides.duplicate(true)
		await key(KEY_M)
		await click(both.model.world(Vector2i(0, 3)))
		check(both.editor.placement_active and not both.editor.preview_result.valid, "Wall placement remains visibly rejected")
		check(main.room.placement_overrides == before, "Rejected placement does not mutate committed room")
		await key(KEY_ESCAPE)
		check(not both.editor.placement_active and main.room.prop_node("theo-workstation").visible, "Escape restores original prop visibility and ends preview")
	both.free()
	await frames()
	all_direction_checks_completed = true

func verify_actor_conflicts() -> void:
	var scene := FIXTURE.new()
	scene.employee_ids.assign(["mira", "theo"])
	scene.initial_facing = "north"
	root.add_child(scene)
	await frames()
	check(scene.ready_ok, "Actor-conflict fixture validates independently")
	if not scene.ready_ok:
		scene.free()
		return
	var main: GameMain = scene.main
	var model: OfficeLayout = scene.model
	var editor: Node2D = scene.editor
	var navigation := main.room.navigation
	main.player.set_physics_process(false)
	for employee: EmployeeAvatar in main._employees.values(): employee.set_physics_process(false)
	var mina := main.get_employee("mira")
	var theo := main.get_employee("theo")
	var founder_start := main.player.position
	var theo_start := theo.position
	var proposed := main.room.placement_overrides.duplicate(true)
	proposed["mira-workstation"] = {"grid": [10, 8], "facing": "east"}
	var blocked := navigation.world(Vector2i(10, 9))
	# Explicit worker-disabled placement fixtures; the tested actions below are
	# real R, mouse commit, Leave and U events, not calls to their handlers.
	main.player.position = blocked
	navigation.actors["founder"] = blocked
	var old_revision := navigation.revision
	var old_actors := navigation.actors.duplicate(true)
	var old_reservations := navigation.reservations.duplicate(true)
	var conflicts := main.room.placement_actor_conflicts(proposed)
	check(conflicts.size() == 1 and conflicts[0].actor_id == "founder", "Read-only query detects founder physical obstruction")
	check(navigation.revision == old_revision and navigation.actors == old_actors and navigation.reservations == old_reservations, "Actor-conflict query does not mutate navigation, actors or reservations")
	await key(KEY_R)
	await click(model.world(Vector2i(10, 8)))
	check(editor.placement_active and "Move Founder clear" in editor._status.text, "Actual founder-blocked commit is rejected with useful status")
	check(main.player.position == blocked and editor._history.is_empty() and main.room.placement_by_id("mira-workstation").facing == "north", "Founder rejection keeps position, facing, candidate and undo history")
	await capture("founder-placement-blocked")
	await key(KEY_ESCAPE)
	check(editor.preview_facing == "north" and editor._facing_picker.get_item_text(editor._facing_picker.selected) == "north", "Cancel restores the committed direction selector")
	main.player.position = founder_start
	navigation.actors["founder"] = founder_start
	theo.position = blocked
	navigation.actors["theo"] = blocked
	theo._update_character_frame()
	await key(KEY_R)
	await click(model.world(Vector2i(10, 8)))
	check(editor.placement_active and "Move Theo clear" in editor._status.text, "Another employee blocks the actual commit without being moved")
	check(theo.position == blocked and editor._history.is_empty(), "Other employee rejection preserves physical feet and history")
	await capture("teammate-placement-blocked")
	await key(KEY_ESCAPE)
	theo.position = theo_start
	navigation.actors["theo"] = theo_start
	# Feet may be off-center during a step. Protect the same10px body samples
	# as navigation, not merely the center cell or large decorative art bounds.
	main.player.position = navigation.world(Vector2i(9, 9)) + Vector2(12, 0)
	navigation.actors["founder"] = main.player.position
	check(navigation.cell_at(main.player.position) == Vector2i(9, 9), "Boundary fixture center remains outside newly blocked cell")
	check(main.room.placement_actor_conflicts(proposed).size() == 1, "Off-center foot radius still prevents a furniture/body overlap")
	main.player.position = founder_start
	navigation.actors["founder"] = founder_start
	navigation.reservations["mira"] = Vector2i(10, 9)
	check(main.room.placement_actor_conflicts(proposed).is_empty(), "A future reservation alone does not pretend an actor is standing there")
	await click(editor.action_buttons["Sit"].get_global_rect().get_center())
	for tick: int in range(5): mina._physics_process(1.0 / 30.0)
	var travelling_position := mina.position
	var old_target := mina._requested_target
	check(mina._has_target and old_target == mina.desk_position, "Real Sit starts an active route toward the original seat")
	await key(KEY_R)
	await click(model.world(Vector2i(10, 8)))
	check(not editor.placement_active and main.room.placement_by_id("mira-workstation").facing == "east", "Route-only target change permits an unobstructed real rotation")
	check(mina.position == travelling_position, "Accepted rotation does not relocate the travelling actor")
	check(mina._has_target and mina._requested_target == mina.desk_position and mina._requested_target != old_target, "Existing placement-change path safely replans the future destination")
	await capture("route-target-replanned")
	await advance_actor(mina)
	check(mina.position == mina.desk_position, "Replanned actor reaches new seat through clear cells")
	var seated_position := mina.position
	var undo_history: Array = editor._history.duplicate(true)
	await key(KEY_U)
	check(editor._history == undo_history and main.room.placement_by_id("mira-workstation").facing == "east", "Occupied undo retains its history entry and committed room")
	check(mina.position == seated_position and "Leave desk" in editor._status.text, "Undo does not teleport a seated actor into restored furniture")
	await capture("occupied-undo-blocked")
	await click(editor.action_buttons["Leave"].get_global_rect().get_center())
	await advance_actor(mina)
	var clear_position := mina.position
	await key(KEY_U)
	check(editor._history.is_empty() and main.room.placement_by_id("mira-workstation").facing == "north", "Undo succeeds after actor has vacated the footprint")
	check(mina.position == clear_position, "Successful cleared undo preserves the actor's current physical position")
	await capture("clear-undo-restored")
	scene.free()
	await frames()
	actor_conflict_checks_completed = true

func run() -> void:
	record_motion = "--motion" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var original_room_hash := FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH)
	var original_catalog_hash := FileAccess.get_sha256(OfficeLayout.DEFAULT_CATALOG_PATH)
	fixture = FIXTURE.new()
	root.add_child(fixture)
	await frames()
	check(fixture.ready_ok, "Actual asset-backed fixture installs: " + str(fixture.errors))
	if not fixture.ready_ok:
		fixture.free()
		quit(1)
		return
	var main: GameMain = fixture.main
	var model: OfficeLayout = fixture.model
	var editor: Node2D = fixture.editor
	var actor := main.get_employee("mira")
	actor.set_physics_process(false)
	main.player.set_physics_process(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "No worker transport or process exists")
	check(not main._state_loaded and not main._worker_ready, "No saved company/settings state was bootstrapped or autosaved")
	check(actor.home_position == main.room.employee_spawn_position("mira"), "Fixture employee starts from its explicitly declared spawn, not a reused bootstrap actor")
	verify_registry_rejection(fixture)
	check(registry_checks_completed, "All malformed registry/profile checks completed without an early script exit")
	check(model.available_facings("desk") == OfficeLayout.FACINGS, "All four real pose/art candidates resolve only inside this scope")
	var plain := OfficeLayout.new()
	plain.load_files()
	check(plain.available_facings("desk") == OfficeLayout.FACINGS, "A separate normal model sees all independently reviewed production facings")
	for facing: String in OfficeLayout.FACINGS:
		var candidate := model.validate_candidate("mira-workstation", Vector2i(10, 8), facing, 1)
		check(candidate.valid, "Canonical candidate geometry validates for " + facing + ": " + str(candidate.errors))
		check(candidate.candidate.profile.status == "calibration_candidate" and not candidate.candidate.profile.review.art, "Readiness status remains truthful in " + facing)
		for blocked: Vector2i in [Vector2i(0, 8), Vector2i(35, 8), Vector2i(10, 2), Vector2i(10, 21), Vector2i(0, 2), Vector2i(35, 21)]:
			check(not model.validate_candidate("mira-workstation", blocked, facing, 1).valid, "Calibration admission cannot bypass any wall/corner checks")
	await capture("single-south-standing")
	var sit: Button = editor.action_buttons["Sit"]
	await click(sit.get_global_rect().get_center())
	check(actor._has_target, "Visible Sit button dispatches real actor navigation")
	check(main.player.route.is_empty(), "UI Sit click does not leak into founder ground navigation")
	await advance_actor(actor)
	check(actor.work_state == EmployeeAvatar.WorkState.SITTING and actor.position == actor.desk_position, "Physical path arrives at actual canonical seat")
	check(actor.seated_render_offset() == Vector2(0, 12), "South supported visual correction is applied without moving feet")
	check(actor._active_work_pose_layers.size() == 2 and not actor._character_sprite.visible, "Canonical CharacterArt supplies two real source layers")
	if not actor._work_pose_layer_sprites.has("upper"):
		fixture.free()
		quit(1)
		return
	check(actor._work_pose_layer_sprites.upper.z_index == roundi(main.room.placement_by_id("mira-workstation").anchor.y) + 3, "Upper hands use declared prop-relative depth")
	check(actor._work_pose_layer_sprites.lower.z_index == roundi(main.room.placement_by_id("mira-workstation").anchor.y), "Lower legs are behind south tabletop")
	await capture("single-south-seated")
	await verify_interrupted_depth(main, actor)
	# R is an actual key event through the existing editor rotate/preview logic.
	await key(KEY_R)
	check(editor.placement_active and editor.preview_facing == "west", "R opens next authored facing in existing NESW selector")
	var occupied_position := actor.position
	var occupied_overrides := main.room.placement_overrides.duplicate(true)
	var occupied_history: Array = editor._history.duplicate(true)
	await click(model.world(Vector2i(10, 8)))
	check(editor.placement_active and not editor.preview_result.valid and "Leave desk" in editor._status.text, "Occupied rotation is rejected with an actionable leave instruction")
	check(actor.position == occupied_position and main.room.placement_overrides == occupied_overrides and editor._history == occupied_history, "Rejected rotation preserves actor feet, committed layout, and undo history")
	await capture("occupied-rotation-rejected")
	await click(editor.action_buttons["Leave"].get_global_rect().get_center())
	check(not editor.placement_active and main.room.prop_node("mira-workstation").visible, "Leave restores the committed preview before vacating")
	await advance_actor(actor)
	await key(KEY_R)
	await click(model.world(Vector2i(10, 8)))
	check(not editor.placement_active and main.room.placement_by_id("mira-workstation").facing == "west", "A real world click commits validated rotation")
	check(actor.position == actor.home_position, "Clear employee is not teleported by accepted rotation")
	await click(editor.action_buttons["Sit"].get_global_rect().get_center())
	await advance_actor(actor)
	check(actor.position == actor.desk_position and actor.seated_render_offset() == Vector2(-12, 4), "Real west path and character-specific supported socket arrive")
	await capture("single-west-seated")
	# Drawn body hit-tests still pass through GameMain, not a special showroom path.
	check(main._interaction_at(actor.render_position() + Vector2(0, -44)).get("id") == "mira", "Live employee hit-test follows registered rendered body")
	await click(actor.render_position() + Vector2(0, -44))
	check(main._pending_interaction == "mira", "Actual employee click enters main interaction route")
	check(not main.player.route.is_empty(), "Founder real path starts toward selected employee")
	main.player.cancel_route()
	main._pending_interaction = ""
	await click(editor.action_buttons["Leave"].get_global_rect().get_center())
	check(actor._has_target and actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "Leaving seat restores single locomotion sprite immediately")
	await advance_actor(actor)
	check(actor.seated_render_offset() == Vector2.ZERO, "Visual transition returns to zero after walking away")
	var registry_id: String = fixture.pose_set_id
	fixture.free()
	await frames()
	check(not CharacterArt.is_calibration_pose_set(registry_id), "Fixture teardown unregisters its scoped actual textures")
	check(not model.calibration_preview_enabled(), "Fixture teardown closes the model's calibration admission")
	check(model.available_facings("desk").is_empty(), "Expired candidate model cannot claim directions after teardown")
	var second := FIXTURE.new()
	root.add_child(second)
	await frames()
	check(second.ready_ok and second.pose_set_id != registry_id, "Second independent scene has a new isolated registry scope")
	check(not CharacterArt.is_calibration_pose_set(registry_id), "Old registry does not leak into the second scene")
	var second_id: String = second.pose_set_id
	second.free()
	await frames()
	check(not CharacterArt.is_calibration_pose_set(second_id), "Second teardown also unregisters its resources")
	await verify_two_employee_facings()
	check(all_direction_checks_completed, "All four native real-scene direction loops completed without an early script exit")
	await verify_actor_conflicts()
	check(actor_conflict_checks_completed, "All real-input actor-conflict cases completed without an early script exit")
	build_native_contacts()
	check(FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH) == original_room_hash and FileAccess.get_sha256(OfficeLayout.DEFAULT_CATALOG_PATH) == original_catalog_hash, "Production room/catalog remain byte-identical")
	check(CharacterArt.supported_work_facings("mira") == ["south"], "Legacy pose readiness remains unchanged after both scenes")
	var result := FileAccess.open(OUTPUT.path_join("headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	result.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "samples": sampled_frames, "motion_paths": motion_paths, "contact_sheets": contact_sheets, "contact_grid": "Six unscaled paired Mina/Theo crops: frames0,1,2 across top;3,4,5 across bottom.", "motion_ticks": motion_frames, "worker_disabled": true, "production_activation": false, "fixture_scope": "single desk then two employees; all four directions and six exact source frames through actual GameMain/EmployeeAvatar/navigation/editor", "limitations": ["Calibration status remains unapproved.", "North seat/hand support inferred.", "East upper lap strip and Theo key contact borderline.", "South hands naturally hidden by monitor.", "West head-adjacent keyboard and Theo one-pixel sole/cushion variation.", "Animation captures diagnose the real pipeline, not aesthetic acceptance."]}, "\t"))
	print("calibrated_workstation: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
