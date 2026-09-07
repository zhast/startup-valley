class_name PassiveLightingEntryGeometry
extends RefCounted
## DEV ONLY. Deterministic task floor lamp, desk lamp kit and coat/bag
## stand. Every projection is declared directly in screen space with fixed
## upper-left light. No finished raster is rotated, mirrored or resampled.

const FAMILIES: Array[String] = ["task_floor_lamp", "desk_lamp_kit", "coat_bag_stand"]
const SIDES: Array[String] = ["north", "east", "south", "west"]
const BASE_LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const DESK_LAYERS: Array[String] = ["surface_decor_rear", "surface_decor_front"]
const OUTPUT_ROOTS := {
	"task_floor_lamp": "res://tests/fixtures/furniture-calibration/task-floor-lamp-v2",
	"desk_lamp_kit": "res://tests/fixtures/furniture-calibration/desk-lamp-kit-v2",
	"coat_bag_stand": "res://tests/fixtures/furniture-calibration/coat-bag-stand-v3",
}

static func revision(family: String) -> String:
	return family.replace("_", "-") + ("-v3" if family == "coat_bag_stand" else "-v2")

const INK := Color("282622")
const DEEP := Color("383833")
const METAL := Color("77746b")
const METAL_LIGHT := Color("b4b0a3")
const POWDER := Color("454540")
const SHADE := Color("315a54")
const SHADE_LIGHT := Color("61968b")
const WARM := Color("e0a247")
const WARM_LIGHT := Color("f0c96b")
const SHADOW := Color("554e42")
const WOOD := Color("77512f")
const WOOD_LIGHT := Color("d1a369")
const COAT := Color("3e5278")
const COAT_LIGHT := Color("6179a2")
const COAT_SHADE := Color("253667")
const BAG := Color("a85b32")
const BAG_LIGHT := Color("d7894d")
const BAG_SHADE := Color("6f3d2a")

static func canvas(family: String) -> Vector2i:
	return Vector2i(192, 224) if family == "desk_lamp_kit" else Vector2i(128, 256)

static func pivot(family: String) -> Vector2i:
	return Vector2i(96, 160) if family == "desk_lamp_kit" else Vector2i(64, 208)

static func sprite_offset(family: String) -> Vector2i:
	return canvas(family) / 2 - pivot(family)

static func layer_names(family: String) -> Array[String]:
	return DESK_LAYERS.duplicate() if family == "desk_lamp_kit" else BASE_LAYERS.duplicate()

static func _floor_lamp_profile(side: String) -> Dictionary:
	match side:
		"north": return {"base": Vector2i(64, 204), "elbow": Vector2i(63, 105), "neck": Vector2i(64, 68), "shade": Rect2i(48, 50, 32, 19), "shade_axis": "back", "interaction": [0, 1], "look": [0, -1]}
		"east": return {"base": Vector2i(63, 204), "elbow": Vector2i(64, 105), "neck": Vector2i(82, 73), "shade": Rect2i(80, 61, 29, 21), "shade_axis": "right", "interaction": [-1, 0], "look": [1, 0]}
		"south": return {"base": Vector2i(64, 204), "elbow": Vector2i(65, 105), "neck": Vector2i(64, 84), "shade": Rect2i(47, 70, 34, 20), "shade_axis": "front", "interaction": [0, -1], "look": [0, 1]}
		"west": return {"base": Vector2i(65, 204), "elbow": Vector2i(64, 104), "neck": Vector2i(47, 72), "shade": Rect2i(19, 60, 30, 21), "shade_axis": "left", "interaction": [1, 0], "look": [-1, 0]}
	return {}

static func _desk_lamp_profile(side: String) -> Dictionary:
	# The lamp remains on the operator's authored right-hand desk edge and aims
	# inward; positions are inside the accepted desk top for that facing.
	match side:
		"north": return {"base": Vector2i(132, 137), "elbow": Vector2i(132, 120), "neck": Vector2i(128, 119), "shade": Rect2i(113, 114, 17, 13), "shade_axis": "left", "desk_axis": "horizontal", "look": [0, -1]}
		"east": return {"base": Vector2i(101, 165), "elbow": Vector2i(102, 156), "neck": Vector2i(102, 153), "shade": Rect2i(95, 151, 13, 16), "shade_axis": "front", "desk_axis": "vertical", "look": [1, 0]}
		"south": return {"base": Vector2i(132, 137), "elbow": Vector2i(133, 121), "neck": Vector2i(126, 119), "shade": Rect2i(118, 113, 14, 14), "shade_axis": "front", "desk_axis": "horizontal", "look": [0, 1]}
		"west": return {"base": Vector2i(91, 91), "elbow": Vector2i(92, 99), "neck": Vector2i(94, 101), "shade": Rect2i(82, 97, 13, 11), "shade_axis": "left", "desk_axis": "vertical", "look": [-1, 0]}
	return {}

