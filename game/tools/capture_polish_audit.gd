extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const OUTPUT_ROOT := "res://tests/output/polish-audit"
const AUDIT_FPS := 30
const VIEWPORT_SIZE := Vector2i(1280, 720)
const THUMBNAIL_SIZE := Vector2i(640, 360)
const ARCHITECTURE_ROOT := "res://assets/runtime/office/architecture/"
const ARCHITECTURE_ALPHA: Dictionary = {
	"floor.png": "opaque",
	"wall.png": "opaque",
	"trim.png": "opaque",
	"window.png": "binary",
	"door.png": "opaque",
}

const EXPECTED_SCENARIOS: Dictionary = {
	"world": [
		"founder-locomotion",
		"employee-idle-cycle",
		"job-state-cycle",
		"schedule-cycle",
		"depth-and-occlusion",
		"office-growth",
	],
	"ui": [
		"team-drawer-controls",
		"chat-and-work-order",
		"work-controls",
		"journal-and-approval",
		"delivery-studio-reader",
		"queued-errors-and-overflow",
	],
}

var _suite := ""
var _main: GameMain
var _scenarios: Array[Dictionary] = []
var _active_scenario_index := -1
var _active_images: Array[Image] = []
var _failures: PackedStringArray = []
var _actor_cell_failures: Dictionary[String, bool] = {}
var _architecture_specs: Dictionary[String, Dictionary] = {}
var _ui_dispatches: Array[Dictionary] = []

func _initialize() -> void:
	_suite = _parse_suite()
	if not EXPECTED_SCENARIOS.has(_suite):
		push_error("Use --suite=world or --suite=ui after the -- separator")
		quit(2)
		return
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _parse_suite() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--suite="):
			return argument.trim_prefix("--suite=").strip_edges().to_lower()
	return ""

func _run() -> void:
	root.always_on_top = true
	root.gui_embed_subwindows = true
	root.grab_focus()
	if not _prepare_output_directories():
		quit(1)
		return
	await _fresh_main(2)
	_write_asset_inventory()
	if _suite == "world":
		await _run_world_suite()
	else:
		await _run_ui_suite()
	_validate_capture()
	_write_manifest()
	if is_instance_valid(_main):
		_main.game_audio.shutdown()
		await create_timer(0.05).timeout
		root.remove_child(_main)
		_main.free()
	if _failures.is_empty():
		print("polish audit captured: %s (%d scenarios)" % [_suite, _scenarios.size()])
		quit()
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)

func _prepare_output_directories() -> bool:
	for path: String in [OUTPUT_ROOT, "%s/%s" % [OUTPUT_ROOT, _suite]]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("Could not create audit output directory: %s" % path)
			return false
	return true

func _fresh_main(hire_count: int) -> void:
	_ui_dispatches.clear()
	if is_instance_valid(_main):
		_main.game_audio.shutdown()
		await create_timer(0.05).timeout
		root.remove_child(_main)
		_main.free()
		await _frames(2)
	_main = MAIN_SCENE.instantiate() as GameMain
	root.add_child(_main)
	await _frames(5)
	_disconnect_worker_actions()
	# Observe every work-dispatch channel, including unintended cross-channel
	# emissions. Watching only the expected signal cannot prove "chat only".
	_main.job_panel.chat_submitted.connect(func(id: String, message: String) -> void: _ui_dispatches.append({"method": "chat.send", "employeeId": id, "message": message}))
	_main.job_panel.assignment_submitted.connect(func(id: String, title: String, _assignment: String, _criteria: PackedStringArray, _attachment: String) -> void: _ui_dispatches.append({"method": "job.start", "employeeId": id, "title": title}))
	_main.job_panel.steer_submitted.connect(func(id: String, message: String) -> void: _ui_dispatches.append({"method": "job.steer", "jobId": id, "message": message}))
	_main.day_clock.set_speed(0.0)
	_main.day_clock.set_time(1, DayClock.WORK_START)
	_main.room.set_hire_count(hire_count)
	_main.player.position = _main.room.grid_to_world_position(_main.room.player_spawn)
	_main.player._physics_process(0.0)
	_main.job_panel.visible = true
	_main.clock_panel.visible = true
	_main.job_panel.set_credential_status(true)
	_main.job_panel.set_worker_ready()
	_main.job_panel._custom_title_input.text = "Launch brief"
	_main.job_panel.close_drawer(false)
	_main.artifact_viewer.hide()
	_main.founder_hud.hide_delivery()
	_main.founder_hud.dismiss_movement_hint()
	await _frames(4)

func _run_world_suite() -> void:
	await _capture_founder_locomotion()
	await _capture_employee_idle_cycle()
	await _capture_job_state_cycle()
	await _capture_schedule_cycle()
	await _capture_depth_and_occlusion()
	await _capture_office_growth()

func _capture_founder_locomotion() -> void:
	await _fresh_main(2)
	_main._spawn_employees([])
	_main.room.set_hire_count(2)
	var origin := _open_locomotion_origin()
	_place_player(origin)
	await _begin_scenario(
		"founder-locomotion",
		"Founder starts and stops cleanly while walking in all four directions and returns near the origin."
	)
	await _walk_player(&"move_right", 14)
	await _walk_player(&"move_left", 14)
	await _capture_keyframe("middle")
	await _walk_player(&"move_up", 14)
	await _walk_player(&"move_down", 14)
	await _frames(12)
	if _main.player.position.distance_to(origin) > 6.0:
		_failures.append("Founder locomotion did not return to its clear origin: %s -> %s" % [origin, _main.player.position])
	await _end_scenario()

func _capture_employee_idle_cycle() -> void:
	await _fresh_main(2)
	var mina := _main.get_employee("mira")
	mina._idle_cooldown = 0.1
	await _begin_scenario(
		"employee-idle-cycle",
		"Mina moves from her spawn to her desk, sits, surfaces a memory, and begins a short wander."
	)
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.SITTING, 180, "Mina seated idle")
	mina.memory_line = "The smallest useful launch can teach us the most."
	mina._idle_elapsed = 2.6
	await _frames(5)
	await _capture_keyframe("middle")
	mina._idle_elapsed = 6.95
	await _frames(24)
	await _end_scenario()

