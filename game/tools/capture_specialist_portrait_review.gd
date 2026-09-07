extends SceneTree
## Run headlessly for asset/layout checks, rendered for exact native UI evidence.
const PAGE := preload("res://tools/specialist_portrait_review_page.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/specialist-portrait-review"
var page: Control
var room: TownRoom
var checks := 0
var failures: Array[String] = []
var sources: Array[Dictionary] = []
var captures: Array[String] = []
var records: Array[Dictionary] = []
var clicks := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func asset_checks() -> void:
	for id: String in ["lawyer", "creative"]:
		var path := PAGE.native_path(id)
		var image := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(path)))
		var source_path := PAGE.SOURCE + id + "-portrait-v3.png"
		var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		var alpha := PIXELS.analyze(image)
		check(image.get_size() == Vector2i(64, 80), id + " is exact64x80 native plate")
		check(alpha.opaque_pixels == 5120 and alpha.transparent_pixels == 0 and alpha.partial_alpha_pixels == 0, id + " is intentionally completely opaque, not a recovered cutout")
		check(alpha.opaque_colors == 32, id + " bounded32-color export")
		check(source.get_size() == Vector2i(1122, 1402) and source.detect_alpha() == Image.ALPHA_NONE, id + " original source remains1122x1402 opaque")
		var ratio := minf(64.0 / source.get_width(), 80.0 / source.get_height())
		check(Vector2i(roundi(source.get_width() * ratio), roundi(source.get_height() * ratio)) == Vector2i(64, 80), id + " uniform normalization, only integer output rounding")
		var corners: Array[String] = []
		for at: Vector2i in [Vector2i(0, 0), Vector2i(63, 0), Vector2i(0, 79), Vector2i(63, 79)]: corners.append(image.get_pixelv(at).to_html(false))
		records.append({"id": id, "native_path": path, "alpha": alpha, "corner_colors": corners,
			"intentionally_opaque": true, "portrait_cutout": false, "employee_registered": false})
		for file: String in [path, source_path]: sources.append({"path": file, "sha256": FileAccess.get_sha256(file)})
	var sample := CharacterArt.bust_portrait("mira")
	check(sample.region.size == Vector2(112, 244 * 0.68), "Current Mina source bust is not misrepresented as a64x80 native sheet")
	check(CharacterArt.bust_portrait("theo").region.size == Vector2(112, 252 * 0.68), "Current Theo source bust retains its actual atlas region")

func layout_checks() -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(1280, 720))
	for id: String in PAGE.IDS:
		var card: Dictionary = page.cards[id]
		var portrait: TextureRect = card.portrait
		check(portrait.size == Vector2(64, 80), id + " identical64x80 comparison opening")
		check((card.frame as Control).size == Vector2(82, 98), id + " actual9px notebook border stays outside plate")
		check(portrait.scale == Vector2.ONE and is_zero_approx(portrait.rotation), id + " no control transform scaling")
		check(portrait.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, id + " nearest texture sampling")
		check((card.frame as Control).get_global_rect().encloses(portrait.get_global_rect()), id + " frame contains plate")
		check((card.backing as Control).get_global_rect().encloses((card.frame as Control).get_global_rect()), id + " native frame fits paper card")
		check((card.root as Control).get_global_rect().encloses((card.backing as Control).get_global_rect()), id + " paper card fits notebook wood")
		check(viewport.encloses((card.root as Control).get_global_rect()), id + " all card controls inside1280x720")
		if bool(card.native):
			check(portrait.stretch_mode == TextureRect.STRETCH_KEEP_CENTERED and portrait.texture.get_size() == portrait.size, id + " candidate keeps every native pixel without COVERED crop")
		else:
			check(portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, id + " baseline retains current UI fit algorithm, explicitly disclosed")
		var border := (card.frame as Panel).get_theme_stylebox("panel") as StyleBoxTexture
		check(border.texture == NotebookSkin.PORTRAIT_FRAME and not border.draw_center, id + " real notebook portrait frame, no fabricated border")
		var name := (card.name_plate as Panel).get_theme_stylebox("panel") as StyleBoxTexture
		check(name.texture == NotebookSkin.PARCHMENT_PANEL, id + " real notebook nameplate material")
	for label: Label in page.labels:
		var font := label.get_theme_font("font")
		var pixels := label.get_theme_font_size("font_size")
		check(pixels >= 14 and (font == GameFonts.BODY or font == GameFonts.EMPHASIS or font == GameFonts.BOLD or font == GameFonts.DISPLAY), label.text + " approved font and readable role")
		check(label.get_line_count() * font.get_height(pixels) <= label.size.y + 1, label.text + " text line metrics fit allotted height")
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var widest := 0.0
			for line: String in label.text.split("\n"): widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x)
			check(widest <= label.size.x, label.text + " text width fits without ellipsis")
		check(viewport.encloses(label.get_global_rect()), label.text + " label stays on native page")
		check((label.get_parent() as Control).get_global_rect().encloses(label.get_global_rect()), label.text + " label does not escape its material")
	for button: Button in page.controls:
		check(button.size.y >= 40, button.text + " accessible control height")
		var style := button.get_theme_stylebox("normal")
		var width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
		check(width + style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT) <= button.size.x, button.text + " label fits actual button insets")
		check((button.get_parent() as Control).get_global_rect().encloses(button.get_global_rect()), button.text + " control stays inside notebook page")
	check(not page.inspect_button.get_global_rect().intersects(page.missing_button.get_global_rect()), "Review controls never overlap")
	check(page.missing_button.disabled, "Absent world poses cannot dispatch an action")

