extends SceneTree
## DEV native room + registered-layer evidence. No GameMain, navigation changes,
## production registration, save access, or newly authored actor interaction.
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/modular-cabinet-calibration"
const MATERIALS := "res://tests/fixtures/furniture-calibration/materials/"
const GAZES := {"north": &"back", "east": &"right", "south": &"front", "west": &"left"}
var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var captures: Array[String] = []
var exports: Array[Dictionary] = []
var checks := 0
var failures: Array[String] = []
var frame_count := 0
var paint_checks := 0
var depth_observations: Array[Dictionary] = []
var checkpoint := ""
var header: Label
var labels: Array[PanelContainer] = []
var h: Texture2D
var v: Texture2D
var room_model: OfficeLayout

class Guide extends Node2D:
	var p: Dictionary
	func _draw() -> void:
		draw_rect(Rect2(p.floor), Color("354b98"), false, 1)
		draw_rect(Rect2(p.top_interior), Color("6196c1"), false, 1)
		draw_rect(Rect2(Vector2(p.service_cell * 32 - Vector2i(16, 16)), Vector2(32, 32)), Color("c1fa81"), false, 1)
		draw_line(Vector2(p.floor.position.x - 4, p.contact_y), Vector2(p.floor.end.x + 4, p.contact_y), Color("fa4616"), 1)
		if p.insert_visible:
			draw_rect(Rect2(p.insert_socket), Color("f1f1f1"), false, 1)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func image(path: String) -> Texture2D:
	var data := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(data != null and not data.is_empty(), "Load " + path)
	return ImageTexture.create_from_image(data)

func label(copy: String, point: Vector2, width: int, height: int = 40) -> Label:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, height)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(8, 4, 8, 4)))
	ui.add_child(panel)
	labels.append(panel)
	var node := Label.new()
	node.text = copy
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(node, "meta")
	panel.add_child(node)
	return node

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Approved room architecture loads without GameMain")
	room_model = room.layout_model
	room.set_hire_count(0)
	room.get_node("Props").hide()
	h = image(MATERIALS + "oak-horizontal-v1-soft.png")
	v = image(MATERIALS + "oak-vertical-v1-soft.png")
	ui = CanvasLayer.new()
	ui.layer = 30
	root.add_child(ui)
	header = label("CABINET GEOMETRY · service sides N / E / S / W · staged, empty inserts", Vector2(136, 96), 1024)
	label("32px floor grid · native scale · no finished front art or interaction approval", Vector2(192, 684), 896, 30)
	for row: int in range(2):
		var family: String = CABINET.FAMILIES[row]
		for column: int in range(4):
			var side: String = CABINET.SIDES[column]
			var p: Dictionary = CABINET.profile(family, side)
			var anchor := Vector2(208 + column * 256, 272 + row * 288)
			check(anchor == room_model.world(room_model.cell_at(anchor)), family + " " + side + " host is actual32px cell center")
			var world_ink := Rect2(p.visual_bounds)
			world_ink.position += anchor
			for corner: Vector2 in [world_ink.position, Vector2(world_ink.end.x - 1, world_ink.position.y), world_ink.end - Vector2.ONE, Vector2(world_ink.position.x, world_ink.end.y - 1)]:
				check(room_model.is_floor(room_model.cell_at(corner)), family + " " + side + " entire actual cabinet ink stays inside room")
			var cabinet := CABINET.new()
			cabinet.position = anchor
			cabinet.z_as_relative = false
			cabinet.z_index = int(anchor.y)
			stage.add_child(cabinet)
			check(cabinet.configure(family, side, h, v), family + " " + side + " exact geometry")
			var actor := Sprite2D.new()
			actor.texture = CharacterArt.locomotion_sheet("mira" if row == 0 else "theo")
			actor.region_enabled = true
			actor.centered = false
			actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			actor.z_as_relative = false
			actor.hide()
			stage.add_child(actor)
			var guide := Guide.new()
			guide.p = p
			guide.position = anchor
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			label("%s · service %s\n%s / rise %dpx" % [family.capitalize(), side.to_upper(), p.service_visibility.replace("_", " "), p.rise], Vector2(anchor.x - 126, 352 + row * 280), 252, 44)
			stations.append({"id": family + "-" + side, "p": p, "anchor": anchor, "cabinet": cabinet, "actor": actor, "guide": guide, "foot": anchor, "whole": null})

func set_actor(station: Dictionary, offset: Vector2i, gaze: String, frame: int = 0) -> void:
	var actor: Sprite2D = station.actor
	var foot := Vector2i(station.anchor) + offset
	actor.region_rect = CharacterArt.locomotion_region(GAZES[gaze], frame)
	actor.position = Vector2(foot - Vector2i(24, 72))
	actor.z_index = foot.y
	actor.show()
	station.foot = Vector2(foot)
	check(not (station.p.floor as Rect2i).has_point(offset), station.id + " physical feet remain outside cabinet")
	for toe: Vector2i in [Vector2i(-9, -6), Vector2i(9, -6), Vector2i(-9, 0), Vector2i(9, 0)]:
		check(room_model.is_floor(room_model.cell_at(Vector2(foot + toe))), station.id + " walk feet stay inside actual room wall grid")
	check(actor.scale == Vector2.ONE and is_zero_approx(actor.rotation), station.id + " actor uses actual native direction, no raster transform")

