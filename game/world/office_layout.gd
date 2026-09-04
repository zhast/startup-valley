class_name OfficeLayout
extends RefCounted
## Authoritative development-authored architecture and furniture geometry.
## Coordinates are floor cells; image overhang is not physical occupancy.

const DEFAULT_PATH := "res://data/office_layout.json"
const DEFAULT_CATALOG_PATH := "res://data/furniture_catalog.json"
const NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var data: Dictionary = {}
var catalog: Dictionary = {}
var tile_size: int = 32
var width: int = 40
var height: int = 23
var _floor: Dictionary[Vector2i, bool] = {}
var _entrances: Array[Vector2i] = []
var _circulation: Dictionary[Vector2i, bool] = {}
var _definition_errors: Array[String] = []

func load_files(path: String = DEFAULT_PATH, catalog_path: String = DEFAULT_CATALOG_PATH) -> bool:
	var room_json: Variant = _read_json(path)
	var catalog_json: Variant = _read_json(catalog_path)
	if not room_json is Dictionary or not catalog_json is Dictionary:
		configure({}, {})
		_definition_errors.append("Room and furniture catalog must be JSON objects")
		return false
	configure(room_json as Dictionary, catalog_json as Dictionary)
	return _definition_errors.is_empty()

func configure(room_data: Dictionary, furniture_data: Dictionary) -> void:
	data = room_data.duplicate(true)
	catalog = furniture_data.get("furniture", furniture_data).duplicate(true)
	tile_size = int(data.get("tile_size", 32))
	width = int(data.get("width", 0))
	height = int(data.get("height", 0))
	_floor.clear()
	_entrances.clear()
	_circulation.clear()
	_definition_errors.clear()
	if tile_size != 32 or width < 1 or height < 1 or width > 256 or height > 256:
		_definition_errors.append("Room must use a 32px grid with dimensions between 1 and 256")
		return
	for rectangle: Variant in data.get("floor_rects", []):
		_apply_rectangle(_floor, rectangle, true, "floor")
	for rectangle: Variant in data.get("wall_rects", []):
		_apply_rectangle(_floor, rectangle, false, "wall")
	for door: Dictionary in data.get("doors", []):
		var grid := vector(door.get("grid", []), Vector2i(-1, -1))
		var rectangle: Array = [grid.x, grid.y, int(door.get("width", 1)), int(door.get("depth", 1))]
		var cells: Dictionary[Vector2i, bool] = {}
		_apply_rectangle(cells, rectangle, true, "door")
		for cell: Vector2i in cells:
			_floor[cell] = true
			if bool(door.get("entrance", false)) and not _entrances.has(cell):
				_entrances.append(cell)
	for rectangle: Variant in data.get("circulation_rects", []):
		_apply_rectangle(_circulation, rectangle, true, "circulation")
	if _floor.is_empty():
		_definition_errors.append("Room has no floor")
	if _entrances.is_empty():
		_definition_errors.append("Room needs an entrance door")
	for cell: Vector2i in _circulation:
		if not is_floor(cell):
			_definition_errors.append("Circulation must lie on floor at %s" % cell)
	for window: Dictionary in data.get("windows", []):
		var origin := vector(window.get("grid", []), Vector2i(-1, -1))
		for y: int in range(int(window.get("height", 1))):
			for x: int in range(int(window.get("width", 1))):
				var cell := origin + Vector2i(x, y)
				if not contains(cell) or is_floor(cell):
					_definition_errors.append("Window must occupy solid architecture at %s" % cell)

static func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text()) if file != null else null

static func vector(value: Variant, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	if value is Vector2i: return value as Vector2i
	if value is Vector2: return Vector2i(value as Vector2)
	if value is Array and value.size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return fallback

static func rectangle(value: Variant) -> Rect2:
	if value is Rect2: return value as Rect2
	if value is Array and value.size() == 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return Rect2()

func _apply_rectangle(target: Dictionary[Vector2i, bool], value: Variant, enabled: bool, label: String) -> void:
	if not value is Array or value.size() != 4:
		_definition_errors.append("%s rectangle requires x, y, width, height" % label)
		return
	var rect := Rect2i(int(value[0]), int(value[1]), int(value[2]), int(value[3]))
	if rect.size.x < 1 or rect.size.y < 1 or rect.position.x < 0 or rect.position.y < 0 or rect.end.x > width or rect.end.y > height:
		_definition_errors.append("%s rectangle extends outside room" % label)
		return
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if enabled: target[cell] = true
			else: target.erase(cell)

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func is_floor(cell: Vector2i) -> bool:
	return _floor.has(cell)

func floor_cells() -> Array[Vector2i]:
	return _floor.keys()

func entrance_cells() -> Array[Vector2i]:
	return _entrances.duplicate()

func circulation_cells() -> Array[Vector2i]:
	return _circulation.keys()

func world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / tile_size), floori(point.y / tile_size))

