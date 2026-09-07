extends SceneTree
## Deterministically derives four-frame, four-facing research strips from the
## accepted native locomotion sheets. The body/anchor stay byte-native; only
## small original handheld tools are painted into transparent pixels.

const OUTPUT := "res://assets/runtime/characters/research-v1/"
const SOURCE := {
	"mira": "res://assets/runtime/characters/mira-locomotion.png",
	"theo": "res://assets/runtime/characters/theo-locomotion.png",
}
const DIRECTIONS := {
	"north": 1,
	"east": 3,
	"south": 0,
	"west": 2,
}
const INK := Color("151515")
const PAPER := Color("f1f1f1")
const PARCHMENT := Color("eee2c8")
const INDIGO := Color("354b98")
const CERULEAN := Color("6196c1")
const VERMILION := Color("fa4616")
const CHARTREUSE := Color("c1fa81")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var failures: Array[String] = []
	for employee: String in SOURCE:
		var source := Image.load_from_file(SOURCE[employee])
		if source == null or source.get_size() != Vector2i(288, 320):
			failures.append("Unexpected locomotion sheet: " + employee)
			continue
		for direction: String in DIRECTIONS:
			var strip := Image.create(192, 80, false, Image.FORMAT_RGBA8)
			strip.fill(Color.TRANSPARENT)
			for frame: int in range(4):
				var idle_column := frame % 2
				strip.blit_rect(source, Rect2i(idle_column * 48, DIRECTIONS[direction] * 80, 48, 80), Vector2i(frame * 48, 0))
				_paint_tool(strip, Vector2i(frame * 48, 0), direction, frame, source.get_pixel(idle_column * 48 + 24, DIRECTIONS[direction] * 80 + 34))
			var path := OUTPUT + employee + "-" + direction + ".png"
			if strip.save_png(path) != OK: failures.append("Could not save " + path)
	print("Directional research poses: %d failures" % failures.size())
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _rect(image: Image, origin: Vector2i, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(origin + rect.position, rect.size), color)

func _outline_box(image: Image, origin: Vector2i, rect: Rect2i, fill: Color) -> void:
	_rect(image, origin, rect, INK)
	if rect.size.x > 2 and rect.size.y > 2: _rect(image, origin, rect.grow(-1), fill)

func _paint_tool(image: Image, origin: Vector2i, direction: String, frame: int, skin: Color) -> void:
	# One stable handheld analyzer with a four-frame scan. Changing only its
	# screen/hand offset reads as motion; it never swaps whole tools at 6 FPS.
	var right_side := direction != "west"
	var side_x := (28 if right_side else 10) + (1 if frame in [1, 2] else 0)
	var hand_x := 29 if right_side else 14
	_rect(image, origin, Rect2i(hand_x, 43, 4, 3), INK)
	_rect(image, origin, Rect2i(hand_x + (1 if right_side else -1), 43, 3, 2), skin)
	_outline_box(image, origin, Rect2i(side_x, 38, 10, 13), INDIGO)
	_rect(image, origin, Rect2i(side_x + 2, 40, 6, 6), CERULEAN)
	_rect(image, origin, Rect2i(side_x + 2, 40 + posmod(frame, 3), 6, 2), CHARTREUSE)
	_rect(image, origin, Rect2i(side_x + 4, 48, 2, 1), PAPER)
	_rect(image, origin, Rect2i(side_x + 8, 37, 2, 3), VERMILION)
