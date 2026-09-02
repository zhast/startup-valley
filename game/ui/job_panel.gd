class_name JobPanel
extends PanelContainer

signal key_submitted(key: String)
signal assignment_submitted(employee_id: String, title: String, assignment: String, acceptance_criteria: PackedStringArray, attached_studio_path: String)
signal cancel_requested(job_id: String)
signal approval_decided(job_id: String, approval_id: String, approved: bool)
signal artifact_open_requested(job_id: String, relative_path: String)
signal artifact_refresh_requested(job_id: String)
signal studio_open_requested(relative_path: String)
signal promotion_decided(job_id: String, approved: bool)

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

var _employee_picker: OptionButton
var _job_picker: OptionButton
var _custom_title_input: LineEdit
var _attachment_label: Label
var _attachment_picker: OptionButton
var _key_input: LineEdit
var _key_status: Label
var _assignment_preview: TextEdit
var _assign_button: Button
var _cancel_button: Button
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
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.custom_minimum_size = Vector2(320.0, 0.0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

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
	_assignment_preview.custom_minimum_size = Vector2(0.0, 72.0)
	_assignment_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_child(_assignment_preview)
	_attachment_label = Label.new()
	_attachment_label.text = "READ CONTEXT (OPTIONAL)"
	_attachment_label.add_theme_font_size_override("font_size", 11)
	_attachment_label.add_theme_color_override("font_color", Color("6db7d8"))
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
	action_row.add_child(_assign_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_active_job)
	action_row.add_child(_cancel_button)

	_status_label = Label.new()
	_status_label.text = "Worker starting…"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.max_lines_visible = 4
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	_last_status_label = Label.new()
	_last_status_label.text = "Last work order  ·  none yet"
	_last_status_label.add_theme_font_size_override("font_size", 11)
	_last_status_label.add_theme_color_override("font_color", Color("91a2bc"))
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
	_promotion_label.text = "Promote completed artifacts into the durable studio?"
	_promotion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_promotion_box.add_child(_promotion_label)
	var promotion_buttons := HBoxContainer.new()
	var promote_button := Button.new()
	promote_button.text = "Approve"
	promote_button.pressed.connect(_decide_promotion.bind(true))
	promotion_buttons.add_child(promote_button)
	var discard_button := Button.new()
	discard_button.text = "Discard"
	discard_button.pressed.connect(_decide_promotion.bind(false))
	promotion_buttons.add_child(discard_button)
	_promotion_box.add_child(promotion_buttons)
	content.add_child(_promotion_box)

	content.add_child(_section_label("LIVE EVENTS"))
	_event_log = RichTextLabel.new()
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.scroll_active = true
	_event_log.custom_minimum_size = Vector2(0.0, 82.0)
	content.add_child(_event_log)

	content.add_child(_section_label("STUDIO FILES"))
	var artifact_scroll := ScrollContainer.new()
	artifact_scroll.custom_minimum_size = Vector2(0.0, 78.0)
	content.add_child(artifact_scroll)
	_artifact_list = VBoxContainer.new()
	_artifact_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artifact_scroll.add_child(_artifact_list)
	var empty_artifact := Label.new()
	empty_artifact.text = "Approved durable files appear here."
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
	var employee_id := str(_employee_picker.get_item_metadata(_employee_picker.selected))
	if _custom_mode:
		var custom_title := _custom_title_input.text.strip_edges()
		var custom_assignment := _assignment_preview.text.strip_edges()
		if custom_title.is_empty():
			_status_label.text = "Give the freeform work order a title."
			_custom_title_input.grab_focus()
			return
		if custom_assignment.is_empty():
			_status_label.text = "Write instructions for the employee."
			_assignment_preview.grab_focus()
			return
		var attached_path := str(_attachment_picker.get_item_metadata(_attachment_picker.selected))
		assignment_submitted.emit(
			employee_id,
			custom_title,
			custom_assignment,
			PackedStringArray([
				"Create at least one artifact that fulfills the instruction",
				"Return a concise delivery summary",
			]),
			attached_path
		)
		return
	var job: Dictionary = CANNED_JOBS[_job_picker.selected]
	assignment_submitted.emit(
		employee_id,
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
		_assignment_preview.placeholder_text = "Describe the real deliverable and the file you want back."
		_custom_title_input.grab_focus()
		return
	_assignment_preview.placeholder_text = ""
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
	_status_label.text = "Submitting work order…"

func mark_job_queued(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_status_label.text = "Queued. Work begins automatically during the next work window."
	_assign_button.text = "Queued until work hours"

func restore_job(job_id: String, status: String, title: String) -> void:
	if status != "queued" and status != "running":
		return
	_active_job_id = job_id
	_assign_button.disabled = true
	_cancel_button.disabled = false
	_assign_button.text = "Queued until work hours" if status == "queued" else "One job at a time"
	_status_label.text = "%s  ·  restored %s" % [title, status]

func finish_job(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_active_job_id = ""
	_assign_button.disabled = _employee_picker.item_count == 0
	_update_assign_copy()
	_cancel_button.disabled = true

func active_job_id() -> String:
	return _active_job_id

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
		_status_label.text = "Worker connected. Pick an employee and work order."

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

func set_info(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("bed0ee"))

func on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	var line := ""
	match event.type:
		&"job.queued":
			mark_job_queued(job_id)
			line = "[color=#e9c46a]queued[/color] · %s" % event.reason
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

func offer_promotion(job_id: String) -> void:
	_promotion_job_id = job_id
	_promotion_label.text = "Approve this job's artifacts for the durable studio?"
	_promotion_box.visible = true
	_event_log.visible = false

func _decide_promotion(approved: bool) -> void:
	var job_id := _promotion_job_id
	_promotion_job_id = ""
	promotion_decided.emit(job_id, approved)
	_promotion_box.visible = false
	_event_log.visible = true
	_status_label.text = "Promoting approved artifacts into studio/…" if approved else "Discarded from the promotion queue."

func show_pending_promotions(pending_promotions: Array) -> void:
	if pending_promotions.is_empty():
		_promotion_job_id = ""
		_promotion_box.visible = false
		_event_log.visible = true
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
	_promotion_label.text = "%s finished “%s”. Approve or discard: %s" % [
		str(candidate.get("employeeName", "Employee")),
		str(candidate.get("title", "Work order")),
		", ".join(artifact_names) if not artifact_names.is_empty() else "completed artifacts",
	]
	_promotion_box.visible = true
	_event_log.visible = false

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

func show_studio_files(files: Array[StudioFileRecord]) -> void:
	_configure_attachment_picker(files)
	for child: Node in _artifact_list.get_children():
		child.queue_free()
	if files.is_empty():
		var empty := Label.new()
		empty.text = "Studio is empty. Approve a completed artifact to promote it."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_artifact_list.add_child(empty)
		return
	for file: StudioFileRecord in files:
		var button := Button.new()
		button.text = "Read studio/  ·  %s" % file.relative_path
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = "Promoted from %s" % file.source_job_id
		button.pressed.connect(studio_open_requested.emit.bind(file.relative_path))
		_artifact_list.add_child(button)

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
