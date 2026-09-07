extends "res://tools/grounded_engineer_mat_fixture.gd"
## Separate second policy; physical-floor-only fixture/evidence stays intact.
func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	result["grounded_work_shadow_follow_seat_x"] = true
	return result
