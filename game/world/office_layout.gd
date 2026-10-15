class_name OfficeLayout
extends RefCounted
## Authoritative development-authored architecture and furniture geometry.
## Coordinates are floor cells; image overhang is not physical occupancy.

const DEFAULT_PATH := "res://data/office_layout.json"
const DEFAULT_CATALOG_PATH := "res://data/furniture_catalog.json"
const FURNISHING_CATALOG_PATH := "res://data/furnishing_catalog.json"
const NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const FACINGS: Array[String] = ["north", "east", "south", "west"]
# A new direction must explicitly author camera-space geometry. Never inherit a
# south footprint, layer origin or seat simply because a facing name was added.
const DIRECTION_FIELDS: Array[String] = ["occupied", "clearance", "interaction", "work_cell", "anchor_offset", "visual_bounds", "work_facing", "seat_anchor", "seat_z_offset", "render_layers", "ambient_overlays"]
const SERVICE_FIELDS: Array[String] = ["profile_kind", "service_side", "approach_gaze", "approach_visual_bounds", "occupied", "clearance", "interaction", "anchor_offset", "visual_bounds", "render_layers", "ambient_overlays"]
const COLLABORATION_FIELDS: Array[String] = ["profile_kind", "reference_gaze", "collaboration_pose_set", "collaboration_slots", "occupied", "clearance", "interaction", "anchor_offset", "visual_bounds", "render_layers", "ambient_overlays"]
const DECORATIVE_FIELDS: Array[String] = ["profile_kind", "occupied", "clearance", "anchor_offset", "visual_bounds", "render_layers", "ambient_overlays"]
const STANDING_SOURCE_BOUNDS := Rect2(-24, -72, 48, 80)
const SEATED_FIELDS: Array[String] = ["work_cell", "work_facing", "seat_anchor", "seat_z_offset", "pose_set", "workstation_capability_revision", "seat_anchor_by_employee", "seat_layer_z_offsets", "seat_pose_depth_lock", "seat_state_handoff", "grounded_work_shadow", "grounded_work_shadow_follow_seat_x", "ground_shadow_z_offset"]
const OPPOSITE_GAZE := {"north": "south", "east": "west", "south": "north", "west": "east"}

var data: Dictionary = {}
var catalog: Dictionary = {}
var role_kits: Dictionary = {}
var decor_kits: Dictionary = {}
var employee_decor_kits: Dictionary = {}
# This is a worker-supplied read-only projection, never a second inventory store.
var furnishing_inventory: Dictionary = {}
var furnishing_bound := false
# Dev-only geometry fixtures can register labeled synthetic pose capabilities on
# their own model instance. Production readiness uses actual CharacterArt data.
var test_pose_capabilities: Dictionary = {}
# A specific live owner may inspect candidates on this model only. This never
# changes their recorded approval status or the production model's gate.
var _calibration_owner_id := 0
var _calibration_service_profiles: Dictionary[String, Dictionary] = {}
var _calibration_decorative_profiles: Dictionary[String, Dictionary] = {}

func enable_calibration_preview(owner: Object) -> bool:
	if not OS.has_feature("editor") or owner == null or not is_instance_valid(owner): return false
	if _calibration_owner_id != 0 and _calibration_owner_id != owner.get_instance_id(): return false
	_calibration_owner_id = owner.get_instance_id()
	return true

func disable_calibration_preview(owner: Object) -> void:
	if owner != null and _calibration_owner_id == owner.get_instance_id():
		_calibration_owner_id = 0
		_calibration_service_profiles.clear()
		_calibration_decorative_profiles.clear()

func calibration_preview_enabled() -> bool:
	return OS.has_feature("editor") and _calibration_owner_id != 0 and is_instance_id_valid(_calibration_owner_id)

func authorize_calibration_service_profile(kind: String, facing: String, owner: Object) -> bool:
	# A standing prop must not borrow an employee pose registry to enter a dev
	# scene. Bind admission to this live model owner and this exact definition.
	# Copying/mutating a candidate does not copy a permit, nor grant approval.
	if not calibration_preview_enabled() or owner == null or not is_instance_valid(owner) or owner.get_instance_id() != _calibration_owner_id: return false
	var base: Variant = catalog.get(kind)
	if not base is Dictionary or kind in ["desk", "research_table"]: return false
	if not base.get("facings", []) is Array or not base.facings.has(facing) or not FACINGS.has(facing): return false
	var variants: Variant = base.get("facing_profiles")
	if not variants is Dictionary or not variants.get(facing) is Dictionary: return false
	var variant: Dictionary = variants[facing]
	if str(variant.get("profile_kind", "")) != "service" or str(variant.get("status", "")) != "calibration_candidate": return false
	for field: String in SERVICE_FIELDS:
		if not variant.has(field): return false
	if str(variant.service_side) != facing: return false
	var profile: Dictionary = base.duplicate(true)
	profile.erase("facing_profiles")
	profile.merge(variant, true)
	var errors: Array[String] = []
	_validate_direction_profile(profile, errors)
	if not errors.is_empty(): return false
	_calibration_service_profiles[kind + ":" + facing] = profile.duplicate(true)
	return true

func _service_calibration_authorized(kind: String, facing: String, profile: Dictionary) -> bool:
	return calibration_preview_enabled() and _calibration_service_profiles.get(kind + ":" + facing, {}) == profile

func authorize_calibration_decorative_profile(kind: String, facing: String, owner: Object) -> bool:
	# Passive art has no employee/pose authority to borrow. Admission belongs to
	# one live model owner and one exact definition, without changing its review.
	if not calibration_preview_enabled() or owner == null or not is_instance_valid(owner) or owner.get_instance_id() != _calibration_owner_id: return false
	var base: Variant = catalog.get(kind)
	if not base is Dictionary or kind in ["desk", "research_table"]: return false
	if not base.get("facings", []) is Array or not base.facings.has(facing) or not FACINGS.has(facing): return false
	var variants: Variant = base.get("facing_profiles")
	if not variants is Dictionary or not variants.get(facing) is Dictionary: return false
	var variant: Dictionary = variants[facing]
	if str(variant.get("profile_kind", "")) != "decorative" or str(variant.get("status", "")) != "calibration_candidate": return false
	for field: String in DECORATIVE_FIELDS:
		if not variant.has(field): return false
	var profile: Dictionary = base.duplicate(true)
	profile.erase("facing_profiles")
	profile.merge(variant, true)
	var errors: Array[String] = []
	_validate_direction_profile(profile, errors)
	if not errors.is_empty(): return false
	_calibration_decorative_profiles[kind + ":" + facing] = profile.duplicate(true)
	return true

