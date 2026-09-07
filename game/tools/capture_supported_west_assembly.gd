extends SceneTree
## DEV-ONLY west calibration. New kit/poses/chair remain unapproved candidates.
## Cell axes rotate logically; camera, actor atlases and furniture images do not.

const DESK := preload("res://tools/modular_desk_geometry.gd")
const OUTPUT := "res://tests/output/supported-west-assembly"
const FIXTURES := "res://tests/fixtures/furniture-calibration"
const IDS: Array[String] = ["mira", "theo"]
const SHIFTS: Array[int] = [0, -8, -12]
const WORK_FOOT := Vector2(32, 0)
const ACTOR_PIVOT := Vector2(24, 72)
const CHAIR_PIVOT := Vector2(48, 112)
const KIT_PIVOT := Vector2(96, 160)
const KEY_OUTLINE := Rect2i(99, 115, 11, 31)
const KEY_BED := Rect2i(100, 116, 9, 29)
const SEAT_BAND := Rect2i(36, 91, 19, 2)

var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var panels: Array[PanelContainer] = []
var captures: Array[String] = []
var observations: Array[Dictionary] = []
var checks := 0
var failures: Array[String] = []
var height_normalized := false
var output_path := OUTPUT
var seat_band := SEAT_BAND

class Guide extends Node2D:

	var shift := 0
	var hip_rows := Vector2i(53, 55)
	var chair_seat := SEAT_BAND

	func _draw() -> void:
		draw_rect(Rect2(-16, -48, 32, 96), Color("FA4616"), false, 1)
		draw_rect(Rect2(16, -16, 32, 32), Color("C1FA81"), false, 1)
		draw_rect(Rect2(-16, -80, 32, 96), Color("6196C1"), false, 1)
		draw_line(WORK_FOOT - Vector2(5, 0), WORK_FOOT + Vector2(5, 0), Color.WHITE, 1)
		draw_line(WORK_FOOT - Vector2(0, 5), WORK_FOOT + Vector2(0, 5), Color.WHITE, 1)
		var foot := WORK_FOOT + Vector2(shift, 0)
		draw_line(WORK_FOOT, foot, Color.WHITE, 1)
		var seat := Rect2(foot + Vector2(chair_seat.position) - CHAIR_PIVOT, Vector2(chair_seat.size))
		draw_rect(seat, Color.CYAN, false, 1)
		var hips := Rect2(foot + Vector2(-10, hip_rows.x - 72), Vector2(14, hip_rows.y - hip_rows.x + 1))
		draw_rect(hips, Color(1, 0.75, 0.2, 0.2), true)
		draw_rect(hips, Color("FFD27F"), false, 1)
		draw_rect(Rect2(WORK_FOOT - ACTOR_PIVOT, Vector2(48, 80)), Color(0.8, 0.8, 1, 0.4), false, 1)
		draw_rect(Rect2(Vector2(KEY_BED.position) - KIT_PIVOT, Vector2(KEY_BED.size)), Color.YELLOW, false, 1)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	height_normalized = "--height-normalized-chair" in OS.get_cmdline_user_args()
	if height_normalized:
		output_path = OUTPUT.path_join("height56")
		seat_band = Rect2i(37, 97, 18, 2)
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func texture(path: String) -> Texture2D:
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
	check(room.load_layout(), "Approved room loads without GameMain/worker/save")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	caption("WEST SUPPORT STUDY · logical foot (+32, 0) · chair/body translated together", Vector2(164, 100), 952)
	caption("UNAPPROVED · %s / Theo frame drift retained · cyan seat / amber hip estimate" % ("height56 W chair" if height_normalized else "taller W chair"), Vector2(164, 660), 952)
	var horizontal := texture(FIXTURES.path_join("materials/oak-horizontal-v1-soft.png"))
	var vertical := texture(FIXTURES.path_join("materials/oak-vertical-v1-soft.png"))
	var chair_art := texture(FIXTURES.path_join("chair-west-v2-height56.png" if height_normalized else "chair-west-v2.png"))
	var monitor_art := texture(FIXTURES.path_join("kits/computer-west-v2-monitor.png"))
	var keyboard_art := texture(FIXTURES.path_join("kits/computer-west-v2-keyboard.png"))
	var mouse_art := texture(FIXTURES.path_join("kits/computer-west-v2-mouse.png"))
	var whole_kit := texture(FIXTURES.path_join("kits/computer-west-v2.png"))
	var combined := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	for component: Texture2D in [monitor_art, keyboard_art, mouse_art]:
		check(component.get_size() == Vector2(192, 224), "Components retain full common192×224 registration")
		combined.blend_rect(component.get_image(), Rect2i(0, 0, 192, 224), Vector2i.ZERO)
	var whole_image := whole_kit.get_image()
	whole_image.convert(Image.FORMAT_RGBA8)
	check(combined.get_data() == whole_image.get_data(), "Independent registered west components recombine to whole kit exactly")
	check(keyboard_art.get_image().get_used_rect() == KEY_OUTLINE, "West keyboard is measured11×31, matching north family's31×11 after axis exchange")
	check(monitor_art.get_image().get_used_rect() == Rect2i(81, 108, 12, 30), "West monitor dimensions/stand remain measured12×30")
	check(mouse_art.get_image().get_used_rect() == Rect2i(99, 103, 9, 6), "West mouse dimensions remain measured9×6")
	check(chair_art.get_image().get_used_rect() == (Rect2i(35, 72, 29, 56) if height_normalized else Rect2i(32, 62, 35, 66)), "Chosen chair normalization has measured bounds, never assumed dimensions")
	var model := OfficeLayout.new()
	check(model.load_files(), "Load actual32px logical grid and existing catalogue")
	check(model.tile_size == 32 and model.available_facings("desk") == ["south"], "No west production facing silently enabled")
	var proposed: Array[Vector2i] = []
	for cell: Array in model.catalog.desk.occupied:
		proposed.append(Vector2i(int(cell[1]), int(cell[0])))
	var nearest := Vector2i.ZERO
	while proposed.has(nearest): nearest += Vector2i.RIGHT
	check(proposed == [Vector2i(0, -1), Vector2i.ZERO, Vector2i(0, 1)], "Logical axis exchange gives1×3 footprint without raster rotation")
	check(Vector2(nearest * model.tile_size) == WORK_FOOT, "Nearest outside work cell is(+1,0), not off-grid(+24,0)")
	for row: int in range(2):
		var pose_art := texture(FIXTURES.path_join("characters/%s-west-seated-v%d.png" % [IDS[row], 2 if row == 0 else 3]))
		check(pose_art.get_size() == Vector2(288, 80), "Source retains six48×80 cells and inherited pivot")
		for column: int in range(3):
			var anchor := Vector2(264 + column * 320, 288 + row * 248)
			var logical := anchor + WORK_FOOT
			var shift := SHIFTS[column]
			var render_foot := logical + Vector2(shift, 0)
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = roundi(anchor.y)
			stage.add_child(desk)
			check(desk.configure("west", horizontal, vertical), "Exact32×96 west top uses generated soft oak")
			var chair := sprite(chair_art, Vector2(96, 160), CHAIR_PIVOT, render_foot, roundi(anchor.y))
			var keyboard := sprite(keyboard_art, Vector2(192, 224), KIT_PIVOT, anchor, roundi(anchor.y + 1))
			var mouse := sprite(mouse_art, Vector2(192, 224), KIT_PIVOT, anchor, roundi(anchor.y + 1))
			var actor := sprite(pose_art, Vector2(48, 80), ACTOR_PIVOT, render_foot, roundi(anchor.y + 2))
			var monitor := sprite(monitor_art, Vector2(192, 224), KIT_PIVOT, anchor, roundi(anchor.y + 3))
			var guide := Guide.new()
			guide.position = anchor
			guide.shift = shift
			guide.hip_rows = Vector2i(53, 55) if row == 0 else Vector2i(49, 51)
			guide.chair_seat = seat_band
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			var label := caption("", anchor + Vector2(-136, 64), 272)
			stations.append({"id": IDS[row], "anchor": anchor, "logical": logical, "render_foot": render_foot, "shift": shift, "desk": desk, "chair": chair, "keyboard": keyboard, "mouse": mouse, "actor": actor, "monitor": monitor, "guide": guide, "label": label, "pose": pose_art, "pose_image": pose_art.get_image(), "monitor_image": monitor_art.get_image(), "chair_image": chair_art.get_image(), "bounds": Rect2(anchor + Vector2(-32, -84), Vector2(104, 132)), "detail_bounds": Rect2i(Vector2i(anchor) + Vector2i(-40, -96), Vector2i(128, 160))})
			check(desk.resolved.top == Rect2i(-16, -80, 32, 96) and desk.resolved.floor == Rect2i(-16, -48, 32, 96), "Screen top and logical floor differ by exact32px elevation")
			check(not Rect2(desk.resolved.floor).intersects(Rect2(WORK_FOOT - Vector2(16, 16), Vector2(32, 32))), "Actual work cell does not overlap blocking footprint")
			check(Rect2(desk.resolved.top).encloses(Rect2(Vector2(KEY_OUTLINE.position) - KIT_PIVOT, Vector2(KEY_OUTLINE.size))), "Entire keyboard lies on actual tabletop")
			check(actor.scale == Vector2.ONE and chair.scale == Vector2.ONE and monitor.scale == Vector2.ONE and desk.scale == Vector2.ONE, "All assets stay native with unchanged camera")
			check(actor.position == render_foot + Vector2(0, -32) and actor.position == chair.position, "Actor and chair retain shared candidate foot and unchanged−32center offset")

