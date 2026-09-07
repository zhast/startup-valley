class_name PassiveTableGeometry
extends RefCounted
## DEV ONLY. Three bare passive table families authored directly at native
## screen-axis scale. No chair, tool, service, work, seat, or action metadata.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const FAMILIES: Array[String] = ["low_coffee_table", "cafe_table", "round_meeting_table"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const OAK_HORIZONTAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-horizontal-v2.png"
const OAK_VERTICAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-vertical-v2.png"
const INK := Color("282622")
const EDGE := Color("77512f")
const LIGHT := Color("d1a369")
const MID := Color("98683b")
const SHADE := Color("583d28")
const CHARCOAL := Color("383833")
const METAL_LIGHT := Color("68685e")
const CONTACT := Color("554e42")

static func revision(family: String) -> String:
	return {
		"low_coffee_table": "low-coffee-table-v1",
		"cafe_table": "cafe-table-v2",
		"round_meeting_table": "round-meeting-table-v1",
	}.get(family, "")

static func canvas(family: String) -> Vector2i:
	return {
		"low_coffee_table": Vector2i(160, 160),
		"cafe_table": Vector2i(160, 240),
		"round_meeting_table": Vector2i(224, 288),
	}.get(family, Vector2i.ZERO)

static func pivot(family: String) -> Vector2i:
	return {
		"low_coffee_table": Vector2i(80, 96),
		"cafe_table": Vector2i(80, 160),
		"round_meeting_table": Vector2i(112, 176),
	}.get(family, Vector2i.ZERO)

static func sprite_offset(family: String) -> Vector2i:
	var size := canvas(family)
	return size / 2 - pivot(family)

static func output_root(family: String) -> String:
	return "res://tests/fixtures/furniture-calibration/" + revision(family) + "/"

static func _low_profile(side: String) -> Dictionary:
	var horizontal := side in ["north", "south"]
	var center := {
		"north": Vector2i(-16, 0), "east": Vector2i(0, -16),
		"south": Vector2i(16, 0), "west": Vector2i(0, 16),
	}[side] as Vector2i
	var floor_size := Vector2i(64, 32) if horizontal else Vector2i(32, 64)
	var top_size := Vector2i(56, 24) if horizontal else Vector2i(24, 56)
	var occupied: Array = {
		"north": [[-1, 0], [0, 0]], "east": [[0, -1], [0, 0]],
		"south": [[0, 0], [1, 0]], "west": [[0, 0], [0, 1]],
	}[side]
	return {
		"family": "low_coffee_table", "facing": side, "axis": "horizontal" if horizontal else "vertical",
		"canvas": canvas("low_coffee_table"), "pivot": pivot("low_coffee_table"),
		"center": center, "floor": Rect2i(center - floor_size / 2, floor_size),
		"top": Rect2i(center - top_size / 2 - Vector2i(0, 20), top_size),
		"rise": 20, "occupied": occupied, "footprint": [2, 1] if horizontal else [1, 2],
		"equivalent_view": "north" if horizontal else "east",
	}

static func _cafe_profile(side: String) -> Dictionary:
	var center := {
		"north": Vector2i(-16, -16), "east": Vector2i(16, -16),
		"south": Vector2i(16, 16), "west": Vector2i(-16, 16),
	}[side] as Vector2i
	var occupied: Array = {
		"north": [[-1, -1], [0, -1], [-1, 0], [0, 0]],
		"east": [[0, -1], [1, -1], [0, 0], [1, 0]],
		"south": [[0, 0], [1, 0], [0, 1], [1, 1]],
		"west": [[-1, 0], [0, 0], [-1, 1], [0, 1]],
	}[side]
	return {
		"family": "cafe_table", "facing": side, "axis": "square",
		"canvas": canvas("cafe_table"), "pivot": pivot("cafe_table"),
		"center": center, "floor": Rect2i(center - Vector2i(32, 32), Vector2i(64, 64)),
		"top": Rect2i(center - Vector2i(26, 20) - Vector2i(0, 44), Vector2i(52, 40)),
		"rise": 44, "occupied": occupied, "footprint": [2, 2], "equivalent_view": "translated_square",
	}

