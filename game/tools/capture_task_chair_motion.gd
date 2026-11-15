extends "res://tests/test_seated_chair_composition.gd"
## Native production chair evidence, with real navigation and seat handoff.
## A bounded fixture drives normal actor methods; this is not input-playtest QA.
var motion: Array[Dictionary] = []

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Chair motion capture requires a native renderer")
		quit(1)
		return
	capture_enabled = true
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.unfocusable = true
	root.mouse_passthrough = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await frames()
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.game_audio.set_volumes(0, 0)
	main.player.set_physics_process(false)
	main.player.hide()
	main.get_node("Interface").hide()
	for actor: EmployeeAvatar in main._employees.values():
		actor.set_physics_process(false)
		actor.hide()
		actor.labels_suppressed = true
		actor._label_layer.hide()
	for facing: String in ["north", "south", "east", "west"]:
		check(main.room.set_placement_overrides({"mira-workstation": {"grid": [10, 8], "facing": facing}, "theo-workstation": {"grid": [20, 8], "facing": facing}}), "Motion fixture keeps production placement " + facing)
		var outward: Vector2 = {"north": Vector2.DOWN, "south": Vector2.UP, "east": Vector2.LEFT, "west": Vector2.RIGHT}[facing]
		for id: String in ["mira", "theo"]:
			var actor := main.get_employee(id)
			actor.show()
			actor.world_paused = false
			pose(actor, true, 0)
			var target := main.room.navigation.safe_position(actor.desk_position + outward * 64, id)
			actor.walk_to(target, EmployeeAvatar.WorkState.WANDERING, EmployeeAvatar.WorkState.IDLE)
		await sample_phase(facing, "exit")
		for id: String in ["mira", "theo"]:
			var actor := main.get_employee(id)
			check(not actor._uses_seated_visual(), id + " leaves the seated layers " + facing)
			actor.walk_to(actor.desk_position, EmployeeAvatar.WorkState.WALKING_TO_DESK, EmployeeAvatar.WorkState.SITTING)
		await sample_phase(facing, "entry")
		for id: String in ["mira", "theo"]:
			var actor := main.get_employee(id)
			check(actor._uses_seated_visual() and not actor._seat_transition_active, id + " settles in the actual seat " + facing)
			check(actor.position.distance_to(actor.desk_position) < 1, id + " reaches the actual work cell " + facing)
	var report := {"checks": checks, "failures": failures, "samples": motion, "scope": "native production assembly, manually stepped normal navigation and handoff"}
	FileAccess.open(OUTPUT.path_join("motion-results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	main.free()
	await process_frame
	print("Task chair motion: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func sample_phase(facing: String, phase: String) -> void:
	for tick: int in range(75):
		for id: String in ["mira", "theo"]:
			var actor := main.get_employee(id)
			var before := actor.position
			actor._physics_process(1.0 / 60.0)
			check(actor.position.distance_to(before) < 4, id + " physical route advances without teleport")
			motion.append({"facing": facing, "phase": phase, "tick": tick, "id": id, "position": [actor.position.x, actor.position.y], "seat_offset": [actor.seated_render_offset().x, actor.seated_render_offset().y], "seated": actor._uses_seated_visual()})
		if tick in [0, 4, 24, 44, 74]: await capture(facing, phase + "-" + str(tick))
