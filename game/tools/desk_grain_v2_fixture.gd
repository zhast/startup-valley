extends "res://tools/desk_finish_v2_fixture.gd"
## Material-only disposable fixture. Finish, poses, sockets and physics inherited.
var quiet_grain := false

func profile(facing: String) -> Dictionary:
	finish_v2 = true
	var result := super.profile(facing)
	if quiet_grain:
		for entry: Dictionary in result.render_layers:
			if str(entry.name) in ["DeskRear", "DeskFront"]:
				entry.art = str(entry.art).replace("modular-desk-finish-v2/", "modular-desk-grain-v2/")
	return result
