extends SceneTree
## Worker-free integrated UI state projection; physical animation remains separate.

var checks := 0
var failures: Array[String] = []
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
		main.game_audio.shutdown()
		main.free()
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.day_clock.set_time(1, DayClock.WORK_START)
	main.game_audio.set_volumes(0, 0)
	# Completed-event follow-ups cannot reach a process; omit the expected offline UI error.
	main.worker_client.request_failed.disconnect(main.job_panel.set_error)
	main.job_panel.set_credential_status(true)
	main.job_panel.set_worker_ready()
	main.job_panel.select_employee("mira")
	main.job_panel.open_drawer(false)
	for employee: EmployeeAvatar in main._employees.values(): employee.set_physics_process(false)
	check(main.worker_client._stdio == null and main.worker_client._process_id == -1, "Fixture never starts a worker or opens saved company state")

func event(kind: StringName) -> void:
	var record := WorkerEventRecord.new()
	record.type = kind
	record.approval_id = "fixture-approval" if kind == &"approval.required" else ""
	main._on_job_event("fixture-job", record)

func begin() -> void:
	main._job_employees["fixture-job"] = "mira"
	main.job_panel.begin_job("fixture-job", "mira")
	main.job_panel.accept_submission("fixture-job")

func project(expected: String) -> void:
	var employee := main.get_employee("mira")
	main.job_panel.select_employee("mira")
	main.job_panel.open_drawer(false)
	var before := [employee.position, employee.work_state, employee._has_target, employee._route.duplicate(), employee._arrival_state, employee.has_live_job]
	main._process(0)
	check(employee.presentation_label() == expected, "World label uses business presentation: %s (actual %s)" % [expected, employee.presentation_label()])
	check([employee.position, employee.work_state, employee._has_target, employee._route, employee._arrival_state, employee.has_live_job] == before, "UI projection does not change route, position or work animation")
	check(employee._ui_highlighted and employee._label_detail_visible(), "Selected actor exposes the projected detail")
	check(EmployeeAvatar.STATUS_FONT.get_string_size(expected, HORIZONTAL_ALIGNMENT_LEFT, -1, EmployeeAvatar.STATUS_FONT_SIZE).x <= employee._name_width() - 16, "Projected wording fits native world-label width: " + expected)
	check_name_geometry(employee)

func line_box(font: Font, size: int, value: String, baseline: Vector2, width: float) -> Rect2:
	var measured := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	return Rect2(baseline + Vector2((width - measured) * 0.5, -font.get_ascent(size)), Vector2(measured, font.get_height(size)))

func check_name_geometry(employee: EmployeeAvatar) -> void:
	var rect := employee._nameplate_rect()
	var inset := EmployeeAvatar.NAME_INSET
	var safe := Rect2(rect.position + inset, rect.size - inset * 2)
	var name_text := employee._fit_label(employee.display_name, safe.size.x, EmployeeAvatar.NAME_FONT, EmployeeAvatar.NAME_FONT_SIZE)
	var name_box := line_box(EmployeeAvatar.NAME_FONT, EmployeeAvatar.NAME_FONT_SIZE, name_text, employee._name_baseline(), safe.size.x)
	check(rect.position == rect.position.round() and rect.size == rect.size.round(), "Centered world name card has whole-pixel edges")
	check(employee._name_baseline() == employee._name_baseline().round(), "Name baseline uses a snapped canvas origin")
	check(safe.encloses(name_box), "Name's full font metrics stay inside paper insets: %s in %s" % [name_box, safe])
	check(GameFonts.has_glyphs(EmployeeAvatar.NAME_FONT, name_text), "Visible world name has bundled glyph coverage: " + name_text)
	if employee._label_detail_visible():
		var label := employee.presentation_label()
		var status_box := line_box(EmployeeAvatar.STATUS_FONT, EmployeeAvatar.STATUS_FONT_SIZE, label, employee._status_baseline(), safe.size.x)
		check(employee._status_baseline() == employee._status_baseline().round(), "Status baseline uses a snapped canvas origin")
		check(safe.encloses(status_box), "Status metrics stay inside paper insets: %s in %s" % [status_box, safe])
		check(name_box.end.y + EmployeeAvatar.TEXT_LINE_GAP <= status_box.position.y + 0.01, "World name and status have distinct line boxes with a readable gap")
		check(GameFonts.has_glyphs(EmployeeAvatar.STATUS_FONT, label), "World status has bundled glyph coverage")

