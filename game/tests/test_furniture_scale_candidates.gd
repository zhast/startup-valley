extends "res://tests/test_furniture_scale_audit.gd"
## Same engine/actor/profile renderer as the defect audit. Candidate overrides
## are authorized only on this test's OfficeLayout instance, never in production.

var candidate_profiles: Dictionary
var candidate_mode := false
var candidate_textures: Array[Texture2D] = []

func prop(kind: String, facing: String, grid: Vector2i, id: String) -> Dictionary:
	if candidate_mode and candidate_profiles.has(kind):
		room.layout_model.catalog[kind].facing_profiles.south = candidate_profiles[kind].duplicate(true)
		check(room.layout_model.authorize_calibration_decorative_profile(kind, "south", self), kind + " scoped preview authorization")
	return super.prop(kind, facing, grid, id)

func run() -> void:
	output = OS.get_environment("STARTUP_VALLEY_SCALE_OUTPUT")
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
	board = Board.new()
	board.footer = "Bottom: candidate standalone furniture; production workstation unchanged. Same actors and ground planes in both rows."
	board.z_index = -1000
	surface.add_child(board)
	room = TownRoom.new()
	surface.add_child(room)
	room.layout_model = OfficeLayout.new()
	check(room.layout_model.load_files(), "Actual catalogs load")
	check(room.layout_model.enable_calibration_preview(self), "Candidate scope starts")
	candidate_profiles = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source/furniture-scale-v1/candidate-profiles.json"))
	# Sources are deliberately .gdignore'd. Cache only these raw candidate images
	# for this fixture's actual TownRoom layer renderer; no runtime import needed.
	for profile: Dictionary in candidate_profiles.values():
		var path: String = profile.preview_art
		var texture := ImageTexture.create_from_image(Image.load_from_file(path))
		texture.take_over_path(path)
		candidate_textures.append(texture)
	for row: int in [0, 1]:
		candidate_mode = row == 1
		var y := 8 if row == 0 else 18
		var ground := y * 32 + 16
		actor_reference("founder", Vector2(80, ground))
		actor_reference("mira", Vector2(144, ground))
		var desk := prop("desk", "south", Vector2i(9, y), "desk-" + str(row))
		label("Current workstation", desk.anchor)
		for entry: Array in [["cafe_chair", 15, "Café chair"], ["cafe_table", 20, "Café table"], ["phone_booth", 28, "Quiet call nook"]]:
			var value := prop(entry[0], "south", Vector2i(entry[1], y), entry[0] + "-" + str(row))
			label(("Candidate " if candidate_mode else "Current ") + entry[2], value.anchor, Vector2(-55, 76))
		actor_reference("founder", Vector2(1040, ground))
	board.queue_redraw()
	await create_timer(0.4).timeout
	RenderingServer.force_draw(false)
	check(surface.get_texture().get_image().save_png(output.path_join("candidate-comparison.png")) == OK, "Same-scale native before/after saved")
	actor_reference("founder", Vector2(896, 608))
	label("Door-plane reference only", Vector2(896, 608), Vector2(-80, 96))
	board.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	check(surface.get_texture().get_image().save_png(output.path_join("candidate-opening.png")) == OK, "Same-scale doorway reference saved")
	var report := {"status": "candidate_component_comparison_not_admission", "engine": Engine.get_version_info(), "checks": checks, "failures": failures, "facts": facts}
	var file := FileAccess.open(output.path_join("candidate-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("Furniture candidate comparison: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
