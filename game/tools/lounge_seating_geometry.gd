class_name LoungeSeatingGeometry
extends RefCounted
## DEV ONLY. Two passive upholstered lounge families drawn directly at native
## screen-axis scale. No actor, seat socket, interaction or lifecycle metadata.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const FAMILIES: Array[String] = ["two_seat_sofa", "lounge_armchair"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]

const INK := Color("282622")
const CONTACT := Color("554e42")
const WOOD := Color("77512f")
const WOOD_LIGHT := Color("d1a369")
const SOFA := Color("536f7d")
const SOFA_LIGHT := Color("7f99a3")
const SOFA_DARK := Color("354b58")
const SOFA_SEAM := Color("b8c8c8")
const CHAIR := Color("a26142")
const CHAIR_LIGHT := Color("cf8b61")
const CHAIR_DARK := Color("713e2d")
const CHAIR_SEAM := Color("e1bd91")

static func revision(family: String) -> String:
	return {"two_seat_sofa": "two-seat-sofa-v3", "lounge_armchair": "lounge-armchair-v3"}.get(family, "")

static func canvas(family: String) -> Vector2i:
	return {"two_seat_sofa": Vector2i(192, 224), "lounge_armchair": Vector2i(160, 208)}.get(family, Vector2i.ZERO)

static func pivot(family: String) -> Vector2i:
	return {"two_seat_sofa": Vector2i(96, 144), "lounge_armchair": Vector2i(80, 128)}.get(family, Vector2i.ZERO)

static func sprite_offset(family: String) -> Vector2i:
	return canvas(family) / 2 - pivot(family)

static func output_root(family: String) -> String:
	return "res://tests/fixtures/furniture-calibration/" + revision(family) + "/"

static func _sofa_profile(side: String) -> Dictionary:
	var center := {
		"north": Vector2i(0, -16), "east": Vector2i(16, 0),
		"south": Vector2i(0, 16), "west": Vector2i(-16, 0),
	}[side] as Vector2i
	var horizontal := side in ["north", "south"]
	var occupied: Array = {
		"north": [[-1, -1], [0, -1], [1, -1], [-1, 0], [0, 0], [1, 0]],
		"east": [[0, -1], [1, -1], [0, 0], [1, 0], [0, 1], [1, 1]],
		"south": [[-1, 0], [0, 0], [1, 0], [-1, 1], [0, 1], [1, 1]],
		"west": [[-1, -1], [0, -1], [-1, 0], [0, 0], [-1, 1], [0, 1]],
	}[side]
	return {
		"family": "two_seat_sofa", "facing": side, "center": center,
		"axis": "horizontal" if horizontal else "vertical",
		"floor": Rect2i(center - (Vector2i(96, 64) if horizontal else Vector2i(64, 96)) / 2, Vector2i(96, 64) if horizontal else Vector2i(64, 96)),
		"footprint": [3, 2] if horizontal else [2, 3], "occupied": occupied,
		"rise": 60, "equivalent_view": {"north": "rear", "east": "right_side", "south": "front", "west": "left_side"}[side],
	}

static func _armchair_profile(side: String) -> Dictionary:
	var center := {
		"north": Vector2i(-16, -16), "east": Vector2i(16, -16),
		"south": Vector2i(16, 16), "west": Vector2i(-16, 16),
	}[side] as Vector2i
	var occupied: Array = {
		"north": [[-1, -1], [0, -1], [-1, 0], [0, 0]],
		"east": [[0, -1], [1, -1], [0, 0], [1, 0]],
		"south": [[0, 0], [1, 0], [0, 1], [1, 1]],
		"west": [[-1, 0], [0, 0], [-1, 1], [0, 1]],
	}[side]
	return {
		"family": "lounge_armchair", "facing": side, "center": center,
		"axis": "screen_y" if side in ["north", "south"] else "screen_x",
		"floor": Rect2i(center - Vector2i(32, 32), Vector2i(64, 64)),
		"footprint": [2, 2], "occupied": occupied, "rise": 52,
		"equivalent_view": {"north": "rear", "east": "right_side", "south": "front", "west": "left_side"}[side],
	}

