extends RefCounted
## DEV-ONLY source-preserving rectangular partition, not newly painted art.
## E2 near arm is visibly separable. Unknown facings deliberately return{}.

const CANVAS := Vector2i(96, 160)
const PIVOT := Vector2i(48, 112)

static func partition(facing: String) -> Dictionary:
	if facing != "east": return {}
	# Measured alpha spans: bar y88:x46..55,y89/90:x44..57,y91:x45..56;
	# connector y92:x48..51; stem y93..101:x48..50. The continuous underside
	# atrow102 is ambiguous seat/support ownership and stays entirely rear.
	var front: Array[Rect2i] = [Rect2i(44, 88, 14, 4), Rect2i(48, 92, 4, 1), Rect2i(48, 93, 3, 9)]
	var rear: Array[Rect2i] = [Rect2i(Vector2i.ZERO, CANVAS)]
	for cut: Rect2i in front:
		var remaining: Array[Rect2i] = []
		for rect: Rect2i in rear:
			remaining.append_array(subtract(rect, cut))
		rear = remaining
	return {"canvas": CANVAS, "pivot": PIVOT, "rear": rear, "front": front, "source": "res://tests/fixtures/furniture-calibration/chair-east-v2.png", "status": "source_partition_candidate_not_runtime_approved"}

static func subtract(rect: Rect2i, cut: Rect2i) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	if not rect.intersects(cut):
		result.append(rect)
		return result
	var overlap := rect.intersection(cut)
	var candidates: Array[Rect2i] = [
		Rect2i(rect.position, Vector2i(rect.size.x, overlap.position.y - rect.position.y)),
		Rect2i(Vector2i(rect.position.x, overlap.end.y), Vector2i(rect.size.x, rect.end.y - overlap.end.y)),
		Rect2i(Vector2i(rect.position.x, overlap.position.y), Vector2i(overlap.position.x - rect.position.x, overlap.size.y)),
		Rect2i(Vector2i(overlap.end.x, overlap.position.y), Vector2i(rect.end.x - overlap.end.x, overlap.size.y)),
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
