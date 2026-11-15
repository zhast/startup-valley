extends SceneTree
## Headless geometry/registration proof; visual approval belongs to browser review.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		print("TERRAIN_CHECK_FAILED " + message)
func check_planting_groups(terrain: VillageTerrain, label: String) -> void:
	var cells := terrain.boundary.get_used_cells()
	check(cells.size() >= 8 and cells.size() < 50, label + " uses sparse deliberate planting groups")
	var long_vertical_run := false
	for cell: Vector2i in cells:
		if terrain.boundary.get_cell_source_id(cell + Vector2i.DOWN) >= 0 and terrain.boundary.get_cell_source_id(cell + Vector2i.DOWN * 2) >= 0:
			long_vertical_run = true
	check(not long_vertical_run, label + " avoids repeated disconnected vertical shrub stamps")
func run() -> void:
	var room := TownRoom.new()
	root.add_child(room)
	check(room.load_layout("res://data/office_layout_starter.json"), "Starter room loads")
	var terrain := room.architecture.exterior_terrain
	check(terrain != null and terrain.ground is TileMapLayer, "Starter uses shared terrain cells")
	check(terrain.scale == Vector2.ONE and terrain.ground.tile_set.tile_size == Vector2i(32, 32), "Shared terrain keeps native scale and grid")
	check(room.architecture.exterior_art == null, "No monolithic background is rendered")
	check_planting_groups(terrain, "Studio yard")
	for y: int in range(21, 23):
		for x: int in range(15, 17):
			check(terrain.ground.get_cell_source_id(Vector2i(x, y)) == terrain._source_ids.paving, "Paving continues through the real threshold")
			check(room.architecture._entry_lane(Vector2i(x, y)), "Trim does not cut off the entrance apron")
	check(not room.architecture._entry_lane(Vector2i(14, 21)), "Adjacent wall remains intact")
	room.queue_free()
	await process_frame
	var court := Courtyard.new()
	root.add_child(court)
	court.set_active(true)
	check_planting_groups(court.terrain, "Courtyard")
	check(Courtyard.SPAWN == Vector2(496, 560) and Courtyard.THEO_POSITION == Vector2(624, 336) and Courtyard.THEO_APPROACH == Vector2(624, 384), "Saved story coordinates remain unchanged")
	check(Courtyard.BOUNDS == Rect2(96, 96, 800, 544), "Worker-authorized movement bounds remain unchanged")
	for target: Vector2 in [Vector2(144, 112), Courtyard.THEO_APPROACH, Vector2(720, 368), Courtyard.SPAWN]:
		check(court.navigation.position_is_safe(target, "founder"), "Saved/legal target remains on clear floor")
		check(not court.navigation.path(Courtyard.SPAWN, target, "founder").is_empty(), "Spawn reaches the preserved target")
	var decoration_count := 0
	for child: Node in court.get_children():
		if not child is Node2D or child.get_script() != null: continue
		var is_decoration := false
		for component: Node in child.get_children():
			if component is StaticBody2D: is_decoration = true
		if is_decoration:
			decoration_count += 1
			var position := (child as Node2D).position
			check(fposmod(position.x, 32) == 16 and fposmod(position.y, 32) == 16, "Props use shared cell-center anchors")
	check(decoration_count == 5, "Every authored courtyard prop is checked, including duplicate families")
	for cell: Vector2i in court.navigation._floor:
		check(court.terrain.boundary.get_cell_source_id(cell) == -1, "Hedge boundary never occupies a legal saved floor cell")
	court.queue_free()
	await process_frame
	var report_path := OS.get_environment("STARTUP_VALLEY_TERRAIN_REPORT")
	if not report_path.is_empty():
		var report := FileAccess.open(report_path, FileAccess.WRITE)
		check(report != null, "Terrain report opens")
		if report != null:
			report.store_string(JSON.stringify({"scope": "headless terrain geometry and registration; no visual approval", "checks": checks, "failures": failures, "engine": Engine.get_version_info(), "display": DisplayServer.get_name()}, "  "))
			report.close()
	print("Village terrain: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
