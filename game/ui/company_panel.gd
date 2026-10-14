class_name CompanyPanel
extends Control

signal action_requested(method: String, parameters: Dictionary)
signal milestone_requested(definition: Dictionary)
signal connection_requested
signal renovation_requested
signal volume_changed(effects: float, ambience: float)
signal architecture_theme_requested(theme_id: String)

var state: Dictionary = {}
var day := 1
var effects_volume := 0.5
var ambience_volume := 0.2
var architecture_theme := OfficeArchitecture.DEFAULT_THEME
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
var _pending_employee_id := ""
var _header: VBoxContainer
var _footer: VBoxContainer
var _preferred_focus: Button
var _details_open := false
var _future_open := false
var _render_generation := 0
var _maximum_panel_size := Vector2(744, 608)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 20
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = GameFonts.interface_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(0.04, 0.035, 0.025, 0.65)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	_frame = PanelContainer.new()
	_frame.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(24, 20, 24, 20)))
	add_child(_frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_frame.add_child(column)
	_header = VBoxContainer.new()
	_header.add_theme_constant_override("separation", 4)
	column.add_child(_header)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	CozyUI.scroll(_scroll)
	column.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	_scroll.add_child(_content)
	_footer = VBoxContainer.new()
	_footer.add_theme_constant_override("separation", 8)
	column.add_child(_footer)
	hide()

func present(mode: String = "journey") -> void:
	if mode == "journey" and _is_chapter_complete():
		mode = "complete"
	screen = mode
	_details_open = false
	_future_open = false
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
	if visible and screen == "journey" and _is_chapter_complete():
		present("complete")
		return
	if visible and screen in ["journey", "title", "closing", "complete"]: _render()

func show_error(message: String) -> void:
	busy = false
	_render()
	_notice.text = message
	_notice.tooltip_text = message
	_notice.add_theme_color_override("font_color", JobPanel.ALERT_INK)
	_notice.visible = not message.is_empty()

func show_summary(value: Dictionary) -> void:
	_summary = value
	present("summary")

func _clear() -> void:
	_preferred_focus = null
	for parent: Control in [_content, _header, _footer]:
		for child: Node in parent.get_children():
			parent.remove_child(child)
			child.queue_free()

func _label(value: String, heading: bool = false, parent: Control = null, role: String = "body") -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUI.label(label, "section" if heading else role)
	(parent if parent != null else _content).add_child(label)
	return label

func _button(value: String, callback: Callable, primary: bool = false, enabled: bool = true, parent: Control = null, variant: String = "") -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.disabled = not enabled or busy
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUI.button(button, variant if not variant.is_empty() else "primary" if primary else "secondary")
	if callback.is_valid(): button.pressed.connect(callback)
	(parent if parent != null else _content).add_child(button)
	return button

func _disclosure(value: String, callback: Callable, expanded: bool, parent: Control) -> Button:
	var button := _button(value, callback, false, true, parent, "quiet")
	CozyUI.disclosure(button, expanded)
	return button

func _card(parent: Control = null) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CozyUI.card(Vector4(16, 12, 16, 12)))
	(parent if parent != null else _content).add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 6)
	panel.add_child(contents)
	return contents

func _heading(title: String, subtitle: String = "", subtitle_role: String = "body") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_header.add_child(row)
	_label(title, false, row, "display")
	var close_button := Button.new()
	CozyUI.close(close_button)
	close_button.tooltip_text = "Back" if screen == "confirm" else "Back to office"
	close_button.pressed.connect(_back)
	close_button.visible = screen != "title"
	row.add_child(close_button)
	if not subtitle.is_empty(): _label(subtitle, false, _header, subtitle_role)

