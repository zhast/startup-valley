class_name FinanceAccountsKitGeometry
extends RefCounted
## DEV ONLY. Deterministic finance-planning decor for the accepted desk.
## Each facing is independently authored in screen space; no finished bitmap is
## rotated, mirrored, scaled, or reused for another direction.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["ledger_folio", "keypad_device", "receipt_trays"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("282622")
const LEDGER := Color("355a4d")
const LEDGER_LIGHT := Color("5f806f")
const BURGUNDY := Color("713f45")
const BRASS := Color("d1a369")
const PAPER := Color("eee2c8")
const PAPER_SHADE := Color("c7b999")
const STEEL := Color("454540")
const STEEL_LIGHT := Color("77746b")
const SCREEN := Color("253667")

static func specifications(side: String) -> Dictionary:
	# Physical arrangement follows host gaze; light remains screen-upper-left.
	match side:
		"north":
			return {
				"ledger_folio": {"layer": "surface_decor_rear", "origin": Vector2i(50, 117), "axis": "horizontal"},
				"keypad_device": {"layer": "surface_decor_rear", "origin": Vector2i(118, 117), "axis": "horizontal"},
				"receipt_trays": {"layer": "surface_decor_front", "origin": Vector2i(50, 132), "axis": "horizontal"},
			}
		"east":
			return {
				"ledger_folio": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical"},
				"keypad_device": {"layer": "surface_decor_rear", "origin": Vector2i(100, 84), "axis": "vertical"},
				"receipt_trays": {"layer": "surface_decor_front", "origin": Vector2i(96, 149), "axis": "vertical"},
			}
		"south":
			return {
				"ledger_folio": {"layer": "surface_decor_rear", "origin": Vector2i(117, 117), "axis": "horizontal"},
				"keypad_device": {"layer": "surface_decor_rear", "origin": Vector2i(53, 118), "axis": "horizontal"},
				"receipt_trays": {"layer": "surface_decor_front", "origin": Vector2i(117, 132), "axis": "horizontal"},
			}
		"west":
			return {
				"ledger_folio": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical"},
				"keypad_device": {"layer": "surface_decor_rear", "origin": Vector2i(101, 84), "axis": "vertical"},
				"receipt_trays": {"layer": "surface_decor_front", "origin": Vector2i(82, 149), "axis": "vertical"},
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

static func _ledger_horizontal(image: Image, p: Vector2i) -> void:
	# Closed folio with abstract column bands; no figures or readable marks.
	image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(23, 9)), INK)
	_box(image, Rect2i(p, Vector2i(24, 10)), LEDGER)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(20, 1)), LEDGER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(4, 1), Vector2i(2, 8)), INK)
	image.fill_rect(Rect2i(p + Vector2i(8, 4), Vector2i(5, 1)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(8, 6), Vector2i(8, 1)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(19, 4), Vector2i(3, 3)), BRASS)

static func _ledger_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(9, 23)), INK)
	_box(image, Rect2i(p, Vector2i(10, 24)), LEDGER)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(1, 20)), LEDGER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(1, 4), Vector2i(8, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(4, 8), Vector2i(1, 5)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(6, 8), Vector2i(1, 8)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(4, 19), Vector2i(3, 3)), BRASS)

static func _keypad_horizontal(image: Image, p: Vector2i) -> void:
	# Unlabelled planning device: blank screen plus uniform, glyph-free keys.
	_box(image, Rect2i(p, Vector2i(13, 11)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(9, 2)), SCREEN)
	for row: int in range(2):
		for column: int in range(3):
			image.fill_rect(Rect2i(p + Vector2i(2 + column * 3, 6 + row * 2), Vector2i(2, 1)), PAPER_SHADE if row == 0 else STEEL_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(10, 8), Vector2i(1, 2)), BURGUNDY)

static func _keypad_vertical(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(9, 14)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(2, 10)), SCREEN)
	for column: int in range(2):
		for row: int in range(3):
			image.fill_rect(Rect2i(p + Vector2i(5 + column * 2, 2 + row * 3), Vector2i(1, 2)), PAPER_SHADE if column == 0 else STEEL_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(6, 11), Vector2i(2, 1)), BURGUNDY)

static func _trays_horizontal(image: Image, p: Vector2i) -> void:
	# Framed two-tier receipt trays with blank slips and no transaction values.
	image.fill_rect(Rect2i(p + Vector2i(0, 2), Vector2i(24, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(0, 7), Vector2i(24, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 4), Vector2i(2, 3)), STEEL_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(21, 4), Vector2i(2, 3)), STEEL)
	_box(image, Rect2i(p + Vector2i(3, 0), Vector2i(14, 5)), PAPER)
	_box(image, Rect2i(p + Vector2i(7, 4), Vector2i(14, 4)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(4, 1), Vector2i(3, 1)), BRASS)
	image.fill_rect(Rect2i(p + Vector2i(17, 5), Vector2i(3, 1)), BURGUNDY)

static func _trays_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 0), Vector2i(2, 24)), INK)
	image.fill_rect(Rect2i(p + Vector2i(7, 0), Vector2i(2, 24)), INK)
	image.fill_rect(Rect2i(p + Vector2i(4, 1), Vector2i(3, 2)), STEEL_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(4, 21), Vector2i(3, 2)), STEEL)
	_box(image, Rect2i(p, Vector2i(5, 14)), PAPER)
	_box(image, Rect2i(p + Vector2i(4, 7), Vector2i(4, 14)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(1, 3), Vector2i(1, 3)), BRASS)
	image.fill_rect(Rect2i(p + Vector2i(5, 17), Vector2i(1, 3)), BURGUNDY)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name): return result
	var spec: Dictionary = specs[object_name]
	var p: Vector2i = spec.origin
	var horizontal := str(spec.axis) == "horizontal"
	match object_name:
		"ledger_folio":
			if horizontal: _ledger_horizontal(result, p)
			else: _ledger_vertical(result, p)
		"keypad_device":
			if horizontal: _keypad_horizontal(result, p)
			else: _keypad_vertical(result, p)
		"receipt_trays":
			if horizontal: _trays_horizontal(result, p)
			else: _trays_vertical(result, p)
	return result

static func binary_over(rear: Image, front: Image) -> Image:
	var result := rear.get_data().duplicate()
	var near := front.get_data()
	for at: int in range(0, result.size(), 4):
		if near[at + 3] != 0:
			for channel: int in range(4): result[at + channel] = near[at + channel]
	return Image.create_from_data(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8, result)

static func layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {"surface_decor_rear": _image(), "surface_decor_front": _image()}
	var specs := specifications(side)
	for object_name: String in OBJECTS:
		if not specs.has(object_name): continue
		var layer_name := str(specs[object_name].layer)
		result[layer_name] = binary_over(result[layer_name], object_image(side, object_name))
	return result

static func whole(side: String) -> Image:
	var parts := layers(side)
	return binary_over(parts.surface_decor_rear, parts.surface_decor_front)

static func layer_depth(side: String, layer_name: String) -> int:
	if side == "south": return 2 if layer_name == "surface_decor_rear" else 4
	if layer_name == "surface_decor_rear": return 0
	return 3 if side in ["east", "west"] else 2

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "FinanceAccounts" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/finance-accounts-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
