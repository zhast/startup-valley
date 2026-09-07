extends SceneTree
## Dev-only exact-source layer/contact study. No production pose registration.

const DESK := preload("res://tools/modular_desk_geometry.gd")
const FIX := "res://tests/fixtures/furniture-calibration/"
const OUTPUT := "res://tests/output/south-actor-layers/"
const CUT := 50
const SHIFTS: Array[int] = [8, 12, 16]
var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var panels: Array[PanelContainer] = []
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var observations: Array[Dictionary] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func part(texture: Texture2D, region: Rect2, origin: Vector2, depth: int) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = texture
	node.region_enabled = true
	node.region_rect = region
	node.centered = false
	node.position = origin.round()
	node.z_as_relative = false
	node.z_index = depth
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(node)
	return node

func label(copy: String, point: Vector2, width: int) -> Label:
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
	return text

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Approved architecture loads in isolated worker-disabled fixture")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	label("SOUTH LAYER STUDY · legs behind top · hands above top · real work foot (0, −32)", Vector2(160, 92), 960)
	label("Diagnostic only · chair follows the supported body · monitor still naturally occludes far-side keys", Vector2(150, 658), 980)
	var horizontal := load(FIX + "materials/oak-horizontal-v1-soft.png") as Texture2D
	var vertical := load(FIX + "materials/oak-vertical-v1-soft.png") as Texture2D
	var chair := load(FIX + "chair-south-v3.png") as Texture2D
	var monitor := load(FIX + "kits/computer-south-v3.png") as Texture2D
	var keyboard := load(FIX + "kits/computer-south-peripherals-v2-keyboard.png") as Texture2D
	var mouse := load(FIX + "kits/computer-south-peripherals-v2-mouse.png") as Texture2D
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/furniture_catalog.json"))
	var work: Array = catalog.furniture.desk.work_cell
	check(Vector2(float(work[0]), float(work[1])) == Vector2(0, -1), "Actual south work cell is outside desk, not a placeholder")
	for row: int in range(2):
		var id := "mira" if row == 0 else "theo"
		var pose := CharacterArt.seated_sheet(id)
		var source := pose.get_image()
		for column: int in range(3):
			var anchor := Vector2(280 + column * 304, 300 + row * 248)
			var foot := anchor + Vector2(0, -32)
			var shift := SHIFTS[column]
			var chair_shift := shift - 8
			var actor_origin := foot + Vector2(-24, -72 + shift)
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = roundi(anchor.y)
			stage.add_child(desk)
			check(desk.configure("south", horizontal, vertical), "Grid-locked south desk configures")
			var chair_node := part(chair, Rect2(0, 0, 96, 160), foot + Vector2(-48, -112 + chair_shift), roundi(anchor.y - 2))
			var lower := part(pose, Rect2(0, CUT, 48, 80 - CUT), actor_origin + Vector2(0, CUT), roundi(anchor.y))
			var upper := part(pose, Rect2(0, 0, 48, CUT), actor_origin, roundi(anchor.y + 3))
			var keys := part(keyboard, Rect2(0, 0, 192, 224), anchor - Vector2(96, 160), roundi(anchor.y + 2))
			var mouse_node := part(mouse, Rect2(0, 0, 192, 224), anchor - Vector2(96, 160), roundi(anchor.y + 2))
			var screen := part(monitor, Rect2(0, 0, 192, 224), anchor - Vector2(96, 157), roundi(anchor.y + 4))
			var copy := label("", anchor + Vector2(-134, 48), 268)
			stations.append({"id": id, "anchor": anchor, "foot": foot, "actor_origin": actor_origin, "shift": shift, "chair_shift": chair_shift, "desk": desk, "chair": chair_node, "lower": lower, "upper": upper, "keyboard": keys, "mouse": mouse_node, "monitor": screen, "label": copy, "source": source, "bounds": Rect2(anchor + Vector2(-80, -120), Vector2(160, 160))})
			check(lower.z_index < desk.z_index + desk.front.z_index and upper.z_index > desk.z_index + desk.front.z_index, "Tabletop is between unchanged lower/upper pixels")
			check(screen.z_index > upper.z_index, "South rear monitor may naturally occlude hands; never fake visibility")
			check(desk.resolved.top.encloses(Rect2i(-16, -48, 31, 13)), "New actual31x13 keyboard lies wholly on tabletop")
			check(desk.resolved.top.encloses(Rect2i(-6, -21, 12, 4)), "Monitor's final support rows at origin+3 remain on tabletop")
			check(not Rect2(desk.resolved.floor).intersects(Rect2(-16, -48, 32, 32)), "Physical work cell remains outside desk collision")
			for frame: int in range(6):
				var whole := source.get_region(Rect2i(frame * 48, 0, 48, 80))
				var reunion := Image.create(48, 80, false, whole.get_format())
				reunion.blit_rect(whole, Rect2i(0, 0, 48, CUT), Vector2i.ZERO)
				reunion.blit_rect(whole, Rect2i(0, CUT, 48, 80 - CUT), Vector2i(0, CUT))
				check(reunion.get_data() == whole.get_data(), "Registered upper/lower union preserves every source byte")
				var hip := Vector2i(47, 50) if id == "mira" else Vector2i(45, 48)
				var seat_y := int(foot.y) + chair_shift - 17
				var hand_hits := 0
				var hand_samples := 0
				var keybed := Rect2i(Vector2i(anchor) + Vector2i(-16, -48), Vector2i(31, 13))
				for y: int in range(40, 48):
					for x: int in range(48):
						if x > 19 and x < 28: continue
						var pixel := whole.get_pixel(x, y)
						if pixel.a < 0.5 or pixel.r < 0.3 or pixel.r < pixel.g * 1.12 or pixel.g < pixel.b * 1.08: continue
						hand_samples += 1
						if keybed.has_point(Vector2i(actor_origin) + Vector2i(x, y)): hand_hits += 1
				observations.append({"id": id, "frame": frame, "actor_shift": shift, "chair_shift": chair_shift, "hip_minus_seat_estimate": [int(actor_origin.y) + hip.x - seat_y, int(actor_origin.y) + hip.y - seat_y], "warm_arm_roi_samples": hand_samples, "samples_over_key_rectangle": hand_hits, "sample_caveat": "Includes warm sleeves/shading; not a semantic hand mask", "hidden_keys_expected": true})

