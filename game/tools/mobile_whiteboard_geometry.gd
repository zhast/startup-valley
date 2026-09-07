extends Node2D
## DEV ONLY: visual orientation, no service/seat/worker behavior or registry.
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["GroundBase", "RearSupports", "FarTray", "BoardFrame", "FaceInsert", "NearTray", "NearSupports"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const INK := Color("282622")
const FRAME := Color("383833")
const LIGHT := Color("68685e")
const SHADE := Color("20221f")
const WHITE := Color("f4f1ed") # Measured substrate of the actual V3 planning insert.
const PAPER_EDGE := Color("c8c8ba")
const POWDERCOAT := "res://tests/fixtures/furniture-calibration/materials/charcoal-powdercoat-v1.png"
var resolved: Dictionary = {}
var layer_images: Dictionary[String, Image] = {}
var planning_source := ""

static func profile(side: String) -> Dictionary:
	if side not in SIDES: return {}
	var broad := side in ["north", "south"]
	var floor := Rect2i(-48, -16, 96, 32) if broad else Rect2i(-16, -48, 32, 96)
	var occupied: Array[Vector2i] = []
	occupied.assign([Vector2i(-1, 0), Vector2i.ZERO, Vector2i(1, 0)] if broad else [Vector2i(0, -1), Vector2i.ZERO, Vector2i(0, 1)])
	var visitor := {"north": Vector2i(0, -32), "east": Vector2i(32, 0), "south": Vector2i(0, 32), "west": Vector2i(-32, 0)}
	var front := Rect2i(-44, -78, 88, 56) if broad else Rect2i(-2, -124, 4, 144)
	var tray := Rect2i(-40, -32, 80, 9) if side == "north" else Rect2i(-40, -22, 80, 9) if side == "south" else Rect2i(2, -64, 8, 80) if side == "east" else Rect2i(-10, -64, 8, 80)
	return {"orientation": side, "direction_semantics": "visual_orientation", "canvas": CANVAS, "pivot": PIVOT, "floor": floor, "occupied": occupied, "board": front, "board_rise": 80, "board_lower_rise": 24, "board_thickness": 4, "tray": tray, "content_socket": Rect2i(-40, -74, 80, 48) if side == "south" else Rect2i(), "visitor_offset": visitor[side], "visitor_bounds": Rect2i(-24, -72, 48, 80), "conservative_visual_bounds": Rect2i(-48, -82, 96, 98) if broad else Rect2i(-16, -124, 32, 172), "face_visibility": "planning_front" if side == "south" else "structural_rear" if side == "north" else "thin_edge_no_readable_face", "runtime_approved": false, "interaction": "none"}

static func paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func box(image: Image, rect: Rect2i, color: Color) -> void:
	paint(image, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: paint(image, rect.grow(-1), color)
	# Highlights stay screen upper-left in every independently defined view.
	paint(image, Rect2i(rect.position + Vector2i(1, 1), Vector2i(maxi(1, rect.size.x - 2), 1)), LIGHT)
	paint(image, Rect2i(rect.position + Vector2i(1, 1), Vector2i(1, maxi(1, rect.size.y - 2))), LIGHT)
	paint(image, Rect2i(rect.end - Vector2i(rect.size.x - 1, 2), Vector2i(maxi(1, rect.size.x - 2), 1)), SHADE)

static func raster_layers(side: String, insert: Image = null) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	if insert != null and (side != "south" or insert.get_size() != Vector2i(80, 48) or insert.detect_alpha() != Image.ALPHA_NONE): return {}
	var images: Dictionary[String, Image] = {}
	for name_value: String in LAYERS: images[name_value] = Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var base := images.GroundBase as Image
	var support := images.RearSupports as Image
	var frame := images.BoardFrame as Image
	if side in ["north", "south"]:
		for x: int in [-42, 42]:
			box(base, Rect2i(x - 3, -12, 6, 24), FRAME)
			box(base, Rect2i(x - 5, -16, 10, 7), FRAME)
			box(base, Rect2i(x - 6, 8, 12, 8), FRAME)
			box(support, Rect2i(x - 2, -24, 4, 34), FRAME)
		box(support, Rect2i(-42, -5, 84, 4), FRAME)
		box(frame, Rect2i(-44, -82, 88, 4), FRAME)
		box(frame, p.board, FRAME)
		var panel := Rect2i(-42, -76, 84, 52)
		if side == "south":
			paint(frame, panel, PAPER_EDGE)
			paint(frame, Rect2i(-40, -74, 80, 48), WHITE)
		else:
			var tile := Image.load_from_file(ProjectSettings.globalize_path(POWDERCOAT))
			if tile == null or tile.get_size() != Vector2i(32, 32): return {}
			for y: int in range(panel.position.y, panel.end.y):
				for x: int in range(panel.position.x, panel.end.x): frame.set_pixelv(Vector2i(x, y) + PIVOT, tile.get_pixel(posmod(x, 32), posmod(y, 32)))
			for y: int in [-69, -33]:
				paint(frame, Rect2i(-37, y, 74, 2), FRAME)
				for x: int in [-37, 34]: paint(frame, Rect2i(x, y, 2, 2), LIGHT)
		var tray := images.FarTray if side == "north" else images.NearTray
		box(tray, p.tray, FRAME)
		if side == "south":
			# Restrained marker silhouettes are geometry, not a writing animation.
			paint(tray, Rect2i(-29, -20, 10, 2), Color("6196c1"))
			paint(tray, Rect2i(-16, -20, 9, 2), Color("b6b5b0"))
	else:
		for y: int in [-42, 42]:
			box(base, Rect2i(-12, y - 3, 24, 6), FRAME)
			box(base, Rect2i(-16, y - 5, 8, 10), FRAME)
			box(base, Rect2i(8, y - 6, 8, 12), FRAME)
			box(support if y < 0 else images.NearSupports, Rect2i(-2, y - 24, 4, 28), FRAME)
		box(frame, p.board, FRAME)
		# The thin top rail and the near end's vertical edge meet at y=-36.
		paint(frame, Rect2i(-1, -36, 2, 1), SHADE)
		box(images.NearTray, p.tray, FRAME)
		var marker_x := 3 if side == "east" else -7
		paint(images.NearTray, Rect2i(marker_x, -53, 2, 10), Color("6196c1"))
		paint(images.NearTray, Rect2i(marker_x, -40, 2, 9), Color("b6b5b0"))
	if insert != null:
		images.FaceInsert.blit_rect(insert, Rect2i(Vector2i.ZERO, insert.get_size()), Vector2i(p.content_socket.position) + PIVOT)
	return images

static func reunite(parts: Dictionary[String, Image]) -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	for name_value: String in LAYERS: result.blend_rect(parts[name_value], Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return result

func configure(side: String, insert: Image = null, source_path := "") -> bool:
	var next := raster_layers(side, insert)
	if next.is_empty(): return false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	resolved = profile(side)
	layer_images = next
	planning_source = source_path if insert != null else ""
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE
	rotation = 0.0
	for name_value: String in LAYERS:
		var sprite := Sprite2D.new()
		sprite.name = name_value
		sprite.texture = ImageTexture.create_from_image(next[name_value])
		sprite.position = Vector2(CANVAS) / 2.0 - Vector2(PIVOT)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	return true
