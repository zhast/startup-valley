extends "res://tools/engineer_mat_fixture.gd"
## Separate opt-in correction; the frozen original mat fixture stays unchanged.
func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	result["grounded_work_shadow"] = true
	return result
