class_name ClockPanel
extends PanelContainer

signal speed_selected(speed: float)

const VERMILION := Color("fa4616")
const OFF_WHITE := Color("f1f1f1")
const CHARCOAL := Color("151515")
const CERULEAN := Color("6196c1")
const CHARTREUSE := Color("c1fa81")
const DUST := Color("b6b5b0")

var _time_label: Label
var _phase_label: Label
var _speed_buttons: Array[Button] = []

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CHARCOAL
	style.border_color = VERMILION
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)
	_time_label = Label.new()
	_time_label.text = "DAY 1  ·  08:00"
	_time_label.add_theme_font_size_override("font_size", 16)
	_time_label.add_theme_color_override("font_color", OFF_WHITE)
	row.add_child(_time_label)
	_phase_label = Label.new()
	_phase_label.text = "WORK"
	_phase_label.add_theme_color_override("font_color", CHARTREUSE)
	row.add_child(_phase_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	for value in [0.0, 1.0, 4.0, 16.0]:
		var button := Button.new()
		button.toggle_mode = true
		button.text = "Ⅱ" if value == 0.0 else "%dx" % int(value)
		button.tooltip_text = "Pause clock" if value == 0.0 else "%d game minutes per second" % int(value)
		button.pressed.connect(speed_selected.emit.bind(value))
		button.add_theme_stylebox_override("normal", _button_style(Color("252525"), Color("484848"), 1))
		button.add_theme_stylebox_override("hover", _button_style(Color("303030"), CERULEAN, 1))
		button.add_theme_stylebox_override("pressed", _button_style(VERMILION, VERMILION, 1))
		button.add_theme_stylebox_override("focus", _button_style(Color("00000000"), CHARTREUSE, 2))
		button.add_theme_color_override("font_color", DUST)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		_speed_buttons.append(button)
		row.add_child(button)

func _button_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	return style

func show_clock(day: int, minute_of_day: int, phase: String, speed: float) -> void:
	_time_label.text = "DAY %d  ·  %02d:%02d" % [day, minute_of_day / 60, minute_of_day % 60]
	_phase_label.text = phase.to_upper()
	var color := CHARTREUSE
	if phase == "lunch":
		color = VERMILION
	elif phase == "off":
		color = DUST
	_phase_label.add_theme_color_override("font_color", color)
	var speeds := [0.0, 1.0, 4.0, 16.0]
	for index in range(_speed_buttons.size()):
		_speed_buttons[index].button_pressed = is_equal_approx(speed, speeds[index])
