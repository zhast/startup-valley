extends "res://tools/capture_native_floor_study.gd"
## DEV ONLY. Nine stills in disposable GameMain instances; no default changes.
const V4_OUTPUT := "res://tests/output/terrazzo-v4-review"
const REVIEW_IDS: Array[String] = ["baseline", "terrazzo-v3-unified", "terrazzo-v4-unified"]
const V4_PATH := "res://tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4-unified-base.png"
const V3_ROOT := "res://tests/fixtures/material-concepts/terrazzo-v3/"
const V3_BEFORE := V3_ROOT + "cream-terrazzo-floor-v3-normalized.png"
const V3_PATH := V3_ROOT + "cream-terrazzo-floor-v3-unified-base.png"
var prior_worker_environment := ""

func _initialize() -> void:
	prior_worker_environment = OS.get_environment("STARTUP_VALLEY_NO_WORKER")
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func material_path(id: String) -> String:
	return DEFAULT_FLOOR if id == "baseline" else (V3_PATH if id == "terrazzo-v3-unified" else V4_PATH)

func inspect_material(id: String) -> void:
	var path := material_path(id)
	check(ResourceLoader.exists(path), "Native comparison floor is imported: " + id)
	if not ResourceLoader.exists(path): return
	textures[id] = load(path) as Texture2D
	var imported := textures[id].get_image()
	imported.convert(Image.FORMAT_RGBA8)
	var raw := Image.load_from_file(ProjectSettings.globalize_path(path))
	raw.convert(Image.FORMAT_RGBA8)
	check(imported.get_size() == Vector2i(128, 128), "Native 128×128 floor: " + id)
	check(imported.get_data() == raw.get_data(), "Imported RGBA exactly matches native file: " + id)
	check(imported.detect_alpha() == Image.ALPHA_NONE, "Opaque floor without pinholes: " + id)
	var settings := FileAccess.get_file_as_string(path + ".import")
	check(settings.contains("compress/mode=0") and settings.contains("mipmaps/generate=false"), "Lossless native floor import: " + id)
	var colors := {}
	var edges := Vector2i.ZERO
	var top_nonbase := 0
	var inner_nonbase := 0
	var base := Color("eae4d7")
	for y: int in range(128):
		for x: int in range(128):
			var color := raw.get_pixel(x, y)
			colors[color.to_rgba32()] = true
			if color != base:
				if y < 8: top_nonbase += 1
				if x >= 8 and x < 120 and y >= 8 and y < 120: inner_nonbase += 1
		if raw.get_pixel(0, y) != raw.get_pixel(127, y): edges.x += 1
		if raw.get_pixel(y, 0) != raw.get_pixel(y, 127): edges.y += 1
	check(edges == Vector2i.ZERO, "Exact opposite edges match; not visual approval: " + id)
	if id != "baseline": check(colors.size() == 7, "Unified candidate uses exactly seven retained material colors: " + id)
	materials[id] = {"native_path": path, "sha256": FileAccess.get_sha256(path), "size": [128, 128], "palette_colors": colors.size(), "exact_edge_mismatch": [edges.x, edges.y], "top8_nonbase_percent": 100.0 * top_nonbase / 1024.0, "inner112_nonbase_percent": 100.0 * inner_nonbase / 12544.0, "density_measurement": "Non-#EAE4D7 color only, not an aesthetic pass threshold; wood has no matching base.", "production_default": id == "baseline"}
	source_hashes[path] = FileAccess.get_sha256(path)

func capture_v4(id: String, stage: int, view: String, baseline: Image = null) -> Image:
	var key := "%s-hires-%d-%s" % [id, stage, view]
	var entry := {"name": key, "material": id, "stage": stage, "view": view, "actor_contrast": body_contrast(textures[id].get_image()), "floor_origin": str(main.room.architecture.global_position)}
	if DisplayServer.get_name() == "headless":
		captures.append(entry)
		return null
	await frames(3)
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == VIEWPORT, "Native 1280×720 room evidence: " + key)
	var tile := textures[id].get_image()
	var wrong := 0
	for y: int in range(112, 145):
		for x: int in range(416, 705):
			var point := Vector2i(x, y) - Vector2i(main.room.architecture.global_position)
			if color_delta(image.get_pixel(x, y), tile.get_pixel(posmod(point.x, 128), posmod(point.y, 128))) > 0.015: wrong += 1
			pixel_checks += 1
	check(wrong == 0, "Actual room samples native floor across 32/128px boundaries: " + key)
	if baseline != null:
		var outside := 0
		for y: int in range(VIEWPORT.y):
			for x: int in range(VIEWPORT.x):
				var cell := Vector2i((Vector2(x, y) - main.room.architecture.global_position) / 32.0)
				if main.room.layout_model.is_floor(cell): continue
				if image.get_pixel(x, y) != baseline.get_pixel(x, y): outside += 1
				pixel_checks += 1
		check(outside == 0, "All nonfloor architecture remains unchanged: " + key)
		for rect: Rect2i in [Rect2i(390, 18, 370, 45), Rect2i(1176, 30, 77, 24), Rect2i(1170, 674, 84, 20)]:
			check(image.get_region(rect).get_data() == baseline.get_region(rect).get_data(), "HUD and rail unchanged: " + key)
		if view == "chat": check(image.get_region(Rect2i(820, 210, 280, 350)).get_data() == baseline.get_region(Rect2i(820, 210, 280, 350)).get_data(), "Chat body/paper unchanged: " + key)
	var path := V4_OUTPUT.path_join(key + ".png")
	check(image.save_png(path) == OK, "Save native evidence: " + key)
	entry["path"] = path
	entry["sha256"] = FileAccess.get_sha256(path)
	if stage == 0:
		var detail := image.get_region(Rect2i(416, 192, 384, 256))
		var detail_path := V4_OUTPUT.path_join(id + "-repeat-native.png")
		check(detail.save_png(detail_path) == OK, "Save native room repeat detail")
		entry["repeat_detail_path"] = detail_path
	captures.append(entry)
	images[key] = image
	return image

