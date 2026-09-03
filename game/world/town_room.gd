class_name TownRoom
extends Node2D

const OFFICE_SHELL_TEXTURE: Texture2D = preload("res://assets/runtime/office/office-shell-base.png")
const DESK_SCENE: PackedScene = preload("res://props/desk.tscn")
const RESEARCH_TABLE_SCENE: PackedScene = preload("res://props/research_table.tscn")
const COLLABORATION_CLUSTER_SCENE: PackedScene = preload("res://props/collaboration_cluster.tscn")
const COFFEE_STATION_SCENE: PackedScene = preload("res://props/coffee_station.tscn")
const APPROVAL_CONSOLE_SCENE: PackedScene = preload("res://props/approval_console.tscn")
const ARTIFACT_ARCHIVE_SCENE: PackedScene = preload("res://props/artifact_archive.tscn")
const PROTOTYPE_BENCH_SCENE: PackedScene = preload("res://props/prototype_bench.tscn")

var tile_size: int = 32
var grid_width: int = 26
var grid_height: int = 18
var player_spawn: Vector2i = Vector2i(13, 15)
var research_grid: Vector2i = Vector2i(21, 4)
var unlocked_hires: int = 0
var _employee_spawns: Dictionary[String, Vector2i] = {}
var _desk_grids: Dictionary[String, Vector2i] = {}
var _employee_names: Dictionary[String, String] = {}
var _plants: Array[Vector2i] = []
var _prop_placements: Array[OfficePropPlacement] = []
var _prop_root: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_prop_root = Node2D.new()
	_prop_root.name = "Props"
	add_child(_prop_root)

func load_layout(path: String = "res://data/town.json") -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not read town layout: %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Town layout is not a JSON object")
		return
	var data := parsed as Dictionary
	tile_size = int(data.get("tile_size", 32))
	grid_width = int(data.get("width", 26))
	grid_height = int(data.get("height", 18))
	player_spawn = _vector_from_json(data.get("player_spawn"), Vector2i(13, 15))
	research_grid = _vector_from_json(data.get("research_table"), Vector2i(18, 4))
	_employee_spawns.clear()
	_employee_names.clear()
	var employees_value: Variant = data.get("employees", [])
	if employees_value is Array:
		for employee_value: Variant in employees_value as Array:
			if employee_value is Dictionary:
				var employee := employee_value as Dictionary
				var employee_id := str(employee.get("id", ""))
				_employee_spawns[employee_id] = _vector_from_json(employee.get("spawn"), Vector2i.ZERO)
				_employee_names[employee_id] = str(employee.get("name", employee_id))
	_desk_grids.clear()
	var desks_value: Variant = data.get("desks", [])
	if desks_value is Array:
		for desk_value: Variant in desks_value as Array:
			if desk_value is Dictionary:
				var desk := desk_value as Dictionary
				_desk_grids[str(desk.get("employee_id", ""))] = _vector_from_json(desk.get("grid"), Vector2i.ZERO)
	_prop_placements.clear()
	var props_value: Variant = data.get("props", [])
	if props_value is Array:
		for prop_value: Variant in props_value as Array:
			if prop_value is Dictionary:
				var placement := OfficePropPlacement.from_json(prop_value as Dictionary)
				if not placement.id.is_empty() and not placement.kind.is_empty():
					_prop_placements.append(placement)
	_plants.clear()
	var plants_value: Variant = data.get("plants", [])
	if plants_value is Array:
		for plant_value: Variant in plants_value as Array:
			_plants.append(_vector_from_json(plant_value, Vector2i.ZERO))
	set_hire_count(_employee_spawns.size())
	queue_redraw()

