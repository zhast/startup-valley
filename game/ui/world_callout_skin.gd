class_name WorldCalloutSkin
extends RefCounted
## Native-pixel callout parts shared by world identity, speech and interaction.
## The quiet paper body is the production component; its pointer never stretches.

const EDGE := Color("b3976f")
const LIGHT := Color("fffbed")
const SHADOW := Color("ac895c")
const POINTER_LENGTH := 8
const POINTER_HALF_WIDTH := 6
const ACTOR_BOUNDS := Rect2(-24, -72, 48, 76)
const KEYCAP_SIZE := Vector2(26, 28)

static func draw(canvas: CanvasItem, rect: Rect2, target: Vector2, state: String = "normal") -> void:
	var snapped := Rect2(rect.position.round(), rect.size.round())
	canvas.draw_style_box(CozyUI.card(Vector4(8, 4, 8, 4)), snapped)
	if state == "hover" or state == "focused":
		canvas.draw_style_box(CozyUI.focus(), snapped)
	draw_pointer(canvas, snapped, target)

static func _pointer(rect: Rect2, target: Vector2) -> Dictionary:
	if rect.has_point(target): return {}
	var relative := (target - rect.get_center()) / (rect.size * 0.5)
	var horizontal := absf(relative.x) > absf(relative.y)
	var direction := Vector2(signf(relative.x), 0) if horizontal else Vector2(0, signf(relative.y))
	var center := rect.get_center().round()
	if horizontal:
		center.x = rect.end.x - 3 if direction.x > 0 else rect.position.x + 2
		center.y = clampf(roundf(target.y), rect.position.y + 12, rect.end.y - 12)
	else:
		center.y = rect.end.y - 3 if direction.y > 0 else rect.position.y + 2
		center.x = clampf(roundf(target.x), rect.position.x + 12, rect.end.x - 12)
	return {"base": center, "direction": direction}

static func pointer_bounds(rect: Rect2, target: Vector2) -> Rect2:
	var pointer := _pointer(rect, target)
	if pointer.is_empty(): return Rect2()
	var base: Vector2 = pointer.base
	var direction: Vector2 = pointer.direction
	var perpendicular := Vector2(-direction.y, direction.x)
	var corners := [base - perpendicular * POINTER_HALF_WIDTH, base + perpendicular * POINTER_HALF_WIDTH, base + direction * (POINTER_LENGTH + 2)]
	var result := Rect2(corners[0], Vector2.ONE)
	for point: Vector2 in corners: result = result.expand(point)
	return result.grow(1)

static func bounds(rect: Rect2, target: Vector2) -> Rect2:
	var pointer := pointer_bounds(rect, target)
	return rect.merge(pointer) if pointer.has_area() else rect

static func draw_pointer(canvas: CanvasItem, rect: Rect2, target: Vector2) -> void:
	var pointer := _pointer(rect, target)
	if pointer.is_empty(): return
	var base: Vector2 = pointer.base
	var direction: Vector2 = pointer.direction
	var perpendicular := Vector2(-direction.y, direction.x)
	# Each cross-section is a whole-pixel rectangle. The first three rows bridge
	# the sheet rim; subsequent stepped rows narrow into an eight-pixel pointer.
	for depth: int in range(POINTER_LENGTH + 3):
		var half_width := maxi(1, POINTER_HALF_WIDTH - ceili(float(maxi(0, depth - 1)) * 0.5))
		var center := base + direction * depth
		var cross_start := center - perpendicular * half_width
		var cross_end := center + perpendicular * (half_width - 1)
		var start := cross_start.min(cross_end)
		var size := (cross_end - cross_start).abs() + Vector2.ONE
		canvas.draw_rect(Rect2(start, size), EDGE if depth < POINTER_LENGTH + 1 else SHADOW)
		if half_width > 1 and depth < POINTER_LENGTH + 1:
			var inner_start := cross_start + perpendicular
			var inner_end := cross_end - perpendicular
			canvas.draw_rect(Rect2(inner_start.min(inner_end), (inner_end - inner_start).abs() + Vector2.ONE), CozyUI.PAPER_LIGHT)

static func draw_keycap(canvas: CanvasItem, rect: Rect2, key: String = "E", pressed: bool = false) -> void:
	var snapped := Rect2(rect.position.round(), rect.size.round())
	# A small inset key is not another full wood-framed action button.
	canvas.draw_rect(Rect2(snapped.position + Vector2(2, 0), snapped.size - Vector2(4, 0)), SHADOW)
	canvas.draw_rect(Rect2(snapped.position + Vector2(0, 2), snapped.size - Vector2(0, 4)), SHADOW)
	canvas.draw_rect(Rect2(snapped.position + Vector2(2, 1), snapped.size - Vector2(4, 4)), LIGHT if not pressed else EDGE)
	canvas.draw_rect(Rect2(snapped.position + Vector2(3, 3), snapped.size - Vector2(6, 7)), CozyUI.PAPER_LIGHT if not pressed else CozyUI.PAPER)
	var font := GameFonts.BOLD
	var font_size := GameFonts.BODY_META
	var baseline := snapped.position + Vector2(2, floorf((snapped.size.y - font.get_height(font_size)) * 0.5) + ceilf(font.get_ascent(font_size)) - 1 + int(pressed))
	canvas.draw_string(font, baseline, key, HORIZONTAL_ALIGNMENT_CENTER, snapped.size.x - 4, font_size, CozyUI.INK)

static func actor_rect(position: Vector2) -> Rect2:
	return Rect2(position.round() + ACTOR_BOUNDS.position, ACTOR_BOUNDS.size)

static func candidates(position: Vector2, size: Vector2, prefer_above: bool = false) -> Array[Rect2]:
	var actor := actor_rect(position)
	var gap := float(POINTER_LENGTH + 3)
	var left := actor.position.x - size.x - gap
	var right := actor.end.x + gap
	var above := actor.position.y - size.y - gap
	var below := actor.end.y + gap
	var centered_x := actor.get_center().x - size.x * 0.5
	var centered_y := actor.get_center().y - size.y * 0.5
	var offsets: Array[Vector2] = [Vector2(centered_x, below), Vector2(left, centered_y), Vector2(right, centered_y), Vector2(centered_x, above)]
	if prefer_above:
		offsets = [Vector2(centered_x, above), Vector2(left, centered_y), Vector2(right, centered_y), Vector2(centered_x, below)]
	offsets.append_array([Vector2(left, above), Vector2(right, above), Vector2(left, below), Vector2(right, below)])
	var result: Array[Rect2] = []
	for point: Vector2 in offsets: result.append(Rect2(point.round(), size.round()))
	return result

static func place(position: Vector2, size: Vector2, occupied: Array[Rect2], viewport: Rect2, prefer_above: bool = false) -> Rect2:
	for candidate: Rect2 in candidates(position, size, prefer_above):
		# Test the pointer too: no paper tail is allowed to cut through a face.
		var painted := bounds(candidate, actor_rect(position).get_center())
		if not viewport.encloses(painted): continue
		var obstructed := false
		for obstacle: Rect2 in occupied:
			if painted.intersects(obstacle):
				obstructed = true
				break
		if not obstructed: return candidate
	return Rect2()
