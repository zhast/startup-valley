class_name DecisionConsoleGeometry
extends RefCounted
## Four independently declared screen-axis views of the approval console.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["FloorShadow", "RearStructure", "FrontStructure", "AmbientOverlay"]
const CANVAS := Vector2i(192, 288)
const PIVOT := Vector2i(96, 208)
const INK := Color("282622")
const CHARCOAL := Color("383833")
const CHARCOAL_LIGHT := Color("57564f")
const METAL := Color("77746b")
const OAK := Color("9b683c")
const OAK_LIGHT := Color("c38a50")
const OAK_DARK := Color("634329")
const SCREEN := Color("202d5c")
const SCREEN_LIGHT := Color("6196c1")
const VERMILION := Color("fa4616")
const CHARTREUSE := Color("c1fa81")
const SHADOW := Color("6a5944")

static func profile(side: String) -> Dictionary:
	match side:
		"north": return _horizontal(side, -1)
		"south": return _horizontal(side, 1)
		"east": return _vertical(side, 1)
		"west": return _vertical(side, -1)
	return {}

static func _horizontal(side: String, approach_sign: int) -> Dictionary:
	var occupied: Array[Array] = []
	var occupied_rows: Array[int] = []
	occupied_rows.assign([0, 1] if side == "north" else [-1, 0])
	for y: int in occupied_rows:
		for x: int in [-1, 0, 1]: occupied.append([x, y])
	return {
		"facing": side, "axis": "horizontal", "service_sign": approach_sign,
		"body": Rect2i(-48, -80, 96, 80), "top": Rect2i(-48, -96, 96, 48),
		"occupied": occupied,
		"clearance": [[-1, approach_sign], [0, approach_sign], [1, approach_sign]],
		"interaction": [0, approach_sign],
	}

static func _vertical(side: String, approach_sign: int) -> Dictionary:
	var occupied: Array[Array] = []
	var occupied_columns: Array[int] = []
	occupied_columns.assign([-1, 0] if side == "east" else [0, 1])
	for x: int in occupied_columns:
		for y: int in [-1, 0, 1]: occupied.append([x, y])
	return {
		"facing": side, "axis": "vertical", "service_sign": approach_sign,
		"body": Rect2i(-32, -112, 64, 112), "top": Rect2i(-48, -112, 48, 96) if side == "west" else Rect2i(0, -112, 48, 96),
		"occupied": occupied,
		"clearance": [[1 if side == "east" else -1, -1], [1 if side == "east" else -1, 0], [1 if side == "east" else -1, 1]],
		"interaction": [1 if side == "east" else -1, 0],
	}

