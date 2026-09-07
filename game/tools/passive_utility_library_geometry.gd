class_name PassiveUtilityLibraryGeometry
extends RefCounted
## DEV ONLY. Deterministic native passive-library art for three existing bases.
## Every N/E/S/W view is independently authored in fixed screen axes. The
## original catalogue canvases, pivots, masks, and planning approach cells stay
## intact; no service, action, worker, runtime, or default placement is added.

const FAMILIES: Array[String] = ["tall_storage_cabinet", "server_cabinet", "recycling_sorter"]
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const ROOTS := {
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

static func measured_rise(family: String) -> int:
	return {"tall_storage_cabinet": 112, "server_cabinet": 96, "recycling_sorter": 48}.get(family, 0)

static func planned_rise_envelope(family: String) -> int:
	return 48 if family == "recycling_sorter" else 160

static func dimension_review(family: String) -> Dictionary:
	return {
		"planned_canvas_retained": [canvas(family).x, canvas(family).y],
		"planned_floor_anchor_retained": [pivot(family).x, pivot(family).y],
		"planned_max_rise_envelope_px": planned_rise_envelope(family),
		"measured_opaque_rise_px": measured_rise(family),
		"revision": "The planned maximum rise was an envelope, not required opaque height. Tall supply storage uses 112px, compact server equipment uses 96px, and the low sorter keeps 48px; original native registration and two-cell collision masks remain unchanged.",
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
	var broad := side in ["north", "south"]
	var rise := measured_rise(family)
	var inset_x := 2
	var body := Rect2i(floor.position.x + inset_x, floor.end.y - rise, floor.size.x - inset_x * 2, rise)
	var identity := ""
	match side:
		"north": identity = "rear"
		"east": identity = "service_front_right_edge"
		"south": identity = "service_front"
		"west": identity = "service_front_left_edge"
	var role_identity := {}
	match family:
		"tall_storage_cabinet":
			role_identity = {"closed_supply_doors": side == "south", "rear_brace": side == "north", "door_edge": "right" if side == "east" else "left" if side == "west" else "broad"}
		"server_cabinet":
			role_identity = {"equipment_face": "rack_front" if side == "south" else "cable_fan_rear" if side == "north" else "vented_right_side" if side == "east" else "vented_left_side", "static_unlit_indicators": true}
		"recycling_sorter":
			role_identity = {"three_stream_order": ["blue", "green", "grey"] if side in ["south", "east"] else ["grey", "green", "blue"], "labels": "color_and_shape_only_no_text"}
	return {
		"family": family,
		"facing": side,
		"service_side": side,
		"approach_gaze": _approach_gaze(side),
		"employee_look_vector": _gaze(side),
		"interaction": _interaction(side),
		"clearance": [_interaction(side)],
		"occupied": _occupied(side),
		"footprint": [2, 1] if broad else [1, 2],
		"axis": "horizontal" if broad else "vertical",
		"floor": floor,
		"body": body,
		"contact_y": floor.end.y,
		"rise": rise,
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

static func _box(image: Image, family: String, rect: Rect2i, fill: Color, light: Color = FRAME_LIGHT, shade: Color = INK_DEEP) -> void:
	_paint(image, family, rect, INK)
	if rect.size.x <= 2 or rect.size.y <= 2: return
	_paint(image, family, rect.grow(-1), fill)
	_paint(image, family, Rect2i(rect.position + Vector2i.ONE, Vector2i(rect.size.x - 2, 1)), light)
	_paint(image, family, Rect2i(rect.position + Vector2i(1, 2), Vector2i(1, rect.size.y - 3)), light)
	_paint(image, family, Rect2i(rect.position + Vector2i(1, rect.size.y - 2), Vector2i(rect.size.x - 2, 1)), shade)
	_paint(image, family, Rect2i(rect.position + Vector2i(rect.size.x - 2, 2), Vector2i(1, rect.size.y - 3)), shade)

static func _tile(image: Image, family: String, rect: Rect2i, source_path: String) -> bool:
	var tile := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if tile == null or tile.get_size() != Vector2i(32, 32): return false
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			image.set_pixelv(Vector2i(x, y) + pivot(family), tile.get_pixel(posmod(x, 32), posmod(y, 32)))
	return true

static func _draw_shadow(image: Image, family: String, floor: Rect2i) -> void:
	var rect := Rect2i(floor.position + Vector2i(1, floor.size.y - 7), Vector2i(floor.size.x - 2, 7))
	var center := Vector2(rect.position) + Vector2(rect.size - Vector2i.ONE) * 0.5
	var radius := Vector2(rect.size) * 0.5
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var delta := (Vector2(x, y) - center) / radius
			if delta.length_squared() <= 1.0 and (delta.length_squared() < 0.25 or (x + y) % 2 == 0):
				_pixel(image, family, Vector2i(x, y), SHADOW)

static func _draw_tall(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	var body: Rect2i = p.body
	_box(rear, "tall_storage_cabinet", body, SUPPLY_PANEL, OAK_LIGHT, OAK_SHADE)
	var field := body.grow(-2)
	var tile_path := OAK_HORIZONTAL if side in ["north", "south"] else OAK_VERTICAL
	_tile(rear, "tall_storage_cabinet", field, tile_path)
	_paint(rear, "tall_storage_cabinet", Rect2i(body.position + Vector2i(2, 2), Vector2i(body.size.x - 4, 2)), OAK_LIGHT)
	_paint(rear, "tall_storage_cabinet", Rect2i(body.position + Vector2i(2, body.size.y - 4), Vector2i(body.size.x - 4, 2)), OAK_SHADE)
	match side:
		"north":
			var panel := body.grow(-6)
			_box(front, "tall_storage_cabinet", panel, SUPPLY_BACK, OAK_LIGHT, OAK_SHADE)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position + Vector2i(4, 20), Vector2i(panel.size.x - 8, 3)), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position + Vector2i(4, panel.size.y - 24), Vector2i(panel.size.x - 8, 3)), INK)
			for x: int in [panel.position.x + 3, panel.end.x - 4]:
				for y: int in [panel.position.y + 4, panel.end.y - 5]: _pixel(front, "tall_storage_cabinet", Vector2i(x, y), STEEL_DARK)
		"east":
			var panel := body.grow(-5)
			_box(front, "tall_storage_cabinet", panel, SUPPLY_PANEL, OAK_LIGHT, OAK_SHADE)
			_paint(front, "tall_storage_cabinet", Rect2i(body.end.x - 5, body.position.y + 8, 3, body.size.y - 15), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(body.end.x - 9, body.position.y + 42, 2, 18), STEEL_DARK)
			_pixel(front, "tall_storage_cabinet", Vector2i(body.end.x - 8, body.position.y + 43), STEEL_LIGHT)
		"south":
			var panel := body.grow(-5)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position, Vector2i(panel.size.x, 2)), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position + Vector2i(0, 22), Vector2i(panel.size.x, 2)), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position + Vector2i(panel.size.x / 2 - 1, 24), Vector2i(2, panel.size.y - 24)), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position + Vector2i(2, 3), Vector2i(panel.size.x - 4, 16)), SUPPLY_BACK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position + Vector2i(panel.size.x / 2 - 5, 49), Vector2i(2, 17)), STEEL_DARK)
			_paint(front, "tall_storage_cabinet", Rect2i(panel.position + Vector2i(panel.size.x / 2 + 3, 49), Vector2i(2, 17)), STEEL_DARK)
			_pixel(front, "tall_storage_cabinet", panel.position + Vector2i(panel.size.x / 2 - 4, 50), STEEL_LIGHT)
			_pixel(front, "tall_storage_cabinet", panel.position + Vector2i(panel.size.x / 2 + 4, 50), STEEL_LIGHT)
		"west":
			var panel := body.grow(-5)
			_box(front, "tall_storage_cabinet", panel, SUPPLY_PANEL, OAK_LIGHT, OAK_SHADE)
			_paint(front, "tall_storage_cabinet", Rect2i(body.position + Vector2i(2, 7), Vector2i(3, body.size.y - 14)), INK)
			_paint(front, "tall_storage_cabinet", Rect2i(body.position + Vector2i(7, 47), Vector2i(2, 18)), STEEL_DARK)
			_pixel(front, "tall_storage_cabinet", body.position + Vector2i(7, 48), STEEL_LIGHT)

