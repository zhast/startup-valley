extends "res://tools/capture_grounded_shadow_x_follow.gd"
## Native resting-tool comparison using the same full real-physics film path.
const RESTING := preload("res://tools/resting_north_engineer_fixture.gd")
const CENTERED := preload("res://tools/horizontal_grounded_mat_fixture.gd")
const REST_OUTPUT := "res://tests/output/resting-north-engineer"
const CENTER_OUTPUT := "res://tests/output/grounded-shadow-x-follow"
var resting_measurements: Array[Dictionary] = []
var unchanged_pixels := 0
var board_region_pixels := 0

func preflight(owner: Node, facing: String) -> void:
	var box := RESTING.resting_mat_bounds()
	var centered := CENTERED.new()
	centered.pose_set_id = owner.pose_set_id
	for direction: String in DIRECTIONS:
		var before: Dictionary = centered.profile(direction)
		var after: Dictionary = owner.profile(direction)
		if direction == "north":
			for entry: Dictionary in before.render_layers:
				if str(entry.name) == "EngineerMat": entry.offset = [-28, -32]
		check(before == after, "Only North mat translation changes; every other view/metadata remains identical")
	centered.free()
	var mat := image_at(RESTING.mat_path(facing))
	var info := PIXELS.analyze(mat)
	check(mat.get_size() == Vector2i(32, 20) and info.opaque_pixels == 640 and info.partial_alpha_pixels == 0, "Original32x20 opaque N2 mat is not recut or alpha keyed")
	check(info.opaque_colors == 18, "Original18-color native palette retained")
	var wood: Rect2i = DESK.profile(facing).top.grow(-2)
	check(wood.grow(-2).encloses(box) and box.position.x == wood.position.x + 2, "Leftmost legal placement leaves two clear pixels inside true wooden rim")
	check(not wood.grow(-2).encloses(Rect2i(box.position - Vector2i(1, 0), box.size)), "Moving one more pixel left would violate the two-pixel inset")
	image_at("res://assets/source/overnight-20260904/roles/engineer-mat-north-v2.png")
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var mat_node: Sprite2D = owner.main.room.prop_node(id + "-workstation").get_node("EngineerMat")
		check(mat_node.position == Vector2(-28, -32) and mat_node.scale == Vector2.ONE and not mat_node.flip_h and not mat_node.flip_v and mat_node.rotation == 0, "Real native renderer moves only the original plate by28px left")
		check(mat_node.texture.resource_path == RESTING.mat_path(facing) and mat_node.region_rect == Rect2(0, 0, 32, 20), "Source texture and full native region remain exact")
		check(bool(actor._workstation_visual.grounded_work_shadow) and bool(actor._workstation_visual.grounded_work_shadow_follow_seat_x), "Previously verified scoped shadow policy retained")

func set_frame(actor: EmployeeAvatar, facing: String, frame: int) -> void:
	super.set_frame(actor, facing, frame)
	# Parent metric describes the centered control. Keep it explicitly named,
	# then measure the identical body against this fixture's resting position.
	var control: Dictionary = observations.back()
	control["measurement_variant"] = "centered projected control"
	var pose := "seated" if frame < 2 else "typing"
	var phase := frame if frame < 2 else frame - 2
	var authored := CharacterArt.work_pose_frame(actor.employee_id, actor._workstation_visual.pose_set, facing, pose, phase)
	var body := PIXELS.rgba(authored.texture.get_image()).get_region(Rect2i(authored.region))
	var origin := Vector2i(actor.render_position() - Vector2(actor._workstation_visual.prop_anchor)) - Vector2i(24, 72)
	var box := RESTING.resting_mat_bounds()
	var overlap := 0
	var head_overlap := 0
	for y: int in range(80):
		for x: int in range(48):
			if body.get_pixel(x, y).a > 0.5 and box.has_point(origin + Vector2i(x, y)):
				overlap += 1
				if y < 36: head_overlap += 1
	resting_measurements.append({"employee": actor.employee_id, "frame": frame,
		"resting_projected_body_pixels": overlap, "resting_upper36rows_pixels": head_overlap,
		"centered_projected_body_pixels": control.projected_body_mat_pixels,
		"semantics": "resting equipment; seated scale reference" if frame < 2 else "existing typing is incompatible stress, not probe use"})
	check(overlap < int(control.projected_body_mat_pixels), "Left resting placement improves original-body clearance without changing the body")

func baseline_compare(owner: Node, shot: Image, facing: String, checkpoint: String) -> void:
	if not checkpoint.begins_with("frame"): return
	var path := CENTER_OUTPUT.path_join(facing + "-" + checkpoint + ".png")
	baseline_hashes[path] = FileAccess.get_sha256(path)
	var before := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path)))
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var pivot := Vector2i(actor._workstation_visual.prop_anchor)
		var old_box := CENTERED.mat_bounds(facing)
		old_box.position += pivot
		var new_box := RESTING.resting_mat_bounds()
		new_box.position += pivot
		var crop := Rect2i(pivot + Vector2i(-80, -112), Vector2i(160, 176))
		var changed := 0
		var unrelated := 0
		for y: int in range(crop.position.y, crop.end.y):
			for x: int in range(crop.position.x, crop.end.x):
				unchanged_pixels += 1
				var at := Vector2i(x, y)
				if before.get_pixelv(at) == shot.get_pixelv(at): continue
				changed += 1
				if not old_box.has_point(at) and not new_box.has_point(at): unrelated += 1
		check(unrelated == 0, "Only original/new mat rectangles differ; body/furniture/shadow pixels elsewhere remain exact")
		resting_measurements.append({"employee": id, "checkpoint": checkpoint, "changed_pixels": changed, "unrelated_changes": unrelated})

