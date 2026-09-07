extends SceneTree
## Provider-free actor-side facing/anchor contract. Synthetic offsets below are
## geometry-only fixtures, never approval of missing N/E/W raster/pose assets.

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
	check_pose_registry()
	for character_id: String in ["mira", "theo"]:
		check_actor(character_id)
	await check_main_integration()
	var output := "res://tests/output/workstation-facing"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output.path_join("results-headless.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "workerDisabled": true, "geometryFixturesOnly": true, "acceptedWorkFacings": ["south"]}, "\t"))
	print("workstation_facing: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_pose_registry() -> void:
	for character_id: String in ["mira", "theo"]:
		check(CharacterArt.supported_work_facings(character_id) == ["south"], "Only real south seated/typing art is supported: " + character_id)
		for facing: String in CharacterArt.WORK_FACINGS:
			for pose: String in ["seated", "typing", "research", "thinking", "approval"]:
				check(CharacterArt.supports_work_pose(character_id, CharacterArt.LEGACY_WORK_POSE_SET, facing, pose) == (facing == "south"), "Directional capability follows authored frames: %s/%s/%s" % [character_id, facing, pose])
		for frame: int in range(8):
			var seated := CharacterArt.work_pose_frame(character_id, CharacterArt.LEGACY_WORK_POSE_SET, "south", "seated", frame)
			var typing := CharacterArt.work_pose_frame(character_id, CharacterArt.LEGACY_WORK_POSE_SET, "south", "typing", frame)
			check(seated.texture == CharacterArt.seated_sheet(character_id) and seated.region == Rect2(Vector2(frame % 2 * 48, 0), CharacterArt.FRAME_SIZE), "Legacy seated pixels/cadence unchanged")
			check(typing.texture == CharacterArt.seated_sheet(character_id) and typing.region == Rect2(Vector2((2 + frame % 4) * 48, 0), CharacterArt.FRAME_SIZE), "Legacy typing pixels/cadence unchanged")
		check(CharacterArt.supported_work_facings(character_id, "missing-set").is_empty(), "An absent set cannot inherit legacy poses")
		check(not CharacterArt.supports_work_pose(character_id, CharacterArt.LEGACY_WORK_POSE_SET, "south", "missing-pose"), "An absent action cannot inherit seated art")
	check(CharacterArt.supported_work_facings("founder").is_empty(), "Founder has no employee work sheet implicitly assigned")
	check(CharacterArt.supported_work_facings("future-lawyer").is_empty(), "Future roles cannot silently borrow Mina's poses")
	check(CharacterArt.supported_work_facings("mira", CharacterArt.LEGACY_WORK_POSE_SET, []).is_empty(), "Empty requirements are not proof of supported directions")

func check_actor(character_id: String) -> void:
	var employee := EmployeeAvatar.new()
	var record := EmployeeRecord.new()
	record.id = character_id
	record.display_name = character_id.capitalize()
	var feet := Vector2(336, 240)
	employee.configure(record, feet, feet, Vector2(656, 240))
	root.add_child(employee)
	employee.set_physics_process(false)
	employee.world_paused = true
	var navigation := OfficeNavigation.new()
	root.add_child(navigation)
	navigation.configure({"width": 30, "height": 20, "tile_size": 32, "walkable_rects": [[0, 0, 30, 20]]}, Vector2.ZERO)
	employee.navigation = navigation
	navigation.actors[character_id] = feet
	navigation.reservations[character_id] = navigation.cell_at(feet)
	var legacy := {"work_facing": "south", "pose_set": CharacterArt.LEGACY_WORK_POSE_SET, "seat_anchor": Vector2.ZERO, "seat_z_offset": -32, "prop_anchor": feet + Vector2(0, 32), "work_position": feet}
	check(employee.configure_workstation_visual(legacy), "Legacy station metadata is accepted")
	check(employee.configure_research_visual(legacy), "Legacy research metadata is accepted")
	for state: EmployeeAvatar.WorkState in [EmployeeAvatar.WorkState.SITTING, EmployeeAvatar.WorkState.TYPING]:
		employee.work_state = state
		employee._physics_process(0)
		check(employee._character_sprite.position == Vector2(0, -32), "Legacy south character origin is pixel-identical")
		check(employee._shadow_sprite.position == Vector2(0, -2) and employee.z_index == int(feet.y), "Legacy south shadow and actor depth are unchanged")
	for facing: String in ["north", "east", "west"]:
		var unavailable := legacy.duplicate(true)
		unavailable.work_facing = facing
		check(not employee.configure_workstation_visual(unavailable), "Missing %s seated/typing art rejects station configuration" % facing)
		check(not employee.configure_research_visual(unavailable), "Missing %s research art rejects station configuration" % facing)
		check(employee._workstation_visual == legacy, "Rejected metadata does not mutate the last accepted station")
	var invalid := legacy.duplicate(true)
	invalid.seat_anchor = Vector2(INF, 0)
	check(not employee.configure_workstation_visual(invalid), "Non-finite render anchors cannot enter actor transforms")
	# These are deliberately nonproduction socket offsets, all rendered with the
	# supported south art. They test metadata math, not other-facing readiness.
	for offset: Vector2 in [Vector2(8, -6), Vector2(-10, 4), Vector2(0, 12)]:
		var geometry := legacy.duplicate(true)
		geometry.seat_anchor = offset
		geometry.seat_z_offset = -11
		geometry["test_fixture"] = "geometry-only"
		employee.position = feet
		employee._has_target = false
		employee.work_state = EmployeeAvatar.WorkState.SITTING
		var before := [employee.position, employee.desk_position, employee._requested_target, employee._route.duplicate(), navigation.actors.duplicate(), navigation.reservations.duplicate()]
		check(employee.configure_workstation_visual(geometry), "Geometry-only render socket can be configured independently of physical feet")
		check(before == [employee.position, employee.desk_position, employee._requested_target, employee._route, navigation.actors, navigation.reservations], "Render metadata cannot move feet, destinations, paths or reservations")
		check(employee._character_sprite.position == Vector2(0, -32) + offset, "Seated character uses explicit render anchor")
		check(employee._shadow_sprite.position == Vector2(0, -2) + offset and employee._effect_sprite.position == Vector2(0, -78) + offset, "Seated shadow and activity cue share the visual socket")
		check(employee.z_index == int(feet.y + 32 - 11), "Seated depth uses prop anchor plus authored seat depth, not offset foot Y")
		check(employee.render_position() == feet + offset, "World label geometry follows the rendered actor")
		var body := employee.get_child(0) as StaticBody2D
		check(body.position == Vector2.ZERO and (body.get_child(0) as CollisionShape2D).position == Vector2.ZERO, "The actor collision body stays at physical feet, never the drawn socket")
		check(not employee._character_sprite.flip_h and not employee._character_sprite.flip_v and employee._character_sprite.rotation == 0 and employee._character_sprite.scale == Vector2.ONE, "Workstation metadata never rotates, mirrors or rescales raster art")
		for state: EmployeeAvatar.WorkState in [EmployeeAvatar.WorkState.IDLE, EmployeeAvatar.WorkState.LUNCH, EmployeeAvatar.WorkState.WORKING, EmployeeAvatar.WorkState.WAITING_APPROVAL, EmployeeAvatar.WorkState.DELIVERING]:
			employee.work_state = state
			employee._update_character_frame()
			check(employee._character_sprite.position == Vector2(0, -32) and employee._shadow_sprite.position == Vector2(0, -2) and employee.z_index == int(feet.y), "Standing/nonseat state resets visual anchor and depth: %s" % state)
			employee.work_state = EmployeeAvatar.WorkState.TYPING
			employee._update_character_frame()
			check(employee.seated_render_offset() == offset, "Typing reapplies accepted socket after state reset")
		employee.walk_to(feet + Vector2(64, 0), EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
		check(employee._has_target and employee.seated_render_offset() == Vector2.ZERO and employee._character_sprite.position == Vector2(0, -32) and employee.z_index == int(feet.y), "Walking immediately clears seat transforms before the next physics frame")
		employee._has_target = false
		employee._route.clear()
		employee.position = feet + Vector2(64, 0)
		employee.work_state = EmployeeAvatar.WorkState.SITTING
		employee._update_character_frame()
		check(employee.seated_render_offset() == Vector2.ZERO and employee.z_index == int(employee.position.y), "A stale seated state away from its socket cannot apply prop-relative depth")
		employee.position = feet
		navigation.actors[character_id] = feet
		navigation.reservations[character_id] = navigation.cell_at(feet)
	# Exercise actual worker-event and schedule paths, not only direct state changes.
	employee.has_live_job = true
	employee.work_state = EmployeeAvatar.WorkState.SITTING
	var typing_event := WorkerEventRecord.new()
	typing_event.type = &"tool.started"
	typing_event.tool = "write_file"
	employee.apply_worker_event(typing_event, feet + Vector2(128, 0))
	check(employee.work_state == EmployeeAvatar.WorkState.TYPING and employee.seated_render_offset() == Vector2(0, 12), "A real write event uses the seated socket without moving feet")
	var failed_event := WorkerEventRecord.new()
	failed_event.type = &"job.failed"
	employee.apply_worker_event(failed_event, feet + Vector2(128, 0))
	check(employee.work_state == EmployeeAvatar.WorkState.IDLE and employee._character_sprite.position == Vector2(0, -32) and employee.z_index == int(feet.y), "A real terminal event clears seated transforms immediately")
	employee.work_state = EmployeeAvatar.WorkState.SITTING
	employee._update_character_frame()
	employee.lunch_position = feet + Vector2(96, 0)
	employee.set_schedule_phase("lunch")
	check(employee._has_target and employee.seated_render_offset() == Vector2.ZERO and employee._character_sprite.position == Vector2(0, -32), "Leaving for lunch removes the workstation socket on the schedule event")
	# An absent direction never paints a substituted work pose, even if invalid
	# fixture metadata bypasses the normal setter/readiness gate.
	employee._set_directional_work_pose("research", 0, {"work_facing": "west", "pose_set": CharacterArt.LEGACY_WORK_POSE_SET})
	check(employee._character_sprite.texture == CharacterArt.locomotion_sheet(character_id) and employee._character_sprite.region_rect == CharacterArt.locomotion_region(&"left", 0), "Unsupported work art has a truthful standing fallback, never fake seated art")
	employee.free()
	navigation.free()

func check_main_integration() -> void:
	var main := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	main.set_process(false)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Integration fixture never launches a provider/worker or opens saved company data")
	for actor: EmployeeAvatar in main._employees.values(): actor.set_physics_process(false)
	var employee := main.get_employee("mira")
	var expected := main.room.employee_workstation_visual("mira")
	check(employee._workstation_visual == expected, "Bootstrap forwards the exact resolved workstation visual profile")
	check(employee._research_visual == main.room.research_visual(), "Bootstrap forwards the exact resolved research profile")
	employee.position = employee.desk_position
	employee._has_target = false
	employee.work_state = EmployeeAvatar.WorkState.SITTING
	employee._physics_process(0)
	var desk := main.room.prop_node("mira-workstation")
	var desk_front := desk.get_node("DeskFront") as Sprite2D
	var lower := employee._work_pose_layer_sprites.get("lower") as Sprite2D
	var upper := employee._work_pose_layer_sprites.get("upper") as Sprite2D
	check(lower != null and upper != null and lower.z_index < desk_front.z_index and upper.z_index > desk_front.z_index, "Production actor uses the reviewed split desk layering")
	# In-memory geometry-only catalog mutation proves the placement refresh path.
	main.room.layout_model.catalog.desk.facing_profiles.south.seat_anchor = [8, -4]
	main.room.layout_model.catalog.desk.facing_profiles.south.seat_anchor_by_employee.mira = [8, -4]
	main.room.layout_model.catalog.desk.facing_profiles.south.seat_z_offset = -12
	main.room._rebuild_props()
	check(employee._workstation_visual == main.room.employee_workstation_visual("mira") and employee.seated_render_offset() == Vector2(8, -4), "Placement rebuild refreshes metadata on an existing employee")
	check(employee.position == employee.desk_position and employee.position == main.room.employee_workstation_visual("mira").work_position, "Placement refresh leaves logical seat feet at the work cell")
	check(main._interaction_at(employee.render_position() + Vector2(0, -44)).get("id", "") == "mira", "Employee click hit-test follows the rendered body")
	main._update_label_visibility("mira")
	var local := WorldCalloutSkin.bounds(employee.world_label_body_rect(), WorldCalloutSkin.ACTOR_BOUNDS.get_center())
	check(employee.world_label_rect() == Rect2(employee.render_position() + local.position, local.size), "Callout drawing/occlusion share the seated visual origin")
	await process_frame
	main.game_audio.shutdown()
	main.free()
