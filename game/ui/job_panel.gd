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
const ALERT_INK := Color("963014")
const SUCCESS_INK := Color("365d1f")
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
var _chat_messages: Array[Dictionary] = []

var _employee_name: Label
var _employee_meta: Label
var _employee_status: Label
var _employee_portrait: TextureRect
var _header_icon: TextureRect
var _drawer_panel: Panel
var _rail_panel: Panel
var _drawer_close_button: Button
var _drawer_open: bool = false
var _drawer_tween: Tween
var _tab_tween: Tween
var _status_tween: Tween
var _waiting_elapsed: float = 0.0
var _tabs: TabContainer
var _chat_scroll: ScrollContainer
var _chat_log: VBoxContainer
var _chat_transcript: String = ""
var _chat_input: LineEdit
var _chat_send_button: Button
var _make_job_button: Button
var _chat_helper: Label
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
var _token_meter: ProgressBar
var _last_status_label: Label
var _event_log: RichTextLabel
var _artifact_list: VBoxContainer
var _approval_box: PanelContainer
var _approval_label: Label
var _approval_job_id: String = ""
var _approval_id: String = ""
var _active_job_id: String = ""
var _promotion_box: PanelContainer
var _promotion_label: Label
var _promotion_job_id: String = ""
var _attention_employee_id: String = ""
var _clock_phase: String = "work"
var _custom_mode: bool = false
var _spend_warning: float = 5.0
var _active_job_running: bool = false
var _credential_configured: bool = false
var _worker_connected: bool = false
var _connection_panel: Panel
var _settings_button: Button
var _connection_badge: Label

func _ready() -> void:
	theme = GameFonts.interface_theme()
	_build_interface()
	_set_drawer_open(false, false)

func _process(delta: float) -> void:
	if not _chat_pending or _chat_send_button == null:
		_waiting_elapsed = 0.0
		return
	_waiting_elapsed += delta
	var dots := int(_waiting_elapsed * 4.0) % 3 + 1
	_chat_send_button.text = ".".repeat(dots)

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
	_rail_panel.add_theme_stylebox_override("panel", NotebookSkin.wood_surface(Vector4(12.0, 12.0, 12.0, 12.0)))
	add_child(_rail_panel)
	_add_outer_frame(_rail_panel)
	var team_rail := _build_team_rail()
	team_rail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rail_panel.add_child(team_rail)
	_build_connection_panel()

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
	var heading := PanelContainer.new()
	heading.position = Vector2(15.0, 18.0)
	heading.size = Vector2(100.0, 52.0)
	heading.add_theme_stylebox_override("panel", NotebookSkin.name_plaque())
	rail.add_child(heading)
	var heading_label := Label.new()
	heading_label.text = "TEAM"
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading_label.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	GameFonts.use_display(heading_label)
	heading_label.add_theme_color_override("font_color", CHARCOAL)
	heading.add_child(heading_label)
	var team_list := VBoxContainer.new()
	team_list.name = "TeamList"
	team_list.add_theme_constant_override("separation", 4)
	team_list.set_anchors_preset(Control.PRESET_TOP_WIDE)
	team_list.offset_left = 15.0
	team_list.offset_top = 82.0
	team_list.offset_right = -15.0
	team_list.offset_bottom = 366.0
	rail.add_child(team_list)
	_settings_button = Button.new()
	_settings_button.text = "SETTINGS"
	_settings_button.position = Vector2(15.0, 662.0)
	_settings_button.size = Vector2(100.0, 42.0)
	_settings_button.tooltip_text = "Open connection settings"
	_settings_button.pressed.connect(_open_connection_settings)
	_style_action_button(_settings_button, INDIGO, false)
	rail.add_child(_settings_button)
	_connection_badge = Label.new()
	_connection_badge.text = "!"
	_connection_badge.visible = false
	_connection_badge.position = Vector2(92.0, 654.0)
	_connection_badge.size = Vector2(24.0, 24.0)
	_connection_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_connection_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_connection_badge.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	GameFonts.use_display(_connection_badge)
	_connection_badge.add_theme_color_override("font_color", VERMILION)
	rail.add_child(_connection_badge)
	return rail

func _build_connection_panel() -> void:
	_connection_panel = Panel.new()
	_connection_panel.name = "ConnectionPanel"
	_connection_panel.visible = false
	_connection_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_connection_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_connection_panel.offset_right = DRAWER_WIDTH
	_connection_panel.add_theme_stylebox_override("panel", NotebookSkin.wood_surface(Vector4(14.0, 14.0, 14.0, 14.0)))
	add_child(_connection_panel)
	_add_outer_frame(_connection_panel)
	var page := PanelContainer.new()
	page.position = Vector2(14.0, 28.0)
	page.size = Vector2(DRAWER_WIDTH - 28.0, 430.0)
	page.add_theme_stylebox_override("panel", NotebookSkin.parchment(Vector4(18.0, 18.0, 18.0, 18.0)))
	_connection_panel.add_child(page)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	page.add_child(content)
	var title := Label.new()
	title.text = "CONNECT AI"
	title.add_theme_font_size_override("font_size", GameFonts.DISPLAY_LARGE)
	GameFonts.use_display(title)
	title.add_theme_color_override("font_color", CHARCOAL)
	content.add_child(title)
	var description := Label.new()
	description.text = "Add one OpenRouter key to chat with teammates and run work orders. The key is stored in your OS keychain."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", GameFonts.BODY_DEFAULT)
	description.add_theme_color_override("font_color", CHARCOAL)
	content.add_child(description)
	_key_input = LineEdit.new()
	_key_input.secret = true
	_key_input.placeholder_text = "Paste OpenRouter key"
	_key_input.custom_minimum_size.y = 48.0
	_key_input.text_submitted.connect(func(_value: String) -> void: _submit_key())
	_style_text_input(_key_input)
	content.add_child(_key_input)
	var save_button := Button.new()
	save_button.text = "SAVE CONNECTION"
	save_button.custom_minimum_size.y = 48.0
	save_button.pressed.connect(_submit_key)
	_style_action_button(save_button, VERMILION, true)
	content.add_child(save_button)
	_key_status = Label.new()
	_key_status.text = "Checking OS keychain…"
	_key_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_key_status.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	_key_status.add_theme_color_override("font_color", CHARCOAL)
	content.add_child(_key_status)
	var close_button := Button.new()
	close_button.text = "BACK TO GAME"
	close_button.custom_minimum_size.y = 44.0
	close_button.pressed.connect(_close_connection_settings)
	_style_action_button(close_button, INDIGO, false)
	content.add_child(close_button)