func _decorative_calibration_authorized(kind: String, facing: String, profile: Dictionary) -> bool:
	return calibration_preview_enabled() and _calibration_decorative_profiles.get(kind + ":" + facing, {}) == profile

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
	if catalog_path == DEFAULT_CATALOG_PATH:
		var library: Variant = _read_json(FURNISHING_CATALOG_PATH)
		if library is Dictionary:
			catalog.merge(library.get("furniture", {}), false)
			role_kits = library.get("role_kits", {}).duplicate(true)
			decor_kits = library.get("decor_kits", {}).duplicate(true)
			employee_decor_kits = library.get("employee_decor_kits", {}).duplicate(true)
	return _definition_errors.is_empty()

func configure(room_data: Dictionary, furniture_data: Dictionary) -> void:
	_calibration_service_profiles.clear()
	_calibration_decorative_profiles.clear()
	data = room_data.duplicate(true)
	catalog = furniture_data.get("furniture", furniture_data).duplicate(true)
	role_kits = furniture_data.get("role_kits", {}).duplicate(true)
	decor_kits = furniture_data.get("decor_kits", {}).duplicate(true)
	employee_decor_kits = furniture_data.get("employee_decor_kits", {}).duplicate(true)
	furnishing_inventory.clear()
	furnishing_bound = false
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

func resolve_placements(hire_count: int, overrides: Dictionary = {}, include_future: bool = false) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	if furnishing_bound:
		var defaults: Dictionary = {}
		for original: Dictionary in data.get("props", []): defaults[str(original.id)] = original
		for id: String in furnishing_inventory:
			var item: Dictionary = furnishing_inventory[id]
			if not overrides.has(id): continue # An omitted optional item is in storage.
			var raw: Dictionary = defaults.get(id, {}).duplicate(true)
			raw.merge({"id": id, "kind": str(item.kind), "owner_id": str(item.get("ownerId", "")), "required_hires": int(raw.get("required_hires", 0))}, true)
			raw.merge(overrides[id], true)
			raw["role_kit"] = str(item.get("roleKit", ""))
			var explicit_decor := str(item.get("decorKit", item.get("decor_kit", "")))
			if not explicit_decor.is_empty():
				raw["decor_kit"] = explicit_decor
			placements.append(resolve(raw))
		if include_future:
			for original: Dictionary in data.get("props", []):
				if not furnishing_inventory.has(str(original.id)) and int(original.get("required_hires", 0)) <= hire_count:
					var future := original.duplicate(true)
					for kit_id: String in role_kits:
						if str(role_kits[kit_id].get("owner_id", "")) == str(future.get("owner_id", "")) and str(role_kits[kit_id].get("host_kind", "")) == str(future.get("kind", "")):
							future["role_kit"] = kit_id
					placements.append(resolve(future))
		return placements
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
	var facing := str(raw.get("facing", "south"))
	var resolution := resolve_profile(kind, facing)
	var profile: Dictionary = resolution.profile
	var grid := vector(raw.get("grid", []), Vector2i(-999, -999))
	placement["id"] = str(raw.get("id", ""))
	placement["kind"] = kind
	placement["owner_id"] = str(raw.get("owner_id", ""))
	placement["grid"] = grid
	placement["facing"] = facing
	placement["direction_errors"] = resolution.errors
	placement["profile"] = profile
	placement["occupied"] = _offset_cells(profile.get("occupied", []) if profile.get("occupied", []) is Array else [], grid)
	placement["clearance"] = _offset_cells(profile.get("clearance", []) if profile.get("clearance", []) is Array else [], grid)
	placement["anchor_offset"] = Vector2(vector(profile.get("anchor_offset", [0, 0])))
	placement["anchor"] = world(grid) + placement["anchor_offset"]
	placement["visual_bounds"] = rectangle(profile.get("visual_bounds", []))
	placement["world_visual_bounds"] = Rect2(placement["anchor"] + placement["visual_bounds"].position, placement["visual_bounds"].size)
	placement["layers"] = profile.get("layers", {}).duplicate(true) if profile.get("layers", {}) is Dictionary else {}
	placement["render_layers"] = render_layers(profile, kind)
	var kit_id := str(raw.get("role_kit", ""))
	if not kit_id.is_empty():
		var kit: Dictionary = role_kits.get(kit_id, {})
		var kit_profile: Dictionary = kit.get("facing_profiles", {}).get(facing, {})
		if kind != str(kit.get("host_kind", "")) or str(raw.get("owner_id", "")) != str(kit.get("owner_id", "")) or kit_profile.is_empty():
			placement.direction_errors.append("Role kit has no reviewed owner/host/facing binding")
		else:
			for layer: Dictionary in kit_profile.get("render_layers", []):
				placement.render_layers.append(layer.duplicate(true))
			# A kit may not silently protrude beyond the validated host envelope.
			var kit_bounds := rectangle(kit_profile.get("visual_bounds", []))
			placement.visual_bounds = placement.visual_bounds.merge(kit_bounds)
			placement.world_visual_bounds = Rect2(placement.anchor + placement.visual_bounds.position, placement.visual_bounds.size)
	# Host-surface decor stacks after the role kit. It occupies no floor cells.
	var decor_id := str(raw.get("decor_kit", raw.get("decorKit", "")))
	if decor_id.is_empty():
		decor_id = str(employee_decor_kits.get(str(raw.get("owner_id", "")), ""))
	if not decor_id.is_empty():
		placement["decor_kit"] = decor_id
		var decor: Dictionary = decor_kits.get(decor_id, {})
		var decor_profile: Dictionary = decor.get("facing_profiles", {}).get(facing, {})
		if kind != str(decor.get("host_kind", "")) or str(raw.get("owner_id", "")) != str(decor.get("owner_id", "")) or decor_profile.is_empty():
			placement.direction_errors.append("Decor kit has no reviewed owner/host/facing binding")
		else:
			for layer: Dictionary in decor_profile.get("render_layers", []):
				placement.render_layers.append(layer.duplicate(true))
			var decor_bounds := rectangle(decor_profile.get("visual_bounds", []))
			placement.visual_bounds = placement.visual_bounds.merge(decor_bounds)
			placement.world_visual_bounds = Rect2(placement.anchor + placement.visual_bounds.position, placement.visual_bounds.size)
	placement["hit_bounds"] = rectangle(profile.get("hit_bounds", profile.get("visual_bounds", [])))
	placement["world_hit_bounds"] = Rect2(placement["anchor"] + placement["hit_bounds"].position, placement["hit_bounds"].size)
	if str(profile.get("profile_kind", "")) == "decorative":
		for field: String in SEATED_FIELDS + ["interaction", "work_position", "service_side", "approach_gaze", "approach_visual_bounds", "world_approach_visual_bounds"]: placement.erase(field)
		placement.erase("calibration_owner_id")
		placement["profile_kind"] = "decorative"
		var viewpoints: Array[Dictionary] = []
		for item: Variant in profile.get("standing_viewpoints", []) if profile.get("standing_viewpoints", []) is Array else []:
			if not item is Dictionary or not _integer_pair(item.get("cell")) or not _integer_rect(item.get("visual_bounds")): continue
			var cell := grid + vector(item.cell)
			var bounds := rectangle(item.visual_bounds)
			viewpoints.append({"cell": cell, "visual_bounds": bounds, "world_visual_bounds": Rect2(world(cell) + bounds.position, bounds.size)})
		placement["standing_viewpoints"] = viewpoints
		return placement
	placement["interaction"] = grid + vector(profile.get("interaction", []))
	placement["work_cell"] = grid + vector(profile.get("work_cell", profile.get("interaction", [])))
	if str(profile.get("profile_kind", "")) == "collaboration":
		for field: String in SEATED_FIELDS:
			placement.erase(field)
		placement.erase("calibration_owner_id")
		placement.erase("work_position")
		placement.erase("work_cell")
		placement["profile_kind"] = "collaboration"
		var slots: Array[Dictionary] = []
		for item: Variant in profile.get("collaboration_slots", []) if profile.get("collaboration_slots", []) is Array else []:
			if not item is Dictionary: continue
			var slot: Dictionary = item.duplicate(true)
			slot["cell"] = grid + vector(item.get("cell"))
			slot["position"] = world(slot.cell)
			var bounds := rectangle(item.get("visual_bounds"))
			slot["visual_bounds"] = bounds
			slot["world_visual_bounds"] = Rect2(slot.position + bounds.position, bounds.size)
			slots.append(slot)
		placement["collaboration_slots"] = slots
		return placement
	if str(profile.get("profile_kind", "")) == "service":
		for field: String in SEATED_FIELDS: placement.erase(field)
		placement.erase("calibration_owner_id")
		placement.erase("work_position")
		placement["profile_kind"] = "service"
		placement["service_side"] = str(profile.get("service_side", ""))
		placement["approach_gaze"] = str(profile.get("approach_gaze", ""))
		placement["approach_visual_bounds"] = rectangle(profile.get("approach_visual_bounds", []))
		placement["world_approach_visual_bounds"] = Rect2(world(placement.interaction) + placement.approach_visual_bounds.position, placement.approach_visual_bounds.size)
		# Standing service points use the ordinary interaction/navigation path;
		# do not manufacture a work cell, seat socket, or character pose contract.
		return placement
	placement["work_facing"] = str(profile.get("work_facing", facing))
	placement["seat_anchor"] = Vector2(vector(profile.get("seat_anchor", [0, 0])))
	# Logical feet/reservations stay on the work cell; seat_anchor affects only
	# the rendered pose, never its navigation destination or collision center.
	placement["work_position"] = world(placement["work_cell"])
	placement["seat_z_offset"] = int(profile.get("seat_z_offset", placement["layers"].get("seat_z_offset", (placement["work_cell"].y - grid.y) * tile_size)))
	placement["pose_set"] = str(profile.get("pose_set", "legacy-office-v1" if facing == "south" else ""))
	if profile.get("workstation_capability_revision") is String:
		placement["workstation_capability_revision"] = str(profile.workstation_capability_revision)
	if profile.get("calibration_owner_id") is int:
		placement["calibration_owner_id"] = int(profile.calibration_owner_id)
	for field: String in ["seat_anchor_by_employee", "seat_layer_z_offsets", "calibration_limitations"]:
		if profile.get(field) is Dictionary or profile.get(field) is Array:
			placement[field] = profile[field].duplicate(true)
	if profile.get("seat_pose_depth_lock") is bool: placement["seat_pose_depth_lock"] = profile.seat_pose_depth_lock
	if profile.get("seat_state_handoff") is Dictionary: placement["seat_state_handoff"] = profile.seat_state_handoff.duplicate(true)
	if profile.get("grounded_work_shadow") is bool: placement["grounded_work_shadow"] = profile.grounded_work_shadow
	if profile.get("grounded_work_shadow_follow_seat_x") is bool: placement["grounded_work_shadow_follow_seat_x"] = profile.grounded_work_shadow_follow_seat_x
	return placement

