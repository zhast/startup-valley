extends RefCounted
## Development-only inventory of actual canonical furniture layer instances.

static func collect(room: TownRoom) -> Dictionary:
	var records: Array[Dictionary] = []
	var expected: Array[String] = []
	var errors: Array[String] = []
	for placement: Dictionary in room.resolved_placements:
		var placement_id := str(placement.id)
		var prop := room._prop_root.get_node_or_null(NodePath(placement_id))
		for layer: Dictionary in placement.get("render_layers", []):
			var layer_name := str(layer.name)
			var key := placement_id + "/" + layer_name
			if key in expected: errors.append("Duplicate declared furniture layer: " + key)
			expected.append(key)
			var sprite: Sprite2D = prop.get_node_or_null(NodePath(layer_name)) as Sprite2D if prop != null else null
			if sprite == null:
				errors.append("Missing live furniture layer: " + key)
				continue
			if sprite.texture == null or sprite.texture.resource_path != str(layer.art): errors.append("Layer texture differs from declared art: " + key)
			if not sprite.region_enabled or sprite.region_rect != OfficeLayout.rectangle(layer.region): errors.append("Layer region differs from declared crop: " + key)
			if sprite.position != Vector2(OfficeLayout.vector(layer.offset)): errors.append("Layer offset differs from declared anchor: " + key)
			if sprite.scale != Vector2.ONE or sprite.global_scale != Vector2.ONE: errors.append("Layer is not native scale: " + key)
			if not is_zero_approx(sprite.rotation) or sprite.flip_h or sprite.flip_v: errors.append("Layer has a raster rotation or mirror: " + key)
			records.append({"id": key, "placementId": placement_id, "layerName": layer_name, "sprite": sprite})
	return {"records": records, "expected": expected, "errors": errors}
