extends "res://tools/calibrated_workstation_fixture.gd"
## DEV ONLY. Independently authored opaque resting-tool plates through the
## normal room/actor pipeline; no engineer employee, probe action or backend.
const MATS := {"north": "north-v2", "east": "east-v1", "south": "south-v2", "west": "west-v1"}

static func mat_path(facing: String) -> String:
	return FIX + "engineer-mat-v1/" + str(MATS[facing]) + ".png" if MATS.has(facing) else ""

static func mat_bounds(facing: String) -> Rect2i:
	# Four explicit native placements, not raster rotations. The centered mat
	# leaves >=4 wood pixels between its edge and the two-pixel tabletop rim.
	match facing:
		"north": return Rect2i(-16, -42, 32, 20)
		"east": return Rect2i(-10, -48, 20, 32)
		"south": return Rect2i(-16, -42, 32, 20)
		"west": return Rect2i(-10, -48, 20, 32)
	return Rect2i()

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	var layers: Array[Dictionary] = []
	for entry: Dictionary in result.render_layers:
		if str(entry.name) not in ["Keyboard", "Mouse", "Monitor"]:
			layers.append(entry)
	var box := mat_bounds(facing)
	layers.append({"name": "EngineerMat", "art": mat_path(facing),
		"region": [0, 0, box.size.x, box.size.y],
		"offset": [box.position.x + box.size.x / 2, box.position.y + box.size.y / 2],
		"z_offset": 2 if facing in ["north", "south"] else 1})
	result.render_layers = layers
	var bounds := Rect2()
	for entry: Dictionary in layers:
		var region := OfficeLayout.rectangle(entry.region)
		var origin := Vector2(OfficeLayout.vector(entry.offset)) - region.size * 0.5
		var ink := OfficeLayout.measured_layer_ink_bounds(entry)
		if ink.has_area():
			var placed := Rect2(origin + ink.position, ink.size)
			bounds = bounds.merge(placed) if bounds.has_area() else placed
	result.visual_bounds = [int(bounds.position.x), int(bounds.position.y), int(bounds.size.x), int(bounds.size.y)]
	result.hit_bounds = result.visual_bounds.duplicate()
	result.calibration_limitations.append("Opaque resting electronics mat. Computer removed, no probe-use pose; existing typing is an incompatible pose stress test, not work.")
	return result
