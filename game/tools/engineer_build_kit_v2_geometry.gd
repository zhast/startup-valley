class_name EngineerBuildKitV2Geometry
extends RefCounted
## DEV ONLY. Deterministic passive engineering decor for the accepted desk.
## The four complete views are independent native screen-axis constructions;
## no finished bitmap is rotated, mirrored, scaled, or reused by another side.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OBJECTS: Array[String] = ["electronics_test_mat", "debug_instrument", "precision_tool_tray"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const SPRITE_OFFSET := Vector2i(0, -48)
const COLLISION_CELLS: Array[Vector2i] = []

const INK := Color("252832")
const INK_LIGHT := Color("464c55")
const MAT_EDGE := Color("19345f")
const MAT_BLUE := Color("315fa5")
const MAT_LIGHT := Color("5787c5")
const BOARD_DARK := Color("244b36")
const BOARD_GREEN := Color("3e8051")
const BOARD_LIGHT := Color("79ad63")
const CONTACT_GOLD := Color("d9bc4d")
const BREADBOARD := Color("eee7d4")
const BREADBOARD_SHADE := Color("c9c0aa")
const PROBE_RED := Color("d45145")
const STEEL := Color("aeb7ba")
const STEEL_LIGHT := Color("dce1dd")
const INSTRUMENT := Color("3b414b")
const INSTRUMENT_LIGHT := Color("606b75")
const SCREEN_DARK := Color("19394a")
const SCREEN_CYAN := Color("66b9c7")
const AMBER := Color("e0a247")
const TRAY := Color("63482f")
const TRAY_LIGHT := Color("a77a45")

static func direction_identity(side: String) -> Dictionary:
	match side:
		"north":
			return {"employee_look_vector": Vector2i.UP, "worker_left_edge": "west", "mat_far_edge": "north", "board_usb_edge": "west", "red_probe_side": "west", "tool_red_side": "west"}
		"east":
			return {"employee_look_vector": Vector2i.RIGHT, "worker_left_edge": "north", "mat_far_edge": "east", "board_usb_edge": "north", "red_probe_side": "north", "tool_red_side": "north"}
		"south":
			return {"employee_look_vector": Vector2i.DOWN, "worker_left_edge": "east", "mat_far_edge": "south", "board_usb_edge": "east", "red_probe_side": "east", "tool_red_side": "east"}
		"west":
			return {"employee_look_vector": Vector2i.LEFT, "worker_left_edge": "south", "mat_far_edge": "west", "board_usb_edge": "south", "red_probe_side": "south", "tool_red_side": "south"}
	return {}

static func specifications(side: String) -> Dictionary:
	# Origins are independently authored full-canvas native pixels. The compact
	# active mat is intentionally not a crop or rescale of the retained v1 plate.
	match side:
		"north":
			return {
				"electronics_test_mat": {"layer": "surface_decor_rear", "origin": Vector2i(51, 115), "axis": "horizontal", "construction": "authored_north"},
				"debug_instrument": {"layer": "surface_decor_rear", "origin": Vector2i(123, 116), "axis": "horizontal", "construction": "authored_north"},
				"precision_tool_tray": {"layer": "surface_decor_front", "origin": Vector2i(122, 132), "axis": "horizontal", "construction": "authored_north"},
			}
		"east":
			return {
				"electronics_test_mat": {"layer": "surface_decor_rear", "origin": Vector2i(82, 82), "axis": "vertical", "construction": "authored_east"},
				"debug_instrument": {"layer": "surface_decor_rear", "origin": Vector2i(100, 155), "axis": "vertical", "construction": "authored_east"},
				"precision_tool_tray": {"layer": "surface_decor_front", "origin": Vector2i(82, 155), "axis": "vertical", "construction": "authored_east"},
			}
		"south":
			return {
				"electronics_test_mat": {"layer": "surface_decor_rear", "origin": Vector2i(115, 115), "axis": "horizontal", "construction": "authored_south"},
				"debug_instrument": {"layer": "surface_decor_rear", "origin": Vector2i(50, 116), "axis": "horizontal", "construction": "authored_south"},
				"precision_tool_tray": {"layer": "surface_decor_front", "origin": Vector2i(50, 132), "axis": "horizontal", "construction": "authored_south"},
			}
		"west":
			return {
				"electronics_test_mat": {"layer": "surface_decor_rear", "origin": Vector2i(96, 147), "axis": "vertical", "construction": "authored_west"},
				"debug_instrument": {"layer": "surface_decor_rear", "origin": Vector2i(82, 83), "axis": "vertical", "construction": "authored_west"},
				"precision_tool_tray": {"layer": "surface_decor_front", "origin": Vector2i(101, 83), "axis": "vertical", "construction": "authored_west"},
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

static func _mat_north(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(26, 14)), MAT_BLUE)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(24, 1)), MAT_LIGHT)
	# Breadboard at the far/North edge.
	_box(image, Rect2i(p + Vector2i(8, 2), Vector2i(10, 4)), BREADBOARD)
	for x: int in [10, 13, 16]: image.set_pixelv(p + Vector2i(x, 3), INK_LIGHT)
	# Board nearer the worker, USB on worker-left/West.
	_box(image, Rect2i(p + Vector2i(8, 7), Vector2i(10, 5)), BOARD_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(9, 8), Vector2i(3, 3)), BOARD_DARK)
	image.set_pixelv(p + Vector2i(15, 9), CONTACT_GOLD)
	image.fill_rect(Rect2i(p + Vector2i(6, 8), Vector2i(2, 3)), STEEL)
	# Red probe left, black probe right, both needle tips toward far edge.
	image.fill_rect(Rect2i(p + Vector2i(2, 5), Vector2i(2, 6)), PROBE_RED)
	image.set_pixelv(p + Vector2i(3, 3), STEEL_LIGHT)
	image.set_pixelv(p + Vector2i(3, 4), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(22, 5), Vector2i(2, 6)), INK)
	image.set_pixelv(p + Vector2i(22, 3), STEEL_LIGHT)
	image.set_pixelv(p + Vector2i(22, 4), STEEL)

