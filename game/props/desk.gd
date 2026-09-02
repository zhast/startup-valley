class_name OfficeDesk
extends Node2D

var owner_name: String = "Desk"

func configure(label: String) -> void:
	owner_name = label
	queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-30.0, -18.0, 60.0, 36.0), Color("8c6748"), true)
	draw_rect(Rect2(-27.0, -15.0, 54.0, 5.0), Color("b78b5e"), true)
	draw_rect(Rect2(-14.0, -30.0, 28.0, 20.0), Color("1f293d"), true)
	draw_rect(Rect2(-11.0, -27.0, 22.0, 14.0), Color("6ca6c9"), true)
	draw_rect(Rect2(-24.0, 16.0, 8.0, 14.0), Color("604735"), true)
	draw_rect(Rect2(16.0, 16.0, 8.0, 14.0), Color("604735"), true)
	draw_string(ThemeDB.fallback_font, Vector2(-30.0, 35.0), owner_name, HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color("c6d2e8"))
