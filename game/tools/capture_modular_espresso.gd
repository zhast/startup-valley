extends SceneTree
## DEV-only espresso box/face feasibility; no full kit, service action or registry.
const ESPRESSO := preload("res://tools/modular_espresso_geometry.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/modular-espresso"
const EXPORT := "res://tests/fixtures/furniture-calibration/modular-espresso-v1"
const MATERIALS := "res://tests/fixtures/furniture-calibration/materials/"
const GAZES := {"north": &"back", "east": &"right", "south": &"front", "west": &"left"}
var stage: Node2D
var ui: CanvasLayer
var header: Label
var room_model: OfficeLayout
var stations: Array[Dictionary] = []
var captures: Array[String] = []
var source_records: Array[Dictionary] = []
var measurements: Array[Dictionary] = []
var depth_observations: Array[Dictionary] = []
var h: Texture2D
var v: Texture2D
var checks := 0
var failures: Array[String] = []
var frames := 0
var actor_pixels := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func texture(path: String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))

func label(copy: String, point: Vector2, width: int, height: int = 28) -> Label:
	var frame := PanelContainer.new()
	frame.position = point
	frame.custom_minimum_size = Vector2(width, height)
	frame.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(8, 2, 8, 2)))
	ui.add_child(frame)
	var result := Label.new()
	result.text = copy
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(result, "meta")
	frame.add_child(result)
	return result

func assembly(parent: Node, point: Vector2, side: String) -> Node2D:
	var host := Node2D.new()
	host.position = point
	host.z_as_relative = false
	host.z_index = int(point.y)
	parent.add_child(host)
	var counter := CABINET.new()
	host.add_child(counter)
	check(counter.configure("counter", side, h, v), side + " exact unchanged counter")
	var machine := ESPRESSO.new()
	machine.name = "Espresso"
	machine.position = Vector2(0, -32)
	host.add_child(machine)
	check(machine.configure(side), side + " generated interior on exact machine geometry")
	return host

func actor(character_id: String, foot: Vector2, gaze: String) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = CharacterArt.locomotion_sheet(character_id)
	result.region_enabled = true
	result.region_rect = CharacterArt.locomotion_region(GAZES[gaze], 0)
	result.centered = false
	result.position = foot - Vector2(24, 72)
	result.z_as_relative = false
	result.z_index = int(foot.y)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(result)
	return result

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Approved actual room loads without GameMain/save/worker")
	room_model = room.layout_model
	room.set_hire_count(0)
	room.get_node("Props").hide()
	h = texture(MATERIALS + "oak-horizontal-v1-soft.png")
	v = texture(MATERIALS + "oak-vertical-v1-soft.png")
	ui = CanvasLayer.new()
	ui.layer = 30
	root.add_child(ui)
	header = label("ESPRESSO VOLUME STUDY · code-native box + interior materials · NOT a full coffee kit", Vector2(144, 96), 960, 36)
	for column: int in range(4):
		label(["North · rear hatch", "East · side vents", "South · controls", "West · fasteners"][column], Vector2(108 + column * 256, 148), 200)
	label("Mina above / Theo below · all 4 faces staged · no new coffee animation, navigation or action", Vector2(112, 680), 1008)
	for row: int in range(2):
		for column: int in range(4):
			var side := ESPRESSO.SIDES[column]
			var anchor := Vector2(208 + column * 256, 336 + row * 256)
			check(anchor == room_model.world(room_model.cell_at(anchor)), side + " host at actual grid center")
			var host := assembly(stage, anchor, side)
			var id := "mira" if row == 0 else "theo"
			var person := actor(id, anchor + Vector2(-64, 32), "south")
			stations.append({"id": side + "-" + id, "side": side, "anchor": anchor, "host": host,
				"actor": person, "foot": anchor + Vector2(-64, 32), "whole": null})
	actor("founder", Vector2(96, 448), "east")

func settle(count: int = 3) -> void:
	for index: int in range(count):
		await process_frame
		frames += 1
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw

func save(data: Image, path: String) -> void:
	check(data.save_png(path) == OK, "Save " + path)
	check(PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path))).get_data() == PIXELS.rgba(data).get_data(), "Exact PNG roundtrip " + path)
	captures.append(path)