static func _coat_profile(side: String) -> Dictionary:
	match side:
		"north": return {"post_x": 64, "top_y": 55, "crossbar_from": Vector2i(41, 66), "crossbar_to": Vector2i(88, 65), "left_hook_tip": Vector2i(36, 57), "right_hook_tip": Vector2i(92, 58), "coat": Rect2i(67, 77, 27, 72), "hanger_hook": Vector2i(82, 65), "bag": Rect2i(34, 138, 24, 31), "shelf": Rect2i(38, 169, 52, 6), "interaction": [0, -1], "look": [0, 1], "service_side": "north", "approach_gaze": "south", "projection": "front", "coat_face": "front", "bag_face": "front"}
		"east": return {"post_x": 65, "top_y": 57, "crossbar_from": Vector2i(53, 69), "crossbar_to": Vector2i(77, 64), "left_hook_tip": Vector2i(49, 62), "right_hook_tip": Vector2i(80, 58), "coat": Rect2i(51, 79, 15, 70), "hanger_hook": Vector2i(59, 68), "bag": Rect2i(68, 141, 12, 29), "shelf": Rect2i(50, 170, 31, 7), "interaction": [1, 0], "look": [-1, 0], "service_side": "east", "approach_gaze": "west", "projection": "side", "coat_face": "side_left", "bag_face": "side_right"}
		"south": return {"post_x": 63, "top_y": 54, "crossbar_from": Vector2i(39, 66), "crossbar_to": Vector2i(87, 64), "left_hook_tip": Vector2i(34, 57), "right_hook_tip": Vector2i(91, 57), "coat": Rect2i(34, 78, 28, 73), "hanger_hook": Vector2i(47, 65), "bag": Rect2i(69, 135, 25, 33), "shelf": Rect2i(37, 168, 53, 7), "interaction": [0, 1], "look": [0, -1], "service_side": "south", "approach_gaze": "north", "projection": "rear", "coat_face": "rear", "bag_face": "rear"}
		"west": return {"post_x": 62, "top_y": 56, "crossbar_from": Vector2i(50, 65), "crossbar_to": Vector2i(75, 70), "left_hook_tip": Vector2i(46, 58), "right_hook_tip": Vector2i(79, 63), "coat": Rect2i(63, 80, 15, 69), "hanger_hook": Vector2i(70, 68), "bag": Rect2i(49, 141, 12, 29), "shelf": Rect2i(47, 170, 31, 6), "interaction": [-1, 0], "look": [1, 0], "service_side": "west", "approach_gaze": "east", "projection": "side", "coat_face": "side_right", "bag_face": "side_left"}
	return {}

static func profile(family: String, side: String) -> Dictionary:
	if family not in FAMILIES or side not in SIDES:
		return {}
	var result := {}
	match family:
		"task_floor_lamp": result = _floor_lamp_profile(side)
		"desk_lamp_kit": result = _desk_lamp_profile(side)
		"coat_bag_stand": result = _coat_profile(side)
	result["family"] = family
	result["facing"] = side
	result["footprint"] = [0, 0] if family == "desk_lamp_kit" else [1, 1]
	result["occupied"] = [] if family == "desk_lamp_kit" else [[0, 0]]
	result["employee_look_vector"] = result.look.duplicate()
	return result

static func _image(family: String) -> Image:
	var size := canvas(family)
	var result := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _inside(image: Image, point: Vector2i) -> bool:
	return point.x >= 0 and point.y >= 0 and point.x < image.get_width() and point.y < image.get_height()

static func _put(image: Image, point: Vector2i, color: Color) -> void:
	if _inside(image, point):
		image.set_pixelv(point, color)

