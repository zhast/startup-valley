class_name JobPanel
extends PanelContainer

signal key_submitted(key: String)
signal chat_history_requested(employee_id: String)
signal chat_submitted(employee_id: String, message: String)
signal assignment_submitted(employee_id: String, title: String, assignment: String, acceptance_criteria: PackedStringArray, attached_studio_path: String)
signal cancel_requested(job_id: String)
signal steer_submitted(job_id: String, message: String)
signal approval_decided(job_id: String, approval_id: String, approved: bool)
signal artifact_open_requested(job_id: String, relative_path: String)
signal artifact_refresh_requested(job_id: String)
signal studio_open_requested(relative_path: String)
signal promotion_decided(job_id: String, approved: bool)

const VERMILION := Color("fa4616")
const OFF_WHITE := Color("f1f1f1")
const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const CERULEAN := Color("6196c1")
const CHARTREUSE := Color("c1fa81")
const DUST := Color("b6b5b0")
const WHITE := Color("ffffff")

const CANNED_JOBS := [
	{
		"title": "Inventory keyboard navigation design note",
		"employee_id": "mira",
		"assignment": "Write a one-page design note for inventory keyboard navigation into design-note.md. Cover focus entry, Tab and Shift+Tab order, arrow-key movement, selection, Escape behavior, visible focus, and acceptance checks.",
		"criteria": ["design-note.md exists", "The note is approximately one page", "Keyboard behavior and acceptance checks are explicit"],
	},
	{
		"title": "Review Mina's inventory note",
		"employee_id": "theo",
		"assignment": "Read Mina's durable studio file at studio/design-note.md. Review its inventory keyboard navigation choices, identify strengths and gaps, and write a concise review into review.md for promotion back into the studio.",
		"criteria": ["review.md exists", "The review cites Mina's design choices", "The review identifies concrete strengths and gaps"],
	},
]

var _employees: Array[EmployeeRecord] = []
var _team_buttons: Dictionary[String, Button] = {}
var _selected_employee_id: String = ""
var _active_employee_id: String = ""
var _last_chat_prompt: String = ""
var _chat_pending: bool = false

var _employee_name: Label
var _employee_meta: Label
var _tabs: TabContainer
var _chat_log: RichTextLabel
var _chat_input: LineEdit
var _chat_send_button: Button
var _make_job_button: Button
var _job_picker: OptionButton
var _custom_title_input: LineEdit
var _attachment_label: Label
var _attachment_picker: OptionButton
var _key_input: LineEdit
var _key_status: Label
var _assignment_preview: TextEdit
var _assign_button: Button
var _cancel_button: Button
var _steer_box: VBoxContainer
var _steer_input: LineEdit
var _steer_button: Button
var _status_label: Label
var _usage_label: Label
var _spend_label: Label
var _last_status_label: Label
var _event_log: RichTextLabel
var _artifact_list: VBoxContainer
var _approval_box: VBoxContainer
var _approval_label: Label
var _approval_job_id: String = ""
var _approval_id: String = ""
var _active_job_id: String = ""
var _promotion_box: VBoxContainer
var _promotion_label: Label
var _promotion_job_id: String = ""
var _clock_phase: String = "work"
var _custom_mode: bool = false
var _spend_warning: float = 5.0
var _active_job_running: bool = false

func _ready() -> void:
	_build_interface()

func _build_interface() -> void:
	add_theme_stylebox_override("panel", _stylebox(CHARCOAL, VERMILION, 2, 10))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var shell := HBoxContainer.new()
	shell.add_theme_constant_override("separation", 10)
	margin.add_child(shell)
	shell.add_child(_build_team_rail())
	var divider := VSeparator.new()
	divider.add_theme_color_override("separator", Color("383838"))
	shell.add_child(divider)
	var drawer := _build_employee_drawer()
	drawer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(drawer)

func _build_team_rail() -> VBoxContainer:
	var rail := VBoxContainer.new()
	rail.custom_minimum_size = Vector2(78.0, 0.0)
	rail.add_theme_constant_override("separation", 8)
	var brand := Label.new()
	brand.text = "SV"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 22)
	brand.add_theme_color_override("font_color", VERMILION)
	rail.add_child(brand)
	var caption := Label.new()
	caption.text = "TEAM"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", DUST)
	rail.add_child(caption)
	var team_scroll := ScrollContainer.new()
	team_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	team_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_child(team_scroll)
	var team_list := VBoxContainer.new()
	team_list.name = "TeamList"
	team_list.add_theme_constant_override("separation", 8)
	team_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_scroll.add_child(team_list)
	var hint := Label.new()
	hint.text = "talk\nassign\ndeliver"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color("777777"))
	rail.add_child(hint)
	return rail

