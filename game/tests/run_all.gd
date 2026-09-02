extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://world/main.tscn")
const OUTPUT_PATH := "res://tests/output/test_worker_walks_to_desk.png"
const BASELINE_PATH := "res://tests/baselines/test_worker_walks_to_desk.png"

var _failures: int = 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("_run")

func _fail(message: String) -> void:
	_failures += 1
	push_error(message)

func _run() -> void:
	var main := MAIN_SCENE.instantiate() as GameMain
	root.add_child(main)
	await process_frame
	await process_frame

	var employee := main.get_employee("mira")
	if employee == null:
		_fail("test_worker_walks_to_desk: Mina was not spawned")
	else:
		main.simulate_worker_event("mira", &"job.started")
		var frames := 0
		while not employee.is_at_desk() and frames < 360:
			await process_frame
			frames += 1
		if not employee.is_at_desk():
			_fail("test_worker_walks_to_desk: employee did not reach the desk")
		main.simulate_worker_event("mira", &"tool.started", "write_file")
		await process_frame
		if employee.work_state != EmployeeAvatar.WorkState.TYPING:
			_fail("test_worker_walks_to_desk: write_file did not produce typing state")
		main.simulate_worker_event("mira", &"job.failed")
		await process_frame
		if employee.work_state != EmployeeAvatar.WorkState.IDLE:
			_fail("test_worker_walks_to_desk: failed job did not return Mina to idle")
		main.simulate_worker_event("mira", &"tool.started", "write_file")
		await process_frame

	var image := _software_state_screenshot(main)
	if image == null or image.is_empty():
		_fail("test_worker_walks_to_desk: could not capture a screenshot")
	else:
		var output_error := image.save_png(OUTPUT_PATH)
		if output_error != OK:
			_fail("test_worker_walks_to_desk: could not save output screenshot")
		elif OS.get_environment("STARTUP_VALLEY_UPDATE_BASELINE") == "1":
			var baseline_error := image.save_png(BASELINE_PATH)
			if baseline_error != OK:
				_fail("test_worker_walks_to_desk: could not update baseline")
		else:
			_compare_baseline(image)

	if _failures == 0:
		print("test_worker_walks_to_desk: passed")
	root.remove_child(main)
	main.free()
	quit(_failures)

func _software_state_screenshot(main: GameMain) -> Image:
	# `godot --headless` deliberately uses the dummy renderer, so viewport textures
	# do not exist. This small software renderer snapshots the same logical positions
	# and worker visual states deterministically on macOS and Windows CI.
	var image := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	image.fill(Color("09111f"))
	var room_origin := Vector2i(16, 35)
	var tile := 16
	for y in range(main.room.grid_height):
		for x in range(main.room.grid_width):
			var floor_color := Color("34445f") if (x + y) % 2 == 0 else Color("314059")
			_fill_rect(image, Rect2i(room_origin + Vector2i(x * tile, y * tile), Vector2i(tile, tile)), floor_color)
	_fill_rect(image, Rect2i(447, 9, 184, 342), Color("11192a"))
	_fill_rect(image, Rect2i(457, 24, 112, 7), Color("dce8ff"))
	_fill_rect(image, Rect2i(457, 40, 76, 3), Color("8fa3c2"))
	for row in [64, 91, 144, 174, 238, 282]:
		_fill_rect(image, Rect2i(457, int(row), 154, 4), Color("34445e"))
	for employee_id in ["mira", "theo"]:
		var worker := main.get_employee(employee_id)
		if worker == null:
			continue
		var desk_center := Vector2i(int(worker.desk_position.x * 0.5), int((worker.desk_position.y - 42.0) * 0.5))
		_fill_rect(image, Rect2i(desk_center - Vector2i(15, 9), Vector2i(30, 18)), Color("8c6748"))
		var worker_center := Vector2i(int(worker.position.x * 0.5), int(worker.position.y * 0.5))
		var worker_color := Color("7dc6a7") if employee_id == "mira" else Color("d9a66f")
		if worker.work_state == EmployeeAvatar.WorkState.TYPING:
			worker_color = worker_color.lightened(0.2)
		_fill_rect(image, Rect2i(worker_center + Vector2i(-5, 0), Vector2i(10, 12)), worker_color)
		_fill_circle(image, worker_center + Vector2i(0, -4), 5, Color("e9b98f"))
	var player_center := Vector2i(int(main.player.position.x * 0.5), int(main.player.position.y * 0.5))
	_fill_rect(image, Rect2i(player_center + Vector2i(-5, 0), Vector2i(10, 13)), Color("5a7fd6"))
	_fill_circle(image, player_center + Vector2i(0, -4), 5, Color("f4c9a8"))
	return image

func _fill_rect(image: Image, rectangle: Rect2i, color: Color) -> void:
	var left := maxi(0, rectangle.position.x)
	var top := maxi(0, rectangle.position.y)
	var right := mini(image.get_width(), rectangle.end.x)
	var bottom := mini(image.get_height(), rectangle.end.y)
	for y in range(top, bottom):
		for x in range(left, right):
			image.set_pixel(x, y, color)

func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if Vector2i(x, y).distance_squared_to(center) <= radius * radius and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _compare_baseline(actual_source: Image) -> void:
	if not FileAccess.file_exists(BASELINE_PATH):
		_fail("test_worker_walks_to_desk: baseline is missing")
		return
	var expected := Image.new()
	var baseline_error := expected.load_png_from_buffer(FileAccess.get_file_as_bytes(BASELINE_PATH))
	if baseline_error != OK or expected.is_empty():
		_fail("test_worker_walks_to_desk: baseline could not be loaded")
		return
	var actual := actual_source.duplicate() as Image
	expected.resize(160, 90, Image.INTERPOLATE_NEAREST)
	actual.resize(160, 90, Image.INTERPOLATE_NEAREST)
	var total_difference := 0.0
	for y in range(90):
		for x in range(160):
			var expected_color := expected.get_pixel(x, y)
			var actual_color := actual.get_pixel(x, y)
			total_difference += absf(expected_color.r - actual_color.r)
			total_difference += absf(expected_color.g - actual_color.g)
			total_difference += absf(expected_color.b - actual_color.b)
	var mean_difference := total_difference / float(160 * 90 * 3)
	if mean_difference > 0.015:
		_fail("test_worker_walks_to_desk: screenshot differs from baseline (%.5f)" % mean_difference)
