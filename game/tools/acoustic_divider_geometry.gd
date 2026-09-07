extends RefCounted
## DEV ONLY: double-sided felt divider. Screen-axis geometry, not raster rotation.
const SIDES: Array[String] = ["north", "east", "south", "west"]
const LAYERS: Array[String] = ["RearSupport", "Panel", "FrontFoot"]
const CANVAS := Vector2i(192, 224)
const PIVOT := Vector2i(96, 160)
const ROOT := "res://tests/fixtures/furniture-calibration/acoustic-divider-v1/"
const FELT := "res://tests/fixtures/furniture-calibration/acoustic-felt-v1/felt.png"
const INK := Color("282622")
const FRAME := Color("383833")
const LIGHT := Color("68685e")
const SHADE := Color("20221f")

static func profile(side: String) -> Dictionary:
	if side not in SIDES: return {}
	var broad := side in ["north", "south"]
	return {"orientation": side, "direction_semantics": "symmetric_visual_orientation",
		"equivalent_view": "south" if broad else "east", "canvas": CANVAS, "pivot": PIVOT,
		"floor": Rect2i(-48, -16, 96, 32) if broad else Rect2i(-16, -48, 32, 96),
		"occupied": [[-1, 0], [0, 0], [1, 0]] if broad else [[0, -1], [0, 0], [0, 1]],
		"face": Rect2i(-44, -61, 88, 56) if broad else Rect2i(-3, -20, 6, 56),
		"top": Rect2i(-44, -67, 88, 6) if broad else Rect2i(-3, -108, 6, 88),
		"fabric": Rect2i(-42, -59, 84, 52) if broad else Rect2i(),
		"visual_bounds": Rect2i(-48, -67, 96, 83) if broad else Rect2i(-16, -108, 32, 156),
		"panel_rise": 64, "lower_rise": 8, "thickness": 6, "runtime_approved": false}

static func paint(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(rect.position + PIVOT, rect.size), color)

static func box(image: Image, rect: Rect2i) -> void:
	paint(image, rect, INK)
	paint(image, rect.grow(-1), FRAME)
	paint(image, Rect2i(rect.position + Vector2i.ONE, Vector2i(rect.size.x - 2, 1)), LIGHT)
	paint(image, Rect2i(rect.position + Vector2i.ONE, Vector2i(1, rect.size.y - 2)), LIGHT)
	paint(image, Rect2i(rect.position + Vector2i(1, rect.size.y - 2), Vector2i(rect.size.x - 2, 1)), SHADE)

static func layers(side: String) -> Dictionary[String, Image]:
	var p := profile(side)
	if p.is_empty(): return {}
	var tile := Image.load_from_file(ProjectSettings.globalize_path(FELT))
	if tile == null or tile.get_size() != Vector2i(32, 32): return {}
	var result: Dictionary[String, Image] = {}
	for label: String in LAYERS: result[label] = Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var rear := result.RearSupport as Image
	var front := result.FrontFoot as Image
	var panel := result.Panel as Image
	if side in ["north", "south"]:
		# Two fixed T feet. Stepped end caps remain within the96×32 ground envelope.
		for x: int in [-36, 36]:
			box(rear, Rect2i(x - 4, -15, 8, 17))
			paint(rear, Rect2i(x - 3, -16, 6, 1), INK)
			box(rear, Rect2i(x - 2, -12, 4, 18))
			box(front, Rect2i(x - 5, 2, 10, 13))
			paint(front, Rect2i(x - 4, 15, 8, 1), INK)
		box(panel, p.top)
		box(panel, p.face)
		var field: Rect2i = p.fabric
		for y: int in range(field.position.y, field.end.y):
			for x: int in range(field.position.x, field.end.x):
				panel.set_pixelv(Vector2i(x, y) + PIVOT, tile.get_pixel(posmod(x - field.position.x, 32), posmod(y - field.position.y, 32)))
	else:
		# Long screen-Y top plane, then its near vertical6×56 edge: not a tall wall.
		for y: int in [-36, 36]:
			var foot := rear if y < 0 else front
			box(foot, Rect2i(-15, y - 4, 30, 8))
			paint(foot, Rect2i(-16, y - 3, 1, 6), INK)
			paint(foot, Rect2i(15, y - 3, 1, 6), INK)
			box(rear, Rect2i(-2, y - 8, 4, 10))
		box(panel, p.top)
		box(panel, p.face)
	return result

static func whole(parts: Dictionary[String, Image]) -> Image:
	var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	for label: String in LAYERS: image.blend_rect(parts[label], Rect2i(Vector2i.ZERO, CANVAS), Vector2i.ZERO)
	return image

static func catalog_entry() -> Dictionary:
	var profiles := {}
	for side: String in SIDES:
		var p := profile(side)
		var render_layers: Array[Dictionary] = []
		var bounds := Rect2()
		for label: String in LAYERS:
			var layer := {"name": label, "art": ROOT + side + "-" + label.to_snake_case() + ".png", "region": [0, 0, 192, 224], "offset": [0, -48], "z_offset": 0}
			render_layers.append(layer)
			var ink := OfficeLayout.measured_layer_ink_bounds(layer)
			if ink.has_area():
				var placed := Rect2(ink.position - Vector2(PIVOT), ink.size)
				bounds = bounds.merge(placed) if bounds.has_area() else placed
		profiles[side] = {"profile_kind": "decorative", "status": "calibration_candidate", "review": {"art": false, "geometry": false},
			"occupied": p.occupied, "clearance": [], "anchor_offset": [0, 0],
			"visual_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)],
			"render_layers": render_layers, "ambient_overlays": [],
			"calibration_limitations": ["Double-sided fabric: N/S equivalent; E/W equivalent. Two physical projections, not four generated originals.", "No interaction, standing viewpoint, work pose, cast shadow or production approval."]}
	return {"facings": SIDES.duplicate(), "facing_profiles": profiles}