func metrics(station: Dictionary, frame: int) -> Dictionary:
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var actor_origin := Vector2i(station.render_foot - ACTOR_PIVOT)
	var kit_origin := Vector2i(station.anchor - KIT_PIVOT)
	var chair_origin := Vector2i(station.render_foot - CHAIR_PIVOT)
	var key_bed := Rect2i(kit_origin + KEY_BED.position, KEY_BED.size)
	var top := Rect2i(Vector2i(station.anchor) + Vector2i(-16, -80), Vector2i(32, 96))
	var head_pixels := 0
	var hidden_head := 0
	var hand_samples := 0
	var key_overlap := 0
	var hand_outside_top := 0
	var chair_over_body := 0
	var leg_over_top := 0
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
			if y >= 51 and top.has_point(point): leg_over_top += 1
			# Left-side skin/region sample; no mirrored mask or exact hand collider.
			if x >= 7 and x <= 22 and y >= 39 and y <= 50 and color.r > 0.3 and color.g > color.r * 0.45 and color.g < color.r * 0.8 and color.b < color.g * 0.9:
				hand_samples += 1
				if key_bed.has_point(point): key_overlap += 1
				if not top.has_point(point): hand_outside_top += 1
	var hips: Vector2i = station.guide.hip_rows
	var seat_y := int(station.render_foot.y) + seat_band.position.y - int(CHAIR_PIVOT.y)
	var used := source.get_used_rect()
	return {"id": station.id, "frame": frame, "assembly_render_x": station.shift, "logical_work_pixel": [32, 0], "actor_relative_chair": [0, 0], "hip_minus_seat": [actor_origin.y + hips.x - seat_y, actor_origin.y + hips.y - seat_y], "sampled_hand_pixels": hand_samples, "hand_pixels_over_key_bed": key_overlap, "hand_pixels_outside_tabletop": hand_outside_top, "head_pixels": head_pixels, "head_hidden_by_monitor": hidden_head, "body_pixels_hidden_if_whole_chair_in_front": chair_over_body, "leg_roi_pixels_over_top_if_body_in_front": leg_over_top, "native_top_row": used.position.y, "native_last_row": used.end.y - 1, "instant_endpoint_jump_px": absi(station.shift), "approved": false}

