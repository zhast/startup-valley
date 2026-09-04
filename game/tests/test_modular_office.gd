extends SceneTree

## Deterministic integration proof for the modular room. The worker is never
## started; input still traverses the viewport GUI/unhandled-input pipelines.
const MAIN: PackedScene = preload("res://world/main.tscn")
const OUTPUT := "res://tests/output/modular-office"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var evidence: Array[Dictionary] = []
var checks := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func frames(count: int = 2) -> void:
	for index: int in range(count): await physics_frame

func fixture(count: int = 2) -> void:
	if is_instance_valid(main):
		main.game_audio.shutdown()
		main.free()
		await frames()
	main = MAIN.instantiate() as GameMain
	viewport.add_child(main)
	await frames(3)
	main.worker_client.set_process(false)
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
	var records: Array[EmployeeRecord] = main.room.placeholder_records()
	records.resize(mini(count, records.size()))
	main._spawn_employees(records)
	if count > records.size(): main.room.set_hire_count(count)
	for employee: EmployeeAvatar in main._employees.values():
		employee.set_physics_process(false)
		employee._has_target = false
		employee._route.clear()
		employee.labels_suppressed = true
	await frames(3)

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event, true)
		await frames(1)

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	# Synthetic viewport events do not update Input's held-action singleton.
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if InputMap.event_is_action(event, action):
			if down: Input.action_press(action)
			else: Input.action_release(action)
	viewport.push_input(event, true)
	await frames()

func capture(name: String, description: String = "") -> Image:
	await frames(3)
	if DisplayServer.get_name() == "headless": return null
	RenderingServer.force_draw(false)
	var rendered := root.get_texture().get_image()
	var path := OUTPUT.path_join(name + ".png")
	check(rendered.save_png(path) == OK, "Save rendered evidence " + name)
	evidence.append({"name": name, "description": description, "path": path, "size": [rendered.get_width(), rendered.get_height()]})
	return rendered

