extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const OUTPUT_PATH := "res://tests/output/test_worker_walks_to_desk.png"
const BASELINE_PATH := "res://tests/baselines/test_worker_walks_to_desk.png"

var _failures: int = 0
var _steer_job_id: String = ""
var _steer_message: String = ""
var _assignment_employee_id: String = ""
var _assignment_title: String = ""
var _assignment_text: String = ""
var _chat_employee_id: String = ""
var _chat_message: String = ""

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _fail(message: String) -> void:
	_failures += 1
	push_error(message)

func _run() -> void:
	var main := MAIN_SCENE.instantiate() as GameMain
	root.add_child(main)
	await process_frame
	await process_frame
	var chat_history_handler := Callable(main.worker_client, "request_chat_history")
	if main.job_panel.chat_history_requested.is_connected(chat_history_handler):
		main.job_panel.chat_history_requested.disconnect(chat_history_handler)
	var chat_submit_handler := Callable(main.worker_client, "send_chat")
	if main.job_panel.chat_submitted.is_connected(chat_submit_handler):
		main.job_panel.chat_submitted.disconnect(chat_submit_handler)
	main.job_panel.set_credential_status(true)
	main.job_panel.set_worker_ready()
	_assert_ui_typography(main)
	var tab_titles: PackedStringArray = []
	for tab_index: int in range(main.job_panel._tabs.get_tab_count()):
		tab_titles.append(main.job_panel._tabs.get_tab_title(tab_index))
	if tab_titles != PackedStringArray(["Chat", "Assign", "Activity", "Studio"]):
		_fail("test_ui_language: employee drawer tabs do not use the approved product terms")
	for tab: Button in main.job_panel._tab_buttons:
		if tab.custom_minimum_size.y < 44.0 or not is_equal_approx(tab.size.x, 86.0):
			_fail("test_ui_layout: real drawer tabs must have equal widths and 44-pixel targets")
	var delivery_button := main.founder_hud.find_child("ViewDelivery", true, false) as Button
	if delivery_button == null or delivery_button.size.y < 40.0:
		_fail("test_ui_layout: delivery review target is below the 40-pixel interaction floor")
	if _contrast_ratio(JobPanel.CHARCOAL, JobPanel.VERMILION) < 4.5 \
		or _contrast_ratio(JobPanel.ALERT_INK, JobPanel.PARCHMENT) < 4.5 \
		or _contrast_ratio(JobPanel.SUCCESS_INK, JobPanel.PARCHMENT) < 4.5 \
		or _contrast_ratio(JobPanel.INDIGO, JobPanel.PARCHMENT) < 4.5:
		_fail("test_ui_contrast: an essential text and surface pair is below 4.5:1")
	main.job_panel.set_credential_status(false)
	await process_frame
	if not main.job_panel._connection_panel.visible or not main.job_panel._assign_button.disabled:
		_fail("test_connection_ui: first run did not separate Connect AI from employee Assign")
	main.job_panel.set_credential_status(true)
	main.job_panel._close_connection_settings()
	main.job_panel.close_drawer(false)
	if main.job_panel.selected_employee_id() != "mira":
		_fail("test_native_team_ui: the first employee was not selected")
	if main.job_panel.drawer_is_open():
		_fail("test_native_team_ui: the employee drawer was open during exploration")
	var rail_style := main.job_panel._rail_panel.get_theme_stylebox("panel") as StyleBoxTexture
	if rail_style == null or rail_style.texture != NotebookSkin.WOOD_FILL:
		_fail("test_character_art: the modular team rail did not use the approved notebook wood")
	_assert_modular_room(main)
	var founder_sprite := main.player.get_node_or_null("CharacterSprite") as Sprite2D
	if founder_sprite == null or founder_sprite.texture == null:
		_fail("test_character_art: the founder did not use the character sheet in the office")
	if main.clock_panel.get_global_rect().end.x >= main.job_panel.rail_global_rect().position.x:
		_fail("test_ui_layout: the clock overlaps the compact team rail")
	if not main.clock_panel.find_children("*", "Button", true, false).is_empty():
		_fail("test_ui_layout: the clock still exposes speed controls")
	var ledger_texture := main.clock_panel.get_node_or_null("LedgerTexture") as TextureRect
	if ledger_texture == null or ledger_texture.texture != ClockPanel.LEDGER_TEXTURE:
		_fail("test_founders_ledger_ui: the live clock did not use the selected ledger artwork")
	if main.founder_hud.get_node_or_null("TitlePlaque") != null or main.founder_hud.get_node_or_null("MovementPlaque") == null:
		_fail("test_founders_ledger_ui: gameplay retained the title plaque or lost the onboarding hint")
	main.clock_panel.show_money_earned(125.5)
	if main.clock_panel._earned_label.text != "$125.50" or main.clock_panel._earned_caption.text != "Earned" or not main.clock_panel._earned_label.tooltip_text.contains("Gross in-game revenue"):
		_fail("test_ui_layout: earned money did not render in the HUD")
	var mina := main.get_employee("mira")
	main.player.position = mina.position + Vector2(48.0, 0.0)
	main.founder_hud.update_interaction(main.player.position, main._employees, true)
	if not main.founder_hud.interaction_visible() or main.founder_hud.interaction_target_id() != "mira":
		_fail("test_founders_ledger_ui: approaching Mina did not show her chat prompt")
	mina.memory_line = "A memory bubble should yield to the interaction prompt."
	mina._speech_visible = true
	main._process(0.0)
	if mina._speech_visible:
		_fail("test_world_ui: the memory bubble overlapped the nearby interaction prompt")
	main.founder_hud._request_chat()
	if not main.job_panel.drawer_is_open() or main.job_panel.selected_employee_id() != "mira" or main.job_panel._tabs.current_tab != 0:
		_fail("test_founders_ledger_ui: the proximity prompt did not open Mina's Chat tab")
	main.job_panel.close_drawer(false)
	main.founder_hud.show_delivery("delivery-test", "mira", "Mina", "design-note.md ready")
	if not main.founder_hud.delivery_visible():
		_fail("test_founders_ledger_ui: a completed delivery did not show the pinned memo")
	main.founder_hud._request_delivery()
	if main.founder_hud.delivery_visible() or not main.job_panel.drawer_is_open() or main.job_panel._tabs.current_tab != 2:
		_fail("test_founders_ledger_ui: the memo did not open the delivery journal")
	main.job_panel.close_drawer(false)
	main.job_panel._on_team_button_pressed("mira")
	if not main.job_panel.drawer_is_open():
		_fail("test_native_team_ui: clicking a portrait did not open the employee drawer")
	main.job_panel._on_team_button_pressed("mira")
	if main.job_panel.drawer_is_open():
		_fail("test_native_team_ui: clicking the selected portrait did not close the employee drawer")
	main.job_panel.select_employee("mira")
	main.job_panel._tabs.current_tab = 1
	await process_frame
	if not main.job_panel.work_controls_fit_panel():
		_fail("test_ui_layout: the work controls overflow the employee drawer")
	_assert_shared_button(main.job_panel._purpose_picker, "secondary")
	if main.job_panel._purpose_picker.get_popup().get_theme_font("font") != GameFonts.EMPHASIS:
		_fail("test_operations_ui: dropdown popup did not use the shared readable font")
	_assert_shared_button(main.job_panel._cancel_button, "danger")
	_assert_shared_button(main.job_panel._make_job_button, "quiet")
	var team_focus_style := (main.job_panel._team_buttons["mira"] as Button).get_theme_stylebox("focus")
	var attention_texture := (main.job_panel._team_buttons["mira"] as Button).get_node_or_null("AttentionBadge") as TextureRect
	if team_focus_style == null or attention_texture == null or attention_texture.texture != OperationsSkin.ATTENTION_BADGE:
		_fail("test_operations_ui: team rail lost keyboard focus or authored attention state")
	main.job_panel._tabs.current_tab = 0
	main.job_panel.select_employee("theo")
	if main.job_panel.selected_employee_id() != "theo":
		_fail("test_native_team_ui: the vertical team rail did not select Theo")
	var theo_selection := (main.job_panel._team_buttons["theo"] as Button).get_node_or_null("SelectionFrame") as Panel
	if theo_selection == null or not theo_selection.visible:
		_fail("test_native_team_ui: the modular team rail did not move its selection treatment to Theo")
	main.job_panel.show_chat_history("theo", [
		{"sender": "player", "content": "What should we test first?"},
		{"sender": "employee", "content": "Start with the smallest useful growth experiment."},
	])
	await process_frame
	if not main.job_panel.chat_text().contains("growth experiment"):
		_fail("test_native_team_ui: persisted chat did not render in the employee drawer")
	var founder_row := main.job_panel._chat_log.get_child(0) as HBoxContainer
	var employee_row := main.job_panel._chat_log.get_child(1) as HBoxContainer
	var founder_bubble := founder_row.get_child(1) as PanelContainer if founder_row != null and founder_row.get_child_count() > 1 else null
	var employee_bubble := employee_row.get_child(1) as PanelContainer if employee_row != null and employee_row.get_child_count() > 1 else null
	if founder_bubble == null or employee_bubble == null:
		_fail("test_operations_ui: founder and employee chat lost distinct message surfaces")
	else:
		for bubble: PanelContainer in [founder_bubble, employee_bubble]:
			if bubble.get_theme_stylebox("panel").get_content_margin(SIDE_LEFT) < 10:
				_fail("test_operations_ui: chat text lost its safe content inset")
	if main.job_panel._make_job_button.get_parent() != main.job_panel._latest_reply_content:
		_fail("test_operations_ui: work-order conversion is detached from the latest employee reply")
	main.job_panel.chat_submitted.connect(_capture_chat)
	main.job_panel._chat_input.text = "Keep this conversational for now."
	main.job_panel._submit_chat()
	if _chat_employee_id != "theo" or _chat_message != "Keep this conversational for now.":
		_fail("test_chat_to_work: Chat did not dispatch the bounded conversation request")
	main.job_panel.show_chat_reply("theo", {"content": "Understood. No work order has started."}, 0.0)
	if main.job_panel._make_job_button.disabled or not main.job_panel._make_job_button.visible:
		_fail("test_native_team_ui: a complete conversation did not expose Create Work Order")
	main.job_panel._make_last_chat_a_job()
	if main.job_panel._tabs.current_tab != 1 or not main.job_panel._assignment_preview.text.contains("Founder: What should we test first?") or not main.job_panel._assignment_preview.text.contains("Theo: Start with the smallest useful growth experiment."):
		_fail("test_chat_to_work: the local draft did not preserve both sides of the bounded discussion")
	var assignment_handler := Callable(main, "_on_assignment_submitted")
	main.job_panel.assignment_submitted.disconnect(assignment_handler)
	main.job_panel.assignment_submitted.connect(_capture_assignment)
	main.job_panel._job_picker.select(main.job_panel.CANNED_JOBS.size())
	main.job_panel._on_job_selected(main.job_panel.CANNED_JOBS.size())
	main.job_panel._custom_title_input.text = "Small growth experiment"
	main.job_panel._assignment_preview.text = "Create a short experiment brief in experiment.md."
	main.job_panel._submit_assignment()
	if _assignment_employee_id != "theo" or _assignment_title != "Small growth experiment" or not _assignment_text.contains("experiment.md"):
		_fail("test_native_team_ui: the work composer did not emit Theo's custom work order")
	main.job_panel._job_picker.select(0)
	main.job_panel._on_job_selected(0)
	main.job_panel.select_employee("mira")
	if main.room.unlocked_hires != 2:
		_fail("test_office_growth: the two-person roster did not restore its furniture stage")
	if main.room.visible_prop_count() != 8:
		_fail("test_modular_office: the two-person stage did not show the founder, collaboration, and research props")
	main.room.set_hire_count(0)
	if main.room.find_child("LockedSections", true, false) != null:
		_fail("test_office_growth: an empty office stage still created blocked expansion areas")
	if main.room.visible_prop_count() != 1 or main.room.prop_node("founder-workstation") == null:
		_fail("test_modular_office: the empty founder stage did not retain exactly one usable workstation")
	main.room.set_hire_count(1)
	if main.room.visible_prop_count() != 5 or main.room.prop_node("mira-workstation") == null:
		_fail("test_modular_office: the first hire did not reveal Mina's workstation and social wing")
	if main.room.prop_node("collaboration-cluster") == null or main.room.prop_node("coffee-station") == null:
		_fail("test_modular_office: the first-hire meeting and coffee props were missing")
	var staged_desk := main.room.prop_node("mira-workstation")
	var staged_desk_rear := staged_desk.get_node_or_null("DeskRear") as Sprite2D if staged_desk != null else null
	var staged_desk_front := staged_desk.get_node_or_null("DeskFront") as Sprite2D if staged_desk != null else null
	if staged_desk == null or not is_zero_approx(staged_desk.rotation) or staged_desk_rear == null or staged_desk_front == null:
		_fail("test_modular_office: the workstation did not use authored rear/front layers")
	elif not staged_desk_rear.scale.is_equal_approx(Vector2.ONE) or not staged_desk_front.scale.is_equal_approx(Vector2.ONE):
		_fail("test_modular_office: the workstation did not render at native scale")
	elif staged_desk_rear.z_index >= staged_desk_front.z_index:
		_fail("test_modular_office: the workstation occlusion layers were reversed")
	main.room.set_hire_count(4)
	if main.room.visible_prop_count() != 9:
		_fail("test_modular_office: the mature office did not include every staged prop")
	if main.room.prop_node("approval-console") == null or main.room.prop_node("artifact-archive") == null or main.room.prop_node("prototype-bench") == null:
		_fail("test_modular_office: the mature office was missing its operations or artifact prop")
	for stage: int in range(5):
		main.room.set_hire_count(stage)
		_assert_modular_room(main)
	var restored_records := main.room.placeholder_records()
	main.room.set_hire_count(restored_records.size())
	var restored_studio: Array[StudioFileRecord] = []
	var restored_file := StudioFileRecord.new()
	restored_file.name = "design-note.md"
	restored_file.relative_path = "design-note.md"
	restored_file.source_job_id = "completed-note"
	restored_studio.append(restored_file)
	main._on_bootstrap(
		restored_records,
		"company",
		"/tmp/startup-valley-test",
		12000,
		0.0,
		5.0,
		{"day": 4, "minuteOfDay": DayClock.LUNCH_START, "speed": 0.0},
		restored_studio,
		[{
			"jobId": "pending-review",
			"employeeName": "Theo",
			"title": "Restored review",
			"artifacts": [{"name": "review.md"}],
		}],
		[{"jobId": "completed-note", "employeeId": "mira", "title": "Restored note", "status": "completed"}],
		{"mira": [{"kind": "outcome", "fact": "Outcome: restored durable note"}], "theo": []}
	)
	await process_frame
	if main.day_clock.day != 4 or main.day_clock.phase != "lunch":
		_fail("test_persistent_boot: clock state was not restored")
	if main.job_panel.studio_file_count() != 1 or not main.job_panel.last_status_text().contains("Completed"):
		_fail("test_persistent_boot: studio listing or last status was not restored")
	var studio_file_card := main.job_panel._artifact_list.get_child(0) as PanelContainer
	var studio_file_button := studio_file_card.find_child("Preview", true, false) as Button if studio_file_card != null else null
	if studio_file_button == null or studio_file_button.text != "Open" or not studio_file_button.tooltip_text.contains("design-note.md"):
		_fail("test_operations_ui: Studio file lost its named file and explicit Open action")
	else:
		_assert_shared_button(studio_file_button, "secondary")
	if not main.job_panel._has_pending_delivery("theo"):
		_fail("test_persistent_boot: pending promotion was not restored")
	if main.founder_hud.delivery_visible():
		_fail("test_persistent_boot: hydration replayed an old completion toast")
	if main.get_employee("mira").memory_line != "Outcome: restored durable note":
		_fail("test_persistent_boot: employee memory was not restored")
	main._spawn_employees([])
	if main.founder_hud.delivery_visible():
		_fail("test_notification_lifecycle: removing the roster retained a stale delivery memo")
	main._spawn_employees(restored_records)
	main.artifact_viewer.show_artifact("design-note.md", "# Design note\n\nReadable delivery text.")
	await process_frame
	if not main.artifact_viewer.modal_fits_viewport() or not main.artifact_viewer.scrim_covers_viewport():
		_fail("test_artifact_viewer: the modal or its scrim escaped the viewport")
	var reader_frame := main.artifact_viewer._modal.get_theme_stylebox("panel")
	var reader_paper_style := main.artifact_viewer._content.get_theme_stylebox("normal")
	if reader_frame == null or reader_frame.get_meta("cozy_material", "") != "notebook" or not reader_paper_style.get_meta("cozy_unframed", false) or reader_paper_style.get_content_margin(SIDE_RIGHT) < 12:
		_fail("test_operations_ui: artifact reader lost its single quiet reading surface")
	if main.artifact_viewer._content.get_theme_font("normal_font") != GameFonts.BODY or main.artifact_viewer._content.get_theme_font("mono_font") != GameFonts.MONO:
		_fail("test_operations_ui: reader body/code font roles are not explicit")
	if main.artifact_viewer._content.get_parsed_text().contains("# Design note"):
		_fail("test_artifact_viewer: common Markdown headings were shown as raw markers")
	main.artifact_viewer.hide()
	main.day_clock.set_time(4, DayClock.WORK_START)
	await process_frame
	var scheduled_employee := main.get_employee("mira")
	scheduled_employee._idle_elapsed = 0.4
	scheduled_employee.set_schedule_phase("work")
	if scheduled_employee._idle_elapsed < 0.4:
		_fail("test_day_clock: repeated work ticks reset the employee idle schedule")

	main.job_panel.show_pending_promotions([])
	main.job_panel.begin_job("queued-state", "theo")
	main.job_panel.mark_job_queued("queued-state")
	main.job_panel.select_employee("theo")
	if main.job_panel._employee_status.text != "Queued" or main.job_panel._employee_ui_state("theo") == "working":
		_fail("test_ui_status: queued work was simultaneously presented as working")
	main.job_panel.finish_job("queued-state")

	main.job_panel.select_employee("mira")
	main.job_panel.begin_job("steer-job", "mira")
	if main.job_panel._event_log.get_theme_font("normal_font") != GameFonts.BODY or main.job_panel._event_log.get_theme_font("bold_font") != GameFonts.BOLD:
		_fail("test_operations_ui: Activity does not use explicit body and emphasis roles")
	if main.job_panel._approval_box.get_theme_stylebox("panel").get_content_margin(SIDE_LEFT) < 8 or main.job_panel._promotion_box.get_theme_stylebox("panel").get_content_margin(SIDE_LEFT) < 8:
		_fail("test_operations_ui: decisions lost safe content insets")
	if main.job_panel._token_meter.visible:
		_fail("test_operations_ui: a daily cost meter is incorrectly presented as work progress")
	main.job_panel.set_spend(2.5, 5.0)
	if not main.job_panel._spend_label.text.contains("$2.5000 USD") or not main.job_panel._spend_label.tooltip_text.contains("$5.00 USD"):
		_fail("test_operations_ui: real spend and warning threshold must be accurately disclosed")
	if OperationsSkin.ACTIVITY_THINKING == null or OperationsSkin.ACTIVITY_RESEARCH == null or OperationsSkin.ACTIVITY_WRITING == null or OperationsSkin.ACTIVITY_TOOL == null or OperationsSkin.ACTIVITY_APPROVAL == null or OperationsSkin.ACTIVITY_ARTIFACT == null or OperationsSkin.ACTIVITY_COMPLETE == null or OperationsSkin.ACTIVITY_FAILED == null:
		_fail("test_operations_ui: one or more real-event activity icons failed to load")
	if OperationsSkin.WORLD_SPEECH_BUBBLE == null or OperationsSkin.WORLD_NAMEPLATE == null or OperationsSkin.WORLD_STATUS_PLAQUE == null or OperationsSkin.WORLD_ATTENTION == null:
		_fail("test_operations_ui: one or more in-world label assets failed to load")
	if not main.job_panel.status_color().is_equal_approx(main.job_panel.CHARCOAL):
		_fail("test_ui_status: submitting work retained a stale error color")
	if main.job_panel._event_log.get_parsed_text() != "" or not main.job_panel._usage_label.text.contains("0 tokens"):
		_fail("test_ui_status: a new work order retained stale activity or usage")
	main._job_employees["steer-job"] = "mira"
	main.job_panel.accept_submission("steer-job")
	var steer_started := WorkerEventRecord.new()
	steer_started.type = &"job.started"
	main._on_job_event("steer-job", steer_started)
	await process_frame
	if not main.job_panel.steer_controls_visible():
		_fail("test_active_job_steer: controls did not appear for an in-flight job")
	var active_status_before_disconnect := main.job_panel._status_label.text
	main.job_panel.set_worker_connection_error("Worker is not connected")
	if main.job_panel._status_label.text != active_status_before_disconnect or not main.job_panel._connection_badge.visible:
		_fail("test_connection_ui: connectivity replaced active work meaning instead of using the global rail state")
	main.job_panel.set_worker_ready()
	main.job_panel.steer_submitted.connect(_capture_steer)
	main.job_panel._tabs.current_tab = 0
	main.job_panel._chat_input.text = "This must not steer from Chat."
	main.job_panel._submit_chat()
	if main.job_panel._tabs.current_tab != 2 or not _steer_job_id.is_empty():
		_fail("test_chat_to_work: Chat did not remain read-only while a work order was active")
	main.job_panel._steer_input.text = "Keep the note under 300 words."
	main.job_panel._submit_steer()
	if _steer_job_id != "steer-job" or _steer_message != "Keep the note under 300 words.":
		_fail("test_active_job_steer: update did not retain the active job identity and text")
	if main.job_panel.active_job_id() != "steer-job":
		_fail("test_active_job_steer: steering replaced the active work order")
	main.job_panel.set_steer_sent("steer-job")
	main._on_worker_crashed("Fake worker exit")
	await process_frame
	if not main.job_panel.active_job_id().is_empty():
		_fail("test_worker_crash: active job remained stuck after the worker exited")
	if main.get_employee("mira").work_state != EmployeeAvatar.WorkState.IDLE:
		_fail("test_worker_crash: employee remained busy after the worker exited")

	var employee := main.get_employee("mira")
	main.job_panel.close_drawer(false)
	await process_frame
	if employee == null:
		_fail("test_worker_walks_to_desk: Mina was not spawned")
	else:
		var employee_sprite := employee.get_node_or_null("CharacterSprite") as Sprite2D
		if employee_sprite == null or employee_sprite.texture == null:
			_fail("test_character_art: Mina did not use the character sheet in the office")
		main.simulate_worker_event("mira", &"job.started")
		var frames := 0
		while not employee.is_at_desk() and frames < 360:
			employee._physics_process(1.0 / 60.0)
			frames += 1
		if not employee.is_at_desk():
			_fail("test_worker_walks_to_desk: employee did not reach the desk")
		var mina_desk := main.room.prop_node("mira-workstation")
		var desk_front := mina_desk.get_node_or_null("DeskFront") as Sprite2D if mina_desk != null else null
		var actor_lower := employee._work_pose_layer_sprites.get("lower") as Sprite2D
		var actor_upper := employee._work_pose_layer_sprites.get("upper") as Sprite2D
		if desk_front == null or actor_lower == null or actor_upper == null or actor_lower.z_index >= desk_front.z_index or actor_upper.z_index <= desk_front.z_index:
			_fail("test_modular_office: Mina's split seated pose did not bracket the reviewed desk front")
		main.simulate_worker_event("mira", &"tool.started", "write_file")
		await process_frame
		if employee.work_state != EmployeeAvatar.WorkState.TYPING:
			_fail("test_worker_walks_to_desk: write_file did not produce typing state")
		main.simulate_worker_event("mira", &"job.failed")
		await process_frame
		if employee.work_state != EmployeeAvatar.WorkState.IDLE:
			_fail("test_worker_walks_to_desk: failed job did not return Mina to idle")
		main.day_clock.set_time(1, DayClock.LUNCH_START)
		await process_frame
		if main.day_clock.phase != "lunch" or employee.work_state != EmployeeAvatar.WorkState.LUNCH:
			_fail("test_day_clock: 12:30 did not enter lunch without fake work")
		main.day_clock.set_time(1, DayClock.WORK_END)
		await process_frame
		if main.day_clock.phase != "off" or employee.work_state != EmployeeAvatar.WorkState.OFF_SHIFT:
			_fail("test_day_clock: 17:30 did not enter off shift")
		main.day_clock.set_time(2, DayClock.WORK_START - 1)
		main.day_clock.advance_minutes(1)
		await process_frame
		if main.day_clock.phase != "work":
			_fail("test_day_clock: queued work window did not open at 08:00")
		main.simulate_worker_event("mira", &"tool.started", "write_file")
		await process_frame

	var image := _software_state_screenshot(main)
	if image == null or image.is_empty():
		_fail("test_worker_walks_to_desk: could not capture a screenshot")
	else:
		var output_error := image.save_png(OUTPUT_PATH)
		if output_error != OK:
			_fail("test_worker_walks_to_desk: could not save output screenshot")
		elif OS.get_environment("STARTUP_VALLEY_UPDATE_BASELINE") == "1":
			var baseline_error := image.save_png(BASELINE_PATH)
			if baseline_error != OK:
				_fail("test_worker_walks_to_desk: could not update baseline")
		else:
			_compare_baseline(image)

	var long_delivery := WorkerEventRecord.new()
	long_delivery.type = &"job.completed"
	long_delivery.summary = "A detailed delivery summary with multiple findings and recommendations. ".repeat(20)
	main.job_panel.select_employee("mira")
	main.job_panel.begin_job("layout-check", "mira")
	main.job_panel.on_job_event("layout-check", long_delivery)
	var preview_artifact := ArtifactRecord.new()
	preview_artifact.artifact_id = "layout-preview"
	preview_artifact.job_id = "layout-check"
	preview_artifact.name = "delivery.md"
	preview_artifact.relative_path = "delivery.md"
	main.job_panel.show_artifacts("layout-check", [preview_artifact])
	main.job_panel.offer_promotion("layout-check", "mira")
	main.job_panel.open_journal_for_employee("mira")
	for frame: int in range(20): await process_frame
	if not main.job_panel.promotion_controls_fit_viewport():
		_fail("test_delivery_layout: long summaries pushed promotion controls below the viewport")
	var preview_button := main.job_panel._delivery_list.find_child("Preview", true, false) as Button
	if preview_button == null or preview_button.get_global_rect().end.y >= main.job_panel._promotion_box.get_global_rect().position.y:
		_fail("test_delivery_layout: inspectable files must precede the promotion decision")

	if _failures == 0:
		print("test_worker_walks_to_desk: passed")
	root.remove_child(main)
	main.free()
	quit(_failures)

