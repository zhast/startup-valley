extends "res://tools/capture_lunch_pose_review.gd"
## Current schedule regression plus explicit no-capability standing fallback.
## Historical standing captures remain unchanged after the cluster promotion.
const AFTER_OUTPUT := "res://tests/output/lunch-schedule-current"
var coverage: Array[String] = []

func preview_standing_break(_actor: EmployeeAvatar) -> void:
	pass # All body, shadow, layer and transition updates are production code.

func capture_state(name: String) -> void:
	# Arrival initiates the same 140ms sit transition as ordinary play.
	tick(6)
	main._update_label_visibility("")
	var entry := {"name": name, "clock": main.day_clock.formatted_time(), "phase": main.day_clock.phase, "actors": {}, "tick": trace.size(), "prototype_only": false}
	for id: String in main._employees:
		var actor: EmployeeAvatar = main._employees[id]
		var body := actor._character_sprite
		source_hashes[body.texture.resource_path] = FileAccess.get_sha256(body.texture.resource_path)
		entry.actors[id] = {"position": [actor.position.x, actor.position.y], "render_position": [actor.render_position().x, actor.render_position().y], "state": actor.work_state, "phase": actor.schedule_phase, "facing": str(actor._facing), "walking": actor._has_target, "source": body.texture.resource_path, "region": [body.region_rect.position.x, body.region_rect.position.y, body.region_rect.size.x, body.region_rect.size.y], "shadow_region": str(actor._shadow_sprite.region_rect), "work_layers": actor._active_work_pose_layers.size()}
		if actor.work_state == EmployeeAvatar.WorkState.LUNCH and not actor._has_target:
			if not actor._collaboration_visual.is_empty():
				check(actor._uses_collaboration_visual(), "Actual lunch uses the reviewed shared chair capability: " + id)
				check(actor.seated_render_offset() == actor._collaboration_visual.seat_anchor, "Settled lunch uses its own registered seat offset")
				check(actor._shadow_sprite.region_rect == PolishArt.shadow_region(2), "Supported lunch uses its seated shadow")
			else:
				check(body.texture == CharacterArt.locomotion_sheet(id), "Unsupported stationary lunch uses standing idle: " + id)
				check(actor._active_work_pose_layers.is_empty() and actor.seated_render_offset() == Vector2.ZERO, "Unsupported break has no stale seat layers or visual offset")
				check(actor._shadow_sprite.region_rect == PolishArt.shadow_region(0), "Unsupported break uses standing shadow")
		if name == "work-restored": check(body.texture == CharacterArt.seated_sheet(id), "Actual 13:30 return restores separate desk-seated atlas")
	if DisplayServer.get_name() != "headless":
		await frames(3)
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		check(picture.get_size() == VIEWPORT, "Native 1280×720 post-fix capture")
		var path := AFTER_OUTPUT.path_join(name + ".png")
		check(picture.save_png(path) == OK, "Save post-fix scene, never historical baseline")
		entry["path"] = path
		entry["sha256"] = FileAccess.get_sha256(path)
		if name.begins_with("lunch-idle"):
			var detail_path := AFTER_OUTPUT.path_join(name + "-lounge-native.png")
			check(picture.get_region(Rect2i(256, 328, 176, 184)).save_png(detail_path) == OK, "Save native post-fix lounge crop")
			entry["native_detail"] = detail_path
	captures.append(entry)

func event(actor: EmployeeAvatar, kind: StringName, tool: String = "") -> void:
	var incoming := WorkerEventRecord.new()
	incoming.type = kind
	incoming.tool = tool
	actor.apply_worker_event(incoming, Vector2(720, 464))

func settle_actor(actor: EmployeeAvatar, state: EmployeeAvatar.WorkState) -> void:
	var count := 0
	while (actor._has_target or actor.work_state != state) and count < 900:
		actor._physics_process(TICK)
		count += 1
	check(not actor._has_target and actor.work_state == state, "Synthetic open-floor route reaches expected actual state: " + str(state))

