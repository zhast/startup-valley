class_name GrowthAnalyticsKitGeometry
extends RefCounted
## DEV ONLY. Deterministic native measurement decor for Theo's accepted desk.
## Every facing is independently authored in screen space; no completed bitmap
## is rotated, mirrored, scaled, or reused as another facing.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["measurement_console", "attribution_test_notes", "comparison_overlay"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("282622")
const CONSOLE := Color("454540")
const STEEL_LIGHT := Color("77746b")
const SCREEN := Color("253667")
const CERULEAN := Color("6196c1")
const TEAL := Color("3d8c8a")
const CYAN := Color("79c7c5")
const AMBER := Color("d1a369")
const CORAL := Color("e46b4d")
const PAPER := Color("eee2c8")
const PAPER_SHADE := Color("c7b999")

static func specifications(side: String) -> Dictionary:
	# Native coordinates follow Theo's gaze; highlights remain screen-upper-left.
	match side:
		"north":
			return {
				"measurement_console": {"layer": "surface_decor_rear", "origin": Vector2i(50, 115), "axis": "horizontal"},
				"attribution_test_notes": {"layer": "surface_decor_rear", "origin": Vector2i(116, 119), "axis": "horizontal"},
				"comparison_overlay": {"layer": "surface_decor_front", "origin": Vector2i(50, 133), "axis": "horizontal"},
			}
		"east":
			return {
				"measurement_console": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical"},
				"attribution_test_notes": {"layer": "surface_decor_rear", "origin": Vector2i(101, 85), "axis": "vertical"},
				"comparison_overlay": {"layer": "surface_decor_front", "origin": Vector2i(102, 146), "axis": "vertical"},
			}
		"south":
			return {
				"measurement_console": {"layer": "surface_decor_rear", "origin": Vector2i(117, 117), "axis": "horizontal"},
				"attribution_test_notes": {"layer": "surface_decor_rear", "origin": Vector2i(53, 119), "axis": "horizontal"},
				"comparison_overlay": {"layer": "surface_decor_front", "origin": Vector2i(116, 133), "axis": "horizontal"},
			}
		"west":
			return {
				"measurement_console": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical"},
				"attribution_test_notes": {"layer": "surface_decor_rear", "origin": Vector2i(101, 86), "axis": "vertical"},
				"comparison_overlay": {"layer": "surface_decor_front", "origin": Vector2i(100, 148), "axis": "vertical"},
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

static func _measurement_console_horizontal(image: Image, p: Vector2i) -> void:
	# A compact physical instrument. Abstract traces contain no labels or values.
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(23, 9)), INK)
	_box(image, Rect2i(p, Vector2i(24, 10)), CONSOLE)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(20, 1)), STEEL_LIGHT)
	_box(image, Rect2i(p + Vector2i(3, 4), Vector2i(13, 5)), SCREEN)
	image.fill_rect(Rect2i(p + Vector2i(5, 7), Vector2i(3, 1)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(8, 6), Vector2i(3, 1)), CYAN)
	image.fill_rect(Rect2i(p + Vector2i(11, 5), Vector2i(3, 1)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(18, 4), Vector2i(2, 2)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(21, 4), Vector2i(2, 2)), CORAL)
	image.fill_rect(Rect2i(p + Vector2i(18, 8), Vector2i(5, 1)), INK)

static func _measurement_console_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(9, 23)), INK)
	_box(image, Rect2i(p, Vector2i(10, 24)), CONSOLE)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(1, 20)), STEEL_LIGHT)
	_box(image, Rect2i(p + Vector2i(4, 3), Vector2i(5, 13)), SCREEN)
	image.fill_rect(Rect2i(p + Vector2i(7, 5), Vector2i(1, 3)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(6, 8), Vector2i(1, 3)), CYAN)
	image.fill_rect(Rect2i(p + Vector2i(5, 11), Vector2i(1, 3)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(4, 18), Vector2i(2, 2)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(4, 21), Vector2i(2, 2)), CORAL)
	image.fill_rect(Rect2i(p + Vector2i(8, 18), Vector2i(1, 5)), INK)

static func _attribution_notes_horizontal(image: Image, p: Vector2i) -> void:
	# Linked test-source chips and a split swatch, never an audience/person card.
	_box(image, Rect2i(p, Vector2i(16, 9)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(14, 1)), PAPER_SHADE)
	_box(image, Rect2i(p + Vector2i(2, 4), Vector2i(4, 3)), CERULEAN)
	_box(image, Rect2i(p + Vector2i(10, 4), Vector2i(4, 3)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(6, 5), Vector2i(4, 1)), INK)
	image.fill_rect(Rect2i(p + Vector2i(7, 4), Vector2i(1, 1)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(8, 6), Vector2i(1, 2)), CORAL)

static func _attribution_notes_vertical(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(9, 16)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(1, 14)), PAPER_SHADE)
	_box(image, Rect2i(p + Vector2i(4, 2), Vector2i(3, 4)), CERULEAN)
	_box(image, Rect2i(p + Vector2i(4, 10), Vector2i(3, 4)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(5, 6), Vector2i(1, 4)), INK)
	image.fill_rect(Rect2i(p + Vector2i(4, 7), Vector2i(1, 1)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(6, 8), Vector2i(2, 1)), CORAL)

static func _comparison_overlay_horizontal(image: Image, p: Vector2i) -> void:
	# Sparse paired state traces suggest an optional changing overlay, not data.
	image.fill_rect(Rect2i(p + Vector2i(0, 5), Vector2i(24, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(2, 4)), INK)
	image.fill_rect(Rect2i(p + Vector2i(21, 1), Vector2i(2, 4)), INK)
	image.fill_rect(Rect2i(p + Vector2i(4, 3), Vector2i(5, 1)), CYAN)
	image.fill_rect(Rect2i(p + Vector2i(10, 2), Vector2i(4, 1)), CYAN)
	image.fill_rect(Rect2i(p + Vector2i(15, 3), Vector2i(5, 1)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(4, 1)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(14, 5), Vector2i(4, 1)), CORAL)

static func _comparison_overlay_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(5, 0), Vector2i(2, 24)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(4, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 21), Vector2i(4, 2)), INK)
	image.fill_rect(Rect2i(p + Vector2i(3, 4), Vector2i(1, 5)), CYAN)
	image.fill_rect(Rect2i(p + Vector2i(2, 10), Vector2i(1, 4)), CYAN)
	image.fill_rect(Rect2i(p + Vector2i(3, 15), Vector2i(1, 5)), TEAL)
	image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(1, 4)), AMBER)
	image.fill_rect(Rect2i(p + Vector2i(5, 14), Vector2i(1, 4)), CORAL)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name): return result
	var spec: Dictionary = specs[object_name]
	var p: Vector2i = spec.origin
	var horizontal := str(spec.axis) == "horizontal"
	match object_name:
		"measurement_console":
			if horizontal: _measurement_console_horizontal(result, p)
			else: _measurement_console_vertical(result, p)
		"attribution_test_notes":
			if horizontal: _attribution_notes_horizontal(result, p)
			else: _attribution_notes_vertical(result, p)
		"comparison_overlay":
			if horizontal: _comparison_overlay_horizontal(result, p)
			else: _comparison_overlay_vertical(result, p)
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
	# South desktop ink is at +1; rear/front remain ordered around the actor.
	if side == "south": return 2 if layer_name == "surface_decor_rear" else 4
	if layer_name == "surface_decor_rear": return 0
	return 3 if side in ["east", "west"] else 2

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "GrowthAnalytics" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/growth-analytics-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
