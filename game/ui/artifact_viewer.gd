class_name ArtifactViewer
extends Control

const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const MUTED_INK := Color("725b46")

var _title_label: Label
var _content: TextEdit
var _close_button: Button
var _modal: PanelContainer
var _transition: Tween

func _ready() -> void:
	theme = GameFonts.interface_theme(14)
	visible = false
	_modal = $Modal
	$Scrim.gui_input.connect(_on_scrim_input)
	_build_interface()

func _build_interface() -> void:
	_modal.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var frame := TextureRect.new()
	frame.texture = OperationsSkin.ARTIFACT_READER_FRAME
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 34)
	_modal.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var plate_label := Label.new()
	plate_label.text = "DELIVERY"
	plate_label.custom_minimum_size.y = 25.0
	plate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate_label.add_theme_font_size_override("font_size", 12)
	GameFonts.use_display(plate_label)
	plate_label.add_theme_color_override("font_color", Color("f1f1f1"))
	column.add_child(plate_label)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	var file_mark := TextureRect.new()
	file_mark.texture = OperationsSkin.ICON_DOCUMENT
	file_mark.custom_minimum_size = Vector2(32.0, 38.0)
	file_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	file_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	file_mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(file_mark)
	_title_label = Label.new()
	_title_label.text = "Artifact"
	_title_label.add_theme_font_size_override("font_size", 18)
	GameFonts.use_display(_title_label)
	_title_label.add_theme_color_override("font_color", CHARCOAL)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(_title_label)
	_close_button = Button.new()
	_close_button.text = ""
	_close_button.icon = OperationsSkin.CLOSE_BUTTON
	_close_button.add_theme_constant_override("icon_max_width", 30)
	_close_button.expand_icon = true
	_close_button.custom_minimum_size = Vector2(34.0, 34.0)
	_close_button.tooltip_text = "Close delivery"
	_close_button.pressed.connect(close_viewer)
	var close_empty := StyleBoxEmpty.new()
	_close_button.add_theme_stylebox_override("normal", close_empty)
	_close_button.add_theme_stylebox_override("hover", close_empty)
	_close_button.add_theme_stylebox_override("pressed", close_empty)
	_close_button.add_theme_stylebox_override("focus", OperationsSkin.focus_ring())
	header.add_child(_close_button)
	var caption := Label.new()
	caption.text = "DELIVERY PREVIEW  ·  READ ONLY"
	caption.add_theme_font_size_override("font_size", 10)
	GameFonts.use_display(caption)
	caption.add_theme_color_override("font_color", MUTED_INK)
	column.add_child(caption)

	_content = TextEdit.new()
	_content.editable = false
	_content.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_font_size_override("font_size", 14)
	_content.add_theme_color_override("font_color", CHARCOAL)
	_content.add_theme_color_override("font_readonly_color", CHARCOAL)
	_content.add_theme_color_override("caret_color", INDIGO)
	_content.add_theme_stylebox_override("normal", OperationsSkin.artifact_paper())
	_content.add_theme_stylebox_override("read_only", OperationsSkin.artifact_paper())
	OperationsSkin.style_text_edit_scrollbar(_content)
	column.add_child(_content)

func show_artifact(name: String, content: String) -> void:
	_title_label.text = name
	_content.text = content
	_content.scroll_vertical = 0
	visible = true
	move_to_front()
	if _transition != null and _transition.is_valid():
		_transition.kill()
	$Scrim.modulate.a = 0.0
	_modal.modulate.a = 0.0
	_modal.pivot_offset = _modal.size * 0.5
	_modal.scale = Vector2.ONE * 0.98
	_transition = create_tween()
	_transition.set_parallel(true)
	_transition.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition.tween_property($Scrim, "modulate:a", 1.0, 0.16)
	_transition.tween_property(_modal, "modulate:a", 1.0, 0.16)
	_transition.tween_property(_modal, "scale", Vector2.ONE, 0.16)
	_close_button.grab_focus()

func close_viewer() -> void:
	if not visible:
		return
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = create_tween()
	_transition.set_parallel(true)
	_transition.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_transition.tween_property($Scrim, "modulate:a", 0.0, 0.12)
	_transition.tween_property(_modal, "modulate:a", 0.0, 0.12)
	_transition.tween_property(_modal, "scale", Vector2.ONE * 0.98, 0.12)
	_transition.chain().tween_callback(func() -> void:
		hide()
		$Scrim.modulate.a = 1.0
		_modal.modulate.a = 1.0
		_modal.scale = Vector2.ONE
	)

func _on_scrim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close_viewer()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_viewer()
		get_viewport().set_input_as_handled()

func modal_fits_viewport() -> bool:
	var viewport_rect := get_viewport_rect()
	var modal_rect := _modal.get_global_rect()
	return viewport_rect.encloses(modal_rect)

func scrim_covers_viewport() -> bool:
	return $Scrim.get_global_rect().is_equal_approx(get_viewport_rect())
