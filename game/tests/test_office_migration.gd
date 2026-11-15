extends SceneTree

const MAIN: PackedScene = preload("res://world/main.tscn")
const OUTPUT := "res://tests/output/office-migration"
var failures: Array[String] = []
var checks := 0
var main: GameMain

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func fixture() -> void:
	if main != null:
		main.free()
		await process_frame
	main = MAIN.instantiate() as GameMain
	root.add_child(main)
	await process_frame
	main.company_panel.hide()
	main.job_panel.set_credential_status(true)
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	main.player.set_physics_process(false)
	main.day_clock.set_speed(0)
	main.day_clock.set_time(1, DayClock.WORK_START)
	for employee: EmployeeAvatar in main._employees.values():
		employee.set_physics_process(false)
		employee.world_paused = false
		employee._has_target = false
		employee.position = main.room.employee_spawn_position(employee.employee_id)
		main.room.navigation.actors[employee.employee_id] = employee.position

func place_founder(point: Vector2) -> void:
	main.player.cancel_route()
	main.player.position = point
	main.room.navigation.actors["founder"] = point

func advance(employee: EmployeeAvatar, count: int) -> void:
	for index: int in range(count): employee._physics_process(1.0 / 60.0)

func arrive(employee: EmployeeAvatar) -> void:
	for frame: int in range(900):
		employee._physics_process(1.0 / 60.0)
		check(main.room.navigation._footprint_clear(employee.position), "Seat retry routes stay outside walls/furniture")
		if employee.work_state == EmployeeAvatar.WorkState.TYPING:
			check(employee.position.distance_to(main.room.employee_desk_position(employee.employee_id)) < 0.5, "Typing only renders at the resolved seat")
		if not employee._has_target and not employee._waiting_for_desk: return
	check(false, "Employee reaches the exact seat after it becomes free")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await test_occupied_seat()
	await test_restore_founder_priority()
	await test_joint_desk_migration()
	await test_growth_reservations()
	await test_roster_growth_reservations()
	await test_waiting_desk_move()
	await test_atomic_reload()
	main.free()
	main = null
	if failures.is_empty(): print("Office migration: %d checks passed" % checks)
	else: print("Office migration failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func test_occupied_seat() -> void:
	await fixture()
	var employee := main.get_employee("mira")
	var seat := main.room.employee_desk_position("mira")
	var before := employee.position
	place_founder(seat)
	employee.has_live_job = true
	var writing := WorkerEventRecord.new()
	writing.type = &"tool.started"
	writing.tool = "write_file"
	employee.apply_worker_event(writing, main.player.position)
	advance(employee, 120)
	check(employee.desk_position == seat, "Occupied seat never rewrites the authored desk destination")
	check(employee._waiting_for_desk and not employee._has_target, "Employee waits for the exact seat instead of claiming adjacent floor")
	check(employee.position == before and employee.work_state == EmployeeAvatar.WorkState.WALKING_TO_DESK, "Waiting employee does not use seated/typing art away from furniture")
	check(employee.has_live_job, "Seat obstruction does not fail or restart live work")
	place_founder(main.room.grid_to_world_position(main.room.player_spawn))
	employee.world_paused = true
	advance(employee, 60)
	check(employee._waiting_for_desk and employee.position == before, "World pause also pauses seat retry movement")
	employee.world_paused = false
	arrive(employee)
	check(employee.position == seat and employee.desk_position == seat, "Founder moving away allows exact authored seat arrival")
	check(employee.work_state == EmployeeAvatar.WorkState.TYPING and employee._character_sprite.texture == CharacterArt.seated_sheet("mira"), "Real write event resumes the corrected seated typing pose")
	check(main.room.navigation.reservations.get("mira") == main.room.navigation.cell_at(seat), "Successful arrival reserves the actual seat")
	# Another actor's reservation is just as temporary as their physical position.
	employee.position = before
	main.room.navigation.actors["mira"] = before
	main.room.navigation.reservations["theo"] = main.room.navigation.cell_at(seat)
	employee.walk_to(seat, EmployeeAvatar.WorkState.WALKING_TO_DESK, EmployeeAvatar.WorkState.TYPING)
	advance(employee, 30)
	check(employee._waiting_for_desk and employee.desk_position == seat, "Reserved seat cannot redirect the employee to a substitute desk")
	main.room.navigation.release("theo")
	arrive(employee)
	check(employee.position == seat, "Released reservation retries to the authored seat")
	# Terminal job events must retire retry state, not silently resurrect work.
	employee.position = before
	main.room.navigation.actors["mira"] = before
	place_founder(seat)
	employee.apply_worker_event(writing, main.player.position)
	var failed := WorkerEventRecord.new()
	failed.type = &"job.failed"
	employee.apply_worker_event(failed, main.player.position)
	advance(employee, 30)
	check(not employee._waiting_for_desk and not employee.has_live_job and employee.work_state == EmployeeAvatar.WorkState.IDLE, "Failed work cancels pending seat retry")
	# A navigation rebuild during a desk approach must also retain its exact seat.
	place_founder(main.room.grid_to_world_position(main.room.player_spawn))
	employee.has_live_job = true
	employee.apply_worker_event(writing, main.player.position)
	advance(employee, 4)
	place_founder(seat)
	main.room.navigation.rebuild_placements(main.room.resolved_placements)
	advance(employee, 30)
	check(employee._waiting_for_desk and employee.desk_position == seat, "Rebuilt navigation cannot substitute a nearby occupied-seat fallback")
	place_founder(main.room.grid_to_world_position(main.room.player_spawn))
	arrive(employee)
	check(employee.position == seat, "Revision retry reaches the same workstation")

func test_restore_founder_priority() -> void:
	await fixture()
	var saved := main.room.employee_spawn_position("mira") + Vector2(1.25, -0.5)
	main.get_employee("mira").position = saved
	main.room.navigation.actors["mira"] = saved
	var company := {"cashCents": 98345, "reputation": 23}
	var milestones := [{"id": "website", "state": "completed"}]
	main._journey = {"player": {"x": saved.x, "y": saved.y}, "company": company.duplicate(true), "milestones": milestones.duplicate(true)}
	main._restore_player()
	check(main.player.position == saved, "Valid fractional founder save wins over a temporary NPC spawn")
	check(main.get_employee("mira").position.distance_to(saved) >= 20, "Conflicting default NPC moves safely instead of displacing the saved founder")
	check(main.room.navigation.position_is_safe(main.get_employee("mira").position, "mira"), "Relocated NPC remains in valid floor clearance")
	check(main._journey.company == company and main._journey.milestones == milestones, "Restoring room positions does not mutate company progression")
	main._restore_player()
	check(main.player.position == saved, "Repeated restore preserves the exact founder position")
	# A prior seated actor cannot remain in a chair pose after being relocated.
	var mina := main.get_employee("mira")
	var seat := main.room.employee_desk_position("mira")
	mina.position = seat
	mina.work_state = EmployeeAvatar.WorkState.SITTING
	main._journey.player = {"x": seat.x, "y": seat.y}
	main._restore_player()
	check(main.player.position == seat and mina.position.distance_to(seat) >= 20, "Restore at an occupied chair prioritizes founder without actor overlap")
	check(mina._waiting_for_desk and mina.work_state == EmployeeAvatar.WorkState.WALKING_TO_DESK, "Relocated seated employee waits instead of sitting on open floor")
	main._journey.player = {"x": 2, "y": 2}
	main._restore_player()
	check(main.room.navigation._footprint_clear(main.player.position), "Invalid legacy founder coordinates still relocate away from walls")

func test_joint_desk_migration() -> void:
	await fixture()
	var records := main.room.placeholder_records()
	var original_mina := records[0].desk_grid
	var original_theo := records[1].desk_grid
	records[0].desk_grid = original_theo
	records[1].desk_grid = original_mina
	main._spawn_employees(records)
	check(main.room.placement_by_id("mira-workstation").grid == original_theo and main.room.placement_by_id("theo-workstation").grid == original_mina, "A valid joint saved desk swap is accepted atomically")
	check(main.get_employee("mira").desk_position == main.room.employee_desk_position("mira"), "Swapped desk retains Mina ownership and work point")
	check(main.get_employee("theo").desk_position == main.room.employee_desk_position("theo"), "Swapped desk retains Theo ownership and work point")
	var mina_only: Array[EmployeeRecord] = [records[0]]
	main._spawn_employees(mina_only)
	main._spawn_employees(records)
	check(main.room.placement_by_id("mira-workstation").grid == original_theo and main.room.placement_by_id("theo-workstation").grid == original_mina, "Valid joint saved coordinates survive hire-stage changes")
	check(main.room.migration_notes.is_empty(), "A safe desk swap is not incorrectly reported as invalid")

func test_atomic_reload() -> void:
	await fixture()
	var before := main.room.layout_model
	var before_prop := main.room.prop_node("mira-workstation")
	var before_revision := main.room.navigation.revision
	check(not main.room.load_layout(OUTPUT.path_join("does-not-exist.json")), "Missing replacement room is rejected")
	check(main.room.layout_model == before and main.room.navigation.revision == before_revision and main.room.prop_node("mira-workstation") == before_prop, "Missing reload leaves model, navigation, and rendered props unchanged")
	var invalid := before.data.duplicate(true)
	invalid.props[0].grid = [0, 0]
	var file := FileAccess.open(OUTPUT.path_join("invalid-layout.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid))
	file.close()
	check(not main.room.load_layout(OUTPUT.path_join("invalid-layout.json")), "Geometrically invalid replacement room is rejected")
	check(main.room.layout_model == before and main.room.navigation.revision == before_revision and main.room.prop_node("mira-workstation") == before_prop, "Invalid reload cannot partially replace a working room")
	check(main.room.load_layout(), "Valid authored room remains reloadable after rejection")
	check(main.room.layout_model.validate_placements(main.room.resolved_placements).valid, "Successful reload swaps a complete validated geometry")

func test_growth_reservations() -> void:
	await fixture()
	var mina := main.get_employee("mira")
	var theo := main.get_employee("theo")
	var research := main.room.research_position()
	mina.has_live_job = true
	mina.walk_to(research, EmployeeAvatar.WorkState.WALKING_TO_RESEARCH, EmployeeAvatar.WorkState.WORKING)
	# Theo steps into the destination after Mina's original route was planned.
	# Growing the room must know about BOTH actors before it replans Mina.
	theo.position = research
	theo.has_live_job = true
	theo._has_target = false
	theo.work_state = EmployeeAvatar.WorkState.WORKING
	main.room.navigation.actors["theo"] = research
	main.room.set_hire_count(4)
	check(main.room.navigation.actors.size() == 1 + main._employees.size(), "Growth registers the founder and every employee before renewed routes")
	check(mina._has_target and not mina._route.is_empty(), "Research approach survives office growth")
	check(mina._route[-1].distance_to(theo.position) >= 20, "Growth replan cannot claim a later employee's current position")
	var reserved: Dictionary[Vector2i, String] = {}
	for id: String in main.room.navigation.reservations:
		var cell: Vector2i = main.room.navigation.reservations[id]
		check(not reserved.has(cell), "Office growth cannot create duplicate destination reservations")
		reserved[cell] = id
	arrive(mina)
	check(mina.position.distance_to(theo.position) >= 20, "Replanned employees finish separated")
	check(mina.has_live_job and theo.has_live_job, "Growth does not reset active employee jobs")
	check(mina.research_position == research and mina._arrival_state == EmployeeAvatar.WorkState.WORKING, "Growth keeps authoritative research target and arrival state")

func test_waiting_desk_move() -> void:
	await fixture()
	var mina := main.get_employee("mira")
	place_founder(mina.desk_position)
	mina.has_live_job = true
	mina.walk_to(mina.desk_position, EmployeeAvatar.WorkState.WALKING_TO_DESK, EmployeeAvatar.WorkState.TYPING)
	check(mina._waiting_for_desk, "Desk-move fixture starts with a genuinely blocked seat")
	# [12, 7] sits in Creative's north clearance once that desk unlocks. [24, 8]
	# stays a free south bay at every hire stage, including the Creative desk.
	var overrides := {"mira-workstation": {"grid": [24, 8], "facing": "south"}}
	var moved := main.room.layout_model.placement_by_id("mira-workstation", 2, overrides)
	var new_seat := main.room.grid_to_world_position(moved.work_cell)
	# Keep the new seat occupied too, without ticking the old waiting request.
	place_founder(new_seat)
	check(main.room.set_placement_overrides(overrides), "Validated desk move is applied while a worker waits")
	check(mina.desk_position == new_seat and mina._requested_target == new_seat, "Pending seat retry immediately follows the moved authored workstation")
	check(mina._waiting_for_desk and not mina._has_target, "Moved but still occupied seat remains waiting rather than claiming nearby floor")
	check(mina._arrival_state == EmployeeAvatar.WorkState.TYPING and mina.has_live_job, "Moving furniture preserves pending typing arrival and active job")
	place_founder(main.room.grid_to_world_position(main.room.player_spawn))
	arrive(mina)
	check(mina.position == new_seat and mina.work_state == EmployeeAvatar.WorkState.TYPING, "Releasing the moved seat resumes typing at the new exact workstation")

func test_roster_growth_reservations() -> void:
	await fixture()
	var records := main.room.placeholder_records()
	var mina := main.get_employee("mira")
	var theo := main.get_employee("theo")
	mina.has_live_job = true
	mina.walk_to(main.room.research_position(), EmployeeAvatar.WorkState.WALKING_TO_RESEARCH, EmployeeAvatar.WorkState.WORKING)
	theo.position = main.room.research_position()
	theo.has_live_job = true
	theo._has_target = false
	theo.work_state = EmployeeAvatar.WorkState.WORKING
	main.room.navigation.actors["theo"] = theo.position
	main._spawn_employees(records)
	check(mina._has_target and main.room.navigation.reservations.get("mira") == main.room.navigation.cell_at(mina._route[-1]), "Roster refresh retains moving employee's destination reservation instead of replacing it with current feet")
	check(main.room.navigation.reservations.get("mira") != main.room.navigation.reservations.get("theo"), "Roster refresh cannot duplicate a stationary teammate's reservation")
	check(mina.has_live_job and theo.has_live_job, "Roster refresh retains live job identities")
	arrive(mina)
	# The real hiring flow adds Theo after geometry changes. Mina's old route
	# may target Theo's new spawn, which must be known before her route renews.
	main._spawn_employees([records[0]])
	mina = main.get_employee("mira")
	mina.set_physics_process(false)
	mina.position = main.room.employee_spawn_position("mira")
	main.room.navigation.actors["mira"] = mina.position
	var new_spawn := main.room.employee_spawn_position("theo")
	mina.walk_to(new_spawn, EmployeeAvatar.WorkState.DELIVERING, EmployeeAvatar.WorkState.IDLE)
	main._spawn_employees(records)
	theo = main.get_employee("theo")
	theo.set_physics_process(false)
	check(mina._has_target and mina._route[-1].distance_to(theo.position) >= 20, "New hire is registered before existing employee route replans")
	check(main.room.navigation.reservations.get("mira") == main.room.navigation.cell_at(mina._route[-1]), "Actual hire flow retains the renewed arrival reservation")
	check(main.room.navigation.reservations.get("mira") != main.room.navigation.reservations.get("theo"), "New hire and arriving employee own distinct destinations")
	check(mina._requested_target == new_spawn and mina._arrival_state == EmployeeAvatar.WorkState.IDLE, "Roster growth preserves original delivery intent and arrival state")
	arrive(mina)
	check(mina.position.distance_to(theo.position) >= 20, "Delivery completes without intersecting newly hired employee")
