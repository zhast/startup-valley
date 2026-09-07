class_name PassiveUtilityLibraryV2Geometry
extends RefCounted
## DEV ONLY. Perspective-correct v2 replacements for three rejected v1 passive
## bases. Each solid is an explicit vertical extrusion: the top plane is the
## exact physical floor rectangle translated upward by a family-wide elevation,
## and the camera-front elevation continues from its near edge to floor contact.
## N/E/S/W are independently detailed in fixed screen axes. No service, worker,
## runtime registration, default placement, or finished-raster transform exists.

const FAMILIES: Array[String] = ["tall_storage_cabinet", "server_cabinet", "recycling_sorter"]
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const ROOTS := {
	"tall_storage_cabinet": "res://tests/fixtures/furniture-calibration/tall-storage-cabinet-v2",
	"server_cabinet": "res://tests/fixtures/furniture-calibration/server-cabinet-v2",
	"recycling_sorter": "res://tests/fixtures/furniture-calibration/recycling-sorter-v2",
}
const V1_ROOTS := {
	"tall_storage_cabinet": "res://tests/fixtures/furniture-calibration/tall-storage-cabinet-v1",
	"server_cabinet": "res://tests/fixtures/furniture-calibration/server-cabinet-v1",
	"recycling_sorter": "res://tests/fixtures/furniture-calibration/recycling-sorter-v1",
}
const POWDERCOAT := "res://tests/fixtures/furniture-calibration/materials/charcoal-powdercoat-v1.png"
const OAK_HORIZONTAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-horizontal-v2.png"
const OAK_VERTICAL := "res://tests/fixtures/furniture-calibration/materials-v2/oak-vertical-v2.png"

const INK := Color("282622")
const INK_DEEP := Color("17191b")
const FRAME := Color("383833")
const FRAME_LIGHT := Color("53524a")
const STEEL := Color("899398")
const STEEL_LIGHT := Color("c5ccca")
const STEEL_DARK := Color("3e474b")
const OAK_EDGE := Color("77512f")
const OAK_LIGHT := Color("d1a369")
const OAK_SHADE := Color("583d28")
const SUPPLY_PANEL := Color("88613b")
const SUPPLY_BACK := Color("684b34")
const SHADOW := Color("554e42")
const SLOT := Color("20252a")
const RECYCLE_BODY := Color("d8cfb8")
const RECYCLE_SHADE := Color("9d9583")
const STREAM_BLUE := Color("3c7da0")
const STREAM_GREEN := Color("579064")
const STREAM_GREY := Color("777c78")

static func canvas(family: String) -> Vector2i:
	return Vector2i(160, 176) if family == "recycling_sorter" else Vector2i(160, 288)

static func pivot(family: String) -> Vector2i:
	return Vector2i(80, 112) if family == "recycling_sorter" else Vector2i(80, 224)

static func sprite_offset(family: String) -> Vector2i:
	return canvas(family) / 2 - pivot(family)

static func elevation(family: String) -> int:
	return {"tall_storage_cabinet": 80, "server_cabinet": 72, "recycling_sorter": 32}.get(family, 0)

static func planned_elevation_envelope(family: String) -> int:
	return 48 if family == "recycling_sorter" else 160

static func dimension_review(family: String) -> Dictionary:
	return {
		"planned_canvas_retained": [canvas(family).x, canvas(family).y],
		"planned_floor_anchor_retained": [pivot(family).x, pivot(family).y],
		"planned_vertical_elevation_envelope_px": planned_elevation_envelope(family),
		"measured_vertical_elevation_px": elevation(family),
		"north_south_top_plane_depth_px": 32,
		"east_west_top_plane_depth_px": 64,
		"maximum_projected_opaque_rise_px": elevation(family) + 64,
		"revision": "V1 treated the body as a flat elevation. V2 retains the original canvas, pivot and masks, but interprets the planned rise as the solid's vertical elevation and separately records the 32px or 64px projected footprint depth. The full top plane is the physical floor rectangle translated upward by one consistent family elevation.",
	}

