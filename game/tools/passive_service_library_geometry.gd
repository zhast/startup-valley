class_name PassiveServiceLibraryGeometry
extends RefCounted
## DEV ONLY. Deterministic passive-library geometry for the water/tea station,
## printer/scanner station and rolling resource cart. Every facing is authored in
## fixed screen axes. No finished bitmap is rotated, mirrored, flipped or scaled.

const FAMILIES: Array[String] = ["water_station", "printer_scanner_station", "resource_cart"]
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const ROOTS := {
	"water_station": "res://tests/fixtures/furniture-calibration/water-station-v2",
	"printer_scanner_station": "res://tests/fixtures/furniture-calibration/printer-scanner-station-v1",
	"resource_cart": "res://tests/fixtures/furniture-calibration/resource-cart-v1",
}
const OAK_HORIZONTAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-horizontal-v2.png"
const OAK_VERTICAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-vertical-v2.png"
const POWDERCOAT := "res://tests/fixtures/furniture-calibration/materials/charcoal-powdercoat-v1.png"

const INK := Color("2b2b29")
const INK_DEEP := Color("1d2223")
const SHADOW := Color("5f5948")
const STEEL := Color("7b8585")
const STEEL_LIGHT := Color("b2bcba")
const STEEL_DARK := Color("4b5556")
const WATER_BODY := Color("d8d1ba")
const WATER_PANEL := Color("b9b29d")
const WATER_BLUE := Color("4c96b6")
const WATER_LIGHT := Color("a8d8df")
const TEA_COPPER := Color("a96635")
const TEA_SHADE := Color("744325")
const CUP := Color("eee6cd")
const PRINTER_BODY := Color("dedbd0")
const PRINTER_SHADE := Color("8d918d")
const PAPER := Color("f3ead4")
const PAPER_SHADE := Color("c9c2af")
const OAK_EDGE := Color("6c4529")
const OAK_LIGHT := Color("cf8f45")
const OAK_SHADE := Color("8d542b")

static func canvas(family: String) -> Vector2i:
	return Vector2i(160, 240) if family == "water_station" else Vector2i(160, 208)

static func pivot(family: String) -> Vector2i:
	return Vector2i(80, 176) if family == "water_station" else Vector2i(80, 144)

static func sprite_offset(family: String) -> Vector2i:
	return canvas(family) / 2 - pivot(family)

static func revision_id(family: String) -> String:
	return family.replace("_", "-") + ("-v2" if family == "water_station" else "-v1")

static func base_elevation(family: String) -> int:
	return {"water_station": 40, "printer_scanner_station": 32, "resource_cart": 72}.get(family, 0)

static func planned_vertical_envelope(family: String) -> int:
	return {"water_station": 112, "printer_scanner_station": 80, "resource_cart": 80}.get(family, 0)

static func expected_feature_rise(family: String) -> int:
	# Vertical feature height above the physical floor plane, before adding its
	# 32/64px screen-projected footprint depth.
	return {"water_station": 80, "printer_scanner_station": 62, "resource_cart": 88}.get(family, 0)

static func dimension_review(family: String) -> Dictionary:
	return {
		"planned_canvas_retained": [canvas(family).x, canvas(family).y],
		"planned_floor_anchor_retained": [pivot(family).x, pivot(family).y],
		"planned_vertical_feature_envelope_px": planned_vertical_envelope(family),
		"measured_base_elevation_px": base_elevation(family),
		"authored_vertical_feature_rise_px": expected_feature_rise(family),
		"north_south_top_plane_depth_px": 32,
		"east_west_top_plane_depth_px": 64,
		"maximum_expected_projected_rise_px": expected_feature_rise(family) + 64,
		"revision": "Water v2 replaces only the rejected narrow reservoir with a supported broad stepped jug; base elevation, footprint top plane, contact geometry, canvas, pivot, scale and masks stay unchanged. " if family == "water_station" else "The planned rise is retained as the vertical feature envelope. Full screen-projected rise is recorded separately because a truthful E/W top plane also contains the exact 64px depth of the 1x2 physical footprint. Canvas, pivot, scale and collision masks do not change.",
	}

