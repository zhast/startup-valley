extends SceneTree
## DEV-ONLY actual room material/composition review. Actors are idle scale
## references, never depicted as performing an authored stylus interaction.

const DESK := preload("res://tools/modular_desk_geometry.gd")
const FIXTURE := "res://tests/fixtures/furniture-calibration/"
const OUTPUT := "res://tests/output/creative-north-composition/"
const KIT_PIVOT := Vector2(96, 160)
const ACTOR_PIVOT := Vector2(24, 72)
var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var panels: Array[PanelContainer] = []
var observations: Array[Dictionary] = []
var captures: Array[String] = []
var checks := 0
var failures: Array[String] = []
var image_cache: Dictionary = {}
var source_hashes: Dictionary = {}
var layout_name := "centered"

class ContactGuide extends Node2D:
	var actor_offset := 12
	var parked := false
	func _draw() -> void:
		draw_rect(Rect2(-48, -48, 96, 32), Color("6196C1"), false, 1)
		var origin := Vector2(-24, actor_offset - 72)
		for rectangle: Rect2 in [Rect2(0, 30, 13, 19), Rect2(35, 30, 13, 19)]:
			rectangle.position += origin
			draw_rect(rectangle, Color("FA4616"), false, 1)
		draw_rect(Rect2(28, -30, 12, 12) if parked else Rect2(-38, -32, 12, 12), Color("C1FA81"), false, 1)
		draw_rect(Rect2(28, -43, 12, 12) if parked else Rect2(28, -41, 12, 12), Color("C1FA81"), false, 1)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func image_for(path: String) -> Image:
	if not image_cache.has(path):
		var value := Image.load_from_file(ProjectSettings.globalize_path(path))
		check(value != null and not value.is_empty(), "Load original fixture " + path)
		value.convert(Image.FORMAT_RGBA8)
		image_cache[path] = value
		source_hashes[path] = value.get_data().hex_encode().sha256_text()
	return image_cache[path]

func piece(path: String, canvas: Vector2, pivot: Vector2, foot: Vector2, depth: int) -> Sprite2D:
	var value := Sprite2D.new()
	value.texture = ImageTexture.create_from_image(image_for(path))
	value.region_enabled = true
	value.region_rect = Rect2(Vector2.ZERO, canvas)
	value.centered = false
	value.position = (foot - pivot).round()
	value.z_as_relative = false
	value.z_index = depth
	value.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(value)
	return value

func caption(copy: String, position_value: Vector2, width: int) -> Label:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.custom_minimum_size = Vector2(width, 42)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(10, 6, 10, 6)))
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(label, "meta")
	panel.add_child(label)
	ui.add_child(panel)
	panels.append(panel)
	return label

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Actual approved room architecture loads without GameMain")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 20
	root.add_child(ui)
	caption("CREATIVE NORTH · ordinary computer / tablet with monitor / tablet only", Vector2(152, 96), 976)
	caption("UNAPPROVED · seated idle scale references only · no pen-use animation or new employee capability", Vector2(136, 660), 1008)
	var horizontal := ImageTexture.create_from_image(image_for(FIXTURE + "materials/oak-horizontal-v1-soft.png"))
	var vertical := ImageTexture.create_from_image(image_for(FIXTURE + "materials/oak-vertical-v1-soft.png"))
	for row: int in range(2):
		var id := "mira" if row == 0 else "theo"
		for column: int in range(3):
			var anchor := Vector2(280 + column * 304, 280 + row * 250)
			var desk := DESK.new()
			desk.position = anchor
			desk.z_as_relative = false
			desk.z_index = int(anchor.y)
			stage.add_child(desk)
			check(desk.configure("north", horizontal, vertical), "Native exact north desk uses soft approved-comparison materials")
			var props: Dictionary = {}
			if column < 2:
				props.monitor = piece(FIXTURE + "kits/computer-north-v2-monitor.png", Vector2(192, 224), KIT_PIVOT, anchor + Vector2(0, -10), int(anchor.y + 2))
			if column == 0:
				for part: String in ["keyboard", "mouse"]:
					props[part] = piece(FIXTURE + "kits/computer-north-v2-" + part + ".png", Vector2(192, 224), KIT_PIVOT, anchor + Vector2(0, 4), int(anchor.y + 2))
			else:
				for part: String in ["tablet", "swatches", "camera"]:
					props[part] = piece(FIXTURE + "roles/creative-north-v1-" + part + ".png", Vector2(192, 224), KIT_PIVOT, anchor, int(anchor.y + 3))
			var physical := anchor + Vector2(0, 32)
			var chair_foot := physical + Vector2(0, -12)
			var actor_foot := chair_foot + Vector2(0, -8 if id == "mira" else -4)
			var pose_path := FIXTURE + "characters/" + id + "-north-seated-v2.png"
			var actor := piece(pose_path, Vector2(48, 80), ACTOR_PIVOT, actor_foot, int(chair_foot.y))
			var chair := piece(FIXTURE + "chair-north-v1.png", Vector2(96, 160), Vector2(48, 112), chair_foot, int(chair_foot.y + 1))
			var guide := ContactGuide.new()
			guide.actor_offset = int(actor_foot.y - anchor.y)
			guide.position = anchor
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			var label := caption("", anchor + Vector2(-140, 60), 280)
			stations.append({"id": id, "column": column, "anchor": anchor, "physical": physical, "chair_foot": chair_foot, "actor_foot": actor_foot, "actor": actor, "chair": chair, "guide": guide, "caption": label, "props": props, "pose": image_for(pose_path), "region": Rect2i(Vector2i(anchor) + Vector2i(-80, -100), Vector2i(160, 145))})
			check(actor.scale == Vector2.ONE and chair.scale == Vector2.ONE and desk.scale == Vector2.ONE, "All scale-reference artwork remains native")
			check(not props.has("tablet") or (not props.has("keyboard") and not props.has("mouse")), "Tablet replaces keyboard/mouse; devices are never stacked")
			check(Rect2i(-48, -48, 96, 32).encloses(Rect2i(-7, -46, 14, 3)), "Fixed raised monitor's actual support rows rest on tabletop")

