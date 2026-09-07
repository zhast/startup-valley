extends "res://tools/capture_supported_north_assembly.gd"
## DEV-ONLY follow-up. Registered source components are positioned separately;
## no pixels, production registry, physical actor position, or saves are changed.

const MONITOR_OUTPUT := "res://tests/output/north-monitor-socket"
const MONITOR_ORIGINS: Array[int] = [4, -6, -10]
const COHORTS: Array[Dictionary] = [
	{"id": "mira", "actor_from_chair": -8},
	{"id": "theo", "actor_from_chair": -8},
	{"id": "theo", "actor_from_chair": -4},
]
const ASSEMBLY_SHIFT := -12

class MonitorSupportGuide extends Node2D:
	var hip_range := Vector2i(63, 65)
	var actor_from_chair := -8
	var standing := false
	var monitor_y := 4

	func _draw() -> void:
		var logical := Vector2(0, 32)
		var chair := logical + Vector2(0, ASSEMBLY_SHIFT)
		var actor_top := chair.y + actor_from_chair - 72
		draw_rect(Rect2(-48, -16, 96, 32), Color("FA4616"), false, 1.0)
		draw_rect(Rect2(-16, 16, 32, 32), Color("C1FA81"), false, 1.0)
		draw_rect(Rect2(-48, -48, 96, 32), Color("6196C1"), false, 1.0)
		draw_line(logical - Vector2(5, 0), logical + Vector2(5, 0), Color.WHITE)
		draw_line(logical - Vector2(0, 5), logical + Vector2(0, 5), Color.WHITE)
		draw_line(logical, chair, Color.WHITE)
		draw_line(chair + Vector2(-20, -16), chair + Vector2(20, -16), Color.CYAN)
		if not standing:
			draw_rect(Rect2(-12, actor_top + hip_range.x, 24, hip_range.y - hip_range.x + 1), Color(1, 0.75, 0.2, 0.35), true)
			draw_rect(Rect2(-12, actor_top + hip_range.x, 24, hip_range.y - hip_range.x + 1), Color("FFD27F"), false, 1.0)
		# Magenta traces the actual last three opaque monitor-base rows.
		draw_rect(Rect2(-7, 124 - 160 + monitor_y, 14, 3), Color("FD9DDD"), false, 1.0)

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Approved room loads without game or worker")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	label_layer = CanvasLayer.new()
	label_layer.layer = 20
	root.add_child(label_layer)
	paper("NORTH MONITOR SOCKET · chair −12 · keyboard/mouse +4 · monitor +4 / −6 / −10", Vector2(164, 90), 912)
	paper("Diagnostic only · cyan seat / amber hip / magenta monitor base · no accepted runtime socket", Vector2(154, 668), 932)
	var kit_path := FIXTURES.path_join("kits/computer-north-v2")
	var original := Image.load_from_file(ProjectSettings.globalize_path(kit_path + ".png"))
	var monitor_image := Image.load_from_file(ProjectSettings.globalize_path(kit_path + "-monitor.png"))
	var keyboard_image := Image.load_from_file(ProjectSettings.globalize_path(kit_path + "-keyboard.png"))
	var mouse_image := Image.load_from_file(ProjectSettings.globalize_path(kit_path + "-mouse.png"))
	for source: Image in [original, monitor_image, keyboard_image, mouse_image]:
		source.convert(Image.FORMAT_RGBA8)
	check(monitor_image.get_used_rect() == Rect2i(80, 97, 33, 30), "Actual monitor bounds include right bezel and final stand row126")
	check(keyboard_image.get_used_rect() == KEYBOARD_OUTLINE, "Keyboard bounds preserve registered source canvas")
	check(mouse_image.get_used_rect() == Rect2i(112, 129, 6, 8), "Mouse bounds preserve registered source canvas")
	var base_crop := monitor_image.get_region(Rect2i(0, 124, 192, 3))
	check(base_crop.get_used_rect() == Rect2i(89, 0, 14, 3), "Monitor base support rows are measured, not inferred from full silhouette")
	var merged := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	merged.fill(Color(0, 0, 0, 0))
	for source: Image in [monitor_image, keyboard_image, mouse_image]:
		check(source.get_size() == Vector2i(192, 224), "Every split component keeps original 192×224 registration canvas")
		merged.blit_rect_mask(source, source, Rect2i(0, 0, 192, 224), Vector2i.ZERO)
	check(merged.get_data() == original.get_data(), "Components exactly recombine before external socket offsets")
	var monitor_texture := ImageTexture.create_from_image(monitor_image)
	var keyboard_texture := ImageTexture.create_from_image(keyboard_image)
	var mouse_texture := ImageTexture.create_from_image(mouse_image)
	var chair_texture := load(FIXTURES.path_join("chair-north-v1.png")) as Texture2D
	for row: int in range(COHORTS.size()):
		for column: int in range(MONITOR_ORIGINS.size()):
			var cohort: Dictionary = COHORTS[row]
			var monitor_y := MONITOR_ORIGINS[column]
			var anchor := Vector2(280 + column * 304, 210 + row * 180)
			var physical := anchor + Vector2(0, 32)
			var chair_foot := physical + Vector2(0, ASSEMBLY_SHIFT)
			var actor_foot := chair_foot + Vector2(0, int(cohort.actor_from_chair))
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = roundi(anchor.y)
			stage.add_child(desk)
			check(desk.configure("north"), "Exact north tabletop configures")
			sprite(monitor_texture, Vector2(192, 224), Vector2(96, 160), anchor + Vector2(0, monitor_y), roundi(anchor.y + 2))
			sprite(keyboard_texture, Vector2(192, 224), Vector2(96, 160), anchor + KIT_OFFSET, roundi(anchor.y + 2))
			sprite(mouse_texture, Vector2(192, 224), Vector2(96, 160), anchor + KIT_OFFSET, roundi(anchor.y + 2))
			var pose := load(FIXTURES.path_join("characters/%s-north-seated-v2.png" % cohort.id)) as Texture2D
			var actor := sprite(pose, Vector2(48, 80), Vector2(24, 72), actor_foot, roundi(chair_foot.y))
			var chair := sprite(chair_texture, Vector2(96, 160), Vector2(48, 112), chair_foot, roundi(chair_foot.y + 1))
			var guide := MonitorSupportGuide.new()
			guide.position = anchor
			guide.hip_range = Vector2i(63, 65) if cohort.id == "mira" else Vector2i(59, 61)
			guide.actor_from_chair = int(cohort.actor_from_chair)
			guide.monitor_y = monitor_y
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			var caption := paper("", anchor + Vector2(-143, 49), 286)
			caption.get_parent().add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 4, 12, 4)))
			stations.append({"id": cohort.id, "shift": ASSEMBLY_SHIFT, "actor_from_chair": cohort.actor_from_chair, "monitor_y": monitor_y, "anchor": anchor, "physical": physical, "chair_foot": chair_foot, "actor_foot": actor_foot, "actor": actor, "chair": chair, "guide": guide, "caption": caption, "pose": pose, "pose_image": pose.get_image(), "kit_image": original, "monitor_image": monitor_image})
			var top := Rect2i(DESK.profile("north").top)
			var base := Rect2i(89, 124, 14, 3)
			base.position += Vector2i(-96, monitor_y - 160)
			check(top.encloses(base), "Actual monitor base stays fully supported by tabletop at origin%d" % monitor_y)
			check(top.encloses(Rect2i(-17, -29, 31, 11)), "Keyboard stays +4Y and fully on tabletop")
			check(top.encloses(Rect2i(16, -27, 6, 8)), "Mouse stays +4Y and fully on tabletop")
			check(actor_foot - chair_foot == Vector2(0, int(cohort.actor_from_chair)), "Character-specific support offset is explicit")
			check(actor.scale == Vector2.ONE and chair.scale == Vector2.ONE, "Native sprites are never rescaled")
			check(not Rect2(-48, -16, 96, 32).has_point(physical - anchor), "Logical actor destination remains outside blocked desk floor")

