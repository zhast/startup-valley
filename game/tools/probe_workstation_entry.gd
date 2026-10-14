extends "res://tools/play_calibrated_workstation.gd"
## Dev-only handoff probe. Inherits the real old entry without replacing its UI.
const OUTPUT := "res://tests/output/workstation-entry-before/"
var checks := 0
var failures: Array[String] = []
var snapshots: Array[Dictionary] = []

func output_directory() -> String: return OUTPUT

func launch_viewer() -> void: await super.run()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames(count: int) -> void:
	for tick: int in range(count): await process_frame

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await frames(2)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames(2)

func action(copy: String) -> void:
	await click(fixture.editor.action_buttons[copy].get_global_rect().get_center())

func snapshot(label: String) -> void:
	await frames(3)
	var toolbar: Rect2 = fixture.editor._inspector.get_parent().get_global_rect()
	var sample := {"name": label, "toolbar": str(toolbar), "labels": []}
	for actor: EmployeeAvatar in fixture.main._employees.values():
		var visible := not actor.labels_suppressed and (actor._labels_visible() or actor._speech_visible or actor.attention_cue_visible())
		var rect := actor.world_label_rect()
		sample.labels.append({"employee": actor.employee_id, "visible": visible, "rect": str(rect), "toolbar_overlap": visible and rect.intersects(toolbar)})
	# Before evidence is observational; a defect is recorded, not suppressed.
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(output_directory() + label + ".png") == OK, "Saved " + label)
	snapshots.append(sample)

func settle(actor: EmployeeAvatar) -> void:
	for tick: int in range(600):
		await process_frame
		if not actor._has_target and not actor._waiting_for_desk and not actor._seat_transition_active: return
	check(false, "Actual actor path settled within bounded time")

func run() -> void:
	await launch_viewer()
	if fixture == null or not fixture.ready_ok: return
	root.gui_embed_subwindows = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	await snapshot("initial")
	await frames(12)
	await snapshot("settled")
	var roster_size := fixture.main._employees.size()
	check(roster_size >= 2 and roster_size <= 3 and fixture.main._employees.has("mira") and fixture.main._employees.has("theo") and (roster_size == 2 or fixture.main._employees.has("creative")), "Real entry roster is two or three authored employees")
	check(fixture.main.worker_client._stdio == null and fixture.main.worker_client._process_id == -1 and not fixture.main._state_loaded and not fixture.main._worker_ready, "Null transport, no process, no personal state")
	for actor: EmployeeAvatar in fixture.main._employees.values(): actor._idle_cooldown = 999
	var mina: EmployeeAvatar = fixture.main.get_employee("mira")
	await action("Sit")
	check(mina._has_target, "Real Sit click starts existing navigation")
	await settle(mina)
	check(mina.work_state == EmployeeAvatar.WorkState.SITTING and mina.position == mina.desk_position, "Real Sit arrives at authored seat")
	await snapshot("seated")
	await action("Type")
	await settle(mina)
	check(mina.work_state == EmployeeAvatar.WorkState.TYPING, "Real Type click selects existing diagnostic typing pose")
	await snapshot("typing")
	var old: Dictionary = fixture.main.room.placement_overrides.duplicate(true)
	var foot := mina.position
	await action("Rotate [R]")
	check(fixture.editor.placement_active and not fixture.editor.preview_result.valid, "Occupied rotation rejected")
	await click(fixture.model.world(fixture.editor.preview_grid))
	check(fixture.main.room.placement_overrides == old and mina.position == foot and "Leave desk" in fixture.editor._status.text, "Rejected rotation preserves physical foot and gives actionable Leave instruction")
	await snapshot("occupied-rotation")
	await action("Leave")
	check(not fixture.editor.placement_active and mina._has_target, "Real Leave cancels preview then walks away")
	await settle(mina)
	check(mina.position == mina.home_position and mina.work_state == EmployeeAvatar.WorkState.IDLE, "Actual Leave returns home")
	await snapshot("left")
	await action("Rotate [R]")
	check(fixture.editor.preview_result.valid, "Unoccupied rotation is valid")
	await click(fixture.model.world(fixture.editor.preview_grid))
	check(not fixture.editor.placement_active and fixture.main.room.placement_by_id("mira-workstation").facing == "west", "Real world click commits West after leaving")
	await snapshot("rotated")
	await action("Sit")
	await settle(mina)
	check(mina.work_state == EmployeeAvatar.WorkState.SITTING and mina.position == mina.desk_position, "Real Sit after rotation reaches new work cell")
	await snapshot("west-seated")
	var model: OfficeLayout = fixture.model
	fixture.free()
	fixture = null
	await frames(2)
	check(not model.calibration_preview_enabled(), "Closing viewer revokes local admission")
	var file := FileAccess.open(output_directory() + ("headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "snapshots": snapshots, "unmodified_old_entry": true, "scope": "Real old two-employee entry; Sit/Type are diagnostic art controls, not real jobs."}, "\t"))
	print("Workstation entry probe: %d checks / %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
