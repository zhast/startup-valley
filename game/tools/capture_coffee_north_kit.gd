extends SceneTree
## DEV native N/S comparison; existing South remains unchanged.
## No GameMain, workers, save state or fabricated drinking animation.
const KIT := preload("res://tools/coffee_north_kit_calibration.gd")
const SOUTH := preload("res://tools/coffee_south_kit_calibration.gd")
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/coffee-north-kit"
const MATERIALS := "res://tests/fixtures/furniture-calibration/materials/"
const GAZES := {"north": &"back", "east": &"right", "south": &"front", "west": &"left"}
const KINDS: Array[String] = ["bare", "south", "north"]
var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var captures: Array[String] = []
var observations: Array[Dictionary] = []
var checks := 0
var failures: Array[String] = []
var frame_count := 0
var actor_pixel_checks := 0
var h: Texture2D
var v: Texture2D
var room_model: OfficeLayout
var header: Label
var captions: Array[PanelContainer] = []
var checkpoint := ""

class Guide extends Node2D:
	var side := "north"
	func _draw() -> void:
		var p: Dictionary = CABINET.profile("counter", side)
		draw_rect(Rect2(p.floor), Color("354b98"), false, 1)
		draw_rect(Rect2(p.top_interior), Color("6196c1"), false, 1)
		for contact: Rect2i in (KIT.CONTACTS if side == "north" else SOUTH.CONTACTS).values():
			draw_rect(Rect2(contact), Color("c1fa81"), false, 1)
		draw_rect(Rect2(Vector2(p.service_cell * 32 - Vector2i(16, 16)), Vector2(32, 32)), Color("fa4616"), false, 1)

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

func label(copy: String, point: Vector2, width: int, height: int = 32) -> Label:
	var panel := PanelContainer.new()
	panel.position = point
	panel.custom_minimum_size = Vector2(width, height)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(8, 2, 8, 2)))
	ui.add_child(panel)
	captions.append(panel)
	var node := Label.new()
	node.text = copy
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(node, "meta")
	panel.add_child(node)
	return node

func assembly(parent: Node, anchor: Vector2, kind: String) -> Node2D:
	if kind == "south":
		return SOUTH.build(parent, anchor, h, v, true)
	return KIT.build(parent, anchor, h, v, kind == "north")

func actor(character_id: String, foot: Vector2, gaze: String) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = CharacterArt.locomotion_sheet(character_id)
	node.region_enabled = true
	node.region_rect = CharacterArt.locomotion_region(GAZES[gaze], 0)
	node.centered = false
	node.position = foot - Vector2(24, 72)
	node.z_as_relative = false
	node.z_index = int(foot.y)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(node)
	return node

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Approved modular room loads without GameMain or personal state")
	room_model = room.layout_model
	room.set_hire_count(0)
	room.get_node("Props").hide()
	h = texture(MATERIALS + "oak-horizontal-v1-soft.png")
	v = texture(MATERIALS + "oak-vertical-v1-soft.png")
	ui = CanvasLayer.new()
	ui.layer = 30
	root.add_child(ui)
	header = label("COFFEE NORTH / SOUTH · independent true views · no new interaction", Vector2(160, 96), 960, 36)
	for index: int in range(3):
		label(["Bare calibrated counter", "South · visible controls", "North · rear housing"][index], Vector2(144 + index * 320, 144), 256, 24)
	label("Mina above / Theo below · service side is separate from the character approach gaze", Vector2(144, 680), 1024, 28)
	actor("founder", Vector2(112, 496), "east")
	for row: int in range(2):
		for column: int in range(3):
			var kind := KINDS[column]
			var anchor := Vector2(272 + column * 320, 304 + row * 256)
			check(anchor == room_model.world(room_model.cell_at(anchor)), kind + " host is an actual32px cell center")
			var host := assembly(stage, anchor, kind)
			check(host != null, kind + " assembly created")
			var person := actor("mira" if row == 0 else "theo", anchor + Vector2(-80, 32), "south")
			var guide := Guide.new()
			guide.side = "north" if kind == "north" else "south"
			guide.position = anchor
			guide.z_as_relative = false
			guide.z_index = 1500
			guide.hide()
			stage.add_child(guide)
			stations.append({"id": kind + ("-mira" if row == 0 else "-theo"), "kind": kind,
				"anchor": anchor, "host": host, "actor": person, "guide": guide, "whole": null, "foot": anchor + Vector2(-80, 32)})

