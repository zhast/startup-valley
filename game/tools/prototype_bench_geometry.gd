class_name PrototypeBenchGeometry
extends RefCounted
## Four native screen-axis views of a product/creative/engineering bench.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["FloorShadow", "RearStructure", "FrontStructure", "ToolOverlay"]
const CANVAS := Vector2i(192, 320)
const PIVOT := Vector2i(96, 240)
const INK := Color("282622")
const OAK := Color("9b683c")
const OAK_LIGHT := Color("c38a50")
const OAK_DARK := Color("634329")
const METAL := Color("454540")
const METAL_LIGHT := Color("77746b")
const INDIGO := Color("354b98")
const CERULEAN := Color("6196c1")
const VERMILION := Color("fa4616")
const CHARTREUSE := Color("c1fa81")
const PARCHMENT := Color("eee2c8")
const SHADOW := Color("6a5944")

static func profile(side: String) -> Dictionary:
	if side in ["north", "south"]:
		var rows: Array[int] = []
		rows.assign([0, 1] if side == "north" else [-1, 0])
		var occupied: Array[Array] = []
		for y: int in rows:
			for x: int in [-1, 0, 1]: occupied.append([x, y])
		var approach_y := -1 if side == "north" else 1
		return {"facing": side, "axis": "horizontal", "occupied": occupied, "clearance": [[-1, approach_y], [0, approach_y], [1, approach_y]], "interaction": [0, approach_y]}
	if side in ["east", "west"]:
		var columns: Array[int] = []
		columns.assign([-1, 0] if side == "east" else [0, 1])
		var occupied: Array[Array] = []
		for x: int in columns:
			for y: int in [-1, 0, 1]: occupied.append([x, y])
		var approach_x := 1 if side == "east" else -1
		return {"facing": side, "axis": "vertical", "occupied": occupied, "clearance": [[approach_x, -1], [approach_x, 0], [approach_x, 1]], "interaction": [approach_x, 0]}
	return {}

static func _paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func _box(image: Image, rect: Rect2i, fill: Color, highlight: Color = Color.TRANSPARENT) -> void:
	_paint(image, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: _paint(image, rect.grow(-1), fill)
	if highlight.a > 0: _paint(image, Rect2i(rect.position + Vector2i(2, 2), Vector2i(maxi(1, rect.size.x - 4), 1)), highlight)

static func _tool(image: Image, origin: Vector2i, color: Color, vertical: bool = false) -> void:
	_box(image, Rect2i(origin, Vector2i(5, 14) if vertical else Vector2i(14, 5)), color)

static func layers(side: String) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	var result: Dictionary[String, Image] = {}
	for label: String in LAYERS:
		var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		result[label] = image
	var shadow := result.FloorShadow as Image
	var rear := result.RearStructure as Image
	var front := result.FrontStructure as Image
	var tools := result.ToolOverlay as Image
	if p.axis == "horizontal":
		_paint(shadow, Rect2i(-52, -15, 106, 22), SHADOW)
		_box(rear, Rect2i(-48, -142, 96, 84), METAL, METAL_LIGHT)
		_box(rear, Rect2i(-43, -136, 86, 48), OAK_DARK, OAK_LIGHT)
		_box(rear, Rect2i(-55, -82, 110, 46), OAK, OAK_LIGHT)
		_box(front, Rect2i(-58, -42, 116, 44), OAK_DARK, OAK_LIGHT)
		_box(front, Rect2i(-48, -34, 38, 26), METAL)
		_box(front, Rect2i(10, -34, 38, 26), METAL)
		if side == "south":
			# Public tool face: printer, cutting mat, calipers and bright test parts.
			_box(tools, Rect2i(-38, -130, 28, 32), INDIGO, CERULEAN)
			_box(tools, Rect2i(-32, -122, 16, 16), PARCHMENT)
			_box(tools, Rect2i(-1, -128, 35, 25), METAL, METAL_LIGHT)
			_paint(tools, Rect2i(5, -120, 22, 10), CERULEAN)
			_tool(tools, Vector2i(-39, -72), VERMILION)
			_tool(tools, Vector2i(-18, -72), CHARTREUSE)
			_tool(tools, Vector2i(4, -72), CERULEAN)
			_tool(tools, Vector2i(28, -72), PARCHMENT)
		else:
			# Away-facing rear: vents, cable rail and power indicators only.
			for x: int in [-34, -20, -6, 8, 22]: _paint(tools, Rect2i(x, -120, 9, 2), METAL_LIGHT)
			_paint(tools, Rect2i(-30, -72, 60, 3), INK)
			_paint(tools, Rect2i(34, -68, 4, 4), CHARTREUSE)
	else:
		var rear_x := -46 if side == "west" else -2
		var front_x := 2 if side == "west" else -48
		_paint(shadow, Rect2i(-20, -140, 44, 148), SHADOW)
		_box(rear, Rect2i(-30, -150, 60, 144), METAL, METAL_LIGHT)
		_box(rear, Rect2i(rear_x, -146, 48, 96), OAK_DARK, OAK_LIGHT)
		_box(front, Rect2i(front_x, -150, 48, 152), OAK, OAK_LIGHT)
		_box(front, Rect2i(front_x + 8, -77, 32, 60), METAL)
		var machine_x := rear_x + 9
		_box(tools, Rect2i(machine_x, -134, 28, 43), INDIGO, CERULEAN)
		_paint(tools, Rect2i(machine_x + 6, -125, 16, 22), PARCHMENT)
		_tool(tools, Vector2i(front_x + 14, -137), VERMILION, true)
		_tool(tools, Vector2i(front_x + 27, -137), CHARTREUSE, true)
	return result

static func whole(parts: Dictionary[String, Image]) -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for label: String in LAYERS:
		if parts.has(label): result.blend_rect(parts[label], Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return result

static func catalog_entry(base_path: String = "res://tests/fixtures/furniture-calibration/prototype-bench-v1/") -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var p := profile(side)
		var render_layers: Array[Dictionary] = []
		for label: String in LAYERS:
			render_layers.append({"name": label, "art": base_path + side + "-" + label.to_snake_case() + ".png", "region": [0, 0, CANVAS.x, CANVAS.y], "offset": [0, CANVAS.y / 2 - PIVOT.y], "z_offset": -1 if label == "FloorShadow" else (0 if label == "RearStructure" else (1 if label == "FrontStructure" else 2))})
		var bounds := Rect2()
		for layer: Dictionary in render_layers:
			var ink := OfficeLayout.measured_layer_ink_bounds(layer)
			if not ink.has_area(): continue
			var placed := Rect2(Vector2(OfficeLayout.vector(layer.offset)) - Vector2(CANVAS) * 0.5 + ink.position, ink.size)
			bounds = bounds.merge(placed) if bounds.has_area() else placed
		profiles[side] = {"profile_kind": "service", "status": "calibration_candidate", "review": {"art": false, "geometry": false}, "service_side": side, "approach_gaze": OfficeLayout.OPPOSITE_GAZE[side], "approach_visual_bounds": [-24, -72, 48, 80], "occupied": p.occupied, "clearance": p.clearance, "interaction": p.interaction, "anchor_offset": [0, 0], "visual_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)], "render_layers": render_layers, "ambient_overlays": []}
	return {"display_name": "Prototype bench", "facings": SIDES, "interaction_kind": "prototype", "wall_mount": "none", "facing_profiles": profiles}