func verify_actor(id: String) -> void:
	var actor := EmployeeAvatar.new()
	var record := EmployeeRecord.new()
	record.id = id
	record.display_name = "Mina" if id == "mira" else "Theo"
	var feet := Vector2(336, 240)
	actor.configure(record, feet, feet, Vector2(592, 240))
	root.add_child(actor)
	actor.set_physics_process(false)
	var navigation := OfficeNavigation.new()
	root.add_child(navigation)
	navigation.configure({"width": 30, "height": 20, "tile_size": 32, "walkable_rects": [[0, 0, 30, 20]]}, Vector2.ZERO)
	actor.navigation = navigation
	navigation.actors[id] = feet
	actor.lunch_position = Vector2(464, 464)
	# Explicit geometry-only previous seat, not new lounge attachment/art.
	var previous_seat := {"work_facing": "south", "pose_set": CharacterArt.LEGACY_WORK_POSE_SET, "seat_anchor": Vector2(8, -6), "seat_z_offset": -11, "prop_anchor": feet + Vector2(0, 32), "work_position": feet}
	check(actor.configure_workstation_visual(previous_seat), "Admit geometry-only prior desk offset")
	for direction: StringName in [&"front", &"back", &"left", &"right"]:
		var approach: Vector2 = {&"front": Vector2.DOWN, &"back": Vector2.UP, &"left": Vector2.LEFT, &"right": Vector2.RIGHT}[direction]
		actor.position = feet - approach * 64
		navigation.actors[id] = actor.position
		actor.lunch_position = feet
		actor.schedule_phase = "work"
		actor.set_schedule_phase("lunch")
		settle_actor(actor, EmployeeAvatar.WorkState.LUNCH)
		check(actor.position == feet and actor._facing == direction and actor._character_sprite.texture == CharacterArt.locomotion_sheet(id), "Real cardinal arrival retains correct standing direction: %s/%s" % [id, direction])
		for frame: int in range(2):
			actor.position = feet
			actor._has_target = false
			actor.work_state = EmployeeAvatar.WorkState.SITTING
			actor._update_character_frame()
			check(actor.seated_render_offset() == Vector2(8, -6), "Prior desk is visibly offset before lunch reset")
			# A stale cached layer deliberately injected by the test must be hidden;
			# this asserts cleanup, never support for a fabricated lounge pose.
			var old_layer := Sprite2D.new()
			actor.add_child(old_layer)
			actor._work_pose_layer_sprites["lunch-test"] = old_layer
			actor._active_work_pose_layers.assign([{"name": "lunch-test"}])
			actor.work_state = EmployeeAvatar.WorkState.LUNCH
			actor.schedule_phase = "lunch"
			actor._facing = direction
			actor._animation_elapsed = float(frame) / 1.5
			var timer := actor._animation_elapsed
			actor._update_character_frame()
			check(actor._character_sprite.texture == CharacterArt.locomotion_sheet(id) and actor._character_sprite.region_rect == CharacterArt.locomotion_region(direction, frame), "Four arrival directions × two authored idle frames: %s/%s/%d" % [id, direction, frame])
			check(actor._shadow_sprite.region_rect == PolishArt.shadow_region(0), "Stationary lunch selects standing shadow")
			check(actor.position == feet and actor._facing == direction and actor._animation_elapsed == timer, "Frame refresh never changes physical feet, facing or idle timer")
			check(actor._active_work_pose_layers.is_empty() and not old_layer.visible, "Lunch hides all stale work layers")
			check(actor.seated_render_offset() == Vector2.ZERO and actor._character_sprite.position == Vector2(0, -32) and actor._shadow_sprite.position == Vector2(0, -2) and actor.z_index == int(feet.y), "Lunch clears previous seated body/shadow/depth correction")
			check(not actor._character_sprite.flip_h and not actor._character_sprite.flip_v and actor._character_sprite.scale == Vector2.ONE and actor._character_sprite.rotation == 0, "Authored native idle direction, no mirror/scale/rotation")
			old_layer.free()
			actor._work_pose_layer_sprites.erase("lunch-test")
		actor._has_target = true
		for frame: int in range(4):
			actor._animation_elapsed = float(frame) / 8.0
			actor._update_character_frame()
			check(actor._character_sprite.region_rect == CharacterArt.locomotion_region(direction, frame + 2) and actor._shadow_sprite.region_rect == PolishArt.shadow_region(1), "Travelling lunch retains all real directional walk frames and walking shadow")
		actor._has_target = false
	coverage.append(id + ": four directions, idle 0/1, walk 2–5, source/transform/layer/shadow checks")
	actor.position = feet
	navigation.actors[id] = feet
	actor.lunch_position = Vector2(464, 464)
	actor.schedule_phase = "work"
	actor.work_state = EmployeeAvatar.WorkState.SITTING
	event(actor, &"job.started")
	settle_actor(actor, EmployeeAvatar.WorkState.WORKING)
	event(actor, &"tool.started", "write_file")
	var protected := [actor.work_state, actor.position, actor._requested_target, actor._route.duplicate(), actor._animation_elapsed, actor._character_sprite.texture, actor._character_sprite.region_rect]
	actor.set_schedule_phase("lunch")
	check(actor.schedule_phase == "lunch" and actor.has_live_job and protected == [actor.work_state, actor.position, actor._requested_target, actor._route, actor._animation_elapsed, actor._character_sprite.texture, actor._character_sprite.region_rect], "Lunch clock cannot interrupt a real active typing job")
	for terminal: StringName in [&"job.failed", &"job.blocked"]:
		actor.world_paused = true
		var terminal_position := actor.position
		event(actor, terminal)
		for index: int in range(15): actor._physics_process(TICK)
		check(actor.position == terminal_position and not actor.has_live_job and actor.work_state == EmployeeAvatar.WorkState.LUNCH, "Incoming terminal event updates lunch state while paused, without moving feet")
		actor.world_paused = false
		settle_actor(actor, EmployeeAvatar.WorkState.LUNCH)
		check(not actor.has_live_job and actor._character_sprite.texture == CharacterArt.locomotion_sheet(id) and actor._shadow_sprite.region_rect == PolishArt.shadow_region(0), "Real terminal work during lunch reaches standing break: " + str(terminal))
		event(actor, &"job.started")
		settle_actor(actor, EmployeeAvatar.WorkState.WORKING)
	event(actor, &"job.completed")
	check(actor.work_state == EmployeeAvatar.WorkState.DELIVERING and actor._has_target, "Completed work still begins actual delivery route")
	protected = [actor.work_state, actor.position, actor._requested_target, actor._route.duplicate(), actor._animation_elapsed, actor._character_sprite.texture, actor._character_sprite.region_rect]
	actor.set_schedule_phase("lunch")
	check(protected == [actor.work_state, actor.position, actor._requested_target, actor._route, actor._animation_elapsed, actor._character_sprite.texture, actor._character_sprite.region_rect], "Repeated lunch clock cannot interrupt delivery")
	actor.world_paused = true
	var paused_position := actor.position
	var paused_route := actor._route.duplicate()
	for index: int in range(15): actor._physics_process(TICK)
	check(actor.position == paused_position and actor._route == paused_route and actor.work_state == EmployeeAvatar.WorkState.DELIVERING, "Paused delivery keeps physical route/position; idle animation policy unchanged")
	actor.world_paused = false
	settle_actor(actor, EmployeeAvatar.WorkState.LUNCH)
	check(actor._character_sprite.texture == CharacterArt.locomotion_sheet(id) and actor._shadow_sprite.region_rect == PolishArt.shadow_region(0), "Delivery completes before returning to actual standing break")
	coverage.append(id + ": actual active-job guard, failure, blocked work, completion, delivery guard/pause and lunch return")
	actor.free()
	navigation.free()

