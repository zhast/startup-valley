class_name PhoneBoothGeometry
extends RefCounted
## DEV ONLY: original editable native call-booth art. Closed passive furniture,
## not an enterable room or a phone action. The camera stays fixed in every view.

const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["floor_shadow", "interior", "door_glazing", "rear_structure", "front_structure"]
const CANVAS := Vector2i(256, 416)
const PIVOT := Vector2i(128, 304)
const OFFSET := Vector2i(0, -96)
const ROOT := "res://tests/fixtures/furniture-calibration/phone-booth-v3"
const RISE := 120
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
		"north": return Rect2i(-16, -16, 64, 64)
		"east": return Rect2i(-48, -16, 64, 64)
		"south": return Rect2i(-48, -48, 64, 64)
		"west": return Rect2i(-16, -48, 64, 64)
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
	for x: int in range(bounds.position.x + 5, bounds.end.x - 2, 10):
		rect(image, Rect2i(x, bounds.position.y + 3, 1, bounds.size.y - 6), FELT_DARK)

static func layers(side: String) -> Dictionary[String, Image]:
	var result: Dictionary[String, Image] = {}
	for name_value: String in LAYERS: result[name_value] = _image()
	if side not in SIDES: return result
	var floor := floor_rect(side)
	var left := floor.position.x + 2
	var right := floor.end.x - 2
	var top := floor.position.y - RISE
	var bottom := floor.end.y
	var near_top := bottom - RISE
	var rear := result.rear_structure
	var front := result.front_structure
	var interior := result.interior
	var glass := result.door_glazing
	# V3 is a compact two-cell booth, not a compressed roof over a three-cell
	# collision mask. Every top-plane pixel uses the same floor projection.
	rect(result.floor_shadow, Rect2i(left + 2, bottom - 1, right - left - 2, 3), Color("625945"))
	_felt(interior, Rect2i(left + 4, near_top + 4, right - left - 8, RISE - 8))
	box(interior, Rect2i(left + 4, bottom - 14, right - left - 8, 9), FLOOR)
	# Separate interior shelf remains a shallow overhead surface; a passive
	# exterior review does not make its interior navigable or add a phone task.
	box(interior, Rect2i(left + 10, near_top + 53, right - left - 20, 10), WOOD)
	rect(interior, Rect2i(left + 12, near_top + 62, 3, 11), DARK)
	rect(interior, Rect2i(right - 15, near_top + 62, 3, 11), DARK)
	# Same-family muted cap and continuous perimeter replace the separate beige
	# upright-looking panel. Its 64px top plane ends EXACTLY at the front rise.
	var roof := Rect2i(left, top, right - left, floor.size.y)
	rect(rear, roof, FELT_DARK)
	rect(rear, roof.grow(-1), Color("7d9390"))
	rect(rear, Rect2i(left + 2, top, right - left - 4, 1), Color("a4b5a9"))
	rect(rear, Rect2i(left, top + 2, 1, roof.size.y - 2), Color("a4b5a9"))
	# One low-contrast roof seam reads as a planar panel joint, not stacked
	# boards or a second door. Both shell and cap retain screen-fixed lighting.
	rect(rear, Rect2i(left + 3, top + 8, right - left - 6, 1), Color("879b96"))
	var vent := Rect2i(left + 19, top + 13, 22, 8)
	match side:
		"east": vent = Rect2i(left + 10, top + 20, 8, 22)
		"south": vent = Rect2i(left + 19, near_top - 18, 22, 8)
		"west": vent = Rect2i(right - 18, top + 20, 8, 22)
	box(rear, vent, FELT_DARK, FELT_LIGHT)
	if side in ["north", "south"]:
		for x: int in range(vent.position.x + 3, vent.end.x - 2, 4): rect(rear, Rect2i(x, vent.position.y + 2, 1, 4), FELT_LIGHT)
	else:
		for y: int in range(vent.position.y + 3, vent.end.y - 2, 4): rect(rear, Rect2i(vent.position.x + 2, y, 4, 1), FELT_LIGHT)
	# Full-width unbroken frame joins the roof plane to the actual near wall.
	box(rear, Rect2i(left, near_top, 5, RISE), WOOD)
	box(rear, Rect2i(right - 5, near_top, 5, RISE), EDGE)
	var door := Rect2i(left + 6, near_top + 6, right - left - 12, RISE - 11)
	rect(glass, Rect2i(door.position, Vector2i(1, door.size.y)), GLASS)
	rect(glass, Rect2i(door.end.x - 1, door.position.y, 1, door.size.y), FELT_DARK)
	rect(glass, Rect2i(door.position.x, door.position.y, door.size.x, 1), GLASS)
	for step: int in range(7): rect(glass, Rect2i(door.position + Vector2i(5 + step, 12 + step * 2), Vector2i(1, 2)), REFLECTION)
	rect(glass, Rect2i(door.end.x - 7, door.position.y + 47, 2, 15), INK)
	rect(glass, Rect2i(door.end.x - 7, door.position.y + 47, 1, 13), METAL)
	if side != "south":
		# These are three separately authored physical elevations, not rotated
		# South rasters. A side door is edge-on in this fixed camera.
		_felt(front, Rect2i(left + 4, near_top + 4, right - left - 8, RISE - 7))
		if side == "east":
			rect(front, Rect2i(right - 7, near_top + 8, 2, RISE - 15), GLASS)
			rect(front, Rect2i(right - 10, near_top + 52, 2, 13), METAL)
		elif side == "west":
			rect(front, Rect2i(left + 5, near_top + 8, 2, RISE - 15), GLASS)
			rect(front, Rect2i(left + 8, near_top + 52, 2, 13), METAL)
		else:
			# Passive ventilation hardware, not a live job/status indicator.
			for x: int in range(left + 15, right - 14, 5): rect(front, Rect2i(x, bottom - 21, 2, 8), FELT_DARK)
	box(front, Rect2i(left, near_top, right - left, 5), WOOD)
	box(front, Rect2i(left, bottom - 5, right - left, 5), WOOD)
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
		entry.facing_profiles[side] = {"profile_kind": "decorative", "status": "calibration_candidate", "review": {"art": false, "geometry": false}, "occupied": occupied(side), "clearance": [[point.x, point.y]], "anchor_offset": [0, 0], "visual_bounds": [bounds.position.x - PIVOT.x, bounds.position.y - PIVOT.y, bounds.size.x, bounds.size.y], "render_layers": layers_value, "ambient_overlays": [], "standing_viewpoints": [{"cell": [point.x, point.y], "visual_bounds": [-24, -72, 48, 80]}], "calibration_limitations": ["Closed passive booth; four collision cells, no entering or phone action.", "Interior and glass remain separate; opaque back/side shell intentionally occludes them."]}
	return entry