static func _segment(image: Image, from: Vector2i, to: Vector2i, color: Color, thickness := 1) -> void:
	var delta := to - from
	var steps := maxi(absi(delta.x), absi(delta.y))
	if steps == 0:
		_put(image, from, color)
		return
	for index: int in range(steps + 1):
		var point := Vector2i((Vector2(from) + Vector2(delta) * float(index) / float(steps)).round())
		for oy: int in range(-thickness / 2, thickness - thickness / 2):
			for ox: int in range(-thickness / 2, thickness - thickness / 2):
				_put(image, point + Vector2i(ox, oy), color)

static func _segment_points(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var delta := to - from
	var steps := maxi(absi(delta.x), absi(delta.y))
	if steps == 0:
		return [from]
	for index: int in range(steps + 1):
		var point := Vector2i((Vector2(from) + Vector2(delta) * float(index) / float(steps)).round())
		if result.is_empty() or result[-1] != point:
			result.append(point)
	return result

static func desk_support_path(side: String) -> Array[Vector2i]:
	var p := _desk_lamp_profile(side)
	var result := _segment_points(Vector2i(p.base) + Vector2i(0, -3), Vector2i(p.elbow))
	for point: Vector2i in _segment_points(Vector2i(p.elbow), Vector2i(p.neck)):
		if not result.has(point):
			result.append(point)
	return result

static func coat_hanger_path(side: String) -> Array[Vector2i]:
	var p := _coat_profile(side)
	var coat_rect: Rect2i = p.coat
	var neck := Vector2i(coat_rect.position.x + coat_rect.size.x / 2, coat_rect.position.y - 3)
	var contact := Vector2i(neck.x, coat_rect.position.y + 2)
	var result := _segment_points(Vector2i(p.hanger_hook), neck)
	for point: Vector2i in _segment_points(neck, contact):
		if not result.has(point):
			result.append(point)
	return result

static func _ellipse(image: Image, rect: Rect2i, fill: Color, outline: Color = Color(0, 0, 0, 0), dither := false) -> void:
	var center := Vector2(rect.position) + Vector2(rect.size - Vector2i.ONE) * 0.5
	var radius := Vector2(rect.size) * 0.5
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var delta := (Vector2(x, y) - center) / radius
			var distance := delta.length_squared()
			if distance > 1.0 or (dither and distance > 0.5 and (x + y) % 2 != 0):
				continue
			var color := fill
			if outline.a > 0.0 and distance > 0.74:
				color = outline
			_put(image, Vector2i(x, y), color)

static func _box(image: Image, rect: Rect2i, fill: Color, light: Color, dark: Color = INK) -> void:
	image.fill_rect(rect, dark)
	if rect.size.x <= 2 or rect.size.y <= 2:
		return
	image.fill_rect(rect.grow(-1), fill)
	image.fill_rect(Rect2i(rect.position + Vector2i.ONE, Vector2i(rect.size.x - 2, 1)), light)
	image.fill_rect(Rect2i(rect.position + Vector2i(1, 2), Vector2i(1, maxi(1, rect.size.y - 3))), light)
	image.fill_rect(Rect2i(rect.position + Vector2i(2, rect.size.y - 2), Vector2i(maxi(1, rect.size.x - 3), 1)), dark)

static func _vertical_shade(image: Image, rect: Rect2i, fill: Color) -> void:
	for row: int in range(rect.size.y):
		var t := float(row) / float(maxi(1, rect.size.y - 1))
		var inset := roundi(lerpf(6.0, 0.0, t))
		var line := Rect2i(rect.position + Vector2i(inset, row), Vector2i(rect.size.x - inset * 2, 1))
		image.fill_rect(line, INK if row == 0 or row == rect.size.y - 1 else fill)
		if row > 0 and row < rect.size.y - 1 and line.size.x > 3:
			_put(image, line.position, INK)
			_put(image, Vector2i(line.end.x - 1, line.position.y), INK)
			_put(image, line.position + Vector2i(1, 0), SHADE_LIGHT)

static func _horizontal_shade(image: Image, rect: Rect2i, points_right: bool, fill: Color) -> void:
	for column: int in range(rect.size.x):
		var t := float(column) / float(maxi(1, rect.size.x - 1))
		if not points_right:
			t = 1.0 - t
		var inset := roundi(lerpf(6.0, 0.0, t))
		var line := Rect2i(rect.position + Vector2i(column, inset), Vector2i(1, rect.size.y - inset * 2))
		image.fill_rect(line, fill)
		_put(image, line.position, INK)
		_put(image, Vector2i(line.position.x, line.end.y - 1), INK)
		if column == 0 or column == rect.size.x - 1:
			image.fill_rect(line, INK)
		elif line.size.y > 3 and column < rect.size.x / 2:
			_put(image, line.position + Vector2i(0, 1), SHADE_LIGHT)

static func _draw_shade(image: Image, rect: Rect2i, axis: String) -> void:
	if axis in ["back", "front"]:
		_vertical_shade(image, rect, POWDER if axis == "back" else SHADE)
	else:
		_horizontal_shade(image, rect, axis == "right", SHADE)

static func _draw_lamp_base(image: Image, center: Vector2i, small := false) -> void:
	var rect := Rect2i(center - Vector2i(10 if small else 20, 4 if small else 7), Vector2i(20 if small else 40, 8 if small else 14))
	_ellipse(image, rect, POWDER, INK)
	_ellipse(image, Rect2i(rect.position + Vector2i(3, 1), Vector2i(rect.size.x - 8, maxi(3, rect.size.y - 5))), METAL_LIGHT)
	for x: int in range(rect.position.x + 3, rect.end.x - 4, 4):
		_put(image, Vector2i(x, rect.position.y + 2), METAL)

static func _floor_lamp_layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {"floor_shadow": _image("task_floor_lamp"), "rear_structure": _image("task_floor_lamp"), "front_structure": _image("task_floor_lamp")}
	var p := _floor_lamp_profile(side)
	# V2: one compact solid contact shadow replaces the rejected busy dither halo.
	_ellipse(result.floor_shadow, Rect2i(Vector2i(p.base) - Vector2i(26, 7), Vector2i(52, 14)), SHADOW)
	var rear: Image = result.rear_structure
	_segment(rear, Vector2i(p.base) + Vector2i(1, -4), Vector2i(p.elbow) + Vector2i(1, 0), DEEP, 6)
	_segment(rear, Vector2i(p.base) + Vector2i(-1, -5), Vector2i(p.elbow) + Vector2i(-1, 0), METAL, 3)
	_segment(rear, Vector2i(p.elbow), Vector2i(p.neck), DEEP, 5)
	_segment(rear, Vector2i(p.elbow) + Vector2i(-1, -1), Vector2i(p.neck) + Vector2i(-1, -1), METAL_LIGHT, 1)
	_ellipse(rear, Rect2i(Vector2i(p.elbow) - Vector2i(5, 5), Vector2i(10, 10)), METAL, INK)
	_draw_shade(rear, p.shade, p.shade_axis)
	var front: Image = result.front_structure
	_draw_lamp_base(front, p.base)
	# Face/lip and bulb stay separable from the structural shade.
	var lip := Rect2i(p.shade.position + Vector2i(2, p.shade.size.y - 4), Vector2i(p.shade.size.x - 4, 4))
	if p.shade_axis == "right": lip = Rect2i(p.shade.end - Vector2i(4, p.shade.size.y - 2), Vector2i(4, p.shade.size.y - 4))
	elif p.shade_axis == "left": lip = Rect2i(p.shade.position + Vector2i(0, 2), Vector2i(4, p.shade.size.y - 4))
	_box(front, lip, WARM, WARM_LIGHT)
	_put(front, lip.position + Vector2i(maxi(1, lip.size.x / 2), maxi(1, lip.size.y / 2)), WARM_LIGHT)
	_segment(front, Vector2i(p.base) + Vector2i(-2, -9), Vector2i(p.base) + Vector2i(-2, -4), METAL_LIGHT, 1)
	return result

static func _desk_lamp_layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {"surface_decor_rear": _image("desk_lamp_kit"), "surface_decor_front": _image("desk_lamp_kit")}
	var p := _desk_lamp_profile(side)
	var rear: Image = result.surface_decor_rear
	_segment(rear, Vector2i(p.base) + Vector2i(0, -2), Vector2i(p.elbow), DEEP, 4)
	_segment(rear, Vector2i(p.base) + Vector2i(-1, -2), Vector2i(p.elbow) + Vector2i(-1, 0), METAL_LIGHT, 1)
	_segment(rear, Vector2i(p.elbow), Vector2i(p.neck), METAL, 4)
	_ellipse(rear, Rect2i(Vector2i(p.elbow) - Vector2i(3, 3), Vector2i(7, 7)), METAL, INK)
	_draw_shade(rear, p.shade, p.shade_axis)
	var front: Image = result.surface_decor_front
	_draw_lamp_base(front, p.base, true)
	var face := Rect2i(p.shade.position + Vector2i(2, p.shade.size.y - 3), Vector2i(maxi(3, p.shade.size.x - 4), 3))
	if p.shade_axis == "right": face = Rect2i(p.shade.end - Vector2i(3, p.shade.size.y - 2), Vector2i(3, maxi(3, p.shade.size.y - 4)))
	elif p.shade_axis == "left": face = Rect2i(p.shade.position + Vector2i(0, 2), Vector2i(3, maxi(3, p.shade.size.y - 4)))
	_box(front, face, WARM, WARM_LIGHT)
	return result

static func _draw_coat(image: Image, rect: Rect2i, face: String) -> void:
	# Front, rear and narrow side silhouettes are separately authored screen-axis
	# projections of one garment. Fixed material light always remains screen-left.
	var side_view := face.begins_with("side_")
	var shoulder_inset := 2 if side_view else 4
	var shoulder := Rect2i(rect.position + Vector2i(shoulder_inset, 0), Vector2i(rect.size.x - shoulder_inset * 2, 6))
	_box(image, shoulder, COAT, COAT_LIGHT)
	for row: int in range(5, rect.size.y):
		var inset := 2 if side_view else (2 if row < 16 else 4 if row > rect.size.y - 12 else 3)
		var line := Rect2i(rect.position + Vector2i(inset, row), Vector2i(rect.size.x - inset * 2, 1))
		image.fill_rect(line, COAT)
		_put(image, line.position, INK)
		_put(image, Vector2i(line.end.x - 1, line.position.y), COAT_SHADE)
		if row % 7 == 2 and line.size.x > 4:
			_put(image, line.position + Vector2i(2, 0), COAT_LIGHT)
	var sleeve_width := 5 if side_view else 7
	var sleeve_height := maxi(18, rect.size.y / 2)
	if face in ["front", "side_left"]:
		_box(image, Rect2i(rect.position + Vector2i(0, 8), Vector2i(sleeve_width, sleeve_height)), COAT, COAT_LIGHT)
	else:
		_box(image, Rect2i(rect.end.x - sleeve_width, rect.position.y + 8, sleeve_width, sleeve_height), COAT, COAT_LIGHT)
	var collar_y := rect.position.y + 3
	if face == "front":
		_segment(image, Vector2i(rect.position.x + rect.size.x / 2 - 5, collar_y), Vector2i(rect.position.x + rect.size.x / 2, collar_y + 7), COAT_LIGHT, 2)
		_segment(image, Vector2i(rect.position.x + rect.size.x / 2 + 5, collar_y), Vector2i(rect.position.x + rect.size.x / 2, collar_y + 7), COAT_SHADE, 2)
		_segment(image, Vector2i(rect.position.x + rect.size.x / 2, collar_y + 8), Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 5), COAT_SHADE, 1)
		for y: int in range(collar_y + 13, rect.end.y - 6, 12):
			_put(image, Vector2i(rect.position.x + rect.size.x / 2 - 2, y), METAL_LIGHT)
	elif face == "rear":
		# Rear yoke and hem replace the front V, placket and buttons.
		_segment(image, rect.position + Vector2i(5, 10), Vector2i(rect.end.x - 6, rect.position.y + 10), COAT_LIGHT, 2)
		_segment(image, rect.position + Vector2i(6, 13), Vector2i(rect.end.x - 7, rect.position.y + 13), COAT_SHADE, 1)
		_segment(image, rect.position + Vector2i(rect.size.x / 2, 14), rect.position + Vector2i(rect.size.x / 2, 31), COAT_SHADE, 1)
		_segment(image, Vector2i(rect.position.x + 5, rect.end.y - 7), Vector2i(rect.end.x - 6, rect.end.y - 7), COAT_LIGHT, 1)
	elif face == "side_left":
		_segment(image, rect.position + Vector2i(4, 5), rect.position + Vector2i(8, 13), COAT_LIGHT, 1)
		_segment(image, rect.position + Vector2i(9, 13), Vector2i(rect.end.x - 3, rect.end.y - 6), COAT_SHADE, 1)
	else:
		_segment(image, Vector2i(rect.end.x - 5, rect.position.y + 5), rect.position + Vector2i(7, 13), COAT_SHADE, 1)
		_segment(image, rect.position + Vector2i(3, 13), rect.position + Vector2i(4, rect.size.y - 6), COAT_LIGHT, 1)

