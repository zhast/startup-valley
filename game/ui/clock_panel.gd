class_name ClockPanel
extends Control

const LEDGER_TEXTURE: Texture2D = preload("res://assets/runtime/ui/founders-ledger/ledger-hud-frame.png")
const VERMILION := Color("fa4616")
const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const CHARTREUSE := Color("c1fa81")
const PARCHMENT_LIGHT := Color("fff7e2")

var _day_label: Label
var _time_label: Label
var _earned_label: Label
var _money_earned: float = 0.0

func _ready() -> void:
	var ledger := TextureRect.new()
	ledger.name = "LedgerTexture"
	ledger.texture = LEDGER_TEXTURE
	ledger.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ledger.stretch_mode = TextureRect.STRETCH_SCALE
	ledger.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ledger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ledger.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ledger)

	_day_label = _ledger_label("DAY 1", Rect2(16.0, 11.0, 124.0, 46.0), VERMILION, 13)
	_time_label = _ledger_label("08:00", Rect2(180.0, 11.0, 100.0, 46.0), INDIGO, 13)
	_earned_label = _ledger_label("$0  EARNED", Rect2(294.0, 11.0, 98.0, 46.0), CHARCOAL, 11)

func _ledger_label(text_value: String, rect: Rect2, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", PARCHMENT_LIGHT)
	label.add_theme_constant_override("outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
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
