extends SceneTree

const OUTPUT := "res://tests/output/ui-redesign/drawer"
const SPEND_PAPER_INSET := Vector2i(18, 10)
var _failures: Array[String] = []
var _spend_ink_samples: Array[Dictionary] = []
var _checks := 0
var _previewed := ""
var _promoted := ""
var _requested_journey := false
var _requested_retry := false
var _key_submissions := 0
var _main: GameMain

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
		push_error(message)

func _frames(count: int = 12) -> void:
	for frame: int in range(count): await process_frame

func _click(control: Control) -> void:
	_check(control.is_visible_in_tree(), "Clicked control must be visible: " + control.name)
	var point := control.get_global_rect().get_center()
	_check(root.get_visible_rect().has_point(point), "Clicked control must be inside viewport: " + control.name)
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
	await _frames()

func _key(code: Key, backwards: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.shift_pressed = backwards
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await _frames(2)

func _type_text(value: String) -> void:
	for character: String in value:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.pressed = true
		root.push_input(event, true)
		await process_frame
	await _frames(2)

func _verify_connection_loop(panel: JobPanel, count: int) -> void:
	var allowed := panel._connection_focus_controls()
	_check(allowed.size() == count, "Connection focus contains only visible enabled controls")
	for backwards: bool in [false, true]:
		var visited: Array[Control] = []
		for step: int in range(count * 3):
			await _key(KEY_TAB, backwards)
			var focus := root.gui_get_focus_owner()
			_check(allowed.has(focus) and focus.is_visible_in_tree(), "Tab/ShiftTab stays in visible connection controls")
			if not visited.has(focus): visited.append(focus)
		_check(visited.size() == count, "Every connection action is reachable in both traversal directions")

func _capture(name_value: String) -> void:
	_assert_text_roles(_main.job_panel)
	_assert_header_and_rail_fit(_main.job_panel)
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	var result := root.get_texture().get_image().save_png(OUTPUT + "/" + name_value + ".png")
	_check(result == OK, "Saved " + name_value)

func _assert_text_roles(panel: JobPanel) -> void:
	for node: Node in panel.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree(): continue
		if control is Label:
			var label := control as Label
			if label.text.is_empty(): continue
			var font := control.get_theme_font("font")
			var role := str(control.get_meta("cozy_text_role", "body"))
			var source := str(control.get_meta("original_heading", label.text))
			var expected_font: Font = GameFonts.display_font_for(source) if role == "display" else GameFonts.EMPHASIS if role == "meta" else GameFonts.BOLD if role in ["action", "title", "section", "numeric", "identity"] else GameFonts.BODY
			var minimum := 22 if role == "display" else 14 if role == "meta" else 20 if role in ["title", "section", "numeric"] else 16
			_check(font == expected_font, "Visible label binds the exact C semantic font role: " + control.name)
			_check(control.get_theme_font_size("font_size") >= minimum, "Visible label meets its role's declared minimum: " + control.name)
			if font == GameFonts.DISPLAY:
				_check(control in [panel._employee_name, panel._connection_title] or control.name == "TeamHeading", "Slab is reserved for controlled drawer/connection/team headings")
				_check(control.get_theme_font_size("font_size") == 22, "Slab heading stays on its native 22px scale")
			_check(GameFonts.has_glyphs(font, label.text), "Every displayed label has bundled glyph coverage: " + label.text)
			_check(label.get_minimum_size().y <= label.size.y + 1.0, "Wrapped label has its full laid-out height: " + label.name)
		elif control is RichTextLabel:
			for role: String in ["normal", "bold", "italics", "bold_italics", "mono"]:
				_check(control.get_theme_font_size(role + "_font_size") >= 16, "Rich text role meets 16px minimum: " + role)
			_check(control.get_theme_font("normal_font") == GameFonts.BODY and control.get_theme_font("bold_font") == GameFonts.BOLD and control.get_theme_font("mono_font") == GameFonts.MONO, "Dynamic rich text keeps distinct body/bold/mono faces")
			_check(control.get_theme_font("italics_font") == GameFonts.ITALIC and control.get_theme_font("bold_italics_font") == GameFonts.BOLD_ITALIC, "Dynamic rich text binds actual Nunito italic variants")
		elif control is Button:
			if (control as Button).text.is_empty(): continue
			_check(control.get_theme_font_size("font_size") >= 16 and control.get_theme_font("font") == GameFonts.BOLD, "Functional button uses Nunito Bold at 16px or larger: " + (control as Button).text)
		elif control is LineEdit or control is TextEdit:
			_check(control.get_theme_font_size("font_size") >= 16 and control.get_theme_font("font") == GameFonts.BODY, "Input uses Nunito body at 16px or larger")

func _assert_single_line_fit(control: Control, value: String, inset: float = 0.0) -> void:
	var font := control.get_theme_font("font")
	var size := control.get_theme_font_size("font_size")
	var measured := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	_check(measured.x <= control.size.x - inset + 0.5, "Text fits its real font metrics and horizontal padding: " + value)
	_check(font.get_height(size) <= control.size.y + 0.5, "Text has full vertical font metrics: " + value)

func _assert_header_and_rail_fit(panel: JobPanel) -> void:
	var heading := panel._rail_panel.find_child("TeamHeading", true, false) as Label
	_check(heading.get_theme_font("font") == GameFonts.DISPLAY and heading.get_theme_font_size("font_size") == 22, "TEAM heading consistently uses controlled Slab at 22px")
	_assert_single_line_fit(heading, heading.text)
	for employee_id: String in panel._team_buttons:
		var rail_name := panel._team_buttons[employee_id].find_child("EmployeeName", true, false) as Label
		_check(rail_name.get_theme_font("font") == GameFonts.BOLD and rail_name.get_theme_font_size("font_size") == 16, "Employee rail identity consistently uses Nunito Bold at 16px")
		if rail_name.text in ["MINA", "THEO"]: _assert_single_line_fit(rail_name, rail_name.text)
	if panel._header_shell.is_visible_in_tree():
		_check(panel._employee_name.get_global_rect().end.x <= panel._drawer_close_button.get_global_rect().position.x, "Employee identity stays completely outside close hit target")
		_check(panel._employee_name.get_global_rect().end.y <= panel._employee_meta.get_global_rect().position.y, "Identity and role text never overlap")
		_check(panel._employee_meta.get_global_rect().end.y <= panel._employee_status.get_global_rect().position.y, "Wrapped role and status never overlap")
		_check(panel._employee_status.get_global_rect().end.y <= panel._header_shell.get_global_rect().end.y - 8.0, "All header text stays inside bottom paper inset")
		for button: Button in panel._tab_buttons:
			var style := button.get_theme_stylebox("normal")
			_assert_single_line_fit(button, button.text, style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT))
	if panel._connection_panel.is_visible_in_tree():
		_assert_single_line_fit(panel._connection_title, panel._connection_title.text)
		_check(panel._connection_title.get_global_rect().end.y <= panel._connection_description.get_global_rect().position.y, "Connection heading leaves its description unobstructed")
	if panel._chat_composer.is_visible_in_tree():
		_check(panel._chat_helper.get_theme_font_size("font_size") >= 16, "Chat's no-tools consequence is body copy, not small metadata")
		_check(panel._chat_helper.get_global_rect().end.y <= panel._chat_composer.get_global_rect().end.y - 8.0, "Wrapped chat consequence stays within composer paper")
		_check(panel._chat_input.size.x >= 160, "Ask button leaves a usable text-input width")
		if panel._chat_send_button.text in ["Ask Mina", "Ask Theo", "Connect", ".", "..", "..."]:
			var style := panel._chat_send_button.get_theme_stylebox("normal")
			_assert_single_line_fit(panel._chat_send_button, panel._chat_send_button.text, style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT))
	if panel._activity_footer.is_visible_in_tree():
		var footer := panel._activity_footer.get_global_rect()
		var safe := Rect2(footer.position + Vector2(SPEND_PAPER_INSET), footer.size - Vector2(SPEND_PAPER_INSET * 2))
		_check(panel._activity_scroll.get_global_rect().end.y <= footer.position.y, "Activity history cannot cover the pinned spend footer")
		_check(safe.encloses(panel._spend_label.get_global_rect()), "Daily AI spend clears the paper's rivets and bottom bevel")
		_check(footer.end.y <= panel.drawer_global_rect().end.y - 12, "Pinned spend remains above the drawer's 12px bottom frame")
		_check(panel._spend_label.get_global_rect().end.x <= panel._usage_toggle.get_global_rect().position.x - 8, "Spend and disclosure have distinct padded hit/text regions")