func _vector_from_json(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Array:
		var values := value as Array
		if values.size() >= 2:
			return Vector2i(int(values[0]), int(values[1]))
	return fallback

func configure_employee_desks(records: Array[EmployeeRecord]) -> void:
	for record: EmployeeRecord in records:
		_desk_grids[record.id] = record.desk_grid
		_employee_names[record.id] = record.display_name
	set_hire_count(records.size())

func set_hire_count(count: int) -> void:
	unlocked_hires = maxi(0, count)
	_rebuild_props()
	queue_redraw()

func _rebuild_props() -> void:
	if _prop_root == null:
		return
	for child: Node in _prop_root.get_children():
		_prop_root.remove_child(child)
		child.queue_free()
	for placement: OfficePropPlacement in _prop_placements:
		if unlocked_hires < placement.required_hires:
			continue
		var prop: Node2D
		match placement.kind:
			"desk":
				var desk := DESK_SCENE.instantiate() as OfficeDesk
				desk.configure(_employee_names.get(placement.owner_id, placement.owner_id))
				prop = desk
			"research_table":
				prop = RESEARCH_TABLE_SCENE.instantiate() as ResearchTable
			"collaboration_cluster":
				prop = COLLABORATION_CLUSTER_SCENE.instantiate() as StaticOfficeProp
			"coffee_station":
				prop = COFFEE_STATION_SCENE.instantiate() as StaticOfficeProp
			"approval_console":
				prop = APPROVAL_CONSOLE_SCENE.instantiate() as StaticOfficeProp
			"artifact_archive":
				prop = ARTIFACT_ARCHIVE_SCENE.instantiate() as StaticOfficeProp
			"prototype_bench":
				prop = PROTOTYPE_BENCH_SCENE.instantiate() as StaticOfficeProp
			_:
				push_warning("Unknown office prop kind: %s" % placement.kind)
				continue
		prop.name = placement.id
		prop.position = grid_to_local_position(placement.grid)
		prop.z_as_relative = false
		prop.z_index = int(position.y + prop.position.y)
		_prop_root.add_child(prop)

func visible_prop_count() -> int:
	return _prop_root.get_child_count() if _prop_root != null else 0

func prop_node(prop_id: String) -> Node2D:
	return _prop_root.get_node_or_null(NodePath(prop_id)) as Node2D if _prop_root != null else null

func placeholder_records() -> Array[EmployeeRecord]:
	var records: Array[EmployeeRecord] = []
	for employee_id: String in _employee_spawns:
		var record := EmployeeRecord.new()
		record.id = employee_id
		record.display_name = _employee_names.get(employee_id, employee_id)
		record.desk_grid = _desk_grids.get(employee_id, Vector2i.ZERO)
		record.morale = 75
		records.append(record)
	records.sort_custom(func(left: EmployeeRecord, right: EmployeeRecord) -> bool: return left.id < right.id)
	return records

func grid_to_local_position(grid: Vector2i) -> Vector2:
	return Vector2(float(grid.x * tile_size + tile_size / 2), float(grid.y * tile_size + tile_size / 2))

func grid_to_world_position(grid: Vector2i) -> Vector2:
	return position + grid_to_local_position(grid)

func employee_spawn_position(employee_id: String) -> Vector2:
	return grid_to_world_position(_employee_spawns.get(employee_id, Vector2i(5, 14)))

func employee_desk_position(employee_id: String) -> Vector2:
	# The work point is behind the desk anchor so Y sorting places the employee's
	# lower body behind the workstation while keeping their head visible.
	return grid_to_world_position(_desk_grids.get(employee_id, Vector2i.ZERO)) + Vector2(0.0, -26.0)

func research_position() -> Vector2:
	return grid_to_world_position(research_grid) + Vector2(0.0, 40.0)

func playable_bounds() -> Rect2:
	return Rect2(position, Vector2(float(grid_width * tile_size), float(grid_height * tile_size)))

func _draw() -> void:
	var size := Vector2(float(grid_width * tile_size), float(grid_height * tile_size))
	draw_texture_rect(OFFICE_SHELL_TEXTURE, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color("9bb3a0"), false, 3.0)