func _open_connection_settings() -> void:
	open_drawer(false)
	_connection_panel.visible = true
	_connection_panel.move_to_front()
	_rail_panel.move_to_front()
	_key_input.grab_focus()

func _close_connection_settings() -> void:
	_connection_panel.visible = false
	if _drawer_open:
		_drawer_panel.move_to_front()
		_rail_panel.move_to_front()

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
	_header_icon = TextureRect.new()
	_header_icon.texture = OperationsSkin.ICON_FOLDER
	_header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	_employee_name.add_theme_font_size_override("font_size", GameFonts.DISPLAY_LARGE)
	GameFonts.use_display(_employee_name)
	_employee_name.add_theme_color_override("font_color", CHARCOAL)
	employee_copy.add_child(_employee_name)
	_employee_meta = Label.new()
	_employee_meta.text = "Select an employee"
	_employee_meta.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	_employee_meta.add_theme_color_override("font_color", INDIGO)
	_employee_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	employee_copy.add_child(_employee_meta)
	_employee_status = Label.new()
	_employee_status.text = "AVAILABLE"
	_employee_status.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	_employee_status.add_theme_color_override("font_color", SUCCESS_INK)
	employee_copy.add_child(_employee_status)
	_drawer_close_button = Button.new()
	_drawer_close_button.text = ""
	_drawer_close_button.icon = OperationsSkin.CLOSE_BUTTON
	_drawer_close_button.expand_icon = true
	_drawer_close_button.tooltip_text = "Close team drawer"
	_drawer_close_button.pressed.connect(close_drawer)
	_style_close_button(_drawer_close_button)
	_drawer_close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_drawer_close_button.offset_left = -50.0
	_drawer_close_button.offset_top = 8.0
	_drawer_close_button.offset_right = -20.0
	_drawer_close_button.offset_bottom = 38.0
	header_shell.add_child(_drawer_close_button)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	GameFonts.use_display(_tabs)
	_tabs.add_theme_color_override("font_selected_color", CHARCOAL)
	_tabs.add_theme_color_override("font_unselected_color", CHARCOAL)
	_tabs.add_theme_stylebox_override("panel", NotebookSkin.wood_surface(Vector4(5.0, 5.0, 5.0, 5.0)))
	_tabs.add_theme_stylebox_override("tab_selected", NotebookSkin.selected_tab())
	_tabs.add_theme_stylebox_override("tab_unselected", NotebookSkin.wood_tab())
	_tabs.add_theme_stylebox_override("tab_hovered", NotebookSkin.wood_tab())
	_tabs.get_tab_bar().custom_minimum_size.y = 40.0
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
	OperationsSkin.style_scroll_container(scroll)
	return scroll