func opaque_at(source: Image, point: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, source.get_size()).has_point(point) and source.get_pixelv(point).a > 0.5

func measure(station: Dictionary, frame: int) -> Dictionary:
	var pose: Image = station.pose.get_region(Rect2i(frame * 48, 0, 48, 80))
	var actor_origin := Vector2i(station.actor_foot - ACTOR_PIVOT)
	var parts: Dictionary = {}
	var intersections: Dictionary = {}
	for name_value: String in station.props:
		var prop: Sprite2D = station.props[name_value]
		var source: Image = prop.texture.get_image()
		var prop_origin := Vector2i(prop.position)
		var total := 0
		var hidden := 0
		var wrist_box_overlap := 0
		var wrist_ink_overlap := 0
		for y: int in range(source.get_height()):
			for x: int in range(source.get_width()):
				if source.get_pixel(x, y).a < 0.5: continue
				var pixel := prop_origin + Vector2i(x, y)
				var in_actor := pixel - actor_origin
				total += 1
				var actor_ink := opaque_at(pose, in_actor)
				if actor_ink: hidden += 1
				if Rect2i(0, 30, 13, 19).has_point(in_actor) or Rect2i(35, 30, 13, 19).has_point(in_actor):
					wrist_box_overlap += 1
					if actor_ink: wrist_ink_overlap += 1
		parts[name_value] = {"opaque_pixels": total, "actor_projection_overlap": hidden, "conservative_wrist_box_overlap": wrist_box_overlap, "wrist_source_ink_overlap": wrist_ink_overlap, "bounds_on_host": [prop_origin.x + source.get_used_rect().position.x - station.anchor.x, prop_origin.y + source.get_used_rect().position.y - station.anchor.y, source.get_used_rect().size.x, source.get_used_rect().size.y]}
		if name_value in ["tablet", "swatches", "camera"]:
			var bounds := source.get_used_rect()
			bounds.position += prop_origin - Vector2i(station.anchor)
			check(Rect2i(-48, -48, 96, 32).encloses(bounds), "Complete creative object bounds remain on tabletop: " + name_value)
			check(Rect2i(-46, -46, 92, 28).encloses(bounds), "Creative object stays at least2px inside tabletop rim: " + name_value)
		if name_value in ["camera", "swatches"]:
			check(wrist_box_overlap == 0 and wrist_ink_overlap == 0, "Side accessories clear conservative wrist regions and actual arm pixels: " + name_value)
		if name_value == "tablet":
			if layout_name == "parked_left":
				check(hidden == 0 and wrist_ink_overlap == 0, "Parked tablet remains entirely visible in both idle endpoints without painting above actor")
			else:
				check(hidden > total * 0.8, "Centered baseline preserves the observed severe tablet occlusion as a rejected control")
		for other_name: String in station.props:
			if name_value >= other_name: continue
			var other: Sprite2D = station.props[other_name]
			var other_image := other.texture.get_image()
			var count := 0
			for y: int in range(source.get_used_rect().position.y, source.get_used_rect().end.y):
				for x: int in range(source.get_used_rect().position.x, source.get_used_rect().end.x):
					if opaque_at(source, Vector2i(x, y)) and opaque_at(other_image, prop_origin + Vector2i(x, y) - Vector2i(other.position)): count += 1
			intersections[name_value + "/" + other_name] = count
			check(count == 0, "Separate devices do not overlap: " + name_value + "/" + other_name)
	return {"id": station.id, "column": station.column, "layout": layout_name, "idle_frame": frame, "actor_y_from_logical": station.actor_foot.y - station.physical.y, "chair_y_from_logical": -12, "actor_scale_reference_only": true, "parts": parts, "opaque_device_intersections": intersections}