func _actions(primary_text: String, callback: Callable, enabled: bool = true, secondary_text: String = "Back to office", secondary_callback: Callable = Callable(), danger: bool = false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_footer.add_child(row)
	var secondary: Button
	if not secondary_text.is_empty():
		secondary = _button(secondary_text, secondary_callback if secondary_callback.is_valid() else hide, false, true, row, "quiet")
		# Evaluations continue outside the notebook. Keep its nonmutating exit
		# usable like the header close button without enabling another request.
		if screen == "journey" and _evaluation_pending() and not secondary_callback.is_valid():
			secondary.disabled = false
	if not primary_text.is_empty():
		var primary := _button(primary_text, callback, not danger, enabled, row, "danger" if danger else "primary")
		_preferred_focus = secondary if danger else primary
	elif secondary != null:
		_preferred_focus = secondary

func _request(method: String, params: Dictionary) -> void:
	if busy: return
	busy = true
	_pending_method = method
	_pending_job_id = str(params.get("jobId", ""))
	if method == "hiring.complete": _pending_employee_id = str(params.get("employeeId", ""))
	_render()
	action_requested.emit(method, params)

func _render() -> void:
	_render_generation += 1
	_clear()
	if screen == "journey" and _is_chapter_complete():
		screen = "complete"
	var panel_size := Vector2(744, 608)
	match screen:
		"title": panel_size = Vector2(624, 408)
		"confirm": panel_size = Vector2(616, 364)
		"hired": panel_size = Vector2(648, 424)
		"complete": panel_size = Vector2(664, 448)
		"settings": panel_size = Vector2(704, 592)
		"closing", "summary": panel_size = Vector2(744, 584)
		"journey":
			if _current_milestone().is_empty(): panel_size = Vector2(704, 564)
	_maximum_panel_size = panel_size
	_frame.custom_minimum_size = Vector2.ZERO
	_frame.size = panel_size
	_frame.position = ((Vector2(1280, 720) - panel_size) * 0.5).round()
	match screen:
		"title": _title_screen()
		"confirm": _confirm_screen()
		"hired": _hired_screen()
		"complete": _complete_screen()
		"settings": _settings_screen()
		"closing", "summary": _day_screen()
		_: _journey_screen()
	# Evaluation already has one durable status on its milestone card. An empty
	# footer row must not reserve a line and force otherwise short pages to scroll.
	_notice = _label("Saving your company…" if busy and not _evaluation_pending() else "", false, _footer)
	_notice.visible = not _notice.text.is_empty()
	_notice.max_lines_visible = 3
	_notice.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notice.mouse_filter = Control.MOUSE_FILTER_PASS
	call_deferred("_configure_focus")
	call_deferred("_fit_sparse_height", _render_generation)

func _fit_sparse_height(generation: int) -> void:
	# Wait for wrapped labels to resolve at the final width. The generation
	# prevents a superseded modal refresh from resizing the current screen.
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _render_generation or not is_inside_tree(): return
	# Review pages retain their envelope when evidence expands; scrolling then
	# leaves the header and primary action stationary. Only sparse states shrink.
	if _details_open or _future_open: return
	if screen == "journey" and not _evaluation(_current_milestone()).is_empty(): return
	var minimum_height := 360.0
	match screen:
		"confirm": minimum_height = 340.0
		"hired": minimum_height = 400.0
		"complete": minimum_height = 400.0
		"settings": minimum_height = 480.0
		"journey": minimum_height = 456.0
		"closing", "summary": minimum_height = 456.0
	var column := _header.get_parent() as VBoxContainer
	var required_height := _frame.get_theme_stylebox("panel").get_minimum_size().y
	required_height += _header.get_combined_minimum_size().y + _content.get_combined_minimum_size().y + _footer.get_combined_minimum_size().y
	required_height += column.get_theme_constant("separation") * 2 + 4
	_frame.size.y = clampf(ceilf(required_height), minimum_height, _maximum_panel_size.y)
	_frame.position = ((Vector2(1280, 720) - _frame.size) * 0.5).round()

func _title_screen() -> void:
	_heading("Startup Valley", "A small office. A real idea. Your first company.", "meta")
	var started := _company_started()
	var card := _card()
	_label("Your company is waiting" if started else "Your first chapter", true, card)
	if state.is_empty():
		_label("Connecting to your saved company…", false, card)
	elif started:
		var company: Dictionary = state.get("company", {})
		var names := PackedStringArray()
		for candidate: Dictionary in state.get("candidates", []):
			if bool(candidate.get("hired", false)): names.append(str(candidate.get("name", "Teammate")))
		_label("Day %d  ·  Chapter %d  ·  %s" % [day, int(company.get("chapter", 1)), ", ".join(names) if not names.is_empty() else "Founder"], false, card)
		_label(_next_step().trim_prefix("NEXT · "), false, card)
		_label("Progress saves automatically.", false, card, "meta")
	else:
		_label("Hire Mina, build a website, then grow your team. Your work becomes real files as your office comes to life.", false, card)
		_label("Mina is your free first hire.", false, card)
	_actions("Continue" if started else "Start company", _continue_game, not state.is_empty(), "New company" if started else "", _confirm_start)

func _confirm_screen() -> void:
	_heading("Start a new company?", "Your current company will leave this office.")
	_label("Your company database and project files will move into a recoverable, timestamped backup. Your AI connection stays saved.")
	_label("This starts a new journey with no hires or earned progress. Go back without changing anything.")
	_actions("Back up + start new", func() -> void: _request("game.new", {"confirmed": true}), true, "Go back", func() -> void: present("title"), true)

func _hired_screen() -> void:
	var hired: Dictionary = {}
	for candidate: Dictionary in state.get("candidates", []):
		if bool(candidate.get("hired", false)):
			hired = candidate
			if str(candidate.get("id", "")) == _pending_employee_id: break
	var person_name := str(hired.get("name", "Your teammate"))
	_heading("Welcome, " + person_name, "A new desk is ready in your office.")
	_person(hired, false)
	_label(_next_step().trim_prefix("NEXT · "))
	_label("Walk to %s or use the team rail. Their desk opens Assign with the current Journey goal ready." % person_name)
	_actions("Meet " + person_name, hide, true, "Company Journey", func() -> void: present("journey"))

func _complete_screen() -> void:
	_heading("Chapter complete", "Your first company chapter is finished.")
	var complete := _card()
	_label("Your company is ready", true, complete)
	_label("Website built. Ads planned. Incorporation prepared. Chapter 2 starts when you give the company a look.", false, complete)
	_label(_next_step().trim_prefix("NEXT · "))
	_actions("Begin Chapter 2", func() -> void: _request("chapter.continue", {}), true, "Back to office")

func _is_chapter_complete() -> bool:
	return chapter_is_complete(state)

static func chapter_is_complete(state: Dictionary) -> bool:
	if state.is_empty(): return false
	if int((state.get("company", {}) as Dictionary).get("chapter", 1)) <= 1: return false
	return open_milestone(state).is_empty() and available_candidate(state).is_empty()

func _settings_screen() -> void:
	_heading("Settings", "The office clock is paused. Real AI work can still finish.")
	var shortcuts := HBoxContainer.new()
	shortcuts.add_theme_constant_override("separation", 12)
	_content.add_child(shortcuts)
	_button("Company Journey", func() -> void: present("journey"), false, true, shortcuts)
	_button("Connect AI", func() -> void: hide(); connection_requested.emit(), false, true, shortcuts)
	_button("Renovate office", func() -> void: hide(); renovation_requested.emit(), false, true, shortcuts)
	var audio := _card()
	_label("Sound", true, audio)
	_slider(effects_volume, true, audio)
	_slider(ambience_volume, false, audio)
	var display := HBoxContainer.new()
	display.add_theme_constant_override("separation", 12)
	_content.add_child(display)
	_label("Display", true, display)
	_button("Switch to window" if get_window().mode == Window.MODE_FULLSCREEN else "Switch to fullscreen", _toggle_fullscreen, false, true, display)
	var look := HBoxContainer.new()
	look.add_theme_constant_override("separation", 12)
	_content.add_child(look)
	var look_label := _label("Office look", true, look)
	look_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	look_label.custom_minimum_size.x = 148
	var picker := OptionButton.new()
	picker.name = "ArchitectureTheme"
	picker.custom_minimum_size = Vector2(240, 44)
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.tooltip_text = "Oak office is the day-1 room. Cafe, Loft, Studio, and Evening swap the floor, walls, windows, trim, and doorway. They do not hire anyone or change the journey."
	CozyUI.dropdown(picker)
	var selected := -1
	for theme_id: String in OfficeArchitecture.THEME_ORDER:
		if not OfficeArchitecture.theme_available(theme_id): continue
		picker.add_item(OfficeArchitecture.theme_label(theme_id))
		picker.set_item_metadata(picker.item_count - 1, theme_id)
		if theme_id == architecture_theme: selected = picker.item_count - 1
	if picker.item_count == 0:
		picker.queue_free()
	else:
		picker.select(maxi(selected, 0))
		picker.item_selected.connect(func(index: int) -> void:
			architecture_theme_requested.emit(str(picker.get_item_metadata(index)))
		)
		look.add_child(picker)
	_label("Explore: WASD, arrows, or click the floor · E chat · J Journey.\nRenovate: M move · R rotate · U undo · Esc cancel or back.")
	_actions("Resume", hide, true, "Title screen", func() -> void: present("title"))

func set_architecture_theme(theme_id: String) -> void:
	architecture_theme = theme_id
	var picker := find_child("ArchitectureTheme", true, false) as OptionButton
	if picker == null: return
	for index: int in range(picker.item_count):
		if str(picker.get_item_metadata(index)) == theme_id:
			picker.select(index)
			return

func _slider(value: float, effects: bool, parent: Control = null) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size.y = 44
	(parent if parent != null else _content).add_child(row)
	var name_label := _label("Effects" if effects else "Ambience", false, row)
	name_label.custom_minimum_size.x = 100
	name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var slider := HSlider.new()
	slider.name = "EffectsSlider" if effects else "AmbienceSlider"
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(220, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUI.slider(slider)
	row.add_child(slider)
	var percentage := _label("%d%%" % roundi(value * 100), false, row, "action")
	percentage.name = "EffectsPercent" if effects else "AmbiencePercent"
	percentage.custom_minimum_size.x = 52
	percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percentage.size_flags_horizontal = Control.SIZE_SHRINK_END
	slider.value_changed.connect(func(amount: float) -> void:
		if effects: effects_volume = amount
		else: ambience_volume = amount
		percentage.text = "%d%%" % roundi(amount * 100)
		volume_changed.emit(effects_volume, ambience_volume)
	)

func _day_screen() -> void:
	var summary: Dictionary = _summary if screen == "summary" else state.get("daySummary", {})
	_heading("Day %d %s" % [int(summary.get("day", day)), "complete" if screen == "summary" else "wrap-up"], "Saved. Your team starts at 08:00." if screen == "summary" else "Take stock before the next office day.")
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 12)
	_content.add_child(metrics)
	_metric(metrics, "Game revenue", "$%s" % _money(int(summary.get("earnedCents", 0))), "virtual company funds")
	_metric(metrics, "Reputation", "+%d" % int(summary.get("reputation", 0)), "company progress")
	_metric(metrics, "Real AI spend", "$%.4f" % float(summary.get("aiSpend", 0)), "real money (USD)")
	var activity := _card()
	_label("Today’s work", true, activity)
	var seen := PackedStringArray()
	for title: String in summary.get("completedWork", []):
		_label("Delivered · " + title, false, activity)
		seen.append(title)
	for entry: Dictionary in summary.get("entries", []):
		var value := str(entry.get("label", "Company progress"))
		if not seen.has(value): _label(value, false, activity)
	if seen.is_empty() and (summary.get("entries", []) as Array).is_empty():
		_label("A planning day. Your next step is ready for tomorrow.", false, activity)
	_label("Tomorrow · " + str(summary.get("nextMilestone", "Your next chapter")), true)
	if screen == "summary":
		_actions("Begin next day", hide, true, "")
	else:
		_label("Active AI work can finish after closing. Finish or cancel it before ending the day; queued work carries over.", false, _footer)
		_actions("End day + save", func() -> void: _request("day.end", {"day": day}), true, "Review office")

func _metric(parent: Control, title: String, value: String, detail: String) -> void:
	var contents := _card(parent)
	(contents.get_parent() as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(title, false, contents, "meta")
	_label(value, false, contents, "numeric")
	_label(detail, false, contents, "meta")

func _money(cents: int) -> String:
	var integer := str(absi(cents) / 100)
	var grouped := ""
	for index: int in range(integer.length()):
		if index > 0 and (integer.length() - index) % 3 == 0: grouped += ","
		grouped += integer[index]
	return ("-" if cents < 0 else "") + grouped + ".%02d" % (absi(cents) % 100)

func _journey_screen() -> void:
	var company: Dictionary = state.get("company", {})
	_heading("Company Journey", "Day %d  ·  $%s game cash  ·  %d reputation" % [day, _money(int(company.get("cashCents", 0))), int(company.get("reputation", 0))], "meta")
	var next := _label(_next_step().trim_prefix("NEXT · "), false, null, "action")
	next.name = "NextStep"
	var definition := _current_milestone()
	var candidate := _available_candidate()
	if not definition.is_empty():
		_milestone_card(definition)
		_milestone_actions(definition)
	elif not candidate.is_empty():
		_person(candidate, true)
		var candidate_id := str(candidate.get("id", ""))
		var affordable := int(company.get("cashCents", 0)) >= int(candidate.get("costCents", 0))
		_actions("Hire %s · %s" % [candidate.get("name", "teammate"), "free" if int(candidate.get("costCents", 0)) == 0 else "$" + _money(int(candidate.get("costCents", 0)))], func() -> void: _request("hiring.complete", {"employeeId": candidate_id}), affordable)
	else:
		var ready := _card()
		_label("A good place to pause", true, ready)
		_label("Today’s goal is complete. Review your files or begin the next office day when you are ready.", false, ready)
		_actions("End day + save", func() -> void: _request("day.end", {"day": day}))
	var future_count := 0
	for item: Dictionary in state.get("milestones", []):
		if str(item.get("id", "")) != str(definition.get("id", "")): future_count += 1
	for item: Dictionary in state.get("candidates", []):
		if not bool(item.get("hired", false)) and str(item.get("id", "")) != str(candidate.get("id", "")): future_count += 1
	var utilities := HBoxContainer.new()
	utilities.add_theme_constant_override("separation", 12)
	_content.add_child(utilities)
	if future_count > 0:
		_disclosure(("Hide" if _future_open else "Show") + " chapter roadmap", _toggle_future, _future_open, utilities)
		if _future_open: _roadmap(definition, candidate)
	if not definition.is_empty() or not candidate.is_empty():
		_button("End day + save", func() -> void: _request("day.end", {"day": day}), false, true, utilities, "secondary")
	var money_note := _label("Game cash is virtual; AI spend is real money (USD). Ads and incorporation create planning files only.")
	money_note.name = "MoneyExplanation"

func _person(candidate: Dictionary, hiring: bool) -> void:
	var card := _card()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var portrait := TextureRect.new()
	portrait.name = "HirePortrait"
	portrait.texture = CharacterArt.bust_portrait(str(candidate.get("id", "mira")))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(96, 116)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 8)
	row.add_child(identity)
	_label(str(candidate.get("name", "Your teammate")), true, identity)
	_label(str(candidate.get("role", "Your new teammate")), false, identity)
	if hiring:
		_label("Free onboarding hire" if int(candidate.get("costCents", 0)) == 0 else "$%s from game cash" % _money(int(candidate.get("costCents", 0))), false, identity, "action")
		_label("A teammate and a new workstation for your office.", false, identity)
	else:
		_label("Hired · ready to meet you", false, identity, "meta")

func _milestone_card(definition: Dictionary) -> void:
	var card := _card()
	card.name = "CurrentMilestone"
	_label(str(definition.get("title", "Company milestone")), true, card)
	_label(_milestone_status(definition), false, card, "action")
	var evaluation := _evaluation(definition)
	if not evaluation.is_empty():
		_label("Quality %.2f / 3" % float(evaluation.get("score", 0)), false, card, "meta")
		_label(str(evaluation.get("summary", "Your review is ready.")), false, card)
	else:
		var failure := str(definition.get("evaluationError", ""))
		if not failure.is_empty(): _label("Evaluation could not finish: " + failure + " Your work is saved.", false, card)
		elif str(definition.get("jobStatus", "")) in ["blocked", "failed", "cancelled"]:
			_label("The previous work stopped. Its files are retained for your next work order.", false, card)
		else: _label(("Files · " if _evaluation_pending() else "Deliver · ") + ", ".join(definition.get("files", [])), false, card)
	_label("Reward · $%s game revenue + %d reputation%s" % [_money(int(definition.get("rewardCents", 0))), int(definition.get("reputation", 0)), " · $%s in-game filing fee" % _money(int(definition.get("feeCents", 0))) if int(definition.get("feeCents", 0)) > 0 else ""], false, card, "meta")
	if not evaluation.is_empty():
		_disclosure(("Hide" if _details_open else "Review") + " criterion evidence", _toggle_details, _details_open, card)
		if _details_open:
			for criterion: Dictionary in evaluation.get("criteria", []):
				_label("%s · %d / 3" % [criterion.get("name", "Criterion"), int(criterion.get("score", 0))], false, card, "action")
				_label(str(criterion.get("evidence", "")), false, card)
			_label("Required files · " + ", ".join(definition.get("files", [])), false, card)
		if evaluation.get("verdict") != "ready":
			_button("Override · half reward, no reputation", func() -> void: _request("milestone.override", {"jobId": str(definition.get("jobId", ""))}), false, true, card, "danger")

func _milestone_actions(definition: Dictionary) -> void:
	var evaluation := _evaluation(definition)
	var job_id := str(definition.get("jobId", ""))
	if str(definition.get("state", "")) == "evaluating" or (busy and _pending_method == "milestone.evaluate" and _pending_job_id == job_id):
		_actions("Evaluate result", Callable(), false)
	elif not evaluation.is_empty():
		if evaluation.get("verdict") == "ready":
			_actions("Complete milestone", func() -> void: _request("milestone.complete", {"jobId": job_id}))
		else:
			_actions("Revise work", func() -> void: hide(); milestone_requested.emit(definition))
	elif str(definition.get("state", "")) == "revision_required":
		_actions("Revise work", func() -> void: hide(); milestone_requested.emit(definition))
	elif definition.get("jobStatus") == "completed":
		_label("Evaluation uses your real AI budget (up to 3,000 tokens).", false, _footer)
		_actions("Retry evaluation" if not str(definition.get("evaluationError", "")).is_empty() else "Evaluate result", func() -> void: _request("milestone.evaluate", {"jobId": job_id}))
	elif str(definition.get("jobStatus", "")) in ["running", "queued"]:
		_actions("Return to team", hide, true, "")
	else:
		var interrupted := str(definition.get("jobStatus", "")) in ["blocked", "failed", "cancelled"]
		_actions("Resume retained work" if interrupted else "Prepare work order", func() -> void: hide(); milestone_requested.emit(definition))

func _roadmap(current: Dictionary, candidate: Dictionary) -> void:
	var contents := _card()
	_label("Chapter roadmap", true, contents)
	for definition: Dictionary in state.get("milestones", []):
		if str(definition.get("id", "")) == str(current.get("id", "")): continue
		_label(str(definition.get("title", "Milestone")) + " · " + _milestone_status(definition), false, contents)
		if definition.get("state") == "locked": _label("From Day %d, after the preceding goal and required hire." % int(definition.get("availableFromDay", 1)), false, contents, "meta")
	for item: Dictionary in state.get("candidates", []):
		if bool(item.get("hired", false)) or str(item.get("id", "")) == str(candidate.get("id", "")): continue
		_label(str(item.get("name", "Teammate")) + " · " + ("Ready to hire" if item.get("available", false) else "Future teammate"), false, contents)

func _toggle_details() -> void:
	_details_open = not _details_open
	_render()

func _toggle_future() -> void:
	_future_open = not _future_open
	_render()

func _evaluation(definition: Dictionary) -> Dictionary:
	return definition.get("evaluation", {}) if definition.get("evaluation") is Dictionary else {}

func _evaluation_pending() -> bool:
	var definition := _current_milestone()
	return str(definition.get("state", "")) == "evaluating" or (busy and _pending_method == "milestone.evaluate" and _pending_job_id == str(definition.get("jobId", "")))

func _milestone_status(definition: Dictionary) -> String:
	var status := str(definition.get("state", "locked"))
	if status == "completed": return "Completed with founder override" if bool(definition.get("overridden", false)) else "Completed"
	if status == "evaluating" or (busy and _pending_method == "milestone.evaluate" and _pending_job_id == str(definition.get("jobId", ""))): return "Evaluating"
	var evaluation := _evaluation(definition)
	if evaluation.get("verdict") == "ready": return "Ready to complete"
	if not evaluation.is_empty() or status == "revision_required": return "Revision needed"
	match str(definition.get("jobStatus", "")):
		"completed": return "Delivered · ready for evaluation"
		"queued": return "Queued · waiting for work hours"
		"running": return "Work in progress"
		"failed", "blocked", "cancelled": return "Work interrupted"
	return status.replace("_", " ").capitalize()

func _current_milestone() -> Dictionary:
	return open_milestone(state)

func _available_candidate() -> Dictionary:
	return available_candidate(state)

func _next_step() -> String:
	return next_step_line(state, busy, _pending_method, _pending_job_id)

static func next_step_line(state: Dictionary, busy: bool = false, pending_method: String = "", pending_job_id: String = "") -> String:
	if state.is_empty() or ((state.get("milestones", []) as Array).is_empty() and (state.get("candidates", []) as Array).is_empty()):
		return ""
	var definition := open_milestone(state)
	if not definition.is_empty():
		var evaluation: Dictionary = definition.get("evaluation", {}) if definition.get("evaluation") is Dictionary else {}
		if definition.get("state") == "evaluating" or (busy and pending_method == "milestone.evaluate" and pending_job_id == str(definition.get("jobId", ""))):
			return "NEXT · Your completed files are saved. You can close this notebook and return to the office."
		if evaluation.get("verdict") == "ready": return "NEXT · Your review passed. Complete the milestone to claim its reward."
		if not evaluation.is_empty() or definition.get("state") == "revision_required": return "NEXT · Revise the work using the review below, then evaluate the new result."
		if definition.get("jobStatus") == "completed": return "NEXT · Preview the files in Activity, Add to Studio, then evaluate the result."
		if definition.get("jobStatus") == "queued": return "NEXT · Your work order is queued. It will start during office work hours."
		if definition.get("jobStatus") == "running": return "NEXT · Follow work, give direction, or answer an approval in your teammate’s Activity."
		if str(definition.get("id", "")) == "website":
			return "NEXT · Open Assign and choose Journey · Build a website, then send the work order."
		if str(definition.get("id", "")) == "brand":
			return "NEXT · Chapter 2 · Open Assign and choose Journey · Design the brand, then send the work order."
		return "NEXT · %s. Prepare a work order for your teammate." % definition.get("title", "Build your company")
	var candidate := available_candidate(state)
	if not candidate.is_empty():
		if str(candidate.get("id", "")) == "creative":
			return "NEXT · Chapter 2 · Give the company a look. Hire Creative, then prepare the brand identity work order."
		return "NEXT · Hire %s from Company Journey, then meet them at their new desk." % candidate.get("name", "your teammate")
	if chapter_is_complete(state):
		return "NEXT · Your chapter is complete. Keep building with ordinary work orders and the shared Studio."
	for item: Dictionary in state.get("milestones", []):
		if item.get("state") == "locked": return "NEXT · Today’s goal is complete. Review your files, then end the day when ready."
	return "NEXT · Your chapter is complete. Keep building with ordinary work orders and the shared Studio."

static func open_milestone(state: Dictionary) -> Dictionary:
	for definition: Dictionary in state.get("milestones", []):
		if str(definition.get("state", "locked")) not in ["locked", "completed"]: return definition
	return {}

static func available_candidate(state: Dictionary) -> Dictionary:
	for candidate: Dictionary in state.get("candidates", []):
		if bool(candidate.get("available", false)) and not bool(candidate.get("hired", false)): return candidate
	return {}

static func station_caption(state: Dictionary, station_id: String, kind: String, owner_id: String, has_active_job: bool, has_approval: bool, has_delivery: bool) -> String:
	match station_id:
		"founder-workstation":
			var milestone := open_milestone(state)
			var evaluation: Dictionary = milestone.get("evaluation", {}) if milestone.get("evaluation") is Dictionary else {}
			if evaluation.get("verdict") == "ready": return "Claim reward"
			if not evaluation.is_empty() or str(milestone.get("state", "")) == "revision_required": return "Revise work"
			if str(milestone.get("jobStatus", "")) == "completed": return "Evaluate result"
			# The website work order is the day-1 goal. An optional later hire must not replace it.
			if str(milestone.get("id", "")) == "website" and str(milestone.get("jobStatus", "")) not in ["running", "queued"]: return "Assign website"
			if str(milestone.get("id", "")) == "brand" and str(milestone.get("jobStatus", "")) not in ["running", "queued", "completed"]: return "Assign brand"
			var candidate := available_candidate(state)
			if not candidate.is_empty():
				var hire_name := str(candidate.get("name", "")).strip_edges()
				return "Hire %s" % hire_name if not hire_name.is_empty() else "Company Journey"
			if milestone.is_empty(): return "Company Journey"
			return "Company Journey"
		"artifact-archive":
			return "Studio"
		"approval-console":
			return "Review approval" if has_approval else "Activity"
		_:
			if kind != "desk" or owner_id.is_empty(): return ""
			if has_approval: return "Review approval"
			if has_delivery: return "Add to Studio"
			if has_active_job: return "Activity"
			var milestone := open_milestone(state)
			if str(milestone.get("employeeId", "")) == owner_id and str(milestone.get("state", "")) in ["available", "revision_required"] and str(milestone.get("jobStatus", "")) not in ["running", "queued", "completed"]:
				if str(milestone.get("id", "")) == "website": return "Assign website"
				if str(milestone.get("id", "")) == "brand": return "Assign brand"
			return "Assign"

func _configure_focus() -> void:
	if not visible: return
	var controls: Array[Control] = []
	for node: Node in _frame.find_children("*", "Control", true, false):
		if node is Button and not (node as Button).disabled and (node as Button).is_visible_in_tree(): controls.append(node as Control)
		elif node is Slider and (node as Slider).is_visible_in_tree(): controls.append(node as Control)
	for index: int in range(controls.size()):
		controls[index].focus_next = controls[index].get_path_to(controls[(index + 1) % controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index + controls.size() - 1) % controls.size()])
	if is_instance_valid(_preferred_focus) and not _preferred_focus.disabled: _preferred_focus.grab_focus()
	elif not controls.is_empty(): controls[0].grab_focus()

func _focus_first() -> void:
	_configure_focus()

func _confirm_start() -> void:
	present("confirm")

func _toggle_fullscreen() -> void:
	get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	_render()

func _continue_game() -> void:
	for candidate: Dictionary in state.get("candidates", []):
		if bool(candidate.get("hired", false)):
			hide()
			return
	present("journey")

func _company_started() -> bool:
	for candidate: Dictionary in state.get("candidates", []):
		if bool(candidate.get("hired", false)): return true
	return bool((state.get("player", {}) as Dictionary).get("movementSeen", false))

func _back() -> void:
	if screen in ["title", "confirm"]: present("title")
	else: hide()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()