func available_facings(kind: String) -> Array[String]:
	var result: Array[String] = []
	for facing: String in FACINGS:
		if resolve_profile(kind, facing).errors.is_empty(): result.append(facing)
	return result

func resolve_profile(kind: String, facing: String) -> Dictionary:
	var definition: Variant = catalog.get(kind, {})
	var base: Dictionary = definition.duplicate(true) if definition is Dictionary else {}
	var errors: Array[String] = []
	if base.is_empty(): return {"profile": {}, "errors": ["Furniture type has no authored profile"]}
	var variants: Dictionary = base.get("facing_profiles", {}) if base.get("facing_profiles", {}) is Dictionary else {}
	var explicit := variants.has(facing)
	var admitted_calibration := false
	var profile := base.duplicate(true)
	profile.erase("facing_profiles")
	var declared: Variant = base.get("facings", [])
	if not FACINGS.has(facing) or not declared is Array or not declared.has(facing):
		errors.append("Facing is not declared as authored")
	if explicit and variants[facing] is Dictionary:
		var variant: Dictionary = variants[facing]
		if base.has("calibration_owner_id") or variant.has("calibration_owner_id"):
			errors.append("Calibration owner id is runtime-only metadata")
		# Common identity and interaction semantics may be shared; directional
		# fields are required below and may not silently inherit a south value.
		profile.merge(variant, true)
		var service := str(profile.get("profile_kind", "")) == "service"
		var collaboration := str(profile.get("profile_kind", "")) == "collaboration"
		var decorative := str(profile.get("profile_kind", "")) == "decorative"
		var profile_kind := str(profile.get("profile_kind", "workstation"))
		if profile_kind not in ["workstation", "service", "collaboration", "decorative"]: errors.append("Unknown directional profile_kind")
		if (service or collaboration or decorative) and kind in ["desk", "research_table"]: errors.append("Seated workstations cannot use shared-furniture profiles")
		if collaboration and kind != "collaboration_cluster": errors.append("Collaboration profiles are limited to the collaboration cluster")
		if not service and not collaboration and not decorative and kind not in ["desk", "research_table"]: errors.append("Shared furniture requires an explicit service, collaboration, or decorative profile_kind")
		for field: String in DECORATIVE_FIELDS if decorative else COLLABORATION_FIELDS if collaboration else SERVICE_FIELDS if service else DIRECTION_FIELDS:
			if not variant.has(field): errors.append("Facing requires explicit " + field)
		var review: Dictionary = variant.get("review", {}) if variant.get("review", {}) is Dictionary else {}
		var calibration := str(variant.get("status", "")) == "calibration_candidate" and (_decorative_calibration_authorized(kind, facing, profile) if decorative else _service_calibration_authorized(kind, facing, profile) if service else calibration_preview_enabled() and CharacterArt.calibration_pose_belongs_to(str(variant.get("pose_set", "")), _calibration_owner_id))
		admitted_calibration = calibration
		var review_passed := true
		var runtime_ready := str(variant.get("status", "")) == "runtime_ready"
		if not calibration:
			var gates: Array[String] = ["art", "geometry"]
			if collaboration or (not service and not decorative): gates.append("poses")
			for gate: String in gates:
				var reviewed: Variant = review.get(gate, false)
				if not reviewed is bool or not reviewed:
					review_passed = false
					errors.append("Facing has not passed " + gate + " review")
			if not runtime_ready: errors.append("Facing is not runtime_ready")
		else:
			profile["calibration_preview"] = true
			profile["calibration_owner_id"] = _calibration_owner_id
		var reviewed_capability: Dictionary = {}
		var declared_capability_revision := str(profile.get("workstation_capability_revision", ""))
		if not calibration and not service and not decorative and runtime_ready and review_passed and not declared_capability_revision.is_empty():
			reviewed_capability = CharacterArt.reviewed_workstation_capability(
				str(profile.get("pose_set", "")),
				str(profile.get("work_facing", "")),
				declared_capability_revision
			)
		if profile.has("workstation_capability_revision"):
			if not profile.workstation_capability_revision is String or str(profile.workstation_capability_revision).is_empty():
				errors.append("Workstation capability revision must be a nonempty string")
			elif reviewed_capability.is_empty() and not calibration:
				errors.append("Workstation capability revision is not in the reviewed production registry")
			elif not reviewed_capability.is_empty():
				if str(profile.get("asset_revision", "")) != str(reviewed_capability.asset_revision):
					errors.append("Workstation asset revision does not match its reviewed capability")
				for option: String in ["seat_pose_depth_lock", "seat_state_handoff", "grounded_work_shadow", "grounded_work_shadow_follow_seat_x"]:
					if not profile.has(option) or not CharacterArt.reviewed_workstation_option_admitted(str(profile.get("pose_set", "")), str(profile.get("work_facing", "")), str(profile.get("workstation_capability_revision", "")), option, profile[option]):
						errors.append("Reviewed workstation capability requires exact " + option)
		if service and str(variant.get("service_side", "")) != facing: errors.append("Service side must match the selected furniture view")
		if collaboration and str(variant.get("reference_gaze", "")) != facing: errors.append("Collaboration reference gaze must match the selected furniture view")
		if kind in ["desk", "research_table"]:
			if not _pose_supported(str(variant.get("pose_set", "")), str(variant.get("work_facing", "")), kind):
				errors.append("Working furniture requires a real directional actor pose capability")
			if str(variant.get("work_facing", "")) != facing: errors.append("Workstation facing must match the worker gaze")
		_validate_direction_profile(profile, errors, admitted_calibration, reviewed_capability)
	elif facing != "south" or explicit:
		errors.append("No explicit authored profile for this facing")
	elif str(profile.get("profile_kind", "")) in ["service", "collaboration", "decorative"]:
		errors.append("Shared and passive furniture require explicit directional profiles")
	# This optional correction is intentionally NOT inferred from a legacy
	# layer/seat offset or a user-supplied calibration_preview marker.
	if profile.has("grounded_work_shadow"):
		if not profile.grounded_work_shadow is bool:
			errors.append("Grounded work shadow must be an explicit boolean")
		elif profile.grounded_work_shadow and kind not in ["desk", "research_table"]:
			errors.append("Grounded work shadow is limited to admitted workstations")
		elif profile.grounded_work_shadow and not admitted_calibration and not CharacterArt.reviewed_workstation_option_admitted(str(profile.get("pose_set", "")), str(profile.get("work_facing", "")), str(profile.get("workstation_capability_revision", "")), "grounded_work_shadow", true):
			errors.append("Grounded work shadow requires an exact reviewed production or owner-scoped calibration capability")
	if profile.has("ground_shadow_z_offset"):
		errors.append("Ground shadow depth is derived from live furniture layers, not authored")
	if profile.has("grounded_work_shadow_follow_seat_x"):
		if not profile.grounded_work_shadow_follow_seat_x is bool:
			errors.append("Grounded shadow horizontal follow must be an explicit boolean")
		elif profile.grounded_work_shadow_follow_seat_x and (not profile.get("grounded_work_shadow") is bool or not profile.grounded_work_shadow):
			errors.append("Horizontal shadow follow requires admitted grounded workstation shadows")
		elif profile.grounded_work_shadow_follow_seat_x and not admitted_calibration and not CharacterArt.reviewed_workstation_option_admitted(str(profile.get("pose_set", "")), str(profile.get("work_facing", "")), str(profile.get("workstation_capability_revision", "")), "grounded_work_shadow_follow_seat_x", true):
			errors.append("Horizontal shadow follow requires an exact reviewed production or owner-scoped calibration capability")
	profile["direction_explicit"] = explicit
	return {"profile": profile, "errors": errors}

