extends SceneTree
## DEV-ONLY contact/depth diagnostic. Never registers a runtime facing or seat.
## The south work cell is (0,-1), NOT modular_desk_geometry's placeholder seat.

const DESK := preload("res://tools/modular_desk_geometry.gd")
const OUTPUT := "res://tests/output/supported-south-assembly"
const FIXTURES := "res://tests/fixtures/furniture-calibration"
const IDS: Array[String] = ["mira", "theo"]
const ACTOR_SHIFTS: Array[int] = [0, 8, 12]
const WORK_FOOT := Vector2(0, -32)
const ACTOR_PIVOT := Vector2(24, 72)
const CHAIR_PIVOT := Vector2(48, 112)
const MONITOR_PIVOT := Vector2(96, 160)
const SEAT_TOP := 95 # Measured S3 source/native cushion top, not a collider.

var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var panels: Array[PanelContainer] = []
var captures: Array[String] = []
var observations: Array[Dictionary] = []
var checks := 0
var failures: Array[String] = []

class Guide extends Node2D:

	var actor_shift := 0
	var hip_rows := Vector2i(47, 50)

	func _draw() -> void:
		draw_rect(Rect2(-48, -16, 96, 32), Color("FA4616"), false, 1)
		draw_rect(Rect2(-16, -48, 32, 32), Color("C1FA81"), false, 1)
		draw_rect(Rect2(-48, -48, 96, 32), Color("6196C1"), false, 1)
		draw_line(Vector2(-5, -32), Vector2(5, -32), Color.WHITE, 1)
		draw_line(Vector2(0, -37), Vector2(0, -27), Color.WHITE, 1)
		var seat := -32 + SEAT_TOP - 112
		draw_line(Vector2(-19, seat), Vector2(19, seat), Color.CYAN, 1)
		var hips := Rect2(-12, -104 + actor_shift + hip_rows.x, 24, hip_rows.y - hip_rows.x + 1)
		draw_rect(hips, Color(1, 0.75, 0.2, 0.18), true)
		draw_rect(hips, Color("FFD27F"), false, 1)
		draw_rect(Rect2(-24, -104 + actor_shift, 48, 80), Color(0.8, 0.8, 1, 0.4), false, 1)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func caption(copy: String, at: Vector2, width: int) -> Label:
	var panel := PanelContainer.new()
	panel.position = at
	panel.custom_minimum_size = Vector2(width, 40)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 6, 10, 6)))
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(label, "meta")
	panel.add_child(label)
	ui.add_child(panel)
	panels.append(panel)
	return label