static func _paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func _box(image: Image, rect: Rect2i, fill: Color, light: Color = Color.TRANSPARENT) -> void:
	_paint(image, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: _paint(image, rect.grow(-1), fill)
	if light.a > 0:
		_paint(image, Rect2i(rect.position + Vector2i(2, 2), Vector2i(maxi(1, rect.size.x - 4), 1)), light)

static func _screen(image: Image, rect: Rect2i, side: String) -> void:
	_box(image, rect, CHARCOAL)
	_paint(image, rect.grow(-3), SCREEN)
	if side in ["north", "south"]:
		_paint(image, Rect2i(rect.position + Vector2i(6, 7), Vector2i(rect.size.x - 12, 2)), SCREEN_LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(6, 12), Vector2i((rect.size.x - 14) / 2, 2)), SCREEN_LIGHT)
	else:
		_paint(image, Rect2i(rect.position + Vector2i(6, 6), Vector2i(2, rect.size.y - 12)), SCREEN_LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(11, 6), Vector2i(2, (rect.size.y - 14) / 2)), SCREEN_LIGHT)

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
	var ambient := result.AmbientOverlay as Image
	var body: Rect2i = p.body
	var top: Rect2i = p.top
	if p.axis == "horizontal":
		_paint(shadow, Rect2i(-45, -15, 94, 22), SHADOW)
		_box(rear, Rect2i(-44, -78, 88, 62), CHARCOAL, CHARCOAL_LIGHT)
		_box(rear, Rect2i(-38, -100, 76, 42), OAK, OAK_LIGHT)
		_box(front, Rect2i(-48, -34, 96, 36), OAK_DARK, OAK_LIGHT)
		if side == "south":
			_screen(rear, Rect2i(-29, -91, 58, 25), side)
			_box(front, Rect2i(-38, -25, 30, 14), CHARCOAL)
			_box(front, Rect2i(8, -25, 30, 14), CHARCOAL)
			_box(front, Rect2i(-34, -22, 7, 7), CHARTREUSE)
			_box(front, Rect2i(27, -22, 7, 7), VERMILION)
			_paint(ambient, Rect2i(-21, -83, 26, 2), SCREEN_LIGHT)
			_paint(ambient, Rect2i(11, -83, 9, 2), CHARTREUSE)
		else:
			# North service faces away from the camera: show a ventilated monitor
			# back and maintenance panels rather than falsely reusing the front UI.
			_box(rear, Rect2i(-29, -91, 58, 25), CHARCOAL)
			for vent_x: int in [-19, -9, 1, 11]: _paint(rear, Rect2i(vent_x, -83, 7, 2), METAL)
			_box(front, Rect2i(-38, -25, 36, 14), OAK)
			_box(front, Rect2i(5, -25, 33, 14), OAK)
			_paint(ambient, Rect2i(29, -88, 3, 3), CHARTREUSE)
	else:
		var left := -30 if side == "west" else 2
		_paint(shadow, Rect2i(-16, -105, 40, 113), SHADOW)
		_box(rear, Rect2i(-28, -108, 56, 102), CHARCOAL, CHARCOAL_LIGHT)
		_box(rear, top, OAK, OAK_LIGHT)
		var screen_x := left + 9
		_screen(rear, Rect2i(screen_x, -99, 26, 64), side)
		var front_x := -2 if side == "west" else -30
		_box(front, Rect2i(front_x, -108, 32, 110), OAK_DARK, OAK_LIGHT)
		_box(front, Rect2i(front_x + 7, -75, 18, 24), CHARCOAL)
		_box(front, Rect2i(front_x + 8, -69, 6, 7), CHARTREUSE)
		_box(front, Rect2i(front_x + 17, -69, 6, 7), VERMILION)
		_paint(ambient, Rect2i(screen_x + 6, -89, 2, 34), SCREEN_LIGHT)
		_paint(ambient, Rect2i(screen_x + 11, -89, 2, 13), CHARTREUSE)
	return result

static func whole(parts: Dictionary[String, Image]) -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for label: String in LAYERS:
		if parts.has(label): result.blend_rect(parts[label], Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return result

static func catalog_entry() -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var p := profile(side)
		var paths: Array[Dictionary] = []
		for label: String in LAYERS:
			paths.append({"name": label, "art": "res://tests/fixtures/furniture-calibration/decision-console-v1/%s-%s.png" % [side, label.to_snake_case()], "region": [0, 0, CANVAS.x, CANVAS.y], "offset": [0, CANVAS.y / 2 - PIVOT.y], "z_offset": -1 if label in ["FloorShadow", "RearStructure"] else (2 if label == "AmbientOverlay" else 1)})
		var bounds := Rect2()
		for layer: Dictionary in paths:
			var ink := OfficeLayout.measured_layer_ink_bounds(layer)
			if not ink.has_area(): continue
			var destination := Vector2(OfficeLayout.vector(layer.offset)) - Vector2(CANVAS) * 0.5 + ink.position
			var placed := Rect2(destination, ink.size)
			bounds = bounds.merge(placed) if bounds.has_area() else placed
		profiles[side] = {
			"status": "calibration_candidate", "review": {"art": false, "geometry": false}, "profile_kind": "service",
			"service_side": side, "approach_gaze": OfficeLayout.OPPOSITE_GAZE[side], "approach_visual_bounds": [-24, -72, 48, 80],
			"occupied": p.occupied, "clearance": p.clearance, "interaction": p.interaction,
			"anchor_offset": [0, 0], "visual_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)],
			"hit_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)],
			"render_layers": paths, "ambient_overlays": [],
		}
	return {"display_name": "Decision console", "facings": SIDES, "interaction_kind": "activity", "wall_mount": "none", "facing_profiles": profiles}
