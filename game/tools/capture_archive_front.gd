extends SceneTree
## DEV-only native insert/volume comparison. No worker, GameMain, save or
## production art registration. This is not a new Studio interaction test.
const CABINET := preload("res://tools/modular_cabinet_geometry.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const FIX := "res://tests/fixtures/furniture-calibration/"
const OUTPUT := "res://tests/output/archive-front"
const SOURCE := "res://assets/source/overnight-20260904/kits/archive-service-south-insert-v1.png"
const INSERT := FIX + "kits/archive-service-south-insert-v1.png"
const REGISTERED := FIX + "kits/archive-service-south-insert-v1-registered.png"
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var stage: Node2D
var ui: CanvasLayer
var stations: Array[Dictionary] = []
var insert_image: Image
var measurements: Dictionary
var panel_labels: Array[PanelContainer] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, copy: String) -> void:
	checks += 1
	if not ok:
		failures.append(copy)
		push_error(copy)

func texture(path: String) -> Texture2D:
	var data := Image.load_from_file(ProjectSettings.globalize_path(path))
	check(data != null and not data.is_empty(), "Load actual source: " + path)
	return ImageTexture.create_from_image(data)

func preflight() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	check(source != null and source.get_size() == Vector2i(1572, 1001), "Retained generated source dimensions")
	insert_image = Image.load_from_file(ProjectSettings.globalize_path(INSERT))
	check(insert_image.get_size() == Vector2i(88, 56), "Exact front socket canvas")
	check(insert_image.get_used_rect() == Rect2i(0, 1, 88, 54), "Uniform88x54 face retains two honest padding rows")
	measurements = PIXELS.analyze(insert_image)
	check(measurements.opaque_pixels == 4752 and measurements.transparent_pixels == 176, "No hidden background inside opaque face; only two padding rows")
	check(measurements.partial_alpha_pixels == 0 and measurements.hidden_rgb_pixels == 0, "Binary alpha and empty RGB padding")
	check(measurements.opaque_colors <= 24, "Deliberate compact native palette")
	var combined := Image.create(192, 288, false, Image.FORMAT_RGBA8)
	combined.fill(Color(0, 0, 0, 0))
	combined.blit_rect(insert_image, Rect2i(0, 0, 88, 56), Vector2i(52, 180))
	var registered := Image.load_from_file(ProjectSettings.globalize_path(REGISTERED))
	registered.convert(Image.FORMAT_RGBA8)
	check(registered.get_data() == combined.get_data(), "Full192x288 pivot96,224 registered source ownership is byte exact")
	var panel_texture := ImageTexture.create_from_image(insert_image)
	for side: String in CABINET.SIDES:
		var cabinet := CABINET.new()
		check(cabinet.configure("archive", side), "Explicit side geometry: " + side)
		check(cabinet.set_service_insert(panel_texture) == (side == "south"), "Front insert is accepted only on visible service south: " + side)
		check(cabinet.resolved.approach_gaze == {"north": "south", "east": "west", "south": "north", "west": "east"}[side], "Service side and actor gaze stay separate")
		cabinet.free()

func label(copy: String, at: Vector2, width: int) -> void:
	var panel := PanelContainer.new()
	panel.position = at
	panel.custom_minimum_size = Vector2(width, 42)
	panel.add_theme_stylebox_override("panel", CozyUI.paper(Vector4(8, 6, 8, 6)))
	ui.add_child(panel)
	panel_labels.append(panel)
	var text := Label.new()
	text.text = copy
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUI.label(text, "meta")
	panel.add_child(text)

