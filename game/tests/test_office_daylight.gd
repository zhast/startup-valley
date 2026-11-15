extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames() -> void:
	for i: int in range(6): await process_frame

func capture(name_value: String) -> Image:
	if DisplayServer.get_name() == "headless": return null
	await frames()
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var folder := ProjectSettings.globalize_path("res://tests/output/office-daylight-current")
	DirAccess.make_dir_recursive_absolute(folder)
	check(image.save_png(folder.path_join(name_value + ".png")) == OK, "Saved " + name_value)
	return image

func run() -> void:
	root.size = Vector2i(1280, 720)
	var room := TownRoom.new()
	root.add_child(room)
	check(room.load_layout(), "Existing office loads with daylight presentation")
	room.set_hire_count(1)
	var layout := room.layout_model
	var floor_before := layout.floor_cells().duplicate()
	var placements_before := room.resolved_placements.duplicate(true)
	check(not room.daylight.patches.is_empty(), "Window modules cast visible floor light")
	check(room.daylight.get_index() > room.architecture.get_index() and room.daylight.get_index() < room._prop_root.get_index(), "Light renders above floor and below props")
	for patch: Dictionary in room.daylight.patches:
		var cell: Vector2i = patch.floor_cell
		check(layout.is_floor(cell), "Light cannot create a new floor cell")
		var area := Rect2(Vector2(cell * layout.tile_size), Vector2.ONE * layout.tile_size).grow(0.01)
		for point: Vector2 in patch.polygon:
			check(area.has_point(point), "Every lit polygon stays inside its floor cell")
	room.daylight.hide()
	var before := await capture("01-before")
	room.daylight.show()
	var after := await capture("02-daylight")
	if before != null and after != null:
		check(before.get_pixel(144, 168) == after.get_pixel(144, 168), "Coffee-machine artwork remains above the daylight")
		check(before.get_pixel(336, 242) == after.get_pixel(336, 242), "Mina’s desk artwork remains above the daylight")
		var changed := 0
		for y: int in range(720):
			for x: int in range(1280):
				if before.get_pixel(x, y) != after.get_pixel(x, y):
					changed += 1
					check(layout.is_floor(Vector2i(x / 32, y / 32)), "Rendered daylight never alters walls or the exterior")
		check(changed > 1000, "Actual native render visibly changes the window floor areas")
	check(room.architecture.apply_theme("evening"), "Evening theme applies")
	await capture("03-evening")
	check(layout.floor_cells() == floor_before and room.resolved_placements == placements_before, "Light and theme changes preserve all floor and furniture geometry")
	for stage: int in range(5):
		check(layout.validate_placements(layout.resolve_placements(stage)).valid, "Hire stage %d remains valid" % stage)
	print("Office daylight: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
