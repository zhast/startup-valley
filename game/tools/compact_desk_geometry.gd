class_name CompactDeskGeometry
extends RefCounted
## DEV ONLY. A deterministic two-cell desk base. Chair, computer, and role
## equipment remain separately owned overlays and are never painted here.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const CANVAS := Vector2i(160, 192)
const PIVOT := Vector2i(80, 128)
const SPRITE_OFFSET := Vector2i(0, -32)

const INK := Color("282622")
const LEG := Color("383833")
const LEG_LIGHT := Color("53524a")
const WOOD := Color("a87742")
const EDGE := Color("77512f")
const LIGHT := Color("d1a369")
const SHADE := Color("583d28")
const SHADOW := Color("554e42")

static func _piece(rect: Rect2i, color: Color) -> Dictionary:
	return {"rect": rect, "color": color}

static func profile(side: String) -> Dictionary:
	# All coordinates are independent screen-space declarations around PIVOT.
	# The even-width base anchors one of its two cells at [0,0], so opposite
	# facings intentionally extend from different sides of that unchanged pivot.
	match side:
		"north":
			return {
				"facing": side,
				"axis": "horizontal",
				"footprint": [2, 1],
				"occupied": [[-1, 0], [0, 0]],
				"clearance": [[0, 1]],
				"interaction": [0, 1],
				"employee_look_vector": [0, -1],
				"floor": Rect2i(-48, -16, 64, 32),
				"top": Rect2i(-48, -48, 64, 30),
				"top_layer": "rear_structure",
				"contact_y": 16,
				"rear_parts": [_piece(Rect2i(-44, -44, 5, 31), LEG), _piece(Rect2i(7, -44, 5, 31), LEG), _piece(Rect2i(-40, -27, 48, 4), EDGE), _piece(Rect2i(-38, -26, 44, 1), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(-44, -16, 5, 32), INK), _piece(Rect2i(7, -16, 5, 32), INK), _piece(Rect2i(-43, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(8, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(-48, -18, 64, 7), EDGE), _piece(Rect2i(-46, -17, 60, 1), LIGHT), _piece(Rect2i(-42, -12, 52, 1), SHADE)],
			}
		"east":
			return {
				"facing": side,
				"axis": "vertical",
				"footprint": [1, 2],
				"occupied": [[0, -1], [0, 0]],
				"clearance": [[-1, 0]],
				"interaction": [-1, 0],
				"employee_look_vector": [1, 0],
				"floor": Rect2i(-16, -48, 32, 64),
				"top": Rect2i(-16, -80, 30, 64),
				"top_layer": "rear_structure",
				"contact_y": 16,
				"rear_parts": [_piece(Rect2i(-13, -76, 5, 30), LEG), _piece(Rect2i(7, -76, 5, 30), LEG), _piece(Rect2i(-8, -71, 4, 48), EDGE), _piece(Rect2i(-7, -69, 1, 44), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(-13, -16, 5, 32), INK), _piece(Rect2i(7, -16, 5, 32), INK), _piece(Rect2i(-12, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(8, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(10, -80, 6, 64), EDGE), _piece(Rect2i(11, -78, 1, 60), LIGHT), _piece(Rect2i(14, -76, 1, 56), SHADE)],
			}
		"south":
			return {
				"facing": side,
				"axis": "horizontal",
				"footprint": [2, 1],
				"occupied": [[1, 0], [0, 0]],
				"clearance": [[0, -1]],
				"interaction": [0, -1],
				"employee_look_vector": [0, 1],
				"floor": Rect2i(-16, -16, 64, 32),
				"top": Rect2i(-16, -48, 64, 30),
				"top_layer": "front_structure",
				"contact_y": 16,
				"rear_parts": [_piece(Rect2i(-12, -44, 5, 31), LEG), _piece(Rect2i(39, -44, 5, 31), LEG), _piece(Rect2i(-8, -27, 48, 4), EDGE), _piece(Rect2i(-6, -26, 44, 1), LEG_LIGHT), _piece(Rect2i(0, -8, 32, 3), LEG), _piece(Rect2i(2, -7, 28, 1), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(-12, -16, 5, 32), INK), _piece(Rect2i(39, -16, 5, 32), INK), _piece(Rect2i(-11, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(40, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(-16, -18, 64, 9), EDGE), _piece(Rect2i(-14, -17, 60, 1), LIGHT), _piece(Rect2i(-10, -11, 52, 1), SHADE)],
			}
		"west":
			return {
				"facing": side,
				"axis": "vertical",
				"footprint": [1, 2],
				"occupied": [[0, 1], [0, 0]],
				"clearance": [[1, 0]],
				"interaction": [1, 0],
				"employee_look_vector": [-1, 0],
				"floor": Rect2i(-16, -16, 32, 64),
				"top": Rect2i(-14, -48, 30, 64),
				"top_layer": "rear_structure",
				"contact_y": 48,
				"rear_parts": [_piece(Rect2i(-11, -44, 5, 30), LEG), _piece(Rect2i(9, -44, 5, 30), LEG), _piece(Rect2i(4, -39, 4, 48), EDGE), _piece(Rect2i(5, -37, 1, 44), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(-11, 16, 5, 32), INK), _piece(Rect2i(9, 16, 5, 32), INK), _piece(Rect2i(-10, 18, 2, 27), LEG_LIGHT), _piece(Rect2i(10, 18, 2, 27), LEG_LIGHT), _piece(Rect2i(-16, -48, 6, 64), EDGE), _piece(Rect2i(-15, -46, 1, 60), LIGHT), _piece(Rect2i(-12, -44, 1, 56), SHADE)],
			}
	return {}

static func overlay_contract(side: String) -> Dictionary:
	# Sockets are proposal geometry only. They name the separately owned asset
	# families but neither load nor bake any of their pixels into this base.
	var p := profile(side)
	if p.is_empty(): return {}
	var top: Rect2i = p.top
	var horizontal := str(p.axis) == "horizontal"
	var device_zone: Rect2i
	var role_zone: Rect2i
	if horizontal:
		device_zone = Rect2i(top.position + Vector2i(4, 4), Vector2i(35, 18))
		role_zone = Rect2i(top.position + Vector2i(43, 5), Vector2i(16, 16))
		if side == "south":
			device_zone = Rect2i(top.position + Vector2i(25, 4), Vector2i(35, 18))
			role_zone = Rect2i(top.position + Vector2i(5, 5), Vector2i(16, 16))
	else:
		device_zone = Rect2i(top.position + Vector2i(4, 4), Vector2i(18, 35))
		role_zone = Rect2i(top.position + Vector2i(5, 43), Vector2i(16, 16))
		if side == "west":
			device_zone = Rect2i(top.position + Vector2i(4, 25), Vector2i(18, 35))
			role_zone = Rect2i(top.position + Vector2i(5, 5), Vector2i(16, 16))
	return {
		"chair": {"owner_family": "ergonomic_chair", "cell": p.interaction.duplicate(), "included_in_base": false, "adds_base_collision": false},
		"device": {"owner_family": "computer_kit", "surface_zone": device_zone, "included_in_base": false, "adds_base_collision": false},
		"role": {"owner_family": "role_tool_kits", "surface_zone": role_zone, "included_in_base": false, "adds_base_collision": false},
	}

static func _image() -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func _draw_parts(image: Image, parts: Array) -> void:
	for raw: Variant in parts:
		var part := raw as Dictionary
		_paint(image, part.rect, part.color)

static func _draw_floor_shadow(image: Image, floor: Rect2i) -> void:
	# Binary-alpha ordered dithering keeps the independent shadow reusable while
	# avoiding a semi-transparent matte or a solid block that reads as cabinetry.
	var inset := Rect2i(floor.position + Vector2i(4, 10), floor.size - Vector2i(8, 20)) if floor.size.x > floor.size.y else Rect2i(floor.position + Vector2i(10, 4), floor.size - Vector2i(20, 8))
	var center := Vector2(inset.position) + Vector2(inset.size - Vector2i.ONE) * 0.5
	var radius := Vector2(inset.size) * 0.5
	for y: int in range(inset.position.y, inset.end.y):
		for x: int in range(inset.position.x, inset.end.x):
			var delta := (Vector2(x, y) - center) / radius
			var distance := delta.length_squared()
			if distance > 1.0: continue
			if distance < 0.30 or (x + y) % 2 == 0:
				_paint(image, Rect2i(x, y, 1, 1), SHADOW)

static func _draw_top(image: Image, rect: Rect2i) -> void:
	_paint(image, rect, INK)
	_paint(image, rect.grow(-2), WOOD)
	_paint(image, Rect2i(rect.position + Vector2i(2, 2), Vector2i(rect.size.x - 4, 1)), LIGHT)
	_paint(image, Rect2i(rect.position + Vector2i(2, 3), Vector2i(1, rect.size.y - 5)), LIGHT)
	_paint(image, Rect2i(rect.position + Vector2i(2, rect.size.y - 3), Vector2i(rect.size.x - 4, 1)), SHADE)
	_paint(image, Rect2i(rect.position + Vector2i(rect.size.x - 3, 3), Vector2i(1, rect.size.y - 6)), SHADE)
	# Two short, screen-aligned grain cues keep the surface coherent with the
	# shared oak workstation without copying its 96px top.
	if rect.size.x > rect.size.y:
		_paint(image, Rect2i(rect.position + Vector2i(11, 10), Vector2i(17, 1)), EDGE)
		_paint(image, Rect2i(rect.position + Vector2i(35, 17), Vector2i(13, 1)), LIGHT)
	else:
		_paint(image, Rect2i(rect.position + Vector2i(10, 11), Vector2i(1, 17)), EDGE)
		_paint(image, Rect2i(rect.position + Vector2i(17, 35), Vector2i(1, 13)), LIGHT)

static func layers(side: String) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	var result: Dictionary[String, Image] = {
		"floor_shadow": _image(),
		"rear_structure": _image(),
		"front_structure": _image(),
	}
	_draw_floor_shadow(result.floor_shadow, p.floor)
	_draw_parts(result.rear_structure, p.rear_parts)
	if str(p.top_layer) == "rear_structure": _draw_top(result.rear_structure, p.top)
	if str(p.top_layer) == "front_structure": _draw_top(result.front_structure, p.top)
	_draw_parts(result.front_structure, p.front_parts)
	return result

static func binary_over(back: Image, near: Image) -> Image:
	var back_bytes := back.get_data()
	var near_bytes := near.get_data()
	var result := back_bytes.duplicate()
	for at: int in range(0, result.size(), 4):
		if near_bytes[at + 3] != 0:
			for channel: int in range(4): result[at + channel] = near_bytes[at + channel]
	return Image.create_from_data(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8, result)

static func whole(side: String) -> Image:
	var parts := layers(side)
	if parts.is_empty(): return Image.new()
	return binary_over(binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure)

static func layer_depth(layer_name: String) -> int:
	return {"floor_shadow": -2, "rear_structure": -1, "front_structure": 1}.get(layer_name, 0)

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "CompactDesk" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/compact-desk-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(layer_name),
	}

static func catalog_entry() -> Dictionary:
	var variants := {}
	for side: String in SIDES:
		var p := profile(side)
		var bounds := whole(side).get_used_rect()
		var local_bounds := Rect2i(bounds.position - PIVOT, bounds.size)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in LAYERS: render_layers.append(descriptor(side, layer_name))
		variants[side] = {
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
			"proposed_workstation_interaction": p.interaction.duplicate(),
			"proposed_employee_look_vector": p.employee_look_vector.duplicate(),
			"overlay_contract": overlay_contract(side),
			"calibration_limitations": ["Passive geometry admission only; no workstation action or seated capability is claimed.", "Chair, device and role pixels are separate asset-family responsibilities."],
		}
	return {
		"display_name": "Compact desk candidate",
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none",
		"facing_profiles": variants,
	}
