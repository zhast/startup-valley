class_name VisitorChairGeometry
extends RefCounted
## DEV ONLY. Deterministic fixed guest seating on the planned 96x144 canvas.
## Every facing is laid out directly in screen space. No completed bitmap is
## rotated, mirrored, scaled, or borrowed from the rolling task chair.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "seat_back", "seat_front"]
const CANVAS := Vector2i(96, 144)
const PIVOT := Vector2i(48, 96)
const SPRITE_OFFSET := Vector2i(0, -24)
const OCCUPIED: Array[Vector2i] = [Vector2i.ZERO]

const INK := Color("282622")
const FRAME := Color("77512f")
const FRAME_LIGHT := Color("d1a369")
const FRAME_SHADE := Color("493421")
const FABRIC := Color("4f7f74")
const FABRIC_LIGHT := Color("76a095")
const FABRIC_SHADE := Color("315a54")
const SEAM := Color("c7b999")
const SHADOW := Color("554e42")

static func _piece(rect: Rect2i, color: Color) -> Dictionary:
	return {"rect": rect, "color": color}

static func profile(side: String) -> Dictionary:
	# Local coordinates are relative to the unchanged floor pivot. Back, seat,
	# and fixed legs are separate declarations for each screen-axis projection.
	match side:
		"north":
			return {
				"facing": side, "axis": "screen_y", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [0, 1],
				"employee_look_vector": [0, -1],
				"shadow": Rect2i(-15, -9, 30, 23),
				"back": Rect2i(-16, -48, 32, 20),
				"seat": Rect2i(-15, -29, 30, 20),
				"back_fill": FABRIC_SHADE, "seat_fill": FABRIC,
				"rear_parts": [
					_piece(Rect2i(-14, -45, 4, 38), FRAME),
					_piece(Rect2i(10, -45, 4, 38), FRAME_SHADE),
					_piece(Rect2i(-12, -31, 24, 3), FRAME),
				],
				"front_parts": [
					_piece(Rect2i(-16, -11, 32, 6), FABRIC_SHADE),
					_piece(Rect2i(-14, -6, 4, 22), INK),
					_piece(Rect2i(-13, -5, 2, 19), FRAME_LIGHT),
					_piece(Rect2i(10, -6, 4, 22), INK),
					_piece(Rect2i(11, -5, 2, 19), FRAME),
					_piece(Rect2i(-9, 10, 18, 3), FRAME),
				],
				"contact_points": [Vector2i(-12, -8), Vector2i(12, -8), Vector2i(-12, 15), Vector2i(12, 15)],
			}
		"east":
			return {
				"facing": side, "axis": "screen_x", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [-1, 0],
				"employee_look_vector": [1, 0],
				"shadow": Rect2i(-15, -10, 30, 25),
				"back": Rect2i(-18, -48, 10, 31),
				"seat": Rect2i(-11, -29, 28, 18),
				"back_fill": FABRIC_SHADE, "seat_fill": FABRIC,
				"rear_parts": [
					_piece(Rect2i(-16, -45, 4, 40), FRAME),
					_piece(Rect2i(-12, -21, 18, 3), FRAME_SHADE),
					_piece(Rect2i(-10, -18, 4, 30), INK),
					_piece(Rect2i(-9, -17, 2, 27), FRAME_LIGHT),
					_piece(Rect2i(7, -10, 3, 20), FRAME_SHADE),
				],
				"front_parts": [
					_piece(Rect2i(-8, -13, 26, 6), FABRIC_SHADE),
					_piece(Rect2i(11, -8, 4, 24), INK),
					_piece(Rect2i(12, -7, 2, 21), FRAME),
					_piece(Rect2i(-8, 10, 22, 3), FRAME),
				],
				"contact_points": [Vector2i(-14, -6), Vector2i(-8, 11), Vector2i(8, 9), Vector2i(13, 15)],
			}
		"south":
			return {
				"facing": side, "axis": "screen_y", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [0, -1],
				"employee_look_vector": [0, 1],
				"shadow": Rect2i(-14, -8, 29, 23),
				"back": Rect2i(-17, -48, 34, 22),
				"seat": Rect2i(-15, -27, 30, 20),
				"back_fill": FABRIC, "seat_fill": FABRIC_LIGHT,
				"rear_parts": [
					_piece(Rect2i(-14, -44, 4, 34), FRAME),
					_piece(Rect2i(10, -44, 4, 34), FRAME_SHADE),
					_piece(Rect2i(-11, -30, 23, 3), FRAME_LIGHT),
				],
				"front_parts": [
					_piece(Rect2i(-16, -9, 32, 7), FABRIC_SHADE),
					_piece(Rect2i(-13, -3, 4, 19), INK),
					_piece(Rect2i(-12, -2, 2, 16), FRAME_LIGHT),
					_piece(Rect2i(9, -3, 4, 19), INK),
					_piece(Rect2i(10, -2, 2, 16), FRAME),
					_piece(Rect2i(-8, 9, 17, 3), FRAME_SHADE),
				],
				"contact_points": [Vector2i(-12, -11), Vector2i(12, -11), Vector2i(-11, 15), Vector2i(11, 15)],
			}
		"west":
			return {
				"facing": side, "axis": "screen_x", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [1, 0],
				"employee_look_vector": [-1, 0],
				"shadow": Rect2i(-15, -9, 30, 24),
				"back": Rect2i(8, -48, 10, 32),
				"seat": Rect2i(-17, -28, 28, 18),
				"back_fill": FABRIC, "seat_fill": FABRIC_LIGHT,
				"rear_parts": [
					_piece(Rect2i(12, -45, 4, 40), FRAME_SHADE),
					_piece(Rect2i(-6, -20, 18, 3), FRAME),
					_piece(Rect2i(6, -17, 4, 29), INK),
					_piece(Rect2i(7, -16, 2, 26), FRAME_LIGHT),
					_piece(Rect2i(-10, -9, 3, 20), FRAME_SHADE),
				],
				"front_parts": [
					_piece(Rect2i(-18, -12, 26, 6), FABRIC_SHADE),
					_piece(Rect2i(-15, -7, 4, 23), INK),
					_piece(Rect2i(-14, -6, 2, 20), FRAME_LIGHT),
					_piece(Rect2i(-14, 9, 22, 3), FRAME),
				],
				"contact_points": [Vector2i(14, -6), Vector2i(8, 11), Vector2i(-9, 10), Vector2i(-13, 15)],
			}
	return {}

