class_name JobPanel
extends Control

var milestone_id := ""
var revision_of_job_id := ""
var _milestone_criteria := PackedStringArray()
var requested_token_budget := 12000
var _chat_follow_tail := true

func prepare_milestone(definition: Dictionary) -> void:
	_purpose_chosen_by_player = false
	select_employee(str(definition.get("employeeId", "mira")))
	_apply_milestone_draft(definition)
	_tabs.current_tab = 1

func _apply_milestone_draft(definition: Dictionary) -> void:
	_job_picker.select(CANNED_JOBS.size())
	_on_job_selected(CANNED_JOBS.size())
	_custom_title_input.text = str(definition.get("title", "Company milestone"))
	_assignment_preview.text = str(definition.get("assignment", ""))
	milestone_id = str(definition.get("id", ""))
	_milestone_criteria = PackedStringArray(definition.get("criteria", []))
	for path: String in definition.get("files", []): _milestone_criteria.append("Deliver " + path)
	var evaluation: Dictionary = definition.get("evaluation", {}) if definition.get("evaluation") is Dictionary else {}
	if evaluation.get("verdict", "") == "revise":
		revision_of_job_id = str(definition.get("jobId", ""))
		_assignment_preview.text += "\n\nRevision feedback:\n" + str(evaluation.get("revisionBrief", ""))
	elif str(definition.get("jobStatus", "")) in ["blocked", "failed", "cancelled"]:
		revision_of_job_id = str(definition.get("jobId", ""))
		_assignment_preview.text += "\n\nResume the retained files. Check existing work first; complete only what is missing or incorrect."
	if not revision_of_job_id.is_empty():
		requested_token_budget = 24000
		_budget_picker.select(1)
	_draft_label.text = "Journey · " + str(definition.get("title", ""))
	_refresh_work_purposes()
	_update_assign_copy()

signal key_submitted(key: String)
signal grok_login_start_requested
signal grok_login_poll_requested
signal grok_login_cancel_requested
signal grok_logout_requested
signal grok_use_local_requested
signal settings_requested
signal journey_requested
signal story_requested(mode: String)
signal worker_retry_requested
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
const ACTIVITY_FOOTER_INSET := Vector2(18, 10)

const CANNED_JOBS := [
	{
		"title": "Shape a startup brief",
		"employee_id": "mira",
		"assignment": "Write startup-brief.md: a one-page proposal for the company's audience, problem, offer and next validation experiment. Use known company context; label assumptions and open questions. This is ordinary planning work, not a Journey milestone.",
		"criteria": ["startup-brief.md exists", "The audience and offer are concrete", "Assumptions and a testable next step are explicit"],
	},
	{
		"title": "Review the launch plan",
		"employee_id": "theo",
		"assignment": "Review available company context and relevant Studio files. Write launch-review.md with the clearest growth opportunity, missing evidence, and a small next experiment. If no company files exist, clearly label a provisional plan and its open questions. Do not launch ads or claim real results.",
		"criteria": ["launch-review.md exists", "The review distinguishes evidence from assumptions", "The review identifies a concrete next experiment"],
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
var _budget_picker: OptionButton
var _draft_label: Label
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
var _daily_ai_spend := 0.0
var _active_job_running: bool = false
var _credential_configured: bool = false
var _offline_provider: bool = false
var _worker_connected: bool = false
var _connection_panel: Panel
var _settings_button: Button
var _connection_badge: Label
var _job_views: Dictionary = {}
var _job_order: Array[String] = []
var _activity_job_id := ""
var _pending_deliveries: Array = []
var _delivery_list: VBoxContainer
var _history_picker: OptionButton
var _activity_cancel: Button
var _assignment_error: Label
var _draft_reset_button: Button
var _submission_pending := false
var _submitted_job_id := ""
var _journey_state: Dictionary = {}
var story_mode := OS.has_feature("web")
var _story_page: VBoxContainer
var _story_line: Label
var _story_action: Button
var _purpose_picker: OptionButton
var _purpose_chosen_by_player := false
var _next_step_label: Label
var _draft_discussion := ""
var _header_shell: Control
var _empty_team_panel: PanelContainer
var _chat_composer: PanelContainer
var _chat_active_banner: PanelContainer
var _chat_active_copy: Label
var _chat_activity_button: Button
var _latest_reply_content: VBoxContainer
var _connection_title: Label
var _connection_description: Label
var _grok_login_button: Button
var _grok_use_local_button: Button
var _grok_disconnect_button: Button
var _grok_code_input: LineEdit
var _grok_open_button: Button
var _grok_cancel_button: Button
var _openrouter_label: Label
var _connection_save_button: Button
var _connection_retry_button: Button
var _connection_back_button: Button
var _grok_signed_in := false
var _grok_cli_available := false
var _grok_login_pending := false
var _openrouter_from_environment := false
var _grok_verification_uri := ""
var _grok_poll_wait := 5
var _grok_poll_timer: Timer
var _connection_focus_return: Control
var _attachment_toggle: Button
var _attachment_expanded := false
var _attachment_reveal_revision := 0
var _attachment_reveal_spacer: Control
var _usage_toggle: Button
var _usage_page: ScrollContainer
var _usage_today_label: Label
var _usage_work_title: Label
var _usage_back_button: Button
var _usage_expanded := false
var _usage_return_scroll := 0
var _activity_content: VBoxContainer
var _activity_scroll: ScrollContainer
var _activity_footer: PanelContainer
var _activity_details: VBoxContainer
var _activity_details_toggle: Button
var _activity_details_expanded := false
var _activity_details_job_id := ""
var _status_card: PanelContainer
var _activity_heading: Label
var _worker_error := ""
var _connection_retry_pending := false
var connect_allowed: Callable
var _tab_strip: HBoxContainer
var _tab_buttons: Array[Button] = []
var _promotion_actions: Array[Button] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = GameFonts.interface_theme()
	# Pin the drawer and team rail to the viewport, including exported scenes
	# and canvas resizes. A fixed editor position can strand the rail mid-room.
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -(DRAWER_WIDTH + DRAWER_GAP + RAIL_WIDTH)
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
	if story_mode:
		_drawer_panel.anchor_bottom = 0
		_drawer_panel.offset_top = 144
		_drawer_panel.offset_bottom = 592
	_drawer_panel.add_theme_stylebox_override("panel", NotebookSkin.wood_surface(Vector4(12.0, 12.0, 12.0, 12.0)))
	add_child(_drawer_panel)
	_add_outer_frame(_drawer_panel)
	var drawer_margin := MarginContainer.new()
	drawer_margin.custom_minimum_size = Vector2(DRAWER_WIDTH, 448.0 if story_mode else 720.0)
	drawer_margin.add_theme_constant_override("margin_left", 12)
	drawer_margin.add_theme_constant_override("margin_right", 12)
	drawer_margin.add_theme_constant_override("margin_top", 28)
	drawer_margin.add_theme_constant_override("margin_bottom", 12)
	_drawer_panel.add_child(drawer_margin)
	drawer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var drawer := _build_employee_drawer()
	drawer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_margin.add_child(drawer)
	# The preset's default resize mode is minimum-size. Explicit zero offsets
	# bind the completed content tree to the authored drawer, not its text minima.
	drawer_margin.offset_left = 0
	drawer_margin.offset_top = 0
	drawer_margin.offset_right = 0
	drawer_margin.offset_bottom = 0
	drawer_margin.minimum_size_changed.connect(_fit_drawer_contents.bind(drawer_margin))
	_fit_drawer_contents(drawer_margin)

	_rail_panel = Panel.new()
	_rail_panel.name = "TeamRail"
	# The sliding drawer's decorative frame is z=1. Keep the whole rail above
	# that frame, not just later in sibling order, so it cannot cross portraits.
	_rail_panel.z_index = 2
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

func _fit_drawer_contents(content: Control) -> void:
	# Wrapped labels can report a tall provisional minimum before their first
	# container sort. Refit after it settles instead of retaining that old size.
	content.set_deferred("size", Vector2(DRAWER_WIDTH, 448.0 if story_mode else 720.0))

func _add_outer_frame(panel: Control) -> void:
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", NotebookSkin.outer_frame())
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.z_index = 1
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
	heading_label.name = "TeamHeading"
	heading_label.text = "TEAM"
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	CozyUI.label(heading_label, "display")
	heading.add_child(heading_label)
	var team_list := VBoxContainer.new()
	team_list.name = "TeamList"
	team_list.add_theme_constant_override("separation", 4)
	team_list.set_anchors_preset(Control.PRESET_TOP_WIDE)
	team_list.offset_left = 15.0
	team_list.offset_top = 82.0
	team_list.offset_right = -15.0
	team_list.offset_bottom = 530.0
	rail.add_child(team_list)
	_settings_button = Button.new()
	_settings_button.text = "Settings"
	_settings_button.position = Vector2(15.0, 662.0)
	_settings_button.size = Vector2(100.0, 42.0)
	_settings_button.tooltip_text = "Open settings or connect AI"
	_settings_button.pressed.connect(func() -> void:
		if OS.has_feature("web") or (_credential_configured and _worker_connected):
			close_drawer(false)
			settings_requested.emit()
		else:
			_open_connection_settings()
	)
	_style_action_button(_settings_button, INDIGO, false)
	rail.add_child(_settings_button)
	_next_step_label = Label.new()
	_next_step_label.name = "RailNextStep"
	_next_step_label.position = Vector2(15.0, 548.0)
	_next_step_label.size = Vector2(100.0, 100.0)
	_next_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_step_label.max_lines_visible = 4
	CozyUI.label(_next_step_label, "meta")
	_next_step_label.add_theme_color_override("font_color", OFF_WHITE)
	rail.add_child(_next_step_label)
	_connection_badge = Label.new()
	_connection_badge.text = "!"
	_connection_badge.visible = false
	_connection_badge.position = Vector2(92.0, 654.0)
	_connection_badge.size = Vector2(24.0, 24.0)
	_connection_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_connection_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	CozyUI.label(_connection_badge, "action")
	_connection_badge.add_theme_font_size_override("font_size", 18)
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
	page.size = Vector2(DRAWER_WIDTH - 28.0, 678.0)
	page.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(18, 20, 18, 20)))
	_connection_panel.add_child(page)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	page.add_child(content)
	_connection_title = Label.new()
	_connection_title.text = "Connect AI"
	CozyUI.label(_connection_title, "display")
	content.add_child(_connection_title)
	_connection_description = Label.new()
	_connection_description.text = "Sign in with Grok to use your Grok / xAI credits for conversations and work orders. An OpenRouter key still works as a fallback and stays in the OS keychain."
	_connection_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(_connection_description)
	content.add_child(_connection_description)
	_grok_login_button = Button.new()
	_grok_login_button.text = "Sign in with Grok"
	_grok_login_button.custom_minimum_size.y = 44.0
	_grok_login_button.pressed.connect(_start_grok_login)
	_style_action_button(_grok_login_button, VERMILION, true)
	content.add_child(_grok_login_button)
	_grok_use_local_button = Button.new()
	_grok_use_local_button.text = "Use saved Grok login"
	_grok_use_local_button.custom_minimum_size.y = 44.0
	_grok_use_local_button.pressed.connect(func() -> void: grok_use_local_requested.emit())
	_style_action_button(_grok_use_local_button, INDIGO, false)
	content.add_child(_grok_use_local_button)
	_grok_use_local_button.hide()
	_grok_code_input = LineEdit.new()
	_grok_code_input.placeholder_text = "Grok device code"
	_grok_code_input.custom_minimum_size.y = 48.0
	_grok_code_input.editable = true
	_style_text_input(_grok_code_input)
	content.add_child(_grok_code_input)
	_grok_code_input.hide()
	_grok_open_button = Button.new()
	_grok_open_button.text = "Open verification page"
	_grok_open_button.custom_minimum_size.y = 44.0
	_grok_open_button.pressed.connect(_open_grok_verification)
	_style_action_button(_grok_open_button, VERMILION, true)
	content.add_child(_grok_open_button)
	_grok_open_button.hide()
	_grok_cancel_button = Button.new()
	_grok_cancel_button.text = "Cancel sign-in"
	_grok_cancel_button.custom_minimum_size.y = 44.0
	_grok_cancel_button.pressed.connect(_cancel_grok_login)
	_style_action_button(_grok_cancel_button, INDIGO, false)
	content.add_child(_grok_cancel_button)
	_grok_cancel_button.hide()
	_grok_disconnect_button = Button.new()
	_grok_disconnect_button.text = "Disconnect Grok"
	_grok_disconnect_button.custom_minimum_size.y = 44.0
	_grok_disconnect_button.pressed.connect(func() -> void: grok_logout_requested.emit())
	_style_action_button(_grok_disconnect_button, INDIGO, false)
	content.add_child(_grok_disconnect_button)
	_grok_disconnect_button.hide()
	_openrouter_label = Label.new()
	_openrouter_label.text = "OpenRouter fallback"
	CozyUI.label(_openrouter_label, "meta")
	content.add_child(_openrouter_label)
	_key_input = LineEdit.new()
	_key_input.secret = true
	_key_input.placeholder_text = "Paste OpenRouter key"
	_key_input.custom_minimum_size.y = 48.0
	_key_input.text_submitted.connect(func(_value: String) -> void: _submit_key())
	_key_input.text_changed.connect(func(_value: String) -> void: _refresh_connection_save_state())
	_style_text_input(_key_input)
	content.add_child(_key_input)
	_connection_save_button = Button.new()
	_connection_save_button.text = "Save connection"
	_connection_save_button.disabled = true
	_connection_save_button.custom_minimum_size.y = 44.0
	_connection_save_button.pressed.connect(_submit_key)
	_style_action_button(_connection_save_button, VERMILION, true)
	content.add_child(_connection_save_button)
	_connection_retry_button = Button.new()
	_connection_retry_button.text = "Reconnect"
	_connection_retry_button.pressed.connect(_request_worker_retry)
	CozyUI.button(_connection_retry_button, "primary")
	content.add_child(_connection_retry_button)
	_connection_retry_button.hide()
	_key_status = Label.new()
	_key_status.text = "Checking OS keychain…"
	_key_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(_key_status)
	content.add_child(_key_status)
	var close_button := Button.new()
	_connection_back_button = close_button
	close_button.text = "Back to game"
	close_button.custom_minimum_size.y = 44.0
	close_button.pressed.connect(_close_connection_settings)
	_style_action_button(close_button, INDIGO, false)
	content.add_child(close_button)

