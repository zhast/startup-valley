class_name PhoneBoothV1Geometry
extends RefCounted
## DEV ONLY: original editable native call-booth art. Closed passive furniture,
## not an enterable room or a phone action. The camera stays fixed in every view.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "interior", "door_glazing", "rear_structure", "front_structure"]
const CANVAS := Vector2i(256, 416)
const PIVOT := Vector2i(128, 304)
const OFFSET := Vector2i(0, -96)
const ROOT := "res://tests/fixtures/furniture-calibration/phone-booth-v1"
const RISE := 112
const INK := Color("282622")
const EDGE := Color("735130")
const WOOD := Color("aa7745")
const LIGHT := Color("cba16e")
const DARK := Color("533e2b")
const FELT := Color("526768")
const FELT_LIGHT := Color("718381")
const FELT_DARK := Color("3c4c4e")
const FLOOR := Color("a29779")
const GLASS := Color("8caeaf")
const REFLECTION := Color("c0d1c5")
const METAL := Color("b6b5b0")

static func floor_rect(side: String) -> Rect2i:
	match side:
		"north": return Rect2i(-48, -16, 96, 96)
		"east": return Rect2i(-80, -48, 96, 96)
		"south": return Rect2i(-48, -80, 96, 96)
		"west": return Rect2i(-16, -48, 96, 96)
	return Rect2i()

static func occupied(side: String) -> Array:
	var result: Array = []
	var floor := floor_rect(side)
	for y: int in range(floor.position.y + 16, floor.end.y, 32):
		for x: int in range(floor.position.x + 16, floor.end.x, 32):
			result.append([x / 32, y / 32])
	return result

static func approach(side: String) -> Vector2i:
	return {"north": Vector2i(0, -1), "east": Vector2i(1, 0), "south": Vector2i(0, 1), "west": Vector2i(-1, 0)}.get(side, Vector2i.ZERO)

static func _image() -> Image:
	var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image

static func rect(image: Image, box: Rect2i, color: Color) -> void:
	if box.has_area(): image.fill_rect(Rect2i(box.position + PIVOT, box.size), color)

static func box(image: Image, bounds: Rect2i, color: Color, highlight: Color = LIGHT) -> void:
	rect(image, bounds, INK)
	rect(image, bounds.grow(-1), color)
	rect(image, Rect2i(bounds.position + Vector2i.ONE, Vector2i(bounds.size.x - 2, 1)), highlight)
	rect(image, Rect2i(bounds.position + Vector2i(1, 2), Vector2i(1, bounds.size.y - 3)), highlight)

static func over(base: Image, near: Image) -> Image:
	var result := base.get_data().duplicate()
	var pixels := near.get_data()
	for at: int in range(0, result.size(), 4):
		if pixels[at + 3] == 0: continue
		for channel: int in range(4): result[at + channel] = pixels[at + channel]
	return Image.create_from_data(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8, result)

static func _felt(image: Image, bounds: Rect2i) -> void:
	box(image, bounds, FELT, FELT_LIGHT)
	for x: int in range(bounds.position.x + 5, bounds.end.x - 2, 7):
		rect(image, Rect2i(x, bounds.position.y + 3, 1, bounds.size.y - 6), FELT_DARK)
	for y: int in range(bounds.position.y + 7, bounds.end.y - 3, 13):
		rect(image, Rect2i(bounds.position.x + 3, y, bounds.size.x - 6, 1), FELT_LIGHT)

