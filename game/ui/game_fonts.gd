class_name GameFonts
extends RefCounted

const DISPLAY: FontFile = preload("res://assets/fonts/tiny5/Tiny5-Regular.ttf")
const BODY: FontFile = preload("res://assets/fonts/nunito-sans/NunitoSans-Variable.ttf")

# The 720p interface is the authored baseline. Tiny5 becomes difficult to scan
# below 18 px, while Nunito Sans remains comfortable for prose at 16 px.
const DISPLAY_LARGE := 28
const DISPLAY_MEDIUM := 20
const DISPLAY_SMALL := 18
const BODY_DEFAULT := 16
const BODY_META := 14

static func interface_theme(default_size: int = BODY_DEFAULT) -> Theme:
	var value := Theme.new()
	value.default_font = BODY
	value.default_font_size = default_size
	return value

static func use_display(control: Control) -> void:
	control.add_theme_font_override("font", DISPLAY)

static func use_body(control: Control) -> void:
	control.add_theme_font_override("font", BODY)
