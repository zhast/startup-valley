extends "res://tools/capture_native_floor_study.gd"
## DEV-ONLY DIAGNOSTIC. Production LUNCH is unchanged. The second pass previews
## removing only its stationary work-sheet override, after actual schedule ticks.
const LUNCH_OUTPUT := "res://tests/output/lunch-pose-review"
const TICK := 1.0 / 30.0
var mode := "runtime"
var trace: Array[Dictionary] = []
var baseline_trace: Array[Dictionary] = []
var prior_environment := ""
var prototype_ticks := 0

func _initialize() -> void:
	prior_environment = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func physical_state() -> Dictionary:
	var state := {}
	for id: String in main._employees:
		var actor: EmployeeAvatar = main._employees[id]
		state[id] = {"position": actor.position, "facing": actor._facing, "state": actor.work_state, "phase": actor.schedule_phase, "target": actor._target_position, "has_target": actor._has_target, "route": actor._route.duplicate(), "requested": actor._requested_target, "arrival": actor._arrival_state, "animation_elapsed": actor._animation_elapsed, "idle_elapsed": actor._idle_elapsed}
	state["reservations"] = main.room.navigation.reservations.duplicate()
	return state

func preview_standing_break(actor: EmployeeAvatar) -> void:
	if mode != "standing-preview" or actor._has_target or actor.work_state != EmployeeAvatar.WorkState.LUNCH: return
	# This is deliberately a local visual experiment, not a new authored pose or
	# production state. It uses the exact existing default-idle branch sources.
	actor._character_sprite.texture = CharacterArt.locomotion_sheet(actor.employee_id)
	actor._character_sprite.region_rect = CharacterArt.locomotion_region(actor._facing, int(actor._animation_elapsed * 1.5) % 2)
	actor._shadow_sprite.region_rect = PolishArt.shadow_region(0)
	prototype_ticks += 1

func tick(count: int = 1) -> void:
	for index: int in range(count):
		for actor: EmployeeAvatar in main._employees.values():
			actor._physics_process(TICK)
			var before := physical_state()
			preview_standing_break(actor)
			check(before == physical_state(), "Preview never alters schedule, route, physical position, timing or reservations")
			check(main.room.navigation.walkable(main.room.navigation.cell_at(actor.position)), "Actual schedule stays in walkable cells: " + actor.employee_id)
		trace.append(physical_state())

func all_arrived(state: EmployeeAvatar.WorkState) -> bool:
	for actor: EmployeeAvatar in main._employees.values():
		if actor.work_state != state or actor._has_target: return false
	return true

func await_arrival(state: EmployeeAvatar.WorkState) -> void:
	var elapsed := 0
	while not all_arrived(state) and elapsed < 900:
		tick()
		elapsed += 1
	check(all_arrived(state), "Both employees arrive through actual navigation within 30 simulated seconds: " + str(state))
	check(main._employees["mira"].position.distance_to(main._employees["theo"].position) >= 22.0, "Distinct reserved lunch/desk destinations")

func capture_state(name: String) -> void:
	main._update_label_visibility("")
	var entry := {"name": mode + "-" + name, "clock": main.day_clock.formatted_time(), "phase": main.day_clock.phase, "actors": {}, "tick": trace.size(), "prototype_only": mode == "standing-preview"}
	for id: String in main._employees:
		var actor: EmployeeAvatar = main._employees[id]
		var body := actor._character_sprite
		source_hashes[body.texture.resource_path] = FileAccess.get_sha256(body.texture.resource_path)
		var crop := body.texture.get_image().get_region(Rect2i(body.region_rect))
		entry.actors[id] = {"position": [actor.position.x, actor.position.y], "render_position": [actor.render_position().x, actor.render_position().y], "state": actor.work_state, "phase": actor.schedule_phase, "facing": str(actor._facing), "walking": actor._has_target, "source": body.texture.resource_path, "region": [body.region_rect.position.x, body.region_rect.position.y, body.region_rect.size.x, body.region_rect.size.y], "ink_bounds": str(crop.get_used_rect()), "shadow_region": str(actor._shadow_sprite.region_rect), "work_layers": actor._active_work_pose_layers.size()}
		if actor.work_state == EmployeeAvatar.WorkState.LUNCH and not actor._has_target:
			var expected := CharacterArt.work_sheet(id) if mode == "runtime" else CharacterArt.locomotion_sheet(id)
			check(body.texture == expected, "Stationary lunch uses explicitly recorded source: " + mode + "/" + id)
			check(actor._active_work_pose_layers.is_empty() and actor.render_position() == actor.position.round(), "Break has no workstation layer or visual seat correction: " + id)
			check(actor._shadow_sprite.region_rect == PolishArt.shadow_region(2 if mode == "runtime" else 0), "Break shadow matches demonstrated seated/standing presentation")
		if name == "work-restored":
			check(body.texture == CharacterArt.seated_sheet(id), "Return to desk restores real production seated pose: " + id)
	if DisplayServer.get_name() != "headless":
		await frames(3)
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		check(picture.get_size() == VIEWPORT, "Native 1280×720 evidence: " + entry.name)
		var path := LUNCH_OUTPUT.path_join(entry.name + ".png")
		check(picture.save_png(path) == OK, "Save actual room evidence: " + entry.name)
		entry["path"] = path
		entry["sha256"] = FileAccess.get_sha256(path)
		if name.begins_with("lunch-idle"):
			var detail := picture.get_region(Rect2i(256, 328, 176, 184))
			var detail_path := LUNCH_OUTPUT.path_join(entry.name + "-lounge-native.png")
			check(detail.save_png(detail_path) == OK, "Save unscaled lounge evidence")
			entry["native_detail"] = detail_path
		images[entry.name] = picture
	captures.append(entry)