func _tab_content(scroll: ScrollContainer) -> VBoxContainer:
	var page := PanelContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", NotebookSkin.parchment(Vector4(14.0, 12.0, 14.0, 12.0)))
	scroll.add_child(page)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(288.0, 0.0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	page.add_child(content)
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
	OperationsSkin.style_scroll_container(_chat_scroll)
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
	var composer_column := VBoxContainer.new()
	composer_column.add_theme_constant_override("separation", 5)
	composer_margin.add_child(composer_column)
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	composer_column.add_child(input_row)
	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Talk through an idea…"
	_chat_input.max_length = 2000
	_chat_input.custom_minimum_size = Vector2(0.0, 48.0)
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.text_submitted.connect(_submit_chat_text)
	_style_text_input(_chat_input)
	input_row.add_child(_chat_input)
	_chat_send_button = Button.new()
	_chat_send_button.text = "ASK"
	_chat_send_button.custom_minimum_size = Vector2(88.0, 48.0)
	_chat_send_button.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	_chat_send_button.pressed.connect(_submit_chat)
	_style_action_button(_chat_send_button, VERMILION, true)
	input_row.add_child(_chat_send_button)
	_chat_helper = Label.new()
	_chat_helper.text = "Conversation only — no tools or files."
	_chat_helper.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	_chat_helper.add_theme_color_override("font_color", CHARCOAL)
	_chat_helper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	composer_column.add_child(_chat_helper)
	_make_job_button = Button.new()
	_make_job_button.text = "CREATE WORK ORDER"
	_make_job_button.custom_minimum_size = Vector2(0.0, 48.0)
	_make_job_button.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	_make_job_button.disabled = true
	_make_job_button.visible = false
	_make_job_button.pressed.connect(_make_last_chat_a_job)
	_style_action_button(_make_job_button, VERMILION, true)
	tab.add_child(_make_job_button)
	return tab

func _build_work_tab() -> ScrollContainer:
	var scroll := _tab_scroll("Assign")
	var content := _tab_content(scroll)
	content.add_child(_section_label("WORK ORDER"))
	_job_picker = OptionButton.new()
	_job_picker.fit_to_longest_item = false
	_job_picker.clip_text = true
	_job_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_job_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_dropdown(_job_picker)
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
	OperationsSkin.style_text_edit_scrollbar(_assignment_preview)
	content.add_child(_assignment_preview)
	_attachment_label = _section_label("READ CONTEXT (OPTIONAL)")
	_attachment_label.visible = false
	content.add_child(_attachment_label)
	_attachment_picker = OptionButton.new()
	_attachment_picker.fit_to_longest_item = false
	_attachment_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_picker.visible = false
	_style_dropdown(_attachment_picker)
	_attachment_picker.add_item("No studio file attached")
	_attachment_picker.set_item_metadata(0, "")
	content.add_child(_attachment_picker)
	var confirmation := Label.new()
	confirmation.text = "Starts an AI work session that can use approved tools, create files, and spend from your configured budget."
	confirmation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmation.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	confirmation.add_theme_color_override("font_color", CHARCOAL)
	content.add_child(confirmation)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	content.add_child(action_row)
	_assign_button = Button.new()
	_assign_button.text = "START WORK ORDER"
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
	var scroll := _tab_scroll("Activity")
	var content := _tab_content(scroll)
	var status_card := PanelContainer.new()
	status_card.add_theme_stylebox_override("panel", OperationsSkin.journal_work_card())
	content.add_child(status_card)
	var status_content := VBoxContainer.new()
	status_content.add_theme_constant_override("separation", 3)
	status_card.add_child(status_content)
	var status_heading := _section_label("CURRENT WORK")
	status_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_heading.add_theme_color_override("font_color", OFF_WHITE)
	status_content.add_child(status_heading)
	_status_label = Label.new()
	_status_label.text = "No active work order."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.max_lines_visible = 5
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.add_theme_color_override("font_color", CHARCOAL)
	status_content.add_child(_status_label)
	_usage_label = Label.new()
	_usage_label.text = "Usage details  ·  0 tokens"
	_usage_label.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	_usage_label.add_theme_color_override("font_color", CHARCOAL)
	status_content.add_child(_usage_label)
	_spend_label = Label.new()
	_spend_label.text = "AI spend today  ·  $0.0000"
	_spend_label.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	_spend_label.add_theme_color_override("font_color", CHARCOAL)
	status_content.add_child(_spend_label)
	_token_meter = ProgressBar.new()
	_token_meter.custom_minimum_size = Vector2(0.0, 24.0)
	_token_meter.min_value = 0.0
	_token_meter.max_value = _spend_warning
	_token_meter.value = 0.0
	_token_meter.show_percentage = false
	_token_meter.add_theme_stylebox_override("background", OperationsSkin.token_meter())
	var meter_fill := StyleBoxFlat.new()
	meter_fill.bg_color = INDIGO
	meter_fill.border_color = WOOD_DARK
	meter_fill.set_border_width_all(1)
	meter_fill.set_corner_radius_all(2)
	meter_fill.content_margin_left = 4.0
	meter_fill.content_margin_right = 4.0
	_token_meter.add_theme_stylebox_override("fill", meter_fill)
	status_content.add_child(_token_meter)
	_last_status_label = Label.new()
	_last_status_label.text = "Last work order  ·  none yet"
	_last_status_label.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	_last_status_label.add_theme_color_override("font_color", CHARCOAL)
	_last_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_content.add_child(_last_status_label)
	_approval_box = PanelContainer.new()
	_approval_box.visible = false
	_approval_box.add_theme_stylebox_override("panel", OperationsSkin.journal_approval_card())
	var approval_content := VBoxContainer.new()
	approval_content.add_theme_constant_override("separation", 5)
	_approval_box.add_child(approval_content)
	var approval_heading := _section_label("ACTION REQUIRED")
	approval_heading.add_theme_color_override("font_color", ALERT_INK)
	approval_content.add_child(approval_heading)
	_approval_label = Label.new()
	_approval_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_approval_label.add_theme_color_override("font_color", CHARCOAL)
	approval_content.add_child(_approval_label)
	var approval_buttons := HBoxContainer.new()
	approval_buttons.add_theme_constant_override("separation", 6)
	var approve_button := Button.new()
	approve_button.text = "Approve"
	approve_button.pressed.connect(_decide_approval.bind(true))
	_style_action_button(approve_button, VERMILION, true)
	approval_buttons.add_child(approve_button)
	var deny_button := Button.new()
	deny_button.text = "Deny"
	deny_button.pressed.connect(_decide_approval.bind(false))
	_style_action_button(deny_button, INDIGO, false)
	approval_buttons.add_child(deny_button)
	approval_content.add_child(approval_buttons)
	content.add_child(_approval_box)
	_promotion_box = PanelContainer.new()
	_promotion_box.visible = false
	_promotion_box.add_theme_stylebox_override("panel", OperationsSkin.journal_delivery_card())
	var promotion_content := VBoxContainer.new()
	promotion_content.add_theme_constant_override("separation", 5)
	_promotion_box.add_child(promotion_content)
	var promotion_heading := _section_label("DELIVERY READY")
	promotion_heading.add_theme_color_override("font_color", INDIGO)
	promotion_content.add_child(promotion_heading)
	_promotion_label = Label.new()
	_promotion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_promotion_label.add_theme_color_override("font_color", CHARCOAL)
	promotion_content.add_child(_promotion_label)
	var promotion_buttons := HBoxContainer.new()
	promotion_buttons.add_theme_constant_override("separation", 6)
	var promote_button := Button.new()
	promote_button.text = "ADD TO STUDIO"
	promote_button.pressed.connect(_decide_promotion.bind(true))
	_style_action_button(promote_button, VERMILION, true)
	promotion_buttons.add_child(promote_button)
	var discard_button := Button.new()
	discard_button.text = "KEEP WITH JOB"
	discard_button.pressed.connect(_decide_promotion.bind(false))
	_style_action_button(discard_button, INDIGO, false)
	promotion_buttons.add_child(discard_button)
	promotion_content.add_child(promotion_buttons)
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
	_steer_button.text = "SEND"
	_steer_button.pressed.connect(_submit_steer)
	_style_action_button(_steer_button, VERMILION, true)
	steer_row.add_child(_steer_button)
	content.add_child(_steer_box)
	content.add_child(_section_label("LIVE ACTIVITY"))
	_event_log = RichTextLabel.new()
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.scroll_active = true
	_event_log.custom_minimum_size = Vector2(0.0, 220.0)
	_event_log.add_theme_color_override("default_color", CHARCOAL)
	_event_log.add_theme_stylebox_override("normal", OperationsSkin.activity_log())
	OperationsSkin.style_rich_text_scrollbar(_event_log)
	content.add_child(_event_log)
	return scroll

func _build_studio_tab() -> ScrollContainer:
	var scroll := _tab_scroll("Studio")
	var content := _tab_content(scroll)
	var intro := Label.new()
	intro.text = "Files added to Studio remain available to future teammates."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", CHARCOAL)
	var intro_card := PanelContainer.new()
	intro_card.add_theme_stylebox_override("panel", OperationsSkin.file_card())
	intro_card.add_child(intro)
	content.add_child(intro_card)
	_artifact_list = VBoxContainer.new()
	_artifact_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_artifact_list)
	_add_empty_artifact("Approved files will appear here.")
	return scroll