static func contact_socket(side: String) -> Dictionary:
	# One walkable physical socket supports either a standing scale check or a
	# seated visual mount. The mount is evidence metadata, never a capability.
	match side:
		"north":
			return {"physical_cell": [0, 1], "actor_gaze": [0, -1], "seated_render_offset": [0, -34], "mounted_render_foot": [0, -2]}
		"east":
			return {"physical_cell": [-1, 0], "actor_gaze": [1, 0], "seated_render_offset": [34, -2], "mounted_render_foot": [2, -2]}
		"south":
			return {"physical_cell": [0, -1], "actor_gaze": [0, 1], "seated_render_offset": [0, 29], "mounted_render_foot": [0, -3]}
		"west":
			return {"physical_cell": [1, 0], "actor_gaze": [-1, 0], "seated_render_offset": [-34, -1], "mounted_render_foot": [-2, -1]}
	return {}

static func _image() -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func _draw_parts(image: Image, parts: Array) -> void:
	for raw: Variant in parts:
		var part := raw as Dictionary
		_paint(image, part.rect, part.color)

static func _dithered_shadow(image: Image, rect: Rect2i) -> void:
	var center := Vector2(rect.position) + Vector2(rect.size - Vector2i.ONE) * 0.5
	var radius := Vector2(rect.size) * 0.5
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var delta := (Vector2(x, y) - center) / radius
			if delta.length_squared() <= 1.0 and (delta.length_squared() < 0.34 or (x + y) % 2 == 0):
				_paint(image, Rect2i(x, y, 1, 1), SHADOW)