func contact_v4(stage: int, view: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var sheet := Image.create(1920, 360, false, Image.FORMAT_RGBA8)
	for index: int in range(REVIEW_IDS.size()):
		var thumb := images["%s-hires-%d-%s" % [REVIEW_IDS[index], stage, view]].duplicate() as Image
		thumb.resize(640, 360, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(thumb, Rect2i(0, 0, 640, 360), Vector2i(index * 640, 0))
	check(sheet.save_png(V4_OUTPUT.path_join("comparison-hires-%d-%s.png" % [stage, view])) == OK, "Save nearest overview; native evidence remains separate")

func run() -> void:
	check(OS.has_feature("editor"), "Dev-only native floor comparison")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(V4_OUTPUT))
	root.size = VIEWPORT
	root.content_scale_size = VIEWPORT
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.gui_embed_subwindows = true
	for path: String in [DEFAULT_FLOOR, OfficeLayout.DEFAULT_PATH, OfficeLayout.DEFAULT_CATALOG_PATH, "res://world/office_architecture.gd", "res://world/main.gd", V4_PATH, SOURCE + "cream-terrazzo-floor-v4.png", V3_BEFORE, V3_ROOT + "cream-terrazzo-floor-v3.png", SOURCE + "cream-terrazzo-floor-v3.png"]: source_hashes[path] = FileAccess.get_sha256(path)
	for id: String in REVIEW_IDS: inspect_material(id)
	if textures.size() != REVIEW_IDS.size():
		finish()
		return
	for stage: int in [0, 4]:
		await make_main(stage)
		var original := signature()
		var baseline: Image
		for id: String in REVIEW_IDS:
			main.room.architecture.floor_art = textures[id]
			main.room.architecture.queue_redraw()
			check(signature() == original, "Material selection preserves physical actors/layout/navigation: " + id)
			var result := await capture_v4(id, stage, "office", baseline)
			if id == "baseline": baseline = result
		contact_v4(stage, "office")
		if stage == 4:
			main.job_panel.select_employee("mira")
			main.job_panel.open_drawer(false)
			main.job_panel.show_chat_history("mira", [{"sender": "player", "content": "Can we make our first useful website?"}, {"sender": "employee", "content": "Let's start with one clear offer and a page customers can understand."}])
			main._update_label_visibility("")
			await frames(6)
			baseline = null
			for id: String in REVIEW_IDS:
				main.room.architecture.floor_art = textures[id]
				main.room.architecture.queue_redraw()
				check(signature() == original, "Chat keeps actual actors and physical layout fixed")
				var result := await capture_v4(id, stage, "chat", baseline)
				if id == "baseline": baseline = result
			contact_v4(stage, "chat")
		main.room.architecture.floor_art = textures["baseline"]
		check(main.room.architecture.floor_art.resource_path == DEFAULT_FLOOR, "Restore instance default before teardown")
		check(main.worker_client._process_id == -1 and main.worker_client._stdio == null, "No real worker process or transport")
		main.free()
		await frames(2)
	for path: String in source_hashes: check(FileAccess.get_sha256(path) == source_hashes[path], "Source/default hash preserved: " + path)
	finish()

func finish() -> void:
	var headless := DisplayServer.get_name() == "headless"
	var result := {"checks": checks, "failures": failures, "pixel_checks": pixel_checks, "renderer": DisplayServer.get_name(), "materials": materials, "captures": captures, "source_hashes": source_hashes, "runtime_approved": false, "production_changed": false, "worker_started": false, "personal_save_access": false, "limitations": ["Nine static actual GameMain views only; no movie, fullscreen or locomotion claim.", "Only the instance floor_art changes. Native scale1 and nearest sampling remain.", "Identical front-idle actors are frozen; stage4 means mature props with the two supported employees.", "Simulated credential-ready UI projection, not actual credentials or worker.", "Global palette normalization and exact edges do not constitute aesthetic approval.", "All V1/V2/V3 sources, exports, helpers and prior evidence remain unchanged."]}
	var file := FileAccess.open(V4_OUTPUT.path_join("results-headless.json" if headless else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", prior_worker_environment)
	print("Terrazzo V4 review: %d checks, %d failures, %d pixel checks, %d states" % [checks, failures.size(), pixel_checks, captures.size()])
	quit(0 if failures.is_empty() else 1)
