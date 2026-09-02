class_name JobPanel
extends PanelContainer

signal key_submitted(key: String)
signal assignment_submitted(employee_id: String, title: String, assignment: String, acceptance_criteria: PackedStringArray)
signal cancel_requested(job_id: String)
signal approval_decided(job_id: String, approval_id: String, approved: bool)
signal artifact_open_requested(job_id: String, relative_path: String)
signal artifact_refresh_requested(job_id: String)

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
		"assignment": "Review Mina's inventory keyboard navigation design note from the recent teammate delivery context. Read the staged handoff artifact, identify strengths and gaps, and write a concise review into review.md.",
		"criteria": ["review.md exists", "The review cites Mina's design choices", "The review identifies concrete strengths and gaps"],
	},
]

var _employee_picker: OptionButton
var _job_picker: OptionButton
var _key_input: LineEdit
var _key_status: Label
var _assignment_preview: TextEdit
var _assign_button: Button
var _cancel_button: Button
var _status_label: Label
var _usage_label: Label
var _spend_label: Label
var _event_log: RichTextLabel
var _artifact_list: VBoxContainer
var _approval_box: VBoxContainer
var _approval_label: Label
var _approval_job_id: String = ""
var _approval_id: String = ""
var _active_job_id: String = ""

func _ready() -> void:
	_build_interface()

func _build_interface() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("11192a")
	panel_style.border_color = Color("34445e")
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var title := Label.new()
	title.text = "STARTUP_VALLEY STUDIO"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("dce8ff"))
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "One real work order at a time"
	subtitle.add_theme_color_override("font_color", Color("8fa3c2"))
	content.add_child(subtitle)

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
	save_key_button.text = "Save securely"
	save_key_button.pressed.connect(_submit_key)
	key_row.add_child(save_key_button)
	_key_status = Label.new()
	_key_status.text = "Checking OS keychain…"
	_key_status.add_theme_font_size_override("font_size", 11)
	_key_status.add_theme_color_override("font_color", Color("91a2bc"))
	content.add_child(_key_status)

	content.add_child(_section_label("WORK ORDER"))
	_employee_picker = OptionButton.new()
	_employee_picker.fit_to_longest_item = false
	_employee_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_employee_picker)
	_job_picker = OptionButton.new()
	_job_picker.fit_to_longest_item = false
	_job_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for job: Dictionary in CANNED_JOBS:
		_job_picker.add_item(str(job.get("title", "Work order")))
	_job_picker.item_selected.connect(_on_job_selected)
	content.add_child(_job_picker)
	_assignment_preview = TextEdit.new()
	_assignment_preview.editable = false
	_assignment_preview.custom_minimum_size = Vector2(0.0, 72.0)
	_assignment_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_child(_assignment_preview)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	content.add_child(action_row)
	_assign_button = Button.new()
	_assign_button.text = "Assign real work"
	_assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_assign_button.pressed.connect(_submit_assignment)
	action_row.add_child(_assign_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_active_job)
	action_row.add_child(_cancel_button)

	_status_label = Label.new()
	_status_label.text = "Worker starting…"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color("bed0ee"))
	content.add_child(_status_label)
	_usage_label = Label.new()
	_usage_label.text = "Tokens  0 in / 0 out  ·  cost $0.0000"
	_usage_label.add_theme_font_size_override("font_size", 11)
	_usage_label.add_theme_color_override("font_color", Color("91a2bc"))
	content.add_child(_usage_label)
	_spend_label = Label.new()
	_spend_label.text = "Today  $0.00"
	_spend_label.add_theme_font_size_override("font_size", 11)
	content.add_child(_spend_label)

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

	content.add_child(_section_label("LIVE EVENTS"))
	_event_log = RichTextLabel.new()
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.scroll_active = true
	_event_log.custom_minimum_size = Vector2(0.0, 82.0)
	content.add_child(_event_log)

	content.add_child(_section_label("ARTIFACTS"))
	var artifact_scroll := ScrollContainer.new()
	artifact_scroll.custom_minimum_size = Vector2(0.0, 78.0)
	content.add_child(artifact_scroll)
	_artifact_list = VBoxContainer.new()
	_artifact_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artifact_scroll.add_child(_artifact_list)
	var empty_artifact := Label.new()
	empty_artifact.text = "Delivered files appear here."
	empty_artifact.add_theme_color_override("font_color", Color("71839f"))
	_artifact_list.add_child(empty_artifact)
	_on_job_selected(0)

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("6db7d8"))
	return label

func _submit_key() -> void:
	var key := _key_input.text.strip_edges()
	_key_input.clear()
	if key.is_empty():
		_status_label.text = "Paste an OpenRouter key first."
		return
	key_submitted.emit(key)
	key = ""

func _submit_assignment() -> void:
	if not _active_job_id.is_empty():
		_status_label.text = "One work order is already active. Cancel it or wait for completion."
		return
	if _employee_picker.item_count == 0:
		_status_label.text = "No employees are available."
		return
	var job: Dictionary = CANNED_JOBS[_job_picker.selected]
	var employee_id := str(_employee_picker.get_item_metadata(_employee_picker.selected))
	assignment_submitted.emit(
		employee_id,
		str(job.get("title", "Work order")),
		str(job.get("assignment", "")),
		PackedStringArray(job.get("criteria", []))
	)

