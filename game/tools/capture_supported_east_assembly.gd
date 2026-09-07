extends SceneTree
## DEV-ONLY candidate contact/depth study. Never registers art, poses, or a seat.
## Real grid is32px. East has no approved production profile; the proposed1x3
## footprint's adjacent west cell is(-1,0), not the old off-grid(-24,0) marker.

const DESK := preload("res://tools/modular_desk_geometry.gd")
const OUTPUT := "res://tests/output/supported-east-assembly"
const FIXTURES := "res://tests/fixtures/furniture-calibration"
const IDS: Array[String] = ["mira", "theo"]
const SHIFTS: Array[int] = [0, 8, 12]
const WORK_FOOT := Vector2(-32, 0)
const ACTOR_PIVOT := Vector2(24, 72)
const CHAIR_PIVOT := Vector2(48, 112)
const KIT_PIVOT := Vector2(96, 160)
const KEY_OUTLINE := Rect2i(81, 118, 10, 20)
const KEY_BED := Rect2i(82, 119, 8, 18)
const SEAT_BAND := Rect2i(40, 96, 21, 2)

var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var panels: Array[PanelContainer] = []
var captures: Array[String] = []
var observations: Array[Dictionary] = []
var checks := 0
var failures: Array[String] = []

class Guide extends Node2D:

	var shift := 0
	var hip_rows := Vector2i(53, 55)

	func _draw() -> void:
		draw_rect(Rect2(-16, -48, 32, 96), Color("FA4616"), false, 1)
		draw_rect(Rect2(-48, -16, 32, 32), Color("C1FA81"), false, 1)
		draw_rect(Rect2(-16, -80, 32, 96), Color("6196C1"), false, 1)
		draw_line(WORK_FOOT - Vector2(5, 0), WORK_FOOT + Vector2(5, 0), Color.WHITE, 1)
		draw_line(WORK_FOOT - Vector2(0, 5), WORK_FOOT + Vector2(0, 5), Color.WHITE, 1)
		var foot := WORK_FOOT + Vector2(shift, 0)
		draw_line(WORK_FOOT, foot, Color.WHITE, 1)
		var seat := Rect2(Vector2(SEAT_BAND.position) - CHAIR_PIVOT + foot, Vector2(SEAT_BAND.size))
		draw_rect(seat, Color.CYAN, false, 1)
		var hips := Rect2(foot + Vector2(-6, hip_rows.x - 72), Vector2(14, hip_rows.y - hip_rows.x + 1))
		draw_rect(hips, Color(1, 0.75, 0.2, 0.2), true)
		draw_rect(hips, Color("FFD27F"), false, 1)
		draw_rect(Rect2(WORK_FOOT - ACTOR_PIVOT, Vector2(48, 80)), Color(0.8, 0.8, 1, 0.4), false, 1)
		draw_rect(Rect2(Vector2(KEY_BED.position) - KIT_PIVOT, Vector2(KEY_BED.size)), Color.YELLOW, false, 1)

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

func texture(path: String) -> Texture2D:
	# Source checkout only: this dev harness intentionally never ships in export.
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(image != null and not image.is_empty(), "Load actual candidate image " + path)
	return ImageTexture.create_from_image(image)

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

