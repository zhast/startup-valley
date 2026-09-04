class_name ArtifactViewer
extends Control

const CHARCOAL := Color("151515")
const INDIGO := Color("354b98")
const MUTED_INK := Color("725b46")

var _title_label: Label
var _content: RichTextLabel
var _close_button: Button
var _caption_label: Label
var _modal: PanelContainer
var _transition: Tween
var _return_focus: WeakRef

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 30
	theme = GameFonts.interface_theme()
	visible = false
	_modal = $Modal
	$Scrim.gui_input.connect(_on_scrim_input)
	_build_interface()

func _build_interface() -> void:
	_modal.add_theme_stylebox_override("panel", CozyUI.paper())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 24)
	_modal.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	var file_mark := TextureRect.new()
	file_mark.name = "DocumentIcon"
	file_mark.texture = CozyUI.icon("document")
	file_mark.custom_minimum_size = Vector2(24.0, 28.0)
	file_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	file_mark.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	file_mark.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	file_mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	file_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(file_mark)
	_title_label = Label.new()
	_title_label.text = "Document"
	# Filenames are dynamic identity, not controlled pixel-display copy. The
	# proportional section face preserves accents, punctuation and clear elision.
	CozyUI.label(_title_label, "title")
	GameFonts.use_bold(_title_label)
	_title_label.add_theme_font_size_override("font_size", GameFonts.SECTION)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.mouse_filter = Control.MOUSE_FILTER_PASS
	header.add_child(_title_label)
	_close_button = Button.new()
	CozyUI.close(_close_button)
	_close_button.tooltip_text = "Close file (Escape)"
	_close_button.pressed.connect(close_viewer)
	header.add_child(_close_button)
	_caption_label = Label.new()
	_caption_label.text = "Job delivery · Read only"
	CozyUI.label(_caption_label, "meta")
	_caption_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_caption_label.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(_caption_label)
	var divider := HSeparator.new()
	var divider_style := StyleBoxLine.new()
	divider_style.color = Color("cbb998")
	divider_style.thickness = 1
	divider.add_theme_stylebox_override("separator", divider_style)
	column.add_child(divider)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = false
	_content.scroll_active = true
	_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.selection_enabled = true
	_content.focus_mode = Control.FOCUS_ALL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	CozyUI.rich_text(_content, GameFonts.DOCUMENT)
	for role: String in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		_content.add_theme_font_size_override(role, GameFonts.DOCUMENT)
	_content.add_theme_font_size_override("mono_font_size", GameFonts.CODE)
	_content.add_theme_constant_override("line_separation", 6)
	# The document is the paper surface, not another decorated notebook inside it.
	var reading_inset := StyleBoxEmpty.new()
	# Reserve the shared six-pixel rim plus breathing room even when keyboard
	# focus appears; focus must never sit directly against the first glyph.
	reading_inset.content_margin_left = 10
	reading_inset.content_margin_right = 12
	reading_inset.content_margin_top = 4
	reading_inset.content_margin_bottom = 12
	reading_inset.set_meta("cozy_family", CozyUI.MATERIAL_FAMILY)
	reading_inset.set_meta("cozy_material", "document-content")
	reading_inset.set_meta("cozy_unframed", true)
	_content.add_theme_stylebox_override("normal", reading_inset)
	_content.add_theme_stylebox_override("focus", CozyUI.focus())
	column.add_child(_content)
	_close_button.focus_next = _close_button.get_path_to(_content)
	_close_button.focus_previous = _close_button.get_path_to(_content)
	_content.focus_next = _content.get_path_to(_close_button)
	_content.focus_previous = _content.get_path_to(_close_button)

func show_artifact(name: String, content: String, provenance: String = "Job delivery") -> void:
	# Replacing the open document must retain the original Preview/Studio action,
	# rather than capturing the reader's own Close button as the return target.
	if not visible:
		var previous := get_viewport().gui_get_focus_owner()
		_return_focus = weakref(previous) if previous != null and not is_ancestor_of(previous) else null
	_title_label.text = name.get_file()
	_title_label.tooltip_text = name
	_caption_label.text = "%s · Read only" % provenance
	_caption_label.tooltip_text = "%s\n%s" % [provenance, name]
	_content.clear()
	# clear() removes the rendered items but retains RichTextLabel's text value.
	# Reset that value too, or reopening identical Markdown skips its rebuild.
	_content.text = ""
	if name.to_lower().ends_with(".md"):
		_content.add_theme_font_override("normal_font", GameFonts.BODY)
		_content.add_theme_font_size_override("normal_font_size", GameFonts.DOCUMENT)
		_content.text = format_markdown(content)
	else:
		_content.add_theme_font_override("normal_font", GameFonts.MONO)
		_content.add_theme_font_size_override("normal_font_size", GameFonts.CODE)
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
	_modal.scale = Vector2.ONE
	_transition = create_tween()
	_transition.set_parallel(true)
	_transition.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition.tween_property($Scrim, "modulate:a", 1.0, 0.16)
	_transition.tween_property(_modal, "modulate:a", 1.0, 0.16)
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
	_transition.chain().tween_callback(func() -> void:
		hide()
		$Scrim.modulate.a = 1.0
		_modal.modulate.a = 1.0
		_modal.scale = Vector2.ONE
		_restore_prior_focus()
	)

func _restore_prior_focus() -> void:
	var previous: Control = _return_focus.get_ref() as Control if _return_focus != null else null
	_return_focus = null
	if previous == null or not previous.is_inside_tree() or not previous.is_visible_in_tree(): return
	if previous.focus_mode == Control.FOCUS_NONE: return
	if previous is BaseButton and (previous as BaseButton).disabled: return
	previous.grab_focus()

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
	for raw_line: String in markdown.replace("\r\n", "\n").split("\n"):
		if raw_line.strip_edges().begins_with("```"):
			output.append("[/code]" if in_code else "[code]")
			in_code = not in_code
			continue
		if in_code:
			output.append(raw_line.replace("[", "[lb]"))
			continue
		# Inline formatting applies inside headings and list items too. Code stays literal.
		var line := _inline_markdown(raw_line)
		if line.begins_with("### "):
			output.append("[font_size=20][b]%s[/b][/font_size]" % line.trim_prefix("### "))
		elif line.begins_with("## "):
			output.append("[font_size=22][b]%s[/b][/font_size]" % line.trim_prefix("## "))
		elif line.begins_with("# "):
			output.append("[font_size=24][b]%s[/b][/font_size]" % line.trim_prefix("# "))
		elif line.begins_with("- ") or line.begins_with("* "):
			output.append("• %s" % line.substr(2))
		else:
			output.append(line)
	if in_code:
		output.append("[/code]")
	return "\n".join(output)

static func _inline_markdown(value: String) -> String:
	var parts := value.split("`")
	var bold := RegEx.new()
	bold.compile("\\*\\*(.+?)\\*\\*")
	var italic := RegEx.new()
	italic.compile("(?<!\\*)\\*([^*]+)\\*(?!\\*)")
	for index: int in range(parts.size()):
		var part := parts[index].replace("[", "[lb]")
		if index % 2 == 1 and index < parts.size() - 1:
			parts[index] = "[code]%s[/code]" % part
		else:
			if index % 2 == 1: part = "`" + part
			part = bold.sub(part, "[b]$1[/b]", true)
			parts[index] = italic.sub(part, "[i]$1[/i]", true)
	return "".join(parts)
