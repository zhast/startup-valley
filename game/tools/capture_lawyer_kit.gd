extends SceneTree
## Dev-only material/placement comparison. No lawyer employee or worker exists.
const DESK := preload("res://tools/modular_desk_geometry.gd")
const FIX := "res://tests/fixtures/furniture-calibration/"
const OUTPUT := "res://tests/output/lawyer-kit-north/"
var stage: Node2D
var ui: CanvasLayer
var actors: Array[Sprite2D] = []
var regions: Array[Rect2] = []
var panels: Array[PanelContainer] = []
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

func piece(path: String, canvas: Vector2, pivot: Vector2, foot: Vector2, depth: int) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = load(path) as Texture2D
	result.region_enabled = true
	result.region_rect = Rect2(Vector2.ZERO, canvas)
	result.centered = false
	result.position = (foot - pivot).round()
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.z_as_relative = false
	result.z_index = depth
	stage.add_child(result)
	return result

func caption(copy: String, point: Vector2, width: int) -> void:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, 42)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 6, 10, 6)))
	var text := Label.new()
	text.text = copy
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(text, "meta")
	panel.add_child(text)
	ui.add_child(panel)
	panels.append(panel)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Existing architecture loads without GameMain")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	caption("LEGAL TOOLKIT · separate binders, checklist and pen cup · native north-view comparison", Vector2(150, 96), 980)
	caption("Staged art only · Mina and Theo provide scale references, not new legal-service capabilities", Vector2(150, 658), 980)
	var horizontal := load(FIX + "materials/oak-horizontal-v1-soft.png") as Texture2D
	var vertical := load(FIX + "materials/oak-vertical-v1-soft.png") as Texture2D
	for component: String in ["binders", "folder", "pen_cup"]:
		var original := Image.load_from_file(FIX + "roles/lawyer-north-v3-" + component + ".png")
		var recolored := Image.load_from_file(FIX + "roles/lawyer-north-v3-" + component + "-brand.png")
		check(original.get_size() == Vector2i(192, 224) and recolored.get_size() == original.get_size(), "Shared native role canvas")
		var alpha_identical := true
		for y: int in range(224):
			for x: int in range(192):
				if original.get_pixel(x, y).a != recolored.get_pixel(x, y).a: alpha_identical = false
		check(alpha_identical, "Brand palette preserves every original alpha pixel")
		check(recolored.get_pixel(0, 0).a == 0.0, "Role padding is truly transparent, never a dark matte")
	for row: int in range(2):
		var id := "mira" if row == 0 else "theo"
		for column: int in range(3):
			var anchor := Vector2(280 + column * 304, 280 + row * 250)
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = int(anchor.y)
			stage.add_child(desk)
			check(desk.configure("north", horizontal, vertical), "Exact desk with selected soft materials")
			piece(FIX + "kits/computer-north-v2-monitor.png", Vector2(192, 224), Vector2(96, 160), anchor + Vector2(0, -10), int(anchor.y + 2))
			piece(FIX + "kits/computer-north-v2-keyboard.png", Vector2(192, 224), Vector2(96, 160), anchor + Vector2(0, 4), int(anchor.y + 2))
			piece(FIX + "kits/computer-north-v2-mouse.png", Vector2(192, 224), Vector2(96, 160), anchor + Vector2(0, 4), int(anchor.y + 2))
			if column > 0:
				var suffix := "-brand" if column == 2 else ""
				for component: String in ["binders", "folder", "pen_cup"]:
					piece(FIX + "roles/lawyer-north-v3-" + component + suffix + ".png", Vector2(192, 224), Vector2(96, 160), anchor, int(anchor.y + 3))
			var chair_foot := anchor + Vector2(0, 20)
			var actor_foot := chair_foot + Vector2(0, -8 if id == "mira" else -4)
			actors.append(piece(FIX + "characters/" + id + "-north-seated-v2.png", Vector2(48, 80), Vector2(24, 72), actor_foot, int(chair_foot.y)))
			piece(FIX + "chair-north-v1.png", Vector2(96, 160), Vector2(48, 112), chair_foot, int(chair_foot.y + 1))
			regions.append(Rect2(anchor + Vector2(-80, -100), Vector2(160, 145)))
			caption(["Plain computer station", "Legal kit · source palette", "Legal kit · brand palette"][column], anchor + Vector2(-135, 55), 270)
			var top: Rect2i = desk.resolved.top
			check(top.encloses(Rect2i(-42, -44, 20, 12)), "Binder proposed contact footprint stays on top")
			check(top.encloses(Rect2i(18, -42, 26, 19)), "Actual flat folder stays on top")
			check(top.encloses(Rect2i(-35, -23, 6, 4)), "Pen cup proposed base stays on top")
	var capture_paths: Array[String] = []
	if DisplayServer.get_name() != "headless":
		for frame: int in range(6):
			for actor: Sprite2D in actors: actor.region_rect = Rect2(frame * 48, 0, 48, 80)
			for tick: int in range(3): await process_frame
			for panel: PanelContainer in panels:
				check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Caption contained in viewport")
				for region: Rect2 in regions: check(not panel.get_global_rect().intersects(region), "Caption never covers any assembly")
			RenderingServer.force_draw(false)
			var screenshot := root.get_texture().get_image()
			check(screenshot.get_size() == Vector2i(1280, 720), "Native room review size")
			var path := "frame%d.png" % frame
			check(screenshot.save_png(OUTPUT + path) == OK, "Save " + path)
			capture_paths.append(path)
	var report := FileAccess.open(OUTPUT + ("headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "failures": failures, "status": "staged_role_kit_not_runtime_approval", "worker_disabled": true, "captures": capture_paths, "columns": ["plain", "source_palette", "brand_palette"], "actor_scale_reference_only": ["mira", "theo"], "source_provenance": "dev/art-catalogue/LAWYER_NORTH_KIT_REVIEW.md"}, "\t"))
	stage.free()
	ui.free()
	print("lawyer_kit: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
