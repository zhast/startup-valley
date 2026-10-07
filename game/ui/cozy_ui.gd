class_name CozyUI
extends RefCounted
## Shared visual vocabulary. Only outer structures use the ornate walnut kit.
## Content controls have fixed geometry and calm paper interiors.

const INK := Color("151515")
const MUTED := Color("5e5143")
const PAPER := Color("f4e3c5")
const PAPER_LIGHT := Color("fff4df")
const LINE := Color("b69b72")
const INDIGO := Color("354b98")
const VERMILION := Color("fa4616")
const ALERT := Color("963014")
const SUCCESS := Color("365d1f")
const DISABLED := Color("ded7c9")
const CONTROL_HEIGHT := 44
const GAP := 8
const INSET := 12
const ART_ROOT := "res://assets/runtime/ui/cozy-controls/"
const MATERIAL_ROOT := "res://assets/runtime/ui/materials/"
const MATERIAL_FAMILY := "startup-notebook"

static func flat(fill: Color, border: Color = Color.TRANSPARENT, width: int = 0, insets: Vector4 = Vector4(12, 8, 12, 8)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(2)
	style.anti_aliasing = false
	_margins(style, insets)
	return style

static func _margins(style: StyleBox, insets: Vector4) -> void:
	style.set_content_margin(SIDE_LEFT, insets.x)
	style.set_content_margin(SIDE_TOP, insets.y)
	style.set_content_margin(SIDE_RIGHT, insets.z)
	style.set_content_margin(SIDE_BOTTOM, insets.w)

static func paper(insets: Vector4 = Vector4(12, 12, 12, 12)) -> StyleBox:
	return _material(NotebookSkin.parchment(insets), "notebook")

static func card(insets: Vector4 = Vector4(12, 12, 12, 12)) -> StyleBox:
	return surface("card", insets)

static func _material(style: StyleBox, kind: String) -> StyleBox:
	style.set_meta("cozy_family", MATERIAL_FAMILY)
	style.set_meta("cozy_material", kind)
	return style

static func icon(kind: String) -> Texture2D:
	return load(MATERIAL_ROOT + kind + ".png") as Texture2D

static func surface(kind: String, insets: Vector4 = Vector4(12, 8, 12, 8)) -> StyleBox:
	return _material(NotebookSkin.texture_style(icon(kind), Vector4(6, 6, 6, 6), insets), kind)

static func bubble(sender: String, insets: Vector4 = Vector4(12, 8, 12, 8)) -> StyleBox:
	return surface("bubble-player" if sender == "player" else "bubble-employee", insets)

static func focus() -> StyleBox:
	# A hollow inset ring: same stepped corners, no expanding outer rectangle.
	return surface("focus", Vector4.ZERO)

static func control_style(variant: String, state: String = "normal") -> StyleBox:
	var texture_root := MATERIAL_ROOT if variant == "quiet" else ART_ROOT
	var texture := load(texture_root + variant + "-" + state + ".png") as Texture2D
	return _material(NotebookSkin.texture_style(texture, Vector4(6, 6, 6, 6), Vector4(12, 8, 12, 8)), "control-" + variant)

static func tab_style(selected: bool, state: String = "normal") -> StyleBox:
	return surface("tab-" + ("active-" if selected else "inactive-") + state, Vector4(8, 8, 8, 8))

static func tab_button(control: Button, selected: bool) -> void:
	button(control, "quiet")
	control.set_meta("cozy_variant", "navigation")
	control.set_meta("cozy_tab_selected", selected)
	for state: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		control.add_theme_stylebox_override(state, tab_style(selected, "pressed" if state == "hover_pressed" else state))

static func button(control: Button, variant: String = "secondary") -> void:
	control.set_meta("cozy_variant", variant)
	control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, CONTROL_HEIGHT)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	control.add_theme_font_override("font", GameFonts.BOLD)
	control.add_theme_font_size_override("font_size", 16)
	control.add_theme_constant_override("outline_size", 0)
	for state: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		control.add_theme_stylebox_override(state, control_style(variant, "pressed" if state == "hover_pressed" else state))
	for role: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		control.add_theme_color_override(role, ALERT if variant == "danger" else INK)
	control.add_theme_color_override("font_disabled_color", MUTED)
	control.add_theme_stylebox_override("focus", focus())
	# Refreshes can restyle state many times; animation signals are bound once.
	if not control.has_meta("cozy_press_bound"):
		control.set_meta("cozy_press_bound", true)
		control.button_down.connect(_pressed.bind(control, true))
		control.button_up.connect(_pressed.bind(control, false))

