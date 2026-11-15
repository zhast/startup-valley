extends SceneTree
## Provider-free real-scene A/B and event checks. No source art is generated.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const OUTPUT := "res://tests/output/calibrated-thinking/reviewed"
var checks := 0
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var motion: Array[Dictionary] = []
var fixture: Node
var movie_tick := 0
var record_motion := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func event(kind: StringName, tool := "") -> WorkerEventRecord:
	return WorkerEventRecord.from_dictionary({"type": kind, "tool": tool})

func send(actors: Array[EmployeeAvatar], kind: StringName, tool := "") -> void:
	for actor: EmployeeAvatar in actors:
		actor.apply_worker_event(event(kind, tool), fixture.main.player.position)

func step(actors: Array[EmployeeAvatar], ticks: int, sequence := "") -> void:
	var start := movie_tick
	for tick: int in range(ticks):
		for actor: EmployeeAvatar in actors:
			actor._physics_process(1.0 / 30.0)
			check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Physical feet remain walkable")
			check(actor.render_position() == actor.render_position().round(), "Visible body remains pixel-snapped")
			if actor._has_target:
				check(actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "Walking has one locomotion body and no stale seated layers")
		if record_motion and not sequence.is_empty():
			movie_tick += 1
			await process_frame
			if tick in [0, int(ticks / 2), ticks - 1]: await capture(sequence + "-%02d" % tick, actors)
	if record_motion and not sequence.is_empty(): motion.append({"scenario": sequence, "start_tick": start, "end_tick": movie_tick, "fps": 30})

