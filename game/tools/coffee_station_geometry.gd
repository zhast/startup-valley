extends Node2D
## DEV-ONLY deterministic four-service-side coffee station. The family reuses
## the exact modular counter and reviewed native material tiles, but draws every
## appliance/decor silhouette from explicit pixel geometry. No generated side
## source is rotated, mirrored, masked, repainted, or sampled by this helper.

const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const SIDES: Array[String] = ["north", "east", "south", "west"]
const CANVAS := Vector2i(192, 256)
const PIVOT := Vector2i(96, 192)
const LAYERS: Array[String] = [
	"FloorShadow", "CounterCarcass", "CounterTop", "CounterFront",
	"CounterPlinth", "ServicePanel", "Espresso", "Grinder",
	"Serviceware", "Plant",
]
const COMPONENTS: Array[String] = ["Espresso", "Grinder", "Serviceware", "Plant"]

const INK := Color("202326")
const INK_SOFT := Color("343536")
const MACHINE := Color("3b4b52")
const MACHINE_DARK := Color("27343a")
const STEEL := Color("c9c7b9")
const STEEL_SHADE := Color("777f7e")
const CERULEAN := Color("55a9cb")
const VERMILION := Color("cf6049")
const CREAM := Color("f0e2bd")
const COFFEE := Color("754426")
const WOOD_DARK := Color("5d3d27")
const WOOD_MID := Color("805535")
const BRASS := Color("d4a85e")
const LEAF_DARK := Color("315838")
const LEAF := Color("4f8b48")
const LEAF_LIGHT := Color("83ad58")
const POT := Color("bd6f43")
const SHADOW := Color("746757")

var resolved: Dictionary = {}
var layers: Dictionary = {}
var render_order: Array[String] = []
var cabinet: Node2D

class PixelLayer extends Node2D:

	var rects: Array[Dictionary] = []
	var tiles: Array[Dictionary] = []

	func _draw() -> void:
		for item: Dictionary in tiles:
			draw_texture_rect(item.texture, Rect2(item.rect), true)
		for item: Dictionary in rects:
			draw_rect(Rect2(item.rect), item.color)

static func colored(rect: Rect2i, color: Color) -> Dictionary:
	return {"rect": rect, "color": color}

static func _add(items: Array[Dictionary], rect: Rect2i, color: Color) -> void:
	if rect.has_area():
		items.append(colored(rect, color))

static func _outline(items: Array[Dictionary], rect: Rect2i, color: Color) -> void:
	_add(items, Rect2i(rect.position, Vector2i(rect.size.x, 1)), color)
	_add(items, Rect2i(rect.position, Vector2i(1, rect.size.y)), color)
	_add(items, Rect2i(rect.position + Vector2i(0, rect.size.y - 1), Vector2i(rect.size.x, 1)), color)
	_add(items, Rect2i(rect.position + Vector2i(rect.size.x - 1, 0), Vector2i(1, rect.size.y)), color)

static func _merge_rect(current: Rect2i, addition: Rect2i) -> Rect2i:
	if not addition.has_area(): return current
	return current.merge(addition) if current.has_area() else addition

static func _plan_bounds(plan: Dictionary) -> Rect2i:
	var result := Rect2i()
	for item: Dictionary in plan.get("rects", []):
		result = _merge_rect(result, item.rect)
	for rect: Rect2i in plan.get("tile_rects", []):
		result = _merge_rect(result, rect)
	return result

