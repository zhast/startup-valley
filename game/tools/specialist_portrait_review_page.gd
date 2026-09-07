extends Control
## DEV-only plate comparison using real notebook materials/fonts. No roster.
const PREFIX := "res://tests/fixtures/character-concepts/overnight-v1/"
const SOURCE := "res://assets/source/overnight-20260904/characters/"
const IDS: Array[String] = ["mira", "theo", "lawyer", "creative"]
const NAMES := {"mira": "Mina", "theo": "Theo", "lawyer": "Legal specialist", "creative": "Creative specialist"}
const PLATE := Color("f4e3c5")
var cards: Dictionary = {}
var labels: Array[Label] = []
var controls: Array[Button] = []
var inspected := false
var note: Label
var inspect_button: Button
var missing_button: Button

static func native_path(id: String) -> String:
	return PREFIX + id + "-portrait-v3.png"

func make_panel(parent: Node, point: Vector2, extent: Vector2, skin: StyleBox) -> Panel:
	var panel := Panel.new()
	panel.position = point
	panel.size = extent
	panel.add_theme_stylebox_override("panel", skin)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(panel)
	return panel

func make_label(parent: Node, text_value: String, rect: Rect2, role: String = "body", wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUI.label(label, role)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	labels.append(label)
	return label

func _ready() -> void:
	size = Vector2(1280, 720)
	theme = GameFonts.interface_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var panel := make_panel(self, Vector2(64, 64), Vector2(1152, 608), NotebookSkin.wood_surface())
	make_panel(panel, Vector2.ZERO, panel.size, NotebookSkin.outer_frame()).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var page := make_panel(panel, Vector2(24, 24), Vector2(1104, 560), NotebookSkin.notebook())
	make_label(page, "SPECIALIST PORTRAITS", Rect2(24, 12, 1056, 40), "display")
	make_label(page, "Future character concepts only. Existing notebook materials; no new employees, hiring or abilities.", Rect2(28, 56, 1048, 30), "meta")
	for index: int in range(IDS.size()):
		var id := IDS[index]
		var card := make_panel(page, Vector2(32 + index * 264, 104), Vector2(248, 322), NotebookSkin.wood_surface(Vector4(12, 12, 12, 12)))
		var backing := make_panel(card, Vector2(12, 12), Vector2(224, 298), NotebookSkin.parchment())
		var native := id in ["lawyer", "creative"]
		make_label(backing, "OPAQUE CONCEPT" if native else "CURRENT CAST", Rect2(12, 10, 200, 28), "meta")
		var frame := make_panel(backing, Vector2(71, 44), Vector2(82, 98), NotebookSkin.portrait_frame())
		var background := ColorRect.new()
		background.color = PLATE
		background.position = Vector2(9, 9)
		background.size = Vector2(64, 80)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(background)
		var portrait := TextureRect.new()
		portrait.position = Vector2(9, 9)
		portrait.size = Vector2(64, 80)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if native else TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(native_path(id)))) if native else CharacterArt.bust_portrait(id)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(portrait)
		var name_plate := make_panel(backing, Vector2(12, 150), Vector2(200, 38), NotebookSkin.name_plaque())
		var name_label := make_label(name_plate, NAMES[id], Rect2(12, 5, 176, 28), "identity")
		var descriptor := "64 × 80 opaque plate\nExact native pixels\nNo alpha cutout" if native else "Existing source bust\nFitted as current UI does\nNot native 64 × 80 art"
		make_label(backing, descriptor, Rect2(12, 200, 200, 72), "meta")
		cards[id] = {"root": card, "backing": backing, "frame": frame, "portrait": portrait, "name_plate": name_plate, "name_label": name_label, "native": native}
	note = make_label(page, "Concepts use a 64 × 80 opening. The current rail's 66 × 74 opening would enlarge and crop them.", Rect2(24, 438, 1056, 44), "body", true)
	inspect_button = Button.new()
	inspect_button.text = "Mark review inspected"
	inspect_button.position = Vector2(276, 490)
	inspect_button.size = Vector2(260, 44)
	CozyUI.button(inspect_button, "secondary")
	inspect_button.pressed.connect(_mark_inspected)
	page.add_child(inspect_button)
	controls.append(inspect_button)
	missing_button = Button.new()
	missing_button.text = "World poses not made"
	missing_button.position = Vector2(552, 490)
	missing_button.size = Vector2(260, 44)
	CozyUI.button(missing_button, "quiet")
	missing_button.disabled = true
	page.add_child(missing_button)
	controls.append(missing_button)

func _mark_inspected() -> void:
	inspected = true
	inspect_button.text = "Inspection recorded locally"
	note.text = "This page records only its own review state. Concepts remain unregistered and are not hireable."
