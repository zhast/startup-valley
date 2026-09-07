extends SceneTree
## Actual fixture attachment proof. No worker, personal save or new art.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const OUTPUT := "res://tests/output/calibrated-work-vfx"
var checks := 0
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var attachments: Array[Dictionary] = []
var fixture: Node
var motion_ticks := 0
var record_motion := false
var capture_prefix := ""

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func source_body(actor: EmployeeAvatar) -> Rect2:
	var ink := actor._character_sprite.texture.get_image().get_region(Rect2i(actor._character_sprite.region_rect)).get_used_rect()
	return Rect2(actor.render_position() + Vector2(-24, -72) + Vector2(ink.position), Vector2(ink.size))

func cue_rect(actor: EmployeeAvatar) -> Rect2:
	return Rect2(actor._effect_sprite.global_position - Vector2(12, 12), Vector2(24, 24))

func verify_cue(actor: EmployeeAvatar, facing: String, pose: String) -> void:
	fixture.main._update_label_visibility("mira")
	var admitted: Variant = CharacterArt.calibration_work_vfx_anchor(actor.employee_id, fixture.pose_set_id, facing, pose)
	check(admitted is Vector2, "Actual registry admits explicit work-VFX anchor")
	if not admitted is Vector2: return
	var expected: Vector2 = Vector2(actor._workstation_visual.prop_anchor) + admitted
	check(actor._effect_sprite.global_position == expected.round(), "Actual cue uses exact prop attachment even during seat interpolation")
	check(actor._effect_sprite.global_position == actor._effect_sprite.global_position.round(), "Cue remains native pixel-aligned")
	check(actor._effect_sprite.scale == Vector2.ONE and not actor._effect_sprite.flip_h and not actor._effect_sprite.flip_v, "Existing cue art is neither scaled nor mirrored")
	check(actor._effect_sprite.region_rect.size == Vector2(24, 24) and actor._effect_sprite.texture == PolishArt.WORLD_VFX, "Original24×24 event atlas is unchanged")
	var body := source_body(actor)
	var placement: Dictionary = fixture.main.room.placement_by_id(actor.employee_id + "-workstation")
	var prop: Rect2 = placement.world_visual_bounds
	prop.position += fixture.main.room.global_position
	var bounds := cue_rect(actor)
	check(actor.calibration_work_vfx_rect() == bounds, "Visible admitted cue exposes its full source frame to callout placement")
	check(bounds.grow(4) in fixture.main._world_ui_obstacles(), "Main reserves the actual calibrated cue plus4px breathing room for label and prompt placement")
	check(bounds.end.y <= minf(body.position.y, prop.position.y) - 4.0, "Full cue frame clears actual head and complete furniture by4px")
	check(not bounds.intersects(body) and not bounds.intersects(prop), "Cue does not cover body, monitor, desk or chair")
	check(Rect2(18, 82, 1114, 620).encloses(bounds), "Cue stays inside native playfield below persistent HUD")
	check(not bounds.intersects(fixture.main.clock_panel.get_global_rect()) and not bounds.intersects(fixture.main.job_panel.rail_global_rect()), "Cue does not touch clock or employee rail")
	if actor._labels_visible() and not actor.labels_suppressed:
		check(not bounds.intersects(actor.world_label_rect()), "Visible employee label and paper pointer avoid work cue: " + facing + "/" + actor.employee_id)
	check(not actor.attention_cue_visible(), "Ordinary thinking/typing does not add an attention badge")
	var count := 0
	for child: Node in actor.get_children():
		if child is Sprite2D and child.texture == PolishArt.WORLD_VFX: count += 1
	check(count == 1, "Exactly one real-event cue sprite exists")

