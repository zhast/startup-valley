extends SceneTree
## DEV-ONLY supported-assembly study. Explicit diagnostic geometry, no production
## pose/furniture registration, worker, navigation mutation, or saved company.

const DESK := preload("res://tools/modular_desk_geometry.gd")
const OUTPUT := "res://tests/output/supported-north-assembly"
const FIXTURES := "res://tests/fixtures/furniture-calibration"
const SHIFTS: Array[int] = [0, -12, -18]
const IDS: Array[String] = ["mira", "theo"]
const ACTOR_FROM_CHAIR := -8
const KIT_OFFSET := Vector2(0, 4)
const KEY_BED := Rect2i(79, 128, 31, 9)
const KEYBOARD_OUTLINE := Rect2i(79, 127, 31, 11)

var stage: Node2D
var label_layer: CanvasLayer
var stations: Array[Dictionary] = []
var captures: Array[String] = []
var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []

class SupportGuide extends Node2D:

	var assembly_shift := 0
	var hip_range := Vector2i(63, 65)
	var standing := false

	func _draw() -> void:
		var logical := Vector2(0, 32)
		var chair := logical + Vector2(0, assembly_shift)
		var actor_top := logical + Vector2(-24, assembly_shift + ACTOR_FROM_CHAIR - 72)
		# Red: logical blocked floor; green: unchanged adjacent work cell.
		draw_rect(Rect2(-48, -16, 96, 32), Color(1, 0.28, 0.08, 0.1), true)
		draw_rect(Rect2(-48, -16, 96, 32), Color("FA4616"), false, 1.0)
		draw_rect(Rect2(-16, 16, 32, 32), Color(0.75, 0.98, 0.5, 0.1), true)
		draw_rect(Rect2(-16, 16, 32, 32), Color("C1FA81"), false, 1.0)
		draw_line(logical - Vector2(5, 0), logical + Vector2(5, 0), Color.WHITE, 1.0)
		draw_line(logical - Vector2(0, 5), logical + Vector2(0, 5), Color.WHITE, 1.0)
		draw_line(logical, chair, Color.WHITE, 1.0)
		# Cyan seat plane comes from the visible east-chair family hypothesis;
		# amber is an estimated anatomical range, not an authored collision mask.
		draw_line(chair + Vector2(-20, -16), chair + Vector2(20, -16), Color.CYAN, 1.0)
		if not standing:
			var hips := Rect2(Vector2(-12, actor_top.y + hip_range.x), Vector2(24, hip_range.y - hip_range.x + 1))
			draw_rect(hips, Color(1, 0.75, 0.2, 0.22), true)
			draw_rect(hips, Color("FFD27F"), false, 1.0)
			# Blue outline retains the exact standing-cell position, exposing the
			# instantaneous endpoint displacement instead of hiding it in a tween.
			draw_rect(Rect2(logical - Vector2(24, 72), Vector2(48, 80)), Color(0.38, 0.59, 0.76, 0.5), false, 1.0)
		draw_rect(Rect2(-48, -48, 96, 32), Color(0.38, 0.59, 0.76, 0.8), false, 1.0)

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

func paper(copy: String, position_value: Vector2, width: int) -> Label:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.custom_minimum_size = Vector2(width, 40)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 8, 12, 8)))
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(label, "meta")
	panel.add_child(label)
	label_layer.add_child(panel)
	return label

