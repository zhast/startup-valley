extends SceneTree
## Production scenes + production worker. Only injected input changes gameplay.
## Launched by scripts/test-demo-godot.mjs with an isolated save directory.
const MAIN := preload("res://world/main.tscn")
var game: GameMain
var failures: Array[String] = []
var checks := 0
var actions: Array[Dictionary] = []
var captures: Array[String] = []
var completed: Dictionary = {}
var request_observations: Array[Dictionary] = []
var restored_snapshot: Dictionary = {}
var phase := ""
var output_dir := ""
var input_mode := "pointer"
var stopped := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failures.append(message)
		print("DEMO_CHECK_FAILED " + message)
	return value

func wait_for(predicate: Callable, message: String, seconds := 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not bool(predicate.call()) and Time.get_ticks_msec() < deadline:
		await process_frame
	return check(bool(predicate.call()), message)

func frames(count := 4) -> void:
	for i: int in range(count): await process_frame

func run() -> void:
	phase = OS.get_environment("STARTUP_VALLEY_DEMO_PHASE")
	output_dir = OS.get_environment("STARTUP_VALLEY_DEMO_OUTPUT")
	input_mode = OS.get_environment("STARTUP_VALLEY_DEMO_INPUT")
	if phase.is_empty() or output_dir.is_empty() or OS.get_environment("STARTUP_VALLEY_DATA_DIR").is_empty() or OS.get_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS") != "1":
		push_error("Use scripts/test-demo-godot.mjs with disposable saves")
		quit(1)
		return
	root.size = Vector2i(int(OS.get_environment("STARTUP_VALLEY_DEMO_WIDTH")), int(OS.get_environment("STARTUP_VALLEY_DEMO_HEIGHT")))
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	root.unfocusable = true
	root.mouse_passthrough = true
	root.always_on_top = false
	game = MAIN.instantiate() as GameMain
	if game == null:
		push_error("Production main scene could not instantiate")
		quit(1)
		return
	root.add_child(game)
	game.worker_client.company_action_completed.connect(func(method: String, result: Dictionary) -> void: completed[method] = result.duplicate(true))
	game.worker_client.company_action_failed.connect(func(method: String, message: String) -> void: check(false, method + ": " + message))
	game.worker_client.request_failed.connect(func(message: String) -> void: check(false, "Worker: " + message))
	game.worker_client.job_event_received.connect(func(_id: String, _event: WorkerEventRecord) -> void: check(false, "Offline demo emitted a provider job event"))
	game.company_panel.action_requested.connect(func(method: String, _params: Dictionary) -> void:
		request_observations.append({"method": method, "busy": game.company_panel.busy})
		check(game.company_panel.busy, "Action immediately enters busy state: " + method)
	)
	if not await wait_for(func() -> bool: return game._state_loaded and game._worker_ready, "Production worker reaches actual title"):
		await finish()
		return
	await frames(10)
	if not check(game.company_panel.story_mode and game.job_panel.story_mode, "Production native scene and rail use the demo story flow"):
		await finish()
		return
	check(game.company_panel.visible and game.company_panel.screen == "title", "Fresh process opens one title modal")
	var expected_path := OS.get_environment("STARTUP_VALLEY_DEMO_EXPECTED")
	if not expected_path.is_empty():
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		restored_snapshot = snapshot().duplicate(true)
		var wanted: Dictionary = expected.get("snapshot", {})
		for field: String in wanted:
			if field == "player":
				var before := Vector2(float(wanted.player.x), float(wanted.player.y))
				var after := Vector2(float(restored_snapshot.player.x), float(restored_snapshot.player.y))
				check(before.distance_to(after) < 0.01 and wanted.player.movementSeen == restored_snapshot.player.movementSeen, "Restart restores player to subpixel serialization precision: %s -> %s" % [before, after])
			else:
				check(restored_snapshot.get(field) == wanted[field], "Restart restores exact " + field)
	await capture("title")
	match phase:
		"arrival":
			check(game._employees.is_empty() and int(game._journey.company.cashCents) == 0, "Clean save starts with no hires or reward")
			await enter()
			check(not game.company_panel.visible, "Start company reveals the playable studio")
			await move_pointer(game.arrival_guest.position + Vector2(0, -32))
			await frames(4)
			check(game.interaction_highlight.active_sources().has(game.arrival_guest.sprite), "Visible Mina visitor receives pointer highlight")
			await click(Vector2(560, 432))
			await wait_for(func() -> bool: return game.player.route.is_empty() and game.player.position.distance_to(Vector2(560, 432)) < 25, "Real floor click moves Founder to the selected clear floor")
			var before := game.player.position
			var event := InputEventKey.new()
			event.keycode = KEY_D
			event.physical_keycode = KEY_D
			event.pressed = true
			Input.parse_input_event(event)
			await create_timer(0.25).timeout
			event = event.duplicate() as InputEventKey
			event.pressed = false
			Input.parse_input_event(event)
			Input.flush_buffered_events()
			await frames(3)
			check(game.player.position.x > before.x + 5, "Held D moves the actual Founder")
			check(game.founder_hud._movement_seen, "Movement tutorial is recorded by gameplay")
			await capture("arrival-movement")
		"hire": await hire()
		"start": await start_project()
		"mid": await work_day()
		"release": await release_project()
		"visit": await visit_courtyard()
		"outdoor": await outdoor()
		"viewport": await viewport_guard()
		"restored":
			await enter()
			check(not game.company_panel.visible, "Reloaded company resumes without replaying a reward modal")
			await capture("resumed")
			await activate(game.founder_hud._goal_action)
			check(game.company_panel._topic_id == "reselling" and game.company_panel._type_id == "template_pack", "Saved opportunity opens the intended unlocked project")
			await capture("next-opportunity")
			await activate(find_button("Let’s make it"))
			await wait_for(func() -> bool: return game._journey.tycoon.get("developing") is Dictionary, "The courtyard opportunity can start a real project")
			check(game._journey.tycoon.developing.topicId == "reselling" and game._journey.tycoon.developing.typeId == "template_pack", "Started project matches Theo's opportunity")
			check(str(game._journey.story.opportunity.status) == "developing", "Worker associates the real next project with the story opportunity")
		_: check(false, "Unknown phase: " + phase)
	await finish()

func enter() -> void:
	var button := find_button("Continue")
	if button == null: button = find_button("Start company")
	await activate(button)

func hire() -> void:
	await enter()
	if not game.company_panel.visible:
		await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return find_button("Invite Mina") != null, "Walking to Mina opens her actual introduction")
	await capture("Mina-invitation")
	var previous: Dictionary = completed.get("hiring.complete", {})
	await activate(find_button("Invite Mina"))
	await wait_for(func() -> bool: return completed.get("hiring.complete", {}) != previous, "Invitation completes through production worker")
	check(game._employees.size() == 1 and game.get_employee("mira") != null, "Exactly one Mina joins the studio")
	check(int(game._journey.company.cashCents) == 0, "Free invitation grants no duplicate cash")
	await capture("Mina-welcome")

