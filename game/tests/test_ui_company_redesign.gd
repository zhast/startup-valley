extends SceneTree

const OUTPUT := "res://tests/output/ui-redesign/company"
var _panel: CompanyPanel
var _checks := 0
var _failures: Array[String] = []
var _actions: Array[String] = []
var _captures: Array[String] = []
var _layouts: Array[Dictionary] = []
var _revisions := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
		push_error(message)

func _frames(count: int = 4) -> void:
	for frame: int in range(count): await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_panel = CompanyPanel.new()
	root.add_child(_panel)
	_panel.action_requested.connect(func(method: String, _params: Dictionary) -> void: _actions.append(method))
	_panel.milestone_requested.connect(func(_definition: Dictionary) -> void: _revisions += 1)
	await _frames()
	_font_contract()
	await _reset_input()
	await _hire_input()
	await _accented_hire()
	await _journey_input()
	await _settings_input()
	await _summary_layout()
	await _closing_layout()
	await _long_review()
	await _collapsed_review_fit()
	await _sparse_layouts()
	await _disabled_hire()
	await _chapter_complete()
	await _chapter_two_end()
	await _chapter_three_end()
	await _tycoon_secondary_actions()
	var file := FileAccess.open(OUTPUT + ("/manifest-headless.json" if DisplayServer.get_name() == "headless" else "/manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": _checks, "failures": _failures, "captures": _captures, "layouts": _layouts,
		"workerDisabled": true, "transactions": "Signal-only spy. No worker, database or real save.",
		"input": "Visible controls receive actual InputEvent mouse/key events."}, "\t"))
	file.close()
	_panel.queue_free()
	await _frames()
	print("Company UI redesign: %d checks; %d failures; %d captures" % [_checks, _failures.size(), _captures.size()])
	quit(0 if _failures.is_empty() else 1)

func _fixture(status: String = "available") -> Dictionary:
	var website := {"id": "website", "title": "Build a website", "employeeId": "mira", "state": "available", "files": ["site/index.html", "site/styles.css"], "rewardCents": 60000, "reputation": 10}
	if status != "available": website.merge({"state": "active", "jobId": "fixture-job", "jobStatus": status}, true)
	if status in ["revise", "ready"]:
		website.merge({"state": "revision_required" if status == "revise" else "active", "jobStatus": "completed", "evaluation": {"verdict": status, "score": 2.0 if status == "revise" else 3.0,
			"summary": "Improve the offer before launch." if status == "revise" else "The website is ready for customers.",
			"criteria": [{"name": "Offer clarity", "score": 2 if status == "revise" else 3, "evidence": "The headline promises a clear next step."}]}}, true)
	return {"company": {"cashCents": 60000, "earnedCents": 60000, "reputation": 10, "chapter": 1}, "player": {"movementSeen": true},
		"candidates": [{"id": "mira", "name": "Mina", "role": "Product + research", "hired": true, "available": false, "costCents": 0},
			{"id": "theo", "name": "Theo", "role": "Growth + operations", "hired": false, "available": false, "costCents": 30000}],
		"milestones": [website, {"id": "ads", "title": "Run ads", "state": "locked", "availableFromDay": 2}]}

func _present(mode: String, value: Dictionary) -> void:
	_panel.update_state(value)
	_panel.present(mode)
	await _frames(15)
	_bounds()

func _button(prefix: String) -> Button:
	for node: Node in _panel.find_children("*", "Button", true, false):
		if (node as Button).text.to_lower().begins_with(prefix.to_lower()): return node as Button
	return null

func _visible(control: Control) -> bool:
	if control == null or not control.is_visible_in_tree(): return false
	var area := control.get_global_rect()
	if not Rect2(0, 0, 1280, 720).encloses(area): return false
	if _panel._scroll.is_ancestor_of(control): return _panel._scroll.get_global_rect().encloses(area)
	return true

func _click(control: Control) -> void:
	_check(_visible(control), "Mouse target must be visibly inside its clipping surface")
	if not _visible(control): return
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down, true)
	await _frames(1)
	var up := InputEventMouseButton.new()
	up.position = point
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	root.push_input(up, true)
	await _frames()

func _key(code: Key) -> void:
	var down := InputEventKey.new()
	down.keycode = code
	down.physical_keycode = code
	down.pressed = true
	root.push_input(down, true)
	await _frames(1)
	var up := InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	root.push_input(up, true)
	await _frames()

func _wheel_down(control: Control, ticks: int) -> void:
	_check(_visible(control), "Wheel target must be visible before scrolling")
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for tick: int in range(ticks):
		var wheel := InputEventMouseButton.new()
		wheel.position = point
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		root.push_input(wheel, true)
		var release := InputEventMouseButton.new()
		release.position = point
		release.button_index = MOUSE_BUTTON_WHEEL_DOWN
		root.push_input(release, true)
		await _frames(1)

func _text() -> String:
	var values := PackedStringArray()
	for node: Node in _panel.find_children("*", "Label", true, false): values.append((node as Label).text)
	return "\n".join(values)

func _font_contract() -> void:
	_check(GameFonts.DISPLAY.get_font_name().to_lower().replace(" ", "").contains("slab"), "Company display resolves to the selected Not Jam Slab face")
	for font: Font in [GameFonts.BODY, GameFonts.EMPHASIS, GameFonts.BOLD]:
		_check(font.get_font_name().to_lower().replace(" ", "").contains("nunito"), "Company prose and actions resolve to the bundled Nunito family")
		_check(not font.get_rids().is_empty(), "Selected C text roles have actual rendering resources")
	_check(GameFonts.BODY.get_rids() != GameFonts.BOLD.get_rids(), "Body and action roles resolve to distinct effective font weights")
	_check(GameFonts.BODY.get_rids() != GameFonts.EMPHASIS.get_rids(), "Body and metadata resolve distinct effective Nunito weights")
	_check(_contrast(CozyUI.INK, CozyUI.PAPER_LIGHT) >= 4.5, "Company prose palette retains readable paper contrast")
	_check(_contrast(CozyUI.MUTED, CozyUI.PAPER_LIGHT) >= 4.5, "Secondary company copy retains readable paper contrast")
	_check(_contrast(CozyUI.MUTED, CozyUI.DISABLED) >= 4.5, "Disabled company labels remain legible in the declared disabled palette")

func _contrast(ink: Color, paper: Color) -> float:
	var values: Array[float] = []
	for color: Color in [ink, paper]:
		var linear := color.srgb_to_linear()
		values.append(0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b)
	return (maxf(values[0], values[1]) + 0.05) / (minf(values[0], values[1]) + 0.05)

