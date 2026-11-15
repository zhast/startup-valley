extends "res://tests/test_map_review.gd"
## Actual room, collision and depth review for the three standalone families.
## Candidate mode overrides only this live model; normal mode uses runtime art.

var candidate_textures: Array[Texture2D] = []

func configure_candidates(room: TownRoom) -> void:
	if OS.get_environment("STARTUP_VALLEY_FURNITURE_CANDIDATE") != "1": return
	var profiles: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source/furniture-scale-v1/candidate-profiles.json"))
	check(room.layout_model.enable_calibration_preview(self), "Room candidate preview is scoped")
	for kind: String in profiles:
		var path: String = profiles[kind].preview_art
		var texture := ImageTexture.create_from_image(Image.load_from_file(path))
		texture.take_over_path(path)
		candidate_textures.append(texture)
		room.layout_model.catalog[kind].facing_profiles.south = profiles[kind].duplicate(true)
		check(room.layout_model.authorize_calibration_decorative_profile(kind, "south", self), kind + " candidate authorized only on room model")

func run() -> void:
	output = OS.get_environment("STARTUP_VALLEY_MAP_OUTPUT")
	if output.is_empty() or DisplayServer.get_name() == "headless":
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
	check(room.load_layout("res://data/office_layout_starter.json"), "Starter room loads")
	configure_candidates(room)
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../dev/map-catalogue/fixtures/first-project-furnishing.json"))
	check(room.apply_furnishing_state(fixture.furnishing), "Real first-project snapshot accepts the corrected café pair")
	room.set_hire_count(1)
	player = load("res://actors/player_avatar.tscn").instantiate() as PlayerAvatar
	surface.add_child(player)
	player.navigation = room.navigation
	player.movement_bounds = room.playable_bounds()
	player.position = Vector2(432, 496)
	check(room.navigation.position_is_safe(player.position, "founder"), "Chair rear crossing point is safe")
	await physics_frame
	await capture("starter-chair-behind")
	await cross_to(Vector2(432, 560), "starter-chair-front")
	await cross_to(Vector2(368, 496), "starter-table-behind")
	await cross_to(Vector2(368, 560), "starter-table-front")
	check(room.load_layout(), "Legacy full room loads")
	configure_candidates(room)
	var state: Dictionary = fixture.furnishing.duplicate(true)
	state.layoutId = "startup-office"
	state.placements = {}
	for prop: Dictionary in room.layout_model.data.props:
		if int(prop.get("required_hires", 0)) <= 1 and int(prop.get("required_office_level", 1)) <= 1:
			state.placements[prop.id] = {"grid": prop.grid, "facing": prop.facing}
	state.placements["decor-phone_booth"] = {"grid": [3, 18], "facing": "south"}
	state.placements["decor-cafe_table"] = {"grid": [5, 8], "facing": "south"}
	state.placements["decor-cafe_chair"] = {"grid": [7, 8], "facing": "south"}
	check(room.apply_furnishing_state(state), "Explicit old-owner full-room fixture preserves the booth anchor")
	player.navigation = room.navigation
	player.movement_bounds = room.playable_bounds()
	player.cancel_route()
	player.position = Vector2(112, 560)
	check(room.navigation.position_is_safe(player.position, "founder"), "Booth rear crossing point is safe")
	check(not room.navigation.position_is_safe(Vector2(80, 592), "founder"), "Widened booth blocks both occupied cells")
	await physics_frame
	await capture("full-office-booth-behind")
	await cross_to(Vector2(112, 624), "full-office-booth-front")
	var report := {"scope": "actual Godot room and navigation component evidence, not full demo acceptance", "candidate": OS.get_environment("STARTUP_VALLEY_FURNITURE_CANDIDATE") == "1", "checks": checks, "failures": failures, "captures": captures, "engine": Engine.get_version_info(), "display": DisplayServer.get_name()}
	var file := FileAccess.open(output.path_join("furniture-room-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("Cozy furniture: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