static func supports(side: String) -> Dictionary:
	# These are explicit raised-counter contact planes in host-local screen
	# coordinates. E/W are authored rectangles, not transformed raster art.
	match side:
		"north":
			return {
				"Espresso": Rect2i(-16, -37, 31, 15),
				"Grinder": Rect2i(-35, -35, 11, 11),
				"Serviceware": Rect2i(-25, -44, 7, 5),
				"Plant": Rect2i(27, -37, 12, 12),
			}
		"east":
			return {
				"Espresso": Rect2i(-10, -48, 15, 31),
				"Grinder": Rect2i(-8, -67, 11, 11),
				"Serviceware": Rect2i(7, -57, 5, 7),
				"Plant": Rect2i(-7, -5, 12, 12),
			}
		"south":
			return {
				"Espresso": Rect2i(-15, -42, 31, 15),
				"Grinder": Rect2i(24, -40, 11, 11),
				"Serviceware": Rect2i(18, -25, 7, 5),
				"Plant": Rect2i(-39, -39, 12, 12),
			}
		"west":
			return {
				"Espresso": Rect2i(-5, -47, 15, 31),
				"Grinder": Rect2i(-3, -8, 11, 11),
				"Serviceware": Rect2i(-12, -14, 5, 7),
				"Plant": Rect2i(-5, -71, 12, 12),
			}
	return {}

static func _extrusion(contact: Rect2i, rise: int) -> Dictionary:
	var roof := Rect2i(contact.position - Vector2i(0, rise), contact.size)
	var face := Rect2i(contact.position.x, roof.end.y, contact.size.x, rise)
	return {"contact": contact, "roof": roof, "face": face,
		"bounds": Rect2i(roof.position, Vector2i(roof.size.x, roof.size.y + rise))}

static func _machine_plan(side: String, contact: Rect2i) -> Dictionary:
	var geometry := _extrusion(contact, 31)
	var roof: Rect2i = geometry.roof
	var face: Rect2i = geometry.face
	var rects: Array[Dictionary] = []
	# The reviewed isotropic powdercoat fills roof.grow(-1) at configure time.
	_outline(rects, roof, INK)
	_add(rects, Rect2i(roof.position + Vector2i.ONE, Vector2i(roof.size.x - 2, 1)), STEEL_SHADE)
	_add(rects, face, INK)
	_add(rects, face.grow(-1), MACHINE)
	_add(rects, Rect2i(face.position + Vector2i(1, 1), Vector2i(face.size.x - 2, 2)), MACHINE_DARK)
	_add(rects, Rect2i(face.position + Vector2i(1, face.size.y - 4), Vector2i(face.size.x - 2, 3)), MACHINE_DARK)
	match side:
		"south":
			# Actual service front: high-contrast display, twin group heads,
			# spouts and drip tray stay readable at the native 31px width.
			_add(rects, Rect2i(face.position + Vector2i(6, 5), Vector2i(19, 6)), INK)
			_add(rects, Rect2i(face.position + Vector2i(8, 6), Vector2i(15, 3)), CERULEAN)
			_add(rects, Rect2i(face.position + Vector2i(5, 13), Vector2i(8, 6)), STEEL)
			_add(rects, Rect2i(face.position + Vector2i(18, 13), Vector2i(8, 6)), STEEL)
			_add(rects, Rect2i(face.position + Vector2i(8, 19), Vector2i(2, 5)), STEEL_SHADE)
			_add(rects, Rect2i(face.position + Vector2i(21, 19), Vector2i(2, 5)), STEEL_SHADE)
			_add(rects, Rect2i(face.position + Vector2i(4, 25), Vector2i(23, 3)), STEEL_SHADE)
			_add(rects, Rect2i(face.position + Vector2i(5, 26), Vector2i(2, 1)), INK_SOFT)
			_add(rects, Rect2i(face.position + Vector2i(9, 26), Vector2i(2, 1)), INK_SOFT)
			_add(rects, Rect2i(face.position + Vector2i(13, 26), Vector2i(2, 1)), INK_SOFT)
			_add(rects, Rect2i(face.position + Vector2i(17, 26), Vector2i(2, 1)), INK_SOFT)
			_add(rects, Rect2i(face.position + Vector2i(25, 7), Vector2i(2, 2)), VERMILION)
		"north":
			# The visible camera face is the real rear: reservoir hatch, vents,
			# cable and no borrowed front controls.
			_add(rects, Rect2i(face.position + Vector2i(5, 5), Vector2i(21, 15)), MACHINE_DARK)
			_outline(rects, Rect2i(face.position + Vector2i(5, 5), Vector2i(21, 15)), STEEL_SHADE)
			for row: int in range(3):
				_add(rects, Rect2i(face.position + Vector2i(9, 8 + row * 3), Vector2i(13, 1)), STEEL_SHADE)
			_add(rects, Rect2i(face.position + Vector2i(7, 24), Vector2i(16, 2)), INK_SOFT)
			_add(rects, Rect2i(face.position + Vector2i(24, 22), Vector2i(2, 6)), INK)
		"east":
			# Service controls are edge-on. This independently authored narrow
			# camera end shows the translucent reservoir gauge and steam knob.
			_add(rects, Rect2i(face.position + Vector2i(3, 5), Vector2i(6, 17)), INK)
			_add(rects, Rect2i(face.position + Vector2i(4, 6), Vector2i(4, 13)), CERULEAN)
			_add(rects, Rect2i(face.position + Vector2i(9, 8), Vector2i(3, 3)), STEEL)
			_add(rects, Rect2i(face.position + Vector2i(4, 24), Vector2i(7, 3)), STEEL_SHADE)
		"west":
			# Opposite genuine end: bold paired fasteners and exhaust slots.
			_add(rects, Rect2i(face.position + Vector2i(3, 5), Vector2i(9, 18)), MACHINE_DARK)
			_add(rects, Rect2i(face.position + Vector2i(5, 7), Vector2i(3, 3)), BRASS)
			_add(rects, Rect2i(face.position + Vector2i(5, 18), Vector2i(3, 3)), BRASS)
			for row: int in range(3):
				_add(rects, Rect2i(face.position + Vector2i(9, 8 + row * 4), Vector2i(2, 2)), STEEL_SHADE)
			_add(rects, Rect2i(face.position + Vector2i(3, 25), Vector2i(9, 2)), INK)
	return {"rects": rects, "tile_rects": [roof.grow(-1)], "contact": contact,
		"geometry": geometry}

