class_name JobPanel
extends Control

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
const PARCHMENT := Color("f4ddb0")
const PARCHMENT_LIGHT := Color("fff7e2")
const PARCHMENT_DARK := Color("d8b879")
const WOOD := Color("9b542d")
const WOOD_DARK := Color("552c22")
const WOOD_LIGHT := Color("de9550")
const MUTED_INK := Color("725b46")
## Authored against the approved 1078 x 1560 notebook mockup at a 720 px viewport.
## Keeping these measurements literal prevents the rail and drawer from slowly
## drifting apart as individual controls are refined.
const RAIL_WIDTH := 130.0
const DRAWER_WIDTH := 368.0
const DRAWER_GAP := 0.0

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
var _employee_status: Label
var _employee_portrait: TextureRect
var _header_icon: Label
var _drawer_panel: Panel
var _rail_panel: Panel
var _drawer_close_button: Button
var _drawer_open: bool = false
var _drawer_tween: Tween
var _tabs: TabContainer
var _chat_scroll: ScrollContainer
var _chat_log: VBoxContainer
var _chat_transcript: String = ""
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
var _attention_employee_id: String = ""
var _clock_phase: String = "work"
var _custom_mode: bool = false
var _spend_warning: float = 5.0
var _active_job_running: bool = false

func _ready() -> void:
	_build_interface()
	_set_drawer_open(false, false)

func _build_interface() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

	_drawer_panel = Panel.new()
	_drawer_panel.name = "EmployeeDrawer"
	_drawer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_drawer_panel.offset_right = DRAWER_WIDTH
	_drawer_panel.add_theme_stylebox_override("panel", NotebookSkin.wood_surface(Vector4(12.0, 12.0, 12.0, 12.0)))
	add_child(_drawer_panel)
	_add_outer_frame(_drawer_panel)
	var drawer_margin := MarginContainer.new()
	drawer_margin.add_theme_constant_override("margin_left", 12)
	drawer_margin.add_theme_constant_override("margin_right", 12)
	drawer_margin.add_theme_constant_override("margin_top", 28)
	drawer_margin.add_theme_constant_override("margin_bottom", 12)
	drawer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drawer_panel.add_child(drawer_margin)
	var drawer := _build_employee_drawer()
	drawer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_margin.add_child(drawer)

	_rail_panel = Panel.new()
	_rail_panel.name = "TeamRail"
	_rail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_rail_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_rail_panel.offset_left = -RAIL_WIDTH
	_rail_panel.add_theme_stylebox_override("panel", NotebookSkin.team_rail("", false))
	add_child(_rail_panel)
	var team_rail := _build_team_rail()
	team_rail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rail_panel.add_child(team_rail)

func _add_outer_frame(panel: Control) -> void:
	var frame := NinePatchRect.new()
	frame.texture = NotebookSkin.OUTER_FRAME
	frame.draw_center = false
	frame.patch_margin_left = 14
	frame.patch_margin_top = 14
	frame.patch_margin_right = 14
	frame.patch_margin_bottom = 14
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.z_index = 100
	panel.add_child(frame)

func _build_team_rail() -> Control:
	var rail := Control.new()
	rail.custom_minimum_size = Vector2(RAIL_WIDTH, 0.0)
	var team_list := VBoxContainer.new()
	team_list.name = "TeamList"
	team_list.add_theme_constant_override("separation", 4)
	team_list.set_anchors_preset(Control.PRESET_TOP_WIDE)
	team_list.offset_left = 15.0
	team_list.offset_top = 78.0
	team_list.offset_right = -15.0
	team_list.offset_bottom = 366.0
	rail.add_child(team_list)
	return rail

