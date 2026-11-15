extends SceneTree
## Deterministic normalization of a retained ImageGen front-panel treatment.
## The historical code-native fixture remains unchanged and supplies geometry.

const SOURCE := "res://assets/source/coffee-front-polish/"
const BASE := "res://tests/fixtures/furniture-calibration/coffee-station-code-v1/"
const RUNTIME := "res://assets/runtime/office/coffee-station-v1/"
const FACE := Rect2i(81, 134, 31, 31)
const PARTS: Array[String] = ["floor_shadow", "counter_carcass", "counter_top", "counter_front", "counter_plinth", "service_panel", "grinder", "espresso", "plant", "serviceware"]
const PALETTE: Array[Color] = [Color("202326"), Color("343536"), Color("3b4b52"), Color("27343a"), Color("c9c7b9"), Color("777f7e"), Color("f0e2bd"), Color("d4a85e"), Color("754426")]

func _initialize() -> void:
	var generated := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + "generated-front-panel.png"))
	var machine := Image.load_from_file(ProjectSettings.globalize_path(BASE + "south-espresso.png"))
	if generated == null or machine == null:
		push_error("Missing retained coffee panel or historical geometry source")
		quit(1)
		return
	machine.convert(Image.FORMAT_RGBA8)
	var panel := Image.create(31, 31, false, Image.FORMAT_RGBA8)
	for y: int in range(31):
		for x: int in range(31):
			# Explicit point sampling avoids low-resolution averaging or blur.
			var point := Vector2i(int((x + 0.5) * generated.get_width() / 31.0), int((y + 0.5) * generated.get_height() / 31.0))
			var input := generated.get_pixelv(point)
			var best := PALETTE[0]
			var distance := INF
			for color: Color in PALETTE:
				var difference := Vector3(input.r - color.r, input.g - color.g, input.b - color.b).length_squared()
				if difference < distance:
					distance = difference
					best = color
			panel.set_pixel(x, y, best)
	machine.blit_rect(panel, Rect2i(0, 0, 31, 31), FACE.position)
	var whole := Image.create(192, 256, false, Image.FORMAT_RGBA8)
	whole.fill(Color(0, 0, 0, 0))
	for part: String in PARTS:
		var layer := machine if part == "espresso" else Image.load_from_file(ProjectSettings.globalize_path(BASE + "south-" + part + ".png"))
		if layer == null:
			push_error("Missing historical coffee layer: " + part)
			quit(1)
			return
		whole.blend_rect(layer, Rect2i(0, 0, 192, 256), Vector2i.ZERO)
	var outputs := {"south-front-panel.png": panel, "south-espresso.png": machine, "south-whole.png": whole}
	var check_only := "--check" in OS.get_cmdline_user_args()
	for name: String in outputs:
		var expected: Image = outputs[name]
		if check_only:
			var current := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + name))
			if current == null or current.get_data() != expected.get_data():
				push_error("Coffee source rebuild mismatch: " + name)
				quit(1)
				return
		else:
			expected.save_png(ProjectSettings.globalize_path(SOURCE + name))
		if name != "south-front-panel.png":
			if check_only:
				var current := Image.load_from_file(ProjectSettings.globalize_path(RUNTIME + name))
				if current == null or current.get_data() != expected.get_data():
					push_error("Coffee runtime rebuild mismatch: " + name)
					quit(1)
					return
			else:
				expected.save_png(ProjectSettings.globalize_path(RUNTIME + name))
	print("Coffee front panel: ", "exact source/runtime rebuild passed" if check_only else "normalized retained ImageGen source; unchanged 31×46 silhouette and 192×256 registration")
	quit()