func save(data: Image, name_value: String) -> void:
	check(data.save_png(OUTPUT.path_join(name_value)) == OK, "Save " + name_value)
	captures.append(name_value)

func settle(count: int = 3) -> void:
	for frame: int in range(count):
		await process_frame
		frame_count += 1
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw

func verify_actor_paint(shot: Image, station: Dictionary) -> void:
	var actor: Sprite2D = station.actor
	if not actor.visible:
		return
	var pose := actor.texture.get_image().get_region(Rect2i(actor.region_rect))
	var p: Dictionary = station.p
	var cabinet_image: Image = station.whole
	var samples := 0
	var mismatches := 0
	var hidden := 0
	var projected := 0
	for y: int in range(80):
		for x: int in range(48):
			var actor_color := pose.get_pixel(x, y)
			if actor_color.a < 0.99:
				continue
			var point := Vector2i(actor.position) + Vector2i(x, y)
			var local := point - Vector2i(station.anchor) + Vector2i(p.pivot)
			var expected := actor_color
			if Rect2i(Vector2i.ZERO, p.canvas).has_point(local):
				var body_color := cabinet_image.get_pixelv(local)
				if body_color.a > 0.99:
					projected += 1
					if actor.z_index < int(station.anchor.y):
						expected = body_color
						hidden += 1
			var actual := shot.get_pixelv(point)
			if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01:
				mismatches += 1
			samples += 1
	paint_checks += samples
	check(samples > 0 and mismatches == 0, station.id + " actor/carcass rendered depth matches native opaque pixels; mismatches=" + str(mismatches))
	if station.foot.y < station.anchor.y:
		check(hidden == projected, station.id + " every genuinely overlapping rear actor pixel is hidden")
	if Vector2i(station.foot - station.anchor) == Vector2i(0, -32):
		check(hidden > 0, station.id + " nearest north service actor really is occluded; far counter walkers need not overlap")
	depth_observations.append({"checkpoint": checkpoint, "id": station.id, "foot_from_host": [station.foot.x - station.anchor.x, station.foot.y - station.anchor.y], "actor_samples": samples, "actor_over_body_projection": projected, "hidden_by_cabinet": hidden, "paint_mismatches": mismatches})

func capture(name_value: String, details: bool = false, paint: bool = true) -> void:
	checkpoint = name_value
	await settle()
	var shot := root.get_texture().get_image()
	check(shot.get_size() == Vector2i(1280, 720), "Native viewport " + name_value)
	save(shot, name_value + ".png")
	for station: Dictionary in stations:
		if paint:
			verify_actor_paint(shot, station)
		if details:
			var crop := shot.get_region(Rect2i(Vector2i(station.anchor) + Vector2i(-96, -136), Vector2i(192, 208)))
			crop.resize(768, 832, Image.INTERPOLATE_NEAREST)
			save(crop, name_value + "-" + station.id + "-4x.png")

func exported_view(p: Dictionary, selected: String) -> SubViewport:
	var view := SubViewport.new()
	view.size = p.canvas
	view.transparent_bg = true
	view.disable_3d = true
	view.msaa_2d = Viewport.MSAA_DISABLED
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var cabinet := CABINET.new()
	cabinet.position = p.pivot
	view.add_child(cabinet)
	check(cabinet.configure(p.family, p.service_side, h, v), "Build registered " + p.family + " " + p.service_side + " " + selected)
	if selected != "whole":
		for layer_name: String in CABINET.LAYERS:
			if layer_name != selected:
				(cabinet.layers[layer_name] as CanvasItem).hide()
	return view

