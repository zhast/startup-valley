class_name TheoCampaignKitGeometry
extends RefCounted
## DEV ONLY. Deterministic native desk-surface decor for Theo.
## Every facing below declares its own screen-space placement. No completed
## bitmap is rotated, mirrored, scaled, or reused as another facing.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["campaign_cards", "audience_notes", "creative_thumbnail_sheet"]
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
const GREEN := Color("83ab56")
const CHARTREUSE := Color("c1fa81")
const VERMILION := Color("fa4616")

static func specifications(side: String) -> Dictionary:
	# Positions are native canvas coordinates. The physical arrangement follows
	# Theo's gaze, while upper-left screen lighting remains fixed in every view.
	match side:
		"north":
			return {
				"campaign_cards": {"layer": "surface_decor_rear", "origin": Vector2i(51, 117), "axis": "horizontal"},
				"audience_notes": {"layer": "surface_decor_rear", "origin": Vector2i(113, 118), "axis": "horizontal"},
				"creative_thumbnail_sheet": {"layer": "surface_decor_front", "origin": Vector2i(50, 132), "axis": "horizontal"},
			}
		"east":
			return {
				"campaign_cards": {"layer": "surface_decor_rear", "origin": Vector2i(82, 83), "axis": "vertical"},
				"audience_notes": {"layer": "surface_decor_front", "origin": Vector2i(100, 158), "axis": "vertical"},
				"creative_thumbnail_sheet": {"layer": "surface_decor_rear", "origin": Vector2i(99, 82), "axis": "vertical"},
			}
		"south":
			return {
				"campaign_cards": {"layer": "surface_decor_rear", "origin": Vector2i(125, 117), "axis": "horizontal"},
				"audience_notes": {"layer": "surface_decor_rear", "origin": Vector2i(53, 118), "axis": "horizontal"},
				"creative_thumbnail_sheet": {"layer": "surface_decor_front", "origin": Vector2i(122, 132), "axis": "horizontal"},
			}
		"west":
			return {
				"campaign_cards": {"layer": "surface_decor_front", "origin": Vector2i(100, 158), "axis": "vertical"},
				"audience_notes": {"layer": "surface_decor_rear", "origin": Vector2i(82, 83), "axis": "vertical"},
				"creative_thumbnail_sheet": {"layer": "surface_decor_rear", "origin": Vector2i(99, 82), "axis": "vertical"},
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

static func _campaign_cards_horizontal(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(14, 7)), INK)
	_box(image, Rect2i(p + Vector2i(0, 1), Vector2i(11, 7)), PAPER_SHADE)
	_box(image, Rect2i(p + Vector2i(3, 0), Vector2i(11, 7)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(4, 1), Vector2i(8, 1)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(10, 4), Vector2i(3, 2)), VERMILION)
	image.fill_rect(Rect2i(p + Vector2i(1, 5), Vector2i(3, 2)), INDIGO)

static func _campaign_cards_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(7, 14)), INK)
	_box(image, Rect2i(p + Vector2i(1, 0), Vector2i(7, 11)), PAPER_SHADE)
	_box(image, Rect2i(p + Vector2i(0, 3), Vector2i(7, 11)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 4), Vector2i(1, 8)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(4, 10), Vector2i(2, 3)), VERMILION)
	image.fill_rect(Rect2i(p + Vector2i(5, 1), Vector2i(2, 3)), INDIGO)

static func _audience_notes_horizontal(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(15, 10)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(13, 1)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(1, 7), Vector2i(13, 2)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(3, 3), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(2, 5), Vector2i(4, 2)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(10, 3), Vector2i(2, 2)), CHARTREUSE)
	image.fill_rect(Rect2i(p + Vector2i(9, 5), Vector2i(4, 2)), GREEN)

static func _audience_notes_vertical(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(10, 15)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(1, 13)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(7, 1), Vector2i(2, 13)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(3, 3), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(2, 5), Vector2i(4, 2)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(3, 10), Vector2i(2, 2)), CHARTREUSE)
	image.fill_rect(Rect2i(p + Vector2i(2, 12), Vector2i(4, 2)), GREEN)

static func _thumbnail_sheet_horizontal(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(20, 10)), PAPER)
	var colors: Array[Color] = [CERULEAN, GREEN, VERMILION]
	for index: int in range(3):
		var q := p + Vector2i(2 + index * 6, 2)
		image.fill_rect(Rect2i(q, Vector2i(5, 6)), INK)
		image.fill_rect(Rect2i(q + Vector2i.ONE, Vector2i(3, 2)), colors[index])
		image.fill_rect(Rect2i(q + Vector2i(1, 4), Vector2i(3, 1)), PAPER_LIGHT)

static func _thumbnail_sheet_vertical(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(10, 20)), PAPER)
	var colors: Array[Color] = [CERULEAN, GREEN, VERMILION]
	for index: int in range(3):
		var q := p + Vector2i(2, 2 + index * 6)
		image.fill_rect(Rect2i(q, Vector2i(6, 5)), INK)
		image.fill_rect(Rect2i(q + Vector2i.ONE, Vector2i(2, 3)), colors[index])
		image.fill_rect(Rect2i(q + Vector2i(4, 1), Vector2i(1, 3)), PAPER_LIGHT)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name): return result
	var spec: Dictionary = specs[object_name]
	var p: Vector2i = spec.origin
	var horizontal := str(spec.axis) == "horizontal"
	match object_name:
		"campaign_cards":
			if horizontal: _campaign_cards_horizontal(result, p)
			else: _campaign_cards_vertical(result, p)
		"audience_notes":
			if horizontal: _audience_notes_horizontal(result, p)
			else: _audience_notes_vertical(result, p)
		"creative_thumbnail_sheet":
			if horizontal: _thumbnail_sheet_horizontal(result, p)
			else: _thumbnail_sheet_vertical(result, p)
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
	# above that wood while still preserving a rear/actor/front depth sandwich.
	if side == "south": return 2 if layer_name == "surface_decor_rear" else 4
	if layer_name == "surface_decor_rear": return 0
	return 3 if side in ["east", "west"] else 2

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/theo-campaign-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
