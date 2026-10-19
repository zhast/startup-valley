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
	# One-cell. The planter's former south-cluster cell [22, 16] is the last
	# remaining four-facing two-cell pocket after the cart and water station.
	# [32, 13] stays valid for every facing in the east bay beside approval.
	state.placements["decor-broadleaf_planter"] = {"grid": [32, 13], "facing": "south"}
	# One-cell. The round meeting table needs a four-facing 3x3 pocket this lamp
	# covered in the coffee bay. [19, 14] stays valid for every facing east of
	# the aisle, north of the printer, and south of Theo's desk, clear of Mina
	# [11, 18], Creative [14, 18], Theo [23, 18], and the founder capture cell
	# [17, 18].
	state.placements["decor-task_floor_lamp"] = {"grid": [19, 14], "facing": "south"}
	# One-cell. The low lounge table needs a four-facing pocket this stand's tall
	# artwork covered on the south floor. [32, 19] stays valid for every facing
	# on the east edge, clear of the planter at [32, 13], the prototype bench,
	# Mina [11, 18], Creative [14, 18], Theo [23, 18], and the founder capture
	# cell [17, 18].
	state.placements["decor-coat_bag_stand"] = {"grid": [32, 19], "facing": "south"}
	# Two-cell footprint. The acoustic divider needs the four-facing pocket this
	# station held beside the research bench. No single décor piece could move
	# without losing its own four-facing home, so this station moves to [22, 13]
	# and the printer shifts to [22, 17]. [22, 13] stays inside artwork and
	# standing headroom for every facing. North occupies [22, 13] and [23, 13];
	# west occupies [22, 12] and [22, 13]. Clear of Mina [11, 18], Creative
	# [14, 18], Theo [23, 18], and the founder capture cell [17, 18].
	state.placements["decor-water_station"] = {"grid": [22, 13], "facing": "south"}
	# Two-cell footprint. The south cluster and the cells beside Theo and the
	# research bench overlap this cart once décor rotates. [4, 18] stays valid
	# for every facing in the southwest lounge.
	state.placements["decor-resource_cart"] = {"grid": [4, 18], "facing": "south"}
	# Two-cell footprint. [22, 16] overlapped the water station once that station
	# moved to [22, 13] to free the divider. [22, 17] stays valid for every
	# facing one cell south of the old pocket. East occupies [22, 18], clear of
	# Theo [23, 18], Mina [11, 18], Creative [14, 18], and the founder capture
	# cell [17, 18].
	state.placements["decor-printer_scanner_station"] = {"grid": [22, 17], "facing": "south"}
	# Two-cell footprint. The cart [4, 18], water station [22, 13], and printer
	# [22, 17] already hold the other four-facing pockets. The sorter is shorter
	# than the printer, so [13, 19] on the open south floor stays inside artwork
	# and standing headroom for every facing while the other décor rotate. West
	# occupies [13, 18], which is clear of Mina [11, 18], Creative [14, 18],
	# Theo [23, 18], and the founder capture cell [17, 18].
	state.placements["decor-recycling_sorter"] = {"grid": [13, 19], "facing": "south"}
	# Two-cell footprint, same shape as the recycling sorter. The sprite is tall
	# (canvas [160, 288], pivot [80, 224], offset [0, -80]). The other eight
	# décor already hold every shared four-facing pocket, and the cabinet's art
	# overlaps the lamp at [25, 18] once both rotate. Moving that lamp to [7, 9]
	# leaves [25, 19] inside artwork and standing headroom for every facing.
	# West occupies [25, 18], clear of Theo [23, 18], Creative [14, 18], Mina
	# [11, 18], and the founder capture cell [17, 18]. The tall sprite stays
	# south of the desk row, so it does not cover an employee work cell.
	state.placements["decor-tall_storage_cabinet"] = {"grid": [25, 19], "facing": "south"}
	# Two-cell footprint, same shape as the supply cabinet. The sprite is tall
	# (canvas [160, 288], pivot [80, 224], offset [0, -80]) and slightly shorter
	# than the supply cabinet. The other nine décor already hold the shared
	# pockets, including the supply cabinet at [25, 19]. [25, 14] stays inside
	# artwork and standing headroom for every facing in that southeast column.
	# West occupies [25, 13], clear of Theo [23, 18], Creative [14, 18], Mina
	# [11, 18], and the founder capture cell [17, 18].
	state.placements["decor-server_cabinet"] = {"grid": [25, 14], "facing": "south"}
	# Two-cell footprint, mirrored from the utility cabinets: north [[-1,0],[0,0]],
	# east [[0,-1],[0,0]], south [[0,0],[1,0]], west [[0,0],[0,1]]. The sprite is
	# low (canvas [160, 160], pivot [80, 96], offset [0, -16]). The other ten
	# décor already hold every shared four-facing pocket, and the coat stand at
	# [19, 18] overlapped this south-floor pocket once both rotated. Moving that
	# coat stand to [32, 19] leaves [20, 19] inside artwork and standing headroom
	# for every facing. West occupies [20, 20]. Clearance stays off Mina [11, 18],
	# Creative [14, 18], Theo [23, 18], and the founder capture cell [17, 18].
	state.placements["decor-low_coffee_table"] = {"grid": [20, 19], "facing": "south"}
	# 3x3 footprint in every facing: occupied [[-1,-1]..[1,1]] in manifest
	# order, clearance one cell outside that square (north [0,-2], east [2,0],
	# south [0,2], west [-2,0]). Canvas [224, 288], pivot [112, 176], offset
	# [0, -32]. The other eleven décor already hold every shared four-facing
	# pocket, and the lamp at [7, 9] overlapped this coffee-bay square once
	# both rotated. Moving that lamp to [19, 14] leaves [7, 7] inside artwork
	# and standing headroom for every facing. Occupied is [6,6] through [8,8];
	# west clearance is [5, 7]. Clear of Mina [11, 18], Creative [14, 18],
	# Theo [23, 18], and the founder capture cell [17, 18].
	state.placements["decor-round_meeting_table"] = {"grid": [7, 7], "facing": "south"}
	# One-cell. The low bookshelf needs the four-facing plus this pedestal held
	# just south of the aisle. [32, 6] stays valid for every facing on the east
	# edge, north of the research bench and the planter at [32, 13], clear of
	# Mina [11, 18], Creative [14, 18], Theo [23, 18], and the founder capture
	# cell [17, 18].
	state.placements["decor-rolling_storage_pedestal"] = {"grid": [32, 6], "facing": "south"}
	# 3x1 when the shelf faces north or south, 1x3 when it faces east or west.
	# Occupied cells are the registration order (the geometry tool lists the
	# same cells): north [[1,0],[0,0],[-1,0]], east [[0,1],[0,0],[0,-1]],
	# south [[-1,0],[0,0],[1,0]], west [[0,-1],[0,0],[0,1]]. Clearance is the
	# front cell just outside that strip: north [0,-1], east [1,0], south
	# [0,1], west [-1,0]. Canvas [192, 224], pivot [96, 160], offset [0, -48].
	# No other shared four-facing pocket stayed free while the previous twelve
	# décor kept their cells. Moving the pedestal to [32, 6] leaves [7, 13]
	# inside artwork and standing headroom for every facing. North and south
	# occupy [6, 13] through [8, 13]; east and west occupy [7, 12] through
	# [7, 14]. West clearance is [6, 13]. Clear of Mina [11, 18], Creative
	# [14, 18], Theo [23, 18], and the founder capture cell [17, 18].
	state.placements["decor-low_bookshelf"] = {"grid": [7, 13], "facing": "south"}
	# 3x1 when the divider faces north or south, 1x3 when it faces east or west.
	# Occupied cells follow the registration proposal (the same cells as
	# acoustic_divider_geometry.gd; south and west reverse that tool's shared
	# order): north [[-1,0],[0,0],[1,0]], east [[0,-1],[0,0],[0,1]], south
	# [[1,0],[0,0],[-1,0]], west [[0,1],[0,0],[0,-1]]. The proposal leaves the
	# interaction cell empty and the geometry tool's clearance list is empty, so
	# clearance is the reference-axis front cell: north [0,-1], east [1,0],
	# south [0,1], west [-1,0]. Canvas [192, 224], pivot [96, 160], offset
	# [0, -48]. No four-facing pocket stayed free while the previous thirteen
	# décor kept their cells, and moving any one of them left that piece without
	# a home. Moving the water station to [22, 13] and the printer from [22, 16]
	# to [22, 17] leaves [23, 6] inside artwork and standing headroom for every
	# facing. North and south occupy [22, 6] through [24, 6]; east and west
	# occupy [23, 5] through [23, 7]. West clearance is [22, 6]. Clear of Mina
	# [11, 18], Creative [14, 18], Theo [23, 18], and the founder capture cell
	# [17, 18].
	state.placements["decor-acoustic_divider"] = {"grid": [23, 6], "facing": "south"}
	check(main.room.apply_furnishing_state(state), "Fourteen native starter decorations fit beside production stations")
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
		check(picker.item_count == 14, "Mature inventory presents all fourteen currently owned furnishings")
		await capture("mature-renovate-open")
		await ui_click(picker.get_global_rect().get_center())
		check(picker.get_popup().visible, "Actual pointer opens the mature inventory dropdown")
		check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(Rect2(Vector2(picker.get_popup().position), Vector2(picker.get_popup().size))), "All fourteen dropdown rows fit the native viewport")
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
			for id: String in ["decor-broadleaf_planter", "decor-task_floor_lamp", "decor-coat_bag_stand", "decor-water_station", "decor-resource_cart", "decor-printer_scanner_station", "decor-recycling_sorter", "decor-tall_storage_cabinet", "decor-server_cabinet", "decor-low_coffee_table", "decor-round_meeting_table", "decor-rolling_storage_pedestal", "decor-low_bookshelf", "decor-acoustic_divider"]: state.placements[id].facing = side
			check(main.room.apply_furnishing_state(state), side + " fourteen native decorations retain valid clearance/layer geometry")
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