func open_project() -> void:
	await enter()
	if not game.company_panel.visible:
		await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return game.company_panel.screen == "product" and game.company_panel.visible, "Current objective opens project screen")

func start_project() -> void:
	await open_project()
	await capture("first-idea")
	await activate(find_button("Let’s make it"))
	await wait_for(func() -> bool: return game._journey.get("tycoon", {}).get("developing") is Dictionary, "First project starts through worker")
	var product: Dictionary = game._journey.tycoon.developing
	check(product.staffIds == ["founder", "mira"], "First project assigns Founder and Mina exactly once")
	check(int(product.progress) == 0, "New project starts at zero progress")
	await capture("project-started")
	await key(KEY_ESCAPE)
	var mina := game.get_employee("mira")
	await wait_for(func() -> bool: return mina.is_at_desk() and mina.work_state == EmployeeAvatar.WorkState.SITTING, "Mina walks to her real assigned seat", 18.0)
	check(mina.has_studio_project and not mina.has_live_job, "Offline project seating is independent of provider activity")
	await create_timer(9.0 if OS.get_environment("STARTUP_VALLEY_DEMO_RUN") == "1" else 1.0).timeout
	check(mina.is_at_desk() and mina.work_state == EmployeeAvatar.WorkState.SITTING, "Assigned teammate holds the seat beyond normal wander delay")
	await capture("Mina-seated")
	for repeat: int in range(2):
		await activate(game.job_panel._team_buttons["mira"])
		await wait_for(func() -> bool: return game.job_panel.drawer_is_open(), "Rail opens Mina's conversation")
		check(not game.company_panel.visible, "Conversation has no second company modal beneath it")
		await capture("Mina-conversation-%d" % repeat)
		await key(KEY_ESCAPE)
		await wait_for(func() -> bool: return not game.job_panel.drawer_is_open(), "Escape closes the conversation")
		check(not game.company_panel.visible, "Escape closes one layer without opening Settings")

