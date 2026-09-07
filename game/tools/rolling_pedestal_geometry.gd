extends Node2D
## DEV ONLY. A desk-height rolling cabinet, with no family/action registration.
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["CasterRear", "CasterFront", "Carcass", "Top", "NearFace", "FaceInsert"]
const CANVAS := Vector2i(96, 144)
const PIVOT := Vector2i(48, 96)
const INK := Color("282622")
const FRAME := Color("383833")
const LIGHT := Color("53534c")
const SHADE := Color("222623")
const POWDERCOAT := "res://tests/fixtures/furniture-calibration/materials/charcoal-powdercoat-v1.png"
var resolved: Dictionary = {}
var layer_images: Dictionary[String, Image] = {}

static func profile(side: String) -> Dictionary:
	if side not in SIDES: return {}
	var broad := side in ["north", "south"]
	var floor := Rect2i(-14, -12, 28, 24) if broad else Rect2i(-12, -14, 24, 28)
	var top := Rect2i(floor.position - Vector2i(0, 32), floor.size)
	var face := Rect2i(top.position.x, top.end.y, top.size.x, 28)
	var visitor := {"north": Vector2i(0, -1), "east": Vector2i(1, 0), "south": Vector2i(0, 1), "west": Vector2i(-1, 0)}
	var gaze := {"north": "south", "east": "west", "south": "north", "west": "east"}
	var names := {"north": "rear", "east": "left_side", "south": "drawer_front", "west": "right_side"}
	var mounts: Array[Vector2i] = []
	for y: int in [-13, 13] if broad else [-11, 11]:
		for x: int in [-11, 11] if broad else [-13, 13]: mounts.append(Vector2i(x, y))
	return {"service_side": side, "approach_gaze": gaze[side], "service_cell": visitor[side], "clearance": [visitor[side]], "occupied": [Vector2i.ZERO], "approach_visual_bounds": Rect2i(-24, -72, 48, 80), "canvas": CANVAS, "pivot": PIVOT, "reserved_floor": Rect2i(-16, -16, 32, 32), "body_floor": floor, "top": top, "face": face, "face_socket": face.grow(-2), "caster_mounts": mounts, "rise": 32, "underside_rise": 4, "camera_face": names[side], "runtime_approved": false, "interaction": "none", "visual_bounds": Rect2i(-14, top.position.y, 28, 14 - top.position.y) if broad else Rect2i(-16, top.position.y, 32, 12 - top.position.y)}

static func paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func box(image: Image, rect: Rect2i) -> void:
	paint(image, rect, INK)
	paint(image, rect.grow(-1), FRAME)
	paint(image, Rect2i(rect.position + Vector2i.ONE, Vector2i(rect.size.x - 2, 1)), LIGHT)
	paint(image, Rect2i(rect.position + Vector2i.ONE, Vector2i(1, rect.size.y - 2)), LIGHT)
	paint(image, Rect2i(rect.end - Vector2i(rect.size.x - 1, 2), Vector2i(rect.size.x - 2, 1)), SHADE)

static func tiled(image: Image, rect: Rect2i, tile: Image) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x): image.set_pixelv(Vector2i(x, y) + PIVOT, tile.get_pixel(posmod(x, 32), posmod(y, 32)))

static func raster_layers(side: String, insert: Image = null) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	if insert != null and (side != "south" or insert.get_size() != Vector2i(24, 24) or insert.detect_alpha() != Image.ALPHA_NONE): return {}
	var tile := Image.load_from_file(ProjectSettings.globalize_path(POWDERCOAT))
	if tile == null or tile.get_size() != Vector2i(32, 32): return {}
	var parts: Dictionary[String, Image] = {}
	for name_value: String in LAYERS: parts[name_value] = Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	for mount: Vector2i in p.caster_mounts:
		var caster := parts.CasterRear if mount.y < 0 else parts.CasterFront
		var x := mount.x
		var y := mount.y
		box(caster, Rect2i(x - 2, y - 7, 4, 3))
		# Mount positions rotate with physical body axes; caster silhouettes keep
		# their freely swiveling screen-space shape and upper-left illumination.
		paint(caster, Rect2i(x - 3, y - 4, 6, 4), INK)
		paint(caster, Rect2i(x - 2, y - 5, 4, 6), INK)
		paint(caster, Rect2i(x - 2, y - 4, 3, 3), FRAME)
		paint(caster, Rect2i(x - 2, y - 4, 2, 1), LIGHT)
	box(parts.Carcass, p.face)
	box(parts.Top, p.top)
	tiled(parts.Top, p.top.grow(-2), tile)
	var socket: Rect2i = p.face_socket
	tiled(parts.NearFace, socket, tile)
	if side == "south":
		# Blank reusable panel until a separately supplied front is installed.
		paint(parts.NearFace, Rect2i(socket.position + Vector2i(0, 11), Vector2i(socket.size.x, 2)), INK)
	elif side == "north":
		for x: int in [socket.position.x + 1, socket.end.x - 2]:
			for y: int in [socket.position.y + 1, socket.end.y - 2]: paint(parts.NearFace, Rect2i(x, y, 1, 1), LIGHT)
		paint(parts.NearFace, Rect2i(socket.position.x + 2, socket.end.y - 3, socket.size.x - 4, 1), FRAME)
	else:
		var seam := socket.end.x - 2 if side == "east" else socket.position.x + 1
		paint(parts.NearFace, Rect2i(seam, socket.position.y, 1, socket.size.y), INK)
		paint(parts.NearFace, Rect2i(socket.position.x + 2, socket.end.y - 3, socket.size.x - 4, 1), FRAME)
	if insert != null: parts.FaceInsert.blit_rect(insert, Rect2i(Vector2i.ZERO, insert.get_size()), socket.position + PIVOT)
	return parts

static func reunite(parts: Dictionary[String, Image]) -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	for name_value: String in LAYERS: result.blend_rect(parts[name_value], Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return result

func configure(side: String, insert: Image = null) -> bool:
	var next := raster_layers(side, insert)
	if next.is_empty(): return false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	resolved = profile(side)
	layer_images = next
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE
	rotation = 0
	for name_value: String in LAYERS:
		var sprite := Sprite2D.new()
		sprite.name = name_value
		sprite.texture = ImageTexture.create_from_image(next[name_value])
		sprite.position = Vector2(CANVAS) / 2 - Vector2(PIVOT)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	return true