func _open_connection_settings() -> void:
	if OS.has_feature("web"):
		close_drawer(false)
		settings_requested.emit()
		return
	if connect_allowed.is_valid() and not connect_allowed.call():
		return
	if not _connection_panel.visible:
		_connection_focus_return = get_viewport().gui_get_focus_owner()
	open_drawer(false)
	_connection_panel.visible = true
	_connection_panel.move_to_front()
	_rail_panel.move_to_front()
	_refresh_connection_surface()
	_refresh_operation_availability()
	_configure_connection_focus()

func _close_connection_settings() -> void:
	_cancel_grok_login_if_pending()
	_connection_panel.visible = false
	_refresh_operation_availability()
	if _drawer_open:
		_drawer_panel.move_to_front()
		_rail_panel.move_to_front()
	if is_instance_valid(_connection_focus_return) and _connection_focus_return.is_visible_in_tree() and not (_connection_focus_return is BaseButton and (_connection_focus_return as BaseButton).disabled):
		_connection_focus_return.grab_focus()
	elif _settings_button.is_visible_in_tree():
		_settings_button.grab_focus()
	_connection_focus_return = null

func _refresh_connection_surface() -> void:
	if _connection_title == null: return
	var unavailable := not _worker_connected and not _worker_error.is_empty()
	var show_grok_flow := not unavailable and _grok_login_pending
	var show_openrouter := not unavailable and not _grok_login_pending
	_connection_title.text = "Connection lost" if unavailable else "AI connection" if _credential_configured else "Connect AI"
	if unavailable:
		_connection_description.text = "Reconnect to resume chat and work. Your saved Grok login or OpenRouter key does not need to change." if _credential_configured else "Reconnect first, then sign in with Grok or add an OpenRouter key."
	elif _offline_provider:
		_connection_description.text = "Offline test provider is active. Work orders complete with local files and no paid model call."
	elif _openrouter_from_environment and _credential_configured:
		_connection_description.text = "Connected with OpenRouter. Work orders use the OpenRouter key from the environment. A Grok login or saved keychain key is not used while that key is set."
	elif _grok_login_pending:
		_connection_description.text = "Enter this code on the Grok page. Work will use your Grok / xAI credits when sign-in finishes. Back cancels sign-in."
	elif _grok_signed_in:
		_connection_description.text = "Signed in with Grok. Conversations and work orders use your Grok / xAI credits. The login is already saved in the OS keychain."
	elif _credential_configured:
		_connection_description.text = "A Grok login or OpenRouter key is already saved. Work uses your Grok / xAI credits when you are signed in with Grok. Paste a new OpenRouter key only to replace that fallback."
	else:
		_connection_description.text = "Sign in with Grok to use your Grok / xAI credits for conversations and work orders. An OpenRouter key still works as a fallback and stays in the OS keychain."
	_connection_save_button.text = "Replace saved key" if _credential_configured else "Save connection"
	_key_input.placeholder_text = "Paste replacement key (optional)" if _credential_configured else "Paste OpenRouter key"
	_grok_login_button.visible = not unavailable and not _credential_configured and not _grok_login_pending
	_grok_use_local_button.visible = not unavailable and not _grok_signed_in and _grok_cli_available and not _grok_login_pending
	_grok_code_input.visible = show_grok_flow
	_grok_open_button.visible = show_grok_flow
	_grok_cancel_button.visible = show_grok_flow
	_grok_disconnect_button.visible = not unavailable and _grok_signed_in and not _grok_login_pending
	_openrouter_label.visible = show_openrouter
	_key_input.visible = show_openrouter
	_connection_save_button.visible = show_openrouter
	_connection_retry_button.visible = unavailable
	_connection_retry_button.disabled = _connection_retry_pending
	if unavailable:
		# The page heading and recovery action already explain a disconnection.
		# Preserve diagnostic detail in a tooltip without repeating that prose.
		_key_status.text = "Reconnecting…" if _connection_retry_pending else ""
		_key_status.tooltip_text = _worker_error
		_connection_retry_button.tooltip_text = _worker_error
		_key_status.add_theme_color_override("font_color", ALERT_INK)
	elif _offline_provider:
		_key_status.text = "Offline test provider. Jobs complete without a model call."
		_key_status.add_theme_color_override("font_color", CHARCOAL)
	elif _openrouter_from_environment and _credential_configured:
		_key_status.text = "Connected with OpenRouter."
		_key_status.add_theme_color_override("font_color", CHARCOAL)
	elif _grok_signed_in:
		_key_status.text = "Signed in with Grok. Work uses your Grok / xAI credits."
		_key_status.add_theme_color_override("font_color", CHARCOAL)
	elif _credential_configured:
		_key_status.text = "Your saved key stays active until you save a replacement."
		_key_status.add_theme_color_override("font_color", CHARCOAL)
	_refresh_connection_save_state()
	_configure_connection_focus()

func _request_worker_retry() -> void:
	if _connection_retry_pending:
		return
	_connection_retry_pending = true
	_refresh_rail_connection_action()
	_refresh_connection_surface()
	worker_retry_requested.emit()

func _refresh_rail_connection_action() -> void:
	if _settings_button == null:
		return
	if _connection_retry_pending:
		_settings_button.text = "Linking…"
		_settings_button.tooltip_text = "Reconnect request in progress."
		_settings_button.disabled = true
		CozyUI.button(_settings_button, "secondary")
	elif not _worker_connected and not _worker_error.is_empty():
		_settings_button.text = "Reconnect"
		_settings_button.tooltip_text = _worker_error
		_settings_button.disabled = false
		CozyUI.button(_settings_button, "primary")
	else:
		_settings_button.text = "Settings" if OS.has_feature("web") or _credential_configured else "Connect"
		_settings_button.tooltip_text = "Open settings" if OS.has_feature("web") else "Open settings or connect AI"
		_settings_button.disabled = false
		CozyUI.button(_settings_button, "secondary")

func _refresh_connection_save_state() -> void:
	if _connection_save_button == null: return
	_connection_save_button.disabled = _key_input.text.strip_edges().is_empty()
	_configure_connection_focus()

func _connection_focus_controls() -> Array[Control]:
	var controls: Array[Control] = []
	for control: Control in [_grok_login_button, _grok_use_local_button, _grok_code_input, _grok_open_button, _grok_cancel_button, _grok_disconnect_button, _key_input, _connection_save_button, _connection_retry_button, _connection_back_button]:
		if control == null or not control.is_visible_in_tree(): continue
		if control is BaseButton and (control as BaseButton).disabled: continue
		if control is LineEdit and not (control as LineEdit).editable: continue
		controls.append(control)
	return controls

func _configure_connection_focus() -> void:
	if _connection_panel == null or not _connection_panel.is_visible_in_tree(): return
	var controls := _connection_focus_controls()
	if controls.is_empty(): return
	for index: int in range(controls.size()):
		var control := controls[index]
		control.focus_next = control.get_path_to(controls[(index + 1) % controls.size()])
		control.focus_previous = control.get_path_to(controls[(index - 1 + controls.size()) % controls.size()])
	if not controls.has(get_viewport().gui_get_focus_owner()): controls[0].grab_focus()

func _input(event: InputEvent) -> void:
	# Connection overlays the drawer, so underlying visible controls must never
	# receive keyboard traversal while it is open. Explicit cycling also repairs
	# focus after a retry becomes disabled or connectivity changes the fields.
	if _connection_panel == null or not _connection_panel.is_visible_in_tree(): return
	if event.is_action_pressed("ui_cancel"):
		_close_connection_settings()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.keycode != KEY_TAB: return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return
	var controls := _connection_focus_controls()
	if controls.is_empty(): return
	_configure_connection_focus()
	var index := controls.find(get_viewport().gui_get_focus_owner())
	controls[(index + (-1 if event.shift_pressed else 1) + controls.size()) % controls.size()].grab_focus()
	get_viewport().set_input_as_handled()

func _build_employee_drawer() -> VBoxContainer:
	var drawer := VBoxContainer.new()
	drawer.add_theme_constant_override("separation", 7)
	var header_shell := Control.new()
	_header_shell = header_shell
	header_shell.custom_minimum_size = Vector2(0.0, 168.0 if story_mode else 112.0)
	drawer.add_child(header_shell)
	var header_card := PanelContainer.new()
	header_card.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(8, 8, 8, 8)))
	header_shell.add_child(header_card)
	header_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 0)
	# Reserve the close target's full width, including for a long employee name.
	header_margin.add_theme_constant_override("margin_right", 44)
	header_margin.add_theme_constant_override("margin_top", 0)
	header_margin.add_theme_constant_override("margin_bottom", 0)
	header_card.add_child(header_margin)
	var employee_header := HBoxContainer.new()
	employee_header.add_theme_constant_override("separation", 12)
	header_margin.add_child(employee_header)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(120.0, 144.0) if story_mode else Vector2(76.0, 88.0)
	portrait_frame.add_theme_stylebox_override("panel", NotebookSkin.portrait_frame())
	employee_header.add_child(portrait_frame)
	_employee_portrait = TextureRect.new()
	_employee_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_employee_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_employee_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_child(_employee_portrait)
	_header_icon = TextureRect.new()
	_header_icon.texture = CozyUI.icon("folder")
	_header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_header_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_icon.custom_minimum_size = Vector2(32, 24)
	_header_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header_icon.visible = false
	employee_header.add_child(_header_icon)
	var employee_copy := VBoxContainer.new()
	employee_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	employee_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	employee_copy.add_theme_constant_override("separation", 3)
	employee_header.add_child(employee_copy)
	_employee_name = Label.new()
	_employee_name.text = "Your team"
	_employee_name.clip_text = true
	_employee_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	_employee_name.mouse_filter = Control.MOUSE_FILTER_PASS
	CozyUI.label(_employee_name, "display")
	_employee_name.resized.connect(_fit_employee_heading)
	employee_copy.add_child(_employee_name)
	_employee_meta = Label.new()
	_employee_meta.text = "Select an employee"
	_employee_meta.mouse_filter = Control.MOUSE_FILTER_PASS
	CozyUI.label(_employee_meta, "meta")
	_employee_meta.add_theme_color_override("font_color", INDIGO)
	_employee_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	employee_copy.add_child(_employee_meta)
	_employee_status = Label.new()
	_employee_status.text = "Available"
	CozyUI.label(_employee_status, "meta")
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
	_drawer_close_button.offset_left = -46.0
	_drawer_close_button.offset_top = 4.0
	_drawer_close_button.offset_right = -2.0
	_drawer_close_button.offset_bottom = 48.0
	header_shell.add_child(_drawer_close_button)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	CozyUI.tabs(_tabs)
	_tabs.tabs_visible = false
	_tab_strip = HBoxContainer.new()
	_tab_strip.add_theme_constant_override("separation", 0)
	# Tabs and the page form one notebook edge. Keep the header's air above,
	# without a strip of background between the selected tab and its paper.
	var notebook_stack := VBoxContainer.new()
	notebook_stack.add_theme_constant_override("separation", 0)
	notebook_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer.add_child(notebook_stack)
	notebook_stack.add_child(_tab_strip)
	for title: String in ["Chat", "Assign", "Activity", "Studio"]:
		var button := Button.new()
		button.text = title
		button.custom_minimum_size = Vector2(86, 44)
		button.clip_text = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = 1.0
		CozyUI.tab_button(button, _tab_buttons.is_empty())
		button.pressed.connect(_select_drawer_tab.bind(_tab_buttons.size()))
		_tab_strip.add_child(button)
		_tab_buttons.append(button)
	notebook_stack.add_child(_tabs)
	_tabs.add_child(_build_chat_tab())
	_tabs.add_child(_build_work_tab())
	_tabs.add_child(_build_journal_tab())
	_tabs.add_child(_build_studio_tab())
	if story_mode:
		notebook_stack.hide()
		_story_page = VBoxContainer.new()
		_story_page.name = "CharacterConversation"
		_story_page.add_theme_constant_override("separation", 12)
		_story_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		drawer.add_child(_story_page)
		var paper := PanelContainer.new()
		paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
		paper.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(18, 16, 18, 16)))
		_story_page.add_child(paper)
		_story_line = Label.new()
		_story_line.name = "CharacterDialogue"
		_story_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_story_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		CozyUI.label(_story_line)
		paper.add_child(_story_line)
		_story_action = Button.new()
		_story_action.name = "StoryNextStep"
		_story_action.custom_minimum_size.y = 44
		_story_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		CozyUI.button(_story_action, "primary")
		_story_action.pressed.connect(func() -> void: story_requested.emit("product"))
		_story_page.add_child(_story_action)
		var goodbye := Button.new()
		goodbye.text = "See you in a bit"
		goodbye.custom_minimum_size.y = 44
		goodbye.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		CozyUI.button(goodbye, "quiet")
		goodbye.pressed.connect(close_drawer)
		_story_page.add_child(goodbye)
	_empty_team_panel = PanelContainer.new()
	_empty_team_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_team_panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(24, 24, 24, 24)))
	drawer.add_child(_empty_team_panel)
	var empty := VBoxContainer.new()
	empty.alignment = BoxContainer.ALIGNMENT_CENTER
	empty.add_theme_constant_override("separation", 16)
	_empty_team_panel.add_child(empty)
	var title := _section_label("Your first teammate")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.add_child(title)
	var hint := Label.new()
	hint.text = "Hire Mina, then assign the website from her desk."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(hint)
	empty.add_child(hint)
	var hire := Button.new()
	hire.text = "Open Company Journey"
	CozyUI.button(hire, "primary")
	hire.pressed.connect(journey_requested.emit)
	empty.add_child(hire)
	_empty_team_panel.hide()
	_tabs.tab_changed.connect(_on_tab_changed)
	return drawer

