extends Node2D
## DEV-ONLY exact counter/archive volume. service_side describes the accessible
## face, never a seated actor's gaze. No production placement/pose registration.

const FAMILIES: Array[String] = ["counter", "archive"]
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["Carcass", "Top", "Front", "Plinth", "Insert"]
const INK := Color("282622")
const FRAME := Color("383833")
const FRAME_LIGHT := Color("53524a")
const WOOD := Color("a87742")
const EDGE := Color("77512f")
const LIGHT := Color("d1a369")
const SHADE := Color("583d28")
enum CameraFace { REAR, LOCKER_END, SERVICE_FRONT, DISPLAY_END }
enum TopFinish { OAK, POWDERCOAT }
const CAMERA_FACES := {"north": CameraFace.REAR, "east": CameraFace.LOCKER_END, "south": CameraFace.SERVICE_FRONT, "west": CameraFace.DISPLAY_END}
const CAMERA_FACE_NAMES := {"north": "rear", "east": "locker_end", "south": "service_front", "west": "display_end"}

var resolved: Dictionary = {}
var material_ready := false
var layers: Dictionary = {}
var camera_face_finish := -1
var top_finish: TopFinish = TopFinish.OAK
var _original_top_tile: Texture2D

class CabinetLayer extends Node2D:

	var rects: Array[Dictionary] = []
	var tiled := Rect2i()
	var tile: Texture2D
	var texture: Texture2D
	var texture_position := Vector2i.ZERO

	func _draw() -> void:
		for item: Dictionary in rects:
			draw_rect(Rect2(item.rect), item.color)
		if tiled.has_area():
			if tile != null:
				draw_texture_rect(tile, Rect2(tiled), true)
			else:
				draw_rect(Rect2(tiled), WOOD)
		if texture != null:
			draw_texture(texture, Vector2(texture_position))

static func profile(family: String, side: String) -> Dictionary:
	if family not in FAMILIES:
		return {}
	# Explicit camera-space floors and service cells. No image transform and no
	# ambiguous shared-prop `facing` or borrowed chair metadata.
	var floor_rect := Rect2i()
	var cell := Vector2i.ZERO
	var gaze := ""
	var clearance: Array[Vector2i] = []
	var material_axis := ""
	match side:
		"north":
			floor_rect = Rect2i(-48, -16, 96, 32)
			cell = Vector2i(0, -1)
			gaze = "south"
			clearance.assign([Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)])
			material_axis = "horizontal"
		"east":
			floor_rect = Rect2i(-16, -48, 32, 96)
			cell = Vector2i(1, 0)
			gaze = "west"
			clearance.assign([Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)])
			material_axis = "vertical"
		"south":
			floor_rect = Rect2i(-48, -16, 96, 32)
			cell = Vector2i(0, 1)
			gaze = "north"
			clearance.assign([Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)])
			material_axis = "horizontal"
		"west":
			floor_rect = Rect2i(-16, -48, 32, 96)
			cell = Vector2i(-1, 0)
			gaze = "east"
			clearance.assign([Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1)])
			material_axis = "vertical"
		_:
			return {}
	var rise := 32 if family == "counter" else 64
	var top := Rect2i(floor_rect.position - Vector2i(0, rise), floor_rect.size)
	var front := Rect2i(top.position.x, top.end.y, top.size.x, rise)
	var plinth := Rect2i(front.position.x, floor_rect.end.y - 4, front.size.x, 4)
	var insert_socket := Rect2i(front.position + Vector2i(4, 4), front.size - Vector2i(8, 8)) if side == "south" else Rect2i()
	var face_socket := Rect2i(front.position + Vector2i(4, 4), front.size - Vector2i(8, 8)) if family == "archive" else Rect2i()
	var occupied: Array[Vector2i] = []
	if side in ["north", "south"]:
		occupied.assign([Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)])
	else:
		occupied.assign([Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)])
	return {
		"family": family, "service_side": side, "approach_gaze": gaze,
		"service_cell": cell, "clearance": clearance, "occupied": occupied,
		"floor": floor_rect, "top": top, "top_interior": top.grow(-2),
		"front": front, "plinth": plinth, "rise": rise, "contact_y": floor_rect.end.y,
		"canvas": Vector2i(192, 256) if family == "counter" else Vector2i(192, 288),
		"pivot": Vector2i(96, 192) if family == "counter" else Vector2i(96, 224),
		"visual_bounds": Rect2i(top.position, Vector2i(top.size.x, top.size.y + rise)),
		"insert_socket": insert_socket, "insert_visible": side == "south",
		"camera_face_kind": CAMERA_FACES[side] if family == "archive" else -1,
		"camera_face_name": CAMERA_FACE_NAMES[side] if family == "archive" else "",
		"camera_face_socket": face_socket,
		"service_visibility": "front" if side == "south" else ("hidden_far_face" if side == "north" else "edge_on"),
		"material_axis": material_axis, "runtime_approved": false,
	}

static func colored(rect: Rect2i, color: Color) -> Dictionary:
	return {"rect": rect, "color": color}

