extends SceneTree
## Bounded complete-candidate review; actual controls/physics, no personal state.
const FIXTURE := preload("res://tools/complete_south_workstation_fixture.gd")
const OUTPUT := "res://tests/output/complete-south-workstation-after-handoff"
var fixture: Node
var review_profile: Dictionary = {}
var checks := 0
var failures: Array[String] = []
var ticks := 0
var frame_origin := 0
var samples: Array[Dictionary] = []
var shots: Array[String] = []
var transitions: Dictionary = {}
var sources: Array[Dictionary] = []
var running_physics := false
var phase := "setup"
var worker_requests: Array = []

func fixture_resource() -> Variant:
	return FIXTURE

func output_directory() -> String:
	return OUTPUT

func review_facing() -> String:
	return "south"

func candidate_label() -> String:
	return "SOUTH CANDIDATE"

func before_evidence_path() -> String:
	return "res://tests/output/complete-south-workstation"

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func actors() -> Array[EmployeeAvatar]:
	return [fixture.main.get_employee("mira"), fixture.main.get_employee("theo")]

func present() -> void:
	await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func collect_transition() -> void:
	if not running_physics or DisplayServer.get_name() == "headless": return
	var transitioning := false
	for actor: EmployeeAvatar in actors(): transitioning = transitioning or actor._seat_transition_active or actor._seat_handoff_active
	if not transitioning: return
	var pixels := root.get_texture().get_image()
	var pair := Image.create(320, 208, false, Image.FORMAT_RGBA8)
	pair.blit_rect(pixels, Rect2i(256, 128, 160, 208), Vector2i.ZERO)
	pair.blit_rect(pixels, Rect2i(704, 128, 160, 208), Vector2i(160, 0))
	if not transitions.has(phase): transitions[phase] = []
	transitions[phase].append({"tick": ticks, "engine_frame": Engine.get_process_frames(), "image": pair})

func tick() -> void:
	if running_physics:
		ticks += 1
		for actor: EmployeeAvatar in actors():
			actor._physics_process(1.0 / 30.0)
			var seated := actor._uses_seated_visual()
			var mounted := seated or actor._seat_transition_active
			check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Physical feet stay in walkable cells")
			var shadow_x := actor.seated_render_offset().x if mounted and bool(actor._workstation_visual.get("grounded_work_shadow_follow_seat_x", false)) else 0.0
			check(actor._shadow_sprite.global_position == actor.position.round() + Vector2(shadow_x, -2), "Grounded shadow stays on the floor and follows only the admitted seat X offset")
			var expected_depth := roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.ground_shadow_z_offset) if mounted else int(actor.position.y)
			check(actor._shadow_sprite.z_index == expected_depth and actor._shadow_sprite.visible, "Visible shadow has correct independent depth at every tick")
			check(actor._character_sprite.global_position == actor._character_sprite.global_position.round(), "Native actor world transform remains pixel-snapped")
			if seated:
				check(actor._active_work_pose_layers.size() == 2 and not actor._character_sprite.visible, "Seated source is partitioned once, never double-painted")
				var seated_depth := roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_z_offset)
				check(actor.z_index == seated_depth, "Seated depth is locked, not interpolated through furniture")
			else:
				check(actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "Standing/moving boundary restores one ordinary body")
				var body_depth := roundi(Vector2(actor._workstation_visual.prop_anchor).y) + int(actor._workstation_visual.seat_layer_z_offsets.lower) if actor._seat_handoff_active else int(actor.position.y)
				check(actor.z_index == body_depth, "Departing body stays between chair and desk front until its opaque pixels clear")
				if actor._seat_handoff_active:
					check(actor.position.distance_to(actor._seat_handoff_origin) < float(actor._workstation_visual.seat_state_handoff.clearance_pixels), "Temporary departure depth is limited to declared visual overlap")
					var lower_depth := int(actor._workstation_visual.seat_layer_z_offsets.lower)
					var chair_behind := false
					var desk_ahead := false
					for layer: Dictionary in review_profile.render_layers:
						if str(layer.name).begins_with("Chair") and int(layer.z_offset) < lower_depth: chair_behind = true
						if str(layer.name) == "DeskFront" and int(layer.z_offset) > lower_depth: desk_ahead = true
					check(chair_behind and desk_ahead, "Standing handoff depth is bracketed between the authored chair and desk front")
			for part: Dictionary in actor._active_work_pose_layers:
				var sprite: Sprite2D = actor._work_pose_layer_sprites[str(part.name)]
				check(sprite.position == sprite.position.round() and sprite.scale == Vector2.ONE, "Source-owned upper/lower layers retain native coordinates")
			samples.append({"tick": ticks, "phase": phase, "employee": actor.employee_id, "feet": [actor.position.x, actor.position.y], "render_offset": [actor.seated_render_offset().x, actor.seated_render_offset().y], "state": actor.work_state, "target": actor._has_target, "transition": actor._seat_transition_active, "seated": seated, "terminal_seat_rest": actor._terminal_seat_rest, "seat_handoff_active": actor._seat_handoff_active, "seat_handoff_distance": actor.position.distance_to(actor._seat_handoff_origin) if actor._seat_handoff_active else null, "body_depth": actor.z_index, "shadow_depth": actor._shadow_sprite.z_index, "shadow_y": actor._shadow_sprite.global_position.y, "source_region": str(actor._character_sprite.region_rect)})
	await present()
	collect_transition()