func work_day() -> void:
	await open_project()
	await end_day()
	check(int(game._journey.tycoon.developing.progress) == 33, "First completed day advances actual project to 33 percent")
	await capture("mid-development")

func end_day() -> void:
	var before := game.day_clock.day
	await activate(find_button("Wrap up the day"))
	await wait_for(func() -> bool: return game.day_clock.day == before + 1 and game.company_panel.screen == "summary", "Day advances once and opens saved summary")
	await capture("day-%d-summary" % before)
	await activate(find_button("Begin next day"))
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return game.company_panel.screen == "product", "Next day resumes the project objective")

func release_project() -> void:
	await open_project()
	for i: int in range(3):
		if bool(game._journey.tycoon.developing.get("ready", false)): break
		await end_day()
	check(bool(game._journey.tycoon.developing.get("ready", false)), "Real day progression makes the first product ready")
	await capture("ready-to-release")
	await activate(find_button("Share it with the world"))
	await wait_for(func() -> bool: return game._journey.tycoon.get("developing") == null and not (game._journey.tycoon.get("history", []) as Array).is_empty(), "Release commits once through production worker")
	check((game._journey.tycoon.history as Array).size() == 1, "Exactly one product has been released")
	check(int(game._journey.company.cashCents) > 0 and int(game._journey.company.reputation) > 0, "Real release earns cash and reputation")
	await capture("first-release")

func visit_courtyard() -> void:
	await enter()
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return str(game._journey.get("story", {}).get("location", "")) == "courtyard", "Walking to the exit travels to the real courtyard", 18.0)
	check(game.courtyard.visible and not game.room.visible, "Courtyard replaces office rendering and navigation")
	await wait_for(func() -> bool: return not game._story_busy, "Travel acknowledgement clears pending state")
	await frames(4)
	await move_pointer(game.courtyard.guest.position + Vector2(0, -32))
	await frames(4)
	check(game.interaction_highlight.active_sources().has(game.courtyard.guest.sprite), "Theo's visible sprite receives pointer highlight")
	await capture("courtyard-arrival")
	await move_pointer(game.courtyard.return_sign.position + Vector2(0, -12))
	await frames(4)
	check(game.courtyard.return_sign.hovered, "Return sign highlights under the pointer")
	await frames(8)
	await click(Vector2(144, 112))
	await wait_for(func() -> bool: return game.player.route.is_empty() and game.player.position.distance_to(Vector2(144, 112)) < 25, "Courtyard northwest path reaches legal save coordinates", 18.0)
	await capture("courtyard-northwest-save")

func outdoor() -> void:
	await enter()
	var company: Dictionary = game._journey.company.duplicate(true)
	var inventory: Array = game.worker_client.furnishing_state.inventory.duplicate(true)
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return game.company_panel.visible and game.company_panel.screen == "courtyard", "Walking to Theo opens his invitation", 18.0)
	await capture("Theo-opportunity")
	await activate(find_button("Let’s make the Market Day Kit"))
	await wait_for(func() -> bool: return str(game._journey.story.opportunity.status) == "accepted", "Theo's opportunity commits through the worker")
	await capture("opportunity-accepted")
	await activate(find_button("Back to our studio"))
	await wait_for(func() -> bool: return str(game._journey.story.location) == "office", "Walking home restores the office", 18.0)
	check(game.room.visible and not game.courtyard.visible, "Return restores office rendering")
	check(game._journey.company == company, "Courtyard visit does not duplicate first-release rewards")
	check(game.worker_client.furnishing_state.inventory == inventory, "Courtyard visit preserves owned furniture")
	await capture("outdoor-return")

