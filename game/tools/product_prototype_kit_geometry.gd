class_name ProductPrototypeKitGeometry
extends RefCounted
## DEV ONLY. Deterministic native product-making overlays for the accepted
## research-table host. Each facing is independently authored in screen space.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["prototype_fixture", "test_parts", "inspection_gauge"]
const CANVAS := Vector2i(192, 320)
const PIVOT := Vector2i(96, 240)
const SPRITE_OFFSET := Vector2i(0, -80)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("282622")
const STEEL := Color("454540")
const STEEL_LIGHT := Color("77746b")
const INDIGO := Color("354b98")
const CERULEAN := Color("6196c1")
const TEAL := Color("3d8c8a")
const AMBER := Color("d1a369")
const CORAL := Color("e46b4d")
const PARCHMENT := Color("eee2c8")

static func specifications(side: String) -> Dictionary:
	# Coordinates are native pixels on the accepted research-table canvas. The
	# fixture follows the worker's gaze; lighting remains screen-upper-left.
	match side:
		"north":
			return {
				"prototype_fixture": {"layer": "surface_decor_rear", "origin": Vector2i(45, 146), "axis": "horizontal"},
				"test_parts": {"layer": "surface_decor_rear", "origin": Vector2i(124, 148), "axis": "horizontal"},
				"inspection_gauge": {"layer": "surface_decor_front", "origin": Vector2i(84, 179), "axis": "horizontal"},
			}
		"east":
			return {
				"prototype_fixture": {"layer": "surface_decor_rear", "origin": Vector2i(101, 143), "axis": "vertical"},
				"test_parts": {"layer": "surface_decor_rear", "origin": Vector2i(72, 170), "axis": "vertical"},
				"inspection_gauge": {"layer": "surface_decor_front", "origin": Vector2i(101, 180), "axis": "vertical"},
			}
		"south":
			return {
				"prototype_fixture": {"layer": "surface_decor_rear", "origin": Vector2i(45, 146), "axis": "horizontal"},
				"test_parts": {"layer": "surface_decor_rear", "origin": Vector2i(126, 149), "axis": "horizontal"},
				"inspection_gauge": {"layer": "surface_decor_front", "origin": Vector2i(84, 186), "axis": "horizontal"},
			}
		"west":
			return {
				"prototype_fixture": {"layer": "surface_decor_rear", "origin": Vector2i(55, 143), "axis": "vertical"},
				"test_parts": {"layer": "surface_decor_rear", "origin": Vector2i(122, 170), "axis": "vertical"},
				"inspection_gauge": {"layer": "surface_decor_front", "origin": Vector2i(101, 180), "axis": "vertical"},
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

static func _prototype_fixture_horizontal(image: Image, p: Vector2i) -> void:
	# Bench-top assembly jig: steel bed, two clamps and a bright test body.
	image.fill_rect(Rect2i(p + Vector2i(2, 3), Vector2i(28, 12)), INK)
	_box(image, Rect2i(p, Vector2i(30, 13)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(26, 1)), STEEL_LIGHT)
	_box(image, Rect2i(p + Vector2i(5, 4), Vector2i(20, 6)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(11, 5), Vector2i(8, 4)), CORAL)
	image.fill_rect(Rect2i(p + Vector2i(2, 5), Vector2i(4, 5)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(24, 5), Vector2i(4, 5)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(13, 3), Vector2i(4, 2)), CERULEAN)

static func _prototype_fixture_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(3, 2), Vector2i(12, 28)), INK)
	_box(image, Rect2i(p, Vector2i(13, 30)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(1, 26)), STEEL_LIGHT)
	_box(image, Rect2i(p + Vector2i(4, 5), Vector2i(6, 20)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(5, 11), Vector2i(4, 8)), CORAL)
	image.fill_rect(Rect2i(p + Vector2i(5, 2), Vector2i(5, 4)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(5, 24), Vector2i(5, 4)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(3, 13), Vector2i(2, 4)), CERULEAN)