static func _grinder_plan(side: String, contact: Rect2i) -> Dictionary:
	var rects: Array[Dictionary] = []
	var top_y := contact.position.y - 23
	_add(rects, Rect2i(contact.position.x - 1, top_y, contact.size.x + 2, 2), INK)
	_add(rects, Rect2i(contact.position.x, top_y + 2, contact.size.x, 2), STEEL_SHADE)
	_add(rects, Rect2i(contact.position.x + 1, top_y + 4, contact.size.x - 2, 7), COFFEE)
	_add(rects, Rect2i(contact.position.x + 2, top_y + 5, contact.size.x - 4, 2), Color("9b6540"))
	_add(rects, Rect2i(contact.position.x, top_y + 11, contact.size.x, 3), INK)
	_add(rects, Rect2i(contact.position.x + 1, top_y + 14, contact.size.x - 2, 15), MACHINE)
	_add(rects, Rect2i(contact.position.x, top_y + 29, contact.size.x, 4), INK)
	if side == "south":
		_add(rects, Rect2i(Vector2i(contact.position.x + contact.size.x - 4, top_y + 17), Vector2i(2, 2)), VERMILION)
	elif side == "north":
		_add(rects, Rect2i(Vector2i(contact.position.x + 3, top_y + 18), Vector2i(contact.size.x - 6, 1)), STEEL_SHADE)
	else:
		_add(rects, Rect2i(Vector2i(contact.position.x + (2 if side == "east" else contact.size.x - 4), top_y + 18), Vector2i(2, 6)), CERULEAN if side == "east" else STEEL_SHADE)
	return {"rects": rects, "tile_rects": [], "contact": contact}