func _section_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	GameFonts.use_display(label)
	label.add_theme_color_override("font_color", INDIGO)
	return label

func _style_action_button(button: Button, accent: Color, filled: bool) -> void:
	GameFonts.use_display(button)
	button.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 40.0)
	button.button_down.connect(_animate_button_press.bind(button, true))
	button.button_up.connect(_animate_button_press.bind(button, false))
	if filled and accent == VERMILION:
		button.add_theme_stylebox_override("normal", NotebookSkin.selected_tab())
		button.add_theme_stylebox_override("hover", NotebookSkin.texture_style(NotebookSkin.TAB_VERMILION, Vector4(10.0, 9.0, 10.0, 9.0), Vector4(19.0, 7.0, 19.0, 7.0), true, Color("fff0e8")))
		button.add_theme_stylebox_override("pressed", NotebookSkin.texture_style(NotebookSkin.TAB_VERMILION, Vector4(10.0, 9.0, 10.0, 9.0), Vector4(19.0, 8.0, 19.0, 6.0), true, Color("c67a68")))
		button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
		button.add_theme_stylebox_override("disabled", OperationsSkin.secondary_button("disabled"))
		button.add_theme_color_override("font_color", CHARCOAL)
		button.add_theme_color_override("font_hover_color", CHARCOAL)
		button.add_theme_color_override("font_pressed_color", CHARCOAL)
		button.add_theme_color_override("font_disabled_color", MUTED_INK)
		return
	if filled:
		button.add_theme_stylebox_override("normal", OperationsSkin.primary_button())
		button.add_theme_stylebox_override("hover", OperationsSkin.primary_button("hover"))
		button.add_theme_stylebox_override("pressed", OperationsSkin.primary_button("pressed"))
		button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
		button.add_theme_stylebox_override("disabled", OperationsSkin.secondary_button("disabled"))
		button.add_theme_color_override("font_color", PARCHMENT_LIGHT)
		button.add_theme_color_override("font_hover_color", PARCHMENT_LIGHT)
		button.add_theme_color_override("font_pressed_color", PARCHMENT_LIGHT)
		button.add_theme_color_override("font_disabled_color", MUTED_INK)
		return
	button.add_theme_stylebox_override("normal", OperationsSkin.secondary_button())
	button.add_theme_stylebox_override("hover", OperationsSkin.secondary_button("hover"))
	button.add_theme_stylebox_override("pressed", OperationsSkin.secondary_button("pressed"))
	button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
	button.add_theme_stylebox_override("disabled", OperationsSkin.secondary_button("disabled"))
	button.add_theme_color_override("font_color", CHARCOAL)
	button.add_theme_color_override("font_hover_color", CHARCOAL)
	button.add_theme_color_override("font_pressed_color", CHARCOAL)
	button.add_theme_color_override("font_disabled_color", MUTED_INK)

func _style_dropdown(option: OptionButton) -> void:
	GameFonts.use_display(option)
	option.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	option.custom_minimum_size.y = 44.0
	option.add_theme_stylebox_override("normal", OperationsSkin.dropdown())
	option.add_theme_stylebox_override("hover", OperationsSkin.dropdown())
	option.add_theme_stylebox_override("pressed", OperationsSkin.dropdown_selected_row())
	option.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
	option.add_theme_stylebox_override("disabled", OperationsSkin.secondary_button("disabled"))
	option.add_theme_icon_override("arrow", OperationsSkin.TRANSPARENT)
	option.add_theme_color_override("font_color", CHARCOAL)
	option.add_theme_color_override("font_hover_color", CHARCOAL)
	option.add_theme_color_override("font_pressed_color", CHARCOAL)
	var popup := option.get_popup()
	popup.add_theme_stylebox_override("panel", NotebookSkin.parchment())
	popup.add_theme_stylebox_override("hover", OperationsSkin.dropdown_selected_row())
	popup.add_theme_color_override("font_color", CHARCOAL)
	popup.add_theme_color_override("font_hover_color", CHARCOAL)

func _style_close_button(button: Button) -> void:
	GameFonts.use_display(button)
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
	button.custom_minimum_size = Vector2(44.0, 44.0)

func _style_text_input(control: Control) -> void:
	control.add_theme_font_size_override("font_size", GameFonts.BODY_DEFAULT)
	control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 44.0)
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
	if _connection_panel != null:
		_connection_panel.visible = false
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
	if _tab_tween != null and _tab_tween.is_valid():
		_tab_tween.kill()
	var page := _tabs.get_current_tab_control()
	if page == null:
		return
	page.modulate.a = 0.55
	_tab_tween = create_tween()
	_tab_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tab_tween.tween_property(page, "modulate:a", 1.0, 0.14)

