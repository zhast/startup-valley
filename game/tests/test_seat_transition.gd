extends SceneTree
## Seat handoff checks cover legacy fail-closed behavior plus the exact reviewed
## N/E/S/W production capability. They do not approve new art or geometry.

var checks := 0
var failures: Array[String] = []
var trace: Array[Dictionary] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func actor_for(id: String) -> EmployeeAvatar:
	var actor := EmployeeAvatar.new()
	var record := EmployeeRecord.new()
	record.id = id
	record.display_name = "Mina" if id == "mira" else "Theo"
	var feet := Vector2(336, 240)
	actor.configure(record, feet, feet, feet + Vector2(128, 0))
	root.add_child(actor)
	actor.set_physics_process(false)
	actor.has_live_job = true
	actor.walk_speed = 0.0
	var navigation := OfficeNavigation.new()
	actor.add_child(navigation)
	navigation.configure({"width": 30, "height": 20, "tile_size": 32, "walkable_rects": [[0, 0, 30, 20]]}, Vector2.ZERO)
	actor.navigation = navigation
	navigation.actors[id] = feet
	navigation.reservations[id] = navigation.cell_at(feet)
	return actor

func geometry(actor: EmployeeAvatar, depth_delta: int = -24) -> Dictionary:
	return {"work_facing": "south", "pose_set": CharacterArt.LEGACY_WORK_POSE_SET, "seat_anchor": Vector2(0, -12), "seat_correction": Vector2(0, -8 if actor.employee_id == "mira" else -4), "seat_z_offset": depth_delta, "prop_anchor": actor.desk_position, "work_position": actor.desk_position, "test_fixture": "geometry-only: not a north art approval"}

func reviewed_geometry(actor: EmployeeAvatar, facing: String) -> Dictionary:
	var anchors := {
		"north": {"mira": Vector2(0, -20), "theo": Vector2(0, -16)},
		"east": {"mira": Vector2(12, 3), "theo": Vector2(12, 4)},
		"south": {"mira": Vector2(0, 12), "theo": Vector2(0, 12)},
		"west": {"mira": Vector2(-12, 4), "theo": Vector2(-12, 8)},
	}
	var depths := {"north": {"upper": 3, "lower": 0}, "east": {"upper": 2, "lower": -4}, "south": {"upper": 3, "lower": 0}, "west": {"upper": 2, "lower": -4}}
	var seat_depths := {"north": 20, "east": 2, "south": 3, "west": 2}
	return {
		"work_facing": facing,
		"pose_set": CharacterArt.REVIEWED_WORKSTATION_POSE_SET,
		"workstation_capability_revision": "workstations-v2:" + facing,
		"seat_anchor": anchors[facing][actor.employee_id],
		"seat_z_offset": seat_depths[facing],
		"seat_layer_z_offsets": depths[facing],
		"seat_pose_depth_lock": true,
		"seat_state_handoff": {"clearance_pixels": 32},
		"grounded_work_shadow": true,
		"grounded_work_shadow_follow_seat_x": true,
		"ground_shadow_z_offset": -6,
		"prop_anchor": actor.desk_position,
		"work_position": actor.desk_position,
	}

func physical(actor: EmployeeAvatar) -> Array:
	return [actor.position, actor.desk_position, actor._route.duplicate(), actor._requested_target, actor._target_position, actor.navigation.actors.duplicate(), actor.navigation.reservations.duplicate(), actor.get_child(0).position]

func shared_geometry(actor: EmployeeAvatar) -> void:
	var visible := actor.render_position()
	check(visible == visible.round(), "Visual foot is an integer world pixel")
	check(actor._character_sprite.global_position + Vector2(0, 32) == visible, "Character shares interpolated snapped origin")
	check(actor._shadow_sprite.global_position + Vector2(0, 2) == visible, "Shadow shares interpolated snapped origin")
	check(actor._effect_sprite.global_position + Vector2(0, 78) == visible, "Event cue shares interpolated snapped origin")
	check(actor._label_layer.global_position == visible, "Callout drawing shares interpolated snapped origin")
	var local := WorldCalloutSkin.bounds(actor.world_label_body_rect(), WorldCalloutSkin.ACTOR_BOUNDS.get_center())
	check(actor.world_label_rect() == Rect2(visible + local.position, local.size), "Callout bounds match paint geometry during interpolation")
	check(actor.get_child(0).position == Vector2.ZERO, "Physical collision body never adopts render offset")
	check(actor._character_sprite.scale == Vector2.ONE and actor._character_sprite.rotation == 0 and not actor._character_sprite.flip_h, "Transition never scales, rotates or mirrors art")