static func _pressed(control: Button, down: bool) -> void:
	if control.has_meta("cozy_press_tween"):
		var previous := control.get_meta("cozy_press_tween") as Tween
		if previous != null and previous.is_valid(): previous.kill()
	if down:
		control.self_modulate = Color(0.94, 0.94, 0.94)
	else:
		var tween := control.create_tween()
		control.set_meta("cozy_press_tween", tween)
		tween.tween_property(control, "self_modulate", Color.WHITE, 0.08)

static func disclosure(control: Button, expanded: bool) -> void:
	button(control, "quiet")
	var arrow := load(ART_ROOT + "chevron.png") as Texture2D
	if expanded:
		var pixels := arrow.get_image()
		pixels.flip_y()
		arrow = ImageTexture.create_from_image(pixels)
	control.icon = arrow
	control.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	control.expand_icon = false
	control.add_theme_constant_override("h_separation", 8)
	control.set_meta("cozy_disclosure_expanded", expanded)
	control.tooltip_text = "Collapse details" if expanded else "Expand details"

static func input(control: Control) -> void:
	control.add_theme_font_override("font", GameFonts.BODY)
	control.add_theme_font_size_override("font_size", 16)
	control.add_theme_constant_override("outline_size", 0)
	control.add_theme_color_override("font_color", INK)
	control.add_theme_color_override("font_readonly_color", MUTED)
	control.add_theme_color_override("font_placeholder_color", MUTED)
	control.add_theme_color_override("caret_color", INDIGO)
	control.add_theme_color_override("selection_color", Color("b7c6e5"))
	control.add_theme_color_override("font_selected_color", INK)
	control.add_theme_stylebox_override("normal", surface("field"))
	control.add_theme_stylebox_override("read_only", surface("readonly"))
	control.add_theme_stylebox_override("focus", focus())
	if control is LineEdit:
		control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, CONTROL_HEIGHT)
		popup((control as LineEdit).get_menu())
	if control is TextEdit:
		popup((control as TextEdit).get_menu())
		control.add_theme_constant_override("line_spacing", 3)
		_scrollbar((control as TextEdit).get_v_scroll_bar())
		_scrollbar((control as TextEdit).get_h_scroll_bar())

static func dropdown(control: OptionButton) -> void:
	button(control)
	control.add_theme_icon_override("arrow", load(ART_ROOT + "chevron.png") as Texture2D)
	control.add_theme_constant_override("modulate_arrow", 0)
	control.add_theme_constant_override("arrow_margin", 12)
	control.add_theme_constant_override("h_separation", 8)
	popup(control.get_popup())

static func popup(menu: PopupMenu) -> void:
	menu.add_theme_font_override("font", GameFonts.EMPHASIS)
	menu.add_theme_font_size_override("font_size", 16)
	menu.add_theme_color_override("font_color", INK)
	menu.add_theme_color_override("font_hover_color", INK)
	menu.add_theme_color_override("font_disabled_color", MUTED)
	menu.add_theme_color_override("font_accelerator_color", MUTED)
	menu.add_theme_color_override("font_separator_color", MUTED)
	menu.add_theme_stylebox_override("panel", surface("popup", Vector4(8, 8, 8, 8)))
	menu.add_theme_stylebox_override("hover", surface("selection", Vector4(8, 8, 8, 8)))
	for prefix: String in ["", "radio_"]:
		menu.add_theme_icon_override(prefix + "checked", icon("checked"))
		menu.add_theme_icon_override(prefix + "unchecked", icon("unchecked"))
		menu.add_theme_icon_override(prefix + "checked_disabled", icon("checked-disabled"))
		menu.add_theme_icon_override(prefix + "unchecked_disabled", icon("unchecked"))
	menu.add_theme_constant_override("v_separation", 18)
	# Godot 4.7 PopupMenu embeds PanelContainer chrome (paper panel + _focus).
	# Stamp it so ancestor audits see notebook materials, not default flats.
	_stamp_popup_chrome(menu)
	if not menu.has_meta("cozy_chrome_bound"):
		menu.set_meta("cozy_chrome_bound", true)
		menu.about_to_popup.connect(_stamp_popup_chrome.bind(menu))
		menu.child_entered_tree.connect(func(_node: Node) -> void: _stamp_popup_chrome(menu))
		if not menu.is_inside_tree():
			menu.tree_entered.connect(_stamp_popup_chrome.bind(menu), CONNECT_ONE_SHOT)

static func _stamp_popup_chrome(menu: PopupMenu) -> void:
	if not is_instance_valid(menu): return
	for node: Node in menu.find_children("*", "PanelContainer", true, false):
		var panel := node as PanelContainer
		var kind := "focus" if str(panel.name) == "_focus" else "popup"
		if str(panel.get_theme_stylebox("panel").get_meta("cozy_material", "")) == kind: continue
		panel.add_theme_stylebox_override("panel", focus() if kind == "focus" else surface("popup", Vector4(8, 8, 8, 8)))

