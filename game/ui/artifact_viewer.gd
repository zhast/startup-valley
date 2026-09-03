class_name ArtifactViewer
extends Control

const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const MUTED_INK := Color("725b46")

var _title_label: Label
var _content: RichTextLabel
var _close_button: Button
var _modal: PanelContainer
var _transition: Tween

func _ready() -> void:
	z_index = 30
	theme = GameFonts.interface_theme()
	visible = false
	_modal = $Modal
	$Scrim.gui_input.connect(_on_scrim_input)
	_build_interface()

func _build_interface() -> void:
	_modal.add_theme_stylebox_override("panel", NotebookSkin.parchment())

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
	plate_label.add_theme_font_size_override("font_size", GameFonts.DISPLAY_SMALL)
	GameFonts.use_display(plate_label)
	plate_label.add_theme_color_override("font_color", CHARCOAL)
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
	_title_label.add_theme_font_size_override("font_size", GameFonts.DISPLAY_MEDIUM)
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
	_close_button.custom_minimum_size = Vector2(44.0, 44.0)
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
	caption.add_theme_font_size_override("font_size", GameFonts.BODY_META)
	GameFonts.use_body(caption)
	caption.add_theme_color_override("font_color", CHARCOAL)
	column.add_child(caption)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = false
	_content.scroll_active = true
	_content.selection_enabled = true
	_content.focus_mode = Control.FOCUS_ALL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_font_size_override("normal_font_size", GameFonts.BODY_DEFAULT)
	_content.add_theme_font_size_override("bold_font_size", GameFonts.BODY_DEFAULT)
	_content.add_theme_font_size_override("italics_font_size", GameFonts.BODY_DEFAULT)
	_content.add_theme_color_override("default_color", CHARCOAL)
	_content.add_theme_stylebox_override("normal", OperationsSkin.artifact_paper())
	OperationsSkin.style_rich_text_scrollbar(_content)
	column.add_child(_content)
	_close_button.focus_next = _close_button.get_path_to(_content)
	_close_button.focus_previous = _close_button.get_path_to(_content)
	_content.focus_next = _content.get_path_to(_close_button)
	_content.focus_previous = _content.get_path_to(_close_button)

func show_artifact(name: String, content: String) -> void:
	_title_label.text = name
	_content.clear()
	if name.to_lower().ends_with(".md"):
		_content.add_theme_font_override("normal_font", GameFonts.BODY)
		_content.text = format_markdown(content)
	else:
		var code_font := SystemFont.new()
		code_font.font_names = PackedStringArray(["Menlo", "Consolas", "monospace"])
		_content.add_theme_font_override("normal_font", code_font)
		# Never interpret source syntax (CSS '*', HTML tags, brackets) as Markdown.
		_content.add_text(content)
	_content.scroll_to_line(0)
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

func _markdown_to_bbcode(markdown: String) -> String:
	return format_markdown(markdown)

static func format_markdown(markdown: String) -> String:
	var output: PackedStringArray = []
	var in_code := false
	var bold := RegEx.new()
	bold.compile("\\*\\*(.+?)\\*\\*")
	for raw_line: String in markdown.replace("\r\n", "\n").split("\n"):
		var line := raw_line.replace("[", "[lb]")
		if line.strip_edges().begins_with("```"):
			output.append("[/bgcolor]" if in_code else "[bgcolor=#ead6aa]")
			in_code = not in_code
			continue
		if in_code:
			output.append("  %s" % line)
			continue
		# Inline formatting applies inside headings and list items too. Code stays literal.
		line = bold.sub(line, "[b]$1[/b]", true)
		if line.begins_with("### "):
			output.append("[font_size=18][b]%s[/b][/font_size]" % line.trim_prefix("### "))
		elif line.begins_with("## "):
			output.append("[font_size=20][b]%s[/b][/font_size]" % line.trim_prefix("## "))
		elif line.begins_with("# "):
			output.append("[font_size=24][b]%s[/b][/font_size]" % line.trim_prefix("# "))
		elif line.begins_with("- ") or line.begins_with("* "):
			output.append("• %s" % line.substr(2))
		else:
			output.append(line)
	if in_code:
		output.append("[/bgcolor]")
	return "\n".join(output)