static func _round_profile(side: String) -> Dictionary:
	var occupied: Array[Array] = []
	for y: int in range(-1, 2):
		for x: int in range(-1, 2): occupied.append([x, y])
	return {
		"family": "round_meeting_table", "facing": side, "axis": "round",
		"canvas": canvas("round_meeting_table"), "pivot": pivot("round_meeting_table"),
		"center": Vector2i.ZERO, "floor": Rect2i(-48, -48, 96, 96),
		"top": Rect2i(-42, -78, 84, 52), "rise": 52,
		"occupied": occupied, "footprint": [3, 3], "equivalent_view": "rotationally_symmetric",
	}

static func profile(family: String, side: String) -> Dictionary:
	if side not in SIDES: return {}
	match family:
		"low_coffee_table": return _low_profile(side)
		"cafe_table": return _cafe_profile(side)
		"round_meeting_table": return _round_profile(side)
	return {}

static func _image(family: String) -> Image:
	var size := canvas(family)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image

static func _paint(image: Image, family: String, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + pivot(family), rect.size), color)

static func _tile() -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(OAK_HORIZONTAL))

static func _inside_chamfer(rect: Rect2i, point: Vector2i, corner := 3) -> bool:
	var local := point - rect.position
	if local.x < 0 or local.y < 0 or local.x >= rect.size.x or local.y >= rect.size.y: return false
	if local.y == 0 or local.y == rect.size.y - 1: return local.x >= corner and local.x < rect.size.x - corner
	if local.y == 1 or local.y == rect.size.y - 2: return local.x >= 1 and local.x < rect.size.x - 1
	return true

static func _draw_chamfered_top(image: Image, family: String, rect: Rect2i, tile: Image) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var point := Vector2i(x, y)
			if not _inside_chamfer(rect, point): continue
			var local := point - rect.position
			var border := not _inside_chamfer(rect.grow(-2), point, 1)
			var color := INK if border else tile.get_pixel(posmod(local.x, 32), posmod(local.y, 32))
			image.set_pixelv(point + pivot(family), color)
	# Fixed screen upper-left highlight and lower-right shade are redrawn for
	# every registered view; no finished bitmap is rotated or mirrored.
	_paint(image, family, Rect2i(rect.position + Vector2i(4, 1), Vector2i(rect.size.x - 8, 1)), LIGHT)
	_paint(image, family, Rect2i(rect.position + Vector2i(2, 3), Vector2i(1, rect.size.y - 7)), LIGHT)
	_paint(image, family, Rect2i(rect.position + Vector2i(4, rect.size.y - 2), Vector2i(rect.size.x - 8, 1)), SHADE)
	_paint(image, family, Rect2i(rect.end.x - 3, rect.position.y + 3, 1, rect.size.y - 7), SHADE)

static func _ellipse_contains(rect: Rect2i, point: Vector2i, inset := 0) -> bool:
	var rx := rect.size.x / 2 - inset
	var ry := rect.size.y / 2 - inset
	if rx <= 0 or ry <= 0: return false
	var center_twice := rect.position * 2 + rect.size - Vector2i.ONE
	var dx := point.x * 2 - center_twice.x
	var dy := point.y * 2 - center_twice.y
	return dx * dx * ry * ry + dy * dy * rx * rx <= 4 * rx * rx * ry * ry

static func _draw_round_top(image: Image, family: String, rect: Rect2i, tile: Image) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var point := Vector2i(x, y)
			if not _ellipse_contains(rect, point): continue
			var color := INK
			if _ellipse_contains(rect, point, 2): color = tile.get_pixel(posmod(x - rect.position.x, 32), posmod(y - rect.position.y, 32))
			image.set_pixelv(point + pivot(family), color)
	# Small highlights follow the screen-space light, not the object's facing.
	_paint(image, family, Rect2i(rect.position + Vector2i(17, 5), Vector2i(26, 1)), LIGHT)
	_paint(image, family, Rect2i(rect.position + Vector2i(8, 12), Vector2i(1, 12)), LIGHT)
	_paint(image, family, Rect2i(rect.position + Vector2i(21, rect.size.y - 5), Vector2i(42, 1)), SHADE)