func viewport_guard() -> void:
	var guard := game.find_child("DemoViewportGuard", true, false) as Control
	if not check(guard != null and guard.is_visible_in_tree(), "Small viewport shows deliberate supported-size guidance"): return
	var before := snapshot()
	await capture("small-display-guidance")
	var start := find_button("Start company")
	if start != null: await touch(start.get_global_rect().get_center())
	await key(KEY_ENTER)
	check(game.company_panel.screen == "title" and game.company_panel.visible and snapshot() == before, "Guard consumes touch and keyboard without activating underlying game")
	root.size = Vector2i(1280, 720)
	await frames(8)
	check(not guard.visible, "Resizing to supported dimensions removes the guidance")
	input_mode = "touch"
	await enter()
	check(not game.company_panel.visible, "Injected touch activates Start in a supported viewport")
	await activate(game.founder_hud._goal_action)
	await wait_for(func() -> bool: return find_button("Invite Mina") != null, "Injected touch objective reaches Mina", 18.0)
	await capture("touch-Mina-invitation")

func find_button(prefix: String) -> Button:
	for node: Node in game.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and button.text.begins_with(prefix): return button
	return null

func activate(button: Button) -> void:
	if button != null:
		var deadline := Time.get_ticks_msec() + 2500
		while is_instance_valid(button) and (not button.is_visible_in_tree() or button.disabled) and Time.get_ticks_msec() < deadline:
			await process_frame
	if not check(button != null and button.is_visible_in_tree() and not button.disabled, "Required action is visible and enabled" + (": " + button.text if button != null else "")): return
	await frames(6)
	check(root.get_visible_rect().encloses(button.get_global_rect()), "Action fits logical viewport: " + button.text)
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is Control and (ancestor as Control).clip_contents:
			check((ancestor as Control).get_global_rect().encloses(button.get_global_rect()), "Action is not clipped by its scroll/container: " + button.text)
		ancestor = ancestor.get_parent()
	var point := button.get_global_rect().get_center()
	actions.append({"input": input_mode, "action": button.text, "point": [point.x, point.y]})
	if input_mode == "touch": await touch(point)
	elif input_mode == "keyboard":
		for i: int in range(80):
			if root.gui_get_focus_owner() == button: break
			await key(KEY_TAB)
		if check(root.gui_get_focus_owner() == button, "Keyboard Tab reaches action: " + button.text): await key(KEY_SPACE)
	else: await click(point)
	await frames(12)

func click(point: Vector2) -> void:
	await move_pointer(point)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = root.get_final_transform() * point
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func move_pointer(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * point
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await frames(1)

func touch(point: Vector2) -> void:
	for down: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = root.get_final_transform() * point
		event.index = 0
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)
	await frames(6)

func snapshot() -> Dictionary:
	var tycoon: Dictionary = game._journey.get("tycoon", {})
	var product: Dictionary = tycoon.get("developing", {}) if tycoon.get("developing") is Dictionary else {}
	var history: Array = []
	for item: Dictionary in tycoon.get("history", []):
		history.append({"id": item.id, "name": item.name, "releasedDay": item.releasedDay, "salesCents": item.salesCents})
	var hires: Array = []
	for candidate: Dictionary in game._journey.get("candidates", []):
		if bool(candidate.get("hired", false)): hires.append(candidate.id)
	return {"company": game._journey.get("company", {}), "day": game.day_clock.day, "hires": hires,
		"product": {"id": product.get("id"), "progress": product.get("progress"), "staffIds": product.get("staffIds"), "ready": product.get("ready")},
		"history": history, "furnishing": game.worker_client.furnishing_state,
		"story": game._journey.get("story", {}), "player": {"x": game.player.position.x, "y": game.player.position.y, "movementSeen": game.founder_hud._movement_seen}}

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(4)
	RenderingServer.force_draw(false)
	var file := output_dir.path_join(phase + "-" + name_value + ".png")
	check(root.get_texture().get_image().save_png(file) == OK, "Native capture: " + name_value)
	captures.append(file)

func finish() -> void:
	if stopped: return
	stopped = true
	await capture("final")
	var file := FileAccess.open(output_dir.path_join(phase + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase": phase, "checks": checks, "failures": failures, "actions": actions, "requests": request_observations, "captures": captures,
		"engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(),
		"window": [root.size.x, root.size.y], "logicalViewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
		"restoredSnapshot": restored_snapshot, "snapshot": snapshot() if game._state_loaded else {}}, "  ") + "\n")
	file.close()
	print("DEMO_PHASE_RESULT %s checks=%d failures=%d" % [phase, checks, failures.size()])
	if not failures.is_empty():
		game.queue_free()
		await frames(4)
		quit(1)
		return
	# The ordinary close path durably saves player position and closes worker stdin.
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
