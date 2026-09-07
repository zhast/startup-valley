class_name CustomerSuccessKitGeometry
extends RefCounted
## DEV ONLY. Deterministic customer-support surface decor for the accepted desk.
## Every facing is independently placed in screen space. No completed bitmap is
## rotated, mirrored, scaled, or reused as another direction.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["compact_headset_dock", "ticket_triage_cards", "conversation_status_console"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("282622")
const HEADSET := Color("454540")
const HEADSET_LIGHT := Color("77746b")
const DOCK := Color("d1a369")
const PAPER := Color("ece3ca")
const PAPER_SHADE := Color("c7b999")
const CONSOLE := Color("355a4d")
const CONSOLE_LIGHT := Color("5f806f")
const SCREEN := Color("253667")
const READY := Color("83ab56")
const WAITING := Color("e0a247")
const ESCALATED := Color("c65b4b")
const CERULEAN := Color("6196c1")

static func specifications(side: String) -> Dictionary:
	# The physical grouping follows host gaze while highlights remain fixed at
	# screen upper-left. Coordinates are native canvas coordinates.
	match side:
		"north":
			return {
				"compact_headset_dock": {"layer": "surface_decor_rear", "origin": Vector2i(50, 116), "axis": "horizontal"},
				"ticket_triage_cards": {"layer": "surface_decor_rear", "origin": Vector2i(118, 118), "axis": "horizontal"},
				"conversation_status_console": {"layer": "surface_decor_front", "origin": Vector2i(50, 132), "axis": "horizontal"},
			}
		"east":
			return {
				"compact_headset_dock": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical"},
				"ticket_triage_cards": {"layer": "surface_decor_rear", "origin": Vector2i(100, 84), "axis": "vertical"},
				"conversation_status_console": {"layer": "surface_decor_front", "origin": Vector2i(99, 149), "axis": "vertical"},
			}
		"south":
			return {
				"compact_headset_dock": {"layer": "surface_decor_rear", "origin": Vector2i(118, 116), "axis": "horizontal"},
				"ticket_triage_cards": {"layer": "surface_decor_rear", "origin": Vector2i(52, 118), "axis": "horizontal"},
				"conversation_status_console": {"layer": "surface_decor_front", "origin": Vector2i(118, 132), "axis": "horizontal"},
			}
		"west":
			return {
				"compact_headset_dock": {"layer": "surface_decor_rear", "origin": Vector2i(100, 81), "axis": "vertical"},
				"ticket_triage_cards": {"layer": "surface_decor_rear", "origin": Vector2i(82, 84), "axis": "vertical"},
				"conversation_status_console": {"layer": "surface_decor_front", "origin": Vector2i(82, 149), "axis": "vertical"},
			}
	return {}

static func _image() -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _box(image: Image, rect: Rect2i, fill: Color) -> void:
	image.fill_rect(rect, INK)
	if rect.size.x > 2 and rect.size.y > 2:
		image.fill_rect(rect.grow(-1), fill)

static func _headset_horizontal(image: Image, p: Vector2i) -> void:
	# Upright headset resting on a small weighted dock, seen along a wide desk.
	image.fill_rect(Rect2i(p + Vector2i(5, 0), Vector2i(14, 2)), HEADSET)
	image.fill_rect(Rect2i(p + Vector2i(5, 0), Vector2i(11, 1)), HEADSET_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(3, 2), Vector2i(3, 6)), HEADSET)
	image.fill_rect(Rect2i(p + Vector2i(18, 2), Vector2i(3, 6)), HEADSET)
	_box(image, Rect2i(p + Vector2i(2, 5), Vector2i(5, 4)), HEADSET_LIGHT)
	_box(image, Rect2i(p + Vector2i(17, 5), Vector2i(5, 4)), HEADSET)
	image.fill_rect(Rect2i(p + Vector2i(11, 6), Vector2i(3, 4)), INK)
	image.fill_rect(Rect2i(p + Vector2i(12, 6), Vector2i(1, 3)), DOCK)
	_box(image, Rect2i(p + Vector2i(8, 9), Vector2i(9, 3)), DOCK)

