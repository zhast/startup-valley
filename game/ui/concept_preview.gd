class_name ConceptPreview
extends Control

signal assign_work_requested(employee_id: String)
signal chat_requested(employee_id: String)

enum Screen {
	CLOSED,
	ROSTER,
	PROFILE,
}

const ROSTER_TEXTURE: Texture2D = preload("res://assets/concepts/ui/team-roster-brand-palette-concept.png")
const PROFILE_TEXTURE: Texture2D = preload("res://assets/concepts/ui/employee-profile-brand-palette-concept.png")

const VERMILION := Color("fa4616")
const OFF_WHITE := Color("f1f1f1")
const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const CERULEAN := Color("6196c1")
const WHITE := Color("ffffff")

var _screen: Screen = Screen.CLOSED
var _preview_root: Control
var _image: TextureRect
var _launcher: Button
var _roster_controls: Array[Control] = []
var _profile_controls: Array[Control] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_build_launcher()
	_build_preview()
	close_preview()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_T:
		if _screen == Screen.CLOSED:
			open_roster()
		else:
			close_preview()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE and _screen != Screen.CLOSED:
		close_preview()
		get_viewport().set_input_as_handled()

func open_roster() -> void:
	_screen = Screen.ROSTER
	_preview_root.visible = true
	_launcher.visible = false
	_image.texture = ROSTER_TEXTURE
	_set_controls_visible(_roster_controls, true)
	_set_controls_visible(_profile_controls, false)

func open_profile() -> void:
	_screen = Screen.PROFILE
	_preview_root.visible = true
	_launcher.visible = false
	_image.texture = PROFILE_TEXTURE
	_set_controls_visible(_roster_controls, false)
	_set_controls_visible(_profile_controls, true)

func close_preview() -> void:
	_screen = Screen.CLOSED
	_preview_root.visible = false
	_launcher.visible = true

func current_screen() -> String:
	match _screen:
		Screen.ROSTER:
			return "roster"
		Screen.PROFILE:
			return "profile"
		_:
			return "closed"

func _build_launcher() -> void:
	_launcher = Button.new()
	_launcher.text = "TEAM  [T]"
	_launcher.tooltip_text = "Open the interactive team UI concept"
	_launcher.focus_mode = Control.FOCUS_ALL
	_launcher.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_launcher.anchor_left = 0.565
	_launcher.anchor_top = 0.025
	_launcher.anchor_right = 0.68
	_launcher.anchor_bottom = 0.085
	_launcher.add_theme_font_size_override("font_size", 15)
	_launcher.add_theme_color_override("font_color", CHARCOAL)
	_launcher.add_theme_color_override("font_hover_color", CHARCOAL)
	_launcher.add_theme_color_override("font_pressed_color", OFF_WHITE)
	_launcher.add_theme_stylebox_override("normal", _button_style(VERMILION, CHARCOAL))
	_launcher.add_theme_stylebox_override("hover", _button_style(OFF_WHITE, VERMILION))
	_launcher.add_theme_stylebox_override("pressed", _button_style(INDIGO, WHITE))
	_launcher.add_theme_stylebox_override("focus", _button_style(CERULEAN, WHITE))
	_launcher.pressed.connect(open_roster)
	add_child(_launcher)

func _build_preview() -> void:
	_preview_root = Control.new()
	_preview_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_preview_root)

	_image = TextureRect.new()
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.mouse_filter = Control.MOUSE_FILTER_STOP
	_preview_root.add_child(_image)

	_roster_controls.append(_hotspot(Rect2(0.365, 0.13, 0.27, 0.44), "Open Mina's profile", open_profile))
	_roster_controls.append(_hotspot(Rect2(0.68, 0.855, 0.27, 0.125), "View Mina's profile", open_profile))
	_roster_controls.append(_hotspot(Rect2(0.02, 0.86, 0.22, 0.12), "Close team roster", close_preview))

	_profile_controls.append(_hotspot(Rect2(0.015, 0.90, 0.13, 0.09), "Back to team roster", open_roster))
	_profile_controls.append(_hotspot(Rect2(0.195, 0.775, 0.145, 0.12), "Assign work to Mina", _assign_mina))
	_profile_controls.append(_hotspot(Rect2(0.025, 0.775, 0.165, 0.12), "Chat with Mina", _chat_with_mina))

func _hotspot(area: Rect2, hint: String, callback: Callable) -> Button:
	var button := Button.new()
	button.anchor_left = area.position.x
	button.anchor_top = area.position.y
	button.anchor_right = area.end.x
	button.anchor_bottom = area.end.y
	button.tooltip_text = hint
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.pressed.connect(callback)
	_preview_root.add_child(button)
	return button

func _set_controls_visible(controls: Array[Control], value: bool) -> void:
	for control: Control in controls:
		control.visible = value

func _assign_mina() -> void:
	close_preview()
	assign_work_requested.emit("mira")

func _chat_with_mina() -> void:
	close_preview()
	chat_requested.emit("mira")

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style
