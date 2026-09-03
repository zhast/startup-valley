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
	if main.job_panel.selected_employee_id() != "mira":
		_fail("test_native_team_ui: the first employee was not selected")
	if main.job_panel.drawer_is_open():
		_fail("test_native_team_ui: the employee drawer was open during exploration")
	var rail_style := main.job_panel._rail_panel.get_theme_stylebox("panel") as StyleBoxTexture
	if rail_style == null or rail_style.texture != NotebookSkin.TEAM_RAIL_NONE:
		_fail("test_character_art: the collapsed team rail did not use the approved notebook artwork")
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
	if main.founder_hud.get_node_or_null("TitlePlaque") == null or main.founder_hud.get_node_or_null("MovementPlaque") == null:
		_fail("test_founders_ledger_ui: the title or movement plaque was missing")
	main.clock_panel.show_money_earned(125.5)
	if main.clock_panel._earned_label.text != "$125.50  EARNED":
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
	var dropdown_style := main.job_panel._job_picker.get_theme_stylebox("normal") as StyleBoxTexture
	var dropdown_popup_style := main.job_panel._job_picker.get_popup().get_theme_stylebox("hover") as StyleBoxTexture
	if dropdown_style == null or dropdown_style.texture != OperationsSkin.DROPDOWN_FIELD or dropdown_popup_style == null or dropdown_popup_style.texture != OperationsSkin.DROPDOWN_SELECTED_ROW:
		_fail("test_operations_ui: work-order dropdown or popup selection retained a generic style")
	var secondary_style := main.job_panel._cancel_button.get_theme_stylebox("normal") as StyleBoxTexture
	var primary_hover_style := main.job_panel._make_job_button.get_theme_stylebox("hover") as StyleBoxTexture
	var team_focus_style := (main.job_panel._team_buttons["mira"] as Button).get_theme_stylebox("focus") as StyleBoxTexture
	var attention_texture := (main.job_panel._team_buttons["mira"] as Button).get_node_or_null("AttentionBadge") as TextureRect
	if secondary_style == null or secondary_style.texture != OperationsSkin.BUTTON_SECONDARY_NORMAL or primary_hover_style == null or primary_hover_style.texture != OperationsSkin.BUTTON_PRIMARY_HOVER:
		_fail("test_operations_ui: primary or secondary interaction states retained generic styling")
	if team_focus_style == null or team_focus_style.texture != OperationsSkin.FOCUS_RING or attention_texture == null or attention_texture.texture != OperationsSkin.ATTENTION_BADGE:
		_fail("test_operations_ui: team rail focus or attention state did not use custom art")
	main.job_panel._tabs.current_tab = 0
	main.job_panel.select_employee("theo")
	if main.job_panel.selected_employee_id() != "theo":
		_fail("test_native_team_ui: the vertical team rail did not select Theo")
	rail_style = main.job_panel._rail_panel.get_theme_stylebox("panel") as StyleBoxTexture
	if rail_style == null or rail_style.texture != NotebookSkin.TEAM_RAIL_THEO:
		_fail("test_native_team_ui: the team rail did not move its selection treatment to Theo")
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
	var founder_bubble_style := founder_bubble.get_theme_stylebox("panel") as StyleBoxTexture if founder_bubble != null else null
	var employee_bubble_style := employee_bubble.get_theme_stylebox("panel") as StyleBoxTexture if employee_bubble != null else null
	if founder_bubble_style == null or founder_bubble_style.texture != OperationsSkin.CHAT_FOUNDER_BUBBLE:
		_fail("test_operations_ui: founder chat did not use its directional custom bubble")
	if employee_bubble_style == null or employee_bubble_style.texture != OperationsSkin.CHAT_EMPLOYEE_BUBBLE:
		_fail("test_operations_ui: employee chat did not use its directional custom bubble")
	if main.job_panel._make_job_button.disabled:
		_fail("test_native_team_ui: a persisted founder message did not enable Assign Work")
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
	if main.room.visible_prop_count() != 6:
		_fail("test_modular_office: the two-person stage did not show the founder, collaboration, and research props")
	main.room.set_hire_count(0)
	if main.room.find_child("LockedSections", true, false) != null:
		_fail("test_office_growth: an empty office stage still created blocked expansion areas")
	if main.room.visible_prop_count() != 1 or main.room.prop_node("founder-workstation") == null:
		_fail("test_modular_office: the empty founder stage did not retain exactly one usable workstation")
	main.room.set_hire_count(1)
	if main.room.visible_prop_count() != 4 or main.room.prop_node("mira-workstation") == null:
		_fail("test_modular_office: the first hire did not reveal Mina's workstation and social wing")
	if main.room.prop_node("collaboration-cluster") == null or main.room.prop_node("coffee-station") == null:
		_fail("test_modular_office: the first-hire meeting and coffee props were missing")
	var staged_desk := main.room.prop_node("mira-workstation")
	var staged_desk_rear := staged_desk.get_node_or_null("WorkstationRear") as Sprite2D if staged_desk != null else null
	var staged_desk_front := staged_desk.get_node_or_null("WorkstationFront") as Sprite2D if staged_desk != null else null
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
	if main.job_panel.studio_file_count() != 1 or not main.job_panel.last_status_text().contains("completed"):
		_fail("test_persistent_boot: studio listing or last status was not restored")
	var studio_file_button := main.job_panel._artifact_list.get_child(0) as Button
	var studio_file_style := studio_file_button.get_theme_stylebox("normal") as StyleBoxTexture if studio_file_button != null else null
	if studio_file_button == null or studio_file_button.icon != OperationsSkin.ACTIVITY_ARTIFACT or studio_file_style == null or studio_file_style.texture != OperationsSkin.FILE_CARD:
		_fail("test_operations_ui: Studio file did not use the custom document card and icon")
	if main.job_panel.pending_promotion_job_id() != "pending-review":
		_fail("test_persistent_boot: pending promotion was not restored")
	if not main.founder_hud.delivery_visible():
		_fail("test_persistent_boot: pending promotion did not restore the completion memo")
	if main.get_employee("mira").memory_line != "Outcome: restored durable note":
		_fail("test_persistent_boot: employee memory was not restored")
	main.artifact_viewer.show_artifact("design-note.md", "# Design note\n\nReadable delivery text.")
	await process_frame
	if not main.artifact_viewer.modal_fits_viewport() or not main.artifact_viewer.scrim_covers_viewport():
		_fail("test_artifact_viewer: the modal or its scrim escaped the viewport")
	var reader_frame_found := false
	for child: Node in main.artifact_viewer._modal.get_children():
		if child is TextureRect and (child as TextureRect).texture == OperationsSkin.ARTIFACT_READER_FRAME:
			reader_frame_found = true
	var reader_paper_style := main.artifact_viewer._content.get_theme_stylebox("read_only") as StyleBoxTexture
	if not reader_frame_found or reader_paper_style == null or reader_paper_style.texture != OperationsSkin.ARTIFACT_PAPER:
		_fail("test_operations_ui: artifact reader did not use its custom frame and paper")
	main.artifact_viewer.hide()
	main.day_clock.set_time(4, DayClock.WORK_START)
	await process_frame
	var scheduled_employee := main.get_employee("mira")
	scheduled_employee._idle_elapsed = 0.4
	scheduled_employee.set_schedule_phase("work")
	if scheduled_employee._idle_elapsed < 0.4:
		_fail("test_day_clock: repeated work ticks reset the employee idle schedule")

	main.job_panel.begin_job("steer-job")
	var journal_style := main.job_panel._event_log.get_theme_stylebox("normal") as StyleBoxTexture
	var journal_scroll_style := main.job_panel._event_log.get_v_scroll_bar().get_theme_stylebox("grabber") as StyleBoxTexture
	var approval_style := main.job_panel._approval_box.get_theme_stylebox("panel") as StyleBoxTexture
	var delivery_style := main.job_panel._promotion_box.get_theme_stylebox("panel") as StyleBoxTexture
	var meter_style := main.job_panel._token_meter.get_theme_stylebox("background") as StyleBoxTexture
	if journal_style == null or journal_style.texture != OperationsSkin.ACTIVITY_ROW or journal_scroll_style == null or journal_scroll_style.texture != OperationsSkin.SCROLL_V_THUMB:
		_fail("test_operations_ui: Journal activity or scrollbar retained a generic style")
	if approval_style == null or approval_style.texture != OperationsSkin.JOURNAL_APPROVAL_CARD or delivery_style == null or delivery_style.texture != OperationsSkin.JOURNAL_DELIVERY_CARD:
		_fail("test_operations_ui: approval or delivery state did not use its custom card")
	if meter_style == null or meter_style.texture != OperationsSkin.TOKEN_METER_FRAME:
		_fail("test_operations_ui: token budget meter did not use its custom frame")
	main.job_panel.set_spend(2.5, 5.0)
	if not is_equal_approx(main.job_panel._token_meter.value, 2.5) or not is_equal_approx(main.job_panel._token_meter.max_value, 5.0):
		_fail("test_operations_ui: daily spend did not drive the real token-budget meter")
	if OperationsSkin.ACTIVITY_THINKING == null or OperationsSkin.ACTIVITY_RESEARCH == null or OperationsSkin.ACTIVITY_WRITING == null or OperationsSkin.ACTIVITY_TOOL == null or OperationsSkin.ACTIVITY_APPROVAL == null or OperationsSkin.ACTIVITY_ARTIFACT == null or OperationsSkin.ACTIVITY_COMPLETE == null or OperationsSkin.ACTIVITY_FAILED == null:
		_fail("test_operations_ui: one or more real-event activity icons failed to load")
	if OperationsSkin.WORLD_SPEECH_BUBBLE == null or OperationsSkin.WORLD_NAMEPLATE == null or OperationsSkin.WORLD_STATUS_PLAQUE == null or OperationsSkin.WORLD_ATTENTION == null:
		_fail("test_operations_ui: one or more in-world label assets failed to load")
	if not main.job_panel.status_color().is_equal_approx(main.job_panel.CERULEAN):
		_fail("test_ui_status: submitting work retained a stale error color")
	if main.job_panel._event_log.get_parsed_text() != "" or not main.job_panel._usage_label.text.contains("0 in / 0 out"):
		_fail("test_ui_status: a new work order retained stale activity or usage")
	main._job_employees["steer-job"] = "mira"
	var steer_started := WorkerEventRecord.new()
	steer_started.type = &"job.started"
	main._on_job_event("steer-job", steer_started)
	await process_frame
	if not main.job_panel.steer_controls_visible():
		_fail("test_active_job_steer: controls did not appear for an in-flight job")
	main.job_panel.steer_submitted.connect(_capture_steer)
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
		if mina_desk == null or employee.z_index >= mina_desk.z_index:
			_fail("test_modular_office: Mina was not depth-sorted behind her workstation")
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
	main.job_panel.on_job_event("layout-check", long_delivery)
	main.job_panel.offer_promotion("layout-check")
	main.job_panel.select_employee("mira")
	await process_frame
	if not main.job_panel.promotion_controls_fit_viewport():
		_fail("test_delivery_layout: long summaries pushed promotion controls below the viewport")

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

func _software_state_screenshot(main: GameMain) -> Image:
	# `godot --headless` deliberately uses the dummy renderer, so viewport textures
	# do not exist. This small software renderer snapshots the same logical positions
	# and worker visual states deterministically on macOS and Windows CI.
	var image := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	image.fill(Color("09111f"))
	var room_origin := Vector2i(16, 35)
	var tile := 16
	for y in range(main.room.grid_height):
		for x in range(main.room.grid_width):
			var floor_color := Color("34445f") if (x + y) % 2 == 0 else Color("314059")
			_fill_rect(image, Rect2i(room_origin + Vector2i(x * tile, y * tile), Vector2i(tile, tile)), floor_color)
	_fill_rect(image, Rect2i(447, 9, 184, 342), Color("11192a"))
	_fill_rect(image, Rect2i(457, 24, 112, 7), Color("dce8ff"))
	_fill_rect(image, Rect2i(457, 40, 76, 3), Color("8fa3c2"))
	for row in [64, 91, 144, 174, 238, 282]:
		_fill_rect(image, Rect2i(457, int(row), 154, 4), Color("34445e"))
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