func _select_drawer_tab(index: int) -> void:
	_tabs.current_tab = index

func _tab_scroll(name_value: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = name_value
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	CozyUI.scroll(scroll)
	return scroll

func _tab_content(scroll: ScrollContainer) -> VBoxContainer:
	var page := PanelContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 12, 12, 12)))
	scroll.add_child(page)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(280.0, 0.0)
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
	notebook.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 12, 12, 12)))
	tab.add_child(notebook)
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	CozyUI.scroll(_chat_scroll)
	_chat_scroll.get_v_scroll_bar().changed.connect(_scroll_chat_to_bottom)
	_chat_scroll.gui_input.connect(_on_chat_scroll_input)
	_chat_scroll.get_v_scroll_bar().gui_input.connect(_on_chat_scroll_input)
	_chat_scroll.get_v_scroll_bar().value_changed.connect(func(value: float) -> void:
		var bar := _chat_scroll.get_v_scroll_bar()
		if value >= bar.max_value - bar.page - 8: _chat_follow_tail = true
	)
	notebook.add_child(_chat_scroll)
	var chat_margin := MarginContainer.new()
	chat_margin.add_theme_constant_override("margin_left", 4)
	chat_margin.add_theme_constant_override("margin_right", 4)
	chat_margin.add_theme_constant_override("margin_top", 4)
	chat_margin.add_theme_constant_override("margin_bottom", 4)
	chat_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_scroll.add_child(chat_margin)
	_chat_log = VBoxContainer.new()
	_chat_log.custom_minimum_size = Vector2.ZERO
	_chat_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_log.add_theme_constant_override("separation", 12)
	chat_margin.add_child(_chat_log)
	_show_chat_hint("Hire your first teammate from Company Journey.")
	var composer_frame := PanelContainer.new()
	_chat_composer = composer_frame
	composer_frame.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(8, 8, 8, 8)))
	tab.add_child(composer_frame)
	var composer_margin := MarginContainer.new()
	composer_margin.add_theme_constant_override("margin_left", 0)
	composer_margin.add_theme_constant_override("margin_right", 0)
	composer_margin.add_theme_constant_override("margin_top", 0)
	composer_margin.add_theme_constant_override("margin_bottom", 0)
	composer_frame.add_child(composer_margin)
	var composer_column := VBoxContainer.new()
	composer_column.add_theme_constant_override("separation", 5)
	composer_margin.add_child(composer_column)
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 4)
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
	_chat_send_button.text = "Ask"
	_chat_send_button.custom_minimum_size = Vector2(100.0, 48.0)
	_chat_send_button.clip_text = true
	_chat_send_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_chat_send_button.pressed.connect(_submit_chat)
	_style_action_button(_chat_send_button, VERMILION, true)
	input_row.add_child(_chat_send_button)
	_chat_helper = Label.new()
	_chat_helper.text = "Conversation only — no tools or files."
	CozyUI.label(_chat_helper)
	_chat_helper.add_theme_color_override("font_color", CHARCOAL)
	_chat_helper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chat_helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	composer_column.add_child(_chat_helper)
	_make_job_button = Button.new()
	_make_job_button.text = "Create work order"
	_make_job_button.custom_minimum_size = Vector2(0.0, 40.0)
	_make_job_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_make_job_button.disabled = true
	_make_job_button.visible = false
	_make_job_button.pressed.connect(_make_last_chat_a_job)
	CozyUI.button(_make_job_button, "quiet")
	tab.add_child(_make_job_button)
	_chat_active_banner = PanelContainer.new()
	_chat_active_banner.add_theme_stylebox_override("panel", CozyUI.paper())
	var active_content := VBoxContainer.new()
	active_content.add_theme_constant_override("separation", 8)
	_chat_active_banner.add_child(active_content)
	_chat_active_copy = Label.new()
	_chat_active_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(_chat_active_copy)
	active_content.add_child(_chat_active_copy)
	_chat_activity_button = Button.new()
	_chat_activity_button.text = "Open Activity"
	CozyUI.button(_chat_activity_button, "secondary")
	_chat_activity_button.pressed.connect(func() -> void:
		if not _active_employee_id.is_empty(): _select_employee(_active_employee_id)
		_tabs.current_tab = 2
	)
	active_content.add_child(_chat_activity_button)
	tab.add_child(_chat_active_banner)
	_chat_active_banner.hide()
	return tab

func _build_work_tab() -> VBoxContainer:
	var tab := VBoxContainer.new()
	tab.name = "Assign"
	var scroll := _tab_scroll("AssignmentFields")
	tab.add_child(scroll)
	var content := _tab_content(scroll)
	# Keep the complete collapsed attachment frame above the pinned budget
	# sheet. Opening optional reference fields remains intentionally scrollable.
	content.add_theme_constant_override("separation", 4)
	_draft_label = Label.new()
	_draft_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(_draft_label)
	_draft_label.add_theme_color_override("font_color", CHARCOAL)
	content.add_child(_draft_label)
	_draft_reset_button = Button.new()
	_draft_reset_button.text = "New side project"
	_style_action_button(_draft_reset_button, INDIGO, false)
	_draft_reset_button.pressed.connect(func() -> void:
		_purpose_chosen_by_player = true
		_job_picker.select(CANNED_JOBS.size())
		_on_job_selected(CANNED_JOBS.size())
	)
	content.add_child(_draft_reset_button)
	_draft_reset_button.hide()
	_purpose_picker = OptionButton.new()
	_purpose_picker.fit_to_longest_item = false
	_purpose_picker.clip_text = true
	_purpose_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_dropdown(_purpose_picker)
	_purpose_picker.item_selected.connect(_choose_work_purpose)
	content.add_child(_purpose_picker)
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
	# One visible purpose picker covers ordinary templates and Journey. The old
	# index picker remains an internal template selector, not a second user choice.
	_job_picker.hide()
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
	_attachment_toggle = Button.new()
	_attachment_toggle.text = "Attach a Studio file"
	CozyUI.disclosure(_attachment_toggle, false)
	_attachment_toggle.pressed.connect(func() -> void:
		_set_attachment_expanded(not _attachment_expanded, true)
	)
	content.add_child(_attachment_toggle)
	_attachment_label = _section_label("Reference file (optional)")
	_attachment_label.visible = false
	content.add_child(_attachment_label)
	_attachment_picker = OptionButton.new()
	_attachment_picker.fit_to_longest_item = false
	_attachment_picker.clip_text = true
	_attachment_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_attachment_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_picker.visible = false
	_style_dropdown(_attachment_picker)
	_attachment_picker.add_item("No studio file attached")
	_attachment_picker.set_item_metadata(0, "")
	content.add_child(_attachment_picker)
	_attachment_reveal_spacer = Control.new()
	_attachment_reveal_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attachment_reveal_spacer.hide()
	content.add_child(_attachment_reveal_spacer)
	_budget_picker = OptionButton.new()
	_budget_picker.fit_to_longest_item = false
	_budget_picker.clip_text = true
	_style_dropdown(_budget_picker)
	_budget_picker.add_item("AI cap · 12,000 tokens", 12000)
	_budget_picker.add_item("AI cap · 24,000 tokens", 24000)
	_budget_picker.item_selected.connect(func(index: int) -> void: requested_token_budget = _budget_picker.get_item_id(index))
	var confirmation := Label.new()
	confirmation.text = "Your teammate can use tools and make files. Real AI charges apply, up to this token limit."
	confirmation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(confirmation)
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 8, 12, 8)))
	tab.add_child(footer)
	var footer_content := VBoxContainer.new()
	footer_content.add_theme_constant_override("separation", 6)
	footer.add_child(footer_content)
	footer_content.add_child(_budget_picker)
	footer_content.add_child(confirmation)
	_assignment_error = Label.new()
	_assignment_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(_assignment_error)
	_assignment_error.add_theme_color_override("font_color", ALERT_INK)
	_assignment_error.hide()
	content.add_child(_assignment_error)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	footer_content.add_child(action_row)
	_assign_button = Button.new()
	_assign_button.text = "Start work order"
	_assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_assign_button.pressed.connect(_submit_assignment)
	_style_action_button(_assign_button, VERMILION, true)
	action_row.add_child(_assign_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.custom_minimum_size = Vector2(72.0, 0.0)
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_active_job)
	CozyUI.button(_cancel_button, "danger")
	_on_job_selected(CANNED_JOBS.size())
	return tab