static func profile(family: String, side: String) -> Dictionary:
	if side not in SIDES: return {}
	if family == "two_seat_sofa": return _sofa_profile(side)
	if family == "lounge_armchair": return _armchair_profile(side)
	return {}

static func _image(family: String) -> Image:
	var size := canvas(family)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image

static func _paint(image: Image, family: String, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + pivot(family), rect.size), color)

static func _soft_box(image: Image, family: String, rect: Rect2i, fill: Color, light: Color, dark: Color, seam := false) -> void:
	_paint(image, family, Rect2i(rect.position + Vector2i(2, 0), Vector2i(rect.size.x - 4, 1)), INK)
	_paint(image, family, Rect2i(rect.position + Vector2i(1, 1), Vector2i(rect.size.x - 2, 1)), INK)
	_paint(image, family, Rect2i(rect.position + Vector2i(0, 2), Vector2i(rect.size.x, rect.size.y - 4)), INK)
	_paint(image, family, Rect2i(rect.position + Vector2i(1, rect.size.y - 2), Vector2i(rect.size.x - 2, 1)), INK)
	_paint(image, family, Rect2i(rect.position + Vector2i(2, rect.size.y - 1), Vector2i(rect.size.x - 4, 1)), INK)
	_paint(image, family, Rect2i(rect.position + Vector2i(2, 2), Vector2i(rect.size.x - 4, rect.size.y - 4)), fill)
	_paint(image, family, Rect2i(rect.position + Vector2i(3, 2), Vector2i(rect.size.x - 6, 1)), light)
	_paint(image, family, Rect2i(rect.position + Vector2i(2, rect.size.y - 3), Vector2i(rect.size.x - 4, 1)), dark)
	if seam and rect.size.x >= 24:
		_paint(image, family, Rect2i(rect.position + Vector2i(rect.size.x / 2, 5), Vector2i(1, rect.size.y - 10)), dark)
		_paint(image, family, Rect2i(rect.position + Vector2i(rect.size.x / 2 - 1, 6), Vector2i(1, rect.size.y - 12)), light)

static func _contact(image: Image, family: String, point: Vector2i) -> void:
	# Small down-right support marks only. They ground the feet without making a
	# broad box or dither field under the upholstered body.
	_paint(image, family, Rect2i(point + Vector2i(1, 0), Vector2i(5, 1)), CONTACT)
	_paint(image, family, Rect2i(point + Vector2i(2, 1), Vector2i(3, 1)), CONTACT)

static func _wood_foot(image: Image, family: String, point: Vector2i, height := 9) -> void:
	_paint(image, family, Rect2i(point - Vector2i(2, height), Vector2i(5, height)), INK)
	_paint(image, family, Rect2i(point - Vector2i(1, height - 1), Vector2i(2, height - 2)), WOOD)
	_paint(image, family, Rect2i(point - Vector2i(1, height - 1), Vector2i(1, maxi(1, height - 4))), WOOD_LIGHT)