func metrics(station: Dictionary, frame: int) -> Dictionary:
	var result := super.metrics(station, frame)
	var source: Image = station.pose_image.get_region(Rect2i(frame * 48, 0, 48, 80))
	var monitor_image: Image = station.monitor_image
	var actor_origin := Vector2i(station.actor_foot) - Vector2i(24, 72)
	var monitor_origin := Vector2i(station.anchor) + Vector2i(-96, int(station.monitor_y) - 160)
	var total := 0
	var hidden := 0
	for y: int in range(97, 120):
		for x: int in range(79, 113):
			var color := monitor_image.get_pixel(x, y)
			var lit := color.a > 0.5 and ((color.b > color.r + 25.0 / 255.0 and color.b > 70.0 / 255.0) or (color.g > color.r + 30.0 / 255.0 and color.g > 80.0 / 255.0))
			if not lit: continue
			total += 1
			var point := monitor_origin + Vector2i(x, y) - actor_origin
			if Rect2i(0, 0, 48, 80).has_point(point) and source.get_pixelv(point).a > 0.5: hidden += 1
	result["monitor_y_from_desk"] = station.monitor_y
	result["monitor_movement_from_baseline"] = int(station.monitor_y) - 4
	result["actor_from_chair"] = station.actor_from_chair
	result["actor_y_from_logical"] = ASSEMBLY_SHIFT + int(station.actor_from_chair)
	result["instant_standing_to_seated_displacement_px"] = abs(ASSEMBLY_SHIFT + int(station.actor_from_chair))
	result["lit_monitor_pixels"] = total
	result["monitor_pixels_occluded_by_actor"] = hidden
	result["monitor_hidden_percent"] = roundi(100.0 * hidden / maxi(1, total))
	result["stand_support_source_y_inclusive"] = [124 + int(station.monitor_y), 126 + int(station.monitor_y)]
	return result