static func _contact(image: Image, family: String, point: Vector2i) -> void:
	_paint(image, family, Rect2i(point + Vector2i(1, 0), Vector2i(4, 1)), CONTACT)
	_paint(image, family, Rect2i(point + Vector2i(2, 1), Vector2i(3, 1)), CONTACT)

static func _leg(image: Image, family: String, surface: Vector2i, ground: Vector2i) -> void:
	var top := mini(surface.y, ground.y)
	var height := maxi(4, absi(ground.y - surface.y) + 2)
	_paint(image, family, Rect2i(surface.x - 3, top, 6, height), INK)
	_paint(image, family, Rect2i(surface.x - 1, top + 1, 2, height - 2), MID)
	_paint(image, family, Rect2i(surface.x - 1, top + 1, 1, height - 3), LIGHT)

static func _draw_low(parts: Dictionary[String, Image], side: String, tile: Image) -> void:
	var family := "low_coffee_table"
	var p := profile(family, side)
	var floor: Rect2i = p.floor
	var top: Rect2i = p.top
	var points: Array[Vector2i] = [
		floor.position + Vector2i(8, 7), Vector2i(floor.end.x - 8, floor.position.y + 7),
		Vector2i(floor.position.x + 8, floor.end.y - 5), floor.end - Vector2i(8, 5),
	]
	for point: Vector2i in points: _contact(parts.floor_shadow, family, point)
	for index: int in range(points.size()):
		var target := parts.rear_structure if index < 2 else parts.front_structure
		_leg(target, family, points[index] - Vector2i(0, int(p.rise)), points[index])
	_draw_chamfered_top(parts.rear_structure, family, top, tile)
	_paint(parts.front_structure, family, Rect2i(top.position + Vector2i(3, top.size.y - 4), Vector2i(top.size.x - 6, 4)), EDGE)
	_paint(parts.front_structure, family, Rect2i(top.position + Vector2i(5, top.size.y - 3), Vector2i(top.size.x - 10, 1)), LIGHT)

static func _draw_cafe(parts: Dictionary[String, Image], side: String, tile: Image) -> void:
	var family := "cafe_table"
	var p := profile(family, side)
	var center: Vector2i = p.center
	var top: Rect2i = p.top
	var back_ground := center + Vector2i(0, -12)
	var front_ground := center + Vector2i(0, 20)
	_contact(parts.floor_shadow, family, back_ground + Vector2i(-10, 0))
	_contact(parts.floor_shadow, family, front_ground + Vector2i(8, 0))
	# V2 keeps the top/pedestal/base design but extends the post into the foot.
	# V1 stopped at center+6 while the base began at center+13, leaving a
	# visible seven-pixel air gap. The one-pixel overlap at center+13 makes the
	# support a single connected native silhouette in every translated view.
	_paint(parts.rear_structure, family, Rect2i(center + Vector2i(-5, -42), Vector2i(10, 56)), INK)
	_paint(parts.rear_structure, family, Rect2i(center + Vector2i(-2, -40), Vector2i(4, 53)), CHARCOAL)
	_paint(parts.rear_structure, family, Rect2i(center + Vector2i(-1, -39), Vector2i(1, 51)), METAL_LIGHT)
	_draw_chamfered_top(parts.rear_structure, family, top, tile)
	_paint(parts.front_structure, family, Rect2i(center + Vector2i(-16, 13), Vector2i(32, 6)), INK)
	_paint(parts.front_structure, family, Rect2i(center + Vector2i(-12, 14), Vector2i(24, 3)), CHARCOAL)
	_paint(parts.front_structure, family, Rect2i(top.position + Vector2i(4, top.size.y - 4), Vector2i(top.size.x - 8, 4)), EDGE)