func _spend_ink(image: Image, blank: Image, safe: Rect2i) -> Dictionary:
	var outside := 0
	var counts: Array[int] = [0, 0]
	var bounds := Rect2i()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var source := blank.get_pixel(x, y)
			var actual := image.get_pixel(x, y)
			if source.r + source.g + source.b - actual.r - actual.g - actual.b < 0.2: continue
			var point := Vector2i(x, y)
			if not safe.has_point(point): outside += 1
			else: counts[0 if y < safe.get_center().y else 1] += 1
			var pixel := Rect2i(point, Vector2i.ONE)
			bounds = pixel if not bounds.has_area() else bounds.merge(pixel)
	return {"outside_paper_pixels": outside, "line_ink_pixels": counts, "ink_bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "passed": outside == 0 and counts[0] > 0 and counts[1] > 0}

func _verify_spend_detector() -> void:
	var blank := Image.create(100, 80, false, Image.FORMAT_RGBA8)
	blank.fill(Color.WHITE)
	var probe := blank.duplicate() as Image
	var safe := Rect2i(SPEND_PAPER_INSET, blank.get_size() - SPEND_PAPER_INSET * 2)
	probe.set_pixelv(safe.position + Vector2i(2, 2), Color.BLACK)
	probe.set_pixelv(safe.end - Vector2i(2, 2), Color.BLACK)
	_check(bool(_spend_ink(probe, blank, safe).passed), "Spend raster detector accepts ink within both paper lines")
	probe.set_pixel(4, 4, Color.BLACK)
	_check(int(_spend_ink(probe, blank, safe).outside_paper_pixels) == 1, "Spend raster detector rejects ink in the rivet corner")

func _verify_rendered_spend(panel: JobPanel, name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var rect := Rect2i(panel._activity_footer.get_global_rect())
	RenderingServer.force_draw(false)
	var actual := root.get_texture().get_image().get_region(rect)
	var original := panel._spend_label.self_modulate
	panel._spend_label.self_modulate.a = 0
	await _frames(2)
	RenderingServer.force_draw(false)
	var blank := root.get_texture().get_image().get_region(rect)
	panel._spend_label.self_modulate = original
	await _frames(2)
	var safe := Rect2i(SPEND_PAPER_INSET, rect.size - SPEND_PAPER_INSET * 2)
	# Optional raw usage is separate metadata below the two-line cost; only the
	# spend label was hidden, so unchanged metadata and button art cancel out.
	var sample := _spend_ink(actual, blank, safe)
	sample["state"] = name_value
	_spend_ink_samples.append(sample)
	_check(bool(sample.passed), "Rendered spend ink clears actual paper rivets/bevel: %s (%s)" % [name_value, sample])
	_check(actual.save_png(OUTPUT.path_join("spend-footer-" + name_value + ".png")) == OK, "Saved native footer ink evidence")

func _assert_disclosure(button: Button, expanded: bool) -> void:
	_check(button.icon != null and button.get_meta("cozy_disclosure_expanded") == expanded, "Disclosure has an authored icon and explicit expansion state: " + button.text)
	_check(button.tooltip_text == ("Collapse details" if expanded else "Expand details"), "Disclosure communicates its next action: " + button.text)
	_check(button.get_theme_font("font") == GameFonts.BOLD and button.get_theme_font_size("font_size") == 16, "Disclosure refresh preserves its Nunito action role")
	_check(button.pressed.get_connections().size() == 1, "Disclosure restyling never duplicates its action signal")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	_verify_spend_detector()
	_check(GameFonts.DISPLAY.get_font_name().to_lower().contains("slab"), "Display resolves to the bundled Slab family")
	for font: Font in [GameFonts.BODY, GameFonts.EMPHASIS, GameFonts.BOLD, GameFonts.ITALIC, GameFonts.BOLD_ITALIC]:
		_check(font.get_font_name().to_lower().contains("nunito"), "Every functional and italic role resolves to the bundled Nunito family")
		_check(not font.get_rids().is_empty(), "Functional font role has an actual rendering resource")
	_check(GameFonts.BODY.get_rids() != GameFonts.BOLD.get_rids(), "Body and action roles resolve distinct font instances")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(_main)
	await _frames()
	_main.day_clock.set_speed(0)
	_main.founder_hud.dismiss_movement_hint()
	var panel := _main.job_panel
	# No provider or save operation is reachable from these input fixtures.
	for name_value: String in ["key_submitted", "settings_requested", "journey_requested", "worker_retry_requested", "chat_history_requested", "chat_submitted", "assignment_submitted", "cancel_requested", "steer_submitted", "approval_decided", "artifact_open_requested", "artifact_refresh_requested", "studio_open_requested", "promotion_decided"]:
		for connection: Dictionary in panel.get_signal_connection_list(name_value):
			panel.disconnect(name_value, connection.callable)
	panel.artifact_open_requested.connect(func(_job: String, path: String) -> void: _previewed = path)
	panel.promotion_decided.connect(func(job: String, _approved: bool) -> void: _promoted = job)
	panel.journey_requested.connect(func() -> void: _requested_journey = true)
	panel.worker_retry_requested.connect(func() -> void: _requested_retry = true)
	panel.key_submitted.connect(func(_key_value: String) -> void: _key_submissions += 1)
	panel.configure_employees(_main.room.placeholder_records())
	panel.set_credential_status(true)
	panel.set_worker_ready()
	panel.select_employee("mira")
	panel.show_chat_history("mira", [{"sender": "player", "content": "Can we make a useful website?"}, {"sender": "employee", "content": "Start with one **clear offer**, one audience, and one action. We can turn that into a small work order."}])
	await _frames(20)
	_check(panel._header_shell.size.y == 112, "Header retains compact height")
	_check(panel._employee_name.get_theme_font("font") == GameFonts.DISPLAY and panel._employee_name.get_theme_font_size("font_size") == 22, "Employee heading uses controlled Slab at 22px")
	for button: Button in panel._tab_buttons:
		_check(is_equal_approx(button.size.x, 86), "Four equal 86px tabs")
		_check(button.size.y >= 44, "Tab has 44px target")
		_check(button.get_theme_font("font") == GameFonts.BOLD, "Tab uses explicit bold face")
	_check(panel._make_job_button.get_parent() == panel._latest_reply_content, "Conversion belongs to latest employee reply")
	_check(panel._make_job_button.get_meta("cozy_variant") == "quiet", "Conversion does not compete with Ask")
	_check(panel._make_job_button.get_theme_stylebox("normal") is StyleBoxFlat and (panel._make_job_button.get_theme_stylebox("normal") as StyleBoxFlat).border_width_left > 0, "Contextual work conversion has a visible resting boundary")
	for label: Node in panel._chat_log.find_children("*", "RichTextLabel", true, false):
		_check(label.get_theme_font("normal_font") == GameFonts.BODY, "Chat has explicit BODY")
		_check(label.get_theme_font("bold_font") == GameFonts.BOLD, "Chat has explicit BOLD")
	_capture("chat")
	await _click(panel._make_job_button)
	_check(panel._tabs.current_tab == 1, "Real contextual click opens editable Assign")
	_check(panel._custom_title_input.editable and panel._assignment_preview.editable, "Converted work remains editable")
	_check(panel._budget_picker.get_global_rect().end.y < panel._assign_button.get_global_rect().position.y, "Token cap visible before Start")
	_check(panel._assign_button.get_global_rect().end.y <= 720, "Start is visible without scrolling")
	_capture("assign")
	_assert_disclosure(panel._attachment_toggle, false)
	await _click(panel._attachment_toggle)
	_check(panel._attachment_picker.is_visible_in_tree(), "Real attachment disclosure click reveals optional context")
	_assert_disclosure(panel._attachment_toggle, true)
	await _click(panel._attachment_toggle)
	_check(not panel._attachment_picker.visible, "Second disclosure click collapses optional context")
	_assert_disclosure(panel._attachment_toggle, false)
	panel.begin_job("drawer-proof", "mira")
	panel.accept_submission("drawer-proof")
	var event := WorkerEventRecord.new()
	event.type = &"job.queued"
	panel.on_job_event("drawer-proof", event)
	_check(panel._employee_status.text == "Queued", "Queued employee status uses readable sentence case")
	_check(not panel._event_log.text.contains("Queued[/color] ·"), "Empty queue reason never leaves a dangling separator")
	event.type = &"job.started"
	panel.on_job_event("drawer-proof", event)
	panel.open_drawer(false)
	await _click(panel._tab_buttons[0])
	_check(panel._chat_active_banner.visible and not panel._chat_composer.visible, "Active Chat is deliberate read-only banner")
	_capture("active-chat")
	await _click(panel._chat_activity_button)
	_check(panel._tabs.current_tab == 2, "Read-only banner opens Activity")
	_check(panel._steer_box.is_visible_in_tree() and not panel._activity_details.visible, "Active steering is immediately available while detailed history is collapsible")
	_check(panel._last_status_label.text.ends_with(" · Running"), "Current-work state suffix is human-readable sentence case")
	_check(panel._status_card.get_global_rect().end.y < panel._steer_box.get_global_rect().position.y, "Current work precedes steering")
	_check(panel._steer_box.get_global_rect().position.y < panel._activity_cancel.get_global_rect().position.y, "Cancellation has lower hierarchy")
	_check(not panel._token_meter.visible, "Daily spend cannot resemble task progress")
	panel.set_spend(2.5, 5.0)
	await _frames()
	var spend_bottom := panel._activity_footer.get_global_rect().end.y
	_assert_disclosure(panel._activity_details_toggle, false)
	_capture("activity")
	await _verify_rendered_spend(panel, "running")
	await _click(panel._activity_details_toggle)
	_check(panel._event_log.is_visible_in_tree(), "Real details click opens the current work timeline")
	_assert_disclosure(panel._activity_details_toggle, true)
	for index: int in range(8):
		var thinking := WorkerEventRecord.new()
		thinking.type = &"agent.thinking"
		thinking.summary = "Reviewing the audience and offer, iteration %d." % index
		panel.on_job_event("drawer-proof", thinking)
	await _frames()
	panel._activity_scroll.scroll_vertical = 10000
	await _frames()
	_check(is_equal_approx(panel._activity_footer.get_global_rect().end.y, spend_bottom), "Long dynamic activity cannot move pinned spend out of view")
	_capture("activity-long-details")
	await _verify_rendered_spend(panel, "scrolled-history")
	panel._activity_scroll.ensure_control_visible(panel._activity_details_toggle)
	await _frames()
	await _click(panel._activity_details_toggle)
	_assert_disclosure(panel._activity_details_toggle, false)
	panel._activity_scroll.scroll_vertical = 0
	await _frames()
	await _click(panel._usage_toggle)
	_check(panel._usage_label.is_visible_in_tree(), "Real usage disclosure reveals raw work-order usage")
	_assert_disclosure(panel._usage_toggle, true)
	_check(is_equal_approx(panel._activity_footer.get_global_rect().end.y, spend_bottom), "Expanded usage grows inward rather than below notebook")
	await _click(panel._usage_toggle)
	_assert_disclosure(panel._usage_toggle, false)
	event = WorkerEventRecord.new()
	event.type = &"approval.required"
	event.approval_id = "drawer-approval"
	event.action = "Publish the launch brief to the shared Studio for Theo to review."
	panel.on_job_event("drawer-proof", event)
	await _frames()
	_check(panel._approval_box.is_visible_in_tree() and not panel._status_card.visible, "Approval gets one clear decision card, not a repeated status banner")
	_check(panel._approval_box.get_global_rect().end.y <= panel._activity_scroll.get_global_rect().end.y, "Default approval and its actions fit above pinned spend")
	for action: Control in [panel._steer_box, panel._activity_cancel, panel._activity_details_toggle]:
		_check(action.get_global_rect().end.y <= panel._activity_scroll.get_global_rect().end.y - 6, "Approval keeps steering, cancellation and complete details frame above its scroll edge: %s %s scroll %s" % [action.name, action.get_global_rect(), panel._activity_scroll.get_global_rect()])
	_check(panel._employee_status.text == "Needs approval", "Approval status keeps sentence case")
	_capture("approval")
	await _verify_rendered_spend(panel, "approval")
	var approve := panel._approval_box.find_children("*", "Button", true, false)[0] as Button
	await _click(approve)
	_check(not panel._approval_box.visible and panel._status_card.visible, "Decision click restores current-work summary")
	var artifact := ArtifactRecord.new()
	artifact.artifact_id = "website-index"
	artifact.name = "index.html"
	artifact.relative_path = "site/index.html"
	artifact.job_id = "drawer-proof"
	panel.show_artifacts("drawer-proof", [artifact])
	event = WorkerEventRecord.new()
	event.type = &"job.completed"
	event.summary = "A focused landing page with a clear offer and one useful call to action."
	panel.on_job_event("drawer-proof", event)
	panel.offer_promotion("drawer-proof", "mira")
	await _frames(20)
	var preview := panel._delivery_list.find_child("Preview", true, false) as Button
	_check(preview != null, "Delivery contains Preview")
	_check(preview.get_global_rect().end.y < panel._promotion_box.get_global_rect().position.y, "Preview precedes promotion decision")
	_check(panel._promotion_box.get_global_rect().end.y <= panel._activity_scroll.get_global_rect().end.y, "One-file delivery decision fits above pinned spend")
	_capture("delivery-preview-first")
	await _verify_rendered_spend(panel, "delivery")
	await _click(preview)
	_check(_previewed == "site/index.html" and _promoted.is_empty(), "Preview is read-only, not implicit promotion")
	await _click(panel._promotion_actions[0])
	_check(_promoted == "drawer-proof", "Explicit promotion follows preview")
	var file := StudioFileRecord.new()
	file.name = "Company direction and validation plan"
	file.relative_path = "briefs/company-direction-and-validation-plan-for-founders.md"
	file.source_job_id = "drawer-proof"
	panel.show_studio_files([file])
	await _click(panel._tab_buttons[3])
	await _frames()
	_check(panel._artifact_list.get_global_rect().end.x <= panel.drawer_global_rect().end.x, "Long Studio file fits drawer")
	_capture("studio")
	panel._tab_buttons[3].grab_focus()
	panel._open_connection_settings()
	await _frames()
	_check(panel._connection_title.text == "AI connection" and panel._connection_description.text.contains("already saved"), "Configured connection explains existing saved key")
	_check(panel._connection_save_button.text == "Replace saved key" and panel._connection_save_button.disabled, "Empty replacement cannot overwrite a saved key")
	await _verify_connection_loop(panel, 2)
	panel._key_input.grab_focus()
	await _type_text("   ")
	_check(panel._key_input.text == "   " and panel._connection_save_button.disabled, "Whitespace input keeps replacement disabled")
	await _key(KEY_ENTER)
	_check(_key_submissions == 0 and panel._key_input.text.is_empty(), "Whitespace Enter never submits a credential")
	await _click(panel._key_input)
	await _type_text("fixture")
	_check(panel._key_input.text == "fixture" and not panel._connection_save_button.disabled, "Real typing enables replacement only for nonempty input (length=%d disabled=%s submitted=%d focus=%s)" % [panel._key_input.text.length(), panel._connection_save_button.disabled, _key_submissions, root.gui_get_focus_owner()])
	await _verify_connection_loop(panel, 3)
	panel._key_input.grab_focus()
	for index: int in range(7): await _key(KEY_BACKSPACE)
	_check(panel._key_input.text.is_empty() and panel._connection_save_button.disabled, "Deleting typed replacement disables saving again")
	await _verify_connection_loop(panel, 2)
	_capture("connection-configured")
	await _key(KEY_ESCAPE)
	_check(panel._tab_buttons[3].has_focus() and _key_submissions == 0, "Leaving configured connection preserves key and invoking focus")
	panel.set_credential_status(false)
	await _frames()
	_check(panel._connection_panel.visible and panel._key_input.has_focus(), "Missing-key modal starts at key input")
	_check(panel._connection_title.text == "Connect AI" and panel._connection_save_button.text == "Save connection" and panel._connection_save_button.disabled, "Missing key retains onboarding copy and safe empty state")
	await _verify_connection_loop(panel, 2)
	panel.set_worker_connection_error("Worker became unavailable while connecting.")
	await _frames()
	_check(panel._connection_description.text == "Reconnect first, then add your OpenRouter key.", "Disconnected onboarding does not imply that a key is already saved")
	await _verify_connection_loop(panel, 2)
	panel.set_worker_ready()
	await _frames()
	await _verify_connection_loop(panel, 2)
	await _key(KEY_ESCAPE)
	_check(not panel._connection_panel.visible and panel._tab_buttons[3].has_focus(), "Escape restores the invoking drawer control (open=%s, focus=%s)" % [panel._connection_panel.visible, root.gui_get_focus_owner()])
	panel.set_credential_status(true)
	panel.set_worker_connection_error("Worker disconnected during the session.")
	panel._open_connection_settings()
	await _frames()
	_check(not panel._key_input.visible and not panel._connection_save_button.visible, "Worker failure does not ask for a new key")
	_check(panel._connection_title.text == "Worker offline", "Worker failure heading uses the same sentence case as connection screens")
	_check(panel._key_status.text.is_empty() and panel._connection_retry_button.tooltip_text == "Worker disconnected during the session.", "Offline page avoids repeating the disconnect while preserving diagnostic detail")
	await _verify_connection_loop(panel, 2)
	_capture("worker-error")
	await _click(panel._connection_retry_button)
	_check(_requested_retry, "Visible reconnect dispatches worker retry")
	await _verify_connection_loop(panel, 1)
	panel.set_worker_ready()
	await _frames()
	_check(not panel._connection_panel.visible, "Recovery returns to current drawer")
	_capture("worker-recovered")
	_main._spawn_employees([])
	panel.open_drawer(false)
	await _frames()
	_check(panel._empty_team_panel.visible and not panel._header_shell.visible and not panel._tabs.visible and not panel._tab_strip.visible, "Empty team hides unusable portrait and tabs")
	var hire := panel._empty_team_panel.find_children("*", "Button", true, false)[0] as Button
	_capture("first-hire")
	await _click(hire)
	_check(_requested_journey, "First-hire screen leads to Journey")
	var long_names := _main.room.placeholder_records()
	long_names[0].display_name = "Mina · Product strategy and customer research"
	panel.configure_employees(long_names)
	panel.select_employee("mira")
	panel._tabs.current_tab = 0
	await _frames()
	_check(panel._employee_name.get_global_rect().end.x <= panel._drawer_close_button.get_global_rect().position.x, "Long employee identity cannot overlap close target")
	_check(panel._employee_name.tooltip_text == long_names[0].display_name, "Long identity preserves full text in tooltip")
	_check(panel._employee_name.get_theme_font("font") == GameFonts.display_font_for(long_names[0].display_name), "Long name selects fallback by glyph coverage, not width")
	_check(panel._chat_send_button.size.x <= 100 and panel._chat_input.size.x >= 160, "Long identity cannot expand Ask or collapse the composer")
	_check(panel._chat_send_button.tooltip_text.contains(long_names[0].display_name), "A clipped Ask label retains its complete accessible text")
	_assert_text_roles(panel)
	_assert_header_and_rail_fit(panel)
	for identity: String in ["Alexandria Customer Research", "Zoë – 顾客研究 🚀"]:
		long_names[0].display_name = identity
		panel.configure_employees(long_names)
		panel.select_employee("mira")
		await _frames()
		_check(panel._employee_name.get_theme_font("font") == GameFonts.display_font_for(identity), "Dynamic identity refresh uses deterministic coverage fallback")
		_check(panel._employee_name.tooltip_text == identity and panel._employee_name.get_meta("original_heading") == identity, "Dynamic non-ASCII identity stays original in tooltip and metadata")
		_check(GameFonts.has_glyphs(panel._employee_name.get_theme_font("font"), panel._employee_name.text), "Displayed dynamic identity has no missing glyphs")
		_assert_single_line_fit(panel._employee_name, panel._employee_name.text)
		_assert_text_roles(panel)
		_assert_header_and_rail_fit(panel)
	await _click(panel._team_buttons["theo"])
	_check(panel._employee_name.text == "Theo" and panel._chat_send_button.text == "Ask Theo", "Real rail selection updates both employee heading and action")
	_assert_single_line_fit(panel._employee_name, "Theo")
	_assert_text_roles(panel)
	_assert_header_and_rail_fit(panel)
	_main.game_audio.shutdown()
	root.remove_child(_main)
	_main.free()
	await _frames(4)
	if not _spend_ink_samples.is_empty():
		var evidence := FileAccess.open(OUTPUT.path_join("spend-ink.json"), FileAccess.WRITE)
		evidence.store_string(JSON.stringify(_spend_ink_samples, "\t"))
	print("UI drawer redesign: %d checks, %d failures" % [_checks, _failures.size()])
	quit(_failures.size())