func _bounds() -> void:
	_check(Rect2(0, 0, 1280, 720).encloses(_panel._frame.get_global_rect()), "Purpose-sized modal stays within native viewport")
	_material(_panel._frame.get_theme_stylebox("panel"), "notebook", "Company outer paper")
	_check(_panel._header.get_global_rect().end.y <= _panel._scroll.get_global_rect().position.y, "Header stays outside scrolled content")
	_check(_panel._scroll.get_global_rect().end.y <= _panel._footer.get_global_rect().position.y, "Footer stays outside scrolled content")
	for node: Node in _panel._content.find_children("*", "PanelContainer", true, false):
		if _menu_chrome(node): continue
		_material((node as PanelContainer).get_theme_stylebox("panel"), "card", "Company reading card")
	var bar := _panel._scroll.get_v_scroll_bar()
	_material(bar.get_theme_stylebox("scroll"), "track", "Company scroll well")
	_material(bar.get_theme_stylebox("grabber"), "thumb", "Company scroll grip")
	for node: Node in _panel._frame.find_children("*", "Label", true, false):
		var label := node as Label
		var role := str(label.get_meta("cozy_text_role", "body"))
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		var expected: Font = GameFonts.display_font_for(label.text) if role == "display" else GameFonts.EMPHASIS if role == "meta" else GameFonts.BOLD if role in ["section", "numeric", "title", "action"] else GameFonts.BODY
		_check(font_size >= (14 if role == "meta" else 16), "Every dynamic company label meets its semantic role minimum")
		_check(font.get_rids() == expected.get_rids(), "Dynamic company label resolves the intended effective font: " + role)
		if role == "display":
			_check(font_size == 22, "Controlled pixel display copy uses its exact native 22px multiple")
			_check(label.text != label.text.to_upper(), "Screen headings use readable mixed case")
		elif role == "section":
			_check(font_size == GameFonts.SECTION, "Subsections retain their separate Nunito20 hierarchy")
		elif role == "numeric":
			_check(font_size == GameFonts.NUMERIC, "Summary numbers use the explicit 20px numeric role")
		if not label.is_visible_in_tree(): continue
		_check(label.size.x <= (label.get_parent() as Control).size.x + 1, "Text width stays inside its parent after Nunito reflow")
		if label.max_lines_visible < 0:
			_check(label.get_minimum_size().y <= label.size.y + 1, "Wrapped company text is not vertically clipped: " + label.text.left(42))
		if role == "display":
			_check(_panel._header.get_global_rect().encloses(label.get_global_rect()), "Screen title remains inside the fixed header")
		for essential: String in ["Real AI work", "real AI budget", "This starts a new journey", "Move:", "Required files", "AI spend is real money"]:
			if label.text.contains(essential):
				_check(role != "meta" and font_size >= 16, "Instructions and consequences use body-sized text: " + essential)
	for node: Node in _panel._frame.find_children("*", "Button", true, false):
		var button := node as Button
		_check(button.get_theme_font("font").get_rids() == GameFonts.BOLD.get_rids(), "Dynamic company buttons resolve explicit Nunito Bold")
		var normal := button.get_theme_stylebox("normal")
		for state: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			var style := button.get_theme_stylebox(state)
			_material(style, "control-" + str(button.get_meta("cozy_variant")), "Company %s state" % state)
			_check(style.get_minimum_size() == normal.get_minimum_size(), "Button states keep stable content insets")
		var focus := button.get_theme_stylebox("focus")
		_material(focus, "focus", "Company keyboard focus")
		_check(_has_no_expansion(focus), "Keyboard focus follows the control without a detached expanded rectangle")
		if not button.is_visible_in_tree() or button.text.is_empty(): continue
		_check(button.size.y >= 44, "Visible company action retains a 44px target")
		var insets := button.get_theme_stylebox("normal").get_minimum_size().x
		var copy_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
		var icon_width := button.icon.get_width() + button.get_theme_constant("h_separation") if button.icon != null else 0
		_check(copy_width + insets + icon_width <= button.size.x + 1, "Button lettering and disclosure icon stay inside protected insets: " + button.text)
	_check(_panel._notice.get_theme_font_size("font_size") >= 16, "Company errors and progress notices are body-sized")

func _material(style: StyleBox, kind: String, context: String) -> void:
	_check(style.get_meta("cozy_family", "") == CozyUI.MATERIAL_FAMILY, context + " belongs to the shared notebook material family")
	_check(style.get_meta("cozy_material", "") == kind, context + " retains its semantic material role")

func _menu_chrome(node: Node) -> bool:
	# OptionButton / PopupMenu internals are popup and focus surfaces, not reading cards.
	var current := node
	while current != null and current != _panel._content:
		if current is OptionButton or current is PopupMenu: return true
		current = current.get_parent()
	return false

func _has_no_expansion(style: StyleBox) -> bool:
	for property: Dictionary in style.get_property_list():
		var property_name := str(property["name"])
		if property_name.begins_with("expand_margin_") and not is_zero_approx(float(style.get(property_name))): return false
	return true

func _capture(name_value: String) -> void:
	await _frames(4)
	# Frame counts alone can finish before the real-time opening fade on a fast
	# renderer. Evidence must show the settled UI, not a translucent transition.
	if _panel._transition != null and _panel._transition.is_valid() and _panel._transition.is_running():
		await _panel._transition.finished
		await _frames(1)
	_check(is_equal_approx(_panel.modulate.a, 1.0), "Company capture waits for its opening transition to settle")
	var regions: Array[Dictionary] = []
	for node: Node in _panel._content.get_children():
		if node is Control:
			var control := node as Control
			regions.append({"type": control.get_class(), "height": control.size.y, "minimumHeight": control.get_combined_minimum_size().y,
				"copy": control.text if control is Label else ""})
	_layouts.append({"name": name_value, "frameHeight": _panel._frame.size.y, "contentHeight": _panel._content.size.y,
		"scrollViewportHeight": _panel._scroll.size.y, "scrollVisible": _panel._scroll.get_v_scroll_bar().visible,
		"scrollOffset": _panel._scroll.scroll_vertical, "noticeVisible": _panel._notice.visible,
		"settledOpacity": _panel.modulate.a, "contentRegions": regions})
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	_check(image.get_size() == Vector2i(1280, 720), "Company capture uses native viewport")
	var path := OUTPUT + "/" + name_value + ".png"
	_check(image.save_png(path) == OK, "Company screenshot saved")
	_captures.append(ProjectSettings.globalize_path(path))