static func _serviceware_plan(side: String, contact: Rect2i) -> Dictionary:
	var rects: Array[Dictionary] = []
	if side in ["north", "south"]:
		var y := contact.position.y - 7
		_add(rects, Rect2i(contact.position.x, y, 4, 6), INK)
		_add(rects, Rect2i(contact.position.x + 1, y + 1, 2, 4), CREAM)
		_add(rects, Rect2i(contact.position.x + 3, y + 2, 2, 3), CREAM)
		_add(rects, Rect2i(contact.position.x + 3, y + 1, 4, 6), INK)
		_add(rects, Rect2i(contact.position.x + 4, y + 2, 2, 3), CREAM)
		_add(rects, Rect2i(contact.position.x + 1, y + 1, 2, 1), COFFEE)
		_add(rects, Rect2i(contact.position.x + 4, y + 2, 2, 1), COFFEE)
	else:
		var y := contact.position.y - 5
		_add(rects, Rect2i(contact.position.x, y, 5, 6), INK)
		_add(rects, Rect2i(contact.position.x + 1, y + 1, 3, 4), CREAM)
		_add(rects, Rect2i(contact.position.x + (4 if side == "east" else -1), y + 2, 2, 3), CREAM)
		_add(rects, Rect2i(contact.position.x, y - 4, 5, 5), INK)
		_add(rects, Rect2i(contact.position.x + 1, y - 3, 3, 3), CREAM)
		_add(rects, Rect2i(contact.position.x + 1, y - 3, 3, 1), COFFEE)
	return {"rects": rects, "tile_rects": [], "contact": contact}

static func _plant_plan(side: String, contact: Rect2i) -> Dictionary:
	var rects: Array[Dictionary] = []
	var center := contact.position.x + contact.size.x / 2
	var bottom := contact.end.y
	# Four explicit leaf clusters keep upper-left light fixed while avoiding a
	# mirrored bitmap shortcut. The plant remains decorative, not service-facing.
	var lean := {"north": -1, "east": 1, "south": 0, "west": -2}[side] as int
	_add(rects, Rect2i(center - 1, bottom - 20, 2, 12), LEAF_DARK)
	_add(rects, Rect2i(center - 7 + lean, bottom - 20, 7, 4), LEAF)
	_add(rects, Rect2i(center - 5 + lean, bottom - 23, 5, 4), LEAF_LIGHT)
	_add(rects, Rect2i(center + 1 + lean, bottom - 18, 7, 4), LEAF)
	_add(rects, Rect2i(center + 2 + lean, bottom - 21, 5, 4), LEAF_LIGHT)
	_add(rects, Rect2i(center - 3, bottom - 25, 6, 5), LEAF)
	_add(rects, Rect2i(center - 1, bottom - 24, 3, 3), LEAF_LIGHT)
	_add(rects, Rect2i(contact.position.x + 1, bottom - 10, contact.size.x - 2, 3), INK)
	_add(rects, Rect2i(contact.position.x + 2, bottom - 7, contact.size.x - 4, 6), POT)
	_add(rects, Rect2i(contact.position.x + 3, bottom - 6, 2, 4), Color("dd9460"))
	_add(rects, Rect2i(contact.position.x + 3, bottom - 1, contact.size.x - 6, 1), INK)
	return {"rects": rects, "tile_rects": [], "contact": contact}

