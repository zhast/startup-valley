class_name BroadleafPlanterGeometry
extends RefCounted
## DEV ONLY. Deterministic one-cell broadleaf floor planter. The four views
## are independent screen-space geometry declarations. The failed generated
## RGB/checkerboard sources are provenance references only: their pixels are
## never loaded, keyed, masked, traced, transformed, or relabelled as alpha.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "rear_structure", "front_structure"]
const CANVAS := Vector2i(128, 224)
const PIVOT := Vector2i(64, 176)
const SPRITE_OFFSET := Vector2i(0, -64)
const OCCUPIED: Array[Vector2i] = [Vector2i.ZERO]
const SOURCE_V1 := "res://assets/source/overnight-20260904/plants/broadleaf-planter-fourway-v1.png"
const SOURCE_V2 := "res://assets/source/overnight-20260904/plants/broadleaf-planter-fourway-v2.png"
const PROMPT_V1 := "res://../dev/art-catalogue/prompts/broadleaf-planter-fourway-v1.md"
const PROMPT_V2 := "res://../dev/art-catalogue/prompts/broadleaf-planter-fourway-v2.md"

const INK := Color("282622")
const SHADOW := Color("554e42")
const SOIL := Color("493421")
const SOIL_LIGHT := Color("77512f")
const STEM_DARK := Color("5b3d27")
const STEM := Color("8a5f35")
const STEM_LIGHT := Color("d1a369")
const LEAF_DARK := Color("274b39")
const LEAF_MID := Color("3f7046")
const LEAF_WARM := Color("5f8a4c")
const LEAF_LIGHT := Color("83ab56")
const LEAF_GLEAM := Color("c1d879")
const POT_DARK := Color("8f846e")
const POT_SHADE := Color("b4a88f")
const POT := Color("d8cfb9")
const POT_LIGHT := Color("ece3ca")

static func _leaf(base: Vector2i, tip: Vector2i, width: int, bend: float, layer: String, tone: int) -> Dictionary:
	return {"base": base, "tip": tip, "width": width, "bend": bend, "layer": layer, "tone": tone}

static func profile(side: String) -> Dictionary:
	# Base/tip coordinates are literal screen pixels on the common canvas. None
	# of these arrangements is derived from another direction.
	match side:
		"north":
			return {
				"facing": side, "axis": "screen_y", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [0, 1], "employee_look_vector": [0, -1],
				"pot": {"center_x": 64, "top_y": 147, "bottom_y": 180, "upper_half_width": 21, "lower_half_width": 17},
				"leaves": [
					_leaf(Vector2i(63, 138), Vector2i(61, 59), 11, -2.0, "rear_structure", 0),
					_leaf(Vector2i(60, 141), Vector2i(31, 80), 13, 3.0, "rear_structure", 1),
					_leaf(Vector2i(68, 140), Vector2i(99, 83), 13, -3.0, "rear_structure", 2),
					_leaf(Vector2i(66, 142), Vector2i(81, 98), 10, 2.0, "rear_structure", 1),
					_leaf(Vector2i(58, 145), Vector2i(22, 114), 14, -3.0, "front_structure", 2),
					_leaf(Vector2i(71, 145), Vector2i(108, 118), 14, 2.0, "front_structure", 0),
				],
			}
		"east":
			return {
				"facing": side, "axis": "screen_x", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [-1, 0], "employee_look_vector": [1, 0],
				"pot": {"center_x": 65, "top_y": 148, "bottom_y": 180, "upper_half_width": 20, "lower_half_width": 16},
				"leaves": [
					_leaf(Vector2i(65, 139), Vector2i(77, 59), 12, -1.5, "rear_structure", 1),
					_leaf(Vector2i(61, 141), Vector2i(40, 84), 11, 3.5, "rear_structure", 0),
					_leaf(Vector2i(69, 140), Vector2i(106, 89), 13, -3.0, "rear_structure", 2),
					_leaf(Vector2i(68, 143), Vector2i(94, 105), 11, 1.0, "rear_structure", 0),
					_leaf(Vector2i(59, 146), Vector2i(28, 120), 14, -2.0, "front_structure", 1),
					_leaf(Vector2i(73, 146), Vector2i(111, 125), 13, 3.0, "front_structure", 2),
				],
			}
		"south":
			return {
				"facing": side, "axis": "screen_y", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [0, -1], "employee_look_vector": [0, 1],
				"pot": {"center_x": 63, "top_y": 147, "bottom_y": 179, "upper_half_width": 21, "lower_half_width": 16},
				"leaves": [
					_leaf(Vector2i(64, 138), Vector2i(68, 60), 12, 2.5, "rear_structure", 2),
					_leaf(Vector2i(59, 141), Vector2i(27, 86), 13, -2.0, "rear_structure", 0),
					_leaf(Vector2i(69, 140), Vector2i(96, 77), 12, 3.0, "rear_structure", 1),
					_leaf(Vector2i(66, 143), Vector2i(84, 104), 10, -2.0, "rear_structure", 2),
					_leaf(Vector2i(57, 146), Vector2i(19, 122), 13, -3.0, "front_structure", 1),
					_leaf(Vector2i(71, 145), Vector2i(104, 120), 14, 1.5, "front_structure", 0),
				],
			}
		"west":
			return {
				"facing": side, "axis": "screen_x", "footprint": [1, 1],
				"occupied": [[0, 0]], "interaction": [1, 0], "employee_look_vector": [-1, 0],
				"pot": {"center_x": 64, "top_y": 148, "bottom_y": 180, "upper_half_width": 20, "lower_half_width": 17},
				"leaves": [
					_leaf(Vector2i(62, 139), Vector2i(50, 61), 12, 2.0, "rear_structure", 0),
					_leaf(Vector2i(68, 141), Vector2i(90, 82), 12, -3.5, "rear_structure", 2),
					_leaf(Vector2i(59, 140), Vector2i(21, 91), 13, 3.0, "rear_structure", 1),
					_leaf(Vector2i(60, 143), Vector2i(34, 106), 10, -1.0, "rear_structure", 2),
					_leaf(Vector2i(72, 146), Vector2i(103, 120), 14, 2.5, "front_structure", 0),
					_leaf(Vector2i(56, 146), Vector2i(18, 125), 13, -2.5, "front_structure", 1),
				],
			}
	return {}

