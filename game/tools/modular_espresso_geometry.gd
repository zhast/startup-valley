extends Node2D
## DEV ONLY: exact fixed-camera volume plus genuine opaque face-interior crops.
## E/W masters remain failed opaque kits. This does not extract their silhouette.
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["Top", "Housing", "Face"]
const CANVAS := Vector2i(64, 96)
const PIVOT := Vector2i(32, 72)
const MATERIAL := "res://tests/fixtures/furniture-calibration/materials/charcoal-powdercoat-v1.png"
const SOURCE_ROOT := "res://assets/source/overnight-20260904/kits/"
const SOURCES := {"north": "coffee-service-north-v2.png", "east": "coffee-service-east-v2.png", "south": "coffee-service-south-v4.png", "west": "coffee-service-west-v2.png"}
# Each rectangle lies entirely inside the original opaque vertical housing.
# It excludes the malformed top, outer edge and every checkerboard pixel.
const CROPS := {"north": Rect2i(214, 326, 318, 360), "east": Rect2i(283, 295, 204, 384), "south": Rect2i(250, 326, 336, 354), "west": Rect2i(293, 326, 221, 357)}
const FEATURES := {"north": "rear hatch / vents / grommet", "east": "vented side interior", "south": "front controls / spouts / drip tray", "west": "two-fastener side interior"}
const INK := Color("151515")
const LIGHT := Color("697681")
const SHADE := Color("222b31")
const BODY := Color("35434d")
var resolved: Dictionary = {}
var layers: Dictionary = {}
var face_record: Dictionary = {}

class Layer extends Node2D:

	var rects: Array[Dictionary] = []
	var tile: Texture2D
	var tile_rect := Rect2i()
	var face: Texture2D
	var face_point := Vector2i.ZERO

	func _draw() -> void:
		for item: Dictionary in rects: draw_rect(Rect2(item.rect), item.color)
		if tile != null: draw_texture_rect(tile, Rect2(tile_rect), true)
		if face != null: draw_texture(face, Vector2(face_point))

static func profile(side: String) -> Dictionary:
	var floor_rect := Rect2i()
	match side:
		"north": floor_rect = Rect2i(-14, -6, 29, 13)
		"east": floor_rect = Rect2i(-6, -14, 13, 29)
		"south": floor_rect = Rect2i(-14, -6, 29, 13)
		"west": floor_rect = Rect2i(-6, -14, 13, 29)
		_: return {}
	var top := Rect2i(floor_rect.position - Vector2i(0, 31), floor_rect.size)
	var face := Rect2i(top.position.x, top.end.y, top.size.x, 31)
	return {"service_side": side, "floor": floor_rect, "rise": 31, "top": top,
		"front": face, "face_socket": face.grow(-1), "contact_y": floor_rect.end.y,
		"visual_bounds": Rect2i(top.position, Vector2i(top.size.x, top.size.y + 31)),
		"canvas": CANVAS, "pivot": PIVOT, "feature": FEATURES[side],
		"odd_dimension_center": Vector2(0.5, 0.5), "runtime_approved": false}

static func face_source(side: String) -> Dictionary:
	var p := profile(side)
	if p.is_empty(): return {}
	var path := SOURCE_ROOT + str(SOURCES[side])
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	if source == null or source.is_empty(): return {}
	source.convert(Image.FORMAT_RGBA8)
	var crop: Rect2i = CROPS[side]
	if not Rect2i(Vector2i.ZERO, source.get_size()).encloses(crop): return {}
	var interior := source.get_region(crop)
	var opaque_bytes := interior.get_data()
	var min_alpha := 255
	for at: int in range(3, opaque_bytes.size(), 4):
		min_alpha = mini(min_alpha, opaque_bytes[at])
		if opaque_bytes[at] < 250: return {}
		# N/S source extraction left253–254 even inside solid metal. Only this
		# verified interior rectangle becomes opaque material; RGB is unchanged.
		opaque_bytes[at] = 255
	interior = Image.create_from_data(crop.size.x, crop.size.y, false, Image.FORMAT_RGBA8, opaque_bytes)
	var socket: Rect2i = p.face_socket
	var factor := minf(float(socket.size.x) / crop.size.x, float(socket.size.y) / crop.size.y)
	var native_size := Vector2i(maxi(1, roundi(crop.size.x * factor)), maxi(1, roundi(crop.size.y * factor)))
	interior.resize(native_size.x, native_size.y, Image.INTERPOLATE_NEAREST)
	var point := socket.position + Vector2i((socket.size.x - native_size.x) / 2, (socket.size.y - native_size.y) / 2)
	return {"image": interior, "source": path, "source_sha256": FileAccess.get_sha256(path),
		"crop": crop, "uniform_scale": factor, "native_size": native_size, "position": point,
		"minimum_original_alpha": min_alpha, "interior_opacity_normalized": min_alpha < 255,
		"padding": socket.size - native_size, "whole_source_alpha_accepted": side in ["north", "south"],
		"source_is_not_silhouette": true, "runtime_approved": false}

static func item(rect: Rect2i, color: Color) -> Dictionary:
	return {"rect": rect, "color": color}

func configure(side: String, use_face: bool = true) -> bool:
	var p := profile(side)
	if p.is_empty(): return false
	var record := face_source(side)
	if record.is_empty(): return false
	var material := Image.load_from_file(ProjectSettings.globalize_path(MATERIAL))
	if material == null or material.get_size() != Vector2i(32, 32): return false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	layers.clear()
	resolved = p
	face_record = record
	scale = Vector2.ONE
	rotation = 0.0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for name_value: String in LAYERS:
		var layer := Layer.new()
		layer.name = name_value
		layer.z_index = 0
		add_child(layer)
		layers[name_value] = layer
	var top: Rect2i = p.top
	var roof: Layer = layers.Top
	roof.rects.assign([item(top, INK), item(Rect2i(top.position + Vector2i.ONE, Vector2i(top.size.x - 2, 1)), LIGHT),
		item(Rect2i(top.position + Vector2i(1, 2), Vector2i(1, top.size.y - 3)), LIGHT),
		item(Rect2i(top.end.x - 2, top.position.y + 2, 1, top.size.y - 3), SHADE),
		item(Rect2i(top.position.x + 2, top.end.y - 2, top.size.x - 3, 1), SHADE)])
	roof.tile = ImageTexture.create_from_image(material)
	roof.tile_rect = top.grow(-2)
	var front: Rect2i = p.front
	var housing: Layer = layers.Housing
	housing.rects.assign([item(front, INK), item(front.grow(-1), BODY)])
	var face: Layer = layers.Face
	if use_face:
		face.face = ImageTexture.create_from_image(record.image)
		face.face_point = record.position
	return true