func physical_blocked(point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1 # Architecture/furniture, not the actor layer.
	return not viewport.world_2d.direct_space_state.intersect_point(query, 1).is_empty()

func place_founder(point: Vector2) -> void:
	main.player.cancel_route()
	main.player.position = point
	main.room.navigation.actors["founder"] = point

func free_ground(near: Vector2i) -> Vector2:
	for radius: int in range(12):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				var cell := near + Vector2i(dx, dy)
				var point := main.room.navigation.world(cell)
				if point.x > 720 or point.y < 150 or point.y > 640: continue
				if not main.room.navigation.walkable(cell): continue
				if not main.room.navigation._footprint_clear(point): continue
				if main.room.navigation._reserved_by_other(cell, "founder"): continue
				if main._interaction_at(point).is_empty(): return point
	check(false, "Find unobstructed ground input target")
	return main.room.grid_to_world_position(main.room.player_spawn)

func wait_founder(limit: int = 480) -> void:
	for index: int in range(limit):
		if main.player.route.is_empty(): return
		check(main.room.navigation._footprint_clear(main.player.position), "Founder route keeps its entire footprint clear")
		await frames(1)
	check(false, "Founder path must finish within the deterministic frame budget")

func wait_employee(employee: EmployeeAvatar, limit: int = 600) -> void:
	for index: int in range(limit):
		if not employee._has_target: return
		check(main.room.navigation._footprint_clear(employee.position), employee.employee_id + " route keeps its entire footprint clear")
		await frames(1)
	check(false, employee.employee_id + " must reach its declared work destination")

func test_shared_geometry() -> void:
	for stage: int in [0, 1, 2, 3, 4]:
		await fixture(stage)
		var model := main.room.layout_model
		var placements: Array[Dictionary] = main.room.resolved_placements
		var result: Dictionary = model.validate_placements(placements)
		check(bool(result.valid), "Stage %d passes the room model's placement validation: %s" % [stage, result.errors])
		check(main.room.position == Vector2.ZERO, "Room and full-screen architecture share one origin")
		check(main.room.tile_size == 32 and main.room.grid_width == 40 and main.room.grid_height == 23, "Room uses the declared native 32px composition")
		var occupied: Dictionary[Vector2i, String] = {}
		for placement: Dictionary in placements:
			var prop := main.room.prop_node(str(placement.id))
			check(prop != null, "Resolved placement renders a prop: " + str(placement.id))
			if prop != null:
				check(prop.position == main.room.grid_to_local_position(placement.grid), "Rendered anchor comes from resolved placement: " + str(placement.id))
				check(prop.rotation == 0 and prop.scale == Vector2.ONE, "Only authored native furniture orientation: " + str(placement.id))
			for cell: Vector2i in placement.occupied:
				occupied[cell] = str(placement.id)
				check(not main.room.navigation.walkable(cell), "Footprint blocks navigation: %s %s" % [placement.id, cell])
				check(physical_blocked(main.room.navigation.world(cell)), "Footprint blocks physical movement: %s %s" % [placement.id, cell])
			var target: Vector2i = placement.interaction
			check(main.room.navigation.walkable(target), "Interaction stays walkable: " + str(placement.id))
			check(not physical_blocked(main.room.navigation.world(target)), "Interaction is not physically inside furniture: " + str(placement.id))
			var route := main.room.navigation.grid.get_id_path(main.room.player_spawn, target)
			check(not route.is_empty(), "Entrance can reach interaction: " + str(placement.id))
		for y: int in range(main.room.grid_height):
			for x: int in range(main.room.grid_width):
				var cell := Vector2i(x, y)
				var expected := model.is_floor(cell) and not occupied.has(cell)
				check(main.room.navigation.walkable(cell) == expected, "Navigation exactly agrees with architecture and resolved occupancy at %s stage %d" % [cell, stage])
				if not model.is_floor(cell):
					check(physical_blocked(main.room.navigation.world(cell)), "Non-floor geometry has wall collision at " + str(cell))
		await capture("stage-%d" % stage, "Actual game at hire stage %d, validated against shared geometry." % stage)

func test_migration_and_growth() -> void:
	await fixture(0)
	var retained_journey := {"company": {"cashCents": 98765, "reputation": 17}, "milestones": [{"id": "website", "state": "completed"}]}
	main._journey = retained_journey.duplicate(true)
	var safe := free_ground(Vector2i(16, 17)) + Vector2(2.0, 1.0)
	main._journey.player = {"x": safe.x, "y": safe.y, "movementSeen": true}
	main._restore_player()
	check(main.player.position == safe, "Valid fractional saved position is retained exactly")
	main._journey.player = {"x": 5.0, "y": 5.0}
	main._restore_player()
	check(main.player.position != Vector2(5, 5) and main.room.navigation._footprint_clear(main.player.position), "Legacy position in a wall relocates to safe room floor")
	# A center in a floor cell is insufficient if feet overlap its boundary.
	main._journey.player = {"x": 32.1, "y": 400.0}
	main._restore_player()
	check(main.room.navigation._footprint_clear(main.player.position), "Legacy boundary-edge position validates its full footprint")
	var records := main.room.placeholder_records()
	var future: Array[Dictionary] = main.room.layout_model.resolve_placements(2)
	var future_mina: Dictionary = {}
	var future_theo: Dictionary = {}
	for placement: Dictionary in future:
		if placement.id == "mira-workstation": future_mina = placement
		if placement.id == "theo-workstation": future_theo = placement
	place_founder(main.room.navigation.world(future_mina.occupied[0]))
	main._spawn_employees([records[0]])
	await frames(3)
	check(main.room.navigation._footprint_clear(main.player.position), "Hiring Mina relocates founder standing under arriving furniture")
	var mina := main.get_employee("mira")
	mina.set_physics_process(false)
	mina.position = main.room.navigation.world(future_theo.occupied[0])
	main.room.navigation.actors["mira"] = mina.position
	main._spawn_employees(records)
	await frames(3)
	check(main.room.navigation._footprint_clear(mina.position), "Hiring Theo relocates employee standing under arriving furniture")
	var destinations: Dictionary[Vector2i, String] = {}
	for employee: EmployeeAvatar in main._employees.values():
		employee.set_physics_process(false)
		var cell := main.room.navigation.cell_at(employee.position)
		check(not destinations.has(cell), "New hire and relocated employee finish on distinct cells")
		destinations[cell] = employee.employee_id
		check(employee.desk_position == main.room.employee_desk_position(employee.employee_id), "Employee work destination refreshes from resolved desk")
	check(main._journey.company == retained_journey.company and main._journey.milestones == retained_journey.milestones, "Geometry migration does not reset company finances or milestone progress")
	# Explicitly invalid old desk coordinates must not reconstruct the old shell.
	records[0].desk_grid = Vector2i(-20, -20)
	main._spawn_employees(records)
	var resolved := main.room.placement_by_id("mira-workstation")
	check(resolved.grid != records[0].desk_grid, "Invalid legacy desk coordinates use the validated fallback bay")
	check(main.room.layout_model.validate_placements(main.room.resolved_placements).valid, "Fallback desk migration retains a valid arrangement")
	var before_invalid: Vector2i = main.room.placement_by_id("mira-workstation").grid
	var revision_before_invalid := main.room.navigation.revision
	check(not main.room.set_placement_overrides({"mira-workstation": {"grid": Vector2i(0, 0), "facing": "west"}}), "Runtime rejects invalid developer placements instead of partially applying them")
	check(main.room.placement_by_id("mira-workstation").grid == before_invalid and main.room.navigation.revision == revision_before_invalid, "Rejected layout leaves rendered and navigation placement unchanged")
	var valid_legacy := Vector2i(-1, -1)
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(2, 0)]:
		var candidate: Vector2i = resolved.grid + offset
		if main.room.layout_model.validate_candidate("mira-workstation", candidate, "south", 4).valid:
			valid_legacy = candidate
			break
	check(valid_legacy.x >= 0, "Fixture locates a genuinely valid alternative legacy desk position")
	if valid_legacy.x >= 0:
		records[0].desk_grid = valid_legacy
		main._spawn_employees(records)
		check(main.room.placement_by_id("mira-workstation").grid == valid_legacy, "Valid legacy desk coordinates are preserved, not silently discarded")
		check(main.get_employee("mira").desk_position == main.room.employee_desk_position("mira"), "Existing employee destination follows a preserved legacy desk position")
	await capture("growth-relocation", "Founder and employee safely relocated when their occupied floor cells became new furniture; company progress retained.")