static func _image() -> Image:
	var result := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	return result

static func _inside(point: Vector2i) -> bool:
	return point.x >= 0 and point.y >= 0 and point.x < CANVAS.x and point.y < CANVAS.y

static func _put_pixel(image: Image, point: Vector2i, color: Color) -> void:
	if _inside(point):
		image.set_pixelv(point, color)

static func _draw_segment(image: Image, from: Vector2i, to: Vector2i, color: Color, thickness := 1) -> void:
	var delta := to - from
	var steps := maxi(absi(delta.x), absi(delta.y))
	if steps == 0:
		_put_pixel(image, from, color)
		return
	for index: int in range(steps + 1):
		var point := Vector2i((Vector2(from) + Vector2(delta) * (float(index) / float(steps))).round())
		for oy: int in range(-thickness / 2, thickness - thickness / 2):
			for ox: int in range(-thickness / 2, thickness - thickness / 2):
				_put_pixel(image, point + Vector2i(ox, oy), color)

static func _draw_stem(image: Image, pot: Dictionary, leaf: Dictionary) -> void:
	var from := Vector2i(int(pot.center_x), int(pot.top_y) + 7)
	var to: Vector2i = leaf.base
	_draw_segment(image, from + Vector2i(1, 0), to + Vector2i(1, 0), STEM_DARK, 3)
	_draw_segment(image, from, to, STEM, 2)
	# The one-pixel screen-left highlight stays fixed when the plant faces change.
	_draw_segment(image, from + Vector2i(-1, -1), to + Vector2i(-1, -1), STEM_LIGHT, 1)

static func _leaf_fill(tone: int) -> Color:
	return [LEAF_MID, LEAF_WARM, LEAF_MID][clampi(tone, 0, 2)]

