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
		if original.id == "founder-workstation": item["roleKit"] = "founder_strategy_kit"
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
	var founder_desk := room.placement_by_id("founder-workstation")
	check(str(founder_desk.get("role_kit", "")) == "founder_strategy_kit", "Founder desk wears the strategy kit")
	check(str(founder_desk.get("decor_kit", "")) == "desk_lamp_kit", "Founder desk stacks the desk lamp kit")
	var founder_kit_layers := 0
	var founder_lamp_layers := 0
	for layer: Dictionary in founder_desk.render_layers:
		if str(layer.art).contains("founder_strategy_kit"): founder_kit_layers += 1
		if str(layer.art).contains("desk_lamp_kit"): founder_lamp_layers += 1
	check(founder_kit_layers == 2, "Founder strategy kit adds two native desk overlays")
	check(founder_lamp_layers == 2, "Desk lamp kit adds two native overlays after the strategy kit")
	var library_arts: Array[String] = []
	for layer: Dictionary in founder_desk.render_layers:
		var art := str(layer.art)
		if art.contains("furnishing-library"): library_arts.append(art)
	check(library_arts.size() == 4 and library_arts[0].contains("founder_strategy_kit") and library_arts[1].contains("founder_strategy_kit") and library_arts[2].contains("desk_lamp_kit") and library_arts[3].contains("desk_lamp_kit"), "Lamp overlays follow the strategy kit layers")
	state = state_for(room, 2)
	check(room.apply_furnishing_state(state), "Existing Mina and Theo gain their exact role kits")
	for side: String in OfficeLayout.FACINGS:
		for owner: String in ["founder", "mira", "theo"]:
			state.placements[owner + "-workstation"].facing = side
		check(room.apply_furnishing_state(state), side + " host/kit room validates")
		for owner: String in ["founder", "mira", "theo"]:
			var placement := room.placement_by_id(owner + "-workstation")
			var prop := room.prop_node(owner + "-workstation")
			var kit_count := 0
			var role_layers := 0
			var lamp_layers := 0
			for layer: Dictionary in placement.render_layers:
				if not str(layer.art).contains("furnishing-library"): continue
				kit_count += 1
				if str(layer.art).contains("desk_lamp_kit"): lamp_layers += 1
				else: role_layers += 1
				var sprite := prop.get_node(str(layer.name)) as Sprite2D
				check(sprite != null and sprite.texture.get_size() == Vector2(192, 224), owner + "/" + side + " keeps full native kit canvas")
				check(sprite.position == Vector2(0, -48) and sprite.scale == Vector2.ONE and sprite.rotation == 0.0 and not sprite.flip_h and not sprite.flip_v, owner + "/" + side + " shares original host anchor with no raster transform")
				check(sprite.z_index == prop.z_index + int(layer.z_offset), owner + "/" + side + " preserves authored separate layer depth")
			var expected_kits := 4 if owner == "founder" else 2
			var expected_lamps := 2 if owner == "founder" else 0
			check(kit_count == expected_kits and role_layers == 2 and lamp_layers == expected_lamps and placement.occupied.size() == 3, owner + "/" + side + " keeps " + str(expected_kits) + " furnishing-library kit layers and zero extra floor collision")
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
	for kind: String in ["broadleaf_planter", "task_floor_lamp", "coat_bag_stand", "rolling_storage_pedestal"]:
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
	# Two cells, so this stays out of the one-cell loop above. [23, 17] is free
	# for every facing: footprint, clearance, artwork, and standing headroom.
	var water_id := "decor-water_station"
	var water_grid := Vector2i(23, 17)
	var water_offsets := {
		"north": [Vector2i(1, 0), Vector2i(0, 0)],
		"east": [Vector2i(0, 1), Vector2i(0, 0)],
		"south": [Vector2i(-1, 0), Vector2i(0, 0)],
		"west": [Vector2i(0, -1), Vector2i(0, 0)],
	}
	check(room.layout_model.available_facings("water_station").size() == 4, "water_station has four production-ready authored views")
	for side: String in OfficeLayout.FACINGS:
		var candidate := room.layout_model.validate_candidate(water_id, water_grid, side, 2, saved)
		check(candidate.valid, "water_station/" + side + " can be placed from storage in the room")
		var next := state.duplicate(true)
		next.placements[water_id] = {"grid": [water_grid.x, water_grid.y], "facing": side}
		check(room.apply_furnishing_state(next), "water_station/" + side + " projects into actual TownRoom")
		var prop := room.prop_node(water_id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in water_offsets[side]:
			expected.append(water_grid + offset)
		var placement := room.placement_by_id(water_id)
		check(prop != null and placement.occupied == expected, "water_station/" + side + " occupies exactly its two footprint cells")
		var library_layers := 0
		for layer: Dictionary in placement.render_layers:
			if str(layer.art).contains("furnishing-library/water_station"):
				library_layers += 1
		check(library_layers == 3, "water_station/" + side + " has 3 furnishing-library layers")
		for child: Node in prop.get_children():
			if child is Sprite2D:
				check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, "water_station/" + side + " keeps native separate layers")
	check(room.apply_furnishing_state(state), "water_station returns to storage")
	check(room.prop_node(water_id) == null, "water_station storage removes scene/collision but not ownership")
	# Two cells, same footprint shape as water_station. That block returns the
	# station to storage first, so [23, 17] is free again for every cart facing.
	var cart_id := "decor-resource_cart"
	var cart_grid := Vector2i(23, 17)
	var cart_offsets := {
		"north": [Vector2i(1, 0), Vector2i(0, 0)],
		"east": [Vector2i(0, 1), Vector2i(0, 0)],
		"south": [Vector2i(-1, 0), Vector2i(0, 0)],
		"west": [Vector2i(0, -1), Vector2i(0, 0)],
	}
	check(room.layout_model.available_facings("resource_cart").size() == 4, "resource_cart has four production-ready authored views")
	for side: String in OfficeLayout.FACINGS:
		var candidate := room.layout_model.validate_candidate(cart_id, cart_grid, side, 2, saved)
		check(candidate.valid, "resource_cart/" + side + " can be placed from storage in the room")
		var next := state.duplicate(true)
		next.placements[cart_id] = {"grid": [cart_grid.x, cart_grid.y], "facing": side}
		check(room.apply_furnishing_state(next), "resource_cart/" + side + " projects into actual TownRoom")
		var prop := room.prop_node(cart_id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in cart_offsets[side]:
			expected.append(cart_grid + offset)
		var placement := room.placement_by_id(cart_id)
		check(prop != null and placement.occupied == expected, "resource_cart/" + side + " occupies exactly its two footprint cells")
		var library_layers := 0
		for layer: Dictionary in placement.render_layers:
			if str(layer.art).contains("furnishing-library/resource_cart"):
				library_layers += 1
		check(library_layers == 3, "resource_cart/" + side + " has 3 furnishing-library layers")
		for child: Node in prop.get_children():
			if child is Sprite2D:
				check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, "resource_cart/" + side + " keeps native separate layers")
	check(room.apply_furnishing_state(state), "resource_cart returns to storage")
	check(room.prop_node(cart_id) == null, "resource_cart storage removes scene/collision but not ownership")
	# Two cells, same footprint shape as resource_cart. That block returns the
	# cart to storage first, so [23, 17] is free again for every printer facing.
	var printer_id := "decor-printer_scanner_station"
	var printer_grid := Vector2i(23, 17)
	var printer_offsets := {
		"north": [Vector2i(1, 0), Vector2i(0, 0)],
		"east": [Vector2i(0, 1), Vector2i(0, 0)],
		"south": [Vector2i(-1, 0), Vector2i(0, 0)],
		"west": [Vector2i(0, -1), Vector2i(0, 0)],
	}
	check(room.layout_model.available_facings("printer_scanner_station").size() == 4, "printer_scanner_station has four production-ready authored views")
	for side: String in OfficeLayout.FACINGS:
		var candidate := room.layout_model.validate_candidate(printer_id, printer_grid, side, 2, saved)
		check(candidate.valid, "printer_scanner_station/" + side + " can be placed from storage in the room")
		var next := state.duplicate(true)
		next.placements[printer_id] = {"grid": [printer_grid.x, printer_grid.y], "facing": side}
		check(room.apply_furnishing_state(next), "printer_scanner_station/" + side + " projects into actual TownRoom")
		var prop := room.prop_node(printer_id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in printer_offsets[side]:
			expected.append(printer_grid + offset)
		var placement := room.placement_by_id(printer_id)
		check(prop != null and placement.occupied == expected, "printer_scanner_station/" + side + " occupies exactly its two footprint cells")
		var library_layers := 0
		for layer: Dictionary in placement.render_layers:
			if str(layer.art).contains("furnishing-library/printer_scanner_station"):
				library_layers += 1
		check(library_layers == 3, "printer_scanner_station/" + side + " has 3 furnishing-library layers")
		for child: Node in prop.get_children():
			if child is Sprite2D:
				check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, "printer_scanner_station/" + side + " keeps native separate layers")
	check(room.apply_furnishing_state(state), "printer_scanner_station returns to storage")
	check(room.prop_node(printer_id) == null, "printer_scanner_station storage removes scene/collision but not ownership")
	# Two cells, same footprint shape as printer_scanner_station. That block
	# returns the printer to storage first, so [23, 17] is free again for every
	# recycling sorter facing.
	var sorter_id := "decor-recycling_sorter"
	var sorter_grid := Vector2i(23, 17)
	var sorter_offsets := {
		"north": [Vector2i(1, 0), Vector2i(0, 0)],
		"east": [Vector2i(0, 1), Vector2i(0, 0)],
		"south": [Vector2i(-1, 0), Vector2i(0, 0)],
		"west": [Vector2i(0, -1), Vector2i(0, 0)],
	}
	check(room.layout_model.available_facings("recycling_sorter").size() == 4, "recycling_sorter has four production-ready authored views")
	for side: String in OfficeLayout.FACINGS:
		var candidate := room.layout_model.validate_candidate(sorter_id, sorter_grid, side, 2, saved)
		check(candidate.valid, "recycling_sorter/" + side + " can be placed from storage in the room")
		var next := state.duplicate(true)
		next.placements[sorter_id] = {"grid": [sorter_grid.x, sorter_grid.y], "facing": side}
		check(room.apply_furnishing_state(next), "recycling_sorter/" + side + " projects into actual TownRoom")
		var prop := room.prop_node(sorter_id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in sorter_offsets[side]:
			expected.append(sorter_grid + offset)
		var placement := room.placement_by_id(sorter_id)
		check(prop != null and placement.occupied == expected, "recycling_sorter/" + side + " occupies exactly its two footprint cells")
		var library_layers := 0
		for layer: Dictionary in placement.render_layers:
			if str(layer.art).contains("furnishing-library/recycling_sorter"):
				library_layers += 1
		check(library_layers == 3, "recycling_sorter/" + side + " has 3 furnishing-library layers")
		for child: Node in prop.get_children():
			if child is Sprite2D:
				check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, "recycling_sorter/" + side + " keeps native separate layers")
	check(room.apply_furnishing_state(state), "recycling_sorter returns to storage")
	check(room.prop_node(sorter_id) == null, "recycling_sorter storage removes scene/collision but not ownership")
	# Two cells, same footprint shape as recycling_sorter. That block returns
	# the sorter to storage first, so [23, 17] is free again for every supply
	# cabinet facing. The sprite is taller than the sorter; this pocket still
	# clears artwork and standing headroom without covering a work cell.
	var cabinet_id := "decor-tall_storage_cabinet"
	var cabinet_grid := Vector2i(23, 17)
	var cabinet_offsets := {
		"north": [Vector2i(1, 0), Vector2i(0, 0)],
		"east": [Vector2i(0, 1), Vector2i(0, 0)],
		"south": [Vector2i(-1, 0), Vector2i(0, 0)],
		"west": [Vector2i(0, -1), Vector2i(0, 0)],
	}
	check(room.layout_model.available_facings("tall_storage_cabinet").size() == 4, "tall_storage_cabinet has four production-ready authored views")
	for side: String in OfficeLayout.FACINGS:
		var candidate := room.layout_model.validate_candidate(cabinet_id, cabinet_grid, side, 2, saved)
		check(candidate.valid, "tall_storage_cabinet/" + side + " can be placed from storage in the room")
		var next := state.duplicate(true)
		next.placements[cabinet_id] = {"grid": [cabinet_grid.x, cabinet_grid.y], "facing": side}
		check(room.apply_furnishing_state(next), "tall_storage_cabinet/" + side + " projects into actual TownRoom")
		var prop := room.prop_node(cabinet_id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in cabinet_offsets[side]:
			expected.append(cabinet_grid + offset)
		var placement := room.placement_by_id(cabinet_id)
		check(prop != null and placement.occupied == expected, "tall_storage_cabinet/" + side + " occupies exactly its two footprint cells")
		var library_layers := 0
		for layer: Dictionary in placement.render_layers:
			if str(layer.art).contains("furnishing-library/tall_storage_cabinet"):
				library_layers += 1
		check(library_layers == 3, "tall_storage_cabinet/" + side + " has 3 furnishing-library layers")
		for child: Node in prop.get_children():
			if child is Sprite2D:
				check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, "tall_storage_cabinet/" + side + " keeps native separate layers")
	check(room.apply_furnishing_state(state), "tall_storage_cabinet returns to storage")
	check(room.prop_node(cabinet_id) == null, "tall_storage_cabinet storage removes scene/collision but not ownership")
	# Two cells, same footprint shape as tall_storage_cabinet. That block returns
	# the cabinet to storage first, so [23, 17] is free again for every server
	# cabinet facing. The sprite is tall; this pocket still clears artwork and
	# standing headroom without covering a work cell.
	var server_id := "decor-server_cabinet"
	var server_grid := Vector2i(23, 17)
	var server_offsets := {
		"north": [Vector2i(1, 0), Vector2i(0, 0)],
		"east": [Vector2i(0, 1), Vector2i(0, 0)],
		"south": [Vector2i(-1, 0), Vector2i(0, 0)],
		"west": [Vector2i(0, -1), Vector2i(0, 0)],
	}
	check(room.layout_model.available_facings("server_cabinet").size() == 4, "server_cabinet has four production-ready authored views")
	for side: String in OfficeLayout.FACINGS:
		var candidate := room.layout_model.validate_candidate(server_id, server_grid, side, 2, saved)
		check(candidate.valid, "server_cabinet/" + side + " can be placed from storage in the room")
		var next := state.duplicate(true)
		next.placements[server_id] = {"grid": [server_grid.x, server_grid.y], "facing": side}
		check(room.apply_furnishing_state(next), "server_cabinet/" + side + " projects into actual TownRoom")
		var prop := room.prop_node(server_id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in server_offsets[side]:
			expected.append(server_grid + offset)
		var placement := room.placement_by_id(server_id)
		check(prop != null and placement.occupied == expected, "server_cabinet/" + side + " occupies exactly its two footprint cells")
		var library_layers := 0
		for layer: Dictionary in placement.render_layers:
			if str(layer.art).contains("furnishing-library/server_cabinet"):
				library_layers += 1
		check(library_layers == 3, "server_cabinet/" + side + " has 3 furnishing-library layers")
		for child: Node in prop.get_children():
			if child is Sprite2D:
				check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, "server_cabinet/" + side + " keeps native separate layers")
	check(room.apply_furnishing_state(state), "server_cabinet returns to storage")
	check(room.prop_node(server_id) == null, "server_cabinet storage removes scene/collision but not ownership")
	# Two cells, mirrored from the server cabinet: the anchor is the east or
	# south end. That block returns the cabinet to storage first, so [23, 17]
	# is free again. Each facing uses the cells the server cabinet's opposite
	# facing already cleared here. The sprite is low (canvas [160, 160]).
	var table_id := "decor-low_coffee_table"
	var table_grid := Vector2i(23, 17)
	var table_offsets := {
		"north": [Vector2i(-1, 0), Vector2i(0, 0)],
		"east": [Vector2i(0, -1), Vector2i(0, 0)],
		"south": [Vector2i(0, 0), Vector2i(1, 0)],
		"west": [Vector2i(0, 0), Vector2i(0, 1)],
	}
	check(room.layout_model.available_facings("low_coffee_table").size() == 4, "low_coffee_table has four production-ready authored views")
	for side: String in OfficeLayout.FACINGS:
		var candidate := room.layout_model.validate_candidate(table_id, table_grid, side, 2, saved)
		check(candidate.valid, "low_coffee_table/" + side + " can be placed from storage in the room")
		var next := state.duplicate(true)
		next.placements[table_id] = {"grid": [table_grid.x, table_grid.y], "facing": side}
		check(room.apply_furnishing_state(next), "low_coffee_table/" + side + " projects into actual TownRoom")
		var prop := room.prop_node(table_id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in table_offsets[side]:
			expected.append(table_grid + offset)
		var placement := room.placement_by_id(table_id)
		check(prop != null and placement.occupied == expected, "low_coffee_table/" + side + " occupies exactly its two footprint cells")
		var library_layers := 0
		for layer: Dictionary in placement.render_layers:
			if str(layer.art).contains("furnishing-library/low_coffee_table"):
				library_layers += 1
		check(library_layers == 3, "low_coffee_table/" + side + " has 3 furnishing-library layers")
		for child: Node in prop.get_children():
			if child is Sprite2D:
				check(child.scale == Vector2.ONE and child.rotation == 0.0 and not child.flip_h and not child.flip_v, "low_coffee_table/" + side + " keeps native separate layers")
	check(room.apply_furnishing_state(state), "low_coffee_table returns to storage")
	check(room.prop_node(table_id) == null, "low_coffee_table storage removes scene/collision but not ownership")
	var old_seat := room.employee_workstation("mira").work_position as Vector2
	room.navigation.actors["mira"] = old_seat
	var moved := saved.duplicate(true)
	moved["mira-workstation"] = {"grid": [10, 6], "facing": "south"}
	check(not room.placement_actor_conflicts(moved).is_empty(), "Occupied workstation cannot be relocated out from under Mina")
	print("test_furnishing_projection: %d checks, %d failures" % [checks, failures.size()])
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