static func close(control: Button) -> void:
	button(control, "quiet")
	control.custom_minimum_size = Vector2(44, 44)
	control.text = ""
	control.icon = icon("close")
	control.expand_icon = false
	control.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.add_theme_font_override("font", GameFonts.BOLD)
	control.add_theme_font_size_override("font_size", 24)
	control.tooltip_text = "Close"

static func label(control: Label, role: String = "body") -> void:
	var font: Font = GameFonts.BODY
	var size := 16
	if role == "display":
		font = GameFonts.display_font_for(control.text)
		size = GameFonts.DISPLAY_LARGE
	elif role in ["title", "section"]:
		font = GameFonts.BOLD
		size = GameFonts.SECTION
	elif role == "numeric":
		font = GameFonts.BOLD
		size = GameFonts.NUMERIC
	elif role == "identity":
		font = GameFonts.BOLD
		size = GameFonts.RAIL_NAME
	elif role == "meta":
		font = GameFonts.EMPHASIS
		size = 14
	elif role == "action":
		font = GameFonts.BOLD
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", MUTED if role == "meta" else INK)
	control.add_theme_constant_override("outline_size", 0)
	control.add_theme_constant_override("line_spacing", 3 if role == "body" else 0)
	control.set_meta("cozy_text_role", role)

static func rich_text(control: RichTextLabel, size: int = 16) -> void:
	GameFonts.rich_text(control, size)
	_scrollbar(control.get_v_scroll_bar())
	if control.has_method("get_menu"):
		popup(control.call("get_menu") as PopupMenu)

static func tabs(control: TabContainer) -> void:
	control.add_theme_font_override("font", GameFonts.BOLD)
	control.add_theme_font_size_override("font_size", 16)
	for role: String in ["font_selected_color", "font_unselected_color", "font_hovered_color", "font_outline_color"]:
		control.add_theme_color_override(role, INK)
	control.add_theme_color_override("font_disabled_color", MUTED)
	control.add_theme_stylebox_override("panel", flat(PAPER, Color.TRANSPARENT, 0, Vector4.ZERO))
	control.add_theme_stylebox_override("tab_selected", tab_style(true))
	control.add_theme_stylebox_override("tab_unselected", tab_style(false))
	control.add_theme_stylebox_override("tab_hovered", tab_style(false, "hover"))
	control.add_theme_stylebox_override("tab_disabled", tab_style(false, "disabled"))
	control.add_theme_stylebox_override("tab_focus", focus())
	var bar := control.get_tab_bar()
	bar.custom_minimum_size.y = 44
	bar.tab_alignment = TabBar.ALIGNMENT_CENTER
	bar.add_theme_font_override("font", GameFonts.BOLD)
	bar.add_theme_font_size_override("font_size", 16)

static func scroll(control: ScrollContainer) -> void:
	_scrollbar(control.get_v_scroll_bar())
	_scrollbar(control.get_h_scroll_bar())

static func _scrollbar(control: ScrollBar) -> void:
	var vertical := control is VScrollBar
	var margins := Vector4(6, 0, 6, 0) if vertical else Vector4(0, 6, 0, 6)
	for spec: Array in [["scroll", "track"], ["grabber", "thumb"], ["grabber_highlight", "thumb-hover"], ["grabber_pressed", "thumb-pressed"]]:
		var kind: String = spec[1] + ("" if vertical else "-horizontal")
		var style := NotebookSkin.texture_style(icon(kind), Vector4(3, 3, 3, 3), margins)
		control.add_theme_stylebox_override(spec[0], _material(style, kind))
	for icon_name: String in ["decrement", "decrement_highlight", "decrement_pressed", "increment", "increment_highlight", "increment_pressed"]:
		control.add_theme_icon_override(icon_name, OperationsSkin.TRANSPARENT)

static func slider(control: HSlider) -> void:
	control.custom_minimum_size.y = 44
	for spec: Array in [["slider", "track-horizontal"], ["grabber_area", "track-filled"], ["grabber_area_highlight", "track-filled"]]:
		var style := NotebookSkin.texture_style(icon(spec[1]), Vector4(3, 3, 3, 3), Vector4(0, 6, 0, 6))
		control.add_theme_stylebox_override(spec[0], _material(style, spec[1]))
	control.add_theme_stylebox_override("focus", focus())
	control.add_theme_icon_override("grabber", load(ART_ROOT + "slider-normal.png") as Texture2D)
	control.add_theme_icon_override("grabber_highlight", load(ART_ROOT + "slider-hover.png") as Texture2D)
	control.add_theme_icon_override("grabber_disabled", load(ART_ROOT + "slider-disabled.png") as Texture2D)
