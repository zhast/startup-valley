class_name ClickFeedback
extends Node2D

var remaining := 0.0
var valid := true

func show_at(point: Vector2, accepted: bool) -> void:
	position = point.round()
	valid = accepted
	remaining = 0.5
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0: return
	remaining = maxf(0, remaining - delta)
	queue_redraw()

func _draw() -> void:
	if remaining <= 0: return
	var color := Color("c1fa81") if valid else Color("fa4616")
	color.a = minf(1, remaining * 4)
	if valid:
		for offset: Vector2 in [Vector2(-10, 0), Vector2(8, 0), Vector2(0, -6), Vector2(0, 4)]:
			draw_rect(Rect2(offset, Vector2(4, 4)), color)
	else:
		draw_line(Vector2(-6, -6), Vector2(6, 6), color, 3)
		draw_line(Vector2(6, -6), Vector2(-6, 6), color, 3)
