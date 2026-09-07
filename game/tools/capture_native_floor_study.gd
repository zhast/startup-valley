extends SceneTree
## DEV ONLY: floor Texture2D override on an actual GameMain instance.
## No catalogue, architecture geometry, navigation, worker or personal save writes.
const OUTPUT := "res://tests/output/native-floor-study"
const STAGED := "res://tests/fixtures/material-concepts/overnight-v1/"
const SOURCE := "res://assets/source/overnight-20260904/materials/"
const DEFAULT_FLOOR := "res://assets/runtime/office/architecture/floor.png"
const MATERIALS: Array[String] = ["baseline", "cream-terrazzo-floor", "walnut-floor", "warm-cork-floor"]
const STAGES: Array[int] = [0, 2, 4]
const VIEWPORT := Vector2i(1280, 720)
var main: GameMain
var checks := 0
var failures: Array[String] = []
var materials: Dictionary = {}
var textures: Dictionary[String, Texture2D] = {}
var captures: Array[Dictionary] = []
var images: Dictionary[String, Image] = {}
var source_hashes: Dictionary = {}
var pixel_checks := 0

class NullWorker extends WorkerClient:
	var blocked_requests: Array[String] = []
	func start() -> void:
		blocked_requests.append("start blocked")
	func _send_request(method: String, _parameters: Dictionary, _job_id: String = "") -> void:
		blocked_requests.append(method)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 3) -> void:
	for index: int in range(count): await process_frame

func freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child: Node in node.get_children(): freeze(child)

func material_path(id: String) -> String:
	return DEFAULT_FLOOR if id == "baseline" else STAGED + id + "-v1.png"

func color_delta(a: Color, b: Color) -> float:
	return (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0

func luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return linear.r * 0.2126 + linear.g * 0.7152 + linear.b * 0.0722

func contrast(a: Color, b: Color) -> float:
	var first := luminance(a)
	var second := luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)

func inspect_material(id: String) -> void:
	var path := material_path(id)
	check(ResourceLoader.exists(path), "Native floor texture exists: " + id)
	if not ResourceLoader.exists(path): return
	var texture := load(path) as Texture2D
	textures[id] = texture
	var image := texture.get_image()
	check(image.get_size() == Vector2i(128, 128), "Exact128x128 native floor: " + id)
	check(image.detect_alpha() == Image.ALPHA_NONE, "Fully opaque floor, no pinholes: " + id)
	var imported := FileAccess.get_file_as_string(path + ".import")
	check(imported.contains("compress/mode=0") and imported.contains("mipmaps/generate=false"), "Lossless import without mipmaps: " + id)
	var raw := Image.load_from_file(ProjectSettings.globalize_path(path))
	raw.convert(Image.FORMAT_RGBA8)
	var actual := image.duplicate() as Image
	actual.convert(Image.FORMAT_RGBA8)
	check(raw.get_data() == actual.get_data(), "Imported buffer preserves native RGB exactly: " + id)
	var colors := {}
	var sum_luma := 0.0
	var min_luma := 1.0
	var max_luma := 0.0
	var internal_x := 0.0
	var internal_y := 0.0
	for y: int in range(128):
		for x: int in range(128):
			var color := image.get_pixel(x, y)
			colors[color.to_rgba32()] = true
			var value := luminance(color)
			sum_luma += value
			min_luma = minf(min_luma, value)
			max_luma = maxf(max_luma, value)
			if x > 0: internal_x += color_delta(color, image.get_pixel(x - 1, y))
			if y > 0: internal_y += color_delta(color, image.get_pixel(x, y - 1))
	var wrap_x := 0.0
	var wrap_y := 0.0
	var mismatch_x := 0
	var mismatch_y := 0
	var max_wrap_x := 0.0
	var max_wrap_y := 0.0
	for index: int in range(128):
		var dx := color_delta(image.get_pixel(0, index), image.get_pixel(127, index))
		var dy := color_delta(image.get_pixel(index, 0), image.get_pixel(index, 127))
		wrap_x += dx
		wrap_y += dy
		max_wrap_x = maxf(max_wrap_x, dx)
		max_wrap_y = maxf(max_wrap_y, dy)
		if dx > 0: mismatch_x += 1
		if dy > 0: mismatch_y += 1
	internal_x /= 128.0 * 127.0
	internal_y /= 128.0 * 127.0
	materials[id] = {"native_path": path, "native_sha256": FileAccess.get_sha256(path), "dimensions": [128, 128], "opaque": true, "colors": colors.size(), "mean_luminance": sum_luma / 16384.0, "luminance_range": [min_luma, max_luma], "wrap_x_mismatched_rows": mismatch_x, "wrap_y_mismatched_columns": mismatch_y, "wrap_x_mean_rgb_delta": wrap_x / 128.0, "wrap_y_mean_rgb_delta": wrap_y / 128.0, "wrap_x_max_rgb_delta": max_wrap_x, "wrap_y_max_rgb_delta": max_wrap_y, "internal_x_mean_rgb_delta": internal_x, "internal_y_mean_rgb_delta": internal_y, "wrap_x_to_internal_ratio": wrap_x / 128.0 / maxf(internal_x, 1.0 / 255.0), "wrap_y_to_internal_ratio": wrap_y / 128.0 / maxf(internal_y, 1.0 / 255.0), "exact_wrap_contract_pass": mismatch_x == 0 and mismatch_y == 0}
	if id != "baseline":
		check(colors.size() <= 12, "Staged native palette stays within12 colors: " + id)
		var master_path := SOURCE + id + "-v1.png"
		var master := Image.load_from_file(ProjectSettings.globalize_path(master_path))
		check(master != null and master.get_size() == Vector2i(1254, 1254), "Preserved1254 square original: " + id)
		materials[id]["source_path"] = master_path
		materials[id]["source_sha256"] = FileAccess.get_sha256(master_path)
		materials[id]["prompt_path"] = SOURCE + id + "-v1.md"

