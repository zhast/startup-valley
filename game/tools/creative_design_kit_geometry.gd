class_name CreativeDesignKitGeometry
extends RefCounted
## DEV ONLY. Deterministic passive creative-design surface decor for the
## accepted workstations-v2 desk. Every facing is authored directly in screen
## coordinates. No complete raster is rotated, mirrored, flipped, or scaled.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["pen_display", "swatch_fan", "stylus_tool_tray"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []
const HISTORICAL_NORTH_SOURCE := "res://assets/source/overnight-20260904/roles/creative-north-v1.png"
const HISTORICAL_NORTH_PROMPT := "res://../dev/art-catalogue/prompts/creative-north-v1.md"
const HISTORICAL_NORTH_REVIEW := "res://../dev/art-catalogue/CREATIVE_NORTH_REVIEW.md"
const HISTORICAL_NORTH_COMPOSITION_REVIEW := "res://../dev/art-catalogue/CREATIVE_NORTH_COMPOSITION_REVIEW.md"

const INK := Color("282622")
const BEZEL := Color("454540")
const BEZEL_LIGHT := Color("77746b")
const SCREEN := Color("253667")
const CERULEAN := Color("6196c1")
const PAPER := Color("ece3ca")
const PAPER_SHADE := Color("c7b999")
const METAL := Color("9e9b8f")
const VERMILION := Color("fa4616")
const CHARTREUSE := Color("c1fa81")
const GREEN := Color("83ab56")
const GOLD := Color("e0a247")

static func specifications(side: String) -> Dictionary:
	# Coordinates include side-specific stand/tool exposure and fixed upper-left
	# highlights. These are four declarations, not transformed finished views.
	match side:
		"north":
			return {
				"pen_display": {"layer": "surface_decor_front", "origin": Vector2i(50, 124), "axis": "horizontal"},
				"swatch_fan": {"layer": "surface_decor_rear", "origin": Vector2i(122, 115), "axis": "horizontal"},
				"stylus_tool_tray": {"layer": "surface_decor_front", "origin": Vector2i(119, 134), "axis": "horizontal"},
			}
		"east":
			return {
				"pen_display": {"layer": "surface_decor_rear", "origin": Vector2i(93, 82), "axis": "vertical"},
				"swatch_fan": {"layer": "surface_decor_front", "origin": Vector2i(97, 148), "axis": "vertical"},
				"stylus_tool_tray": {"layer": "surface_decor_front", "origin": Vector2i(83, 157), "axis": "vertical"},
			}
		"south":
			return {
				"pen_display": {"layer": "surface_decor_rear", "origin": Vector2i(114, 125), "axis": "horizontal"},
				"swatch_fan": {"layer": "surface_decor_rear", "origin": Vector2i(50, 115), "axis": "horizontal"},
				"stylus_tool_tray": {"layer": "surface_decor_front", "origin": Vector2i(50, 134), "axis": "horizontal"},
			}
		"west":
			return {
				"pen_display": {"layer": "surface_decor_front", "origin": Vector2i(82, 148), "axis": "vertical"},
				"swatch_fan": {"layer": "surface_decor_rear", "origin": Vector2i(97, 83), "axis": "vertical"},
				"stylus_tool_tray": {"layer": "surface_decor_rear", "origin": Vector2i(83, 83), "axis": "vertical"},
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

static func _screen_marks_horizontal(image: Image, p: Vector2i, side: String) -> void:
	# Abstract blocks are a blank design canvas, never glyphs, labels, or metrics.
	image.fill_rect(Rect2i(p + Vector2i(3, 2), Vector2i(8, 1)), CERULEAN)
	if side == "north":
		image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(5, 4)), VERMILION)
		image.fill_rect(Rect2i(p + Vector2i(10, 4), Vector2i(6, 5)), CHARTREUSE)
		image.fill_rect(Rect2i(p + Vector2i(17, 6), Vector2i(5, 3)), GREEN)
	else:
		image.fill_rect(Rect2i(p + Vector2i(4, 6), Vector2i(6, 3)), GREEN)
		image.fill_rect(Rect2i(p + Vector2i(11, 4), Vector2i(4, 5)), VERMILION)
		image.fill_rect(Rect2i(p + Vector2i(16, 5), Vector2i(6, 4)), CHARTREUSE)

static func _screen_marks_vertical(image: Image, p: Vector2i, side: String) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 3), Vector2i(1, 7)), CERULEAN)
	if side == "east":
		image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(4, 5)), CHARTREUSE)
		image.fill_rect(Rect2i(p + Vector2i(4, 11), Vector2i(5, 4)), VERMILION)
		image.fill_rect(Rect2i(p + Vector2i(6, 16), Vector2i(3, 4)), GREEN)
	else:
		image.fill_rect(Rect2i(p + Vector2i(4, 4), Vector2i(5, 4)), GREEN)
		image.fill_rect(Rect2i(p + Vector2i(6, 9), Vector2i(3, 6)), VERMILION)
		image.fill_rect(Rect2i(p + Vector2i(4, 16), Vector2i(5, 3)), CHARTREUSE)

