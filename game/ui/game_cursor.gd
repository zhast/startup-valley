class_name GameCursor
extends RefCounted
## Authored pixel icons, installed as hardware cursors to avoid frame latency.
## X=outline, o=warm paper, +=highlight. Hotspots touch the visible tip.
const ARROW: PackedStringArray = [
	"X...............", "XX..............", "X+X.............", "X+oX............",
	"X+ooX...........", "X+oooX..........", "X+ooooX.........", "X+oooooX........",
	"X+ooooooX.......", "X+oooXXXXX......", "X+oXooX.........", "X+X.XooX........",
	"XX..XooX........", "X....XooX.......", ".....XooX.......", "......XX........",
]
const HAND: PackedStringArray = [
	".....XX.........", "....X++X........", "....X+oX........", "....X+oX........",
	"....X+oXXX......", "....X+oXooXX....", "....X+oXooXoX...", ".XX.X+ooooXoXX..",
	"X++XX+oooooooX..", "X+ooX+oooooooX..", ".X+ooooooooooX..", "..X+oooooooooX..",
	"...X+oooooooX...", "...X+oooooooX...", "....XooooooX....", "....XXXXXXXX....",
]
const ARROW_HOTSPOT := Vector2(0, 0)
const HAND_HOTSPOT := Vector2(10, 0)

static var _owners: Dictionary[int, bool] = {}
static var _arrow_texture: ImageTexture
static var _hand_texture: ImageTexture

static func texture(pixels: PackedStringArray) -> ImageTexture:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y: int in range(pixels.size()):
		for x: int in range(pixels[y].length()):
			var color := Color.TRANSPARENT
			match pixels[y][x]:
				"X": color = Color("493322")
				"o": color = Color("e9c27d")
				"+": color = Color("fff3d2")
			for dy: int in range(2):
				for dx: int in range(2): image.set_pixel(x * 2 + dx, y * 2 + dy, color)
	return ImageTexture.create_from_image(image)

static func install(owner: Object) -> void:
	var id := owner.get_instance_id()
	if _owners.has(id): return
	_owners[id] = true
	if _arrow_texture != null: return
	_arrow_texture = texture(ARROW)
	_hand_texture = texture(HAND)
	Input.set_custom_mouse_cursor(_arrow_texture, Input.CURSOR_ARROW, ARROW_HOTSPOT)
	Input.set_custom_mouse_cursor(_hand_texture, Input.CURSOR_POINTING_HAND, HAND_HOTSPOT)

static func release(owner: Object) -> void:
	if not _owners.erase(owner.get_instance_id()) or not _owners.is_empty(): return
	# Input retains the textures independently. Clear its slots before releasing
	# our references, while RenderingServer is still alive. Static resources
	# otherwise survive until script shutdown, after the renderer is gone.
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
	_arrow_texture = null
	_hand_texture = null
