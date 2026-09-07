extends "res://tools/desk_grain_v2_fixture.gd"
## New combined candidate only. Existing fixtures and production remain unchanged.
func _ready() -> void:
	quiet_grain = true
	employee_ids.assign(["mira", "theo"])
	initial_facing = "south"
	super._ready()

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	result.grounded_work_shadow = true
	result.grounded_work_shadow_follow_seat_x = true
	# Source-preserving terminal/leave handoff. One logical cell clears the
	# measured32px chair ink and27–29px standing bodies; padded canvases do not
	# inflate the visual clearance contract.
	result.seat_state_handoff = {"clearance_pixels": 32}
	return result