func configure(family: String, side: String, horizontal_tile: Texture2D = null, vertical_tile: Texture2D = null) -> bool:
	var next := profile(family, side)
	if next.is_empty():
		return false
	for material: Texture2D in [horizontal_tile, vertical_tile]:
		if material != null and material.get_size() != Vector2(32, 32):
			return false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	layers.clear()
	resolved = next
	camera_face_finish = -1
	top_finish = TopFinish.OAK
	material_ready = horizontal_tile != null and vertical_tile != null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE
	rotation = 0.0
	for index: int in range(LAYERS.size()):
		var layer := CabinetLayer.new()
		layer.name = LAYERS[index]
		# Whole solid cabinet stays at the host's floor depth. Adjacent sublayers
		# must not pull the entire archive behind an actor on its north side.
		layer.z_index = 0
		add_child(layer)
		layers[LAYERS[index]] = layer
	var top: Rect2i = next.top
	var front: Rect2i = next.front
	var plinth: Rect2i = next.plinth
	var carcass: CabinetLayer = layers.Carcass
	carcass.rects.assign([
		colored(Rect2i(front.position, Vector2i(2, front.size.y - 4)), INK),
		colored(Rect2i(front.end.x - 2, front.position.y, 2, front.size.y - 4), INK),
	])
	var roof: CabinetLayer = layers.Top
	roof.rects.assign([
		colored(top, INK),
		colored(Rect2i(top.position + Vector2i(1, 1), Vector2i(top.size.x - 2, 1)), LIGHT),
		colored(Rect2i(top.position + Vector2i(1, 2), Vector2i(1, top.size.y - 3)), LIGHT),
		colored(Rect2i(top.position + Vector2i(2, top.size.y - 2), Vector2i(top.size.x - 3, 1)), SHADE),
		colored(Rect2i(top.position + Vector2i(top.size.x - 2, 2), Vector2i(1, top.size.y - 3)), SHADE),
	])
	roof.tiled = next.top_interior
	roof.tile = horizontal_tile if next.material_axis == "horizontal" else vertical_tile
	_original_top_tile = roof.tile
	var face: CabinetLayer = layers.Front
	var field := Rect2i(front.position + Vector2i(2, 0), Vector2i(front.size.x - 4, front.size.y - 4))
	face.rects.assign([
		colored(field, EDGE if family == "counter" else FRAME),
		colored(Rect2i(field.position, Vector2i(field.size.x, 2)), SHADE if family == "counter" else INK),
		colored(Rect2i(field.position + Vector2i(0, 2), Vector2i(1, field.size.y - 2)), LIGHT if family == "counter" else FRAME_LIGHT),
		colored(Rect2i(field.end.x - 1, field.position.y + 2, 1, field.size.y - 2), SHADE if family == "counter" else INK),
	])
	# Only the south-facing service insert may occupy this plain rectangular
	# socket. Other sides expose plain rear/end structure, not yawed fake doors.
	var base: CabinetLayer = layers.Plinth
	base.rects.assign([
		colored(plinth, INK),
		colored(Rect2i(plinth.position + Vector2i(2, 0), Vector2i(plinth.size.x - 4, 2)), SHADE),
	])
	return true

func set_service_insert(texture: Texture2D) -> bool:
	if resolved.is_empty():
		return false
	var layer: CabinetLayer = layers.Insert
	if texture == null:
		layer.texture = null
		camera_face_finish = -1
		layer.queue_redraw()
		return true
	var socket: Rect2i = resolved.insert_socket
	if not resolved.insert_visible or texture.get_size() != Vector2(socket.size):
		return false
	layer.texture = texture
	layer.texture_position = socket.position
	camera_face_finish = CameraFace.SERVICE_FRONT if resolved.family == "archive" else -1
	layer.queue_redraw()
	return true

func set_camera_face_finish(kind: CameraFace, texture: Texture2D) -> bool:
	# This describes the face visible to the fixed camera, not the service door.
	# E/W end art is independently drawn; a South door cannot be reused here.
	if resolved.is_empty() or resolved.family != "archive" or kind != int(resolved.camera_face_kind):
		return false
	var socket: Rect2i = resolved.camera_face_socket
	if texture != null and texture.get_size() != Vector2(socket.size):
		return false
	var layer: CabinetLayer = layers.Insert
	layer.texture = texture
	layer.texture_position = socket.position
	camera_face_finish = int(kind) if texture != null else -1
	layer.queue_redraw()
	return true

func set_top_finish(kind: TopFinish, texture: Texture2D = null) -> bool:
	if resolved.is_empty() or kind not in [TopFinish.OAK, TopFinish.POWDERCOAT]:
		return false
	if kind == TopFinish.POWDERCOAT and (texture == null or texture.get_size() != Vector2(32, 32)):
		return false
	if kind == TopFinish.OAK and texture != null:
		return false # The existing separately authored axis tile is restored.
	var top: Rect2i = resolved.top
	var roof: CabinetLayer = layers.Top
	var light := LIGHT if kind == TopFinish.OAK else Color("53534c")
	var shade := SHADE if kind == TopFinish.OAK else Color("222623")
	var ink := INK if kind == TopFinish.OAK else Color("151515")
	roof.rects.assign([
		colored(top, ink),
		colored(Rect2i(top.position + Vector2i(1, 1), Vector2i(top.size.x - 2, 1)), light),
		colored(Rect2i(top.position + Vector2i(1, 2), Vector2i(1, top.size.y - 3)), light),
		colored(Rect2i(top.position + Vector2i(2, top.size.y - 2), Vector2i(top.size.x - 3, 1)), shade),
		colored(Rect2i(top.position + Vector2i(top.size.x - 2, 2), Vector2i(1, top.size.y - 3)), shade),
	])
	roof.tile = _original_top_tile if kind == TopFinish.OAK else texture
	top_finish = kind
	roof.queue_redraw()
	return true