func _cancel_active_job() -> void:
	if _active_job_id.is_empty():
		return
	_cancel_button.disabled = true
	_status_label.text = "Cancelling the active work order…"
	cancel_requested.emit(_active_job_id)

func _on_job_selected(index: int) -> void:
	if index < 0 or index >= CANNED_JOBS.size():
		return
	var job: Dictionary = CANNED_JOBS[index]
	_assignment_preview.text = str(job.get("assignment", ""))
	var employee_id := str(job.get("employee_id", ""))
	for item in range(_employee_picker.item_count):
		if str(_employee_picker.get_item_metadata(item)) == employee_id:
			_employee_picker.select(item)
			break

func configure_employees(records: Array[EmployeeRecord]) -> void:
	_employee_picker.clear()
	for record: EmployeeRecord in records:
		_employee_picker.add_item("%s  ·  morale %d" % [record.display_name, record.morale])
		_employee_picker.set_item_metadata(_employee_picker.item_count - 1, record.id)
	_assign_button.disabled = records.is_empty() or not _active_job_id.is_empty()
	_on_job_selected(_job_picker.selected)

func begin_job(job_id: String) -> void:
	_active_job_id = job_id
	_assign_button.disabled = true
	_assign_button.text = "One job at a time"
	_cancel_button.disabled = false
	_status_label.text = "Work order accepted. Waiting for job.started…"

func finish_job(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_active_job_id = ""
	_assign_button.disabled = _employee_picker.item_count == 0
	_assign_button.text = "Assign real work"
	_cancel_button.disabled = true

func active_job_id() -> String:
	return _active_job_id

func set_worker_ready() -> void:
	if _active_job_id.is_empty():
		_status_label.text = "Worker connected. Pick an employee and canned work order."

func set_credential_status(configured: bool) -> void:
	_key_status.text = "Stored in OS keychain" if configured else "Not configured — never stored in the game database"
	_key_status.add_theme_color_override("font_color", Color("78c49b") if configured else Color("d1a36f"))

func set_credential_saved() -> void:
	set_credential_status(true)
	_status_label.text = "OpenRouter key saved to the OS keychain."

func set_spend(daily_spend: float, warning: float) -> void:
	_spend_label.text = "Today  $%.4f  · warning at $%.2f" % [daily_spend, warning]
	if daily_spend >= warning:
		_spend_label.add_theme_color_override("font_color", Color("e9a16f"))

func set_error(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("ef8f91"))

func on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	var line := ""
	match event.type:
		&"job.started":
			_status_label.text = "Employee is walking to their desk."
			line = "[color=#72c9a1]job started[/color]"
		&"agent.thinking":
			_status_label.text = event.summary
			line = "thinking · %s" % event.summary
		&"tool.started":
			_status_label.text = event.label
			line = "[color=#6db7d8]tool[/color] · %s" % event.tool
		&"tool.completed":
			line = "%s · %s" % [event.tool, "done" if event.ok else "failed"]
		&"approval.required":
			_approval_job_id = job_id
			_approval_id = event.approval_id
			_approval_label.text = event.action
			_approval_box.visible = true
			line = "[color=#e9a16f]approval required[/color]"
		&"artifact.created":
			line = "[color=#b797eb]artifact[/color] · %s" % event.name
			artifact_refresh_requested.emit(job_id)
		&"usage.updated":
			_usage_label.text = "Tokens  %d in / %d out  ·  cost $%.4f" % [event.input_tokens, event.output_tokens, event.cost]
			line = "usage · %d tokens · $%.4f" % [event.input_tokens + event.output_tokens, event.cost]
		&"job.blocked":
			_status_label.text = event.reason
			line = "[color=#e9a16f]blocked[/color] · %s" % event.reason
			finish_job(job_id)
		&"job.completed":
			_status_label.text = event.summary
			line = "[color=#72c9a1]completed[/color]"
			artifact_refresh_requested.emit(job_id)
			finish_job(job_id)
		&"job.failed":
			_status_label.text = event.error
			line = "[color=#ef8f91]failed[/color] · %s" % event.error
			finish_job(job_id)
	if not line.is_empty():
		_event_log.append_text("• %s\n" % line)
		_event_log.scroll_to_line(maxi(0, _event_log.get_line_count() - 1))

func _decide_approval(approved: bool) -> void:
	approval_decided.emit(_approval_job_id, _approval_id, approved)
	_approval_box.visible = false

func show_artifacts(job_id: String, artifacts: Array[ArtifactRecord]) -> void:
	for child: Node in _artifact_list.get_children():
		child.queue_free()
	if artifacts.is_empty():
		var empty := Label.new()
		empty.text = "No artifacts yet."
		_artifact_list.add_child(empty)
		return
	for artifact: ArtifactRecord in artifacts:
		var button := Button.new()
		button.text = "Read in game  ·  %s" % artifact.name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = artifact.relative_path
		button.pressed.connect(_open_artifact.bind(job_id, artifact.relative_path))
		_artifact_list.add_child(button)

func _open_artifact(job_id: String, relative_path: String) -> void:
	artifact_open_requested.emit(job_id, relative_path)