func sprite(art: Texture2D, canvas: Vector2, pivot: Vector2, foot: Vector2, depth: int) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = art
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
	check(room.load_layout(), "Approved room loads without GameMain or a worker")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	caption("EAST SUPPORT STUDY · logical foot (−32, 0) · chair/body translated together", Vector2(164, 100), 952)
	caption("UNAPPROVED · short keyboard · cyan seat / amber hip estimate · offsets are not runtime sockets", Vector2(164, 660), 952)
	var horizontal := texture(FIXTURES.path_join("materials/oak-horizontal-v1-soft.png"))
	var vertical := texture(FIXTURES.path_join("materials/oak-vertical-v1-soft.png"))
	var chair_art := texture(FIXTURES.path_join("chair-east-v2.png"))
	var monitor_art := texture(FIXTURES.path_join("kits/computer-east-v2-monitor.png"))
	var keyboard_art := texture(FIXTURES.path_join("kits/computer-east-v2-keyboard.png"))
	var mouse_art := texture(FIXTURES.path_join("kits/computer-east-v2-mouse.png"))
	var model := OfficeLayout.new()
	check(model.load_files(), "Load real logical office grid and production catalogue")
	var actual_cells: Array[Vector2i] = []
	for cell: Array in model.catalog.desk.occupied:
		actual_cells.append(OfficeLayout.vector(cell))
	check(model.tile_size == 32 and actual_cells == [Vector2i(-1, 0), Vector2i.ZERO, Vector2i(1, 0)], "Grid and legacy3x1 physical footprint are the actual production values")
	check(model.available_facings("desk") == ["south"], "East remains unavailable; this study is not a fake runtime profile")
	var proposed: Array[Vector2i] = []
	for cell: Array in model.catalog.desk.occupied:
		proposed.append(Vector2i(int(cell[1]), int(cell[0])))
	check(proposed == [Vector2i(0, -1), Vector2i.ZERO, Vector2i(0, 1)], "Logical axis exchange alone yields proposed1x3 footprint")
	var nearest := Vector2i.ZERO
	while proposed.has(nearest): nearest += Vector2i.LEFT
	check(Vector2(nearest * model.tile_size) == WORK_FOOT, "Nearest west work cell is(-1,0), exactly(-32,0) pixels")
	check(int(DESK.profile("east").seat_reference.x) % model.tile_size != 0, "Old−24px seat_reference is explicitly off-grid and unused")
	for row: int in range(2):
		var pose_art := texture(FIXTURES.path_join("characters/%s-east-seated-v%d.png" % [IDS[row], 3 if row == 0 else 4]))
		check(pose_art.get_size() == Vector2(288, 80), "East actor source is six unchanged48x80 frames")
		for column: int in range(3):
			var anchor := Vector2(280 + column * 320, 288 + row * 248)
			var logical := anchor + WORK_FOOT
			var shift := SHIFTS[column]
			var render_foot := logical + Vector2(shift, 0)
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = roundi(anchor.y)
			stage.add_child(desk)
			check(desk.configure("east", horizontal, vertical), "Exact native east desk uses soft tiled material, never a turned prop")
			var chair := sprite(chair_art, Vector2(96, 160), CHAIR_PIVOT, render_foot, roundi(anchor.y))
			var keyboard := sprite(keyboard_art, Vector2(192, 224), KIT_PIVOT, anchor, roundi(anchor.y + 1))
			var mouse := sprite(mouse_art, Vector2(192, 224), KIT_PIVOT, anchor, roundi(anchor.y + 1))
			var actor := sprite(pose_art, Vector2(48, 80), ACTOR_PIVOT, render_foot, roundi(anchor.y + 2))
			var monitor := sprite(monitor_art, Vector2(192, 224), KIT_PIVOT, anchor, roundi(anchor.y + 3))
			var guide := Guide.new()
			guide.position = anchor
			guide.shift = shift
			guide.hip_rows = Vector2i(53, 55) if row == 0 else Vector2i(52, 54)
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			var label := caption("", anchor + Vector2(-136, 64), 272)
			stations.append({"id": IDS[row], "anchor": anchor, "logical": logical, "render_foot": render_foot, "shift": shift, "desk": desk, "chair": chair, "keyboard": keyboard, "mouse": mouse, "actor": actor, "monitor": monitor, "guide": guide, "label": label, "pose": pose_art, "pose_image": pose_art.get_image(), "monitor_image": monitor_art.get_image(), "chair_image": chair_art.get_image(), "art_bounds": Rect2(anchor + Vector2(-64, -84), Vector2(96, 132)), "detail_bounds": Rect2i(Vector2i(anchor) + Vector2i(-80, -96), Vector2i(128, 160))})
			check(desk.resolved.top == Rect2i(-16, -80, 32, 96) and desk.resolved.floor == Rect2i(-16, -48, 32, 96), "Exact32x96 top has32px elevation above floor footprint")
			check(not Rect2(desk.resolved.floor).intersects(Rect2(WORK_FOOT - Vector2(16, 16), Vector2(32, 32))), "Physical reserved work cell touches but never overlaps blocked desk footprint")
			check(Rect2(desk.resolved.top).encloses(Rect2(Vector2(KEY_OUTLINE.position) - KIT_PIVOT, Vector2(KEY_OUTLINE.size))), "Short keyboard still fits actual tabletop; fit does not approve its proportions")
			check(actor.scale == Vector2.ONE and chair.scale == Vector2.ONE and desk.scale == Vector2.ONE, "Actor/chair/desk remain at native scale1")
			check(actor.position - chair.position == Vector2(0, 0), "Actor and chair rendered Sprite2D centers share offset here because canvas−pivot is equal")