func _build_employee_drawer() -> VBoxContainer:
	var drawer := VBoxContainer.new()
	drawer.add_theme_constant_override("separation", 7)
	var header_shell := Control.new()
	header_shell.custom_minimum_size = Vector2(0.0, 150.0)
	drawer.add_child(header_shell)
	var header_card := PanelContainer.new()
	header_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_card.add_theme_stylebox_override("panel", NotebookSkin.parchment(Vector4(12.0, 11.0, 38.0, 11.0)))
	header_shell.add_child(header_card)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 12)
	header_margin.add_theme_constant_override("margin_right", 38)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header_card.add_child(header_margin)
	var employee_header := HBoxContainer.new()
	employee_header.add_theme_constant_override("separation", 16)
	header_margin.add_child(employee_header)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(104.0, 112.0)
	portrait_frame.add_theme_stylebox_override("panel", NotebookSkin.portrait_frame())
	employee_header.add_child(portrait_frame)
	_employee_portrait = TextureRect.new()
	_employee_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_employee_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_employee_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_child(_employee_portrait)
	_header_icon = Label.new()
	_header_icon.text = "▤"
	_header_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_icon.add_theme_font_size_override("font_size", 38)
	_header_icon.add_theme_color_override("font_color", INDIGO)
	_header_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_icon.visible = false
	_header_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_frame.add_child(_header_icon)
	var employee_copy := VBoxContainer.new()
	employee_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	employee_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	employee_copy.add_theme_constant_override("separation", 3)
	employee_header.add_child(employee_copy)
	_employee_name = Label.new()
	_employee_name.text = "Your team"
	_employee_name.add_theme_font_size_override("font_size", 27)
	_employee_name.add_theme_color_override("font_color", CHARCOAL)
	employee_copy.add_child(_employee_name)
	_employee_meta = Label.new()
	_employee_meta.text = "Select an employee"
	_employee_meta.add_theme_font_size_override("font_size", 14)
	_employee_meta.add_theme_color_override("font_color", INDIGO)
	_employee_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	employee_copy.add_child(_employee_meta)
	_employee_status = Label.new()
	_employee_status.text = "● available"
	_employee_status.add_theme_font_size_override("font_size", 14)
	_employee_status.add_theme_color_override("font_color", Color("77b83f"))
	employee_copy.add_child(_employee_status)
	_drawer_close_button = Button.new()
	_drawer_close_button.text = "×"
	_drawer_close_button.tooltip_text = "Close team drawer"
	_drawer_close_button.pressed.connect(close_drawer)
	_style_action_button(_drawer_close_button, WOOD_DARK, false)
	_drawer_close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_drawer_close_button.offset_left = -50.0
	_drawer_close_button.offset_top = 8.0
	_drawer_close_button.offset_right = -20.0
	_drawer_close_button.offset_bottom = 38.0
	header_shell.add_child(_drawer_close_button)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", 15)
	_tabs.add_theme_color_override("font_selected_color", OFF_WHITE)
	_tabs.add_theme_color_override("font_unselected_color", CHARCOAL)
	_tabs.add_theme_stylebox_override("panel", NotebookSkin.wood_surface(Vector4(5.0, 5.0, 5.0, 5.0)))
	_tabs.add_theme_stylebox_override("tab_selected", NotebookSkin.selected_tab())
	_tabs.add_theme_stylebox_override("tab_unselected", NotebookSkin.wood_tab())
	_tabs.add_theme_stylebox_override("tab_hovered", NotebookSkin.wood_tab())
	drawer.add_child(_tabs)
	_tabs.add_child(_build_chat_tab())
	_tabs.add_child(_build_work_tab())
	_tabs.add_child(_build_journal_tab())
	_tabs.add_child(_build_studio_tab())
	_tabs.tab_changed.connect(_on_tab_changed)
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
	content.custom_minimum_size = Vector2(280.0, 0.0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	return content

func _build_chat_tab() -> VBoxContainer:
	var tab := VBoxContainer.new()
	tab.name = "Chat"
	tab.add_theme_constant_override("separation", 7)
	var notebook := NotebookPanel.new()
	notebook.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notebook.add_theme_stylebox_override("panel", NotebookSkin.notebook())
	tab.add_child(notebook)
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notebook.add_child(_chat_scroll)
	var chat_margin := MarginContainer.new()
	chat_margin.add_theme_constant_override("margin_left", 14)
	chat_margin.add_theme_constant_override("margin_right", 14)
	chat_margin.add_theme_constant_override("margin_top", 18)
	chat_margin.add_theme_constant_override("margin_bottom", 18)
	chat_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_scroll.add_child(chat_margin)
	_chat_log = VBoxContainer.new()
	_chat_log.custom_minimum_size = Vector2(296.0, 0.0)
	_chat_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_log.add_theme_constant_override("separation", 12)
	chat_margin.add_child(_chat_log)
	_show_chat_hint("Choose a teammate from the rail.")
	var composer_frame := PanelContainer.new()
	composer_frame.add_theme_stylebox_override("panel", NotebookSkin.content_frame())
	tab.add_child(composer_frame)
	var composer_margin := MarginContainer.new()
	composer_margin.add_theme_constant_override("margin_left", 8)
	composer_margin.add_theme_constant_override("margin_right", 8)
	composer_margin.add_theme_constant_override("margin_top", 8)
	composer_margin.add_theme_constant_override("margin_bottom", 8)
	composer_frame.add_child(composer_margin)
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	composer_margin.add_child(input_row)
	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Talk through an idea…"
	_chat_input.max_length = 2000
	_chat_input.custom_minimum_size = Vector2(0.0, 48.0)
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.text_submitted.connect(_submit_chat_text)
	_style_text_input(_chat_input)
	input_row.add_child(_chat_input)
	_chat_send_button = Button.new()
	_chat_send_button.text = "SEND"
	_chat_send_button.custom_minimum_size = Vector2(88.0, 48.0)
	_chat_send_button.add_theme_font_size_override("font_size", 16)
	_chat_send_button.pressed.connect(_submit_chat)
	_style_action_button(_chat_send_button, VERMILION, true)
	input_row.add_child(_chat_send_button)
	_make_job_button = Button.new()
	_make_job_button.text = "ASSIGN WORK"
	_make_job_button.custom_minimum_size = Vector2(0.0, 56.0)
	_make_job_button.add_theme_font_size_override("font_size", 18)
	_make_job_button.disabled = true
	_make_job_button.pressed.connect(_make_last_chat_a_job)
	_style_action_button(_make_job_button, INDIGO, true)
	tab.add_child(_make_job_button)
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
	_style_text_input(_key_input)
	key_row.add_child(_key_input)
	var save_key_button := Button.new()
	save_key_button.text = "Save"
	save_key_button.custom_minimum_size = Vector2(54.0, 0.0)
	save_key_button.pressed.connect(_submit_key)
	_style_action_button(save_key_button, INDIGO, false)
	key_row.add_child(save_key_button)
	_key_status = Label.new()
	_key_status.text = "Checking OS keychain…"
	_key_status.add_theme_font_size_override("font_size", 10)
	_key_status.add_theme_color_override("font_color", MUTED_INK)
	content.add_child(_key_status)
	content.add_child(_section_label("WORK ORDER"))
	_job_picker = OptionButton.new()
	_job_picker.fit_to_longest_item = false
	_job_picker.clip_text = true
	_job_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_job_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(_job_picker, INDIGO, false)
	for job: Dictionary in CANNED_JOBS:
		_job_picker.add_item(str(job.get("title", "Work order")))
	_job_picker.add_item("Custom work order…")
	_job_picker.item_selected.connect(_on_job_selected)
	content.add_child(_job_picker)
	_custom_title_input = LineEdit.new()
	_custom_title_input.placeholder_text = "Work-order title"
	_custom_title_input.max_length = 200
	_custom_title_input.visible = false
	_style_text_input(_custom_title_input)
	content.add_child(_custom_title_input)
	_assignment_preview = TextEdit.new()
	_assignment_preview.editable = false
	_assignment_preview.custom_minimum_size = Vector2(0.0, 122.0)
	_assignment_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_style_text_input(_assignment_preview)
	content.add_child(_assignment_preview)
	_attachment_label = _section_label("READ CONTEXT (OPTIONAL)")
	_attachment_label.visible = false
	content.add_child(_attachment_label)
	_attachment_picker = OptionButton.new()
	_attachment_picker.fit_to_longest_item = false
	_attachment_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_picker.visible = false
	_style_action_button(_attachment_picker, INDIGO, false)
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
	_style_action_button(_assign_button, VERMILION, true)
	action_row.add_child(_assign_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.custom_minimum_size = Vector2(72.0, 0.0)
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_active_job)
	_style_action_button(_cancel_button, VERMILION, false)
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
	_status_label.add_theme_color_override("font_color", CHARCOAL)
	content.add_child(_status_label)
	_usage_label = Label.new()
	_usage_label.text = "Tokens  0 in / 0 out  ·  cost $0.0000"
	_usage_label.add_theme_font_size_override("font_size", 10)
	_usage_label.add_theme_color_override("font_color", MUTED_INK)
	content.add_child(_usage_label)
	_spend_label = Label.new()
	_spend_label.text = "Today  $0.0000"
	_spend_label.add_theme_font_size_override("font_size", 10)
	_spend_label.add_theme_color_override("font_color", MUTED_INK)
	content.add_child(_spend_label)
	_last_status_label = Label.new()
	_last_status_label.text = "Last work order  ·  none yet"
	_last_status_label.add_theme_font_size_override("font_size", 10)
	_last_status_label.add_theme_color_override("font_color", MUTED_INK)
	_last_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(_last_status_label)
	_approval_box = VBoxContainer.new()
	_approval_box.visible = false
	_approval_box.add_theme_constant_override("separation", 5)
	var approval_heading := _section_label("ACTION REQUIRED")
	approval_heading.add_theme_color_override("font_color", VERMILION)
	_approval_box.add_child(approval_heading)
	_approval_label = Label.new()
	_approval_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_approval_label.add_theme_color_override("font_color", CHARCOAL)
	_approval_box.add_child(_approval_label)
	var approval_buttons := HBoxContainer.new()
	approval_buttons.add_theme_constant_override("separation", 6)
	var approve_button := Button.new()
	approve_button.text = "Approve"
	approve_button.pressed.connect(_decide_approval.bind(true))
	_style_action_button(approve_button, CHARTREUSE, true)
	approval_buttons.add_child(approve_button)
	var deny_button := Button.new()
	deny_button.text = "Deny"
	deny_button.pressed.connect(_decide_approval.bind(false))
	_style_action_button(deny_button, VERMILION, false)
	approval_buttons.add_child(deny_button)
	_approval_box.add_child(approval_buttons)
	content.add_child(_approval_box)
	_promotion_box = VBoxContainer.new()
	_promotion_box.visible = false
	_promotion_box.add_theme_constant_override("separation", 5)
	var promotion_heading := _section_label("DELIVERY READY")
	promotion_heading.add_theme_color_override("font_color", INDIGO)
	_promotion_box.add_child(promotion_heading)
	_promotion_label = Label.new()
	_promotion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_promotion_label.add_theme_color_override("font_color", CHARCOAL)
	_promotion_box.add_child(_promotion_label)
	var promotion_buttons := HBoxContainer.new()
	promotion_buttons.add_theme_constant_override("separation", 6)
	var promote_button := Button.new()
	promote_button.text = "Add to studio"
	promote_button.pressed.connect(_decide_promotion.bind(true))
	_style_action_button(promote_button, CHARTREUSE, true)
	promotion_buttons.add_child(promote_button)
	var discard_button := Button.new()
	discard_button.text = "Discard"
	discard_button.pressed.connect(_decide_promotion.bind(false))
	_style_action_button(discard_button, VERMILION, false)
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
	_style_text_input(_steer_input)
	steer_row.add_child(_steer_input)
	_steer_button = Button.new()
	_steer_button.text = "Send"
	_steer_button.pressed.connect(_submit_steer)
	_style_action_button(_steer_button, INDIGO, true)
	steer_row.add_child(_steer_button)
	content.add_child(_steer_box)
	content.add_child(_section_label("LIVE ACTIVITY"))
	_event_log = RichTextLabel.new()
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.scroll_active = true
	_event_log.custom_minimum_size = Vector2(0.0, 220.0)
	_event_log.add_theme_color_override("default_color", CHARCOAL)
	_event_log.add_theme_stylebox_override("normal", _stylebox(PARCHMENT_LIGHT, WOOD, 2, 2))
	content.add_child(_event_log)
	return scroll

func _build_studio_tab() -> ScrollContainer:
	var scroll := _tab_scroll("Files")
	var content := _tab_content(scroll)
	var intro := Label.new()
	intro.text = "Deliveries become durable only after you add them to the studio. Future employees can use approved files."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", MUTED_INK)
	content.add_child(intro)
	_artifact_list = VBoxContainer.new()
	_artifact_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_artifact_list)
	var empty := Label.new()
	empty.text = "Approved files will appear here."
	empty.add_theme_color_override("font_color", MUTED_INK)
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