static func _mat_east(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(14, 26)), MAT_BLUE)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(1, 24)), MAT_LIGHT)
	# Breadboard at far/East; board nearer West, USB on worker-left/North.
	_box(image, Rect2i(p + Vector2i(8, 8), Vector2i(4, 10)), BREADBOARD)
	for y: int in [10, 13, 16]: image.set_pixelv(p + Vector2i(9, y), INK_LIGHT)
	_box(image, Rect2i(p + Vector2i(2, 8), Vector2i(5, 10)), BOARD_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(3, 9), Vector2i(3, 3)), BOARD_DARK)
	image.set_pixelv(p + Vector2i(4, 15), CONTACT_GOLD)
	image.fill_rect(Rect2i(p + Vector2i(3, 6), Vector2i(3, 2)), STEEL)
	# Red probe North, black South, tips toward far/East.
	image.fill_rect(Rect2i(p + Vector2i(4, 2), Vector2i(6, 2)), PROBE_RED)
	image.set_pixelv(p + Vector2i(11, 3), STEEL_LIGHT)
	image.set_pixelv(p + Vector2i(10, 3), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(4, 22), Vector2i(6, 2)), INK)
	image.set_pixelv(p + Vector2i(11, 22), STEEL_LIGHT)
	image.set_pixelv(p + Vector2i(10, 22), STEEL)

static func _mat_south(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(26, 14)), MAT_BLUE)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(24, 1)), MAT_LIGHT)
	# Breadboard at far/South; board nearer North, USB on worker-left/East.
	_box(image, Rect2i(p + Vector2i(8, 8), Vector2i(10, 4)), BREADBOARD)
	for x: int in [10, 13, 16]: image.set_pixelv(p + Vector2i(x, 10), INK_LIGHT)
	_box(image, Rect2i(p + Vector2i(8, 2), Vector2i(10, 5)), BOARD_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(14, 3), Vector2i(3, 3)), BOARD_DARK)
	image.set_pixelv(p + Vector2i(10, 4), CONTACT_GOLD)
	image.fill_rect(Rect2i(p + Vector2i(18, 3), Vector2i(2, 3)), STEEL)
	# Red probe East, black West, tips toward far/South.
	image.fill_rect(Rect2i(p + Vector2i(22, 3), Vector2i(2, 6)), PROBE_RED)
	image.set_pixelv(p + Vector2i(22, 10), STEEL)
	image.set_pixelv(p + Vector2i(22, 11), STEEL_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(2, 3), Vector2i(2, 6)), INK)
	image.set_pixelv(p + Vector2i(3, 10), STEEL)
	image.set_pixelv(p + Vector2i(3, 11), STEEL_LIGHT)

static func _mat_west(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(14, 26)), MAT_BLUE)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(1, 24)), MAT_LIGHT)
	# Breadboard at far/West; board nearer East, USB on worker-left/South.
	_box(image, Rect2i(p + Vector2i(2, 8), Vector2i(4, 10)), BREADBOARD)
	for y: int in [10, 13, 16]: image.set_pixelv(p + Vector2i(4, y), INK_LIGHT)
	_box(image, Rect2i(p + Vector2i(7, 8), Vector2i(5, 10)), BOARD_GREEN)
	image.fill_rect(Rect2i(p + Vector2i(8, 14), Vector2i(3, 3)), BOARD_DARK)
	image.set_pixelv(p + Vector2i(9, 10), CONTACT_GOLD)
	image.fill_rect(Rect2i(p + Vector2i(8, 18), Vector2i(3, 2)), STEEL)
	# Red probe South, black North, tips toward far/West.
	image.fill_rect(Rect2i(p + Vector2i(4, 22), Vector2i(6, 2)), PROBE_RED)
	image.set_pixelv(p + Vector2i(2, 22), STEEL_LIGHT)
	image.set_pixelv(p + Vector2i(3, 22), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(4, 2), Vector2i(6, 2)), INK)
	image.set_pixelv(p + Vector2i(2, 3), STEEL_LIGHT)
	image.set_pixelv(p + Vector2i(3, 3), STEEL)