func sprite(texture: Texture2D, canvas: Vector2, pivot: Vector2, foot: Vector2, depth: int) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture
	result.region_enabled = true
	result.region_rect = Rect2(Vector2.ZERO, canvas)
	result.position = (foot + canvas / 2.0 - pivot).round()
	result.z_as_relative = false
	result.z_index = depth
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(result)
	return result

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Approved room architecture loads without GameMain/worker")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	caption("SOUTH SUPPORT STUDY · real work foot (0, −32) · unchanged 48×80 production poses", Vector2(180, 100), 920)
	caption("Diagnostic only · chair fixed · cyan: seat top · amber: hip estimate · no runtime approval", Vector2(180, 658), 920)
	var horizontal := load(FIXTURES.path_join("materials/oak-horizontal-v1-soft.png")) as Texture2D
	var vertical := load(FIXTURES.path_join("materials/oak-vertical-v1-soft.png")) as Texture2D
	var chair_texture := load(FIXTURES.path_join("chair-south-v3.png")) as Texture2D
	var monitor_texture := load(FIXTURES.path_join("kits/computer-south-v3.png")) as Texture2D
	check(horizontal.get_size() == Vector2(32, 32) and vertical.get_size() == Vector2(32, 32), "Generated soft oak is native 32px repeat material")
	check(chair_texture.get_size() == Vector2(96, 160) and monitor_texture.get_size() == Vector2(192, 224), "Registered source canvases remain intact")
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/furniture_catalog.json"))
	var work_cell: Array = catalogue.furniture.desk.work_cell
	check(Vector2(float(work_cell[0]), float(work_cell[1])) * 32.0 == WORK_FOOT, "Fixture work foot comes from actual legacy south work cell")
	for row: int in range(2):
		for column: int in range(3):
			var anchor := Vector2(280 + column * 304, 300 + row * 248)
			var logical := anchor + WORK_FOOT
			var shift := ACTOR_SHIFTS[column]
			var actor_foot := logical + Vector2(0, shift)
			var chair := sprite(chair_texture, Vector2(96, 160), CHAIR_PIVOT, logical, roundi(anchor.y - 33))
			var pose := CharacterArt.seated_sheet(IDS[row])
			var actor := sprite(pose, Vector2(48, 80), ACTOR_PIVOT, actor_foot, roundi(anchor.y - 32))
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = roundi(anchor.y)
			stage.add_child(desk)
			check(desk.configure("south", horizontal, vertical), "Exact south modular desk configures with generated materials")
			var monitor := sprite(monitor_texture, Vector2(192, 224), MONITOR_PIVOT, anchor, roundi(anchor.y + 2))
			var guide := Guide.new()
			guide.position = anchor
			guide.actor_shift = shift
			guide.hip_rows = Vector2i(47, 50) if row == 0 else Vector2i(45, 48)
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			var label := caption("", anchor + Vector2(-134, 48), 268)
			stations.append({"id": IDS[row], "anchor": anchor, "logical": logical, "actor_foot": actor_foot, "shift": shift, "chair": chair, "actor": actor, "desk": desk, "monitor": monitor, "guide": guide, "label": label, "pose": pose, "pose_image": pose.get_image(), "monitor_image": monitor_texture.get_image(), "bounds": Rect2(anchor + Vector2(-80, -120), Vector2(160, 160))})
			check(desk.resolved.top == Rect2i(-48, -48, 96, 32) and desk.resolved.floor == Rect2i(-48, -16, 96, 32), "Exact top and ground footprint are distinct, consistent rectangles")
			check(desk.resolved.top_layer == "front", "Entire current south tabletop stays ahead of actor; no invented split")
			check(not Rect2(desk.resolved.floor).intersects(Rect2(-16, -48, 32, 32)), "Physical work cell touches but does not intersect blocked footprint")
			check(actor.position == logical + Vector2(0, -32 + shift), "Native centered sprite keeps production offset −32 and foot baseline72")
			check(chair.position == logical + Vector2(0, -32), "Chair remains registered at the unchanged logical foot")
			check(chair.z_index < actor.z_index and actor.z_index < desk.z_index + desk.front.z_index and monitor.z_index > desk.z_index + desk.front.z_index, "Explicit south layer order is chair → actor → whole desk top → rear monitor")
			check(actor.scale == Vector2.ONE and chair.scale == Vector2.ONE and monitor.scale == Vector2.ONE and desk.scale == Vector2.ONE, "All art remains native, no runtime scaling")
			check(pose.get_size() == Vector2(288, 80), "Production south sheet contains exactly six 48×80 cells")

func metrics(station: Dictionary, frame: int) -> Dictionary:
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var actor_origin := Vector2i(station.actor_foot) - Vector2i(ACTOR_PIVOT)
	var monitor_origin := Vector2i(station.anchor) - Vector2i(MONITOR_PIVOT)
	var top: Rect2i = station.desk.resolved.top
	top.position += Vector2i(station.anchor)
	var head_pixels := 0
	var head_hidden := 0
	var arm_region_pixels := 0
	var arm_hidden := 0
	for y: int in range(80):
		for x: int in range(48):
			if source.get_pixel(x, y).a < 0.5: continue
			var point := actor_origin + Vector2i(x, y)
			var monitor_point := point - monitor_origin
			var blocked := top.has_point(point)
			if Rect2i(0, 0, 192, 224).has_point(monitor_point):
				blocked = blocked or station.monitor_image.get_pixelv(monitor_point).a > 0.5
			if y < 32:
				head_pixels += 1
				if blocked: head_hidden += 1
			# A rectangular arm/hand region, not a semantic hand-pixel collider.
			if y >= 40 and y <= 47 and (x <= 19 or x >= 28):
				arm_region_pixels += 1
				if blocked: arm_hidden += 1
	var hip: Vector2i = station.guide.hip_rows
	var seat_y := int(station.logical.y) + SEAT_TOP - 112
	return {"id": station.id, "frame": frame, "actor_render_y": station.shift, "chair_render_y": 0, "hip_minus_seat_y_range": [actor_origin.y + hip.x - seat_y, actor_origin.y + hip.y - seat_y], "head_pixels": head_pixels, "head_hidden_by_top_or_monitor": head_hidden, "arm_roi_pixels": arm_region_pixels, "arm_roi_hidden_by_top_or_monitor": arm_hidden, "foot_endpoint_jump_px": station.shift, "keyboard": "not present in candidate south kit; cannot claim hand-key contact"}

