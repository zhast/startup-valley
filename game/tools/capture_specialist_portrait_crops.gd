extends SceneTree
## Provider-free source/palette/geometry proof and native comparison.
const PAGE := preload("res://tools/specialist_portrait_crop_page.gd")
const PIXELS := preload("res://tools/export_modular_desk_layers.gd")
const OUTPUT := "res://tests/output/specialist-portrait-crops"
var page: Control
var room: TownRoom
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var records: Array[Dictionary] = []
var protected_files: Dictionary = {}

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func color_set(image: Image) -> Dictionary:
	var result: Dictionary = {}
	var data := PIXELS.rgba(image).get_data()
	for at: int in range(0, data.size(), 4): result[data.slice(at, at + 4).hex_encode()] = true
	return result

func asset_checks() -> void:
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../dev/art-catalogue/specialist-portrait-crops.json"))
	var export_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PAGE.CROP_ROOT + "manifest.json"))
	check(export_manifest.failures.is_empty() and export_manifest.checks == 20, "Independent builder repeat proof passed")
	protected_files = export_manifest.protectedFiles
	for entry: Dictionary in export_manifest.records:
		var source_recipe: Dictionary = recipe.characters[entry.id]
		var crop := Rect2i(entry.crop[0], entry.crop[1], entry.crop[2], entry.crop[3])
		var source := Image.load_from_file(ProjectSettings.globalize_path("res://../" + str(entry.source)))
		check(Rect2i(Vector2i.ZERO, source.get_size()).encloses(crop), entry.id + entry.variant + " source crop is contained")
		check(crop.size.x * 80 == crop.size.y * 64, entry.id + entry.variant + " exact4:5 avoids stretch or added padding")
		var hair := Rect2i(source_recipe.hair_bounds[0], source_recipe.hair_bounds[1], source_recipe.hair_bounds[2], source_recipe.hair_bounds[3])
		check(crop.encloses(hair), entry.id + entry.variant + " source-observed full hair envelope stays inside crop")
		check(float(entry.approximateHairTop) >= 4 and float(entry.approximateHairTop) <= 6, entry.id + entry.variant + " intended4–6px hair top")
		check(float(entry.approximateEyeLine) >= 32 and float(entry.approximateEyeLine) <= 40, entry.id + entry.variant + " intended eye-line range")
		var data := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(PAGE.CROP_ROOT + str(entry.id) + "-" + str(entry.variant) + ".png")))
		var alpha := PIXELS.analyze(data)
		check(data.get_size() == Vector2i(64, 80) and alpha.opaque_pixels == 5120 and alpha.partial_alpha_pixels == 0, entry.id + entry.variant + " native opaque plate, not cutout")
		check(alpha.opaque_colors <= 32, entry.id + entry.variant + " original32-color palette budget")
		var palette := Image.load_from_file(ProjectSettings.globalize_path("res://../" + str(entry.palette)))
		var allowed := color_set(palette)
		var unchanged := true
		for color: String in color_set(data):
			if not allowed.has(color): unchanged = false
		check(unchanged, entry.id + entry.variant + " colors are exclusively from unchanged v3 palette")
		check(FileAccess.get_sha256("res://../" + str(entry.source)) == entry.sourceSha256, entry.id + entry.variant + " original master hash preserved")
		records.append(entry)

