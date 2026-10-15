extends SceneTree
## Deterministic native production projection: accepted role kits, stored decor,
## real navigation and employee events. No worker, credential or save is opened.
var output_root := "res://tests/output/furnishing-runtime"
var main: GameMain
var checks := 0
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var details: Array[Image] = []
var frame_count := 0
var source_before: Dictionary = {}
var movie_path := ""
var scenarios: Array[Dictionary] = []

func source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for source: String in ["res://tools/capture_furnishing_runtime.gd", "res://world/main.gd", "res://worker_client.gd", "res://world/office_layout.gd", "res://world/town_room.gd", "res://world/office_navigation.gd", "res://actors/employee_avatar.gd", "res://actors/player_avatar.gd", "res://ui/office_renovation.gd", "res://ui/game_fonts.gd", "res://ui/cozy_ui.gd", "res://data/office_layout.json", "res://data/furniture_catalog.json", "res://data/furnishing_catalog.json"]:
		result[source] = FileAccess.get_sha256(source)
	var library: Dictionary = OfficeLayout._read_json(OfficeLayout.FURNISHING_CATALOG_PATH)
	for copy: Dictionary in library.source_copies:
		var source := "res://" + str(copy.destination).trim_prefix("game/")
		result[source] = FileAccess.get_sha256(source)
	return result

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	var requested := OS.get_environment("STARTUP_VALLEY_AUDIT_OUTPUT_ROOT")
	if not requested.is_empty(): output_root = requested
	var arguments := OS.get_cmdline_args()
	for index: int in range(arguments.size() - 1):
		if arguments[index] == "--write-movie": movie_path = arguments[index + 1]
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func step(count: int = 1) -> void:
	for index: int in range(count):
		frame_count += 1
		if OS.get_cmdline_user_args().has("--diagnose") and frame_count % 120 == 0: print("Furnishing lifecycle frame ", frame_count)
		for actor: EmployeeAvatar in main._employees.values():
			actor.world_paused = false
			actor._physics_process(1.0 / 30.0)
			check(main.room.navigation.walkable(main.room.navigation.cell_at(actor.position)), actor.employee_id + " stays in a walkable cell")
			check(main.room.navigation._footprint_clear(actor.position), actor.employee_id + " keeps its whole physical footprint off blocked furniture/wall cells")
		await process_frame

func settle(actor: EmployeeAvatar, expected: EmployeeAvatar.WorkState, label: String) -> void:
	for index: int in range(480):
		await step()
		if actor.work_state == expected and not actor._has_target and not actor._seat_transition_active: break
	check(actor.work_state == expected and not actor._has_target, label + " reaches expected state/destination")
	for other: EmployeeAvatar in main._employees.values():
		if other != actor: check(other.position.distance_to(actor.position) >= 20.0, label + " does not end overlapped with another employee")
	await step(6)

func event(actor: EmployeeAvatar, type: StringName, tool: String = "") -> void:
	var record := WorkerEventRecord.new()
	record.type = type
	record.tool = tool
	actor.apply_worker_event(record, main.player.position)

func ui_click(point: Vector2) -> void:
	root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame
	for down: bool in [true, false]:
		var button := InputEventMouseButton.new()
		button.position = point
		button.global_position = point
		button.button_index = MOUSE_BUTTON_LEFT
		button.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		button.pressed = down
		Input.parse_input_event(button)
		Input.flush_buffered_events()
		await process_frame
	await process_frame

func capture(label: String, owner: String = "") -> void:
	print("Furnishing lifecycle checkpoint: ", label)
	if DisplayServer.get_name() == "headless": return
	# A background/occluded native window may suppress automatic draw signals.
	# Force this audit frame after the bounded physics steps instead of waiting
	# forever for frame_post_draw while the user works in another application.
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var file := output_root.path_join(label + ".png")
	check(image.get_size() == Vector2i(1280, 720), label + " uses native viewport")
	check(image.save_png(file) == OK, label + " saved")
	captures.append({"label": label, "path": file, "sha256": FileAccess.get_sha256(file), "engine_process_frame": Engine.get_process_frames(), "physics_frame": frame_count})
	if not owner.is_empty():
		var anchor: Vector2 = main.room.placement_by_id(owner + "-workstation").anchor
		var detail := image.get_region(Rect2i(Vector2i(anchor) - Vector2i(96, 160), Vector2i(192, 224)))
		details.append(detail)

