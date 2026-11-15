extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func capture(name_value: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for i: int in range(6): await process_frame
	RenderingServer.force_draw(false)
	var folder := ProjectSettings.globalize_path("res://tests/output/starter-office-current")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value + ".png")) == OK, "Saved " + name_value)

func projection(path: String, hires: int, with_decor: bool = false) -> Dictionary:
	var data: Dictionary = OfficeLayout._read_json(path)
	var library: Dictionary = OfficeLayout._read_json(OfficeLayout.FURNISHING_CATALOG_PATH)
	var state := {"version": 1, "layoutId": data.id, "revision": hires, "inventory": [], "placements": {}, "recovery": ""}
	for prop: Dictionary in data.props:
		if int(prop.required_hires) > hires or int(prop.get("required_office_level", 1)) > 1: continue
		var owner := str(prop.get("owner_id", ""))
		state.inventory.append({"id": prop.id, "kind": prop.kind, "ownerId": owner, "essential": true, "grant": "test", "roleKit": library.employee_role_kits.get(owner, "")})
		state.placements[prop.id] = {"grid": prop.grid, "facing": prop.facing}
	if with_decor:
		var cells := {"cafe_table": [11, 16], "cafe_chair": [13, 16], "broadleaf_planter": [25, 11]}
		for kind: String in cells:
			var id := "decor-" + kind
			state.inventory.append({"id": id, "kind": kind, "ownerId": "", "essential": false, "grant": "test", "roleKit": ""})
			state.placements[id] = {"grid": cells[kind], "facing": "south"}
	return state

func run() -> void:
	root.size = Vector2i(1280, 720)
	var room := TownRoom.new()
	root.add_child(room)
	check(room.load_layout(), "Original room loads before worker hydration")
	var starter := projection("res://data/office_layout_starter.json", 0, true)
	check(room.apply_furnishing_state(starter), "Worker snapshot switches into the compact definition")
	check(room.layout_model.floor_cells().size() == 288, "Starter has 288 genuine walkable cells")
	for cell: Vector2i in [Vector2i(32, 15), Vector2i(30, 20), Vector2i(2, 12), Vector2i(15, 22)]:
		check(not room.layout_model.is_floor(cell) and not room.navigation.walkable(cell), "Visible garden is blocked by actual navigation")
		check(not room.navigation.position_is_safe(room.navigation.world(cell)), "Garden cannot become a saved actor position")
	for stage: int in range(5):
		check(room.layout_model.validate_placements(room.layout_model.resolve_placements(stage)).valid, "Starter geometry validates at stage %d" % stage)
	room.set_hire_count(0)
	await capture("02-new-company")
	var hired := projection("res://data/office_layout_starter.json", 1, true)
	check(room.apply_furnishing_state(hired), "Mina, shared table and coffee fit with the existing café and plant")
	room.set_hire_count(1)
	for prop: Dictionary in room.resolved_placements:
		if str(prop.get("profile_kind", "")) == "decorative": continue
		var target := room.interaction_world_position(str(prop.id))
		var route := room.navigation.path(room.grid_to_world_position(room.player_spawn), target, "founder")
		check(not route.is_empty() and route[-1].distance_to(target) < 1.0, "Entrance reaches " + str(prop.id))
	await capture("01-starter-with-mina")
	var previous := room.layout_model
	var previous_placements := room.placement_overrides.duplicate(true)
	var invalid := hired.duplicate(true)
	invalid.layoutId = "../../untrusted"
	check(not room.apply_furnishing_state(invalid), "Untrusted layout identity is rejected")
	invalid = projection("res://data/office_layout.json", 2)
	invalid.placements["mira-workstation"].grid = [0, 0]
	check(not room.apply_furnishing_state(invalid), "Invalid larger-room snapshot is rejected transactionally")
	check(room.layout_model == previous and room.placement_overrides == previous_placements and room.navigation.walkable(Vector2i(15, 19)), "Rejected switch preserves model, placements and navigation")
	var expanded := projection("res://data/office_layout.json", 2)
	check(room.apply_furnishing_state(expanded), "Authoritative expansion switches to the full room")
	room.set_hire_count(2)
	check(room.layout_model.floor_cells().size() == 614 and room.architecture.exterior_art == null, "Expanded room restores original architecture and geometry")
	check(room.navigation.position_is_safe(room.grid_to_world_position(room.player_spawn)), "Expanded entrance is safe")
	await capture("03-expanded-studio")
	expanded.erase("layoutId")
	check(room.apply_furnishing_state(expanded), "Legacy projection without layout ID remains supported")
	print("Starter office: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
