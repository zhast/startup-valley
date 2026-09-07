class_name CollaborationTableGeometry
extends RefCounted
## Exact screen-axis collaboration table. Each camera-space view is declared
## independently; no rendered bitmap is rotated or mirrored.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["FloorShadow", "RearStructure", "FrontStructure"]
const CANVAS := Vector2i(256, 272)
const PIVOT := Vector2i(128, 176)
const CHAIR_CANVAS := Vector2i(96, 160)
const CHAIR_PATHS := {
	"north": ["res://assets/runtime/office/workstations-v2/chair-north.png"],
	"east": ["res://assets/runtime/office/workstations-v2/chair-east-rear.png", "res://assets/runtime/office/workstations-v2/chair-east-front.png"],
	"south": ["res://assets/runtime/office/workstations-v2/chair-south.png"],
	"west": ["res://assets/runtime/office/workstations-v2/chair-west-rear.png", "res://assets/runtime/office/workstations-v2/chair-west-front.png"],
}
const HORIZONTAL_TILE := "res://tests/fixtures/furniture-calibration/materials/oak-horizontal-v1-soft.png"
const VERTICAL_TILE := "res://tests/fixtures/furniture-calibration/materials/oak-vertical-v1-soft.png"
const INK := Color("282622")
const CHARCOAL := Color("383833")
const METAL_LIGHT := Color("53524a")
const EDGE := Color("77512f")
const LIGHT := Color("d1a369")
const SHADE := Color("583d28")
const PARCHMENT := Color("eee2c8")
const PAPER_SHADE := Color("c9aa79")
const INDIGO := Color("354b98")
const INDIGO_DARK := Color("202d5c")
const VERMILION := Color("fa4616")
const SHADOW := Color("6a5944")

static func profile(side: String) -> Dictionary:
	match side:
		"north":
			return _horizontal(side, [[-54, -44], [-18, -29], [42, -48]], [-7, -38], [-36, -25], Vector2i.ZERO)
		"south":
			# South's reference seat is north of the table. The previous base-only
			# candidate kept North's pivot and therefore painted one cell away from
			# its declared floor mask. Move the independently authored South view,
			# notes and legs together; no bitmap is rotated or mirrored.
			return _horizontal(side, [[-59, -33], [16, -45], [48, -25]], [5, -38], [35, -49], Vector2i(0, 32))
		"east":
			return _vertical(side, [[-21, -89], [7, -48], [-18, 10]], [-8, -22], [14, 24], Vector2i.ZERO)
		"west":
			# West's reference seat is east of the table, so its two-cell floor
			# mask is [-1,0]. Shift the complete authored view one cell left.
			return _vertical(side, [[7, -82], [-20, -34], [9, 14]], [5, -18], [-18, -5], Vector2i(-32, 0))
	return {}

static func _horizontal(side: String, notes: Array, cable: Array, pen: Array, table_shift: Vector2i) -> Dictionary:
	var occupied: Array[Array] = []
	var rows: Array[int] = []
	rows.assign([-1, 0] if side == "north" else [0, 1])
	for y: int in rows:
		for x: int in range(-2, 3): occupied.append([x, y])
	var north_y := -2 if side == "north" else -1
	var south_y := 1 if side == "north" else 2
	var reference_y := south_y if side == "north" else north_y
	return {"facing": side, "axis": "horizontal", "top": Rect2i(Vector2i(-80, -64) + table_shift, Vector2i(160, 64)),
		"floor": Rect2i(Vector2i(-80, -32) + table_shift, Vector2i(160, 64)), "contact_y": 32 + table_shift.y,
		"table_shift": table_shift, "occupied": occupied,
		"clearance": [[-1, north_y], [1, north_y], [-1, south_y], [1, south_y]],
		"interaction": [-1, reference_y], "notes": notes, "cable": cable, "pen": pen,
		"chairs": _horizontal_chairs(north_y, south_y),
		"slots": _horizontal_slots(side, north_y, south_y)}