static func _draw_bag(image: Image, rect: Rect2i, face: String) -> void:
	_box(image, rect, BAG, BAG_LIGHT, BAG_SHADE)
	var side_view := face.begins_with("side_")
	var handle_inset := 2 if side_view else 5
	var handle_left := rect.position + Vector2i(handle_inset, 0)
	var handle_right := Vector2i(rect.end.x - handle_inset - 1, rect.position.y)
	_segment(image, handle_left, handle_left + Vector2i(2, -8), BAG_SHADE, 2)
	_segment(image, handle_left + Vector2i(2, -8), handle_right + Vector2i(-2, -8), BAG_SHADE, 2)
	_segment(image, handle_right + Vector2i(-2, -8), handle_right, BAG_SHADE, 2)
	if face == "front":
		_box(image, Rect2i(rect.position.x + 5, rect.position.y + 8, 4, 5), WARM, WARM_LIGHT)
		_segment(image, rect.position + Vector2i(3, rect.size.y - 5), Vector2i(rect.end.x - 4, rect.end.y - 6), BAG_SHADE, 1)
	elif face == "rear":
		_segment(image, rect.position + Vector2i(4, 7), Vector2i(rect.end.x - 5, rect.position.y + 7), BAG_SHADE, 1)
		_segment(image, rect.position + Vector2i(5, 8), Vector2i(rect.end.x - 6, rect.position.y + 15), BAG_LIGHT, 1)
	else:
		var hardware_x := rect.position.x + 2 if face == "side_left" else rect.end.x - 4
		_box(image, Rect2i(hardware_x, rect.position.y + 9, 2, 4), WARM, WARM_LIGHT)
		_segment(image, rect.position + Vector2i(3, rect.size.y - 5), Vector2i(rect.end.x - 3, rect.end.y - 6), BAG_SHADE, 1)

