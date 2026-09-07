extends SceneTree
## DEV-ONLY native review of imported candidate layers in the actual GameMain
## TownRoom. No worker, save, production registration, or new coffee action.
const COFFEE := preload("res://tools/coffee_station_geometry.gd")
const FIXTURE := preload("res://tools/coffee_station_candidate_fixture.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/coffee-station-candidate"
var fixture: Node
var ui: CanvasLayer
var header: Label
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var depth_observations: Array[Dictionary] = []
var exact_prop_pixels := 0
var actor_pixels := 0
var frames := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle(count: int = 3) -> void:
	for frame: int in range(count):
		await process_frame
		frames += 1
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw

func save(image: Image, name_value: String) -> void:
	var path := OUTPUT.path_join(name_value)
	check(image.save_png(path) == OK, "Save native evidence " + path)
	var roundtrip := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(roundtrip != null and PIXELS.rgba(roundtrip).get_data() == PIXELS.rgba(image).get_data(), "Exact evidence PNG roundtrip " + name_value)
	captures.append(name_value)

func build_header() -> void:
	ui = CanvasLayer.new()
	ui.layer = 50
	root.add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(132, 96)
	panel.custom_minimum_size = Vector2(1016, 48)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(12, 6, 12, 6)))
	ui.add_child(panel)
	header = Label.new()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	CozyUI.label(header, "body")
	panel.add_child(header)

func whole_texture(side: String) -> Image:
	return (load(FIXTURE.EXPORT + side + "-whole.png") as Texture2D).get_image()

func verify_prop(screen: Image, side: String) -> void:
	var placement: Dictionary = fixture.main.room.placement_by_id("coffee-station")
	var anchor := Vector2i(placement.anchor)
	var whole := whole_texture(side)
	var mismatches := 0
	var samples := 0
	for y: int in range(whole.get_height()):
		for x: int in range(whole.get_width()):
			var expected := whole.get_pixel(x, y)
			if expected.a < 0.99: continue
			var point := anchor - COFFEE.PIVOT + Vector2i(x, y)
			var actual := screen.get_pixelv(point)
			if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01: mismatches += 1
			samples += 1
	exact_prop_pixels += samples
	check(samples > 2500 and mismatches == 0, side + " actual TownRoom equals imported registered layers; samples=" + str(samples) + " mismatches=" + str(mismatches))

func verify_actor_depth(screen: Image, side: String) -> void:
	var player: PlayerAvatar = fixture.main.player
	var sprite := player.get_node("CharacterSprite") as Sprite2D
	var pose := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
	var placement: Dictionary = fixture.main.room.placement_by_id("coffee-station")
	var anchor := Vector2i(placement.anchor)
	var whole := whole_texture(side)
	var origin := anchor - COFFEE.PIVOT
	var body_origin := Vector2i(player.position.round()) - Vector2i(24, 72)
	var hidden := 0
	var mismatches := 0
	var samples := 0
	for y: int in range(pose.get_height()):
		for x: int in range(pose.get_width()):
			var expected := pose.get_pixel(x, y)
			if expected.a < 0.99: continue
			var point := body_origin + Vector2i(x, y)
			var local := point - origin
			if player.z_index < int(placement.anchor.y) and Rect2i(Vector2i.ZERO, COFFEE.CANVAS).has_point(local):
				var cover := whole.get_pixelv(local)
				if cover.a > 0.99:
					expected = cover
					hidden += 1
			var actual := screen.get_pixelv(point)
			if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01: mismatches += 1
			samples += 1
	actor_pixels += samples
	check(samples > 1000 and mismatches == 0, side + " actual standing actor/candidate depth; hidden=" + str(hidden) + " mismatches=" + str(mismatches))
	if side == "north": check(hidden > 250, "North rear service honestly occludes the nearby actor")
	else: check(hidden == 0, side + " actor at side/front service is not falsely hidden")
	depth_observations.append({"side": side, "actor_samples": samples, "hidden_by_station": hidden, "mismatches": mismatches})