static func _occupied(side: String) -> Array:
	match side:
		"north": return [[1, 0], [0, 0]]
		"east": return [[0, 1], [0, 0]]
		"south": return [[-1, 0], [0, 0]]
		"west": return [[0, -1], [0, 0]]
	return []

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
	var lift := elevation(family)
	var top := Rect2i(floor.position - Vector2i(0, lift), floor.size)
	var front := Rect2i(top.position.x, top.end.y, top.size.x, lift)
	var identity := ""
	match side:
		"north": identity = "rear"
		"east": identity = "service_front_right_end"
		"south": identity = "service_front"
		"west": identity = "service_front_left_end"
	var role_identity := {}
	match family:
		"tall_storage_cabinet":
			role_identity = {"camera_face": "paired_closed_doors" if side == "south" else "braced_rear" if side == "north" else "right_closed_end" if side == "east" else "left_closed_end", "open_storage": false}
		"server_cabinet":
			role_identity = {"camera_face": "rack_front" if side == "south" else "fan_and_cable_rear" if side == "north" else "right_vented_end" if side == "east" else "left_vented_end", "static_unlit_indicators": true}
		"recycling_sorter":
			role_identity = {"camera_face": "three_front_doors" if side == "south" else "closed_rear" if side == "north" else "right_end" if side == "east" else "left_end", "top_apertures": 3, "labels": "color_and_shape_only_no_text"}
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
		"front": front,
		"contact_y": floor.end.y,
		"elevation": lift,
		"top_plane_depth": floor.size.y,
		"projected_opaque_rise": floor.end.y - top.position.y,
		"solid_bounds": Rect2i(top.position, Vector2i(top.size.x, top.size.y + lift)),
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

static func _draw_shadow(image: Image, family: String, floor: Rect2i) -> void:
	# The solid occupies the entire projected floor plane, so only narrow lateral
	# contact marks remain visible. They never extend below the protected canvas.
	var y := floor.end.y - 5
	_paint(image, family, Rect2i(floor.position.x - 4, y, 4, 4), SHADOW)
	_paint(image, family, Rect2i(floor.end.x, y + 1, 4, 3), SHADOW)
	_pixel(image, family, Vector2i(floor.position.x - 5, y + 2), SHADOW)
	_pixel(image, family, Vector2i(floor.end.x + 4, y + 2), SHADOW)

static func _draw_solid(rear: Image, family: String, p: Dictionary, top_fill: Color, face_fill: Color, tile_path := "") -> void:
	var top: Rect2i = p.top
	var face: Rect2i = p.front
	_paint(rear, family, top, INK)
	if tile_path.is_empty(): _paint(rear, family, top.grow(-1), top_fill)
	else: _tile(rear, family, top.grow(-1), tile_path)
	# Fixed upper-left light on the actual top plane.
	_paint(rear, family, Rect2i(top.position + Vector2i.ONE, Vector2i(top.size.x - 2, 1)), OAK_LIGHT if family == "tall_storage_cabinet" else FRAME_LIGHT if family == "server_cabinet" else STEEL_LIGHT)
	_paint(rear, family, Rect2i(top.position + Vector2i(1, 2), Vector2i(1, top.size.y - 3)), OAK_LIGHT if family == "tall_storage_cabinet" else FRAME_LIGHT if family == "server_cabinet" else STEEL_LIGHT)
	_paint(rear, family, Rect2i(top.position.x + 2, top.end.y - 2, top.size.x - 3, 1), OAK_SHADE if family == "tall_storage_cabinet" else INK_DEEP if family == "server_cabinet" else RECYCLE_SHADE)
	_paint(rear, family, Rect2i(top.end.x - 2, top.position.y + 2, 1, top.size.y - 3), OAK_SHADE if family == "tall_storage_cabinet" else INK_DEEP if family == "server_cabinet" else RECYCLE_SHADE)
	# Camera-front elevation begins at the top plane's near edge and reaches the
	# physical floor contact exactly; this is not a trim pretending to be a top.
	_paint(rear, family, face, INK)
	_paint(rear, family, face.grow(-1), face_fill)
	_paint(rear, family, Rect2i(face.position + Vector2i(1, 1), Vector2i(1, face.size.y - 2)), OAK_LIGHT if family == "tall_storage_cabinet" else FRAME_LIGHT if family == "server_cabinet" else STEEL_LIGHT)
	_paint(rear, family, Rect2i(face.end.x - 2, face.position.y + 1, 1, face.size.y - 2), OAK_SHADE if family == "tall_storage_cabinet" else INK_DEEP if family == "server_cabinet" else RECYCLE_SHADE)
	_paint(rear, family, Rect2i(face.position.x + 1, face.end.y - 2, face.size.x - 2, 1), OAK_SHADE if family == "tall_storage_cabinet" else INK_DEEP if family == "server_cabinet" else RECYCLE_SHADE)