static func _test_parts_horizontal(image: Image, p: Vector2i) -> void:
	# Three physical fit-test parts; gaps and profiles keep them unlike note cards.
	_box(image, Rect2i(p + Vector2i(0, 2), Vector2i(5, 8)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(3, 2)), TEAL)
	_box(image, Rect2i(p + Vector2i(7, 0), Vector2i(6, 7)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(9, 6), Vector2i(2, 4)), INK)
	_box(image, Rect2i(p + Vector2i(15, 2), Vector2i(5, 9)), CORAL)
	image.fill_rect(Rect2i(p + Vector2i(16, 4), Vector2i(3, 2)), PARCHMENT)

static func _test_parts_vertical(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p + Vector2i(2, 0), Vector2i(8, 5)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(2, 3)), TEAL)
	_box(image, Rect2i(p + Vector2i(0, 7), Vector2i(7, 6)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(6, 9), Vector2i(4, 2)), INK)
	_box(image, Rect2i(p + Vector2i(2, 15), Vector2i(9, 5)), CORAL)
	image.fill_rect(Rect2i(p + Vector2i(4, 16), Vector2i(2, 3)), PARCHMENT)

static func _inspection_gauge_horizontal(image: Image, p: Vector2i) -> void:
	# Small dial-and-probe cue; the abstract needle carries no numeric claim.
	image.fill_rect(Rect2i(p + Vector2i(7, 3), Vector2i(19, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(10, 2), Vector2i(15, 1)), STEEL_LIGHT)
	_box(image, Rect2i(p, Vector2i(8, 8)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(4, 4)), PARCHMENT)
	image.fill_rect(Rect2i(p + Vector2i(4, 2), Vector2i(1, 3)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(25, 1), Vector2i(2, 6)), INK)
	image.fill_rect(Rect2i(p + Vector2i(28, 0), Vector2i(2, 3)), INK)
	image.fill_rect(Rect2i(p + Vector2i(28, 5), Vector2i(2, 3)), INK)

static func _inspection_gauge_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(3, 7), Vector2i(2, 19)), INK)
	image.fill_rect(Rect2i(p + Vector2i(2, 10), Vector2i(1, 15)), STEEL_LIGHT)
	_box(image, Rect2i(p, Vector2i(8, 8)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(4, 4)), PARCHMENT)
	image.fill_rect(Rect2i(p + Vector2i(2, 4), Vector2i(3, 1)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(1, 25), Vector2i(6, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(0, 28), Vector2i(3, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(5, 28), Vector2i(3, 2)), INK)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name): return result
	var spec: Dictionary = specs[object_name]
	var p: Vector2i = spec.origin
	var horizontal := str(spec.axis) == "horizontal"
	match object_name:
		"prototype_fixture":
			if horizontal: _prototype_fixture_horizontal(result, p)
			else: _prototype_fixture_vertical(result, p)
		"test_parts":
			if horizontal: _test_parts_horizontal(result, p)
			else: _test_parts_vertical(result, p)
		"inspection_gauge":
			if horizontal: _inspection_gauge_horizontal(result, p)
			else: _inspection_gauge_vertical(result, p)
	return result

static func binary_over(rear: Image, front: Image) -> Image:
	var back := rear.get_data()
	var near := front.get_data()
	var result := back.duplicate()
	for at: int in range(0, result.size(), 4):
		if near[at + 3] != 0:
			for channel: int in range(4): result[at + channel] = near[at + channel]
	return Image.create_from_data(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8, result)

static func layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {
		"surface_decor_rear": _image(),
		"surface_decor_front": _image(),
	}
	var specs := specifications(side)
	for object_name: String in OBJECTS:
		if not specs.has(object_name): continue
		var target: Image = result[str(specs[object_name].layer)]
		result[str(specs[object_name].layer)] = binary_over(target, object_image(side, object_name))
	return result

static func whole(side: String) -> Image:
	var parts := layers(side)
	return binary_over(parts.surface_decor_rear, parts.surface_decor_front)

static func layer_depth(side: String, layer_name: String) -> int:
	# The accepted research base uses a far rear/tool plane for South and a
	# prop-locked actor depth in all views. These values preserve rear/actor/front.
	if layer_name == "surface_decor_rear": return -38 if side == "south" else -1
	return 3 if side == "north" else 2

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "ProductPrototype" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/product-prototype-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