func _build_journal_tab() -> VBoxContainer:
	var tab := VBoxContainer.new()
	tab.name = "Activity"
	tab.add_theme_constant_override("separation", 4)
	var scroll := _tab_scroll("ActivityContent")
	_activity_scroll = scroll
	scroll.follow_focus = true
	tab.add_child(scroll)
	var content := _tab_content(scroll)
	content.add_theme_constant_override("separation", 4)
	_activity_content = content
	_history_picker = OptionButton.new()
	_history_picker.fit_to_longest_item = false
	_history_picker.clip_text = true
	_history_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_dropdown(_history_picker)
	_history_picker.item_selected.connect(func(index: int) -> void:
		_activity_job_id = str(_history_picker.get_item_metadata(index))
		_refresh_selected_activity()
		artifact_refresh_requested.emit(_activity_job_id)
	)
	content.add_child(_history_picker)
	_status_card = PanelContainer.new()
	_status_card.add_theme_stylebox_override("panel", CozyUI.card(Vector4(8, 8, 8, 8)))
	content.add_child(_status_card)
	var status_content := VBoxContainer.new()
	status_content.add_theme_constant_override("separation", 4)
	_status_card.add_child(status_content)
	_last_status_label = Label.new()
	_last_status_label.text = "Current work"
	CozyUI.label(_last_status_label, "action")
	_last_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_content.add_child(_last_status_label)
	_status_label = Label.new()
	_status_label.text = "No active work order."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.max_lines_visible = 3
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	CozyUI.label(_status_label)
	status_content.add_child(_status_label)
	_delivery_list = VBoxContainer.new()
	_delivery_list.add_theme_constant_override("separation", 8)
	_delivery_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_delivery_list)
	_approval_box = PanelContainer.new()
	_approval_box.visible = false
	_approval_box.add_theme_stylebox_override("panel", CozyUI.card(Vector4(8, 8, 8, 8)))
	var approval_content := VBoxContainer.new()
	approval_content.add_theme_constant_override("separation", 4)
	_approval_box.add_child(approval_content)
	approval_content.add_child(_section_label("Decision needed"))
	_approval_label = Label.new()
	_approval_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(_approval_label)
	approval_content.add_child(_approval_label)
	var approval_buttons := HBoxContainer.new()
	approval_buttons.add_theme_constant_override("separation", 8)
	for approved: bool in [true, false]:
		var button := Button.new()
		button.text = "Approve" if approved else "Deny"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_decide_approval.bind(approved))
		CozyUI.button(button, "primary" if approved else "secondary")
		approval_buttons.add_child(button)
	approval_content.add_child(approval_buttons)
	content.add_child(_approval_box)
	_promotion_box = PanelContainer.new()
	_promotion_box.visible = false
	_promotion_box.add_theme_stylebox_override("panel", CozyUI.card(Vector4(8, 8, 8, 8)))
	var promotion_content := VBoxContainer.new()
	promotion_content.add_theme_constant_override("separation", 8)
	_promotion_box.add_child(promotion_content)
	_promotion_label = Label.new()
	_promotion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(_promotion_label)
	promotion_content.add_child(_promotion_label)
	for approved: bool in [true, false]:
		var button := Button.new()
		button.text = "Add to Studio" if approved else "Keep with job"
		button.pressed.connect(_decide_promotion.bind(approved))
		CozyUI.button(button, "primary" if approved else "quiet")
		promotion_content.add_child(button)
		_promotion_actions.append(button)
	content.add_child(_promotion_box)
	_steer_box = VBoxContainer.new()
	_steer_box.visible = false
	_steer_box.add_theme_constant_override("separation", 4)
	_steer_box.add_child(_section_label("Update active work"))
	_steer_input = LineEdit.new()
	_steer_input.placeholder_text = "Add a correction or constraint"
	_steer_input.max_length = 2000
	_steer_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_steer_input.text_submitted.connect(_submit_steer_text)
	_style_text_input(_steer_input)
	_steer_box.add_child(_steer_input)
	_steer_button = Button.new()
	_steer_button.text = "Send update"
	_steer_button.pressed.connect(_submit_steer)
	CozyUI.button(_steer_button, "secondary")
	_steer_box.add_child(_steer_button)
	content.add_child(_steer_box)
	_activity_cancel = _cancel_button
	_activity_cancel.text = "Cancel work order"
	_activity_cancel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(_activity_cancel)
	_activity_cancel.hide()
	_activity_details_toggle = Button.new()
	_activity_details_toggle.text = "Work details"
	CozyUI.disclosure(_activity_details_toggle, false)
	_activity_details_toggle.pressed.connect(func() -> void:
		_activity_details_expanded = not _activity_details_expanded
		_refresh_selected_activity()
		if _activity_details_expanded: call_deferred("_reveal_activity_details")
	)
	content.add_child(_activity_details_toggle)
	_activity_details = VBoxContainer.new()
	_activity_details.add_theme_constant_override("separation", 8)
	_activity_details.hide()
	content.add_child(_activity_details)
	_activity_heading = _section_label("Latest activity")
	_activity_details.add_child(_activity_heading)
	_event_log = RichTextLabel.new()
	_event_log.bbcode_enabled = true
	_event_log.fit_content = true
	_event_log.scroll_active = false
	_event_log.add_theme_stylebox_override("normal", CozyUI.card(Vector4(8, 8, 8, 8)))
	CozyUI.rich_text(_event_log)
	_activity_details.add_child(_event_log)
	_usage_page = _tab_scroll("ActivityLedger")
	_usage_page.hide()
	tab.add_child(_usage_page)
	var ledger := _tab_content(_usage_page)
	ledger.add_child(_section_label("AI ledger"))
	var currency_note := Label.new()
	currency_note.text = "Real money, not company cash."
	currency_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(currency_note)
	ledger.add_child(currency_note)
	var today_card := PanelContainer.new()
	today_card.add_theme_stylebox_override("panel", CozyUI.card())
	ledger.add_child(today_card)
	var today_content := VBoxContainer.new()
	today_content.add_theme_constant_override("separation", 4)
	today_card.add_child(today_content)
	today_content.add_child(_section_label("Today"))
	_usage_today_label = Label.new()
	_usage_today_label.text = "$0.0000 USD"
	CozyUI.label(_usage_today_label, "numeric")
	today_content.add_child(_usage_today_label)
	var today_note := Label.new()
	today_note.text = "Chat, work, and evaluations"
	today_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(today_note, "meta")
	today_content.add_child(today_note)
	var work_card := PanelContainer.new()
	work_card.add_theme_stylebox_override("panel", CozyUI.card())
	ledger.add_child(work_card)
	var work_content := VBoxContainer.new()
	work_content.add_theme_constant_override("separation", 4)
	work_card.add_child(work_content)
	_usage_work_title = Label.new()
	_usage_work_title.text = "Selected work"
	_usage_work_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_usage_work_title.max_lines_visible = 2
	_usage_work_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_usage_work_title.mouse_filter = Control.MOUSE_FILTER_PASS
	CozyUI.label(_usage_work_title, "action")
	work_content.add_child(_usage_work_title)
	_usage_label = Label.new()
	_usage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_usage_label.text = "$0.0000 USD · 0 tokens"
	CozyUI.label(_usage_label)
	work_content.add_child(_usage_label)
	_usage_label.tooltip_text = "A token limit bounds each work order. Its dollar cost depends on the model."
	_usage_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_usage_back_button = Button.new()
	_usage_back_button.text = "Back to Activity"
	_usage_back_button.custom_minimum_size.x = 320
	_usage_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	CozyUI.button(_usage_back_button, "quiet")
	_usage_back_button.pressed.connect(_set_usage_expanded.bind(false))
	# The return action is pinned, just like spend, even for an unusually long
	# work title. Only the ledger's reading area scrolls.
	_usage_back_button.hide()
	tab.add_child(_usage_back_button)
	_activity_footer = PanelContainer.new()
	_activity_footer.name = "ActivitySpendFooter"
	_activity_footer.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(ACTIVITY_FOOTER_INSET.x, ACTIVITY_FOOTER_INSET.y, ACTIVITY_FOOTER_INSET.x, ACTIVITY_FOOTER_INSET.y)))
	tab.add_child(_activity_footer)
	var footer_content := VBoxContainer.new()
	footer_content.add_theme_constant_override("separation", 4)
	_activity_footer.add_child(footer_content)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 8)
	footer_content.add_child(footer_row)
	_spend_label = Label.new()
	_spend_label.text = "AI spend today\n$0.0000 USD"
	_spend_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_spend_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spend_label.mouse_filter = Control.MOUSE_FILTER_PASS
	CozyUI.label(_spend_label)
	footer_row.add_child(_spend_label)
	_usage_toggle = Button.new()
	_usage_toggle.text = "Usage details"
	_usage_toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	CozyUI.disclosure(_usage_toggle, false)
	_usage_toggle.pressed.connect(func() -> void:
		_set_usage_expanded(not _usage_expanded)
	)
	footer_row.add_child(_usage_toggle)
	# Keep the public meter projection for existing usage consumers, but do not
	# render an unbounded daily cost as invented job progress.
	_token_meter = ProgressBar.new()
	_token_meter.max_value = _spend_warning
	_token_meter.show_percentage = false
	content.add_child(_token_meter)
	_token_meter.hide()
	return tab

func _set_usage_expanded(expanded: bool, restore_focus: bool = true, restore_scroll: bool = true) -> void:
	if _usage_page == null: return
	var was_expanded := _usage_expanded
	if expanded and not _usage_expanded:
		_usage_return_scroll = _activity_scroll.scroll_vertical
	_usage_expanded = expanded
	_usage_page.visible = expanded
	_usage_back_button.visible = expanded
	_activity_scroll.visible = not expanded
	CozyUI.disclosure(_usage_toggle, expanded)
	if expanded:
		_usage_page.scroll_vertical = 0
		if restore_focus: _usage_back_button.grab_focus()
	else:
		if was_expanded and restore_scroll: _activity_scroll.set_deferred("scroll_vertical", _usage_return_scroll)
		if restore_focus and _usage_toggle.is_visible_in_tree(): _usage_toggle.grab_focus()

func _reveal_activity_details() -> void:
	# Wait for the expanded text to shape, then land on its heading and first
	# complete entry instead of exposing an orphaned line below the fold.
	var requested_job := _activity_job_id
	await get_tree().process_frame
	await get_tree().process_frame
	if not _activity_details_expanded or _usage_expanded or requested_job != _activity_job_id: return
	if not _drawer_open or _tabs.current_tab != 2: return
	# A short timeline still needs enough trailing paper to align its disclosure
	# with the viewport. Otherwise maximum-scroll clamping leaves fragments of
	# earlier approval buttons stranded across the top reading edge.
	_activity_details.custom_minimum_size.y = maxf(0.0, _activity_scroll.size.y - _activity_details_toggle.size.y - _activity_content.get_theme_constant("separation"))
	await get_tree().process_frame
	await get_tree().process_frame
	if not _activity_details_expanded or _usage_expanded or requested_job != _activity_job_id: return
	if not _drawer_open or _tabs.current_tab != 2: return
	_activity_scroll.scroll_vertical += int(roundf(_activity_details_toggle.global_position.y - _activity_scroll.global_position.y))

func _refresh_usage(view: Dictionary) -> void:
	if _usage_label == null: return
	_usage_work_title.text = "Selected work · " + str(view.get("title", "Work order")) if not view.is_empty() else "No work selected"
	_usage_work_title.tooltip_text = _usage_work_title.text
	if view.has("inputTokens") or view.has("outputTokens") or view.has("cost"):
		_usage_label.text = "$%.4f USD · %d tokens" % [float(view.get("cost", 0.0)), int(view.get("inputTokens", 0)) + int(view.get("outputTokens", 0))]
	else:
		_usage_label.text = str(view.get("usage", "$0.0000 USD · 0 tokens")).replace("This work order · ", "").replace("Usage details · ", "")
	_usage_today_label.text = "$%.4f USD" % _daily_ai_spend

func _build_studio_tab() -> ScrollContainer:
	var scroll := _tab_scroll("Studio")
	var content := _tab_content(scroll)
	_artifact_list = VBoxContainer.new()
	_artifact_list.add_theme_constant_override("separation", 12)
	_artifact_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_artifact_list)
	_add_empty_artifact("Keep a delivery to share it with your team.")
	return scroll

func _section_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	CozyUI.label(label, "title")
	return label

func _style_action_button(button: Button, accent: Color, filled: bool) -> void:
	CozyUI.button(button, "primary" if filled and accent == VERMILION else "secondary")

func _style_dropdown(option: OptionButton) -> void:
	CozyUI.dropdown(option)

func _style_close_button(button: Button) -> void:
	CozyUI.close(button)

func _style_text_input(control: Control) -> void:
	CozyUI.input(control)

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
	_drawer_tween.tween_method(func(x: float) -> void: _drawer_panel.position.x = roundf(x), _drawer_panel.position.x, target_x, 0.16)
	if not open:
		_drawer_tween.finished.connect(func() -> void:
			if not _drawer_open:
				_drawer_panel.visible = false
		)
	_refresh_team_card_styles()

func close_drawer(animated: bool = true) -> void:
	var connection_was_open := _connection_panel != null and _connection_panel.visible
	_cancel_grok_login_if_pending()
	if _connection_panel != null:
		_connection_panel.visible = false
	_set_drawer_open(false, animated)
	# Roster hydration closes this drawer and used to leave Start disabled with
	# Connect already dismissed. Re-enable the work action so it can reopen Connect.
	_refresh_operation_availability()
	if connection_was_open:
		_connection_focus_return = null
		_settings_button.grab_focus()

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
	for index: int in range(_tab_buttons.size()):
		CozyUI.tab_button(_tab_buttons[index], index == _tab)
	if _tab != 2 and _usage_expanded: _set_usage_expanded(false, false)
	if _tab == 1 and _attachment_expanded:
		call_deferred("_reveal_attachment_fields", _attachment_reveal_revision)
	_refresh_employee_header()
	if _tab == 2 and not _activity_job_id.is_empty() and _worker_connected:
		artifact_refresh_requested.emit(_activity_job_id)
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
		elif _usage_expanded:
			_set_usage_expanded(false)
		else:
			close_drawer()
		get_viewport().set_input_as_handled()

func _team_list() -> VBoxContainer:
	return find_child("TeamList", true, false) as VBoxContainer