static func _coat_layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {"floor_shadow": _image("coat_bag_stand"), "rear_structure": _image("coat_bag_stand"), "front_structure": _image("coat_bag_stand")}
	var p := _coat_profile(side)
	# V2: a compact solid contact shadow avoids a broad checkerboard halo.
	_ellipse(result.floor_shadow, Rect2i(int(p.post_x) - 27, 199, 54, 14), SHADOW)
	var rear: Image = result.rear_structure
	_segment(rear, Vector2i(int(p.post_x), 201), Vector2i(int(p.post_x), int(p.top_y)), WOOD, 7)
	_segment(rear, Vector2i(int(p.post_x) - 2, 199), Vector2i(int(p.post_x) - 2, int(p.top_y) + 2), WOOD_LIGHT, 2)
	_ellipse(rear, Rect2i(int(p.post_x) - 6, int(p.top_y) - 4, 12, 12), WOOD, INK)
	_segment(rear, Vector2i(p.crossbar_from), Vector2i(p.crossbar_to), WOOD, 5)
	_segment(rear, Vector2i(p.crossbar_from) + Vector2i(1, -2), Vector2i(p.left_hook_tip), WOOD_LIGHT, 3)
	_segment(rear, Vector2i(p.crossbar_to) + Vector2i(-1, 0), Vector2i(p.right_hook_tip), WOOD, 3)
	# V3 retains v2's physical hanger while projecting the rack independently.
	var coat_rect: Rect2i = p.coat
	var hanger_neck := Vector2i(coat_rect.position.x + coat_rect.size.x / 2, coat_rect.position.y - 3)
	_segment(rear, Vector2i(p.hanger_hook), hanger_neck, METAL_LIGHT, 2)
	_segment(rear, hanger_neck, Vector2i(hanger_neck.x, coat_rect.position.y + 2), METAL, 2)
	_segment(rear, hanger_neck, Vector2i(coat_rect.position.x + 4, coat_rect.position.y + 3), METAL, 2)
	_segment(rear, hanger_neck, Vector2i(coat_rect.end.x - 5, coat_rect.position.y + 3), METAL, 2)
	_box(rear, p.shelf, WOOD, WOOD_LIGHT)
	var front: Image = result.front_structure
	_draw_coat(front, p.coat, str(p.coat_face))
	_draw_bag(front, p.bag, str(p.bag_face))
	_draw_lamp_base(front, Vector2i(int(p.post_x), 205))
	_segment(front, Vector2i(int(p.post_x) - 2, 181), Vector2i(int(p.post_x) - 2, 198), WOOD_LIGHT, 2)
	return result