func _unhandled_key_input(event: InputEvent) -> void:
	if _drawer_open and event.is_action_pressed("ui_cancel"):
		if _connection_panel != null and _connection_panel.visible:
			_close_connection_settings()
		else:
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
	if records.is_empty():
		var empty_label := Label.new()
		empty_label.text = "YOUR FIRST HIRE\nWILL APPEAR HERE"
		empty_label.custom_minimum_size = Vector2(100.0, 100.0)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", GameFonts.BODY_META)
		empty_label.add_theme_color_override("font_color", OFF_WHITE)
		list.add_child(empty_label)
	for record: EmployeeRecord in records:
		var button := Button.new()
		button.text = ""
		button.tooltip_text = "Talk with %s" % record.display_name
		button.set_meta("display_name", record.display_name)
		button.custom_minimum_size = Vector2(100.0, 143.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_contents = true
		button.pressed.connect(_on_team_button_pressed.bind(record.id))
		button.add_theme_stylebox_override("normal", NotebookSkin.wood_surface(Vector4(7.0, 7.0, 7.0, 7.0)))
		button.add_theme_stylebox_override("hover", NotebookSkin.texture_style(NotebookSkin.WOOD_FILL, Vector4(5.0, 5.0, 5.0, 5.0), Vector4(7.0, 7.0, 7.0, 7.0), true, Color("fff0e8")))
		button.add_theme_stylebox_override("pressed", NotebookSkin.wood_surface(Vector4(8.0, 8.0, 8.0, 8.0)))
		var selection_frame := NinePatchRect.new()
		selection_frame.name = "SelectionFrame"
		selection_frame.texture = NotebookSkin.OUTER_FRAME
		selection_frame.patch_margin_left = 14
		selection_frame.patch_margin_top = 14
		selection_frame.patch_margin_right = 14
		selection_frame.patch_margin_bottom = 14
		selection_frame.self_modulate = VERMILION
		selection_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selection_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(selection_frame)
		var portrait_frame := PanelContainer.new()
		portrait_frame.position = Vector2(8.0, 8.0)
		portrait_frame.size = Vector2(84.0, 92.0)
		portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_frame.add_theme_stylebox_override("panel", NotebookSkin.portrait_frame())
		button.add_child(portrait_frame)
		var portrait := TextureRect.new()
		portrait.texture = CharacterArt.bust_portrait(record.id)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_frame.add_child(portrait)
		var name_plate := PanelContainer.new()
		name_plate.position = Vector2(8.0, 103.0)
		name_plate.size = Vector2(84.0, 32.0)
		name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_plate.add_theme_stylebox_override("panel", NotebookSkin.name_plaque())
		button.add_child(name_plate)
		var name_label := Label.new()
		name_label.text = record.display_name.to_upper()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
		GameFonts.use_display(name_label)
		name_label.add_theme_color_override("font_color", CHARCOAL)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_plate.add_child(name_label)
		var status_dot := TextureRect.new()
		status_dot.name = "StatusDot"
		status_dot.texture = OperationsSkin.WORLD_AVAILABLE
		status_dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		status_dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		status_dot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		status_dot.offset_left = -29.0
		status_dot.offset_top = 23.0
		status_dot.offset_right = -8.0
		status_dot.offset_bottom = 46.0
		button.add_child(status_dot)
		var attention_badge := TextureRect.new()
		attention_badge.name = "AttentionBadge"
		attention_badge.texture = OperationsSkin.ATTENTION_BADGE
		attention_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		attention_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		attention_badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		attention_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		attention_badge.visible = false
		attention_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		attention_badge.offset_left = 2.0
		attention_badge.offset_top = 2.0
		attention_badge.offset_right = 25.0
		attention_badge.offset_bottom = 29.0
		button.add_child(attention_badge)
		list.add_child(button)
		_team_buttons[record.id] = button
	_refresh_team_statuses()
	_refresh_operation_availability()
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

func open_chat_for_employee(employee_id: String) -> void:
	_select_employee(employee_id)
	_tabs.current_tab = 0
	open_drawer()

func open_journal_for_employee(employee_id: String) -> void:
	if not employee_id.is_empty():
		_select_employee(employee_id)
	_tabs.current_tab = 2
	open_drawer()

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
	if _worker_connected:
		chat_history_requested.emit(employee_id)

func _refresh_team_card_styles() -> void:
	for id: String in _team_buttons:
		var button: Button = _team_buttons[id]
		button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
		var selection_frame := button.get_node_or_null("SelectionFrame") as NinePatchRect
		if selection_frame != null:
			selection_frame.visible = _drawer_open and id == _selected_employee_id

func _selected_employee() -> EmployeeRecord:
	for record: EmployeeRecord in _employees:
		if record.id == _selected_employee_id:
			return record
	return null

func _refresh_employee_header() -> void:
	if _tabs != null and _tabs.current_tab == 3:
		_employee_name.text = "Studio"
		_employee_meta.text = "Approved deliveries"
		_employee_status.text = "SHARED TEAM FILES"
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
	var activity := _employee_ui_state(employee.id)
	_employee_meta.text = _employee_specialty(employee.id)
	_employee_status.text = activity.to_upper()
	_employee_status.add_theme_color_override("font_color", _state_text_color(activity))

func _refresh_team_statuses() -> void:
	for employee_id: String in _team_buttons:
		var button: Button = _team_buttons[employee_id]
		var status_dot := button.get_node_or_null("StatusDot") as TextureRect
		var attention_badge := button.get_node_or_null("AttentionBadge") as TextureRect
		if status_dot == null:
			continue
		var state := _employee_ui_state(employee_id)
		status_dot.self_modulate = _state_color(state)
		status_dot.texture = _state_icon(state)
		status_dot.visible = true
		button.tooltip_text = "%s · %s" % [str(button.get_meta("display_name", employee_id)), state]
		if attention_badge != null:
			attention_badge.visible = (employee_id == _active_employee_id and not _approval_id.is_empty()) or employee_id == _attention_employee_id

func _employee_ui_state(employee_id: String) -> String:
	if employee_id == _active_employee_id and not _approval_id.is_empty():
		return "needs approval"
	if employee_id == _attention_employee_id:
		return "delivery ready"
	if employee_id == _active_employee_id and not _active_job_id.is_empty():
		return "working" if _active_job_running else "queued"
	if _clock_phase == "lunch":
		return "at lunch"
	if _clock_phase == "off":
		return "off shift"
	return "available"

func _state_color(state: String) -> Color:
	match state:
		"needs approval", "delivery ready":
			return VERMILION
		"working":
			return INDIGO
		"queued":
			return CERULEAN
		"at lunch":
			return VERMILION
		"off shift":
			return DUST
	return Color("4f7f2c")

func _state_text_color(state: String) -> Color:
	match state:
		"needs approval", "delivery ready", "at lunch":
			return ALERT_INK
		"working", "queued":
			return INDIGO
		"off shift":
			return CHARCOAL
	return SUCCESS_INK

func _state_icon(state: String) -> Texture2D:
	match state:
		"needs approval", "delivery ready":
			return OperationsSkin.ATTENTION_BADGE
		"working":
			return OperationsSkin.ACTIVITY_WRITING
		"queued":
			return OperationsSkin.ACTIVITY_THINKING
		"off shift":
			return OperationsSkin.WORLD_AVAILABLE
	return OperationsSkin.WORLD_AVAILABLE

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
	var greeting := "What are we building? We can shape the idea before creating a work order." if employee.id == "mira" else "What should we test or grow? We can sharpen it before creating a work order."
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
		avatar_frame.add_theme_stylebox_override("panel", NotebookSkin.portrait_frame())
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
	bubble.add_theme_stylebox_override("panel", OperationsSkin.chat_bubble(sender))
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
	message_label.add_theme_font_size_override("font_size", GameFonts.BODY_DEFAULT)
	message_label.add_theme_color_override("font_color", CHARCOAL)
	bubble_margin.add_child(message_label)
	_chat_log.add_child(row)
	_animate_entry(row, -7.0 if sender == "employee" else 7.0)
	call_deferred("_scroll_chat_to_bottom")

func _clear_chat() -> void:
	_chat_transcript = ""
	_last_chat_prompt = ""
	_chat_messages.clear()
	if _make_job_button != null:
		_make_job_button.disabled = true
		_make_job_button.visible = false
	for child: Node in _chat_log.get_children():
		_chat_log.remove_child(child)
		child.queue_free()

func _show_chat_hint(message: String) -> void:
	var hint_panel := PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", OperationsSkin.chat_system_strip())
	var hint := Label.new()
	hint.text = message
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", MUTED_INK)
	hint_panel.add_child(hint)
	_chat_log.add_child(hint_panel)
	_animate_entry(hint_panel)

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
		_remember_chat_message(sender, content)
		_append_chat_line(sender, "Founder" if sender == "player" else employee.display_name, content)
	var has_employee_reply := not _chat_messages.is_empty() and str(_chat_messages[-1].get("sender", "")) == "employee"
	_make_job_button.disabled = _last_chat_prompt.is_empty() or not _active_job_id.is_empty() or not has_employee_reply
	_make_job_button.visible = not _make_job_button.disabled

func show_chat_reply(employee_id: String, message: Dictionary, daily_spend: float) -> void:
	_chat_pending = false
	_refresh_chat_mode()
	set_spend(daily_spend, _spend_warning)
	if employee_id != _selected_employee_id:
		return
	var employee := _selected_employee()
	var content := str(message.get("content", ""))
	_remember_chat_message("employee", content)
	_append_chat_line("employee", employee.display_name, content)
	_make_job_button.disabled = _last_chat_prompt.is_empty() or not _active_job_id.is_empty()
	_make_job_button.visible = not _make_job_button.disabled
	_set_status("%s replied." % employee.display_name)

func set_chat_failed(employee_id: String, message: String) -> void:
	_chat_pending = false
	_refresh_chat_mode()
	if employee_id == _selected_employee_id:
		_append_chat_line("employee", "System", message)

func _submit_chat_text(_text: String) -> void:
	_submit_chat()

func _submit_chat() -> void:
	if not _active_job_id.is_empty():
		_tabs.current_tab = 2
		return
	if not _credential_configured:
		_open_connection_settings()
		return
	if not _worker_connected:
		set_worker_connection_error("Worker is not connected")
		return
	var message := _chat_input.text.strip_edges()
	if message.is_empty() or _selected_employee_id.is_empty():
		return
	_chat_input.clear()
	_last_chat_prompt = message
	_make_job_button.disabled = true
	_make_job_button.visible = false
	_remember_chat_message("player", message)
	_append_chat_line("player", "Founder", message)
	_chat_pending = true
	_refresh_chat_mode()
	chat_submitted.emit(_selected_employee_id, message)

func _refresh_chat_mode() -> void:
	if _chat_input == null:
		return
	var selected_employee := _selected_employee()
	var has_employee := selected_employee != null
	var has_active_job := not _active_job_id.is_empty()
	var can_chat := has_employee and _credential_configured and _worker_connected
	_chat_input.editable = can_chat and not _chat_pending and not has_active_job
	_chat_send_button.disabled = not can_chat or _chat_pending
	if _chat_pending:
		_chat_send_button.text = "."
		_chat_input.placeholder_text = "Waiting for a reply…"
		_chat_helper.text = "Waiting for a conversational reply — no work has started."
	elif has_active_job:
		_chat_send_button.text = "ACTIVITY"
		_chat_input.placeholder_text = "Use Activity to update the current work order"
		_chat_helper.text = "%s is busy. Send work instructions from Activity." % _active_employee_name()
	elif not _credential_configured or not _worker_connected:
		_chat_send_button.text = "CONNECT"
		_chat_input.placeholder_text = "Connect AI from Settings"
		_chat_helper.text = "Connection required before a conversation can start."
	else:
		_chat_send_button.text = "ASK %s" % selected_employee.display_name.to_upper() if has_employee else "ASK"
		_chat_input.placeholder_text = "Talk through an idea…"
		_chat_helper.text = "Conversation only — no tools or files."
	_make_job_button.visible = not _make_job_button.disabled and not has_active_job and not _chat_pending

func _make_last_chat_a_job() -> void:
	if _last_chat_prompt.is_empty():
		return
	_job_picker.select(CANNED_JOBS.size())
	_on_job_selected(CANNED_JOBS.size())
	var concise_title := _last_chat_prompt.replace("\n", " ").strip_edges()
	_custom_title_input.text = concise_title.left(72)
	_assignment_preview.text = _chat_work_order_draft()
	_tabs.current_tab = 1
	_custom_title_input.grab_focus()

func _remember_chat_message(sender: String, content: String) -> void:
	_chat_messages.append({"sender": sender, "content": content.strip_edges()})
	while _chat_messages.size() > 24:
		_chat_messages.pop_front()

func _chat_work_order_draft() -> String:
	var lines: PackedStringArray = ["Work request:", _last_chat_prompt, "", "Discussion context:"]
	var first := maxi(0, _chat_messages.size() - 6)
	for index: int in range(first, _chat_messages.size()):
		var message: Dictionary = _chat_messages[index]
		var speaker := "Founder" if str(message.get("sender", "")) == "player" else _selected_employee().display_name
		lines.append("%s: %s" % [speaker, str(message.get("content", "")).strip_edges()])
	return "\n".join(lines).left(3800)

func _active_employee_name() -> String:
	for employee: EmployeeRecord in _employees:
		if employee.id == _active_employee_id:
			return employee.display_name
	return "A teammate"

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
	if not _credential_configured:
		_open_connection_settings()
		return
	if not _worker_connected:
		set_worker_connection_error("Worker is not connected")
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
	_set_status("Cancelling the active work order…", ALERT_INK)
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
	_set_status("Sending update to the active work session…", INDIGO)
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
	_usage_label.text = "Usage details  ·  0 tokens"
	_token_meter.value = 0.0
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
	_set_status("Submitting work order…", INDIGO)
	_tabs.current_tab = 2
	_refresh_employee_header()
	_refresh_team_statuses()
	_refresh_chat_mode()
	close_drawer()

func mark_job_queued(job_id: String) -> void:
	if job_id != _active_job_id:
		return
	_set_status("Queued. Work begins automatically during the next work window.", INDIGO)
	_active_job_running = false
	_assign_button.text = "Queued until work hours"
	_steer_box.visible = false
	_refresh_employee_header()
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
	_set_status("%s  ·  restored %s" % [title, status], INDIGO)
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
	_refresh_operation_availability()
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
	_set_status("Update delivered to the same active work session.", INDIGO)

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
	return _assign_button.get_global_rect().end.x <= drawer_rect.end.x \
		and _cancel_button.get_global_rect().end.x <= drawer_rect.end.x

func status_color() -> Color:
	return _status_label.get_theme_color("font_color")

func set_worker_ready() -> void:
	_worker_connected = true
	if _connection_badge != null:
		_connection_badge.visible = false
	if _settings_button != null:
		_settings_button.text = "SETTINGS" if _credential_configured else "CONNECT"
	if _key_status != null:
		_key_status.text = "Connected. Key stored in the OS keychain." if _credential_configured else "Connection required before chat or work can start."
		_key_status.add_theme_color_override("font_color", CHARCOAL if _credential_configured else ALERT_INK)
	_refresh_operation_availability()

func set_worker_connection_error(message: String) -> void:
	_worker_connected = false
	if _connection_badge != null:
		_connection_badge.visible = true
		_connection_badge.tooltip_text = message
	if _settings_button != null:
		_settings_button.text = "CONNECT"
		_settings_button.tooltip_text = message
	if _key_status != null:
		_key_status.text = message
		_key_status.add_theme_color_override("font_color", ALERT_INK)
	_refresh_operation_availability()

func set_clock_phase(phase: String) -> void:
	_clock_phase = phase
	_update_assign_copy()
	_refresh_employee_header()
	_refresh_team_statuses()
	if _active_job_id.is_empty() and phase != "work":
		_set_status("Lunch — new work queues until 13:30." if phase == "lunch" else "Off hours — new work queues until 08:00.", ALERT_INK if phase == "lunch" else MUTED_INK)

func _update_assign_copy() -> void:
	if not _active_job_id.is_empty():
		return
	if _clock_phase == "work":
		_assign_button.text = "START WORK ORDER"
	elif _clock_phase == "lunch":
		_assign_button.text = "QUEUE FOR 13:30"
	else:
		_assign_button.text = "QUEUE FOR 08:00"

func set_credential_status(configured: bool) -> void:
	_credential_configured = configured
	_key_status.text = "Connected. Key stored in the OS keychain." if configured else "Connection required before chat or work can start."
	_key_status.add_theme_color_override("font_color", CHARCOAL if configured else ALERT_INK)
	_settings_button.text = "SETTINGS" if configured else "CONNECT"
	_refresh_operation_availability()
	if not configured:
		call_deferred("_open_connection_settings")

func set_credential_saved() -> void:
	set_credential_status(true)
	_close_connection_settings()
	_set_status("OpenRouter key saved.", INDIGO)

func set_spend(daily_spend: float, warning: float) -> void:
	_spend_warning = warning
	_token_meter.max_value = maxf(warning, 0.01)
	_token_meter.value = clampf(daily_spend, 0.0, _token_meter.max_value)
	_spend_label.text = "AI spend today  ·  $%.4f of $%.2f warning" % [daily_spend, warning]
	_spend_label.add_theme_color_override("font_color", ALERT_INK if daily_spend >= warning else CHARCOAL)
	_pulse_control(_token_meter, VERMILION if daily_spend >= warning else CERULEAN)

func set_error(message: String) -> void:
	if message.to_lower().contains("worker is not connected"):
		set_worker_connection_error(message)
		return
	_set_status(message, ALERT_INK)

func set_info(message: String) -> void:
	_set_status(message)

func _set_status(message: String, color: Color = CHARCOAL) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)
	if _status_tween != null and _status_tween.is_valid():
		_status_tween.kill()
	_status_label.modulate.a = 0.45
	_status_tween = create_tween()
	_status_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_status_tween.tween_property(_status_label, "modulate:a", 1.0, 0.12)

