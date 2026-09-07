extends SceneTree
## Native material comparison in the approved office, not a production layout.
const DESK := preload("res://tools/modular_desk_geometry.gd")
const OUTPUT := "res://tests/output/desk-material-room"
const MATERIALS := "res://tests/fixtures/furniture-calibration/materials"
var stage: Node2D
var ui: CanvasLayer

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func label(copy: String, at: Vector2, width: int) -> void:
	var panel := PanelContainer.new()
	panel.position = at
	panel.custom_minimum_size = Vector2(width, 38)
	panel.add_theme_stylebox_override("panel", CozyUI.paper())
	var text := Label.new()
	text.text = copy
	CozyUI.label(text, "meta")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text)
	ui.add_child(panel)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Material review needs a rendered backend.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	assert(room.load_layout())
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 30
	root.add_child(ui)
	label("NATIVE ROOM MATERIAL REVIEW · same geometry, two palette treatments", Vector2(200, 110), 736)
	for row: int in range(2):
		var suffix := "" if row == 0 else "-soft"
		var horizontal := load(MATERIALS.path_join("oak-horizontal-v1" + suffix + ".png")) as Texture2D
		var vertical := load(MATERIALS.path_join("oak-vertical-v1" + suffix + ".png")) as Texture2D
		for column: int in range(4):
			var desk := DESK.new()
			desk.position = Vector2(240 + column * 224, 288 + row * 232)
			desk.z_as_relative = false
			desk.z_index = roundi(desk.position.y)
			stage.add_child(desk)
			assert(desk.configure(DESK.DIRECTIONS[column], horizontal, vertical))
			label(DESK.DIRECTIONS[column].to_upper(), desk.position + Vector2(-80, 62), 160)
		label("Original five-color grain" if row == 0 else "Reduced three-color contrast", Vector2(330, 400 + row * 232), 476)
	var founder := Sprite2D.new()
	founder.texture = CharacterArt.locomotion_sheet("founder")
	founder.region_enabled = true
	founder.region_rect = CharacterArt.locomotion_region(&"front", 0)
	founder.position = Vector2(132, 460) + Vector2(0, -32)
	founder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	founder.z_index = 460
	stage.add_child(founder)
	for index: int in range(4): await process_frame
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	assert(screenshot.get_size() == Vector2i(1280, 720))
	assert(screenshot.save_png(OUTPUT.path_join("two-palettes-native.png")) == OK)
	var manifest := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"status": "material_comparison_not_runtime_approval", "worker": "disabled", "production_changed": false, "native_viewport": [1280, 720], "top_row": "original five-color palette", "bottom_row": "reduced three-color palette", "geometry": "modular_desk_geometry.gd", "pixel_scale": 1, "capture": "two-palettes-native.png"}, "\t"))
	print("Native material comparison captured.")
	stage.free()
	ui.free()
	await process_frame
	quit(0)