func set_frame(frame: int, mode: String = "layered") -> void:
	for station: Dictionary in stations:
		station.upper.region_rect = Rect2(frame * 48, 0, 48, CUT)
		station.lower.region_rect = Rect2(frame * 48, CUT, 48, 80 - CUT)
		station.upper.z_index = int(station.anchor.y) + (3 if mode != "whole_behind" else 0)
		station.desk.visible = mode != "support"
		station.keyboard.visible = mode != "support"
		station.mouse.visible = mode != "support"
		station.monitor.visible = mode != "support"
		station.label.text = "%s · actor +%d / chair +%d\n%s · frame %d" % ["Mina" if station.id == "mira" else "Theo", station.shift, station.chair_shift, mode, frame]

func capture(name_value: String) -> void:
	for tick: int in range(3): await process_frame
	for panel: PanelContainer in panels:
		check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Caption remains inside viewport")
		for station: Dictionary in stations:
			check(not panel.get_global_rect().intersects(station.bounds), "Caption does not cover any assembly")
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Native capture dimensions")
	check(screenshot.save_png(OUTPUT + name_value + ".png") == OK, "Save " + name_value)
	captures.append(name_value + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	build()
	set_frame(0)
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		for frame: int in range(6):
			set_frame(frame)
			await capture("layered-frame%d" % frame)
		set_frame(2, "whole_behind")
		await capture("whole-behind-frame2")
		set_frame(2, "support")
		await capture("support-frame2")
		for tick: int in range(180):
			set_frame(2 + (tick / 6) % 4)
			await RenderingServer.frame_post_draw
	var output := FileAccess.open(OUTPUT + ("headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"status": "diagnostic_not_runtime_approval", "worker_disabled": true, "checks": checks, "failures": failures, "captures": captures, "source_cut_row": CUT, "logical_work_cell": [0, -1], "actor_shifts": SHIFTS, "chair_rule": "actor_shift -8; never changes physics", "keyboard_native": [31, 13], "monitor_origin_y": 3, "observations": observations}, "\t"))
	stage.free()
	ui.free()
	print("south_actor_layers: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
