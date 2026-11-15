extends SceneTree
## Rendered geometry fixtures, not earned progression. Integrated journey tests
## separately reach these visitors through production input and worker saves.

var checks := 0
var failures: Array[String] = []
var main: GameMain
var surface: SubViewport

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func show_hover(hover: Dictionary, obstacles: Array[Rect2]) -> Rect2:
	var details := main._station_hover_details(hover)
	main._update_hover_highlight(hover)
	main.founder_hud.update_station_hover(details.id, details.caption, details.bounds, true, obstacles)
	return main.founder_hud.station_hover_rect()

func verify_hover(id: String, target: Node2D, approach: Vector2, obstacles: Array[Rect2]) -> void:
	var hover := {"id": id, "kind": "story", "point": approach}
	var expected: Rect2 = target.painted_bounds()
	var details := main._station_hover_details(hover)
	check(details.bounds == expected, id + " uses actual painted target bounds")
	hover.point += Vector2(96, 64)
	check(main._station_hover_details(hover).bounds == expected, id + " bounds never follow navigation approach")
	hover.point = approach
	var painted := show_hover(hover, obstacles)
	check(painted.has_area(), id + " has a visible actionable callout")
	check(not painted.intersects(expected), id + " paper and pointer clear target and nameplate")
	check(Rect2(18, 82, FounderHud.PLAYFIELD_RIGHT - 36, 620).encloses(painted), id + " callout stays inside playfield")
	for obstacle: Rect2 in obstacles:
		check(not painted.intersects(obstacle), id + " clears protected content")
	check(hover.point == approach, id + " leaves navigation approach unchanged")
	await process_frame
	RenderingServer.force_draw(false)
	var output := OS.get_environment("STARTUP_VALLEY_HOVER_OUTPUT")
	if not output.is_empty() and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(output)
		check(surface.get_texture().get_image().save_png(output.path_join(id + ".png")) == OK, id + " native capture saved")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.unfocusable = true
	root.mouse_passthrough = true
	surface = SubViewport.new()
	surface.size = root.size
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	main = load("res://world/main.tscn").instantiate() as GameMain
	surface.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main._spawn_employees([])
	main._journey = {"company": {}, "candidates": [{"id": "mira", "name": "Mina", "hired": false, "available": true, "costCents": 0}], "tycoon": {}, "story": {"location": "office", "courtyardUnlocked": true}}
	main._apply_story_location(true)
	main.company_panel.hide()
	main.founder_hud.set_story_goal(StoryMoments.goal(main._journey))
	await process_frame
	var office_obstacles := main._world_ui_obstacles()
	office_obstacles.append(WorldCalloutSkin.actor_rect(main.player.position))
	await verify_hover("arrival-mina", main.arrival_guest, main.arrival_guest.position + Vector2(0, 32), office_obstacles)
	await verify_hover("courtyard-exit", main.courtyard_sign, main.room.grid_to_world_position(main.room.player_spawn), office_obstacles)
	main._journey.story.location = "courtyard"
	main._journey.player = {"x": Courtyard.SPAWN.x, "y": Courtyard.SPAWN.y}
	main._apply_story_location(true)
	main.founder_hud.set_story_goal(StoryMoments.goal(main._journey))
	await process_frame
	var outside_obstacles: Array[Rect2] = [main.clock_panel.get_global_rect(), WorldCalloutSkin.actor_rect(main.player.position), main.courtyard.guest.painted_bounds(), main.courtyard.return_sign.painted_bounds(), main.founder_hud.next_step_rect()]
	# Negative control recreates the former approach-based box. It must expose
	# the reported head/nameplate overlap, so this catches the causal regression.
	var legacy_box := Rect2(Courtyard.THEO_APPROACH + Vector2(-24, -80), Vector2(48, 80))
	main.founder_hud.update_station_hover("courtyard-theo", "Talk with Theo · E", legacy_box, true, [])
	check(main.founder_hud.station_hover_rect().intersects(main.courtyard.guest.painted_bounds()), "Legacy approach box reproduces Theo head/nameplate overlap")
	await verify_hover("courtyard-theo", main.courtyard.guest, Courtyard.THEO_APPROACH, outside_obstacles)
	await verify_hover("office-return", main.courtyard.return_sign, Courtyard.SPAWN, outside_obstacles)
	check(main.courtyard.interaction_at(main.courtyard.guest.position + Vector2(0, -82)).point == Courtyard.THEO_APPROACH, "Theo hit still navigates to the established approach")
	check(main.courtyard.interaction_at(main.courtyard.return_sign.position).point == Courtyard.SPAWN, "Return sign still navigates to the established approach")
	main.game_audio.shutdown()
	main.free()
	surface.free()
	await process_frame
	print("Story hover: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