static func layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {}
	for name_value: String in LAYERS: result[name_value] = _image()
	if side not in SIDES: return result
	var floor := floor_rect(side)
	var left := floor.position.x + 4
	var right := floor.end.x - 4
	var top := floor.position.y - RISE
	var bottom := floor.end.y
	var near_top := bottom - RISE
	var rear := result.rear_structure
	var front := result.front_structure
	var interior := result.interior
	var glass := result.door_glazing
	# Ground contact is outside the solid foot rail, not a floating dither field.
	rect(result.floor_shadow, Rect2i(left + 3, bottom - 3, right - left - 4, 4), Color("625945"))
	# Acoustic interior and the low standing shelf remain separate from the
	# glazed door and opaque shell. Only South exposes the complete interior.
	_felt(interior, Rect2i(left + 5, near_top + 7, right - left - 10, RISE - 15))
	box(interior, Rect2i(left + 7, bottom - 18, right - left - 14, 10), FLOOR)
	# Author the shelf on the wall opposite the actual door, without rotating
	# finished pixels. Asymmetric outlet/hinge details keep light screen-fixed.
	match side:
		"south":
			box(interior, Rect2i(left + 15, near_top + 52, 54, 10), WOOD)
			rect(interior, Rect2i(left + 19, near_top + 61, 4, 14), DARK)
			rect(interior, Rect2i(right - 28, near_top + 61, 4, 14), DARK)
		"north":
			box(interior, Rect2i(left + 15, top + 59, 54, 9), WOOD)
		"east":
			box(interior, Rect2i(left + 7, top + 48, 12, 68), WOOD)
			box(interior, Rect2i(left + 19, top + 52, 3, 63), EDGE)
		"west":
			box(interior, Rect2i(right - 19, top + 51, 12, 67), WOOD)
			box(interior, Rect2i(right - 22, top + 55, 3, 60), EDGE)
	# A horizontal roof plane is essential: the previous open canopy's upright
	# felt drawing looked like a second stacked storey. This closed booth uses a
	# pale planar roof, shallow seams and a small direction-specific vent.
	var roof := Rect2i(left, top, right - left, floor.size.y + 2)
	box(rear, roof, Color("c8b996"), Color("e0d2ad"))
	for y: int in range(top + 14, roof.end.y - 4, 17):
		rect(rear, Rect2i(left + 4, y, right - left - 8, 1), Color("b4a480"))
	var vent := Rect2i(left + 28, top + 10, 30, 10)
	match side:
		"east": vent = Rect2i(left + 10, top + 29, 10, 30)
		"south": vent = Rect2i(left + 28, roof.end.y - 23, 30, 10)
		"west": vent = Rect2i(right - 21, top + 29, 10, 30)
	box(rear, vent, FELT_DARK, FELT_LIGHT)
	if side in ["north", "south"]:
		for x: int in range(vent.position.x + 3, vent.end.x - 2, 4): rect(rear, Rect2i(x, vent.position.y + 2, 1, 6), FELT_LIGHT)
	else:
		for y: int in range(vent.position.y + 3, vent.end.y - 2, 4): rect(rear, Rect2i(vent.position.x + 2, y, 6, 1), FELT_LIGHT)
	# Side posts rise vertically. All light stays on upper/left edges.
	box(rear, Rect2i(left, top, right - left, 7), WOOD)
	box(rear, Rect2i(left, top + 5, 6, bottom - top - 9), WOOD)
	box(rear, Rect2i(right - 6, top + 5, 6, bottom - top - 9), EDGE)
	box(rear, Rect2i(left + 5, top + 5, 5, floor.size.y - 7), WOOD)
	box(rear, Rect2i(right - 10, top + 5, 5, floor.size.y - 7), EDGE)
	# Glazing uses clear pixels with authored edge/reflection marks, never a
	# painted checkerboard or partial-alpha veil. Door jamb remains detachable.
	var door := Rect2i(left + 9, near_top + 5, right - left - 18, RISE - 12)
	if side == "north": door.position.y = top + 6
	if side in ["north", "south"]:
		rect(glass, Rect2i(door.position, Vector2i(2, door.size.y)), GLASS)
		rect(glass, Rect2i(door.end.x - 2, door.position.y, 2, door.size.y), FELT_DARK)
		rect(glass, Rect2i(door.position.x + 2, door.position.y, door.size.x - 4, 2), GLASS)
		rect(glass, Rect2i(door.position.x + 4, door.end.y - 2, door.size.x - 8, 2), GLASS)
		for step: int in range(8): rect(glass, Rect2i(door.position + Vector2i(8 + step, 16 + step * 2), Vector2i(2, 2)), REFLECTION)
		rect(glass, Rect2i(door.end.x - 10, door.position.y + 40, 3, 16), INK)
		rect(glass, Rect2i(door.end.x - 9, door.position.y + 40, 1, 14), METAL)
	else:
		var door_x := right - 12 if side == "east" else left + 8
		box(glass, Rect2i(door_x, top + 12, 4, bottom - top - 23), GLASS, REFLECTION)
		rect(glass, Rect2i(door_x - 2 if side == "east" else door_x + 4, near_top + 41, 2, 13), METAL)
		for step: int in range(5): rect(glass, Rect2i(door_x + 1, top + 23 + step * 5, 1, 2), REFLECTION)
	# Camera-facing shell: north shows its opaque rear, south the actual glazed
	# doorway, E/W show the appropriate side panel and thin door edge.
	if side == "north":
		_felt(front, Rect2i(left + 5, near_top + 6, right - left - 10, RISE - 10))
		box(front, Rect2i(left, near_top, right - left, 7), WOOD)
	elif side in ["east", "west"]:
		_felt(front, Rect2i(left + 7, near_top + 6, right - left - 14, RISE - 13))
		box(front, Rect2i(left, near_top, right - left, 7), WOOD)
		var seam_x := right - 15 if side == "east" else left + 12
		rect(front, Rect2i(seam_x, near_top + 9, 2, RISE - 19), DARK)
	else:
		box(front, Rect2i(left, near_top, right - left, 7), WOOD)
		box(front, Rect2i(left, near_top + 6, 8, RISE - 10), WOOD)
		box(front, Rect2i(right - 8, near_top + 6, 8, RISE - 10), EDGE)
	box(front, Rect2i(left, bottom - 7, right - left, 5), WOOD)
	return result