static func _headset_vertical(image: Image, p: Vector2i, side: String) -> void:
	# Independently drawn narrow-desk projection; screen lighting is unchanged.
	image.fill_rect(Rect2i(p + Vector2i(0, 5), Vector2i(2, 14)), HEADSET)
	image.fill_rect(Rect2i(p + Vector2i(0, 5), Vector2i(1, 11)), HEADSET_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(2, 3), Vector2i(6, 3)), HEADSET)
	image.fill_rect(Rect2i(p + Vector2i(2, 18), Vector2i(6, 3)), HEADSET)
	_box(image, Rect2i(p + Vector2i(5, 2), Vector2i(4, 5)), HEADSET_LIGHT)
	_box(image, Rect2i(p + Vector2i(5, 17), Vector2i(4, 5)), HEADSET)
	image.fill_rect(Rect2i(p + Vector2i(6, 10), Vector2i(3, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(6, 10), Vector2i(2, 1)), DOCK)
	_box(image, Rect2i(p + Vector2i(8, 8), Vector2i(2, 9)), DOCK)
	# East exposes the lower cradle foot toward the seated contact edge. West's
	# independently placed silhouette keeps that foot tucked behind the earcup.
	if side == "east":
		_box(image, Rect2i(p + Vector2i(1, 20), Vector2i(5, 4)), DOCK)

static func _tickets_horizontal(image: Image, p: Vector2i) -> void:
	var states: Array[Color] = [CERULEAN, WAITING, READY]
	for index: int in range(3):
		var q := p + Vector2i(index * 4, index)
		_box(image, Rect2i(q, Vector2i(8, 7)), PAPER)
		image.fill_rect(Rect2i(q + Vector2i(1, 1), Vector2i(2, 4)), states[index])
		image.fill_rect(Rect2i(q + Vector2i(4, 2), Vector2i(3, 1)), PAPER_SHADE)
		image.fill_rect(Rect2i(q + Vector2i(4, 4), Vector2i(2, 1)), PAPER_SHADE)

static func _tickets_vertical(image: Image, p: Vector2i) -> void:
	var states: Array[Color] = [CERULEAN, ESCALATED, READY]
	for index: int in range(3):
		var q := p + Vector2i(index, index * 4)
		_box(image, Rect2i(q, Vector2i(7, 8)), PAPER)
		image.fill_rect(Rect2i(q + Vector2i(1, 1), Vector2i(4, 2)), states[index])
		image.fill_rect(Rect2i(q + Vector2i(2, 4), Vector2i(1, 3)), PAPER_SHADE)
		image.fill_rect(Rect2i(q + Vector2i(4, 4), Vector2i(1, 2)), PAPER_SHADE)

static func _console_horizontal(image: Image, p: Vector2i) -> void:
	# Blank conversation surface and three simple state lamps; no glyphs/metrics.
	_box(image, Rect2i(p, Vector2i(24, 10)), CONSOLE)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(10, 6)), SCREEN)
	image.fill_rect(Rect2i(p + Vector2i(3, 2), Vector2i(8, 1)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(14, 2), Vector2i(8, 1)), CONSOLE_LIGHT)
	var states: Array[Color] = [READY, WAITING, ESCALATED]
	for index: int in range(3):
		image.fill_rect(Rect2i(p + Vector2i(15 + index * 3, 5), Vector2i(2, 2)), states[index])

static func _console_vertical(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(10, 24)), CONSOLE)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(6, 10)), SCREEN)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(1, 8)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(2, 14), Vector2i(1, 8)), CONSOLE_LIGHT)
	var states: Array[Color] = [READY, ESCALATED, WAITING]
	for index: int in range(3):
		image.fill_rect(Rect2i(p + Vector2i(4, 15 + index * 3), Vector2i(2, 2)), states[index])

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name):
		return result
	var spec: Dictionary = specs[object_name]
	var p: Vector2i = spec.origin
	var horizontal := str(spec.axis) == "horizontal"
	match object_name:
		"compact_headset_dock":
			if horizontal: _headset_horizontal(result, p)
			else: _headset_vertical(result, p, side)
		"ticket_triage_cards":
			if horizontal: _tickets_horizontal(result, p)
			else: _tickets_vertical(result, p)
		"conversation_status_console":
			if horizontal: _console_horizontal(result, p)
			else: _console_vertical(result, p)
	return result

static func binary_over(rear: Image, front: Image) -> Image:
	var result := rear.get_data().duplicate()
	var near := front.get_data()
	for at: int in range(0, result.size(), 4):
		if near[at + 3] != 0:
			for channel: int in range(4):
				result[at + channel] = near[at + channel]
	return Image.create_from_data(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8, result)

static func layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {
		"surface_decor_rear": _image(),
		"surface_decor_front": _image(),
	}
	var specs := specifications(side)
	for object_name: String in OBJECTS:
		if not specs.has(object_name):
			continue
		var layer_name := str(specs[object_name].layer)
		result[layer_name] = binary_over(result[layer_name], object_image(side, object_name))
	return result

static func whole(side: String) -> Image:
	var parts := layers(side)
	return binary_over(parts.surface_decor_rear, parts.surface_decor_front)

static func layer_depth(side: String, layer_name: String) -> int:
	if side == "south":
		return 2 if layer_name == "surface_decor_rear" else 4
	if layer_name == "surface_decor_rear":
		return 0
	return 3 if side in ["east", "west"] else 2

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "CustomerSuccess" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/customer-success-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
