extends "res://tools/capture_engineer_mat_composition.gd"
## Separate correction evidence; never overwrites the frozen engineer baseline.
const GROUNDED_FIXTURE := preload("res://tools/grounded_engineer_mat_fixture.gd")
const CORRECTED_OUTPUT := "res://tests/output/grounded-work-shadow"
const FROZEN_BASELINE := "res://tests/output/engineer-mat-composition"
var baseline_hashes: Dictionary = {}
var comparison_pixels := 0
var shadow_floor_pixels := 0
var grounded_observations: Array[Dictionary] = []

func check_grounded_transform(owner: Node, actor: EmployeeAvatar) -> void:
	check(actor._shadow_sprite.visible, "Correction retains the real visible shadow node")
	check(actor._shadow_sprite.texture == PolishArt.CHARACTER_SHADOWS, "Original source/alpha retained")
	check(actor._shadow_sprite.global_position == actor.position.round() + Vector2(0, -2), "Native ground origin is physical feet, independent of seat lift")
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
		var old_box := Rect2i(new_shadow.origin + Vector2i(actor.seated_render_offset()), new_shadow.image.get_size())
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
		if facing == "south": check(mat_changed == 47, "Exactly47 former tabletop shadow pixels corrected, with no mat/body repaint")
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
	await floor_visibility(owner, shot, facing, checkpoint)

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
	for id: String in IDS:
		owner.send_to_desk(id)
		walk(main.get_employee(id), true)
	for frame: int in range(6):
		label.text = "GROUNDED SHADOW · %s · frame%d · art/poses unchanged; mat still unapproved" % [facing.to_upper(), frame]
		for id: String in IDS: set_frame(main.get_employee(id), facing, frame)
		await capture(owner, facing, "frame%d" % frame)
	label.text = "GROUNDED SHADOW · %s · paused at the same physical feet" % facing.to_upper()
	for id: String in IDS:
		var actor: EmployeeAvatar = main.get_employee(id)
		actor.world_paused = true
		actor._physics_process(0.1)
	await capture(owner, facing, "paused")
	for id: String in IDS:
		var actor: EmployeeAvatar = main.get_employee(id)
		actor.world_paused = false
		owner.leave_desk(id)
		actor._physics_process(1.0 / 30.0)
		check(actor._seat_transition_active, "Native departure samples actual first interpolation frame")
	label.text = "GROUNDED SHADOW · %s · actual leave-seat interpolation" % facing.to_upper()
	await capture(owner, facing, "leave-transition")
	for id: String in IDS: walk(main.get_employee(id), false)
	label.text = "GROUNDED SHADOW · %s · ordinary standing floor shadow restored" % facing.to_upper()
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
	var comparison := Image.create(640, 352, false, Image.FORMAT_RGBA8)
	for frame: int in [0, 2]:
		for variant: int in range(2):
			var folder := FROZEN_BASELINE if variant == 0 else CORRECTED_OUTPUT
			var source := Image.load_from_file(ProjectSettings.globalize_path(folder.path_join("south-frame%d.png" % frame)))
			for person: int in range(2): comparison.blit_rect(source, Rect2i(256 + person * 448, 160, 160, 176), Vector2i(variant * 320 + person * 160, (frame / 2) * 176))
	check(comparison.save_png(CORRECTED_OUTPUT.path_join("south-before-after-native.png")) == OK, "Save frozen South baseline beside exact correction")
	captures.append("south-before-after-native.png")
	comparison.resize(2560, 1408, Image.INTERPOLATE_NEAREST)
	check(comparison.save_png(CORRECTED_OUTPUT.path_join("south-before-after-4x.png")) == OK, "Save nearest South correction comparison")
	captures.append("south-before-after-4x.png")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use test_grounded_work_shadow.gd for headless validation; this script requires native readback.")
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
	for path: String in baseline_hashes: check(FileAccess.get_sha256(path) == baseline_hashes[path], "Frozen original engineer capture remains byte-identical")
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Original source/native art remains byte-identical")
	var file := FileAccess.open(CORRECTED_OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "capture_settle_frames": frames,
		"mat_depth_pixels": depth_pixels, "before_after_comparison_pixels": comparison_pixels, "actual_visible_shadow_pixels": shadow_floor_pixels,
		"observations": observations, "grounded_observations": grounded_observations,
		"baseline_sha256": baseline_hashes, "source_sha256": source_hashes,
		"production_profiles_changed": false, "worker_disabled": true, "runtime_art_approved": false,
		"floor_visibility_proof": "Saved scenes always show real shadows; a temporary dev-only hidden-shadow readback provides exact background for original-alpha blend verification."}, "\t"))
	print("Grounded shadow native: %d checks, %d failures; %d captures; %d actual visible floor-shadow pixels." % [checks, failures.size(), captures.size(), shadow_floor_pixels])
	quit(0 if failures.is_empty() else 1)
