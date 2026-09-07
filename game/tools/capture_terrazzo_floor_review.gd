extends "res://tools/capture_native_floor_study.gd"
## DEV ONLY. Reuses the isolated actual GameMain setup; does not overwrite v1 evidence.
const REVIEW_OUTPUT := "res://tests/output/terrazzo-floor-review"
const REVIEW_MATERIALS: Array[String] = ["baseline", "terrazzo-v1", "terrazzo-v2-normalized"]
const V1 := "res://tests/fixtures/material-concepts/overnight-v1/cream-terrazzo-floor-v1.png"
const V2_ROOT := "res://tests/fixtures/material-concepts/terrazzo-v2/"
const V2 := V2_ROOT + "cream-terrazzo-floor-v2-normalized.png"
const V2_ORIGINAL := V2_ROOT + "cream-terrazzo-floor-v2.png"
const SAMPLES: Array[int] = [0, 7, 15, 23, 32, 48, 128]
var movement: Array[Dictionary] = []
var baseline_motion: Dictionary = {}
var saved_environment := ""
var old_physics_rate := 60

func _initialize() -> void:
	saved_environment = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func material_path(id: String) -> String:
	return DEFAULT_FLOOR if id == "baseline" else (V1 if id == "terrazzo-v1" else V2)

func inspect_material(id: String) -> void:
	var path := material_path(id)
	check(ResourceLoader.exists(path), "Real staged floor imported: " + id)
	if not ResourceLoader.exists(path): return
	textures[id] = load(path) as Texture2D
	var image := textures[id].get_image()
	image.convert(Image.FORMAT_RGBA8)
	var original := Image.load_from_file(ProjectSettings.globalize_path(path))
	original.convert(Image.FORMAT_RGBA8)
	check(image.get_size() == Vector2i(128, 128), "Exact native 128×128 plate")
	check(image.get_data() == original.get_data(), "Lossless import exactly preserves native pixels")
	check(image.detect_alpha() == Image.ALPHA_NONE, "No alpha pinholes or transparent checkerboard")
	var colors := {}
	var edges := Vector2i.ZERO
	var luma := 0.0
	for y: int in range(128):
		for x: int in range(128):
			colors[image.get_pixel(x, y).to_rgba32()] = true
			luma += luminance(image.get_pixel(x, y))
		if image.get_pixel(0, y) != image.get_pixel(127, y): edges.x += 1
		if image.get_pixel(y, 0) != image.get_pixel(y, 127): edges.y += 1
	if id != "baseline": check(colors.size() <= 12, "Staged native bounded palette remains at most 12 colors")
	if id != "terrazzo-v1": check(edges == Vector2i.ZERO, "Unchanged exact opposite-edge floor contract passes")
	materials[id] = {"path": path, "size": [128, 128], "palette_colors": colors.size(), "mean_luminance": luma / 16384.0, "edge_mismatch_x": edges.x, "edge_mismatch_y": edges.y, "sha256": FileAccess.get_sha256(path), "approved": id == "baseline"}
	source_hashes[path] = FileAccess.get_sha256(path)

func verify_normalization() -> void:
	var before := Image.load_from_file(ProjectSettings.globalize_path(V2_ORIGINAL))
	var after := Image.load_from_file(ProjectSettings.globalize_path(V2))
	var changed := 0
	var incorrect := 0
	for y: int in range(128):
		for x: int in range(128):
			var a := before.get_pixel(x, y)
			var b := after.get_pixel(x, y)
			if a == b: continue
			changed += 1
			if a != Color("ebe4d5") or b != Color("eae4d7"): incorrect += 1
	check(changed == 10536 and incorrect == 0, "Only the 10,536 globally merged cream pixels change; no edge painting")
	materials["normalization"] = {"changed_pixels": changed, "unexpected_changes": incorrect, "mapping": "#EBE4D5 → #EAE4D7", "before": V2_ORIGINAL, "after": V2}