func set_frame(frame: int, guided: bool = false, standing: bool = false) -> void:
	for station: Dictionary in stations:
		var actor: Sprite2D = station.actor
		station.guide.visible = guided
		station.guide.standing = standing
		station.guide.queue_redraw()
		station.chair.modulate.a = 0.22 if guided else 1.0
		var name_value := "Mina" if station.id == "mira" else "Theo"
		if standing:
			actor.texture = CharacterArt.locomotion_sheet(station.id)
			actor.region_rect = CharacterArt.locomotion_region(&"back", 0)
			actor.position = station.physical + Vector2(0, -32)
			station.caption.text = "%s · standing / monitor %+d" % [name_value, station.monitor_y]
		else:
			actor.texture = station.pose
			actor.region_rect = Rect2(frame * 48, 0, 48, 80)
			actor.position = station.actor_foot + Vector2(0, -32)
			var value := metrics(station, frame)
			station.caption.text = "%s · seat %d / monitor %+d\nHidden %d%% · keys %d/%d" % [name_value, station.actor_from_chair, station.monitor_y, value.monitor_hidden_percent, value.hand_pixels_over_key_bed, value.sampled_hand_pixels]

func capture(name_value: String) -> void:
	await frames()
	for panel: Node in label_layer.get_children():
		if not panel is Control: continue
		for station: Dictionary in stations:
			var assembly := Rect2(station.anchor + Vector2(-48, -73), Vector2(96, 109))
			check(not panel.get_global_rect().intersects(assembly), "Diagnostic caption never occludes a monitor, person, chair or tabletop")
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1280, 720), "Monitor socket evidence is native1280×720")
	check(image.save_png(MONITOR_OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	print("North monitor socket: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MONITOR_OUTPUT))
	build()
	set_frame(0)
	await frames()
	for panel: Node in label_layer.get_children():
		if not panel is Control: continue
		for station: Dictionary in stations:
			var assembly := Rect2(station.anchor + Vector2(-48, -73), Vector2(96, 109))
			check(not panel.get_global_rect().intersects(assembly), "All diagnostic caption bounds stay outside native assembly regions")
	for frame: int in range(6):
		for station: Dictionary in stations:
			var value := metrics(station, frame)
			check(value.lit_monitor_pixels > 0, "Lit monitor sample exists")
			var expected := [-5, -3] if station.id == "theo" and station.actor_from_chair == -8 else [-1, 1]
			check(value.hip_gap_from_inferred_seat == expected, "Exposed hip/seat range matches explicit character-specific offset")
			observations.append(value)
	# Monitor translation must not alter hands, keyboard or seat support.
	for row: int in range(COHORTS.size()):
		for frame: int in range(2, 6):
			var reference := metrics(stations[row * 3], frame)
			for column: int in range(1, 3):
				var value := metrics(stations[row * 3 + column], frame)
				check(value.hand_pixels_over_key_bed == reference.hand_pixels_over_key_bed, "Independent monitor socket preserves keyboard contact")
				check(value.hip_gap_from_inferred_seat == reference.hip_gap_from_inferred_seat, "Independent monitor socket preserves seat relation")
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
		for tick: int in range(240):
			var standing := tick < 45 or tick >= 195
			var frame := (tick / 15) % 2 if tick < 90 else 2 + ((tick - 90) / 6) % 4
			set_frame(frame, tick >= 150 and tick < 195, standing)
			await RenderingServer.frame_post_draw
	var file := FileAccess.open(MONITOR_OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"status": "candidate_socket_study_not_approved", "checks": checks, "failures": failures, "workerDisabled": true, "renderer": DisplayServer.get_name(), "captures": captures, "monitor_origins": MONITOR_ORIGINS, "monitor_movement_from_baseline": [0, -10, -14], "keyboard_mouse_origin": [0, 4], "chair_shift": ASSEMBLY_SHIFT, "cohorts": COHORTS, "desk": "exact geometry control, not final material", "seat_plane_is_family_hypothesis": true, "source_pixels_changed": false, "runtime_or_navigation_changed": false, "movie_diagnostic_frames": 240, "observations": observations}, "\t"))
	stage.free()
	label_layer.free()
	await frames()
	print("north_monitor_socket: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