static func layers(family: String, side: String) -> Dictionary[String, Image]:
	match family:
		"task_floor_lamp": return _floor_lamp_layers(side)
		"desk_lamp_kit": return _desk_lamp_layers(side)
		"coat_bag_stand": return _coat_layers(side)
	return {}

static func binary_over(back: Image, near: Image) -> Image:
	var result := back.get_data().duplicate()
	var front := near.get_data()
	for at: int in range(0, result.size(), 4):
		if front[at + 3] != 0:
			for channel: int in range(4):
				result[at + channel] = front[at + channel]
	return Image.create_from_data(back.get_width(), back.get_height(), false, Image.FORMAT_RGBA8, result)

static func whole(family: String, side: String) -> Image:
	var parts := layers(family, side)
	var result := _image(family)
	for layer_name: String in layer_names(family):
		result = binary_over(result, parts[layer_name])
	return result

static func layer_depth(family: String, layer_name: String) -> int:
	if family == "desk_lamp_kit":
		# Host desk front/top is z+1. Surface decor must remain above that plane;
		# rear z+2 is still strictly below the front lip/base at z+4.
		return 2 if layer_name == "surface_decor_rear" else 4
	return {"floor_shadow": -8, "rear_structure": -4, "front_structure": 5}.get(layer_name, 0)