func frames(count: int) -> void:
	for index: int in range(count): await tick()

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
	await tick()

func select_actor(index: int) -> void:
	var picker: OptionButton = fixture.editor._prop_picker
	picker.grab_focus()
	var popup := picker.get_popup()
	await present()
	for open_attempt: int in range(2):
		if popup.visible: break
		await key(KEY_SPACE)
	check(popup.visible, "Real Space opens the native employee selector")
	for attempt: int in range(4):
		if popup.get_focused_item() == index: break
		await key(KEY_DOWN)
	check(popup.get_focused_item() == index, "Actual arrow input focuses the requested employee")
	await key(KEY_ENTER)
	await tick()
	check(fixture.editor._owner_id() == (["mira", "theo"][index]), "Real selector chooses requested employee")

func action(copy: String) -> void:
	var button: Button = fixture.editor.action_buttons[copy]
	check(button.is_visible_in_tree() and not button.disabled, "Action is a visible enabled control: " + copy)
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	# Preserve the exact zero-time action boundary before advancing physics.
	await present()
	collect_transition()
	await tick()
	check(fixture.main.player.route.is_empty(), "Toolbar click does not leak into founder movement")

func settled() -> bool:
	for actor: EmployeeAvatar in actors():
		if actor._has_target or actor._waiting_for_desk or actor._seat_transition_active: return false
	return true

func finish_path() -> void:
	for index: int in range(140):
		if settled(): break
		await tick()
	check(settled(), "Both real routes and seat transitions settle within bounded budget: " + phase)

func capture(name_value: String) -> void:
	await present()
	if DisplayServer.get_name() == "headless": return
	var pixels := root.get_texture().get_image()
	check(pixels.get_size() == Vector2i(1280, 720), "Capture is native 1280×720")
	check(pixels.save_png(output_directory().path_join(name_value + ".png")) == OK, "Save native " + name_value)
	shots.append(name_value + ".png")
	var pair := Image.create(320, 208, false, Image.FORMAT_RGBA8)
	pair.blit_rect(pixels, Rect2i(256, 128, 160, 208), Vector2i.ZERO)
	pair.blit_rect(pixels, Rect2i(704, 128, 160, 208), Vector2i(160, 0))
	check(pair.save_png(output_directory().path_join(name_value + "-native.png")) == OK, "Save native pair")
	pair.resize(1280, 832, Image.INTERPOLATE_NEAREST)
	check(pair.save_png(output_directory().path_join(name_value + "-4x.png")) == OK, "Save nearest inspection pair")