func settle() -> void:
	for index: int in range(5): await process_frame
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw

func save(image: Image, name_value: String) -> void:
	check(image.save_png(OUTPUT.path_join(name_value)) == OK, "Save " + name_value)
	captures.append(name_value)

func capture(name_value: String) -> void:
	await settle()
	var screenshot := PIXELS.rgba(root.get_texture().get_image())
	check(screenshot.get_size() == Vector2i(1280, 720), "Actual native1280x720 viewport")
	for id: String in ["lawyer", "creative"]:
		var portrait: TextureRect = page.cards[id].portrait
		var rect := Rect2i(portrait.get_global_rect())
		var expected := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(PAGE.native_path(id))))
		check(screenshot.get_region(rect).get_data() == expected.get_data(), id + " all5120 actual viewport pixels exactly equal native plate; no cover crop, filtering or frame overlap")
	save(screenshot, name_value + ".png")
	if name_value == "native-notebook":
		for id: String in PAGE.IDS:
			var box := Rect2i((page.cards[id].root as Control).get_global_rect())
			var detail := screenshot.get_region(box)
			save(detail, id + "-card-native.png")
			detail.resize(box.size.x * 4, box.size.y * 4, Image.INTERPOLATE_NEAREST)
			save(detail, id + "-card-4x.png")

func mouse_click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	Input.parse_input_event(motion)
	await process_frame
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = at
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		Input.parse_input_event(click)
		await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	asset_checks()
	room = load("res://world/town_room.tscn").instantiate() as TownRoom
	root.add_child(room)
	check(room.load_layout(), "Actual approved room backdrop, no GameMain or worker")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	page = PAGE.new()
	root.add_child(page)
	page.inspect_button.pressed.connect(func() -> void: clicks += 1)
	await settle()
	layout_checks()
	if DisplayServer.get_name() != "headless":
		await capture("native-notebook")
		page.inspect_button.grab_focus()
		check(page.inspect_button.has_focus(), "Keyboard focus reaches review-only button")
		await capture("keyboard-focus")
		await mouse_click(page.missing_button.get_global_rect().get_center())
		check(clicks == 0 and not page.inspected, "Disabled world-pose control cannot change page state")
		await mouse_click(page.inspect_button.get_global_rect().get_center())
		check(clicks == 1 and page.inspected, "Actual mouse hit dispatches one local review action")
		await settle()
		layout_checks()
		await capture("inspected-local-only")
	for source: Dictionary in sources: check(FileAccess.get_sha256(source.path) == source.sha256, "Original source/export unchanged " + str(source.path))
	var report := {"checks": checks, "failures": failures, "sources": sources, "portraits": records, "captures": captures,
		"actual_clicks": clicks, "headless": DisplayServer.get_name() == "headless", "worker_started": false, "save_access": false,
		"employee_registered": false, "intentionally_opaque": true, "runtime_approved": false,
		"limitations": ["Portrait concepts only; no world poses, employee backend or hiring.", "Current cast retains production COVERED fit behavior, not new64x80 native source art.",
			"New native plate frame uses82x98 with64x80 opening; existing84x92 rail opening66x74 would crop/enlarge this plate."]}
	var file := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	page.free()
	room.free()
	await process_frame
	print("Specialist portrait review: %d checks, %d failures; %d captures; intentionally opaque, no employee registration." % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
