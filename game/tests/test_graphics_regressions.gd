extends SceneTree

const OUTPUT := "res://tests/output/graphics-repair"
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 15) -> void:
	for index: int in range(count): await process_frame

func capture(name: String) -> Image:
	await frames()
	if DisplayServer.get_name() == "headless": return null
	RenderingServer.force_draw(false)
	var rendered := root.get_texture().get_image()
	rendered.save_png(OUTPUT.path_join(name + ".png"))
	return rendered

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.gui_embed_subwindows = true
	var comparison := Control.new()
	root.add_child(comparison)
	for index: int in range(2):
		var panel := Panel.new()
		panel.position = Vector2(30 + index * 620, 30)
		panel.size = Vector2(580, 640)
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if index == 0:
			var old := StyleBoxTexture.new()
			old.texture = NotebookSkin.PARCHMENT_PANEL
			for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: old.set_texture_margin(side, 10)
			panel.add_theme_stylebox_override("panel", old)
		else: panel.add_theme_stylebox_override("panel", NotebookSkin.parchment())
		comparison.add_child(panel)
	var proof := await capture("corner-comparison")
	if proof != null:
		var source := NotebookSkin.PARCHMENT_PANEL.get_image()
		var matching := 0
		var sampled := 0
		for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			for y: int in range(14):
				for x: int in range(14):
					var expected := source.get_pixel(x + corner.x * (source.get_width() - 14), y + corner.y * (source.get_height() - 14))
					if expected.a < 0.99: continue
					var actual := proof.get_pixel(650 + x + corner.x * 566, 30 + y + corner.y * 626)
					sampled += 1
					if absf(expected.r - actual.r) + absf(expected.g - actual.g) + absf(expected.b - actual.b) < 0.025: matching += 1
		check(sampled > 400 and matching == sampled, "All opaque menu-corner pixels must survive panel resizing unchanged (%d/%d)" % [matching, sampled])
	comparison.free()

	var main: GameMain = load("res://world/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	for entry: Dictionary in main.job_panel.get_signal_list():
		for connection: Dictionary in main.job_panel.get_signal_connection_list(entry.name):
			var callback: Callable = connection.callable
			if callback.get_object() == main.worker_client:
				main.job_panel.disconnect(entry.name, callback)
	main.company_panel.hide()
	main.job_panel.set_credential_status(true)
	main.job_panel.set_worker_ready()
	main.job_panel.close_drawer(false)
	main.day_clock.set_speed(0)
	main.day_clock.set_time(1, DayClock.WORK_START)
	main.founder_hud.dismiss_movement_hint()
	main._spawn_employees(main.room.placeholder_records())
	for employee_id: String in ["mira", "theo"]:
		var employee := main.get_employee(employee_id)
		employee.position = employee.desk_position
		employee._has_target = false
		employee.world_paused = true
		employee.set_physics_process(false)
		employee.work_state = EmployeeAvatar.WorkState.SITTING
		employee._physics_process(0)
		employee._label_hold = 0
		employee.queue_redraw()
		check(employee._character_sprite.texture == CharacterArt.seated_sheet(employee_id), "Desk idle must use ergonomic seated art")
		var desk := main.room.prop_node(employee_id + "-workstation")
		var rear := desk.get_node("DeskRear") as Sprite2D
		var front := desk.get_node("DeskFront") as Sprite2D
		check(rear.texture.resource_path.ends_with("desk-south-rear.png") and front.texture.resource_path.ends_with("desk-south-front.png"), "Furniture uses the reviewed independent South layers")
		check(rear.position == front.position and rear.scale == Vector2.ONE and front.scale == Vector2.ONE, "Furniture must preserve common origin and native scale")
		var lower := employee._work_pose_layer_sprites.get("lower") as Sprite2D
		var upper := employee._work_pose_layer_sprites.get("upper") as Sprite2D
		check(lower != null and upper != null and lower.z_index < front.z_index and upper.z_index > front.z_index, "Split seated body brackets the reviewed desk front")
	await capture("office-seated")
	for employee_id: String in ["mira", "theo"]:
		var employee := main.get_employee(employee_id)
		employee.work_state = EmployeeAvatar.WorkState.TYPING
		employee._animation_elapsed = 0
		employee._physics_process(0)
		check(employee._character_sprite.texture == CharacterArt.seated_sheet(employee_id), "Typing must not use the cross-legged laptop pose")
		check(employee._character_sprite.region_rect.size == Vector2(48, 80), "Seated cells must remain native 48x80")
		employee.work_state = EmployeeAvatar.WorkState.LUNCH
		employee._update_character_frame()
		check(employee._character_sprite.texture == CharacterArt.locomotion_sheet(employee_id), "Lunch uses directional standing idle until supported lounge poses exist")
		check(employee._character_sprite.region_rect.size == Vector2(48, 80), "Lunch preserves the native standing source cell")
		check(employee._shadow_sprite.region_rect == PolishArt.shadow_region(0), "Lunch keeps the standing floor shadow")
		employee.work_state = EmployeeAvatar.WorkState.TYPING
		employee._update_character_frame()
	await capture("office-typing")
	if DisplayServer.get_name() != "headless":
		for employee_id: String in ["mira", "theo"]:
			var employee := main.get_employee(employee_id)
			var visible_frames: Dictionary = {}
			for frame: int in range(4):
				employee._animation_elapsed = float(frame) / 8.0
				employee._update_character_frame()
				await frames(1)
				RenderingServer.force_draw(false)
				var crop := root.get_texture().get_image().get_region(Rect2i(Vector2i(employee.position) - Vector2i(24, 72), Vector2i(48, 80)))
				visible_frames[hash(crop.get_data())] = true
			check(visible_frames.size() >= 2, "%s typing motion must remain visible above the desktop" % employee_id)
	main.job_panel.open_chat_for_employee("mira")
	main.job_panel.show_chat_history("mira", [{"sender": "player", "content": "What should we build?"}, {"sender": "employee", "content": "A small website with one clear promise. Let's turn it into a work order."}])
	await capture("chat")
	var button := main.job_panel._make_job_button
	check(button.is_visible_in_tree() and not button.disabled, "Contextual work-order control must be visible and enabled before input")
	var press := InputEventMouseButton.new()
	press.position = button.get_global_rect().get_center()
	press.global_position = press.position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	check(button.scale == Vector2.ONE and button.self_modulate != Color.WHITE, "Press feedback must be immediate without fractional scale")
	press = press.duplicate()
	press.pressed = false
	root.push_input(press, true)
	await frames(12)
	check(main.job_panel._tabs.current_tab == 1, "Real contextual click converts chat into Assign")
	await capture("assign")
	var picker := main.job_panel._purpose_picker
	var picker_event := InputEventMouseMotion.new()
	picker_event.position = picker.get_global_rect().get_center()
	picker_event.global_position = picker_event.position
	root.push_input(picker_event, true)
	await frames(1)
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = picker_event.position
		click.global_position = click.position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)
		await frames(1)
	await capture("assign-dropdown")
	check(picker.get_popup().visible, "Real mouse input must open the dropdown")
	check(picker.get_theme_stylebox("pressed").get_minimum_size() == picker.get_theme_stylebox("normal").get_minimum_size(), "Open dropdown must retain stable field geometry")
	check(picker.get_meta("cozy_variant", "") == "secondary" and picker.get_theme_font("font") == GameFonts.BOLD, "Dropdown uses shared readable control system")
	check(picker.get_theme_color("font_hover_pressed_color") == JobPanel.CHARCOAL, "Open dropdown must retain readable ink")
	picker.get_popup().hide()
	main.artifact_viewer.show_artifact("Website plan.md", "# Our first website\n\nA clear promise, a useful product, and a simple next step.\n\n- Offer\n- Evidence\n- Call to action\n".repeat(8))
	for index: int in range(12):
		await process_frame
		check(main.artifact_viewer._modal.scale == Vector2.ONE, "Reader fades must not resample the notebook")
	await capture("reader")
	main.artifact_viewer.hide()
	main.company_panel.update_state({"company": {"cashCents": 60000, "grossEarningsCents": 60000, "reputation": 10}, "milestones": []})
	main.company_panel.present("journey")
	await capture("journey")
	check(main.company_panel.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and main.job_panel.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and main.artifact_viewer.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Pixel UI roots must use nearest sampling")
	main.company_panel.hide()
	main.job_panel._tabs.current_tab = 0
	root.size = Vector2i(1600, 900)
	await capture("chat-1600x900")
	if failures.is_empty() and OS.get_cmdline_user_args().has("--interactive"):
		print("Graphics fixture ready for native UI inspection; no worker or save writes.")
		return
	main.game_audio.shutdown()
	await frames()
	main.free()
	if failures.is_empty(): print("Graphics regressions: passed (rendered corners, registered workstation, seated poses, scale-safe feedback)")
	quit(failures.size())
