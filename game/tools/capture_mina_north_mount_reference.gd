extends SceneTree
## Read-only art reference: actual current movement/seat behavior, not new poses.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const OUTPUT := "res://tests/output/mina-north-mount-reference"
const SOURCES: Array[String] = ["res://assets/runtime/characters/mira-locomotion.png", "res://tests/fixtures/furniture-calibration/characters/mira-north-seated-v2.png", "res://tests/fixtures/furniture-calibration/chair-north-v1.png", "res://actors/employee_avatar.gd", "res://tools/calibrated_workstation_fixture.gd", "res://data/furniture_catalog.json", "res://data/office_layout.json"]
var fixture: Node
var actor: EmployeeAvatar
var checks := 0
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var physics_tick := 0
var chair_anchor := Vector2.ZERO
var desk_anchor := Vector2.ZERO
var saved_cells: Array[Image] = []
var saved_registered: Array[Image] = []
var saved_assemblies: Array[Image] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label_value: String) -> void:
	checks += 1
	if not value:
		failures.append(label_value)
		push_error(label_value)

func rect_value(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func vec(value: Vector2) -> Array[float]:
	return [value.x, value.y]

func digest(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()

func click_button(name_value: String) -> void:
	var button: Button = fixture.editor.action_buttons[name_value]
	var point := button.get_global_rect().get_center()
	var hover := InputEventMouseMotion.new()
	hover.position = point
	hover.global_position = point
	root.push_input(hover, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await process_frame
	fixture.main.set_process(false)
	actor.world_paused = false
	actor.labels_suppressed = true

func step() -> void:
	actor._physics_process(1.0 / 30.0)
	physics_tick += 1
	check(actor.navigation.position_is_safe(actor.position, actor.employee_id), "Physical navigation remains outside blocked cells")
	check(actor.render_position() == actor.render_position().round(), "Source rendering remains pixel-snapped")
	check(actor._character_sprite.scale == Vector2.ONE and not actor._character_sprite.flip_h and not actor._character_sprite.flip_v, "No source stretch or mirrored pose")
	if actor._uses_seated_visual():
		check(actor.position == actor.desk_position and actor.z_index == roundi(desk_anchor.y) + 20, "Seated body stays at real socket and locked North depth")
	else:
		check(actor.z_index == int(actor.position.y), "Locomotion retains physical-foot depth")
	if DisplayServer.get_name() != "headless": await process_frame

func sample(name_value: String) -> void:
	var sprite := actor._character_sprite
	var sheet := sprite.texture.get_image()
	sheet.convert(Image.FORMAT_RGBA8)
	var region := Rect2i(sprite.region_rect)
	var imported_cell := sheet.get_region(region)
	check(region.size == Vector2i(48, 80) and actor._active_work_pose_layers.is_empty(), "North actor-only reference is one exact native48×80 source cell")
	var source_path := SOURCES[1] if actor._uses_seated_visual() else SOURCES[0]
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	source.convert(Image.FORMAT_RGBA8)
	var cell := source.get_region(region)
	var visible_mismatches := 0
	var transparent_rgb_differences := 0
	for y: int in range(80):
		for x: int in range(48):
			var original := cell.get_pixel(x, y)
			var imported := imported_cell.get_pixel(x, y)
			if original.a != imported.a or (original.a > 0.0 and original != imported): visible_mismatches += 1
			elif original != imported: transparent_rgb_differences += 1
	check(visible_mismatches == 0, "Original-source export has identical alpha and every visible runtime pixel; legacy import-only transparent RGB is reported separately")
	var registered := Image.create(96, 112, false, Image.FORMAT_RGBA8)
	var origin := Vector2i(24, 24) + Vector2i(actor.seated_render_offset())
	check(Rect2i(0, 0, 96, 112).encloses(Rect2i(origin, Vector2i(48, 80))), "Registered diagnostic frame contains every source pixel without clipping")
	registered.blit_rect(cell, Rect2i(0, 0, 48, 80), origin)
	check(registered.get_region(Rect2i(origin, Vector2i(48, 80))).get_data() == cell.get_data(), "Registered source translation inverts exactly")
	var ink := cell.get_used_rect()
	var record := {"name": name_value, "physics_tick": physics_tick, "physical_foot": vec(actor.position), "render_foot": vec(actor.render_position()), "render_offset": vec(actor.seated_render_offset()), "desk_anchor": vec(desk_anchor), "chair_anchor": vec(chair_anchor), "work_state": actor.work_state, "walking": actor._has_target, "seat_transition_active": actor._seat_transition_active, "seat_elapsed_ms": actor._seat_transition_elapsed * 1000.0, "source": source_path, "source_region": rect_value(region), "source_ink": rect_value(ink), "world_ink": [actor.render_position().x - 24 + ink.position.x, actor.render_position().y - 72 + ink.position.y, ink.size.x, ink.size.y], "actor_depth": actor.z_index, "chair_depth": roundi(desk_anchor.y) + 21, "source_sha256": digest(cell), "registered_sha256": digest(registered), "legacy_import_zero_alpha_rgb_differences": transparent_rgb_differences}
	if DisplayServer.get_name() != "headless":
		actor.labels_suppressed = true
		fixture.main.job_panel.close_drawer(false)
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var scene := root.get_texture().get_image()
		check(scene.get_size() == Vector2i(1280, 720), "Actual room reference remains native1280×720")
		var crop := Rect2i(Vector2i(desk_anchor) - Vector2i(80, 112), Vector2i(160, 192))
		var assembly := scene.get_region(crop)
		check(scene.save_png(OUTPUT.path_join(name_value + "-room.png")) == OK, "Save actual room " + name_value)
		check(assembly.save_png(OUTPUT.path_join(name_value + "-assembly.png")) == OK, "Save native assembly crop")
		var detail := assembly.duplicate()
		detail.resize(640, 768, Image.INTERPOLATE_NEAREST)
		check(detail.save_png(OUTPUT.path_join(name_value + "-assembly-4x.png")) == OK, "Save nearest assembly detail")
		check(cell.save_png(OUTPUT.path_join(name_value + "-actor48.png")) == OK, "Save native exact actor source")
		check(registered.save_png(OUTPUT.path_join(name_value + "-actor-registered.png")) == OK, "Save source-preserving fixed-physical-foot reference")
		record["scene_sha256"] = digest(scene)
		record["assembly_crop"] = rect_value(crop)
		saved_cells.append(cell)
		saved_registered.append(registered)
		saved_assemblies.append(assembly)
	samples.append(record)

func contacts() -> void:
	if saved_cells.is_empty(): return
	# A compact identity pair for prompting: original north standing idle at
	# left, original current north seated idle at right. Exact source pixels.
	var identity := Image.create(96, 80, false, Image.FORMAT_RGBA8)
	for index: int in range(2):
		var original := Image.load_from_file(ProjectSettings.globalize_path(SOURCES[index]))
		original.convert(Image.FORMAT_RGBA8)
		identity.blit_rect(original, Rect2i(0, 80 if index == 0 else 0, 48, 80), Vector2i(index * 48, 0))
	check(identity.save_png(OUTPUT.path_join("identity-standing-seated-native.png")) == OK, "Save exact-source identity pair")
	identity.resize(384, 320, Image.INTERPOLATE_NEAREST)
	check(identity.save_png(OUTPUT.path_join("identity-standing-seated-4x.png")) == OK, "Save nearest identity comparison")
	for kind: String in ["source", "registered", "assembly"]:
		var cells: Array[Image] = saved_cells if kind == "source" else saved_registered if kind == "registered" else saved_assemblies
		var size := cells[0].get_size()
		var columns := 6
		var rows := ceili(float(cells.size()) / columns)
		var sheet := Image.create(size.x * columns, size.y * rows, false, Image.FORMAT_RGBA8)
		for index: int in range(cells.size()):
			sheet.blit_rect(cells[index], Rect2i(Vector2i.ZERO, size), Vector2i(index % columns * size.x, int(index / columns) * size.y))
		check(sheet.save_png(OUTPUT.path_join(kind + "-contact-native.png")) == OK, "Save unscaled " + kind + " reference contact")
		if kind != "assembly":
			sheet.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
			check(sheet.save_png(OUTPUT.path_join(kind + "-contact-4x.png")) == OK, "Save nearest reference contact")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var hashes := {}
	for path: String in SOURCES: hashes[path] = FileAccess.get_sha256(path)
	fixture = FIXTURE.new()
	fixture.initial_facing = "north"
	fixture.employee_ids.assign(["mira"])
	root.add_child(fixture)
	actor = fixture.main.get_employee("mira")
	actor.set_physics_process(false)
	fixture.main.set_process(false)
	fixture.main.player.set_physics_process(false)
	actor._idle_cooldown = 1000.0
	actor.labels_suppressed = true
	await process_frame
	await process_frame
	fixture.main.job_panel.close_drawer(false)
	check(fixture.ready_ok, "Actual canonical Mina North fixture admits unchanged candidate sources")
	check(not fixture.main._state_loaded and fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1, "No worker process, personal save or bootstrap")
	check(actor._seat_transition_preview and is_equal_approx(actor._seat_transition_duration, 0.14), "Capture actual existing140ms preview, not new mount art")
	desk_anchor = actor._workstation_visual.prop_anchor
	chair_anchor = actor.desk_position + Vector2(0, -12)
	var registry_id: String = fixture.pose_set_id
	await sample("00-walk-start")
	await click_button("Sit")
	check(actor._has_target and actor._arrival_state == EmployeeAvatar.WorkState.SITTING, "Real Sit button creates actual path toward seated arrival")
	var near_index := 0
	for index: int in range(400):
		await step()
		if actor._has_target and actor.position.distance_to(actor.desk_position) <= 22:
			await sample("01-approach-%02d" % near_index)
			near_index += 1
		if not actor._has_target: break
	check(actor.position == actor.desk_position and actor._uses_seated_visual(), "Actual walk reaches the real reserved work foot")
	await sample("02-seat-pose-boundary")
	for index: int in range(5):
		await step()
		await sample("03-seat-%02d" % index)
	check(not actor._seat_transition_active and actor.seated_render_offset() == Vector2(0, -20), "Actual transition reaches existing North candidate offset")
	await sample("04-idle-a")
	for index: int in range(20): await step()
	await sample("04-idle-b")
	await click_button("Leave")
	check(actor._has_target and not actor._uses_seated_visual(), "Real Leave button switches to actual locomotion and a home route")
	await sample("05-leave-pose-boundary")
	for index: int in range(5):
		await step()
		await sample("06-leave-%02d" % index)
	check(not actor._seat_transition_active and actor.seated_render_offset() == Vector2.ZERO, "Current stand transition releases the visual offset while route advances")
	for index: int in range(400):
		if not actor._has_target: break
		await step()
	check(actor.position == actor.home_position and actor.work_state == EmployeeAvatar.WorkState.IDLE, "Actual home route finishes without teleport")
	await sample("07-home")
	contacts()
	fixture.free()
	check(not CharacterArt.is_calibration_pose_set(registry_id), "Reference fixture unregisters candidate poses on teardown")
	for path: String in SOURCES: check(hashes[path] == FileAccess.get_sha256(path), "Reference did not change source/production: " + path)
	var manifest := {"checks": checks, "failures": failures, "samples": samples, "physics_ticks": physics_tick, "source_hashes": hashes, "new_art": false, "runtime_approved": false, "worker_started": false, "actor_cell": [48, 80], "source_pivot": [24, 72], "registered_diagnostic_canvas": [96, 112], "registered_diagnostic_pivot": [48, 96], "current_duration_ms": 140, "sample_order": "Contact sheets follow samples in six columns; no text or guide is baked into actor exports."}
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	print("Mina North mount reference: %d checks, %d failures, %d sampled states, %d physics ticks." % [checks, failures.size(), samples.size(), physics_tick])
	quit(0 if failures.is_empty() else 1)
