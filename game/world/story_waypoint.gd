class_name StoryWaypoint
extends Node2D
## A readable in-world wayfinding sign using the game's existing paper skin.

var caption := "Courtyard"
var hovered := false
const SIGN := Rect2(-72, -32, 144, 40)

func _ready() -> void:
	z_as_relative = false
	z_index = 1500
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_style_box(CozyUI.paper(), SIGN)
	draw_string(GameFonts.BOLD, Vector2(-65, -7), caption, HORIZONTAL_ALIGNMENT_CENTER, 130, 18, CozyUI.INK)
	if hovered: draw_rect(SIGN, Color("ad783b"), false, 2)

func hit(point: Vector2) -> bool:
	return is_visible_in_tree() and painted_bounds().has_point(point)

func painted_bounds() -> Rect2:
	return global_transform * SIGN