func _capture_job_state_cycle() -> void:
	await _fresh_main(2)
	var mina := _main.get_employee("mira")
	var job_id := "polish-job"
	_main._job_employees[job_id] = "mira"
	_main.job_panel.begin_job(job_id, "mira")
	_main.job_panel.close_drawer(false)
	await _begin_scenario(
		"job-state-cycle",
		"Mina visibly distinguishes walking, thinking, typing, research, approval, delivery, and failure recovery."
	)
	var started := _event(&"job.started")
	_main._on_job_event(job_id, started)
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.WORKING, 180, "Mina reached her desk")
	var thinking := _event(&"agent.thinking")
	thinking.summary = "Choosing the narrowest useful promise…"
	_main._on_job_event(job_id, thinking)
	await _frames(18)
	var writing := _event(&"tool.started")
	writing.tool = "write_file"
	writing.label = "Writing launch-brief.md"
	_main._on_job_event(job_id, writing)
	await _frames(24)
	await _capture_keyframe("middle")
	var research := _event(&"tool.started")
	research.tool = "web_search"
	research.label = "Researching customer evidence"
	_main._on_job_event(job_id, research)
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.WORKING, 210, "Mina reached research")
	await _frames(36)
	var approval := _event(&"approval.required")
	approval.approval_id = "polish-approval"
	approval.action = "Publish the launch brief to the shared studio."
	_main._on_job_event(job_id, approval)
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.WAITING_APPROVAL, 240, "Mina reached approval")
	await _frames(30)
	var completed := _event(&"job.completed")
	completed.summary = "Launch brief ready."
	mina.apply_worker_event(completed, _main.player.position)
	_main.job_panel.on_job_event(job_id, completed)
	_main.founder_hud.show_delivery(job_id, "mira", "Mina", "launch-brief.md ready")
	_main.job_panel.offer_promotion(job_id, "mira")
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.IDLE, 180, "Mina delivered the result")
	await _frames(18)
	_main.job_panel.begin_job("polish-failure", "mira")
	var failed := _event(&"job.failed")
	failed.error = "The audit intentionally stopped this work order."
	mina.apply_worker_event(failed, _main.player.position)
	_main.job_panel.on_job_event("polish-failure", failed)
	await _frames(20)
	await _end_scenario()

func _capture_schedule_cycle() -> void:
	await _fresh_main(2)
	var mina := _main.get_employee("mira")
	var theo := _main.get_employee("theo")
	await _begin_scenario(
		"schedule-cycle",
		"Both employees transition from work to lunch, off shift, and back to the work window."
	)
	_main.day_clock.set_time(1, DayClock.LUNCH_START)
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.LUNCH, 240, "Mina reached lunch")
	await _wait_for_employee_state(theo, EmployeeAvatar.WorkState.LUNCH, 120, "Theo reached lunch")
	await _frames(20)
	await _capture_keyframe("middle")
	_main.day_clock.set_time(1, DayClock.WORK_END)
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.OFF_SHIFT, 240, "Mina went off shift")
	await _wait_for_employee_state(theo, EmployeeAvatar.WorkState.OFF_SHIFT, 180, "Theo went off shift")
	await _frames(20)
	_main.day_clock.set_time(2, DayClock.WORK_START)
	await _wait_for_employee_state(mina, EmployeeAvatar.WorkState.SITTING, 240, "Mina returned to work")
	await _wait_for_employee_state(theo, EmployeeAvatar.WorkState.SITTING, 180, "Theo returned to work")
	await _frames(20)
	await _end_scenario()

func _capture_depth_and_occlusion() -> void:
	await _fresh_main(4)
	_main._spawn_employees([])
	_main.room.set_hire_count(4)
	var desk := _main.room.placement_by_id("mira-workstation")
	_place_player(_depth_anchor(desk, true))
	await _begin_scenario(
		"depth-and-occlusion",
		"The founder reads behind and in front of furniture using ground-contact Y sorting without sprite rotation."
	)
	await _frames(12)
	await _walk_player_to(_depth_anchor(desk, false), "desk front")
	await _frames(12)
	var research := _main.room.placement_by_id("research-bench")
	await _walk_player_to(_depth_anchor(research, true), "research bench rear")
	await _frames(12)
	await _walk_player_to(_depth_anchor(research, false), "research bench front")
	await _frames(12)
	await _capture_keyframe("middle")
	for prop_id: String in ["collaboration-cluster", "prototype-bench"]:
		var placement := _main.room.placement_by_id(prop_id)
		await _walk_player_to(_depth_anchor(placement, true), prop_id + " rear")
		await _frames(12)
		await _walk_player_to(_depth_anchor(placement, false), prop_id + " front")
		await _frames(12)
	await _end_scenario()

func _capture_office_growth() -> void:
	await _fresh_main(0)
	_main._spawn_employees([])
	_main.room.set_hire_count(0)
	await _begin_scenario(
		"office-growth",
		"The office progresses from founder-only to two hires and then the mature four-hire prop layout."
	)
	_record_marker("office-stage-0")
	await _frames(30)
	for stage: int in range(1, 5):
		_main.room.set_hire_count(stage)
		await _frames(30)
		var expected_count := _main.room.layout_model.resolve_placements(stage).size()
		if _main.room.visible_prop_count() != expected_count:
			_failures.append("Office growth stage %d has %d props, expected %d" % [stage, _main.room.visible_prop_count(), expected_count])
		_record_marker("office-stage-%d" % stage)
		if stage == 2:
			await _capture_keyframe("middle")
	await _end_scenario()

func _run_ui_suite() -> void:
	await _capture_team_drawer_controls()
	await _capture_chat_and_work_order()
	await _capture_work_controls()
	await _capture_journal_and_approval()
	await _capture_delivery_studio_reader()
	await _capture_queued_errors_and_overflow()

func _capture_team_drawer_controls() -> void:
	await _fresh_main(2)
	var mina_button := _main.job_panel._team_buttons["mira"] as Button
	mina_button.grab_focus()
	await _begin_scenario(
		"team-drawer-controls",
		"Portrait focus, hover, selection, drawer travel, employee switching, and close feedback remain coherent."
	)
	_move_mouse_to(mina_button)
	await _frames(8)
	await _press_control(mina_button)
	_check(_main.job_panel.selected_employee_id() == "mira" and _main.job_panel.drawer_is_open(), "mina-rail-selection")
	await _frames(3)
	await _capture_keyframe("middle")
	await _frames(10)
	var theo_button := _main.job_panel._team_buttons["theo"] as Button
	await _press_control(theo_button)
	_check(_main.job_panel.selected_employee_id() == "theo", "theo-rail-selection")
	await _frames(10)
	_main.job_panel.close_drawer()
	await _frames(10)
	await _end_scenario()

func _capture_chat_and_work_order() -> void:
	await _fresh_main(2)
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 0
	_main.job_panel.show_chat_history("mira", _long_chat_history())
	await _begin_scenario(
		"chat-and-work-order",
		"Long chat scrolls cleanly, send/wait/reply states are legible, and Create work order carries the bounded discussion forward."
	)
	await _type_into(_main.job_panel._chat_input, "Make a one-week launch plan.")
	await _press_control(_main.job_panel._chat_send_button)
	_check(_ui_dispatches.size() == 1 and _ui_dispatches[0].method == "chat.send", "chat-only-dispatch")
	_check(_main.job_panel._chat_pending and _main.job_panel._chat_send_button.disabled, "chat-waiting-disabled")
	await _checkpoint("chat-waiting")
	await _frames(16)
	await _capture_keyframe("middle")
	_main.job_panel.show_chat_reply("mira", {"content": "I’ll turn the themes into a focused promise, evidence summary, and one-week experiment."}, 0.018)
	await _frames(20)
	await _ensure_visible(_main.job_panel._make_job_button)
	await _press_control(_main.job_panel._make_job_button)
	_check(_main.job_panel._tabs.current_tab == 1 and _main.job_panel._assignment_preview.text.contains("Discussion context"), "chat-to-editable-work-draft")
	await _frames(12)
	await _end_scenario()