func _capture_steer(job_id: String, message: String) -> void:
	_steer_job_id = job_id
	_steer_message = message

func _capture_assignment(
	employee_id: String,
	title: String,
	assignment: String,
	_acceptance_criteria: PackedStringArray,
	_attached_studio_path: String
) -> void:
	_assignment_employee_id = employee_id
	_assignment_title = title
	_assignment_text = assignment

func _capture_chat(employee_id: String, message: String) -> void:
	_chat_employee_id = employee_id
	_chat_message = message

func _assert_shared_button(button: Button, variant: String) -> void:
	if button.get_meta("cozy_variant", "") != variant or button.get_theme_font("font") != GameFonts.BOLD:
		_fail("test_shared_controls: %s does not use the intended %s action and bold font" % [button.name, variant])
	if button.custom_minimum_size.y < 44:
		_fail("test_shared_controls: %s is below the target floor" % button.name)
	var minimum := button.get_theme_stylebox("normal").get_minimum_size()
	for state: String in ["hover", "pressed", "disabled", "hover_pressed"]:
		if not button.get_theme_stylebox(state).get_minimum_size().is_equal_approx(minimum):
			_fail("test_shared_controls: %s geometry jumps in %s" % [button.name, state])
	if not button.has_theme_stylebox_override("focus"):
		_fail("test_shared_controls: %s has no explicit keyboard focus" % button.name)