static func _draw_round(parts: Dictionary[String, Image], side: String, tile: Image) -> void:
	var family := "round_meeting_table"
	var p := profile(family, side)
	var top: Rect2i = p.top
	for point: Vector2i in [Vector2i(-20, 25), Vector2i(16, 25), Vector2i(-12, 38), Vector2i(20, 38)]:
		_contact(parts.floor_shadow, family, point)
	_paint(parts.rear_structure, family, Rect2i(-7, -34, 14, 69), INK)
	_paint(parts.rear_structure, family, Rect2i(-3, -32, 6, 65), CHARCOAL)
	_paint(parts.rear_structure, family, Rect2i(-2, -31, 2, 62), METAL_LIGHT)
	_draw_round_top(parts.rear_structure, family, top, tile)
	_paint(parts.front_structure, family, Rect2i(-28, 31, 56, 8), INK)
	_paint(parts.front_structure, family, Rect2i(-22, 32, 44, 4), CHARCOAL)
	_paint(parts.front_structure, family, Rect2i(-18, 32, 26, 1), METAL_LIGHT)
	# A compact front rim clarifies the ellipse without filling its lower half.
	_paint(parts.front_structure, family, Rect2i(-25, top.end.y - 3, 50, 3), EDGE)
	_paint(parts.front_structure, family, Rect2i(-18, top.end.y - 3, 30, 1), LIGHT)

static func layers(family: String, side: String) -> Dictionary[String, Image]:
	if profile(family, side).is_empty(): return {}
	var tile := _tile()
	if tile == null or tile.get_size() != Vector2i(32, 32): return {}
	var result: Dictionary[String, Image] = {}
	for layer_name: String in LAYERS: result[layer_name] = _image(family)
	match family:
		"low_coffee_table": _draw_low(result, side, tile)
		"cafe_table": _draw_cafe(result, side, tile)
		"round_meeting_table": _draw_round(result, side, tile)
	return result

static func whole(family: String, side: String) -> Image:
	var result := _image(family)
	var parts := layers(family, side)
	for layer_name: String in LAYERS:
		result.blend_rect(parts[layer_name], Rect2i(Vector2i.ZERO, canvas(family)), Vector2i.ZERO)
	return result

static func layer_depth(layer_name: String) -> int:
	return {"floor_shadow": -2, "rear_structure": -1, "front_structure": 1}.get(layer_name, 0)

static func descriptor(family: String, side: String, layer_name: String) -> Dictionary:
	var size := canvas(family)
	var offset := sprite_offset(family)
	return {
		"name": family.to_pascal_case() + layer_name.to_pascal_case(),
		"art": output_root(family) + side + "-" + layer_name + ".png",
		"region": [0, 0, size.x, size.y], "offset": [offset.x, offset.y],
		"z_offset": layer_depth(layer_name),
	}

static func catalog_entry(family: String) -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var geometry := profile(family, side)
		var used := whole(family, side).get_used_rect()
		var local := Rect2i(used.position - pivot(family), used.size)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in LAYERS: render_layers.append(descriptor(family, side, layer_name))
		profiles[side] = {
			"profile_kind": "decorative", "status": "calibration_candidate",
			"review": {"art": false, "geometry": false},
			"occupied": geometry.occupied.duplicate(true), "clearance": [],
			"anchor_offset": [0, 0],
			"visual_bounds": [local.position.x, local.position.y, local.size.x, local.size.y],
			"hit_bounds": [local.position.x, local.position.y, local.size.x, local.size.y],
			"render_layers": render_layers, "ambient_overlays": [],
			"calibration_limitations": [
				"Bare passive table art only; no interaction, service, chair, seat, work pose, role kit or production approval.",
				"Direction equivalence is declared by physical symmetry; no finished bitmap is rotated or mirrored.",
			],
		}
	return {"facings": SIDES.duplicate(), "facing_profiles": profiles}
