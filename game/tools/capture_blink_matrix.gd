extends SceneTree
## Native renderer contact sheets of the exact runtime frame registry.
## Supplementary art inspection; not a simulation or earned progression test.
var surface: SubViewport
var board: Node2D
var output := ""

func _initialize() -> void:
	call_deferred("run")

func cell(texture: Texture2D, region: Rect2, column: int, row: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.scale = Vector2(2, 2)
	sprite.position = Vector2(100 + column * 100, 32 + row * 168)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board.add_child(sprite)

func label(value: String, y: float) -> void:
	var text := Label.new()
	text.text = value
	text.position = Vector2(4, y)
	text.add_theme_font_override("font", GameFonts.BOLD)
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color("30271c"))
	board.add_child(text)

func capture(name_value: String) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	var status := surface.get_texture().get_image().save_png(output.path_join(name_value + ".png"))
	if status != OK: push_error("Capture failed: " + name_value)
	for child: Node in board.get_children(): child.queue_free()
	await process_frame

func run() -> void:
	output = OS.get_environment("STARTUP_VALLEY_BLINK_OUTPUT")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Set STARTUP_VALLEY_BLINK_OUTPUT and use native renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(900, 720)
	root.unfocusable = true
	root.mouse_passthrough = true
	surface = SubViewport.new()
	surface.size = root.size
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	surface.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("bcb7a5"))
	root.add_child(surface)
	board = Node2D.new()
	surface.add_child(board)
	var directions: Array[StringName] = [&"front", &"back", &"left", &"right"]
	for id: String in ["founder", "mira", "theo", "creative"]:
		label(id + " · idle open / closed · walk1/2/3/4 · native2×", 4)
		for row: int in range(4):
			label(str(directions[row]), 80 + row * 168)
			for frame: int in range(6): cell(CharacterArt.locomotion_sheet(id), CharacterArt.locomotion_region(directions[row], frame), frame, row)
		await capture(id + "-locomotion")
	for id: String in ["mira", "theo"]:
		for pose_set: String in ["seated-typing", "research", "legacy-work"]:
			label(id + " · " + pose_set + " · exact runtime registry · native2×", 4)
			for row: int in range(4):
				var facing: String = ["south", "north", "west", "east"][row]
				label(["type/approve", "read/think", "carry F/B", "carry L/R"][row] if pose_set == "legacy-work" else facing, 80 + row * 168)
				for frame: int in range(8 if pose_set == "legacy-work" else 4 if pose_set == "research" else 6):
					if pose_set == "legacy-work":
						cell(CharacterArt.work_sheet(id), CharacterArt.work_region(row, frame), frame, row)
					else:
						var pose := "research" if pose_set == "research" else "seated" if frame < 2 else "typing"
						var phase := frame - 2 if pose == "typing" else frame
						var art := CharacterArt.work_pose_frame(id, CharacterArt.REVIEWED_WORKSTATION_POSE_SET, facing, pose, phase)
						cell(art.texture, art.region, frame, row)
			await capture(id + "-" + pose_set)
	print("Blink matrix: 10 native sheets,240 exact runtime cells")
	surface.free()
	await process_frame
	quit()
