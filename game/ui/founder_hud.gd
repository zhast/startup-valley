class_name FounderHud
extends Control

signal chat_requested(employee_id: String)
signal delivery_requested(job_id: String, employee_id: String)

const NOTIFICATION_TEXTURE: Texture2D = preload("res://assets/runtime/ui/founders-ledger/notification-memo.png")
const INTERACTION_TEXTURE: Texture2D = preload("res://assets/runtime/ui/founders-ledger/interaction-prompt.png")
const MOVEMENT_TEXTURE: Texture2D = preload("res://assets/runtime/ui/founders-ledger/movement-plaque.png")

const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const VERMILION := Color("fa4616")
const ALERT_INK := Color("963014")
const PARCHMENT_LIGHT := Color("fff7e2")
const PLAYFIELD_RIGHT := 1150.0
const INTERACTION_DISTANCE := 96.0

var _notification: Control
var _notification_heading: Label
var _notification_detail: Label
var _interaction_prompt: Control
var _interaction_target_id: String = ""
var _delivery_job_id: String = ""
var _delivery_employee_id: String = ""
var _notification_tween: Tween
var _notification_rest_position: Vector2
var _movement_hint: Control
var _movement_hint_tween: Tween
var _movement_seen: bool = false

func _ready() -> void:
	theme = GameFonts.interface_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_notification()
	_notification_rest_position = _notification.position
	_build_interaction_prompt()
	_build_movement_hint()

func _process(_delta: float) -> void:
	if _movement_seen or _movement_hint == null:
		return
	if Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx():
		return
	_movement_seen = true
	if _movement_hint_tween != null and _movement_hint_tween.is_valid():
		_movement_hint_tween.kill()
	_movement_hint_tween = create_tween()
	_movement_hint_tween.tween_property(_movement_hint, "modulate:a", 0.0, 0.35)
	_movement_hint_tween.tween_callback(_movement_hint.hide)

func _build_notification() -> void:
	_notification = _texture_control("DeliveryMemo", NOTIFICATION_TEXTURE, Rect2(24.0, 18.0, 250.0, 120.0))
	_notification.visible = false
	_notification_heading = _label("DELIVERY READY", GameFonts.DISPLAY_SMALL, CHARCOAL)
	_notification_heading.position = Vector2(18.0, 22.0)
	_notification_heading.size = Vector2(194.0, 22.0)
	_notification_heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notification.add_child(_notification_heading)
	_notification_detail = _label("Work order ready", GameFonts.BODY_META, CHARCOAL)
	GameFonts.use_body(_notification_detail)
	_notification_detail.position = Vector2(18.0, 44.0)
	_notification_detail.size = Vector2(194.0, 20.0)
	_notification_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notification.add_child(_notification_detail)
	var view_button := Button.new()
	view_button.name = "ViewDelivery"
	view_button.text = "VIEW"
	view_button.position = Vector2(142.0, 67.0)
	view_button.size = Vector2(70.0, 40.0)
	view_button.focus_mode = Control.FOCUS_ALL
	view_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_ink_button(view_button, ALERT_INK)
	view_button.pressed.connect(_request_delivery)
	_notification.add_child(view_button)

