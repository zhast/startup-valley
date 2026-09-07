class_name LawyerContractKitV2Geometry
extends RefCounted
## DEV ONLY. Deterministic legal-planning surface decor for the accepted desk.
## Every facing is drawn independently in native screen space. No completed
## bitmap is rotated, mirrored, scaled, or reused as another direction.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["contract_binder", "tabbed_review_folder", "pen_cup"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("282622")
const INK_LIGHT := Color("454540")
const PAPER := Color("ece3ca")
const PAPER_LIGHT := Color("f1f1f1")
const PAPER_SHADE := Color("c7b999")
const BINDER := Color("253667")
const BINDER_LIGHT := Color("3f5a8c")
const BINDER_SPINE := Color("172445")
const CERULEAN := Color("6196c1")
const TAB_GREEN := Color("83ab56")
const TAB_GOLD := Color("e0a247")
const PEN_RED := Color("c65b4b")
const CUP := Color("77512f")
const CUP_LIGHT := Color("d1a369")

static func direction_identity(side: String) -> Dictionary:
	# The employee's physical left side turns with host gaze. The binder spine,
	# blank/checklist leaves, outer tabs, and pen order follow that turn while
	# highlights remain fixed at screen upper-left.
	match side:
		"north":
			return {
				"employee_look_vector": Vector2i.UP,
				"worker_left_edge": "west",
				"binder_spine_edge": "west",
				"folder_blank_leaf": "west",
				"folder_checklist_leaf": "east",
				"folder_tab_edge": "east",
				"page_mark_axis": "screen_horizontal",
				"red_pen_side": "west",
				"blue_pen_side": "east",
			}
		"east":
			return {
				"employee_look_vector": Vector2i.RIGHT,
				"worker_left_edge": "north",
				"binder_spine_edge": "north",
				"folder_blank_leaf": "north",
				"folder_checklist_leaf": "south",
				"folder_tab_edge": "south",
				"page_mark_axis": "screen_vertical",
				"red_pen_side": "north",
				"blue_pen_side": "south",
			}
		"south":
			return {
				"employee_look_vector": Vector2i.DOWN,
				"worker_left_edge": "east",
				"binder_spine_edge": "east",
				"folder_blank_leaf": "east",
				"folder_checklist_leaf": "west",
				"folder_tab_edge": "west",
				"page_mark_axis": "screen_horizontal",
				"red_pen_side": "east",
				"blue_pen_side": "west",
			}
		"west":
			return {
				"employee_look_vector": Vector2i.LEFT,
				"worker_left_edge": "south",
				"binder_spine_edge": "south",
				"folder_blank_leaf": "south",
				"folder_checklist_leaf": "north",
				"folder_tab_edge": "north",
				"page_mark_axis": "screen_vertical",
				"red_pen_side": "south",
				"blue_pen_side": "north",
			}
	return {}

static func specifications(side: String) -> Dictionary:
	# Origins are full-canvas native pixels and are independently declared.
	match side:
		"north":
			return {
				"contract_binder": {"layer": "surface_decor_rear", "origin": Vector2i(51, 115), "axis": "horizontal", "construction": "authored_north"},
				"tabbed_review_folder": {"layer": "surface_decor_rear", "origin": Vector2i(124, 117), "axis": "horizontal", "construction": "authored_north"},
				"pen_cup": {"layer": "surface_decor_front", "origin": Vector2i(52, 128), "axis": "upright", "construction": "authored_north"},
			}
		"east":
			return {
				"contract_binder": {"layer": "surface_decor_rear", "origin": Vector2i(97, 83), "axis": "vertical", "construction": "authored_east"},
				"tabbed_review_folder": {"layer": "surface_decor_front", "origin": Vector2i(96, 147), "axis": "vertical", "construction": "authored_east"},
				"pen_cup": {"layer": "surface_decor_rear", "origin": Vector2i(83, 85), "axis": "upright", "construction": "authored_east"},
			}
		"south":
			return {
				"contract_binder": {"layer": "surface_decor_rear", "origin": Vector2i(121, 115), "axis": "horizontal", "construction": "authored_south"},
				"tabbed_review_folder": {"layer": "surface_decor_rear", "origin": Vector2i(50, 117), "axis": "horizontal", "construction": "authored_south"},
				"pen_cup": {"layer": "surface_decor_front", "origin": Vector2i(130, 128), "axis": "upright", "construction": "authored_south"},
			}
		"west":
			return {
				"contract_binder": {"layer": "surface_decor_front", "origin": Vector2i(83, 151), "axis": "vertical", "construction": "authored_west"},
				"tabbed_review_folder": {"layer": "surface_decor_rear", "origin": Vector2i(82, 84), "axis": "vertical", "construction": "authored_west"},
				"pen_cup": {"layer": "surface_decor_front", "origin": Vector2i(99, 149), "axis": "upright", "construction": "authored_west"},
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

static func _binder_north(image: Image, p: Vector2i) -> void:
	# West spine; page block and a small index tab extend east.
	_box(image, Rect2i(p + Vector2i(0, 4), Vector2i(20, 8)), BINDER_SPINE)
	_box(image, Rect2i(p + Vector2i(2, 0), Vector2i(18, 8)), BINDER)
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(3, 6)), BINDER_SPINE)
	image.fill_rect(Rect2i(p + Vector2i(6, 2), Vector2i(12, 3)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(7, 2), Vector2i(9, 1)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(5, 7), Vector2i(13, 2)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(18, 2), Vector2i(2, 2)), TAB_GREEN)