func set_frame(frame: int, mode: String = "native") -> void:
	for station: Dictionary in stations:
		var actor: Sprite2D = station.actor
		actor.texture = station.pose
		actor.region_rect = Rect2(frame * 48, 0, 48, 80)
		actor.position = station.actor_foot + Vector2(0, -32)
		station.desk.visible = mode != "support"
		station.monitor.visible = mode != "support"
		station.guide.visible = mode == "guides" or mode == "support"
		station.chair.modulate.a = 1.0
		if mode == "standing":
			actor.texture = CharacterArt.locomotion_sheet(station.id)
			actor.region_rect = CharacterArt.locomotion_region(&"front", 0)
			actor.position = station.logical + Vector2(0, -32)
		var copy := "%s · actor %+d / chair 0\n%s" % ["Mina" if station.id == "mira" else "Theo", station.shift, "standing endpoint" if mode == "standing" else ("idle %d" % frame if frame < 2 else "typing %d" % (frame - 2))]
		station.label.text = copy

func validate_ui() -> void:
	for panel: PanelContainer in panels:
		check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Caption remains inside native viewport")
		for station: Dictionary in stations:
			check(not panel.get_global_rect().intersects(station.bounds), "No diagnostic caption intersects any native assembly")

func capture(name_value: String, detail: bool = false) -> void:
	await frames()
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Native screenshot is1280×720")
	check(screenshot.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if detail:
		for station: Dictionary in stations:
			var crop := screenshot.get_region(Rect2i(station.bounds))
			crop.resize(640, 640, Image.INTERPOLATE_NEAREST)
			var path := "%s-%s-y%d-4x.png" % [name_value, station.id, station.shift]
			check(crop.save_png(OUTPUT.path_join(path)) == OK, "Save nearest-neighbor contact detail " + path)
			captures.append(path)
	print("Supported south study: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	build()
	for frame: int in range(6):
		for station: Dictionary in stations:
			var result := metrics(station, frame)
			observations.append(result)
			check(result.head_pixels > 0 and result.head_hidden_by_top_or_monitor == 0, "Upper-head sample remains visible across every candidate/frame")
			check(result.arm_roi_pixels > 0, "Arm-region measurement samples actual opaque source pixels")
	set_frame(0)
	await frames()
	validate_ui()
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		set_frame(0, "standing")
		await capture("standing-endpoint")
		for frame: int in range(6):
			set_frame(frame)
			await capture("native-frame%d" % frame, frame == 2)
		for frame: int in range(6):
			set_frame(frame, "support")
			await capture("support-frame%d" % frame, frame == 2)
		set_frame(2, "guides")
		await capture("guides-frame2")
		for tick: int in range(210):
			var frame := (tick / 15) % 2 if tick < 60 or tick >= 180 else 2 + ((tick - 60) / 6) % 4
			set_frame(frame, "standing" if tick < 30 or tick >= 195 else "native")
			await RenderingServer.frame_post_draw
	var manifest := FileAccess.open(OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if manifest != null:
		manifest.store_string(JSON.stringify({"status": "diagnostic_not_runtime_approval", "checks": checks, "failures": failures, "worker_disabled": true, "production_changed": false, "renderer": DisplayServer.get_name(), "captures": captures, "logical_work_foot": [0, -32], "actor_render_y_candidates": ACTOR_SHIFTS, "chair_render_y": 0, "top": [-48, -48, 96, 32], "floor": [-48, -16, 96, 32], "seat_y_relative_chair_pivot": -17, "hip_ranges_estimated_not_masks": {"mira": [47, 50], "theo": [45, 48]}, "head_sample_source_rows": [0, 31], "arm_sample_source_rows": [40, 47], "arm_sample_source_x": "x <=19 or x >=28; opaque ROI, not semantic hand mask", "material": "generated native soft oak", "keyboard": "not authored/absent from south rear-monitor source", "movie_sequence_frames": 210, "observations": observations}, "\t"))
	stage.free()
	ui.free()
	await frames()
	print("supported_south_assembly: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