func test_input_and_interactions() -> void:
	await fixture(2)
	var start := free_ground(Vector2i(16, 18))
	var target := free_ground(Vector2i(19, 18))
	place_founder(start)
	await click(target)
	check(not main.player.route.is_empty(), "Real ground click starts click-to-move")
	await wait_founder()
	check(main.player.position.distance_to(target) <= 3, "Click-to-move reaches the chosen ground point")
	await click(start)
	await key(KEY_A, true)
	check(main.player.route.is_empty(), "Keyboard movement immediately cancels a click path")
	await key(KEY_A, false)
	var before := main.player.position
	await key(KEY_D, true)
	await frames(12)
	await key(KEY_D, false)
	check(main.player.position.x > before.x + 10, "Real held keyboard input moves the founder")
	await click(Vector2(8, 300))
	check(main.player.route.is_empty(), "Wall click rejects movement")
	await click(main.job_panel._team_buttons["mira"].get_global_rect().get_center())
	check(main.job_panel.drawer_is_open() and main.player.route.is_empty(), "Team rail click selects employee without moving through UI")
	await frames(12)
	before = main.player.position
	await key(KEY_D, true)
	await frames(12)
	await key(KEY_D, false)
	check(main.player.position == before, "Drawer prevents underlying world movement")
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	await frames(12)
	check(not main.job_panel.drawer_is_open(), "Escape closes the drawer through actual input")
	for station: String in ["founder-workstation", "artifact-archive", "approval-console", "mira-workstation", "theo-workstation"]:
		main.company_panel.hide()
		main.job_panel.close_drawer(false)
		await frames(2)
		var prop := main.room.prop_node(station)
		var hit := station_hit(station, prop.global_position)
		check(hit != Vector2.INF, "Resolved hit target is discoverable for " + station)
		if hit == Vector2.INF: continue
		var interaction: Dictionary = main.room.interaction_at(hit)
		check(str(interaction.get("id", "")) == station, "Room-owned click target retains station identity: " + station)
		var approach: Vector2 = interaction.point
		place_founder(main.room.navigation.world(main.room.navigation.nearest(approach + Vector2(0, 96), "founder")))
		await click(hit)
		await wait_founder(720)
		await frames(14)
		if station == "founder-workstation":
			check(main.company_panel.visible, "Founder desk opens Company Journey on arrival")
		else:
			var tab := 3 if station == "artifact-archive" else 2 if station == "approval-console" else 1
			check(main.job_panel.drawer_is_open() and main.job_panel._tabs.current_tab == tab, "Station opens its declared interface on arrival: " + station)
	main.company_panel.hide()
	main.job_panel.close_drawer(false)
	await frames(2)
	var mina := main.get_employee("mira")
	place_founder(main.room.navigation.world(main.room.navigation.nearest(mina.position + Vector2(0, 112), "founder")))
	await click(mina.position + Vector2(0, -38))
	await wait_founder()
	await frames(12)
	check(main.job_panel.drawer_is_open() and main.job_panel.selected_employee_id() == "mira", "Clicking employee walks over and opens their Chat")
	await capture("employee-chat", "Real employee click-to-interact and no UI-to-world click leakage.")