func _pose_supported(pose_set: String, facing: String, kind: String) -> bool:
	if pose_set.begins_with("test-only-") and OS.has_feature("editor"):
		var fixture: Variant = test_pose_capabilities.get(pose_set, [])
		if fixture is Array and fixture.has(facing): return true
	var poses: Array[String] = ["seated", "typing"]
	if kind == "research_table": poses.assign(["research"])
	for employee_id: String in ["mira", "theo"]:
		for pose: String in poses:
			if not CharacterArt.supports_work_pose(employee_id, pose_set, facing, pose): return false
	return true

func _validate_direction_profile(profile: Dictionary, errors: Array[String], admitted_calibration: bool = false, reviewed_capability: Dictionary = {}) -> void:
	for field: String in ["occupied", "clearance"]:
		if not profile.get(field) is Array:
			errors.append(field + " must be an array of integer cell offsets")
			continue
		if field == "occupied" and profile[field].is_empty(): errors.append("Facing footprint is empty")
		for cell: Variant in profile[field]:
			if not _integer_pair(cell): errors.append(field + " requires integer cell offsets")
	var service := str(profile.get("profile_kind", "")) == "service"
	var collaboration := str(profile.get("profile_kind", "")) == "collaboration"
	var decorative := str(profile.get("profile_kind", "")) == "decorative"
	var pair_fields: Array[String] = []
	pair_fields.assign(["anchor_offset"] if decorative else ["interaction", "anchor_offset"])
	if not service and not collaboration and not decorative: pair_fields.append_array(["work_cell", "seat_anchor"])
	for field: String in pair_fields:
		if not _integer_pair(profile.get(field)): errors.append(field + " requires an integer pair")
	if decorative:
		_validate_decorative_profile(profile, errors)
	elif service:
		_validate_service_profile(profile, errors)
	elif collaboration:
		_validate_collaboration_profile(profile, errors)
	else:
		if profile.has("service_side") or profile.has("approach_gaze") or profile.has("approach_visual_bounds"): errors.append("Workstation profiles cannot mix in standing service semantics")
		if not FACINGS.has(str(profile.get("work_facing", ""))): errors.append("work_facing must be cardinal")
		if not _integer_number(profile.get("seat_z_offset")): errors.append("seat_z_offset must be integer pixels")
	if profile.has("seat_anchor_by_employee"):
		var anchors: Variant = profile.seat_anchor_by_employee
		if not anchors is Dictionary: errors.append("Per-employee seat anchors must be a dictionary")
		else:
			for employee_id: String in ["mira", "theo"]:
				if not _integer_pair(anchors.get(employee_id)): errors.append("Missing integer seat anchor for " + employee_id)
	if profile.has("seat_layer_z_offsets"):
		var depths: Variant = profile.seat_layer_z_offsets
		if not depths is Dictionary: errors.append("Seat layer depths must be a dictionary")
		else:
			for part: String in ["upper", "lower"]:
				if not _integer_number(depths.get(part)): errors.append("Missing integer seat layer depth for " + part)
	if profile.has("seat_pose_depth_lock"):
		if not profile.seat_pose_depth_lock is bool:
			errors.append("Seat pose depth lock must be an explicit boolean")
		elif profile.seat_pose_depth_lock and not admitted_calibration and reviewed_capability.get("seat_pose_depth_lock") != true:
			errors.append("Seat pose depth lock requires an exact reviewed production or owner-scoped calibration capability")
	if profile.has("seat_state_handoff"):
		var handoff: Variant = profile.seat_state_handoff
		if not handoff is Dictionary:
			errors.append("Seat state handoff must be an explicit dictionary")
		elif not admitted_calibration and not CharacterArt.reviewed_workstation_option_admitted(str(profile.get("pose_set", "")), str(profile.get("work_facing", "")), str(profile.get("workstation_capability_revision", "")), "seat_state_handoff", handoff):
			errors.append("Seat state handoff requires an exact reviewed production or owner-scoped calibration capability")
		else:
			var clearance: Variant = handoff.get("clearance_pixels")
			if not _integer_number(clearance) or int(clearance) < 1 or int(clearance) > 128:
				errors.append("Seat state handoff requires clearance_pixels from 1 to 128")
			var depths: Variant = profile.get("seat_layer_z_offsets")
			if not depths is Dictionary or not _integer_number(depths.get("lower")):
				errors.append("Seat state handoff requires an integer lower-body depth")
			else:
				var lower := int(depths.lower)
				var chair_behind := false
				var desk_ahead := false
				for layer: Variant in profile.get("render_layers", []):
					if not layer is Dictionary or not _integer_number(layer.get("z_offset")): continue
					var layer_name := str(layer.get("name", ""))
					if layer_name.begins_with("Chair") and int(layer.z_offset) < lower: chair_behind = true
					if layer_name == "DeskFront" and int(layer.z_offset) > lower: desk_ahead = true
				if not chair_behind or not desk_ahead:
					errors.append("Seat state handoff depth must be bracketed by chair and DeskFront layers")
	if profile.has("calibration_limitations"):
		if not profile.calibration_limitations is Array:
			errors.append("Calibration limitations must be a list of honest diagnostic notes")
		else:
			for limitation: Variant in profile.calibration_limitations:
				if not limitation is String or str(limitation).is_empty(): errors.append("Calibration limitations require nonempty text")
	var bounds := rectangle(profile.get("visual_bounds"))
	if not _integer_rect(profile.get("visual_bounds")) or not bounds.has_area(): errors.append("Facing requires positive native visual_bounds")
	var hit := rectangle(profile.get("hit_bounds", profile.get("visual_bounds")))
	if not hit.has_area() or not bounds.encloses(hit): errors.append("Hit bounds must lie inside visual_bounds")
	var entries: Variant = profile.get("render_layers", [])
	if not entries is Array or entries.is_empty():
		errors.append("Facing requires native render_layers")
		return
	var names: Array[String] = []
	var union := Rect2()
	for entry: Variant in entries:
		if not entry is Dictionary:
			errors.append("Render layer must be an object")
			continue
		var layer := entry as Dictionary
		var layer_name := str(layer.get("name", ""))
		if layer_name.is_empty() or layer_name.validate_node_name() != layer_name or layer_name in [".", "..", "PlacementCollision"] or names.has(layer_name): errors.append("Render layers require unique valid node names")
		names.append(layer_name)
		var path := str(layer.get("art", ""))
		if not path.begins_with("res://") or not ResourceLoader.exists(path, "Texture2D"):
			errors.append("Missing native layer art: " + path)
			continue
		var texture := load(path) as Texture2D
		var region := rectangle(layer.get("region"))
		if texture == null or not _integer_rect(layer.get("region")) or not region.has_area() or not Rect2(Vector2.ZERO, texture.get_size()).encloses(region):
			errors.append("Layer region exceeds native art: " + layer_name)
			continue
		if not _integer_pair(layer.get("offset")) or not _integer_number(layer.get("z_offset")):
			errors.append("Layer offset/depth must be integer pixels: " + layer_name)
		if layer.has("rotation") or layer.has("scale") or layer.has("flip_h") or layer.has("flip_v"):
			errors.append("Native directional art cannot rotate, scale or mirror")
		var destination := Rect2(Vector2(vector(layer.get("offset"))) - region.size * 0.5, region.size)
		if not destination.position.is_equal_approx(destination.position.round()): errors.append("Layer canvas must land on integer pixels")
		var ink := measured_layer_ink_bounds(layer)
		var content := layer_content_bounds(layer)
		if layer.has("content_bounds") and (not _integer_rect(layer.content_bounds) or not Rect2(Vector2.ZERO, region.size).encloses(content) or (ink.has_area() and not content.encloses(ink))):
			errors.append("Layer content_bounds must contain every nontransparent pixel inside its region: " + layer_name)
		if content.has_area():
			var protected := Rect2(destination.position + content.position, content.size)
			union = union.merge(protected) if union.has_area() else protected
	if union != bounds: errors.append("visual_bounds must equal the union of measured/protected layer content, not transparent canvas padding")
	if not profile.get("ambient_overlays", []) is Array:
		errors.append("ambient_overlays must explicitly list direction-specific attachments")
	else:
		for overlay: Variant in profile.get("ambient_overlays", []):
			if not overlay is Dictionary or not _integer_pair(overlay.get("offset")) or not _integer_number(overlay.get("row")) or not _integer_number(overlay.get("z_offset")):
				errors.append("Ambient overlay requires integer row, offset and depth")
			elif int(overlay.row) < 0 or int(overlay.row) > 4: errors.append("Ambient overlay row is outside the authored atlas")