func _style_action_button(button: Button, accent: Color, filled: bool) -> void:
	if filled and accent == VERMILION:
		button.add_theme_stylebox_override("normal", NotebookSkin.selected_tab())
		button.add_theme_stylebox_override("hover", NotebookSkin.selected_tab())
		button.add_theme_stylebox_override("pressed", NotebookSkin.selected_tab())
		button.add_theme_stylebox_override("focus", NotebookSkin.selected_tab())
		button.add_theme_stylebox_override("disabled", _stylebox(PARCHMENT_DARK, MUTED_INK, 1, 2))
		button.add_theme_color_override("font_color", WHITE)
		button.add_theme_color_override("font_hover_color", WHITE)
		button.add_theme_color_override("font_pressed_color", WHITE)
		button.add_theme_color_override("font_disabled_color", MUTED_INK)
		return
	if filled and accent == INDIGO:
		button.add_theme_stylebox_override("normal", NotebookSkin.indigo_button())
		button.add_theme_stylebox_override("hover", NotebookSkin.indigo_button())
		button.add_theme_stylebox_override("pressed", NotebookSkin.indigo_button())
		button.add_theme_stylebox_override("focus", NotebookSkin.indigo_button())
		button.add_theme_stylebox_override("disabled", _stylebox(PARCHMENT_DARK, MUTED_INK, 1, 2))
		button.add_theme_color_override("font_color", PARCHMENT_LIGHT)
		button.add_theme_color_override("font_hover_color", PARCHMENT_LIGHT)
		button.add_theme_color_override("font_pressed_color", PARCHMENT_LIGHT)
		button.add_theme_color_override("font_disabled_color", MUTED_INK)
		return
	var normal_background := accent if filled else PARCHMENT_LIGHT
	var normal_foreground := CHARCOAL if filled and accent == CHARTREUSE else WHITE if filled else CHARCOAL
	button.add_theme_stylebox_override("normal", _stylebox(normal_background, accent, 1, 5))
	button.add_theme_stylebox_override("hover", _stylebox(normal_background.lightened(0.09), accent.lightened(0.1), 1, 5))
	button.add_theme_stylebox_override("pressed", _stylebox(normal_background.darkened(0.09), accent, 2, 5))
	button.add_theme_stylebox_override("focus", _stylebox(PARCHMENT_LIGHT, VERMILION, 3, 4))
	button.add_theme_stylebox_override("disabled", _stylebox(PARCHMENT_DARK, MUTED_INK, 1, 4))
	button.add_theme_color_override("font_color", normal_foreground)
	button.add_theme_color_override("font_hover_color", normal_foreground)
	button.add_theme_color_override("font_pressed_color", normal_foreground)
	button.add_theme_color_override("font_disabled_color", MUTED_INK)