func capture_review(id: String, stage: int, view: String, baseline: Image = null) -> Image:
	var key := "%s-hires-%d-%s" % [id, stage, view]
	var entry := {"name": key, "material": id, "stage": stage, "view": view, "actor_contrast": body_contrast(textures[id].get_image())}
	if DisplayServer.get_name() == "headless":
		captures.append(entry)
		return null
	await frames(2)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == VIEWPORT, "Native 1280×720 evidence: " + key)
	var floor_image := textures[id].get_image()
	var wrong := 0
	# Clear aisle independent of staged actors; spans 32-cell and 128-plate edges.
	for y: int in range(112, 145):
		for x: int in range(416, 705):
			var local := Vector2i(x, y) - Vector2i(main.room.architecture.global_position)
			if color_delta(image.get_pixel(x, y), floor_image.get_pixel(posmod(local.x, 128), posmod(local.y, 128))) > 0.015: wrong += 1
			pixel_checks += 1
	check(wrong == 0, "Native floor samples match the actual plate across grid/repeat seams: " + key)
	if baseline != null:
		var outside_changed := 0
		for y: int in range(VIEWPORT.y):
			for x: int in range(VIEWPORT.x):
				var cell := Vector2i((Vector2(x, y) - main.room.architecture.global_position) / 32.0)
				if main.room.layout_model.is_floor(cell): continue
				if image.get_pixel(x, y) != baseline.get_pixel(x, y): outside_changed += 1
				pixel_checks += 1
		check(outside_changed == 0, "No architecture pixels outside the floor changed: " + key)
		for rect: Rect2i in [Rect2i(390, 18, 370, 45), Rect2i(1176, 30, 77, 24), Rect2i(1170, 674, 84, 20)]:
			check(image.get_region(rect).get_data() == baseline.get_region(rect).get_data(), "HUD and rail remain byte-identical: " + key)
		if view == "chat": check(image.get_region(Rect2i(820, 210, 280, 350)).get_data() == baseline.get_region(Rect2i(820, 210, 280, 350)).get_data(), "Chat paper and body ink are unchanged: " + key)
	var path := REVIEW_OUTPUT.path_join(key + ".png")
	check(image.save_png(path) == OK, "Write native room: " + key)
	entry["path"] = path
	entry["sha256"] = FileAccess.get_sha256(path)
	captures.append(entry)
	images[key] = image
	return image