func _validate_decorative_profile(profile: Dictionary, errors: Array[String]) -> void:
	for field: String in SEATED_FIELDS + ["interaction", "work_position", "service_side", "approach_gaze", "approach_visual_bounds", "action", "actions", "interaction_action"]:
		if profile.has(field): errors.append("Decorative profile cannot contain " + field)
	var review: Variant = profile.get("review", {})
	if not review is Dictionary:
		errors.append("Decorative review must be an art/geometry dictionary")
	else:
		for gate: String in ["art", "geometry"]:
			if not review.get(gate) is bool: errors.append("Decorative review requires explicit boolean " + gate)
		if review.has("poses"): errors.append("Decorative profile does not claim a pose review")
	var occupied: Array[Vector2i] = []
	var clearance: Array[Vector2i] = []
	for field: String in ["occupied", "clearance"]:
		if not profile.get(field) is Array: continue
		var seen: Array[Vector2i] = []
		for item: Variant in profile[field]:
			if not _integer_pair(item): continue
			var cell := vector(item)
			if seen.has(cell): errors.append("Decorative " + field + " contains a duplicate cell")
			seen.append(cell)
		if field == "occupied": occupied.assign(seen)
		else: clearance.assign(seen)
	for cell: Vector2i in clearance:
		if occupied.has(cell): errors.append("Decorative clearance intersects its own footprint")
	var viewpoints: Variant = profile.get("standing_viewpoints", [])
	if not viewpoints is Array:
		errors.append("standing_viewpoints must be an array of geometry-only viewing envelopes")
		return
	var seen_points: Array[Vector2i] = []
	for item: Variant in viewpoints:
		if not item is Dictionary or not _integer_pair(item.get("cell")) or not _integer_rect(item.get("visual_bounds")):
			errors.append("Standing viewpoint requires an integer cell and native visual_bounds")
			continue
		for key: Variant in item.keys():
			if key not in ["cell", "visual_bounds"]: errors.append("Standing viewpoint is geometry only; unsupported field " + str(key))
		var cell := vector(item.cell)
		if not clearance.has(cell) or occupied.has(cell): errors.append("Standing viewpoint must belong to clear unoccupied clearance")
		if seen_points.has(cell): errors.append("Duplicate standing viewpoint")
		seen_points.append(cell)
		if not rectangle(item.visual_bounds).encloses(STANDING_SOURCE_BOUNDS): errors.append("Standing viewpoint must contain the native48×80 actor envelope")

