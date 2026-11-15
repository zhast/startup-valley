class_name TownRoom
extends Node2D

signal placements_changed

const LAYOUT_PATHS: Dictionary = {
	"startup-office": "res://data/office_layout.json",
	"starter-cottage-v1": "res://data/office_layout_starter.json",
}

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
var unlocked_office_level: int = 1
var navigation: OfficeNavigation
var architecture: OfficeArchitecture
var daylight: OfficeDaylight
var _employee_names: Dictionary[String, String] = {}
var _prop_root: Node2D
var _effect_root: Node2D
var _last_built_hires: int = -1
var furnishing_revision: int = -1

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	architecture = OfficeArchitecture.new()
	architecture.name = "Architecture"
	add_child(architecture)
	daylight = OfficeDaylight.new()
	daylight.name = "WindowDaylight"
	add_child(daylight)
	# Repainting a new room theme also recolours the window light. There is no
	# animated pulse or process loop, and it never sits over a prop or person.
	architecture.draw.connect(daylight.queue_redraw)
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
	placement_overrides.clear()
	furnishing_revision = -1
	migration_notes.clear()
	_adopt_layout(next_model)
	set_hire_count(_employee_names.size())
	return true

func _adopt_layout(next_model: OfficeLayout) -> void:
	layout_model = next_model
	layout_model.office_level = maxi(1, unlocked_office_level)
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
	var previous_theme := architecture.theme_id
	architecture.configure(layout_model)
	if previous_theme != architecture.theme_id: architecture.apply_theme(previous_theme)
	daylight.configure(layout_model, architecture)

func _vector(value: Variant) -> Vector2i:
	if value is Vector2i: return value
	if value is Array and value.size() >= 2: return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO

func _validate_all(overrides: Dictionary, model: OfficeLayout = null) -> bool:
	if model == null: model = layout_model
	if model.furnishing_bound:
		for key: Variant in overrides:
			if not model.furnishing_inventory.has(str(key)): return false
			var value: Variant = overrides[key]
			if not value is Dictionary or not OfficeLayout._integer_pair(value.get("grid")) or not OfficeLayout.FACINGS.has(str(value.get("facing", ""))): return false
			for field: Variant in value:
				if str(field) not in ["grid", "facing"]: return false
		for id: String in model.furnishing_inventory:
			if bool(model.furnishing_inventory[id].get("essential", false)) and not overrides.has(id): return false
	for stage: int in range(5):
		var result := model.validate_placements(model.resolve_placements(stage, overrides, true))
		if not bool(result.valid): return false
	return true

func apply_furnishing_state(state: Dictionary) -> bool:
	# Commit the projection only after the entire worker snapshot validates. A
	# failed snapshot leaves the room, inventory, collision and revision intact.
	if layout_model == null or int(state.get("version", -1)) != 1 or not state.get("inventory") is Array or not state.get("placements") is Dictionary: return false
	# Only shipped layout identities are admitted, never arbitrary file paths.
	# Old projections without an identity retain the original office.
	var layout_id := str(state.get("layoutId", "startup-office"))
	if not LAYOUT_PATHS.has(layout_id): return false
	var switching := str(layout_model.data.get("id", "")) != layout_id
	var next_model := OfficeLayout.new() if switching else layout_model
	if switching and not next_model.load_files(str(LAYOUT_PATHS[layout_id])): return false
	next_model.office_level = maxi(1, unlocked_office_level)
	var next_inventory: Dictionary = {}
	for value: Variant in state.inventory:
		if not value is Dictionary or str(value.get("id", "")).is_empty() or not next_model.catalog.has(str(value.get("kind", ""))): return false
		var id := str(value.id)
		if next_inventory.has(id): return false
		next_inventory[id] = value.duplicate(true)
	var previous_inventory := next_model.furnishing_inventory
	var previously_bound := next_model.furnishing_bound
	next_model.furnishing_inventory = next_inventory
	next_model.furnishing_bound = true
	if not _validate_all(state.placements, next_model):
		next_model.furnishing_inventory = previous_inventory
		next_model.furnishing_bound = previously_bound
		return false
	if switching: _adopt_layout(next_model)
	placement_overrides = state.placements.duplicate(true)
	furnishing_revision = int(state.get("revision", 0))
	_rebuild_props()
	return true

func set_placement_overrides(overrides: Dictionary) -> bool:
	if not _validate_all(overrides): return false
	placement_overrides = overrides.duplicate(true)
	_rebuild_props()
	return true