func _style_text_input(control: Control) -> void:
	control.add_theme_color_override("font_color", CHARCOAL)
	control.add_theme_color_override("font_readonly_color", MUTED_INK)
	control.add_theme_color_override("font_placeholder_color", MUTED_INK)
	control.add_theme_color_override("caret_color", VERMILION)
	control.add_theme_stylebox_override("normal", NotebookSkin.input_field())
	control.add_theme_stylebox_override("focus", NotebookSkin.input_field())
	control.add_theme_stylebox_override("read_only", NotebookSkin.input_field())

func _set_drawer_open(open: bool, animated: bool = true) -> void:
	_drawer_open = open
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()
	var target_x := 0.0 if open else DRAWER_WIDTH + DRAWER_GAP
	if open:
		_drawer_panel.visible = true
		_rail_panel.move_to_front()
	if not animated:
		_drawer_panel.position.x = target_x
		_drawer_panel.visible = open
		_refresh_team_card_styles()
		return
	_drawer_tween = create_tween()
	_drawer_tween.set_trans(Tween.TRANS_QUAD)
	_drawer_tween.set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	_drawer_tween.tween_property(_drawer_panel, "position:x", target_x, 0.16)
	if not open:
		_drawer_tween.finished.connect(func() -> void:
			if not _drawer_open:
				_drawer_panel.visible = false
		)
	_refresh_team_card_styles()

