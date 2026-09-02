class_name TownRoom
extends Node2D

const OFFICE_BACKGROUND_TEXTURE: Texture2D = preload("res://assets/runtime/office/main-office-background.png")
const LOCKED_FILL := Color("172230f2")
const LOCKED_INSET := Color("223042ed")
const LOCKED_STRIPE := Color("405a6066")
const LOCKED_BORDER := Color("d9b15c")

var tile_size: int = 32
var grid_width: int = 26
var grid_height: int = 18
var player_spawn: Vector2i = Vector2i(13, 15)
var research_grid: Vector2i = Vector2i(18, 4)
var unlocked_hires: int = 0
var _employee_spawns: Dictionary[String, Vector2i] = {}
var _desk_grids: Dictionary[String, Vector2i] = {}
var _employee_names: Dictionary[String, String] = {}
var _plants: Array[Vector2i] = []
var _locked_collision_root: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_locked_collision_root = Node2D.new()
	_locked_collision_root.name = "LockedSections"
	add_child(_locked_collision_root)

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
	_plants.clear()
	var plants_value: Variant = data.get("plants", [])
	if plants_value is Array:
		for plant_value: Variant in plants_value as Array:
			_plants.append(_vector_from_json(plant_value, Vector2i.ZERO))
	set_hire_count(_employee_spawns.size())
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
	set_hire_count(records.size())
	_rebuild_desks()

func _rebuild_desks() -> void:
	# The runtime background owns the furniture. Logical desk coordinates remain
	# authoritative for worker movement and can change independently of the art.
	queue_redraw()

func set_hire_count(count: int) -> void:
	unlocked_hires = maxi(0, count)
	_rebuild_locked_collisions()
	queue_redraw()

func locked_section_count() -> int:
	var count := 0
	for section: Dictionary in _section_definitions():
		if unlocked_hires < int(section.get("minimum_hires", 0)):
			count += 1
	return count

func _section_definitions() -> Array[Dictionary]:
	return [
		{
			"minimum_hires": 1,
			"grid_rect": Rect2(0.0, 0.0, 6.5, 15.0),
			"label": "MEETING + COFFEE",
		},
		{
			"minimum_hires": 2,
			"grid_rect": Rect2(18.0, 0.0, 8.0, 6.2),
			"label": "RESEARCH LAB",
		},
		{
			"minimum_hires": 3,
			"grid_rect": Rect2(18.0, 6.2, 8.0, 5.0),
			"label": "OPS + APPROVALS",
		},
		{
			"minimum_hires": 4,
			"grid_rect": Rect2(18.0, 11.2, 8.0, 6.8),
			"label": "ARTIFACT STUDIO",
		},
	]

func _section_rect(section: Dictionary) -> Rect2:
	var grid_rect: Rect2 = section.get("grid_rect", Rect2())
	return Rect2(grid_rect.position * float(tile_size), grid_rect.size * float(tile_size))

func _rebuild_locked_collisions() -> void:
	if _locked_collision_root == null:
		return
	for child: Node in _locked_collision_root.get_children():
		child.queue_free()
	for section: Dictionary in _section_definitions():
		if unlocked_hires >= int(section.get("minimum_hires", 0)):
			continue
		var area := _section_rect(section)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = area.size
		collision.position = area.position + area.size * 0.5
		collision.shape = shape
		body.add_child(collision)
		_locked_collision_root.add_child(body)

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
	draw_texture_rect(OFFICE_BACKGROUND_TEXTURE, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color("9bb3a0"), false, 3.0)
	for section: Dictionary in _section_definitions():
		if unlocked_hires < int(section.get("minimum_hires", 0)):
			_draw_locked_section(section)

func _draw_locked_section(section: Dictionary) -> void:
	var area := _section_rect(section)
	draw_rect(area, LOCKED_FILL, true)
	var inset := area.grow(-7.0)
	draw_rect(inset, LOCKED_INSET, true)
	var stripe_y := inset.position.y
	while stripe_y < inset.end.y:
		draw_rect(Rect2(inset.position.x, stripe_y, inset.size.x, 7.0), LOCKED_STRIPE, true)
		stripe_y += 24.0
	draw_rect(area, LOCKED_BORDER, false, 3.0)
	var label := str(section.get("label", "NEW WING"))
	var label_y := area.position.y + area.size.y * 0.5
	draw_string(
		ThemeDB.fallback_font,
		Vector2(area.position.x + 12.0, label_y - 8.0),
		"RENOVATION",
		HORIZONTAL_ALIGNMENT_CENTER,
		area.size.x - 24.0,
		15,
		Color("f2d89b")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(area.position.x + 12.0, label_y + 14.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		area.size.x - 24.0,
		12,
		Color("dce7df")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(area.position.x + 12.0, label_y + 34.0),
		"UNLOCKS WITH A NEW HIRE",
		HORIZONTAL_ALIGNMENT_CENTER,
		area.size.x - 24.0,
		9,
		Color("9eb3aa")
	)