func sprite(texture: Texture2D, canvas: Vector2, pivot: Vector2, at: Vector2, depth: int) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture
	result.region_enabled = true
	result.region_rect = Rect2(Vector2.ZERO, canvas)
	result.position = (at + canvas / 2.0 - pivot).round()
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
	check(room.load_layout(), "Approved room architecture loads")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	label_layer = CanvasLayer.new()
	label_layer.layer = 20
	root.add_child(label_layer)
	paper("SUPPORTED NORTH ASSEMBLY · exact 96×32 top · actor stays 8px north of chair", Vector2(196, 100), 832)
	paper("Diagnostic only · cyan = inferred seat · amber = hip estimate · white = unchanged logical foot", Vector2(172, 640), 880)
	var kit := load(FIXTURES.path_join("kits/computer-north-v2.png")) as Texture2D
	var chair_texture := load(FIXTURES.path_join("chair-north-v1.png")) as Texture2D
	for row: int in range(2):
		for column: int in range(3):
			var anchor := Vector2(280 + column * 304, 272 + row * 224)
			var physical := anchor + Vector2(0, 32)
			var shift := SHIFTS[column]
			var chair_foot := physical + Vector2(0, shift)
			var actor_foot := chair_foot + Vector2(0, ACTOR_FROM_CHAIR)
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = roundi(anchor.y)
			stage.add_child(desk)
			check(desk.configure("north"), "Exact modular north geometry configures")
			sprite(kit, Vector2(192, 224), Vector2(96, 160), anchor + KIT_OFFSET, roundi(anchor.y + 2))
			var pose := load(FIXTURES.path_join("characters/%s-north-seated-v2.png" % IDS[row])) as Texture2D
			var actor := sprite(pose, Vector2(48, 80), Vector2(24, 72), actor_foot, roundi(chair_foot.y))
			var chair := sprite(chair_texture, Vector2(96, 160), Vector2(48, 112), chair_foot, roundi(chair_foot.y + 1))
			var guide := SupportGuide.new()
			guide.position = anchor
			guide.assembly_shift = shift
			guide.hip_range = Vector2i(63, 65) if row == 0 else Vector2i(59, 61)
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			var caption := paper("", anchor + Vector2(-132, 80), 264)
			stations.append({"id": IDS[row], "shift": shift, "anchor": anchor, "physical": physical, "chair_foot": chair_foot, "actor_foot": actor_foot, "actor": actor, "chair": chair, "guide": guide, "caption": caption, "pose": pose, "kit_image": kit.get_image(), "pose_image": pose.get_image()})
			var profile: Dictionary = DESK.profile("north")
			check(profile.top == Rect2i(-48, -48, 96, 32) and profile.floor == Rect2i(-48, -16, 96, 32), "Study uses exact tabletop/floor projection, not whole-source alpha dimensions")
			check(not Rect2(profile.floor).has_point(physical - anchor), "Logical foot stays one adjacent cell south of blocked footprint")
			check(not Rect2(profile.floor).intersects(Rect2(-16, 16, 32, 32)), "Unchanged reserved work cell touches but never overlaps desk footprint")
			var keyboard_on_desk := Rect2(KEYBOARD_OUTLINE)
			keyboard_on_desk.position += KIT_OFFSET - Vector2(96, 160)
			check(Rect2(profile.top).encloses(keyboard_on_desk), "Entire keyboard outline +4Y remains on exact horizontal top")
			check(actor_foot - chair_foot == Vector2(0, ACTOR_FROM_CHAIR), "Whole-assembly shift preserves actor/chair support relation")
			check(actor.scale == Vector2.ONE and chair.scale == Vector2.ONE and desk.scale == Vector2.ONE, "Native actor/chair/desk scale remains 1")

func metrics(station: Dictionary, frame: int) -> Dictionary:
	var pose_image: Image = station.pose_image
	var kit_image: Image = station.kit_image
	var source := pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var actor_origin: Vector2i = Vector2i(station.actor_foot) - Vector2i(24, 72)
	var kit_origin: Vector2i = Vector2i(station.anchor + KIT_OFFSET) - Vector2i(96, 160)
	var key_rect := Rect2i(kit_origin + KEY_BED.position, KEY_BED.size)
	var skin_total := 0
	var key_overlap := 0
	for y: int in range(30, 49):
		for x: int in range(48):
			if x > 12 and x < 35: continue
			var color := source.get_pixel(x, y)
			# A reviewed color/region sample, not a claim that these pixels are a
			# semantic hand collider. Orange jacket/highlights are excluded.
			if color.a > 0.5 and color.r > 130.0 / 255.0 and color.g > color.r * 0.42 and color.g < color.r * 0.8 and color.b < color.g * 0.9:
				skin_total += 1
				if key_rect.has_point(actor_origin + Vector2i(x, y)): key_overlap += 1
	var screen_total := 0
	var screen_hidden := 0
	for y: int in range(97, 120):
		for x: int in range(79, 113):
			var color := kit_image.get_pixel(x, y)
			var lit := color.a > 0.5 and ((color.b > color.r + 25.0 / 255.0 and color.b > 70.0 / 255.0) or (color.g > color.r + 30.0 / 255.0 and color.g > 80.0 / 255.0))
			if not lit: continue
			screen_total += 1
			var point := kit_origin + Vector2i(x, y) - actor_origin
			if Rect2i(0, 0, 48, 80).has_point(point) and source.get_pixelv(point).a > 0.5: screen_hidden += 1
	var hip: Vector2i = station.guide.hip_range
	var seat_y := int(station.chair_foot.y) - 16
	return {"id": station.id, "assembly_shift": station.shift, "actor_y_from_logical": int(station.shift) + ACTOR_FROM_CHAIR, "frame": frame, "sampled_hand_pixels": skin_total, "hand_pixels_over_key_bed": key_overlap, "lit_monitor_pixels": screen_total, "monitor_pixels_occluded_by_actor": screen_hidden, "monitor_hidden_percent": roundi(100.0 * screen_hidden / maxi(1, screen_total)), "hip_gap_from_inferred_seat": [actor_origin.y + hip.x - seat_y, actor_origin.y + hip.y - seat_y], "instant_standing_to_seated_displacement_px": abs(int(station.shift) + ACTOR_FROM_CHAIR)}

