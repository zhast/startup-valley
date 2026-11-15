class_name InteractionHighlight
extends RefCounted
## Child overlays retain each source layer's transform and depth. Original
## materials, textures and alpha-based picking are never changed.

const GLOW_SHADER: Shader = preload("res://world/interaction_highlight.gdshader")
var _overlays: Dictionary[int, Dictionary] = {}

func sync(sources: Array[Sprite2D]) -> void:
	for id: int in _overlays.keys():
		var source := _overlays[id].source.get_ref() as Sprite2D
		if not _visible_source(source) or not sources.has(source):
			var old := _overlays[id].overlay.get_ref() as Sprite2D
			if old != null:
				old.hide()
				old.queue_free()
			_overlays.erase(id)
	for source: Sprite2D in sources:
		if not _visible_source(source): continue
		var id := source.get_instance_id()
		var overlay := _overlays[id].overlay.get_ref() as Sprite2D if _overlays.has(id) else null
		if overlay == null:
			overlay = Sprite2D.new()
			overlay.name = "InteractionGlow"
			overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			overlay.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
			var glow := ShaderMaterial.new()
			glow.shader = GLOW_SHADER
			overlay.material = glow
			source.add_child(overlay)
			_overlays[id] = {"source": weakref(source), "overlay": weakref(overlay)}
		# A walking or seated actor may change texture, region or pose between
		# frames while the pointer remains still.
		overlay.texture = source.texture
		overlay.self_modulate.a = source.self_modulate.a
		overlay.centered = source.centered
		overlay.offset = source.offset
		overlay.flip_h = source.flip_h
		overlay.flip_v = source.flip_v
		overlay.hframes = source.hframes
		overlay.vframes = source.vframes
		overlay.frame = source.frame
		overlay.region_enabled = source.region_enabled
		overlay.region_rect = source.region_rect
		overlay.region_filter_clip_enabled = true
		var texture_size := source.texture.get_size()
		var region := source.region_rect if source.region_enabled else Rect2(Vector2.ZERO, texture_size)
		var cell_size := region.size / Vector2(source.hframes, source.vframes)
		region = Rect2(region.position + Vector2(source.frame_coords) * cell_size, cell_size)
		(overlay.material as ShaderMaterial).set_shader_parameter("source_texture", source.texture)
		(overlay.material as ShaderMaterial).set_shader_parameter("source_region", Vector4(region.position.x / texture_size.x, region.position.y / texture_size.y, region.end.x / texture_size.x, region.end.y / texture_size.y))

func active_sources() -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for entry: Dictionary in _overlays.values():
		var source := entry.source.get_ref() as Sprite2D
		if _visible_source(source): result.append(source)
	return result

func _visible_source(source: Sprite2D) -> bool:
	if not is_instance_valid(source) or not source.is_visible_in_tree() or source.texture == null or source.self_modulate.a <= 0.0: return false
	var item: CanvasItem = source
	while item != null:
		if item.modulate.a <= 0.0: return false
		item = item.get_parent() as CanvasItem
	return true