static func _draw_sofa_face(parts: Dictionary[String, Image], side: String) -> void:
	var family := "two_seat_sofa"
	var c: Vector2i = profile(family, side).center
	if side == "north":
		# Facing north exposes the near outside of the rear shell. The v2 study
		# incorrectly repeated the South seat inset here and merely recolored it.
		# This authored rear has a narrow backrest top and an opaque near face;
		# the seat lies behind it and is therefore not presented as a front view.
		for point: Vector2i in [Vector2i(-38, -36), Vector2i(38, -36), Vector2i(-38, 7), Vector2i(38, 7)]: _contact(parts.floor_shadow, family, point)
		_soft_box(parts.rear_structure, family, Rect2i(-42, -54, 84, 9), SOFA, SOFA_LIGHT, SOFA_DARK, true)
		_soft_box(parts.front_structure, family, Rect2i(-44, -47, 88, 50), SOFA_DARK, SOFA_LIGHT, SOFA_DARK, true)
		_soft_box(parts.front_structure, family, Rect2i(-48, -42, 13, 45), SOFA, SOFA_LIGHT, SOFA_DARK)
		_soft_box(parts.front_structure, family, Rect2i(35, -42, 13, 45), SOFA_DARK, SOFA_LIGHT, SOFA_DARK)
		_soft_box(parts.front_structure, family, Rect2i(-39, -3, 78, 18), SOFA_DARK, SOFA_LIGHT, SOFA_DARK, true)
		for point: Vector2i in [Vector2i(-37, 23), Vector2i(37, 23)]: _wood_foot(parts.front_structure, family, point)
		return
	var back := Rect2i(-44, -60, 88, 41)
	var seat := Rect2i(c + Vector2i(-40, -42), Vector2i(80, 30))
	for point: Vector2i in [c + Vector2i(-38, -20), c + Vector2i(38, -20), c + Vector2i(-38, 23), c + Vector2i(38, 23)]: _contact(parts.floor_shadow, family, point)
	_soft_box(parts.rear_structure, family, back, SOFA, SOFA_LIGHT, SOFA_DARK, true)
	_soft_box(parts.rear_structure, family, seat, SOFA_LIGHT, SOFA_LIGHT, SOFA_DARK, true)
	# Far arms establish the thick lounge silhouette behind the seat plane.
	_soft_box(parts.rear_structure, family, Rect2i(c + Vector2i(-47, -49), Vector2i(12, 39)), SOFA_DARK, SOFA_LIGHT, SOFA_DARK)
	_soft_box(parts.rear_structure, family, Rect2i(c + Vector2i(35, -49), Vector2i(12, 39)), SOFA, SOFA_LIGHT, SOFA_DARK)
	# Front rail and near arm caps stay separable from a future actor layer.
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(-43, -18), Vector2i(86, 15)), SOFA_DARK, SOFA_LIGHT, SOFA_DARK, true)
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(-48, -29), Vector2i(13, 28)), SOFA, SOFA_LIGHT, SOFA_DARK)
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(35, -29), Vector2i(13, 28)), SOFA_DARK, SOFA_LIGHT, SOFA_DARK)
	# The v1 study omitted the lower upholstered base, leaving its short feet
	# suspended. This support-only revision restores the base rather than turning
	# a low lounge sofa into a piece on implausibly tall legs.
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(-39, -3), Vector2i(78, 18)), SOFA_DARK, SOFA_LIGHT, SOFA_DARK, true)
	for point: Vector2i in [c + Vector2i(-37, 23), c + Vector2i(37, 23)]: _wood_foot(parts.front_structure, family, point)
	_paint(parts.front_structure, family, Rect2i(c + Vector2i(-27, -13), Vector2i(54, 1)), SOFA_SEAM)

static func _draw_sofa_side(parts: Dictionary[String, Image], side: String) -> void:
	var family := "two_seat_sofa"
	var p: Dictionary = profile(family, side)
	var floor: Rect2i = p.floor
	var east := side == "east"
	var back_x := floor.position.x + 2 if east else floor.end.x - 18
	var seat_x := back_x + 12 if east else floor.position.x + 6
	var support_x: Array[int] = [floor.position.x + 8, floor.end.x - 12]
	var far_contact_y := floor.position.y + 10
	var near_contact_y := floor.end.y - 9
	for x: int in support_x:
		_contact(parts.floor_shadow, family, Vector2i(x, far_contact_y))
		_contact(parts.floor_shadow, family, Vector2i(x, near_contact_y))
		# Far supports are painted first so the elevated upholstery properly hides
		# them instead of producing exposed frame bars across the cushion.
		_wood_foot(parts.rear_structure, family, Vector2i(x, far_contact_y), 31)
	# Horizontal surfaces shift upward by their actual elevation while retaining
	# the full 96px north/south floor depth. This fixes v2's top edge, which sat
	# only six pixels above the far floor contact despite declaring a 60px rise.
	_soft_box(parts.rear_structure, family, Rect2i(back_x, floor.position.y - int(p.rise), 16, floor.size.y + int(p.rise) - 9), SOFA_DARK if east else SOFA, SOFA_LIGHT, SOFA_DARK, true)
	_soft_box(parts.rear_structure, family, Rect2i(seat_x, floor.position.y - 20, 44, floor.size.y - 12), SOFA, SOFA_LIGHT, SOFA_DARK, true)
	_soft_box(parts.rear_structure, family, Rect2i(floor.position.x + 4, floor.position.y - 34, floor.size.x - 8, 14), SOFA_DARK, SOFA_LIGHT, SOFA_DARK)
	for x: int in support_x: _wood_foot(parts.front_structure, family, Vector2i(x, near_contact_y))
	_soft_box(parts.front_structure, family, Rect2i(floor.position.x + 4, floor.end.y - 48, floor.size.x - 8, 15), SOFA, SOFA_LIGHT, SOFA_DARK)
	_soft_box(parts.front_structure, family, Rect2i(seat_x, floor.end.y - 33, 44, 25), SOFA_DARK, SOFA_LIGHT, SOFA_DARK, true)
	# Fixed screen-light piping is authored independently on each physical side.
	_paint(parts.front_structure, family, Rect2i(back_x + 3, floor.position.y - int(p.rise) + 5, 1, floor.size.y + int(p.rise) - 24), SOFA_SEAM)

