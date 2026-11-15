class_name FounderHud
extends Control

signal chat_requested(employee_id: String)
signal delivery_requested(job_id: String, employee_id: String)
signal goal_requested(mode: String)

class InteractionButton extends Button:
	var callout_target := Vector2.ZERO
	func _draw() -> void:
		WorldCalloutSkin.draw(self, Rect2(Vector2.ZERO, size), callout_target, "focused" if has_focus() else "hover" if is_hovered() else "normal")
		WorldCalloutSkin.draw_keycap(self, Rect2(Vector2(10, 8), WorldCalloutSkin.KEYCAP_SIZE), "E", is_pressed())
		var font := GameFonts.BOLD
		var baseline := floorf((size.y - font.get_height(16)) * 0.5) + ceilf(font.get_ascent(16))
		draw_string(font, Vector2(44, baseline), "Chat", HORIZONTAL_ALIGNMENT_CENTER, size.x - 54, 16, CozyUI.INK)

class StationCallout extends Control:
	var callout_target := Vector2.ZERO
	var caption := ""
	func _draw() -> void:
		WorldCalloutSkin.draw(self, Rect2(Vector2.ZERO, size), callout_target)
		var font := GameFonts.BOLD
		var baseline := floorf((size.y - font.get_height(16)) * 0.5) + ceilf(font.get_ascent(16))
		draw_string(font, Vector2(12, baseline), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x - 24, 16, CozyUI.INK)

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
var _next_step_hint: Control
var _next_step_label: Label
var _goal_chapter: Label
var _goal_action: Button
var _goal_mode := "journey"
var _goal_marks: Array[ColorRect] = []
var _station_callout: StationCallout
var _station_target_id := ""
var station_input_enabled: Callable

func _ready() -> void:
	theme = GameFonts.interface_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_notification()
	_notification_rest_position = _notification.position
	_build_interaction_prompt()
	_station_callout = StationCallout.new()
	_station_callout.name = "StationHover"
	_station_callout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_station_callout.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_station_callout.set_meta("cozy_material", "world-callout")
	add_child(_station_callout)
	_station_callout.hide()
	_build_movement_hint()
	_build_next_step_hint()

func _process(_delta: float) -> void:
	# Editor placement can disable world input while GameMain processing itself
	# is paused. This lightweight guard prevents its last hover paper lingering.
	if _station_callout != null and _station_callout.visible and station_input_enabled.is_valid() and not station_input_enabled.call():
		_station_callout.hide()
		_station_target_id = ""
	if _movement_seen or _movement_hint == null:
		return
	if Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx():
		return
	notice_movement()

func notice_movement() -> void:
	if _movement_seen: return
	_movement_seen = true
	if _movement_hint_tween != null and _movement_hint_tween.is_valid():
		_movement_hint_tween.kill()
	_movement_hint_tween = create_tween()
	_movement_hint_tween.tween_property(_movement_hint, "modulate:a", 0.0, 0.35)
	_movement_hint_tween.tween_callback(_movement_hint.hide)

func _build_notification() -> void:
	var toast := Panel.new()
	toast.name = "DeliveryMemo"
	toast.position = Vector2(24, 18)
	toast.size = Vector2(310, 84)
	toast.add_theme_stylebox_override("panel", CozyUI.paper())
	# Keep the whole visible memo above world input, not only its View button.
	toast.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(toast)
	_notification = toast
	_notification.visible = false
	_notification_heading = _label("Delivery ready", GameFonts.BODY_DEFAULT, CHARCOAL)
	CozyUI.label(_notification_heading, "action")
	_notification_heading.position = Vector2(14.0, 14.0)
	_notification_heading.size = Vector2(202.0, 24.0)
	_notification_heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notification.add_child(_notification_heading)
	_notification_detail = _label("Work order ready", GameFonts.BODY_META, CHARCOAL)
	GameFonts.use_body(_notification_detail)
	_notification_detail.position = Vector2(14.0, 42.0)
	_notification_detail.size = Vector2(202.0, 22.0)
	_notification_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notification.add_child(_notification_detail)
	var view_button := Button.new()
	view_button.name = "ViewDelivery"
	view_button.text = "View"
	view_button.position = Vector2(226.0, 20.0)
	view_button.size = Vector2(70.0, 44.0)
	view_button.focus_mode = Control.FOCUS_ALL
	view_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	CozyUI.button(view_button, "secondary")
	view_button.pressed.connect(_request_delivery)
	_notification.add_child(view_button)