func _build_employee_drawer() -> VBoxContainer:
	var drawer := VBoxContainer.new()
	drawer.add_theme_constant_override("separation", 7)
	var eyebrow := Label.new()
	eyebrow.text = "STARTUP VALLEY  /  OFFICE LINE"
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", CERULEAN)
	drawer.add_child(eyebrow)
	_employee_name = Label.new()
	_employee_name.text = "Your team"
	_employee_name.add_theme_font_size_override("font_size", 22)
	_employee_name.add_theme_color_override("font_color", OFF_WHITE)
	drawer.add_child(_employee_name)
	_employee_meta = Label.new()
	_employee_meta.text = "Select an employee to start"
	_employee_meta.add_theme_font_size_override("font_size", 11)
	_employee_meta.add_theme_color_override("font_color", CHARTREUSE)
	drawer.add_child(_employee_meta)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_color_override("font_selected_color", VERMILION)
	drawer.add_child(_tabs)
	_tabs.add_child(_build_chat_tab())
	_tabs.add_child(_build_work_tab())
	_tabs.add_child(_build_journal_tab())
	_tabs.add_child(_build_studio_tab())
	return drawer

func _tab_scroll(name_value: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = name_value
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return scroll

func _tab_content(scroll: ScrollContainer) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(334.0, 0.0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	return content

func _build_chat_tab() -> VBoxContainer:
	var tab := VBoxContainer.new()
	tab.name = "Chat"
	tab.add_theme_constant_override("separation", 8)
	_chat_log = RichTextLabel.new()
	_chat_log.bbcode_enabled = true
	_chat_log.fit_content = false
	_chat_log.scroll_active = true
	_chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_log.add_theme_font_size_override("normal_font_size", 13)
	_chat_log.append_text("[color=#b6b5b0]Choose a teammate from the rail.[/color]")
	tab.add_child(_chat_log)
	_make_job_button = Button.new()
	_make_job_button.text = "Turn my last message into a work order →"
	_make_job_button.disabled = true
	_make_job_button.pressed.connect(_make_last_chat_a_job)
	tab.add_child(_make_job_button)
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	tab.add_child(input_row)
	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Talk through an idea…"
	_chat_input.max_length = 2000
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.text_submitted.connect(_submit_chat_text)
	input_row.add_child(_chat_input)
	_chat_send_button = Button.new()
	_chat_send_button.text = "Chat"
	_chat_send_button.pressed.connect(_submit_chat)
	_chat_send_button.add_theme_stylebox_override("normal", _stylebox(VERMILION, VERMILION, 1, 5))
	_chat_send_button.add_theme_color_override("font_color", WHITE)
	input_row.add_child(_chat_send_button)
	return tab

func _build_work_tab() -> ScrollContainer:
	var scroll := _tab_scroll("Work")
	var content := _tab_content(scroll)
	content.add_child(_section_label("OPENROUTER"))
	var key_row := HBoxContainer.new()
	key_row.add_theme_constant_override("separation", 6)
	content.add_child(key_row)
	_key_input = LineEdit.new()
	_key_input.secret = true
	_key_input.placeholder_text = "Paste key once"
	_key_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_row.add_child(_key_input)
	var save_key_button := Button.new()
	save_key_button.text = "Save"
	save_key_button.pressed.connect(_submit_key)
	key_row.add_child(save_key_button)
	_key_status = Label.new()
	_key_status.text = "Checking OS keychain…"
	_key_status.add_theme_font_size_override("font_size", 10)
	_key_status.add_theme_color_override("font_color", DUST)
	content.add_child(_key_status)
	content.add_child(_section_label("WORK ORDER"))
	_job_picker = OptionButton.new()
	_job_picker.fit_to_longest_item = false
	_job_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for job: Dictionary in CANNED_JOBS:
		_job_picker.add_item(str(job.get("title", "Work order")))
	_job_picker.add_item("Custom work order…")
	_job_picker.item_selected.connect(_on_job_selected)
	content.add_child(_job_picker)
	_custom_title_input = LineEdit.new()
	_custom_title_input.placeholder_text = "Work-order title"
	_custom_title_input.max_length = 200
	_custom_title_input.visible = false
	content.add_child(_custom_title_input)
	_assignment_preview = TextEdit.new()
	_assignment_preview.editable = false
	_assignment_preview.custom_minimum_size = Vector2(0.0, 122.0)
	_assignment_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_child(_assignment_preview)
	_attachment_label = _section_label("READ CONTEXT (OPTIONAL)")
	_attachment_label.visible = false
	content.add_child(_attachment_label)
	_attachment_picker = OptionButton.new()
	_attachment_picker.fit_to_longest_item = false
	_attachment_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_picker.visible = false
	_attachment_picker.add_item("No studio file attached")
	_attachment_picker.set_item_metadata(0, "")
	content.add_child(_attachment_picker)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	content.add_child(action_row)
	_assign_button = Button.new()
	_assign_button.text = "Assign real work"
	_assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_assign_button.pressed.connect(_submit_assignment)
	_assign_button.add_theme_stylebox_override("normal", _stylebox(VERMILION, VERMILION, 1, 5))
	_assign_button.add_theme_color_override("font_color", WHITE)
	action_row.add_child(_assign_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_active_job)
	action_row.add_child(_cancel_button)
	_on_job_selected(0)
	return scroll

func _build_journal_tab() -> ScrollContainer:
	var scroll := _tab_scroll("Journal")
	var content := _tab_content(scroll)
	_status_label = Label.new()
	_status_label.text = "Worker starting…"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.max_lines_visible = 5
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.add_theme_color_override("font_color", OFF_WHITE)
	content.add_child(_status_label)
	_usage_label = Label.new()
	_usage_label.text = "Tokens  0 in / 0 out  ·  cost $0.0000"
	_usage_label.add_theme_font_size_override("font_size", 10)
	_usage_label.add_theme_color_override("font_color", DUST)
	content.add_child(_usage_label)
	_spend_label = Label.new()
	_spend_label.text = "Today  $0.0000"
	_spend_label.add_theme_font_size_override("font_size", 10)
	_spend_label.add_theme_color_override("font_color", DUST)
	content.add_child(_spend_label)
	_last_status_label = Label.new()
	_last_status_label.text = "Last work order  ·  none yet"
	_last_status_label.add_theme_font_size_override("font_size", 10)
	_last_status_label.add_theme_color_override("font_color", DUST)
	_last_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(_last_status_label)
	_approval_box = VBoxContainer.new()
	_approval_box.visible = false
	_approval_label = Label.new()
	_approval_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_approval_box.add_child(_approval_label)
	var approval_buttons := HBoxContainer.new()
	var approve_button := Button.new()
	approve_button.text = "Approve"
	approve_button.pressed.connect(_decide_approval.bind(true))
	approval_buttons.add_child(approve_button)
	var deny_button := Button.new()
	deny_button.text = "Deny"
	deny_button.pressed.connect(_decide_approval.bind(false))
	approval_buttons.add_child(deny_button)
	_approval_box.add_child(approval_buttons)
	content.add_child(_approval_box)
	_promotion_box = VBoxContainer.new()
	_promotion_box.visible = false
	_promotion_label = Label.new()
	_promotion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_promotion_box.add_child(_promotion_label)
	var promotion_buttons := HBoxContainer.new()
	var promote_button := Button.new()
	promote_button.text = "Add to studio"
	promote_button.pressed.connect(_decide_promotion.bind(true))
	promotion_buttons.add_child(promote_button)
	var discard_button := Button.new()
	discard_button.text = "Discard"
	discard_button.pressed.connect(_decide_promotion.bind(false))
	promotion_buttons.add_child(discard_button)
	_promotion_box.add_child(promotion_buttons)
	content.add_child(_promotion_box)
	_steer_box = VBoxContainer.new()
	_steer_box.visible = false
	_steer_box.add_child(_section_label("UPDATE ACTIVE JOB"))
	var steer_row := HBoxContainer.new()
	_steer_box.add_child(steer_row)
	_steer_input = LineEdit.new()
	_steer_input.placeholder_text = "Add a correction or constraint"
	_steer_input.max_length = 2000
	_steer_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_steer_input.text_submitted.connect(_submit_steer_text)
	steer_row.add_child(_steer_input)
	_steer_button = Button.new()
	_steer_button.text = "Send"
	_steer_button.pressed.connect(_submit_steer)
	steer_row.add_child(_steer_button)
	content.add_child(_steer_box)
	content.add_child(_section_label("LIVE ACTIVITY"))
	_event_log = RichTextLabel.new()
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.scroll_active = true
	_event_log.custom_minimum_size = Vector2(0.0, 220.0)
	content.add_child(_event_log)
	return scroll

func _build_studio_tab() -> ScrollContainer:
	var scroll := _tab_scroll("Studio")
	var content := _tab_content(scroll)
	var intro := Label.new()
	intro.text = "Deliveries become durable only after you add them to the studio. Future employees can use approved files."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", DUST)
	content.add_child(intro)
	_artifact_list = VBoxContainer.new()
	_artifact_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_artifact_list)
	var empty := Label.new()
	empty.text = "Approved files will appear here."
	empty.add_theme_color_override("font_color", Color("777777"))
	_artifact_list.add_child(empty)
	return scroll

func _section_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", CERULEAN)
	return label

func _stylebox(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _team_list() -> VBoxContainer:
	return find_child("TeamList", true, false) as VBoxContainer

func configure_employees(records: Array[EmployeeRecord]) -> void:
	_employees = records
	var list := _team_list()
	for child: Node in list.get_children():
		child.queue_free()
	_team_buttons.clear()
	for record: EmployeeRecord in records:
		var button := Button.new()
		button.text = "%s\n%s" % [record.display_name.left(1).to_upper(), record.display_name.to_upper()]
		button.tooltip_text = "Talk with %s" % record.display_name
		button.custom_minimum_size = Vector2(70.0, 64.0)
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(select_employee.bind(record.id))
		list.add_child(button)
		_team_buttons[record.id] = button
	_assign_button.disabled = records.is_empty() or not _active_job_id.is_empty()
	if records.is_empty():
		_selected_employee_id = ""
		_refresh_employee_header()
		return
	var wanted := _selected_employee_id
	if wanted.is_empty() or not _team_buttons.has(wanted):
		wanted = records[0].id
	select_employee(wanted)

func select_employee(employee_id: String) -> void:
	if not _team_buttons.has(employee_id):
		return
	_selected_employee_id = employee_id
	for id: String in _team_buttons:
		var button: Button = _team_buttons[id]
		button.add_theme_stylebox_override("normal", _stylebox(VERMILION if id == employee_id else Color("292929"), VERMILION if id == employee_id else Color("484848"), 1, 6))
		button.add_theme_color_override("font_color", WHITE if id == employee_id else DUST)
	if not _custom_mode and _job_picker != null:
		for index: int in range(CANNED_JOBS.size()):
			var job: Dictionary = CANNED_JOBS[index]
			if str(job.get("employee_id", "")) == employee_id:
				_job_picker.select(index)
				_assignment_preview.text = str(job.get("assignment", ""))
				break
	_refresh_employee_header()
	_refresh_chat_mode()
	_show_empty_chat()
	chat_history_requested.emit(employee_id)

func _selected_employee() -> EmployeeRecord:
	for record: EmployeeRecord in _employees:
		if record.id == _selected_employee_id:
			return record
	return null

func _refresh_employee_header() -> void:
	var employee := _selected_employee()
	if employee == null:
		_employee_name.text = "Your team"
		_employee_meta.text = "No employee selected"
		return
	_employee_name.text = employee.display_name
	var activity := "working" if _active_employee_id == employee.id else "available"
	_employee_meta.text = "%s  ·  morale %d  ·  %s" % [_employee_specialty(employee.id), employee.morale, activity]

func _employee_specialty(employee_id: String) -> String:
	return "Product + research" if employee_id == "mira" else "Growth + operations"

func _safe_bbcode(value: String) -> String:
	return value.replace("[", "﹇").replace("]", "﹈").replace("**", "")

func _show_empty_chat() -> void:
	_chat_log.clear()
	var employee := _selected_employee()
	if employee == null:
		_chat_log.append_text("[color=#b6b5b0]Choose a teammate from the rail.[/color]")
		return
	var greeting := "What are we building? Talk it through with me, then turn it into a work order." if employee.id == "mira" else "What should we test or grow? We can sharpen the idea before assigning it."
	_append_chat_line("employee", employee.display_name, greeting)

func _append_chat_line(sender: String, name_value: String, content: String) -> void:
	var color := "#c1fa81" if sender == "employee" else "#fa4616"
	_chat_log.append_text("[color=%s][b]%s[/b][/color]\n%s\n\n" % [color, _safe_bbcode(name_value), _safe_bbcode(content)])
	_chat_log.scroll_to_line(maxi(0, _chat_log.get_line_count() - 1))

func show_chat_history(employee_id: String, messages: Array) -> void:
	if employee_id != _selected_employee_id:
		return
	_chat_log.clear()
	if messages.is_empty():
		_show_empty_chat()
		return
	var employee := _selected_employee()
	for value: Variant in messages:
		if not value is Dictionary:
			continue
		var message := value as Dictionary
		var sender := str(message.get("sender", "employee"))
		_append_chat_line(sender, "Founder" if sender == "player" else employee.display_name, str(message.get("content", "")))

func show_chat_reply(employee_id: String, message: Dictionary, daily_spend: float) -> void:
	_chat_pending = false
	_refresh_chat_mode()
	set_spend(daily_spend, _spend_warning)
	if employee_id != _selected_employee_id:
		return
	var employee := _selected_employee()
	_append_chat_line("employee", employee.display_name, str(message.get("content", "")))
	_status_label.text = "%s replied. Turn the idea into a work order when it is ready." % employee.display_name

func set_chat_failed(employee_id: String, message: String) -> void:
	_chat_pending = false
	_refresh_chat_mode()
	if employee_id == _selected_employee_id:
		_append_chat_line("employee", "System", message)

func _submit_chat_text(_text: String) -> void:
	_submit_chat()

func _submit_chat() -> void:
	var message := _chat_input.text.strip_edges()
	if message.is_empty() or _selected_employee_id.is_empty():
		return
	_chat_input.clear()
	_last_chat_prompt = message
	_make_job_button.disabled = false
	_append_chat_line("player", "Founder", message)
	if not _active_job_id.is_empty():
		if not _active_job_running:
			_append_chat_line("employee", "System", "This work order is queued. You can update it after work begins.")
			return
		if _active_employee_id != _selected_employee_id:
			_append_chat_line("employee", "System", "One teammate is already working. Finish or cancel that job first.")
			return
		_chat_pending = true
		_refresh_chat_mode()
		steer_submitted.emit(_active_job_id, message)
		return
	_chat_pending = true
	_refresh_chat_mode()
	chat_submitted.emit(_selected_employee_id, message)

func _refresh_chat_mode() -> void:
	if _chat_input == null:
		return
	var has_employee := not _selected_employee_id.is_empty()
	var selected_job_running := _active_job_running and _active_employee_id == _selected_employee_id
	var chat_blocked := not _active_job_id.is_empty() and not selected_job_running
	_chat_input.editable = has_employee and not _chat_pending and not chat_blocked
	_chat_send_button.disabled = not has_employee or _chat_pending or chat_blocked
	if _chat_pending:
		_chat_send_button.text = "…"
		_chat_input.placeholder_text = "Waiting for a reply…"
	elif selected_job_running:
		_chat_send_button.text = "Update"
		_chat_input.placeholder_text = "Update %s's active job…" % _selected_employee().display_name
	elif chat_blocked:
		_chat_send_button.text = "Queued" if not _active_job_running else "Busy"
		_chat_input.placeholder_text = "Wait for the current work order"
	else:
		_chat_send_button.text = "Chat"
		_chat_input.placeholder_text = "Talk through an idea…"

func _make_last_chat_a_job() -> void:
	if _last_chat_prompt.is_empty():
		return
	_job_picker.select(CANNED_JOBS.size())
	_on_job_selected(CANNED_JOBS.size())
	var employee := _selected_employee()
	_custom_title_input.text = "Follow up with %s" % employee.display_name
	_assignment_preview.text = _last_chat_prompt
	_tabs.current_tab = 1
	_custom_title_input.grab_focus()

func _submit_key() -> void:
	var key := _key_input.text.strip_edges()
	_key_input.clear()
	if key.is_empty():
		set_error("Paste an OpenRouter key first.")
		return
	key_submitted.emit(key)
	key = ""

func _submit_assignment() -> void:
	if not _active_job_id.is_empty():
		set_error("One work order is already active. Cancel it or wait for completion.")
		return
	if _selected_employee_id.is_empty():
		set_error("Choose an employee first.")
		return
	if _custom_mode:
		var custom_title := _custom_title_input.text.strip_edges()
		var custom_assignment := _assignment_preview.text.strip_edges()
		if custom_title.is_empty():
			set_error("Give the work order a title.")
			_custom_title_input.grab_focus()
			return
		if custom_assignment.is_empty():
			set_error("Write instructions for the employee.")
			_assignment_preview.grab_focus()
			return
		var attached_path := str(_attachment_picker.get_item_metadata(_attachment_picker.selected))
		assignment_submitted.emit(
			_selected_employee_id,
			custom_title,
			custom_assignment,
			PackedStringArray(["Create at least one artifact that fulfills the instruction", "Return a concise delivery summary"]),
			attached_path
		)
		return
	var job: Dictionary = CANNED_JOBS[_job_picker.selected]
	assignment_submitted.emit(
		_selected_employee_id,
		str(job.get("title", "Work order")),
		str(job.get("assignment", "")),
		PackedStringArray(job.get("criteria", [])),
		""
	)

func _cancel_active_job() -> void:
	if _active_job_id.is_empty():
		return
	_cancel_button.disabled = true
	_status_label.text = "Cancelling the active work order…"
	cancel_requested.emit(_active_job_id)

func _submit_steer_text(_text: String) -> void:
	_submit_steer()

func _submit_steer() -> void:
	if _active_job_id.is_empty() or not _steer_box.visible:
		return
	var message := _steer_input.text.strip_edges()
	if message.is_empty():
		set_error("Write an update for the active employee first.")
		_steer_input.grab_focus()
		return
	_steer_input.clear()
	_steer_button.disabled = true
	_status_label.text = "Sending update to the active work session…"
	steer_submitted.emit(_active_job_id, message)

func _on_job_selected(index: int) -> void:
	if index < 0 or index > CANNED_JOBS.size():
		return
	_custom_mode = index == CANNED_JOBS.size()
	_custom_title_input.visible = _custom_mode
	_assignment_preview.editable = _custom_mode
	_attachment_label.visible = _custom_mode
	_attachment_picker.visible = _custom_mode
	if _custom_mode:
		_assignment_preview.text = ""
		_assignment_preview.placeholder_text = "Describe the deliverable and the file you want back."
		return
	_assignment_preview.placeholder_text = ""
	var job: Dictionary = CANNED_JOBS[index]
	_assignment_preview.text = str(job.get("assignment", ""))
	var employee_id := str(job.get("employee_id", ""))
	if _team_buttons.has(employee_id):
		select_employee(employee_id)

func begin_job(job_id: String, employee_id: String = "") -> void:
	_active_job_id = job_id
	_active_employee_id = employee_id if not employee_id.is_empty() else _selected_employee_id
	_active_job_running = false
	_assign_button.disabled = true
	_assign_button.text = "One job at a time"
	_cancel_button.disabled = false
	_steer_box.visible = false
	_steer_button.disabled = false
	_steer_input.clear()
	_status_label.text = "Submitting work order…"
	_tabs.current_tab = 2
	_refresh_employee_header()
	_refresh_chat_mode()

func mark_job_queued(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_status_label.text = "Queued. Work begins automatically during the next work window."
	_active_job_running = false
	_assign_button.text = "Queued until work hours"
	_steer_box.visible = false

func restore_job(job_id: String, status: String, title: String, employee_id: String = "") -> void:
	if status != "queued" and status != "running":
		return
	_active_job_id = job_id
	_active_employee_id = employee_id
	_active_job_running = status == "running"
	_assign_button.disabled = true
	_cancel_button.disabled = false
	_assign_button.text = "Queued until work hours" if status == "queued" else "One job at a time"
	_status_label.text = "%s  ·  restored %s" % [title, status]
	_steer_box.visible = status == "running"
	_refresh_employee_header()
	_refresh_chat_mode()

func finish_job(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_active_job_id = ""
	_active_employee_id = ""
	_active_job_running = false
	_assign_button.disabled = _employees.is_empty()
	_update_assign_copy()
	_cancel_button.disabled = true
	_steer_box.visible = false
	_steer_button.disabled = false
	_steer_input.clear()
	_refresh_employee_header()
	_refresh_chat_mode()

func active_job_id() -> String:
	return _active_job_id

func steer_controls_visible() -> bool:
	return _steer_box.visible

func selected_employee_id() -> String:
	return _selected_employee_id

func set_steer_sent(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_chat_pending = false
	_steer_button.disabled = false
	_refresh_chat_mode()
	_status_label.text = "Update delivered to the same active work session."

func set_steer_failed(job_id: String, message: String) -> void:
	if job_id != _active_job_id:
		return
	_chat_pending = false
	_steer_button.disabled = false
	_refresh_chat_mode()
	set_error(message)

func studio_file_count() -> int:
	return _artifact_list.get_child_count()

func last_status_text() -> String:
	return _last_status_label.text

func promotion_controls_fit_viewport() -> bool:
	if not _promotion_box.visible:
		return false
	return _promotion_box.get_global_rect().end.y <= get_viewport_rect().end.y

func set_worker_ready() -> void:
	if _active_job_id.is_empty():
		_status_label.text = "Worker connected. Chat with a teammate or assign work."

func set_clock_phase(phase: String) -> void:
	_clock_phase = phase
	_update_assign_copy()
	if _active_job_id.is_empty() and phase != "work":
		_status_label.text = "Lunch — new work queues until 13:30." if phase == "lunch" else "Off hours — new work queues until 08:00."

func _update_assign_copy() -> void:
	if not _active_job_id.is_empty():
		return
	if _clock_phase == "work":
		_assign_button.text = "Assign real work"
	elif _clock_phase == "lunch":
		_assign_button.text = "Queue until 13:30"
	else:
		_assign_button.text = "Queue until 08:00"

func set_credential_status(configured: bool) -> void:
	_key_status.text = "Ready — key stored in OS keychain" if configured else "Add a key to chat or run work"
	_key_status.add_theme_color_override("font_color", CHARTREUSE if configured else VERMILION)

func set_credential_saved() -> void:
	set_credential_status(true)
	_status_label.text = "OpenRouter key saved."

func set_spend(daily_spend: float, warning: float) -> void:
	_spend_warning = warning
	_spend_label.text = "Today  $%.4f  · warning at $%.2f" % [daily_spend, warning]
	_spend_label.add_theme_color_override("font_color", VERMILION if daily_spend >= warning else DUST)

func set_error(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", VERMILION)

func set_info(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", OFF_WHITE)

func on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	var line := ""
	match event.type:
		&"job.queued":
			mark_job_queued(job_id)
			line = "[color=#fa4616]queued[/color] · %s" % _safe_bbcode(event.reason)
		&"job.started":
			_status_label.text = "Employee is walking to their desk."
			if job_id == _active_job_id:
				_active_job_running = true
				_steer_box.visible = true
				_steer_button.disabled = false
				_refresh_chat_mode()
			line = "[color=#c1fa81]job started[/color]"
		&"agent.thinking":
			_status_label.text = event.summary
			line = "thinking · %s" % _safe_bbcode(event.summary)
		&"tool.started":
			_status_label.text = event.label
			line = "[color=#6196c1]tool[/color] · %s" % _safe_bbcode(event.tool)
		&"tool.completed":
			line = "%s · %s" % [_safe_bbcode(event.tool), "done" if event.ok else "failed"]
		&"approval.required":
			_approval_job_id = job_id
			_approval_id = event.approval_id
			_approval_label.text = event.action
			_approval_box.visible = true
			_tabs.current_tab = 2
			line = "[color=#fa4616]approval required[/color]"
		&"artifact.created":
			line = "[color=#c1fa81]delivery[/color] · %s" % _safe_bbcode(event.name)
		&"usage.updated":
			_usage_label.text = "Tokens  %d in / %d out  ·  cost $%.4f" % [event.input_tokens, event.output_tokens, event.cost]
			line = "usage · %d tokens · $%.4f" % [event.input_tokens + event.output_tokens, event.cost]
		&"job.blocked":
			_status_label.text = event.reason
			line = "[color=#fa4616]blocked[/color] · %s" % _safe_bbcode(event.reason)
			finish_job(job_id)
		&"job.completed":
			_status_label.text = event.summary
			line = "[color=#c1fa81]completed[/color]"
			finish_job(job_id)
		&"job.failed":
			_status_label.text = event.error
			line = "[color=#fa4616]failed[/color] · %s" % _safe_bbcode(event.error)
			finish_job(job_id)
	if not line.is_empty():
		_event_log.append_text("• %s\n" % line)
		_event_log.scroll_to_line(maxi(0, _event_log.get_line_count() - 1))

func _decide_approval(approved: bool) -> void:
	approval_decided.emit(_approval_job_id, _approval_id, approved)
	_approval_box.visible = false

func offer_promotion(job_id: String) -> void:
	_promotion_job_id = job_id
	_promotion_label.text = "Add this delivery to the durable studio?"
	_promotion_box.visible = true
	_tabs.current_tab = 2

func _decide_promotion(approved: bool) -> void:
	var job_id := _promotion_job_id
	_promotion_job_id = ""
	promotion_decided.emit(job_id, approved)
	_promotion_box.visible = false
	_status_label.text = "Adding approved delivery to studio/…" if approved else "Delivery discarded."

func show_pending_promotions(pending_promotions: Array) -> void:
	if pending_promotions.is_empty():
		_promotion_job_id = ""
		_promotion_box.visible = false
		return
	var candidate_value: Variant = pending_promotions[0]
	if not candidate_value is Dictionary:
		return
	var candidate := candidate_value as Dictionary
	var job_id := str(candidate.get("jobId", ""))
	if job_id.is_empty():
		return
	var artifact_names: PackedStringArray = []
	var artifact_values: Variant = candidate.get("artifacts", [])
	if artifact_values is Array:
		for artifact_value: Variant in artifact_values as Array:
			if artifact_value is Dictionary:
				artifact_names.append(str((artifact_value as Dictionary).get("name", "artifact")))
	_promotion_job_id = job_id
	_promotion_label.text = "%s finished “%s”. Add to studio or discard: %s" % [
		str(candidate.get("employeeName", "Employee")),
		str(candidate.get("title", "Work order")),
		", ".join(artifact_names) if not artifact_names.is_empty() else "completed artifacts",
	]
	_promotion_box.visible = true

func pending_promotion_job_id() -> String:
	return _promotion_job_id

func show_recent_jobs(jobs: Array) -> void:
	if jobs.is_empty():
		_last_status_label.text = "Last work order  ·  none yet"
		return
	var latest_value: Variant = jobs[0]
	if latest_value is Dictionary:
		var latest := latest_value as Dictionary
		_last_status_label.text = "Last  ·  %s  ·  %s" % [str(latest.get("title", "Work order")), str(latest.get("status", "unknown"))]

func show_artifacts(job_id: String, artifacts: Array[ArtifactRecord]) -> void:
	_clear_artifact_list()
	if artifacts.is_empty():
		_add_empty_artifact("No delivery files were created.")
		return
	for artifact: ArtifactRecord in artifacts:
		var button := Button.new()
		button.text = "Open delivery  ·  %s" % artifact.name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = artifact.relative_path
		button.pressed.connect(_open_artifact.bind(job_id, artifact.relative_path))
		_artifact_list.add_child(button)
	_tabs.current_tab = 3

func _open_artifact(job_id: String, relative_path: String) -> void:
	artifact_open_requested.emit(job_id, relative_path)

func show_studio_files(files: Array[StudioFileRecord]) -> void:
	_configure_attachment_picker(files)
	_clear_artifact_list()
	if files.is_empty():
		_add_empty_artifact("Studio is empty. Approve a completed delivery to add it.")
		return
	for file: StudioFileRecord in files:
		var button := Button.new()
		button.text = "studio/%s" % file.relative_path
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = "Promoted from %s" % file.source_job_id
		button.pressed.connect(studio_open_requested.emit.bind(file.relative_path))
		_artifact_list.add_child(button)

func _clear_artifact_list() -> void:
	for child: Node in _artifact_list.get_children():
		child.queue_free()

func _add_empty_artifact(message: String) -> void:
	var empty := Label.new()
	empty.text = message
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty.add_theme_color_override("font_color", DUST)
	_artifact_list.add_child(empty)

func _configure_attachment_picker(files: Array[StudioFileRecord]) -> void:
	var selected_path := ""
	if _attachment_picker.item_count > 0:
		selected_path = str(_attachment_picker.get_item_metadata(_attachment_picker.selected))
	_attachment_picker.clear()
	_attachment_picker.add_item("No studio file attached")
	_attachment_picker.set_item_metadata(0, "")
	for file: StudioFileRecord in files:
		_attachment_picker.add_item("studio/%s" % file.relative_path)
		var index := _attachment_picker.item_count - 1
		_attachment_picker.set_item_metadata(index, file.relative_path)
		if file.relative_path == selected_path:
			_attachment_picker.select(index)
