class_name ArtifactViewer
extends PanelContainer

var _title_label: Label
var _content: TextEdit

func _ready() -> void:
	visible = false
	_build_interface()

func _build_interface() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0c1422")
	style.border_color = Color("6db7d8")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title_label = Label.new()
	_title_label.text = "Artifact"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	header.add_child(close_button)

	_content = TextEdit.new()
	_content.editable = false
	_content.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_font_size_override("font_size", 14)
	column.add_child(_content)

func show_artifact(name: String, content: String) -> void:
	_title_label.text = name
	_content.text = content
	_content.scroll_vertical = 0
	visible = true
	move_to_front()
