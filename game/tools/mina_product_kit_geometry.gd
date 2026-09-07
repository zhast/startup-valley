class_name MinaProductKitGeometry
extends RefCounted
## DEV ONLY. Deterministic native desk-surface product/research tools for Mina.
## Every facing declares its own screen-space placement. No completed bitmap is
## rotated, mirrored, scaled, or reused as another facing.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["insight_notebook", "prototype_wireframes", "testing_tokens"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("282622")
const PAPER := Color("ece3ca")
const PAPER_LIGHT := Color("f1f1f1")
const PAPER_SHADE := Color("c7b999")
const INDIGO := Color("253667")
const CERULEAN := Color("6196c1")
const MINT := Color("7fbf9b")
const LILAC := Color("8b78ad")
const GOLD := Color("d1a369")

static func specifications(side: String) -> Dictionary:
	# Positions are native canvas coordinates. The physical tool arrangement
	# follows Mina's gaze while upper-left screen lighting remains fixed.
	match side:
		"north":
			return {
				"insight_notebook": {"layer": "surface_decor_rear", "origin": Vector2i(50, 117), "axis": "horizontal"},
				"prototype_wireframes": {"layer": "surface_decor_front", "origin": Vector2i(52, 132), "axis": "horizontal"},
				"testing_tokens": {"layer": "surface_decor_rear", "origin": Vector2i(116, 119), "axis": "horizontal"},
			}
		"east":
			return {
				"insight_notebook": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical"},
				"prototype_wireframes": {"layer": "surface_decor_front", "origin": Vector2i(100, 148), "axis": "vertical"},
				"testing_tokens": {"layer": "surface_decor_rear", "origin": Vector2i(102, 84), "axis": "vertical"},
			}
		"south":
			return {
				"insight_notebook": {"layer": "surface_decor_rear", "origin": Vector2i(117, 117), "axis": "horizontal"},
				"prototype_wireframes": {"layer": "surface_decor_front", "origin": Vector2i(114, 132), "axis": "horizontal"},
				"testing_tokens": {"layer": "surface_decor_rear", "origin": Vector2i(55, 119), "axis": "horizontal"},
			}
		"west":
			return {
				"insight_notebook": {"layer": "surface_decor_rear", "origin": Vector2i(99, 149), "axis": "vertical"},
				"prototype_wireframes": {"layer": "surface_decor_front", "origin": Vector2i(100, 82), "axis": "vertical"},
				"testing_tokens": {"layer": "surface_decor_rear", "origin": Vector2i(82, 84), "axis": "vertical"},
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

static func _insight_notebook_horizontal(image: Image, p: Vector2i) -> void:
	# Open research notebook: affinity dots on the left, a tiny lens on the right.
	image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(22, 9)), PAPER_SHADE)
	_box(image, Rect2i(p, Vector2i(12, 10)), PAPER)
	_box(image, Rect2i(p + Vector2i(12, 0), Vector2i(12, 10)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(11, 1), Vector2i(2, 8)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(10, 1)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(13, 1), Vector2i(10, 1)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(3, 4), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(7, 3), Vector2i(2, 2)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(7, 7), Vector2i(2, 2)), LILAC)
	image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(3, 1)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(16, 3), Vector2i(5, 5)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(17, 4), Vector2i(3, 3)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(20, 7), Vector2i(2, 2)), INDIGO)

static func _insight_notebook_vertical(image: Image, p: Vector2i) -> void:
	# Independently authored vertical notebook, retaining fixed screen lighting.
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(9, 22)), PAPER_SHADE)
	_box(image, Rect2i(p, Vector2i(10, 12)), PAPER)
	_box(image, Rect2i(p + Vector2i(0, 12), Vector2i(10, 12)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 11), Vector2i(8, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(1, 10)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(1, 13), Vector2i(1, 10)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(4, 3), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(3, 7), Vector2i(2, 2)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(7, 7), Vector2i(2, 2)), LILAC)
	image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(1, 3)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(3, 16), Vector2i(5, 5)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(4, 17), Vector2i(3, 3)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(7, 20), Vector2i(2, 2)), INDIGO)

