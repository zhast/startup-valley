extends SceneTree
## Dev-only geometry acceptance; not art, seat, or production direction approval.
const DESK := preload("res://tools/modular_desk_geometry.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	check(DESK.profile("diagonal").is_empty(), "Unknown facing fails closed")
	for facing: String in DESK.DIRECTIONS:
		var p: Dictionary = DESK.profile(facing)
		var desk := DESK.new()
		root.add_child(desk)
		check(desk.configure(facing), "%s constructs" % facing)
		var horizontal := facing in ["north", "south"]
		check(p.top == (Rect2i(-48, -48, 96, 32) if horizontal else Rect2i(-16, -80, 32, 96)), "%s exact top geometry" % facing)
		check(p.floor == (Rect2i(-48, -16, 96, 32) if horizontal else Rect2i(-16, -48, 32, 96)), "%s exact floor geometry" % facing)
		check(p.contact_y == (16 if horizontal else 48), "%s exact contact line" % facing)
		check(p.floor.end.y == p.contact_y, "%s floor and contact agree" % facing)
		check(p.top.position == p.floor.position - Vector2i(0, 32), "%s fixed32px elevation" % facing)
		check(p.top.size == p.floor.size, "%s screen axes not diamond yaw" % facing)
		check(desk.scale == Vector2.ONE and desk.rotation == 0.0, "%s no image/node rotation or scaling" % facing)
		check(desk.rear.name == "Rear" and desk.front.name == "Front", "%s separate explicit draw layers" % facing)
		check(desk.rear.z_index == -1 and desk.front.z_index == 1, "%s actor z0 fits layer interval" % facing)
		check(not desk.material_ready, "%s placeholder is explicitly unapproved" % facing)
		var maximum_y := -1000
		for key: String in ["rear", "front"]:
			for part: Dictionary in p[key]:
				var rect: Rect2i = part.rect
				check(rect.has_area(), "%s %s piece has positive integer area" % [facing, key])
				check(rect.end.y <= p.contact_y, "%s piece does not sink below floor contact" % facing)
				check(rect.position.x >= p.floor.position.x and rect.end.x <= p.floor.end.x, "%s part stays in floor width" % facing)
				maximum_y = maxi(maximum_y, rect.end.y)
		check(maximum_y == p.contact_y, "%s leg ends meet floor contact exactly" % facing)
		var old: Dictionary = desk.resolved.duplicate(true)
		check(not desk.configure("bad") and desk.resolved == old, "%s rejected facing preserves view" % facing)
		var tile := Image.create(32, 32, false, Image.FORMAT_RGB8)
		tile.fill(Color("a87742"))
		var native := ImageTexture.create_from_image(tile)
		check(desk.configure(facing, native, native) and desk.material_ready, "%s accepts native32px material" % facing)
		var bad_tile := ImageTexture.create_from_image(Image.create(64, 32, false, Image.FORMAT_RGB8))
		check(not desk.configure(facing, bad_tile, native), "%s refuses non-native material" % facing)
		desk.free()
	await process_frame
	print("Modular desk calibration: %d checks, %d failures; dev-only, no art or pose approval." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