static func _pen_display(image: Image, p: Vector2i, side: String) -> void:
	if side in ["north", "south"]:
		if side == "south":
			image.fill_rect(Rect2i(p + Vector2i(8, -4), Vector2i(12, 2)), INK)
			image.fill_rect(Rect2i(p + Vector2i(11, -2), Vector2i(6, 3)), BEZEL_LIGHT)
		_box(image, Rect2i(p, Vector2i(28, 14)), BEZEL)
		image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(24, 9)), SCREEN)
		_screen_marks_horizontal(image, p, side)
		if side == "north":
			image.fill_rect(Rect2i(p + Vector2i(11, 13), Vector2i(6, 2)), BEZEL_LIGHT)
			image.fill_rect(Rect2i(p + Vector2i(8, 15), Vector2i(12, 2)), INK)
	else:
		if side == "east":
			image.fill_rect(Rect2i(p + Vector2i(-4, 6), Vector2i(2, 12)), INK)
			image.fill_rect(Rect2i(p + Vector2i(-2, 9), Vector2i(3, 6)), BEZEL_LIGHT)
		_box(image, Rect2i(p, Vector2i(14, 24)), BEZEL)
		image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(9, 20)), SCREEN)
		_screen_marks_vertical(image, p, side)
		if side == "west":
			image.fill_rect(Rect2i(p + Vector2i(13, 9), Vector2i(3, 6)), BEZEL_LIGHT)
			image.fill_rect(Rect2i(p + Vector2i(15, 6), Vector2i(2, 12)), INK)

static func _swatch_card(image: Image, rect: Rect2i, color: Color) -> void:
	_box(image, rect, PAPER)
	image.fill_rect(Rect2i(rect.position + Vector2i(1, 1), Vector2i(rect.size.x - 2, 3)), color)
	image.set_pixelv(rect.position + Vector2i(1, rect.size.y - 2), PAPER_SHADE)

static func _swatch_fan(image: Image, p: Vector2i, side: String) -> void:
	match side:
		"north":
			_swatch_card(image, Rect2i(p + Vector2i(0, 4), Vector2i(7, 8)), VERMILION)
			_swatch_card(image, Rect2i(p + Vector2i(4, 2), Vector2i(7, 9)), CHARTREUSE)
			_swatch_card(image, Rect2i(p + Vector2i(8, 0), Vector2i(7, 10)), CERULEAN)
			image.fill_rect(Rect2i(p + Vector2i(5, 6), Vector2i(2, 2)), METAL)
		"south":
			_swatch_card(image, Rect2i(p + Vector2i(0, 0), Vector2i(7, 9)), GREEN)
			_swatch_card(image, Rect2i(p + Vector2i(3, 3), Vector2i(7, 9)), VERMILION)
			_swatch_card(image, Rect2i(p + Vector2i(7, 1), Vector2i(7, 10)), GOLD)
			image.fill_rect(Rect2i(p + Vector2i(6, 5), Vector2i(2, 2)), METAL)
		"east":
			_swatch_card(image, Rect2i(p + Vector2i(4, 0), Vector2i(8, 7)), CERULEAN)
			_swatch_card(image, Rect2i(p + Vector2i(2, 4), Vector2i(9, 7)), VERMILION)
			_swatch_card(image, Rect2i(p + Vector2i(0, 8), Vector2i(10, 7)), GREEN)
			image.fill_rect(Rect2i(p + Vector2i(5, 6), Vector2i(2, 2)), METAL)
		"west":
			_swatch_card(image, Rect2i(p + Vector2i(0, 0), Vector2i(9, 7)), CHARTREUSE)
			_swatch_card(image, Rect2i(p + Vector2i(3, 4), Vector2i(9, 7)), GREEN)
			_swatch_card(image, Rect2i(p + Vector2i(1, 8), Vector2i(10, 7)), VERMILION)
			image.fill_rect(Rect2i(p + Vector2i(5, 5), Vector2i(2, 2)), METAL)

static func _stylus_tool_tray(image: Image, p: Vector2i, side: String) -> void:
	if side in ["north", "south"]:
		_box(image, Rect2i(p, Vector2i(22, 7)), BEZEL)
		image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(15, 1)), METAL)
		image.fill_rect(Rect2i(p + Vector2i(4, 4), Vector2i(16, 1)), GOLD)
		image.set_pixelv(p + Vector2i(18 if side == "north" else 2, 2), CERULEAN)
		image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(7, 1)), BEZEL_LIGHT)
	else:
		_box(image, Rect2i(p, Vector2i(7, 16)), BEZEL)
		image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(1, 11)), METAL)
		image.fill_rect(Rect2i(p + Vector2i(4, 1), Vector2i(1, 13)), GOLD)
		image.set_pixelv(p + Vector2i(2, 13 if side == "east" else 2), CERULEAN)
		image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(1, 6)), BEZEL_LIGHT)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name):
		return result
	var p: Vector2i = specs[object_name].origin
	match object_name:
		"pen_display": _pen_display(result, p, side)
		"swatch_fan": _swatch_fan(result, p, side)
		"stylus_tool_tray": _stylus_tool_tray(result, p, side)
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
		"name": "CreativeDesign" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/creative-design-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
