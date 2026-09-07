extends SceneTree
## Developer-only native art comparison. Does not enable catalogue facings or
## assert that an unlayered source is ready for seated production use.
const OUTPUT := "res://tests/output/furniture-calibration"
const CANDIDATE := "res://tests/fixtures/furniture-calibration/desk-south-v2.png"
const CANVAS := Vector2(192, 224)
const PIVOT := Vector2(96, 160)

var stage: Node2D
var room: TownRoom
var annotation_layer: CanvasLayer

class FootprintGuide extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-48, -16, 96, 32), Color(0.75, 0.98, 0.5, 0.65), false, 1.0)
		draw_line(Vector2(-7, 0), Vector2(7, 0), Color.CYAN)
		draw_line(Vector2(0, -7), Vector2(0, 7), Color.CYAN)
		draw_line(Vector2(-48, 16), Vector2(48, 16), Color(1, 0.3, 0.08))

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func annotation(copy: String, point: Vector2, width: int) -> void:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, 36)
	panel.add_theme_stylebox_override("panel", CozyUI.paper())
	var label := Label.new()
	label.text = copy
	CozyUI.label(label, "meta")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	annotation_layer.add_child(panel)

func actor(character_id: String, foot: Vector2, direction: StringName = &"front") -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = CharacterArt.locomotion_sheet(character_id)
	sprite.region_enabled = true
	sprite.region_rect = CharacterArt.locomotion_region(direction, 0)
	# Match PlayerAvatar/EmployeeAvatar: opaque feet end near row72 within the
	#80px frame, so the production centered-frame origin is-32, not-40.
	sprite.position = foot + Vector2(0, -32)
	sprite.z_as_relative = false
	sprite.z_index = roundi(foot.y)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(sprite)
	return sprite

func capture(name_value: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	assert(screenshot.get_size() == Vector2i(1280, 720))
	assert(screenshot.save_png(OUTPUT.path_join(name_value + ".png")) == OK)
	print("Furniture calibration captured: " + name_value)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Furniture calibration requires the rendered Godot backend.")
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
	room.set_hire_count(2)
	await frames()
	var prop := room.prop_node("mira-workstation")
	assert(prop != null)
	for child: Node in prop.get_children():
		if child is Sprite2D: (child as Sprite2D).hide()
	var candidate := Sprite2D.new()
	candidate.texture = load(CANDIDATE) as Texture2D
	assert(candidate.texture.get_size() == CANVAS)
	candidate.position = CANVAS / 2.0 - PIVOT
	candidate.z_as_relative = false
	candidate.z_index = prop.z_index
	candidate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prop.add_child(candidate)
	actor("mira", prop.global_position + Vector2(-80, 16))
	actor("theo", room.grid_to_world_position(Vector2i(23, 9)))
	actor("founder", room.grid_to_world_position(Vector2i(8, 19)))
	annotation_layer = CanvasLayer.new()
	annotation_layer.layer = 20
	root.add_child(annotation_layer)
	annotation("NEW empty base · native review only", Vector2(188, 304), 288)
	annotation("CURRENT furnished desk", Vector2(550, 304), 224)
	annotation("Fixed camera · 32px floor grid · 48×80 actors · worker disabled", Vector2(300, 646), 564)
	await capture("desk-south-native")
	var guide := FootprintGuide.new()
	guide.position = prop.global_position
	guide.z_as_relative = false
	guide.z_index = 1500
	stage.add_child(guide)
	await capture("desk-south-footprint")
	var manifest := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({
		"status": "native_review_only_not_runtime_approved", "worker": "disabled",
		"candidate": CANDIDATE, "canvas_px": [192, 224], "floor_pivot_px": [96, 160],
		"contact_bottom_offset_px": 16, "source": "desk-south-v2.png",
		"captures": ["desk-south-native.png", "desk-south-footprint.png"],
		"seated_occlusion_tested": false, "directions_reviewed": ["south"]
	}, "\t"))
	stage.free()
	annotation_layer.free()
	await frames()
	quit(0)