func navigation_data() -> Dictionary:
	# Compress the exact floor set to row runs. No second manually painted grid.
	var rectangles: Array[Array] = []
	for y: int in range(height):
		var start := -1
		for x: int in range(width + 1):
			var floor_here := is_floor(Vector2i(x, y))
			if floor_here and start < 0: start = x
			if not floor_here and start >= 0:
				rectangles.append([start, y, x - start, 1])
				start = -1
	return {"tile_size": tile_size, "width": width, "height": height, "walkable_rects": rectangles, "wall_rects": []}

func resolve_placements(hire_count: int, overrides: Dictionary = {}) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	for original: Dictionary in data.get("props", []):
		if int(original.get("required_hires", 0)) > maxi(0, hire_count): continue
		var raw := original.duplicate(true)
		var override: Variant = overrides.get(str(raw.get("id", "")), {})
		if override is Dictionary:
			# Coordinates/facing are editable. Ownership, art and unlocks are not.
			for field: String in ["grid", "facing"]:
				if override.has(field): raw[field] = override[field]
		elif override is Vector2i or override is Vector2 or override is Array:
			raw["grid"] = override
		placements.append(resolve(raw))
	return placements

func resolve(raw: Dictionary) -> Dictionary:
	var placement := raw.duplicate(true)
	var kind := str(raw.get("kind", ""))
	var profile: Dictionary = catalog.get(kind, {}).duplicate(true)
	var grid := vector(raw.get("grid", []), Vector2i(-999, -999))
	placement["id"] = str(raw.get("id", ""))
	placement["kind"] = kind
	placement["owner_id"] = str(raw.get("owner_id", ""))
	placement["grid"] = grid
	placement["facing"] = str(raw.get("facing", "south"))
	placement["profile"] = profile
	placement["occupied"] = _offset_cells(profile.get("occupied", []), grid)
	placement["clearance"] = _offset_cells(profile.get("clearance", []), grid)
	placement["interaction"] = grid + vector(profile.get("interaction", []))
	placement["work_cell"] = grid + vector(profile.get("work_cell", profile.get("interaction", [])))
	placement["anchor_offset"] = Vector2(vector(profile.get("anchor_offset", [0, 0])))
	placement["anchor"] = world(grid) + placement["anchor_offset"]
	placement["visual_bounds"] = rectangle(profile.get("visual_bounds", []))
	placement["world_visual_bounds"] = Rect2(placement["anchor"] + placement["visual_bounds"].position, placement["visual_bounds"].size)
	placement["layers"] = profile.get("layers", {}).duplicate(true)
	return placement