func sample_pose(frame: int) -> void:
	for actor: EmployeeAvatar in actors():
		check(actor.work_state == (EmployeeAvatar.WorkState.SITTING if frame < 2 else EmployeeAvatar.WorkState.TYPING), "Actual Sit/Type control established the sampled state")
		# Endpoint phase sampling only; physical feet, authored pose, socket and
		# geometry are never repaired. Continuous transitions are recorded apart.
		var pose := "seated" if frame < 2 else "typing"
		var pose_frame := frame if frame < 2 else frame - 2
		actor._animation_elapsed = float(pose_frame) / (1.5 if frame < 2 else 8.0) + 0.001
		actor._update_character_frame()
		var expected_anchor: Vector2 = actor._workstation_visual.seat_anchor
		check(actor.position == actor.desk_position and actor.seated_render_offset() == expected_anchor, "Native endpoint preserves physical work foot and authored seat correction")
		var authored := CharacterArt.work_pose_frame(actor.employee_id, str(actor._workstation_visual.pose_set), review_facing(), pose, pose_frame)
		var parts: Array[Dictionary] = actor._active_work_pose_layers
		check(parts.size() == 2, "Endpoint has source-owned upper/lower partitions")
		if parts.size() == 2:
			check(authored.has("layers") and parts == authored.layers, "Partition matches the registered per-frame source cuts exactly")
			var upper: Rect2 = parts[0].region
			var lower: Rect2 = parts[1].region
			check(upper.position == authored.region.position and upper.size.x == 48 and lower.position == upper.position + Vector2(0, upper.size.y) and lower.size == Vector2(48, 80 - upper.size.y), "Partition reconstructs the exact 48×80 frame without loss or overlap")
			check(actor._character_sprite.texture == authored.texture, "Endpoint uses the registered direction-specific source texture")
	await capture("pose-%d" % frame)

func write_transition_sheets() -> void:
	for label: String in transitions:
		var entries: Array = transitions[label]
		var sheet := Image.create(320 * entries.size(), 208, false, Image.FORMAT_RGBA8)
		for index: int in range(entries.size()): sheet.blit_rect(entries[index].image, Rect2i(0, 0, 320, 208), Vector2i(index * 320, 0))
		check(sheet.save_png(output_directory().path_join(label + "-all-transition-ticks-native.png")) == OK, "Save every rendered transition tick: " + label)
		# Small per-actor rows remain inspectable at actual native pixels instead
		# of relying on a viewer that shrinks a 4,000px-wide strip.
		for index: int in range(entries.size()):
			check((entries[index].image as Image).save_png(output_directory().path_join("transition-%s-%02d.png" % [label, index])) == OK, "Save native transition pair")
		var columns := mini(5, entries.size())
		var rows := ceili(float(entries.size()) / float(columns))
		var grid := Image.create(320 * columns, 208 * rows, false, Image.FORMAT_RGBA8)
		grid.fill(Color("#eee2c8"))
		for index: int in range(entries.size()):
			grid.blit_rect(entries[index].image, Rect2i(0, 0, 320, 208), Vector2i(index % columns, floori(float(index) / float(columns))) * Vector2i(320, 208))
		check(grid.save_png(output_directory().path_join(label + "-review-grid-native.png")) == OK, "Save readable native transition grid: " + label)

func write_pose_sheet() -> void:
	if DisplayServer.get_name() == "headless": return
	var grid := Image.create(960, 416, false, Image.FORMAT_RGBA8)
	for frame: int in range(6):
		var source := Image.load_from_file(ProjectSettings.globalize_path(output_directory().path_join("pose-%d-native.png" % frame)))
		check(source != null and source.get_size() == Vector2i(320, 208), "Load exact native pose pair for contact sheet")
		if source != null:
			grid.blit_rect(source, Rect2i(0, 0, 320, 208), Vector2i(frame % 3, floori(float(frame) / 3.0)) * Vector2i(320, 208))
	check(grid.save_png(output_directory().path_join("six-poses-review-native.png")) == OK, "Save six source-frame endpoints at native size")