func _validate_service_profile(profile: Dictionary, errors: Array[String]) -> void:
	for field: String in SEATED_FIELDS:
		if profile.has(field): errors.append("Standing service profile cannot contain " + field)
	var review: Variant = profile.get("review", {})
	if not review is Dictionary:
		errors.append("Service review must be an art/geometry dictionary")
	else:
		for gate: String in ["art", "geometry"]:
			if not review.get(gate) is bool: errors.append("Service review requires explicit boolean " + gate)
		if review.has("poses"): errors.append("Standing service profile does not claim a seated pose review")
	var side := str(profile.get("service_side", ""))
	if not FACINGS.has(side): errors.append("service_side must be cardinal")
	if str(profile.get("approach_gaze", "")) != str(OPPOSITE_GAZE.get(side, "invalid")):
		errors.append("Standing approach gaze must face opposite the service side")
	var headroom := rectangle(profile.get("approach_visual_bounds", []))
	if not _integer_rect(profile.get("approach_visual_bounds")) or not headroom.encloses(STANDING_SOURCE_BOUNDS):
		errors.append("Service approach_visual_bounds must contain the native standing source cell (-24,-72,48,80)")
	if not profile.get("occupied") is Array or profile.occupied.is_empty() or not profile.get("clearance") is Array or not _integer_pair(profile.get("interaction")): return
	var interaction := vector(profile.interaction)
	var occupied: Array[Vector2i] = []
	var low := Vector2i(2147483647, 2147483647)
	var high := Vector2i(-2147483647, -2147483647)
	for value: Variant in profile.occupied:
		if not _integer_pair(value): return
		var cell := vector(value)
		occupied.append(cell)
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	var approach_clear := false
	for value: Variant in profile.clearance:
		if not _integer_pair(value): continue
		var cell := vector(value)
		if occupied.has(cell): errors.append("Service clearance intersects its own footprint")
		if cell == interaction: approach_clear = true
	if not approach_clear: errors.append("Service interaction must belong to its explicit clearance")
	var on_face := false
	match side:
		"north": on_face = interaction.y == low.y - 1 and interaction.x >= low.x and interaction.x <= high.x
		"east": on_face = interaction.x == high.x + 1 and interaction.y >= low.y and interaction.y <= high.y
		"south": on_face = interaction.y == high.y + 1 and interaction.x >= low.x and interaction.x <= high.x
		"west": on_face = interaction.x == low.x - 1 and interaction.y >= low.y and interaction.y <= high.y
	if not on_face: errors.append("Service interaction must be one clear cell beyond its named footprint face")