func _assert_modular_room(main: GameMain) -> void:
	var room := main.room
	if main.get_node_or_null("Backdrop") != null:
		_fail("test_modular_office: obsolete campus overlay still exists")
	if room.layout_model == null or room.architecture == null or room.architecture.layout != room.layout_model:
		_fail("test_modular_office: rendered architecture does not share the authoritative layout")
		return
	if room.architecture.theme_id != OfficeArchitecture.DEFAULT_THEME:
		_fail("test_modular_office: a fresh office must spawn the oak architecture theme")
	var cafe_floor := load(OfficeArchitecture.theme_path("cafe", "floor")) as Texture2D
	main.company_panel.present("settings")
	var theme_picker := main.company_panel.find_child("ArchitectureTheme", true, false) as OptionButton
	var cafe_index := -1
	if theme_picker == null:
		_fail("test_modular_office: Settings does not offer an office look")
	else:
		for index: int in range(theme_picker.item_count):
			if str(theme_picker.get_item_metadata(index)) == "cafe": cafe_index = index
		if cafe_index < 0:
			_fail("test_modular_office: Cafe is not a selectable office look")
		else:
			theme_picker.item_selected.emit(cafe_index)
	if room.architecture.theme_id != "cafe" or room.architecture.floor_art != cafe_floor:
		_fail("test_modular_office: choosing Cafe did not spawn the cafe architecture kit")
	if room.architecture.apply_theme("loft") or room.architecture.apply_theme("studio") or room.architecture.apply_theme("evening"):
		_fail("test_modular_office: unbound architecture themes must not replace the office")
	if not room.architecture.apply_theme(OfficeArchitecture.DEFAULT_THEME):
		_fail("test_modular_office: oak office theme did not restore")
	main.company_panel.set_architecture_theme(room.architecture.theme_id)
	main.company_panel.hide()
	if room.global_position != Vector2.ZERO or not room.playable_bounds().encloses(Rect2(0, 0, 1280, 720)):
		_fail("test_modular_office: architecture does not cover the logical viewport")
	var validation := room.layout_model.validate_placements(room.resolved_placements)
	if not validation.valid:
		_fail("test_modular_office: live hire stage is invalid: %s" % validation.errors)
	var occupied := room.layout_model.occupied_cells(room.resolved_placements)
	for y: int in range(room.grid_height):
		for x: int in range(room.grid_width):
			var cell := Vector2i(x, y)
			var expected := room.layout_model.is_floor(cell) and not occupied.has(cell)
			if room.navigation.walkable(cell) != expected:
				_fail("test_modular_office: navigation diverges from architecture/placement at %s" % cell)
	for placement: Dictionary in room.resolved_placements:
		var prop := room.prop_node(str(placement.id))
		if prop == null or prop.position != placement.anchor:
			_fail("test_modular_office: prop does not use resolved anchor: %s" % placement.id)
		if room.interaction_world_position(str(placement.id)) != room.grid_to_world_position(placement.interaction):
			_fail("test_modular_office: station interaction does not use resolved cell: %s" % placement.id)

