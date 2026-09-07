class_name SharedWorkbenchGeometry
extends RefCounted
## DEV ONLY. A deterministic five-cell paired workbench base. Two chairs,
## devices, and role kits remain separately owned overlays and are never
## painted here.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const CANVAS := Vector2i(256, 304)
const PIVOT := Vector2i(128, 208)
const SPRITE_OFFSET := Vector2i(0, -56)

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
	# Five odd-count cells center naturally on [0,0]. The named view owns its
	# screen-space joinery and paired socket order; no finished raster transform
	# is used to derive an opposing direction.
	match side:
		"north":
			return {
				"facing": side,
				"axis": "horizontal",
				"footprint": [5, 1],
				"occupied": [[-2, 0], [-1, 0], [0, 0], [1, 0], [2, 0]],
				"work_cells": [[-1, 1], [1, 1]],
				"clearance": [[-1, 1], [0, 1], [1, 1]],
				"interaction": [0, 1],
				"employee_look_vector": [0, -1],
				"floor": Rect2i(-80, -16, 160, 32),
				"top": Rect2i(-77, -54, 154, 32),
				"top_layer": "rear_structure",
				"contact_y": 16,
				"rear_parts": [_piece(Rect2i(-71, -50, 6, 37), LEG), _piece(Rect2i(-3, -50, 6, 37), LEG), _piece(Rect2i(65, -50, 6, 37), LEG), _piece(Rect2i(-65, -31, 130, 5), EDGE), _piece(Rect2i(-61, -30, 122, 1), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(-71, -16, 6, 32), INK), _piece(Rect2i(-3, -16, 6, 32), INK), _piece(Rect2i(65, -16, 6, 32), INK), _piece(Rect2i(-70, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(-2, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(66, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(-77, -22, 154, 9), EDGE), _piece(Rect2i(-75, -21, 150, 1), LIGHT), _piece(Rect2i(-68, -15, 136, 2), SHADE)],
			}
		"east":
			return {
				"facing": side,
				"axis": "vertical",
				"footprint": [1, 5],
				"occupied": [[0, -2], [0, -1], [0, 0], [0, 1], [0, 2]],
				"work_cells": [[-1, -1], [-1, 1]],
				"clearance": [[-1, -1], [-1, 0], [-1, 1]],
				"interaction": [-1, 0],
				"employee_look_vector": [1, 0],
				"floor": Rect2i(-16, -80, 32, 160),
				"top": Rect2i(-14, -77, 28, 154),
				"top_layer": "rear_structure",
				"contact_y": 80,
				"rear_parts": [_piece(Rect2i(-13, -71, 8, 6), LEG), _piece(Rect2i(-13, -3, 8, 6), LEG), _piece(Rect2i(-13, 65, 8, 6), LEG), _piece(Rect2i(-8, -65, 4, 130), EDGE), _piece(Rect2i(-7, -61, 1, 122), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(5, -72, 8, 6), INK), _piece(Rect2i(5, -4, 8, 6), INK), _piece(Rect2i(5, 64, 8, 6), INK), _piece(Rect2i(6, -71, 5, 1), LEG_LIGHT), _piece(Rect2i(6, -3, 5, 1), LEG_LIGHT), _piece(Rect2i(6, 65, 5, 1), LEG_LIGHT), _piece(Rect2i(9, -77, 5, 154), EDGE), _piece(Rect2i(10, -75, 1, 150), LIGHT), _piece(Rect2i(12, -68, 1, 136), SHADE), _piece(Rect2i(5, 73, 8, 7), INK)],
			}
		"south":
			return {
				"facing": side,
				"axis": "horizontal",
				"footprint": [5, 1],
				"occupied": [[2, 0], [1, 0], [0, 0], [-1, 0], [-2, 0]],
				"work_cells": [[1, -1], [-1, -1]],
				"clearance": [[1, -1], [0, -1], [-1, -1]],
				"interaction": [0, -1],
				"employee_look_vector": [0, 1],
				"floor": Rect2i(-80, -16, 160, 32),
				"top": Rect2i(-77, -54, 154, 32),
				"top_layer": "front_structure",
				"contact_y": 16,
				"rear_parts": [_piece(Rect2i(-69, -50, 6, 37), LEG), _piece(Rect2i(-3, -50, 6, 37), LEG), _piece(Rect2i(63, -50, 6, 37), LEG), _piece(Rect2i(-63, -31, 126, 5), EDGE), _piece(Rect2i(-59, -30, 118, 1), LEG_LIGHT), _piece(Rect2i(-12, -9, 24, 4), LEG), _piece(Rect2i(-9, -8, 18, 1), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(-69, -16, 6, 32), INK), _piece(Rect2i(-3, -16, 6, 32), INK), _piece(Rect2i(63, -16, 6, 32), INK), _piece(Rect2i(-68, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(-2, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(64, -14, 2, 27), LEG_LIGHT), _piece(Rect2i(-77, -22, 154, 9), EDGE), _piece(Rect2i(-75, -21, 150, 1), LIGHT), _piece(Rect2i(-66, -15, 132, 2), SHADE)],
			}
		"west":
			return {
				"facing": side,
				"axis": "vertical",
				"footprint": [1, 5],
				"occupied": [[0, 2], [0, 1], [0, 0], [0, -1], [0, -2]],
				"work_cells": [[1, 1], [1, -1]],
				"clearance": [[1, 1], [1, 0], [1, -1]],
				"interaction": [1, 0],
				"employee_look_vector": [-1, 0],
				"floor": Rect2i(-16, -80, 32, 160),
				"top": Rect2i(-14, -77, 28, 154),
				"top_layer": "rear_structure",
				"contact_y": 80,
				"rear_parts": [_piece(Rect2i(5, -69, 8, 6), LEG), _piece(Rect2i(5, -3, 8, 6), LEG), _piece(Rect2i(5, 63, 8, 6), LEG), _piece(Rect2i(4, -63, 4, 126), EDGE), _piece(Rect2i(5, -59, 1, 118), LEG_LIGHT), _piece(Rect2i(-8, -12, 4, 24), LEG), _piece(Rect2i(-7, -9, 1, 18), LEG_LIGHT)],
				"front_parts": [_piece(Rect2i(-13, -70, 8, 6), INK), _piece(Rect2i(-13, -4, 8, 6), INK), _piece(Rect2i(-13, 62, 8, 6), INK), _piece(Rect2i(-11, -69, 5, 1), LEG_LIGHT), _piece(Rect2i(-11, -3, 5, 1), LEG_LIGHT), _piece(Rect2i(-11, 63, 5, 1), LEG_LIGHT), _piece(Rect2i(-14, -77, 5, 154), EDGE), _piece(Rect2i(-13, -75, 1, 150), LIGHT), _piece(Rect2i(-11, -66, 1, 132), SHADE), _piece(Rect2i(-13, 73, 8, 7), INK)],
			}
	return {}

static func overlay_contract(side: String) -> Dictionary:
	# Sockets are proposal geometry only. They name the separately owned asset
	# families but neither load nor bake any of their pixels into this base.
	var p := profile(side)
	if p.is_empty(): return {}
	var top: Rect2i = p.top
	var horizontal := str(p.axis) == "horizontal"
	var device_a: Rect2i
	var device_b: Rect2i
	var role_a: Rect2i
	var role_b: Rect2i
	if horizontal:
		device_a = Rect2i(top.position + Vector2i(8, 6), Vector2i(40, 18))
		role_a = Rect2i(top.position + Vector2i(52, 7), Vector2i(18, 16))
		device_b = Rect2i(top.position + Vector2i(84, 6), Vector2i(40, 18))
		role_b = Rect2i(top.position + Vector2i(128, 7), Vector2i(18, 16))
	else:
		device_a = Rect2i(top.position + Vector2i(6, 8), Vector2i(18, 40))
		role_a = Rect2i(top.position + Vector2i(7, 52), Vector2i(16, 18))
		device_b = Rect2i(top.position + Vector2i(6, 84), Vector2i(18, 40))
		role_b = Rect2i(top.position + Vector2i(7, 128), Vector2i(16, 18))
	return {
		"chair_a": {"owner_family": "ergonomic_chair", "cell": p.work_cells[0].duplicate(), "included_in_base": false, "adds_base_collision": false},
		"chair_b": {"owner_family": "ergonomic_chair", "cell": p.work_cells[1].duplicate(), "included_in_base": false, "adds_base_collision": false},
		"device_a": {"owner_family": "computer_kit", "surface_zone": device_a, "included_in_base": false, "adds_base_collision": false},
		"device_b": {"owner_family": "computer_kit", "surface_zone": device_b, "included_in_base": false, "adds_base_collision": false},
		"role_a": {"owner_family": "role_tool_kits", "surface_zone": role_a, "included_in_base": false, "adds_base_collision": false},
		"role_b": {"owner_family": "role_tool_kits", "surface_zone": role_b, "included_in_base": false, "adds_base_collision": false},
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
	var inset := Rect2i(floor.position + Vector2i(4, 10), floor.size - Vector2i(8, 20)) if floor.size.x > floor.size.y else Rect2i(floor.position + Vector2i(1, 4), floor.size - Vector2i(2, 8))
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
	# Two bays and a centered cable well distinguish this long shared bench from
	# the 64px compact desk and equipment-heavy prototype/research benches.
	if rect.size.x > rect.size.y:
		_paint(image, Rect2i(rect.position + Vector2i(17, 12), Vector2i(31, 1)), EDGE)
		_paint(image, Rect2i(rect.position + Vector2i(102, 18), Vector2i(27, 1)), LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(70, 5), Vector2i(14, 6)), INK)
		_paint(image, Rect2i(rect.position + Vector2i(73, 7), Vector2i(3, 2)), LEG_LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(78, 7), Vector2i(3, 2)), LEG_LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(76, 12), Vector2i(2, 14)), SHADE)
	else:
		_paint(image, Rect2i(rect.position + Vector2i(12, 17), Vector2i(1, 31)), EDGE)
		_paint(image, Rect2i(rect.position + Vector2i(18, 102), Vector2i(1, 27)), LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(5, 70), Vector2i(6, 14)), INK)
		_paint(image, Rect2i(rect.position + Vector2i(7, 73), Vector2i(2, 3)), LEG_LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(7, 78), Vector2i(2, 3)), LEG_LIGHT)
		_paint(image, Rect2i(rect.position + Vector2i(12, 76), Vector2i(14, 2)), SHADE)

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
		"name": "SharedWorkbench" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/shared-workbench-v1/%s-%s.png" % [side, layer_name],
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
		var viewpoints: Array[Dictionary] = []
		for raw_cell: Variant in p.clearance:
			viewpoints.append({"cell": (raw_cell as Array).duplicate(), "visual_bounds": [-24, -72, 48, 80]})
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
			"standing_viewpoints": viewpoints,
			"proposed_workstation_interaction": p.interaction.duplicate(),
			"proposed_employee_look_vector": p.employee_look_vector.duplicate(),
			"overlay_contract": overlay_contract(side),
			"proposed_work_cells": p.work_cells.duplicate(true),
			"calibration_limitations": ["Passive geometry admission only; no workstation action, reservation, multi-actor or seated capability is claimed.", "Both chairs, both devices and both role kits are separate asset-family responsibilities."],
		}
	return {
		"display_name": "Shared workbench candidate",
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none",
		"facing_profiles": variants,
	}
