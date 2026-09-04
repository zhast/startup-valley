extends SceneTree

const MAIN := preload("res://world/main.tscn")
const OUTPUT := "res://tests/output/complete-game"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var actions: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	if not ok:
		failures.append(description)
		push_error(description)

func frames(count: int = 2) -> void:
	for index: int in range(count): await physics_frame

func key(code: Key, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	# push_input drives GUI/key dispatch; mirror movement action state because a
	# manually injected SubViewport event does not update the Input singleton.
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if InputMap.event_is_action(event, action):
			if pressed: Input.action_press(action)
			else: Input.action_release(action)
	viewport.push_input(event, true)
	await frames()

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
		await frames(1)

func screenshot(name: String) -> void:
	await frames(12)
	if DisplayServer.get_name() == "headless": return
	# macOS may suppress automatic presentation for an occluded test window.
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))

func button_named(prefix: String) -> Button:
	for node: Node in main.company_panel.find_children("*", "Button", true, false):
		if (node as Button).is_visible_in_tree() and (node as Button).text.to_lower().begins_with(prefix.to_lower()): return node as Button
	return null

func check_world_label_ui_occlusion() -> void:
	var employee := main.get_employee("mira")
	var other := main.get_employee("theo")
	var original_position := employee.position
	var original_other := other.position
	other.position = Vector2(400, 480)
	employee.position = Vector2(760, 360)
	employee._label_hold = 5
	main.job_panel.close_drawer(false)
	main._update_label_visibility("")
	check(not employee.labels_suppressed, "Uncovered world label remains visible")
	main.job_panel.open_drawer(false)
	check(employee.world_label_rect().intersects(main.job_panel.drawer_global_rect()), "Fixture label crosses drawer boundary")
	main._update_label_visibility("")
	check(employee.labels_suppressed or not employee.world_label_rect().intersects(main.job_panel.drawer_global_rect()), "Drawer label relocates as a whole or suppresses; no partial card")
	main.job_panel._open_connection_settings()
	main.job_panel._drawer_panel.hide()
	main._update_label_visibility("")
	check(employee.labels_suppressed or not employee.world_label_rect().intersects(main.job_panel._connection_panel.get_global_rect()), "Connection alone never covers a world label or pointer")
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main._update_label_visibility("")
	check(not employee.labels_suppressed, "World label restores after overlays close")
	employee.position = Vector2(1140, 360)
	main._update_label_visibility("")
	check(employee.labels_suppressed or not employee.world_label_rect().intersects(main.job_panel.rail_global_rect()), "Docked rail relocates or suppresses the whole world callout")
	employee.position = Vector2(520, 360)
	main.artifact_viewer.show_artifact("label-test.md", "# Safe modal\n\nNo world labels belong above this.")
	main._update_label_visibility("")
	check(employee.labels_suppressed and other.labels_suppressed, "Artifact modal suppresses every world label")
	main.artifact_viewer.hide()
	main.company_panel.present("settings")
	main._update_label_visibility("")
	check(employee.labels_suppressed and other.labels_suppressed, "Company modal suppresses every world label")
	main.company_panel.hide()
	main._update_label_visibility("")
	check(not employee.labels_suppressed and not other.labels_suppressed, "World labels restore when modal closes")
	employee.position = original_position
	other.position = original_other
	employee._label_hold = 0
	main._update_label_visibility("")

