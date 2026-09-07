extends SceneTree
## Dev-only regression: real key events must match the shipped InputMap.
const FIXTURE := preload("res://tools/calibrated_workstation_fixture.gd")
var OUTPUT := OS.get_environment("STARTUP_VALLEY_AUDIT_OUTPUT_ROOT").path_join("directional-input/") if not OS.get_environment("STARTUP_VALLEY_AUDIT_OUTPUT_ROOT").is_empty() else "res://tests/output/directional-input/"
const CLEAR_AISLE := Vector2(640, 624)
const GROUND_TARGET := Vector2(704, 624)
const CASES := [
	[KEY_A, "move_left", Vector2.LEFT], [KEY_LEFT, "move_left", Vector2.LEFT],
	[KEY_D, "move_right", Vector2.RIGHT], [KEY_RIGHT, "move_right", Vector2.RIGHT],
	[KEY_W, "move_up", Vector2.UP], [KEY_UP, "move_up", Vector2.UP],
	[KEY_S, "move_down", Vector2.DOWN], [KEY_DOWN, "move_down", Vector2.DOWN],
]
var main: GameMain
var checks := 0
var failures: Array[String] = []
var records: Array[Dictionary] = []

func _initialize() -> void:
	if not preload("res://tools/audit_output_scope.gd").valid(OS.get_environment("STARTUP_VALLEY_AUDIT_OUTPUT_ROOT")):
		push_error("Directional input output must be a strict res://tests/output/ descendant")
		quit(2)
		return
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count := 2) -> void:
	for tick: int in range(count): await process_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(1)

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await frames(1)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(1)

func step_player() -> void:
	# Actual physics ticks are explicit only to make headless timing repeatable.
	# The input vector still comes from the real parsed event and shipped map.
	main.player._physics_process(1.0 / 30.0)
	await frames(1)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
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
	for actor: EmployeeAvatar in main._employees.values(): actor.set_physics_process(false)
	main._process(0)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1 and not main._state_loaded, "No real worker transport or loaded personal state")
	var mappings := {}
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		var codes: Array[int] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey: codes.append(event.physical_keycode)
		mappings[action] = codes
	for spec: Array in CASES:
		root.gui_release_focus()
		main.player.cancel_route()
		# The old (464,464) probe is inside the accepted collaboration cluster.
		# Prove this fixture's clear aisle before asking physics to test input.
		main.player.position = CLEAR_AISLE
		main.player.velocity = Vector2.ZERO
		main._process(0)
		check(main.room.navigation.position_is_safe(CLEAR_AISLE, "founder"), "Directional probe begins on safe ground")
		check(main.room.navigation.position_is_safe(CLEAR_AISLE + spec[2] * 16.0, "founder"), "Directional probe has a clear movement corridor")
		var start: Vector2 = main.player.position
		await key(spec[0], true)
		var mapped := Input.is_action_pressed(spec[1])
		check(mapped, OS.get_keycode_string(spec[0]) + " activates " + spec[1])
		await step_player()
		var moved: Vector2 = main.player.position - start
		check(moved.dot(spec[2]) > 0.0 and absf(moved.cross(spec[2])) < 0.01, OS.get_keycode_string(spec[0]) + " moves founder only in its expected direction")
		await key(spec[0], false)
		check(not Input.is_action_pressed(spec[1]), "Release clears " + OS.get_keycode_string(spec[0]))
		main.player.position = start
		main.player.cancel_route()
		check(main.room.navigation.position_is_safe(GROUND_TARGET, "founder"), "Click route target is clear")
		await click(GROUND_TARGET)
		check(not main.player.route.is_empty(), "Real ground click starts route before " + OS.get_keycode_string(spec[0]))
		await key(spec[0], true)
		await step_player()
		check(main.player.route.is_empty(), OS.get_keycode_string(spec[0]) + " cancels the existing click route")
		await key(spec[0], false)
		records.append({"key": OS.get_keycode_string(spec[0]), "code": spec[0], "action": spec[1], "mapped": mapped, "motion": [moved.x, moved.y]})
	main.player.cancel_route()
	for code: Key in [KEY_INSERT, KEY_PAUSE]:
		var start: Vector2 = main.player.position
		await key(code, true)
		check(Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx(), OS.get_keycode_string(code) + " is not a movement binding")
		await step_player()
		check(main.player.position == start, OS.get_keycode_string(code) + " does not move founder")
		await key(code, false)
	main.job_panel.set_worker_ready()
	main.job_panel.set_credential_status(true)
	main.job_panel.open_chat_for_employee("mira")
	await create_timer(0.22).timeout
	main.job_panel._chat_input.grab_focus()
	main._process(0)
	check(root.gui_get_focus_owner() == main.job_panel._chat_input and main.player.input_blocked, "Actual chat focus pauses world input")
	for spec: Array in CASES:
		var start: Vector2 = main.player.position
		await key(spec[0], true)
		await step_player()
		check(main.player.position == start and main.player.velocity == Vector2.ZERO, "Focused chat prevents movement from " + OS.get_keycode_string(spec[0]))
		await key(spec[0], false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Focused UI simulation never opens a worker transport")
	main.game_audio.shutdown()
	main.free()
	await frames(3)
	check(root.get_child_count() == 0, "Fresh fixture closes cleanly")
	var result := {"checks": checks, "failures": failures, "mappings": mappings, "engine_constants": {"left": KEY_LEFT, "right": KEY_RIGHT, "insert": KEY_INSERT, "pause": KEY_PAUSE}, "records": records, "engine": Engine.get_version_info().string}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var phase := "before" if OS.get_cmdline_user_args().has("--record-before") else "after"
	var file := FileAccess.open(OUTPUT + phase + ("-headless.json" if DisplayServer.get_name() == "headless" else "-native.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("Directional input: %d checks / %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