func state_for(hires: int) -> Dictionary:
	var result := {"version": 1, "revision": 0, "inventory": [], "placements": {}, "recovery": ""}
	for original: Dictionary in main.room.layout_model.data.props:
		if int(original.required_hires) > hires: continue
		var item := {"id": original.id, "kind": original.kind, "ownerId": str(original.get("owner_id", "")), "essential": true, "grant": "test"}
		if original.id == "founder-workstation": item["roleKit"] = "founder_strategy_kit"
		if original.id == "mira-workstation": item["roleKit"] = "mina_discovery_kit"
		if original.id == "theo-workstation": item["roleKit"] = "theo_campaign_kit"
		result.inventory.append(item)
		result.placements[original.id] = {"grid": original.grid.duplicate(), "facing": original.facing}
	var library: Dictionary = OfficeLayout._read_json(OfficeLayout.FURNISHING_CATALOG_PATH)
	for item: Dictionary in library.starter_decor:
		result.inventory.append({"id": item.id, "kind": item.kind, "ownerId": "", "essential": false, "grant": "starter"})
	return result

func run() -> void:
	if not output_root.begins_with("res://tests/output/") or output_root.contains(".."):
		push_error("Furnishing evidence must stay in an explicit test-output directory")
		quit(1)
		return
	if DisplayServer.get_name() == "headless" and not OS.get_cmdline_user_args().has("--diagnose"):
		push_error("Native furnishing review requires a renderer")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_root))
	if not movie_path.is_empty() and FileAccess.file_exists(output_root.path_join("manifest.json")):
		push_error("Preserve earlier evidence: choose a unique furnishing movie output directory")
		quit(1)
		return
	source_before = source_hashes()
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	for index: int in range(4): await process_frame
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.job_panel.close_drawer(false)
	main.founder_hud.dismiss_movement_hint()
	main.player.set_physics_process(false)
	main.player.position = main.room.grid_to_world_position(Vector2i(17, 18))
	main.room.navigation.actors["founder"] = main.player.position
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "No worker or personal company opened")
	var state := state_for(2)
	state.placements["decor-broadleaf_planter"] = {"grid": [22, 16], "facing": "south"}
	state.placements["decor-task_floor_lamp"] = {"grid": [25, 18], "facing": "south"}
	state.placements["decor-coat_bag_stand"] = {"grid": [19, 18], "facing": "south"}
	state.placements["decor-rolling_storage_pedestal"] = {"grid": [7, 13], "facing": "south"}
	check(main.room.apply_furnishing_state(state), "Four native starter decorations fit beside production stations")
	var founder_lamp_layers := 0
	var founder_strategy_layers := 0
	for layer: Dictionary in main.room.placement_by_id("founder-workstation").render_layers:
		var art := str(layer.get("art", ""))
		if art.contains("desk_lamp_kit"): founder_lamp_layers += 1
		if art.contains("founder_strategy_kit"): founder_strategy_layers += 1
	check(founder_strategy_layers == 2 and founder_lamp_layers == 2, "Founder desk stacks desk_lamp_kit after founder_strategy_kit")
	main._on_room_placements_changed()
	for actor: EmployeeAvatar in main._employees.values(): actor.set_physics_process(false)
	await step(4)
	if OS.get_cmdline_user_args().has("--mature-ui"):
		root.gui_embed_subwindows = true
		main.office_renovation.receive_state(state)
		main.office_renovation.open()
		for index: int in range(4): await process_frame
		var picker := main.office_renovation._prop_picker
		check(picker.item_count == 11, "Mature inventory presents all eleven currently owned furnishings")
		await capture("mature-renovate-open")
		await ui_click(picker.get_global_rect().get_center())
		check(picker.get_popup().visible, "Actual pointer opens the mature inventory dropdown")
		check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(Rect2(Vector2(picker.get_popup().position), Vector2(picker.get_popup().size))), "All eleven dropdown rows fit the native viewport")
		await capture("mature-renovate-dropdown")
		picker.get_popup().hide()
		main.office_renovation.select_placement("mira-workstation")
		for index: int in range(3): await process_frame
		await capture("mature-mina-kit-preview")
		var ui_source_after := source_hashes()
		check(ui_source_after == source_before, "Mature UI capture retains exact source and accepted-image hashes")
		var ui_manifest := FileAccess.open(output_root.path_join("mature-ui-manifest.json"), FileAccess.WRITE)
		ui_manifest.store_string(JSON.stringify({"worker_disabled": true, "fixture_scope": "Native layout and actual dropdown pointer input only; not worker persistence evidence", "checks": checks, "failures": failures, "captures": captures, "source_hashes_before": source_before, "source_hashes_after": ui_source_after}, "\t"))
		main.game_audio.shutdown()
		main.free()
		print("Mature furnishing UI capture: %d checks, %d failures, %d native captures" % [checks, failures.size(), captures.size()])
		quit(0 if failures.is_empty() else 1)
		return
	if OS.get_cmdline_user_args().has("--decor-only"):
		for side: String in OfficeLayout.FACINGS:
			for id: String in ["decor-broadleaf_planter", "decor-task_floor_lamp", "decor-coat_bag_stand", "decor-rolling_storage_pedestal"]: state.placements[id].facing = side
			check(main.room.apply_furnishing_state(state), side + " four native decorations retain valid clearance/layer geometry")
			main._on_room_placements_changed()
			await step(2)
			await capture("decor-" + side)
		var decor_manifest := FileAccess.open(output_root.path_join("decor-manifest.json"), FileAccess.WRITE)
		decor_manifest.store_string(JSON.stringify({"worker_disabled": true, "checks": checks, "failures": failures, "captures": captures, "source_hashes": source_before}, "\t"))
		main.game_audio.shutdown()
		main.free()
		print("Furnishing decor capture: %d checks, %d failures, %d native captures" % [checks, failures.size(), captures.size()])
		quit(0 if failures.is_empty() else 1)
		return
	await capture("decorated-room")
	for side: String in OfficeLayout.FACINGS:
		state.placements["mira-workstation"].facing = side
		state.placements["theo-workstation"].facing = side
		check(main.room.apply_furnishing_state(state), side + " preserves valid furnished room")
		main._on_room_placements_changed()
		for actor: EmployeeAvatar in main._employees.values():
			actor.has_live_job = false
			actor.set_schedule_phase("work")
			actor._idle_cooldown = 1000.0
		for owner: String in ["mira", "theo"]:
			var actor := main.get_employee(owner)
			var prefix := side + "-" + owner + "-"
			var scenario_start := Engine.get_process_frames()
			event(actor, &"job.started")
			await step(4)
			await capture(prefix + "approach", owner)
			await settle(actor, EmployeeAvatar.WorkState.WORKING, prefix + "thinking")
			await capture(prefix + "thinking", owner)
			event(actor, &"tool.started", "write_file")
			await settle(actor, EmployeeAvatar.WorkState.TYPING, prefix + "typing")
			check(actor._uses_seated_visual(), prefix + " uses reviewed seated work on role host")
			await capture(prefix + "typing", owner)
			event(actor, &"tool.started", "web_search")
			await settle(actor, EmployeeAvatar.WorkState.WORKING, prefix + "research")
			await capture(prefix + "research", owner)
			event(actor, &"approval.required")
			await settle(actor, EmployeeAvatar.WorkState.WAITING_APPROVAL, prefix + "approval")
			await capture(prefix + "approval", owner)
			event(actor, &"job.completed")
			await settle(actor, EmployeeAvatar.WorkState.IDLE, prefix + "delivery")
			await capture(prefix + "delivery", owner)
			event(actor, &"job.started")
			await settle(actor, EmployeeAvatar.WorkState.WORKING, prefix + "restart")
			event(actor, &"job.failed")
			await step(5)
			await capture(prefix + "failed-rest", owner)
			actor.set_schedule_phase("lunch")
			await settle(actor, EmployeeAvatar.WorkState.LUNCH, prefix + "lunch")
			await capture(prefix + "lunch", owner)
			actor.set_schedule_phase("work")
			await settle(actor, EmployeeAvatar.WorkState.SITTING, prefix + "return")
			await capture(prefix + "return", owner)
			scenarios.append({"name": side + "-" + owner, "first_engine_frame": scenario_start, "last_engine_frame": Engine.get_process_frames(), "expected_end_state": "SITTING", "actual_end_state": EmployeeAvatar.WorkState.keys()[actor.work_state], "expected_position": [actor.desk_position.x, actor.desk_position.y], "actual_position": [actor.position.x, actor.position.y]})
			actor._idle_cooldown = 1000.0
	if DisplayServer.get_name() == "headless":
		print("Furnishing lifecycle diagnostic: %d checks, %d failures, %d physics frames" % [checks, failures.size(), frame_count])
		main.game_audio.shutdown()
		main.free()
		quit(0 if failures.is_empty() else 1)
		return
	var contact := Image.create(192 * 9, 224 * 8, false, Image.FORMAT_RGBA8)
	contact.fill(Color("f1f1f1"))
	for index: int in range(details.size()): contact.blit_rect(details[index], Rect2i(Vector2i.ZERO, Vector2i(192, 224)), Vector2i(index % 9 * 192, index / 9 * 224))
	contact.save_png(output_root.path_join("role-lifecycle-contact-native.png"))
	var source_after := source_hashes()
	check(source_after == source_before, "Capture does not change its production sources or exact accepted images")
	var manifest := {"worker_disabled": true, "checks": checks, "failures": failures, "captures": captures, "contact_sheet": output_root.path_join("role-lifecycle-contact-native.png"), "directions": OfficeLayout.FACINGS, "sequence": ["approach", "thinking", "typing", "research", "approval", "delivery", "failed-rest", "lunch", "return"], "scenarios": scenarios, "movie_path": movie_path, "fps": 30, "physics_frames": frame_count, "engine_process_frames": Engine.get_process_frames(), "source_hashes_before": source_before, "source_hashes_after": source_after}
	var file := FileAccess.open(output_root.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	main.game_audio.shutdown()
	main.free()
	print("Furnishing runtime capture: %d checks, %d failures, %d native captures" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
