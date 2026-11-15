class_name ClickFeedback
extends Node2D

const INK := Color("493322")
const VALID := Color("f8d889")
const INVALID := Color("fa4616")
const DOT_CENTERS: Array[Vector2] = [Vector2(-6, 0), Vector2(6, 0), Vector2(0, -6), Vector2(0, 6)]
const DOT_CORE_SIZE := Vector2(2, 2)
const DOT_RIM_SIZE := Vector2(4, 4)
const INVALID_EXTENT := Vector2(6, 6)
const DURATION := 0.32

var remaining := 0.0
var valid := true

static func accepted_core_rects() -> Array[Rect2]:
	return _centered_rects(DOT_CORE_SIZE)

static func accepted_rim_rects() -> Array[Rect2]:
	return _centered_rects(DOT_RIM_SIZE)

static func _centered_rects(size_value: Vector2) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for center: Vector2 in DOT_CENTERS:
		result.append(Rect2(center - size_value * 0.5, size_value))
	return result

func show_at(point: Vector2, accepted: bool) -> void:
	position = point.round()
	valid = accepted
	remaining = DURATION
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0: return
	remaining = maxf(0, remaining - delta)
	queue_redraw()

func _draw() -> void:
	if remaining <= 0: return
	var color := VALID if valid else INVALID
	color.a = minf(1, remaining * 8)
	var rim := INK
	rim.a = color.a
	if valid:
		# Four small sparks expand symmetrically around the exact click hotspot.
		# Whole-pixel steps keep the feedback sharp while its center stays fixed.
		var spread := floorf((1.0 - remaining / DURATION) * 3.0)
		for rect: Rect2 in accepted_rim_rects(): draw_rect(Rect2(rect.position + rect.get_center().normalized() * spread, rect.size), rim)
		for rect: Rect2 in accepted_core_rects(): draw_rect(Rect2(rect.position + rect.get_center().normalized() * spread, rect.size), color)
	else:
		# Rejected clicks share the same dark separation without changing the
		# established Vermilion X or its centered, whole-pixel endpoints.
		draw_line(-INVALID_EXTENT, INVALID_EXTENT, rim, 5, false)
		draw_line(Vector2(-INVALID_EXTENT.x, INVALID_EXTENT.y), Vector2(INVALID_EXTENT.x, -INVALID_EXTENT.y), rim, 5, false)
		draw_line(-INVALID_EXTENT, INVALID_EXTENT, color, 3, false)
		draw_line(Vector2(-INVALID_EXTENT.x, INVALID_EXTENT.y), Vector2(INVALID_EXTENT.x, -INVALID_EXTENT.y), color, 3, false)