func placement_actor_conflicts(overrides: Dictionary) -> Array[Dictionary]:
	# Read-only editor admission, deliberately not a bootstrap/migration guard.
	# Reservations describe future destinations, not bodies: only live feet and
	# the same10px footprint samples used by OfficeNavigation can block a commit.
	var conflicts: Array[Dictionary] = []
	if navigation == null or layout_model == null: return conflicts
	var current := layout_model.occupied_cells(resolved_placements)
	var next_placements := layout_model.resolve_placements(unlocked_hires, overrides)
	var proposed := layout_model.occupied_cells(next_placements)
	for actor_id: String in navigation.actors:
		var feet: Vector2 = navigation.actors[actor_id]
		var occupied_seat := ""
		for placement: Dictionary in resolved_placements:
			var moved := true
			for next: Dictionary in next_placements:
				if next.id == placement.id:
					moved = next.grid != placement.grid or next.facing != placement.facing
					break
			if not moved: continue
			if layout_model.furnishing_bound and (placement.get("occupied", []).has(navigation.cell_at(feet)) or placement.get("clearance", []).has(navigation.cell_at(feet))):
				occupied_seat = str(placement.id)
				break
			if placement.has("work_position") and feet.distance_to(global_position + Vector2(placement.work_position)) <= 10.0:
				occupied_seat = str(placement.id)
				break
			if str(placement.get("profile_kind", "")) != "collaboration": continue
			for slot: Dictionary in placement.get("collaboration_slots", []):
				if feet.distance_to(global_position + Vector2(slot.position)) <= 10.0:
					occupied_seat = str(placement.id)
					break
			if not occupied_seat.is_empty(): break
		if not occupied_seat.is_empty():
			conflicts.append({"actor_id": actor_id, "display_name": "Founder" if actor_id == "founder" else _employee_names.get(actor_id, actor_id.capitalize()), "position": feet, "cell": navigation.cell_at(feet), "placement_id": occupied_seat, "reason": "occupied_seat"})
			continue
		for offset: Vector2 in [Vector2.ZERO, Vector2(-10, -10), Vector2(10, -10), Vector2(-10, 10), Vector2(10, 10)]:
			var cell := navigation.cell_at(feet + offset)
			if proposed.has(cell) and not current.has(cell):
				conflicts.append({"actor_id": actor_id, "display_name": "Founder" if actor_id == "founder" else _employee_names.get(actor_id, actor_id.capitalize()), "position": feet, "cell": cell, "placement_id": str(proposed[cell])})
				break
	return conflicts

func configure_employee_desks(records: Array[EmployeeRecord]) -> void:
	if layout_model.furnishing_bound:
		for record: EmployeeRecord in records: _employee_names[record.id] = record.display_name
		set_hire_count(records.size())
		return
	# Worker-owned legacy coordinates are suggestions, never unchecked geometry.
	var proposed := placement_overrides.duplicate(true)
	migration_notes.clear()
	var batch := proposed.duplicate(true)
	for record: EmployeeRecord in records:
		_employee_names[record.id] = record.display_name
		var station_id := "%s-workstation" % record.id
		if not layout_model.placement_by_id(station_id, 4).is_empty():
			batch[station_id] = {"grid": [record.desk_grid.x, record.desk_grid.y], "facing": _station_facing(station_id, proposed)}
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
		candidate[station_id] = {"grid": [record.desk_grid.x, record.desk_grid.y], "facing": _station_facing(station_id, proposed)}
		if _validate_all(candidate):
			proposed = candidate
		else:
			migration_notes.append("%s: legacy desk %s is invalid; using the validated station." % [record.id, record.desk_grid])
	placement_overrides = proposed
	set_hire_count(records.size())

func _station_facing(station_id: String, overrides: Dictionary) -> String:
	# Old worker records own coordinates, not orientation. Preserve a validated
	# local/exported facing instead of resetting every bootstrap to south.
	return str(layout_model.placement_by_id(station_id, 4, overrides).get("facing", "south"))

