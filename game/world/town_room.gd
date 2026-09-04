class_name TownRoom
extends Node2D

signal placements_changed

const PROP_SCENES: Dictionary = {
	"desk": preload("res://props/desk.tscn"),
	"research_table": preload("res://props/research_table.tscn"),
	"collaboration_cluster": preload("res://props/collaboration_cluster.tscn"),
	"coffee_station": preload("res://props/coffee_station.tscn"),
	"approval_console": preload("res://props/approval_console.tscn"),
	"artifact_archive": preload("res://props/artifact_archive.tscn"),
	"prototype_bench": preload("res://props/prototype_bench.tscn"),
}

var layout_model: OfficeLayout
var resolved_placements: Array[Dictionary] = []
var placement_overrides: Dictionary = {}
var migration_notes: Array[String] = []
var tile_size: int = 32
var grid_width: int = 40
var grid_height: int = 23
var player_spawn := Vector2i(17, 19)
var unlocked_hires: int = 0
var navigation: OfficeNavigation
var architecture: OfficeArchitecture
var _employee_names: Dictionary[String, String] = {}
var _prop_root: Node2D
var _effect_root: Node2D
var _last_built_hires: int = -1

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	architecture = OfficeArchitecture.new()
	architecture.name = "Architecture"
	add_child(architecture)
	_prop_root = Node2D.new()
	_prop_root.name = "Props"
	add_child(_prop_root)
	_effect_root = Node2D.new()
	_effect_root.name = "UnlockEffects"
	add_child(_effect_root)

func load_layout(path: String = "res://data/office_layout.json") -> bool:
	# Loading a developer export is transactional too: no partial room, collision,
	# or visual mutation when the replacement definition is invalid.
	var next_model := OfficeLayout.new()
	if not next_model.load_files(path): return false
	for stage: int in range(5):
		if not bool(next_model.validate_placements(next_model.resolve_placements(stage)).valid): return false
	layout_model = next_model
	placement_overrides.clear()
	migration_notes.clear()
	tile_size = layout_model.tile_size
	grid_width = layout_model.width
	grid_height = layout_model.height
	player_spawn = _vector(layout_model.data.get("player_spawn", [17, 19]))
	_employee_names.clear()
	for employee: Dictionary in layout_model.data.get("employees", []):
		_employee_names[str(employee.id)] = str(employee.name)
	if navigation == null:
		navigation = OfficeNavigation.new()
		navigation.name = "OfficeNavigation"
		get_parent().add_child(navigation)
	navigation.configure(layout_model.navigation_data(), global_position)
	architecture.configure(layout_model)
	set_hire_count(_employee_names.size())
	return true

func _vector(value: Variant) -> Vector2i:
	if value is Vector2i: return value
	if value is Array and value.size() >= 2: return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO

func _validate_all(overrides: Dictionary) -> bool:
	for stage: int in range(5):
		var result := layout_model.validate_placements(layout_model.resolve_placements(stage, overrides))
		if not bool(result.valid): return false
	return true

func set_placement_overrides(overrides: Dictionary) -> bool:
	if not _validate_all(overrides): return false
	placement_overrides = overrides.duplicate(true)
	_rebuild_props()
	return true

func configure_employee_desks(records: Array[EmployeeRecord]) -> void:
	# Worker-owned legacy coordinates are suggestions, never unchecked geometry.
	var proposed := placement_overrides.duplicate(true)
	migration_notes.clear()
	var batch := proposed.duplicate(true)
	for record: EmployeeRecord in records:
		_employee_names[record.id] = record.display_name
		var station_id := "%s-workstation" % record.id
		if not layout_model.placement_by_id(station_id, 4).is_empty():
			batch[station_id] = {"grid": [record.desk_grid.x, record.desk_grid.y], "facing": "south"}
	# Validate a joint move first; two owners can safely exchange desks even if
	# either move in isolation would collide with the other's previous station.
	if _validate_all(batch):
		placement_overrides = batch
		set_hire_count(records.size())
		return
	for record: EmployeeRecord in records:
		_employee_names[record.id] = record.display_name
		var station_id := "%s-workstation" % record.id
		if layout_model.placement_by_id(station_id, 4).is_empty(): continue
		var candidate := proposed.duplicate(true)
		candidate[station_id] = {"grid": [record.desk_grid.x, record.desk_grid.y], "facing": "south"}
		if _validate_all(candidate):
			proposed = candidate
		else:
			migration_notes.append("%s: legacy desk %s is invalid; using the validated station." % [record.id, record.desk_grid])
	placement_overrides = proposed
	set_hire_count(records.size())

func set_hire_count(count: int) -> void:
	var previous := unlocked_hires
	unlocked_hires = maxi(0, count)
	var animate_from := previous if _last_built_hires >= 0 and unlocked_hires > previous else -1
	_rebuild_props(animate_from)
	_last_built_hires = unlocked_hires