func configure_employees(records: Array[EmployeeRecord]) -> void:
	_employees = records
	_empty_team_panel.visible = records.is_empty()
	_header_shell.visible = not records.is_empty()
	_tabs.visible = not records.is_empty() and not story_mode
	_tab_strip.visible = not records.is_empty() and not story_mode
	# Hiding only its children leaves this expanding stack claiming half the
	# empty drawer. Onboarding owns the complete paper surface instead.
	(_tabs.get_parent() as Control).visible = not records.is_empty() and not story_mode
	if _story_page != null: _story_page.visible = not records.is_empty()
	var list := _team_list()
	for child: Node in list.get_children():
		child.queue_free()
	_team_buttons.clear()
	if records.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Your team starts here"
		empty_label.custom_minimum_size = Vector2(100.0, 100.0)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		CozyUI.label(empty_label)
		empty_label.add_theme_color_override("font_color", OFF_WHITE)
		list.add_child(empty_label)
		var hire_button := Button.new()
		hire_button.text = "Hire Mina"
		CozyUI.button(hire_button, "primary")
		hire_button.pressed.connect(journey_requested.emit)
		list.add_child(hire_button)
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
		var selection_frame := Panel.new()
		selection_frame.name = "SelectionFrame"
		selection_frame.add_theme_stylebox_override("panel", NotebookSkin.outer_frame())
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
		name_label.name = "EmployeeName"
		name_label.text = record.display_name.to_upper()
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.tooltip_text = record.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		CozyUI.label(name_label, "identity")
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
	_refresh_rail_next_step()
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
	if _selected_employee_id != employee_id:
		_purpose_chosen_by_player = false
		_set_attachment_expanded(false)
		_set_usage_expanded(false, false, false)
	if _selected_employee_id != employee_id and not milestone_id.is_empty():
		_on_job_selected(CANNED_JOBS.size())
		_job_picker.select(CANNED_JOBS.size())
		_custom_title_input.clear()
	_selected_employee_id = employee_id
	_activity_job_id = ""
	_refresh_work_purposes()
	_refresh_team_card_styles()
	var journey_draft := _available_milestone_for(employee_id)
	if not _purpose_chosen_by_player and not journey_draft.is_empty():
		_apply_milestone_draft(journey_draft)
	elif not _custom_mode and _job_picker != null:
		for index: int in range(CANNED_JOBS.size()):
			var job: Dictionary = CANNED_JOBS[index]
			if str(job.get("employee_id", "")) == employee_id:
				_job_picker.select(index)
				_assignment_preview.text = str(job.get("assignment", ""))
				break
	_refresh_employee_header()
	_refresh_chat_mode()
	_show_empty_chat()
	_refresh_selected_activity()
	if _worker_connected and not story_mode:
		chat_history_requested.emit(employee_id)

func _refresh_team_card_styles() -> void:
	for id: String in _team_buttons:
		var button: Button = _team_buttons[id]
		button.add_theme_stylebox_override("focus", CozyUI.focus())
		var selection_frame := button.get_node_or_null("SelectionFrame") as Panel
		if selection_frame != null:
			selection_frame.visible = _drawer_open and id == _selected_employee_id

func _selected_employee() -> EmployeeRecord:
	for record: EmployeeRecord in _employees:
		if record.id == _selected_employee_id:
			return record
	return null

func _set_employee_heading(value: String) -> void:
	var face := GameFonts.display_font_for(value)
	_employee_name.add_theme_font_override("font", face)
	_employee_name.set_meta("full_heading", value)
	_employee_name.set_meta("original_heading", value)
	_employee_name.tooltip_text = value
	_fit_employee_heading()

func _fit_employee_heading() -> void:
	if _employee_name == null or not _employee_name.has_meta("full_heading"): return
	var full := str(_employee_name.get_meta("full_heading"))
	var face := _employee_name.get_theme_font("font")
	var size := _employee_name.get_theme_font_size("font_size")
	var width := _employee_name.size.x
	_employee_name.text = full
	if width <= 0 or face.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width: return
	# Slab does not contain an ellipsis glyph. Fit with covered ASCII dots while
	# keeping the same font and the complete identity in the tooltip/record.
	var shortened := full
	while not shortened.is_empty() and face.get_string_size(shortened + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		shortened = shortened.left(-1)
	_employee_name.text = shortened + "..."

func _refresh_employee_header() -> void:
	var portrait_frame := _employee_portrait.get_parent() as PanelContainer
	if not story_mode and _tabs != null and _tabs.current_tab == 3:
		_set_employee_heading("Studio")
		_employee_meta.text = "Approved deliveries"
		_employee_meta.tooltip_text = _employee_meta.text
		_employee_status.text = "Shared team files"
		_employee_status.add_theme_color_override("font_color", INDIGO)
		_employee_portrait.texture = null
		portrait_frame.hide()
		_header_icon.visible = true
		return
	portrait_frame.show()
	var employee := _selected_employee()
	if employee == null:
		_set_employee_heading("Your team")
		_employee_meta.text = "No employee selected"
		_employee_meta.tooltip_text = _employee_meta.text
		_employee_status.text = ""
		_employee_portrait.texture = null
		_header_icon.visible = false
		return
	_set_employee_heading(employee.display_name)
	_employee_portrait.texture = CharacterArt.bust_portrait(employee.id)
	_header_icon.visible = false
	var activity := _employee_ui_state(employee.id)
	_employee_meta.text = _employee_specialty(employee.id)
	_employee_meta.tooltip_text = _employee_meta.text
	_employee_status.text = activity.left(1).to_upper() + activity.substr(1)
	_employee_status.add_theme_color_override("font_color", _state_text_color(activity))
	if story_mode:
		_employee_portrait.texture = StoryMoments.portrait(employee.id)
		_employee_meta.text = StoryMoments.role(employee.id)
		_employee_status.hide()
		_refresh_story()

func _refresh_story() -> void:
	if _story_page == null: return
	var moment := StoryMoments.conversation(_selected_employee_id, _journey_state)
	_story_line.text = "“" + str(moment.get("line", "")) + "”"
	_story_action.text = str(moment.get("action", "Open our notebook"))

func _refresh_team_statuses() -> void:
	_refresh_employee_header()
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
			# The status icon already conveys approval/delivery/failure. An extra
			# badge is only needed for older deliveries alongside a running job.
			attention_badge.visible = state in ["working", "queued"] and _has_pending_delivery(employee_id)

func _employee_ui_state(employee_id: String) -> String:
	if employee_id == _active_employee_id and not _approval_id.is_empty():
		return "needs approval"
	if employee_id == _active_employee_id and not _active_job_id.is_empty():
		return "working" if _active_job_running else "queued"
	var latest := _latest_job_for(employee_id)
	var status := str((_job_views.get(latest, {}) as Dictionary).get("status", ""))
	if status in ["blocked", "failed", "cancelled"]:
		return "cancelled" if status == "cancelled" else "needs retry"
	if employee_id == _attention_employee_id or _has_pending_delivery(employee_id):
		return "delivery ready"
	if _clock_phase == "lunch":
		return "at lunch"
	if _clock_phase == "off":
		return "off shift"
	return "available"

func _state_color(state: String) -> Color:
	match state:
		"needs approval", "delivery ready", "needs retry", "cancelled":
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
		"needs approval", "delivery ready", "at lunch", "needs retry", "cancelled":
			return ALERT_INK
		"working", "queued":
			return INDIGO
		"off shift":
			return CHARCOAL
	return SUCCESS_INK

func _state_icon(state: String) -> Texture2D:
	match state:
		"needs approval", "delivery ready", "needs retry", "cancelled":
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
		_show_chat_hint("Hire your first teammate from Company Journey.")
		return
	if OS.has_feature("web"):
		_show_chat_hint("Your team develops products through Company Journey → New Product. AI chat and file work orders are available in the desktop edition.")
		return
	var greeting := "What are we building? We can shape the idea before creating a work order." if employee.id == "mira" else "What should we test or grow? We can sharpen it before creating a work order."
	var milestone := _available_milestone_for(employee.id)
	if str(milestone.get("id", "")) == "website":
		greeting = "Chat is optional. Open Assign and choose Journey · Build a website to finish Day 1."
	_append_chat_line("employee", employee.display_name, greeting)

func _append_chat_line(sender: String, name_value: String, content: String) -> void:
	if sender == "player": _chat_follow_tail = true
	_chat_transcript += "%s\n%s\n\n" % [name_value, content]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if sender == "employee":
		var avatar_frame := PanelContainer.new()
		avatar_frame.name = "ChatFaceFrame"
		avatar_frame.custom_minimum_size = Vector2(40.0, 40.0)
		avatar_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		avatar_frame.add_theme_stylebox_override("panel", CozyUI.card(Vector4(4, 4, 4, 4)))
		row.add_child(avatar_frame)
		var avatar := TextureRect.new()
		avatar.name = "ChatFace"
		var employee := _selected_employee()
		avatar.texture = CharacterArt.chat_face(employee.id) if employee != null else null
		avatar.custom_minimum_size = Vector2(32, 32)
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		avatar_frame.add_child(avatar)
	else:
		var player_spacer := Control.new()
		player_spacer.custom_minimum_size = Vector2(12.0, 0.0)
		row.add_child(player_spacer)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", CozyUI.bubble(sender, Vector4(10, 10, 10, 10)))
	row.add_child(bubble)
	var bubble_margin := VBoxContainer.new()
	bubble_margin.add_theme_constant_override("separation", 6)
	bubble.add_child(bubble_margin)
	var message_label := RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.scroll_active = false
	message_label.selection_enabled = true
	message_label.text = ArtifactViewer.format_markdown(content)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("normal_font_size", GameFonts.BODY_DEFAULT)
	message_label.add_theme_font_size_override("bold_font_size", GameFonts.BODY_DEFAULT)
	message_label.add_theme_color_override("default_color", CHARCOAL)
	CozyUI.rich_text(message_label)
	bubble_margin.add_child(message_label)
	if sender == "employee":
		_latest_reply_content = bubble_margin
		if _make_job_button != null:
			_make_job_button.reparent(bubble_margin)
	_chat_log.add_child(row)
	_animate_entry(row, -7.0 if sender == "employee" else 7.0)
	call_deferred("_scroll_chat_to_bottom")

func _clear_chat() -> void:
	_chat_follow_tail = true
	_chat_transcript = ""
	_last_chat_prompt = ""
	_chat_messages.clear()
	if _make_job_button != null:
		_make_job_button.disabled = true
		_make_job_button.visible = false
		# The contextual control is reused across replies and must survive the
		# message subtree it currently belongs to being removed.
		_make_job_button.reparent(_tabs.get_tab_control(0))
	_latest_reply_content = null
	for child: Node in _chat_log.get_children():
		_chat_log.remove_child(child)
		child.queue_free()

func _show_chat_hint(message: String) -> void:
	var hint_panel := PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", CozyUI.card())
	var hint := Label.new()
	hint.text = message
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(hint)
	hint.add_theme_color_override("font_color", MUTED_INK)
	hint_panel.add_child(hint)
	_chat_log.add_child(hint_panel)
	_animate_entry(hint_panel)

func _scroll_chat_to_bottom() -> void:
	# Range changes fire again after text shaping/layout. No suspended coroutine
	# can outlive a replaced fixture or steal an older-history reader's position.
	if _chat_scroll != null and _chat_follow_tail:
		_chat_scroll.set_deferred("scroll_vertical", int(_chat_scroll.get_v_scroll_bar().max_value))

func _on_chat_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_LEFT]:
		_chat_follow_tail = false

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
	if _chat_pending: return
	if not _active_job_id.is_empty():
		_tabs.current_tab = 2
		return
	if not _credential_configured:
		_open_connection_settings()
		return
	if not _worker_connected:
		set_worker_connection_error("Worker is not connected")
		_open_connection_settings()
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
	if OS.has_feature("web"):
		_chat_input.editable = false
		_chat_input.placeholder_text = "AI chat is available on desktop"
		_chat_send_button.text = "Desktop only"
		_chat_send_button.disabled = true
		_chat_helper.text = "Develop products with your team in Company Journey → New Product."
		_make_job_button.visible = false
		return
	var selected_employee := _selected_employee()
	var has_employee := selected_employee != null
	var has_active_job := not _active_job_id.is_empty()
	var can_chat := has_employee and _credential_configured and _worker_connected
	_chat_composer.visible = not has_active_job
	_chat_active_banner.visible = has_active_job
	_chat_active_copy.text = "%s is working. Send changes or follow progress in Activity." % _active_employee_name()
	_chat_input.editable = can_chat and not _chat_pending and not has_active_job
	_chat_send_button.disabled = not has_employee or _chat_pending
	if _chat_pending:
		_chat_send_button.text = "."
		_chat_input.placeholder_text = "Waiting for a reply…"
		_chat_helper.text = "Waiting for a conversational reply — no work has started."
	elif has_active_job:
		_chat_send_button.text = "Open Activity"
		_chat_input.placeholder_text = "Work is in Activity"
		_chat_helper.text = "%s is busy. Send work instructions from Activity." % _active_employee_name()
	elif not _credential_configured or not _worker_connected:
		_chat_send_button.text = "Connect"
		_chat_input.placeholder_text = "Connect AI to begin"
		_chat_helper.text = "Connect AI for conversations and work orders."
	else:
		_chat_send_button.text = "Ask %s" % selected_employee.display_name if has_employee else "Ask"
		_chat_input.placeholder_text = "Talk through an idea…"
		_chat_helper.text = "Conversation only — no tools or files."
	_chat_send_button.tooltip_text = _chat_send_button.text
	_make_job_button.visible = not _make_job_button.disabled and not has_active_job and not _chat_pending