func set_office_level(level: int) -> void:
	var next := maxi(1, level)
	unlocked_office_level = next
	if layout_model == null or layout_model.office_level == next:
		return
	layout_model.office_level = next
	_rebuild_props()

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
		var decorative := str(placement.get("profile_kind", "")) == "decorative" and bool(placement.profile.get("direction_explicit", false)) and (placement.get("direction_errors", []) as Array).is_empty()
		if scene == null and not decorative: continue
		# Only a fully validated explicit passive profile gets this neutral layer
		# carrier. Unknown legacy kinds never acquire a fallback scene or action.
		var prop := scene.instantiate() as Node2D if scene != null else Node2D.new()
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
	var existing: Dictionary[String, Sprite2D] = {}
	for child: Node in prop.get_children():
		if child is Sprite2D and not child is OfficeAmbientOverlay:
			existing[str(child.name)] = child as Sprite2D
	for layer: Dictionary in placement.get("render_layers", []):
		var layer_name := str(layer.name)
		var sprite: Sprite2D = existing.get(layer_name)
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = layer_name
			prop.add_child(sprite)
		existing.erase(layer_name)
		sprite.texture = load(str(layer.art)) as Texture2D
		sprite.position = Vector2(OfficeLayout.vector(layer.offset))
		sprite.scale = Vector2.ONE
		sprite.rotation = 0.0
		sprite.flip_h = false
		sprite.flip_v = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.region_enabled = true
		sprite.region_rect = OfficeLayout.rectangle(layer.region)
		sprite.z_as_relative = false
		sprite.z_index = prop.z_index + int(layer.z_offset)
	for sprite: Sprite2D in existing.values():
		prop.remove_child(sprite)
		sprite.queue_free()
	# Legacy scene attachments stay exactly as authored. An explicit direction
	# must opt into its own attachments; never leave south's scan/glow floating.
	if bool(profile.get("direction_explicit", false)):
		for child: Node in prop.get_children():
			if child is OfficeAmbientOverlay:
				prop.remove_child(child)
				child.queue_free()
		for attachment: Dictionary in profile.get("ambient_overlays", []):
			var overlay := OfficeAmbientOverlay.new()
			overlay.configure(int(attachment.row), Vector2(OfficeLayout.vector(attachment.offset)))
			overlay.z_as_relative = false
			overlay.z_index = prop.z_index + int(attachment.z_offset)
			prop.add_child(overlay)
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
	# Passive native-layer furniture has no target; never fabricate its pivot
	# or the founder spawn as a usable socket. Existing missing-id fallback stays.
	if str(placement.get("profile_kind", "")) == "decorative": return Vector2(INF, INF)
	return grid_to_world_position(placement.interaction) if not placement.is_empty() else grid_to_world_position(player_spawn)

func interaction_approach_direction(prop_id: String) -> Vector2:
	var placement := placement_by_id(prop_id)
	if str(placement.get("profile_kind", "")) != "service": return Vector2.ZERO
	match str(placement.get("approach_gaze", "")):
		"north": return Vector2.UP
		"east": return Vector2.RIGHT
		"south": return Vector2.DOWN
		"west": return Vector2.LEFT
	return Vector2.ZERO

func interaction_at(point: Vector2) -> Dictionary:
	return surface_at(point).get("interaction", {})

func surface_at(point: Vector2) -> Dictionary:
	var result := {}
	var top_sprite: Sprite2D
	for placement: Dictionary in resolved_placements:
		var prop := prop_node(str(placement.id))
		if prop == null: continue
		# Include decorative furniture as an occluder, but never invent an action
		# for it. Explicit registered layers exclude ambient animation and VFX.
		for layer: Dictionary in placement.render_layers:
			var sprite := prop.get_node_or_null(NodePath(str(layer.name))) as Sprite2D
			if not VisibleSurface.painted(sprite, point) or not VisibleSurface.in_front(sprite, top_sprite): continue
			top_sprite = sprite
			var interaction := {}
			var bounds: Rect2 = placement.world_hit_bounds
			bounds.position += global_position
			if str(placement.get("profile_kind", "")) != "decorative" and bool(placement.profile.get("interaction_enabled", true)) and str(placement.kind) in ["desk", "artifact_archive", "approval_console"] and bounds.has_point(point):
				interaction = {"id": str(placement.id), "kind": "prop", "point": interaction_world_position(str(placement.id))}
			result = {"sprite": sprite, "interaction": interaction}
	return result

func placeholder_records() -> Array[EmployeeRecord]:
	var records: Array[EmployeeRecord] = []
	if layout_model == null: return records
	# Layout order keeps Mina first. Alphabetical order would select Creative.
	for employee: Dictionary in layout_model.data.get("employees", []):
		var employee_id := str(employee.get("id", ""))
		if employee_id.is_empty() or not _employee_names.has(employee_id): continue
		var record := EmployeeRecord.new()
		record.id = employee_id
		record.display_name = _employee_names[employee_id]
		var placement := layout_model.placement_by_id("%s-workstation" % employee_id, 4)
		record.desk_grid = placement.get("grid", Vector2i.ZERO)
		record.morale = 75
		records.append(record)
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

func employee_workstation(employee_id: String) -> Dictionary:
	# UI/actor integration can obtain the exact reviewed pose/anchor/depth data
	# without re-reading a second catalog or inferring facing from a walked path.
	return placement_by_id("%s-workstation" % employee_id).duplicate(true)

