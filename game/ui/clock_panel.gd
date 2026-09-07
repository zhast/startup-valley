class_name ClockPanel
extends Control

const LEDGER_TEXTURE: Texture2D = preload("res://assets/runtime/ui/founders-ledger/ledger-hud-frame.png")
const VERMILION := Color("fa4616")
const ALERT_INK := Color("963014")
const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const CHARTREUSE := Color("c1fa81")
const PARCHMENT_LIGHT := Color("fff7e2")

var _day_label: Label
var _time_label: Label
var _earned_label: Label
var _day_caption: Label
var _time_caption: Label
var _earned_caption: Label
var _money_earned: float = 0.0

func _ready() -> void:
	theme = GameFonts.interface_theme()
	# The paper covers the world: Day/Time and blank areas must not select
	# employees behind it. Child labels can still delegate input to this panel.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var ledger := TextureRect.new()
	ledger.name = "LedgerTexture"
	ledger.texture = LEDGER_TEXTURE
	ledger.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ledger.stretch_mode = TextureRect.STRETCH_SCALE
	ledger.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ledger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ledger.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ledger)

	# All three values share one face, size and line box. The ring binding stays
	# between the first two columns; captions disambiguate the compact day number.
	_day_label = _ledger_label("1", Rect2(26.0, 29.0, 116.0, 22.0), GameFonts.DISPLAY_SMALL, true)
	_time_label = _ledger_label("08:00", Rect2(166.0, 29.0, 96.0, 22.0), GameFonts.DISPLAY_SMALL, true)
	_earned_label = _ledger_label("$0", Rect2(270.0, 29.0, 110.0, 22.0), GameFonts.DISPLAY_SMALL, true)
	_day_caption = _ledger_label("Day", Rect2(26.0, 8.0, 116.0, 20.0), GameFonts.BODY_META)
	_time_caption = _ledger_label("Time", Rect2(166.0, 8.0, 96.0, 20.0), GameFonts.BODY_META)
	_earned_caption = _ledger_label("Earned", Rect2(270.0, 8.0, 110.0, 20.0), GameFonts.BODY_META)
	_earned_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_earned_label.tooltip_text = "Gross in-game revenue: $0. Not your real AI spend."
	_earned_caption.mouse_filter = Control.MOUSE_FILTER_STOP
	_earned_caption.tooltip_text = "Gross in-game revenue, not company cash or real AI spend."

func _ledger_label(text_value: String, rect: Rect2, font_size: int, value: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	if value:
		GameFonts.use_display(label)
	else:
		GameFonts.use_emphasis(label)
	# Default line spacing expands Nunito's caption beyond its painted paper.
	# Apply the actual face and single-line metrics before fixing the line box.
	label.add_theme_constant_override("line_spacing", 0)
	label.position = rect.position
	label.size = rect.size
	label.add_theme_color_override("font_color", CHARCOAL)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	# Entering the tree resolves the inherited theme. Reapply the fixed box after
	# that resolution, so the pre-tree default font cannot leave a taller height.
	label.size = rect.size
	return label

func show_clock(day: int, minute_of_day: int) -> void:
	_day_label.text = str(day)
	_time_label.text = "%02d:%02d" % [minute_of_day / 60, minute_of_day % 60]

func show_money_earned(amount: float) -> void:
	_money_earned = maxf(0.0, amount)
	_earned_label.text = "$%s" % _format_money(_money_earned)
	_earned_label.tooltip_text = "Gross in-game revenue: $%s. Not your real AI spend." % _exact_money(_money_earned)

func _exact_money(amount: float) -> String:
	return "%.2f" % amount

func _format_money(amount: float) -> String:
	# Preserve a readable fixed type size instead of shrinking large values.
	# Exact cents remain available in the tooltip and Journey's finances.
	for entry: Array in [[1.0e12, "T"], [1.0e9, "B"], [1.0e6, "M"], [1.0e3, "K"]]:
		if amount >= float(entry[0]):
			return "%s%s" % [_trim_decimal("%.1f" % (amount / float(entry[0]))), entry[1]]
	if is_equal_approx(amount, roundf(amount)):
		return "%d" % int(amount)
	return "%.2f" % amount

func _trim_decimal(value: String) -> String:
	return value.trim_suffix(".0")