func view(size_value: Vector2i) -> SubViewport:
	var result := SubViewport.new()
	result.size = size_value
	result.transparent_bg = true
	result.disable_3d = true
	result.msaa_2d = Viewport.MSAA_DISABLED
	result.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	result.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(result)
	return result

func export_all() -> void:
	for side: String in ESPRESSO.SIDES:
		var images: Dictionary = {}
		var record: Dictionary = ESPRESSO.face_source(side)
		source_records.append({"side": side, "source": record.source, "sha256": record.source_sha256, "crop": PIXELS.rect_values(record.crop),
			"native_size": [record.native_size.x, record.native_size.y], "factor": record.uniform_scale,
			"minimum_original_alpha": record.minimum_original_alpha, "interior_opacity_normalized": record.interior_opacity_normalized,
			"whole_source_alpha_accepted": record.whole_source_alpha_accepted})
		save(record.image, EXPORT.path_join(side + "-face-material.png"))
		for name_value: String in ["whole", "Top", "Housing", "Face"]:
			var viewport := view(ESPRESSO.CANVAS)
			var machine := ESPRESSO.new()
			machine.position = Vector2(ESPRESSO.PIVOT)
			viewport.add_child(machine)
			check(machine.configure(side), side + " native isolated " + name_value)
			if name_value != "whole":
				for layer: String in ESPRESSO.LAYERS: (machine.layers[layer] as CanvasItem).visible = layer == name_value
			await settle()
			var data := PIXELS.rgba(viewport.get_texture().get_image())
			var alpha := PIXELS.analyze(data)
			check(alpha.partial_alpha_pixels == 0 and alpha.hidden_rgb_pixels == 0 and alpha.transparent_pixels > 0, side + " exact clean alpha " + name_value)
			images[name_value] = data
			save(data, EXPORT.path_join(side + "-" + name_value.to_lower() + ".png"))
			viewport.free()
		var reconstructed := PIXELS.binary_over(PIXELS.binary_over(images.Top, images.Housing), images.Face)
		check(reconstructed.get_data() == (images.whole as Image).get_data(), side + " all registered source layers reconstruct whole byte-exact")
		var p: Dictionary = ESPRESSO.profile(side)
		var actual: Dictionary = PIXELS.analyze(images.whole)
		check(actual.opaque_bounds == PIXELS.rect_values(Rect2i(p.visual_bounds.position + ESPRESSO.PIVOT, p.visual_bounds.size)), side + " visible volume exactly matches independent geometry")
		var detail := (images.whole as Image).duplicate() as Image
		detail.resize(ESPRESSO.CANVAS.x * 4, ESPRESSO.CANVAS.y * 4, Image.INTERPOLATE_NEAREST)
		save(detail, OUTPUT.path_join(side + "-appliance-4x.png"))
		measurements.append({"side": side, "geometry": PIXELS.rect_values(p.visual_bounds), "alpha": actual, "runtime_approved": false})
		var host_view := view(Vector2i(192, 256))
		assembly(host_view, Vector2(96, 192), side)
		await settle()
		var combined := PIXELS.rgba(host_view.get_texture().get_image())
		save(combined, OUTPUT.path_join(side + "-counter-assembly.png"))
		for station: Dictionary in stations:
			if station.side == side: station.whole = combined
		host_view.free()

func set_actor(station: Dictionary, offset: Vector2i, gaze: String, frame: int = 0) -> void:
	var foot := Vector2i(station.anchor) + offset
	var person: Sprite2D = station.actor
	person.region_rect = CharacterArt.locomotion_region(GAZES[gaze], frame)
	person.position = Vector2(foot - Vector2i(24, 72))
	person.z_index = foot.y
	station.foot = Vector2(foot)
	var floor_rect: Rect2i = CABINET.profile("counter", station.side).floor
	for corner: Vector2i in [Vector2i(-10, -10), Vector2i(10, -10), Vector2i(-10, 10), Vector2i(10, 10)]:
		check(not floor_rect.has_point(offset + corner), station.id + " scripted physical radius outside counter")
		check(room_model.is_floor(room_model.cell_at(Vector2(foot + corner))), station.id + " scripted radius stays on room floor")