static func _draw_armchair_face(parts: Dictionary[String, Image], side: String) -> void:
	var family := "lounge_armchair"
	var c: Vector2i = profile(family, side).center
	if side == "north":
		for point: Vector2i in [Vector2i(-39, -36), Vector2i(7, -36), Vector2i(-39, 7), Vector2i(7, 7)]: _contact(parts.floor_shadow, family, point)
		_soft_box(parts.rear_structure, family, Rect2i(-41, -52, 50, 9), CHAIR, CHAIR_LIGHT, CHAIR_DARK)
		_soft_box(parts.front_structure, family, Rect2i(-43, -45, 54, 45), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
		_soft_box(parts.front_structure, family, Rect2i(-48, -38, 13, 38), CHAIR, CHAIR_LIGHT, CHAIR_DARK)
		_soft_box(parts.front_structure, family, Rect2i(3, -38, 13, 38), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
		_soft_box(parts.front_structure, family, Rect2i(-38, -1, 44, 12), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
		for point: Vector2i in [Vector2i(-37, 7), Vector2i(5, 7)]: _wood_foot(parts.front_structure, family, point, 8)
		return
	for point: Vector2i in [c + Vector2i(-23, -20), c + Vector2i(23, -20), c + Vector2i(-23, 23), c + Vector2i(23, 23)]: _contact(parts.floor_shadow, family, point)
	_soft_box(parts.rear_structure, family, Rect2i(c.x - 25, -52, 50, 40), CHAIR, CHAIR_LIGHT, CHAIR_DARK, false)
	_soft_box(parts.rear_structure, family, Rect2i(c + Vector2i(-22, -31), Vector2i(44, 28)), CHAIR_LIGHT, CHAIR_LIGHT, CHAIR_DARK, false)
	_soft_box(parts.rear_structure, family, Rect2i(c + Vector2i(-30, -40), Vector2i(12, 38)), CHAIR, CHAIR_LIGHT, CHAIR_DARK)
	_soft_box(parts.rear_structure, family, Rect2i(c + Vector2i(18, -40), Vector2i(12, 38)), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(-25, -9), Vector2i(50, 15)), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(-30, -22), Vector2i(13, 29)), CHAIR, CHAIR_LIGHT, CHAIR_DARK)
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(17, -22), Vector2i(13, 29)), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
	# A compact lower base joins the v1 detached feet without changing the
	# chair's floor contract or inflating its legs.
	_soft_box(parts.front_structure, family, Rect2i(c + Vector2i(-22, 4), Vector2i(44, 12)), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
	for point: Vector2i in [c + Vector2i(-21, 23), c + Vector2i(21, 23)]: _wood_foot(parts.front_structure, family, point, 8)
	_paint(parts.front_structure, family, Rect2i(c + Vector2i(-15, -5), Vector2i(30, 1)), CHAIR_SEAM)

static func _draw_armchair_side(parts: Dictionary[String, Image], side: String) -> void:
	var family := "lounge_armchair"
	var p: Dictionary = profile(family, side)
	var floor: Rect2i = p.floor
	var east := side == "east"
	var back_x := floor.position.x + 3 if east else floor.end.x - 16
	var seat_x := back_x + 11 if east else floor.position.x + 7
	var support_x: Array[int] = [floor.position.x + 9, floor.end.x - 11]
	var far_contact_y := floor.position.y + 10
	var near_contact_y := floor.end.y - 8
	for x: int in support_x:
		_contact(parts.floor_shadow, family, Vector2i(x, far_contact_y))
		_contact(parts.floor_shadow, family, Vector2i(x, near_contact_y))
		_wood_foot(parts.rear_structure, family, Vector2i(x, far_contact_y), 29)
	_soft_box(parts.rear_structure, family, Rect2i(back_x, floor.position.y - int(p.rise), 14, floor.size.y + int(p.rise) - 8), CHAIR_DARK if east else CHAIR, CHAIR_LIGHT, CHAIR_DARK)
	_soft_box(parts.rear_structure, family, Rect2i(seat_x, floor.position.y - 18, 38, floor.size.y - 11), CHAIR, CHAIR_LIGHT, CHAIR_DARK)
	_soft_box(parts.rear_structure, family, Rect2i(floor.position.x + 5, floor.position.y - 30, floor.size.x - 10, 13), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
	for x: int in support_x: _wood_foot(parts.front_structure, family, Vector2i(x, near_contact_y), 8)
	_soft_box(parts.front_structure, family, Rect2i(floor.position.x + 5, floor.end.y - 38, floor.size.x - 10, 13), CHAIR, CHAIR_LIGHT, CHAIR_DARK)
	_soft_box(parts.front_structure, family, Rect2i(seat_x, floor.end.y - 28, 38, 21), CHAIR_DARK, CHAIR_LIGHT, CHAIR_DARK)
	_paint(parts.front_structure, family, Rect2i(back_x + 3, floor.position.y - int(p.rise) + 4, 1, floor.size.y + int(p.rise) - 21), CHAIR_SEAM)

static func layers(family: String, side: String) -> Dictionary[String, Image]:
	if profile(family, side).is_empty(): return {}
	var result: Dictionary[String, Image] = {}
	for layer_name: String in LAYERS: result[layer_name] = _image(family)
	if family == "two_seat_sofa":
		if side in ["north", "south"]: _draw_sofa_face(result, side)
		else: _draw_sofa_side(result, side)
	else:
		if side in ["north", "south"]: _draw_armchair_face(result, side)
		else: _draw_armchair_side(result, side)
	return result

static func whole(family: String, side: String) -> Image:
	var result := _image(family)
	var parts := layers(family, side)
	for layer_name: String in LAYERS:
		result.blend_rect(parts[layer_name], Rect2i(Vector2i.ZERO, canvas(family)), Vector2i.ZERO)
	return result

static func layer_depth(layer_name: String) -> int:
	return {"floor_shadow": -8, "rear_structure": -6, "front_structure": 5}.get(layer_name, 0)

static func descriptor(family: String, side: String, layer_name: String) -> Dictionary:
	var size := canvas(family)
	var offset := sprite_offset(family)
	return {
		"name": family.to_pascal_case() + layer_name.to_pascal_case(),
		"art": output_root(family) + side + "-" + layer_name + ".png",
		"region": [0, 0, size.x, size.y], "offset": [offset.x, offset.y],
		"z_offset": layer_depth(layer_name),
	}

static func catalog_entry(family: String) -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var geometry := profile(family, side)
		var used := whole(family, side).get_used_rect()
		var local := Rect2i(used.position - pivot(family), used.size)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in LAYERS: render_layers.append(descriptor(family, side, layer_name))
		profiles[side] = {
			"profile_kind": "decorative", "status": "calibration_candidate",
			"review": {"art": false, "geometry": false},
			"occupied": geometry.occupied.duplicate(true), "clearance": [],
			"anchor_offset": [0, 0],
			"visual_bounds": [local.position.x, local.position.y, local.size.x, local.size.y],
			"hit_bounds": [local.position.x, local.position.y, local.size.x, local.size.y],
			"render_layers": render_layers, "ambient_overlays": [],
			"calibration_limitations": [
				"Bare passive upholstered furniture only; no seat socket, interaction, reservation, actor pose or runtime approval.",
				"Existing actors are scale/depth probes only and are never baked into these layers.",
			],
		}
	return {"display_name": family.replace("_", " ").capitalize() + " candidate", "facings": SIDES.duplicate(), "interaction_kind": "none", "wall_mount": "none", "facing_profiles": profiles}