func set_frame(frame: int, mode: String = "native") -> void:
	for station: Dictionary in stations:
		var actor: Sprite2D = station.actor
		actor.texture = station.pose
		actor.region_rect = Rect2(frame * 48, 0, 48, 80)
		actor.position = station.render_foot + Vector2(0, -32)
		actor.z_index = roundi(station.anchor.y - 2) if mode == "body-below" else roundi(station.anchor.y + 2)
		station.desk.visible = mode != "support"
		station.monitor.visible = mode != "support"
		station.keyboard.visible = mode != "support"
		station.mouse.visible = mode != "support"
		station.guide.visible = mode == "guides" or mode == "support"
		station.chair.z_index = roundi(station.anchor.y + 4) if mode == "chair-front" else roundi(station.anchor.y - 3 if mode == "body-below" else station.anchor.y)
		if mode == "standing":
			actor.texture = CharacterArt.locomotion_sheet(station.id)
			actor.region_rect = CharacterArt.locomotion_region(&"left", 0)
			actor.position = station.logical + Vector2(0, -32)
		station.label.text = "%s · chair/body X%+d\n%s" % ["Mina" if station.id == "mira" else "Theo", station.shift, "standing logical endpoint" if mode == "standing" else ("%s · frame%d" % [mode, frame])]