func _rebuild_props(animate_from: int = -1) -> void:
	if _prop_root == null or layout_model == null: return
	var next := layout_model.resolve_placements(unlocked_hires, placement_overrides)
	var validation := layout_model.validate_placements(next)
	if not bool(validation.valid):
		push_error("Rejected office layout: %s" % str(validation.errors))
		return
	resolved_placements = next
	for child: Node in _prop_root.get_children():
		_prop_root.remove_child(child)
		child.queue_free()
	for placement: Dictionary in resolved_placements:
		var scene := PROP_SCENES.get(str(placement.kind)) as PackedScene
		if scene == null: continue
		var prop := scene.instantiate() as Node2D
		if prop is OfficeDesk: (prop as OfficeDesk).configure(_employee_names.get(str(placement.owner_id), str(placement.owner_id)))
		prop.name = str(placement.id)
		prop.position = layout_model.world(placement.grid) + Vector2(placement.get("anchor_offset", Vector2.ZERO))
		prop.z_as_relative = false
		prop.z_index = roundi(global_position.y + prop.position.y)
		prop.set_meta("resolved_placement", placement)
		prop.set_meta("catalog_collision", true)
		_prop_root.add_child(prop)
		_apply_profile(prop, placement)
		if animate_from >= 0 and int(placement.required_hires) > animate_from:
			var effect := OfficeUnlockEffect.new()
			effect.position = prop.position + Vector2(0, -18)
			effect.z_as_relative = false
			effect.z_index = prop.z_index + 4
			_effect_root.add_child(effect)
	if navigation != null: navigation.rebuild_placements(resolved_placements)
	placements_changed.emit()

func _apply_profile(prop: Node2D, placement: Dictionary) -> void:
	var profile: Dictionary = placement.profile
	var layers: Dictionary = profile.get("layers", {})
	var texture := load(str(profile.art)) as Texture2D
	for child: Node in prop.get_children():
		if child is Sprite2D and not child is OfficeAmbientOverlay:
			var sprite := child as Sprite2D
			sprite.texture = texture
			sprite.position = Vector2(_vector(profile.get("sprite_offset", [0, 0])))
			sprite.scale = Vector2.ONE
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.region_enabled = profile.has("atlas_cell")
			if sprite.region_enabled:
				var cell := Vector2(_vector(profile.atlas_cell))
				var column := 1 if str(child.name).ends_with("Front") else 0
				sprite.region_rect = Rect2(Vector2(column, int(profile.get("atlas_row", 0))) * cell, cell)
			if str(child.name).ends_with("Rear"): child.z_index = prop.z_index + int(layers.get("rear_z_offset", -40))
			elif str(child.name).ends_with("Front"): child.z_index = prop.z_index + int(layers.get("front_z_offset", 1))
			else: child.z_index = int(layers.get("body_z_offset", 0))
	var body := StaticBody2D.new()
	body.name = "PlacementCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	for cell: Vector2i in placement.occupied:
		var shape := RectangleShape2D.new()
		shape.size = Vector2.ONE * tile_size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = layout_model.world(cell) - prop.position
		body.add_child(collision)
	prop.add_child(body)

func visible_prop_count() -> int:
	return _prop_root.get_child_count() if _prop_root != null else 0

func prop_node(prop_id: String) -> Node2D:
	return _prop_root.get_node_or_null(NodePath(prop_id)) as Node2D if _prop_root != null else null

func placement_by_id(prop_id: String) -> Dictionary:
	for placement: Dictionary in resolved_placements:
		if str(placement.id) == prop_id: return placement
	return {}

func interaction_world_position(prop_id: String) -> Vector2:
	var placement := placement_by_id(prop_id)
	return grid_to_world_position(placement.interaction) if not placement.is_empty() else grid_to_world_position(player_spawn)

func interaction_at(point: Vector2) -> Dictionary:
	# Hit-test in reverse render-depth order.
	var sorted := resolved_placements.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.grid.y > b.grid.y)
	for placement: Dictionary in sorted:
		if str(placement.kind) not in ["desk", "artifact_archive", "approval_console"]: continue
		var bounds: Rect2 = placement.world_visual_bounds
		bounds.position += global_position
		if bounds.has_point(point):
			return {"id": str(placement.id), "kind": "prop", "point": interaction_world_position(str(placement.id))}
	return {}

func placeholder_records() -> Array[EmployeeRecord]:
	var records: Array[EmployeeRecord] = []
	for employee_id: String in _employee_names:
		var record := EmployeeRecord.new()
		record.id = employee_id
		record.display_name = _employee_names[employee_id]
		var placement := layout_model.placement_by_id("%s-workstation" % employee_id, 4)
		record.desk_grid = placement.get("grid", Vector2i.ZERO)
		record.morale = 75
		records.append(record)
	records.sort_custom(func(a: EmployeeRecord, b: EmployeeRecord) -> bool: return a.id < b.id)
	return records

func grid_to_local_position(grid: Vector2i) -> Vector2:
	return layout_model.world(grid)

func grid_to_world_position(grid: Vector2i) -> Vector2:
	return global_position + grid_to_local_position(grid)

func employee_spawn_position(employee_id: String) -> Vector2:
	return grid_to_world_position(layout_model.employee_spawn(employee_id))

func employee_desk_position(employee_id: String) -> Vector2:
	var placement := placement_by_id("%s-workstation" % employee_id)
	return grid_to_world_position(placement.get("work_cell", placement.get("interaction", player_spawn)))

func research_position() -> Vector2:
	return interaction_world_position("research-bench")

func lunch_position() -> Vector2:
	return interaction_world_position("collaboration-cluster")

func playable_bounds() -> Rect2:
	return Rect2(global_position, Vector2(grid_width * tile_size, mini(grid_height * tile_size, 720)))