func opaque_sprite_point(sprite: Sprite2D) -> Vector2:
	var image := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.5:
				return sprite.to_global(Vector2(x, y) - sprite.region_rect.size * 0.5 + Vector2(0.5, 0.5))
	return Vector2(INF, INF)

func enter(actor: EmployeeAvatar) -> void:
	actor.position = actor.desk_position
	actor.navigation.actors[actor.employee_id] = actor.position
	actor.navigation.reservations[actor.employee_id] = actor.navigation.cell_at(actor.position)
	actor._has_target = false
	actor._route.clear()
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	actor._update_character_frame()

func event(kind: StringName, tool: String = "", error_copy: String = "") -> WorkerEventRecord:
	var record := WorkerEventRecord.new()
	record.type = kind
	record.tool = tool
	record.error = error_copy
	return record

func test_default_gate(id: String) -> void:
	var actor := actor_for(id)
	var metadata := geometry(actor)
	check(actor.configure_workstation_visual(metadata), "Optional geometry correction validates")
	enter(actor)
	check(not actor._seat_transition_preview and not actor._seat_transition_active, "Production default never enables preview")
	check(actor.seated_render_offset() == Vector2(0, -12), "Default path ignores dev-only character correction")
	check(actor._character_sprite.position == Vector2(0, -44), "Existing nonzero legacy seat anchor remains instantaneous")
	check(not actor.set_seat_transition_preview(true, 79) and not actor.set_seat_transition_preview(true, 181), "Durations outside80–180ms are refused")
	check(not actor.set_seat_transition_preview(true, NAN), "Nonfinite transition duration is refused")
	check(not actor._seat_transition_preview, "Invalid preview settings leave legacy behavior unchanged")
	var invalid := metadata.duplicate(true)
	invalid.seat_correction = Vector2(INF, 0)
	check(not actor.configure_workstation_visual(invalid) and actor._workstation_visual == metadata, "Nonfinite correction cannot mutate accepted metadata")
	invalid.seat_correction = [0, -8]
	check(not actor.configure_workstation_visual(invalid), "Correction must be explicit resolved Vector2, not ambiguous JSON input")
	for facing: String in ["north", "east", "west"]:
		invalid = metadata.duplicate(true)
		invalid.work_facing = facing
		check(not actor.configure_workstation_visual(invalid), "Preview metadata does not grant unauthored direction: " + facing)
	check(CharacterArt.supported_work_facings(id) == ["south"], "No production art capability was registered")
	actor.free()

func test_reviewed_production_gate(id: String, facing: String) -> void:
	var actor := actor_for(id)
	var metadata := reviewed_geometry(actor, facing)
	check(actor.configure_workstation_visual(metadata), "Exact reviewed production metadata validates: " + id + "/" + facing)
	check(actor._seat_transition_preview and is_equal_approx(actor._seat_transition_duration, 0.14), "Reviewed production enables the bounded 140ms handoff: " + id + "/" + facing)
	enter(actor)
	check(actor._seat_transition_active and actor.seated_render_offset() == Vector2.ZERO, "Reviewed production begins seated entry at standing endpoint: " + id + "/" + facing)
	actor._physics_process(0.14)
	check(not actor._seat_transition_active and actor.seated_render_offset() == metadata.seat_anchor, "Reviewed production reaches its exact authored seat anchor: " + id + "/" + facing)
	var forged := metadata.duplicate(true)
	forged.workstation_capability_revision = "workstations-v2:forged"
	check(not actor.configure_workstation_visual(forged), "Forged revision cannot replace accepted production metadata: " + id + "/" + facing)
	var legacy := geometry(actor)
	check(actor.configure_workstation_visual(legacy) and not actor._seat_transition_preview, "Legacy reconfiguration disables reviewed production handoff: " + id + "/" + facing)
	actor.free()