static func _prototype_wireframes_horizontal(image: Image, p: Vector2i) -> void:
	# A connected flow of product-screen wireframes, not campaign thumbnails.
	_box(image, Rect2i(p, Vector2i(8, 10)), PAPER)
	_box(image, Rect2i(p + Vector2i(17, 0), Vector2i(8, 10)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(4, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(2, 5), Vector2i(2, 3)), LILAC)
	image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(1, 3)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(19, 2), Vector2i(4, 1)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(19, 4), Vector2i(4, 4)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(8, 4), Vector2i(9, 2)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(14, 3), Vector2i(3, 1)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(14, 6), Vector2i(3, 1)), INDIGO)

static func _prototype_wireframes_vertical(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(10, 7)), PAPER)
	_box(image, Rect2i(p + Vector2i(0, 13), Vector2i(10, 7)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(2, 3)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(5, 2), Vector2i(3, 2)), LILAC)
	image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(3, 1)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(2, 15), Vector2i(1, 3)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(4, 15), Vector2i(4, 3)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(4, 7), Vector2i(2, 6)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(3, 10), Vector2i(1, 3)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(6, 10), Vector2i(1, 3)), INDIGO)

static func _testing_tokens_horizontal(image: Image, p: Vector2i) -> void:
	# Three chunky prototype material/test samples with distinct silhouettes.
	image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(4, 5)), INK)
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(2, 1)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(2, 3), Vector2i(2, 3)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(6, 1), Vector2i(5, 6)), INK)
	image.fill_rect(Rect2i(p + Vector2i(7, 2), Vector2i(3, 4)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(12, 2), Vector2i(4, 5)), INK)
	image.fill_rect(Rect2i(p + Vector2i(13, 1), Vector2i(2, 1)), GOLD)
	image.fill_rect(Rect2i(p + Vector2i(13, 3), Vector2i(2, 3)), GOLD)

static func _testing_tokens_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(5, 4)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(1, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(3, 2), Vector2i(3, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(1, 6), Vector2i(6, 5)), INK)
	image.fill_rect(Rect2i(p + Vector2i(2, 7), Vector2i(4, 3)), MINT)
	image.fill_rect(Rect2i(p + Vector2i(2, 12), Vector2i(5, 4)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 13), Vector2i(1, 2)), GOLD)
	image.fill_rect(Rect2i(p + Vector2i(3, 13), Vector2i(3, 2)), GOLD)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name): return result
	var spec: Dictionary = specs[object_name]
	var p: Vector2i = spec.origin
	var horizontal := str(spec.axis) == "horizontal"
	match object_name:
		"insight_notebook":
			if horizontal: _insight_notebook_horizontal(result, p)
			else: _insight_notebook_vertical(result, p)
		"prototype_wireframes":
			if horizontal: _prototype_wireframes_horizontal(result, p)
			else: _prototype_wireframes_vertical(result, p)
		"testing_tokens":
			if horizontal: _testing_tokens_horizontal(result, p)
			else: _testing_tokens_vertical(result, p)
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
		var object := object_image(side, object_name)
		result[str(specs[object_name].layer)] = binary_over(target, object)
	return result

static func whole(side: String) -> Image:
	var parts := layers(side)
	return binary_over(parts.surface_decor_rear, parts.surface_decor_front)

static func layer_depth(side: String, layer_name: String) -> int:
	# The accepted South desktop belongs to DeskFront at +1; its decor must sit
	# above that wood while preserving a rear/actor/front depth sandwich.
	if side == "south": return 2 if layer_name == "surface_decor_rear" else 4
	if layer_name == "surface_decor_rear": return 0
	return 3 if side in ["east", "west"] else 2

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "MinaProduct" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/mina-product-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