static func _offset_cells(values: Array, grid: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for value: Variant in values:
		var cell := grid + vector(value)
		if not cells.has(cell): cells.append(cell)
	return cells

func placement_by_id(id: String, hire_count: int, overrides: Dictionary = {}) -> Dictionary:
	for placement: Dictionary in resolve_placements(hire_count, overrides):
		if placement.id == id: return placement
	return {}

func employee_spawn(id: String) -> Vector2i:
	for employee: Dictionary in data.get("employees", []):
		if str(employee.get("id", "")) == id: return vector(employee.get("spawn", []))
	return vector(data.get("player_spawn", []))

func occupied_cells(placements: Array[Dictionary]) -> Dictionary[Vector2i, String]:
	var cells: Dictionary[Vector2i, String] = {}
	for placement: Dictionary in placements:
		for cell: Vector2i in placement.get("occupied", []): cells[cell] = str(placement.id)
	return cells

func collision_rects(placements: Array[Dictionary]) -> Array[Rect2]:
	var rectangles: Array[Rect2] = []
	for cell: Vector2i in occupied_cells(placements):
		rectangles.append(Rect2(Vector2(cell) * tile_size, Vector2.ONE * tile_size))
	return rectangles

func walkable_cells(placements: Array[Dictionary]) -> Array[Vector2i]:
	var occupied := occupied_cells(placements)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _floor:
		if not occupied.has(cell): cells.append(cell)
	return cells

func reachable_cells(placements: Array[Dictionary]) -> Dictionary[Vector2i, bool]:
	var occupied := occupied_cells(placements)
	var reached: Dictionary[Vector2i, bool] = {}
	var pending: Array[Vector2i] = []
	# One connected entrance component; separate entrances must not hide islands.
	for entrance: Vector2i in _entrances:
		if is_floor(entrance) and not occupied.has(entrance):
			pending.append(entrance)
			reached[entrance] = true
			break
	var cursor := 0
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		for offset: Vector2i in NEIGHBORS:
			var next := cell + offset
			if not is_floor(next) or occupied.has(next) or reached.has(next): continue
			reached[next] = true
			pending.append(next)
	return reached

func validate_candidate(id: String, grid: Vector2i, facing: String, hire_count: int, overrides: Dictionary = {}) -> Dictionary:
	var candidate_overrides := overrides.duplicate(true)
	candidate_overrides[id] = {"grid": grid, "facing": facing}
	var placements := resolve_placements(hire_count, candidate_overrides)
	var result := validate_placements(placements)
	var candidate: Dictionary = {}
	for placement: Dictionary in placements:
		if placement.id == id: candidate = placement
	if candidate.is_empty():
		_add_issue(result, "unknown_placement", id, "Furniture is unavailable at this hire stage")
	result["candidate"] = candidate
	result["placements"] = placements
	return result

func validate_placements(placements: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {"valid": true, "errors": [], "issues": []}
	for error: String in _definition_errors: _add_issue(result, "invalid_room", "", error)
	var ids: Dictionary[String, bool] = {}
	var occupied: Dictionary[Vector2i, String] = {}
	for placement: Dictionary in placements:
		var id := str(placement.get("id", ""))
		var profile: Dictionary = placement.get("profile", {})
		if id.is_empty() or ids.has(id): _add_issue(result, "duplicate_id", id, "Furniture needs a unique id")
		ids[id] = true
		if profile.is_empty():
			_add_issue(result, "unknown_kind", id, "Furniture type has no authored profile")
			continue
		if not profile.get("facings", []).has(placement.get("facing", "")):
			_add_issue(result, "unsupported_facing", id, "No authored art for this facing")
		if placement.get("occupied", []).is_empty(): _add_issue(result, "empty_footprint", id, "Furniture needs an occupied footprint")
		for cell: Vector2i in placement.get("occupied", []):
			if not is_floor(cell): _add_issue(result, "wall_intersection", id, "Footprint intersects a wall or room boundary", cell)
			if _entrances.has(cell): _add_issue(result, "entrance_blocked", id, "Blocks the entrance", cell)
			if _circulation.has(cell): _add_issue(result, "circulation_blocked", id, "Blocks the reserved circulation aisle", cell)
			if occupied.has(cell): _add_issue(result, "furniture_overlap", id, "Overlaps %s" % occupied[cell], cell)
			occupied[cell] = id
		_validate_visual_walls(result, placement)
	for placement: Dictionary in placements:
		var id := str(placement.id)
		for cell: Vector2i in placement.get("clearance", []):
			if not is_floor(cell): _add_issue(result, "wall_clearance", id, "Chair or interaction clearance intersects a wall", cell)
			if occupied.has(cell): _add_issue(result, "clearance_blocked", id, "Blocks chair or interaction access with %s" % occupied[cell], cell)
		var interaction: Vector2i = placement.get("interaction", Vector2i(-1, -1))
		if not is_floor(interaction) or occupied.has(interaction):
			_add_issue(result, "interaction_blocked", id, "Interaction point is not walkable", interaction)
		var work_cell: Vector2i = placement.get("work_cell", interaction)
		if not is_floor(work_cell) or occupied.has(work_cell):
			_add_issue(result, "work_cell_blocked", id, "Work or seated position is not walkable", work_cell)
	for left_index: int in range(placements.size()):
		var left := placements[left_index]
		for right_index: int in range(left_index + 1, placements.size()):
			var right := placements[right_index]
			var left_rect: Rect2 = left.get("world_visual_bounds", Rect2())
			var right_rect: Rect2 = right.get("world_visual_bounds", Rect2())
			if left_rect.has_area() and right_rect.has_area() and left_rect.intersects(right_rect):
				_add_issue(result, "visual_overlap", str(left.id), "Furniture artwork overlaps %s" % right.id)
	var reached := reachable_cells(placements)
	for entrance: Vector2i in _entrances:
		if not reached.has(entrance): _add_issue(result, "entrance_unreachable", "", "Entrance is disconnected", entrance)
	for placement: Dictionary in placements:
		var interaction: Vector2i = placement.get("interaction", Vector2i(-1, -1))
		if not reached.has(interaction): _add_issue(result, "interaction_unreachable", str(placement.id), "Cannot reach chair or interaction point from entrance", interaction)
		var work_cell: Vector2i = placement.get("work_cell", interaction)
		if not reached.has(work_cell): _add_issue(result, "work_cell_unreachable", str(placement.id), "Cannot reach work or seated position from entrance", work_cell)
	for cell: Vector2i in _floor:
		if not occupied.has(cell) and not reached.has(cell):
			_add_issue(result, "floor_disconnected", "", "Placement isolates part of the room", cell)
			break
	return result

func _validate_visual_walls(result: Dictionary, placement: Dictionary) -> void:
	var rect: Rect2 = placement.get("world_visual_bounds", Rect2())
	if not rect.has_area():
		_add_issue(result, "missing_visual_bounds", str(placement.id), "Furniture needs native visual bounds")
		return
	var start := cell_at(rect.position)
	var end := cell_at(rect.end - Vector2.ONE * 0.001)
	for y: int in range(start.y, end.y + 1):
		for x: int in range(start.x, end.x + 1):
			var cell := Vector2i(x, y)
			if not is_floor(cell):
				_add_issue(result, "visual_wall_intersection", str(placement.id), "Artwork extends into a wall; move furniture farther inward", cell)
				return

static func _add_issue(result: Dictionary, code: String, id: String, message: String, cell: Vector2i = Vector2i(-1, -1)) -> void:
	# One actionable message per reason/object; overlay still highlights its cell.
	for existing: Dictionary in result.issues:
		if existing.code == code and existing.id == id and existing.message == message: return
	result.valid = false
	result.errors.append((id + ": " if not id.is_empty() else "") + message)
	result.issues.append({"code": code, "id": id, "message": message, "cell": cell})