static func _occupied(side: String) -> Array:
	return {
		"north": [[1, 0], [0, 0]],
		"east": [[0, 1], [0, 0]],
		"south": [[-1, 0], [0, 0]],
		"west": [[0, -1], [0, 0]],
	}.get(side, [])

static func _floor(side: String) -> Rect2i:
	match side:
		"north": return Rect2i(-16, -16, 64, 32)
		"east": return Rect2i(-16, -16, 32, 64)
		"south": return Rect2i(-48, -16, 64, 32)
		"west": return Rect2i(-16, -48, 32, 64)
	return Rect2i()

static func _interaction(side: String) -> Array:
	return {"north": [0, -1], "east": [1, 0], "south": [0, 1], "west": [-1, 0]}.get(side, [])

static func _gaze(side: String) -> Array:
	return {"north": [0, 1], "east": [-1, 0], "south": [0, -1], "west": [1, 0]}.get(side, [])

static func _approach_gaze(side: String) -> String:
	return {"north": "south", "east": "west", "south": "north", "west": "east"}.get(side, "")

static func profile(family: String, side: String) -> Dictionary:
	if family not in FAMILIES or side not in SIDES: return {}
	var floor := _floor(side)
	var elevation := base_elevation(family)
	var top := Rect2i(floor.position - Vector2i(0, elevation), floor.size)
	var face := Rect2i(top.position.x, top.end.y, top.size.x, elevation)
	var identity: String = str({
		"north": "rear",
		"east": "service_front_right_end",
		"south": "service_front",
		"west": "service_front_left_end",
	}.get(side, ""))
	var role_identity := {}
	match family:
		"water_station":
			role_identity = {
				"camera_face": "reservoir_and_rear_cable" if side == "north" else "right_dispenser_end" if side == "east" else "taps_kettle_and_cups" if side == "south" else "left_dispenser_end",
				"water_dispenser": true,
				"tea_kettle": true,
				"cups": 3,
			}
		"printer_scanner_station":
			role_identity = {
				"camera_face": "hinge_and_cable_rear" if side == "north" else "right_scanner_end" if side == "east" else "output_slot_and_paper_tray" if side == "south" else "left_scanner_end",
				"scanner_lid": true,
				"paper_is_static": true,
			}
		"resource_cart":
			role_identity = {
				"camera_face": "rear_handle" if side == "north" else "right_handle_end" if side == "east" else "open_tray_fronts" if side == "south" else "left_handle_end",
				"open_trays": 2,
				"casters": 4,
				"mobile_behavior_implemented": false,
			}
	return {
		"family": family,
		"facing": side,
		"service_side": side,
		"approach_gaze": _approach_gaze(side),
		"employee_look_vector": _gaze(side),
		"interaction": _interaction(side),
		"clearance": [_interaction(side)],
		"occupied": _occupied(side),
		"footprint": [2, 1] if side in ["north", "south"] else [1, 2],
		"axis": "horizontal" if side in ["north", "south"] else "vertical",
		"floor": floor,
		"top": top,
		"front": face,
		"contact_y": floor.end.y,
		"base_elevation": elevation,
		"top_plane_depth": floor.size.y,
		"base_projected_rise": floor.end.y - top.position.y,
		"base_solid_bounds": Rect2i(top.position, Vector2i(top.size.x, top.size.y + elevation)),
		"camera_face_identity": identity,
		"role_identity": role_identity,
		"canvas": canvas(family),
		"pivot": pivot(family),
		"dimension_review": dimension_review(family),
		"runtime_approved": false,
		"interaction_implemented": false,
	}

