extends SceneTree
## Native candidate-art showroom. These manually posed review sprites do not
## bypass production's reviewed-art/actor capability gate or alter saved layouts.
const OUTPUT := "res://tests/output/furniture-rotations"
const FIXTURES := "res://tests/fixtures/furniture-calibration"
const CANVAS := Vector2(192, 224)
const PIVOT := Vector2(96, 160)
const DIRECTIONS: Array[String] = ["north", "east", "south", "west"]
const FILES: Array[String] = ["desk-north-v2.png", "desk-east-v3.png", "desk-south-v2.png", "desk-west-v3.png"]
const ANCHORS: Array[Vector2] = [Vector2(240, 304), Vector2(464, 304), Vector2(688, 304), Vector2(912, 304)]
const APPROACH: Array[Vector2] = [Vector2(0, 32), Vector2(-32, 0), Vector2(0, -32), Vector2(32, 0)]

var stage: Node2D
var room: TownRoom
var layer: CanvasLayer
var captures: Array[String] = []

class FloorGuide extends Node2D:
	var side := false
	func _draw() -> void:
		var footprint := Rect2(-16, -48, 32, 96) if side else Rect2(-48, -16, 96, 32)
		draw_rect(footprint, Color(0.75, 0.98, 0.5), false)
		draw_line(Vector2(-6, 0), Vector2(6, 0), Color.CYAN)
		draw_line(Vector2(0, -6), Vector2(0, 6), Color.CYAN)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func label(copy: String, point: Vector2, width: int) -> void:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, 40)
	panel.add_theme_stylebox_override("panel", CozyUI.paper())
	var text := Label.new()
	text.text = copy
	CozyUI.label(text, "meta")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text)
	layer.add_child(panel)

func render_sprite(texture: Texture2D, region: Rect2, center: Vector2, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = center.round()
	sprite.z_as_relative = false
	sprite.z_index = depth
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(sprite)
	return sprite

func capture(name_value: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	assert(screenshot.get_size() == Vector2i(1280, 720))
	assert(screenshot.save_png(OUTPUT.path_join(name_value + ".png")) == OK)
	captures.append(name_value + ".png")
	print("Furniture rotation art review: " + name_value)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rotation art review requires a rendered backend.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	stage = Node2D.new()
	root.add_child(stage)
	room = load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	assert(room.load_layout())
	room.set_hire_count(0)
	layer = CanvasLayer.new()
	layer.layer = 20
	root.add_child(layer)
	label("DIRECTIONAL DESK CALIBRATION · candidate art, not production approval", Vector2(272, 110), 608)
	for index: int in range(4):
		var texture := load(FIXTURES.path_join(FILES[index])) as Texture2D
		assert(texture != null and texture.get_size() == CANVAS)
		render_sprite(texture, Rect2(Vector2.ZERO, CANVAS), ANCHORS[index] + CANVAS / 2.0 - PIVOT, roundi(ANCHORS[index].y))
		label(DIRECTIONS[index].to_upper(), Vector2(ANCHORS[index].x - 96, 386), 192)
	label("Current furnished south desk", Vector2(144, 596), 256)
	label("Same floor pivot · unit scale · independently drawn views · no bitmap rotation", Vector2(450, 626), 636)
	await capture("four-desks-native")
	var guides: Array[Node2D] = []
	for index: int in range(4):
		var guide := FloorGuide.new()
		guide.side = index % 2 == 1
		guide.position = ANCHORS[index]
		guide.z_as_relative = false
		guide.z_index = 1200
		stage.add_child(guide)
		guides.append(guide)
	await capture("four-desks-floor-pivots")
	for guide: Node2D in guides: guide.hide()
	# Standing people are actual production frame/offset references. They show
	# scale and intended approach; no claim of seated furniture contact is made.
	var view_names: Array[StringName] = [&"back", &"right", &"front", &"left"]
	for index: int in range(4):
		var foot := ANCHORS[index] + APPROACH[index] * 2.0
		render_sprite(CharacterArt.locomotion_sheet("mira"), CharacterArt.locomotion_region(view_names[index], 0), foot + Vector2(0, -32), roundi(foot.y))
	await capture("four-desks-standing-approach")
	var manifest := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({
		"status": "candidate_art_only_not_runtime_approved", "worker": "disabled",
		"captures": captures, "directions": DIRECTIONS, "native_canvas_px": [192, 224],
		"footprint_pivot_px": [96, 160], "frame_center_offset_px": [0, -32],
		"candidate_files": FILES, "production_catalog_changed": false,
		"chair_seated_contact_tested": false, "production_facing_capability": "south_only"
	}, "\t"))
	stage.free()
	layer.free()
	await frames()
	quit(0)