func set_actor(station: Dictionary, offset: Vector2i, gaze: String, frame: int = 0) -> void:
	var person: Sprite2D = station.actor
	var foot := Vector2i(station.anchor) + offset
	person.region_rect = CharacterArt.locomotion_region(GAZES[gaze], frame)
	person.position = Vector2(foot - Vector2i(24, 72))
	person.z_index = foot.y
	station.foot = Vector2(foot)
	check(not Rect2i(-48, -16, 96, 32).has_point(offset), station.id + " physical foot stays outside declared counter collision")
	for toe: Vector2i in [Vector2i(-10, -10), Vector2i(10, -10), Vector2i(-10, 10), Vector2i(10, 10)]:
		check(not Rect2i(-48, -16, 96, 32).has_point(offset + toe), station.id + " actor physical radius stays outside counter")
		check(room_model.is_floor(room_model.cell_at(Vector2(foot + toe))), station.id + " actor radius stays inside room floor")
	check(person.scale == Vector2.ONE and is_zero_approx(person.rotation), station.id + " native nonrotated locomotion")

func settle(count: int = 3) -> void:
	for index: int in range(count):
		await process_frame
		frame_count += 1
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw

func save(data: Image, name_value: String) -> void:
	check(data.save_png(OUTPUT.path_join(name_value)) == OK, "Save " + name_value)
	captures.append(name_value)

func export_assemblies() -> void:
	for kind: String in KINDS:
		var view := SubViewport.new()
		view.size = KIT.CANVAS
		view.transparent_bg = true
		view.disable_3d = true
		view.msaa_2d = Viewport.MSAA_DISABLED
		view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		assembly(view, Vector2(KIT.PIVOT), kind)
		await settle()
		var data := PIXELS.rgba(view.get_texture().get_image())
		check(PIXELS.analyze(data).partial_alpha_pixels == 0, kind + " assembled export has binary alpha")
		check(PIXELS.analyze(data).hidden_rgb_pixels == 0, kind + " assembled export clean padding")
		save(data, kind + "-assembly.png")
		for station: Dictionary in stations:
			if station.kind == kind:
				station.whole = data
		view.free()
	var expected := PIXELS.binary_over(stations[0].whole, KIT.image())
	check(expected.get_data() == (stations[2].whole as Image).get_data(), "Rendered North is exact bare geometry plus unchanged registered kit pixels")
	var expected_south := PIXELS.binary_over(stations[0].whole, SOUTH.image())
	check(expected_south.get_data() == (stations[1].whole as Image).get_data(), "Existing South is exact same bare geometry plus unchanged original kit")

func verify(shot: Image, station: Dictionary) -> void:
	var person: Sprite2D = station.actor
	var pose := person.texture.get_image().get_region(Rect2i(person.region_rect))
	var body: Image = station.whole
	var hidden := 0
	var projected := 0
	var mismatches := 0
	var samples := 0
	for y: int in range(80):
		for x: int in range(48):
			var color := pose.get_pixel(x, y)
			if color.a < 0.99: continue
			var point := Vector2i(person.position) + Vector2i(x, y)
			var local := point - Vector2i(station.anchor) + KIT.PIVOT
			var expected := color
			if Rect2i(Vector2i.ZERO, KIT.CANVAS).has_point(local):
				var covering := body.get_pixelv(local)
				if covering.a > 0.99:
					projected += 1
					if person.z_index < int(station.anchor.y):
						expected = covering
						hidden += 1
			var actual := shot.get_pixelv(point)
			if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01:
				mismatches += 1
			samples += 1
	actor_pixel_checks += samples
	check(samples > 0 and mismatches == 0, station.id + " actual native actor/assembly depth pixels; mismatches=" + str(mismatches))
	if Vector2i(station.foot - station.anchor) == Vector2i(0, -32):
		check(hidden > 0, station.id + " close north actor is honestly occluded")
	if station.foot.y > station.anchor.y:
		check(hidden == 0, station.id + " front actor is never buried by counter")
	var actor_rect := pose.get_used_rect()
	actor_rect.position += Vector2i(person.position)
	var body_rect := body.get_used_rect()
	body_rect.position += Vector2i(station.anchor) - KIT.PIVOT
	for panel: PanelContainer in captions:
		check(not panel.get_global_rect().intersects(Rect2(actor_rect)) and not panel.get_global_rect().intersects(Rect2(body_rect)), station.id + " diagnostic captions do not overlap actual art")
	observations.append({"checkpoint": checkpoint, "id": station.id, "foot_offset": [station.foot.x - station.anchor.x, station.foot.y - station.anchor.y],
		"source_actor_pixels": samples, "projected_over_assembly": projected, "hidden_by_assembly": hidden, "pixel_mismatches": mismatches})

