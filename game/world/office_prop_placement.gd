class_name OfficePropPlacement
extends RefCounted

var id: String = ""
var kind: String = ""
var grid: Vector2i = Vector2i.ZERO
var required_hires: int = 0
var owner_id: String = ""

static func from_json(value: Dictionary) -> OfficePropPlacement:
	var placement := OfficePropPlacement.new()
	placement.id = str(value.get("id", ""))
	placement.kind = str(value.get("kind", ""))
	placement.required_hires = maxi(0, int(value.get("required_hires", 0)))
	placement.owner_id = str(value.get("owner_id", ""))
	var grid_value: Variant = value.get("grid", [])
	if grid_value is Array:
		var coordinates := grid_value as Array
		if coordinates.size() >= 2:
			placement.grid = Vector2i(int(coordinates[0]), int(coordinates[1]))
	return placement
