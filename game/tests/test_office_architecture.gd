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
	# A GDScript error or failed assertion aborts the called coroutine without
	# necessarily giving the Godot process a nonzero exit code. Require the check
	# body to reach its final sentinel before this wrapper can report success.
	var completed: Array[bool] = [false]
	await run_checks(completed)
	check(completed[0], "Office architecture checks aborted on a script error or assertion")
	if failures.is_empty(): print("Office architecture: %d checks passed" % checks)
	quit(0 if failures.is_empty() else 1)

func run_checks(completed: Array[bool]) -> void:
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
	check_theme_kit("cafe-")
	var model := OfficeLayout.new()
	check(model.load_files(), "Load authoritative architecture model")
	var architecture := OfficeArchitecture.new()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.add_child(architecture)
	architecture.configure(model)
	check(not architecture.blockout and architecture.floor_art != null, "Game uses generated modular art, not blockout")
	check(architecture.theme_id == OfficeArchitecture.DEFAULT_THEME, "Authored room spawns the oak office theme")
	check(architecture.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Architecture uses nearest sampling")
	var cafe_floor := load(OfficeArchitecture.theme_path("cafe", "floor")) as Texture2D
	check(architecture.apply_theme("cafe") and architecture.floor_art == cafe_floor and architecture.wall_art == load(OfficeArchitecture.theme_path("cafe", "wall")) and architecture.theme_id == "cafe", "Cafe theme is spawnable without replacing the oak files")
	check(not architecture.apply_theme("loft") and architecture.theme_id == "cafe", "Unregistered themes do not swap the room")
	check(architecture.apply_theme(OfficeArchitecture.DEFAULT_THEME) and architecture.floor_art == load(ART + "floor.png"), "Oak office theme restores the base kit")
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
	check(check_catalog_rendering(), "Catalog authority check reaches its completion sentinel")
	completed[0] = true

func check_theme_kit(prefix: String) -> void:
	var dimensions := {"floor": Vector2i(128, 128), "wall": Vector2i(128, 96), "trim": Vector2i(128, 64), "window": Vector2i(160, 96), "door": Vector2i(64, 32)}
	var images: Dictionary[String, Image] = {}
	for name: String in dimensions:
		var file := prefix + name
		var texture := load(ART + file + ".png") as Texture2D
		check(texture != null, "Theme texture exists: " + file)
		if texture == null: continue
		var image := texture.get_image()
		images[name] = image
		check(image.get_size() == dimensions[name], "Theme module dimensions: " + file)
		var imported := FileAccess.get_file_as_string(ART + file + ".png.import")
		check(imported.contains("mipmaps/generate=false") and imported.contains("compress/mode=0"), "Lossless, non-mipmapped theme: " + file)
		if name in ["floor", "wall", "trim", "door"]:
			check(image.detect_alpha() == Image.ALPHA_NONE, "Opaque theme surface has no transparent pinholes: " + file)
		else:
			check(image.get_pixel(0, 0).a == 0 and image.get_pixel(159, 95).a == 0, "Theme window corners are clean alpha: " + file)
	if images.size() != 5: return
	var floor_image := images["floor"]
	for y: int in range(128):
		check(floor_image.get_pixel(0, y) == floor_image.get_pixel(127, y), prefix + "floor horizontal wrap is exact at row %d" % y)
	for x: int in range(128):
		check(floor_image.get_pixel(x, 0) == floor_image.get_pixel(x, 127), prefix + "floor vertical wrap is exact at column %d" % x)
	var wall_image := images["wall"]
	for y: int in range(96):
		check(wall_image.get_pixel(0, y) == wall_image.get_pixel(127, y), prefix + "wall horizontal wrap is exact at row %d" % y)
	var trim := images["trim"]
	for x: int in range(32):
		check(trim.get_pixel(x, 0) == trim.get_pixel(x, 31), prefix + "west cap vertical repeat")
		check(trim.get_pixel(32 + x, 0) == trim.get_pixel(32 + x, 31), prefix + "east cap vertical repeat")
	for y: int in range(32):
		check(trim.get_pixel(64, y) == trim.get_pixel(95, y), prefix + "south cap horizontal repeat")

func ambient_overlays(prop: Node2D) -> Array[OfficeAmbientOverlay]:
	var result: Array[OfficeAmbientOverlay] = []
	if prop == null: return result
	for child: Node in prop.get_children():
		if child is OfficeAmbientOverlay: result.append(child as OfficeAmbientOverlay)
	return result

func check_profile_overlays(room: TownRoom, prop_id: String) -> void:
	var placement := room.placement_by_id(prop_id)
	var prop := room.prop_node(prop_id)
	check(not placement.is_empty(), "Resolved placement exists for ambient profile: " + prop_id)
	check(prop != null, "Runtime prop exists for ambient profile: " + prop_id)
	if placement.is_empty() or prop == null: return
	var declared: Variant = placement.profile.get("ambient_overlays")
	check(declared is Array, "Resolved profile owns an ambient overlay list: " + prop_id)
	if not declared is Array: return
	var actual := ambient_overlays(prop)
	var expected := declared as Array
	check(actual.size() == expected.size(), "Runtime ambient overlays exactly match the resolved catalogue profile: " + prop_id)
	for index: int in range(mini(actual.size(), expected.size())):
		var attachment: Variant = expected[index]
		check(attachment is Dictionary, "Catalogue ambient overlay is structured: %s[%d]" % [prop_id, index])
		if not attachment is Dictionary: continue
		var definition := attachment as Dictionary
		var overlay := actual[index]
		check(overlay.atlas_row == int(definition.row), "Runtime ambient row matches catalogue: %s[%d]" % [prop_id, index])
		check(overlay.position == Vector2(OfficeLayout.vector(definition.offset)), "Runtime ambient offset matches catalogue: %s[%d]" % [prop_id, index])
		check(overlay.z_index == prop.z_index + int(definition.z_offset), "Runtime ambient depth matches catalogue: %s[%d]" % [prop_id, index])
		check(overlay.texture == PolishArt.AMBIENT_OFFICE, "Runtime ambient overlay uses the ambient atlas: %s[%d]" % [prop_id, index])

func check_catalog_rendering() -> bool:
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	root.add_child(room)
	var loaded := room.load_layout()
	check(loaded, "Load room for catalog authority check")
	if not loaded:
		room.free()
		return false
	# Reconstruct the legacy atlas-backed desk locally. It must remain catalog
	# authoritative even though normal production desks now use an exact,
	# reviewed render-layer registry.
	var desk: Dictionary = room.layout_model.catalog.desk
	desk.erase("facing_profiles")
	desk.facings = ["south"]
	desk.art = "res://assets/runtime/office/layered-furniture.png"
	desk.atlas_cell = [128, 96]
	desk.atlas_row = 1
	desk.visual_bounds = [-64, -88, 128, 96]
	# This legacy-only atlas has a wider painted edge than the admitted desk.
	# Keep the authority probe clear of the enlarged production lunch cluster;
	# normal placement still uses the unchanged current layout.
	for row: Dictionary in room.layout_model.data.props:
		if str(row.id) == "founder-workstation": row.grid = [7, 17]
	room._rebuild_props()
	var workstation := room.prop_node("mira-workstation")
	check(workstation != null, "Catalog-authoritative workstation exists")
	var front := workstation.get_node_or_null("WorkstationFront") as Sprite2D if workstation != null else null
	check(front != null, "Catalog-authoritative workstation front exists")
	if front != null:
		check(front.texture != null and front.texture.resource_path == str(desk.art), "Placed prop uses catalog art, not scene constants")
		check(front.region_rect == Rect2(128, 96, 128, 96), "Placed prop uses catalog atlas cell and row")
	# Explicit promoted profiles replace legacy scene attachments. The catalogue
	# is authoritative even when its truthful declaration is an empty list.
	check_profile_overlays(room, "coffee-station")
	check_profile_overlays(room, "research-bench")
	if room.navigation != null: room.navigation.free()
	room.free()
	return true
