class_name BaseFurnitureReviewV2
extends RefCounted
## DEV ONLY. Base-art review revision for the compact desk and shared workbench.
## The v1 structure stays byte-identical; only its checker-dither floor shadow is
## replaced by restrained, screen-down/right contact marks under authored feet.

const COMPACT := preload("res://tools/compact_desk_geometry.gd")
const WORKBENCH := preload("res://tools/shared_workbench_geometry.gd")
const FAMILIES: Array[String] = ["compact_desk", "shared_workbench"]
const SHADOW := Color("554e42")
const STRUCTURE_INK := Color("282622")

static func source(family: String) -> Variant:
	match family:
		"compact_desk": return COMPACT
		"shared_workbench": return WORKBENCH
	return null

static func revision(family: String) -> String:
	return {"compact_desk": "compact-desk-v2", "shared_workbench": "shared-workbench-v2"}.get(family, "")

static func display_name(family: String) -> String:
	return {"compact_desk": "Compact desk base v2", "shared_workbench": "Shared workbench base v2"}.get(family, family)

static func output_root(family: String) -> String:
	return "res://tests/fixtures/furniture-calibration/" + revision(family)

static func _image(canvas: Vector2i) -> Image:
	var result := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _paint_local(image: Image, pivot: Vector2i, local_rect: Rect2i, color: Color) -> void:
	if local_rect.has_area():
		image.fill_rect(Rect2i(local_rect.position + pivot, local_rect.size), color)

static func _contact_shadow(base: Variant, side: String) -> Image:
	var profile: Dictionary = base.profile(side)
	var result := _image(base.CANVAS)
	var floor: Rect2i = profile.floor
	var seen: Dictionary = {}
	# Main structure-ink rectangles identify the real foot/support marks in each
	# independently authored view. Long end-on workbenches expose several small
	# cross-axis feet, while the other views end on the declared contact row.
	for raw: Variant in profile.front_parts:
		var part := raw as Dictionary
		var rect: Rect2i = part.rect
		if part.color != STRUCTURE_INK:
			continue
		var reaches_contact := rect.end.y == int(profile.contact_y) and rect.size.x <= 10
		var end_on_support := str(profile.axis) == "vertical" and rect.size.x <= 10 and rect.size.y <= 8
		if not reaches_contact and not end_on_support:
			continue
		var key := "%d:%d" % [rect.end.x, rect.end.y]
		if seen.has(key):
			continue
		seen[key] = true
		# A fixed upper-left light produces three tiny stepped marks down/right of
		# each foot. They remain inside the physical floor mask and never form the
		# broad checker lattice that looked like an extra furniture component.
		var rows: Array[Rect2i] = [
			Rect2i(rect.end.x - 1, rect.end.y - 3, 7, 1),
			Rect2i(rect.end.x, rect.end.y - 2, 7, 1),
			Rect2i(rect.end.x + 1, rect.end.y - 1, 6, 1),
		]
		for row: Rect2i in rows:
			_paint_local(result, base.PIVOT, row.intersection(floor), SHADOW)
	return result

static func layers(family: String, side: String) -> Dictionary[String, Image]:
	var base: Variant = source(family)
	if base == null or side not in base.SIDES:
		return {}
	var original: Dictionary[String, Image] = base.layers(side)
	return {
		"floor_shadow": _contact_shadow(base, side),
		"rear_structure": (original.rear_structure as Image).duplicate(),
		"front_structure": (original.front_structure as Image).duplicate(),
	}

static func whole(family: String, side: String) -> Image:
	var base: Variant = source(family)
	var parts := layers(family, side)
	if base == null or parts.is_empty():
		return Image.new()
	return base.binary_over(base.binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure)

static func descriptor(family: String, side: String, layer_name: String) -> Dictionary:
	var base: Variant = source(family)
	if base == null:
		return {}
	var result: Dictionary = base.descriptor(side, layer_name).duplicate(true)
	result.art = output_root(family).path_join("%s-%s.png" % [side, layer_name])
	return result

static func catalog_entry(family: String) -> Dictionary:
	var base: Variant = source(family)
	if base == null:
		return {}
	var result: Dictionary = base.catalog_entry().duplicate(true)
	result.display_name = display_name(family)
	for side: String in base.SIDES:
		var profile: Dictionary = result.facing_profiles[side]
		var used := whole(family, side).get_used_rect()
		var local := Rect2i(used.position - base.PIVOT, used.size)
		profile.visual_bounds = [local.position.x, local.position.y, local.size.x, local.size.y]
		profile.hit_bounds = profile.visual_bounds.duplicate()
		var render_layers: Array[Dictionary] = []
		for layer_name: String in base.LAYERS:
			render_layers.append(descriptor(family, side, layer_name))
		profile.render_layers = render_layers
		profile.status = "calibration_candidate"
		profile.review = {"art": false, "geometry": false}
		profile.calibration_limitations = [
			"Base-art review only; no workstation action or seated capability is claimed.",
			"Chair, device, role tools, actors and work poses remain separate asset-family responsibilities.",
		]
	return result
