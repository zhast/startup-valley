class_name VisitorChairReviewV2
extends RefCounted
## DEV ONLY. Shadow-only review revision of visitor-chair-v1. Every structural
## pixel, projection, pivot, collision cell and contact point remains v1.

const CHAIR := preload("res://tools/visitor_chair_geometry.gd")
const REVISION := "visitor-chair-v2"
const OUTPUT_ROOT := "res://tests/fixtures/furniture-calibration/" + REVISION
const SHADOW := Color("554e42")
const SIDES: Array[String] = CHAIR.SIDES
const LAYERS: Array[String] = CHAIR.LAYERS
const CANVAS := CHAIR.CANVAS
const PIVOT := CHAIR.PIVOT
const SPRITE_OFFSET := CHAIR.SPRITE_OFFSET

static func profile(side: String) -> Dictionary: return CHAIR.profile(side)
static func contact_socket(side: String) -> Dictionary: return CHAIR.contact_socket(side)
static func layer_depth(layer_name: String) -> int: return CHAIR.layer_depth(layer_name)
static func binary_over(back: Image, near: Image) -> Image: return CHAIR.binary_over(back, near)

static func contact_mark_rects(side: String) -> Array[Rect2i]:
	var profile: Dictionary = CHAIR.profile(side)
	var floor := Rect2i(-16, -16, 32, 32)
	var result: Array[Rect2i] = []
	for value: Variant in profile.get("contact_points", []):
		var point := Vector2i(value)
		# Fixed upper-left light: two tiny down/right rows touch each declared
		# support. Intersecting the physical cell keeps the front row grounded.
		for candidate: Rect2i in [
			Rect2i(point + Vector2i(1, -1), Vector2i(5, 1)),
			Rect2i(point + Vector2i(2, 0), Vector2i(4, 1)),
		]:
			var clipped := candidate.intersection(floor)
			if clipped.has_area(): result.append(clipped)
	return result

static func _image() -> Image:
	var image := Image.create(CHAIR.CANVAS.x, CHAIR.CANVAS.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image

static func contact_shadow(side: String) -> Image:
	var image := _image()
	for rect: Rect2i in contact_mark_rects(side):
		image.fill_rect(Rect2i(rect.position + CHAIR.PIVOT, rect.size), SHADOW)
	return image

static func layers(side: String) -> Dictionary[String, Image]:
	if side not in CHAIR.SIDES: return {}
	var original: Dictionary[String, Image] = CHAIR.layers(side)
	return {
		"floor_shadow": contact_shadow(side),
		"seat_back": (original.seat_back as Image).duplicate(),
		"seat_front": (original.seat_front as Image).duplicate(),
	}

static func whole(side: String) -> Image:
	var parts := layers(side)
	if parts.is_empty(): return Image.new()
	return CHAIR.binary_over(CHAIR.binary_over(parts.floor_shadow, parts.seat_back), parts.seat_front)

static func descriptor(side: String, layer_name: String) -> Dictionary:
	var result: Dictionary = CHAIR.descriptor(side, layer_name).duplicate(true)
	result.art = OUTPUT_ROOT.path_join("%s-%s.png" % [side, layer_name])
	return result

static func catalog_entry() -> Dictionary:
	var result: Dictionary = CHAIR.catalog_entry().duplicate(true)
	result.display_name = "Visitor chair v2 shadow review"
	for side: String in CHAIR.SIDES:
		var profile: Dictionary = result.facing_profiles[side]
		var used := whole(side).get_used_rect()
		var local := Rect2i(used.position - CHAIR.PIVOT, used.size)
		profile.visual_bounds = [local.position.x, local.position.y, local.size.x, local.size.y]
		profile.hit_bounds = profile.visual_bounds.duplicate()
		var render_layers: Array[Dictionary] = []
		for layer_name: String in CHAIR.LAYERS:
			render_layers.append(descriptor(side, layer_name))
		profile.render_layers = render_layers
		profile.status = "calibration_candidate"
		profile.review = {"art": false, "geometry": false}
		profile.calibration_limitations = [
			"Shadow-only v2 review; v1 chair structure and optional contact geometry remain unchanged.",
			"Passive art only: no interaction, reservation policy, seated lifecycle or actor pose is added.",
		]
	return result
