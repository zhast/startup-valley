extends SceneTree
## Map-component evidence only. Uses real renderers and one retained production
## furnishing projection; fixture positioning is not an earned-gameplay claim.

var checks := 0
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var surface: SubViewport
var player: PlayerAvatar
var output: String

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func capture(label: String) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	var file := output.path_join(label + ".png")
	check(surface.get_texture().get_image().save_png(file) == OK, label + " capture saved")
	captures.append({"path": file, "player": [player.position.x, player.position.y], "pixels": [1280, 720]})

func cross_to(point: Vector2, label: String) -> void:
	check(player.move_to(point), label + " has a real navigation route")
	var deadline := Time.get_ticks_msec() + 10000
	while not player.route.is_empty() and Time.get_ticks_msec() < deadline:
		await physics_frame
	check(player.position.distance_to(point) < 3, label + " reached target around real collision")
	await capture(label)

func run() -> void:
	output = OS.get_environment("STARTUP_VALLEY_MAP_OUTPUT")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Map review requires native rendering and STARTUP_VALLEY_MAP_OUTPUT")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.unfocusable = true
	root.mouse_passthrough = true
	surface = SubViewport.new()
	surface.size = root.size
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	var room := TownRoom.new()
	surface.add_child(room)
	check(room.load_layout("res://data/office_layout_starter.json"), "Actual starter layout loads")
	var fixture_path := ProjectSettings.globalize_path("res://../dev/map-catalogue/fixtures/first-project-furnishing.json")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	check(room.apply_furnishing_state(fixture.furnishing), "Retained production worker furniture validates and renders")
	player = load("res://actors/player_avatar.tscn").instantiate() as PlayerAvatar
	surface.add_child(player)
	player.navigation = room.navigation
	player.movement_bounds = room.playable_bounds()
	player.position = Vector2(368, 336)
	check(room.navigation.position_is_safe(player.position, "founder"), "Starter desk rear point is safe")
	await physics_frame
	await capture("starter-behind-desk")
	await cross_to(Vector2(368, 400), "starter-in-front-of-desk")
	room.hide()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	room.navigation.process_mode = Node.PROCESS_MODE_DISABLED
	var courtyard := Courtyard.new()
	surface.add_child(courtyard)
	courtyard.set_active(true)
	player.cancel_route()
	player.navigation = courtyard.navigation
	player.movement_bounds = Courtyard.BOUNDS
	player.position = Vector2(720, 272)
	check(courtyard.navigation.position_is_safe(player.position, "founder"), "Courtyard planter rear point is safe")
	await physics_frame
	await capture("courtyard-behind-planter")
	await cross_to(Vector2(720, 368), "courtyard-in-front-of-planter")
	check(not courtyard.navigation.path(player.position, Courtyard.SPAWN, "founder").is_empty(), "Actual return path remains reachable")
	var report := {"scope": "native map component fixture; not final demo acceptance", "checks": checks, "failures": failures, "captures": captures, "engine": Engine.get_version_info(), "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "fixture_source": "dev/map-catalogue/fixtures/first-project-furnishing.json"}
	var file := FileAccess.open(output.path_join("depth-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	surface.queue_free()
	await process_frame
	print("Map review: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
