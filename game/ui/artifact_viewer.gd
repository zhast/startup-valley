class_name ArtifactViewer
extends Control

const VERMILION := Color("fa4616")
const OFF_WHITE := Color("f1f1f1")
const CHARCOAL := Color("151515")
const CERULEAN := Color("6196c1")
const CHARTREUSE := Color("c1fa81")
const DUST := Color("b6b5b0")

var _title_label: Label
var _content: TextEdit
var _close_button: Button
var _modal: PanelContainer

func _ready() -> void:
	visible = false
	_modal = $Modal
	$Scrim.gui_input.connect(_on_scrim_input)
	_build_interface()

func _build_interface() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CHARCOAL
	style.border_color = VERMILION
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_modal.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_modal.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var file_mark := Label.new()
	file_mark.text = "▤"
	file_mark.add_theme_font_size_override("font_size", 22)
	file_mark.add_theme_color_override("font_color", VERMILION)
	header.add_child(file_mark)
	_title_label = Label.new()
	_title_label.text = "Artifact"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", OFF_WHITE)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.pressed.connect(hide)
	_close_button.add_theme_stylebox_override("normal", _stylebox(Color("252525"), CERULEAN, 1, 5))
	_close_button.add_theme_stylebox_override("hover", _stylebox(Color("303030"), CERULEAN, 2, 5))
	_close_button.add_theme_stylebox_override("focus", _stylebox(Color("202020"), CHARTREUSE, 2, 5))
	_close_button.add_theme_color_override("font_color", OFF_WHITE)
	header.add_child(_close_button)
	var caption := Label.new()
	caption.text = "DELIVERY PREVIEW  ·  READ ONLY"
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", DUST)
	column.add_child(caption)

	_content = TextEdit.new()
	_content.editable = false
	_content.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_font_size_override("font_size", 14)
	_content.add_theme_color_override("font_color", OFF_WHITE)
	_content.add_theme_color_override("font_readonly_color", OFF_WHITE)
	_content.add_theme_color_override("caret_color", VERMILION)
	_content.add_theme_stylebox_override("normal", _stylebox(Color("202020"), Color("484848"), 1, 6))
	_content.add_theme_stylebox_override("read_only", _stylebox(Color("202020"), Color("484848"), 1, 6))
	column.add_child(_content)

func _stylebox(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func show_artifact(name: String, content: String) -> void:
	_title_label.text = name
	_content.text = content
	_content.scroll_vertical = 0
	visible = true
	move_to_front()
	_close_button.grab_focus()

func _on_scrim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

func modal_fits_viewport() -> bool:
	var viewport_rect := get_viewport_rect()
	var modal_rect := _modal.get_global_rect()
	return viewport_rect.encloses(modal_rect)

func scrim_covers_viewport() -> bool:
	return $Scrim.get_global_rect().is_equal_approx(get_viewport_rect())
