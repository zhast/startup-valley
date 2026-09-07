extends RefCounted
## DEV-ONLY measured W-height56 near arm; no mirrored east partition.
const CANVAS := Vector2i(96, 160)
const PIVOT := Vector2i(48, 112)
const SOURCE := "res://tests/fixtures/furniture-calibration/chair-west-v2-height56.png"

static func partition() -> Dictionary:
	# Actual bar: y89:x40..50; y90/91:x39..51; y92:x40..48.
	# The stem x44..47 continues y93..102, in front of the blue cushion.
	# Row103 joins the seat underside ambiguously and remains entirely rear.
	var near_arm: Array[Rect2i] = [Rect2i(39, 89, 13, 4), Rect2i(44, 93, 4, 10)]
	var rear: Array[Rect2i] = [Rect2i(Vector2i.ZERO, CANVAS)]
	for cut: Rect2i in near_arm:
		var remaining: Array[Rect2i] = []
		for rectangle: Rect2i in rear: remaining.append_array(subtract(rectangle, cut))
		rear = remaining
	return {"source": SOURCE, "canvas": CANVAS, "pivot": PIVOT, "rear": rear, "near_arm": near_arm, "status": "exact_source_partition_not_runtime_approved"}

static func subtract(rectangle: Rect2i, cut: Rect2i) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	if not rectangle.intersects(cut): return [rectangle]
	var overlap := rectangle.intersection(cut)
	var candidates: Array[Rect2i] = [
		Rect2i(rectangle.position, Vector2i(rectangle.size.x, overlap.position.y - rectangle.position.y)),
		Rect2i(Vector2i(rectangle.position.x, overlap.end.y), Vector2i(rectangle.size.x, rectangle.end.y - overlap.end.y)),
		Rect2i(Vector2i(rectangle.position.x, overlap.position.y), Vector2i(overlap.position.x - rectangle.position.x, overlap.size.y)),
		Rect2i(Vector2i(overlap.end.x, overlap.position.y), Vector2i(rectangle.end.x - overlap.end.x, overlap.size.y)),
	]
	for candidate: Rect2i in candidates:
		if candidate.has_area(): result.append(candidate)
	return result

static func layer(art: Texture2D, regions: Array, foot: Vector2, depth: int) -> Node2D:
	var result := Node2D.new()
	result.position = foot - Vector2(PIVOT)
	result.z_as_relative = false
	result.z_index = depth
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rectangle: Rect2i in regions:
		var sprite := Sprite2D.new()
		sprite.texture = art
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(rectangle)
		sprite.position = Vector2(rectangle.position)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		result.add_child(sprite)
	return result
