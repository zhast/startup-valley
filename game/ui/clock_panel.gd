class_name ClockPanel
extends PanelContainer

const VERMILION := Color("fa4616")
const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const CHARTREUSE := Color("c1fa81")
const PARCHMENT_LIGHT := Color("fff7e2")
const WOOD := Color("9b542d")
const WOOD_DARK := Color("552c22")
const WOOD_LIGHT := Color("de9550")

var _day_label: Label
var _time_label: Label
var _earned_label: Label
var _money_earned: float = 0.0

func _ready() -> void:
	add_theme_stylebox_override("panel", _panel_style(WOOD_DARK, WOOD_LIGHT, 3, 3))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	_day_label = _plaque_label("DAY 1", 72.0, VERMILION)
	row.add_child(_day_label.get_parent())
	_time_label = _plaque_label("08:00", 68.0, INDIGO)
	row.add_child(_time_label.get_parent())
	_earned_label = _plaque_label("$0  EARNED", 124.0, CHARCOAL)
	row.add_child(_earned_label.get_parent())

func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _plaque_label(text_value: String, minimum_width: float, color: Color) -> Label:
	var plaque := PanelContainer.new()
	plaque.custom_minimum_size = Vector2(minimum_width, 0.0)
	plaque.add_theme_stylebox_override("panel", _panel_style(PARCHMENT_LIGHT, WOOD, 2, 2))
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	plaque.add_child(label)
	return label

func show_clock(day: int, minute_of_day: int) -> void:
	_day_label.text = "DAY %d" % day
	_time_label.text = "%02d:%02d" % [minute_of_day / 60, minute_of_day % 60]

func show_money_earned(amount: float) -> void:
	_money_earned = maxf(0.0, amount)
	_earned_label.text = "$%s  EARNED" % _format_money(_money_earned)
	_earned_label.add_theme_color_override("font_color", CHARTREUSE if _money_earned > 0.0 else CHARCOAL)

func _format_money(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return "%d" % int(amount)
	return "%.2f" % amount