static func _service_panel_plan(side: String, counter: Dictionary) -> Dictionary:
	var rects: Array[Dictionary] = []
	var front: Rect2i = counter.front
	var panel := Rect2i(front.position + Vector2i(4, 4), front.size - Vector2i(8, 8))
	_add(rects, panel, INK)
	_add(rects, panel.grow(-1), WOOD_DARK)
	match side:
		"south":
			# Open cup cubby plus two doors completes the visible service face.
			var cubby := Rect2i(panel.position + Vector2i(3, 3), Vector2i(25, panel.size.y - 6))
			_add(rects, cubby, INK_SOFT)
			_add(rects, Rect2i(cubby.position + Vector2i(2, 6), Vector2i(cubby.size.x - 4, 1)), STEEL_SHADE)
			for index: int in range(3):
				_add(rects, Rect2i(cubby.position + Vector2i(3 + index * 7, 2), Vector2i(4, 4)), CREAM)
			var doors := Rect2i(panel.position + Vector2i(31, 2), Vector2i(panel.size.x - 34, panel.size.y - 4))
			_add(rects, doors, WOOD_MID)
			_add(rects, Rect2i(doors.position + Vector2i(doors.size.x / 2, 0), Vector2i(1, doors.size.y)), INK)
			_add(rects, Rect2i(doors.position + Vector2i(doors.size.x / 2 - 3, 7), Vector2i(2, 4)), BRASS)
			_add(rects, Rect2i(doors.position + Vector2i(doors.size.x / 2 + 2, 7), Vector2i(2, 4)), BRASS)
		"north":
			# Calm true rear with cable grommet and ventilation, not front doors.
			for x: int in range(panel.position.x + 5, panel.end.x - 4, 18):
				_add(rects, Rect2i(x, panel.position.y + 3, 1, panel.size.y - 6), WOOD_MID)
			for row: int in range(3):
				_add(rects, Rect2i(panel.position + Vector2i(29, 5 + row * 4), Vector2i(26, 1)), INK_SOFT)
			_add(rects, Rect2i(panel.end - Vector2i(13, 10), Vector2i(6, 6)), INK_SOFT)
			_add(rects, Rect2i(panel.end - Vector2i(11, 8), Vector2i(2, 2)), STEEL_SHADE)
		"east":
			_add(rects, Rect2i(panel.position + Vector2i(3, 3), Vector2i(panel.size.x - 6, panel.size.y - 6)), WOOD_MID)
			_add(rects, Rect2i(panel.position + Vector2i(5, 5), Vector2i(4, panel.size.y - 10)), CERULEAN)
			_add(rects, Rect2i(panel.end - Vector2i(8, 12), Vector2i(3, 7)), BRASS)
		"west":
			_add(rects, Rect2i(panel.position + Vector2i(3, 3), Vector2i(panel.size.x - 6, panel.size.y - 6)), WOOD_MID)
			_add(rects, Rect2i(panel.position + Vector2i(5, 5), Vector2i(panel.size.x - 10, 2)), STEEL_SHADE)
			_add(rects, Rect2i(panel.position + Vector2i(5, 10), Vector2i(panel.size.x - 10, 2)), STEEL_SHADE)
			_add(rects, Rect2i(panel.position + Vector2i(5, 15), Vector2i(3, 3)), BRASS)
			_add(rects, Rect2i(panel.end - Vector2i(8, 9), Vector2i(3, 3)), BRASS)
	return {"rects": rects, "tile_rects": []}

static func _shadow_plan(side: String, counter: Dictionary) -> Dictionary:
	var rects: Array[Dictionary] = []
	var floor: Rect2i = counter.floor
	_add(rects, Rect2i(floor.position.x + 3, floor.end.y - 3, floor.size.x - 6, 4), SHADOW)
	_add(rects, Rect2i(floor.position.x + 8, floor.end.y + 1, floor.size.x - 16, 2), SHADOW)
	# Break the edge into pixels rather than treating transparent padding as a
	# giant collision or using partial alpha.
	for x: int in range(floor.position.x + 10, floor.end.x - 10, 8):
		_add(rects, Rect2i(x, floor.end.y + 3, 4, 1), SHADOW)
	return {"rects": rects, "tile_rects": []}

static func component_plan(side: String, component: String) -> Dictionary:
	var all_supports := supports(side)
	if all_supports.is_empty() or not all_supports.has(component): return {}
	var contact: Rect2i = all_supports[component]
	match component:
		"Espresso": return _machine_plan(side, contact)
		"Grinder": return _grinder_plan(side, contact)
		"Serviceware": return _serviceware_plan(side, contact)
		"Plant": return _plant_plan(side, contact)
	return {}