static func _binder_east(image: Image, p: Vector2i) -> void:
	# Independently drawn narrow projection with the spine on the north edge.
	_box(image, Rect2i(p + Vector2i(0, 2), Vector2i(8, 18)), BINDER_SPINE)
	_box(image, Rect2i(p + Vector2i(4, 0), Vector2i(8, 20)), BINDER)
	image.fill_rect(Rect2i(p + Vector2i(5, 1), Vector2i(6, 3)), BINDER_SPINE)
	image.fill_rect(Rect2i(p + Vector2i(6, 5), Vector2i(3, 12)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(6, 6), Vector2i(1, 9)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(2, 17), Vector2i(7, 2)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(1, 18), Vector2i(2, 2)), TAB_GREEN)

static func _binder_south(image: Image, p: Vector2i) -> void:
	# East spine and opposite cover stagger; fixed upper-left screen light remains.
	_box(image, Rect2i(p + Vector2i(0, 0), Vector2i(18, 8)), BINDER)
	_box(image, Rect2i(p + Vector2i(0, 4), Vector2i(20, 8)), BINDER_SPINE)
	image.fill_rect(Rect2i(p + Vector2i(16, 1), Vector2i(3, 6)), BINDER_SPINE)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(12, 3)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(3, 2), Vector2i(9, 1)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(2, 7), Vector2i(13, 2)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(0, 2), Vector2i(2, 2)), TAB_GREEN)

static func _binder_west(image: Image, p: Vector2i) -> void:
	# Independently drawn narrow projection with the spine on the south edge.
	_box(image, Rect2i(p + Vector2i(4, 0), Vector2i(8, 18)), BINDER)
	_box(image, Rect2i(p + Vector2i(0, 0), Vector2i(8, 20)), BINDER_SPINE)
	image.fill_rect(Rect2i(p + Vector2i(1, 16), Vector2i(6, 3)), BINDER_SPINE)
	image.fill_rect(Rect2i(p + Vector2i(3, 3), Vector2i(3, 12)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(5, 4), Vector2i(1, 9)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(3, 1), Vector2i(7, 2)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(9, 0), Vector2i(2, 2)), TAB_GREEN)

static func _folder_north(image: Image, p: Vector2i) -> void:
	# Blank west leaf, checklist east leaf, tabs on the outer east edge.
	image.fill_rect(Rect2i(p + Vector2i(1, 2), Vector2i(15, 12)), INK)
	_box(image, Rect2i(p + Vector2i(0, 1), Vector2i(8, 12)), PAPER)
	_box(image, Rect2i(p + Vector2i(7, 0), Vector2i(9, 13)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(7, 2), Vector2i(1, 9)), PAPER_SHADE)
	for row: int in range(3):
		image.set_pixelv(p + Vector2i(9, 3 + row * 3), INK_LIGHT)
		image.fill_rect(Rect2i(p + Vector2i(11, 3 + row * 3), Vector2i(4, 1)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(16, 2), Vector2i(2, 2)), TAB_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(16, 6), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(16, 10), Vector2i(2, 2)), TAB_GOLD)

static func _folder_east(image: Image, p: Vector2i) -> void:
	# New true-East construction: blank north, checklist south, tabs south.
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(12, 14)), INK)
	_box(image, Rect2i(p + Vector2i(1, 0), Vector2i(12, 8)), PAPER)
	_box(image, Rect2i(p + Vector2i(0, 7), Vector2i(13, 9)), PAPER_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(2, 7), Vector2i(9, 1)), PAPER_SHADE)
	for column: int in range(3):
		image.set_pixelv(p + Vector2i(3 + column * 3, 9), INK_LIGHT)
		image.fill_rect(Rect2i(p + Vector2i(3 + column * 3, 11), Vector2i(1, 4)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(2, 16), Vector2i(2, 2)), TAB_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(6, 16), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(10, 16), Vector2i(2, 2)), TAB_GOLD)