static func _instrument_north(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(18, 10)), INSTRUMENT)
	_box(image, Rect2i(p + Vector2i(2, 2), Vector2i(9, 5)), SCREEN_DARK)
	image.fill_rect(Rect2i(p + Vector2i(3, 3), Vector2i(7, 1)), SCREEN_CYAN)
	image.set_pixelv(p + Vector2i(13, 3), AMBER)
	image.set_pixelv(p + Vector2i(15, 3), PROBE_RED)
	image.fill_rect(Rect2i(p + Vector2i(13, 6), Vector2i(3, 2)), INSTRUMENT_LIGHT)

static func _instrument_east(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(10, 18)), INSTRUMENT)
	_box(image, Rect2i(p + Vector2i(3, 2), Vector2i(5, 9)), SCREEN_DARK)
	image.fill_rect(Rect2i(p + Vector2i(4, 3), Vector2i(1, 7)), SCREEN_CYAN)
	image.set_pixelv(p + Vector2i(6, 13), AMBER)
	image.set_pixelv(p + Vector2i(6, 15), PROBE_RED)
	image.fill_rect(Rect2i(p + Vector2i(2, 13), Vector2i(2, 3)), INSTRUMENT_LIGHT)

static func _instrument_south(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(18, 10)), INSTRUMENT)
	_box(image, Rect2i(p + Vector2i(7, 3), Vector2i(9, 5)), SCREEN_DARK)
	image.fill_rect(Rect2i(p + Vector2i(8, 6), Vector2i(7, 1)), SCREEN_CYAN)
	image.set_pixelv(p + Vector2i(4, 6), AMBER)
	image.set_pixelv(p + Vector2i(2, 6), PROBE_RED)
	image.fill_rect(Rect2i(p + Vector2i(2, 2), Vector2i(3, 2)), INSTRUMENT_LIGHT)

static func _instrument_west(image: Image, p: Vector2i) -> void:
	_box(image, Rect2i(p, Vector2i(10, 18)), INSTRUMENT)
	_box(image, Rect2i(p + Vector2i(2, 7), Vector2i(5, 9)), SCREEN_DARK)
	image.fill_rect(Rect2i(p + Vector2i(5, 8), Vector2i(1, 7)), SCREEN_CYAN)
	image.set_pixelv(p + Vector2i(3, 4), AMBER)
	image.set_pixelv(p + Vector2i(3, 2), PROBE_RED)
	image.fill_rect(Rect2i(p + Vector2i(6, 2), Vector2i(2, 3)), INSTRUMENT_LIGHT)

static func _tray_horizontal(image: Image, p: Vector2i, red_left: bool) -> void:
	_box(image, Rect2i(p, Vector2i(18, 8)), TRAY)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(16, 1)), TRAY_LIGHT)
	var red_x := 2 if red_left else 10
	var steel_x := 10 if red_left else 2
	image.fill_rect(Rect2i(p + Vector2i(red_x, 3), Vector2i(5, 2)), PROBE_RED)
	image.set_pixelv(p + Vector2i(red_x + 5, 3), STEEL_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(steel_x, 3), Vector2i(5, 1)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(steel_x + 1, 5), Vector2i(4, 1)), STEEL_LIGHT)

static func _tray_vertical(image: Image, p: Vector2i, red_top: bool) -> void:
	_box(image, Rect2i(p, Vector2i(8, 18)), TRAY)
	image.fill_rect(Rect2i(p + Vector2i(1, 1), Vector2i(1, 16)), TRAY_LIGHT)
	var red_y := 2 if red_top else 10
	var steel_y := 10 if red_top else 2
	image.fill_rect(Rect2i(p + Vector2i(3, red_y), Vector2i(2, 5)), PROBE_RED)
	image.set_pixelv(p + Vector2i(3, red_y + 5), STEEL_LIGHT)
	image.fill_rect(Rect2i(p + Vector2i(3, steel_y), Vector2i(1, 5)), STEEL)
	image.fill_rect(Rect2i(p + Vector2i(5, steel_y + 1), Vector2i(1, 4)), STEEL_LIGHT)

static func object_image(side: String, object_name: String) -> Image:
	var result := _image()
	var specs := specifications(side)
	if not specs.has(object_name): return result
	var p: Vector2i = specs[object_name].origin
	match side:
		"north":
			match object_name:
				"electronics_test_mat": _mat_north(result, p)
				"debug_instrument": _instrument_north(result, p)
				"precision_tool_tray": _tray_horizontal(result, p, true)
		"east":
			match object_name:
				"electronics_test_mat": _mat_east(result, p)
				"debug_instrument": _instrument_east(result, p)
				"precision_tool_tray": _tray_vertical(result, p, true)
		"south":
			match object_name:
				"electronics_test_mat": _mat_south(result, p)
				"debug_instrument": _instrument_south(result, p)
				"precision_tool_tray": _tray_horizontal(result, p, false)
		"west":
			match object_name:
				"electronics_test_mat": _mat_west(result, p)
				"debug_instrument": _instrument_west(result, p)
				"precision_tool_tray": _tray_vertical(result, p, false)
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
		"name": "EngineerBuildV2" + side.capitalize() + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/engineer-build-kit-v2/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(side, layer_name),
	}