static func profile(side: String) -> Dictionary:
	var counter: Dictionary = CABINET.profile("counter", side)
	var all_supports := supports(side)
	if counter.is_empty() or all_supports.is_empty(): return {}
	var component_bounds: Dictionary = {}
	var full_bounds: Rect2i = counter.visual_bounds
	full_bounds = _merge_rect(full_bounds, _plan_bounds(_shadow_plan(side, counter)))
	full_bounds = _merge_rect(full_bounds, _plan_bounds(_service_panel_plan(side, counter)))
	var order := COMPONENTS.duplicate()
	order.sort_custom(func(a: String, b: String) -> bool:
		var left: Rect2i = all_supports[a]
		var right: Rect2i = all_supports[b]
		return left.end.y < right.end.y if left.end.y != right.end.y else a < b
	)
	for component: String in COMPONENTS:
		var bounds := _plan_bounds(component_plan(side, component))
		component_bounds[component] = bounds
		full_bounds = _merge_rect(full_bounds, bounds)
	var result := counter.duplicate(true)
	result["canvas"] = CANVAS
	result["pivot"] = PIVOT
	result["supports"] = all_supports
	result["component_bounds"] = component_bounds
	result["component_order"] = order
	result["visual_bounds"] = full_bounds
	result["machine_camera_face"] = {"north": "rear", "east": "reservoir_end", "south": "service_controls", "west": "vent_end"}[side]
	result["service_controls_visibility"] = "front" if side == "south" else ("rear_hidden" if side == "north" else "edge_on")
	result["runtime_approved"] = false
	result["derivation"] = "deterministic_code_geometry_plus_reviewed_native_tiles"
	return result

func _add_layer(name_value: String, plan: Dictionary, powdercoat: Texture2D = null) -> PixelLayer:
	var layer := PixelLayer.new()
	layer.name = name_value
	layer.rects.assign(plan.get("rects", []))
	for rect: Rect2i in plan.get("tile_rects", []):
		layer.tiles.append({"rect": rect, "texture": powdercoat})
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.z_index = -1 if name_value == "FloorShadow" else 0
	add_child(layer)
	layers[name_value] = layer
	return layer

func configure(side: String, horizontal_tile: Texture2D, vertical_tile: Texture2D, powdercoat_tile: Texture2D) -> bool:
	var next := profile(side)
	if next.is_empty(): return false
	for material: Texture2D in [horizontal_tile, vertical_tile, powdercoat_tile]:
		if material == null or material.get_size() != Vector2(32, 32): return false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	layers.clear()
	render_order.clear()
	resolved = next
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE
	rotation = 0.0
	_add_layer("FloorShadow", _shadow_plan(side, next))
	cabinet = CABINET.new()
	cabinet.name = "ExactCounter"
	add_child(cabinet)
	if not cabinet.configure("counter", side, horizontal_tile, vertical_tile):
		cabinet.free()
		cabinet = null
		return false
	var cabinet_names := {
		"Carcass": "CounterCarcass", "Top": "CounterTop",
		"Front": "CounterFront", "Plinth": "CounterPlinth",
	}
	for original: String in cabinet_names:
		var name_value: String = cabinet_names[original]
		var node: Node2D = cabinet.layers[original]
		node.name = name_value
		layers[name_value] = node
	(cabinet.layers.Insert as CanvasItem).hide()
	_add_layer("ServicePanel", _service_panel_plan(side, next))
	var component_nodes: Dictionary = {}
	for component: String in COMPONENTS:
		component_nodes[component] = _add_layer(component, component_plan(side, component), powdercoat_tile if component == "Espresso" else null)
	# Node declaration order is the exact same-depth rear-to-front contract.
	for component: String in next.component_order:
		move_child(component_nodes[component], get_child_count() - 1)
	render_order.assign(["FloorShadow", "CounterCarcass", "CounterTop", "CounterFront", "CounterPlinth", "ServicePanel"])
	for component: String in next.component_order: render_order.append(component)
	return true