func run_pass(next_mode: String) -> void:
	mode = next_mode
	trace.clear()
	await make_main(2)
	main.day_clock.set_time(1, DayClock.LUNCH_START - 1)
	await_arrival(EmployeeAvatar.WorkState.SITTING)
	await capture_state("before-lunch")
	main.day_clock.set_time(1, DayClock.LUNCH_START)
	tick(23)
	await capture_state("walking-to-lounge")
	await_arrival(EmployeeAvatar.WorkState.LUNCH)
	await capture_state("lunch-idle-0")
	tick(21)
	await capture_state("lunch-idle-1")
	var before_repeat := physical_state()
	main.day_clock.set_time(1, DayClock.LUNCH_START + 1)
	check(physical_state() == before_repeat, "Repeated lunch clock event does not restart settled route or idle timer")
	for actor: EmployeeAvatar in main._employees.values(): actor.world_paused = true
	var paused_positions: Array[Vector2] = []
	for actor: EmployeeAvatar in main._employees.values(): paused_positions.append(actor.position)
	tick(15)
	var actor_index := 0
	for actor: EmployeeAvatar in main._employees.values():
		check(actor.position == paused_positions[actor_index], "Paused lunch keeps physical position fixed")
		actor_index += 1
	await capture_state("lunch-paused")
	for actor: EmployeeAvatar in main._employees.values(): actor.world_paused = false
	main.day_clock.set_time(1, DayClock.LUNCH_END)
	tick(23)
	await capture_state("returning-to-work")
	await_arrival(EmployeeAvatar.WorkState.SITTING)
	await capture_state("work-restored")
	if mode == "runtime": baseline_trace.assign(trace.duplicate(true))
	else: check(trace == baseline_trace, "Entire actual lunch/return schedule and navigation trace is identical under standing preview")
	check(main.worker_client._process_id == -1 and main.worker_client._stdio == null, "No worker process, provider or save transport opened")
	main.queue_free()
	await frames(3)

func run() -> void:
	check(OS.has_feature("editor"), "Lunch comparison is dev-only")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LUNCH_OUTPUT))
	root.size = VIEWPORT
	root.content_scale_size = VIEWPORT
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	for path: String in ["res://actors/employee_avatar.gd", "res://world/main.gd", "res://world/town_room.gd", "res://simulation/day_clock.gd", "res://character_art.gd", "res://world/office_navigation.gd"]: source_hashes[path] = FileAccess.get_sha256(path)
	await run_pass("runtime")
	await run_pass("standing-preview")
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Production source frozen during diagnostic: " + path)
	check(prototype_ticks > 0, "Isolated standing preview sampled actual stationary lunch")
	var rendered := DisplayServer.get_name() != "headless"
	var result := {"checks": checks, "failures": failures, "renderer": DisplayServer.get_name(), "workerDisabled": true, "productionModified": false, "scenario_count": captures.size(), "captures": captures, "source_sha256": source_hashes, "actual_physics_ticks_per_pass": trace.size(), "prototype_actor_ticks": prototype_ticks, "comparison": "Exact existing schedule/navigation. Standing pass locally overrides only stationary LUNCH body texture/region and shadow after each actual tick.", "limits": "Keyframes, not a recorded movie; no production fix, new art, lounge seat sockets, provider or live job."}
	var file := FileAccess.open(LUNCH_OUTPUT.path_join("results.json" if rendered else "results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", prior_environment)
	print("Lunch pose review: %d checks, %d failures; %d actual ticks per pass" % [checks, failures.size(), trace.size()])
	quit(0 if failures.is_empty() else 1)