func _build_interaction_prompt() -> void:
	var prompt := Control.new()
	prompt.name = "InteractionPrompt"
	prompt.size = Vector2(112, 44)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	_interaction_prompt = prompt
	_interaction_prompt.visible = false
	var button := InteractionButton.new()
	button.name = "ChatAction"
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.tooltip_text = "Chat with employee (E)"
	button.position = Vector2.ZERO
	button.size = Vector2(112.0, 44.0)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	CozyUI.button(button, "quiet")
	# One authored surface, not an opaque button covering a second paper panel.
	for state: String in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.set_meta("cozy_material", "world-callout")
	button.pressed.connect(_request_chat)
	_interaction_prompt.add_child(button)

func _build_movement_hint() -> void:
	_movement_hint = _texture_control("MovementPlaque", MOVEMENT_TEXTURE, Rect2(455.0, 672.0, 240.0, 48.0))
	var label := _label("Click / WASD to move", GameFonts.BODY_DEFAULT, CHARCOAL)
	CozyUI.label(label, "action")
	label.text = "Click / WASD to move"
	label.position = Vector2(18.0, 9.0)
	label.size = Vector2(204.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_movement_hint.add_child(label)

func _build_next_step_hint() -> void:
	var plaque := Panel.new()
	plaque.name = "NextStepPlaque"
	plaque.position = Vector2(800.0, 16.0)
	plaque.size = Vector2(320.0, 56.0)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 8, 12, 8)))
	add_child(plaque)
	_next_step_hint = plaque
	_next_step_hint.visible = false
	_next_step_label = _label("Next · Hire Mina", GameFonts.BODY_DEFAULT, CHARCOAL)
	CozyUI.label(_next_step_label, "action")
	_next_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_step_label.max_lines_visible = 2
	_next_step_label.position = Vector2(12.0, 6.0)
	_next_step_label.size = Vector2(296.0, 44.0)
	_next_step_hint.add_child(_next_step_label)
	_goal_chapter = _label("A studio begins", GameFonts.BODY_META, CHARCOAL)
	CozyUI.label(_goal_chapter, "meta")
	_goal_chapter.position = Vector2(14, 8)
	_goal_chapter.size = Vector2(312, 20)
	_goal_chapter.hide()
	plaque.add_child(_goal_chapter)
	for index: int in range(4):
		var mark := ColorRect.new()
		mark.position = Vector2(266 + index * 13, 14)
		mark.size = Vector2(9, 9)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.hide()
		plaque.add_child(mark)
		_goal_marks.append(mark)
	_goal_action = Button.new()
	_goal_action.name = "CurrentGoalAction"
	_goal_action.position = Vector2(12, 62)
	_goal_action.size = Vector2(316, 42)
	_goal_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	CozyUI.button(_goal_action, "primary")
	_goal_action.pressed.connect(func() -> void: goal_requested.emit(_goal_mode))
	_goal_action.hide()
	plaque.add_child(_goal_action)

func set_story_goal(goal: Dictionary) -> void:
	if goal.is_empty():
		hide_next_step()
		return
	_next_step_hint.position = Vector2(780, 12)
	_next_step_hint.size = Vector2(340, 114)
	_next_step_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	_next_step_label.position = Vector2(14, 30)
	_next_step_label.size = Vector2(312, 28)
	_next_step_label.max_lines_visible = 1
	_next_step_label.text = str(goal.get("title", "Your next step"))
	_next_step_label.tooltip_text = str(goal.get("detail", ""))
	_goal_chapter.text = "%s · %d / %d" % [goal.get("chapter", "Our story"), int(goal.get("completed", 0)), int(goal.get("total", 4))]
	_goal_chapter.show()
	for index: int in range(_goal_marks.size()):
		_goal_marks[index].color = Color("598347") if index < int(goal.get("completed", 0)) else Color("c9b58d")
		_goal_marks[index].visible = index < int(goal.get("total", 4))
	_goal_action.text = str(goal.get("action", "Open our notebook"))
	_goal_action.show()
	_goal_mode = str(goal.get("mode", "journey"))
	_next_step_hint.show()

func set_next_step(text: String) -> void:
	var line := text.trim_prefix("NEXT · ").strip_edges()
	if line.is_empty():
		hide_next_step()
		return
	_next_step_label.text = "Next · " + line
	_next_step_label.tooltip_text = line
	_next_step_hint.visible = true

func set_goal_pending(pending: bool) -> void:
	_goal_action.disabled = pending
	if pending: _goal_action.text = "Saving our place…"

func hide_next_step() -> void:
	if _next_step_hint != null:
		_next_step_hint.visible = false