func export_layers() -> void:
	for station: Dictionary in stations:
		var p: Dictionary = station.p
		var views: Dictionary = {}
		for name_value: String in ["whole", "Carcass", "Top", "Front", "Plinth", "Insert"]:
			views[name_value] = exported_view(p, name_value)
		await settle()
		var combined := Image.create(p.canvas.x, p.canvas.y, false, Image.FORMAT_RGBA8)
		combined.fill(Color(0, 0, 0, 0))
		var measurements: Dictionary = {}
		for name_value: String in ["Carcass", "Top", "Front", "Plinth", "Insert", "whole"]:
			var data := PIXELS.rgba((views[name_value] as SubViewport).get_texture().get_image())
			check(data.get_size() == p.canvas, station.id + " same full canvas for " + name_value)
			var measured := PIXELS.analyze(data)
			check(measured.partial_alpha_pixels == 0 and measured.hidden_rgb_pixels == 0, station.id + " binary clean transparent layer " + name_value)
			check(measured.opaque_pixels > 0 if name_value != "Insert" else measured.opaque_pixels == 0, station.id + " missing insert is honestly empty")
			measurements[name_value] = measured
			save(data, station.id + "-" + name_value.to_lower() + ".png")
			if name_value != "whole":
				combined = PIXELS.binary_over(combined, data)
			else:
				check(combined.get_data() == data.get_data(), station.id + " all five native layers reconstruct whole byte-exact")
				check(data.get_used_rect() == Rect2i(p.visual_bounds.position + p.pivot, p.visual_bounds.size), station.id + " actual ink bounds match volume, not padded canvas")
				check(data.get_used_rect().end.y == p.pivot.y + p.contact_y, station.id + " actual last floor pixel matches contact boundary")
				station.whole = data
				var material := (h if p.material_axis == "horizontal" else v).get_image()
				for offset: Vector2i in [Vector2i(0, 0), Vector2i(3, 11), Vector2i(14, 20), Vector2i(20, 3)]:
					var point := Vector2i(p.pivot) + (p.top_interior as Rect2i).position + offset
					var expected := material.get_pixelv(offset % 32)
					var actual := data.get_pixelv(point)
					check(absf(expected.r - actual.r) < 0.01 and absf(expected.g - actual.g) < 0.01 and absf(expected.b - actual.b) < 0.01, station.id + " material painted at native repeat without scaling " + str(offset))
		exports.append({"id": station.id, "service_side": p.service_side, "approach_gaze": p.approach_gaze, "rise": p.rise, "canvas": [p.canvas.x, p.canvas.y], "pivot": [p.pivot.x, p.pivot.y], "floor": PIXELS.rect_values(p.floor), "top": PIXELS.rect_values(p.top), "top_interior": PIXELS.rect_values(p.top_interior), "insert_socket": PIXELS.rect_values(p.insert_socket), "service_visibility": p.service_visibility, "measurements": measurements})
		for view: SubViewport in views.values():
			view.free()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run test_modular_cabinet_geometry.gd for headless checks; this evidence tool needs the native renderer.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	build()
	await export_layers()
	await capture("all-eight-bare", true)
	for station: Dictionary in stations:
		set_actor(station, Vector2i(-80, 16), "south")
	await capture("standing-scale", true)
	for station: Dictionary in stations:
		set_actor(station, station.p.service_cell * 32, station.p.approach_gaze)
	await capture("service-approach", true)
	for station: Dictionary in stations:
		(station.guide as CanvasItem).show()
	await capture("geometry-guides", false, false)
	for station: Dictionary in stations:
		(station.guide as CanvasItem).hide()
	# Captions are hidden during traversal because lower-row feet can pass their
	# normal static-caption band. Header remains; no labels cover the evidence.
	for index: int in range(2, labels.size()):
		labels[index].hide()
	for station: Dictionary in stations:
		set_actor(station, Vector2i(0, -64), "east")
	header.text = "BEHIND · cabinet keeps its real floor depth; no whole-body visibility cheat"
	await capture("behind-cabinets")
	for station: Dictionary in stations:
		set_actor(station, Vector2i(0, 64), "west")
	header.text = "IN FRONT · actor depth follows physical feet, not art height"
	await capture("in-front-cabinets")
	var path: Array[Vector2i] = [Vector2i(-80, 64), Vector2i(-80, -64), Vector2i(80, -64), Vector2i(80, 64), Vector2i(-80, 64)]
	header.text = "WALK-AROUND · deterministic visual path; existing four-direction locomotion only"
	for segment: int in range(path.size() - 1):
		var a := path[segment]
		var b := path[segment + 1]
		var direction := "north" if b.y < a.y else ("south" if b.y > a.y else ("east" if b.x > a.x else "west"))
		for step: int in range(33):
			var foot := Vector2i(Vector2(a).lerp(Vector2(b), float(step) / 32.0).round())
			for station: Dictionary in stations:
				set_actor(station, foot, direction, 2 + posmod(step / 4, 4))
			await process_frame
			frame_count += 1
			if step == 16 and segment in [0, 1, 2]:
				await capture("walk-segment-" + str(segment))
	for panel: PanelContainer in labels:
		panel.show()
	for station: Dictionary in stations:
		set_actor(station, station.p.service_cell * 32, station.p.approach_gaze)
	header.text = "FINAL · exact geometry candidate; service artwork and gameplay integration remain unapproved"
	await capture("final-service")
	for panel: PanelContainer in labels:
		check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(panel.get_global_rect()), "Final caption stays in viewport")
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "frames": frame_count, "painted_actor_pixel_checks": paint_checks, "depth_observations": depth_observations, "captures": captures, "profiles": exports, "worker_disabled": true, "save_access": false, "runtime_approved": false, "materials": [MATERIALS + "oak-horizontal-v1-soft.png", MATERIALS + "oak-vertical-v1-soft.png"], "limitations": ["Deterministic scripted walk is visual evidence, not production AStar/input acceptance.", "Front inserts are intentionally empty; no appliance or document detail implied.", "Coffee interaction and reaching/drinking poses remain unimplemented.", "All art stays native; service sides are not seated work facings."]}, "\t"))
	print("Modular cabinet native calibration: %d checks, %d failures, %d image outputs, %d actor pixels, %d scripted frames." % [checks, failures.size(), captures.size(), paint_checks, frame_count])
	stage.free()
	ui.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