static func _image(family: String) -> Image:
	var result := Image.create(canvas(family).x, canvas(family).y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _paint(image: Image, family: String, rect: Rect2i, color: Color) -> void:
	if rect.has_area(): image.fill_rect(Rect2i(rect.position + pivot(family), rect.size), color)

static func _pixel(image: Image, family: String, point: Vector2i, color: Color) -> void:
	image.set_pixelv(point + pivot(family), color)

static func _tile(image: Image, family: String, rect: Rect2i, source_path: String) -> bool:
	var tile := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if tile == null or tile.get_size() != Vector2i(32, 32): return false
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			image.set_pixelv(Vector2i(x, y) + pivot(family), tile.get_pixel(posmod(x, 32), posmod(y, 32)))
	return true

static func _panel(image: Image, family: String, rect: Rect2i, fill: Color) -> void:
	_paint(image, family, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: _paint(image, family, rect.grow(-1), fill)

static func _shadow(image: Image, family: String, floor: Rect2i) -> void:
	var y := floor.end.y - 5
	_paint(image, family, Rect2i(floor.position.x - 4, y, 4, 4), SHADOW)
	_paint(image, family, Rect2i(floor.end.x, y + 1, 4, 3), SHADOW)
	_pixel(image, family, Vector2i(floor.position.x - 5, y + 2), SHADOW)
	_pixel(image, family, Vector2i(floor.end.x + 4, y + 2), SHADOW)

static func _solid(rear: Image, family: String, p: Dictionary, top_fill: Color, face_fill: Color, tile_path := "") -> void:
	var top: Rect2i = p.top
	var face: Rect2i = p.front
	_paint(rear, family, top, INK)
	if tile_path.is_empty(): _paint(rear, family, top.grow(-1), top_fill)
	else: _tile(rear, family, top.grow(-1), tile_path)
	_paint(rear, family, Rect2i(top.position + Vector2i.ONE, Vector2i(top.size.x - 2, 1)), STEEL_LIGHT if family != "resource_cart" else OAK_LIGHT)
	_paint(rear, family, Rect2i(top.position + Vector2i(1, 2), Vector2i(1, top.size.y - 3)), STEEL_LIGHT if family != "resource_cart" else OAK_LIGHT)
	_paint(rear, family, Rect2i(top.position.x + 2, top.end.y - 2, top.size.x - 3, 1), STEEL_DARK if family != "resource_cart" else OAK_SHADE)
	_paint(rear, family, Rect2i(top.end.x - 2, top.position.y + 2, 1, top.size.y - 3), STEEL_DARK if family != "resource_cart" else OAK_SHADE)
	_paint(rear, family, face, INK)
	_paint(rear, family, face.grow(-1), face_fill)
	_paint(rear, family, Rect2i(face.position + Vector2i.ONE, Vector2i(1, face.size.y - 2)), STEEL_LIGHT if family != "resource_cart" else OAK_LIGHT)
	_paint(rear, family, Rect2i(face.end.x - 2, face.position.y + 1, 1, face.size.y - 2), STEEL_DARK if family != "resource_cart" else OAK_SHADE)
	_paint(rear, family, Rect2i(face.position.x + 1, face.end.y - 2, face.size.x - 2, 1), STEEL_DARK if family != "resource_cart" else OAK_SHADE)

static func _draw_water_jug(image: Image, rect: Rect2i) -> void:
	# Broad supported office-water jug with stepped shoulders, a short collar and
	# neck, and fixed-camera highlights. It has no label, glow or liquid metric.
	var family := "water_station"
	var center_x := rect.position.x + rect.size.x / 2
	var body := Rect2i(rect.position.x, rect.position.y + 10, rect.size.x, rect.size.y - 10)
	var lower_shoulder := Rect2i(rect.position.x + 2, rect.position.y + 8, rect.size.x - 4, 4)
	var upper_shoulder := Rect2i(rect.position.x + 5, rect.position.y + 6, rect.size.x - 10, 4)
	var collar := Rect2i(center_x - 6, rect.position.y + 3, 12, 5)
	var neck := Rect2i(center_x - 3, rect.position.y, 6, 5)
	for shape: Rect2i in [body, lower_shoulder, upper_shoulder, collar, neck]: _paint(image, family, shape, INK)
	_paint(image, family, body.grow(-1), WATER_BLUE)
	_paint(image, family, Rect2i(lower_shoulder.position + Vector2i(1, 1), lower_shoulder.size - Vector2i(2, 1)), WATER_BLUE)
	_paint(image, family, Rect2i(upper_shoulder.position + Vector2i(1, 1), upper_shoulder.size - Vector2i(2, 1)), WATER_BLUE)
	_paint(image, family, Rect2i(collar.position + Vector2i(1, 1), collar.size - Vector2i(2, 1)), WATER_BLUE)
	_paint(image, family, Rect2i(neck.position + Vector2i(1, 1), neck.size - Vector2i(2, 1)), WATER_LIGHT)
	_paint(image, family, Rect2i(body.position.x + 3, body.position.y + 2, 2, body.size.y - 5), WATER_LIGHT)
	_paint(image, family, Rect2i(body.end.x - 4, body.position.y + 3, 2, body.size.y - 6), Color("34718c"))
	_pixel(image, family, Vector2i(lower_shoulder.position.x + 4, lower_shoulder.position.y + 1), WATER_LIGHT)

static func _draw_kettle(image: Image, center: Vector2i, horizontal := true) -> void:
	var family := "water_station"
	var body := Rect2i(center - Vector2i(6, 4), Vector2i(12, 9)) if horizontal else Rect2i(center - Vector2i(4, 6), Vector2i(9, 12))
	_panel(image, family, body, TEA_COPPER)
	if horizontal:
		_paint(image, family, Rect2i(body.end.x, body.position.y + 2, 4, 3), TEA_SHADE)
		_paint(image, family, Rect2i(body.position.x + 2, body.position.y - 3, body.size.x - 4, 2), INK)
	else:
		_paint(image, family, Rect2i(body.position.x + 2, body.end.y, 3, 4), TEA_SHADE)
		_paint(image, family, Rect2i(body.position.x - 3, body.position.y + 2, 2, body.size.y - 4), INK)

static func _draw_cups(image: Image, side: String, top: Rect2i) -> void:
	var family := "water_station"
	if side in ["north", "south"]:
		var y := top.end.y - 7 if side == "south" else top.position.y + 4
		for index: int in range(3): _panel(image, family, Rect2i(top.end.x - 19 + index * 5, y, 4, 5), CUP)
	else:
		var x := top.end.x - 7 if side == "east" else top.position.x + 3
		for index: int in range(3): _panel(image, family, Rect2i(x, top.end.y - 19 + index * 5, 5, 4), CUP)

static func _draw_water(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	_solid(rear, "water_station", p, WATER_BODY, WATER_PANEL)
	var top: Rect2i = p.top
	var face: Rect2i = p.front
	var jug_width := 28 if side in ["north", "south"] else 24
	var bottle := Rect2i(top.position.x + 4, top.position.y - 39, jug_width, 37)
	_draw_water_jug(rear, bottle)
	var tower := Rect2i(bottle.position.x - 2, bottle.end.y - 1, bottle.size.x + 4, maxi(12, top.end.y - bottle.end.y + 1))
	_panel(rear, "water_station", tower, WATER_PANEL)
	if side in ["north", "south"]:
		_draw_kettle(front, Vector2i(top.end.x - 23, top.position.y + top.size.y / 2), true)
	else:
		_draw_kettle(front, Vector2i(top.position.x + top.size.x / 2, top.end.y - 23), false)
	_draw_cups(front, side, top)
	var service_panel := face.grow(-5)
	_panel(front, "water_station", service_panel, WATER_BODY)
	match side:
		"north":
			_paint(front, "water_station", Rect2i(service_panel.position.x + 5, service_panel.position.y + 5, service_panel.size.x - 10, 3), STEEL_DARK)
			_paint(front, "water_station", Rect2i(service_panel.position.x + 7, service_panel.end.y - 8, 5, 3), INK)
		"east":
			_paint(front, "water_station", Rect2i(service_panel.end.x - 4, service_panel.position.y + 5, 2, service_panel.size.y - 10), STEEL_DARK)
			_pixel(front, "water_station", Vector2i(service_panel.position.x + 5, service_panel.position.y + 8), WATER_BLUE)
		"south":
			var niche := Rect2i(service_panel.position.x + 7, service_panel.position.y + 5, 22, 17)
			_panel(front, "water_station", niche, STEEL_DARK)
			for x: int in [niche.position.x + 6, niche.position.x + 14]:
				_paint(front, "water_station", Rect2i(x, niche.position.y + 2, 3, 5), WATER_BLUE)
			_paint(front, "water_station", Rect2i(niche.position.x + 3, niche.end.y - 4, niche.size.x - 6, 2), STEEL)
		"west":
			_paint(front, "water_station", Rect2i(service_panel.position.x + 2, service_panel.position.y + 5, 2, service_panel.size.y - 10), STEEL_LIGHT)
			_pixel(front, "water_station", Vector2i(service_panel.end.x - 6, service_panel.position.y + 11), TEA_COPPER)

static func _draw_printer_device(rear: Image, front: Image, side: String, top: Rect2i) -> void:
	var family := "printer_scanner_station"
	var device_top := Rect2i()
	var device_face := Rect2i()
	if side in ["north", "south"]:
		device_top = Rect2i(top.position.x + 8, top.position.y - 22, top.size.x - 16, 18)
		device_face = Rect2i(device_top.position.x, device_top.end.y, device_top.size.x, 22)
	else:
		device_top = Rect2i(top.position.x + 6, top.position.y - 22, top.size.x - 12, 38)
		device_face = Rect2i(device_top.position.x, device_top.end.y, device_top.size.x, 22)
	_panel(rear, family, device_top, PRINTER_BODY)
	_paint(rear, family, Rect2i(device_top.position + Vector2i(3, 3), device_top.size - Vector2i(6, 6)), PRINTER_SHADE)
	_paint(rear, family, Rect2i(device_top.position + Vector2i(5, 5), device_top.size - Vector2i(10, 10)), INK_DEEP)
	_panel(rear, family, device_face, PRINTER_BODY)
	var panel := device_face.grow(-4)
	match side:
		"north":
			_paint(front, family, Rect2i(panel.position.x + 3, panel.position.y + 3, panel.size.x - 6, 2), STEEL_DARK)
			_paint(front, family, Rect2i(panel.end.x - 7, panel.position.y + 7, 3, 3), STEEL)
			_panel(front, family, Rect2i(panel.position.x + 6, panel.end.y - 7, panel.size.x - 12, 4), PAPER)
		"east":
			_paint(front, family, Rect2i(panel.end.x - 3, panel.position.y + 3, 2, panel.size.y - 6), STEEL_DARK)
			_panel(front, family, Rect2i(panel.position.x + 3, panel.end.y - 7, panel.size.x - 6, 4), PAPER)
		"south":
			var slot := Rect2i(panel.position.x + 3, panel.position.y + 3, panel.size.x - 6, 4)
			_panel(front, family, slot, INK_DEEP)
			var paper := Rect2i(panel.position.x + 7, slot.end.y, panel.size.x - 14, 8)
			_panel(front, family, paper, PAPER)
			_paint(front, family, Rect2i(paper.position.x + 3, paper.position.y + 3, paper.size.x - 6, 1), PAPER_SHADE)
		"west":
			_paint(front, family, Rect2i(panel.position.x + 1, panel.position.y + 3, 2, panel.size.y - 6), STEEL_LIGHT)
			_panel(front, family, Rect2i(panel.position.x + 3, panel.end.y - 7, panel.size.x - 6, 4), PAPER)

static func _draw_printer(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	_solid(rear, "printer_scanner_station", p, PRINTER_SHADE, PRINTER_BODY, POWDERCOAT)
	_draw_printer_device(rear, front, side, p.top)
	var face: Rect2i = p.front
	var cabinet := face.grow(-5)
	_panel(front, "printer_scanner_station", cabinet, PRINTER_SHADE)
	if side in ["north", "south"]:
		_paint(front, "printer_scanner_station", Rect2i(cabinet.position.x + 3, cabinet.position.y + cabinet.size.y / 2, cabinet.size.x - 6, 2), INK)
		if side == "south": _panel(front, "printer_scanner_station", Rect2i(cabinet.position.x + 8, cabinet.end.y - 8, cabinet.size.x - 16, 4), PAPER)
	else:
		_paint(front, "printer_scanner_station", Rect2i(cabinet.position.x + cabinet.size.x / 2, cabinet.position.y + 3, 2, cabinet.size.y - 6), INK)

static func _tray(image: Image, family: String, rect: Rect2i, tile_path: String, rim_color: Color) -> void:
	_paint(image, family, rect, INK)
	_tile(image, family, rect.grow(-2), tile_path)
	_paint(image, family, Rect2i(rect.position + Vector2i.ONE, Vector2i(rect.size.x - 2, 2)), OAK_LIGHT)
	_paint(image, family, Rect2i(rect.position.x + 1, rect.end.y - 3, rect.size.x - 2, 2), rim_color)
	_paint(image, family, Rect2i(rect.end.x - 3, rect.position.y + 2, 2, rect.size.y - 4), OAK_SHADE)

static func _draw_cart(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	var family := "resource_cart"
	var floor: Rect2i = p.floor
	var top: Rect2i = p.top
	# The lower tray sits four pixels above the floor plane. The 68px elevation
	# difference between tray surfaces leaves a real open gap even in the 64px-deep
	# E/W projections; v1 must not collapse into a closed cabinet silhouette.
	var lower := Rect2i(floor.position - Vector2i(0, 4), floor.size)
	var tile_path := OAK_HORIZONTAL if side in ["north", "south"] else OAK_VERTICAL
	_tray(rear, family, top, tile_path, OAK_EDGE)
	_tray(front, family, lower, tile_path, OAK_EDGE)
	# Exact screen-axis legs link both trays to four small casters at floor contact.
	var leg_xs: Array[int] = [floor.position.x + 4, floor.end.x - 7]
	for x: int in leg_xs:
		_paint(rear, family, Rect2i(x, top.end.y - 1, 3, floor.end.y - top.end.y - 1), STEEL_DARK)
		_paint(front, family, Rect2i(x + 1, lower.end.y - 1, 2, floor.end.y - lower.end.y), STEEL)
	for x: int in [floor.position.x + 3, floor.end.x - 8]:
		_panel(front, family, Rect2i(x, floor.end.y - 5, 6, 5), INK_DEEP)
	# Handle orientation is separately authored; no mobile behavior is implied.
	match side:
		"north":
			_paint(rear, family, Rect2i(top.position.x + 4, top.position.y - 16, 3, 17), STEEL_DARK)
			_paint(rear, family, Rect2i(top.position.x + 4, top.position.y - 16, top.size.x - 8, 3), STEEL)
			_paint(rear, family, Rect2i(top.end.x - 7, top.position.y - 16, 3, 17), STEEL_DARK)
		"east":
			_paint(rear, family, Rect2i(top.end.x - 2, top.position.y + 4, 22, 3), STEEL)
			_paint(rear, family, Rect2i(top.end.x + 17, top.position.y + 4, 3, 24), STEEL_DARK)
		"south":
			_paint(front, family, Rect2i(top.position.x + 4, top.end.y - 1, 3, 20), STEEL_DARK)
			_paint(front, family, Rect2i(top.position.x + 4, top.end.y + 16, top.size.x - 8, 3), STEEL)
			_paint(front, family, Rect2i(top.end.x - 7, top.end.y - 1, 3, 20), STEEL_DARK)
		"west":
			_paint(rear, family, Rect2i(top.position.x - 20, top.end.y - 7, 22, 3), STEEL)
			_paint(rear, family, Rect2i(top.position.x - 20, top.end.y - 28, 3, 24), STEEL_DARK)
	# A few neutral supply blocks sit in separate trays without text or role claims.
	if side in ["north", "south"]:
		_panel(front, family, Rect2i(top.position.x + 9, top.position.y + 7, 13, 8), WATER_BLUE)
		_panel(front, family, Rect2i(top.end.x - 22, top.position.y + 10, 12, 7), TEA_COPPER)
		_panel(front, family, Rect2i(lower.position.x + 11, lower.position.y + 8, lower.size.x - 22, 7), PAPER_SHADE)
	else:
		_panel(front, family, Rect2i(top.position.x + 8, top.position.y + 9, 8, 13), WATER_BLUE)
		_panel(front, family, Rect2i(top.position.x + 11, top.end.y - 22, 7, 12), TEA_COPPER)
		_panel(front, family, Rect2i(lower.position.x + 8, lower.position.y + 11, 7, lower.size.y - 22), PAPER_SHADE)

static func layers(family: String, side: String) -> Dictionary[String, Image]:
	var p := profile(family, side)
	if p.is_empty(): return {}
	var result: Dictionary[String, Image] = {
		"floor_shadow": _image(family),
		"rear_structure": _image(family),
		"front_structure": _image(family),
	}
	_shadow(result.floor_shadow, family, p.floor)
	match family:
		"water_station": _draw_water(result.rear_structure, result.front_structure, side, p)
		"printer_scanner_station": _draw_printer(result.rear_structure, result.front_structure, side, p)
		"resource_cart": _draw_cart(result.rear_structure, result.front_structure, side, p)
	return result

static func whole(family: String, side: String) -> Image:
	var source := layers(family, side)
	return binary_over(binary_over(source.floor_shadow, source.rear_structure), source.front_structure)

static func binary_over(back: Image, near: Image) -> Image:
	var result := back.get_data().duplicate()
	var foreground := near.get_data()
	for at: int in range(0, result.size(), 4):
		if foreground[at + 3] != 0:
			for channel: int in range(4): result[at + channel] = foreground[at + channel]
	return Image.create_from_data(back.get_width(), back.get_height(), false, Image.FORMAT_RGBA8, result)

static func descriptor(family: String, side: String, layer_name: String) -> Dictionary:
	var base := "%s%s%s%s" % [family.to_pascal_case(), "V2" if family == "water_station" else "V1", side.to_pascal_case(), layer_name.to_pascal_case()]
	return {
		"name": base,
		"art": str(ROOTS[family]).path_join("%s-%s.png" % [side, layer_name]),
		"region": [0, 0, canvas(family).x, canvas(family).y],
		"offset": [sprite_offset(family).x, sprite_offset(family).y],
		"z_offset": {"floor_shadow": -2, "rear_structure": -1, "front_structure": 1}[layer_name],
	}

static func catalog_entry(family: String) -> Dictionary:
	if family not in FAMILIES: return {}
	var profiles := {}
	for side: String in SIDES:
		var p := profile(family, side)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in LAYERS: render_layers.append(descriptor(family, side, layer_name))
		var opaque_bounds := whole(family, side).get_used_rect()
		var local_bounds := Rect2i(opaque_bounds.position - pivot(family), opaque_bounds.size)
		profiles[side] = {
			"profile_kind": "decorative",
			"status": "calibration_candidate",
			"review": {"art": false, "geometry": false},
			"occupied": p.occupied.duplicate(true),
			"clearance": p.clearance.duplicate(true),
			"anchor_offset": [0, 0],
			"render_layers": render_layers,
			"visual_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"hit_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"ambient_overlays": [],
			"standing_viewpoints": [{"cell": p.interaction.duplicate(), "visual_bounds": [-24, -72, 48, 80]}],
			"proposed_service_side": p.service_side,
			"proposed_approach_gaze": p.approach_gaze,
			"proposed_employee_look_vector": p.employee_look_vector.duplicate(),
			"proposed_interaction_cell": p.interaction.duplicate(),
			"dimension_review": p.dimension_review.duplicate(true),
			"calibration_limitations": ["Passive art/geometry review only; service-side metadata is not an implemented action.", "No worker, role, backend, transaction, live metric, default placement, or runtime registration is supplied."],
		}
	return {
		"display_name": family.replace("_", " ").capitalize() + (" v2 candidate" if family == "water_station" else " v1 candidate"),
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none",
		"facing_profiles": profiles,
	}