func make_main(stage: int) -> void:
	main = load("res://world/main.tscn").instantiate() as GameMain
	main.get_node("WorkerClient").set_script(NullWorker)
	root.add_child(main)
	main.game_audio.set_volumes(0, 0)
	main.game_audio.shutdown()
	main.day_clock.set_speed(0)
	main.day_clock.set_time(1, DayClock.WORK_START)
	main.founder_hud.dismiss_movement_hint()
	main.founder_hud.hide_delivery()
	main.job_panel.set_worker_ready()
	# Simulated UI projection only. There is no real key or transport in this fixture.
	main.job_panel.set_credential_status(true)
	main.job_panel.close_drawer(false)
	main._spawn_employees([])
	var records: Array[EmployeeRecord] = []
	var available := main.room.placeholder_records()
	for index: int in range(mini(stage, available.size())): records.append(available[index])
	main._spawn_employees(records)
	main.room.set_hire_count(stage)
	main.room.get_node("UnlockEffects").hide()
	main.player.cancel_route()
	main.player.position = main.room.grid_to_world_position(main.room.player_spawn)
	main.player.face_direction(Vector2.DOWN)
	main.player.z_index = roundi(main.player.position.y)
	for employee: EmployeeAvatar in main._employees.values():
		employee._has_target = false
		employee.work_state = EmployeeAvatar.WorkState.IDLE
		employee._facing = &"front"
		employee._animation_elapsed = 0
		employee._idle_elapsed = 0
		employee._label_hold = 60
		employee._speech_visible = false
		employee._update_character_frame()
		employee.z_index = roundi(employee.position.y)
	main._update_label_visibility("")
	freeze(main)
	await frames(6)
	main.job_panel.close_drawer(false)
	check(main.worker_client is NullWorker and main.worker_client._process_id == -1 and main.worker_client._stdio == null, "Null transport only; no worker process or pipe")
	check(not main.artifact_viewer.visible and not main.company_panel.visible and not main.job_panel._connection_panel.visible, "No accidental modal contaminates floor evidence")
	check(main.room.architecture.floor_art.resource_path == DEFAULT_FLOOR, "Fresh instance always starts with unchanged production floor")
	check(main.room.architecture.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and main.room.architecture.global_scale == Vector2.ONE, "Architecture renders at native1x nearest sampling")

