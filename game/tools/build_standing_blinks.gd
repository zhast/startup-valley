extends SceneTree
## Registered ImageGen eye patches only. Original hair/body/alpha stay exact.
const SOURCE := "res://assets/source/blink-polish-v3/"

func _initialize() -> void:
	for id: String in ["mira", "founder"]:
		var status := build(id)
		if status != OK:
			quit(status)
			return
	quit()

func build(id: String) -> Error:
	var original := Image.load_from_file(SOURCE + id + "-locomotion-before.png")
	var generated := Image.load_from_file(SOURCE + ("generated-blinks.png" if id == "mira" else "generated-founder-theo.png"))
	original.convert(Image.FORMAT_RGBA8)
	generated.convert(Image.FORMAT_RGBA8)
	var result := original.duplicate() as Image
	var palette: Array[Color] = []
	for y: int in range(original.get_height()):
		for x: int in range(original.get_width()):
			var color := original.get_pixel(x, y)
			if color.a == 1 and not palette.has(color): palette.append(color)
	# The flawed frame added pale bars above the eye and retained its pupil.
	# Restore the original open-frame face before adding only generated lids.
	if id == "mira":
		for row: int in [0, 2, 3]:
			result.blit_rect(original, Rect2i(0, row * 80 + 20, 48, 14), Vector2i(48, row * 80 + 20))
	var patches: Array[Dictionary] = [
		{"source": Rect2i(220, 326, 70, 70), "target": Vector2i(48 + 17, 25)},
		{"source": Rect2i(319, 326, 70, 70), "target": Vector2i(48 + 26, 25)},
		{"source": Rect2i(780, 325, 70, 70), "target": Vector2i(48 + 15, 160 + 24)},
		{"source": Rect2i(1463, 319, 70, 70), "target": Vector2i(48 + 29, 240 + 24)},
	]
	if id == "founder":
		patches = [
			{"source": Rect2i(226, 378, 92, 92), "target": Vector2i(48 + 16, 24)},
			{"source": Rect2i(381, 378, 92, 92), "target": Vector2i(48 + 27, 24)},
		]
	for patch: Dictionary in patches:
		var sampled := generated.get_region(patch.source)
		sampled.resize(6, 6, Image.INTERPOLATE_NEAREST)
		for y: int in range(6):
			for x: int in range(6):
				var color := sampled.get_pixel(x, y)
				var closest := palette[0]
				var distance := INF
				for candidate: Color in palette:
					var error := Vector3(color.r - candidate.r, color.g - candidate.g, color.b - candidate.b).length_squared()
					if error < distance:
						distance = error
						closest = candidate
				var target: Vector2i = patch.target + Vector2i(x, y)
				closest.a = original.get_pixelv(target).a
				result.set_pixelv(target, closest)
	var overlay := Image.create(288, 320, false, Image.FORMAT_RGBA8)
	for y: int in range(320):
		for x: int in range(288):
			# Blitting the open face must not change invisible RGB payload. An
			# over-composited source overlay cannot reproduce transparent RGB.
			if original.get_pixel(x, y).a == 0: result.set_pixel(x, y, original.get_pixel(x, y))
			if result.get_pixel(x, y) != original.get_pixel(x, y): overlay.set_pixel(x, y, result.get_pixel(x, y))
	if overlay.save_png(SOURCE + id + "-blink-overlay.png") != OK:
		push_error("Cannot retain registered blink overlay")
		return ERR_CANT_CREATE
	var path := "res://assets/runtime/characters/" + id + "-locomotion.png" if "--apply" in OS.get_cmdline_user_args() else SOURCE + id + "-locomotion-candidate.png"
	var status := result.save_png(path)
	print(id, " standing blink: ", path, " status=", status)
	return status