func _reset_input() -> void:
	_panel.day = 3
	await _present("title", _fixture())
	_check(_text().contains("Day 3") and _text().contains("Mina"), "Continue card identifies saved day and hired teammate")
	await _click(_button("New company"))
	_check(_panel.screen == "confirm", "New company opens confirmation")
	_check(root.gui_get_focus_owner() == _button("Go back"), "Destructive confirmation initially focuses Go back")
	_check(_button("Back up").get_meta("cozy_variant") == "danger", "Reset is visually destructive, not a positive primary")
	await _capture("reset-safe-focus")
	await _key(KEY_ENTER)
	_check(_panel.screen == "title" and _actions.is_empty(), "Enter on initial reset focus returns safely without a transaction")
	await _click(_button("New company"))
	await _key(KEY_ESCAPE)
	_check(_panel.screen == "title" and _actions.is_empty(), "Escape cancels reset without a transaction")
	await _click(_button("New company"))
	await _click(_button("Back up"))
	await _click(_button("Back up"))
	_check(_actions.count("game.new") == 1, "Rapid confirmed reset emits only one signal; no real save exists in this fixture")
	_panel.show_error("Fixture reset cancelled. Nothing was changed.")
	_actions.clear()

func _hire_input() -> void:
	var value := _fixture()
	value["player"] = {"movementSeen": false}
	value["milestones"][0]["state"] = "locked"
	value["candidates"][0].merge({"hired": false, "available": true}, true)
	await _present("title", value)
	await _click(_button("Start company"))
	_check(_panel.screen == "journey", "New company leads to first hire")
	_check(_text().contains("Mina") and _text().contains("Free onboarding hire"), "Hiring identifies person and game cost")
	_check((_panel.find_child("HirePortrait", true, false) as TextureRect).texture != null, "Hiring reuses employee portrait")
	await _click(_button("Hire Mina"))
	await _click(_button("Hire Mina"))
	_check(_actions.count("hiring.complete") == 1, "Rapid hire emits only one request")
	value["candidates"][0].merge({"hired": true, "available": false}, true)
	value["candidates"][1]["hired"] = true
	await _present("hired", value)
	_check(_text().contains("Welcome, Mina") and _button("Meet Mina") != null, "Hire confirmation preserves requested identity even with two hired candidates")
	_check(_text().contains("website") or _text().contains("Assign"), "Hire confirmation points at the website work order instead of only chatting")
	await _capture("named-hire")
	_actions.clear()

func _journey_input() -> void:
	await _present("journey", _fixture("completed"))
	_check(_visible(_button("Evaluate result")), "Evaluate is pinned and visible before any evidence")
	_check(_text().contains("up to 3,000 tokens"), "Real evaluation spend is explained beside confirmation")
	await _click(_button("Evaluate result"))
	_check(_actions.count("milestone.evaluate") == 1, "Evaluation dispatch remains milestone.evaluate")
	_check(_button("Evaluate result").disabled and _panel._next_step().contains("files are saved"), "Busy evaluation preserves its disabled action and saved-work guidance")
	_check(not _panel._notice.visible and _text().count("Evaluating") == 1, "Evaluation has one visible progress label, not repeated footer and button messages")
	await _capture("evaluation-busy")
	await _click(_button("Evaluate result"))
	_check(_actions.count("milestone.evaluate") == 1, "Disabled evaluation does not dispatch again")
	_check(not _button("Back to office").disabled, "Pending evaluation keeps its nonmutating office navigation available")
	var pending_state := _panel.state.duplicate(true)
	await _click(_button("Back to office"))
	_check(not _panel.visible and _panel.busy, "Returning to the office hides the notebook without clearing its pending evaluation")
	_check(_panel.state == pending_state and _panel._pending_method == "milestone.evaluate" and _panel._pending_job_id == "fixture-job", "Closing preserves the exact company projection and pending evaluation identity")
	_check(_actions.count("milestone.evaluate") == 1, "Returning to office emits no evaluation or transaction request")
	_panel.present("journey")
	await _frames(15)
	_bounds()
	_check(_panel._evaluation_pending() and _text().count("Evaluating") == 1 and _button("Evaluate result").disabled, "Reopening retains one progress state and cannot start another evaluation")
	await _click(_button("Evaluate result"))
	_check(_actions.count("milestone.evaluate") == 1, "Reopening and clicking the pending action cannot dispatch a duplicate evaluation")
	var error := _fixture("completed")
	error["milestones"][0]["evaluationError"] = "Provider temporarily unavailable."
	await _present("journey", error)
	_check(_visible(_button("Retry evaluation")) and _text().contains("Your work is saved"), "Evaluation failure offers retry and preserves completed work meaning")
	await _capture("evaluation-error")
	await _present("journey", _fixture("revise"))
	_check(_panel._next_step().contains("Revise") and not _panel._next_step().contains("then evaluate the result"), "Revision result overrides completed-job evaluate instruction")
	_check(_visible(_button("Revise work")), "Revision primary is visible before evidence expansion")
	await _click(_button("Revise work"))
	_check(_revisions == 1 and not _panel.visible, "Revise opens a work-order draft through existing milestone signal")
	await _present("journey", _fixture("revise"))
	_check(_button("Override").get_meta("cozy_variant") == "danger", "Override is a bounded consequence action rather than plain text")
	await _click(_button("Override"))
	_check(_actions.count("milestone.override") == 1, "Override remains an explicit separate action")
	await _present("journey", _fixture("ready"))
	_check(_panel._next_step().contains("review passed") and _visible(_button("Complete milestone")), "Passing review leads directly to visible completion")
	await _click(_button("Complete milestone"))
	await _click(_button("Complete milestone"))
	_check(_actions.count("milestone.complete") == 1, "Rapid completion remains idempotent at UI boundary")
	await _present("journey", _fixture("queued"))
	_check(_panel._next_step().contains("queued") and not _text().contains("Work in progress"), "Queued and running presentation do not conflict")
	await _present("journey", _fixture())
	_check(not _text().contains("Theo") and _visible(_button("Prepare work order")), "Future hire does not displace current available objective")
	_check(_button("Show chapter").icon != null, "Roadmap visibly announces its disclosure behavior")
	_check(_button("End day + save").get_meta("cozy_variant") == "secondary", "End Day remains a bounded secondary action")
	await _click(_button("Show chapter"))
	_check(_text().contains("Theo") and _text().contains("Future teammate"), "Roadmap explicitly reveals future teammates")
	_actions.clear()

func _accented_hire() -> void:
	var value := _fixture()
	value["candidates"][0]["name"] = "Éloïse"
	await _present("hired", value)
	_check(_text().contains("Welcome, Éloïse") and _button("Meet Éloïse") != null, "Accented hire identity is retained in title and action copy")
	for node: Node in _panel._header.find_children("*", "Label", true, false):
		var label := node as Label
		if label.get_meta("cozy_text_role", "") == "display":
			_check(label.get_theme_font("font").get_rids() == GameFonts.BOLD.get_rids(), "Accented dynamic title uses the explicit bundled Nunito coverage fallback")
			_check(GameFonts.has_glyphs(label.get_theme_font("font"), label.text), "Every accented title character is supported by the effective face")
			_check(_visible(label), "Accented title remains fully inside its modal header")
	await _capture("accented-hire-heading")