func signature() -> String:
	var actors := {"founder": str(main.player.position)}
	for id: String in main._employees: actors[id] = str(main._employees[id].position)
	return JSON.stringify({"actors": actors, "layout": main.room.layout_model.data, "navigation": main.room.layout_model.navigation_data(), "placements": main.room.placement_overrides, "props": main.room.visible_prop_count()})

func body_contrast(floor_image: Image) -> Dictionary:
	var output := {}
	var actors: Array[Node2D] = [main.player]
	for employee: EmployeeAvatar in main._employees.values(): actors.append(employee)
	for actor: Node2D in actors:
		var sprite := actor.get_node("CharacterSprite") as Sprite2D
		var cell := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
		var origin := Vector2i(sprite.global_position - sprite.region_rect.size / 2.0)
		var values: Array[float] = []
		for y: int in range(1, cell.get_height() - 1):
			for x: int in range(1, cell.get_width() - 1):
				var color := cell.get_pixel(x, y)
				if color.a < 1.0: continue
				for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor := Vector2i(x, y) + direction
					if cell.get_pixelv(neighbor).a > 0: continue
					var point := origin + neighbor - Vector2i(main.room.architecture.global_position)
					values.append(contrast(color, floor_image.get_pixel(posmod(point.x, 128), posmod(point.y, 128))))
		values.sort()
		var low := 0
		for value: float in values:
			if value < 1.5: low += 1
		var actor_id := (actor as EmployeeAvatar).employee_id if actor is EmployeeAvatar else "founder"
		output[actor_id] = {"border_samples": values.size(), "median_outline_to_floor_contrast": values[values.size() / 2] if not values.is_empty() else 0, "outline_samples_below_1_5": low, "meaning": "Diagnostic contrast of source silhouette against sampled underlying floor; not a UI text WCAG test."}
	return output

func capture(id: String, stage: int, view: String, baseline: Image) -> Image:
	var name_value := "%s-hires-%d-%s" % [id, stage, view]
	var entry := {"name": name_value, "material": id, "stage": stage, "view": view, "floor_origin": str(main.room.architecture.global_position), "floor_filter": "nearest", "scale": [1, 1], "actor_contrast": body_contrast(textures[id].get_image())}
	if DisplayServer.get_name() == "headless":
		captures.append(entry)
		return null
	await frames(3)
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	check(image.get_size() == VIEWPORT, "Native1280x720 capture: " + name_value)
	var floor_image := textures[id].get_image()
	var errors := 0
	# Unobstructed central aisle samples include32px cell and128px plate boundaries.
	for y: int in range(320, 450, 3):
		for x: int in range(448, 577, 3):
			var local := Vector2i(x, y) - Vector2i(main.room.architecture.global_position)
			if color_delta(image.get_pixel(x, y), floor_image.get_pixel(posmod(local.x, 128), posmod(local.y, 128))) > 0.015: errors += 1
			pixel_checks += 1
	check(errors == 0, "Actual floor sampling matches native plate across cell/repeat edges: " + name_value)
	if baseline != null:
		var outside_changed := 0
		for y: int in range(VIEWPORT.y):
			for x: int in range(VIEWPORT.x):
				var cell := Vector2i((Vector2(x, y) - main.room.architecture.global_position) / 32.0)
				if main.room.layout_model.is_floor(cell): continue
				if image.get_pixel(x, y) != baseline.get_pixel(x, y): outside_changed += 1
				pixel_checks += 1
		check(outside_changed == 0, "No wall/trim/window/outside-floor pixels changed: " + name_value)
		for rect: Rect2i in [Rect2i(390, 18, 370, 45), Rect2i(1176, 30, 77, 24), Rect2i(1170, 674, 84, 20)]:
			check(image.get_region(rect).get_data() == baseline.get_region(rect).get_data(), "HUD/rail text ink stays byte-identical on alternate floor: " + name_value)
		if view == "chat": check(image.get_region(Rect2i(820, 210, 280, 350)).get_data() == baseline.get_region(Rect2i(820, 210, 280, 350)).get_data(), "Opaque chat paper/body typography stays byte-identical: " + name_value)
	var path := OUTPUT.path_join(name_value + ".png")
	check(image.save_png(path) == OK, "Write native evidence: " + name_value)
	entry["path"] = path
	entry["sha256"] = FileAccess.get_sha256(path)
	captures.append(entry)
	images[name_value] = image
	return image