static func whole(side: String) -> Image:
	var result := _image()
	var parts := layers(side)
	for layer: String in LAYERS: result = over(result, parts[layer])
	return result

static func descriptor(side: String, layer: String) -> Dictionary:
	var depth := floor_rect(side).end.y
	var z := depth - 1
	if layer == "floor_shadow": z = -200
	elif layer == "interior": z = depth - 4
	elif layer == "door_glazing": z = depth - 2
	elif layer == "front_structure": z = depth
	return {"name": "Booth" + layer.to_pascal_case(), "art": ROOT.path_join(side + "-" + layer + ".png"), "region": [0, 0, CANVAS.x, CANVAS.y], "offset": [OFFSET.x, OFFSET.y], "z_offset": z}

static func catalog_entry() -> Dictionary:
	var entry := {"facings": SIDES.duplicate(), "facing_profiles": {}, "interaction_kind": "none"}
	for side: String in SIDES:
		var layers_value: Array[Dictionary] = []
		for layer: String in LAYERS: layers_value.append(descriptor(side, layer))
		var bounds := whole(side).get_used_rect()
		var point := approach(side)
		entry.facing_profiles[side] = {"profile_kind": "decorative", "status": "calibration_candidate", "review": {"art": false, "geometry": false}, "occupied": occupied(side), "clearance": [[point.x, point.y]], "anchor_offset": [0, 0], "visual_bounds": [bounds.position.x - PIVOT.x, bounds.position.y - PIVOT.y, bounds.size.x, bounds.size.y], "render_layers": layers_value, "ambient_overlays": [], "standing_viewpoints": [{"cell": [point.x, point.y], "visual_bounds": [-24, -72, 48, 80]}], "calibration_limitations": ["Closed passive booth; nine collision cells, no entering or phone action.", "Interior and glass remain separate; opaque back/side shell intentionally occludes them."]}
	return entry