func capture(name_value: String, actors: Array[EmployeeAvatar]) -> void:
	if DisplayServer.get_name() == "headless": return
	name_value = capture_prefix + name_value
	await process_frame
	RenderingServer.force_draw(false)
	check(not fixture.main.job_panel._connection_panel.visible and not fixture.main.job_panel._drawer_open, "Native evidence has no connection/drawer occlusion")
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Native evidence size remains1280×720")
	check(image.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	var states: Array[Dictionary] = []
	for actor: EmployeeAvatar in actors:
		var rect := cue_rect(actor)
		var body := source_body(actor)
		var label := actor.world_label_rect()
		states.append({"employee": actor.employee_id, "cue_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "source_region": [actor._effect_sprite.region_rect.position.x, actor._effect_sprite.region_rect.position.y, 24, 24], "body_position": [actor.render_position().x, actor.render_position().y], "source_body_bounds": [body.position.x, body.position.y, body.size.x, body.size.y], "label_rect": [label.position.x, label.position.y, label.size.x, label.size.y], "label_visible": actor._labels_visible() and not actor.labels_suppressed, "state": actor.work_state, "activity": str(actor._activity)})
	captures.append({"path": name_value + ".png", "tick": motion_ticks, "actors": states})

func event(kind: StringName, tool := "") -> WorkerEventRecord:
	return WorkerEventRecord.from_dictionary({"type": kind, "tool": tool})

func test_validation() -> void:
	var owner := FIXTURE.new()
	var definition: Dictionary = owner.pose_registry()
	for value: Variant in [null, "top", [0], [0, -96.5], [0, INF], [0, -257], ["0", -96]]:
		var bad := definition.duplicate(true)
		bad.facings.north.thinking.work_vfx_anchor_by_character.mira = value
		check(not CharacterArt.register_calibration_pose_set("dev-calibration-vfx-invalid", bad, owner), "Malformed/non-native attachment is rejected")
	for fault: String in ["missing_actor", "wrong_actor", "wrong_pose"]:
		var bad := definition.duplicate(true)
		if fault == "missing_actor": bad.facings.north.thinking.work_vfx_anchor_by_character.erase("theo")
		elif fault == "wrong_actor": bad.facings.north.thinking.work_vfx_anchor_by_character["founder"] = [0, -90]
		else: bad.facings.north.seated["work_vfx_anchor_by_character"] = {"mira": [0, -90], "theo": [0, -90]}
		check(not CharacterArt.register_calibration_pose_set("dev-calibration-vfx-invalid", bad, owner), "Attachment cannot be silently admitted: " + fault)
	for id: String in ["mira", "theo"]:
		check(CharacterArt.calibration_work_vfx_anchor(id, CharacterArt.LEGACY_WORK_POSE_SET, "south", "thinking") == null, "Legacy production registry has no attachment")
		var actor := EmployeeAvatar.new()
		var record := EmployeeRecord.from_dictionary({"id": id, "display_name": id})
		root.add_child(actor)
		actor.configure(record, Vector2(300, 300), Vector2(300, 300), Vector2(500, 300))
		actor.has_live_job = true
		actor.work_state = EmployeeAvatar.WorkState.WORKING
		actor._set_activity(&"thinking")
		actor._update_character_frame()
		check(not actor.calibration_work_vfx_rect().has_area(), "Visible legacy work cue never changes production callout obstacles")
		check(actor.work_vfx_position() == actor.position + Vector2(0, -78), "Legacy cue retains original body origin")
		actor.free()
	owner.free()

func direction(facing: String, nearby := false) -> void:
	capture_prefix = "nearby-" if nearby else ""
	fixture = FIXTURE.new()
	fixture.employee_ids = ["mira", "theo"] as Array[String]
	fixture.initial_facing = facing
	root.add_child(fixture)
	await process_frame
	await process_frame
	check(fixture.ready_ok, "Actual attachment fixture starts " + facing + str(fixture.errors))
	if not fixture.ready_ok:
		fixture.free()
		return
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	fixture.main.job_panel.close_drawer(false)
	if nearby:
		check(fixture.main.room.set_placement_overrides({"theo-workstation": {"grid": [14, 8], "facing": facing}}), "Actual canonical placement accepts nearby non-overlapping desks")
	var actors: Array[EmployeeAvatar] = []
	for id: String in ["mira", "theo"]:
		var actor: EmployeeAvatar = fixture.main.get_employee(id)
		actor.set_physics_process(false)
		actor.world_paused = false
		actor.set_ui_presentation_state("working")
		actor.apply_worker_event(event(&"job.started"), fixture.main.player.position)
		actors.append(actor)
	for tick: int in range(300 if nearby else 150):
		for actor: EmployeeAvatar in actors:
			actor._physics_process(1.0 / 30.0)
			if actor._uses_calibration_seated_thinking(): verify_cue(actor, facing, "thinking")
		if record_motion and actors[0]._seat_transition_active:
			motion_ticks += 1
			await process_frame
			await capture(facing + "-seat-transition-%03d" % tick, actors)
	for actor: EmployeeAvatar in actors:
		check(actor.is_at_desk() and not actor._seat_transition_active, "Actual job-start path and seated transition settle")
		var anchor: Vector2 = CharacterArt.calibration_work_vfx_anchor(actor.employee_id, fixture.pose_set_id, facing, "thinking")
		attachments.append({"facing": facing, "employee": actor.employee_id, "anchor_from_prop": [anchor.x, anchor.y]})
		actor._effect_sprite.visible = false
		check(not actor.calibration_work_vfx_rect().has_area(), "Hidden cue leaves no stale label obstacle")
		actor._effect_sprite.visible = true
		actor._effect_sprite.self_modulate.a = 0.0
		check(not actor.calibration_work_vfx_rect().has_area(), "Suppressed cue leaves no stale label obstacle")
		actor._effect_sprite.self_modulate.a = 1.0
	# Exercise the actual drawer pause policy and incoming/repeated events.
	fixture.main.job_panel.select_employee("mira")
	fixture.main._process(0.0)
	check(fixture.main._world_paused(), "An actual employee drawer pauses the world")
	var drawer: Rect2 = fixture.main.job_panel.drawer_global_rect()
	check(drawer in fixture.main._world_ui_obstacles(), "Actual open drawer remains a callout obstacle")
	for actor: EmployeeAvatar in actors:
		var size := actor.world_label_body_rect().size
		var candidate: Rect2 = fixture.main._calibration_callout_fallback(actor, size, fixture.main._world_ui_obstacles(), Rect2(18, 82, 1114, 620))
		if candidate.has_area():
			var painted := WorldCalloutSkin.bounds(candidate, WorldCalloutSkin.actor_rect(actor.render_position()).get_center())
			check(not painted.intersects(drawer), "Calibrated fallback never places a name or pointer under actual drawer")
	var tween_count := get_processed_tweens().size()
	for actor: EmployeeAvatar in actors:
		var physical := actor.position
		var visual := actor.render_position()
		var cue := actor.calibration_work_vfx_rect()
		var serial := actor._seat_transition_serial
		check(actor.world_paused, "Main propagates actual UI pause to actor")
		for repeat_index: int in range(3):
			actor.apply_worker_event(event(&"tool.started", "write_file"), fixture.main.player.position)
			actor._physics_process(1.0 / 30.0)
			verify_cue(actor, facing, "typing")
			actor.apply_worker_event(event(&"tool.completed"), fixture.main.player.position)
			actor._physics_process(1.0 / 30.0)
			verify_cue(actor, facing, "thinking")
		check(actor.position == physical and actor.render_position() == visual, "Paused incoming state changes cannot move physical feet or body")
		check(actor.calibration_work_vfx_rect() == cue and actor._seat_transition_serial == serial, "Repeated events retain fixed cue and do not restart seat interpolation")
	check(get_processed_tweens().size() == tween_count, "Incoming/repeated cue updates create no duplicate tweens")
	fixture.main.job_panel.close_drawer(false)
	fixture.main._process(0.0)
	for actor: EmployeeAvatar in actors:
		actor.set_ui_presentation_state("working")
		check(not actor.world_paused, "Closing actual drawer restores existing world policy")
	for pose: String in ["thinking", "typing"]:
		for actor: EmployeeAvatar in actors:
			actor.apply_worker_event(event(&"tool.completed") if pose == "thinking" else event(&"tool.started", "write_file"), fixture.main.player.position)
		for frame: int in range(4):
			for actor: EmployeeAvatar in actors:
				actor._animation_elapsed = float(frame) / (1.5 if pose == "thinking" else 8.0)
				actor._update_character_frame()
				actor._effect_sprite.region_rect = PolishArt.effect_region(StringName(pose), frame)
				verify_cue(actor, facing, pose)
			await capture("%s-%s-frame%d" % [facing, pose, frame], actors)
		# Focus/nameplates remain legible without duplicating attention badges.
		for actor: EmployeeAvatar in actors: actor.set_interaction_highlighted(true)
		fixture.main._update_label_visibility("mira")
		for actor: EmployeeAvatar in actors:
			verify_cue(actor, facing, pose)
			check(actor._labels_visible() and not actor.labels_suppressed, "Requested hover name remains visible with supported assembly and cue")
			var label := actor.world_label_rect()
			for obstacle: Rect2 in fixture.main._world_ui_obstacles():
				check(not label.intersects(obstacle), "Requested complete nameplate/pointer avoids furniture, cue and UI")
		check(not actors[0].world_label_rect().intersects(actors[1].world_label_rect()), "Nearby requested employee labels cannot overlap each other")
		await capture("%s-%s-labels" % [facing, pose], actors)
		# The assembly fallback must still refuse genuinely occupied screen area.
		var viewport := Rect2(18, 82, 1114, 620)
		var size := actors[0].world_label_body_rect().size
		check(not fixture.main._calibration_callout_fallback(actors[0], size, [viewport] as Array[Rect2], viewport).has_area(), "Full modal or occupied viewport cannot be bypassed by calibrated fallback")
		var original := actors[0]._effect_sprite.visible
		actors[0]._effect_sprite.visible = false
		check(not fixture.main._calibration_callout_fallback(actors[0], size, [] as Array[Rect2], viewport).has_area(), "Absent scoped cue cannot unlock larger callout candidates")
		actors[0]._effect_sprite.visible = original
		for actor: EmployeeAvatar in actors:
			actor.set_interaction_highlighted(false)
			actor.set_drawer_selected(true)
			verify_cue(actor, facing, pose)
		await capture("%s-%s-selected" % [facing, pose], actors)
		for actor: EmployeeAvatar in actors: actor.set_drawer_selected(false)
		for tick: int in range(24):
			for actor: EmployeeAvatar in actors:
				actor._physics_process(1.0 / 30.0)
				verify_cue(actor, facing, pose)
			if record_motion:
				motion_ticks += 1
				await process_frame
	for actor: EmployeeAvatar in actors:
		actor.apply_worker_event(event(&"job.failed"), fixture.main.player.position)
		check(actor._effect_sprite.global_position == actor.render_position() + Vector2(0, -78), "Terminal failure immediately restores original body-relative event cue")
		check(not actor._uses_seated_visual(), "Failure cannot retain a workstation-only attachment")
		check(not actor.calibration_work_vfx_rect().has_area(), "Terminal event releases calibration label obstacle immediately")
		for tick: int in range(6): actor._physics_process(1.0 / 30.0)
	await capture(facing + "-failure-original-cue", actors)
	var id: String = fixture.pose_set_id
	fixture.free()
	await process_frame
	check(CharacterArt.calibration_work_vfx_anchor("mira", id, facing, "thinking") == null, "Fixture teardown clears cue admission")

func run() -> void:
	record_motion = "--motion" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	test_validation()
	for facing: String in OfficeLayout.FACINGS: await direction(facing)
	await direction("north", true)
	var output := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "attachments": attachments, "captures": captures, "motion_ticks": motion_ticks, "worker_disabled": true, "production_activation": false, "basis": "Full24px cue4px above actual prop ink and source-head extrema, including both ends of seated visual correction; prop-relative attachment, no artwork movement."}, "\t"))
	print("calibrated_work_vfx: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