func _build_interaction_prompt() -> void:
	_interaction_prompt = _texture_control("InteractionPrompt", INTERACTION_TEXTURE, Rect2(0.0, 0.0, 130.0, 52.0))
	_interaction_prompt.visible = false
	var label := _label("E  ·  CHAT", GameFonts.DISPLAY_SMALL, CHARCOAL)
	label.position = Vector2(12.0, 9.0)
	label.size = Vector2(94.0, 34.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt.add_child(label)
	var button := Button.new()
	button.name = "ChatAction"
	button.text = ""
	button.position = Vector2.ZERO
	button.size = Vector2(112.0, 52.0)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_ink_button(button, Color.TRANSPARENT)
	button.pressed.connect(_request_chat)
	_interaction_prompt.add_child(button)

func _build_movement_hint() -> void:
	_movement_hint = _texture_control("MovementPlaque", MOVEMENT_TEXTURE, Rect2(455.0, 660.0, 240.0, 48.0))
	var label := _label("WASD / ARROWS TO MOVE", GameFonts.DISPLAY_SMALL, CHARCOAL)
	label.position = Vector2(18.0, 9.0)
	label.size = Vector2(204.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_movement_hint.add_child(label)

func _texture_control(name_value: String, texture_value: Texture2D, rect: Rect2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = name_value
	texture_rect.texture = texture_value
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	return texture_rect

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	GameFonts.use_display(label)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", PARCHMENT_LIGHT)
	label.add_theme_constant_override("outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style_ink_button(button: Button, font_color: Color) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	GameFonts.use_display(button)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", INDIGO)
	button.add_theme_color_override("font_pressed_color", CHARCOAL)
	button.add_theme_color_override("font_focus_color", VERMILION)

func update_interaction(
	player_position: Vector2,
	employees: Dictionary[String, EmployeeAvatar],
	enabled: bool
) -> void:
	var closest: EmployeeAvatar = null
	var closest_distance := INTERACTION_DISTANCE
	if enabled:
		for employee_id: String in employees:
			var employee := employees[employee_id] as EmployeeAvatar
			if employee == null:
				continue
			var distance := player_position.distance_to(employee.position)
			if distance < closest_distance:
				closest = employee
				closest_distance = distance
	if closest == null:
		_interaction_target_id = ""
		_interaction_prompt.visible = false
		return
	_interaction_target_id = closest.employee_id
	var prompt_position := closest.position + Vector2(-136.0, -70.0)
	prompt_position.x = clampf(prompt_position.x, 18.0, PLAYFIELD_RIGHT - _interaction_prompt.size.x - 18.0)
	prompt_position.y = clampf(prompt_position.y, 82.0, 636.0)
	_interaction_prompt.position = prompt_position.round()
	_interaction_prompt.visible = true

func show_delivery(job_id: String, employee_id: String, employee_name: String, detail: String) -> void:
	_delivery_job_id = job_id
	_delivery_employee_id = employee_id
	_notification_heading.text = "%s FINISHED" % employee_name.to_upper()
	_notification_detail.text = detail
	_notification.visible = true
	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()
	_notification.position = _notification_rest_position + Vector2(-12.0, 0.0)
	_notification.modulate.a = 0.0
	_notification_tween = create_tween()
	_notification_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_notification_tween.tween_property(_notification, "position", _notification_rest_position, 0.16)
	_notification_tween.parallel().tween_property(_notification, "modulate:a", 1.0, 0.16)
	_notification_tween.tween_interval(6.0)
	_notification_tween.tween_property(_notification, "modulate:a", 0.0, 0.2)
	_notification_tween.tween_callback(_notification.hide)

func hide_delivery() -> void:
	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()
	_delivery_job_id = ""
	_delivery_employee_id = ""
	_notification.visible = false
	_notification.position = _notification_rest_position
	_notification.modulate.a = 1.0

func dismiss_movement_hint() -> void:
	_movement_seen = true
	if _movement_hint != null:
		_movement_hint.hide()

func delivery_visible() -> bool:
	return _notification.visible

func interaction_visible() -> bool:
	return _interaction_prompt.visible

func interaction_target_id() -> String:
	return _interaction_target_id

func _request_chat() -> void:
	if not _interaction_target_id.is_empty():
		chat_requested.emit(_interaction_target_id)

func _request_delivery() -> void:
	if not _delivery_job_id.is_empty():
		delivery_requested.emit(_delivery_job_id, _delivery_employee_id)

func _unhandled_key_input(event: InputEvent) -> void:
	if _interaction_prompt.visible and event.is_action_pressed("interact"):
		_request_chat()
		get_viewport().set_input_as_handled()
