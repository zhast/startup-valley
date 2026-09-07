extends SceneTree
## DEV-ONLY four-view geometry specimen; no GameMain, worker, save or registry.
## Optional args: --horizontal=res://path.png --vertical=res://path.png
const DESK := preload("res://tools/modular_desk_geometry.gd")
const OUTPUT := "res://tests/output/modular-desk-calibration"
const ACTORS := {
	"mira": {"north": "res://tests/fixtures/furniture-calibration/characters/mira-north-seated-v2.png", "east": "res://tests/fixtures/furniture-calibration/characters/mira-east-seated-v3.png", "south": "res://assets/runtime/characters/mira-seated.png", "west": "res://tests/fixtures/furniture-calibration/characters/mira-west-seated-v2.png"},
	"theo": {"north": "res://tests/fixtures/furniture-calibration/characters/theo-north-seated-v2.png", "east": "res://tests/fixtures/furniture-calibration/characters/theo-east-seated-v4.png", "south": "res://assets/runtime/characters/theo-seated.png", "west": "res://tests/fixtures/furniture-calibration/characters/theo-west-seated-v3.png"},
}

var stage: Node2D
var ui: CanvasLayer
var guides: Array[Node2D] = []
var actors: Array[Sprite2D] = []
var desks: Array[Node2D] = []
var horizontal_path := ""
var vertical_path := ""
var captures: Array[String] = []
var material_label: Label
var pose_label: Label
var raster_checks := 0
var material_images: Dictionary = {}

class Backdrop extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("ded5c2"))
		for x: int in range(0, 1281, 32):
			draw_rect(Rect2(x, 112, 1, 528), Color("d3c9b5"))
		for y: int in range(112, 641, 32):
			draw_rect(Rect2(0, y, 1280, 1), Color("d3c9b5"))

class Guides extends Node2D:
	var p: Dictionary
	func _draw() -> void:
		draw_rect(Rect2(p.floor), Color("354b98"), false, 1.0)
		draw_rect(Rect2(p.top), Color("4c7529"), false, 1.0)
		var floor_rect: Rect2i = p.floor
		draw_line(Vector2(floor_rect.position.x - 8, p.contact_y), Vector2(floor_rect.end.x + 8, p.contact_y), Color("fa4616"), 1.0)
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color("354b98"), 1.0)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color("354b98"), 1.0)

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--horizontal="): horizontal_path = arg.trim_prefix("--horizontal=")
		elif arg.begins_with("--vertical="): vertical_path = arg.trim_prefix("--vertical=")
	call_deferred("run")

func image_texture(path: String) -> Texture2D:
	if path.is_empty(): return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null and not image.is_empty(), "Missing calibration source: " + path)
	return ImageTexture.create_from_image(image)

func label(copy: String, point: Vector2, width: int, size: int = 16) -> Label:
	var node := Label.new()
	node.text = copy
	node.position = point
	node.size = Vector2(width, 32)
	node.add_theme_font_override("font", GameFonts.BODY)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", Color("282622"))
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(node)
	return node

func make_desk(facing: String, pivot: Vector2, horizontal: Texture2D, vertical: Texture2D) -> Node2D:
	var node := DESK.new()
	node.position = pivot
	stage.add_child(node)
	assert(node.configure(facing, horizontal, vertical))
	desks.append(node)
	var guide := Guides.new()
	guide.p = node.resolved
	guide.position = pivot
	guide.z_index = 20
	guide.hide()
	stage.add_child(guide)
	guides.append(guide)
	return node