func close_drawer(animated: bool = true) -> void:
	_set_drawer_open(false, animated)

func open_drawer(animated: bool = true) -> void:
	_set_drawer_open(true, animated)

func drawer_is_open() -> bool:
	return _drawer_open

func rail_global_rect() -> Rect2:
	return _rail_panel.get_global_rect()

func drawer_global_rect() -> Rect2:
	return _drawer_panel.get_global_rect()

func _on_team_button_pressed(employee_id: String) -> void:
	var has_attention := employee_id == _attention_employee_id or (employee_id == _active_employee_id and not _approval_id.is_empty())
	var target_tab := 2 if has_attention else 0
	if _drawer_open and _selected_employee_id == employee_id and _tabs.current_tab == target_tab:
		close_drawer()
		return
	_select_employee(employee_id)
	_tabs.current_tab = target_tab
	open_drawer()

func _on_tab_changed(_tab: int) -> void:
	_refresh_employee_header()

func _unhandled_key_input(event: InputEvent) -> void:
	if _drawer_open and event.is_action_pressed("ui_cancel"):
		close_drawer()
		get_viewport().set_input_as_handled()

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
		button.text = ""
		button.tooltip_text = "Talk with %s" % record.display_name
		button.set_meta("display_name", record.display_name)
		button.custom_minimum_size = Vector2(100.0, 143.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_contents = true
		button.pressed.connect(_on_team_button_pressed.bind(record.id))
		var name_label := Label.new()
		name_label.name = "Name"
		name_label.text = record.display_name.to_upper()
		name_label.visible = false
		button.add_child(name_label)
		var status_dot := Label.new()
		status_dot.name = "StatusDot"
		status_dot.text = "●"
		status_dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_dot.add_theme_font_size_override("font_size", 18)
		status_dot.add_theme_color_override("font_color", Color("46b93f"))
		status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		status_dot.offset_left = -29.0
		status_dot.offset_top = 23.0
		status_dot.offset_right = -8.0
		status_dot.offset_bottom = 46.0
		button.add_child(status_dot)
		var attention_badge := Label.new()
		attention_badge.name = "AttentionBadge"
		attention_badge.text = "!"
		attention_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		attention_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		attention_badge.add_theme_font_size_override("font_size", 11)
		attention_badge.add_theme_color_override("font_color", OFF_WHITE)
		attention_badge.add_theme_stylebox_override("normal", _stylebox(VERMILION, WOOD_DARK, 2, 8))
		attention_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		attention_badge.visible = false
		attention_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		attention_badge.offset_left = 2.0
		attention_badge.offset_top = 2.0
		attention_badge.offset_right = 20.0
		attention_badge.offset_bottom = 20.0
		button.add_child(attention_badge)
		list.add_child(button)
		_team_buttons[record.id] = button
	_refresh_team_statuses()
	_assign_button.disabled = records.is_empty() or not _active_job_id.is_empty()
	if records.is_empty():
		_selected_employee_id = ""
		_refresh_employee_header()
		_refresh_chat_mode()
		_show_empty_chat()
		close_drawer(false)
		return
	var wanted := _selected_employee_id
	if wanted.is_empty() or not _team_buttons.has(wanted):
		wanted = records[0].id
	_select_employee(wanted)
	close_drawer(false)

func select_employee(employee_id: String) -> void:
	_select_employee(employee_id)
	open_drawer(false)

func _select_employee(employee_id: String) -> void:
	if not _team_buttons.has(employee_id):
		return
	_selected_employee_id = employee_id
	_refresh_team_card_styles()
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

func _refresh_team_card_styles() -> void:
	var selected := _drawer_open and not _selected_employee_id.is_empty()
	_rail_panel.add_theme_stylebox_override(
		"panel",
		NotebookSkin.team_rail(_selected_employee_id, selected, _employees.is_empty())
	)
	for id: String in _team_buttons:
		var button: Button = _team_buttons[id]
		var empty_style := StyleBoxEmpty.new()
		button.add_theme_stylebox_override("normal", empty_style)
		button.add_theme_stylebox_override("hover", empty_style)
		button.add_theme_stylebox_override("pressed", empty_style)
		button.add_theme_stylebox_override("focus", empty_style)

func _selected_employee() -> EmployeeRecord:
	for record: EmployeeRecord in _employees:
		if record.id == _selected_employee_id:
			return record
	return null

func _refresh_employee_header() -> void:
	if _tabs != null and _tabs.current_tab == 3:
		_employee_name.text = "Studio"
		_employee_meta.text = "Approved deliveries"
		_employee_status.text = "● shared team files"
		_employee_status.add_theme_color_override("font_color", INDIGO)
		_employee_portrait.texture = null
		_header_icon.visible = true
		return
	var employee := _selected_employee()
	if employee == null:
		_employee_name.text = "Your team"
		_employee_meta.text = "No employee selected"
		_employee_status.text = ""
		_employee_portrait.texture = null
		_header_icon.visible = false
		return
	_employee_name.text = employee.display_name
	_employee_portrait.texture = CharacterArt.bust_portrait(employee.id)
	_header_icon.visible = false
	var activity := "working" if _active_employee_id == employee.id else "at lunch" if _clock_phase == "lunch" else "off shift" if _clock_phase == "off" else "available"
	_employee_meta.text = _employee_specialty(employee.id)
	_employee_status.text = "● %s" % activity
	_employee_status.add_theme_color_override("font_color", VERMILION if activity == "working" or activity == "at lunch" else DUST if activity == "off shift" else Color("77b83f"))

func _refresh_team_statuses() -> void:
	for employee_id: String in _team_buttons:
		var button: Button = _team_buttons[employee_id]
		var status_dot := button.get_node_or_null("StatusDot") as Label
		var attention_badge := button.get_node_or_null("AttentionBadge") as Label
		if status_dot == null:
			continue
		var color := CHARTREUSE
		var state := "available"
		if employee_id == _active_employee_id and not _active_job_id.is_empty():
			color = VERMILION if _active_job_running else CERULEAN
			state = "working" if _active_job_running else "queued"
		elif _clock_phase == "lunch":
			color = VERMILION
			state = "at lunch"
		elif _clock_phase == "off":
			color = DUST
			state = "off shift"
		status_dot.add_theme_color_override("font_color", color)
		status_dot.visible = state != "available"
		button.tooltip_text = "%s · %s" % [button.get_node("Name").text.capitalize(), state]
		if attention_badge != null:
			attention_badge.visible = (employee_id == _active_employee_id and not _approval_id.is_empty()) or employee_id == _attention_employee_id

func _employee_specialty(employee_id: String) -> String:
	return "Product + research" if employee_id == "mira" else "Growth + operations"

func _safe_bbcode(value: String) -> String:
	return value.replace("[", "﹇").replace("]", "﹈").replace("**", "")

func _show_empty_chat() -> void:
	_clear_chat()
	var employee := _selected_employee()
	if employee == null:
		_show_chat_hint("Choose a teammate from the rail.")
		return
	var greeting := "What are we building? Talk it through with me, then turn it into a work order." if employee.id == "mira" else "What should we test or grow? We can sharpen the idea before assigning it."
	_append_chat_line("employee", employee.display_name, greeting)

func _append_chat_line(sender: String, name_value: String, content: String) -> void:
	_chat_transcript += "%s\n%s\n\n" % [name_value, content]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if sender == "employee":
		var avatar_frame := PanelContainer.new()
		avatar_frame.custom_minimum_size = Vector2(54.0, 58.0)
		avatar_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		avatar_frame.add_theme_stylebox_override("panel", _stylebox(PARCHMENT, WOOD, 2, 2))
		row.add_child(avatar_frame)
		var avatar := TextureRect.new()
		var employee := _selected_employee()
		avatar.texture = CharacterArt.bust_portrait(employee.id) if employee != null else null
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		avatar_frame.add_child(avatar)
	else:
		var player_spacer := Control.new()
		player_spacer.custom_minimum_size = Vector2(42.0, 0.0)
		row.add_child(player_spacer)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _stylebox(PARCHMENT_LIGHT, WOOD if sender == "employee" else CERULEAN, 2, 3))
	row.add_child(bubble)
	var bubble_margin := MarginContainer.new()
	bubble_margin.add_theme_constant_override("margin_left", 10)
	bubble_margin.add_theme_constant_override("margin_right", 10)
	bubble_margin.add_theme_constant_override("margin_top", 8)
	bubble_margin.add_theme_constant_override("margin_bottom", 8)
	bubble.add_child(bubble_margin)
	var message_label := Label.new()
	message_label.text = content
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", CHARCOAL)
	bubble_margin.add_child(message_label)
	_chat_log.add_child(row)
	call_deferred("_scroll_chat_to_bottom")

