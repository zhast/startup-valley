extends SceneTree

## Fresh Chapter 1 with the real worker and an isolated company.
## Stops before any paid model call: hire Mina, reach the website work order,
## move, then end the day. A missing API key must open Connect, not crash.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	if OS.get_environment("STARTUP_VALLEY_DATA_DIR").is_empty():
		var data_dir := OS.get_temp_dir().path_join("startup-valley-chapter1-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
		DirAccess.make_dir_recursive_absolute(data_dir)
		OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		failures.append(message)
		push_error("FAIL " + message)

func frames(count: int = 2) -> void:
	for _index: int in range(count):
		await process_frame

func button_named(prefix: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	for node: Node in main.company_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and button.text.to_lower().begins_with(prefix.to_lower()):
			return button
	return null

func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree() and not (control is BaseButton and (control as BaseButton).disabled), "Click target is visible and enabled: " + (str(control.name) if control != null else "missing") + ((" / " + (control as Button).text) if control is Button else ""))
	if control == null:
		return
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)
	await frames(1)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		viewport.push_input(event, true)
		await frames(1)
	await frames(8)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if InputMap.event_is_action(event, action):
			if pressed:
				Input.action_press(action)
			else:
				Input.action_release(action)
	viewport.push_input(event, true)
	await frames(1)

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	main = MAIN.instantiate()
	viewport.add_child(main)
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		await frames(1)
		if main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty():
			break
	check(main._state_loaded and main._worker_ready, "Worker bootstrap loads a fresh company")
	check(main.company_panel.visible and main.company_panel.screen == "title", "Fresh company opens on the title screen")
	check(main._employees.is_empty(), "Founder starts alone")
	check(main.room.architecture.floor_art != null and main.room.architecture.wall_art != null, "Office architecture art is bound")
	check(main.room.architecture.theme_id == "office" and main.room.architecture.floor_art == load("res://assets/runtime/office/architecture/floor.png"), "Day 1 still spawns the oak office, not cafe, loft, studio, or evening")
	check(OfficeArchitecture.DEFAULT_THEME == "office", "Oak remains the day-1 default")
	check(OfficeArchitecture.theme_available("cafe") and OfficeArchitecture.theme_available("loft") and OfficeArchitecture.theme_available("studio") and OfficeArchitecture.theme_available("evening"), "Cafe, loft, studio, and evening architecture are registered")
	main.day_clock.set_speed(0)
	var start := button_named("Start company")
	await click(start)
	await frames(20)
	check(main.company_panel.screen == "journey", "Start company opens Journey for the first hire")
	var hire := button_named("Hire Mina")
	await click(hire)
	await frames(30)
	check(main.company_panel.screen == "hired", "Hiring Mina confirms instead of leaving Journey busy")
	check(main._employees.has("mira") and not main._employees.has("theo"), "Only Mina joins the office")
	check(main.room.prop_node("mira-workstation") != null, "Mina's workstation is in the room")
	var mira_desk := main.room.placement_by_id("mira-workstation")
	check(str(mira_desk.get("role_kit", "")) == "mina_discovery_kit", "Mina's desk wears the discovery kit")
	var founder_desk := main.room.placement_by_id("founder-workstation")
	check(str(founder_desk.get("role_kit", "")) == "founder_strategy_kit", "The founder desk wears the strategy kit")
	var founder_strategy_layers := 0
	var founder_lamp_layers := 0
	for layer: Dictionary in founder_desk.render_layers:
		var art := str(layer.get("art", ""))
		if art.contains("founder_strategy_kit"): founder_strategy_layers += 1
		if art.contains("desk_lamp_kit"): founder_lamp_layers += 1
	check(founder_strategy_layers == 2 and founder_lamp_layers == 2, "The founder desk stacks the desk lamp kit on the strategy kit")
	var meet := button_named("Meet Mina")
	await click(meet)
	await frames(12)
	check(not main.company_panel.visible, "Meet Mina returns to the office")
	var next_step := ""
	if main.founder_hud._next_step_label != null:
		next_step = main.founder_hud._next_step_label.text
	check(main.founder_hud._next_step_hint.visible and next_step.to_lower().contains("website"), "Office hint names the website work order: " + next_step)
	var before := main.player.position
	await key(KEY_A, true)
	for _step: int in range(40):
		await physics_frame
	await key(KEY_A, false)
	check(main.player.position.distance_to(before) > 8.0, "WASD moves the founder on day 1")
	check(main.player._character_sprite.texture == CharacterArt.locomotion_sheet("founder"), "Founder uses the founder locomotion sheet")
	var mina: EmployeeAvatar = main.get_employee("mira")
	check(mina != null and mina._character_sprite.texture == CharacterArt.locomotion_sheet("mira"), "Mina uses her locomotion sheet")
	await key(KEY_J, true)
	await key(KEY_J, false)
	await frames(8)
	check(main.company_panel.visible and main.company_panel.screen == "journey", "J opens Journey after hiring")
	var prepare := button_named("Prepare work order")
	await click(prepare)
	await frames(16)
	check(not main.company_panel.visible and main.job_panel.drawer_is_open(), "Prepare work order opens Assign")
	check(main.job_panel.milestone_id == "website", "Assign is bound to the website milestone")
	check(main.job_panel._assign_button.text.to_lower().contains("website"), "Assign button names the website work order")
	await click(main.job_panel._assign_button)
	await frames(12)
	check(main.job_panel._connection_panel.visible, "Starting work without an API key opens Connect instead of crashing")
	check(not main.job_panel._credential_configured, "Chapter 1 ignores host Grok and OpenRouter credentials")
	check(main.job_panel._grok_login_button.visible and main.job_panel._grok_login_button.text.contains("Grok"), "Connect offers Sign in with Grok")
	check(main.job_panel._connection_description.text.contains("xAI"), "Connect copy names Grok / xAI credits")
	check(main.job_panel.active_job_id().is_empty(), "No work order is submitted without a key")
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	await frames(6)
	await key(KEY_J, true)
	await key(KEY_J, false)
	await frames(8)
	var end_day := button_named("End day")
	await click(end_day)
	await frames(30)
	check(main.company_panel.screen == "summary", "Ending day 1 reaches the day summary")
	check(button_named("Begin next day") != null, "Day summary can return to the office")
	var creative_sheet := CharacterArt.locomotion_sheet("creative")
	var expected_creative := load("res://assets/runtime/characters/creative-locomotion.png") as Texture2D
	check(creative_sheet != null and creative_sheet == expected_creative and creative_sheet != CharacterArt.locomotion_sheet("founder"), "Creative locomotion is registered to creative-locomotion.png")
	var catalog_value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/furnishing_catalog.json"))
	var catalog: Dictionary = catalog_value if catalog_value is Dictionary else {}
	var role_value: Variant = catalog.get("employee_role_kits", {})
	var kits_value: Variant = catalog.get("role_kits", {})
	var role_map: Dictionary = role_value if role_value is Dictionary else {}
	var kits: Dictionary = kits_value if kits_value is Dictionary else {}
	var kit_value: Variant = kits.get("creative_design_kit", {})
	var creative_kit: Dictionary = kit_value if kit_value is Dictionary else {}
	check(str(role_map.get("founder", "")) == "founder_strategy_kit", "Founder maps to founder_strategy_kit")
	check(str(role_map.get("creative", "")) == "creative_design_kit", "Creative hire maps to creative_design_kit")
	check(str(creative_kit.get("owner_id", "")) == "creative" and str(creative_kit.get("host_kind", "")) == "desk", "Creative design kit is bound to a creative-owned desk")
	var founder_kit_value: Variant = kits.get("founder_strategy_kit", {})
	var founder_kit: Dictionary = founder_kit_value if founder_kit_value is Dictionary else {}
	check(str(founder_kit.get("owner_id", "")) == "founder" and str(founder_kit.get("host_kind", "")) == "desk", "Founder strategy kit is bound to the founder-owned desk")
	var decor_map_value: Variant = catalog.get("employee_decor_kits", {})
	var decor_kits_value: Variant = catalog.get("decor_kits", {})
	var decor_map: Dictionary = decor_map_value if decor_map_value is Dictionary else {}
	var decor_kits: Dictionary = decor_kits_value if decor_kits_value is Dictionary else {}
	var lamp_value: Variant = decor_kits.get("desk_lamp_kit", {})
	var lamp_kit: Dictionary = lamp_value if lamp_value is Dictionary else {}
	check(str(decor_map.get("founder", "")) == "desk_lamp_kit", "Founder maps to desk_lamp_kit")
	check(str(lamp_kit.get("owner_id", "")) == "founder" and str(lamp_kit.get("host_kind", "")) == "desk", "Desk lamp kit is a founder desk host-surface decor kit")
	print("CHAPTER1 ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	var exit_code := 0 if failures.is_empty() else 1
	if exit_code == 0:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