func _capture_work_controls() -> void:
	await _fresh_main(2)
	_main.job_panel.select_employee("mira")
	_main.job_panel._tabs.current_tab = 1
	_main.job_panel._job_picker.select(_main.job_panel.CANNED_JOBS.size())
	_main.job_panel._on_job_selected(_main.job_panel.CANNED_JOBS.size())
	_main.job_panel._custom_title_input.text = "One-week launch plan"
	_main.job_panel._assignment_preview.text = "Create a concise launch plan in launch-plan.md with a promise, evidence, and next experiment."
	await _begin_scenario(
		"work-controls",
		"Dropdown, popup selection, focus, hover, press, disabled, and text-entry states use the same custom control language."
	)
	await _press_control(_main.job_panel._purpose_picker)
	await _frames(18)
	if not _main.job_panel._purpose_picker.get_popup().visible:
		_failures.append("Visible work-purpose dropdown did not open from real pointer input")
	await _capture_keyframe("middle")
	await _press_key(KEY_DOWN)
	await _press_key(KEY_DOWN)
	await _press_key(KEY_ENTER)
	if _main.job_panel._purpose_picker.get_popup().visible:
		_failures.append("Work-purpose dropdown did not accept keyboard selection")
	_check(_main.job_panel._purpose_picker.selected == 1, "dropdown-selection-changed")
	await _checkpoint("dropdown-selected")
	# Return through the same real picker to make its custom title editable.
	await _press_control(_main.job_panel._purpose_picker)
	await _press_key(KEY_DOWN)
	await _press_key(KEY_ENTER)
	await _type_into(_main.job_panel._custom_title_input, "A focused launch plan")
	_main.job_panel._assignment_preview.text = "Write launch-plan.md with a clear offer and one measurable experiment."
	await _checkpoint("visible-title-focus")
	var handler := Callable(_main, "_on_assignment_submitted")
	if _main.job_panel.assignment_submitted.is_connected(handler):
		_main.job_panel.assignment_submitted.disconnect(handler)
	_main.job_panel.assignment_submitted.connect(func(id: String, _title: String, _assignment: String, _criteria: PackedStringArray, _attachment: String) -> void:
		_main.job_panel.begin_job("submitted-polish", id)
	)
	await _press_control(_main.job_panel._assign_button)
	_check(_ui_dispatches.size() == 1 and _ui_dispatches[0].method == "job.start", "confirmed-assignment-dispatch")
	_check(_main.job_panel._assign_button.disabled, "assignment-pending-disabled")
	await _press_control(_main.job_panel._assign_button, true)
	_check(_ui_dispatches.size() == 1, "disabled-assignment-no-double-dispatch")
	await _checkpoint("assignment-disabled")
	await _frames(8)
	await _end_scenario()

func _capture_journal_and_approval() -> void:
	await _fresh_main(2)
	var job_id := "journal-polish"
	_main._job_employees[job_id] = "mira"
	_main.job_panel.select_employee("mira")
	_main.job_panel.begin_job(job_id, "mira")
	_main.job_panel.accept_submission(job_id)
	_main.job_panel.open_drawer(false)
	_main.job_panel._tabs.current_tab = 2
	var started := _event(&"job.started")
	_main._on_job_event(job_id, started)
	var thinking := _event(&"agent.thinking")
	thinking.summary = "Grouping customer evidence into one promise…"
	_main._on_job_event(job_id, thinking)
	var writing := _event(&"tool.started")
	writing.tool = "write_file"
	writing.label = "Writing launch-brief.md"
	_main._on_job_event(job_id, writing)
	_main.job_panel.set_spend(0.0, 5.0)
	await _begin_scenario(
		"journal-and-approval",
		"Activity, spend at zero/half/full, steering, approval attention, and decision controls communicate one live job."
	)
	_main.job_panel.set_spend(2.5, 5.0)
	await _frames(20)
	await _capture_keyframe("middle")
	_main.job_panel.set_spend(5.0, 5.0)
	await _ensure_visible(_main.job_panel._steer_input)
	await _type_into(_main.job_panel._steer_input, "Keep the offer specific.")
	await _ensure_visible(_main.job_panel._steer_button)
	await _press_control(_main.job_panel._steer_button)
	_check(_ui_dispatches.size() == 1 and _ui_dispatches[0].method == "job.steer", "activity-only-steering-dispatch")
	_check(_main.job_panel._steer_button.disabled, "steering-pending-disabled")
	_main.job_panel.set_steer_sent(job_id)
	var approval := _event(&"approval.required")
	approval.approval_id = "journal-approval"
	approval.action = "Publish the launch brief to the shared studio for Theo."
	_main._on_job_event(job_id, approval)
	await _frames(24)
	var approve := _button_named(_main.job_panel._approval_box, "Approve")
	await _ensure_visible(approve)
	await _checkpoint("approval-visible")
	_main.job_panel.approval_decided.connect(func(id: String, approval_id: String, approved: bool) -> void: _ui_dispatches.append({"method": "approval", "jobId": id, "approvalId": approval_id, "approved": approved}))
	await _press_control(approve)
	_check(_ui_dispatches.size() == 2 and _ui_dispatches[1].approved, "approval-click-dispatch")
	await _end_scenario()