func capture(name_value: String, details: bool = false, verify_paint: bool = true) -> void:
	checkpoint = name_value
	await settle()
	var shot := root.get_texture().get_image()
	check(shot.get_size() == Vector2i(1280, 720), name_value + " native1280×720 viewport")
	save(shot, name_value + ".png")
	for station: Dictionary in stations:
		if verify_paint: verify(shot, station)
		if details:
			var crop := shot.get_region(Rect2i(Vector2i(station.anchor) + Vector2i(-112, -136), Vector2i(224, 224)))
			crop.resize(896, 896, Image.INTERPOLATE_NEAREST)
			save(crop, name_value + "-" + station.id + "-4x.png")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This visual capture requires the native renderer. Use test_coffee_north_kit.gd headlessly.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	build()
	await export_assemblies()
	await capture("native-comparison", true)
	for station: Dictionary in stations: set_actor(station, Vector2i(0, -32) if station.kind == "north" else Vector2i(0, 32), "south" if station.kind == "north" else "north")
	header.text = "SERVICE APPROACH · existing standing art only · no drinking/reaching behavior"
	await capture("service-approach", true)
	for station: Dictionary in stations:
		if station.kind != "bare": (station.guide as CanvasItem).show()
	header.text = "N/S SUPPORT HYPOTHESES · physical180° floor turn, not a rotated raised bitmap"
	await capture("support-guides", true, false)
	for station: Dictionary in stations:
		(station.guide as CanvasItem).hide()
		set_actor(station, Vector2i(0, -32), "south")
	header.text = "CLOSE BEHIND · solid cabinet keeps floor depth · hidden bodies are intentional"
	await capture("close-behind", true)
	for station: Dictionary in stations: set_actor(station, Vector2i(0, 64), "west")
	header.text = "IN FRONT · no counter-over-person depth inversion"
	await capture("in-front", true)
	var path: Array[Vector2i] = [Vector2i(-80, 64), Vector2i(-80, -64), Vector2i(80, -64), Vector2i(80, 64), Vector2i(-80, 64)]
	header.text = "SCRIPTED VISUAL WALK · four existing poses · not a navigation/input acceptance test"
	for segment: int in range(path.size() - 1):
		var a := path[segment]
		var b := path[segment + 1]
		var gaze := "north" if b.y < a.y else ("south" if b.y > a.y else ("east" if b.x > a.x else "west"))
		for step: int in range(33):
			var foot := Vector2i(Vector2(a).lerp(Vector2(b), float(step) / 32.0).round())
			for station: Dictionary in stations: set_actor(station, foot, gaze, 2 + posmod(step / 4, 4))
			await process_frame
			frame_count += 1
			if step in [0, 16, 32]: await capture("walk-%d-%d" % [segment, step])
	for station: Dictionary in stations: set_actor(station, Vector2i(0, -32) if station.kind == "north" else Vector2i(0, 32), "south" if station.kind == "north" else "north")
	header.text = "FINAL CANDIDATE · native source retained · camera/interaction approval still pending"
	await capture("final-service")
	for station: Dictionary in stations:
		set_actor(station, Vector2i(32, -32) if station.kind == "north" else Vector2i(-32, 32), "south" if station.kind == "north" else "north")
	header.text = "MACHINE-ALIGNED PROPOSAL · N right / S left service cell · no behavior or navigation change"
	await capture("machine-aligned-proposal", true)
	var file := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "frames": frame_count, "captures": captures,
		"actor_pixel_checks": actor_pixel_checks, "depth_observations": observations, "parts": KIT.records(),
		"north_source": KIT.SOURCE, "north_sha256": FileAccess.get_sha256(KIT.SOURCE), "south_source": SOUTH.SOURCE, "south_sha256": FileAccess.get_sha256(SOUTH.SOURCE), "south_parts": SOUTH.records(), "runtime_approved": false,
		"worker_started": false, "save_access": false, "contact_regions_are_hypotheses": true,
		"limitations": ["No new coffee interaction or drinking/reaching pose.", "Scripted visual walk is not canonical path/input proof.", "North service means South approach gaze; South service means North approach gaze.", "Bare counter front is intentionally unfinished; no production replacement.", "The independently authored N/S views support identity comparison but do not recover hidden appliance depth; contact boxes remain hypotheses. E/W are not shown or approved."]}, "\t"))
	print("Coffee north/south native room: %d checks, %d failures, %d PNGs, %d actor pixels, %d scripted frames." % [checks, failures.size(), captures.size(), actor_pixel_checks, frame_count])
	stage.free()
	ui.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
