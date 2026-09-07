extends "res://tools/capture_engineer_mat_composition.gd"
## Second policy evidence; preserves both earlier comparison baselines.
const GROUNDED_FIXTURE := preload("res://tools/horizontal_grounded_mat_fixture.gd")
const CORRECTED_OUTPUT := "res://tests/output/grounded-shadow-x-follow"
const FROZEN_BASELINE := "res://tests/output/grounded-work-shadow"
var baseline_hashes: Dictionary = {}
var comparison_pixels := 0
var shadow_floor_pixels := 0
var grounded_observations: Array[Dictionary] = []
var transition_states: Array[Dictionary] = []
var continuous_frames := 0
var filming_transition := false
var physics_ticks := 0

func check_grounded_transform(owner: Node, actor: EmployeeAvatar) -> void:
	check(actor._shadow_sprite.visible, "Correction retains the real visible shadow node")
	check(actor._shadow_sprite.texture == PolishArt.CHARACTER_SHADOWS, "Original source/alpha retained")
	var seated := actor._uses_seated_visual() or actor._seat_transition_active
	var x := actor.seated_render_offset().x if seated else 0.0
	check(actor._shadow_sprite.global_position == actor.position.round() + Vector2(x, -2), "Shadow follows native seated X and retains physical-floor Y")
	if actor._uses_seated_visual() or actor._seat_transition_active:
		var prop: Node2D = owner.main.room.prop_node(actor.employee_id + "-workstation")
		for child: Node in prop.get_children():
			if child is Sprite2D: check(actor._shadow_sprite.z_index < child.z_index, "Ground shadow stays below every own native furniture layer")
	else:
		check(actor._shadow_sprite.z_index == int(actor.position.y), "Standing shadow returns to physical floor depth")

func baseline_compare(owner: Node, shot: Image, facing: String, checkpoint: String) -> void:
	if not checkpoint.begins_with("frame"): return
	var path := FROZEN_BASELINE.path_join(facing + "-" + checkpoint + ".png")
	check(FileAccess.file_exists(path), "Frozen native baseline exists")
	baseline_hashes[path] = FileAccess.get_sha256(path)
	var before := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path)))
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var new_shadow := sprite_data(actor._shadow_sprite)
		var old_box := Rect2i(new_shadow.origin - Vector2i(roundi(actor.seated_render_offset().x), 0), new_shadow.image.get_size())
		var new_box := Rect2i(new_shadow.origin, new_shadow.image.get_size())
		var pivot := Vector2i(actor._workstation_visual.prop_anchor)
		var crop := Rect2i(pivot + Vector2i(-80, -112), Vector2i(160, 176))
		var changed := 0
		var unrelated := 0
		var mat_changed := 0
		var mat := GROUNDED_FIXTURE.mat_bounds(facing)
		mat.position += pivot
		for y: int in range(crop.position.y, crop.end.y):
			for x: int in range(crop.position.x, crop.end.x):
				comparison_pixels += 1
				var at := Vector2i(x, y)
				if before.get_pixelv(at) == shot.get_pixelv(at): continue
				changed += 1
				if not old_box.has_point(at) and not new_box.has_point(at): unrelated += 1
				if mat.has_point(at): mat_changed += 1
		check(unrelated == 0, "Before/after source/art/body pixels outside shadow regions remain exact")
		check(mat_changed == 0, "Horizontal correction cannot change a single tabletop pixel")
		if facing in ["north", "south"]: check(changed == 0, "N/S zero-X views remain byte-exact against first grounded policy")
		grounded_observations.append({"facing": facing, "employee": id, "checkpoint": checkpoint,
			"before_after_changed_pixels": changed, "unrelated_pixel_changes": unrelated,
			"mat_changed_pixels": mat_changed, "old_shadow_rect": PIXELS.rect_values(old_box), "new_shadow_rect": PIXELS.rect_values(new_box)})