func next_step_rect() -> Rect2:
	if _next_step_hint == null or not _next_step_hint.visible:
		return Rect2()
	return _next_step_hint.get_global_rect()

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
	GameFonts.use_body(label)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func update_interaction(
	player_position: Vector2,
	employees: Dictionary[String, EmployeeAvatar],
	enabled: bool,
	obstacles: Array[Rect2] = []
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
	var silhouettes: Array[Rect2] = obstacles.duplicate()
	silhouettes.append(WorldCalloutSkin.actor_rect(player_position))
	for employee: EmployeeAvatar in employees.values():
		silhouettes.append(WorldCalloutSkin.actor_rect(employee.render_position()))
	var prompt_size := _interaction_prompt.size
	var viewport := Rect2(18, 82, PLAYFIELD_RIGHT - 36, get_viewport_rect().size.y - 100)
	# Only presentation follows an authored seated socket. Distance above stays
	# measured from physical feet, preserving proximity and navigation rules.
	var visual_position := closest.render_position()
	var candidate := WorldCalloutSkin.place(visual_position, prompt_size, silhouettes, viewport, true)
	_interaction_prompt.visible = candidate.has_area()
	if not candidate.has_area(): return
	_interaction_prompt.position = candidate.position
	var button := _interaction_prompt.get_node("ChatAction") as InteractionButton
	button.callout_target = WorldCalloutSkin.actor_rect(visual_position).get_center() - candidate.position
	button.tooltip_text = "Chat with %s (E)" % closest.display_name
	button.queue_redraw()

func interaction_rect() -> Rect2:
	var button := _interaction_prompt.get_node("ChatAction") as InteractionButton
	return WorldCalloutSkin.bounds(_interaction_prompt.get_global_rect(), _interaction_prompt.global_position + button.callout_target)

func update_station_hover(target_id: String, caption: String, target_bounds: Rect2, enabled: bool, obstacles: Array[Rect2]) -> void:
	_station_target_id = ""
	_station_callout.hide()
	if not enabled or target_id.is_empty() or caption.is_empty() or not target_bounds.has_area(): return
	var width := ceilf(GameFonts.BOLD.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x) + 24.0
	var size_value := Vector2(maxf(80, width), 40)
	var viewport := Rect2(18, 82, PLAYFIELD_RIGHT - 36, get_viewport_rect().size.y - 100)
	var gap := float(WorldCalloutSkin.POINTER_LENGTH + 3)
	var center := target_bounds.get_center()
	var left := target_bounds.position.x - size_value.x - gap
	var right := target_bounds.end.x + gap
	var above := target_bounds.position.y - size_value.y - gap
	var below := target_bounds.end.y + gap
	var positions: Array[Vector2] = [
		Vector2(center.x - size_value.x * 0.5, above),
		Vector2(center.x - size_value.x * 0.5, below),
		Vector2(left, center.y - size_value.y * 0.5),
		Vector2(right, center.y - size_value.y * 0.5),
		Vector2(left, above), Vector2(right, above),
		Vector2(left, below), Vector2(right, below),
	]
	for point: Vector2 in positions:
		var candidate := Rect2(point.round(), size_value)
		var painted := WorldCalloutSkin.bounds(candidate, center)
		if not viewport.encloses(painted): continue
		if painted.intersects(target_bounds): continue
		var blocked := false
		for obstacle: Rect2 in obstacles:
			if painted.intersects(obstacle):
				blocked = true
				break
		if blocked: continue
		_station_target_id = target_id
		_station_callout.caption = caption
		_station_callout.position = candidate.position
		_station_callout.size = candidate.size
		_station_callout.callout_target = center - candidate.position
		_station_callout.show()
		_station_callout.queue_redraw()
		# One actionable paper at a time. The physical proximity/E target stays
		# intact; only its redundant visual is suppressed during station hover.
		_interaction_prompt.hide()
		return

func station_hover_rect() -> Rect2:
	if not _station_callout.visible: return Rect2()
	return WorldCalloutSkin.bounds(_station_callout.get_global_rect(), _station_callout.global_position + _station_callout.callout_target)

func station_hover_target_id() -> String:
	return _station_target_id

func show_delivery(job_id: String, employee_id: String, employee_name: String, detail: String) -> void:
	_delivery_job_id = job_id
	_delivery_employee_id = employee_id
	_notification_heading.text = "%s finished" % employee_name
	_notification_detail.text = detail
	_notification_detail.tooltip_text = detail
	_notification.visible = true
	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()
	var entrance := _notification_rest_position + Vector2(-12.0, 0.0)
	_notification.position = entrance
	_notification.modulate.a = 0.0
	_notification_tween = create_tween()
	_notification_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_notification_tween.tween_method(func(value: Vector2) -> void: _notification.position = value.round(), entrance, _notification_rest_position, 0.16)
	_notification_tween.parallel().tween_property(_notification, "modulate:a", 1.0, 0.16)
	_notification_tween.tween_interval(6.0)
	_notification_tween.tween_property(_notification, "modulate:a", 0.0, 0.16)
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
	if not _interaction_target_id.is_empty() and event.is_action_pressed("interact"):
		_request_chat()
		get_viewport().set_input_as_handled()
