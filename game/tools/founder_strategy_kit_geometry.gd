class_name FounderStrategyKitGeometry
extends RefCounted
## DEV ONLY. Four independently placed screen-axis views of static founder
## planning decor. No completed raster is rotated, mirrored, scaled or reused.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["open_roadmap_notebook", "small_planning_cards", "decision_folder"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("282622")
const PAPER := Color("ece3ca")
const PAPER_LIGHT := Color("f1f1f1")
const PAPER_SHADE := Color("c7b999")
const FOLDER := Color("b98544")
const FOLDER_LIGHT := Color("d1a369")
const INDIGO := Color("253667")
const CERULEAN := Color("6196c1")
const GREEN := Color("83ab56")
const CHARTREUSE := Color("c1fa81")
const VERMILION := Color("fa4616")

static func specifications(side: String) -> Dictionary:
	# Native canvas coordinates, authored separately for each host-gaze view.
	match side:
		"north": return {
			"open_roadmap_notebook": {"layer": "surface_decor_front", "origin": Vector2i(50, 131), "axis": "horizontal"},
			"small_planning_cards": {"layer": "surface_decor_rear", "origin": Vector2i(114, 118), "axis": "horizontal"},
			"decision_folder": {"layer": "surface_decor_rear", "origin": Vector2i(50, 117), "axis": "horizontal"},
		}
		"east": return {
			"open_roadmap_notebook": {"layer": "surface_decor_rear", "origin": Vector2i(99, 82), "axis": "vertical"},
			"small_planning_cards": {"layer": "surface_decor_front", "origin": Vector2i(100, 158), "axis": "vertical"},
			"decision_folder": {"layer": "surface_decor_rear", "origin": Vector2i(82, 83), "axis": "vertical"},
		}
		"south": return {
			"open_roadmap_notebook": {"layer": "surface_decor_front", "origin": Vector2i(119, 131), "axis": "horizontal"},
			"small_planning_cards": {"layer": "surface_decor_rear", "origin": Vector2i(52, 118), "axis": "horizontal"},
			"decision_folder": {"layer": "surface_decor_rear", "origin": Vector2i(122, 117), "axis": "horizontal"},
		}
		"west": return {
			"open_roadmap_notebook": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical"},
			"small_planning_cards": {"layer": "surface_decor_rear", "origin": Vector2i(100, 84), "axis": "vertical"},
			"decision_folder": {"layer": "surface_decor_front", "origin": Vector2i(100, 156), "axis": "vertical"},
		}
	return {}

static func _image() -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _box(image: Image, rect: Rect2i, fill: Color) -> void:
	image.fill_rect(rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: image.fill_rect(rect.grow(-1), fill)

static func _notebook_horizontal(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(22, 9)), INK)
	_box(image, Rect2i(p, Vector2i(12, 10)), PAPER)
	_box(image, Rect2i(p + Vector2i(11, 0), Vector2i(12, 10)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(11, 1), Vector2i(1, 8)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(3, 3), Vector2i(3, 3)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(6, 4), Vector2i(3, 1)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(9, 4), Vector2i(2, 3)), GREEN)
	image.fill_rect(Rect2i(p + Vector2i(15, 3), Vector2i(3, 3)), VERMILION)
	image.fill_rect(Rect2i(p + Vector2i(18, 4), Vector2i(2, 1)), FOLDER_LIGHT)

static func _notebook_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(9, 22)), INK)
	_box(image, Rect2i(p, Vector2i(10, 12)), PAPER)
	_box(image, Rect2i(p + Vector2i(0, 11), Vector2i(10, 12)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 11), Vector2i(8, 1)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(3, 3), Vector2i(3, 3)), INDIGO)
	image.fill_rect(Rect2i(p + Vector2i(4, 6), Vector2i(1, 3)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(3, 9), Vector2i(3, 2)), GREEN)
	image.fill_rect(Rect2i(p + Vector2i(3, 15), Vector2i(3, 3)), VERMILION)
	image.fill_rect(Rect2i(p + Vector2i(4, 18), Vector2i(1, 2)), FOLDER_LIGHT)

static func _cards_horizontal(image: Image, p: Vector2i) -> void:
	var colors: Array[Color] = [INDIGO, CHARTREUSE, VERMILION]
	for index: int in range(3):
		var q := p + Vector2i(index * 4, index)
		_box(image, Rect2i(q, Vector2i(7, 7)), PAPER)
		image.fill_rect(Rect2i(q + Vector2i(1, 1), Vector2i(5, 2)), colors[index])
		image.fill_rect(Rect2i(q + Vector2i(2, 5), Vector2i(3, 1)), PAPER_SHADE)

static func _cards_vertical(image: Image, p: Vector2i) -> void:
	var colors: Array[Color] = [INDIGO, CHARTREUSE, VERMILION]
	for index: int in range(3):
		var q := p + Vector2i(index, index * 4)
		_box(image, Rect2i(q, Vector2i(7, 7)), PAPER)
		image.fill_rect(Rect2i(q + Vector2i(1, 1), Vector2i(2, 5)), colors[index])
		image.fill_rect(Rect2i(q + Vector2i(5, 2), Vector2i(1, 3)), PAPER_SHADE)

static func _folder_horizontal(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 0), Vector2i(7, 3)), INK)
	image.fill_rect(Rect2i(p + Vector2i(3, 1), Vector2i(5, 2)), FOLDER_LIGHT)
	_box(image, Rect2i(p + Vector2i(0, 2), Vector2i(18, 8)), FOLDER)
	image.fill_rect(Rect2i(p + Vector2i(2, 4), Vector2i(14, 1)), FOLDER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(13, 6), Vector2i(3, 2)), INDIGO)

static func _folder_vertical(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(0, 2), Vector2i(3, 7)), INK)
	image.fill_rect(Rect2i(p + Vector2i(1, 3), Vector2i(2, 5)), FOLDER_LIGHT)
	_box(image, Rect2i(p + Vector2i(2, 0), Vector2i(8, 18)), FOLDER)
	image.fill_rect(Rect2i(p + Vector2i(4, 2), Vector2i(1, 14)), FOLDER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(6, 13), Vector2i(2, 3)), INDIGO)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name): return result
	var spec: Dictionary = specs[object_name]
	var p: Vector2i = spec.origin
	var horizontal := str(spec.axis) == "horizontal"
	match object_name:
		"open_roadmap_notebook":
			if horizontal: _notebook_horizontal(result, p)
			else: _notebook_vertical(result, p)
		"small_planning_cards":
			if horizontal: _cards_horizontal(result, p)
			else: _cards_vertical(result, p)
		"decision_folder":
			if horizontal: _folder_horizontal(result, p)
			else: _folder_vertical(result, p)
	return result

static func binary_over(rear: Image, front: Image) -> Image:
	var result := rear.get_data()
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
		"name": "Founder" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/founder-strategy-kit-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y], "offset": [0, -48],
		"z_offset": layer_depth(side, layer_name),
	}
