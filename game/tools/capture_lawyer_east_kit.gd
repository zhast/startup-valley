extends SceneTree
## Native overlay placement study. A diagnostic, never an employment feature.
const DESK := preload("res://tools/modular_desk_geometry.gd")
const FIX := "res://tests/fixtures/furniture-calibration/"
const OUTPUT := "res://tests/output/lawyer-kit-east/"
var stage: Node2D
var ui: CanvasLayer
var actors: Array[Sprite2D] = []
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func piece(path: String, region: Rect2, origin: Vector2, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = origin.round()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_as_relative = false
	sprite.z_index = depth
	stage.add_child(sprite)
	return sprite

func text(copy: String, point: Vector2, width: int) -> void:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, 42)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 6, 10, 6)))
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(label, "meta")
	panel.add_child(label)
	ui.add_child(panel)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Isolated room loads without GameMain or worker")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	text("EAST LEGAL KIT · independently drawn tools · compare actual mouse/folder placement", Vector2(150, 96), 980)
	text("Staged only · plain / intentional overlap control / separated mouse · no document-use animation", Vector2(130, 658), 1020)
	var horizontal := load(FIX + "materials/oak-horizontal-v1-soft.png") as Texture2D
	var vertical := load(FIX + "materials/oak-vertical-v1-soft.png") as Texture2D
	for row: int in range(2):
		var id := "mira" if row == 0 else "theo"
		var version := "v3" if row == 0 else "v4"
		for column: int in range(3):
			var anchor := Vector2(300 + column * 292, 280 + row * 245)
			var z := roundi(anchor.y)
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = z
			stage.add_child(desk)
			check(desk.configure("east", horizontal, vertical), "Exact east desk geometry")
			var work_foot := anchor + Vector2(-32, 0)
			var chair_foot := work_foot + Vector2(12, 0)
			piece(FIX + "chair-layers-v1/east-rear.png", Rect2(0, 0, 96, 160), chair_foot - Vector2(48, 112), z - 5)
			piece(FIX + "chair-layers-v1/east-front.png", Rect2(0, 0, 96, 160), chair_foot - Vector2(48, 112), z - 3)
			var actor_origin := chair_foot + Vector2(-24, -72 + (3 if id == "mira" else 4))
			var path := FIX + "characters/" + id + "-east-seated-" + version + ".png"
			actors.append(piece(path, Rect2(0, 52, 48, 28), actor_origin + Vector2(0, 52), z - 4))
			actors.append(piece(path, Rect2(0, 0, 48, 52), actor_origin, z + 2))
			piece(FIX + "kits/computer-east-v4-monitor.png", Rect2(0, 0, 192, 224), anchor - Vector2(96, 160), z + 3)
			piece(FIX + "kits/computer-east-v4-keyboard.png", Rect2(0, 0, 192, 224), anchor + Vector2(6, 0) - Vector2(96, 160), z + 1)
			var mouse_x := 20 if column == 2 else 6
			piece(FIX + "kits/computer-east-v4-mouse.png", Rect2(0, 0, 192, 224), anchor + Vector2(mouse_x, 0) - Vector2(96, 160), z + 1)
			if column > 0:
				for component: String in ["binders", "folder", "pen_cup"]:
					piece(FIX + "roles/lawyer-east-v4-" + component + ".png", Rect2(0, 0, 192, 224), anchor - Vector2(96, 160), z + 1)
			text(["Plain computer station", "Control · mouse under folder", "Candidate · separate mouse"][column], anchor + Vector2(-130, 55), 260)
			var top: Rect2i = desk.resolved.top
			check(top.encloses(Rect2i(-10, -77, 12, 20)), "Binder proposed contact footprint inside top")
			check(top.encloses(Rect2i(-15, -15, 19, 27)), "Complete flat folder inside top")
			check(top.encloses(Rect2i(7, -79, 6, 3)), "Cup proposed base inside top")
			var mouse_bounds := Rect2i(-15 + mouse_x, -11, 9, 6)
			check(top.encloses(mouse_bounds), "Mouse stays on top in every comparison")
			check(mouse_bounds.intersects(Rect2i(-15, -15, 19, 27)) == (column != 2), "Intended overlap control and separated candidate")
	var captures: Array[String] = []
	if DisplayServer.get_name() != "headless":
		for frame: int in range(6):
			for actor: Sprite2D in actors:
				var region := actor.region_rect
				region.position.x = frame * 48
				actor.region_rect = region
			for tick: int in range(3): await process_frame
			RenderingServer.force_draw(false)
			var screenshot := root.get_texture().get_image()
			check(screenshot.get_size() == Vector2i(1280, 720), "Native evidence size")
			var name_value := "frame%d.png" % frame
			check(screenshot.save_png(OUTPUT + name_value) == OK, "Save " + name_value)
			captures.append(name_value)
	var report := FileAccess.open(OUTPUT + ("headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "failures": failures, "status": "staged_not_approved", "captures": captures, "worker_disabled": true, "mouse_x_candidates": [6, 6, 20], "folder_bounds": [-15, -15, 19, 27], "actor_reach_caveat": "Existing Theo E keyboard edge contact remains unapproved", "binder_dimensions": [12, 32], "cup_dimensions": [6, 12]}, "\t"))
	stage.free()
	ui.free()
	print("lawyer_east: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
