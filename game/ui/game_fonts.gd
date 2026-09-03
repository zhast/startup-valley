class_name GameFonts
extends RefCounted

const DISPLAY: FontFile = preload("res://assets/fonts/tiny5/Tiny5-Regular.ttf")
const BODY: FontFile = preload("res://assets/fonts/nunito-sans/NunitoSans-Variable.ttf")

static func interface_theme(default_size: int = 14) -> Theme:
	var value := Theme.new()
	value.default_font = BODY
	value.default_font_size = default_size
	return value

static func use_display(control: Control) -> void:
	control.add_theme_font_override("font", DISPLAY)

static func use_body(control: Control) -> void:
	control.add_theme_font_override("font", BODY)