func _assert_ui_typography(main: GameMain) -> void:
	var controls: Array[Node] = [main.job_panel, main.clock_panel, main.founder_hud, main.artifact_viewer]
	controls.append_array(main.find_children("*", "Control", true, false))
	var seen: Dictionary = {}
	for node: Node in controls:
		if not node is Control or seen.has(node.get_instance_id()):
			continue
		seen[node.get_instance_id()] = true
		var control := node as Control
		if not _control_has_readable_text(control):
			continue
		if control is RichTextLabel:
			var rich_size := control.get_theme_font_size("normal_font_size")
			if rich_size > 0 and rich_size < GameFonts.BODY_DEFAULT:
				_fail("test_ui_typography: %s rich body text is below 16 px" % control.name)
			if control.get_theme_font("bold_font") == control.get_theme_font("normal_font") or control.get_theme_font("mono_font") != GameFonts.MONO:
				_fail("test_ui_typography: %s lost distinct bold or bundled code font" % control.name)
			continue
		var font_size := control.get_theme_font_size("font_size")
		var font := control.get_theme_font("font")
		if font not in [GameFonts.DISPLAY, GameFonts.BODY, GameFonts.EMPHASIS, GameFonts.BOLD]:
			_fail("test_ui_typography: %s uses an unapproved functional font" % control.name)
		if font == GameFonts.DISPLAY and font_size != 22:
			_fail("test_ui_typography: %s must use Slab at native22" % control.name)
		elif font_size < GameFonts.BODY_META:
			_fail("test_ui_typography: %s secondary copy is below 14 px" % control.name)
		if control is BaseButton and font != GameFonts.BOLD:
			_fail("test_ui_typography: %s action text must use Nunito Bold" % control.name)