func capture(owner: Node, facing: String, checkpoint: String) -> void:
	if not rendered: return
	if not filming_transition:
		for tick: int in range(3):
			await process_frame
			frames += 1
	RenderingServer.force_draw(false)
	var shot := PIXELS.rgba(root.get_texture().get_image())
	check(shot.get_size() == Vector2i(1280, 720), "ActualGameMain evidence is native1280x720")
	for id: String in IDS: check_grounded_transform(owner, owner.main.get_employee(id))
	verify_depth(owner, shot, facing, checkpoint)
	# Frozen review annotations, not semantic segmentation or new cutout art.
	# Prove the original board/breadboard rectangles are visible at true size.
	for id: String in IDS:
		var live: Sprite2D = owner.main.room.prop_node(id + "-workstation").get_node("EngineerMat")
		var plate := sprite_data(live)
		for box: Rect2i in [Rect2i(10, 8, 11, 6), Rect2i(10, 1, 12, 5)]:
			var mismatch := 0
			for y: int in range(box.position.y, box.end.y):
				for x: int in range(box.position.x, box.end.x):
					board_region_pixels += 1
					if shot.get_pixelv(plate.origin + Vector2i(x, y)) != plate.image.get_pixel(x, y): mismatch += 1
			check(mismatch == 0, "Original circuit-board and breadboard detail stays fully visible, without resizing")
	baseline_compare(owner, shot, facing, checkpoint)
	var path := checkpoint + ".png"
	check(shot.save_png(REST_OUTPUT.path_join(path)) == OK, "Save resting-kit actual room")
	captures.append(path)
	for person: int in range(2):
		var crop := shot.get_region(Rect2i(256 + person * 448, 160, 160, 176))
		crop.resize(640, 704, Image.INTERPOLATE_NEAREST)
		path = "%s-%s-4x.png" % [IDS[person], checkpoint]
		check(crop.save_png(REST_OUTPUT.path_join(path)) == OK, "Save nearest source-preserving detail")
		captures.append(path)

func film_walk(owner: Node, facing: String, entering: bool, label: Label) -> void:
	var phase := "enter" if entering else "leave"
	var saw_transition := {"mira": false, "theo": false}
	var finished := {"mira": false, "theo": false}
	var paused_once := false
	var captured := 0
	for tick: int in range(650):
		var sample := false
		var all_finished := true
		for id: String in IDS:
			var actor: EmployeeAvatar = owner.main.get_employee(id)
			if not finished[id]:
				var was_transition := actor._seat_transition_active
				actor._physics_process(1.0 / 30.0)
				physics_ticks += 1
				check(actor.navigation.position_is_safe(actor.position, id), "Filmed route never changes physical collision safety")
				check_grounded_transform(owner, actor)
				if actor._seat_transition_active:
					saw_transition[id] = true
					sample = true
				if was_transition and not actor._seat_transition_active: sample = true
				finished[id] = not actor._has_target and not actor._waiting_for_desk and not actor._seat_transition_active
			all_finished = all_finished and finished[id]
		if sample or all_finished:
			label.text = "RESTING TOOLS · %s · actual %s tick %d · no probing action" % [facing.to_upper(), phase, tick]
		await process_frame
		continuous_frames += 1
		if sample or all_finished:
			filming_transition = true
			await capture(owner, facing, "%s-%02d" % [phase, captured])
			filming_transition = false
			for id: String in IDS:
				var actor: EmployeeAvatar = owner.main.get_employee(id)
				transition_states.append({"facing": facing, "employee": id, "phase": phase, "tick": tick,
					"active": actor._seat_transition_active, "feet": [actor.position.x, actor.position.y],
					"seat_render_offset": [actor.seated_render_offset().x, actor.seated_render_offset().y],
					"shadow": [actor._shadow_sprite.global_position.x, actor._shadow_sprite.global_position.y],
					"shadow_depth": actor._shadow_sprite.z_index,
					"image": "%s-%02d.png" % [phase, captured]})
			captured += 1
			if not paused_once and not all_finished:
				for id: String in IDS:
					var actor: EmployeeAvatar = owner.main.get_employee(id)
					actor.world_paused = true
					var before := [actor.position, actor.seated_render_offset(), actor._shadow_sprite.position, actor._seat_transition_elapsed]
					actor._physics_process(0.2)
					check(before == [actor.position, actor.seated_render_offset(), actor._shadow_sprite.position, actor._seat_transition_elapsed], "Pausing mid-interpolation freezes feet/body/shadow together")
					actor.world_paused = false
				paused_once = true
		if all_finished: break
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		check(saw_transition[id] and finished[id], "Entire real mount/leave transition and route were filmed")
		check(actor.position == (actor.desk_position if entering else actor.home_position), "Filmed endpoint retains exact original physical destination")

