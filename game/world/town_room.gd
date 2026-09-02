class_name TownRoom
extends Node2D

const DESK_SCENE: PackedScene = preload("res://props/desk.tscn")
const RESEARCH_TABLE_SCENE: PackedScene = preload("res://props/research_table.tscn")

var tile_size: int = 32
var grid_width: int = 26
var grid_height: int = 18
var player_spawn: Vector2i = Vector2i(4, 9)
var research_grid: Vector2i = Vector2i(18, 4)
var _employee_spawns: Dictionary[String, Vector2i] = {}
var _desk_grids: Dictionary[String, Vector2i] = {}
var _employee_names: Dictionary[String, String] = {}
var _plants: Array[Vector2i] = []

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
	player_spawn = _vector_from_json(data.get("player_spawn"), Vector2i(4, 9))
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
	_plants.clear()
	var plants_value: Variant = data.get("plants", [])
	if plants_value is Array:
		for plant_value: Variant in plants_value as Array:
			_plants.append(_vector_from_json(plant_value, Vector2i.ZERO))
	_rebuild_desks()
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
	_rebuild_desks()

func _rebuild_desks() -> void:
	for child: Node in get_children():
		if child is OfficeDesk or child is ResearchTable:
			child.queue_free()
	for employee_id: String in _desk_grids:
		var desk := DESK_SCENE.instantiate() as OfficeDesk
		desk.position = grid_to_local_position(_desk_grids[employee_id])
		desk.configure(_employee_names.get(employee_id, employee_id))
		add_child(desk)
	var research_table := RESEARCH_TABLE_SCENE.instantiate() as ResearchTable
	research_table.position = grid_to_local_position(research_grid)
	add_child(research_table)

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
	return grid_to_world_position(_desk_grids.get(employee_id, Vector2i.ZERO)) + Vector2(0.0, 42.0)

func research_position() -> Vector2:
	return grid_to_world_position(research_grid) + Vector2(0.0, 40.0)

func playable_bounds() -> Rect2:
	return Rect2(position, Vector2(float(grid_width * tile_size), float(grid_height * tile_size)))

func _draw() -> void:
	var size := Vector2(float(grid_width * tile_size), float(grid_height * tile_size))
	draw_rect(Rect2(Vector2.ZERO, size), Color("253148"), true)
	for y in range(grid_height):
		for x in range(grid_width):
			var tile_color := Color("34445f") if (x + y) % 2 == 0 else Color("314059")
			draw_rect(Rect2(float(x * tile_size), float(y * tile_size), float(tile_size), float(tile_size)), tile_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), Color("8da0be"), false, 4.0)
	draw_rect(Rect2(2.0, 2.0, size.x - 4.0, 18.0), Color("172238"), true)
	for plant_grid: Vector2i in _plants:
		var plant := grid_to_local_position(plant_grid)
		draw_rect(Rect2(plant + Vector2(-8.0, 4.0), Vector2(16.0, 15.0)), Color("8e6042"), true)
		draw_circle(plant + Vector2(-5.0, -2.0), 8.0, Color("5ca36c"))
		draw_circle(plant + Vector2(5.0, -5.0), 8.0, Color("70bd7e"))