func add_standing(id: String, foot: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = CharacterArt.locomotion_sheet(id)
	sprite.region_enabled = true
	sprite.region_rect = CharacterArt.locomotion_region(&"front", 0)
	sprite.centered = false
	sprite.position = foot - Vector2(24, 72)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(sprite)

func set_actor(id: String, frame: int) -> void:
	for index: int in range(4):
		var facing: String = DESK.DIRECTIONS[index]
		var sprite: Sprite2D = actors[index]
		sprite.texture = image_texture(ACTORS[id][facing])
		assert(sprite.texture.get_size() == Vector2(288, 80))
		sprite.region_rect = Rect2(frame * 48, 0, 48, 80)
	pose_label.text = "%s frame %d — native body reference only; no chair/socket or pose approval" % [id.capitalize(), frame]

func capture(name_value: String) -> void:
	for index: int in range(3): await process_frame
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	assert(screenshot.get_size() == Vector2i(1280, 720))
	# Data-only profile checks missed a negative-z rear layer behind the opaque
	# showroom backdrop. Prove actual top material pixels reach every bare view.
	for index: int in range(4):
		var p: Dictionary = DESK.profile(DESK.DIRECTIONS[index])
		var pivot := Vector2i(160 + index * 320, 282)
		for sample_x: int in [4, 12, 20]:
			for sample_y: int in [4, 12, 20]:
				var point: Vector2i = pivot + p.top.position + Vector2i(sample_x, sample_y)
				var expected: Color = DESK.WOOD
				if material_images.has(p.material_axis):
					var source: Image = material_images[p.material_axis]
					expected = source.get_pixel((sample_x - 2) % 32, (sample_y - 2) % 32)
				var actual := screenshot.get_pixelv(point)
				raster_checks += 1
				assert(absf(actual.r - expected.r) < 0.01 and absf(actual.g - expected.g) < 0.01 and absf(actual.b - expected.b) < 0.01, "Painted top hidden, altered or resampled: %s at %s" % [DESK.DIRECTIONS[index], point])
	assert(screenshot.save_png(OUTPUT.path_join(name_value + ".png")) == OK)
	captures.append(name_value + ".png")
	print("Modular desk calibration captured: " + name_value)

func rect_values(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use test_modular_desk_calibration.gd for headless geometry checks; this tool requires rendering.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	stage = Node2D.new()
	root.add_child(stage)
	var backdrop := Backdrop.new()
	backdrop.z_index = -100
	stage.add_child(backdrop)
	ui = CanvasLayer.new()
	ui.layer = 30
	root.add_child(ui)
	label("MODULAR DESK GEOMETRY — DEV PROTOTYPE / NOT RUNTIME APPROVED", Vector2(20, 12), 1240, 22)
	var horizontal := image_texture(horizontal_path)
	var vertical := image_texture(vertical_path)
	if horizontal != null: material_images["horizontal"] = horizontal.get_image()
	if vertical != null: material_images["vertical"] = vertical.get_image()
	material_label = label("FLAT WOOD PLACEHOLDER — no generated material supplied", Vector2(20, 48), 1240)
	if horizontal != null and vertical != null:
		material_label.text = "Native 32×32 generated material tiles; explicit geometry, no finished prop image transforms"
	label("Top row: bare desks + existing standing scale reference. Bottom row: unapproved seated references.", Vector2(20, 80), 1240)
	pose_label = label("", Vector2(20, 642), 1240)
	label("32px grid | native 48×80 actors | green=top, indigo=floor/pivot, orange=contact | worker/save access disabled", Vector2(20, 679), 1240, 14)
	var profiles: Array[Dictionary] = []
	for index: int in range(4):
		var facing: String = DESK.DIRECTIONS[index]
		var x := 160.0 + index * 320.0
		var p: Dictionary = DESK.profile(facing)
		label(facing.to_upper(), Vector2(x - 140, 126), 280, 20)
		make_desk(facing, Vector2(x, 282), horizontal, vertical)
		add_standing("founder" if index % 2 == 0 else "theo", Vector2(x - 90, 300))
		label("top %d×%d · floor contact %+d" % [p.top.size.x, p.top.size.y, p.contact_y], Vector2(x - 148, 346), 296, 14)
		var desk := make_desk(facing, Vector2(x, 566), horizontal, vertical)
		var sprite := Sprite2D.new()
		sprite.name = "UnapprovedBodyReference"
		sprite.centered = false
		sprite.position = Vector2(p.seat_reference) - Vector2(24, 72)
		sprite.region_enabled = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 0
		desk.add_child(sprite)
		actors.append(sprite)
		profiles.append({"facing": facing, "top": rect_values(p.top), "floor": rect_values(p.floor), "contact_y": p.contact_y, "unapproved_seat_reference": [p.seat_reference.x, p.seat_reference.y], "top_layer": p.top_layer})
	set_actor("mira", 0)
	await capture("four-view-mira-idle")
	for guide: Node2D in guides: guide.show()
	await capture("four-view-geometry-guides")
	for guide: Node2D in guides: guide.hide()
	set_actor("mira", 2)
	await capture("four-view-mira-typing")
	set_actor("theo", 0)
	await capture("four-view-theo-idle")
	set_actor("theo", 2)
	await capture("four-view-theo-typing")
	var manifest := FileAccess.open(OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"status": "dev_geometry_only_not_runtime_approved", "worker": "disabled", "save_access": false, "native_viewport": [1280, 720], "material_horizontal": horizontal_path, "material_vertical": vertical_path, "flat_placeholder": horizontal == null or vertical == null, "node_scale": [1, 1], "node_rotation": 0, "layer_order": ["Rear", "UnapprovedBodyReference", "Front"], "profiles": profiles, "captures": captures, "painted_top_pixel_checks": raster_checks, "pose_and_layering_approved": false}, "\t"))
	stage.free()
	ui.free()
	await process_frame
	quit(0)
