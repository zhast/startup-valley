class_name NotebookPanel
extends PanelContainer

const RULE_COLOR := Color("d8b87980")
const MARGIN_COLOR := Color("fa461640")
const RING_COLOR := Color("552c22")
const RING_HIGHLIGHT := Color("de9550")

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var rule_y := 38.0
	while rule_y < size.y - 12.0:
		draw_dashed_line(
			Vector2(14.0, rule_y),
			Vector2(size.x - 14.0, rule_y),
			RULE_COLOR,
			1.0,
			3.0
		)
		rule_y += 36.0
	draw_line(Vector2(30.0, 10.0), Vector2(30.0, size.y - 10.0), MARGIN_COLOR, 1.0)
	var ring_y := 24.0
	while ring_y < size.y - 12.0:
		draw_line(Vector2(0.0, ring_y), Vector2(14.0, ring_y), RING_COLOR, 3.0)
		draw_circle(Vector2(14.0, ring_y), 4.5, RING_COLOR)
		draw_circle(Vector2(14.0, ring_y), 1.6, RING_HIGHLIGHT)
		ring_y += 48.0
