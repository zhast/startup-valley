class_name ClockPanel
extends PanelContainer

signal speed_selected(speed: float)

const VERMILION := Color("fa4616")
const OFF_WHITE := Color("f1f1f1")
const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const CHARTREUSE := Color("c1fa81")
const PARCHMENT := Color("f4ddb0")
const PARCHMENT_LIGHT := Color("fff7e2")
const PARCHMENT_DARK := Color("d8b879")
const WOOD := Color("9b542d")
const WOOD_DARK := Color("552c22")
const WOOD_LIGHT := Color("de9550")
const MUTED_INK := Color("725b46")

var _time_label: Label
var _phase_label: Label
var _speed_buttons: Array[Button] = []

func _ready() -> void:
	add_theme_stylebox_override("panel", _panel_style(WOOD_DARK, WOOD_LIGHT, 3, 3))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)

	var clock_face := PanelContainer.new()
	clock_face.custom_minimum_size = Vector2(164.0, 0.0)
	clock_face.add_theme_stylebox_override("panel", _panel_style(PARCHMENT, WOOD, 2, 2))
	row.add_child(clock_face)
	var clock_margin := MarginContainer.new()
	clock_margin.add_theme_constant_override("margin_left", 8)
	clock_margin.add_theme_constant_override("margin_right", 8)
	clock_margin.add_theme_constant_override("margin_top", 3)
	clock_margin.add_theme_constant_override("margin_bottom", 3)
	clock_face.add_child(clock_margin)
	var clock_row := HBoxContainer.new()
	clock_row.add_theme_constant_override("separation", 7)
	clock_margin.add_child(clock_row)
	_time_label = Label.new()
	_time_label.text = "DAY 1  ·  08:00"
	_time_label.add_theme_font_size_override("font_size", 14)
	_time_label.add_theme_color_override("font_color", CHARCOAL)
	clock_row.add_child(_time_label)
	_phase_label = Label.new()
	_phase_label.text = "WORK"
	_phase_label.add_theme_font_size_override("font_size", 10)
	_phase_label.add_theme_color_override("font_color", INDIGO)
	clock_row.add_child(_phase_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	for value in [0.0, 1.0, 4.0, 16.0]:
		var button := Button.new()
		button.toggle_mode = true
		button.text = "Ⅱ" if value == 0.0 else "%dx" % int(value)
		button.tooltip_text = "Pause clock" if value == 0.0 else "%d game minutes per second" % int(value)
		button.pressed.connect(speed_selected.emit.bind(value))
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_stylebox_override("normal", _button_style(PARCHMENT_DARK, WOOD, 2))
		button.add_theme_stylebox_override("hover", _button_style(PARCHMENT_LIGHT, VERMILION, 2))
		button.add_theme_stylebox_override("pressed", _button_style(VERMILION, WOOD_DARK, 2))
		button.add_theme_stylebox_override("focus", _button_style(PARCHMENT_LIGHT, CHARTREUSE, 2))
		button.add_theme_color_override("font_color", CHARCOAL)
		button.add_theme_color_override("font_hover_color", CHARCOAL)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_color_override("font_focus_color", CHARCOAL)
		_speed_buttons.append(button)
		row.add_child(button)

func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _button_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(2)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func show_clock(day: int, minute_of_day: int, phase: String, speed: float) -> void:
	_time_label.text = "DAY %d  ·  %02d:%02d" % [day, minute_of_day / 60, minute_of_day % 60]
	_phase_label.text = phase.to_upper()
	var color := INDIGO
	if phase == "lunch":
		color = VERMILION
	elif phase == "off":
		color = MUTED_INK
	_phase_label.add_theme_color_override("font_color", color)
	var speeds := [0.0, 1.0, 4.0, 16.0]
	for index in range(_speed_buttons.size()):
		_speed_buttons[index].button_pressed = is_equal_approx(speed, speeds[index])