func _settings_input() -> void:
	await _present("settings", _fixture())
	_check(_panel._content.size.y <= _panel._scroll.size.y, "Settings fits without vertical scrolling")
	_check(not _panel._scroll.get_v_scroll_bar().visible, "Settings does not need a scrollbar")
	var slider := _panel.find_child("EffectsSlider", true, false) as HSlider
	var percent := _panel.find_child("EffectsPercent", true, false) as Label
	_check(_visible(slider), "Volume slider is visible before input")
	_material(slider.get_theme_stylebox("slider"), "track-horizontal", "Volume track")
	_material(slider.get_theme_stylebox("grabber_area"), "track-filled", "Volume fill")
	var picker := _panel.find_child("ArchitectureTheme", true, false) as OptionButton
	_check(picker != null and picker.item_count >= 2, "Settings office look lists the registered architecture kits")
	if picker != null:
		_material(picker.get_popup().get_theme_stylebox("panel"), "popup", "Office look menu")
		for node: Node in picker.get_popup().find_children("*", "PanelContainer", true, false):
			var kind := "focus" if str(node.name) == "_focus" else "popup"
			_material((node as PanelContainer).get_theme_stylebox("panel"), kind, "Office look menu " + kind)
	slider.grab_focus()
	await _key(KEY_RIGHT)
	_check(is_equal_approx(_panel.effects_volume, 0.55) and percent.text == "55%", "Keyboard volume change updates live percentage")
	await _capture("settings-live-percentage")
	for index: int in range(12):
		await _key(KEY_TAB)
		_check(_panel.is_ancestor_of(root.gui_get_focus_owner()), "Settings Tab focus remains in modal")
	await _key(KEY_ESCAPE)
	_check(not _panel.visible, "Escape closes settings")

func _summary_layout() -> void:
	_panel.show_summary({"day": 3, "earnedCents": 987654321, "reputation": 123456, "aiSpend": 123.4567, "completedWork": ["Build a website", "A long title for the launch campaign creative and audience plan"], "entries": [{"label": "Incorporation planning completed"}], "nextMilestone": "Your next chapter"})
	await _frames(15)
	_bounds()
	_check(_text().contains("$9,876,543.21"), "Large in-game revenue is grouped and retains cents")
	_check(_text().contains("Game revenue") and _text().contains("virtual company funds") and _text().contains("Optional AI spend") and _text().contains("real money (USD)"), "Day results distinguish virtual company funds from optional real AI costs in USD")
	var numeric_count := 0
	for node: Node in _panel.find_children("*", "Label", true, false):
		var label := node as Label
		if label.get_meta("cozy_text_role", "") == "numeric":
			numeric_count += 1
			_check(_visible(label) and label.get_line_count() == 1, "Large summary values remain complete single lines inside their cards")
	_check(numeric_count == 3, "All three summary values have explicit numeric roles")
	_check(_visible(_button("Begin next day")), "Next day action remains visible with large metrics and long work titles")
	await _capture("day-summary-large-values")
	_panel.show_summary({"day": 3, "earnedCents": 60000, "reputation": 10, "aiSpend": 0, "completedWork": ["Ship a product"], "entries": [], "nextMilestone": "Your next chapter"})
	await _frames(15)
	_check(not _text().contains("Optional AI spend") and not _text().contains("Real AI spend"), "A day with no AI work hides the optional spend metric")
	_check(_text().contains("Game revenue") and _text().contains("virtual company funds"), "Virtual game revenue remains when optional AI spend is hidden")

func _closing_layout() -> void:
	var value := _fixture()
	value["daySummary"] = {"day": 3, "earnedCents": 60000, "reputation": 10, "aiSpend": 0.0437, "completedWork": ["Build a website"], "nextMilestone": "Run ads"}
	await _present("closing", value)
	_check(_visible(_button("End day + save")), "Closing action stays visible beside body-sized day-end consequences")
	await _capture("day-closing")
	_panel.show_error("The worker is unavailable. Your company remains saved; reconnect and try again.")
	await _frames(12)
	_bounds()
	_check(_visible(_panel._notice), "Multiline recovery copy is visible inside the fixed footer")
	await _capture("day-closing-error")

func _long_review() -> void:
	var value := _fixture("ready")
	var evaluation: Dictionary = value["milestones"][0]["evaluation"]
	evaluation["criteria"] = [{"name": "Completeness", "score": 3, "evidence": "Specific evidence of a complete deliverable and meaningful next step. ".repeat(100)}]
	await _present("journey", value)
	var header_position := _panel._header.global_position
	var footer_position := _panel._footer.global_position
	_check(_button("Review criterion").icon != null, "Criterion evidence has a visible disclosure icon")
	await _click(_button("Review criterion"))
	_check(_panel._details_open, "Visible evidence disclosure responds to pointer input")
	await _capture("long-evidence-top")
	await _wheel_down(_panel._scroll, 160)
	_check(_panel._scroll.scroll_vertical > 0, "Real pointer wheel scrolls long review evidence")
	_check(_panel._header.global_position == header_position and _panel._footer.global_position == footer_position, "Long evidence scrolls without moving modal header or primary action")
	_check(_visible(_button("Complete milestone")), "Completion stays visible while reading long criterion evidence")
	_check(_panel._content.size.x <= _panel._scroll.size.x - _panel._scroll.get_v_scroll_bar().size.x + 1, "Long review wraps before scrollbar")
	await _capture("long-evidence-bottom")

func _collapsed_review_fit() -> void:
	var value := _fixture("revise")
	value["milestones"][0]["evaluation"]["summary"] = "The offer is clear, but the signup flow needs a usable next step."
	await _present("journey", value)
	_check(_panel._content.size.y <= _panel._scroll.size.y, "Ordinary collapsed revision fits without a tiny scroll")
	_check(not _panel._scroll.get_v_scroll_bar().visible, "Collapsed revision needs no scrollbar")
	var money_note := _panel.find_child("MoneyExplanation", true, false) as Label
	_check(money_note != null and _visible(money_note), "The entire money and planning-files explanation is visible at rest")
	_check(money_note != null and money_note.text.contains("Game cash is virtual") and money_note.text.contains("Shipping products is fully offline") and money_note.text.contains("planning files only"), "Journey keeps virtual cash, offline shipping, and planning-only consequences explicit")
	_check(not _panel._notice.visible, "An empty notice never reserves a footer line")
	await _capture("collapsed-revision-fit")
	_panel.show_error("Evaluation could not finish because the provider returned an incomplete response. Your files are saved. Retry when your connection is restored; no milestone reward has been claimed.")
	await _frames(15)
	_bounds()
	_check(_visible(_panel._notice) and _panel._notice.get_line_count() >= 2, "Long recovery notice remains complete inside the footer")
	await _capture("long-error-fit")