func _control_has_readable_text(control: Control) -> bool:
	if control is Label:
		return not (control as Label).text.is_empty()
	if control is Button:
		return not (control as Button).text.is_empty()
	return control is LineEdit or control is TextEdit or control is RichTextLabel or control is OptionButton or control is TabContainer

func _contrast_ratio(first: Color, second: Color) -> float:
	var first_luminance := _relative_luminance(first)
	var second_luminance := _relative_luminance(second)
	var lighter := maxf(first_luminance, second_luminance)
	var darker := minf(first_luminance, second_luminance)
	return (lighter + 0.05) / (darker + 0.05)

func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)

func _software_state_screenshot(main: GameMain) -> Image:
	# `godot --headless` deliberately uses the dummy renderer, so viewport textures
	# do not exist. This is a LOGICAL STATE DIAGRAM, not evidence that the game art
	# looks correct. Actual rendered captures are covered by the graphics suites.
	var image := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	image.fill(Color("484b52"))
	var model := main.room.layout_model
	var room_origin := Vector2i(main.room.global_position * 0.5)
	var tile := model.tile_size / 2
	for cell: Vector2i in model.floor_cells():
		var floor_color := Color("ad9774") if (cell.x + cell.y) % 2 == 0 else Color("aa9471")
		_fill_rect(image, Rect2i(room_origin + cell * tile, Vector2i(tile, tile)), floor_color)
	for placement: Dictionary in main.room.resolved_placements:
		for cell: Vector2i in placement.occupied:
			_fill_rect(image, Rect2i(room_origin + cell * tile, Vector2i(tile, tile)), Color("8c6748"))
		var target := Vector2i((main.room.global_position + model.world(placement.interaction)) * 0.5)
		_fill_rect(image, Rect2i(target - Vector2i(2, 2), Vector2i(4, 4)), Color("c1fa81"))
	var rail := main.job_panel.rail_global_rect()
	_fill_rect(image, Rect2i(Vector2i(rail.position * 0.5), Vector2i(rail.size * 0.5)), Color("68442b"))
	for employee_id in ["mira", "theo"]:
		var worker := main.get_employee(employee_id)
		if worker == null:
			continue
		var desk_prop := main.room.prop_node("%s-workstation" % employee_id)
		var desk_global := desk_prop.global_position if desk_prop != null else worker.desk_position
		var desk_center := Vector2i(int(desk_global.x * 0.5), int(desk_global.y * 0.5))
		_fill_rect(image, Rect2i(desk_center - Vector2i(15, 9), Vector2i(30, 18)), Color("8c6748"))
		var worker_center := Vector2i(int(worker.position.x * 0.5), int(worker.position.y * 0.5))
		var worker_color := Color("7dc6a7") if employee_id == "mira" else Color("d9a66f")
		if worker.work_state == EmployeeAvatar.WorkState.TYPING:
			worker_color = worker_color.lightened(0.2)
		_fill_rect(image, Rect2i(worker_center + Vector2i(-5, 0), Vector2i(10, 12)), worker_color)
		_fill_circle(image, worker_center + Vector2i(0, -4), 5, Color("e9b98f"))
	var player_center := Vector2i(int(main.player.position.x * 0.5), int(main.player.position.y * 0.5))
	_fill_rect(image, Rect2i(player_center + Vector2i(-5, 0), Vector2i(10, 13)), Color("5a7fd6"))
	_fill_circle(image, player_center + Vector2i(0, -4), 5, Color("f4c9a8"))
	return image