func build() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	stage.add_child(room)
	check(room.load_layout(), "Approved modular room loads")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	ui = CanvasLayer.new()
	ui.layer = 30
	root.add_child(ui)
	label("ARCHIVE · legacy / exact bare volume / new service-south insert", Vector2(144, 112), 960)
	label("Native1x · south access, north gaze · staged art, no production replacement", Vector2(208, 620), 832)
	var h := texture(FIX + "materials/oak-horizontal-v1-soft.png")
	var v := texture(FIX + "materials/oak-vertical-v1-soft.png")
	for column: int in range(3):
		var anchor := Vector2(272 + column * 320, 368)
		var body: Node2D
		if column == 0:
			var legacy := Sprite2D.new()
			legacy.texture = texture("res://assets/runtime/office/artifact-archive.png")
			legacy.offset = Vector2(0, -43)
			legacy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			body = legacy
		else:
			var cabinet := CABINET.new()
			check(cabinet.configure("archive", "south", h, v), "Exact64px rise and96x32 floor")
			if column == 2:
				check(cabinet.set_service_insert(ImageTexture.create_from_image(insert_image)), "Native panel fits without scaling")
			body = cabinet
		body.position = anchor
		body.z_as_relative = false
		body.z_index = int(anchor.y)
		stage.add_child(body)
		check(body.scale == Vector2.ONE and is_zero_approx(body.rotation), "No runtime transforms of furniture")
		var actor := Sprite2D.new()
		actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		actor.region_enabled = true
		actor.centered = false
		actor.z_as_relative = false
		actor.hide()
		stage.add_child(actor)
		stations.append({"column": column, "anchor": anchor, "body": body, "actor": actor})
		label(["Legacy · wider art, shallow roof", "Bare candidate · incomplete", "Front insert · independent texture"][column], Vector2(anchor.x - 152, 476), 304)
		for corner: Vector2 in [anchor + Vector2(-68, -90), anchor + Vector2(68, 16)]:
			check(room.layout_model.is_floor(room.layout_model.cell_at(corner)), "Visible cabinet stays inside actual room floor")

func set_actors(id: String, offset: Vector2i, gaze: StringName) -> void:
	for station: Dictionary in stations:
		var actor: Sprite2D = station.actor
		actor.texture = CharacterArt.locomotion_sheet(id)
		actor.region_rect = CharacterArt.locomotion_region(gaze, 0)
		var feet := Vector2i(station.anchor) + offset
		actor.position = Vector2(feet - Vector2i(24, 72))
		actor.z_index = feet.y
		actor.show()
		check(not Rect2i(-48, -16, 96, 32).has_point(offset), "Scale-reference feet stay outside floor volume")

func capture(name_value: String, verify_panel: bool = false) -> void:
	for index: int in range(3): await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	check(shot.get_size() == Vector2i(1280, 720), "Native1280x720 capture")
	check(shot.save_png(OUTPUT.path_join(name_value + ".png")) == OK, "Save " + name_value)
	captures.append(name_value + ".png")
	var crop := shot.get_region(Rect2i(816, 248, 192, 208))
	crop.resize(768, 832, Image.INTERPOLATE_NEAREST)
	check(crop.save_png(OUTPUT.path_join(name_value + "-4x.png")) == OK, "Save nearest-neighbor detail")
	captures.append(name_value + "-4x.png")
	if verify_panel:
		var mismatch := 0
		var anchor: Vector2 = stations[2].anchor
		for y: int in range(1, 55):
			for x: int in range(88):
				var actual := shot.get_pixelv(Vector2i(anchor) + Vector2i(-44 + x, -44 + y))
				var expected := insert_image.get_pixel(x, y)
				if absf(actual.r - expected.r) > 0.01 or absf(actual.g - expected.g) > 0.01 or absf(actual.b - expected.b) > 0.01: mismatch += 1
		check(mismatch == 0, "All4752 opaque front pixels render at native coordinates, mismatches=" + str(mismatch))
	for panel: PanelContainer in panel_labels:
		check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Caption remains on screen")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	preflight()
	if DisplayServer.get_name() != "headless" and failures.is_empty():
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)
		build()
		await capture("unoccupied", true)
		for id: String in ["mira", "theo"]:
			set_actors(id, Vector2i(-80, 16), &"front")
			await capture(id + "-standing-scale", true)
			set_actors(id, Vector2i(0, 32), &"back")
			await capture(id + "-service-south")
			set_actors(id, Vector2i(0, -32), &"front")
			await capture(id + "-behind")
		stage.free()
		ui.free()
		await process_frame
	var report := {"status": "staged_south_insert_not_runtime_approved", "checks": checks, "failures": failures, "source": SOURCE, "source_sha256": FileAccess.get_sha256(SOURCE), "native": INSERT, "measurements": measurements, "captures": captures, "service_side": "south", "approach_gaze": "north", "panel_size": [88, 56], "ink_bounds": [0, 1, 88, 54], "canvas": [192, 288], "pivot": [96, 224], "worker_disabled": true, "save_access": false, "limitations": ["Only service-south artwork exists; other service sides retain bare calibration volume.", "Actors are sprite scale/depth references, not a new interaction or navigation test.", "Generated front did not follow exact compartment widths; uniform native aspect is preserved.", "No new archive action, production registration, or automatic approval."]}
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("Archive front: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
