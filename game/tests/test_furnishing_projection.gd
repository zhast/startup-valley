extends SceneTree
## Provider-free projection and real scene geometry checks. Worker transaction
## durability is intentionally tested independently through its actual SQLite API.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func state_for(room: TownRoom, hires: int) -> Dictionary:
	var result := {"version": 1, "revision": 0, "inventory": [], "placements": {}, "recovery": ""}
	for original: Dictionary in room.layout_model.data.props:
		if int(original.required_hires) > hires: continue
		var item := {"id": original.id, "kind": original.kind, "ownerId": str(original.get("owner_id", "")), "essential": true, "grant": "test"}
		if original.id == "mira-workstation": item["roleKit"] = "mina_discovery_kit"
		if original.id == "theo-workstation": item["roleKit"] = "theo_campaign_kit"
		result.inventory.append(item)
		result.placements[original.id] = {"grid": original.grid.duplicate(), "facing": original.facing}
	var library: Dictionary = OfficeLayout._read_json(OfficeLayout.FURNISHING_CATALOG_PATH)
	for item: Dictionary in library.starter_decor:
		result.inventory.append({"id": item.id, "kind": item.kind, "ownerId": "", "essential": false, "grant": "starter"})
	return result

func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var room := TownRoom.new()
	world.add_child(room)
	check(room.load_layout(), "Authored room and furnishing profiles load")
	var state := state_for(room, 0)
	check(room.apply_furnishing_state(state), "Founder-only authoritative inventory applies")
	check(room.visible_prop_count() == 1, "Starter decorations stay stored until explicitly placed")
	state = state_for(room, 2)
	check(room.apply_furnishing_state(state), "Existing Mina and Theo gain their exact role kits")
	for side: String in OfficeLayout.FACINGS:
		for owner: String in ["mira", "theo"]:
			state.placements[owner + "-workstation"].facing = side
		check(room.apply_furnishing_state(state), side + " host/kit room validates")
		for owner: String in ["mira", "theo"]:
			var placement := room.placement_by_id(owner + "-workstation")
			var prop := room.prop_node(owner + "-workstation")
			var kit_count := 0
			for layer: Dictionary in placement.render_layers:
				if not str(layer.art).contains("furnishing-library"): continue
				kit_count += 1
				var sprite := prop.get_node(str(layer.name)) as Sprite2D
				check(sprite != null and sprite.texture.get_size() == Vector2(192, 224), owner + "/" + side + " keeps full native kit canvas")
				check(sprite.position == Vector2(0, -48) and sprite.scale == Vector2.ONE and sprite.rotation == 0.0 and not sprite.flip_h and not sprite.flip_v, owner + "/" + side + " shares original host anchor with no raster transform")
				check(sprite.z_index == prop.z_index + int(layer.z_offset), owner + "/" + side + " preserves authored separate layer depth")
			check(kit_count == 2 and placement.occupied.size() == 3, owner + "/" + side + " adds two distinct role layers and zero floor collision")
	var saved := room.placement_overrides.duplicate(true)
	var records := room.placeholder_records()
	for record: EmployeeRecord in records: record.desk_grid = Vector2i(2, 2)
	room.configure_employee_desks(records)
	check(room.placement_overrides == saved, "Legacy desk coordinates cannot replace durable placements")
	var invalid := state.duplicate(true)
	invalid.revision = 10
	invalid.placements.erase("mira-workstation")
	check(not room.apply_furnishing_state(invalid), "Required workstation cannot be stored")
	check(room.placement_overrides == saved and room.furnishing_revision == 0, "Invalid snapshot retains last valid layout and revision")
	invalid = state.duplicate(true)
	invalid.placements["decor-broadleaf_planter"] = {"grid": [1, 3], "facing": "north"}
	check(not room.apply_furnishing_state(invalid), "Planter canopy may not overlap architecture")
	for kind: String in ["broadleaf_planter", "task_floor_lamp", "rolling_storage_pedestal"]:
		check(room.layout_model.available_facings(kind).size() == 4, kind + " has four production-ready authored views")
		var id := "decor-" + kind
		for side: String in OfficeLayout.FACINGS:
			var candidate := room.layout_model.validate_candidate(id, Vector2i(23, 17), side, 2, saved)
			check(candidate.valid, kind + "/" + side + " can be placed from storage in the room")
			var next := state.duplicate(true)
			next.placements[id] = {"grid": [23, 17], "facing": side}
			check(room.apply_furnishing_state(next), kind + "/" + side + " projects into actual TownRoom")
			var prop := room.prop_node(id)
			check(prop != null and room.placement_by_id(id).occupied == [Vector2i(23, 17)], kind + "/" + side + " has exact one-cell floor collision")
			for child: Node in prop.get_children():
				if child is Sprite2D:
					check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, kind + "/" + side + " keeps native separate layers")
		check(room.apply_furnishing_state(state), kind + " returns to storage")
		check(room.prop_node(id) == null, kind + " storage removes scene/collision but not ownership")
	var old_seat := room.employee_workstation("mira").work_position as Vector2
	room.navigation.actors["mira"] = old_seat
	var moved := saved.duplicate(true)
	moved["mira-workstation"] = {"grid": [10, 6], "facing": "south"}
	check(not room.placement_actor_conflicts(moved).is_empty(), "Occupied workstation cannot be relocated out from under Mina")
	print("test_furnishing_projection: %d checks, %d failures" % [checks, failures.size()])
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