func set_layout(parked: bool) -> void:
	layout_name = "parked_left" if parked else "centered"
	for station: Dictionary in stations:
		if station.column == 0: continue
		station.props.tablet.position = station.anchor - KIT_PIVOT + (Vector2(-30, -7) if parked else Vector2.ZERO)
		station.props.swatches.position = station.anchor - KIT_PIVOT + (Vector2(66, 2) if parked else Vector2.ZERO)
		station.props.camera.position = station.anchor - KIT_PIVOT + (Vector2(0, -2) if parked else Vector2.ZERO)
		station.guide.parked = parked
		station.guide.queue_redraw()

func set_state(frame: int, show_actors: bool, guides: bool = false) -> void:
	check(frame in [0, 1], "Only authored seated idle endpoints used; no typing/stylus action implied")
	for station: Dictionary in stations:
		station.actor.region_rect = Rect2(frame * 48, 0, 48, 80)
		station.actor.visible = show_actors
		station.chair.visible = show_actors
		station.guide.visible = guides and station.column > 0
		station.caption.text = ["Plain computer", "Tablet + monitor", "Tablet only"][station.column] + (" · resting left" if layout_name == "parked_left" and station.column > 0 else "") + ("\n" + ("Mina" if station.id == "mira" else "Theo") + " · idle scale reference" if show_actors else "\nUnoccupied composition")

func validate_ui() -> void:
	for panel: PanelContainer in panels:
		check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Caption is within native viewport")
		var style := panel.get_theme_stylebox("panel")
		check((panel.get_child(0) as Label).get_minimum_size().x <= panel.custom_minimum_size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT), "Caption text respects painted paper insets")
		for station: Dictionary in stations: check(not panel.get_global_rect().intersects(Rect2(station.region)), "No caption covers head, devices, chair or legs")

func capture(name_value: String, details: bool = false) -> void:
	for tick: int in range(3): await process_frame
	validate_ui()
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == Vector2i(1280, 720), "Composition evidence stays native1280x720")
	check(screenshot.save_png(OUTPUT + name_value + ".png") == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	if details:
		for station: Dictionary in stations:
			var crop := screenshot.get_region(station.region)
			crop.resize(640, 580, Image.INTERPOLATE_NEAREST)
			var path := "%s-%s-option%d-4x.png" % [name_value, station.id, station.column]
			check(crop.save_png(OUTPUT + path) == OK, "Save nearest detail " + path)
			captures.append(path)
	print("Creative north composition: " + name_value)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	build()
	for parked: bool in [false, true]:
		set_layout(parked)
		for frame: int in [0, 1]:
			for station: Dictionary in stations: observations.append(measure(station, frame))
	set_state(0, true)
	for tick: int in range(3): await process_frame
	validate_ui()
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		for parked: bool in [false, true]:
			set_layout(parked)
			set_state(0, false)
			await capture(layout_name + "-unoccupied", true)
			for frame: int in [0, 1]:
				set_state(frame, true)
				await capture(layout_name + "-idle-frame%d" % frame, true)
		set_state(0, true, true)
		await capture("clearance-guides")
	for path: String in image_cache:
		check(image_cache[path].get_data().hex_encode().sha256_text() == source_hashes[path], "No source image pixels changed during composition")
	var report := FileAccess.open(OUTPUT + ("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"status": "staged_native_room_composition_not_runtime_approved", "checks": checks, "failures": failures, "workerDisabled": true, "captures": captures, "columns": ["plain_computer", "tablet_with_monitor", "tablet_only"], "layouts": ["centered", "parked_left"], "frames": [0, 1], "actor_scale_reference_only": true, "stylus_use_animation": false, "source_or_production_changed": false, "source_hashes": source_hashes, "observations": observations}, "\t"))
	stage.free()
	ui.free()
	print("creative_north_composition: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