func capture(name_value: String, actors: Array[EmployeeAvatar]) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	check(not fixture.main.job_panel._connection_panel.visible and not fixture.main.job_panel._drawer_open, "No deferred connection/drawer surface hides either actor in evidence")
	RenderingServer.force_draw(false)
	var pixels := root.get_texture().get_image()
	check(pixels.get_size() == Vector2i(1280, 720), "Native GameMain capture is1280×720")
	check(pixels.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	var state: Array[Dictionary] = []
	for actor: EmployeeAvatar in actors:
		state.append({"employee": actor.employee_id, "state": actor.work_state, "activity": str(actor._activity), "live_job": actor.has_live_job, "physical_position": [actor.position.x, actor.position.y], "render_position": [actor.render_position().x, actor.render_position().y], "source_region": [actor._character_sprite.region_rect.position.x, actor._character_sprite.region_rect.position.y, 48, 80], "source_layers": actor._active_work_pose_layers.size()})
	captures.append({"path": name_value + ".png", "tick": movie_tick, "actors": state})

func open_fixture(facing: String, reuse: bool) -> Array[EmployeeAvatar]:
	fixture = FIXTURE.new()
	fixture.employee_ids = ["mira", "theo"] as Array[String]
	fixture.initial_facing = facing
	fixture.reuse_seated_idle_for_thinking = reuse
	root.add_child(fixture)
	await process_frame
	await process_frame # Let the explicit credential-missing onboarding defer finish.
	check(fixture.ready_ok, "Scoped real fixture admits %s thinking=%s: %s" % [facing, reuse, fixture.errors])
	var actors: Array[EmployeeAvatar] = []
	if not fixture.ready_ok: return actors
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	fixture.main.job_panel.close_drawer(false)
	check(fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1, "No worker process or transport is started")
	for id: String in ["mira", "theo"]:
		var actor: EmployeeAvatar = fixture.main.get_employee(id)
		actor.set_physics_process(false)
		actor.world_paused = false
		actor._idle_cooldown = 1000.0
		actors.append(actor)
	return actors

func close_fixture() -> void:
	var registered_id: String = fixture.pose_set_id
	fixture.free()
	await process_frame
	check(not CharacterArt.is_calibration_pose_set(registered_id), "Fixture teardown removes optional thinking capability")

func verify_source(actor: EmployeeAvatar, facing: String, phase: int) -> void:
	actor._animation_elapsed = (float(phase) + 0.01) / 1.5
	actor._blink_elapsed = (3.2 if actor.employee_id == "mira" else 2.45) if phase == 1 else 0
	actor._update_character_frame()
	var idle := CharacterArt.work_pose_frame(actor.employee_id, fixture.pose_set_id, facing, "seated", phase)
	var thought := CharacterArt.work_pose_frame(actor.employee_id, fixture.pose_set_id, facing, "thinking", phase)
	check(thought.get("reuse_pose") == "seated" and thought.get("presentation") == "quiet_seated_thinking", "Thinking provenance explicitly identifies quiet seated-idle reuse")
	check(thought.texture == idle.texture and thought.region == idle.region and thought.get("layers", []) == idle.get("layers", []), "Thinking frame and every source cut are exactly the seated-idle source")
	check(actor._character_sprite.texture == idle.texture and actor._character_sprite.region_rect == idle.region, "Actual runtime selects idle columns0–1, never typing columns2–5")
	check(actor._uses_calibration_seated_thinking() and actor._uses_seated_visual(), "Live thinking uses its admitted supported seat")
	check(actor._shadow_sprite.region_rect == PolishArt.shadow_region(2), "Quiet seated thinking uses seated shadow")
	check(actor._effect_sprite.global_position == actor.work_vfx_position(), "Actual thinking cue follows its explicit attachment or legacy origin")
	check(actor._label_layer.global_position == actor.render_position(), "Actual callout follows supported body")
	check(actor._shadow_sprite.global_position + Vector2(0, 2) == actor.render_position(), "Shadow origin follows supported body")
	check(actor.z_index == roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_z_offset), "Thinking locks the exact seated pose depth")
	var source: Image = idle.texture.get_image()
	if not idle.has("layers"):
		check(actor._character_sprite.visible and actor._active_work_pose_layers.is_empty(), "North owns one whole seated body")
	else:
		var joined := Image.create(48, 80, false, Image.FORMAT_RGBA8)
		var covered := 0
		check(not actor._character_sprite.visible and actor._active_work_pose_layers.size() == 2, "Split body replaces whole sprite without duplicates")
		for part: Dictionary in idle.layers:
			var sprite: Sprite2D = actor._work_pose_layer_sprites[str(part.name)]
			check(sprite.visible and sprite.texture == idle.texture and sprite.region_rect == part.region, "Visible source layer has exact region ownership")
			check(sprite.position == Vector2(-24, -72) + actor.seated_render_offset() + Vector2(part.offset), "Source layer keeps original cell registration")
			check(sprite.z_index == roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_layer_z_offsets[str(part.name)]), "Actual source layer keeps reviewed prop-relative depth")
			joined.blit_rect(source, Rect2i(part.region), Vector2i(part.offset))
			covered += int(part.region.size.x * part.region.size.y)
		check(covered == 48 * 80 and not Rect2(idle.layers[0].region).intersects(idle.layers[1].region), "Source ownership is complete and disjoint")
		check(joined.get_data() == source.get_region(Rect2i(idle.region)).get_data(), "Layer reunion is byte-exact including transparent pixels")
	for unsupported: String in ["research", "approval", "delivery"]:
		check(not CharacterArt.supports_work_pose(actor.employee_id, fixture.pose_set_id, facing, unsupported), "Thinking reuse grants no " + unsupported + " art capability")
	actor.has_live_job = false
	actor._update_character_frame()
	check(not actor._uses_seated_visual() and actor._active_work_pose_layers.is_empty() and actor._character_sprite.texture == CharacterArt.locomotion_sheet(actor.employee_id), "Even a stale WORKING label cannot reuse seated thinking after live-job revocation")
	actor.has_live_job = true
	actor._update_character_frame()