func test_timing_and_refresh(id: String, milliseconds: float, depth_delta: int) -> void:
	var actor := actor_for(id)
	actor.configure_workstation_visual(geometry(actor, depth_delta))
	check(actor.set_seat_transition_preview(true, milliseconds), "Editor-only preview explicitly enables")
	var tween_count := get_processed_tweens().size()
	enter(actor)
	var expected := Vector2(0, -20 if id == "mira" else -16)
	check(actor.seated_render_offset() == Vector2.ZERO and actor._seat_transition_active, "Seat entry starts at standing visual endpoint, not a teleport")
	var before := physical(actor)
	var serial := actor._seat_transition_serial
	var previous := actor.seated_render_offset()
	var elapsed := 0.0
	var steps := 0
	while elapsed < milliseconds / 1000.0:
		actor._physics_process(0.01)
		elapsed += 0.01
		steps += 1
		var current := actor.seated_render_offset()
		check(current.y <= previous.y and current.y >= expected.y, "Seat motion is monotonic without overshoot")
		check(absf(current.y - previous.y) <= 4.0, "Ten-millisecond step is bounded, not an endpoint teleport")
		check(actor.z_index >= mini(int(actor.position.y), int(actor.position.y) + depth_delta) and actor.z_index <= maxi(int(actor.position.y), int(actor.position.y) + depth_delta), "Near/far depth stays within explicit endpoints")
		shared_geometry(actor)
		check(physical(actor) == before, "Visual interpolation cannot alter physical feet, routes or reservations")
		actor.apply_worker_event(event(&"tool.started", "write_file"), actor.position)
		actor.configure_workstation_visual(geometry(actor, depth_delta))
		actor.set_seat_transition_preview(true, milliseconds)
		actor._update_character_frame()
		check(actor._seat_transition_serial == serial, "Repeated typing events, metadata and preview refreshes do not restart transition")
		previous = current
		trace.append({"id": id, "durationMs": milliseconds, "depthDelta": depth_delta, "step": steps, "offset": [current.x, current.y], "z": actor.z_index, "physical": [actor.position.x, actor.position.y]})
	check(not actor._seat_transition_active and actor.seated_render_offset() == expected, "Transition completes inside configured80–180ms duration")
	check(actor.z_index == int(actor.position.y) + depth_delta, "Completed seat uses explicit prop-relative depth")
	check(get_processed_tweens().size() == tween_count, "Repeated state updates create no Tween objects")
	# Omitted metadata is a new zero correction, never inheritance from a former
	# employee/pose-set profile. Midtransition changes retarget current pixels.
	var refreshed := geometry(actor, depth_delta)
	refreshed.erase("seat_correction")
	actor.configure_workstation_visual(refreshed)
	check(actor.seated_render_offset() == expected, "Metadata refresh does not teleport existing visual endpoint")
	actor._physics_process(milliseconds / 1000.0)
	check(actor.seated_render_offset() == Vector2(0, -12), "Missing correction explicitly returns to zero after refresh")
	check(actor.set_seat_transition_preview(false), "Preview may explicitly be disabled")
	check(not actor._seat_transition_active and actor.seated_render_offset() == Vector2(0, -12), "Disabling preview resets transition state to exact legacy rendering")
	actor.free()

func test_interrupts(id: String) -> void:
	for interruption: String in ["walk", "failed", "cancelled", "delivery", "approval", "research", "lunch"]:
		var actor := actor_for(id)
		actor.configure_workstation_visual(geometry(actor))
		actor.set_seat_transition_preview(true)
		enter(actor)
		actor._physics_process(0.06)
		var partial := actor.seated_render_offset()
		check(partial != Vector2.ZERO and actor._seat_transition_active, "Interruption fixture catches actual in-flight seat motion")
		match interruption:
			"walk": actor.walk_to(actor.position + Vector2(64, 0), EmployeeAvatar.WorkState.WANDERING)
			"failed": actor.apply_worker_event(event(&"job.failed", "", "Fixture failure"), actor.position)
			"cancelled": actor.apply_worker_event(event(&"job.failed", "", "Cancelled by player"), actor.position)
			"delivery": actor.apply_worker_event(event(&"job.completed"), actor.position + Vector2(96, 0))
			"approval": actor.apply_worker_event(event(&"approval.required"), actor.position + Vector2(96, 0))
			"research": actor.apply_worker_event(event(&"tool.started", "web_search"), actor.position)
			"lunch":
				actor.has_live_job = false
				actor.lunch_position = actor.position + Vector2(96, 0)
				actor.set_schedule_phase("lunch")
		check(actor.seated_render_offset() == partial, "Interrupted seat reverses from current visible position: " + interruption)
		var before := physical(actor)
		for step: int in range(15):
			actor._physics_process(0.01)
			shared_geometry(actor)
			check(physical(actor) == before, "Stand interpolation itself never changes physical navigation: " + interruption)
		check(not actor._seat_transition_active and actor.seated_render_offset() == Vector2.ZERO, "Interruption fully clears seat correction: " + interruption)
		check(actor.z_index == int(actor.position.y), "Interruption restores ordinary physical depth: " + interruption)
		actor.free()
	var actor := actor_for(id)
	actor.configure_workstation_visual(geometry(actor))
	actor.set_seat_transition_preview(true)
	enter(actor)
	actor._physics_process(0.14)
	actor.work_state = EmployeeAvatar.WorkState.IDLE
	actor._update_character_frame()
	actor._physics_process(0.04)
	var partial := actor.seated_render_offset()
	enter(actor)
	check(actor.seated_render_offset() == partial, "Reentering while standing up retargets without a snap")
	actor._physics_process(0.14)
	check(actor.seated_render_offset() == Vector2(0, -20 if id == "mira" else -16), "Reentered seat reaches corrected endpoint")
	actor.world_paused = true
	actor.work_state = EmployeeAvatar.WorkState.IDLE
	actor._update_character_frame()
	partial = actor.seated_render_offset()
	actor._physics_process(0.5)
	check(actor.seated_render_offset() == partial and actor._seat_transition_elapsed == 0, "World pause freezes visual transition without losing pending target")
	actor.world_paused = false
	actor._physics_process(0.14)
	check(actor.seated_render_offset() == Vector2.ZERO, "Unpause completes pending stand transition")
	# A stale seated state far away cannot keep applying a desk correction.
	enter(actor)
	actor._physics_process(0.14)
	actor.position += Vector2(64.25, 0.25)
	actor.navigation.actors[id] = actor.position
	actor._physics_process(0.14)
	check(actor.seated_render_offset() == Vector2.ZERO and actor.z_index == int(actor.position.y), "Stale seated state away from desk sheds correction and depth")
	shared_geometry(actor)
	actor.free()