func metrics(station: Dictionary, frame: int) -> Dictionary:
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var actor_origin := Vector2i(station.render_foot - ACTOR_PIVOT)
	var kit_origin := Vector2i(station.anchor - KIT_PIVOT)
	var chair_origin := Vector2i(station.render_foot - CHAIR_PIVOT)
	var key_bed := Rect2i(kit_origin + KEY_BED.position, KEY_BED.size)
	var head_pixels := 0
	var hidden_head := 0
	var hand_samples := 0
	var key_overlap := 0
	var hand_outside_top := 0
	var chair_over_body := 0
	var top := Rect2i(Vector2i(station.anchor) + Vector2i(-16, -80), Vector2i(32, 96))
	for y: int in range(80):
		for x: int in range(48):
			var color := source.get_pixel(x, y)
			if color.a < 0.5: continue
			var point := actor_origin + Vector2i(x, y)
			var monitor_point := point - kit_origin
			if y < 32:
				head_pixels += 1
				if Rect2i(0, 0, 192, 224).has_point(monitor_point) and station.monitor_image.get_pixelv(monitor_point).a > 0.5: hidden_head += 1
			var chair_point := point - chair_origin
			if Rect2i(0, 0, 96, 160).has_point(chair_point) and station.chair_image.get_pixelv(chair_point).a > 0.5: chair_over_body += 1
			# Skin-color samples within a reviewed hand rectangle, not an authored
			# hand collider. Region excludes torso and orange-jacket highlights.
			if x >= 28 and x <= 43 and y >= 39 and y <= 50 and color.r > 0.3 and color.g > color.r * 0.45 and color.g < color.r * 0.8 and color.b < color.g * 0.9:
				hand_samples += 1
				if key_bed.has_point(point): key_overlap += 1
				if not top.has_point(point): hand_outside_top += 1
	var hips: Vector2i = station.guide.hip_rows
	var seat_y := int(station.render_foot.y) + SEAT_BAND.position.y - int(CHAIR_PIVOT.y)
	return {"id": station.id, "frame": frame, "assembly_render_x": station.shift, "logical_work_pixel": [-32, 0], "actor_relative_chair": [0, 0], "hip_band_minus_observed_seat": [actor_origin.y + hips.x - seat_y, actor_origin.y + hips.y - seat_y], "sampled_hand_pixels": hand_samples, "hand_pixels_over_short_key_bed": key_overlap, "hand_pixels_outside_tabletop": hand_outside_top, "head_pixels": head_pixels, "head_hidden_by_monitor": hidden_head, "body_pixels_hidden_if_whole_chair_in_front": chair_over_body, "instant_endpoint_jump_px": station.shift, "short_keyboard_approved": false}