func _make_last_chat_a_job() -> void:
	if _last_chat_prompt.is_empty():
		return
	_job_picker.select(CANNED_JOBS.size())
	_on_job_selected(CANNED_JOBS.size())
	_custom_title_input.text = "Company direction brief"
	_assignment_preview.text = _chat_work_order_draft()
	_draft_discussion = _discussion_context()
	_refresh_work_purposes()
	_tabs.current_tab = 1
	_custom_title_input.grab_focus()

func _remember_chat_message(sender: String, content: String) -> void:
	_chat_messages.append({"sender": sender, "content": content.strip_edges()})
	while _chat_messages.size() > 24:
		_chat_messages.pop_front()

func _chat_work_order_draft() -> String:
	return ("Write next-steps.md: a concise company direction brief based on this discussion. Recommend one specific deliverable, its audience and offer, and a small validation step. Label assumptions. This ordinary work order does not complete a Journey milestone. To build a Journey deliverable instead, choose it in the purpose selector.\n\nDiscussion context:\n" + _discussion_context()).left(3800)

func _discussion_context() -> String:
	var lines: PackedStringArray = []
	var first := maxi(0, _chat_messages.size() - 6)
	for index: int in range(first, _chat_messages.size()):
		var message: Dictionary = _chat_messages[index]
		var speaker := "Founder" if str(message.get("sender", "")) == "player" else _selected_employee().display_name
		lines.append("%s: %s" % [speaker, str(message.get("content", "")).strip_edges()])
	return "\n".join(lines).left(3800)

func set_journey_state(value: Dictionary) -> void:
	_journey_state = value
	_refresh_work_purposes()
	_refresh_rail_next_step()
	_refresh_story()

func _available_milestone_for(employee_id: String) -> Dictionary:
	for definition: Dictionary in _journey_state.get("milestones", []):
		if str(definition.get("employeeId", "")) != employee_id: continue
		if str(definition.get("state", "")) in ["available", "revision_required"]: return definition
	return {}

func _refresh_rail_next_step() -> void:
	if _next_step_label == null: return
	if story_mode:
		_next_step_label.text = ""
		_next_step_label.hide()
		return
	if _employees.is_empty():
		_next_step_label.text = ""
		_next_step_label.visible = false
		return
	var line := CompanyPanel.next_step_line(_journey_state).trim_prefix("NEXT · ")
	_next_step_label.text = line
	_next_step_label.tooltip_text = line
	_next_step_label.visible = not line.is_empty()

func _refresh_work_purposes() -> void:
	if _purpose_picker == null: return
	_purpose_picker.clear()
	_purpose_picker.add_item("New custom work order")
	_purpose_picker.set_item_metadata(0, {})
	for index: int in range(CANNED_JOBS.size()):
		_purpose_picker.add_item(str(CANNED_JOBS[index].get("title", "Work order")))
		_purpose_picker.set_item_metadata(index + 1, {"cannedIndex": index})
		if not _custom_mode and _job_picker != null and _job_picker.selected == index: _purpose_picker.select(index + 1)
	for definition: Dictionary in _journey_state.get("milestones", []):
		if str(definition.get("employeeId", "")) != _selected_employee_id: continue
		if str(definition.get("state", "")) not in ["available", "revision_required"]: continue
		_purpose_picker.add_item("Journey · " + str(definition.get("title", "")))
		var index := _purpose_picker.item_count - 1
		_purpose_picker.set_item_metadata(index, definition)
		if str(definition.get("id", "")) == milestone_id: _purpose_picker.select(index)

func _choose_work_purpose(index: int) -> void:
	_purpose_chosen_by_player = true
	var definition: Dictionary = _purpose_picker.get_item_metadata(index)
	var discussion := _draft_discussion
	if definition.has("cannedIndex"):
		var template := int(definition.cannedIndex)
		_job_picker.select(template)
		_on_job_selected(template)
	elif definition.is_empty():
		_job_picker.select(CANNED_JOBS.size())
		_on_job_selected(CANNED_JOBS.size())
		if not discussion.is_empty():
			_custom_title_input.text = "Company direction brief"
			_assignment_preview.text = "Write next-steps.md with a concrete recommendation and next test.\n\nDiscussion:\n" + discussion
	else:
		prepare_milestone(definition)
		if not discussion.is_empty(): _assignment_preview.text = (_assignment_preview.text + "\n\nCompany discussion (reference context):\n" + discussion).left(4000)
	_draft_discussion = discussion
	_refresh_work_purposes()

func _active_employee_name() -> String:
	for employee: EmployeeRecord in _employees:
		if employee.id == _active_employee_id:
			return employee.display_name
	return "A teammate"

func _safe_grok_code(user_code: String) -> bool:
	if user_code.length() < 4 or user_code.length() > 64: return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9-]+$")
	return pattern.search(user_code) != null

func _safe_grok_uri(uri: String) -> bool:
	if not uri.begins_with("https://"): return false
	var host := uri.trim_prefix("https://").split("/")[0].split(":")[0].to_lower()
	return host == "x.ai" or host.ends_with(".x.ai")

func _start_grok_login() -> void:
	if not _worker_connected:
		set_worker_connection_error("Worker is not connected")
		return
	_key_status.text = "Starting Grok sign-in…"
	_key_status.add_theme_color_override("font_color", CHARCOAL)
	grok_login_start_requested.emit()

func _open_grok_verification() -> void:
	if _safe_grok_uri(_grok_verification_uri):
		OS.shell_open(_grok_verification_uri)

func _cancel_grok_login() -> void:
	_cancel_grok_login_if_pending()
	_refresh_connection_surface()

func _cancel_grok_login_if_pending() -> void:
	if not _grok_login_pending and (_grok_poll_timer == null or _grok_poll_timer.is_stopped()):
		return
	_grok_login_pending = false
	_stop_grok_poll()
	_grok_code_input.clear()
	_grok_verification_uri = ""
	grok_login_cancel_requested.emit()

func _start_grok_poll(interval_seconds: int) -> void:
	if _grok_poll_timer == null:
		_grok_poll_timer = Timer.new()
		_grok_poll_timer.one_shot = true
		_grok_poll_timer.timeout.connect(func() -> void: grok_login_poll_requested.emit())
		add_child(_grok_poll_timer)
	_grok_poll_timer.start(float(maxi(interval_seconds, 1)))

func _stop_grok_poll() -> void:
	if _grok_poll_timer != null:
		_grok_poll_timer.stop()

func _submit_key() -> void:
	var key := _key_input.text.strip_edges()
	_key_input.clear()
	if key.is_empty():
		_key_status.text = "Paste a replacement key first." if _credential_configured else "Paste an OpenRouter key first."
		_key_status.add_theme_color_override("font_color", ALERT_INK)
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
		_open_connection_settings()
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
			_milestone_criteria if not milestone_id.is_empty() else PackedStringArray(["Create at least one artifact that fulfills the instruction", "Return a concise delivery summary"]),
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
	if _active_job_id.is_empty() or _cancel_button.disabled:
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
	_set_status("Sending your change to %s…" % _active_employee_name(), INDIGO)
	steer_submitted.emit(_active_job_id, message)

func _set_attachment_expanded(expanded: bool, reveal: bool = false) -> void:
	_attachment_reveal_revision += 1
	_attachment_expanded = expanded and _custom_mode
	if _attachment_picker == null or _attachment_label == null: return
	_attachment_picker.visible = _attachment_expanded
	_attachment_label.visible = _attachment_expanded
	_attachment_reveal_spacer.visible = _attachment_expanded
	CozyUI.disclosure(_attachment_toggle, _attachment_expanded)
	if reveal and _attachment_expanded:
		call_deferred("_reveal_attachment_fields", _attachment_reveal_revision)

func _reveal_attachment_fields(revision: int) -> void:
	# Keep the title, description and reference picker together. A little trailing
	# paper lets the complete title align with the reading edge, without leaving
	# half of the preceding purpose dropdown visible. Collapsed forms hide this
	# space; stale requests cannot scroll a replacement template or hidden tab.
	await get_tree().process_frame
	await get_tree().process_frame
	if revision != _attachment_reveal_revision or not _attachment_expanded or not _custom_mode: return
	if not _drawer_open or _tabs.current_tab != 1 or not _attachment_picker.is_visible_in_tree(): return
	var scroll := _tabs.get_tab_control(1).get_child(0) as ScrollContainer
	var content := _attachment_picker.get_parent() as VBoxContainer
	var revealed_height := _attachment_picker.global_position.y + _attachment_picker.size.y - _custom_title_input.global_position.y
	_attachment_reveal_spacer.custom_minimum_size.y = maxf(0.0, scroll.size.y - revealed_height - content.get_theme_constant("separation"))
	await get_tree().process_frame
	await get_tree().process_frame
	if revision != _attachment_reveal_revision or not _attachment_expanded or not _custom_mode: return
	if not _drawer_open or _tabs.current_tab != 1 or not _attachment_picker.is_visible_in_tree(): return
	scroll.scroll_vertical += int(roundf(_custom_title_input.global_position.y - scroll.global_position.y))

func _on_job_selected(index: int) -> void:
	milestone_id = ""
	revision_of_job_id = ""
	_milestone_criteria.clear()
	_draft_discussion = ""
	requested_token_budget = 12000
	_budget_picker.select(0)
	_attachment_picker.select(0)
	_custom_title_input.clear()
	_draft_label.text = "Side project · outside your Journey"
	if _assignment_error != null: _assignment_error.hide()
	if index < 0 or index > CANNED_JOBS.size():
		return
	_job_picker.select(index)
	_custom_mode = index == CANNED_JOBS.size()
	_refresh_work_purposes()
	_custom_title_input.visible = _custom_mode
	_assignment_preview.editable = _custom_mode
	_attachment_toggle.visible = _custom_mode
	_set_attachment_expanded(false)
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
	_submission_pending = true
	_submitted_job_id = job_id
	_activity_job_id = job_id
	_job_order.push_front(job_id)
	_job_views[job_id] = {"employeeId": _active_employee_id, "title": _custom_title_input.text if _custom_mode else _job_picker.text, "status": "submitting", "statusText": "Sending work order…", "inputTokens": 0, "outputTokens": 0, "cost": 0.0, "events": ""}
	_usage_label.text = "$0.0000 USD · 0 tokens"
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
	_refresh_employee_header()
	_refresh_team_statuses()
	_refresh_chat_mode()
	_refresh_selected_activity()

func accept_submission(job_id: String) -> void:
	if job_id != _submitted_job_id: return
	_submission_pending = false
	_submitted_job_id = ""
	# Clear only after acceptance; a rejected form remains editable with its error.
	_job_picker.select(CANNED_JOBS.size())
	_on_job_selected(CANNED_JOBS.size())
	_tabs.current_tab = 2
	if job_id == _active_job_id: close_drawer()

func reject_submission(job_id: String, message: String) -> void:
	_submission_pending = false
	_submitted_job_id = ""
	finish_job(job_id)
	_job_order.erase(job_id)
	_job_views.erase(job_id)
	_activity_job_id = ""
	_assignment_error.text = message
	_assignment_error.show()
	_tabs.current_tab = 1
	open_drawer()

func reset_company() -> void:
	close_drawer(false)
	_active_job_id = ""
	_active_employee_id = ""
	_active_job_running = false
	_approval_id = ""
	_approval_job_id = ""
	_approval_box.hide()
	_promotion_job_id = ""
	_attention_employee_id = ""
	_promotion_box.hide()
	_event_log.clear()
	_job_views.clear()
	_job_order.clear()
	_activity_job_id = ""
	_pending_deliveries.clear()
	_submission_pending = false
	_submitted_job_id = ""
	_clear_artifact_list()
	_chat_messages.clear()
	_chat_pending = false
	_last_chat_prompt = ""
	_custom_title_input.clear()
	_on_job_selected(CANNED_JOBS.size())
	_refresh_operation_availability()
	_purpose_chosen_by_player = false
	_set_status("Hire Mina from Company Journey to get started.", CHARCOAL)
	_refresh_rail_next_step()

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
	_set_status("%s has your update." % _active_employee_name(), INDIGO)

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
	_worker_error = ""
	_connection_retry_pending = false
	if _connection_badge != null:
		_connection_badge.visible = false
	_refresh_rail_connection_action()
	if _key_status != null:
		_apply_key_status()
	_refresh_operation_availability()
	_refresh_connection_surface()
	if _credential_configured and _connection_panel.visible:
		_close_connection_settings()