func check_journey_shortcut_scope() -> void:
	main.company_panel.hide()
	main.artifact_viewer.hide()
	main.job_panel.close_drawer(false)
	main.job_panel._open_connection_settings()
	main.job_panel._connection_back_button.grab_focus()
	check(main.job_panel._connection_back_button.has_focus() and main.job_panel._connection_back_button.is_visible_in_tree(), "Connection shortcut fixture focuses an actual visible button")
	await key(KEY_J)
	await key(KEY_J, false)
	check(main.job_panel._connection_panel.visible and not main.company_panel.visible, "J cannot open Journey behind the connection overlay")
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main.artifact_viewer.show_artifact("shortcuts.md", "# Read this first\n\nJourney must not open behind this reader.")
	check(main.artifact_viewer._close_button.has_focus(), "Reader shortcut fixture owns keyboard focus")
	await key(KEY_J)
	await key(KEY_J, false)
	check(main.artifact_viewer.visible and not main.company_panel.visible, "J cannot open Journey behind an artifact")
	main.artifact_viewer.hide()
	await key(KEY_J)
	await key(KEY_J, false)
	check(main.company_panel.visible and main.company_panel.screen == "journey", "J opens Journey during office exploration")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	check(not main.company_panel.visible, "Escape returns from shortcut Journey to office")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	# Isolate hit testing from macOS window focus/Retina coordinate transforms.
	# Events still traverse the real viewport GUI and unhandled-input pipelines.
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(display)
	main = MAIN.instantiate()
	viewport.add_child(main)
	await frames(4)
	main.worker_client.set_process(false)
	main.job_panel.chat_history_requested.disconnect(main.worker_client.request_chat_history)
	main.job_panel.set_worker_ready()
	main.job_panel.set_credential_status(true)
	main.job_panel._close_connection_settings()
	main.company_panel.hide()
	main.job_panel.close_drawer(false)
	for employee: EmployeeAvatar in main._employees.values(): employee.set_physics_process(false)
	check_world_label_ui_occlusion()
	await check_journey_shortcut_scope()
	var original_mina := main.get_employee("mira").position
	var original_theo := main.get_employee("theo").position
	main.get_employee("theo").position = main.room.employee_desk_position("theo")
	var architecture := main.room.layout_model
	var floor_rect := OfficeLayout.rectangle(architecture.data.floor_rects[0])
	var prompt_cells: Array[Vector2i] = [main.room.player_spawn, Vector2i(floor_rect.position) + Vector2i(1, 2), Vector2i(floor_rect.end) - Vector2i(2, 2)]
	for founder_cell: Vector2i in prompt_cells:
		var founder_point := main.room.grid_to_world_position(founder_cell)
		for nearby_offset: Vector2 in [Vector2(32, 0), Vector2(-32, 0), Vector2(0, 32), Vector2(0, -32)]:
			main.get_employee("mira").position = founder_point + nearby_offset
			main.founder_hud.update_interaction(founder_point, main._employees, true, main._world_ui_obstacles())
			check(main.founder_hud.interaction_target_id() == "mira", "Nearby teammates retain E interaction even in deliberately crowded edge fixtures")
			if not main.founder_hud.interaction_visible(): continue
			var prompt_rect := main.founder_hud.interaction_rect()
			for actor_point: Vector2 in [founder_point, founder_point + nearby_offset, main.get_employee("theo").position]:
				check(not prompt_rect.intersects(Rect2(actor_point + Vector2(-24, -72), Vector2(48, 76))), "Chat prompt must never cover an actor silhouette")
			for obstacle: Rect2 in main._world_ui_obstacles():
				check(not prompt_rect.intersects(obstacle), "Chat prompt and pointer avoid furniture faces and UI")
	main.get_employee("mira").position = original_mina
	main.get_employee("theo").position = original_theo
	var movement_start := main.room.player_spawn
	var movement_end := movement_start + Vector2i.UP * 2
	check(main.room.navigation.walkable(movement_start) and main.room.navigation.walkable(movement_end), "Authored entrance spine provides open movement fixture")
	main.player.position = main.room.grid_to_world_position(movement_start)
	await frames(12)
	var start := main.player.position
	await click(main.room.grid_to_world_position(movement_end))
	check(not main.player.route.is_empty(), "Ground click must start an actual route")
	await frames(90)
	check(main.player.position.distance_to(main.room.grid_to_world_position(movement_end)) < 3, "Click movement arrives at destination")
	await click(main.room.grid_to_world_position(movement_start))
	var tap := InputEventKey.new()
	tap.keycode = KEY_A
	tap.physical_keycode = KEY_A
	tap.pressed = true
	viewport.push_input(tap, true)
	tap = tap.duplicate()
	tap.pressed = false
	viewport.push_input(tap, true)
	check(main.player.route.is_empty(), "A tap between physics frames immediately cancels click movement")
	await click(main.room.grid_to_world_position(movement_start))
	await key(KEY_A)
	check(main.player.route.is_empty(), "Keyboard input immediately cancels click route")
	await key(KEY_A, false)
	var west_wall_cell := Vector2i(floor_rect.position.x, main.room.player_spawn.y)
	main.player.position = main.room.grid_to_world_position(west_wall_cell)
	await key(KEY_A)
	await frames(80)
	await key(KEY_A, false)
	check(main.room.navigation.cell_at(main.player.position).x >= west_wall_cell.x, "Founder cannot cross outer wall")
	await click(main.room.grid_to_world_position(west_wall_cell + Vector2i.LEFT))
	check(main.player.route.is_empty(), "Blocked ground must not start a route")
	# Every generated route uses only walkable cells, including all desk detours.
	for cell: Vector2i in architecture.floor_cells():
		if not main.room.navigation.walkable(cell): continue
		var route := main.room.navigation.path(start, main.room.grid_to_world_position(cell), "test")
		check(not route.is_empty(), "Every free office floor cell remains reachable")
		for point: Vector2 in route:
			check(main.room.navigation.walkable(main.room.navigation.cell_at(point)), "AStar crossed blocked cell")
	main.room.navigation.release("test")
	# A destination is not valid merely because AStar returns it. Each entrance
	# must lie inside player bounds and be physically reachable by real input.
	for entrance: Vector2i in architecture.entrance_cells():
		var destination := main.room.grid_to_world_position(entrance)
		check(main.room.playable_bounds().grow(-14).has_point(destination), "Entrance center fits the playable movement boundary")
		main.player.cancel_route()
		main.player.position = start
		await click(destination)
		await frames(120)
		check(main.player.position.distance_to(destination) < 3, "Real click reaches every authored entrance cell: %s" % entrance)
	main.player.position = start
	await click(main.job_panel._team_buttons["mira"].get_global_rect().get_center())
	check(main.job_panel.drawer_is_open(), "Real rail click opens drawer")
	check(main.player.route.is_empty(), "Rail click must not leak into world")
	await frames(14)
	for index: int in [1, 2, 3, 0]:
		var tab_button := main.job_panel._tab_buttons[index]
		check(tab_button.is_visible_in_tree() and not tab_button.disabled, "Drawer tab must be visible before real input")
		await click(tab_button.get_global_rect().get_center())
		check(main.job_panel._tabs.current_tab == index, "Real tab click selects " + tab_button.text)
		check(main.player.route.is_empty(), "Tab click cannot leak into world movement")
	var minute := main.day_clock.minute_of_day
	var before := main.player.position
	await key(KEY_D)
	await frames(70)
	await key(KEY_D, false)
	check(main.player.position == before and main.day_clock.minute_of_day == minute, "Drawer pauses movement and business clock")
	await screenshot("employee-drawer")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	check(not main.job_panel.drawer_is_open() and not main.company_panel.visible, "Escape closes drawer before opening pause")
	await frames(14)
	for id: String in ["mira", "theo", "mira", "theo", "theo", "mira"]:
		await click(main.job_panel._team_buttons[id].get_global_rect().get_center())
	await frames(14)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Interrupted drawer tweens settle on last employee")
	main.job_panel.close_drawer(false)
	await frames()
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	check(main.company_panel.visible and main.company_panel.screen == "settings", "Escape opens settings from office")
	await screenshot("settings")
	for index: int in range(12):
		await key(KEY_TAB)
		await key(KEY_TAB, false)
		var focus := viewport.gui_get_focus_owner()
		check(focus != null and main.company_panel.is_ancestor_of(focus), "Modal keyboard focus cannot escape")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	await click(main.job_panel._settings_button.get_global_rect().get_center())
	check(main.company_panel.visible and main.company_panel.screen == "settings", "Rail Settings opens the same pause/settings menu")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	# Click employee: walk first, then chat, with no handler invoked directly.
	var mina := main.get_employee("mira")
	main.player.position = mina.position + Vector2(0, 64)
	mina.set_interaction_highlighted(true)
	main._update_label_visibility("mira")
	check(mina.labels_suppressed or not mina.world_label_rect().intersects(WorldCalloutSkin.actor_rect(main.player.position)), "Contextual employee callout relocates or hides without covering the approaching founder")
	main.player.position = main.room.navigation.world(main.room.navigation.nearest(mina.position + Vector2(0, 112), "founder"))
	await frames()
	await click(mina.position + Vector2(0, -30))
	await frames(180)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Employee click walks into range then opens Chat")
	main.job_panel.close_drawer(false)
	# Founder desk must be useful even in the empty first office.
	for station: String in ["artifact-archive", "approval-console", "mira-workstation", "theo-workstation"]:
		var prop := main.room.prop_node(station)
		check(prop != null, "Two-person chapter unlocks " + station)
		if prop == null: continue
		main.player.position = main.room.navigation.world(main.room.navigation.nearest(main.room.interaction_world_position(station) + Vector2(0, architecture.tile_size * 2), "founder"))
		await frames(4)
		await click(prop.global_position + Vector2(0, -32))
		await frames(240)
		var tab := 3 if station == "artifact-archive" else 2 if station == "approval-console" else 1
		check(main.job_panel.drawer_is_open() and main.job_panel._tabs.current_tab == tab, "Station real-click opens correct screen: " + station)
		main.job_panel.close_drawer(false)
		await frames(4)
	# A stationary approval requester may stand at a station approach. The
	# redesigned room must route around them or yield without a deadlock.
	var approval_approach := main.room.interaction_world_position("approval-console")
	main.player.position = approval_approach + Vector2(0, architecture.tile_size * 2)
	mina.position = approval_approach + Vector2(0, architecture.tile_size)
	mina.has_live_job = true
	mina._has_target = false
	mina.work_state = EmployeeAvatar.WorkState.WAITING_APPROVAL
	mina.set_physics_process(true)
	main.room.navigation.actors["founder"] = main.player.position
	main.room.navigation.actors["mira"] = mina.position
	main.room.navigation.reservations.clear()
	main.job_panel.begin_job("passage-approval", "mira")
	main.job_panel.accept_submission("passage-approval")
	main.job_panel._approval_id = "pending"
	main.job_panel.select_employee("theo")
	main.job_panel.close_drawer(false)
	await frames(15)
	var console_prop := main.room.prop_node("approval-console")
	await click(console_prop.global_position + Vector2(0, -32))
	await frames(480)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Blocked console approach yields passage and opens the employee awaiting approval")
	check(main.player.position.distance_to(mina.position) >= 19, "Yielding cannot overlap the founder")
	main.job_panel.finish_job("passage-approval")
	main.job_panel.close_drawer(false)
	# Both employees target one station: the shared service must reserve distinct
	# destinations and keep every sampled foot position out of architecture.
	for employee: EmployeeAvatar in main._employees.values():
		employee.set_physics_process(true)
		employee.has_live_job = true
		employee.walk_to(main.room.research_position(), EmployeeAvatar.WorkState.WALKING_TO_RESEARCH, EmployeeAvatar.WorkState.WORKING)
	var reached := false
	for frame: int in range(1200):
		await frames(1)
		var all_arrived := true
		for employee: EmployeeAvatar in main._employees.values():
			check(main.room.navigation.walkable(main.room.navigation.cell_at(employee.position)), "Employee feet stay on walkable cells")
			all_arrived = all_arrived and not employee._has_target
		check(main.get_employee("mira").position.distance_to(main.get_employee("theo").position) >= 19.5, "Moving employees never overlap")
		if all_arrived:
			reached = true
			break
	check(reached, "Both employees reach reserved research destinations")
	check(main.room.navigation.reservations.get("mira") != main.room.navigation.reservations.get("theo"), "Employees reserve distinct destination cells")
	for employee: EmployeeAvatar in main._employees.values():
		employee.has_live_job = false
	main.day_clock.set_time(1, DayClock.WORK_END)
	for frame: int in range(1200):
		await frames(1)
		if not main.get_employee("mira")._has_target and not main.get_employee("theo")._has_target: break
	for employee: EmployeeAvatar in main._employees.values():
		check(employee.work_state == EmployeeAvatar.WorkState.OFF_SHIFT and not employee._has_target, "Employees can leave a shared station without doorway deadlock")
	main.day_clock.set_time(2, DayClock.LUNCH_START)
	main.day_clock.set_speed(0)
	for frame: int in range(1200):
		await frames(1)
		if not main.get_employee("mira")._has_target and not main.get_employee("theo")._has_target: break
	for employee: EmployeeAvatar in main._employees.values():
		if employee._has_target: print("lunch waiting ", employee.employee_id, " pos=", employee.position, " route=", employee._route, " actors=", main.room.navigation.actors)
		check(employee.work_state == EmployeeAvatar.WorkState.LUNCH and not employee._has_target, "Employees reach separate lunch seats")
	main._spawn_employees([])
	main.player.position = main.room.grid_to_world_position(main.room.player_spawn)
	await frames()
	var desk := main.room.prop_node("founder-workstation")
	await click(desk.global_position + Vector2(0, -35))
	await frames(180)
	check(main.company_panel.visible and main.company_panel.screen == "journey", "Founder desk opens Company Journey on arrival")
	main.company_panel.action_requested.disconnect(main.worker_client.company_request)
	main.company_panel.action_requested.connect(func(method: String, _params: Dictionary) -> void: actions.append(method))
	main.company_panel.update_state({"company": {"cashCents": 0, "earnedCents": 0, "reputation": 0, "chapter": 1}, "candidates": [{"id": "mira", "name": "Mina", "role": "Product + research", "available": true, "hired": false, "costCents": 0}], "milestones": []})
	main.company_panel.present("title")
	await screenshot("title")
	await click(button_named("START COMPANY").get_global_rect().get_center())
	await screenshot("founder-onboarding")
	check(main.company_panel.screen == "journey", "Start Company offers first hire without a misleading Continue")
	await click(button_named("HIRE MINA").get_global_rect().get_center())
	await click(button_named("HIRE MINA").get_global_rect().get_center())
	check(actions.count("hiring.complete") == 1, "Rapid hire clicks dispatch only once")
	main.company_panel.show_error("Connection interrupted. Retry safely; your company is saved.")
	await screenshot("recoverable-error")
	main.company_panel.show_summary({"day": 3, "earnedCents": 120000, "reputation": 35, "aiSpend": 0.014, "entries": [{"label": "Run ads"}, {"label": "Incorporate"}], "nextMilestone": "Your next chapter"})
	await screenshot("day-summary")
	var hired: Array[EmployeeRecord] = [main.room.placeholder_records()[0]]
	main._spawn_employees(hired)
	var website := {"id": "website", "title": "Build a website", "employeeId": "mira", "state": "active", "jobStatus": "completed", "jobId": "website-fixture", "files": ["site/index.html", "site/styles.css"], "rewardCents": 60000, "reputation": 10, "feeCents": 0}
	main.company_panel.update_state({"company": {"cashCents": 0}, "milestones": [website]})
	main.company_panel.present("journey")
	await screenshot("journey-evaluate")
	await click(button_named("EVALUATE RESULT").get_global_rect().get_center())
	check(actions.count("milestone.evaluate") == 1, "Evaluation dispatches only the evaluator action")
	website.evaluation = {"verdict": "revise", "score": 1.75, "summary": "The offer needs a clearer audience.", "revisionBrief": "Name the audience and make the primary CTA actionable.", "criteria": [{"name": "Clear offer", "score": 1, "evidence": "Generic headline."}]}
	website.state = "revision_required"
	main.company_panel.update_state({"company": {"cashCents": 0}, "milestones": [website]})
	await screenshot("journey-revision")
	var override_button := button_named("OVERRIDE")
	main.company_panel._scroll.ensure_control_visible(override_button)
	await frames(4)
	await click(override_button.get_global_rect().get_center())
	check(actions.count("milestone.override") == 1, "Founder override has a distinct explicit action")
	website.evaluation.verdict = "ready"
	website.evaluation.score = 3.0
	website.evaluation.summary = "Clear offer, coherent page, and a usable call to action."
	website.evaluation.criteria = [{"name": "Clear offer", "score": 3, "evidence": "The headline names the audience and promise."}]
	website.state = "active"
	main.company_panel.update_state({"company": {"cashCents": 0}, "milestones": [website]})
	await screenshot("journey-ready")
	var complete := button_named("COMPLETE MILESTONE")
	check(complete != null and not main.company_panel._scroll.is_ancestor_of(complete), "Milestone completion stays in the stable footer, outside scrolling evidence")
	await frames(4)
	check(complete.get_global_rect().end.y <= 720, "Milestone completion remains visible")
	await click(complete.get_global_rect().get_center())
	check(actions.count("milestone.complete") == 1, "Passing review still requires explicit completion")
	website.state = "completed"
	main._spawn_employees(main.room.placeholder_records())
	main.day_clock.set_time(3, 17 * 60 + 30)
	main.clock_panel.show_money_earned(1800)
	main.company_panel.update_state({"company": {"cashCents": 100000, "earnedCents": 180000, "reputation": 45, "chapter": 2}, "milestones": [website]})
	await screenshot("journey-chapter-complete")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1600, 900)
		await screenshot("window-1600x900")
		check(main.company_panel.get_global_rect().size.is_equal_approx(Vector2(1280, 720)), "Larger window preserves 1280x720 logical composition")
		root.mode = Window.MODE_FULLSCREEN
		await screenshot("fullscreen")
		check(main.company_panel._frame.get_global_rect().end.x <= 1280, "Fullscreen keeps modal within logical viewport")
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
	main.queue_free()
	await frames(4)
	viewport.queue_free()
	display.queue_free()
	await frames(2)
	if failures.is_empty(): print("complete-game real-input tests: passed")
	else: print("complete-game failures: ", failures)
	quit(0 if failures.is_empty() else 1)