func _fill_rect(image: Image, rectangle: Rect2i, color: Color) -> void:
	var left := maxi(0, rectangle.position.x)
	var top := maxi(0, rectangle.position.y)
	var right := mini(image.get_width(), rectangle.end.x)
	var bottom := mini(image.get_height(), rectangle.end.y)
	for y in range(top, bottom):
		for x in range(left, right):
			image.set_pixel(x, y, color)

func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if Vector2i(x, y).distance_squared_to(center) <= radius * radius and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _compare_baseline(actual_source: Image) -> void:
	if not FileAccess.file_exists(BASELINE_PATH):
		_fail("test_worker_walks_to_desk: baseline is missing")
		return
	var expected := Image.new()
	var baseline_error := expected.load_png_from_buffer(FileAccess.get_file_as_bytes(BASELINE_PATH))
	if baseline_error != OK or expected.is_empty():
		_fail("test_worker_walks_to_desk: baseline could not be loaded")
		return
	var actual := actual_source.duplicate() as Image
	expected.resize(160, 90, Image.INTERPOLATE_NEAREST)
	actual.resize(160, 90, Image.INTERPOLATE_NEAREST)
	var total_difference := 0.0
	for y in range(90):
		for x in range(160):
			var expected_color := expected.get_pixel(x, y)
			var actual_color := actual.get_pixel(x, y)
			total_difference += absf(expected_color.r - actual_color.r)
			total_difference += absf(expected_color.g - actual_color.g)
			total_difference += absf(expected_color.b - actual_color.b)
	var mean_difference := total_difference / float(160 * 90 * 3)
	if mean_difference > 0.015:
		_fail("test_worker_walks_to_desk: screenshot differs from baseline (%.5f)" % mean_difference)