func _clear_chat() -> void:
	_chat_transcript = ""
	_last_chat_prompt = ""
	if _make_job_button != null:
		_make_job_button.disabled = true
	for child: Node in _chat_log.get_children():
		_chat_log.remove_child(child)
		child.queue_free()

func _show_chat_hint(message: String) -> void:
	var hint := Label.new()
	hint.text = message
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", MUTED_INK)
	_chat_log.add_child(hint)

func _scroll_chat_to_bottom() -> void:
	if _chat_scroll != null:
		_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)

func chat_text() -> String:
	return _chat_transcript

func show_chat_history(employee_id: String, messages: Array) -> void:
	if employee_id != _selected_employee_id:
		return
	_clear_chat()
	if messages.is_empty():
		_show_empty_chat()
		return
	var employee := _selected_employee()
	for value: Variant in messages:
		if not value is Dictionary:
			continue
		var message := value as Dictionary
		var sender := str(message.get("sender", "employee"))
		var content := str(message.get("content", ""))
		if sender == "player":
			_last_chat_prompt = content
		_append_chat_line(sender, "Founder" if sender == "player" else employee.display_name, content)
	_make_job_button.disabled = _last_chat_prompt.is_empty() or not _active_job_id.is_empty()

func show_chat_reply(employee_id: String, message: Dictionary, daily_spend: float) -> void:
	_chat_pending = false
	_refresh_chat_mode()
	set_spend(daily_spend, _spend_warning)
	if employee_id != _selected_employee_id:
		return
	var employee := _selected_employee()
	_append_chat_line("employee", employee.display_name, str(message.get("content", "")))
	_set_status("%s replied. Turn the idea into a work order when it is ready." % employee.display_name)

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
		_chat_send_button.text = "UPDATE"
		_chat_input.placeholder_text = "Update %s's active job…" % _selected_employee().display_name
	elif chat_blocked:
		_chat_send_button.text = "QUEUED" if not _active_job_running else "BUSY"
		_chat_input.placeholder_text = "Wait for the current work order"
	else:
		_chat_send_button.text = "SEND"
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
	_set_status("Cancelling the active work order…", VERMILION)
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
	_set_status("Sending update to the active work session…", CERULEAN)
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
	_usage_label.text = "Tokens  0 in / 0 out  ·  cost $0.0000"
	_event_log.clear()
	_approval_job_id = ""
	_approval_id = ""
	_approval_box.visible = false
	_assign_button.disabled = true
	_assign_button.text = "One job at a time"
	_cancel_button.disabled = false
	_steer_box.visible = false
	_steer_button.disabled = false
	_steer_input.clear()
	_set_status("Submitting work order…", CERULEAN)
	_tabs.current_tab = 2
	_refresh_employee_header()
	_refresh_team_statuses()
	_refresh_chat_mode()
	close_drawer()