func verify_registry_guards() -> void:
	var owner := FIXTURE.new()
	var valid: Dictionary = owner.pose_registry()
	check(CharacterArt.register_calibration_pose_set("dev-calibration-thinking-valid", valid, owner), "Real alias registry accepts String keys and all native source cuts")
	check(CharacterArt.unregister_calibration_pose_set("dev-calibration-thinking-valid", owner), "Valid test registry can be released by its owner")
	for mutation: String in ["typing_pixels", "wrong_cuts", "missing_provenance", "wrong_presentation", "recursive_alias", "different_frame_count"]:
		var bad := valid.duplicate(true)
		match mutation:
			"typing_pixels": bad.facings.south.thinking.column = 2
			"wrong_cuts": bad.facings.south.thinking.cuts_by_character.mira = [49, 49]
			"missing_provenance": bad.facings.south.thinking.erase("reuse_pose")
			"wrong_presentation": bad.facings.south.thinking.presentation = "researching"
			"recursive_alias": bad.facings.south.seated.reuse_pose = "thinking"
			"different_frame_count": bad.facings.south.thinking.frames = 1
		check(not CharacterArt.register_calibration_pose_set("dev-calibration-thinking-invalid", bad, owner), "Registry rejects dishonest idle-thinking alias: " + mutation)
	owner.free()

func verify_events(actors: Array[EmployeeAvatar], facing: String) -> void:
	var positions: Array[Vector2] = []
	var offsets: Array[Vector2] = []
	var serials: Array[int] = []
	var reservations: Dictionary = actors[0].navigation.reservations.duplicate(true)
	var tweens_before := get_processed_tweens().size()
	for actor: EmployeeAvatar in actors:
		positions.append(actor.position)
		offsets.append(actor.seated_render_offset())
		serials.append(actor._seat_transition_serial)
		actor.world_paused = true
	for repeated: int in range(4): send(actors, &"agent.thinking")
	await step(actors, 6)
	for index: int in range(actors.size()):
		var actor := actors[index]
		check(actor.position == positions[index] and actor.seated_render_offset() == offsets[index], "Paused repeated thinking leaves physical/visual seat unchanged")
		check(actor._seat_transition_serial == serials[index], "Repeated thinking does not restart interpolation")
	send(actors, &"tool.started", "write_file")
	await step(actors, 6)
	for index: int in range(actors.size()):
		var actor := actors[index]
		check(actor.work_state == EmployeeAvatar.WorkState.TYPING and actor._activity == &"typing", "Incoming real typing state is applied while world paused")
		check(actor.position == positions[index] and actor.seated_render_offset() == offsets[index], "Thinking→typing retains its seat while paused")
		check(actor._character_sprite.region_rect.position.x >= 96, "Only tool-start selects actual typing frames")
	await capture("after-%s-paused-incoming-typing" % facing, actors)
	send(actors, &"tool.completed", "write_file")
	for index: int in range(actors.size()):
		var actor := actors[index]
		check(actor.work_state == EmployeeAvatar.WorkState.WORKING and actor._activity == &"thinking", "Tool completion preserves actual WORKING/thinking semantics")
		check(actor._seat_transition_serial == serials[index], "Thinking→typing→thinking does not remount or tween again")
		verify_source(actor, facing, 0)
	check(actors[0].navigation.reservations == reservations and get_processed_tweens().size() == tweens_before, "Visual state changes alter neither reservations nor Tween count")
	await capture("after-%s-paused-return-thinking" % facing, actors)
	for actor: EmployeeAvatar in actors: actor.world_paused = false
	await step(actors, 42, "after-%s-quiet-loop" % facing)
	send(actors, &"tool.started", "write_file")
	await step(actors, 12, "after-%s-typing-loop" % facing)
	send(actors, &"tool.completed", "write_file")
	# No new delivery art is supplied: the existing event keeps its ordinary
	# delivery walk, and failure uses its original non-seated recovery state.
	actors[0].world_paused = true
	actors[1].world_paused = true
	actors[0].apply_worker_event(event(&"job.completed"), fixture.main.player.position)
	actors[1].apply_worker_event(event(&"job.failed"), fixture.main.player.position)
	await step(actors, 3)
	for index: int in range(actors.size()):
		var actor := actors[index]
		check(not actor.has_live_job and not actor._uses_seated_visual(), "Terminal event revokes seated thinking immediately")
		check(actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "Terminal event leaves no stale source layers")
		check(actor.position == positions[index], "Paused terminal event does not move physical feet")
		check(actor.z_index == int(actor.position.y), "Terminal event restores ordinary physical-foot depth")
		actor.world_paused = false
	await step(actors, 12, "after-%s-leave-recovery" % facing)
	for actor: EmployeeAvatar in actors:
		check(actor.seated_render_offset() == Vector2.ZERO, "Leaving or failure clears old seat correction after140ms")
		actor.apply_worker_event(event(&"agent.thinking"), fixture.main.player.position)
		check(not actor.has_live_job and not actor._uses_calibration_seated_thinking(), "Late thinking after terminal job cannot resurrect seated work")
	await capture("after-%s-left-and-failed" % facing, actors)

