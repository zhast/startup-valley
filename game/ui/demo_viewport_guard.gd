class_name DemoViewportGuard
extends Control
## An explicit supported-size treatment, not a shrunken desktop interface.

const MINIMUM := Vector2i(1024, 576)

func _ready() -> void:
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("272b22")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(900, 0)
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)
	var title := Label.new()
	title.text = "Give the studio a little more room"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", GameFonts.BOLD)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("fff5dd"))
	column.add_child(title)
	var detail := Label.new()
	detail.name = "SupportedSizeNotice"
	detail.text = "This demo needs a window of at least 1024 × 576.\nResize the window, or play on a larger screen.\nYour company stays saved."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_override("font", GameFonts.BODY)
	detail.add_theme_font_size_override("font_size", 30)
	detail.add_theme_color_override("font_color", Color("ead8b8"))
	column.add_child(detail)
	get_window().size_changed.connect(refresh)
	refresh()

func refresh() -> void:
	var physical := get_window().size
	# Headless Godot reports a dummy64px window until a test requests a size.
	# Its authored viewport remains the actual test surface in that case.
	if DisplayServer.get_name() == "headless" and physical == Vector2i(64, 64):
		physical = Vector2i(get_viewport_rect().size)
	visible = physical.x < MINIMUM.x or physical.y < MINIMUM.y

func _input(event: InputEvent) -> void:
	if visible and (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouse or event is InputEventKey):
		get_viewport().set_input_as_handled()