func _capture_delivery_studio_reader() -> void:
	await _fresh_main(2)
	var job_id := "delivery-polish"
	_main.job_panel.select_employee("mira")
	_main.job_panel.begin_job(job_id, "mira")
	var completed := _event(&"job.completed")
	completed.summary = "Launch brief complete with a focused promise and experiment."
	_main.job_panel.on_job_event(job_id, completed)
	var artifact := ArtifactRecord.new()
	artifact.artifact_id = "delivery-polish-brief"
	artifact.name = "Launch brief"
	artifact.relative_path = "launch-brief.md"
	_main.job_panel.show_artifacts(job_id, [artifact])
	_main.job_panel.offer_promotion(job_id, "mira")
	_main.job_panel.close_drawer(false)
	_main.founder_hud.show_delivery(job_id, "mira", "Mina", "launch-brief.md ready")
	await _begin_scenario(
		"delivery-studio-reader",
		"Delivery View opens inspectable files; Preview is exercised before promotion, followed by Studio selection and actual reader scroll/close/reopen input."
	)
	await _press_control(_main.founder_hud._notification.get_node("ViewDelivery"))
	await _frames(18)
	var preview := _button_named(_main.job_panel._delivery_list, "Preview")
	_check(_control_visible(preview), "delivery-preview-in-first-view")
	_main.job_panel.artifact_open_requested.connect(func(id: String, path: String) -> void:
		_ui_dispatches.append({"method": "artifact.read", "jobId": id, "path": path})
		_main.artifact_viewer.show_artifact(path, _reader_document())
	)
	await _press_control(preview)
	_check(_main.artifact_viewer.visible and _ui_dispatches.size() == 1, "preview-opens-reader-before-decision")
	await _frames(12)
	await _capture_keyframe("middle")
	var document := _main.artifact_viewer._content
	var previous_scroll := document.get_v_scroll_bar().value
	for index: int in range(8): await _wheel(document, MOUSE_BUTTON_WHEEL_DOWN)
	_check(document.get_v_scroll_bar().value > previous_scroll, "reader-wheel-scroll")
	await _checkpoint("reader-scrolled")
	var close_events: Array[String] = []
	_main.artifact_viewer._close_button.pressed.connect(func() -> void: close_events.append("pressed"))
	await _press_control(_main.artifact_viewer._close_button)
	await _frames(8)
	_check(close_events == ["pressed"], "reader-close-button-pressed")
	_check(not _main.artifact_viewer.visible, "reader-click-close")
	await _press_control(preview)
	await _frames(10)
	_check(_main.artifact_viewer.visible and is_zero_approx(document.get_v_scroll_bar().value), "reader-reopen-reset")
	_check(document.get_parsed_text().contains("Help a first-time creator") and document.get_content_height() > document.size.y, "reader-reopen-retains-document")
	await _press_key(KEY_ESCAPE)
	await _frames(8)
	_check(not _main.artifact_viewer.visible, "reader-escape-close")
	_main.job_panel.promotion_decided.connect(func(id: String, approved: bool) -> void: _ui_dispatches.append({"method": "promotion", "jobId": id, "approved": approved}))
	var promote := _button_named(_main.job_panel._promotion_box, "Add to Studio")
	await _ensure_visible(promote)
	await _press_control(promote)
	_check(_ui_dispatches.size() == 3 and _ui_dispatches[0].method == "artifact.read" and _ui_dispatches[2].method == "promotion", "preview-before-promotion-dispatch-order")
	await _checkpoint("delivery-promoted")
	var studio_file := StudioFileRecord.new()
	studio_file.name = "launch-brief.md"
	studio_file.relative_path = "launch-brief.md"
	studio_file.source_job_id = job_id
	_main.job_panel.show_studio_files([])
	await _press_control(_main.job_panel._tab_buttons[3])
	await _frames(16)
	await _checkpoint("studio-empty")
	_main.job_panel.show_studio_files([studio_file])
	await _frames(16)
	_main.job_panel.studio_open_requested.connect(func(path: String) -> void:
		_ui_dispatches.append({"method": "studio.read", "path": path})
		_main.artifact_viewer.show_artifact(path, _reader_document(), "Shared Studio")
	)
	await _press_control(_button_named(_main.job_panel._artifact_list, "Open"))
	_check(_ui_dispatches.back().method == "studio.read", "studio-file-selection")
	await _frames(18)
	_check(document.get_parsed_text().contains("Help a first-time creator") and document.get_content_height() > document.size.y, "studio-reader-retains-document")
	await _end_scenario()

func _capture_queued_errors_and_overflow() -> void:
	await _fresh_main(2)
	_main.day_clock.set_time(1, DayClock.WORK_END)
	_main.job_panel.select_employee("theo")
	_main.job_panel._tabs.current_tab = 1
	await _begin_scenario(
		"queued-errors-and-overflow",
		"Off-hours, queued work, long copy, keyboard focus, error, and recovery remain bounded and unmistakable."
	)
	_main.job_panel.begin_job("queued-polish", "theo")
	_main.job_panel.accept_submission("queued-polish")
	_main.job_panel.on_job_event("queued-polish", _event(&"job.queued"))
	_main.job_panel.mark_job_queued("queued-polish")
	_main.job_panel.open_drawer(false)
	_main.job_panel._tabs.current_tab = 2
	await _frames(20)
	await _capture_keyframe("middle")
	_main.job_panel.set_worker_connection_error("The worker disconnected while preparing a long customer-research delivery. Your work remains saved. Reconnect to continue.")
	_main.job_panel._open_connection_settings()
	await _frames(24)
	_check(_main.job_panel._connection_panel.visible and _main.job_panel._connection_retry_button.visible, "worker-error-retry-visible")
	await _checkpoint("worker-error")
	await _press_control(_main.job_panel._connection_retry_button)
	# A deterministic successful bootstrap response, never a provider request.
	_main.job_panel.set_worker_ready()
	_main.job_panel.set_info("Worker recovered. Queued work remains in Activity.")
	await _frames(18)
	_check(_main.job_panel._worker_connected and not _main.job_panel._connection_panel.visible, "worker-recovery-distinct")
	await _checkpoint("worker-recovered")
	await _end_scenario()

func _begin_scenario(name_value: String, expected_state: String) -> void:
	_active_images.clear()
	var scenario := {
		"name": name_value,
		"startFrame": Engine.get_process_frames(),
		"endFrame": 0,
		"expectedState": expected_state,
		"keyframes": {},
		"frameHashes": [],
		"sampledFramesDistinct": false,
		"contactSheet": "",
		"markers": [],
		"actorCellsChecked": 0,
		"keyframeState": {},
		"uiKeyframeState": {},
		"checks": [],
		"checkpoints": {},
	}
	_scenarios.append(scenario)
	_active_scenario_index = _scenarios.size() - 1
	await _frames(1)
	await _capture_keyframe("start")

func _end_scenario() -> void:
	await _capture_keyframe("end")
	var scenario := _scenarios[_active_scenario_index]
	scenario["endFrame"] = Engine.get_process_frames()
	scenario["dispatches"] = _ui_dispatches.duplicate(true)
	var hashes := scenario["frameHashes"] as Array
	var unique_hashes := {}
	for hash_value: Variant in hashes:
		unique_hashes[str(hash_value)] = true
	scenario["sampledFramesDistinct"] = unique_hashes.size() > 1
	scenario["contactSheet"] = _write_contact_sheet(str(scenario["name"]))
	_scenarios[_active_scenario_index] = scenario
	_active_scenario_index = -1
	_active_images.clear()
	await _frames(12)