static func descriptor(family: String, side: String, layer_name: String) -> Dictionary:
	return {
		"name": family.to_pascal_case() + layer_name.to_pascal_case(),
		"art": str(OUTPUT_ROOTS[family]).path_join("%s-%s.png" % [side, layer_name]),
		"region": [0, 0, canvas(family).x, canvas(family).y],
		"offset": [sprite_offset(family).x, sprite_offset(family).y],
		"z_offset": layer_depth(family, layer_name),
	}

static func catalog_entry(family: String) -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var p := profile(family, side)
		var bounds := whole(family, side).get_used_rect()
		var local := Rect2i(bounds.position - pivot(family), bounds.size)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in layer_names(family):
			render_layers.append(descriptor(family, side, layer_name))
		var clearance: Array = [] if family == "desk_lamp_kit" else [p.interaction.duplicate()]
		var viewpoints: Array = [] if family == "desk_lamp_kit" else [{"cell": p.interaction.duplicate(), "visual_bounds": [-24, -76, 48, 84]}]
		profiles[side] = {
			"profile_kind": "decorative",
			"status": "calibration_candidate",
			"review": {"art": false, "geometry": false},
			"occupied": p.occupied.duplicate(true),
			"clearance": clearance,
			"anchor_offset": [0, 0],
			"visual_bounds": [local.position.x, local.position.y, local.size.x, local.size.y],
			"hit_bounds": [local.position.x, local.position.y, local.size.x, local.size.y],
			"render_layers": render_layers,
			"ambient_overlays": [],
			"standing_viewpoints": viewpoints,
			"proposed_employee_look_vector": p.employee_look_vector.duplicate(),
			"calibration_limitations": ["Passive art and contact evidence only; no light switch, service, seat or backend capability."],
		}
		if family == "coat_bag_stand":
			profiles[side]["proposed_service_side"] = p.service_side
			profiles[side]["proposed_approach_gaze"] = p.approach_gaze
	return {
		"display_name": family.to_pascal_case() + " candidate",
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none" if family != "desk_lamp_kit" else "host_surface",
		"facing_profiles": profiles,
	}