static func _panel(image: Image, family: String, rect: Rect2i, fill: Color) -> void:
	_paint(image, family, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: _paint(image, family, rect.grow(-1), fill)

static func _draw_tall(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	var tile_path := OAK_HORIZONTAL if side in ["north", "south"] else OAK_VERTICAL
	_draw_solid(rear, "tall_storage_cabinet", p, SUPPLY_PANEL, SUPPLY_PANEL, tile_path)
	var top: Rect2i = p.top
	var face: Rect2i = p.front
	# A small cap seam sits on the real top plane, proving the plane remains a
	# surface rather than a 2px face trim.
	_paint(front, "tall_storage_cabinet", Rect2i(top.position + Vector2i(5, top.size.y / 2), Vector2i(top.size.x - 10, 2)), OAK_EDGE)
	var panel := face.grow(-5)
	match side:
		"north":
			_panel(front, "tall_storage_cabinet", panel, SUPPLY_BACK)
			for y: int in [panel.position.y + 15, panel.end.y - 18]:
				_paint(front, "tall_storage_cabinet", Rect2i(panel.position.x + 4, y, panel.size.x - 8, 3), INK)
			for x: int in [panel.position.x + 3, panel.end.x - 4]:
				for y: int in [panel.position.y + 4, panel.end.y - 5]: _pixel(front, "tall_storage_cabinet", Vector2i(x, y), STEEL_DARK)
		"east":
			_panel(front, "tall_storage_cabinet", panel, SUPPLY_PANEL)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.end.x - 4, panel.position.y + 4, 2, panel.size.y - 8), OAK_EDGE)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.end.x - 8, panel.position.y + 29, 2, 18), STEEL_DARK)
			_pixel(front, "tall_storage_cabinet", Vector2i(panel.end.x - 7, panel.position.y + 30), STEEL_LIGHT)
		"south":
			_panel(front, "tall_storage_cabinet", panel, SUPPLY_PANEL)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position.x + 2, panel.position.y + 17, panel.size.x - 4, 2), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position.x + panel.size.x / 2 - 1, panel.position.y + 19, 2, panel.size.y - 21), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position.x + 4, panel.position.y + 4, panel.size.x - 8, 10), SUPPLY_BACK)
			for x: int in [panel.position.x + panel.size.x / 2 - 5, panel.position.x + panel.size.x / 2 + 3]:
				_paint(front, "tall_storage_cabinet", Rect2i(x, panel.position.y + 37, 2, 16), STEEL_DARK)
				_pixel(front, "tall_storage_cabinet", Vector2i(x + 1, panel.position.y + 38), STEEL_LIGHT)
		"west":
			_panel(front, "tall_storage_cabinet", panel, SUPPLY_PANEL)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position.x + 2, panel.position.y + 4, 2, panel.size.y - 8), OAK_EDGE)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position.x + 6, panel.position.y + 33, 2, 18), STEEL_DARK)
			_pixel(front, "tall_storage_cabinet", Vector2i(panel.position.x + 6, panel.position.y + 34), STEEL_LIGHT)

static func _vent_lines(image: Image, family: String, rect: Rect2i) -> void:
	for y: int in range(rect.position.y + 2, rect.end.y - 1, 4):
		_paint(image, family, Rect2i(rect.position.x + 2, y, rect.size.x - 4, 1), STEEL_DARK)