static func _vertical(side: String, notes: Array, cable: Array, pen: Array, table_shift: Vector2i) -> Dictionary:
	var occupied: Array[Array] = []
	var columns: Array[int] = []
	columns.assign([0, 1] if side == "east" else [-1, 0])
	for x: int in columns:
		for y: int in range(-2, 3): occupied.append([x, y])
	var west_x := -1 if side == "east" else -2
	var east_x := 2 if side == "east" else 1
	var reference_x := west_x if side == "east" else east_x
	return {"facing": side, "axis": "vertical", "top": Rect2i(Vector2i(-32, -112) + table_shift, Vector2i(64, 160)),
		"floor": Rect2i(Vector2i(-32, -80) + table_shift, Vector2i(64, 160)), "contact_y": 80,
		"table_shift": table_shift, "occupied": occupied,
		"clearance": [[west_x, -1], [west_x, 1], [east_x, -1], [east_x, 1]],
		"interaction": [reference_x, -1], "notes": notes, "cable": cable, "pen": pen,
		"chairs": _vertical_chairs(west_x, east_x),
		"slots": _vertical_slots(side, west_x, east_x)}

static func _seat(facing: String, cell: Array, near: bool) -> Dictionary:
	var anchors := {
		"north": {"mira": [0, -20], "theo": [0, -16]},
		"east": {"mira": [12, 3], "theo": [12, 4]},
		"south": {"mira": [0, 12], "theo": [0, 12]},
		"west": {"mira": [-12, 4], "theo": [-12, 8]},
	}
	# A rear horizontal collaborator naturally protrudes above the short table
	# edge. A rear side-facing collaborator sits entirely inside the long top's
	# screen silhouette, so its split upper body must sit above the top (z=0)
	# while remaining behind the front edge (z=3). Keeping its lower body behind
	# the top preserves chair/table contact without making the actor disappear.
	var upper_depth := 2 if not near and facing in ["east", "west"] else 10 if near else -2
	return {
		"cell": cell, "work_facing": facing,
		"visual_bounds": [-24, -72, 48, 80],
		"capability_revision": "collaboration-cluster-v2:" + facing,
		"seat_anchor_by_employee": anchors[facing].duplicate(true),
		"seat_z_offset": 7 if near else -7,
		"seat_layer_z_offsets": {"lower": 7 if near else -7, "upper": upper_depth},
		"ground_shadow_z_offset": 3 if near else -11,
	}

static func _horizontal_slots(side: String, north_y: int, south_y: int) -> Array[Dictionary]:
	# First two are the deterministic two-person pair used by the current Mina /
	# Theo roster. The other two remain valid empty seats and future-safe sockets.
	if side == "north":
		return [_seat("north", [-1, south_y], true), _seat("south", [1, north_y], false), _seat("north", [1, south_y], true), _seat("south", [-1, north_y], false)]
	return [_seat("south", [-1, north_y], false), _seat("north", [1, south_y], true), _seat("south", [1, north_y], false), _seat("north", [-1, south_y], true)]

static func _vertical_slots(side: String, west_x: int, east_x: int) -> Array[Dictionary]:
	if side == "east":
		return [_seat("east", [west_x, -1], false), _seat("west", [east_x, 1], true), _seat("east", [west_x, 1], true), _seat("west", [east_x, -1], false)]
	return [_seat("west", [east_x, -1], false), _seat("east", [west_x, 1], true), _seat("west", [east_x, 1], true), _seat("east", [west_x, -1], false)]

static func _horizontal_chairs(north_y: int, south_y: int) -> Array[Dictionary]:
	var chairs: Array[Dictionary] = []
	for x: int in [-1, 1]:
		chairs.append({"name": "NorthChair%d" % (0 if x < 0 else 1), "facing": "south", "cell": [x, north_y], "offset": [x * 32, north_y * 32 - 28], "z_offset": -9})
		chairs.append({"name": "SouthChair%d" % (0 if x < 0 else 1), "facing": "north", "cell": [x, south_y], "offset": [x * 32, south_y * 32 - 44], "z_offset": 5})
	return chairs