func employee_workstation_visual(employee_id: String) -> Dictionary:
	return _workstation_visual("%s-workstation" % employee_id)

func research_visual() -> Dictionary:
	return _workstation_visual("research-bench")

func _workstation_visual(prop_id: String) -> Dictionary:
	var placement := placement_by_id(prop_id)
	if placement.is_empty() or str(placement.get("profile_kind", "")) in ["service", "collaboration", "decorative"]: return {}
	var result := {
		"work_facing": placement.work_facing, "seat_anchor": placement.seat_anchor,
		"seat_z_offset": placement.seat_z_offset, "pose_set": placement.pose_set,
		"prop_anchor": global_position + placement.anchor,
		"work_position": grid_to_world_position(placement.work_cell),
	}
	if placement.get("workstation_capability_revision") is String:
		result["workstation_capability_revision"] = str(placement.workstation_capability_revision)
	if placement.get("calibration_owner_id") is int:
		result["calibration_owner_id"] = int(placement.calibration_owner_id)
	if placement.has("seat_anchor_by_employee"):
		var owner_id := str(placement.get("owner_id", ""))
		if placement.seat_anchor_by_employee.has(owner_id):
			result.seat_anchor = Vector2(OfficeLayout.vector(placement.seat_anchor_by_employee[owner_id]))
	for field: String in ["seat_layer_z_offsets", "calibration_limitations"]:
		if placement.has(field): result[field] = placement[field].duplicate(true)
	if placement.get("seat_pose_depth_lock") is bool: result["seat_pose_depth_lock"] = placement.seat_pose_depth_lock
	if placement.get("seat_state_handoff") is Dictionary: result["seat_state_handoff"] = placement.seat_state_handoff.duplicate(true)
	if placement.get("grounded_work_shadow") is bool:
		result["grounded_work_shadow"] = placement.grounded_work_shadow
		if placement.grounded_work_shadow:
			var lowest := 4096
			for layer: Dictionary in placement.render_layers: lowest = mini(lowest, int(layer.z_offset))
			# Includes chair, apron and all front/rear layers. No artist-entered
			# shadow depth can accidentally paint a floor shadow over the top.
			result["ground_shadow_z_offset"] = lowest - 1
	if placement.get("grounded_work_shadow_follow_seat_x") is bool:
		result["grounded_work_shadow_follow_seat_x"] = placement.grounded_work_shadow_follow_seat_x
	return result

func research_position() -> Vector2:
	return interaction_world_position("research-bench")

func _collaboration_slot(employee_id: String) -> Dictionary:
	var placement := placement_by_id("collaboration-cluster")
	if placement.is_empty() or str(placement.get("profile_kind", "")) != "collaboration": return {}
	var slots: Array = placement.get("collaboration_slots", [])
	if slots.is_empty(): return {}
	if employee_id.is_empty(): return slots[0] as Dictionary
	var employee_ids: Array[String] = []
	for known_id: String in _employee_names: employee_ids.append(known_id)
	employee_ids.sort()
	var index := employee_ids.find(employee_id)
	if index < 0 or index >= slots.size(): return {}
	return slots[index] as Dictionary

func lunch_position(employee_id: String = "") -> Vector2:
	var slot := _collaboration_slot(employee_id)
	if not slot.is_empty(): return global_position + Vector2(slot.position)
	return interaction_world_position("collaboration-cluster")

func collaboration_visual(employee_id: String) -> Dictionary:
	var placement := placement_by_id("collaboration-cluster")
	var slot := _collaboration_slot(employee_id)
	if placement.is_empty() or slot.is_empty(): return {}
	var anchors: Variant = slot.get("seat_anchor_by_employee")
	if not anchors is Dictionary or not anchors.has(employee_id): return {}
	return {
		"work_facing": str(slot.get("work_facing", "")),
		"pose_set": str(placement.profile.get("collaboration_pose_set", "")),
		"collaboration_capability_revision": str(slot.get("capability_revision", "")),
		"seat_anchor": Vector2(OfficeLayout.vector(anchors[employee_id])),
		"seat_z_offset": int(slot.get("seat_z_offset", 0)),
		"seat_layer_z_offsets": slot.get("seat_layer_z_offsets", {}).duplicate(true),
		"ground_shadow_z_offset": int(slot.get("ground_shadow_z_offset", 0)),
		"prop_anchor": global_position + Vector2(placement.anchor),
		"seat_position": global_position + Vector2(slot.position),
	}

func playable_bounds() -> Rect2:
	return Rect2(global_position, Vector2(grid_width * tile_size, mini(grid_height * tile_size, 720)))