func mark_job_queued(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_set_status("Queued. Work begins automatically during the next work window.", CERULEAN)
	_active_job_running = false
	_assign_button.text = "Queued until work hours"
	_steer_box.visible = false
	_refresh_team_statuses()

func restore_job(job_id: String, status: String, title: String, employee_id: String = "") -> void:
	if status != "queued" and status != "running":
		return
	_active_job_id = job_id
	_active_employee_id = employee_id
	_active_job_running = status == "running"
	_assign_button.disabled = true
	_cancel_button.disabled = false
	_assign_button.text = "Queued until work hours" if status == "queued" else "One job at a time"
	_set_status("%s  ·  restored %s" % [title, status], CERULEAN)
	_steer_box.visible = status == "running"
	_refresh_employee_header()
	_refresh_chat_mode()
	_refresh_team_statuses()

func finish_job(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_active_job_id = ""
	_active_employee_id = ""
	_active_job_running = false
	if _approval_job_id == job_id:
		_approval_job_id = ""
		_approval_id = ""
		_approval_box.visible = false
	_assign_button.disabled = _employees.is_empty()
	_update_assign_copy()
	_cancel_button.disabled = true
	_steer_box.visible = false
	_steer_button.disabled = false
	_steer_input.clear()
	_refresh_employee_header()
	_refresh_chat_mode()
	_refresh_team_statuses()

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
	_set_status("Update delivered to the same active work session.", CERULEAN)

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

func work_controls_fit_panel() -> bool:
	var drawer_rect := _drawer_panel.get_global_rect()
	return _key_input.get_global_rect().end.x <= drawer_rect.end.x \
		and _assign_button.get_global_rect().end.x <= drawer_rect.end.x \
		and _cancel_button.get_global_rect().end.x <= drawer_rect.end.x

func status_color() -> Color:
	return _status_label.get_theme_color("font_color")

func set_worker_ready() -> void:
	if _active_job_id.is_empty():
		_set_status("Worker connected. Chat with a teammate or assign work.")

func set_clock_phase(phase: String) -> void:
	_clock_phase = phase
	_update_assign_copy()
	_refresh_employee_header()
	_refresh_team_statuses()
	if _active_job_id.is_empty() and phase != "work":
		_set_status("Lunch — new work queues until 13:30." if phase == "lunch" else "Off hours — new work queues until 08:00.", VERMILION if phase == "lunch" else MUTED_INK)

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
	_key_status.add_theme_color_override("font_color", INDIGO if configured else VERMILION)

func set_credential_saved() -> void:
	set_credential_status(true)
	_set_status("OpenRouter key saved.", INDIGO)

func set_spend(daily_spend: float, warning: float) -> void:
	_spend_warning = warning
	_spend_label.text = "Today  $%.4f  · warning at $%.2f" % [daily_spend, warning]
	_spend_label.add_theme_color_override("font_color", VERMILION if daily_spend >= warning else MUTED_INK)

func set_error(message: String) -> void:
	_set_status(message, VERMILION)

func set_info(message: String) -> void:
	_set_status(message)

func _set_status(message: String, color: Color = CHARCOAL) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)

func on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	var line := ""
	match event.type:
		&"job.queued":
			mark_job_queued(job_id)
			line = "[color=#fa4616]queued[/color] · %s" % _safe_bbcode(event.reason)
		&"job.started":
			_set_status("Employee is walking to their desk.", INDIGO)
			if job_id == _active_job_id:
				_active_job_running = true
				_steer_box.visible = true
				_steer_button.disabled = false
				_refresh_chat_mode()
				_refresh_employee_header()
				_refresh_team_statuses()
			line = "[color=#354b98]job started[/color]"
		&"agent.thinking":
			_set_status(event.summary)
			line = "thinking · %s" % _safe_bbcode(event.summary)
		&"tool.started":
			_set_status(event.label, CERULEAN)
			line = "[color=#6196c1]tool[/color] · %s" % _safe_bbcode(event.tool)
		&"tool.completed":
			line = "%s · %s" % [_safe_bbcode(event.tool), "done" if event.ok else "failed"]
		&"approval.required":
			_approval_job_id = job_id
			_approval_id = event.approval_id
			_approval_label.text = event.action
			_approval_box.visible = true
			_tabs.current_tab = 2
			_set_status("A decision is needed before work can continue.", VERMILION)
			_refresh_team_statuses()
			line = "[color=#fa4616]approval required[/color]"
		&"artifact.created":
			line = "[color=#354b98]delivery[/color] · %s" % _safe_bbcode(event.name)
		&"usage.updated":
			_usage_label.text = "Tokens  %d in / %d out  ·  cost $%.4f" % [event.input_tokens, event.output_tokens, event.cost]
			line = "usage · %d tokens · $%.4f" % [event.input_tokens + event.output_tokens, event.cost]
		&"job.blocked":
			_set_status(event.reason, VERMILION)
			line = "[color=#fa4616]blocked[/color] · %s" % _safe_bbcode(event.reason)
			finish_job(job_id)
		&"job.completed":
			_set_status(event.summary, INDIGO)
			line = "[color=#354b98]completed[/color]"
			finish_job(job_id)
		&"job.failed":
			_set_status(event.error, VERMILION)
			line = "[color=#fa4616]failed[/color] · %s" % _safe_bbcode(event.error)
			finish_job(job_id)
	if not line.is_empty():
		_event_log.append_text("• %s\n" % line)
		_event_log.scroll_to_line(maxi(0, _event_log.get_line_count() - 1))

func _decide_approval(approved: bool) -> void:
	approval_decided.emit(_approval_job_id, _approval_id, approved)
	_approval_box.visible = false
	_approval_job_id = ""
	_approval_id = ""
	_refresh_team_statuses()

func offer_promotion(job_id: String, employee_id: String = "") -> void:
	_promotion_job_id = job_id
	_attention_employee_id = employee_id
	_promotion_label.text = "Add this delivery to the durable studio?"
	_promotion_box.visible = true
	_tabs.current_tab = 2
	_refresh_team_statuses()

func _decide_promotion(approved: bool) -> void:
	var job_id := _promotion_job_id
	_promotion_job_id = ""
	_attention_employee_id = ""
	promotion_decided.emit(job_id, approved)
	_promotion_box.visible = false
	_refresh_team_statuses()
	_set_status("Adding approved delivery to studio/…" if approved else "Delivery discarded.", CHARTREUSE if approved else DUST)

func show_pending_promotions(pending_promotions: Array) -> void:
	if pending_promotions.is_empty():
		_promotion_job_id = ""
		_attention_employee_id = ""
		_promotion_box.visible = false
		_refresh_team_statuses()
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
	_attention_employee_id = _employee_id_for_name(str(candidate.get("employeeName", "")))
	_promotion_label.text = "%s finished “%s”. Add to studio or discard: %s" % [
		str(candidate.get("employeeName", "Employee")),
		str(candidate.get("title", "Work order")),
		", ".join(artifact_names) if not artifact_names.is_empty() else "completed artifacts",
	]
	_promotion_box.visible = true
	_refresh_team_statuses()

func _employee_id_for_name(display_name: String) -> String:
	for employee: EmployeeRecord in _employees:
		if employee.display_name == display_name:
			return employee.id
	return ""

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
		_style_action_button(button, CERULEAN, false)
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
		_style_action_button(button, CERULEAN, false)
		_artifact_list.add_child(button)

func _clear_artifact_list() -> void:
	for child: Node in _artifact_list.get_children():
		child.queue_free()

func _add_empty_artifact(message: String) -> void:
	var empty := Label.new()
	empty.text = message
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty.add_theme_color_override("font_color", MUTED_INK)
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
