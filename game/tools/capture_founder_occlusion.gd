extends SceneTree
## DEV ONLY: real-click regression for a founder hiding another world object.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
const OUTPUT := "res://tests/output/founder-occlusion/"
var main: GameMain
var checks := 0
var failures: Array[String] = []
var records: Array[Dictionary] = []
var fixed := false

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	fixed = not OS.get_cmdline_user_args().has("--expect-old")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for tick: int in range(count): await process_frame

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await frames(1)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await frames(1)

func setup() -> void:
	main = load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(FIXTURE.NullWorker)
	root.add_child(main)
	main.game_audio.set_volumes(0, 0)
	await frames(3)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.day_clock.set_speed(0)
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main.founder_hud.dismiss_movement_hint()
	main.room.set_hire_count(4)
	for actor: EmployeeAvatar in main._employees.values(): actor.set_physics_process(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Worker is blocked")

func run_case(kind: String) -> void:
	await setup()
	var mina := main.get_employee("mira")
	mina._route.clear()
	mina._has_target = false
	mina.has_live_job = false
	if kind == "station":
		mina.position = mina.desk_position
		mina.work_state = EmployeeAvatar.WorkState.SITTING
		main.player.position = Vector2(336, 304)
	else:
		mina.position = Vector2(464, 432)
		mina.work_state = EmployeeAvatar.WorkState.IDLE
		main.player.position = Vector2(464, 400 if kind == "employee-behind" else 464)
	mina._animation_elapsed = 0
	mina._update_character_frame()
	main.player.face_direction(Vector2.DOWN)
	main.player._physics_process(0)
	main._process(0)
	await frames()
	var founder := main.player._character_sprite
	var point := Vector2.INF
	var wanted := "mira-workstation" if kind == "station" else "mira"
	var behind := kind == "employee-behind"
	var bounds := Rect2i(main.player.position + Vector2(-24, -72), Vector2(48, 80))
	for y: int in range(bounds.position.y, bounds.end.y, 2):
		for x: int in range(bounds.position.x, bounds.end.x, 2):
			var candidate := Vector2(x, y)
			if not VisibleSurface.painted(founder, candidate): continue
			var under: Sprite2D = main.room.surface_at(candidate).get("sprite") if kind == "station" else mina.body_surface_at(candidate)
			if under == null or VisibleSurface.in_front(founder, under) == behind: continue
			if kind == "station" and main.room.interaction_at(candidate).get("id") != wanted: continue
			point = candidate
			break
		if point.is_finite(): break
	check(point.is_finite(), kind + " has an actual opaque body overlap at the tested depth")
	if point.is_finite():
		var expected := "" if fixed and not behind else wanted
		check(str(main._interaction_at(point).get("id", "")) == expected, kind + " exact owner before actual input")
		if fixed:
			check(main.player.body_surface_at(point) == founder, kind + " exposes actual founder body only")
			founder.hide()
			check(main.player.body_surface_at(point) == null, "Hidden founder is not an occluder")
			check(str(main._interaction_at(point).get("id", "")) == wanted, "Hidden founder leaves underlying target available")
			founder.show()
			founder.self_modulate.a = 0.0
			check(main.player.body_surface_at(point) == null, "Transparent founder modulation is not an occluder")
			check(str(main._interaction_at(point).get("id", "")) == wanted, "Transparent founder leaves underlying target available")
			founder.self_modulate.a = 1.0
		main.player.cancel_route()
		await click(point)
		check(main._pending_interaction == expected, kind + " actual mouse dispatch obeys visible owner")
		var record := {"case": kind, "point": [point.x, point.y], "founder_feet": [main.player.position.x, main.player.position.y], "target": main._pending_interaction, "expected": expected, "founder_depth": VisibleSurface.depth(founder)}
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)
			await RenderingServer.frame_post_draw
			var screen := root.get_texture().get_image()
			var visible_body: Sprite2D = mina._character_sprite if behind else founder
			var source := visible_body.texture.get_image()
			var pixel := Vector2i(visible_body.to_local(point) - visible_body.get_rect().position + visible_body.region_rect.position)
			check(screen.get_pixelv(Vector2i(point)).is_equal_approx(source.get_pixelv(pixel)), kind + " chosen native pixel really belongs to the visible body")
			var filename := ("after-" if fixed else "before-") + kind + ".png"
			check(screen.save_png(OUTPUT + filename) == OK, "Save " + filename)
			record["capture"] = filename
		records.append(record)
	main.game_audio.shutdown()
	main.free()
	await frames()

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for kind: String in ["station", "employee", "employee-behind"]: await run_case(kind)
	var result := {"checks": checks, "failures": failures, "records": records, "fixed": fixed, "worker_started": false}
	var suffix := "-headless.json" if DisplayServer.get_name() == "headless" else "-native.json"
	var file := FileAccess.open(OUTPUT + ("after" if fixed else "before") + suffix, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	print("Founder occlusion: %d checks, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