static func _draw_leaf(image: Image, leaf: Dictionary) -> void:
	var base: Vector2i = leaf.base
	var tip: Vector2i = leaf.tip
	var vector := Vector2(tip - base)
	var length := vector.length()
	if length <= 1.0:
		return
	var axis := vector / length
	var normal := Vector2(-axis.y, axis.x)
	var width := float(int(leaf.width))
	var bend := float(leaf.bend)
	var margin := ceili(width + absf(bend) + 3.0)
	var min_x := mini(base.x, tip.x) - margin
	var max_x := maxi(base.x, tip.x) + margin
	var min_y := mini(base.y, tip.y) - margin
	var max_y := maxi(base.y, tip.y) + margin
	var fill := _leaf_fill(int(leaf.tone))
	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var sample := Vector2(x + 0.5, y + 0.5)
			var raw_t := (sample - Vector2(base)).dot(axis) / length
			if raw_t < 0.0 or raw_t > 1.0:
				continue
			var curve := sin(raw_t * PI) * bend
			var center := Vector2(base) + axis * (raw_t * length) + normal * curve
			var transverse := absf((sample - center).dot(normal))
			var envelope := pow(maxf(0.0, sin(raw_t * PI)), 0.68)
			var stepped_noise := 0.45 if (x + y + int(leaf.tone)) % 4 == 0 else 0.0
			var half_width := width * envelope - stepped_noise
			if transverse > half_width or half_width < 0.45:
				continue
			var color := LEAF_DARK
			if transverse <= half_width - 1.35:
				color = fill
				# Sparse upper-left facets make the screen-space light readable while
				# leaving broad, dark organic masses at native scale.
				if x < center.x - 0.5 and y < lerpf(float(base.y), float(tip.y), raw_t) + 3.0:
					if (x * 3 + y + int(leaf.tone)) % 7 < 3:
						color = LEAF_LIGHT
						if raw_t > 0.25 and raw_t < 0.70 and (x + y) % 11 == 0:
							color = LEAF_GLEAM
			_put_pixel(image, Vector2i(x, y), color)
	# A broken midrib and short branch veins keep the leaf legible as pixel art.
	for index: int in range(3, maxi(4, floori(length) - 2)):
		var t := float(index) / length
		if t >= 0.94:
			break
		var center := Vector2(base) + axis * float(index) + normal * (sin(t * PI) * bend)
		var center_pixel := Vector2i(center.round())
		_put_pixel(image, center_pixel, STEM_LIGHT if index % 4 != 0 else STEM)
		if index % 9 == 3 and t > 0.18 and t < 0.78:
			var vein_span := maxi(2, roundi(width * sin(t * PI) * 0.48))
			_draw_segment(image, center_pixel, Vector2i((center + normal * vein_span - axis * 2.0).round()), LEAF_LIGHT, 1)
		if index % 11 == 5 and t > 0.22 and t < 0.74:
			var vein_span := maxi(2, roundi(width * sin(t * PI) * 0.42))
			_draw_segment(image, center_pixel, Vector2i((center - normal * vein_span - axis * 2.0).round()), LEAF_DARK, 1)
	_put_pixel(image, tip, LEAF_DARK)

static func _draw_shadow(image: Image, pot: Dictionary) -> void:
	var center := Vector2(float(pot.center_x), float(pot.bottom_y) - 1.0)
	var radius := Vector2(28.0, 9.0)
	for y: int in range(int(center.y - radius.y), int(center.y + radius.y) + 1):
		for x: int in range(int(center.x - radius.x), int(center.x + radius.x) + 1):
			var delta := (Vector2(x + 0.5, y + 0.5) - center) / radius
			var distance := delta.length_squared()
			if distance <= 1.0 and (distance < 0.48 or (x + y) % 2 == 0):
				_put_pixel(image, Vector2i(x, y), SHADOW)

static func _draw_back_rim(image: Image, pot: Dictionary) -> void:
	var center := Vector2(float(pot.center_x), float(pot.top_y) + 4.0)
	var radius := Vector2(float(pot.upper_half_width), 6.0)
	for y: int in range(int(center.y - radius.y), int(center.y + 1.0)):
		for x: int in range(int(center.x - radius.x), int(center.x + radius.x) + 1):
			var delta := (Vector2(x + 0.5, y + 0.5) - center) / radius
			var distance := delta.length_squared()
			if distance <= 1.0:
				var color := SOIL if distance < 0.77 else INK
				if distance < 0.55 and x < int(center.x) and (x + y) % 5 == 0:
					color = SOIL_LIGHT
				_put_pixel(image, Vector2i(x, y), color)

