class_name CompanyPanel
extends Control

signal action_requested(method: String, parameters: Dictionary)
signal milestone_requested(definition: Dictionary)
signal connection_requested
signal volume_changed(effects: float, ambience: float)

var state: Dictionary = {}
var day := 1
var effects_volume := 0.5
var ambience_volume := 0.2
var screen := "journey"
var busy := false
var _content: VBoxContainer
var _scroll: ScrollContainer
var _notice: Label
var _summary: Dictionary = {}
var _transition: Tween
var _frame: PanelContainer
var _pending_method := ""
var _pending_job_id := ""

func _ready() -> void:
	z_index = 20
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = GameFonts.interface_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(0.04, 0.035, 0.025, 0.65)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	_frame = PanelContainer.new()
	_frame.position = Vector2(284, 44)
	_frame.size = Vector2(712, 632)
	_frame.add_theme_stylebox_override("panel", NotebookSkin.parchment())
	add_child(_frame)
	var margin := MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	_frame.add_child(margin)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)
	OperationsSkin.style_scroll_container(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	_scroll.add_child(_content)
	hide()

func present(mode: String = "journey") -> void:
	screen = mode
	_scroll.scroll_vertical = 0
	show()
	_render()
	if _transition != null and _transition.is_valid(): _transition.kill()
	modulate.a = 0.0
	_transition = create_tween()
	_transition.tween_property(self, "modulate:a", 1.0, 0.14)

func update_state(value: Dictionary) -> void:
	state = value
	busy = false
	if visible and screen in ["journey", "title", "closing"]:
		_render()

func show_error(message: String) -> void:
	busy = false
	_render()
	_notice.text = message
	_notice.add_theme_color_override("font_color", JobPanel.ALERT_INK)

func show_summary(value: Dictionary) -> void:
	_summary = value
	present("summary")

func _clear() -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

func _label(value: String, heading: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 28 if heading else 16)
	label.add_theme_color_override("font_color", JobPanel.CHARCOAL)
	if heading:
		GameFonts.use_display(label)
	else:
		GameFonts.use_body(label)
	_content.add_child(label)
	return label

func _button(value: String, callback: Callable, primary: bool = false, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.disabled = not enabled or busy
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 20)
	GameFonts.use_display(button)
	button.add_theme_color_override("font_color", JobPanel.CHARCOAL)
	button.add_theme_color_override("font_hover_color", JobPanel.CHARCOAL)
	button.add_theme_color_override("font_pressed_color", JobPanel.CHARCOAL)
	button.add_theme_color_override("font_focus_color", JobPanel.CHARCOAL)
	button.add_theme_stylebox_override("normal", NotebookSkin.texture_style(NotebookSkin.TAB_VERMILION if primary else NotebookSkin.NAME_PLAQUE, Vector4(8, 8, 8, 8), Vector4(12, 6, 12, 6)))
	button.add_theme_stylebox_override("hover", button.get_theme_stylebox("normal") if primary else NotebookSkin.name_plaque())
	button.add_theme_stylebox_override("pressed", button.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("disabled", OperationsSkin.secondary_button("disabled"))
	button.add_theme_color_override("font_disabled_color", JobPanel.CHARCOAL)
	button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
	button.pressed.connect(callback)
	button.button_down.connect(_press_button.bind(button, true))
	button.button_up.connect(_press_button.bind(button, false))
	_content.add_child(button)
	return button

func _press_button(button: Button, pressed: bool) -> void:
	if button.has_meta("press_tween"):
		var old := button.get_meta("press_tween") as Tween
		if old != null and old.is_valid(): old.kill()
	button.pivot_offset = button.size * 0.5
	button.self_modulate = Color(0.9, 0.9, 0.9) if pressed else Color.WHITE
	var tween := button.create_tween()
	button.set_meta("press_tween", tween)
	tween.tween_property(button, "scale", Vector2.ONE * (0.98 if pressed else 1.0), 0.09)

func _request(method: String, params: Dictionary) -> void:
	if busy:
		return
	busy = true
	_pending_method = method
	_pending_job_id = str(params.get("jobId", ""))
	_render()
	_notice.text = "Evaluating your work…" if method == "milestone.evaluate" else "Saving your company…"
	action_requested.emit(method, params)

func _render() -> void:
	_clear()
	var company: Dictionary = state.get("company", {})
	if screen == "title":
		_label("STARTUP VALLEY", true)
		_label("A small office. A real idea. Your first company.")
		_label("Build a website, plan your launch, and prepare your company with real AI teammates.")
		var started := _company_started()
		_label("Connecting to your saved company…" if state.is_empty() else "Your progress is saved automatically." if started else "Start with a free first hire: Mina.")
		_button("CONTINUE" if started else "START COMPANY", _continue_game, true, not state.is_empty())
		if started: _button("NEW COMPANY", _confirm_start, false, not state.is_empty())
	elif screen == "confirm":
		_label("START A NEW COMPANY?", true)
		_label("Your current company, database, and files will be moved into a recoverable backup. Your AI connection stays saved.")
		_button("BACK UP + START NEW", func() -> void: _request("game.new", {"confirmed": true}), true)
		_button("GO BACK", func() -> void: present("title"))
	elif screen == "hired":
		_label("YOUR TEAM HAS GROWN", true)
		_label("A new desk is ready. Click your teammate in the office to walk over and talk, or click their desk to assign work.")
		_label("Use J or your founder desk to return to Journey. Your next milestone is listed there.")
		_button("MEET YOUR TEAM", hide, true)
	elif screen == "settings":
		_label("PAUSED", true)
		_label("The office clock is paused. Real AI work can still finish.")
		_button("RESUME", hide, true)
		_button("COMPANY JOURNEY", func() -> void: present("journey"))
		_button("CONNECT AI", func() -> void: hide(); connection_requested.emit())
		_button("TOGGLE FULLSCREEN", _toggle_fullscreen)
		_label("Effects volume")
		_slider(effects_volume, true)
		_label("Ambience volume")
		_slider(ambience_volume, false)
		_label("Move: WASD / arrows or click the floor. Click people and desks to interact. E: nearby chat. J: Journey. Escape: back / pause.")
		_button("TITLE SCREEN", func() -> void: present("title"))
	elif screen in ["summary", "closing"]:
		var summary: Dictionary = _summary if screen == "summary" else state.get("daySummary", {})
		_label("DAY %d %s" % [int(summary.get("day", day)), "COMPLETE" if screen == "summary" else "WRAP-UP"], true)
		_label("Earned $%.2f  ·  Reputation +%d\nAI spend recorded today: $%.4f" % [float(summary.get("earnedCents", 0)) / 100.0, int(summary.get("reputation", 0)), float(summary.get("aiSpend", 0.0))])
		for title: String in summary.get("completedWork", []): _label("Delivered: " + title)
		for entry: Dictionary in summary.get("entries", []):
			_label("Completed: " + str(entry.get("label", "Company progress")))
		_label("Tomorrow: " + str(summary.get("nextMilestone", "Your next chapter")))
		if screen == "summary":
			_label("Saved. Your team starts at 08:00.")
			_button("BEGIN NEXT DAY", hide, true)
		else:
			_label("Active AI work can finish after closing. Finish or cancel it before ending the day; queued work carries over.")
			_button("END DAY + SAVE", func() -> void: _request("day.end", {"day": day}), true)
			_button("REVIEW OFFICE", hide)
	else:
		_label("OFFICE CLOSED" if screen == "closing" else "COMPANY JOURNEY", true)
		_label("Day %d  ·  $%.2f cash  ·  %d reputation" % [day, float(company.get("cashCents", 0)) / 100.0, int(company.get("reputation", 0))])
		_label("Game economy only. AI usage is real. Ads and incorporation produce planning files, not external actions.")
		_label(_next_step())
		if int(company.get("chapter", 1)) > 1:
			_label("CHAPTER COMPLETE — YOUR COMPANY IS READY", true)
			_label("You built a website, planned a launch, and prepared your incorporation checklist. Keep creating with your team.")
		for candidate: Dictionary in state.get("candidates", []):
			if bool(candidate.get("hired", false)):
				continue
			_label("%s — %s" % [candidate.get("name", ""), candidate.get("role", "")], true)
			var candidate_id := str(candidate.get("id", ""))
			var price := float(candidate.get("costCents", 0)) / 100.0
			_button("HIRE %s · %s" % [str(candidate.get("name", "")).to_upper(), "FREE FIRST HIRE" if price == 0 else "$%.0f" % price], func() -> void: _request("hiring.complete", {"employeeId": candidate_id}), true, bool(candidate.get("available", false)) and int(company.get("cashCents", 0)) >= int(candidate.get("costCents", 0)))
		for definition: Dictionary in state.get("milestones", []):
			_milestone_card(definition)
		_label("End your planning day when you are ready. Tomorrow's milestone unlocks at 08:00; there is no need to wait for the clock.")
		_button("END DAY + SAVE", func() -> void: _request("day.end", {"day": day}))
		_button("BACK TO OFFICE", hide)
	_notice = _label("" if not busy else "Working…")
	# A single focus loop keeps keyboard navigation inside the active modal.
	var buttons: Array[Node] = _content.find_children("*", "Control", true, false)
	var enabled_buttons: Array[Control] = []
	for node: Node in buttons:
		if (node is Button and not (node as Button).disabled) or node is Slider:
			enabled_buttons.append(node as Control)
	for index: int in range(enabled_buttons.size()):
		var button := enabled_buttons[index]
		button.focus_next = button.get_path_to(enabled_buttons[(index + 1) % enabled_buttons.size()])
		button.focus_previous = button.get_path_to(enabled_buttons[(index + enabled_buttons.size() - 1) % enabled_buttons.size()])
	if not enabled_buttons.is_empty():
		call_deferred("_focus_first")

func _focus_first() -> void:
	if not visible: return
	for node: Node in _content.find_children("*", "Button", true, false):
		if not (node as Button).disabled:
			(node as Button).grab_focus()
			return

func _milestone_card(definition: Dictionary) -> void:
	var status := str(definition.get("state", "locked"))
	var reviewing := busy and _pending_method == "milestone.evaluate" and _pending_job_id == str(definition.get("jobId", ""))
	var evaluation: Dictionary = definition.get("evaluation", {}) if definition.get("evaluation") is Dictionary else {}
	var heading := "READY TO COMPLETE" if evaluation.get("verdict") == "ready" and status != "completed" else status.replace("_", " ").to_upper()
	if reviewing: heading = "EVALUATING"
	_label("%s  ·  %s" % [definition.get("title", ""), heading], true)
	if status == "locked":
		_label("Available from Day %d. Hire the required teammate and finish the preceding milestone." % int(definition.get("availableFromDay", 1)))
		return
	if status == "completed":
		_label("Completed with founder override" if bool(definition.get("overridden", false)) else "Completed and evaluated")
		return
	_label("Required: " + ", ".join(definition.get("files", [])))
	_label("Reward: $%.0f + %d reputation%s" % [float(definition.get("rewardCents", 0)) / 100, int(definition.get("reputation", 0)), " · $%.0f filing cost (in-game)" % (float(definition.get("feeCents", 0)) / 100) if int(definition.get("feeCents", 0)) > 0 else ""])
	var job_id := str(definition.get("jobId", ""))
	if not evaluation.is_empty():
		_label("Quality %.2f / 3 · %s" % [float(evaluation.get("score", 0)), evaluation.get("summary", "")])
		for criterion: Dictionary in evaluation.get("criteria", []):
			_label("%s: %d/3 — %s" % [criterion.get("name", ""), int(criterion.get("score", 0)), criterion.get("evidence", "")])
		if evaluation.get("verdict") == "ready":
			_button("COMPLETE MILESTONE", func() -> void: _request("milestone.complete", {"jobId": job_id}), true)
		else:
			_button("REVISE WORK", func() -> void: hide(); milestone_requested.emit(definition), true)
			_button("OVERRIDE · HALF REWARD, NO REPUTATION", func() -> void: _request("milestone.override", {"jobId": job_id}))
	elif definition.get("jobStatus") == "completed":
		_label(str(definition.get("evaluationError", "")))
		_button("EVALUATING YOUR WORK…" if reviewing else ("RETRY EVALUATION" if not str(definition.get("evaluationError", "")).is_empty() else "EVALUATE RESULT") + " · USES AI BUDGET", func() -> void: _request("milestone.evaluate", {"jobId": job_id}), true)
	elif str(definition.get("jobStatus", "")) in ["running", "queued"] or status == "evaluating":
		_label("Your teammate is working. Review live activity from the team rail.")
	else:
		var interrupted := str(definition.get("jobStatus", "")) in ["blocked", "failed", "cancelled"]
		if interrupted: _label("The previous work stopped. Its files are retained; resume them in a new bounded work order.")
		_button("RESUME RETAINED WORK" if interrupted else "PREPARE WORK ORDER", func() -> void: hide(); milestone_requested.emit(definition), true)

func _slider(value: float, effects: bool) -> void:
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size.y = 40
	slider.add_theme_stylebox_override("slider", OperationsSkin.horizontal_scroll_track())
	slider.add_theme_stylebox_override("grabber_area", OperationsSkin.horizontal_scroll_thumb())
	slider.add_theme_stylebox_override("grabber_area_highlight", OperationsSkin.horizontal_scroll_thumb())
	var thumb := AtlasTexture.new()
	thumb.atlas = OperationsSkin.SCROLL_H_THUMB
	thumb.region = Rect2(0, 0, mini(24, OperationsSkin.SCROLL_H_THUMB.get_width()), mini(24, OperationsSkin.SCROLL_H_THUMB.get_height()))
	slider.add_theme_icon_override("grabber", thumb)
	slider.add_theme_icon_override("grabber_highlight", thumb)
	slider.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
	slider.value_changed.connect(func(amount: float) -> void:
		if effects: effects_volume = amount
		else: ambience_volume = amount
		volume_changed.emit(effects_volume, ambience_volume)
	)
	_content.add_child(slider)

func _confirm_start() -> void:
	present("confirm")

func _toggle_fullscreen() -> void:
	get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func _continue_game() -> void:
	var hired := false
	for candidate: Dictionary in state.get("candidates", []):
		hired = hired or bool(candidate.get("hired", false))
	if hired: hide()
	else: present("journey")

func _company_started() -> bool:
	for candidate: Dictionary in state.get("candidates", []):
		if bool(candidate.get("hired", false)): return true
	return bool((state.get("player", {}) as Dictionary).get("movementSeen", false))

func _next_step() -> String:
	for candidate: Dictionary in state.get("candidates", []):
		if bool(candidate.get("available", false)) and not bool(candidate.get("hired", false)):
			return "NEXT · Hire %s, then meet them at their new desk." % candidate.get("name", "your teammate")
	for definition: Dictionary in state.get("milestones", []):
		if definition.get("state") == "completed": continue
		if definition.get("state") == "locked": return "NEXT · Today's goal is complete. Explore your office, review your files, then end the day when ready."
		if definition.get("jobStatus") == "completed": return "NEXT · Review your teammate's files in Activity, then evaluate the result below."
		if definition.get("jobStatus") in ["running", "queued"]: return "NEXT · Visit your teammate's desk to follow their work, give direction or answer an approval."
		return "NEXT · %s. Prepare the work order below; your teammate will deliver real files." % definition.get("title", "Build your company")
	return "NEXT · Your chapter is complete. Keep building with ordinary work orders and the shared Studio."

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if screen in ["title", "confirm"]: present("title")
		else: hide()
		get_viewport().set_input_as_handled()