func _sparse_layouts() -> void:
	await _present("journey", _fixture())
	_check(_panel._frame.size.y < 608 and _panel._content.size.y <= _panel._scroll.size.y, "Available Journey uses a compact content-sized modal without clipping")
	await _capture("sparse-journey")
	await _present("settings", _fixture())
	_check(_panel._frame.size.y < 592 and _panel._content.size.y <= _panel._scroll.size.y, "Settings removes empty page space without introducing scrolling")
	await _capture("compact-settings")
	_panel.show_summary({"day": 1, "earnedCents": 60000, "reputation": 10, "aiSpend": 0.0437, "completedWork": ["Build a website"], "nextMilestone": "Run ads"})
	await _frames(15)
	_bounds()
	_check(_panel._frame.size.y < 584, "Short day summary uses a content-responsive height")
	_check(_visible(_button("Begin next day")), "Compact summary retains its complete primary action")
	await _capture("compact-summary")

func _disabled_hire() -> void:
	var value := _fixture()
	value["company"]["cashCents"] = 0
	value["milestones"][0]["state"] = "completed"
	value["candidates"][1]["available"] = true
	await _present("journey", value)
	var hire := _button("Hire Theo")
	_check(hire != null and hire.disabled and _visible(hire), "Unaffordable Theo hire remains visible, named and disabled")
	var before := _actions.size()
	await _click(hire)
	_check(_actions.size() == before, "Disabled hiring cannot dispatch a transaction")
	await _capture("disabled-hire")

func _chapter_complete() -> void:
	var value := _fixture()
	value["company"]["chapter"] = 2
	value["milestones"][0]["state"] = "completed"
	value["milestones"][1]["state"] = "completed"
	value["candidates"][0]["hired"] = true
	value["candidates"][1].merge({"hired": true, "available": false}, true)
	await _present("journey", value)
	_check(_panel.screen == "complete", "Finished chapter presents the chapter-complete screen")
	_check(_text().contains("Chapter complete") and _visible(_button("Back to office")), "Chapter-complete screen names the win state and keeps an office exit")
	await _capture("chapter-complete")
	await _click(_button("Back to office"))
	_check(not _panel.visible, "Chapter-complete Back to office closes the notebook")

func _chapter_two_end() -> void:
	var value := _fixture()
	value["company"]["chapter"] = 2
	value["company"]["cashCents"] = 180000
	value["milestones"][0]["state"] = "completed"
	value["milestones"][1]["state"] = "completed"
	value["milestones"].append({"id": "brand", "title": "Design the brand", "state": "completed", "employeeId": "creative"})
	value["candidates"][0]["hired"] = true
	value["candidates"][1].merge({"hired": true, "available": false}, true)
	value["candidates"].append({"id": "creative", "name": "Creative", "role": "Design + brand", "hired": true, "available": false, "costCents": 0})
	value["milestones"].append({"id": "apply", "title": "Apply the brand", "state": "locked", "employeeId": "creative"})
	await _present("journey", value)
	_check(_panel.screen == "complete", "Finished brand presents the Chapter 2 end screen")
	_check(_text().contains("Chapter 2 complete") and _visible(_button("Begin Chapter 3")), "Chapter 2 end state names the chapter and offers Chapter 3")
	_check(_button("Begin Chapter 2") == null, "Chapter 2 end state does not offer to begin Chapter 2 again")
	_check(_visible(_button("Back to office")), "Chapter 2 end state can return to the office")
	await _capture("chapter-two-complete")
	await _click(_button("Back to office"))
	_check(not _panel.visible, "Chapter 2 Back to office closes the notebook")

func _chapter_three_end() -> void:
	var value := _fixture()
	value["company"]["chapter"] = 3
	value["company"]["cashCents"] = 220000
	value["milestones"][0]["state"] = "completed"
	value["milestones"][1]["state"] = "completed"
	value["milestones"].append({"id": "brand", "title": "Design the brand", "state": "completed", "employeeId": "creative"})
	value["milestones"].append({"id": "apply", "title": "Apply the brand", "state": "completed", "employeeId": "creative"})
	value["candidates"][0]["hired"] = true
	value["candidates"][1].merge({"hired": true, "available": false}, true)
	value["candidates"].append({"id": "creative", "name": "Creative", "role": "Design + brand", "hired": true, "available": false, "costCents": 0})
	await _present("journey", value)
	_check(_panel.screen == "complete", "Finished application presents the Chapter 3 end screen")
	_check(_text().contains("Chapter 3 complete") and _text().to_lower().contains("more is coming"), "Chapter 3 end state names the chapter and says more is coming")
	_check(_button("Begin Chapter 3") == null, "Chapter 3 end state does not offer to begin Chapter 3 again")
	_check(_visible(_button("Back to office")), "Chapter 3 end state can return to the office")
	await _capture("chapter-three-complete")
	await _click(_button("Back to office"))
	_check(not _panel.visible, "Chapter 3 Back to office closes the notebook")