static func _draw_front_pot(image: Image, pot: Dictionary) -> void:
	var center_x := int(pot.center_x)
	var top := int(pot.top_y) + 3
	var bottom := int(pot.bottom_y)
	var upper := float(pot.upper_half_width)
	var lower := float(pot.lower_half_width)
	for y: int in range(top, bottom + 1):
		var t := float(y - top) / float(maxi(1, bottom - top))
		var half_width := roundi(lerpf(upper, lower, t))
		for x: int in range(center_x - half_width, center_x + half_width + 1):
			var edge := x == center_x - half_width or x == center_x + half_width or y == bottom
			var color := INK if edge else POT
			if not edge:
				if x <= center_x - maxi(7, half_width / 2) and y < bottom - 3:
					color = POT_LIGHT
				elif x >= center_x + maxi(7, half_width / 2) or y >= bottom - 3:
					color = POT_SHADE
				elif (x + y) % 19 == 0:
					color = POT_DARK
			_put_pixel(image, Vector2i(x, y), color)
	# Front lip: a stepped lower half-ellipse with a ceramic highlight band.
	var rim_center := Vector2(float(center_x), float(pot.top_y) + 4.0)
	var rim_radius := Vector2(upper, 6.0)
	for y: int in range(int(rim_center.y), int(rim_center.y + rim_radius.y) + 1):
		for x: int in range(int(rim_center.x - rim_radius.x), int(rim_center.x + rim_radius.x) + 1):
			var delta := (Vector2(x + 0.5, y + 0.5) - rim_center) / rim_radius
			var distance := delta.length_squared()
			if distance <= 1.0 and distance >= 0.48:
				var color := POT_DARK if distance > 0.83 else POT_LIGHT
				if x > center_x + 8:
					color = POT_SHADE
				_put_pixel(image, Vector2i(x, y), color)

static func layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {
		"floor_shadow": _image(),
		"rear_structure": _image(),
		"front_structure": _image(),
	}
	var p := profile(side)
	if p.is_empty():
		return result
	_draw_shadow(result.floor_shadow, p.pot)
	for layer_name: String in ["rear_structure", "front_structure"]:
		for leaf: Dictionary in p.leaves:
			if str(leaf.layer) == layer_name:
				_draw_stem(result[layer_name], p.pot, leaf)
		for leaf: Dictionary in p.leaves:
			if str(leaf.layer) == layer_name:
				_draw_leaf(result[layer_name], leaf)
	_draw_back_rim(result.rear_structure, p.pot)
	_draw_front_pot(result.front_structure, p.pot)
	return result

static func binary_over(back: Image, near: Image) -> Image:
	var result := back.get_data().duplicate()
	var front := near.get_data()
	for at: int in range(0, result.size(), 4):
		if front[at + 3] != 0:
			for channel: int in range(4):
				result[at + channel] = front[at + channel]
	return Image.create_from_data(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8, result)

static func whole(side: String) -> Image:
	var parts := layers(side)
	return binary_over(binary_over(parts.floor_shadow, parts.rear_structure), parts.front_structure)

static func layer_depth(layer_name: String) -> int:
	return {"floor_shadow": -8, "rear_structure": -4, "front_structure": 5}.get(layer_name, 0)

static func descriptor(side: String, layer_name: String) -> Dictionary:
	return {
		"name": "BroadleafPlanter" + layer_name.to_pascal_case(),
		"art": "res://tests/fixtures/furniture-calibration/broadleaf-planter-v1/%s-%s.png" % [side, layer_name],
		"region": [0, 0, CANVAS.x, CANVAS.y],
		"offset": [SPRITE_OFFSET.x, SPRITE_OFFSET.y],
		"z_offset": layer_depth(layer_name),
	}

static func catalog_entry() -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var p := profile(side)
		var bounds := whole(side).get_used_rect()
		var local_bounds := Rect2i(bounds.position - PIVOT, bounds.size)
		var render_layers: Array[Dictionary] = []
		for layer_name: String in LAYERS:
			render_layers.append(descriptor(side, layer_name))
		profiles[side] = {
			"profile_kind": "decorative",
			"status": "calibration_candidate",
			"review": {"art": false, "geometry": false},
			"occupied": p.occupied.duplicate(true),
			"clearance": [p.interaction.duplicate()],
			"anchor_offset": [0, 0],
			"visual_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"hit_bounds": [local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y],
			"render_layers": render_layers,
			"ambient_overlays": [],
			"standing_viewpoints": [
				{"cell": p.interaction.duplicate(), "visual_bounds": [-24, -76, 48, 84]},
			],
			"calibration_limitations": [
				"Standing actor contact is evidence-only; this passive planter exposes no interaction capability.",
				"Generated checkerboard source pixels are not used by these independently authored native layers.",
			],
		}
	return {
		"display_name": "Broadleaf planter candidate",
		"facings": SIDES.duplicate(),
		"interaction_kind": "none",
		"wall_mount": "none",
		"facing_profiles": profiles,
	}