func run() -> void:
	check(OS.has_feature("editor"), "Post-fix lunch test is dev-only")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AFTER_OUTPUT))
	root.size = VIEWPORT
	root.content_scale_size = VIEWPORT
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	for path: String in ["res://actors/employee_avatar.gd", "res://world/main.gd", "res://world/town_room.gd", "res://simulation/day_clock.gd", "res://character_art.gd", "res://world/office_navigation.gd"]: source_hashes[path] = FileAccess.get_sha256(path)
	var historical := "res://tests/output/lunch-pose-review/results.json"
	var historical_hash := FileAccess.get_sha256(historical)
	await run_pass("runtime")
	for id: String in ["mira", "theo"]: verify_actor(id)
	check(FileAccess.get_sha256(historical) == historical_hash, "Historical before evidence remains byte-identical")
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Production snapshot frozen through post-fix run: " + path)
	var result := {"checks": checks, "failures": failures, "renderer": DisplayServer.get_name(), "workerDisabled": true, "actual_production_pose": true, "captures": captures, "coverage": coverage, "source_sha256": source_hashes, "actual_schedule_ticks": trace.size(), "historical_before_sha256": historical_hash, "limits": "Native keyframes, not a movie. Real production schedule and actor event paths with disposable NullWorker; no paid work or personal save."}
	var path := AFTER_OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "results.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", prior_environment)
	print("Lunch schedule and standing fallback: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
