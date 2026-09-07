extends "res://tools/horizontal_grounded_mat_fixture.gd"
## DEV ONLY. Original opaque N2 plate parked beside the actor, never active use.
static func resting_mat_bounds() -> Rect2i:
	return Rect2i(-44, -42, 32, 20)

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	if facing != "north": return result
	var box := resting_mat_bounds()
	for entry: Dictionary in result.render_layers:
		if str(entry.name) == "EngineerMat":
			entry.offset = [box.position.x + box.size.x / 2, box.position.y + box.size.y / 2]
	# The plate remains inside the already measured desk silhouette; collision,
	# hit bounds, actor sockets and all other profile metadata stay identical.
	return result