static func _soft_box(image: Image, rect: Rect2i, fill: Color, show_seam: bool) -> void:
	# A one-pixel stepped silhouette reads as upholstery without partial alpha.
	_paint(image, Rect2i(rect.position + Vector2i(2, 0), Vector2i(rect.size.x - 4, 1)), INK)
	_paint(image, Rect2i(rect.position + Vector2i(1, 1), Vector2i(rect.size.x - 2, 1)), INK)
	_paint(image, Rect2i(rect.position + Vector2i(0, 2), Vector2i(rect.size.x, rect.size.y - 4)), INK)
	_paint(image, Rect2i(rect.position + Vector2i(1, rect.size.y - 2), Vector2i(rect.size.x - 2, 1)), INK)
	_paint(image, Rect2i(rect.position + Vector2i(2, rect.size.y - 1), Vector2i(rect.size.x - 4, 1)), INK)
	_paint(image, Rect2i(rect.position + Vector2i(2, 2), Vector2i(rect.size.x - 4, rect.size.y - 4)), fill)
	_paint(image, Rect2i(rect.position + Vector2i(3, 2), Vector2i(rect.size.x - 6, 1)), FABRIC_LIGHT)
	_paint(image, Rect2i(rect.position + Vector2i(2, rect.size.y - 3), Vector2i(rect.size.x - 4, 1)), FABRIC_SHADE)
	if show_seam and rect.size.x >= 20:
		_paint(image, Rect2i(rect.position + Vector2i(6, 6), Vector2i(rect.size.x - 12, 1)), SEAM)

static func layers(side: String) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	var result: Dictionary[String, Image] = {"floor_shadow": _image(), "seat_back": _image(), "seat_front": _image()}
	_dithered_shadow(result.floor_shadow, p.shadow)
	_draw_parts(result.seat_back, p.rear_parts)
	_soft_box(result.seat_back, p.back, p.back_fill, side in ["south", "west"])
	_soft_box(result.seat_back, p.seat, p.seat_fill, side in ["east", "south"])
	_draw_parts(result.seat_front, p.front_parts)
	return result

static func binary_over(back: Image, near: Image) -> Image:
	var result := back.get_data().duplicate()
	var front := near.get_data()
	for at: int in range(0, result.size(), 4):
		if front[at + 3] != 0:
			for channel: int in range(4): result[at + channel] = front[at + channel]
	return Image.create_from_data(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8, result)

static func whole(side: String) -> Image:
	var parts := layers(side)
	if parts.is_empty(): return Image.new()
	return binary_over(binary_over(parts.floor_shadow, parts.seat_back), parts.seat_front)

static func layer_depth(layer_name: String) -> int:
	return {"floor_shadow": -8, "seat_back": -6, "seat_front": 5}.get(layer_name, 0)

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "VisitorChair" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/visitor-chair-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(layer_name),
	}

static func catalog_entry() -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var p := profile(side)
		var socket := contact_socket(side)
		var bounds := whole(side).get_used_rect()
		var local_bounds := Rect2i(bounds.position - PIVOT, bounds.size)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in LAYERS: render_layers.append(descriptor(side, layer_name))
		profiles[side] = {
			"profile_kind": "decorative",
			"status": "calibration_candidate",
			"review": {"art": false, "geometry": false},
			"occupied": p.occupied.duplicate(true),
			"clearance": [socket.physical_cell.duplicate()],
			"anchor_offset": [0, 0],
			"visual_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"hit_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"render_layers": render_layers,
			"ambient_overlays": [],
			"standing_viewpoints": [{"cell": socket.physical_cell.duplicate(), "visual_bounds": [-24, -72, 48, 80]}],
			"optional_contact_socket": {
				"physical_cell": socket.physical_cell.duplicate(),
				"actor_gaze": socket.actor_gaze.duplicate(),
				"seated_render_offset": socket.seated_render_offset.duplicate(),
				"mounted_render_foot": socket.mounted_render_foot.duplicate(),
				"modes": ["standing_probe", "seated_probe"],
				"runtime_capability": false,
			},
			"calibration_limitations": [
				"Optional contact geometry is evidence-only; this passive candidate exposes no interaction or seat capability.",
				"Existing employee art may probe scale and occlusion, but no actor pixels are baked into this family.",
			],
		}
	return {
		"display_name": "Visitor chair candidate",
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none",
		"facing_profiles": profiles,
	}