static func _draw_vent_grid(image: Image, family: String, rect: Rect2i, horizontal: bool) -> void:
	if horizontal:
		for y: int in range(rect.position.y + 2, rect.end.y - 1, 4):
			_paint(image, family, Rect2i(rect.position.x + 2, y, rect.size.x - 4, 1), STEEL_DARK)
	else:
		for x: int in range(rect.position.x + 2, rect.end.x - 1, 4):
			_paint(image, family, Rect2i(x, rect.position.y + 2, 1, rect.size.y - 4), STEEL_DARK)

static func _draw_server(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	var body: Rect2i = p.body
	_box(rear, "server_cabinet", body, FRAME, FRAME_LIGHT, INK_DEEP)
	_tile(rear, "server_cabinet", body.grow(-2), POWDERCOAT)
	_paint(rear, "server_cabinet", Rect2i(body.position + Vector2i(2, 2), Vector2i(body.size.x - 4, 2)), FRAME_LIGHT)
	match side:
		"north":
			var panel := body.grow(-5)
			_box(front, "server_cabinet", panel, INK_DEEP, STEEL_DARK, INK)
			var left_fan := Rect2i(panel.position + Vector2i(4, 10), Vector2i(18, 22))
			var right_fan := Rect2i(panel.end.x - 22, panel.position.y + 10, 18, 22)
			_box(front, "server_cabinet", left_fan, FRAME)
			_box(front, "server_cabinet", right_fan, FRAME)
			_draw_vent_grid(front, "server_cabinet", left_fan.grow(-2), true)
			_draw_vent_grid(front, "server_cabinet", right_fan.grow(-2), true)
			_paint(front, "server_cabinet", Rect2i(panel.position + Vector2i(panel.size.x / 2 - 2, 6), Vector2i(4, panel.size.y - 12)), STEEL_DARK)
			for y: int in range(panel.position.y + 42, panel.end.y - 5, 12):
				_paint(front, "server_cabinet", Rect2i(panel.position.x + 4, y, panel.size.x - 8, 2), FRAME)
		"east":
			var panel := body.grow(-5)
			_box(front, "server_cabinet", panel, INK_DEEP, STEEL_DARK, INK)
			_draw_vent_grid(front, "server_cabinet", Rect2i(panel.position + Vector2i(2, 8), Vector2i(panel.size.x - 4, panel.size.y - 16)), true)
			_paint(front, "server_cabinet", Rect2i(body.end.x - 5, body.position.y + 5, 3, body.size.y - 10), STEEL)
			for y: int in [body.position.y + 18, body.position.y + 22, body.position.y + 26]:
				_pixel(front, "server_cabinet", Vector2i(body.end.x - 4, y), STEEL_DARK)
		"south":
			var panel := body.grow(-5)
			_box(front, "server_cabinet", panel, INK_DEEP, STEEL_DARK, INK)
			var row_height := 11
			for index: int in range(6):
				var row := Rect2i(panel.position + Vector2i(3, 5 + index * row_height), Vector2i(panel.size.x - 6, 8))
				_box(front, "server_cabinet", row, FRAME, STEEL_DARK, INK)
				_paint(front, "server_cabinet", Rect2i(row.position + Vector2i(4, 3), Vector2i(row.size.x - 13, 2)), STEEL_DARK)
				_pixel(front, "server_cabinet", row.position + Vector2i(row.size.x - 6, 3), STEEL)
			_paint(front, "server_cabinet", Rect2i(panel.position + Vector2i(4, panel.size.y - 14), Vector2i(panel.size.x - 8, 4)), STEEL_DARK)
			for x: int in range(panel.position.x + 7, panel.end.x - 6, 5):
				_pixel(front, "server_cabinet", Vector2i(x, panel.end.y - 12), INK)
		"west":
			var panel := body.grow(-5)
			_box(front, "server_cabinet", panel, INK_DEEP, STEEL_DARK, INK)
			_draw_vent_grid(front, "server_cabinet", Rect2i(panel.position + Vector2i(2, 8), Vector2i(panel.size.x - 4, panel.size.y - 16)), true)
			_paint(front, "server_cabinet", Rect2i(body.position + Vector2i(2, 5), Vector2i(3, body.size.y - 10)), STEEL)
			for y: int in [body.position.y + 23, body.position.y + 27, body.position.y + 31]:
				_pixel(front, "server_cabinet", Vector2i(body.position.x + 3, y), STEEL_DARK)

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
			_paint(image, family, Rect2i(center - Vector2i(1, 3), Vector2i(3, 7)), RECYCLE_BODY)

static func _draw_sorter(rear: Image, front: Image, side: String, p: Dictionary) -> void:
	var body: Rect2i = p.body
	_box(rear, "recycling_sorter", body, RECYCLE_BODY, STEEL_LIGHT, RECYCLE_SHADE)
	_paint(rear, "recycling_sorter", Rect2i(body.position + Vector2i(2, 2), Vector2i(body.size.x - 4, 5)), RECYCLE_SHADE)
	var colors: Array[Color] = []
	if side in ["south", "east"]:
		colors.assign([STREAM_BLUE, STREAM_GREEN, STREAM_GREY])
	else:
		colors.assign([STREAM_GREY, STREAM_GREEN, STREAM_BLUE])
	match side:
		"north":
			var panel := body.grow(-5)
			for index: int in range(3):
				var x := panel.position.x + index * panel.size.x / 3
				var width := panel.size.x / 3
				_paint(front, "recycling_sorter", Rect2i(x + 1, panel.position.y + 3, width - 2, 3), colors[index])
				_paint(front, "recycling_sorter", Rect2i(x + width - 1, panel.position.y + 8, 1, panel.size.y - 12), RECYCLE_SHADE)
			_paint(front, "recycling_sorter", Rect2i(panel.position + Vector2i(2, panel.size.y - 6), Vector2i(panel.size.x - 4, 2)), RECYCLE_SHADE)
		"east":
			var panel := body.grow(-4)
			for index: int in range(3):
				var y := panel.position.y + 3 + index * 11
				_box(front, "recycling_sorter", Rect2i(panel.position.x + 2, y, panel.size.x - 4, 7), colors[index], STEEL_LIGHT, RECYCLE_SHADE)
				_stream_icon(front, "recycling_sorter", Vector2i(panel.position.x + panel.size.x / 2, y + 3), index, colors[index])
			_paint(front, "recycling_sorter", Rect2i(body.end.x - 4, body.position.y + 4, 2, body.size.y - 8), INK)
		"south":
			var panel := body.grow(-5)
			for index: int in range(3):
				var x := panel.position.x + index * panel.size.x / 3
				var width := panel.size.x / 3
				_box(front, "recycling_sorter", Rect2i(x + 1, panel.position.y + 2, width - 2, panel.size.y - 4), colors[index], STEEL_LIGHT, RECYCLE_SHADE)
				_paint(front, "recycling_sorter", Rect2i(x + 4, panel.position.y + 7, width - 8, 4), SLOT)
				_stream_icon(front, "recycling_sorter", Vector2i(x + width / 2, panel.position.y + 21), index, colors[index])
		"west":
			var panel := body.grow(-4)
			for index: int in range(3):
				var y := panel.position.y + 3 + index * 11
				_box(front, "recycling_sorter", Rect2i(panel.position.x + 2, y, panel.size.x - 4, 7), colors[index], STEEL_LIGHT, RECYCLE_SHADE)
				_stream_icon(front, "recycling_sorter", Vector2i(panel.position.x + panel.size.x / 2, y + 3), 2 - index, colors[index])
			_paint(front, "recycling_sorter", Rect2i(body.position + Vector2i(2, 4), Vector2i(2, body.size.y - 8)), INK)

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
		"name": family.to_pascal_case() + side.capitalize() + layer_name.to_pascal_case(),
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
			"calibration_limitations": ["Passive art/geometry review only; service_side remains catalogue planning metadata, not an implemented action.", "No worker, role, backend, transaction, live metric, default placement, or runtime registration is supplied."],
		}
	return {
		"display_name": family.replace("_", " ").capitalize() + " candidate",
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none",
		"facing_profiles": profiles,
	}