func _refresh_operation_availability() -> void:
	if _assign_button != null:
		_assign_button.disabled = _employees.is_empty() or not _active_job_id.is_empty() or not _credential_configured or not _worker_connected
	_refresh_chat_mode()

func on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	var line := ""
	match event.type:
		&"job.queued":
			mark_job_queued(job_id)
			line = "[color=#963014]queued[/color] · %s" % _safe_bbcode(event.reason)
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
			_set_status(event.label, INDIGO)
			line = "[color=#6196c1]tool[/color] · %s" % _safe_bbcode(event.tool)
		&"tool.completed":
			line = "%s · %s" % [_safe_bbcode(event.tool), "done" if event.ok else "failed"]
		&"approval.required":
			_approval_job_id = job_id
			_approval_id = event.approval_id
			_approval_label.text = event.action
			_approval_box.visible = true
			_reveal_control(_approval_box)
			_tabs.current_tab = 2
			_set_status("A decision is needed before work can continue.", ALERT_INK)
			_refresh_team_statuses()
			line = "[color=#963014]approval required[/color]"
		&"artifact.created":
			line = "[color=#354b98]delivery[/color] · %s" % _safe_bbcode(event.name)
		&"usage.updated":
			_usage_label.text = "Usage details  ·  %d tokens  ·  $%.4f" % [event.input_tokens + event.output_tokens, event.cost]
			line = "usage · %d tokens · $%.4f" % [event.input_tokens + event.output_tokens, event.cost]
		&"job.blocked":
			_set_status(event.reason, ALERT_INK)
			line = "[color=#963014]blocked[/color] · %s" % _safe_bbcode(event.reason)
			finish_job(job_id)
		&"job.completed":
			_set_status(event.summary, INDIGO)
			line = "[color=#354b98]completed[/color]"
			finish_job(job_id)
		&"job.failed":
			_set_status(event.error, ALERT_INK)
			line = "[color=#963014]failed[/color] · %s" % _safe_bbcode(event.error)
			finish_job(job_id)
	if not line.is_empty():
		var icon_path := OperationsSkin.activity_icon_path(event.type, event.tool, event.ok)
		_event_log.append_text("[img=18x18]%s[/img]  %s\n" % [icon_path, line])
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
	_promotion_label.text = "Make this delivery available to future teammates?"
	_promotion_box.visible = true
	_reveal_control(_promotion_box)
	_tabs.current_tab = 2
	_refresh_team_statuses()

