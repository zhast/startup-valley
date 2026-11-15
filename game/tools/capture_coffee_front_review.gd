extends SceneTree

const OUTPUT := "res://tests/output/coffee-front-review"
var main: GameMain
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func settle() -> void:
	for index: int in range(8): await process_frame
	await RenderingServer.frame_post_draw

func capture(name: String, anchor: Vector2) -> void:
	await settle()
	var screen := root.get_texture().get_image()
	screen.save_png(OUTPUT.path_join(name + ".png"))
	var detail := screen.get_region(Rect2i(Vector2i(anchor) + Vector2i(-96, -128), Vector2i(192, 160)))
	detail.resize(768, 640, Image.INTERPOLATE_NEAREST)
	detail.save_png(OUTPUT.path_join(name + "-detail.png"))
	captures.append(name)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.unfocusable = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	main = load("res://world/main.tscn").instantiate() as GameMain
	root.add_child(main)
	await settle()
	main.set_process(false)
	main.day_clock.set_speed(0)
	main.player.set_physics_process(false)
	main.game_audio.set_volumes(0, 0)
	main.get_node("Interface").hide()
	main.room.set_hire_count(1)
	for employee: EmployeeAvatar in main._employees.values():
		employee.set_physics_process(false)
		employee.labels_suppressed = true
		employee.hide()
	for side: String in ["south", "north", "east", "west"]:
		if not main.room.set_placement_overrides({"coffee-station": {"grid": [4, 6], "facing": side}}):
			failures.append("Rejected unchanged coffee profile: " + side)
			continue
		var placement: Dictionary = main.room.placement_by_id("coffee-station")
		var anchor: Vector2 = placement.anchor
		main.player.position = anchor + Vector2(72, 8)
		main.player.z_index = int(main.player.position.y)
		main.player.face_direction(Vector2.DOWN)
		main.player.hide()
		var mina: EmployeeAvatar = main._employees.get("mira")
		if mina != null:
			mina.show()
			mina.position = anchor + Vector2(72, 8)
			mina.work_state = EmployeeAvatar.WorkState.IDLE
			mina._has_target = false
			mina._animation_elapsed = 0
			mina._facing = &"front"
			mina._update_character_frame()
			mina._label_layer.hide()
		await capture(side + "-scale", anchor)
		if side == "south":
			main.player.show()
			main.player.position = anchor + Vector2(0, 20)
			main.player.z_index = int(main.player.position.y)
			await capture(side + "-front", anchor)
			main.player.position = anchor + Vector2(0, -40)
			main.player.z_index = int(main.player.position.y)
			await capture(side + "-behind", anchor)
	var report := {"failures": failures, "captures": captures, "native_size": [1280, 720], "room": "actual GameMain and TownRoom production layers", "worker_disabled": true, "geometry_changed": false, "save_access": false}
	FileAccess.open(OUTPUT.path_join("capture-results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	main.game_audio.shutdown()
	main.free()
	await process_frame
	print("Coffee review: ", report)
	call_deferred("quit", 0 if failures.is_empty() else 1)