func _capture_keyframe(phase: String) -> void:
	if _active_scenario_index < 0:
		_failures.append("Tried to capture %s without an active scenario" % phase)
		return
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var scenario := _scenarios[_active_scenario_index]
	var name_value := str(scenario["name"])
	var relative_path := "%s/%s/%s-%s.png" % [OUTPUT_ROOT, _suite, name_value, phase]
	var save_error := image.save_png(relative_path)
	if save_error != OK:
		_failures.append("Could not save keyframe: %s" % relative_path)
	var keyframes := scenario["keyframes"] as Dictionary
	keyframes[phase] = relative_path
	var state: Dictionary = scenario["keyframeState"]
	state[phase] = _actor_snapshot()
	(scenario["uiKeyframeState"] as Dictionary)[phase] = _ui_snapshot()
	var hashes := scenario["frameHashes"] as Array
	hashes.append(str(hash(image.get_data())))
	_scenarios[_active_scenario_index] = scenario
	_active_images.append(image)

func _write_contact_sheet(name_value: String) -> String:
	if _active_images.size() != 3:
		_failures.append("%s did not produce start, middle, and end keyframes" % name_value)
		return ""
	var sheet := Image.create(THUMBNAIL_SIZE.x * 3, THUMBNAIL_SIZE.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("151515"))
	for index: int in range(_active_images.size()):
		var thumbnail := _active_images[index].duplicate() as Image
		thumbnail.resize(THUMBNAIL_SIZE.x, THUMBNAIL_SIZE.y, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(
			thumbnail,
			Rect2i(Vector2i.ZERO, THUMBNAIL_SIZE),
			Vector2i(index * THUMBNAIL_SIZE.x, 0)
		)
	var relative_path := "%s/%s/%s-contact-sheet.png" % [OUTPUT_ROOT, _suite, name_value]
	var save_error := sheet.save_png(relative_path)
	if save_error != OK:
		_failures.append("Could not save contact sheet: %s" % relative_path)
		return ""
	return relative_path

func _write_manifest() -> void:
	var manifest := {
		"schemaVersion": 1,
		"suite": _suite,
		"viewport": {"width": VIEWPORT_SIZE.x, "height": VIEWPORT_SIZE.y},
		"fps": AUDIT_FPS,
		"networkDisabled": true,
		"frameOrigin": "Engine process frame; movie writer may include a short startup lead-in",
		"passThreshold": {"minimumCategory": 2, "minimumMean": 2.5},
		"reviewRubric": {
			"categories": ["pixel", "motion", "continuity", "layering", "text", "feedback"],
			"scoreRange": {"minimum": 0, "maximum": 3},
			"reviewer": "Human or visual-review agent; capture validation does not assign aesthetic scores",
		},
		"scenarios": _scenarios,
		"failures": Array(_failures),
	}
	_write_json("%s/%s/manifest.json" % [OUTPUT_ROOT, _suite], manifest)

func _validate_capture() -> void:
	var expected := EXPECTED_SCENARIOS[_suite] as Array
	if _scenarios.size() != expected.size():
		_failures.append("Expected %d %s scenarios, captured %d" % [expected.size(), _suite, _scenarios.size()])
	for expected_name: Variant in expected:
		var found := false
		for scenario: Dictionary in _scenarios:
			if str(scenario["name"]) != str(expected_name):
				continue
			found = true
			var keyframes := scenario["keyframes"] as Dictionary
			if int(scenario.get("actorCellsChecked", 0)) < 1:
				_failures.append("%s did not verify actor walkability during motion" % expected_name)
			for phase: String in ["start", "middle", "end"]:
				var path := str(keyframes.get(phase, ""))
				if path.is_empty() or not FileAccess.file_exists(path):
					_failures.append("%s is missing its %s keyframe" % [expected_name, phase])
			if not bool(scenario["sampledFramesDistinct"]):
				_failures.append("%s sampled frames were identical" % expected_name)
			var contact_sheet := str(scenario["contactSheet"])
			if contact_sheet.is_empty() or not FileAccess.file_exists(contact_sheet):
				_failures.append("%s is missing its contact sheet" % expected_name)
			if str(expected_name) == "office-growth":
				var markers: Array = scenario.get("markers", [])
				for stage: int in range(5):
					var matched := false
					for marker: Dictionary in markers:
						if str(marker.get("label", "")) == "office-stage-%d" % stage:
							matched = true
					if not matched:
						_failures.append("Office growth is missing stage %d evidence" % stage)
		if not found:
			_failures.append("Missing required scenario: %s" % expected_name)

func _write_asset_inventory() -> void:
	_load_architecture_specs()
	var texture_paths: PackedStringArray = []
	_collect_png_paths("res://assets/runtime/office", texture_paths)
	_collect_png_paths("res://assets/runtime/ui", texture_paths)
	_collect_png_paths("res://assets/runtime/characters", texture_paths)
	_collect_png_paths("res://assets/runtime/effects", texture_paths)
	texture_paths.sort()
	var textures: Array[Dictionary] = []
	for path: String in texture_paths:
		textures.append(_inspect_texture(path))
	var live_nodes: Array[Dictionary] = []
	_main.room.set_hire_count(4)
	for prop: Node in _main.room._prop_root.get_children():
		var sprite := _prop_sprite(prop)
		if sprite == null:
			continue
		live_nodes.append(_inspect_live_sprite("office-prop", prop.name, sprite))
	for employee_id: String in _main._employees:
		var employee := _main._employees[employee_id] as EmployeeAvatar
		var sprite := employee.get_node_or_null("CharacterSprite") as Sprite2D
		if sprite != null:
			live_nodes.append(_inspect_live_sprite("character", employee_id, sprite))
	var founder_sprite := _main.player.get_node_or_null("CharacterSprite") as Sprite2D
	if founder_sprite != null:
		live_nodes.append(_inspect_live_sprite("character", "founder", founder_sprite))
	var atlas_specs: Array[Dictionary] = [
		{"characterId": "founder", "path": CharacterArt.FOUNDER_LOCOMOTION.resource_path, "width": 288, "height": 320, "columns": 6, "rows": 4, "cellWidth": 48, "cellHeight": 80},
		{"characterId": "mira", "path": CharacterArt.MIRA_LOCOMOTION.resource_path, "width": 288, "height": 320, "columns": 6, "rows": 4, "cellWidth": 48, "cellHeight": 80},
		{"characterId": "theo", "path": CharacterArt.THEO_LOCOMOTION.resource_path, "width": 288, "height": 320, "columns": 6, "rows": 4, "cellWidth": 48, "cellHeight": 80},
	]
	var known_flags: PackedStringArray = []
	for texture_info: Dictionary in textures:
		for issue: Variant in texture_info.get("flags", []):
			known_flags.append("%s: %s" % [str(texture_info.get("path", "texture")), str(issue)])
	for live_info: Dictionary in live_nodes:
		for issue: Variant in live_info.get("flags", []):
			known_flags.append("%s: %s" % [str(live_info.get("id", "sprite")), str(issue)])
	var stages: Array[Dictionary] = []
	for stage: int in range(5):
		var placements := _main.room.layout_model.resolve_placements(stage)
		var validation := _main.room.layout_model.validate_placements(placements)
		stages.append({"hires": stage, "propCount": placements.size(), "valid": bool(validation.get("valid", false)), "errors": validation.get("errors", [])})
	var inventory := {
		"schemaVersion": 3,
		"generatedBy": "capture_polish_audit.gd",
		"textures": textures,
		"liveSprites": live_nodes,
		"characterAtlases": atlas_specs,
		"roomModel": {
			"definition": OfficeLayout.DEFAULT_PATH,
			"catalog": OfficeLayout.DEFAULT_CATALOG_PATH,
			"tileSize": _main.room.layout_model.tile_size,
			"gridWidth": _main.room.layout_model.width,
			"gridHeight": _main.room.layout_model.height,
			"floorCellCount": _main.room.layout_model.floor_cells().size(),
			"architectureMode": "blockout" if _main.room.architecture.blockout else "modular-kit",
			"stages": stages,
			"architectureManifest": ARCHITECTURE_ROOT + "manifest.json",
		},
		"fonts": [
			{"role": "display", "path": GameFonts.DISPLAY.resource_path, "license": "res://assets/fonts/not-jam-slab/LICENSE-CC0.txt", "nativePixels": 22},
			{"role": "body", "path": GameFonts.BODY.resource_path, "license": "res://assets/fonts/nunito-sans/OFL.txt"},
			{"role": "emphasis", "path": GameFonts.EMPHASIS.resource_path, "license": "res://assets/fonts/nunito-sans/OFL.txt"},
			{"role": "bold", "path": GameFonts.BOLD.resource_path, "license": "res://assets/fonts/nunito-sans/OFL.txt"},
			{"role": "italic", "path": GameFonts.ITALIC.resource_path, "license": "res://assets/fonts/nunito-sans/OFL.txt"},
			{"role": "bold_italic", "path": GameFonts.BOLD_ITALIC.resource_path, "license": "res://assets/fonts/nunito-sans/OFL.txt"},
			{"role": "code", "path": GameFonts.MONO.resource_path, "license": "res://assets/fonts/jetbrains-mono/OFL.txt"},
		],
		"knownFlags": Array(known_flags),
	}
	_write_json("%s/asset-inventory.json" % OUTPUT_ROOT, inventory)

func _load_architecture_specs() -> void:
	_architecture_specs.clear()
	var file := FileAccess.open(ARCHITECTURE_ROOT + "manifest.json", FileAccess.READ)
	if file == null:
		_failures.append("Architecture asset manifest is missing")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_failures.append("Architecture asset manifest must be a JSON object")
		return
	var manifest := parsed as Dictionary
	for spec: Dictionary in manifest.get("assets", []):
		var filename := str(spec.get("file", ""))
		_architecture_specs[filename] = spec
	for filename: String in ARCHITECTURE_ALPHA:
		if not _architecture_specs.has(filename):
			_failures.append("Architecture manifest is missing " + filename)
		elif str(_architecture_specs[filename].get("alpha", "")) != str(ARCHITECTURE_ALPHA[filename]):
			_failures.append("Architecture alpha declaration differs from authored asset: " + filename)

func _collect_png_paths(directory_path: String, output: PackedStringArray) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child_path := "%s/%s" % [directory_path, entry]
			if directory.current_is_dir():
				_collect_png_paths(child_path, output)
			elif entry.get_extension().to_lower() == "png":
				output.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _inspect_texture(path: String) -> Dictionary:
	var texture := load(path) as Texture2D
	if texture == null:
		_failures.append("Could not load texture for inventory: %s" % path)
		return {"path": path, "flags": ["load-failed"]}
	var image := texture.get_image()
	var import_text := ""
	var import_file := FileAccess.open("%s.import" % path, FileAccess.READ)
	if import_file != null:
		import_text = import_file.get_as_text()
	var flags: PackedStringArray = []
	var used_rect := image.get_used_rect()
	var full_rect := Rect2i(Vector2i.ZERO, image.get_size())
	var has_transparent_border := used_rect != full_rect
	var has_transparency := image.detect_alpha() != Image.ALPHA_NONE
	var architecture_asset := path.begins_with(ARCHITECTURE_ROOT)
	var architecture_spec: Dictionary = _architecture_specs.get(path.get_file(), {}) if architecture_asset else {}
	var alpha_expectation := str(architecture_spec.get("alpha", ""))
	var modular_office_asset := path.begins_with("res://assets/runtime/office/") \
		and not architecture_asset \
		and not path.ends_with("office-shell-base.png") \
		and not path.ends_with("campus-surround.png") \
		and not path.ends_with("main-office-background.png")
	var alpha_required := path.begins_with("res://assets/runtime/characters/") \
		or path.begins_with("res://assets/runtime/effects/") \
		or modular_office_asset
	if alpha_required and not has_transparency:
		flags.append("opaque-runtime-cutout")
	if architecture_asset:
		if architecture_spec.is_empty():
			flags.append("architecture-metadata-missing")
		else:
			var expected_size: Array = architecture_spec.get("size", [])
			if expected_size.size() != 2 or image.get_size() != Vector2i(int(expected_size[0]), int(expected_size[1])):
				flags.append("architecture-size-mismatch")
			if alpha_expectation == "opaque" and has_transparency:
				flags.append("architecture-opaque-tile-has-alpha-gaps")
			elif alpha_expectation == "binary" and image.detect_alpha() != Image.ALPHA_BIT:
				flags.append("architecture-cutout-needs-binary-alpha")
	if modular_office_asset \
		and maxi(image.get_width(), image.get_height()) > 512:
		flags.append("oversized-runtime-prop-source")
	if (alpha_required or architecture_asset) and not import_text.contains("compress/mode=0"):
		flags.append("runtime-cutout-not-lossless")
	if not import_text.is_empty() and not import_text.contains("mipmaps/generate=false"):
		flags.append("mipmaps-not-explicitly-disabled")
	return {
		"path": path,
		"width": image.get_width(),
		"height": image.get_height(),
		"hasTransparentBorder": has_transparent_border,
		"hasTransparency": has_transparency,
		"assetRole": "architecture" if architecture_asset else ("office-cutout" if modular_office_asset else "other"),
		"alphaExpectation": alpha_expectation if architecture_asset else ("transparent-cutout" if alpha_required else "unrestricted"),
		"usedRect": {"x": used_rect.position.x, "y": used_rect.position.y, "width": used_rect.size.x, "height": used_rect.size.y},
		"losslessImport": import_text.contains("compress/mode=0"),
		"mipmapsDisabled": import_text.contains("mipmaps/generate=false"),
		"flags": Array(flags),
	}

func _prop_sprite(prop: Node) -> Sprite2D:
	for node_name: String in ["WorkstationFront", "ResearchBenchFront", "PropSprite"]:
		var sprite := prop.get_node_or_null(node_name) as Sprite2D
		if sprite != null:
			return sprite
	return null

func _inspect_live_sprite(kind: String, id_value: String, sprite: Sprite2D) -> Dictionary:
	var source_size := Vector2.ZERO
	var source_path := ""
	if sprite.texture is AtlasTexture:
		var atlas := sprite.texture as AtlasTexture
		source_size = atlas.region.size
		source_path = atlas.atlas.resource_path
	elif sprite.texture != null:
		source_size = sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
		source_path = sprite.texture.resource_path
	var displayed_size := source_size * sprite.scale.abs()
	var flags: PackedStringArray = []
	if sprite.scale.x < 0.5 or sprite.scale.y < 0.5:
		flags.append("heavy-runtime-downscale")
	if not is_equal_approx(displayed_size.x, roundf(displayed_size.x)) \
		or not is_equal_approx(displayed_size.y, roundf(displayed_size.y)):
		flags.append("fractional-displayed-pixel-size")
	return {
		"kind": kind,
		"id": id_value,
		"sourcePath": source_path,
		"sourceWidth": source_size.x,
		"sourceHeight": source_size.y,
		"scaleX": sprite.scale.x,
		"scaleY": sprite.scale.y,
		"displayedWidth": displayed_size.x,
		"displayedHeight": displayed_size.y,
		"flags": Array(flags),
	}

func _write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("Could not write JSON output: %s" % path)
		return
	file.store_string(JSON.stringify(value, "\t") + "\n")

func _disconnect_worker_actions() -> void:
	_disconnect_if_connected(_main.job_panel.key_submitted, Callable(_main.worker_client, "save_openrouter_key"))
	_disconnect_if_connected(_main.job_panel.chat_history_requested, Callable(_main.worker_client, "request_chat_history"))
	_disconnect_if_connected(_main.job_panel.chat_submitted, Callable(_main.worker_client, "send_chat"))
	_disconnect_if_connected(_main.job_panel.cancel_requested, Callable(_main.worker_client, "cancel_job"))
	_disconnect_if_connected(_main.job_panel.steer_submitted, Callable(_main.worker_client, "steer_job"))
	_disconnect_if_connected(_main.job_panel.approval_decided, Callable(_main.worker_client, "approve"))
	_disconnect_if_connected(_main.job_panel.artifact_refresh_requested, Callable(_main.worker_client, "request_artifacts"))
	_disconnect_if_connected(_main.job_panel.artifact_open_requested, Callable(_main.worker_client, "read_artifact"))
	_disconnect_if_connected(_main.job_panel.studio_open_requested, Callable(_main.worker_client, "read_studio_file"))
	_disconnect_if_connected(_main.job_panel.promotion_decided, Callable(_main.worker_client, "promote_job"))
	_disconnect_if_connected(_main.job_panel.promotion_decided, Callable(_main, "_on_promotion_decided"))

func _disconnect_if_connected(signal_value: Signal, callable: Callable) -> void:
	if signal_value.is_connected(callable):
		signal_value.disconnect(callable)

func _walk_player(action: StringName, frame_count: int) -> void:
	Input.action_press(action)
	await _frames(frame_count)
	Input.action_release(action)
	await _frames(6)

func _place_player(world_position: Vector2) -> void:
	var cell := _main.room.navigation.cell_at(world_position)
	if not _main.room.navigation.walkable(cell):
		_failures.append("Audit attempted an invalid founder placement at %s" % cell)
		return
	_main.player.cancel_route()
	_main.player.position = world_position
	_main.player._physics_process(0.0)

func _open_locomotion_origin() -> Vector2:
	# A complete four-direction demonstration needs three clear cells around its
	# origin. Derive this from occupancy instead of the former room's coordinates.
	var navigation := _main.room.navigation
	var desired := _main.room.player_spawn + Vector2i(0, -4)
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for cell: Vector2i in _main.room.layout_model.floor_cells():
		var clear := true
		for y: int in range(-3, 4):
			for x: int in range(-3, 4):
				if not navigation.walkable(cell + Vector2i(x, y)):
					clear = false
		if clear and Vector2(cell).distance_squared_to(Vector2(desired)) < best_distance:
			best = cell
			best_distance = Vector2(cell).distance_squared_to(Vector2(desired))
	if best.x < 0:
		_failures.append("No clear seven-cell locomotion patch exists in the current office")
		return _main.room.grid_to_world_position(_main.room.player_spawn)
	return _main.room.grid_to_world_position(best)

func _depth_anchor(placement: Dictionary, rear: bool) -> Vector2:
	var grid: Vector2i = placement.get("grid", Vector2i.ZERO)
	var row := grid.y
	for cell: Vector2i in placement.get("occupied", []):
		row = mini(row, cell.y) if rear else maxi(row, cell.y)
	var target := Vector2i(grid.x, row + (-1 if rear else 1))
	if not _main.room.navigation.walkable(target):
		_failures.append("%s has no valid %s audit anchor at %s" % [placement.get("id", "prop"), "rear" if rear else "front", target])
	return _main.room.grid_to_world_position(target)

func _walk_player_to(target: Vector2, label: String) -> void:
	if not _main.player.move_to(target):
		_failures.append("No founder route to " + label)
		return
	var path_length := 0.0
	var previous := _main.player.position
	for point: Vector2 in _main.player.route:
		path_length += previous.distance_to(point)
		previous = point
	var deadline := ceili(path_length / _main.player.speed * AUDIT_FPS) + 90
	for frame: int in range(deadline):
		if _main.player.route.is_empty():
			break
		await _frames(1)
	if _main.player.position.distance_to(target) > 4.0:
		_failures.append("Founder did not reach %s: %s != %s" % [label, _main.player.position, target])
	_record_marker(label)

func _record_marker(label: String) -> void:
	if _active_scenario_index < 0:
		return
	var markers: Array = _scenarios[_active_scenario_index]["markers"]
	markers.append({"label": label, "frame": Engine.get_process_frames(), "state": _actor_snapshot()})

func _actor_snapshot() -> Dictionary:
	var snapshot := {"founder": _actor_position(_main.player.position)}
	for employee_id: String in _main._employees:
		var employee := _main._employees[employee_id] as EmployeeAvatar
		var state := _actor_position(employee.position)
		state["workState"] = EmployeeAvatar.WorkState.keys()[employee.work_state]
		state["hasTarget"] = employee._has_target
		snapshot[employee_id] = state
	return snapshot

func _actor_position(point: Vector2) -> Dictionary:
	var cell := _main.room.navigation.cell_at(point)
	return {"position": [point.x, point.y], "cell": [cell.x, cell.y], "walkable": _main.room.navigation.walkable(cell)}

func _check_actor_cells() -> void:
	if _active_scenario_index < 0 or not is_instance_valid(_main):
		return
	var snapshot := _actor_snapshot()
	var current: Dictionary = _scenarios[_active_scenario_index]
	current["actorCellsChecked"] = int(current.get("actorCellsChecked", 0)) + snapshot.size()
	for id: String in snapshot:
		var state: Dictionary = snapshot[id]
		if bool(state["walkable"]):
			continue
		var message := "%s: %s occupied blocked cell %s" % [_scenarios[_active_scenario_index]["name"], id, state["cell"]]
		if not _actor_cell_failures.has(message):
			_actor_cell_failures[message] = true
			_failures.append(message)

func _move_mouse_to(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	# Inject one deterministic pointer stream. Warping the native macOS cursor
	# races Retina/window-coordinate mouse events against these viewport events.
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)

func _press_control(control: Control, allow_disabled: bool = false) -> void:
	if not _control_visible(control):
		_check(false, "input-target-visible: %s" % (str(control.name) if control != null else "missing"))
		return
	if control is BaseButton and (control as BaseButton).disabled and not allow_disabled:
		_check(false, "input-target-enabled: %s" % control.name)
		return
	_move_mouse_to(control)
	await _frames(8)
	var point := control.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.position = point
	press.global_position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	await _frames(5)
	var release := InputEventMouseButton.new()
	release.position = point
	release.global_position = point
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release, true)
	await _frames(5)

