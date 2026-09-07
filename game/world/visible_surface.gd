class_name VisibleSurface
extends RefCounted
## Picking for the native world body layers (one canvas, explicit Z, no Y-sort).
## Uses Godot's texture alpha cache, never a viewport/GPU image readback.

static func painted(sprite: Sprite2D, point: Vector2) -> bool:
	if not is_instance_valid(sprite) or not sprite.is_visible_in_tree() or sprite.texture == null: return false
	if sprite.self_modulate.a <= 0.0: return false
	var item: CanvasItem = sprite
	while item != null:
		if item.modulate.a <= 0.0: return false
		item = item.get_parent() as CanvasItem
	return sprite.is_pixel_opaque(sprite.to_local(point))

static func depth(item: CanvasItem) -> int:
	var result := item.z_index
	var parent := item.get_parent() as CanvasItem
	if item.z_as_relative and parent != null: result += depth(parent)
	return clampi(result, RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)

static func in_front(candidate: Sprite2D, current: Sprite2D) -> bool:
	if candidate == null: return false
	if current == null: return true
	var candidate_depth := depth(candidate)
	var current_depth := depth(current)
	if candidate_depth != current_depth: return candidate_depth > current_depth
	# Equal-Z native body layers draw in scene order. No input-priority override:
	# the last painted sibling/branch wins, just as it does in the renderer.
	return candidate.is_greater_than(current)

static func top(sprites: Array[Sprite2D], point: Vector2) -> Sprite2D:
	var result: Sprite2D
	for sprite: Sprite2D in sprites:
		if painted(sprite, point) and in_front(sprite, result): result = sprite
	return result