func station_hit(id: String, anchor: Vector2) -> Vector2:
	# Search the visible authored footprint, not a magic fixed prop rectangle.
	for y: int in range(-10, -100, -4):
		for x: int in range(-48, 49, 4):
			var point := anchor + Vector2(x, y)
			var hit: Dictionary = main._interaction_at(point)
			if str(hit.get("id", "")) == id: return point
	return Vector2.INF

func test_workstation_bay() -> void:
	await fixture(1)
	var mina := main.get_employee("mira")
	mina.set_physics_process(true)
	mina._idle_cooldown = 1000
	mina.walk_to(mina.desk_position, EmployeeAvatar.WorkState.IDLE_WALKING, EmployeeAvatar.WorkState.SITTING)
	check(mina._has_target, "Workstation chair is reachable from the employee spawn")
	await wait_employee(mina)
	check(mina.work_state == EmployeeAvatar.WorkState.SITTING and mina.position.distance_to(main.room.employee_desk_position("mira")) < 1, "Employee reaches authored chair anchor and sits")
	mina.set_physics_process(false)
	mina._physics_process(0)
	var desk := main.room.prop_node("mira-workstation")
	var rear := desk.get_node("WorkstationRear") as Sprite2D
	var front := desk.get_node("WorkstationFront") as Sprite2D
	check(rear.z_index < mina.z_index and mina.z_index < front.z_index, "Chair/employee/front desktop have correct depth order")
	check(rear.position == front.position and rear.scale == Vector2.ONE and front.scale == Vector2.ONE, "Workstation layers retain one native registered origin")
	check(mina._character_sprite.texture == CharacterArt.seated_sheet("mira"), "Sitting uses the corrected reusable chair pose")
	await capture("bay-seated", "One complete workstation bay: reachable rear chair, actor between furniture layers, native pixels.")
	mina.has_live_job = true
	mina.apply_worker_event(WorkerEventRecord.from_dictionary({"type": "tool.started", "tool": "write_file"}), main.player.position)
	var hashes: Dictionary = {}
	for index: int in range(4):
		mina._animation_elapsed = float(index) / 8.0
		mina._update_character_frame()
		var image := await capture("bay-typing-%d" % index, "Actual worker-event typing frame %d above the desktop." % index)
		if image != null:
			var crop := image.get_region(Rect2i(Vector2i(mina.position) - Vector2i(24, 72), Vector2i(48, 80)))
			hashes[hash(crop.get_data())] = true
	check(mina.work_state == EmployeeAvatar.WorkState.TYPING, "Write event selects typing at the declared chair")
	if DisplayServer.get_name() != "headless": check(hashes.size() >= 2, "At least two typing poses remain visibly different after furniture occlusion")
	mina.has_live_job = false
	mina.set_physics_process(true)
	mina.walk_to(mina.home_position, EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
	await wait_employee(mina)
	check(mina.position.distance_to(mina.home_position) < 1, "Employee can leave the chair and return to the room")
	mina.set_physics_process(false)
	await capture("bay-exit", "Employee can leave the workstation without crossing its occupied floor cells.")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
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
	await test_shared_geometry()
	await test_migration_and_growth()
	await test_input_and_interactions()
	await test_workstation_bay()
	await fixture(2)
	root.size = Vector2i(1600, 900)
	await capture("office-1600x900", "Aspect-preserved resized presentation of the native 1280x720 room.")
	# A fast headless check must not erase the rendered capture evidence index.
	var manifest_name := "integration-headless.json" if DisplayServer.get_name() == "headless" else "integration-manifest.json"
	var manifest := FileAccess.open(OUTPUT.path_join(manifest_name), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"checks": checks, "failures": failures, "worker": "disabled", "captures": evidence}, "\t"))
	manifest.close()
	if failures.is_empty() and OS.get_cmdline_user_args().has("--interactive"):
		print("Modular office interactive fixture ready; worker disabled, no user save writes.")
		return
	main.game_audio.shutdown()
	main.free()
	if failures.is_empty(): print("Modular office integration: %d checks passed, %d rendered captures" % [checks, evidence.size()])
	quit(failures.size())