func validate_ui() -> void:
	for panel: PanelContainer in panels:
		check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Caption fits1280×720")
		for station: Dictionary in stations:
			check(not panel.get_global_rect().intersects(station.bounds), "No caption overlaps any native assembly")

func capture(name_value: String, detail: bool = false) -> void:
	await frames()
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Native west evidence remains1280×720")
	check(screenshot.save_png(output_path.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if detail:
		for station: Dictionary in stations:
			var crop := screenshot.get_region(station.detail_bounds)
			crop.resize(512, 640, Image.INTERPOLATE_NEAREST)
			var path := "%s-%s-x%d-4x.png" % [name_value, station.id, station.shift]
			check(crop.save_png(output_path.path_join(path)) == OK, "Save exact4× contact crop " + path)
			captures.append(path)
	print("Supported west study: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path))
	build()
	for frame: int in range(6):
		for station: Dictionary in stations:
			var result := metrics(station, frame)
			observations.append(result)
			check(result.head_pixels > 0 and result.head_hidden_by_monitor == 0, "Upper-head ROI stays in front of view without monitor occlusion")
			check(result.sampled_hand_pixels > 0, "Each frame has actual left-hand-region samples")
			check(result.leg_roi_pixels_over_top_if_body_in_front > 0, "Known body/top conflict is recorded rather than hidden by a false pass")
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
		set_frame(2, "chair-front")
		await capture("whole-chair-front-frame2", true)
		set_frame(2, "body-below")
		await capture("whole-body-below-top-frame2", true)
		set_frame(2, "guides")
		await capture("guides-frame2")
		for tick: int in range(210):
			var frame := (tick / 15) % 2 if tick < 60 or tick >= 180 else 2 + ((tick - 60) / 6) % 4
			set_frame(frame, "standing" if tick < 30 or tick >= 195 else "native")
			await RenderingServer.frame_post_draw
	var file := FileAccess.open(output_path.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "known_mismatches_not_runtime_approval", "checks": checks, "failures": failures, "worker_disabled": true, "production_changed": false, "renderer": DisplayServer.get_name(), "captures": captures, "logical_work_foot": [32, 0], "assembly_render_x_candidates": SHIFTS, "chair_y": 0, "actor_relative_chair": [0, 0], "chair_height_normalized": height_normalized, "seat_band_native": [seat_band.position.x, seat_band.position.y, seat_band.size.x, seat_band.size.y], "hip_estimates": {"mira": [53, 55], "theo": [49, 51]}, "kit_normalization": "separate complete source objects uniformly scaled to actual device dimensions, no stretched axis/rotation/mirror", "known_west_chair_mismatch": "height56/casters27/seat97–98 now requires actor support review" if height_normalized else "66px tall versus east56; seat5px higher", "known_theo_registration_mismatch": "top4/5 and sole70/71 vary; hip4px above Mina", "movie_sequence_frames": 210, "observations": observations}, "\t"))
	stage.free()
	ui.free()
	await frames()
	print("supported_west_assembly: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