func check_world_typography() -> void:
	check(EmployeeAvatar.NAME_FONT == GameFonts.BOLD and EmployeeAvatar.NAME_FONT_SIZE == 16, "World identity explicitly uses Nunito Bold16")
	check(EmployeeAvatar.STATUS_FONT == GameFonts.EMPHASIS and EmployeeAvatar.STATUS_FONT_SIZE == 14, "World status explicitly uses Nunito metadata14")
	check(EmployeeAvatar.SPEECH_FONT == GameFonts.BODY and EmployeeAvatar.SPEECH_FONT_SIZE == 16, "World speech explicitly uses Nunito body16")
	var employee := EmployeeAvatar.new()
	for identity: String in ["Mina", "Theo", "Alexandria Customer Research", "Zoë – 顾客研究 🚀"]:
		employee.display_name = identity
		for detail: bool in [false, true]:
			employee.set_ui_highlighted(detail)
			check_name_geometry(employee)
			check(employee.display_name == identity, "World elision does not alter the original employee identity")
	for position: Vector2 in [Vector2(300, 340), Vector2(300.49, 340.72), Vector2(300.5, 340.5)]:
		employee.position = position
		var expected := employee._nameplate_rect()
		expected.position += position.round()
		check(employee.world_label_rect() == expected, "World UI occlusion uses the same snapped card as painting")
	for speech: String in ["One clear offer.", "A very long memory sentence must remain readable without covering the whole office", "https://example.com/a-very-long-unbroken-memory-reference followed by more context", "Zoë reviews résumé–validation…\n顾客研究 🚀 → next steps"]:
		employee.memory_line = speech
		employee._speech_visible = true
		var rect := employee._speech_rect()
		var safe := Rect2(rect.position + EmployeeAvatar.SPEECH_INSET, rect.size - EmployeeAvatar.SPEECH_INSET * 2)
		var lines := employee._wrap_speech(speech, 21)
		check(lines.size() > 0 and lines.size() <= 2, "Speech remains a bounded two-line contextual card")
		var previous := Rect2()
		for index: int in range(lines.size()):
			var baseline := employee._speech_baseline(index)
			var bounds := line_box(EmployeeAvatar.SPEECH_FONT, EmployeeAvatar.SPEECH_FONT_SIZE, lines[index], baseline, safe.size.x)
			check(baseline == baseline.round(), "Speech uses a whole-pixel baseline")
			check(safe.encloses(bounds), "Speech font metrics fit painted paper including long first tokens: %s in %s" % [bounds, safe])
			check(GameFonts.has_glyphs(EmployeeAvatar.SPEECH_FONT, lines[index]), "Speech has bundled glyph coverage")
			if index > 0: check(previous.end.y + EmployeeAvatar.TEXT_LINE_GAP <= bounds.position.y + 0.01, "Speech lines do not overlap")
			previous = bounds
		check(employee.memory_line == speech, "Speech wrapping preserves the original memory text")
		check(employee.world_label_rect() == Rect2(employee.position.round() + rect.position, rect.size), "Speech occlusion matches its metric-derived paper")
	employee.free()

func run() -> void:
	check_world_typography()
	fixture()
	begin()
	event(&"job.started")
	project("Waiting for desk" if main.get_employee("mira")._waiting_for_desk else "To desk")
	event(&"job.completed")
	var employee := main.get_employee("mira")
	employee.world_paused = false
	for frame: int in range(900):
		if not employee._has_target: break
		employee._physics_process(1.0 / 60.0)
	check(not employee._has_target and employee.work_state == EmployeeAvatar.WorkState.IDLE, "Real deterministic delivery route reaches idle arrival")
	project("Delivery ready")
	check(main.job_panel._employee_ui_state("mira") == "delivery ready", "World and drawer agree after delivery arrival")

	fixture()
	main.job_panel.show_pending_promotions([{"jobId": "saved-delivery", "employeeId": "mira", "title": "Saved website", "summary": "Ready for review"}])
	project("Delivery ready")
	check(main.get_employee("mira").work_state == EmployeeAvatar.WorkState.IDLE, "Hydrated pending delivery does not restart its completed animation")
	main.job_panel.show_pending_promotions([])
	project("Available")

	fixture()
	main.day_clock.set_time(1, 18 * 60)
	project("Off shift")
	begin()
	main.job_panel.mark_job_queued("fixture-job")
	project("Queued")
	check(main.get_employee("mira").work_state == EmployeeAvatar.WorkState.OFF_SHIFT, "Queued wording leaves off-shift physical schedule intact")

	fixture()
	main.day_clock.set_time(1, DayClock.LUNCH_START)
	project("At lunch")

	fixture()
	begin()
	event(&"job.started")
	event(&"approval.required")
	project("Needs approval")
	event(&"job.failed")
	project("Needs retry")

	fixture()
	main.job_panel.restore_job("saved-running", "running", "Restored work", "mira")
	project("Working")
	check(main.get_employee("mira").work_state == EmployeeAvatar.WorkState.IDLE, "Cached running label does not invent a physical animation")
	main.game_audio.shutdown()
	main.free()
	await process_frame
	print("World UI presentation: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