func make_contact(stage: int, view: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var sheet := Image.create(2560, 360, false, Image.FORMAT_RGBA8)
	for index: int in range(MATERIALS.size()):
		var key := "%s-hires-%d-%s" % [MATERIALS[index], stage, view]
		var thumb := images[key].duplicate() as Image
		thumb.resize(640, 360, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(thumb, Rect2i(0, 0, 640, 360), Vector2i(index * 640, 0))
	check(sheet.save_png(OUTPUT.path_join("comparison-hires-%d-%s.png" % [stage, view])) == OK, "Write nearest comparison contact")

func run() -> void:
	check(OS.has_feature("editor"), "Floor study only runs in editor-capable dev build")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = VIEWPORT
	root.content_scale_size = VIEWPORT
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	for path: String in [DEFAULT_FLOOR, OfficeLayout.DEFAULT_PATH, OfficeLayout.DEFAULT_CATALOG_PATH]: source_hashes[path] = FileAccess.get_sha256(path)
	for id: String in MATERIALS: inspect_material(id)
	if textures.size() != MATERIALS.size():
		finish()
		return
	for stage: int in STAGES:
		await make_main(stage)
		var original := signature()
		var baseline: Image
		for id: String in MATERIALS:
			main.room.architecture.floor_art = textures[id]
			main.room.architecture.queue_redraw()
			check(signature() == original, "Floor override never changes actors/navigation/collision/layout: " + id)
			var image := await capture(id, stage, "office", baseline)
			if id == "baseline": baseline = image
		make_contact(stage, "office")
		if stage == 2:
			main.job_panel.select_employee("mira")
			main.job_panel.open_drawer(false)
			main.job_panel.show_chat_history("mira", [{"sender": "player", "content": "Can we make our first useful website?"}, {"sender": "employee", "content": "Let's start with one clear offer and a page customers can understand."}])
			main._update_label_visibility("")
			await frames(6)
			baseline = null
			for id: String in MATERIALS:
				main.room.architecture.floor_art = textures[id]
				main.room.architecture.queue_redraw()
				check(signature() == original, "Opening UI keeps physical floor/actor state fixed: " + id)
				var image := await capture(id, stage, "chat", baseline)
				if id == "baseline": baseline = image
			make_contact(stage, "chat")
		main.room.architecture.floor_art = textures["baseline"]
		check(main.room.architecture.floor_art.resource_path == DEFAULT_FLOOR, "Default resource restored before instance teardown")
		check(main.worker_client._process_id == -1 and main.worker_client._stdio == null, "No worker appeared during review")
		main.free()
		await frames(2)
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Production/source file remains byte-identical: " + path)
	finish()

func finish() -> void:
	var headless := DisplayServer.get_name() == "headless"
	var result := {"checks": checks, "failures": failures, "pixel_checks": pixel_checks, "renderer": DisplayServer.get_name(), "worker_started": false, "personal_save_access": false, "production_changed": false, "runtime_approved": false, "simulated_ui_credentials": true, "materials": materials, "captures": captures, "source_hashes": source_hashes, "limitations": ["Only floor_art is overridden on disposable actual GameMain instances.", "Seam/color/outline metrics are measurements, not automatic art approval.", "Actors are frozen at identical native front-idle poses; this is not a movement audit.", "Stage4 is the mature prop layout with the supported two-employee roster.", "Half-size contacts are comparisons; individual captures are native1280x720."]}
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("Native floor study: %d checks, %d failures, %d pixel checks, %d states" % [checks, failures.size(), pixel_checks, captures.size()])
	quit(0 if failures.is_empty() else 1)
