extends SceneTree
## Read-only staged-art socket comparison. No production approval or save access.
const OUTPUT := "res://tests/output/north-seating"
const FIXTURES := "res://tests/fixtures/furniture-calibration"
const OFFSETS: Array[int] = [-8, -12, -16]
const IDS: Array[String] = ["mira", "theo"]
var stage: Node2D
var layer: CanvasLayer
var actors: Array[Sprite2D] = []
var captures: Array[String] = []
var output_path := OUTPUT

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func label(copy: String, point: Vector2, width: int) -> void:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, 36)
	panel.add_theme_stylebox_override("panel", CozyUI.paper())
	var text := Label.new()
	text.text = copy
	CozyUI.label(text, "meta")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text)
	layer.add_child(panel)

func sprite(path: String, canvas: Vector2, pivot: Vector2, at: Vector2, depth: int) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = load(path) as Texture2D
	assert(result.texture != null)
	result.region_enabled = true
	result.region_rect = Rect2(Vector2.ZERO, canvas)
	result.position = (at + canvas / 2.0 - pivot).round()
	result.z_as_relative = false
	result.z_index = depth
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(result)
	return result

func capture(name_value: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	assert(screenshot.get_size() == Vector2i(1280, 720))
	assert(screenshot.save_png(output_path.path_join(name_value + ".png")) == OK)
	captures.append(name_value + ".png")
	print("North seating candidate: " + name_value)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native seating review requires a rendered backend.")
		quit(1)
		return
	if "--computer" in OS.get_cmdline_user_args(): output_path = OUTPUT.path_join("with-computer")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	assert(room.load_layout())
	room.set_hire_count(0)
	# Remove the unrelated starter prop visually, retaining approved room art.
	room.get_node("Props").hide()
	layer = CanvasLayer.new()
	layer.layer = 20
	root.add_child(layer)
	label("NORTH SOCKET STUDY · candidate art · same physical work cell, varied render offset", Vector2(220, 110), 784)
	for row: int in range(2):
		for column: int in range(3):
			var anchor := Vector2(280 + column * 304, 272 + row * 224)
			var physical_foot := anchor + Vector2(0, 32)
			sprite(FIXTURES.path_join("desk-north-v2.png"), Vector2(192, 224), Vector2(96, 160), anchor, roundi(anchor.y))
			if "--computer" in OS.get_cmdline_user_args():
				sprite(FIXTURES.path_join("kits/computer-north-v2.png"), Vector2(192, 224), Vector2(96, 160), anchor, roundi(anchor.y + 1))
			var actor := sprite(FIXTURES.path_join("characters/" + IDS[row] + "-north-seated-v2.png"), Vector2(48, 80), Vector2(24, 72), physical_foot + Vector2(0, OFFSETS[column]), roundi(physical_foot.y))
			actors.append(actor)
			sprite(FIXTURES.path_join("chair-north-v1.png"), Vector2(96, 160), Vector2(48, 112), physical_foot, roundi(physical_foot.y + 1))
			label(("Mina" if row == 0 else "Theo") + " · render Y " + str(OFFSETS[column]), anchor + Vector2(-112, 80), 224)
	await capture("idle-frame0")
	for frame: int in range(1, 6):
		for actor: Sprite2D in actors: actor.region_rect.position.x = frame * 48
		await capture("pose-frame" + str(frame))
	# A fixed-FPS movie includes the idle pair, transition, typing loop and return.
	for tick: int in range(180):
		var frame := (tick / 15) % 2 if tick < 60 or tick >= 150 else 2 + ((tick - 60) / 5) % 4
		for actor: Sprite2D in actors: actor.region_rect.position.x = frame * 48
		await RenderingServer.frame_post_draw
	var manifest := FileAccess.open(output_path.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({
		"status": "candidate_socket_study", "worker": "disabled", "captures": captures,
		"physical_work_cell": [0, 1], "render_y_offsets": OFFSETS,
		"desk_pivot": [96, 160], "chair_pivot": [48, 112], "actor_pivot": [24, 72],
		"chair_depth": "physical foot + 1", "production_changed": false,
		"computer_kit": "--computer" in OS.get_cmdline_user_args(),
		"movie_sequence_frames": 180, "movie_sequence": "idle pair, typing loop, idle pair"
	}, "\t"))
	stage.free()
	layer.free()
	await frames()
	quit(0)
