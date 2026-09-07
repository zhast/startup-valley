extends "res://tools/specialist_portrait_review_page.gd"
## A separate dev page. Frozen v3 review/page and production UI are unchanged.
const CROP_ROOT := "res://tests/fixtures/character-concepts/overnight-crops-v1/"
const REVIEW_IDS: Array[String] = ["mira", "lawyer-v3", "lawyer-a", "lawyer-b", "theo", "creative-v3", "creative-a", "creative-b"]
var guides: Array[Control] = []
var guide_button: Button
var guides_visible := false

class EyeGuide extends Control:
	func _draw() -> void:
		draw_line(Vector2(0, 32), Vector2(63, 32), Color("6196c1"), 1)
		draw_line(Vector2(0, 40), Vector2(63, 40), Color("6196c1"), 1)

static func plate_path(id: String) -> String:
	var pair := id.split("-")
	return PREFIX + pair[0] + "-portrait-v3.png" if pair[1] == "v3" else CROP_ROOT + id + ".png"

func _ready() -> void:
	size = Vector2(1280, 720)
	theme = GameFonts.interface_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var panel := make_panel(self, Vector2(64, 40), Vector2(1152, 640), NotebookSkin.wood_surface())
	make_panel(panel, Vector2.ZERO, panel.size, NotebookSkin.outer_frame()).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var page := make_panel(panel, Vector2(24, 24), Vector2(1104, 592), NotebookSkin.notebook())
	make_label(page, "PORTRAIT FRAMING", Rect2(24, 8, 800, 40), "display")
	make_label(page, "Originals preserved · four source-only crop alternatives · every concept is an opaque 64 × 80 plate", Rect2(24, 48, 1056, 28), "meta")
	guide_button = Button.new()
	guide_button.text = "Show eye guides"
	guide_button.position = Vector2(864, 8)
	guide_button.size = Vector2(208, 40)
	CozyUI.button(guide_button, "secondary")
	guide_button.pressed.connect(toggle_guides)
	page.add_child(guide_button)
	controls.append(guide_button)
	for index: int in range(REVIEW_IDS.size()):
		var id := REVIEW_IDS[index]
		var row := index / 4
		var column := index % 4
		var current := id in ["mira", "theo"]
		var card := make_panel(page, Vector2(32 + column * 264, 88 + row * 240), Vector2(248, 224), NotebookSkin.wood_surface())
		var backing := make_panel(card, Vector2(12, 12), Vector2(224, 200), NotebookSkin.parchment())
		var caption: String = {"mira": "CURRENT MINA", "theo": "CURRENT THEO"}.get(id, "LEGAL" if row == 0 else "CREATIVE")
		make_label(backing, caption, Rect2(12, 4, 200, 24), "meta")
		var frame := make_panel(backing, Vector2(71, 30), Vector2(82, 98), NotebookSkin.portrait_frame())
		var background := ColorRect.new()
		background.color = PLATE
		background.position = Vector2(9, 9)
		background.size = Vector2(64, 80)
		frame.add_child(background)
		var portrait := TextureRect.new()
		portrait.position = Vector2(9, 9)
		portrait.size = Vector2(64, 80)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if current else TextureRect.STRETCH_KEEP_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.texture = CharacterArt.bust_portrait(id) if current else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(plate_path(id))))
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(portrait)
		if not current:
			var guide := EyeGuide.new()
			guide.position = Vector2(9, 9)
			guide.size = Vector2(64, 80)
			guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
			guide.hide()
			frame.add_child(guide)
			guides.append(guide)
		var name_plate := make_panel(backing, Vector2(12, 134), Vector2(200, 34), NotebookSkin.name_plaque())
		var name_copy := "Existing UI bust" if current else ("Original v3" if id.ends_with("v3") else ("A · shoulders" if id.ends_with("a") else "B · closer"))
		var name_label := make_label(name_plate, name_copy, Rect2(12, 3, 176, 28), "identity")
		var description := "Production fit, not native" if current else ("Waist-up · unchanged" if id.ends_with("v3") else "Crop · original palette")
		make_label(backing, description, Rect2(8, 172, 208, 24), "meta")
		cards[id] = {"root": card, "backing": backing, "frame": frame, "portrait": portrait, "name_plate": name_plate, "name_label": name_label, "native": not current}
	note = make_label(page, "Target: full hair, 4–6px top margin, approximate eye row 32–40. Current rail sizing still needs a separate decision.", Rect2(20, 560, 1064, 28), "meta")

func toggle_guides() -> void:
	guides_visible = not guides_visible
	for guide: Control in guides: guide.visible = guides_visible
	guide_button.text = "Hide eye guides" if guides_visible else "Show eye guides"