func _control_visible(control: Control) -> bool:
	if control == null or not control.is_visible_in_tree(): return false
	var point := control.get_global_rect().get_center()
	if not root.get_visible_rect().has_point(point): return false
	var parent := control.get_parent()
	while parent != null:
		if parent is Control and (parent as Control).clip_contents and not (parent as Control).get_global_rect().has_point(point): return false
		parent = parent.get_parent()
	return true

func _ensure_visible(control: Control) -> void:
	if control == null:
		_check(false, "required-control-exists")
		return
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer: (parent as ScrollContainer).ensure_control_visible(control)
		parent = parent.get_parent()
	await _frames(4)

func _type_into(control: LineEdit, text: String) -> void:
	await _ensure_visible(control)
	control.text = ""
	await _press_control(control)
	_check(control.has_focus() and control.editable and _control_visible(control), "visible-editable-text-focus")
	for character: String in text:
		var key_event := InputEventKey.new()
		key_event.unicode = character.unicode_at(0)
		key_event.pressed = true
		root.push_input(key_event, true)
		await _frames(1)
	_check(control.text == text, "real-keyboard-text-entry")

func _wheel(control: Control, direction: MouseButton) -> void:
	if not _control_visible(control):
		_check(false, "scroll-target-visible")
		return
	_move_mouse_to(control)
	var event := InputEventMouseButton.new()
	event.button_index = direction
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.pressed = true
	root.push_input(event, true)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await _frames(2)