func run() -> void:
	record_motion = "--motion" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var room_hash := FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH)
	var catalog_hash := FileAccess.get_sha256(OfficeLayout.DEFAULT_CATALOG_PATH)
	verify_registry_guards()
	for reuse: bool in [false, true]:
		for facing: String in OfficeLayout.FACINGS:
			var actors := await open_fixture(facing, reuse)
			if actors.size() != 2:
				await close_fixture()
				continue
			send(actors, &"job.started")
			await step(actors, 150)
			for actor: EmployeeAvatar in actors:
				check(actor.is_at_desk() and not actor._has_target, "Actual job-start walk arrives at authored desk: %s %s at%s target%s paused%s" % [facing, actor.employee_id, actor.position, actor.desk_position, actor.world_paused])
				check(actor.work_state == EmployeeAvatar.WorkState.WORKING and actor._activity == &"thinking" and actor.has_live_job, "Job start remains live WORKING/thinking")
				if reuse:
					check(CharacterArt.calibration_thinking_reuses_seated(actor.employee_id, fixture.pose_set_id, facing), "Capability is explicit for both actors/all four directions")
				else:
					check(not actor._uses_seated_visual() and actor._active_work_pose_layers.is_empty() and actor._character_sprite.texture == CharacterArt.locomotion_sheet(actor.employee_id), "Disabled capability reproduces old standing fallback")
			if reuse:
				for phase: int in range(2):
					for actor: EmployeeAvatar in actors: verify_source(actor, facing, phase)
					await capture("after-%s-idle-%d" % [facing, phase], actors)
				await verify_events(actors, facing)
			else:
				await capture("before-%s-standing-thinking" % facing, actors)
				await step(actors, 12, "before-%s-standing-loop" % facing)
			await close_fixture()
	for id: String in ["mira", "theo"]:
		check(CharacterArt.supported_work_facings(id) == ["south"], "Production work-facing support remains South only")
		check(not CharacterArt.calibration_thinking_reuses_seated(id, CharacterArt.LEGACY_WORK_POSE_SET, "south"), "Legacy South thinking never opts into calibration reuse")
		var frame := CharacterArt.work_pose_frame(id, CharacterArt.LEGACY_WORK_POSE_SET, "south", "thinking", 0)
		check(frame.texture == CharacterArt.work_sheet(id) and frame.region == CharacterArt.work_region(1, 4), "Legacy South thinking texture/region remains byte-for-byte source-identical")
	check(FileAccess.get_sha256(OfficeLayout.DEFAULT_PATH) == room_hash and FileAccess.get_sha256(OfficeLayout.DEFAULT_CATALOG_PATH) == catalog_hash, "No production layout or art catalogue changed")
	var report := {"checks": checks, "failures": failures, "worker_disabled": true, "production_activation": false, "reuse": "Owner-scoped WORKING + thinking reuses seated-idle source columns0–1 with a brief120ms blink every4s; typing remains columns2–5 only on actual tool state.", "captures": captures, "motion": motion, "motion_ticks": movie_tick, "limitations": ["No new drawn art.", "No research, approval or delivery capability added.", "Existing seat/hand contact and mount-pose limitations remain.", "Pause freezes navigation/seat interpolation; live event visuals and gentle animation keep updating as before."]}
	var output := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	print("calibrated_thinking: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