func floor_visibility(owner: Node, shot: Image, facing: String, checkpoint: String) -> void:
	# Isolated dev readback only: compare the same frozen frame with the shadow
	# omitted to prove which real floor pixels it actually affects. The saved
	# corrected scene always includes both visible, original shadow sprites.
	for id: String in IDS: owner.main.get_employee(id)._shadow_sprite.hide()
	await process_frame
	frames += 1
	RenderingServer.force_draw(false)
	var background := PIXELS.rgba(root.get_texture().get_image())
	for id: String in IDS: owner.main.get_employee(id)._shadow_sprite.show()
	await process_frame
	frames += 1
	RenderingServer.force_draw(false)
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var shadow := sprite_data(actor._shadow_sprite)
		var visible_count := 0
		var wrong_blend := 0
		for y: int in range(shadow.image.get_height()):
			for x: int in range(shadow.image.get_width()):
				var at: Vector2i = shadow.origin + Vector2i(x, y)
				var actual := shot.get_pixelv(at)
				var under := background.get_pixelv(at)
				if actual == under: continue # Furniture/body naturally occludes it.
				visible_count += 1
				shadow_floor_pixels += 1
				var expected := under.blend(shadow.image.get_pixel(x, y))
				if absf(expected.r - actual.r) > 1.01 / 255.0 or absf(expected.g - actual.g) > 1.01 / 255.0 or absf(expected.b - actual.b) > 1.01 / 255.0: wrong_blend += 1
		check(wrong_blend == 0, "Native visible ground-shadow pixels match original alpha over real background")
		if facing in ["east", "west"] or checkpoint == "returned-idle": check(visible_count > 0, "Shadow is actually visible on unobstructed floor, not hidden to make a test pass")
		grounded_observations.append({"facing": facing, "employee": id, "checkpoint": checkpoint, "native_visible_ground_shadow_pixels": visible_count, "original_alpha_blend_mismatches": wrong_blend})

func capture(owner: Node, facing: String, checkpoint: String) -> void:
	if not filming_transition:
		for tick: int in range(3):
			await process_frame
			frames += 1
	RenderingServer.force_draw(false)
	var shot := PIXELS.rgba(root.get_texture().get_image())
	check(shot.get_size() == Vector2i(1280, 720), "Correction evidence stays native1280x720")
	for id: String in IDS: check_grounded_transform(owner, owner.main.get_employee(id))
	verify_depth(owner, shot, facing, checkpoint)
	baseline_compare(owner, shot, facing, checkpoint)
	var path := facing + "-" + checkpoint + ".png"
	check(shot.save_png(CORRECTED_OUTPUT.path_join(path)) == OK, "Save corrected native scene")
	captures.append(path)
	for id: String in IDS:
		var actor: EmployeeAvatar = owner.main.get_employee(id)
		var pivot := Vector2i(actor._workstation_visual.prop_anchor)
		var image := shot.get_region(Rect2i(pivot + Vector2i(-80, -112), Vector2i(160, 176)))
		image.resize(640, 704, Image.INTERPOLATE_NEAREST)
		path = "%s-%s-%s-4x.png" % [facing, id, checkpoint]
		check(image.save_png(CORRECTED_OUTPUT.path_join(path)) == OK, "Save nearest shadow detail")
		captures.append(path)
	if not filming_transition: await floor_visibility(owner, shot, facing, checkpoint)

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
			label.text = "SHADOW X + FLOOR Y · %s · actual %s tick %d" % [facing.to_upper(), phase, tick]
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
					"image": "%s-%s-%02d.png" % [facing, phase, captured]})
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
	var owner := GROUNDED_FIXTURE.new()
	owner.employee_ids.assign(IDS)
	owner.initial_facing = facing
	root.add_child(owner)
	await process_frame
	check(owner.ready_ok, "Corrected actual GameMain fixture validates " + facing)
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
	var paper := PanelContainer.new()
	paper.position = Vector2(176, 112)
	paper.custom_minimum_size = Vector2(800, 40)
	paper.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 4, 10, 4)))
	ui.add_child(paper)
	var label := Label.new()
	CozyUI.label(label, "meta")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paper.add_child(label)
	preflight(owner, facing)
	label.text = "SHADOW X + FLOOR Y · %s · real walk and enter interpolation" % facing.to_upper()
	for id: String in IDS: owner.send_to_desk(id)
	await film_walk(owner, facing, true, label)
	for frame: int in range(6):
		label.text = "SHADOW X + FLOOR Y · %s · frame%d · art/poses unchanged; mat still unapproved" % [facing.to_upper(), frame]
		for id: String in IDS: set_frame(main.get_employee(id), facing, frame)
		await capture(owner, facing, "frame%d" % frame)
	label.text = "SHADOW X + FLOOR Y · %s · paused at the same physical feet" % facing.to_upper()
	for id: String in IDS:
		var actor: EmployeeAvatar = main.get_employee(id)
		actor.world_paused = true
		actor._physics_process(0.1)
	await capture(owner, facing, "paused")
	label.text = "SHADOW X + FLOOR Y · %s · real leave interpolation and return path" % facing.to_upper()
	for id: String in IDS:
		main.get_employee(id).world_paused = false
		owner.leave_desk(id)
	await film_walk(owner, facing, false, label)
	label.text = "SHADOW X + FLOOR Y · %s · ordinary standing floor shadow restored" % facing.to_upper()
	await capture(owner, facing, "returned-idle")
	var scope: String = owner.pose_set_id
	check(not main._worker_ready and not main._state_loaded and main.worker_client is GROUNDED_FIXTURE.NullWorker, "No worker/bootstrap/save during correction evidence")
	owner.free()
	await process_frame
	check(not CharacterArt.is_calibration_pose_set(scope), "Corrected fixture capability revoked on teardown")
	return true