func review_contact(stage: int, view: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var sheet := Image.create(1920, 360, false, Image.FORMAT_RGBA8)
	for index: int in range(3):
		var thumb := images["%s-hires-%d-%s" % [REVIEW_MATERIALS[index], stage, view]].duplicate() as Image
		thumb.resize(640, 360, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(thumb, Rect2i(0, 0, 640, 360), Vector2i(index * 640, 0))
	check(sheet.save_png(REVIEW_OUTPUT.path_join("comparison-hires-%d-%s.png" % [stage, view])) == OK, "Save nearest half-size overview; native evidence remains separate")

func movement_actor(id: String) -> Node2D:
	return main.player if id == "founder" else main.get_employee(id)

func prepare_walk() -> void:
	main.job_panel.close_drawer(false)
	main.player.input_blocked = false
	for index: int in range(3):
		var id: String = ["founder", "mira", "theo"][index]
		var actor := movement_actor(id)
		actor.position = Vector2(432, 368 + index * 96)
		main.room.navigation.actors[id] = actor.position
		if actor is EmployeeAvatar:
			actor.world_paused = false
			actor.labels_suppressed = true
			actor._idle_cooldown = 1000.0
			actor._animation_elapsed = 0.0
			actor._update_character_frame()
		else:
			actor._animation_elapsed = 0.0
			actor.face_direction(Vector2.RIGHT)
			actor._character_sprite.position = Vector2(0, -32)
			actor._shadow_sprite.position = Vector2(0, -2)
		actor.z_index = int(actor.position.y)
	# Founder starts from a real world click. Employees use the existing scheduled
	# walk path API; they are not teleported along the route or given fake frames.
	var target := Vector2(624, 368)
	var motion := InputEventMouseMotion.new()
	motion.position = target
	motion.global_position = target
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = target
		event.global_position = target
		root.push_input(event, true)
	check(not main.player.route.is_empty(), "Real world click starts founder route")
	for index: int in range(2):
		var employee := main.get_employee(["mira", "theo"][index])
		employee.walk_to(Vector2(624, 464 + index * 96), EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
		check(employee._has_target, "Actual employee path starts across native floor repeats")

func walk_sample(id: String, tick: int) -> void:
	var state := {}
	for actor_id: String in ["founder", "mira", "theo"]:
		var actor := movement_actor(actor_id)
		var sprite := actor.get_node("CharacterSprite") as Sprite2D
		var shadow := actor.get_node("PixelShadow") as Sprite2D
		check(sprite.global_position == sprite.global_position.round() and shadow.global_position == shadow.global_position.round(), "Moving actor and shadow render at integer positions")
		check(sprite.scale == Vector2.ONE and shadow.scale == Vector2.ONE and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Moving source artwork stays native nearest 1×")
		state[actor_id] = {"physical": str(actor.position), "body_origin": str(sprite.global_position), "body_region": str(sprite.region_rect), "shadow_origin": str(shadow.global_position), "shadow_region": str(shadow.region_rect)}
	if id == "baseline": baseline_motion[tick] = state.duplicate(true)
	else: check(state == baseline_motion[tick], "Identical sampled actor paths/frames/shadows across floor materials")
	movement.append({"material": id, "tick": tick, "actors": state})
	var image := await capture_review(id, 2, "walk-%03d" % tick)
	if image == null: return
	var strip := Image.create(288, 112, false, Image.FORMAT_RGBA8)
	for index: int in range(3):
		var actor := movement_actor(["founder", "mira", "theo"][index])
		var crop := image.get_region(Rect2i(Vector2i(actor.position.round()) - Vector2i(48, 88), Vector2i(96, 112)))
		strip.blit_rect(crop, Rect2i(0, 0, 96, 112), Vector2i(index * 96, 0))
	check(strip.save_png(REVIEW_OUTPUT.path_join("%s-walk-%03d-actors-native.png" % [id, tick])) == OK, "Save native moving feet/shadow detail")
	strip.resize(1152, 448, Image.INTERPOLATE_NEAREST)
	check(strip.save_png(REVIEW_OUTPUT.path_join("%s-walk-%03d-actors-4x.png" % [id, tick])) == OK, "Save nearest detail without re-exporting actor art")

func run_walk(id: String) -> void:
	await make_main(2)
	main.room.architecture.floor_art = textures[id]
	main.room.architecture.queue_redraw()
	prepare_walk()
	await walk_sample(id, 0)
	for tick: int in range(1, 129):
		main.player._physics_process(1.0 / 30.0)
		main.click_feedback._process(1.0 / 30.0)
		for actor: EmployeeAvatar in main._employees.values(): actor._physics_process(1.0 / 30.0)
		for actor_id: String in ["founder", "mira", "theo"]:
			var actor := movement_actor(actor_id)
			check(main.room.navigation.position_is_safe(actor.position, actor_id), "Every live movement step remains in walkable geometry")
		if DisplayServer.get_name() != "headless": await process_frame
		if tick in SAMPLES: await walk_sample(id, tick)
	for index: int in range(3):
		var actor_id: String = ["founder", "mira", "theo"][index]
		var actor := movement_actor(actor_id)
		check(actor.position == Vector2(624, 368 + index * 96), "Actual path ends beyond the 512px repeat boundary without repositioning")
		var poses := {}
		var positions := {}
		for item: Dictionary in movement:
			if item.material != id: continue
			poses[item.actors[actor_id].body_region] = true
			positions[item.actors[actor_id].physical] = true
		check(poses.size() >= 3 and positions.size() >= 3, "Sampled actual locomotion has distinct source cells and positions, not a sliding still")
	check(main.click_feedback.remaining == 0.0, "Actual click feedback expires; fixture freeze cannot leave a stale destination marker")
	main.free()
	await frames(2)

func run() -> void:
	old_physics_rate = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 30
	root.size = VIEWPORT
	root.content_scale_size = VIEWPORT
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_OUTPUT))
	for path: String in [DEFAULT_FLOOR, OfficeLayout.DEFAULT_PATH, OfficeLayout.DEFAULT_CATALOG_PATH, V2_ORIGINAL, SOURCE + "cream-terrazzo-floor-v2.png", "res://world/office_architecture.gd"]: source_hashes[path] = FileAccess.get_sha256(path)
	for id: String in REVIEW_MATERIALS: inspect_material(id)
	if textures.size() == 3:
		verify_normalization()
		for stage: int in STAGES:
			await make_main(stage)
			var original := signature()
			var baseline: Image
			for id: String in REVIEW_MATERIALS:
				main.room.architecture.floor_art = textures[id]
				main.room.architecture.queue_redraw()
				check(signature() == original, "Material override leaves actual geometry, actors and navigation unchanged")
				var image := await capture_review(id, stage, "office", baseline)
				if id == "baseline": baseline = image
			review_contact(stage, "office")
			if stage == 2:
				main.job_panel.select_employee("mira")
				main.job_panel.open_drawer(false)
				main.job_panel.show_chat_history("mira", [{"sender": "player", "content": "Can we make our first useful website?"}, {"sender": "employee", "content": "Let's start with one clear offer and a page customers can understand."}])
				main._update_label_visibility("")
				await frames(6)
				baseline = null
				for id: String in REVIEW_MATERIALS:
					main.room.architecture.floor_art = textures[id]
					main.room.architecture.queue_redraw()
					check(signature() == original, "Chat cannot alter actors or navigation during floor comparison")
					var image := await capture_review(id, stage, "chat", baseline)
					if id == "baseline": baseline = image
				review_contact(stage, "chat")
			main.free()
			await frames(2)
		for id: String in REVIEW_MATERIALS: await run_walk(id)
	for path: String in source_hashes: check(source_hashes[path] == FileAccess.get_sha256(path), "Preserved source and production hash: " + path)
	finish()

func finish() -> void:
	var headless := DisplayServer.get_name() == "headless"
	var result := {"checks": checks, "failures": failures, "pixel_checks": pixel_checks, "materials": materials, "captures": captures, "movement": movement, "source_hashes": source_hashes, "runtime_approved": false, "worker_started": false, "personal_save_access": false, "production_changed": false, "limitations": ["Disposable actual GameMain fixtures; only floor_art changes.", "Native captures are 1280×720; half-size overviews are not readability evidence.", "Actual production walk methods advance fixed30Hz along real navigation routes; scene physics is disabled between deterministic steps.", "No seated calibration shadows or other new production features are enabled.", "Stage4 means mature office furniture with the supported two-person roster."]}
	var file := FileAccess.open(REVIEW_OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	Engine.physics_ticks_per_second = old_physics_rate
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", saved_environment)
	print("Terrazzo native review: %d checks, %d failures, %d pixel checks, %d states" % [checks, failures.size(), pixel_checks, captures.size()])
	quit(0 if failures.is_empty() else 1)