func verify_handoff_validation() -> void:
	for actor: EmployeeAvatar in actors():
		var accepted := actor._workstation_visual.duplicate(true)
		for invalid: Variant in ["32", null, 0, 0.5, INF, 129]:
			var metadata := accepted.duplicate(true)
			metadata.seat_state_handoff = {"clearance_pixels": invalid}
			check(not actor.configure_workstation_visual(metadata) and actor._workstation_visual == accepted, "Malformed handoff clearance fails closed without mutating the accepted visual")
		for invalid: Variant in ["0", null, 0.5, INF, -4097, 4096]:
			var metadata := accepted.duplicate(true)
			metadata.seat_layer_z_offsets.lower = invalid
			check(not actor.configure_workstation_visual(metadata) and actor._workstation_visual == accepted, "Malformed handoff body depth fails closed without mutating the accepted visual")
		var production_forgery := accepted.duplicate(true)
		production_forgery.pose_set = CharacterArt.LEGACY_WORK_POSE_SET
		check(not actor.configure_workstation_visual(production_forgery) and actor._workstation_visual == accepted, "A handoff field cannot activate against an ordinary production pose set")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	frame_origin = Engine.get_process_frames()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	fixture = fixture_resource().new()
	root.add_child(fixture)
	check(fixture.ready_ok, "Combined exact candidate is admitted: " + str(fixture.errors))
	if not fixture.ready_ok:
		fixture.free()
		quit(1)
		return
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	for actor: EmployeeAvatar in actors(): actor.set_physics_process(false)
	await frames(8)
	fixture.main.job_panel.close_drawer(false)
	fixture.editor._status.text = candidate_label() + " · quiet grain + floor shadow · two employees · no worker, saves or production approval"
	var profile: Dictionary = fixture.model.resolve_profile("desk", review_facing()).profile
	review_profile = profile
	check(profile.seat_pose_depth_lock and profile.grounded_work_shadow and profile.grounded_work_shadow_follow_seat_x, "Combined fixture explicitly opts into all tested depth/shadow policies")
	check(profile.get("seat_state_handoff") is Dictionary and not profile.seat_state_handoff.is_empty(), "Combined fixture explicitly declares its bounded departure handoff")
	check(profile.status == "calibration_candidate" and not profile.review.art, "Combined review does not enable production")
	for layer: Dictionary in profile.render_layers:
		sources.append({"path": layer.art, "sha256": FileAccess.get_sha256(str(layer.art)), "offset": layer.offset, "depth": layer.z_offset})
	for actor: EmployeeAvatar in actors():
		check(actor.position == actor.home_position and actor.home_position.y == 560, "Original declared start is unchanged")
		var initial_route := actor.navigation.path(actor.position, actor.desk_position, actor.employee_id)
		check(not initial_route.is_empty(), "Declared workstation work cell is reachable from the employee's real start")
		var lowest_depth := 4096
		for layer: Dictionary in profile.render_layers: lowest_depth = mini(lowest_depth, int(layer.z_offset))
		check(actor._workstation_visual.ground_shadow_z_offset == lowest_depth - 1, "Ground shadow is beneath chair and all desk/device layers")
		var seated_source := CharacterArt.work_pose_frame(actor.employee_id, str(actor._workstation_visual.pose_set), review_facing(), "seated", 0)
		sources.append({"employee": actor.employee_id, "seated_decoded_sha256": digest((seated_source.texture as Texture2D).get_image().get_data())})
	verify_handoff_validation()
	worker_requests = fixture.main.worker_client.blocked_requests.duplicate()
	await capture("initial")
	running_physics = true
	phase = "enter"
	for index: int in range(2):
		await select_actor(index)
		await action("Sit")
		check(actors()[index]._has_target, "Real Sit click creates an actual reserved route")
	await finish_path()
	await sample_pose(0)
	await sample_pose(1)
	phase = "typing"
	for index: int in range(2):
		await select_actor(index)
		await action("Type")
	await finish_path()
	for frame: int in range(2, 6): await sample_pose(frame)
	phase = "failure"
	for actor: EmployeeAvatar in actors():
		var event := WorkerEventRecord.new()
		event.type = &"job.failed"
		actor.apply_worker_event(event, fixture.main.player.position)
	await frames(8)
	for actor: EmployeeAvatar in actors():
		check(not actor.has_live_job and actor.work_state == EmployeeAvatar.WorkState.IDLE and actor._terminal_seat_rest, "Failure ends business state immediately while retaining an honest seated idle visual")
		check(actor._uses_seated_visual() and actor._active_work_pose_layers.size() == 2, "Failure never substitutes a standing torso inside the occupied chair")
		check(actor.position == actor.desk_position and actor.seated_render_offset() == Vector2(actor._workstation_visual.seat_anchor), "Failure preserves physical feet and the reviewed seat socket")
		check(not actor.navigation.reservations.has(actor.employee_id), "Failure releases the physical destination reservation exactly as before")
		var repeated := WorkerEventRecord.new()
		repeated.type = &"job.failed"
		actor.apply_worker_event(repeated, fixture.main.player.position)
		check(actor._terminal_seat_rest and actor._uses_seated_visual() and not actor._seat_transition_active, "A repeated terminal event is idempotent and does not flash a standing body")
	await capture("failure-restored")
	phase = "reenter"
	for index: int in range(2):
		await select_actor(index)
		var actor := actors()[index]
		var serial := actor._seat_transition_serial
		await action("Type")
		check(not actor._has_target and actor.work_state == EmployeeAvatar.WorkState.TYPING and actor._activity == &"typing", "Type at the occupied seat uses the real write-file presentation without a redundant route")
		check(actor._seat_transition_serial == serial, "Exact-seat typing does not restart its seat transition")
		check(not actor._terminal_seat_rest, "A genuine typing event supersedes terminal seated rest")
		check(actor.navigation.reservations.get(actor.employee_id) == actor.navigation.cell_at(actor.desk_position), "Exact-seat job start reacquires the physical desk reservation")
	await finish_path()
	await capture("typing-restored")
	phase = "leave"
	for index: int in range(2):
		await select_actor(index)
		await action("Leave")
		check(actors()[index]._seat_handoff_active, "Leave begins a bounded chair-to-walk depth handoff")
	await finish_path()
	for actor: EmployeeAvatar in actors():
		check(actor.position == actor.home_position and actor.seated_render_offset() == Vector2.ZERO and not actor._seat_handoff_active, "Actual Leave returns to original home and ordinary physical depth")
	await capture("left")
	running_physics = false
	write_transition_sheets()
	write_pose_sheet()
	check(fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1, "No worker was started")
	check(fixture.main.worker_client.blocked_requests == worker_requests and not fixture.main._state_loaded, "Review actions perform no new worker requests or company bootstrap")
	var pose_set: String = fixture.pose_set_id
	check(CharacterArt.unregister_calibration_pose_set(pose_set, fixture), "Capability-loss check revokes the exact live pose owner")
	for actor: EmployeeAvatar in actors():
		actor._terminal_seat_rest = true
		actor._seat_handoff_active = true
		actor._update_character_frame()
		check(not actor._terminal_seat_rest and not actor._seat_handoff_active and actor._active_work_pose_layers.is_empty() and actor._character_sprite.visible, "Revoked pose capability clears every render-only seat latch and restores ordinary art")
	fixture.free()
	await process_frame
	check(not CharacterArt.is_calibration_pose_set(pose_set), "Teardown revokes the temporary pose owner")
	var rendered := Engine.get_process_frames() - frame_origin
	check(rendered <= 360, "Complete native run stays within 360-frame budget")
	var transition_counts := {}
	for label: String in transitions: transition_counts[label] = transitions[label].size()
	var result := {"checks": checks, "failures": failures, "physics_ticks": ticks, "engine_frames": rendered, "captures": shots, "transition_frames": transition_counts, "samples": samples, "sources": sources, "profile": profile, "direction": review_facing(), "scope": review_facing().capitalize() + " complete workstation lifecycle; dev candidate only, no production admission", "visual_acceptance": "requires a fresh native review; automated geometry is not art approval", "before_evidence": before_evidence_path()}
	var suffix := "-headless" if DisplayServer.get_name() == "headless" else ""
	var file := FileAccess.open(output_directory().path_join("results" + suffix + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	print("Complete %s workstation: %d checks, %d failures; %d physics ticks, %d rendered frames" % [review_facing().capitalize(), checks, failures.size(), ticks, rendered])
	quit(0 if failures.is_empty() else 1)