func contacts() -> void:
	var all_four := Image.create(640, 352, false, Image.FORMAT_RGBA8)
	for index: int in range(4):
		var direction := DIRECTIONS[index]
		var sheet := Image.create(960, 352, false, Image.FORMAT_RGBA8)
		for frame: int in range(6):
			var full := Image.load_from_file(ProjectSettings.globalize_path(CORRECTED_OUTPUT.path_join("%s-frame%d.png" % [direction, frame])))
			for person: int in range(2):
				var source := Rect2i(256 + person * 448, 160, 160, 176)
				sheet.blit_rect(full, source, Vector2i((frame % 3) * 320 + person * 160, int(frame / 3) * 176))
				if frame == 0: all_four.blit_rect(full, source, Vector2i(index * 160, person * 176))
		var path := direction + "-all-six-native.png"
		check(sheet.save_png(CORRECTED_OUTPUT.path_join(path)) == OK, "Save native all-six correction contact")
		captures.append(path)
	check(all_four.save_png(CORRECTED_OUTPUT.path_join("all-four-native.png")) == OK, "Save all-four correction contact")
	captures.append("all-four-native.png")
	for direction: String in DIRECTIONS:
		for phase: String in ["enter", "leave"]:
			var sequence := Image.create(960, 352, false, Image.FORMAT_RGBA8)
			for index: int in range(6):
				var source := Image.load_from_file(ProjectSettings.globalize_path(CORRECTED_OUTPUT.path_join("%s-%s-%02d.png" % [direction, phase, index])))
				for person: int in range(2):
					sequence.blit_rect(source, Rect2i(256 + person * 448, 160, 160, 176), Vector2i((index % 3) * 320 + person * 160, int(index / 3) * 176))
			var path := "%s-%s-native.png" % [direction, phase]
			check(sequence.save_png(CORRECTED_OUTPUT.path_join(path)) == OK, "Save every transition interpolation sample at native size")
			captures.append(path)
	for direction: String in ["east", "west"]:
		var comparison := Image.create(640, 352, false, Image.FORMAT_RGBA8)
		for frame: int in [0, 2]:
			for variant: int in range(2):
				var folder := FROZEN_BASELINE if variant == 0 else CORRECTED_OUTPUT
				var source := Image.load_from_file(ProjectSettings.globalize_path(folder.path_join("%s-frame%d.png" % [direction, frame])))
				for person: int in range(2): comparison.blit_rect(source, Rect2i(256 + person * 448, 160, 160, 176), Vector2i(variant * 320 + person * 160, (frame / 2) * 176))
		var path := direction + "-before-after-native.png"
		check(comparison.save_png(CORRECTED_OUTPUT.path_join(path)) == OK, "Save first-policy versus X-follow native comparison")
		captures.append(path)
		comparison.resize(2560, 1408, Image.INTERPOLATE_NEAREST)
		path = direction + "-before-after-4x.png"
		check(comparison.save_png(CORRECTED_OUTPUT.path_join(path)) == OK, "Save nearest X-follow comparison")
		captures.append(path)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use test_grounded_shadow_x_follow.gd for headless validation; this script requires native readback.")
		quit(1)
		return
	rendered = true
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CORRECTED_OUTPUT))
	for direction: String in DIRECTIONS: await run_direction(direction)
	contacts()
	for path: String in baseline_hashes: check(FileAccess.get_sha256(path) == baseline_hashes[path], "Frozen first-policy capture remains byte-identical")
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Original source/native art remains byte-identical")
	var file := FileAccess.open(CORRECTED_OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "capture_settle_frames": frames, "continuous_frames": continuous_frames, "physics_ticks": physics_ticks,
		"transition_states": transition_states,
		"mat_depth_pixels": depth_pixels, "before_after_comparison_pixels": comparison_pixels, "actual_visible_shadow_pixels": shadow_floor_pixels,
		"observations": observations, "grounded_observations": grounded_observations,
		"baseline_sha256": baseline_hashes, "source_sha256": source_hashes,
		"production_profiles_changed": false, "worker_disabled": true, "runtime_art_approved": false,
		"floor_visibility_proof": "Saved scenes always show real shadows; a temporary dev-only hidden-shadow readback provides exact background for original-alpha blend verification."}, "\t"))
	print("Horizontal grounded shadow native: %d checks, %d failures; %d captures; %d actual visible floor-shadow pixels." % [checks, failures.size(), captures.size(), shadow_floor_pixels])
	quit(0 if failures.is_empty() else 1)