func crop_detail(screen: Image, anchor: Vector2i, name_value: String) -> void:
	var source := Rect2i(anchor - Vector2i(112, 144), Vector2i(224, 208))
	var detail := screen.get_region(source)
	detail.resize(source.size.x * 4, source.size.y * 4, Image.INTERPOLATE_NEAREST)
	save(detail, name_value)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Coffee room review needs a rendered backend; use test_coffee_station_candidate.gd headlessly.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	fixture = FIXTURE.new()
	# Keep all four 3x1/1x3 footprints and service cells out of the authored
	# central cross-aisle while placing the review near the viewport center.
	fixture.initial_grid = Vector2i(22, 15)
	fixture.initial_facing = "north"
	root.add_child(fixture)
	await settle(4)
	check(fixture.ready_ok and fixture.errors.is_empty(), "Actual-room fixture starts: " + str(fixture.errors))
	if not fixture.ready_ok:
		quit(1)
		return
	fixture.main.get_node("Interface").hide()
	build_header()
	var player: PlayerAvatar = fixture.main.player
	var empty_images: Dictionary = {}
	var service_images: Dictionary = {}
	for side: String in COFFEE.SIDES:
		check(fixture.set_facing(side), side + " facing rebuilds through actual TownRoom")
		player.cancel_route()
		player.input_blocked = false
		player.position = fixture.model.world(Vector2i(5, 16))
		player.z_index = int(player.position.y)
		fixture.main.room.navigation.actors["founder"] = player.position
		header.text = "COFFEE STATION · %s service · deterministic native layers · production unchanged" % side.to_upper()
		await settle()
		var screen := PIXELS.rgba(root.get_texture().get_image())
		check(screen.get_size() == Vector2i(1280, 720), side + " native1280×720 actual-room frame")
		verify_prop(screen, side)
		save(screen, side + "-room-native.png")
		empty_images[side] = screen
		var placement: Dictionary = fixture.main.room.placement_by_id("coffee-station")
		crop_detail(screen, Vector2i(placement.anchor), side + "-room-4x.png")
		player.position = fixture.model.world(placement.interaction)
		player.z_index = int(player.position.y)
		player.face_direction(fixture.main.room.interaction_approach_direction("coffee-station"))
		fixture.main.room.navigation.actors["founder"] = player.position
		header.text = "%s SERVICE · exact approach cell / opposite gaze · existing standing pose, no coffee action" % side.to_upper()
		await settle()
		var service := PIXELS.rgba(root.get_texture().get_image())
		verify_actor_depth(service, side)
		save(service, side + "-service-native.png")
		service_images[side] = service
		crop_detail(service, Vector2i(placement.anchor), side + "-service-4x.png")
	var empty_sheet := Image.create(2560, 1440, false, Image.FORMAT_RGBA8)
	var service_sheet := Image.create(2560, 1440, false, Image.FORMAT_RGBA8)
	for index: int in range(COFFEE.SIDES.size()):
		var side: String = COFFEE.SIDES[index]
		var destination := Vector2i((index % 2) * 1280, (index / 2) * 720)
		empty_sheet.blit_rect(empty_images[side], Rect2i(0, 0, 1280, 720), destination)
		service_sheet.blit_rect(service_images[side], Rect2i(0, 0, 1280, 720), destination)
	save(empty_sheet, "all-four-room-native.png")
	save(service_sheet, "all-four-service-native.png")
	var manifest := {"checks": checks, "failures": failures, "captures": captures,
		"native_room": "actual GameMain/TownRoom with owner-scoped calibration admission and imported registered layers",
		"exact_prop_pixels": exact_prop_pixels, "actor_pixels": actor_pixels, "depth_observations": depth_observations,
		"frames": frames, "runtime_registered": false, "catalogue_changed": false,
		"new_interaction": false, "worker_disabled": true, "save_access": false,
		"limitations": ["Standing frames reuse existing locomotion; they are scale/depth references, not reaching or drinking animations.", "The fixture validates the existing service profile path but intentionally does not invent a coffee action.", "Production catalogue and normal room placement remain unchanged."]}
	var file := FileAccess.open(OUTPUT.path_join("room-manifest.json"), FileAccess.WRITE)
	check(file != null, "Open room evidence manifest")
	manifest.checks = checks
	manifest.failures = failures
	if file != null: file.store_string(JSON.stringify(manifest, "\t") + "\n")
	fixture.free()
	ui.free()
	await process_frame
	print("Coffee station room review: %d checks, %d failures, %d captures; candidate only." % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
