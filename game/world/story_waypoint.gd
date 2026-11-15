class_name StoryWaypoint
extends Node2D
## A readable in-world wayfinding sign using the game's existing paper skin.

var caption := "Courtyard"
var hovered := false

func _ready() -> void:
	z_as_relative = false
	z_index = 1500
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_style_box(CozyUI.paper(), Rect2(-72, -32, 144, 40))
	draw_string(GameFonts.BOLD, Vector2(-65, -7), caption, HORIZONTAL_ALIGNMENT_CENTER, 130, 18, CozyUI.INK)
	if hovered: draw_rect(Rect2(-72, -32, 144, 40), Color("ad783b"), false, 2)

func hit(point: Vector2) -> bool:
	return is_visible_in_tree() and Rect2(global_position + Vector2(-72, -32), Vector2(144, 40)).has_point(point)
