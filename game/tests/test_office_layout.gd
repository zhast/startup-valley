extends SceneTree

const MODEL: Script = preload("res://world/office_layout.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func has_issue(result: Dictionary, code: String, id: String = "") -> bool:
	for issue: Dictionary in result.issues:
		if issue.code == code and (id.is_empty() or issue.id == id): return true
	return false

func run() -> void:
	var layout: OfficeLayout = MODEL.new()
	check(layout.load_files(), "Default architecture and furniture catalog load")
	check(layout.width == 40 and layout.height == 23 and layout.tile_size == 32, "Native room uses 32px floor grid")
	check(layout.floor_cells().size() == 614, "Interior floor and two-cell doorway share one floor set")
	check(layout.is_floor(Vector2i(17, 21)) and not layout.is_floor(Vector2i(17, 22)), "Door opens only fully visible reachable floor cells")
	for entrance: Vector2i in layout.entrance_cells():
		check(layout.world(entrance).y + 10 < 720, "Entrance foot center and collision clearance fit the playable viewport")
	check(not layout.is_floor(Vector2i(4, 1)), "Windows do not open walkable holes in walls")
	check(layout.world(Vector2i(10, 8)) == Vector2(336, 272), "Grid anchors are native cell centers")
	check(layout.cell_at(Vector2(335, 272)) == Vector2i(10, 8), "World positions map back to architecture grid")
	var navigation := layout.navigation_data()
	var nav_floor: Dictionary[Vector2i, bool] = {}
	for rectangle: Array in navigation.walkable_rects:
		for y: int in range(rectangle[1], rectangle[1] + rectangle[3]):
			for x: int in range(rectangle[0], rectangle[0] + rectangle[2]): nav_floor[Vector2i(x, y)] = true
	check(nav_floor.size() == layout.floor_cells().size(), "Navigation uses every exact architecture floor cell")
	for cell: Vector2i in nav_floor: check(layout.is_floor(cell), "Navigation cannot independently paint walkable cells")
	for stage: int in range(5):
		var placements := layout.resolve_placements(stage)
		var validation := layout.validate_placements(placements)
		check(validation.valid, "Hire stage %d validates: %s" % [stage, validation.errors])
		check(placements.size() == [1, 5, 8, 9, 10][stage], "Hire stage %d resolves the intended furniture" % stage)
		var reached := layout.reachable_cells(placements)
		check(reached.size() == layout.walkable_cells(placements).size(), "All free floor remains connected at stage %d" % stage)
		for placement: Dictionary in placements:
			check(reached.has(placement.interaction), "%s interaction is reachable" % placement.id)
			if placement.get("profile_kind", "") == "service":
				check(not placement.has("work_cell"), "%s supplies a reachable standing service point, not a fictional seat" % placement.id)
			elif placement.get("profile_kind", "") == "collaboration":
				check(not placement.has("work_cell") and placement.collaboration_slots.size() == 4, "%s supplies four explicit collaboration sockets, not one fictional workstation" % placement.id)
				for slot: Dictionary in placement.collaboration_slots:
					check(reached.has(slot.cell), "%s collaboration socket is reachable: %s" % [placement.id, slot.cell])
			else:
				check(reached.has(placement.work_cell), "%s work/seat is reachable" % placement.id)
			for cell: Vector2i in placement.clearance: check(reached.has(cell), "%s clearance is accessible" % placement.id)
	var desk := layout.placement_by_id("mira-workstation", 2)
	check(desk.work_cell == Vector2i(10, 7) and desk.interaction == Vector2i(10, 9), "Seat and founder approach are separate authored cells")
	check(desk.profile.layers.shared_origin and desk.profile.layers.rear_z_offset < -32 and desk.profile.layers.front_z_offset > -32, "Layer metadata places seated actor between complementary images")
	check(desk.visual_bounds == Rect2(-48, -80, 96, 96) and desk.hit_bounds == Rect2(-48, -80, 96, 96), "Reviewed South assembly uses its measured native ink bounds")
	var chair_depth := 0
	var desk_front_depth := 0
	var saw_chair := false
	for layer: Dictionary in desk.render_layers:
		if str(layer.name) == "ChairWhole":
			saw_chair = true
			chair_depth = int(layer.z_offset)
			check(Vector2(OfficeLayout.vector(layer.offset)) == Vector2(0, -76), "South desk chair is tucked north of the desktop")
		elif str(layer.name) == "DeskFront":
			desk_front_depth = int(layer.z_offset)
	var standing_feet_y := int(layout.world(desk.work_cell).y)
	var prop_depth := roundi(desk.anchor.y)
	check(saw_chair and prop_depth + chair_depth < standing_feet_y and prop_depth + desk_front_depth > prop_depth + chair_depth, "South desk chair draws below a standing worker at the work cell and under DeskFront")
	var cluster := layout.placement_by_id("collaboration-cluster", 2)
	check(cluster.visual_bounds == Rect2(-80, -80, 161, 148) and cluster.hit_bounds == Rect2(-80, -80, 161, 148), "South collaboration cluster includes the north chairs behind the table")
	var north_chairs := 0
	for layer: Dictionary in cluster.render_layers:
		var layer_name := str(layer.name)
		if layer_name == "NorthChair0Whole" or layer_name == "NorthChair1Whole":
			north_chairs += 1
			check(Vector2(OfficeLayout.vector(layer.offset)) == Vector2(0, -56) and int(layer.z_offset) == -9, layer_name + " is behind the tabletop at its original depth")
		elif layer_name.begins_with("SouthChair") or layer_name.begins_with("Table"):
			check(Vector2(OfficeLayout.vector(layer.offset)) == Vector2(0, -40), layer_name + " keeps the shared south cluster offset")
	check(north_chairs == 2, "South collaboration cluster still has both far chairs")
	check(layout.validate_candidate("mira-workstation", Vector2i(10, 8), "south", 2).valid, "Existing workstation position is valid")
	check(layout.validate_candidate("mira-workstation", Vector2i(12, 7), "south", 2).valid, "Free workstation bay can be reauthored")
	check(layout.validate_candidate("mira-workstation", Vector2i(10, 8), "east", 2).valid, "Reviewed East orientation resolves without rotating South art")
	check(has_issue(layout.validate_candidate("mira-workstation", Vector2i(0, 8), "south", 2), "wall_intersection"), "Footprint cannot intersect side wall")
	check(has_issue(layout.validate_candidate("mira-workstation", Vector2i(10, 4), "south", 2), "visual_wall_intersection"), "Furniture overhang cannot enter painted north wall even with a floor footprint")
	check(has_issue(layout.validate_candidate("mira-workstation", Vector2i(10, 3), "south", 2), "wall_clearance"), "Seating cannot be hidden inside wall")
	check(has_issue(layout.validate_candidate("mira-workstation", Vector2i(20, 8), "south", 2), "furniture_overlap"), "Desk cannot occupy another desk")
	check(has_issue(layout.validate_candidate("mira-workstation", Vector2i(20, 7), "south", 2), "clearance_blocked"), "Desk cannot block another employee's chair lane")
	check(has_issue(layout.validate_candidate("mira-workstation", Vector2i(17, 8), "south", 2), "circulation_blocked"), "Required circulation remains clear")
	check(has_issue(layout.validate_candidate("mira-workstation", Vector2i(17, 21), "south", 2), "entrance_blocked"), "Door threshold cannot hold furniture")
	check(has_issue(layout.validate_candidate("prototype-bench", Vector2i(29, 18), "south", 2), "unknown_placement"), "Developer cannot move a locked prop at earlier stage")
	check(has_issue(layout.validate_candidate("prototype-bench", Vector2i(29, 17), "south", 4), "visual_overlap"), "Tall prototype cannot overlap approval art while footprints remain separate")
	var override := {"mira-workstation": {"grid": [12, 7], "facing": "south", "owner_id": "theo", "required_hires": 0}}
	var moved := layout.placement_by_id("mira-workstation", 2, override)
	check(moved.grid == Vector2i(12, 7) and moved.owner_id == "mira" and moved.required_hires == 1, "Coordinate override cannot reassign ownership or unlock furniture")
	check(layout.placement_by_id("mira-workstation", 2).grid == Vector2i(10, 8), "Preview does not mutate authored data")
	check(layout.employee_spawn("mira") == Vector2i(11, 18), "Employee spawn comes from the same room definition")
	_test_isolated_chair(layout)
	_test_architecture_validation(layout)
	if failures.is_empty(): print("Office layout: %d checks passed" % checks)
	else: print("Office layout: %d failures / %d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)

func _test_isolated_chair(source: OfficeLayout) -> void:
	var data := source.data.duplicate(true)
	data.circulation_rects = []
	data.windows = []
	# A north chamber has a single floor doorway. The desk blocks the passage
	# while its chair remains on otherwise free floor, unreachable from entry.
	data.floor_rects = [[7, 3, 7, 5], [9, 8, 3, 1], [10, 9, 1, 1], [1, 10, 34, 11]]
	data.props = [{"id": "isolated-desk", "kind": "desk", "grid": [10, 8], "facing": "south"}]
	var custom: OfficeLayout = MODEL.new()
	custom.configure(data, {"furniture": source.catalog})
	var result := custom.validate_placements(custom.resolve_placements(0))
	check(not has_issue(result, "wall_intersection"), "Isolated-chair fixture keeps the whole physical footprint on floor")
	check(not has_issue(result, "interaction_unreachable"), "Isolated-chair fixture keeps founder approach reachable")
	check(has_issue(result, "work_cell_unreachable", "isolated-desk"), "A walkable but isolated chair must be rejected")
	check(has_issue(result, "floor_disconnected"), "Placement cannot isolate a whole room chamber")

func _test_architecture_validation(source: OfficeLayout) -> void:
	var data := source.data.duplicate(true)
	data.floor_rects = [[-1, 3, 34, 18]]
	var custom: OfficeLayout = MODEL.new()
	custom.configure(data, {"furniture": source.catalog})
	check(has_issue(custom.validate_placements([]), "invalid_room"), "Out-of-bounds architecture fails explicitly")
	data = source.data.duplicate(true)
	data.doors = []
	custom.configure(data, {"furniture": source.catalog})
	check(has_issue(custom.validate_placements([]), "invalid_room"), "Room without entrance fails explicitly")