func _validate_collaboration_profile(profile: Dictionary, errors: Array[String]) -> void:
	for field: String in SEATED_FIELDS + ["service_side", "approach_gaze", "approach_visual_bounds", "standing_viewpoints"]:
		if profile.has(field): errors.append("Collaboration profile cannot contain " + field)
	var review: Variant = profile.get("review", {})
	if not review is Dictionary:
		errors.append("Collaboration review must be an art/geometry/poses dictionary")
	else:
		for gate: String in ["art", "geometry", "poses"]:
			if not review.get(gate) is bool: errors.append("Collaboration review requires explicit boolean " + gate)
	var reference_gaze := str(profile.get("reference_gaze", ""))
	if not FACINGS.has(reference_gaze): errors.append("Collaboration reference_gaze must be cardinal")
	var pose_set_value: Variant = profile.get("collaboration_pose_set")
	if not pose_set_value is String or str(pose_set_value).is_empty(): errors.append("Collaboration pose set must be explicit")
	var asset_revision := str(profile.get("asset_revision", ""))
	if asset_revision != CharacterArt.REVIEWED_COLLABORATION_REVISION: errors.append("Collaboration furniture revision is not the reviewed cluster")
	var occupied: Array[Vector2i] = []
	var clearance: Array[Vector2i] = []
	for raw: Variant in profile.get("occupied", []) if profile.get("occupied", []) is Array else []:
		if _integer_pair(raw): occupied.append(vector(raw))
	for raw: Variant in profile.get("clearance", []) if profile.get("clearance", []) is Array else []:
		if _integer_pair(raw): clearance.append(vector(raw))
	var slots: Variant = profile.get("collaboration_slots")
	if not slots is Array or slots.size() != 4:
		errors.append("Collaboration cluster requires exactly four authored seat sockets")
		return
	var seen: Array[Vector2i] = []
	for item: Variant in slots:
		if not item is Dictionary:
			errors.append("Collaboration seat socket must be an object")
			continue
		var slot := item as Dictionary
		var required: Array[String] = ["cell", "work_facing", "visual_bounds", "capability_revision", "seat_anchor_by_employee", "seat_z_offset", "seat_layer_z_offsets", "ground_shadow_z_offset"]
		for field: String in required:
			if not slot.has(field): errors.append("Collaboration seat socket requires " + field)
		if not _integer_pair(slot.get("cell")): continue
		var cell := vector(slot.cell)
		if seen.has(cell): errors.append("Collaboration seat sockets must use distinct cells")
		seen.append(cell)
		if occupied.has(cell) or not clearance.has(cell): errors.append("Collaboration seat socket must be clear and included in clearance")
		var facing := str(slot.get("work_facing", ""))
		if not FACINGS.has(facing): errors.append("Collaboration seat work_facing must be cardinal")
		var capability := CharacterArt.reviewed_collaboration_capability(str(pose_set_value), facing, str(slot.get("capability_revision", "")))
		if capability.is_empty() or str(capability.get("furniture_asset_revision", "")) != asset_revision: errors.append("Collaboration seat lacks an exact reviewed directional pose capability")
		if not _integer_rect(slot.get("visual_bounds")) or not rectangle(slot.get("visual_bounds")).encloses(STANDING_SOURCE_BOUNDS): errors.append("Collaboration seat must contain the native48×80 character envelope")
		var anchors: Variant = slot.get("seat_anchor_by_employee")
		if not anchors is Dictionary:
			errors.append("Collaboration seat anchors must be per employee")
		else:
			for employee_id: String in ["mira", "theo"]:
				if not _integer_pair(anchors.get(employee_id)): errors.append("Collaboration seat missing anchor for " + employee_id)
		if not _integer_number(slot.get("seat_z_offset")) or not _integer_number(slot.get("ground_shadow_z_offset")): errors.append("Collaboration seat depth values must be integer pixels")
		var depths: Variant = slot.get("seat_layer_z_offsets")
		if not depths is Dictionary or not _integer_number(depths.get("lower")) or not _integer_number(depths.get("upper")):
			errors.append("Collaboration seat requires integer upper/lower depths")
		elif int(depths.lower) >= int(depths.upper) or int(slot.get("ground_shadow_z_offset", 0)) >= int(depths.lower):
			errors.append("Collaboration seat shadow/lower/upper depth order is invalid")
	if not seen.is_empty() and vector(profile.get("interaction")) != seen[0]: errors.append("Collaboration interaction must equal its first deterministic seat socket")

static func _integer_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))

static func _integer_pair(value: Variant) -> bool:
	if value is Vector2i: return true
	if value is Vector2: return value.is_finite() and value == value.round()
	return value is Array and value.size() == 2 and _integer_number(value[0]) and _integer_number(value[1])

static func _integer_rect(value: Variant) -> bool:
	if value is Rect2: return value.position.is_finite() and value.size.is_finite() and value.position == value.position.round() and value.size == value.size.round()
	if not value is Array or value.size() != 4: return false
	for number: Variant in value:
		if not _integer_number(number): return false
	return true

static func measured_layer_ink_bounds(layer: Dictionary) -> Rect2:
	# Bounds are local to the selected atlas region, NOT to the source image.
	# Any nonzero alpha is included: faint matte residue may not bypass wall
	# validation. Measuring never trims/repositions the registered render canvas.
	var path := str(layer.get("art", ""))
	if not ResourceLoader.exists(path, "Texture2D"): return Rect2()
	var texture := load(path) as Texture2D
	if texture == null: return Rect2()
	var region := rectangle(layer.get("region"))
	if not region.has_area() or not Rect2(Vector2.ZERO, texture.get_size()).encloses(region): return Rect2()
	var image := texture.get_image()
	if image == null or image.is_empty(): return Rect2()
	if image.is_compressed() and image.decompress() != OK: return Rect2()
	return Rect2(image.get_region(Rect2i(region)).get_used_rect())

static func layer_content_bounds(layer: Dictionary) -> Rect2:
	# An optional conservative protected box can include intentional clearance,
	# but validation independently proves it never excludes visible artwork.
	return rectangle(layer.content_bounds) if layer.has("content_bounds") else measured_layer_ink_bounds(layer)