static func _draw_server(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	_draw_solid(rear, "server_cabinet", p, FRAME, FRAME, POWDERCOAT)
	var top: Rect2i = p.top
	var face: Rect2i = p.front
	# Ventilation is drawn on the actual equipment roof as well as the relevant
	# physical face; static marks are deliberately unlit.
	var roof_vent := top.grow(-7)
	_vent_lines(front, "server_cabinet", roof_vent)
	var panel := face.grow(-5)
	_panel(front, "server_cabinet", panel, INK_DEEP)
	match side:
		"north":
			var fan_width := maxi(7, (panel.size.x - 13) / 2)
			for x: int in [panel.position.x + 4, panel.end.x - 4 - fan_width]:
				var fan := Rect2i(x, panel.position.y + 8, fan_width, 18)
				_panel(front, "server_cabinet", fan, FRAME)
				_vent_lines(front, "server_cabinet", fan.grow(-2))
			_paint(front, "server_cabinet", Rect2i(panel.position.x + panel.size.x / 2 - 2, panel.position.y + 4, 4, panel.size.y - 8), STEEL_DARK)
			for y: int in range(panel.position.y + 34, panel.end.y - 4, 9): _paint(front, "server_cabinet", Rect2i(panel.position.x + 4, y, panel.size.x - 8, 2), FRAME)
		"east":
			_vent_lines(front, "server_cabinet", panel.grow(-2))
			_paint(front, "server_cabinet", Rect2i(panel.end.x - 3, panel.position.y + 4, 2, panel.size.y - 8), STEEL)
			for y: int in [panel.position.y + 15, panel.position.y + 19, panel.position.y + 23]: _pixel(front, "server_cabinet", Vector2i(panel.end.x - 2, y), STEEL_DARK)
		"south":
			for index: int in range(5):
				var row := Rect2i(panel.position.x + 3, panel.position.y + 4 + index * 11, panel.size.x - 6, 8)
				_panel(front, "server_cabinet", row, FRAME)
				_paint(front, "server_cabinet", Rect2i(row.position.x + 4, row.position.y + 3, row.size.x - 13, 2), STEEL_DARK)
				_pixel(front, "server_cabinet", Vector2i(row.end.x - 6, row.position.y + 3), STEEL)
			_paint(front, "server_cabinet", Rect2i(panel.position.x + 4, panel.end.y - 10, panel.size.x - 8, 3), STEEL_DARK)
			for x: int in range(panel.position.x + 7, panel.end.x - 6, 6): _pixel(front, "server_cabinet", Vector2i(x, panel.end.y - 9), INK)
		"west":
			_vent_lines(front, "server_cabinet", panel.grow(-2))
			_paint(front, "server_cabinet", Rect2i(panel.position.x + 1, panel.position.y + 4, 2, panel.size.y - 8), STEEL)
			for y: int in [panel.position.y + 20, panel.position.y + 24, panel.position.y + 28]: _pixel(front, "server_cabinet", Vector2i(panel.position.x + 2, y), STEEL_DARK)

static func _stream_icon(image: Image, family: String, center: Vector2i, index: int, color: Color) -> void:
	match index:
		0:
			_paint(image, family, Rect2i(center - Vector2i(2, 2), Vector2i(5, 5)), color)
			_pixel(image, family, center, RECYCLE_BODY)
		1:
			_paint(image, family, Rect2i(center - Vector2i(1, 3), Vector2i(3, 7)), color)
			_paint(image, family, Rect2i(center - Vector2i(3, 1), Vector2i(7, 3)), color)
		2:
			_paint(image, family, Rect2i(center - Vector2i(3, 2), Vector2i(7, 5)), color)
			_paint(image, family, Rect2i(center - Vector2i(1, 1), Vector2i(3, 3)), RECYCLE_BODY)

static func _stream_colors(side: String) -> Array[Color]:
	var colors: Array[Color] = []
	if side in ["south", "east"]: colors.assign([STREAM_BLUE, STREAM_GREEN, STREAM_GREY])
	else: colors.assign([STREAM_GREY, STREAM_GREEN, STREAM_BLUE])
	return colors

static func _draw_top_apertures(front: Image, side: String, top: Rect2i, colors: Array[Color]) -> void:
	# Three real openings live on the top plane near the declared service edge.
	# Their axis and ordering are independently declared for each facing.
	if side in ["north", "south"]:
		var y := top.position.y + 5 if side == "north" else top.end.y - 10
		for index: int in range(3):
			var width := 14
			var x := top.position.x + 6 + index * 18
			_panel(front, "recycling_sorter", Rect2i(x, y, width, 6), SLOT)
			_stream_icon(front, "recycling_sorter", Vector2i(x + width / 2, y + 3), index if side == "south" else 2 - index, colors[index])
	else:
		var x := top.end.x - 10 if side == "east" else top.position.x + 5
		for index: int in range(3):
			var height := 14
			var y := top.position.y + 6 + index * 18
			_panel(front, "recycling_sorter", Rect2i(x, y, 6, height), SLOT)
			_stream_icon(front, "recycling_sorter", Vector2i(x + 3, y + height / 2), index if side == "east" else 2 - index, colors[index])

static func _draw_sorter(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	_draw_solid(rear, "recycling_sorter", p, RECYCLE_BODY, RECYCLE_BODY)
	var top: Rect2i = p.top
	var face: Rect2i = p.front
	var colors := _stream_colors(side)
	_draw_top_apertures(front, side, top, colors)
	var panel := face.grow(-5)
	match side:
		"north":
			_panel(front, "recycling_sorter", panel, RECYCLE_SHADE)
			for index: int in range(3):
				var x := panel.position.x + index * panel.size.x / 3
				_paint(front, "recycling_sorter", Rect2i(x + 2, panel.position.y + 5, panel.size.x / 3 - 4, 3), colors[index])
				if index > 0: _paint(front, "recycling_sorter", Rect2i(x, panel.position.y + 3, 1, panel.size.y - 6), INK)
		"east":
			_panel(front, "recycling_sorter", panel, RECYCLE_SHADE)
			for index: int in range(3):
				var y := panel.position.y + 3 + index * 7
				_paint(front, "recycling_sorter", Rect2i(panel.position.x + 3, y, panel.size.x - 6, 4), colors[index])
		"south":
			_panel(front, "recycling_sorter", panel, RECYCLE_SHADE)
			for index: int in range(3):
				var x := panel.position.x + index * panel.size.x / 3
				var width := panel.size.x / 3
				_panel(front, "recycling_sorter", Rect2i(x + 1, panel.position.y + 2, width - 2, panel.size.y - 4), colors[index])
				_stream_icon(front, "recycling_sorter", Vector2i(x + width / 2, panel.position.y + panel.size.y / 2), index, colors[index])
		"west":
			_panel(front, "recycling_sorter", panel, RECYCLE_SHADE)
			for index: int in range(3):
				var y := panel.position.y + 3 + index * 7
				_paint(front, "recycling_sorter", Rect2i(panel.position.x + 3, y, panel.size.x - 6, 4), colors[index])

static func layers(family: String, side: String) -> Dictionary[String, Image]:
	var p := profile(family, side)
	if p.is_empty(): return {}
	var result: Dictionary[String, Image] = {
		"floor_shadow": _image(family),
		"rear_structure": _image(family),
		"front_structure": _image(family),
	}
	_draw_shadow(result.floor_shadow, family, p.floor)
	match family:
		"tall_storage_cabinet": _draw_tall(result.rear_structure, result.front_structure, side, p)
		"server_cabinet": _draw_server(result.rear_structure, result.front_structure, side, p)
		"recycling_sorter": _draw_sorter(result.rear_structure, result.front_structure, side, p)
	return result

static func binary_over(back: Image, near: Image) -> Image:
	var result := back.get_data().duplicate()
	var foreground := near.get_data()
	for at: int in range(0, result.size(), 4):
		if foreground[at + 3] != 0:
			for channel: int in range(4): result[at + channel] = foreground[at + channel]
	return Image.create_from_data(back.get_width(), back.get_height(), false, Image.FORMAT_RGBA8, result)

static func whole(family: String, side: String) -> Image:
	var parts := layers(family, side)
	if parts.is_empty(): return Image.new()
	return binary_over(binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure)

static func layer_depth(layer_name: String) -> int:
	return {"floor_shadow": -2, "rear_structure": -1, "front_structure": 1}.get(layer_name, 0)

static func descriptor(family: String, side: String, layer_name: String) -> Dictionary:
	return {
		"name": family.to_pascal_case() + "V2" + side.capitalize() + layer_name.to_pascal_case(),
		"art": str(ROOTS[family]).path_join("%s-%s.png" % [side, layer_name]),
		"region": [0, 0, canvas(family).x, canvas(family).y],
		"offset": [sprite_offset(family).x, sprite_offset(family).y],
		"z_offset": layer_depth(layer_name),
	}

static func catalog_entry(family: String) -> Dictionary:
	if family not in FAMILIES: return {}
	var profiles := {}
	for side: String in SIDES:
		var p := profile(family, side)
		var used := whole(family, side).get_used_rect()
		var local_bounds := Rect2i(used.position - pivot(family), used.size)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in LAYERS: render_layers.append(descriptor(family, side, layer_name))
		profiles[side] = {
			"profile_kind": "decorative",
			"status": "calibration_candidate",
			"review": {"art": false, "geometry": false},
			"occupied": p.occupied.duplicate(true),
			"clearance": p.clearance.duplicate(true),
			"anchor_offset": [0, 0],
			"visual_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"hit_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"render_layers": render_layers,
			"ambient_overlays": [],
			"standing_viewpoints": [{"cell": p.interaction.duplicate(), "visual_bounds": [-24, -72, 48, 80]}],
			"proposed_service_side": p.service_side,
			"proposed_approach_gaze": p.approach_gaze,
			"proposed_employee_look_vector": p.employee_look_vector.duplicate(),
			"proposed_interaction_cell": p.interaction.duplicate(),
			"dimension_review": p.dimension_review.duplicate(true),
			"calibration_limitations": ["Passive v2 art/geometry review only; service-side metadata is not an implemented action.", "No worker, role, backend, transaction, live metric, default placement, or runtime registration is supplied."],
		}
	return {
		"display_name": family.replace("_", " ").capitalize() + " v2 candidate",
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none",
		"facing_profiles": profiles,
	}
