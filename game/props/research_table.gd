class_name ResearchTable
extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-45.0, -22.0, 90.0, 44.0), Color("57728c"), true)
	draw_circle(Vector2(-26.0, -3.0), 8.0, Color("8ed1df"))
	draw_circle(Vector2(0.0, -3.0), 8.0, Color("9ab5ef"))
	draw_circle(Vector2(26.0, -3.0), 8.0, Color("c8a7e8"))
	draw_string(ThemeDB.fallback_font, Vector2(-42.0, 38.0), "RESEARCH", HORIZONTAL_ALIGNMENT_CENTER, 84.0, 10, Color("c6d4e9"))
