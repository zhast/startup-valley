extends SceneTree

const ART := "res://assets/runtime/office/architecture/"
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)

func equal_color(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a) < 0.025

func run() -> void:
	var dimensions := {"floor": Vector2i(128, 128), "wall": Vector2i(128, 96), "trim": Vector2i(128, 64), "window": Vector2i(160, 96), "door": Vector2i(64, 32)}
	var images: Dictionary[String, Image] = {}
	for name: String in dimensions:
		var texture := load(ART + name + ".png") as Texture2D
		check(texture != null, "Architecture texture exists: " + name)
		if texture == null: continue
		var image := texture.get_image()
		images[name] = image
		check(image.get_size() == dimensions[name], "Native module dimensions: " + name)
		var imported := FileAccess.get_file_as_string(ART + name + ".png.import")
		check(imported.contains("mipmaps/generate=false") and imported.contains("compress/mode=0"), "Lossless, non-mipmapped architecture: " + name)
		if name in ["floor", "wall", "trim", "door"]:
			check(image.detect_alpha() == Image.ALPHA_NONE, "Opaque architectural surface has no transparent pinholes: " + name)
		else:
			check(image.detect_alpha() != Image.ALPHA_NONE, "Window exterior has real alpha, not a checkerboard")
			check(image.get_pixel(0, 0).a == 0 and image.get_pixel(159, 95).a == 0, "Window corners are clean alpha")
	if images.size() != 5: quit(1); return
	var floor_image := images["floor"]
	for y: int in range(128):
		check(floor_image.get_pixel(0, y) == floor_image.get_pixel(127, y), "Floor horizontal wrap is exact at row %d" % y)
	for x: int in range(128):
		check(floor_image.get_pixel(x, 0) == floor_image.get_pixel(x, 127), "Floor vertical wrap is exact at column %d" % x)
	var wall_image := images["wall"]
	for y: int in range(96):
		check(wall_image.get_pixel(0, y) == wall_image.get_pixel(127, y), "Wall horizontal wrap is exact at row %d" % y)
	var trim := images["trim"]
	for x: int in range(32):
		check(trim.get_pixel(x, 0) == trim.get_pixel(x, 31), "West cap vertical repeat")
		check(trim.get_pixel(32 + x, 0) == trim.get_pixel(32 + x, 31), "East cap vertical repeat")
	for y: int in range(32):
		check(trim.get_pixel(64, y) == trim.get_pixel(95, y), "South cap horizontal repeat")
	var model := OfficeLayout.new()
	check(model.load_files(), "Load authoritative architecture model")
	var architecture := OfficeArchitecture.new()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.add_child(architecture)
	architecture.configure(model)
	check(not architecture.blockout and architecture.floor_art != null, "Game uses generated modular art, not blockout")
	check(architecture.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Architecture uses nearest sampling")
	if DisplayServer.get_name() != "headless":
		for index: int in range(4): await process_frame
		RenderingServer.force_draw(false)
		var actual := root.get_texture().get_image()
		for cell: Vector2i in model.floor_cells():
			if model.entrance_cells().has(cell): continue
			# Test the visible tile edges as well as centers in the rendered frame.
			for offset: Vector2i in [Vector2i.ZERO, Vector2i(31, 0), Vector2i(0, 31), Vector2i(31, 31), Vector2i(16, 16)]:
				var point := cell * 32 + offset
				if point.y >= 720: continue
				check(equal_color(actual.get_pixelv(point), floor_image.get_pixel(point.x % 128, point.y % 128)), "Rendered floor is native and registered at %s" % point)
		var output := "res://tests/output/modular-office"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		check(actual.save_png(output + "/architecture-only.png") == OK, "Save actual rendered architecture evidence")
	architecture.free()
	await check_catalog_rendering()
	if failures.is_empty(): print("Office architecture: %d checks passed" % checks)
	quit(0 if failures.is_empty() else 1)

func check_catalog_rendering() -> void:
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	root.add_child(room)
	check(room.load_layout(), "Load room for catalog authority check")
	# A temporary local fixture changes the art profile only. The ghost and
	# production prop must not disagree because a scene retained old constants.
	var desk: Dictionary = room.layout_model.catalog.desk
	desk.art = "res://assets/runtime/office/layered-furniture.png"
	desk.atlas_cell = [128, 96]
	desk.atlas_row = 1
	desk.visual_bounds = [-64, -88, 128, 96]
	room._rebuild_props()
	var front := room.prop_node("mira-workstation").get_node("WorkstationFront") as Sprite2D
	check(front.texture.resource_path == str(desk.art), "Placed prop uses catalog art, not scene constants")
	check(front.region_rect == Rect2(128, 96, 128, 96), "Placed prop uses catalog atlas cell and row")
	var coffee := room.prop_node("coffee-station").get_node("AmbientOverlay") as OfficeAmbientOverlay
	var scan := room.prop_node("research-bench").get_node("ResearchScan") as OfficeAmbientOverlay
	check(coffee.position == Vector2(20, -66) and scan.position == Vector2(0, -62), "Furniture profile cannot displace separate ambient overlays")
	check(coffee.texture == PolishArt.AMBIENT_OFFICE and scan.texture == PolishArt.AMBIENT_OFFICE, "Furniture profile cannot replace ambient atlas with furniture")
	room.navigation.free()
	room.free()