func test_main_hit_geometry() -> void:
	var main := load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	main.set_process(false)
	main.game_audio.set_volumes(0, 0)
	main.day_clock.set_speed(0)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Hit-test fixture never launches worker or opens a company save")
	for candidate: EmployeeAvatar in main._employees.values(): candidate.set_physics_process(false)
	var actor := main.get_employee("mira")
	actor.position = actor.desk_position
	actor.has_live_job = true
	actor.world_paused = false
	actor.configure_workstation_visual(geometry(actor))
	actor.set_seat_transition_preview(true)
	actor._has_target = false
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	actor._update_character_frame()
	for step: int in range(10):
		actor._physics_process(0.016)
		var painted_point := opaque_sprite_point(actor._character_sprite)
		check(painted_point.is_finite() and actor.body_surface_at(painted_point) == actor._character_sprite, "Interpolated source exposes a real painted employee pixel")
		var hit := main._interaction_at(painted_point)
		check(hit.get("id", "") == "mira", "Real main employee hit-test follows the interpolated painted body: " + str(hit))
		check(hit.get("point", Vector2.ZERO) == actor.position + Vector2(0, 40), "Click approach uses physical employee location, never seated render correction: " + str(hit))
		main._update_label_visibility("mira")
		shared_geometry(actor)
	main.game_audio.shutdown()
	main.free()

func test_ordinary_walking_unchanged(id: String) -> void:
	var preview := actor_for(id)
	var legacy := actor_for(id)
	for actor: EmployeeAvatar in [preview, legacy]:
		actor.configure_workstation_visual(geometry(actor))
		actor.walk_speed = 110.0
	preview.set_seat_transition_preview(true)
	enter(preview)
	enter(legacy)
	preview._physics_process(0.14)
	legacy._physics_process(0.14)
	for actor: EmployeeAvatar in [preview, legacy]:
		actor.walk_to(actor.position + Vector2(96, 0), EmployeeAvatar.WorkState.WANDERING)
	for step: int in range(15):
		preview._physics_process(1.0 / 60.0)
		legacy._physics_process(1.0 / 60.0)
		check(preview.position == legacy.position, "Ordinary walking advances identically while preview stands up")
		check(preview._route == legacy._route and preview._target_position == legacy._target_position, "Stand animation never changes path or destination")
		check(preview.navigation.actors == legacy.navigation.actors and preview.navigation.reservations == legacy.navigation.reservations, "Preview cannot change walking actor registration or reservations")
		shared_geometry(preview)
	check(preview.seated_render_offset() == Vector2.ZERO and preview.position != preview.desk_position, "Real walking continues after visual stand completes")
	preview.free()
	legacy.free()

func run() -> void:
	for id: String in ["mira", "theo"]:
		test_default_gate(id)
		for facing: String in ["north", "east", "south", "west"]: test_reviewed_production_gate(id, facing)
		for duration: float in [80.0, 140.0, 180.0]:
			for depth: int in [-24, 24]: test_timing_and_refresh(id, duration, depth)
		test_interrupts(id)
		test_ordinary_walking_unchanged(id)
	test_main_hit_geometry()
	var output := "res://tests/output/seat-transition"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output.path_join("results-headless.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "workerDisabled": true, "legacyDefaultOff": true, "reviewedProductionDurationMs": 140, "registeredFacings": ["north", "east", "south", "west"], "trace": trace}, "\t"))
	print("seat_transition: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