func set_frame(frame: int, mode: String = "native") -> void:
	for station: Dictionary in stations:
		var actor: Sprite2D = station.actor
		actor.texture = station.pose
		actor.region_rect = Rect2(frame * 48, 0, 48, 80)
		actor.position = station.render_foot + Vector2(0, -32)
		station.desk.visible = mode != "support"
		station.monitor.visible = mode != "support"
		station.keyboard.visible = mode != "support"
		station.mouse.visible = mode != "support"
		station.guide.visible = mode == "guides" or mode == "support"
		station.chair.z_index = roundi(station.anchor.y + 4) if mode == "chair-front" else roundi(station.anchor.y)
		if mode == "standing":
			actor.texture = CharacterArt.locomotion_sheet(station.id)
			actor.region_rect = CharacterArt.locomotion_region(&"right", 0)
			actor.position = station.logical + Vector2(0, -32)
		var result := metrics(station, frame)
		station.label.text = "%s · chair/body X+%d\n%s" % ["Mina" if station.id == "mira" else "Theo", station.shift, "standing logical endpoint" if mode == "standing" else ("short-key hand sample %d/%d" % [result.hand_pixels_over_short_key_bed, result.sampled_hand_pixels])]

func validate_ui() -> void:
	for panel: PanelContainer in panels:
		check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Caption fits actual1280x720 viewport")
		for station: Dictionary in stations:
			check(not panel.get_global_rect().intersects(station.art_bounds), "Caption does not cover native head, desk, chair or floor contact")

func capture(name_value: String, detail: bool = false) -> void:
	await frames()
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Native east evidence is1280x720")
	check(screenshot.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if detail:
		for station: Dictionary in stations:
			var crop := screenshot.get_region(station.detail_bounds)
			crop.resize(512, 640, Image.INTERPOLATE_NEAREST)
			var path := "%s-%s-x%d-4x.png" % [name_value, station.id, station.shift]
			check(crop.save_png(OUTPUT.path_join(path)) == OK, "Save contact detail " + path)
			captures.append(path)
	print("Supported east study: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	build()
	for frame: int in range(6):
		for station: Dictionary in stations:
			var result := metrics(station, frame)
			observations.append(result)
			check(result.head_pixels > 0 and result.head_hidden_by_monitor == 0, "Side monitor does not hide an actor head at any tested offset/frame")
			check(result.sampled_hand_pixels > 0, "Every pose has actual skin samples in the reviewed hand region")
			check(result.hip_band_minus_observed_seat == ([-3, -1] if station.id == "mira" else [-4, -2]), "Horizontal assembly translation cannot conceal character-specific seat-height differences")
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
		set_frame(2, "guides")
		await capture("guides-frame2")
		set_frame(2, "support")
		await capture("support-frame2")
		set_frame(2, "chair-front")
		await capture("chair-front-frame2")
		for tick: int in range(240):
			var mode := "standing" if tick < 45 or tick >= 195 else "native"
			if tick >= 150 and tick < 195: mode = "guides"
			var frame := (tick / 15) % 2 if tick < 90 else 2 + ((tick - 90) / 6) % 4
			set_frame(frame, mode)
			await RenderingServer.frame_post_draw
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "candidate_study_not_approved", "checks": checks, "failures": failures, "workerDisabled": true, "renderer": DisplayServer.get_name(), "captures": captures, "logical_work_cell": [-1, 0], "logical_work_pixel": [-32, 0], "production_east_profile_exists": false, "assembly_x_shifts": SHIFTS, "actor_relative_chair": [0, 0], "kit": "computer-east-v2: short keyboard NOT approved", "materials": ["oak-horizontal-v1-soft.png", "oak-vertical-v1-soft.png"], "source_files": ["chair-east-v2.png", "mira-east-seated-v3.png", "theo-east-seated-v4.png", "computer-east-v2-monitor.png", "computer-east-v2-keyboard.png", "computer-east-v2-mouse.png"], "exact_geometry": "res://tools/modular_desk_geometry.gd", "production_navigation_or_registry_changed": false, "diagnostic_motion_frames": 240, "observations": observations}, "\t"))
	stage.free()
	ui.free()
	await frames()
	print("supported_east_assembly: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