func _tycoon_secondary_actions() -> void:
	var value := _fixture()
	value["milestones"][0]["state"] = "locked"
	value["milestones"][1]["state"] = "locked"
	value["candidates"][0]["hired"] = false
	value["candidates"][0]["available"] = true
	value["company"]["cashCents"] = 0
	value["tycoon"] = {
		"researchPoints": 0,
		"researchNotice": "",
		"trainingNotice": "",
		"upgradeNotice": "",
		"upgrades": [
			{"id": "standing_desk", "name": "Oak Standing Desk", "blurb": "Stand for the sketches.", "priceCents": 25000, "kind": "design", "effect": "+1 design per person per dev day", "owned": false, "affordable": false},
			{"id": "ring_light", "name": "Ring Light", "blurb": "Warmer clips.", "priceCents": 40000, "kind": "hype", "effect": "+1 hype per person per dev day", "owned": true, "affordable": false},
		],
		"topics": [
			{"id": "fitness", "name": "Fitness", "unlocked": true, "researchCost": 4},
			{"id": "sneakers", "name": "Sneakers", "unlocked": false, "researchCost": 4},
			{"id": "reselling", "name": "Reselling", "unlocked": false, "researchCost": 4},
			{"id": "sports_betting", "name": "Sports Betting Picks", "unlocked": false, "researchCost": 4},
			{"id": "dating", "name": "Dating Advice", "unlocked": false, "researchCost": 4},
		],
		"types": [
			{"id": "newsletter", "name": "Newsletter", "unlocked": true, "researchCost": 6},
			{"id": "coaching", "name": "Coaching", "unlocked": false, "researchCost": 6},
			{"id": "software", "name": "Software Tool", "unlocked": false, "researchCost": 6},
		],
		"staff": [{
			"id": "founder", "name": "Founder", "hired": true,
			"design": 2, "tech": 2, "hype": 2, "trainedToday": false,
			"training": {
				"design": {"costCents": 30000, "enabled": false},
				"tech": {"costCents": 30000, "enabled": false},
				"hype": {"costCents": 30000, "enabled": false},
			},
		}],
	}
	await _present("journey", value)
	var hire := _button("Hire Mina")
	_check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the single primary action")
	var new_product := _panel.find_child("NewProduct", true, false) as Button
	var train_card := _panel.find_child("TrainStaff", true, false) as Control
	var research_card := _panel.find_child("ResearchCard", true, false) as Control
	var train_tech := _panel.find_child("Train_founder_tech", true, false) as Button
	var research_sneakers := _panel.find_child("Research_sneakers", true, false) as Button
	var research_coaching := _panel.find_child("Research_coaching", true, false) as Button
	_check(new_product != null and str(new_product.get_meta("cozy_variant", "")) == "secondary", "New Product reads as secondary")
	_check(train_tech != null and str(train_tech.get_meta("cozy_variant", "")) == "secondary", "Train Tech reads as secondary")
	_check(research_sneakers != null and str(research_sneakers.get_meta("cozy_variant", "")) == "secondary", "Research Sneakers reads as secondary")
	_check(research_coaching != null and research_coaching.disabled, "Research Coaching stays disabled without enough points")
	var upgrades_card := _panel.find_child("UpgradesCard", true, false) as Control
	var buy_desk := _panel.find_child("Buy_standing_desk", true, false) as Button
	var owned_light := _panel.find_child("Owned_ring_light", true, false) as Label
	_check(train_card != null and research_card != null and upgrades_card != null and new_product.get_global_rect().position.y < train_card.get_global_rect().position.y and train_card.get_global_rect().position.y < research_card.get_global_rect().position.y and research_card.get_global_rect().position.y < upgrades_card.get_global_rect().position.y, "Train staff, Research, and Upgrades sit below New Product")
	_check(_text().contains("0 research points"), "Research card shows the point balance")
	_check(buy_desk != null and buy_desk.disabled and str(buy_desk.get_meta("cozy_variant", "")) == "secondary" and buy_desk.text == "Buy Oak Standing Desk · $250", "Buy Oak Standing Desk is a disabled secondary action")
	_check(owned_light != null and owned_light.text.contains("Ring Light"), "An owned upgrade shows one line")
	_check(_panel.find_child("Buy_ring_light", true, false) == null, "An owned upgrade hides its buy button")
	var tycoon: Dictionary = value["tycoon"]
	tycoon["contract"] = {
		"id": "nova",
		"client": "Nova on Whop",
		"topicId": "crypto",
		"typeId": "newsletter",
		"topicName": "Crypto Alpha",
		"typeName": "Newsletter",
		"bonusCents": 8000,
		"status": "offered",
		"enabled": true,
		"reason": "",
	}
	await _present("journey", value)
	var accept := _panel.find_child("AcceptContract", true, false) as Button
	var contract_client := _panel.find_child("ContractClient", true, false) as Label
	var contract_pair := _panel.find_child("ContractPair", true, false) as Label
	var contract_bonus := _panel.find_child("ContractBonus", true, false) as Label
	_check(accept != null and not accept.disabled and str(accept.get_meta("cozy_variant", "")) == "secondary" and accept.text == "Accept contract", "Accept contract reads as secondary")
	_check(contract_client != null and contract_client.text == "Nova on Whop", "The contract card names the client")
	_check(contract_pair != null and contract_pair.text == "Crypto Alpha × Newsletter", "The contract card names the pair")
	_check(contract_bonus != null and contract_bonus.text == "Bonus $80 on release", "The contract card names the bonus")
	_check(_button("Hire Mina") != null and str(_button("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the contract")
	tycoon["history"] = [{
		"id": "p1",
		"name": "Crypto Alpha Newsletter",
		"status": "released",
		"salesDays": 1,
		"salesDaysTotal": 4,
		"salesCents": 20700,
		"fans": 5,
		"review": {"score": 7, "reviewers": []},
		"patch": {
			"costCents": 10000,
			"scoreBonus": 1,
			"applied": false,
			"enabled": false,
			"reason": "Need $100",
		},
	}]
	await _present("journey", value)
	var patch := _panel.find_child("Patch_p1", true, false) as Button
	var selling := _panel.find_child("Selling_p1", true, false) as Control
	_check(selling != null, "Company Journey shows the selling-product card")
	_check(patch != null and patch.disabled and str(patch.get_meta("cozy_variant", "")) == "secondary" and patch.text == "Patch · Need $100", "Patch reads Need $100 when cash is short")
	_check(_panel.find_child("Sequel_p1", true, false) == null, "A selling card without a sequel offer draws no Sequel button")
	_check(_panel.find_child("Award_p1", true, false) == null, "A selling card without an award offer draws no Enter award button")
	_check(_panel.find_child("Port_p1", true, false) == null, "A selling card without a port offer draws no Port button")
	_check(_button("Hire Mina") != null and str(_button("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Patch")
	var shipped: Dictionary = (tycoon["history"] as Array)[0]
	var offer: Dictionary = shipped["patch"]
	offer["applied"] = true
	offer["reason"] = "Already patched."
	tycoon["patchNotice"] = "Patched Crypto Alpha Newsletter. −$100"
	await _present("journey", value)
	var patched := _panel.find_child("SellingPatched_p1", true, false) as Label
	var notice := _panel.find_child("PatchNotice", true, false) as Label
	patch = _panel.find_child("Patch_p1", true, false) as Button
	_check(patched != null and patched.text == "Patched · +1 score", "The selling card names the patched state")
	_check(notice != null and notice.text == "Patched Crypto Alpha Newsletter. −$100", "The selling card names the patch cost")
	_check(patch != null and patch.disabled and patch.text == "Patch · Already patched.", "A second patch stays disabled")
	var sequel_state := value.duplicate(true)
	var sequel_tycoon: Dictionary = sequel_state["tycoon"]
	sequel_tycoon["history"] = [{
		"id": "p1",
		"name": "Crypto Alpha Newsletter",
		"status": "complete",
		"salesDays": 4,
		"salesDaysTotal": 4,
		"salesCents": 20700,
		"fans": 5,
		"review": {"score": 6, "reviewers": []},
		"sequel": {
			"scoreBonus": 0,
			"savedDays": 1,
			"isSequel": false,
			"started": false,
			"enabled": true,
			"reason": "",
		},
	}]
	await _present("journey", sequel_state)
	var finished := _panel.find_child("Finished_p1", true, false) as Control
	var sequel := _panel.find_child("Sequel_p1", true, false) as Button
	_check(finished != null, "Company Journey shows the finished-product card")
	_check(sequel != null and not sequel.disabled and str(sequel.get_meta("cozy_variant", "")) == "secondary" and sequel.text == "Sequel", "Sequel reads as secondary")
	_check(_button("Hire Mina") != null and str(_button("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Sequel")
	var done: Dictionary = (sequel_tycoon["history"] as Array)[0]
	var sequel_offer: Dictionary = done["sequel"]
	sequel_offer["started"] = true
	sequel_offer["enabled"] = false
	sequel_offer["reason"] = "Already has a sequel."
	await _present("journey", sequel_state)
	sequel = _panel.find_child("Sequel_p1", true, false) as Button
	_check(sequel != null and sequel.disabled and sequel.text == "Sequel · Already has a sequel.", "A second sequel stays disabled")
	var award_state := {
		"id": "p1",
		"name": "Crypto Alpha Newsletter",
		"status": "complete",
		"salesDays": 4,
		"salesDaysTotal": 4,
		"salesCents": 46800,
		"fans": 11,
		"review": {"score": 6, "reviewers": []},
		"award": {
			"show": "Whop Creator Awards",
			"costCents": 4000,
			"outcome": "",
			"fans": 0,
			"entered": false,
			"enabled": true,
			"reason": "",
		},
	}
	var award_journey := sequel_state.duplicate(true)
	(award_journey["tycoon"] as Dictionary)["history"] = [award_state]
	await _present("journey", award_journey)
	var award := _panel.find_child("Award_p1", true, false) as Button
	var award_show := _panel.find_child("AwardShow_p1", true, false) as Label
	_check(award != null and not award.disabled and str(award.get_meta("cozy_variant", "")) == "secondary" and award.text == "Enter award", "Enter award reads as secondary")
	_check(award_show != null and award_show.text == "Whop Creator Awards · $40", "The shipped card names the show and the fee")
	_check(_panel.find_child("AwardResult_p1", true, false) == null, "The result line waits until the product enters")
	_check(_button("Hire Mina") != null and str(_button("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Enter award")
	var award_offer: Dictionary = award_state["award"]
	award_offer["entered"] = true
	award_offer["enabled"] = false
	award_offer["outcome"] = "won"
	award_offer["fans"] = 12
	award_offer["reason"] = "Already entered."
	await _present("journey", award_journey)
	award = _panel.find_child("Award_p1", true, false) as Button
	var award_result := _panel.find_child("AwardResult_p1", true, false) as Label
	_check(award_result != null and award_result.text == "Award · Won · +12 fans", "A win names the fan bonus")
	_check(award != null and award.disabled and award.text == "Enter award · Already entered.", "A second entry stays disabled")
	award_offer["outcome"] = "nominated"
	award_offer["fans"] = 4
	await _present("journey", award_journey)
	award_result = _panel.find_child("AwardResult_p1", true, false) as Label
	_check(award_result != null and award_result.text == "Award · Nominated · +4 fans", "A nominee names the smaller bonus")
	award_offer["outcome"] = "entered"
	award_offer["fans"] = 0
	await _present("journey", award_journey)
	award_result = _panel.find_child("AwardResult_p1", true, false) as Label
	_check(award_result != null and award_result.text == "Award · Entered", "A low score reads Entered")
	award_offer["entered"] = false
	award_offer["outcome"] = ""
	award_offer["reason"] = "Need $40"
	await _present("journey", award_journey)
	award = _panel.find_child("Award_p1", true, false) as Button
	_check(award != null and award.disabled and award.text == "Enter award · Need $40", "Short cash reads Need $40")
	_check(_panel.find_child("AwardResult_p1", true, false) == null, "A refused entry draws no result line")
	var port_state := {
		"id": "p1",
		"name": "Crypto Alpha Newsletter",
		"status": "complete",
		"salesDays": 4,
		"salesDaysTotal": 4,
		"salesCents": 46800,
		"fans": 11,
		"review": {"score": 6, "reviewers": []},
		"sequel": {
			"scoreBonus": 0,
			"savedDays": 1,
			"isSequel": false,
			"started": false,
			"enabled": true,
			"reason": "",
		},
		"award": {
			"show": "Whop Creator Awards",
			"costCents": 4000,
			"outcome": "",
			"fans": 0,
			"entered": false,
			"enabled": true,
			"reason": "",
		},
		"port": {
			"shelf": "Whop Mobile",
			"costCents": 8000,
			"phase": "",
			"cents": 0,
			"fans": 0,
			"enabled": true,
			"reason": "",
		},
	}
	var port_journey := sequel_state.duplicate(true)
	(port_journey["tycoon"] as Dictionary)["history"] = [port_state]
	await _present("journey", port_journey)
	var port_button := _panel.find_child("Port_p1", true, false) as Button
	var port_shelf := _panel.find_child("PortShelf_p1", true, false) as Label
	var shelf_row := _panel.find_child("ShelfActions_p1", true, false) as Control
	var sequel_row := _panel.find_child("Sequel_p1", true, false) as Button
	var award_row := _panel.find_child("Award_p1", true, false) as Button
	_check(port_button != null and not port_button.disabled and str(port_button.get_meta("cozy_variant", "")) == "secondary" and port_button.text == "Port", "Port reads as secondary")
	_check(port_shelf != null and port_shelf.text == "Whop Mobile · $80", "The shipped card names the shelf and the fee")
	_check(_panel.find_child("PortLine_p1", true, false) == null, "The port line waits until the port starts")
	_check(shelf_row != null and sequel_row != null and award_row != null and sequel_row.get_parent() == shelf_row and award_row.get_parent() == shelf_row and port_button.get_parent() == shelf_row, "Sequel, Enter award, and Port share one row")
	_check(_button("Hire Mina") != null and str(_button("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Port")
	var port_offer: Dictionary = port_state["port"]
	port_offer["phase"] = "selling"
	port_offer["enabled"] = false
	port_offer["reason"] = "Already ported."
	await _present("journey", port_journey)
	var port_line := _panel.find_child("PortLine_p1", true, false) as Label
	port_button = _panel.find_child("Port_p1", true, false) as Button
	_check(port_line != null and port_line.text == "Port · Whop Mobile · selling 1 day", "A started port reads selling 1 day")
	_check(port_button != null and port_button.disabled and port_button.text == "Port · Already ported.", "A second port stays disabled")
	_check(_panel.find_child("PortShelf_p1", true, false) == null, "The fee line hides once the port has started")
	port_offer["phase"] = "sold"
	port_offer["cents"] = 4500
	port_offer["fans"] = 2
	await _present("journey", port_journey)
	port_line = _panel.find_child("PortLine_p1", true, false) as Label
	_check(port_line != null and port_line.text == "Port · Whop Mobile · $45.00", "A finished port names the extra sales")
	port_offer["phase"] = ""
	port_offer["cents"] = 0
	port_offer["fans"] = 0
	port_offer["reason"] = "Need $80"
	await _present("journey", port_journey)
	port_button = _panel.find_child("Port_p1", true, false) as Button
	_check(port_button != null and port_button.disabled and port_button.text == "Port · Need $80", "Short cash reads Need $80")
	_check(_panel.find_child("PortLine_p1", true, false) == null, "A refused port draws no status line")
	port_state["status"] = "released"
	port_state["patch"] = {
		"costCents": 10000,
		"scoreBonus": 1,
		"applied": false,
		"enabled": false,
		"reason": "Need $100",
	}
	port_offer["reason"] = "Still selling."
	await _present("journey", port_journey)
	port_button = _panel.find_child("Port_p1", true, false) as Button
	_check(port_button != null and port_button.disabled and port_button.text == "Port · Still selling.", "Port stays disabled while the product is selling")
	port_state["status"] = "complete"
	port_offer["reason"] = "Another port is still selling."
	await _present("journey", port_journey)
	port_button = _panel.find_child("Port_p1", true, false) as Button
	_check(port_button != null and port_button.disabled and port_button.text == "Port · Another port is still selling.", "Another selling port disables this one")
	tycoon.erase("contract")
	tycoon.erase("history")
	tycoon.erase("patchNotice")
	for topic: Dictionary in tycoon["topics"]:
		topic["unlocked"] = true
	for kind: Dictionary in tycoon["types"]:
		kind["unlocked"] = true
	tycoon["researchPoints"] = 20
	await _present("journey", value)
	_check(_panel.find_child("ResearchCard", true, false) == null, "Research card hides once every topic and type is unlocked")
	_check(_panel.find_child("UpgradesCard", true, false) != null, "Upgrades stay when research is finished")
	tycoon["priceSteps"] = [
		{"percent": 80, "unitPercent": 120, "label": "−20%"},
		{"percent": 100, "unitPercent": 100, "label": "Catalog"},
		{"percent": 120, "unitPercent": 80, "label": "+20%"},
	]
	tycoon["marketingOptions"] = [
		{"id": "none", "label": "None", "costCents": 0, "unitPercent": 100, "enabled": true, "reason": ""},
		{"id": "small", "label": "Small ad", "costCents": 5000, "unitPercent": 120, "enabled": false, "reason": "Need $50"},
		{"id": "big", "label": "Big ad", "costCents": 15000, "unitPercent": 150, "enabled": false, "reason": "Need $150"},
	]
	await _present("product", value)
	var price_low := _panel.find_child("Price_80", true, false) as Button
	var price_catalog := _panel.find_child("Price_100", true, false) as Button
	var price_high := _panel.find_child("Price_120", true, false) as Button
	_check(price_low != null and str(price_low.get_meta("cozy_variant", "")) == "secondary", "−20% price reads as secondary")
	_check(price_catalog != null and str(price_catalog.get_meta("cozy_variant", "")) == "secondary" and price_catalog.text == "Catalog", "Catalog price reads as secondary")
	_check(price_high != null and str(price_high.get_meta("cozy_variant", "")) == "secondary", "+20% price reads as secondary")
	_check(_panel.find_child("PriceEffect", true, false) != null, "The picker shows the price unit-effect line")
	var no_ad := _panel.find_child("Marketing_none", true, false) as Button
	var small_ad := _panel.find_child("Marketing_small", true, false) as Button
	var big_ad := _panel.find_child("Marketing_big", true, false) as Button
	_check(no_ad != null and not no_ad.disabled and str(no_ad.get_meta("cozy_variant", "")) == "secondary", "None reads as secondary")
	_check(small_ad != null and small_ad.disabled and str(small_ad.get_meta("cozy_variant", "")) == "secondary" and small_ad.text == "Small ad · Need $50", "Small ad is a disabled secondary action")
	_check(big_ad != null and big_ad.disabled and big_ad.text == "Big ad · Need $150", "Big ad shows Need $150")
	var marketing_line := _panel.find_child("MarketingEffect", true, false) as Label
	_check(marketing_line != null and marketing_line.text == "None · $0 · no extra units", "The picker shows the marketing cost line")
	_check(_panel.find_child("Focus_balanced", true, false) == null, "A payload without focus options draws no focus control")
	tycoon["focusOptions"] = [
		{"id": "balanced", "label": "Balanced", "stat": "", "bonus": 0},
		{"id": "design", "label": "Design", "stat": "design", "bonus": 1},
		{"id": "tech", "label": "Tech", "stat": "tech", "bonus": 1},
		{"id": "hype", "label": "Hype", "stat": "hype", "bonus": 1},
	]
	await _present("product", value)
	var focus_balanced := _panel.find_child("Focus_balanced", true, false) as Button
	var focus_design := _panel.find_child("Focus_design", true, false) as Button
	var focus_tech := _panel.find_child("Focus_tech", true, false) as Button
	var focus_hype := _panel.find_child("Focus_hype", true, false) as Button
	_check(focus_balanced != null and not focus_balanced.disabled and str(focus_balanced.get_meta("cozy_variant", "")) == "secondary" and focus_balanced.text == "Balanced", "Balanced reads as secondary")
	_check(focus_design != null and str(focus_design.get_meta("cozy_variant", "")) == "secondary" and focus_design.text == "Design", "Design reads as secondary")
	_check(focus_tech != null and focus_tech.text == "Tech", "Tech is on the focus row")
	_check(focus_hype != null and focus_hype.text == "Hype", "Hype is on the focus row")
	var focus_line := _panel.find_child("FocusEffect", true, false) as Label
	_check(focus_line != null and focus_line.text == "Balanced · no point bump", "The picker shows the focus line")
	var build := _panel.find_child("OnTheBuild", true, false) as Label
	_check(build != null and build.text == "On the build", "Balanced leaves the build line plain")
	var start := _button("Start development")
	_check(start != null and str(start.get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	_check(_button("Hire Mina") == null, "Hire stays off the product picker")