static func render_layers(profile: Dictionary, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if profile.has("render_layers"):
		var ordered: Array[Dictionary] = []
		if profile.render_layers is Array:
			for layer: Variant in profile.render_layers:
				if layer is Dictionary: ordered.append({"layer": layer.duplicate(true), "order": ordered.size()})
		# Editor draw order must agree with runtime depth even when authored JSON
		# lists semantic layers in a different order. Equal-depth cabinet panels
		# retain declared order explicitly; sort implementation stability is not
		# an ownership/layering contract.
		ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var left := int(a.layer.get("z_offset", 0))
			var right := int(b.layer.get("z_offset", 0))
			return left < right if left != right else int(a.order) < int(b.order)
		)
		for entry: Dictionary in ordered: result.append(entry.layer)
		return result
	# Canonicalize the existing south-only scenes without changing any pixels,
	# node handles, layer registration or effective depth.
	var path := str(profile.get("art", ""))
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"): return result
	var texture := load(path) as Texture2D
	if texture == null: return result
	var depth: Dictionary = profile.get("layers", {})
	var offset: Variant = profile.get("sprite_offset", [0, 0])
	if profile.has("atlas_cell"):
		var cell := vector(profile.atlas_cell)
		var row := int(profile.get("atlas_row", 0))
		var prefix := "Workstation" if kind == "desk" else "ResearchBench"
		for column: int in range(2):
			result.append({"name": prefix + ("Rear" if column == 0 else "Front"), "art": path, "region": [column * cell.x, row * cell.y, cell.x, cell.y], "offset": offset, "z_offset": int(depth.get("rear_z_offset" if column == 0 else "front_z_offset", -40 if column == 0 else 1))})
	else:
		result.append({"name": "PropSprite", "art": path, "region": [0, 0, texture.get_width(), texture.get_height()], "offset": offset, "z_offset": int(depth.get("body_z_offset", 0))})
	return result

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
		for error: String in placement.get("direction_errors", []):
			_add_issue(result, "unsupported_facing", id, error)
		if placement.get("occupied", []).is_empty(): _add_issue(result, "empty_footprint", id, "Furniture needs an occupied footprint")
		for cell: Vector2i in placement.get("occupied", []):
			if not is_floor(cell): _add_issue(result, "wall_intersection", id, "Footprint intersects a wall or room boundary", cell)
			if _entrances.has(cell): _add_issue(result, "entrance_blocked", id, "Blocks the entrance", cell)
			if _circulation.has(cell): _add_issue(result, "circulation_blocked", id, "Blocks the reserved circulation aisle", cell)
			if occupied.has(cell): _add_issue(result, "furniture_overlap", id, "Overlaps %s" % occupied[cell], cell)
			occupied[cell] = id
		_validate_visual_walls(result, placement)
		if str(placement.get("profile_kind", "")) == "service":
			_validate_service_headroom(result, placement)
		elif str(placement.get("profile_kind", "")) == "collaboration":
			_validate_collaboration_headroom(result, placement)
		elif str(placement.get("profile_kind", "")) == "decorative":
			_validate_decorative_headroom(result, placement)
	for placement: Dictionary in placements:
		var id := str(placement.id)
		var passive := str(placement.get("profile_kind", "")) == "decorative"
		for cell: Vector2i in placement.get("clearance", []):
			if not is_floor(cell): _add_issue(result, "wall_clearance", id, "Viewing clearance intersects a wall" if passive else "Chair or interaction clearance intersects a wall", cell)
			if occupied.has(cell): _add_issue(result, "clearance_blocked", id, ("Blocks viewing clearance with %s" if passive else "Blocks chair or interaction access with %s") % occupied[cell], cell)
		if passive: continue
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
		if str(placement.get("profile_kind", "")) == "decorative": continue
		var interaction: Vector2i = placement.get("interaction", Vector2i(-1, -1))
		if not reached.has(interaction): _add_issue(result, "interaction_unreachable", str(placement.id), "Cannot reach chair or interaction point from entrance", interaction)
		if str(placement.get("profile_kind", "")) == "collaboration":
			for slot: Dictionary in placement.get("collaboration_slots", []):
				if not reached.has(slot.cell): _add_issue(result, "collaboration_seat_unreachable", str(placement.id), "Cannot reach collaboration seat from entrance", slot.cell)
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

func _validate_decorative_headroom(result: Dictionary, placement: Dictionary) -> void:
	for point: Dictionary in placement.get("standing_viewpoints", []):
		var bounds: Rect2 = point.world_visual_bounds
		var valid := Rect2(Vector2.ZERO, Vector2(width, height) * tile_size).encloses(bounds)
		var start := cell_at(bounds.position)
		var end := cell_at(bounds.end - Vector2.ONE * 0.001)
		for y: int in range(start.y, end.y + 1):
			for x: int in range(start.x, end.x + 1):
				if not is_floor(Vector2i(x, y)): valid = false
		if not valid: _add_issue(result, "decorative_headroom", str(placement.id), "Viewing clearance would overlap architecture; move passive furniture inward", point.cell)

func _validate_service_headroom(result: Dictionary, placement: Dictionary) -> void:
	# A clear floor cell is not enough for a tall visitor near the back wall.
	# This envelope protects source-cell headroom against architecture only;
	# overlap with the service cabinet is intentional floor-sorted occlusion.
	var bounds: Rect2 = placement.get("world_approach_visual_bounds", Rect2())
	if not bounds.position.is_finite() or not bounds.size.is_finite() or not bounds.has_area():
		_add_issue(result, "service_headroom", str(placement.id), "Standing service point needs an explicit native visitor envelope")
		return
	if not Rect2(Vector2.ZERO, Vector2(width, height) * tile_size).encloses(bounds):
		_add_issue(result, "service_headroom", str(placement.id), "Standing visitor would overlap a wall; move service furniture farther inward")
		return
	var start := cell_at(bounds.position)
	var end := cell_at(bounds.end - Vector2.ONE * 0.001)
	for y: int in range(start.y, end.y + 1):
		for x: int in range(start.x, end.x + 1):
			if not is_floor(Vector2i(x, y)):
				_add_issue(result, "service_headroom", str(placement.id), "Standing visitor would overlap a wall; move service furniture farther inward", Vector2i(x, y))
				return

func _validate_collaboration_headroom(result: Dictionary, placement: Dictionary) -> void:
	for slot: Dictionary in placement.get("collaboration_slots", []):
		var bounds: Rect2 = slot.get("world_visual_bounds", Rect2())
		var valid := bounds.has_area() and Rect2(Vector2.ZERO, Vector2(width, height) * tile_size).encloses(bounds)
		if valid:
			var start := cell_at(bounds.position)
			var end := cell_at(bounds.end - Vector2.ONE * 0.001)
			for y: int in range(start.y, end.y + 1):
				for x: int in range(start.x, end.x + 1):
					if not is_floor(Vector2i(x, y)): valid = false
		if not valid: _add_issue(result, "collaboration_headroom", str(placement.id), "Seated collaborator would overlap architecture; move the cluster inward", slot.cell)

static func _add_issue(result: Dictionary, code: String, id: String, message: String, cell: Vector2i = Vector2i(-1, -1)) -> void:
	# One actionable message per reason/object; overlay still highlights its cell.
	for existing: Dictionary in result.issues:
		if existing.code == code and existing.id == id and existing.message == message: return
	result.valid = false
	result.errors.append((id + ": " if not id.is_empty() else "") + message)
	result.issues.append({"code": code, "id": id, "message": message, "cell": cell})