static func _vertical_chairs(west_x: int, east_x: int) -> Array[Dictionary]:
	var chairs: Array[Dictionary] = []
	for y: int in [-1, 1]:
		var near := y > 0
		var rear_depth := 4 if near else -10
		chairs.append({"name": "WestChair%d" % (0 if y < 0 else 1), "facing": "east", "cell": [west_x, y], "offset": [west_x * 32 + 12, y * 32 - 32], "z_offset": rear_depth})
		chairs.append({"name": "EastChair%d" % (0 if y < 0 else 1), "facing": "west", "cell": [east_x, y], "offset": [east_x * 32 - 12, y * 32 - 32], "z_offset": rear_depth})
	return chairs

static func _paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func _outlined_box(image: Image, rect: Rect2i, fill: Color) -> void:
	_paint(image, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: _paint(image, rect.grow(-1), fill)

static func _tile_top(image: Image, rect: Rect2i, tile: Image) -> void:
	_paint(image, rect, INK)
	var inside := rect.grow(-2)
	for y: int in range(inside.position.y, inside.end.y):
		for x: int in range(inside.position.x, inside.end.x):
			image.set_pixelv(PIVOT + Vector2i(x, y), tile.get_pixel(posmod(x - inside.position.x, 32), posmod(y - inside.position.y, 32)))
	_paint(image, Rect2i(rect.position + Vector2i(1, 1), Vector2i(rect.size.x - 2, 1)), LIGHT)
	_paint(image, Rect2i(rect.position + Vector2i(1, 2), Vector2i(1, rect.size.y - 3)), LIGHT)
	_paint(image, Rect2i(rect.position + Vector2i(2, rect.size.y - 2), Vector2i(rect.size.x - 3, 1)), SHADE)
	_paint(image, Rect2i(rect.position + Vector2i(rect.size.x - 2, 2), Vector2i(1, rect.size.y - 3)), SHADE)

static func _paper(image: Image, origin: Vector2i, vertical: bool) -> void:
	var size := Vector2i(10, 7) if not vertical else Vector2i(7, 10)
	_outlined_box(image, Rect2i(origin, size), PARCHMENT)
	if not vertical:
		_paint(image, Rect2i(origin + Vector2i(2, 2), Vector2i(6, 1)), PAPER_SHADE)
		_paint(image, Rect2i(origin + Vector2i(2, 4), Vector2i(4, 1)), PAPER_SHADE)
	else:
		_paint(image, Rect2i(origin + Vector2i(2, 2), Vector2i(3, 1)), PAPER_SHADE)
		_paint(image, Rect2i(origin + Vector2i(2, 4), Vector2i(3, 1)), PAPER_SHADE)
		_paint(image, Rect2i(origin + Vector2i(2, 6), Vector2i(2, 1)), PAPER_SHADE)

static func layers(side: String) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	var tile_path := HORIZONTAL_TILE if p.axis == "horizontal" else VERTICAL_TILE
	var tile := Image.load_from_file(ProjectSettings.globalize_path(tile_path))
	if tile == null or tile.get_size() != Vector2i(32, 32): return {}
	var result: Dictionary[String, Image] = {}
	for label: String in LAYERS:
		var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		result[label] = image
	var shadow := result.FloorShadow as Image
	var rear := result.RearStructure as Image
	var front := result.FrontStructure as Image
	# Draw every authored table in its local unshifted construction frame, then
	# translate the complete registered layers for South/West's corrected pivot.
	# This keeps legs, shadow, notes and top inseparable during the correction.
	var table_shift := Vector2i(p.get("table_shift", Vector2i.ZERO))
	var top: Rect2i = p.top
	top.position -= table_shift
	if p.axis == "horizontal":
		for x: int in [-72, 64]:
			_paint(shadow, Rect2i(x, -27, 8, 2), SHADOW)
			_outlined_box(rear, Rect2i(x, -59, 8, 31), CHARCOAL)
			_paint(rear, Rect2i(x + 2, -57, 2, 27), METAL_LIGHT)
			_paint(shadow, Rect2i(x, 31, 10, 2), SHADOW)
			_outlined_box(front, Rect2i(x, -2, 8, 34), CHARCOAL)
			_paint(front, Rect2i(x + 2, 0, 2, 29), METAL_LIGHT)
		_paint(shadow, Rect2i(-79, 32, 160, 2), SHADOW)
		_outlined_box(front, Rect2i(-80, -2, 160, 8), EDGE)
		_paint(front, Rect2i(-78, -1, 156, 1), LIGHT)
	else:
		for y: int in [-104, 40]:
			_paint(shadow, Rect2i(-27, y + 31, 8, 2), SHADOW)
			_outlined_box(rear, Rect2i(-28, y, 8, 32), CHARCOAL)
			_paint(rear, Rect2i(-26, y + 2, 2, 27), METAL_LIGHT)
			_paint(shadow, Rect2i(23, y + 31, 10, 2), SHADOW)
			_outlined_box(front, Rect2i(20, y, 8, 34), CHARCOAL)
			_paint(front, Rect2i(22, y + 2, 2, 29), METAL_LIGHT)
		_paint(shadow, Rect2i(31, -79, 2, 160), SHADOW)
		_outlined_box(front, Rect2i(24, -112, 8, 160), EDGE)
		_paint(front, Rect2i(25, -110, 1, 156), LIGHT)
	_tile_top(rear, top, tile)
	var cable_origin := Vector2i(int(p.cable[0]), int(p.cable[1]))
	var cable_rect := Rect2i(cable_origin, Vector2i(22, 10) if p.axis == "horizontal" else Vector2i(10, 22))
	_outlined_box(rear, cable_rect, INDIGO_DARK)
	_paint(rear, cable_rect.grow(-3), INDIGO)
	for raw: Variant in p.notes:
		_paper(rear, Vector2i(int(raw[0]), int(raw[1])), p.axis == "vertical")
	var pen := Vector2i(int(p.pen[0]), int(p.pen[1]))
	if p.axis == "horizontal":
		_paint(rear, Rect2i(pen, Vector2i(8, 2)), INK)
		_paint(rear, Rect2i(pen + Vector2i(1, 0), Vector2i(6, 1)), VERMILION)
	else:
		_paint(rear, Rect2i(pen, Vector2i(2, 8)), INK)
		_paint(rear, Rect2i(pen + Vector2i(0, 1), Vector2i(1, 6)), VERMILION)
	if table_shift != Vector2i.ZERO:
		for label: String in LAYERS:
			var source := result[label] as Image
			var shifted := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
			shifted.fill(Color(0, 0, 0, 0))
			shifted.blend_rect(source, Rect2i(Vector2i.ZERO, CANVAS), table_shift)
			result[label] = shifted
	return result

static func cluster_layers(side: String) -> Dictionary[String, Image]:
	var table := layers(side)
	if table.is_empty(): return {}
	var result: Dictionary[String, Image] = {
		"TableFloorShadow": table.FloorShadow,
		"TableRearStructure": table.RearStructure,
		"TableFrontStructure": table.FrontStructure,
	}
	for chair: Dictionary in profile(side).chairs:
		var facing := str(chair.facing)
		var sources: Array = CHAIR_PATHS.get(facing, [])
		for part_index: int in range(sources.size()):
			var source := Image.load_from_file(ProjectSettings.globalize_path(str(sources[part_index])))
			if source == null or source.get_size() != CHAIR_CANVAS: return {}
			var layer := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
			layer.fill(Color(0, 0, 0, 0))
			var offset := Vector2i(int(chair.offset[0]), int(chair.offset[1]))
			layer.blend_rect(source, Rect2i(Vector2i.ZERO, CHAIR_CANVAS), PIVOT + offset - CHAIR_CANVAS / 2)
			var suffix := "Whole" if sources.size() == 1 else "Rear" if part_index == 0 else "Front"
			result[str(chair.name) + suffix] = layer
	return result

static func cluster_specs(side: String, art_root: String) -> Array[Dictionary]:
	var p := profile(side)
	if p.is_empty(): return []
	var specs: Array[Dictionary] = [
		_layer_spec("TableFloorShadow", side, art_root, -12),
		_layer_spec("TableRearStructure", side, art_root, 0),
		_layer_spec("TableFrontStructure", side, art_root, 3),
	]
	for chair: Dictionary in p.chairs:
		var parts: Array[String] = []
		parts.assign(["Whole"] if (CHAIR_PATHS.get(str(chair.facing), []) as Array).size() == 1 else ["Rear", "Front"])
		for part_index: int in range(parts.size()):
			var name := str(chair.name) + parts[part_index]
			specs.append(_layer_spec(name, side, art_root, int(chair.z_offset) + part_index * 2))
	return specs

static func _layer_spec(name: String, side: String, art_root: String, depth: int) -> Dictionary:
	return {
		"name": name,
		"art": art_root.path_join(side + "-" + name.to_snake_case() + ".png"),
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [0, -40],
		"z_offset": depth,
	}

static func cluster_visual_bounds(side: String) -> Array[int]:
	var whole_image := cluster_whole(side)
	if whole_image.is_empty(): return []
	var ink := whole_image.get_used_rect()
	var position := Vector2i(0, -40) - CANVAS / 2 + ink.position
	return [position.x, position.y, ink.size.x, ink.size.y]

static func production_profile(side: String, art_root := "res://assets/runtime/office/collaboration-cluster-v2") -> Dictionary:
	var geometry := profile(side)
	if geometry.is_empty(): return {}
	return {
		"profile_kind": "collaboration", "status": "runtime_ready",
		"review": {"art": true, "geometry": true, "poses": true},
		"asset_revision": "collaboration-cluster-v2", "reference_gaze": side,
		"collaboration_pose_set": "reviewed-workstations-v2",
		"occupied": geometry.occupied.duplicate(true), "clearance": geometry.clearance.duplicate(true),
		"interaction": geometry.interaction.duplicate(), "anchor_offset": [0, 0],
		"visual_bounds": cluster_visual_bounds(side), "hit_bounds": cluster_visual_bounds(side),
		"render_layers": cluster_specs(side, art_root), "ambient_overlays": [],
		"collaboration_slots": geometry.slots.duplicate(true),
	}

static func whole(parts: Dictionary[String, Image]) -> Image:
	var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for label: String in LAYERS:
		var layer := parts[label] as Image
		image.blend_rect(layer, Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return image

static func cluster_whole(side: String) -> Image:
	var parts := cluster_layers(side)
	var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var by_name: Dictionary = {}
	for spec: Dictionary in cluster_specs(side, "res://"):
		by_name[str(spec.name)] = spec
	var names: Array = parts.keys()
	names.sort_custom(func(left: String, right: String) -> bool:
		var left_depth := int((by_name.get(left, {}) as Dictionary).get("z_offset", 0))
		var right_depth := int((by_name.get(right, {}) as Dictionary).get("z_offset", 0))
		return left_depth < right_depth if left_depth != right_depth else left < right
	)
	for name: String in names:
		var layer := parts[name] as Image
		# Native Image compositing is deterministic and matches the runtime
		# Sprite2D source-over operation without a slow per-pixel GDScript loop.
		image.blend_rect(layer, Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return image