func _button_named(parent: Node, text: String) -> Button:
	for child: Node in parent.find_children("*", "Button", true, false):
		if (child as Button).text == text: return child as Button
	return null

func _check(condition: bool, label: String) -> void:
	if _active_scenario_index >= 0:
		var checks: Array = _scenarios[_active_scenario_index]["checks"]
		checks.append({"label": label, "passed": condition, "frame": Engine.get_process_frames()})
	if not condition: _failures.append(label)

func _checkpoint(label: String) -> void:
	await _frames(2)
	RenderingServer.force_draw(false)
	var path := "%s/%s/%s-%s.png" % [OUTPUT_ROOT, _suite, _scenarios[_active_scenario_index].name, label]
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "checkpoint-saved: " + label)
	(_scenarios[_active_scenario_index]["checkpoints"] as Dictionary)[label] = {"path": path, "frame": Engine.get_process_frames(), "uiState": _ui_snapshot()}
	_record_marker(label)

func _ui_snapshot() -> Dictionary:
	return {
		"employeeId": _main.job_panel.selected_employee_id(),
		"drawerOpen": _main.job_panel.drawer_is_open(),
		"tab": _main.job_panel._tabs.current_tab,
		"activeJobId": _main.job_panel.active_job_id(),
		"chatPending": _main.job_panel._chat_pending,
		"assignmentDisabled": _main.job_panel._assign_button.disabled,
		"approvalVisible": _main.job_panel._approval_box.is_visible_in_tree(),
		"workerConnected": _main.job_panel._worker_connected,
		"connectionVisible": _main.job_panel._connection_panel.is_visible_in_tree(),
		"readerVisible": _main.artifact_viewer.visible,
		"readerScroll": _main.artifact_viewer._content.get_v_scroll_bar().value,
		"readerTextLength": _main.artifact_viewer._content.get_parsed_text().length(),
		"notificationVisible": _main.founder_hud.delivery_visible(),
	}