func set_frame(frame: int, guided: bool = false, standing: bool = false) -> void:
	for station: Dictionary in stations:
		var actor: Sprite2D = station.actor
		var guide: SupportGuide = station.guide
		guide.visible = guided
		guide.standing = standing
		guide.queue_redraw()
		station.chair.modulate.a = 0.22 if guided else 1.0
		if standing:
			actor.texture = CharacterArt.locomotion_sheet(station.id)
			actor.region_rect = CharacterArt.locomotion_region(&"back", 0)
			actor.position = station.physical + Vector2(0, -32)
			station.caption.text = "%s · chair %d / standing at logical foot" % ["Mina" if station.id == "mira" else "Theo", station.shift]
		else:
			actor.texture = station.pose
			actor.region_rect = Rect2(frame * 48, 0, 48, 80)
			actor.position = station.actor_foot + Vector2(0, -32)
			var observation := metrics(station, frame)
			station.caption.text = "%s · chair %d / actor %d\nMonitor hidden %d%% · hand sample %d/%d" % ["Mina" if station.id == "mira" else "Theo", station.shift, observation.actor_y_from_logical, observation.monitor_hidden_percent, observation.hand_pixels_over_key_bed, observation.sampled_hand_pixels]

func capture(name_value: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Native supported assembly capture remains 1280×720")
	check(image.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save supported assembly evidence " + name_value)
	captures.append(name_value + ".png")
	print("Supported north study: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	build()
	for frame: int in range(6):
		for station: Dictionary in stations:
			var observation := metrics(station, frame)
			check(observation.lit_monitor_pixels > 0, "Monitor occlusion sample has actual lit source pixels")
			check(observation.hip_gap_from_inferred_seat == ([-1, 1] if station.id == "mira" else [-5, -3]), "Assembly shifts cannot conceal a changed hip/seat relation")
			observations.append(observation)
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		set_frame(0, false, true)
		await capture("standing-endpoint")
		for frame: int in range(6):
			set_frame(frame)
			await capture("native-frame%d" % frame)
		for frame: int in range(6):
			set_frame(frame, true)
			await capture("guides-frame%d" % frame)
		set_frame(0, true, true)
		await capture("standing-guides")
		# Deliberate hard endpoints expose the unimplemented sit/pull-in motion.
		# This is diagnostic footage, not a fabricated polished transition.
		for tick: int in range(240):
			var standing := tick < 45 or tick >= 195
			var frame := (tick / 15) % 2 if tick < 90 else 2 + ((tick - 90) / 6) % 4
			set_frame(frame, tick >= 150 and tick < 195, standing)
			await RenderingServer.frame_post_draw
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "unsupported_candidate_study_not_approved", "checks": checks, "failures": failures, "workerDisabled": true, "renderer": DisplayServer.get_name(), "captures": captures, "assembly_shifts": SHIFTS, "actor_relative_chair_y": ACTOR_FROM_CHAIR, "logical_work_cell_offset": [0, 32], "kit_offset": [0, 4], "exact_desk_geometry": "res://tools/modular_desk_geometry.gd", "material": "geometry_control_colors_not_final_art", "seat_plane_is_family_hypothesis": true, "navigation_or_runtime_changed": false, "movie_diagnostic_frames": 240, "observations": observations}, "\t"))
	stage.free()
	label_layer.free()
	await frames()
	print("supported_north_assembly: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