func set_worker_connection_error(message: String) -> void:
	_worker_connected = false
	_worker_error = message
	_connection_retry_pending = false
	if _connection_badge != null:
		_connection_badge.visible = true
		_connection_badge.tooltip_text = message
	_refresh_rail_connection_action()
	if _key_status != null:
		_key_status.text = message
		_key_status.add_theme_color_override("font_color", ALERT_INK)
	_refresh_operation_availability()
	_refresh_connection_surface()

func set_clock_phase(phase: String) -> void:
	_clock_phase = phase
	_update_assign_copy()
	_refresh_employee_header()
	_refresh_team_statuses()
	if _active_job_id.is_empty() and phase != "work":
		_set_status("Lunch — new work queues until 13:30." if phase == "lunch" else "Off hours — new work queues until 08:00.", ALERT_INK if phase == "lunch" else MUTED_INK)

func _update_assign_copy() -> void:
	if OS.has_feature("web"):
		_assign_button.text = "AI work orders · desktop only"
		return
	if not _active_job_id.is_empty():
		return
	if _clock_phase == "work":
		_assign_button.text = "Start website work order" if milestone_id == "website" else "Start work order"
	elif _clock_phase == "lunch":
		_assign_button.text = "Queue for 13:30"
	else:
		_assign_button.text = "Queue for 08:00"

func set_credential_status(configured: bool) -> void:
	_credential_configured = configured
	if not configured:
		_openrouter_from_environment = false
	if configured:
		_grok_login_pending = false
		_stop_grok_poll()
	_apply_key_status()
	_refresh_rail_connection_action()
	_refresh_operation_availability()
	_refresh_connection_surface()
	if configured and _offline_provider and _connection_panel != null and _connection_panel.visible:
		_close_connection_settings()
	# Credential hydration is passive: the offline company must remain playable
	# without opening a modal behind the title or Journey. Chat, Assign, and the
	# explicit Connect action open this surface when the player actually opts in.

func set_credential_detail(detail: Dictionary) -> void:
	_offline_provider = bool(detail.get("offline", false))
	_grok_signed_in = bool(detail.get("grokSignedIn", false))
	_grok_cli_available = bool(detail.get("grokCliAvailable", false))
	_openrouter_from_environment = str(detail.get("openRouterSource", "")) == "environment"
	if not bool(detail.get("loginPending", false)):
		_grok_login_pending = false
	set_credential_status(bool(detail.get("configured", false)))

func _apply_key_status() -> void:
	if _key_status == null:
		return
	if _offline_provider:
		_key_status.text = "Offline test provider. Jobs complete without a model call."
	elif _openrouter_from_environment and _credential_configured:
		_key_status.text = "Connected with OpenRouter."
	elif _grok_signed_in:
		_key_status.text = "Signed in with Grok. Work uses your Grok / xAI credits."
	elif _credential_configured:
		_key_status.text = "Connected. Key stored in the OS keychain."
	else:
		_key_status.text = "Connection required before chat or work can start."
	_key_status.add_theme_color_override("font_color", CHARCOAL if _credential_configured else ALERT_INK)

func set_credential_saved() -> void:
	set_credential_status(true)
	_close_connection_settings()
	_set_status("OpenRouter key saved.", INDIGO)

func show_grok_login_challenge(user_code: String, verification_uri: String, interval_seconds: int) -> void:
	if not _safe_grok_code(user_code) or not _safe_grok_uri(verification_uri):
		show_grok_login_failed("Grok sign-in returned an unusable code. Try again.")
		return
	_grok_login_pending = true
	_grok_verification_uri = verification_uri
	_grok_poll_wait = maxi(interval_seconds, 1)
	_grok_code_input.text = user_code
	_key_status.text = "Waiting for Grok. Enter the code on the verification page."
	_key_status.add_theme_color_override("font_color", CHARCOAL)
	_refresh_connection_surface()
	_start_grok_poll(_grok_poll_wait)

func show_grok_login_poll(result: Dictionary) -> void:
	var status := str(result.get("status", ""))
	if status == "pending":
		_grok_login_pending = true
		_start_grok_poll(maxi(int(result.get("intervalSeconds", _grok_poll_wait)), 1))
		return
	if status == "complete":
		_grok_login_pending = false
		_stop_grok_poll()
		_grok_code_input.clear()
		_grok_verification_uri = ""
		set_credential_detail(result)
		_close_connection_settings()
		_set_status("Signed in with Grok. Work uses your Grok / xAI credits.", INDIGO)
		return
	if status == "failed":
		show_grok_login_failed(str(result.get("message", "Grok sign-in did not finish.")))
		return
	_grok_login_pending = false
	_stop_grok_poll()
	_refresh_connection_surface()

func show_grok_login_failed(message: String) -> void:
	_grok_login_pending = false
	_stop_grok_poll()
	_grok_code_input.clear()
	_grok_verification_uri = ""
	_key_status.text = message if not message.is_empty() else "Grok sign-in did not finish."
	_key_status.add_theme_color_override("font_color", ALERT_INK)
	_refresh_connection_surface()

func set_spend(daily_spend: float, warning: float) -> void:
	_daily_ai_spend = daily_spend
	_spend_warning = warning
	_token_meter.max_value = maxf(warning, 0.01)
	_token_meter.value = clampf(daily_spend, 0.0, _token_meter.max_value)
	_spend_label.text = "AI spend today\n$%.4f USD" % daily_spend
	_spend_label.tooltip_text = "Real AI spend. Daily warning: $%.2f USD; this is not a work-order dollar cap." % warning
	_token_meter.tooltip_text = _spend_label.tooltip_text
	_spend_label.add_theme_color_override("font_color", ALERT_INK if daily_spend >= warning else CHARCOAL)
	_refresh_usage(_job_views.get(_activity_job_id, {}) as Dictionary)

func set_error(message: String) -> void:
	if message.to_lower().contains("worker is not connected"):
		set_worker_connection_error(message)
		return
	_set_status(message, ALERT_INK)

func set_info(message: String) -> void:
	_set_status(message)

func _set_status(message: String, color: Color = CHARCOAL) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", ALERT_INK if color == VERMILION or color == ALERT_INK else CHARCOAL)
	if _status_tween != null and _status_tween.is_valid():
		_status_tween.kill()
	_status_label.modulate.a = 0.45
	_status_tween = create_tween()
	_status_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_status_tween.tween_property(_status_label, "modulate:a", 1.0, 0.12)

func _refresh_operation_availability() -> void:
	if _assign_button != null:
		# A missing key must not dead-end the button. While Connect is closed, Start
		# stays pressable and _submit_assignment opens Connect instead of sending work.
		# While Connect is open, Start stays disabled so the two actions stay separate.
		var connect_prompt_open := _connection_panel != null and _connection_panel.visible and not _credential_configured
		_assign_button.disabled = OS.has_feature("web") or _employees.is_empty() or not _active_job_id.is_empty() or not _worker_connected or connect_prompt_open
		if OS.has_feature("web"):
			_assign_button.tooltip_text = "Develop products through Company Journey → New Product. AI file work orders are available on desktop."
		elif _active_job_id.is_empty() and not _credential_configured:
			_assign_button.tooltip_text = "Connect AI before this work order can start."
		elif _active_job_id.is_empty() and not _worker_connected:
			_assign_button.tooltip_text = "Reconnect before this work order can start."
		else:
			_assign_button.tooltip_text = _assign_button.text
	_refresh_chat_mode()

func on_job_event(job_id: String, event: WorkerEventRecord) -> void:
	if not _job_views.has(job_id):
		_job_order.push_front(job_id)
		_job_views[job_id] = {"employeeId": _active_employee_id if not _active_employee_id.is_empty() else _selected_employee_id, "title": "Work order", "events": ""}
	var view: Dictionary = _job_views[job_id]
	var line := ""
	match event.type:
		&"job.queued":
			view.status = "queued"
			mark_job_queued(job_id)
			line = "[color=#354b98]Queued[/color]"
			if not event.reason.strip_edges().is_empty(): line += " · " + _safe_bbcode(event.reason)
		&"job.started":
			view.status = "running"
			_set_status("Employee is walking to their desk.", INDIGO)
			if job_id == _active_job_id:
				_active_job_running = true
				_steer_box.visible = true
				_steer_button.disabled = false
				_refresh_chat_mode()
				_refresh_employee_header()
				_refresh_team_statuses()
			line = "[color=#354b98]Started work[/color]"
		&"agent.thinking":
			_set_status(event.summary)
			line = "Thinking · %s" % _safe_bbcode(event.summary)
		&"tool.started":
			_set_status(event.label, INDIGO)
			line = _safe_bbcode(event.label) if not event.label.is_empty() else _tool_activity_label(event.tool)
		&"tool.completed":
			line = "%s · %s" % [_tool_activity_label(event.tool), "done" if event.ok else "needs another try"]
		&"approval.required":
			_approval_job_id = job_id
			_approval_id = event.approval_id
			_approval_label.text = event.action
			_approval_box.visible = true
			_reveal_control(_approval_box)
			_set_status("A decision is needed before work can continue.", ALERT_INK)
			_refresh_team_statuses()
			line = "[color=#963014]Waiting for your approval[/color]"
		&"artifact.created":
			line = "[color=#354b98]File ready[/color] · %s" % _safe_bbcode(event.name)
		&"usage.updated":
			view.inputTokens = event.input_tokens
			view.outputTokens = event.output_tokens
			view.cost = event.cost
			line = "" # Usage has a dedicated disclosure; keep the timeline meaningful.
		&"job.blocked":
			view.status = "blocked"
			_set_status(event.reason, ALERT_INK)
			line = "[color=#963014]Needs attention[/color] · %s" % _safe_bbcode(event.reason)
			finish_job(job_id)
		&"job.completed":
			view.status = "completed"
			_set_status(event.summary, INDIGO)
			line = "[color=#354b98]Work complete[/color]"
			finish_job(job_id)
		&"job.failed":
			view.status = "cancelled" if event.error == "Cancelled by player" else "failed"
			_set_status(event.error, ALERT_INK)
			line = "[color=#963014]Work stopped[/color] · %s" % _safe_bbcode(event.error)
			finish_job(job_id)
	if not line.is_empty():
		var icon_path := OperationsSkin.activity_icon_path(event.type, event.tool, event.ok)
		view.events = str(view.get("events", "")) + "[img=18x18]%s[/img]  %s\n" % [icon_path, line]
		var diagnostics: Array = view.get("eventIdentifiers", [])
		var identifier := str(event.type) + (" · " + event.tool if not event.tool.is_empty() else "")
		if not diagnostics.has(identifier): diagnostics.append(identifier)
		view.eventIdentifiers = diagnostics
	if event.type not in [&"usage.updated", &"artifact.created", &"tool.completed"]:
		view.statusText = _status_label.text
	_refresh_selected_activity()
	_refresh_employee_header()
	_refresh_team_statuses()

func _tool_activity_label(tool: String) -> String:
	match tool:
		"web_search": return "Research"
		"web_fetch": return "Reading a source"
		"write_file": return "Writing a file"
		"edit_file": return "Updating a file"
		"read_file": return "Reading a file"
		"list_files": return "Checking project files"
	return "Working on the task"

func _decide_approval(approved: bool) -> void:
	if _approval_id.is_empty(): return
	approval_decided.emit(_approval_job_id, _approval_id, approved)
	if _job_views.has(_approval_job_id):
		(_job_views[_approval_job_id] as Dictionary).statusText = "Approved — work is continuing." if approved else "Declined — employee is wrapping up."
	_approval_box.visible = false
	_approval_job_id = ""
	_approval_id = ""
	_refresh_selected_activity()
	# This explicit decision replaces the card the player was reading. Return
	# to its complete outcome; ordinary incoming events never reset the scroll.
	_activity_scroll.set_deferred("scroll_vertical", 0)
	_refresh_team_statuses()

func offer_promotion(job_id: String, employee_id: String = "") -> void:
	var found := false
	for candidate: Dictionary in _pending_deliveries:
		found = found or str(candidate.get("jobId", "")) == job_id
	if not found: _pending_deliveries.push_front({"jobId": job_id, "employeeId": employee_id, "title": str((_job_views.get(job_id, {}) as Dictionary).get("title", "Work order"))})
	_refresh_selected_activity()
	_refresh_team_statuses()

func _decide_promotion(approved: bool) -> void:
	var job_id := _promotion_job_id
	if job_id.is_empty(): return
	if ((_job_views.get(job_id, {}) as Dictionary).get("artifacts", []) as Array).is_empty(): return
	_pending_deliveries = _pending_deliveries.filter(func(candidate: Dictionary) -> bool: return str(candidate.get("jobId", "")) != job_id)
	_promotion_job_id = ""
	_attention_employee_id = ""
	promotion_decided.emit(job_id, approved)
	_promotion_box.visible = false
	_refresh_team_statuses()
	_set_status("Adding approved delivery to Studio…" if approved else "Delivery kept with its work order.", CHARCOAL)

