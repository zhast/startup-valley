extends "res://tools/calibrated_workstation_fixture.gd"
## Disposable dev instance only. All physical/actor/cue metadata stays inherited.
var finish_v2 := false

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	if finish_v2:
		for entry: Dictionary in result.render_layers:
			if str(entry.name) in ["DeskRear", "DeskFront"]:
				entry.art = str(entry.art).replace("modular-desk-v1/", "modular-desk-finish-v2/")
	return result
