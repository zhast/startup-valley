extends RefCounted
## DEV ONLY: true screen-axis low shelf. No service, seat, or production action.
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["Carcass", "Top", "Front", "Plinth", "Insert"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const ROOT := "res://tests/fixtures/furniture-calibration/low-bookshelf-v1/"
const INSERT := ROOT + "books-row-native.png"
const BAY := Color("1c1c1a") # Actual dominant native source background; not keyed alpha.
const OAK_HORIZONTAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-horizontal-v2.png"
const OAK_VERTICAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-vertical-v2.png"
const INK := Color("282622")
const EDGE := Color("77512f")
const LIGHT := Color("d1a369")
const SHADE := Color("583d28")

static func profile(side: String) -> Dictionary:
	if side not in SIDES: return {}
	var broad := side in ["north", "south"]
	var floor := Rect2i(-48, -16, 96, 32) if broad else Rect2i(-16, -48, 32, 96)
	var top := Rect2i(floor.position - Vector2i(0, 32), floor.size)
	var face := Rect2i(top.position.x, top.end.y, top.size.x, 32)
	return {"orientation": side, "direction_semantics": "visible_physical_face", "canvas": CANVAS, "pivot": PIVOT,
		"floor": floor, "top": top, "top_interior": top.grow(-2), "face": face,
		"plinth": Rect2i(face.position.x, floor.end.y - 4, face.size.x, 4),
		"insert": Rect2i(-44, -12, 88, 24) if side == "south" else Rect2i(),
		"content": Rect2i(-35, -12, 70, 24) if side == "south" else Rect2i(),
		"visual_bounds": Rect2i(top.position, Vector2i(top.size.x, top.size.y + 32)),
		"occupied": [[-1, 0], [0, 0], [1, 0]] if broad else [[0, -1], [0, 0], [0, 1]],
		"top_material": OAK_HORIZONTAL if broad else OAK_VERTICAL,
		"face_identity": "open_books_and_bin" if side == "south" else "plain_rear" if side == "north" else "plain_closed_end",
		"equivalent_view": "east" if side in ["east", "west"] else side, "runtime_approved": false}

static func paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func layers(side: String, insert: Image = null) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	if insert != null and (side != "south" or insert.get_size() != Vector2i(70, 24) or insert.detect_alpha() != Image.ALPHA_NONE): return {}
	var tile := Image.load_from_file(ProjectSettings.globalize_path(p.top_material))
	if tile == null or tile.get_size() != Vector2i(32, 32): return {}
	var images: Dictionary[String, Image] = {}
	for label: String in LAYERS: images[label] = Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var top: Rect2i = p.top
	var face: Rect2i = p.face
	paint(images.Carcass, face, INK)
	paint(images.Front, Rect2i(face.position + Vector2i(2, 0), face.size - Vector2i(4, 4)), EDGE)
	paint(images.Front, Rect2i(face.position + Vector2i(2, 0), Vector2i(face.size.x - 4, 2)), SHADE)
	paint(images.Front, Rect2i(face.position + Vector2i(2, 2), Vector2i(1, face.size.y - 6)), LIGHT)
	paint(images.Front, Rect2i(face.end.x - 3, face.position.y + 2, 1, face.size.y - 6), SHADE)
	# Actual rear/end framing, not the hidden front copied or yawed sideways.
	if side == "south":
		paint(images.Front, p.insert, BAY)
	else:
		var panel := Rect2i(face.position + Vector2i(4, 4), face.size - Vector2i(8, 8))
		paint(images.Front, panel, SHADE)
		paint(images.Front, panel.grow(-1), EDGE)
		paint(images.Front, Rect2i(panel.position + Vector2i.ONE, Vector2i(panel.size.x - 2, 1)), Color("a87742"))
	paint(images.Top, top, INK)
	paint(images.Top, Rect2i(top.position + Vector2i.ONE, Vector2i(top.size.x - 2, 1)), LIGHT)
	paint(images.Top, Rect2i(top.position + Vector2i(1, 2), Vector2i(1, top.size.y - 3)), LIGHT)
	paint(images.Top, Rect2i(top.end.x - 2, top.position.y + 2, 1, top.size.y - 3), SHADE)
	paint(images.Top, Rect2i(top.position.x + 2, top.end.y - 2, top.size.x - 3, 1), SHADE)
	var field: Rect2i = p.top_interior
	for y: int in range(field.size.y):
		for x: int in range(field.size.x):
			images.Top.set_pixelv(field.position + Vector2i(x, y) + PIVOT, tile.get_pixel(x % 32, y % 32))
	paint(images.Plinth, p.plinth, INK)
	paint(images.Plinth, Rect2i(Vector2i(p.plinth.position) + Vector2i(2, 0), Vector2i(p.plinth.size.x - 4, 2)), SHADE)
	if insert != null:
		var rgba := insert.duplicate() as Image
		rgba.convert(Image.FORMAT_RGBA8)
		images.Insert.blit_rect(rgba, Rect2i(Vector2i.ZERO, rgba.get_size()), Vector2i(p.content.position) + PIVOT)
	return images

static func whole(parts: Dictionary[String, Image]) -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	for label: String in LAYERS: result.blend_rect(parts[label], Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return result

static func catalog_entry() -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var p := profile(side)
		var render_layers: Array[Dictionary] = []
		for label: String in LAYERS:
			render_layers.append({"name": label, "art": ROOT + side + "-" + label.to_snake_case() + ".png", "region": [0, 0, 192, 224], "offset": [0, -48], "z_offset": 0})
		var bounds: Rect2i = p.visual_bounds
		profiles[side] = {"profile_kind": "decorative", "status": "calibration_candidate", "review": {"art": false, "geometry": false},
			"occupied": p.occupied, "clearance": [], "anchor_offset": [0, 0],
			"visual_bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
			"render_layers": render_layers, "ambient_overlays": [],
			"calibration_limitations": ["Only South exposes the separately generated books/bin insert.", "E/W closed ends are geometrically equivalent; no four-original claim.", "Passive study: no interaction, service, worker, seat, cast shadow or production approval."]}
	return {"facings": SIDES.duplicate(), "facing_profiles": profiles}
