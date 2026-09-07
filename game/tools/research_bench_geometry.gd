class_name ResearchBenchGeometry
extends RefCounted
## Original four-facing product-research bench, authored on the room's screen axes.

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
		var body_y := -1 if side == "north" else 0
		var occupied: Array[Array] = []
		for y: int in [body_y, body_y + 1]:
			for x: int in [-1, 0, 1]: occupied.append([x, y])
		# The view names the employee's gaze. They stand on the opposite side of
		# the bench and look toward it, matching the workstation contract.
		var interaction_y := 1 if side == "north" else -1
		return {"occupied": occupied, "clearance": [[-1, interaction_y], [0, interaction_y], [1, interaction_y]], "interaction": [0, interaction_y], "work_cell": [0, interaction_y]}
	if side in ["east", "west"]:
		var body_x := 0 if side == "east" else -1
		var occupied: Array[Array] = []
		for x: int in [body_x, body_x + 1]:
			for y: int in [-1, 0, 1]: occupied.append([x, y])
		var interaction_x := -1 if side == "east" else 1
		return {"occupied": occupied, "clearance": [[interaction_x, -1], [interaction_x, 0], [interaction_x, 1]], "interaction": [interaction_x, 0], "work_cell": [interaction_x, 0]}
	return {}

static func _paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func _box(image: Image, rect: Rect2i, fill: Color, highlight: Color = Color.TRANSPARENT) -> void:
	_paint(image, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: _paint(image, rect.grow(-1), fill)
	if highlight.a > 0: _paint(image, Rect2i(rect.position + Vector2i(2, 2), Vector2i(maxi(1, rect.size.x - 4), 1)), highlight)

static func layers(side: String) -> Dictionary[String, Image]:
	if profile(side).is_empty(): return {}
	var result: Dictionary[String, Image] = {}
	for label: String in LAYERS:
		var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT); result[label] = image
	var shadow := result.FloorShadow as Image
	var rear := result.RearStructure as Image
	var front := result.FrontStructure as Image
	var tools := result.ToolOverlay as Image
	if side in ["north", "south"]:
		_paint(shadow, Rect2i(-54, -14, 108, 22), SHADOW)
		_box(rear, Rect2i(-55, -106, 110, 62), OAK_DARK, OAK_LIGHT)
		_box(rear, Rect2i(-48, -135, 96, 38), METAL, METAL_LIGHT)
		_box(front, Rect2i(-58, -48, 116, 48), OAK, OAK_LIGHT)
		_box(front, Rect2i(-46, -40, 34, 31), METAL)
		_box(front, Rect2i(12, -40, 34, 31), METAL)
		if side == "south":
			# Readable public face: microscope, scan pad, samples and notes.
			_box(tools, Rect2i(-41, -126, 24, 28), INDIGO, CERULEAN)
			_paint(tools, Rect2i(-35, -121, 7, 13), PARCHMENT)
			_paint(tools, Rect2i(-25, -113, 8, 4), INDIGO)
			_box(tools, Rect2i(-4, -119, 36, 18), CERULEAN, PARCHMENT)
			_paint(tools, Rect2i(2, -114, 24, 7), CHARTREUSE)
			for x: int in [-37, -25, -13]:
				_box(tools, Rect2i(x, -71, 6, 15), PARCHMENT)
				_paint(tools, Rect2i(x + 1, -62, 4, 5), CHARTREUSE if x != -25 else VERMILION)
			_box(tools, Rect2i(8, -72, 29, 18), PARCHMENT)
			_paint(tools, Rect2i(13, -67, 19, 2), INDIGO)
		else:
			# Rear view exposes cable rails and vented instrument backs.
			for x: int in [-37, -24, -11, 2, 15, 28]: _paint(tools, Rect2i(x, -119, 9, 2), METAL_LIGHT)
			_paint(tools, Rect2i(-38, -73, 76, 3), INK)
			_paint(tools, Rect2i(31, -68, 5, 5), CHARTREUSE)
	else:
		var back_x := -43 if side == "west" else -5
		var near_x := 1 if side == "west" else -47
		_paint(shadow, Rect2i(-20, -141, 42, 150), SHADOW)
		_box(rear, Rect2i(-29, -151, 58, 145), METAL, METAL_LIGHT)
		_box(rear, Rect2i(back_x, -146, 44, 92), OAK_DARK, OAK_LIGHT)
		_box(front, Rect2i(near_x, -151, 46, 153), OAK, OAK_LIGHT)
		_box(front, Rect2i(near_x + 7, -70, 32, 54), METAL)
		var tool_x := back_x + 8
		_box(tools, Rect2i(tool_x, -133, 26, 31), INDIGO, CERULEAN)
		_paint(tools, Rect2i(tool_x + 6, -124, 8, 14), PARCHMENT)
		_paint(tools, Rect2i(tool_x + 15, -114, 8, 4), INDIGO)
		_box(tools, Rect2i(near_x + 10, -139, 25, 18), CERULEAN)
		_paint(tools, Rect2i(near_x + 14, -134, 17, 7), CHARTREUSE)
		for y: int in [-103, -88, -73]: _box(tools, Rect2i(near_x + 15, y, 6, 12), PARCHMENT)
	return result

static func whole(parts: Dictionary[String, Image]) -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for label: String in LAYERS:
		if parts.has(label): result.blend_rect(parts[label], Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return result