static func _folder_south(image: Image, p: Vector2i) -> void:
	# Checklist west, blank east, tabs on the outer west edge.
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(15, 12)), INK)
	_box(image, Rect2i(p + Vector2i(2, 0), Vector2i(9, 13)), PAPER_LIGHT)
	_box(image, Rect2i(p + Vector2i(10, 1), Vector2i(8, 12)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(10, 2), Vector2i(1, 9)), PAPER_SHADE)
	for row: int in range(3):
		image.set_pixelv(p + Vector2i(3, 3 + row * 3), INK_LIGHT)
		image.fill_rect(Rect2i(p + Vector2i(5, 3 + row * 3), Vector2i(4, 1)), PAPER_SHADE)
	image.fill_rect(Rect2i(p + Vector2i(0, 2), Vector2i(2, 2)), TAB_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(0, 6), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(0, 10), Vector2i(2, 2)), TAB_GOLD)

static func _folder_west(image: Image, p: Vector2i) -> void:
	# Corrected West construction: tabs north, checklist north, blank south.
	image.fill_rect(Rect2i(p + Vector2i(2, 3), Vector2i(12, 14)), INK)
	image.fill_rect(Rect2i(p + Vector2i(2, 0), Vector2i(2, 2)), TAB_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(6, 0), Vector2i(2, 2)), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(10, 0), Vector2i(2, 2)), TAB_GOLD)
	_box(image, Rect2i(p + Vector2i(0, 2), Vector2i(13, 9)), PAPER_LIGHT)
	_box(image, Rect2i(p + Vector2i(1, 10), Vector2i(12, 8)), PAPER)
	image.fill_rect(Rect2i(p + Vector2i(2, 10), Vector2i(9, 1)), PAPER_SHADE)
	for column: int in range(3):
		image.set_pixelv(p + Vector2i(3 + column * 3, 4), INK_LIGHT)
		image.fill_rect(Rect2i(p + Vector2i(3 + column * 3, 6), Vector2i(1, 4)), PAPER_SHADE)

static func _cup_body(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(1, 5), Vector2i(8, 3)), INK)
	image.fill_rect(Rect2i(p + Vector2i(2, 6), Vector2i(6, 1)), CUP_LIGHT)
	_box(image, Rect2i(p + Vector2i(1, 7), Vector2i(8, 7)), CUP)
	image.fill_rect(Rect2i(p + Vector2i(2, 8), Vector2i(1, 4)), CUP_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(0, 13), Vector2i(10, 1)), INK)

static func _cup_north(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 0), Vector2i(2, 7)), PEN_RED)
	image.set_pixelv(p + Vector2i(1, 1), PEN_RED)
	image.fill_rect(Rect2i(p + Vector2i(7, 1), Vector2i(2, 6)), CERULEAN)
	image.set_pixelv(p + Vector2i(9, 2), CERULEAN)
	_cup_body(image, p)

static func _cup_east(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(3, 0), Vector2i(2, 7)), PEN_RED)
	image.set_pixelv(p + Vector2i(2, 1), PEN_RED)
	image.fill_rect(Rect2i(p + Vector2i(6, 2), Vector2i(2, 5)), CERULEAN)
	image.set_pixelv(p + Vector2i(8, 3), CERULEAN)
	_cup_body(image, p)

static func _cup_south(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(2, 1), Vector2i(2, 6)), CERULEAN)
	image.set_pixelv(p + Vector2i(0, 2), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(7, 0), Vector2i(2, 7)), PEN_RED)
	image.set_pixelv(p + Vector2i(9, 1), PEN_RED)
	_cup_body(image, p)

static func _cup_west(image: Image, p: Vector2i) -> void:
	image.fill_rect(Rect2i(p + Vector2i(3, 2), Vector2i(2, 5)), CERULEAN)
	image.set_pixelv(p + Vector2i(1, 3), CERULEAN)
	image.fill_rect(Rect2i(p + Vector2i(6, 0), Vector2i(2, 7)), PEN_RED)
	image.set_pixelv(p + Vector2i(8, 1), PEN_RED)
	_cup_body(image, p)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name):
		return result
	var p: Vector2i = specs[object_name].origin
	match side:
		"north":
			match object_name:
				"contract_binder": _binder_north(result, p)
				"tabbed_review_folder": _folder_north(result, p)
				"pen_cup": _cup_north(result, p)
		"east":
			match object_name:
				"contract_binder": _binder_east(result, p)
				"tabbed_review_folder": _folder_east(result, p)
				"pen_cup": _cup_east(result, p)
		"south":
			match object_name:
				"contract_binder": _binder_south(result, p)
				"tabbed_review_folder": _folder_south(result, p)
				"pen_cup": _cup_south(result, p)
		"west":
			match object_name:
				"contract_binder": _binder_west(result, p)
				"tabbed_review_folder": _folder_west(result, p)
				"pen_cup": _cup_west(result, p)
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
		"name": "LawyerContractV2" + side.capitalize() + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/lawyer-contract-kit-v2/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
