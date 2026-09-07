extends SceneTree
## DEV ONLY: reuse the real notebook review component, never register a roster.
const PAGE := preload("res://tools/specialist_portrait_review_page.gd")
const OUTPUT := "res://tests/output/additional-portraits-v1/"
const ENTRIES: Array[Dictionary] = [
	{"slot": "mira", "role": "Legal", "path": "res://tests/fixtures/character-concepts/overnight-crops-v1/lawyer-b.png"},
	{"slot": "theo", "role": "Creative", "path": "res://tests/fixtures/character-concepts/overnight-crops-v1/creative-b.png"},
	{"slot": "lawyer", "role": "Engineer", "path": "res://tests/fixtures/character-concepts/additional-v1/engineer-portrait-v1.png"},
	{"slot": "creative", "role": "Finance", "path": "res://tests/fixtures/character-concepts/additional-v1/finance-portrait-v1.png"}
]
const CUSTOMER_SUPPORT_ENTRIES: Array[Dictionary] = [
	{"slot": "mira", "role": "Creative", "path": "res://tests/fixtures/character-concepts/overnight-crops-v1/creative-b.png"},
	{"slot": "theo", "role": "Engineer", "path": "res://tests/fixtures/character-concepts/additional-v1/engineer-portrait-v1.png"},
	{"slot": "lawyer", "role": "Finance", "path": "res://tests/fixtures/character-concepts/additional-v1/finance-portrait-v1.png"},
	{"slot": "creative", "role": "Customer support", "path": "res://tests/fixtures/character-concepts/customer-support-v1/portrait.png"}
]
var checks := 0
var failures: Array[String] = []
var records: Array[Dictionary] = []
var captures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func rgba(image: Image) -> Image:
	var copy := image.duplicate() as Image
	copy.convert(Image.FORMAT_RGBA8)
	return copy

func run() -> void:
	# A named study selects an isolated output; the original comparison is never
	# overwritten by a later portrait batch.
	var customer_support := OS.get_cmdline_user_args().has("--portrait-study=customer-support")
	var entries: Array[Dictionary] = CUSTOMER_SUPPORT_ENTRIES if customer_support else ENTRIES
	var output := "res://tests/output/customer-support-portrait-v1/" if customer_support else OUTPUT
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var room := load("res://world/town_room.tscn").instantiate() as TownRoom
	root.add_child(room)
	check(room.load_layout(), "Actual room loads without GameMain, worker or save")
	room.set_hire_count(0)
	room.get_node("Props").hide()
	var page := PAGE.new()
	root.add_child(page)
	for entry: Dictionary in entries:
		var card: Dictionary = page.cards[entry.slot]
		var native := rgba(Image.load_from_file(ProjectSettings.globalize_path(entry.path)))
		check(native.get_size() == Vector2i(64, 80), entry.role + " exact native plate")
		check(native.detect_alpha() == Image.ALPHA_NONE, entry.role + " intentionally opaque")
		var colors := {}
		var bytes := native.get_data()
		for at: int in range(0, bytes.size(), 4): colors[bytes.slice(at, at + 4).hex_encode()] = true
		check(colors.size() <= 32, entry.role + " bounded palette")
		var portrait: TextureRect = card.portrait
		portrait.texture = ImageTexture.create_from_image(native)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		card.name_label.text = entry.role
		for child: Node in card.backing.get_children():
			if child is Label:
				(child as Label).text = "OPAQUE CONCEPT" if child.position.y < 100 else "64 × 80 opaque plate\nExact native pixels\nNo world poses yet"
		check(portrait.scale == Vector2.ONE and portrait.size == Vector2(64, 80), entry.role + " native unscaled opening")
		check(card.frame.get_global_rect().encloses(portrait.get_global_rect()), entry.role + " full plate inside frame")
		records.append({"role": entry.role, "path": entry.path, "sha256": FileAccess.get_sha256(entry.path), "colors": colors.size(), "native_size": [64, 80]})
	page.note.text = "Future portrait concepts only. No hiring, abilities or world animation is implemented by this review."
	for label: Label in page.labels:
		var font := label.get_theme_font("font")
		var pixels := label.get_theme_font_size("font_size")
		check(pixels >= 14 and font.get_height(pixels) <= label.size.y, "Readable label line: " + label.text)
		if not label.text.contains("\n"):
			check(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x <= label.size.x, "Label fits: " + label.text)
	for index: int in range(6): await process_frame
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var screenshot := rgba(root.get_texture().get_image())
		check(screenshot.get_size() == Vector2i(1280, 720), "Native screenshot")
		check(screenshot.save_png(output + "four-specialists-native.png") == OK, "Save actual notebook comparison")
		captures.append("four-specialists-native.png")
		for entry: Dictionary in entries:
			var card: Dictionary = page.cards[entry.slot]
			var plate := screenshot.get_region(Rect2i(card.portrait.get_global_rect()))
			var native := rgba(Image.load_from_file(ProjectSettings.globalize_path(entry.path)))
			check(plate.get_data() == native.get_data(), entry.role + " all 5120 rendered pixels exact")
			var crop := screenshot.get_region(Rect2i(card.root.get_global_rect()))
			var filename: String = str(entry.role).to_lower() + "-card-native.png"
			check(crop.save_png(output + filename) == OK, "Save " + filename)
			captures.append(filename)
	var result := {"checks": checks, "failures": failures, "records": records, "captures": captures, "native_review_only": true, "worker_started": false, "save_access": false, "employee_registered": false, "runtime_approved": false}
	var name_value := "results-headless.json" if DisplayServer.get_name() == "headless" else "manifest.json"
	var file := FileAccess.open(output + name_value, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	page.free()
	room.free()
	await process_frame
	print("Additional portraits: %d checks, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