func layout_checks() -> void:
	for id: String in PAGE.REVIEW_IDS:
		var card: Dictionary = page.cards[id]
		var image: TextureRect = card.portrait
		check(image.size == Vector2(64, 80) and image.scale == Vector2.ONE and is_zero_approx(image.rotation), id + " native comparison opening")
		check((card.frame as Control).size == Vector2(82, 98) and (card.frame as Control).get_global_rect().encloses(image.get_global_rect()), id + " actual frame contains full plate")
		check((card.root as Control).get_global_rect().encloses((card.backing as Control).get_global_rect()), id + " paper stays in card")
		check((card.backing as Control).get_global_rect().encloses((card.name_plate as Control).get_global_rect()), id + " name plaque stays in paper")
		check(not (card.frame as Control).get_global_rect().intersects((card.name_plate as Control).get_global_rect()), id + " frame/name do not overlap")
		if card.native:
			check(image.stretch_mode == TextureRect.STRETCH_KEEP_CENTERED and image.texture.get_size() == Vector2(64, 80), id + " all native source pixels kept")
	for label: Label in page.labels:
		var font := label.get_theme_font("font")
		var pixels := label.get_theme_font_size("font_size")
		check(pixels >= 14 and font in [GameFonts.BOLD, GameFonts.BODY, GameFonts.EMPHASIS, GameFonts.DISPLAY], label.text + " approved font role")
		check(font.get_height(pixels) <= label.size.y, label.text + " full font line fits")
		check(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x <= label.size.x, label.text + " copy fits without clipping")
		check((label.get_parent() as Control).get_global_rect().encloses(label.get_global_rect()), label.text + " label remains inside material")
	var button: Button = page.guide_button
	var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	var skin := button.get_theme_stylebox("normal")
	check(button.size.y >= 40 and text_width + skin.get_content_margin(SIDE_LEFT) + skin.get_content_margin(SIDE_RIGHT) <= button.size.x, "Guide control has full target/text insets")
	check(Rect2(0, 0, 1280, 720).encloses(page.get_global_rect()), "Page remains in native composition")

func settle() -> void:
	for frame: int in range(5): await process_frame
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw

func save(image: Image, name_value: String) -> void:
	check(image.save_png(OUTPUT.path_join(name_value)) == OK, "Save " + name_value)
	captures.append(name_value)

func capture(name_value: String, details: bool = false) -> void:
	await settle()
	var screenshot := PIXELS.rgba(root.get_texture().get_image())
	check(screenshot.get_size() == Vector2i(1280, 720), "Native1280x720 screenshot")
	if not page.guides_visible:
		for id: String in PAGE.REVIEW_IDS:
			if not bool(page.cards[id].native): continue
			var rect := Rect2i((page.cards[id].portrait as Control).get_global_rect())
			var original := PIXELS.rgba(Image.load_from_file(ProjectSettings.globalize_path(PAGE.plate_path(id))))
			check(screenshot.get_region(rect).get_data() == original.get_data(), id + " actual5120plate pixels unchanged/unclipped at1x")
	save(screenshot, name_value + ".png")
	if details:
		for id: String in PAGE.REVIEW_IDS:
			var rect := Rect2i((page.cards[id].root as Control).get_global_rect())
			var crop := screenshot.get_region(rect)
			save(crop, id + "-native.png")
			crop.resize(rect.size.x * 4, rect.size.y * 4, Image.INTERPOLATE_NEAREST)
			save(crop, id + "-4x.png")

func click_guides() -> void:
	var at: Vector2 = page.guide_button.get_global_rect().get_center()
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
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	asset_checks()
	room = load("res://world/town_room.tscn").instantiate() as TownRoom
	root.add_child(room)
	check(room.load_layout(), "Actual room loads with no GameMain/worker/save")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	page = PAGE.new()
	root.add_child(page)
	await settle()
	layout_checks()
	if DisplayServer.get_name() != "headless":
		await capture("native-framing-comparison", true)
		await click_guides()
		check(page.guides_visible, "Actual mouse toggles diagnostic eye-row guides only")
		await capture("eye-guide-overlay")
		await click_guides()
		check(not page.guides_visible, "Second mouse click restores untouched image pixels")
		await capture("guides-hidden-again")
	for path: String in protected_files: check(FileAccess.get_sha256("res://../" + path) == protected_files[path], "Original source/v3 remains unchanged " + path)
	var result := {"checks": checks, "failures": failures, "captures": captures, "records": records, "worker_started": false,
		"save_access": false, "employee_registered": false, "runtime_approved": false, "original_review_unchanged": true,
		"landmarks_approximate": true, "new_plate_runtime_scale": 1, "rail_migration_required": true}
	var out := FileAccess.open(OUTPUT.path_join("results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"), FileAccess.WRITE)
	out.store_string(JSON.stringify(result, "\t") + "\n")
	page.free()
	room.free()
	await process_frame
	print("Portrait crop review: %d checks, %d failures; %d captures; no production changes." % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
