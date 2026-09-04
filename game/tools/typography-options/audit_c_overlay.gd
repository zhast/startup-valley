extends RefCounted
## Disposable C-study overrides only. Deliberately mirrors the approved preview,
## including its remaining gaps, rather than silently improving the product.
const SLAB: FontFile = preload("res://tools/typography-options/fonts/NotJamSlabSerif11.ttf")
const BODY: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Body.tres")
const META: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Emphasis.tres")
const BOLD: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-Bold.tres")
const ITALIC: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-BodyItalic.tres")
const BOLD_ITALIC: FontVariation = preload("res://assets/fonts/nunito-sans/NunitoSans-BoldItalic.tres")
const MONO: FontFile = preload("res://tools/typography-options/fonts/NotJamMonoClean8.ttf")

static func set_face(control: Control, font: Font, pixels: int) -> void:
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", pixels)

static func set_popup(menu: PopupMenu) -> void:
	menu.add_theme_font_override("font", META)
	menu.add_theme_font_size_override("font_size", 16)

static func apply(main: GameMain) -> void:
	walk(main)
	for value: Label in [main.clock_panel._day_label, main.clock_panel._time_label, main.clock_panel._earned_label]:
		set_face(value, SLAB, 22)
		value.add_theme_constant_override("line_spacing", 0)
		value.position.y = 29
		value.size.y = 22
	for caption: Label in [main.clock_panel._day_caption, main.clock_panel._time_caption, main.clock_panel._earned_caption]:
		set_face(caption, META, 14)
		caption.add_theme_constant_override("line_spacing", 0)
		caption.position.y = 8
		caption.size.y = 20
	var names: Array[Label] = []
	var heading := main.job_panel._rail_panel.find_child("TeamHeading", true, false) as Label
	if heading != null: names.append(heading)
	for employee_id: String in main.job_panel._team_buttons:
		var label := main.job_panel._team_buttons[employee_id].find_child("EmployeeName", true, false) as Label
		if label != null: names.append(label)
	for label: Label in names:
		if SLAB.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x <= label.size.x and SLAB.get_height(22) <= label.size.y:
			set_face(label, SLAB, 22)

static func walk(node: Node) -> void:
	if node is RichTextLabel:
		for entry: Array in [["normal", BODY], ["bold", BOLD], ["italics", ITALIC], ["bold_italics", BOLD_ITALIC], ["mono", MONO]]:
			(node as RichTextLabel).add_theme_font_override(str(entry[0]) + "_font", entry[1])
			(node as RichTextLabel).add_theme_font_size_override(str(entry[0]) + "_font_size", 16)
	elif node is Label:
		var role := str(node.get_meta("cozy_text_role", "body"))
		set_face(node, SLAB if role == "display" else META if role == "meta" else BOLD if role in ["title", "action"] else BODY, 22 if role == "display" else 14 if role == "meta" else 16)
	elif node is Button:
		set_face(node, BOLD, 16)
		if node is OptionButton: set_popup(node.get_popup())
	elif node is LineEdit or node is TextEdit:
		set_face(node, BODY, 16)
		set_popup(node.call("get_menu"))
	for child: Node in node.get_children(): walk(child)

static func inventory(node: Node, result: Array[Dictionary]) -> void:
	if node is Control and node.is_visible_in_tree() and (node is Label or node is Button or node is LineEdit or node is TextEdit or node is RichTextLabel):
		var control := node as Control
		var rich := node is RichTextLabel
		var face := control.get_theme_font("normal_font" if rich else "font")
		var pixels := control.get_theme_font_size("normal_font_size" if rich else "font_size")
		var rect := control.get_global_rect()
		result.append({"node": str(node.get_path()), "text": str(node.get("text")), "role": str(node.get_meta("cozy_text_role", "unassigned")), "font": face.resource_path, "size": pixels, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	for child: Node in node.get_children(): inventory(child, result)