func run_direction(facing: String) -> bool:
	var owner := RESTING.new()
	owner.employee_ids.assign(IDS)
	owner.initial_facing = facing
	root.add_child(owner)
	await process_frame
	check(owner.ready_ok, "Actual resting fixture passes canonical registration and layout validation")
	if not owner.ready_ok:
		owner.free()
		return false
	for tick: int in range(3): await process_frame
	var main: GameMain = owner.main
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor: EmployeeAvatar in main._employees.values():
		actor.set_physics_process(false)
		actor._label_layer.hide()
		actor._effect_sprite.hide()
	for child: Node in owner.editor.get_children():
		if child is CanvasLayer: child.hide()
	var ui := CanvasLayer.new()
	ui.layer = 100
	owner.add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(176, 112)
	panel.custom_minimum_size = Vector2(800, 40)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 4, 10, 4)))
	ui.add_child(panel)
	var label := Label.new()
	CozyUI.label(label, "meta")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	preflight(owner, facing)
	label.text = "RESTING ENGINEER TOOLS · NORTH · real approach; no probing gesture"
	for id: String in IDS: owner.send_to_desk(id)
	await film_walk(owner, facing, true, label)
	for frame: int in range(6):
		label.text = "RESTING TOOLS · NORTH · frame%d · %s" % [frame, "seated reference" if frame < 2 else "typing stress only, NOT probe use"]
		for id: String in IDS: set_frame(main.get_employee(id), facing, frame)
		await capture(owner, facing, "frame%d" % frame)
	for id: String in IDS: owner.leave_desk(id)
	await film_walk(owner, facing, false, label)
	label.text = "RESTING ENGINEER TOOLS · unchanged source and work cells · no production activation"
	await capture(owner, facing, "returned-home")
	check(not main._worker_ready and not main._state_loaded and main.worker_client is RESTING.NullWorker, "No worker/provider/bootstrap/save transport")
	owner.free()
	await process_frame
	return true

func contacts() -> void:
	for phase: String in ["enter", "leave", "frame"]:
		var sheet := Image.create(960, 352, false, Image.FORMAT_RGBA8)
		for index: int in range(6):
			var name := "frame%d.png" % index if phase == "frame" else "%s-%02d.png" % [phase, index]
			var source := Image.load_from_file(ProjectSettings.globalize_path(REST_OUTPUT.path_join(name)))
			for person: int in range(2): sheet.blit_rect(source, Rect2i(256 + person * 448, 160, 160, 176), Vector2i((index % 3) * 320 + person * 160, int(index / 3) * 176))
		var path := phase + "-all-native.png"
		check(sheet.save_png(REST_OUTPUT.path_join(path)) == OK, "Save native all-six actor comparison")
		captures.append(path)
	var pair := Image.create(640, 352, false, Image.FORMAT_RGBA8)
	for index: int in range(2):
		for variant: int in range(2):
			var path := CENTER_OUTPUT.path_join("north-frame%d.png" % (index * 2)) if variant == 0 else REST_OUTPUT.path_join("frame%d.png" % (index * 2))
			var source := Image.load_from_file(ProjectSettings.globalize_path(path))
			for person: int in range(2): pair.blit_rect(source, Rect2i(256 + person * 448, 160, 160, 176), Vector2i(variant * 320 + person * 160, index * 176))
	check(pair.save_png(REST_OUTPUT.path_join("centered-resting-native.png")) == OK, "Save centered versus resting native comparison")
	captures.append("centered-resting-native.png")
	pair.resize(2560, 1408, Image.INTERPOLATE_NEAREST)
	check(pair.save_png(REST_OUTPUT.path_join("centered-resting-4x.png")) == OK, "Save native-comparison nearest4x")
	captures.append("centered-resting-4x.png")

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REST_OUTPUT))
	await run_direction("north")
	check(physics_ticks > 250 and resting_measurements.size() >= 12, "Full fixture and both six-pose cases finish")
	if rendered: contacts()
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Original mat source/native hashes unchanged")
	for path: String in baseline_hashes: check(FileAccess.get_sha256(path) == baseline_hashes[path], "Centered frozen comparison remains unchanged")
	var result := {"checks": checks, "failures": failures, "captures": captures, "physics_ticks": physics_ticks,
		"continuous_frames": continuous_frames, "capture_hold_frames": frames, "measurements": resting_measurements,
		"observations": observations, "transition_states": transition_states, "mat_depth_pixels": depth_pixels,
		"comparison_pixels": unchanged_pixels, "board_region_pixels": board_region_pixels, "source_sha256": source_hashes, "baseline_sha256": baseline_hashes,
		"production_changed": false, "worker_disabled": true, "art_approved": false}
	var file := FileAccess.open(REST_OUTPUT.path_join("manifest.json" if rendered else "results-headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	print("Resting North engineer: %d checks, %d failures; %d native/evidence images." % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