func _reader_document() -> String:
	return "# Launch brief\n\n## Promise\nHelp a first-time creator validate one paid offer in seven days. Keep **evidence** separate from *assumptions*.\n\n- Publish one landing page.\n- Book five follow-up calls.\n\n```text\nOwner: Mina\nWindow: 7 days\n```\n\n".repeat(10)

func _press_key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = pressed
		root.push_input(key, true)
		await _frames(1)

func _event(type_value: StringName) -> WorkerEventRecord:
	var event := WorkerEventRecord.new()
	event.type = type_value
	return event

func _long_chat_history() -> Array[Dictionary]:
	return [
		{"sender": "player", "content": "Customer interviews keep pointing at the same launch problem."},
		{"sender": "employee", "content": "I would group the evidence and choose one narrow promise."},
		{"sender": "player", "content": "Keep it useful for a first-time creator with one week."},
		{"sender": "employee", "content": "Then the output should be a short promise, evidence summary, and experiment."},
		{"sender": "player", "content": "Make the experiment measurable without requiring a large audience."},
		{"sender": "employee", "content": "We can use one landing page and five follow-up calls as the first signal."},
		{"sender": "player", "content": "That is the direction. Keep it concise enough to share with Theo."},
		{"sender": "employee", "content": "Understood. I will preserve the decisions and remove the interview noise."},
	]

func _frames(frame_count: int) -> void:
	for frame: int in range(frame_count):
		await process_frame
		_check_actor_cells()

func _wait_for_employee_state(employee: EmployeeAvatar, expected_state: int, max_frames: int, label: String) -> void:
	var path_length := 0.0
	var previous := employee.position
	for point: Vector2 in employee._route:
		path_length += previous.distance_to(point)
		previous = point
	# Wall-aware routes can be longer than the old straight-line animations.
	var navigation_deadline := maxi(max_frames, ceili(path_length / employee.walk_speed * AUDIT_FPS) + 120)
	for frame: int in range(navigation_deadline):
		if employee.work_state == expected_state and not employee._has_target:
			return
		await _frames(1)
	_failures.append("Timed out waiting for %s" % label)
	print("Navigation timeout: ", employee.employee_id, " at ", employee.position, " route ", employee._route, " actors ", employee.navigation.actors)