func _decide_promotion(approved: bool) -> void:
	var job_id := _promotion_job_id
	_promotion_job_id = ""
	_attention_employee_id = ""
	promotion_decided.emit(job_id, approved)
	_promotion_box.visible = false
	_refresh_team_statuses()
	_set_status("Adding approved delivery to Studio…" if approved else "Delivery kept with its work order.", CHARTREUSE if approved else CHARCOAL)

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
	_promotion_label.text = "%s finished “%s”. Add these files to Studio or keep them with the work order: %s" % [
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
		button.icon = OperationsSkin.ICON_DELIVERY
		button.add_theme_constant_override("icon_max_width", 28)
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = artifact.relative_path
		button.pressed.connect(_open_artifact.bind(job_id, artifact.relative_path))
		_style_file_button(button)
		_artifact_list.add_child(button)
		_animate_entry(button)
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
		button.icon = OperationsSkin.ACTIVITY_ARTIFACT
		button.add_theme_constant_override("icon_max_width", 28)
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = "Promoted from %s" % file.source_job_id
		button.pressed.connect(studio_open_requested.emit.bind(file.relative_path))
		_style_file_button(button)
		_artifact_list.add_child(button)
		_animate_entry(button)

func _clear_artifact_list() -> void:
	for child: Node in _artifact_list.get_children():
		child.queue_free()

func _add_empty_artifact(message: String) -> void:
	var empty_panel := PanelContainer.new()
	empty_panel.add_theme_stylebox_override("panel", OperationsSkin.file_card())
	var empty_row := HBoxContainer.new()
	empty_row.add_theme_constant_override("separation", 8)
	empty_panel.add_child(empty_row)
	var empty_icon := TextureRect.new()
	empty_icon.texture = OperationsSkin.ICON_EMPTY_TRAY
	empty_icon.custom_minimum_size = Vector2(42.0, 34.0)
	empty_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	empty_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	empty_row.add_child(empty_icon)
	var empty := Label.new()
	empty.text = message
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty.add_theme_font_size_override("font_size", GameFonts.BODY_DEFAULT)
	empty.add_theme_color_override("font_color", CHARCOAL)
	empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_row.add_child(empty)
	_artifact_list.add_child(empty_panel)
	_animate_entry(empty_panel)

func _style_file_button(button: Button) -> void:
	GameFonts.use_body(button)
	button.add_theme_font_size_override("font_size", GameFonts.BODY_DEFAULT)
	button.custom_minimum_size.y = 50.0
	button.add_theme_stylebox_override("normal", OperationsSkin.file_card())
	button.add_theme_stylebox_override("hover", OperationsSkin.file_card(true))
	button.add_theme_stylebox_override("pressed", OperationsSkin.file_card(true))
	button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
	button.add_theme_color_override("font_color", CHARCOAL)
	button.add_theme_color_override("font_hover_color", CHARCOAL)
	button.add_theme_color_override("font_pressed_color", CHARCOAL)
	button.button_down.connect(_animate_button_press.bind(button, true))
	button.button_up.connect(_animate_button_press.bind(button, false))

func _animate_entry(control: Control, horizontal_offset: float = 0.0) -> void:
	control.modulate.a = 0.0
	control.position.x += horizontal_offset
	var final_x := control.position.x - horizontal_offset
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, 0.14)
	tween.tween_property(control, "position:x", final_x, 0.14)

func _reveal_control(control: Control) -> void:
	control.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, 0.16)

func _pulse_control(control: Control, color: Color) -> void:
	control.self_modulate = color.lightened(0.35)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "self_modulate", Color.WHITE, 0.18)

func _animate_button_press(button: Button, pressed: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * (0.98 if pressed else 1.0), 0.07)

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
