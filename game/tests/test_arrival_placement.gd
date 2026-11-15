extends SceneTree
## Geometry fixtures only: real room/profile rendering, no earned progress.

var checks := 0
var failures: Array[String] = []
var main: GameMain

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func projection(path: String, compact: bool) -> Dictionary:
	var data: Dictionary = OfficeLayout._read_json(path)
	var state := {"version": 1, "layoutId": data.id, "revision": 1, "inventory": [], "placements": {}, "recovery": ""}
	for prop: Dictionary in data.props:
		if int(prop.required_hires) > 0 or int(prop.get("required_office_level", 1)) > 1: continue
		state.inventory.append({"id": prop.id, "kind": prop.kind, "ownerId": prop.get("owner_id", ""), "essential": true, "grant": "test"})
		state.placements[prop.id] = {"grid": prop.grid, "facing": prop.facing}
	for kind: String in ["cafe_table", "cafe_chair"]:
		var id := "decor-" + kind
		var x := (11 if kind == "cafe_table" else 13) if compact else (5 if kind == "cafe_table" else 7)
		state.inventory.append({"id": id, "kind": kind, "ownerId": "", "essential": false, "grant": "test"})
		state.placements[id] = {"grid": [x, 16 if compact else 8], "facing": "south"}
	return state

func validate_arrival(label: String) -> void:
	var point := main.arrival_guest.position
	var body := Rect2(point + Vector2(-24, -72), Vector2(48, 80))
	check(main.arrival_guest.visible, label + " visitor remains visible")
	check(main.room.navigation.walkable(main.room.navigation.cell_at(point)), label + " feet are on walkable floor")
	for placement: Dictionary in main.room.resolved_placements:
		var painted: Rect2 = placement.world_visual_bounds
		painted.position += main.room.global_position
		check(not body.intersects(painted), label + " body clears " + str(placement.id))
	var route := main.room.navigation.path(main.room.grid_to_world_position(main.room.player_spawn), point + Vector2(0, 32), "founder")
	check(not route.is_empty() and route[-1].distance_to(point + Vector2(0, 32)) < 1, label + " invitation has a reachable approach")
	main.player.position = point + Vector2(32, 0)
	main._sync_story_visitors()
	check(main.arrival_guest.position == point, label + " player movement does not relocate visitor")

func run() -> void:
	root.size = Vector2i(1280, 720)
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	main.set_process(false)
	main._spawn_employees([])
	main._journey = {"candidates": [{"id": "mira", "hired": false}]}
	for compact: bool in [true, false]:
		var path := "res://data/office_layout_starter.json" if compact else "res://data/office_layout.json"
		var state := projection(path, compact)
		var label := "compact" if compact else "legacy"
		check(main.room.apply_furnishing_state(state), label + " real furnishing projection applies")
		main._sync_story_visitors()
		validate_arrival(label)
		var original := main.arrival_guest.position
		var grid := main.room.navigation.cell_at(original)
		state.placements["decor-cafe_chair"].grid = [grid.x, grid.y - 1]
		state.revision += 1
		check(main.room.apply_furnishing_state(state), label + " furniture edit can overlap preferred arrival silhouette")
		check(main.arrival_guest.position != original, label + " placement callback recomputes arrival point")
		validate_arrival(label + " after edit")
	main.game_audio.shutdown()
	main.free()
	await process_frame
	print("Arrival placement: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
