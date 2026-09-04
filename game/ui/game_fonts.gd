class_name GameFonts
extends RefCounted

const DISPLAY: FontFile = preload("res://assets/fonts/not-jam-slab/NotJamSlabSerif11.ttf")
const BODY: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Body.tres")
const EMPHASIS: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Emphasis.tres")
const BOLD: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Bold.tres")
const ITALIC: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-BodyItalic.tres")
const BOLD_ITALIC: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-BoldItalic.tres")
const MONO: FontVariation = preload("res://assets/fonts/jetbrains-mono/JetBrainsMono-Body.tres")

# Slab's 11px design grid is rendered at exactly 2x. Functional/reading roles
# stay proportional and antialiased. Never shrink a role to make a control fit.
const DISPLAY_LARGE := 22
const DISPLAY_MEDIUM := 22
const DISPLAY_SMALL := 22
const SECTION := 20
const NUMERIC := 20
const RAIL_NAME := 16
const DOCUMENT := 18
const CODE := 16
const BODY_DEFAULT := 16
const BODY_META := 14

static func _static_init() -> void:
	# Godot includes every fallback's metrics in Label minimum heights, even
	# for ASCII. Align fallback line boxes to Nunito without scaling outlines
	# or changing advances. Rendered mixed-script bounds are tested separately.
	for source: FontFile in [preload("res://assets/fonts/noto-fallback/NotoSansCJKsc-Regular.otf"), preload("res://assets/fonts/noto-fallback/NotoSansSymbols2-Regular.ttf"), preload("res://assets/fonts/noto-fallback/NotoEmoji.ttf")]:
		source.get_rids()
		for pixels: int in range(14, 25):
			source.get_height(pixels)
			for index: int in range(source.get_cache_count()):
				source.set_cache_ascent(index, pixels, BODY.base_font.get_ascent(pixels))
				source.set_cache_descent(index, pixels, BODY.base_font.get_descent(pixels))

static func has_glyphs(font: Font, text: String) -> bool:
	for character: String in text:
		var code := character.unicode_at(0)
		if code > 32 and not font.has_char(code): return false
	return true

static func display_font_for(text: String) -> Font:
	# Coverage fallback only: the font never changes in response to available
	# width, string length, hover, selection, or other layout state.
	return DISPLAY if has_glyphs(DISPLAY, text) else BOLD

static func interface_theme(default_size: int = BODY_DEFAULT) -> Theme:
	var value := Theme.new()
	value.default_font = BODY
	value.default_font_size = default_size
	for type_name: String in ["Label", "LineEdit", "TextEdit"]:
		value.set_font("font", type_name, BODY)
	for type_name: String in ["Button", "OptionButton", "TabBar", "TabContainer", "PopupMenu"]:
		value.set_font("font", type_name, BOLD)
		value.set_font_size("font_size", type_name, 16)
	value.set_font("normal_font", "RichTextLabel", BODY)
	value.set_font("bold_font", "RichTextLabel", BOLD)
	value.set_font("italics_font", "RichTextLabel", ITALIC)
	value.set_font("bold_italics_font", "RichTextLabel", BOLD_ITALIC)
	value.set_font("mono_font", "RichTextLabel", MONO)
	for role: String in ["normal", "bold", "italics", "bold_italics", "mono"]:
		value.set_font_size(role + "_font_size", "RichTextLabel", default_size)
	value.set_font_size("mono_font_size", "RichTextLabel", CODE)
	value.set_color("default_color", "RichTextLabel", Color("151515"))
	value.set_color("font_color", "Label", Color("151515"))
	value.set_constant("line_separation", "RichTextLabel", 3)
	# Tooltips are part of the interface too: deterministic readable metadata
	# rather than an operating-system/default-theme font on a dark popup.
	value.set_font("font", "TooltipLabel", EMPHASIS)
	value.set_font_size("font_size", "TooltipLabel", 14)
	value.set_color("font_color", "TooltipLabel", Color("151515"))
	value.set_constant("outline_size", "TooltipLabel", 0)
	var tooltip := StyleBoxFlat.new()
	tooltip.bg_color = Color("fff4df")
	tooltip.border_color = Color("8b6745")
	tooltip.set_border_width_all(1)
	tooltip.set_content_margin_all(8)
	tooltip.anti_aliasing = false
	value.set_stylebox("panel", "TooltipPanel", tooltip)
	return value

static func use_display(control: Control) -> void:
	control.add_theme_font_override("font", DISPLAY)

static func use_body(control: Control) -> void:
	control.add_theme_font_override("font", BODY)

static func use_emphasis(control: Control) -> void:
	control.add_theme_font_override("font", EMPHASIS)

static func use_bold(control: Control) -> void:
	control.add_theme_font_override("font", BOLD)

static func rich_text(control: RichTextLabel, size: int = BODY_DEFAULT) -> void:
	control.add_theme_font_override("normal_font", BODY)
	control.add_theme_font_override("bold_font", BOLD)
	control.add_theme_font_override("italics_font", ITALIC)
	control.add_theme_font_override("bold_italics_font", BOLD_ITALIC)
	control.add_theme_font_override("mono_font", MONO)
	for role: String in ["normal", "bold", "italics", "bold_italics", "mono"]:
		control.add_theme_font_size_override(role + "_font_size", size)
	control.add_theme_font_size_override("mono_font_size", CODE)
	control.add_theme_color_override("default_color", Color("151515"))
	control.add_theme_constant_override("line_separation", 3)
