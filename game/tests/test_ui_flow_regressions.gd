extends SceneTree

var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 6) -> void:
	for frame: int in range(count): await process_frame

func click_control(control: Control) -> void:
	check(control.is_visible_in_tree(), "Input target must be visible: " + control.name)
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await frames()

func check_attachment_state(panel: JobPanel, expected: bool, context: String) -> void:
	check(panel._attachment_picker.visible == expected, context + ": attachment content has expected state")
	check(panel._attachment_label.visible == expected, context + ": attachment heading follows content")
	check(bool(panel._attachment_toggle.get_meta("cozy_disclosure_expanded", false)) == expected, context + ": chevron agrees with content")

func choose_option(option: OptionButton, index: int) -> void:
	await click_control(option)
	var popup := option.get_popup()
	check(popup.visible, "Purpose selector opens through real pointer input")
	for attempt: int in range(option.item_count + 1):
		if popup.get_focused_item() == index: break
		await key(KEY_DOWN)
	check(popup.get_focused_item() == index, "Keyboard navigation reaches the intended purpose")
	await key(KEY_ENTER)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var main: GameMain = load("res://world/main.tscn").instantiate()
	root.add_child(main)
	main.job_panel.open_chat_for_employee("mira")
	await frames(20)
	var panel := main.job_panel
	main.artifact_viewer.show_artifact("format.md", "# **Heading**\n- **Strong** item\n* **Another** item\n```\n**literal**\n```")
	var formatted := main.artifact_viewer._content.get_parsed_text()
	check(formatted.contains("Heading") and formatted.contains("• Strong item") and formatted.contains("• Another item"), "Markdown emphasis must work inside headings and list items")
	check(formatted.contains("**literal**"), "Fenced code must preserve Markdown characters")
	main.artifact_viewer.hide()
	check(panel._tabs.size.x >= 330 and panel._tabs.size.y >= 480 and panel._tab_strip.size.y >= 44, "Chat content and separate real tab strip must fill the authored drawer")
	check(panel._chat_scroll.size.y >= 250, "Empty Chat must retain a useful reading viewport")
	panel.show_chat_history("mira", [{"sender": "player", "content": "What should we build?"}, {"sender": "employee", "content": "**Build a prototype** with one clear offer.\n\n".repeat(18)}])
	await frames(20)
	check(panel._chat_scroll.scroll_vertical >= panel._chat_scroll.get_v_scroll_bar().max_value - panel._chat_scroll.get_v_scroll_bar().page - 10, "Long chat must scroll after text shaping")
	for node: Node in panel._chat_log.find_children("*", "RichTextLabel", true, false):
		check(not (node as RichTextLabel).get_parsed_text().contains("**"), "Chat must render emphasis, not literal Markdown")
	var file := StudioFileRecord.new()
	file.name = "A long company direction brief"
	file.relative_path = "briefs/a-really-long-company-direction-and-validation-brief-for-the-founder.md"
	panel.show_studio_files([file])
	panel._job_picker.select(panel.CANNED_JOBS.size())
	panel._on_job_selected(panel.CANNED_JOBS.size())
	await click_control(panel._tab_buttons[1])
	var collapsed_scroll := panel._tabs.get_tab_control(1).get_child(0) as ScrollContainer
	check(collapsed_scroll.get_global_rect().encloses(panel._attachment_toggle.get_global_rect()), "Empty custom assignment contains the complete collapsed attachment control")
	check(panel._attachment_toggle.get_global_rect().end.y <= collapsed_scroll.get_global_rect().end.y - 8, "Empty custom attachment clears the form/footer seam by8px")
	await click_control(panel._attachment_toggle)
	panel._attachment_picker.select(1)
	await frames(20)
	check(panel._attachment_picker.is_visible_in_tree(), "Optional context disclosure reveals the actual attachment picker")
	check(panel._attachment_picker.get_global_rect().end.x <= panel.drawer_global_rect().end.x, "Long attachment cannot widen Assign")
	# The original audit used a handler probe. Reproduce its actual user path:
	# open the purpose popup, select a preset with the keyboard, then return.
	var assignment_scroll := panel._tabs.get_tab_control(1).get_child(0) as ScrollContainer
	assignment_scroll.ensure_control_visible(panel._purpose_picker)
	await frames()
	await choose_option(panel._purpose_picker, 1)
	check(not panel._custom_mode, "Real popup keyboard selection chooses a preset purpose")
	check_attachment_state(panel, false, "Preset selection")
	await choose_option(panel._purpose_picker, 0)
	check(panel._custom_mode, "Real popup keyboard selection returns to a custom purpose")
	check_attachment_state(panel, false, "Purpose round-trip")
	await click_control(panel._attachment_toggle)
	check_attachment_state(panel, true, "Reopened attachment")
	await click_control(panel._team_buttons["theo"])
	await click_control(panel._tab_buttons[1])
	check_attachment_state(panel, false, "Employee switch")
	await click_control(panel._attachment_toggle)
	await click_control(panel._drawer_close_button)
	await click_control(panel._team_buttons["theo"])
	await click_control(panel._tab_buttons[1])
	check_attachment_state(panel, panel._attachment_picker.visible, "Drawer reopening")
	await click_control(panel._team_buttons["mira"])
	var definition := {"id": "website", "employeeId": "mira", "title": "Build a website", "assignment": "Create the site files.", "criteria": ["Complete site"], "files": ["site/index.html", "site/styles.css"], "state": "available"}
	panel.set_journey_state({"milestones": [definition]})
	panel.prepare_milestone(definition)
	panel.begin_job("accepted", "mira")
	panel.accept_submission("accepted")
	check(panel.milestone_id.is_empty() and panel.revision_of_job_id.is_empty(), "Accepted work cannot leak milestone metadata into the next draft")
	panel.open_journal_for_employee("mira")
	var started := WorkerEventRecord.new()
	started.type = &"job.started"
	panel.on_job_event("accepted", started)
	check(panel._activity_cancel.visible and not panel._activity_cancel.disabled, "Cancellation belongs in Activity")
	var artifact := ArtifactRecord.new()
	artifact.artifact_id = "a"
	artifact.name = "index.html"
	artifact.relative_path = "site/index.html"
	panel._tabs.current_tab = 0
	panel.show_artifacts("accepted", [artifact])
	check(panel._tabs.current_tab == 0, "File arrival must not hijack the active tab")
	var studio_row := panel._artifact_list.get_child(0) as PanelContainer
	var studio_open := studio_row.find_child("Preview", true, false) as Button
	check(panel.studio_file_count() == 1 and studio_open != null and studio_open.tooltip_text.contains(file.relative_path), "Deliveries must not replace approved Studio files")
	var done := WorkerEventRecord.new()
	done.type = &"job.completed"
	done.summary = "A complete prototype."
	panel.on_job_event("accepted", done)
	panel.offer_promotion("accepted", "mira")
	panel._tabs.current_tab = 2
	panel.open_drawer()
	panel.set_spend(17.252, 5.0)
	panel._usage_label.text = "Usage details · 24000 tokens · $17.2520"
	await frames(20)
	check(panel._drawer_close_button.get_global_rect().end.x <= panel.drawer_global_rect().end.x, "Usage and delivery cards cannot push the drawer close control behind the rail")
	for child: Node in panel._drawer_panel.get_children():
		if child is MarginContainer: check((child as Control).size.x <= panel.DRAWER_WIDTH + 1, "Delivery actions must fit the authored drawer without widening its contents")
	panel.begin_job("blocked", "mira")
	var stopped := WorkerEventRecord.new()
	stopped.type = &"job.blocked"
	stopped.reason = "Files retained after budget cap."
	panel.on_job_event("blocked", stopped)
	check(panel._employee_ui_state("mira") == "needs retry", "Old delivery cannot mask a new failure")
	check(not panel._promotion_box.visible, "Old delivery promotion cannot appear on a different current job")
	panel.select_employee("theo")
	check(not panel._status_label.text.contains("budget cap"), "Mina's failure cannot become Theo's Activity")
	panel.select_employee("mira")
	panel._on_job_selected(panel.CANNED_JOBS.size())
	panel._custom_title_input.text = "Keep this draft"
	panel._assignment_preview.text = "Write an ordinary memo."
	panel.begin_job("rejected", "mira")
	panel.reject_submission("rejected", "Simulated recoverable rejection")
	check(panel.drawer_is_open() and panel._tabs.current_tab == 1 and panel._assignment_error.visible, "Rejected work must remain in the editable form with an error")
	check(panel._custom_title_input.text == "Keep this draft", "Rejection must preserve user draft")
	main.artifact_viewer.show_artifact("styles.css", "* { box-sizing: border-box; }\n[x] { color: red; }")
	check(main.artifact_viewer._content.get_parsed_text().begins_with("* {"), "CSS universal selector is source, not a Markdown bullet")
	check(main.artifact_viewer._content.get_parsed_text().contains("[x]"), "Source brackets must be preserved exactly")
	check(main.artifact_viewer.z_index > panel.z_index + 1 and main.company_panel.z_index > panel.z_index + 1, "Modal layers must cover drawer ornamentation")
	main.company_panel.update_state({"company": {}, "milestones": [{"id": "website", "title": "Build a website", "state": "revision_required", "jobId": "accepted", "evaluation": {"verdict": "revise", "summary": "Long review. ".repeat(100), "criteria": [{"name": "Completeness", "score": 1, "evidence": "Specific review evidence. ".repeat(80)}]}}]})
	main.company_panel.present("journey")
	await frames(20)
	var review_scroll := main.company_panel._scroll
	check(main.company_panel._content.size.x <= review_scroll.size.x - review_scroll.get_v_scroll_bar().size.x + 1, "Journey prose must wrap before its scrollbar, never beneath it")
	await frames()
	root.remove_child(main)
	main.free()
	if failures.is_empty(): print("UI flow regressions: passed")
	quit(failures.size())
