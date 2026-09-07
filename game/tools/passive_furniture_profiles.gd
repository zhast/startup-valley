extends RefCounted
## DEV-ONLY exact source descriptors; no production family or review admission.
const WHITEBOARD := preload("res://tools/mobile_whiteboard_geometry.gd")
const PEDESTAL := preload("res://tools/rolling_pedestal_geometry.gd")
const FAMILIES: Array[String] = ["mobile_whiteboard", "rolling_storage_pedestal"]
const BOARD_ROOT := "res://tests/fixtures/furniture-calibration/mobile-whiteboard-v1/"
const PEDESTAL_ROOT := "res://tests/fixtures/furniture-calibration/pedestal-v1/"
const PLANNING := "res://tests/fixtures/furniture-calibration/passive-furniture-v1/whiteboard-south-planning.png"

static func profile(kind: String, facing: String) -> Dictionary:
	if kind not in FAMILIES or facing not in OfficeLayout.FACINGS: return {}
	var board := kind == "mobile_whiteboard"
	var geometry: Dictionary = WHITEBOARD.profile(facing) if board else PEDESTAL.profile(facing)
	var size := Vector2i(192, 224) if board else Vector2i(96, 144)
	var offset := Vector2i(0, -48) if board else Vector2i(0, -24)
	var names: Array[String] = WHITEBOARD.LAYERS if board else PEDESTAL.LAYERS
	var folder := BOARD_ROOT if board else PEDESTAL_ROOT
	var layers: Array[Dictionary] = []
	var bounds := Rect2()
	for part: String in names:
		var path := folder + facing + "-" + part.to_snake_case() + ".png"
		if board and facing == "south" and part == "FaceInsert": path = PLANNING
		var layer := {"name": part, "art": path, "region": [0, 0, size.x, size.y], "offset": [offset.x, offset.y], "z_offset": 0}
		layers.append(layer)
		var ink := OfficeLayout.measured_layer_ink_bounds(layer)
		if ink.has_area():
			var placed := Rect2(Vector2(offset) - Vector2(size) / 2.0 + ink.position, ink.size)
			bounds = bounds.merge(placed) if bounds.has_area() else placed
	var occupied: Array[Array] = []
	for cell: Vector2i in geometry.occupied: occupied.append([cell.x, cell.y])
	var view_cell := {"north": Vector2i(0, -1), "east": Vector2i(1, 0), "south": Vector2i(0, 1), "west": Vector2i(-1, 0)}[facing] as Vector2i
	return {"profile_kind": "decorative", "status": "calibration_candidate", "review": {"art": false, "geometry": false},
		"occupied": occupied, "clearance": [[view_cell.x, view_cell.y]], "anchor_offset": [0, 0],
		"visual_bounds": [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)],
		"render_layers": layers, "ambient_overlays": [],
		"standing_viewpoints": [{"cell": [view_cell.x, view_cell.y], "visual_bounds": [-24, -72, 48, 80]}],
		"calibration_limitations": ["Passive dev candidate: no interaction, work pose, service action or approval.",
			"Whiteboard edge views intentionally do not expose South planning content." if board else "Only South has new drawer art; common rear and sides are code-native."]}

static func catalog_entry(kind: String) -> Dictionary:
	var result := {"facings": OfficeLayout.FACINGS.duplicate(), "facing_profiles": {}}
	for facing: String in OfficeLayout.FACINGS: result.facing_profiles[facing] = profile(kind, facing)
	return result