func verify_depth(screen: Image, checkpoint: String) -> void:
	for station: Dictionary in stations:
		var person: Sprite2D = station.actor
		var body := PIXELS.rgba(person.texture.get_image()).get_region(Rect2i(person.region_rect))
		var whole: Image = station.whole
		var origin := Vector2i(station.anchor) - Vector2i(96, 192)
		var mismatches := 0
		var hidden := 0
		for y: int in range(body.get_height()):
			for x: int in range(body.get_width()):
				var body_color := body.get_pixel(x, y)
				if body_color.a < 0.99: continue
				var at := Vector2i(person.position) + Vector2i(x, y)
				var local := at - origin
				var expected := body_color
				if Rect2i(Vector2i.ZERO, whole.get_size()).has_point(local):
					var machine_color := whole.get_pixelv(local)
					if machine_color.a > 0.99 and station.foot.y < station.anchor.y:
						expected = machine_color
						hidden += 1
				actor_pixels += 1
				if screen.get_pixelv(at) != expected: mismatches += 1
		check(mismatches == 0, station.id + " actual opaque depth " + checkpoint)
		depth_observations.append({"checkpoint": checkpoint, "station": station.id, "hidden": hidden, "mismatches": mismatches})

func capture(name_value: String, details: bool = false) -> void:
	await settle()
	var screen := PIXELS.rgba(root.get_texture().get_image())
	check(screen.get_size() == Vector2i(1280, 720), "Native actual room capture")
	verify_depth(screen, name_value)
	save(screen, OUTPUT.path_join(name_value + ".png"))
	if details:
		for station: Dictionary in stations:
			var box := Rect2i(Vector2i(station.anchor) - Vector2i(88, 152), Vector2i(176, 224))
			var detail := screen.get_region(box)
			detail.resize(box.size.x * 4, box.size.y * 4, Image.INTERPOLATE_NEAREST)
			save(detail, OUTPUT.path_join(name_value + "-" + str(station.id) + "-4x.png"))

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use test_modular_espresso_geometry.gd headlessly; this source-based evidence needs a native renderer.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EXPORT))
	build()
	await export_all()
	await capture("native-four-views", true)
	for station: Dictionary in stations:
		var p: Dictionary = CABINET.profile("counter", station.side)
		set_actor(station, p.service_cell * 32, p.approach_gaze)
	header.text = "SERVICE SIDE · existing standing poses · no reaching, pouring or drinking claim"
	await capture("service-approach", true)
	for station: Dictionary in stations: set_actor(station, Vector2i(0, -64), "south")
	header.text = "BEHIND SOLID COUNTER · exact depth · no whole-object lowering to reveal actors"
	await capture("behind", true)
	for station: Dictionary in stations: set_actor(station, Vector2i(0, 64), "north")
	header.text = "FRONT · existing back-standing pose remains in front of the counter"
	await capture("in-front")
	var route: Array[Vector2i] = [Vector2i(-64, 64), Vector2i(-64, -64), Vector2i(64, -64), Vector2i(64, 64), Vector2i(-64, 64)]
	header.text = "SCRIPTED WALKAROUND · exact radius checks · not canonical navigation or input"
	for segment: int in range(4):
		for tick: int in range(9):
			var point := Vector2(route[segment]).lerp(Vector2(route[segment + 1]), float(tick) / 8.0).round()
			for station: Dictionary in stations: set_actor(station, Vector2i(point), ["north", "east", "south", "west"][segment], tick % 4)
			if tick in [0, 4, 8]: await capture("walk-%d-%d" % [segment, tick])
			else: await settle(1)
	for source: Dictionary in source_records: check(FileAccess.get_sha256(source.source) == source.sha256, source.side + " original source unchanged")
	var report := {"checks": checks, "failures": failures, "captures": captures, "frames": frames, "actor_pixel_checks": actor_pixels,
		"views": measurements, "sources": source_records, "depth_observations": depth_observations,
		"runtime_approved": false, "worker_started": false, "save_access": false,
		"limitations": ["Only exact espresso geometry/material interiors, not a full four-direction coffee kit.",
			"Failed E/W source silhouettes remain opaque and unusable; only wholly interior rectangles are used.",
			"Counter front unfinished, no new service action or character hand poses.", "Scripted motion is not canonical AStar/editor/input evidence."]}
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file = FileAccess.open(EXPORT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	stage.free()
	ui.free()
	await process_frame
	print("Modular espresso native: %d checks, %d failures; %d PNGs, %d depth pixels; staged only." % [checks, failures.size(), captures.size(), actor_pixels])
	quit(0 if failures.is_empty() else 1)