func show_pending_promotions(pending_promotions: Array) -> void:
	_pending_deliveries = pending_promotions.duplicate(true)
	_refresh_selected_activity()
	_refresh_team_statuses()

func _employee_id_for_name(display_name: String) -> String:
	for employee: EmployeeRecord in _employees:
		if employee.display_name == display_name:
			return employee.id
	return ""

func pending_promotion_job_id() -> String:
	return _promotion_job_id

func pending_decision_employee_id() -> String:
	if not _approval_id.is_empty() and not _active_employee_id.is_empty(): return _active_employee_id
	if not _attention_employee_id.is_empty(): return _attention_employee_id
	return _selected_employee_id

func _latest_job_for(employee_id: String) -> String:
	for id: String in _job_order:
		if str((_job_views.get(id, {}) as Dictionary).get("employeeId", "")) == employee_id: return id
	return ""

func _delivery_employee(candidate: Dictionary) -> String:
	return str(candidate.get("employeeId", _employee_id_for_name(str(candidate.get("employeeName", "")))))

func _has_pending_delivery(employee_id: String) -> bool:
	for candidate: Dictionary in _pending_deliveries:
		if _delivery_employee(candidate) == employee_id: return true
	return false

func _refresh_selected_activity() -> void:
	if _history_picker == null or _delivery_list == null: return
	# Pending older deliveries stay reachable through the history picker, but do
	# not overwrite the current job's status or the shared Studio file list.
	for candidate: Dictionary in _pending_deliveries:
		var id := str(candidate.get("jobId", ""))
		if not id.is_empty() and not _job_views.has(id):
			_job_views[id] = {"employeeId": _delivery_employee(candidate), "title": str(candidate.get("title", "Delivery")), "status": "completed", "statusText": str(candidate.get("summary", "Delivery ready for review."))}
			_job_order.append(id)
	if str((_job_views.get(_activity_job_id, {}) as Dictionary).get("employeeId", "")) != _selected_employee_id or _activity_job_id.is_empty():
		_activity_job_id = _latest_job_for(_selected_employee_id)
	if _activity_details_job_id != _activity_job_id:
		_set_usage_expanded(false, false, false)
		_activity_details_job_id = _activity_job_id
		_activity_details_expanded = false
		_activity_scroll.scroll_vertical = 0
	var history: Array[String] = []
	for id: String in _job_order:
		var item: Dictionary = _job_views.get(id, {})
		if str(item.get("employeeId", "")) != _selected_employee_id: continue
		history.append(id)
	if history != _history_picker.get_meta("job_ids", []):
		_history_picker.clear()
		for id: String in history:
			var title := str((_job_views[id] as Dictionary).get("title", "Work order"))
			var duplicate_titles := 0
			for candidate: String in history:
				if str((_job_views[candidate] as Dictionary).get("title", "")) == title: duplicate_titles += 1
			var number := history.size() - history.find(id)
			_history_picker.add_item(("#%d · " % number if duplicate_titles > 1 else "") + title)
			_history_picker.set_item_metadata(_history_picker.item_count - 1, id)
		_history_picker.set_meta("job_ids", history)
	if history.has(_activity_job_id): _history_picker.select(history.find(_activity_job_id))
	_history_picker.visible = _history_picker.item_count > 0
	var view: Dictionary = _job_views.get(_activity_job_id, {})
	var status := str(view.get("status", ""))
	_status_label.text = str(view.get("statusText", "No work order yet. Create one from Assign or Company Journey.")).replace("**", "").replace("`", "")
	_status_label.add_theme_color_override("font_color", ALERT_INK if status in ["blocked", "failed", "cancelled"] else CHARCOAL)
	var state_copy := status.left(1).to_upper() + status.substr(1).replace("_", " ")
	_last_status_label.text = "%s · %s" % [view.get("title", "Work order"), state_copy] if not view.is_empty() else "No work orders yet"
	_refresh_usage(view)
	var log_text := str(view.get("events", ""))
	if log_text.is_empty() and not view.is_empty() and _activity_details_expanded: log_text = "Detailed activity will appear here as work progresses."
	if _event_log.text != log_text: _event_log.text = log_text
	_event_log.tooltip_text = "Event identifiers: " + ", ".join(view.get("eventIdentifiers", [])) if view.has("eventIdentifiers") else ""
	_event_log.visible = not log_text.is_empty()
	_activity_heading.visible = _event_log.visible
	var is_active := not _active_job_id.is_empty() and _activity_job_id == _active_job_id and _selected_employee_id == _active_employee_id
	_activity_cancel.visible = is_active and not _submission_pending
	_activity_cancel.disabled = _cancel_button.disabled
	_steer_box.visible = is_active and _active_job_running
	_approval_box.visible = is_active and not _approval_id.is_empty()
	_promotion_job_id = ""
	_attention_employee_id = ""
	for candidate: Dictionary in _pending_deliveries:
		if _attention_employee_id.is_empty(): _attention_employee_id = _delivery_employee(candidate)
		if str(candidate.get("jobId", "")) == _activity_job_id and not is_active:
			_promotion_job_id = _activity_job_id
			_promotion_label.text = "Add to Studio so the team can use these files. Keep with job leaves them on this work order only."
	_promotion_box.visible = not _promotion_job_id.is_empty()
	# A decision already carries its current state and explanation. The longer
	# work summary stays available through details without pushing actions down.
	_status_card.visible = not (_approval_box.visible or _promotion_box.visible) or _activity_details_expanded
	_activity_details.visible = _activity_details_expanded
	_activity_details_toggle.visible = not view.is_empty()
	CozyUI.disclosure(_activity_details_toggle, _activity_details_expanded)
	var artifacts: Array = view.get("artifacts", [])
	_delivery_list.visible = not artifacts.is_empty() or _promotion_box.visible
	# A delivered file is the decision's evidence: its Preview always precedes
	# the summary and promotion controls, including restored older deliveries.
	_activity_content.move_child(_delivery_list, 1 if not artifacts.is_empty() or _promotion_box.visible else 2)
	_activity_content.move_child(_status_card, 2 if not artifacts.is_empty() or _promotion_box.visible else 1)
	for action: Button in _promotion_actions:
		action.disabled = artifacts.is_empty()
	var file_key: Array[String] = [_activity_job_id, str(_promotion_box.visible)]
	for artifact: ArtifactRecord in artifacts: file_key.append(artifact.artifact_id)
	if file_key == _delivery_list.get_meta("file_key", []): return
	_delivery_list.set_meta("file_key", file_key)
	for child: Node in _delivery_list.get_children():
		_delivery_list.remove_child(child)
		child.queue_free()
	if not artifacts.is_empty():
		_delivery_list.add_child(_section_label("Delivered files"))
	elif _promotion_box.visible:
		var loading := Label.new()
		loading.text = "Load the delivery to review its files."
		loading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		CozyUI.label(loading)
		_delivery_list.add_child(loading)
		var refresh := Button.new()
		refresh.text = "Load files"
		CozyUI.button(refresh, "secondary")
		refresh.pressed.connect(func() -> void: artifact_refresh_requested.emit(_activity_job_id))
		_delivery_list.add_child(refresh)
	for artifact: ArtifactRecord in artifacts:
		var row := _file_row(artifact.name, artifact.relative_path, artifact.relative_path.get_extension().to_upper(), "Preview", _open_artifact.bind(_activity_job_id, artifact.relative_path))
		_delivery_list.add_child(row)

func show_recent_jobs(jobs: Array) -> void:
	var order: Array[String] = []
	for job: Dictionary in jobs:
		var id := str(job.get("jobId", ""))
		if id.is_empty(): continue
		order.append(id)
		if not _job_order.has(id): _job_order.append(id)
		var view: Dictionary = _job_views.get(id, {})
		view.merge(job, true)
		if not view.has("statusText"): view.statusText = str(job.get("summary", "%s · %s" % [job.get("title", "Work order"), job.get("status", "")]))
		_job_views[id] = view
	for id: String in _job_order:
		if not order.has(id): order.append(id)
	_job_order = order
	_refresh_selected_activity()

func show_artifacts(job_id: String, artifacts: Array[ArtifactRecord]) -> void:
	var view: Dictionary = _job_views.get(job_id, {"employeeId": _selected_employee_id, "title": "Delivery"})
	view.artifacts = artifacts
	_job_views[job_id] = view
	_refresh_selected_activity()

func _open_artifact(job_id: String, relative_path: String) -> void:
	artifact_open_requested.emit(job_id, relative_path)

func show_studio_files(files: Array[StudioFileRecord]) -> void:
	_configure_attachment_picker(files)
	_clear_artifact_list()
	if files.is_empty():
		_add_empty_artifact("Keep a completed delivery here so future work can use it.")
		return
	for file: StudioFileRecord in files:
		var source: Dictionary = _job_views.get(file.source_job_id, {})
		var owner := _employee_name_for(str(source.get("employeeId", "")))
		var context := file.relative_path.get_extension().to_upper() + " · " + (owner if not owner.is_empty() else "Shared with the team")
		var row := _file_row(file.name, "studio/" + file.relative_path, context, "Open", studio_open_requested.emit.bind(file.relative_path))
		_artifact_list.add_child(row)
		_animate_entry(row)

func _clear_artifact_list() -> void:
	for child: Node in _artifact_list.get_children():
		_artifact_list.remove_child(child)
		child.queue_free()

func _add_empty_artifact(message: String) -> void:
	var empty_panel := PanelContainer.new()
	empty_panel.custom_minimum_size.y = 240
	empty_panel.add_theme_stylebox_override("panel", CozyUI.card(Vector4(12, 24, 12, 24)))
	var empty_row := VBoxContainer.new()
	empty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	empty_row.add_theme_constant_override("separation", 12)
	empty_panel.add_child(empty_row)
	var empty_icon := TextureRect.new()
	empty_icon.name = "EmptyStudioTray"
	empty_icon.texture = OperationsSkin.ICON_EMPTY_TRAY
	empty_icon.custom_minimum_size = empty_icon.texture.get_size()
	empty_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	empty_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	empty_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	empty_row.add_child(empty_icon)
	var title := _section_label("Your shared Studio")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_row.add_child(title)
	var empty := Label.new()
	empty.text = message
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(empty)
	empty_row.add_child(empty)
	var next := Button.new()
	next.text = "Review deliveries" if not _pending_deliveries.is_empty() else "Create a work order"
	CozyUI.button(next, "secondary")
	next.pressed.connect(func() -> void:
		if _employees.is_empty():
			journey_requested.emit()
		else:
			_tabs.current_tab = 2 if not _pending_deliveries.is_empty() else 1
	)
	empty_row.add_child(next)
	_artifact_list.add_child(empty_panel)
	_animate_entry(empty_panel)

func _file_row(title: String, path: String, context: String, action: String, callback: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", CozyUI.card(Vector4(8, 8, 8, 8)))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	content.add_child(top)
	var icon := TextureRect.new()
	icon.name = "DocumentIcon"
	icon.texture = CozyUI.icon("document")
	icon.custom_minimum_size = Vector2(24, 28)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	top.add_child(icon)
	var name_label := Label.new()
	name_label.name = "FileTitle"
	name_label.text = title if not title.is_empty() else path.get_file()
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.tooltip_text = name_label.text
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUI.label(name_label, "action")
	top.add_child(name_label)
	var button := Button.new()
	button.name = "Preview"
	button.text = action
	button.tooltip_text = path
	button.pressed.connect(callback)
	CozyUI.button(button, "secondary")
	top.add_child(button)
	var metadata := Label.new()
	metadata.name = "FileMetadata"
	metadata.text = context
	metadata.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	metadata.max_lines_visible = 2
	metadata.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	metadata.tooltip_text = path
	metadata.mouse_filter = Control.MOUSE_FILTER_PASS
	CozyUI.label(metadata, "meta")
	content.add_child(metadata)
	return card

func _employee_name_for(employee_id: String) -> String:
	for employee: EmployeeRecord in _employees:
		if employee.id == employee_id: return employee.display_name
	return ""

func _style_file_button(button: Button) -> void:
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUI.button(button, "secondary")

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
	var previous: Tween = button.get_meta("press_tween") as Tween if button.has_meta("press_tween") else null
	if previous != null and previous.is_valid():
		previous.kill()
	button.scale = Vector2.ONE
	if pressed:
		button.self_modulate = Color(0.85, 0.85, 0.85)
		return
	var tween := create_tween()
	button.set_meta("press_tween", tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "self_modulate", Color.WHITE, 0.09)

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
