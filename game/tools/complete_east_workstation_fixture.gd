extends "res://tools/desk_grain_v2_fixture.gd"
## DEV ONLY. Complete East lifecycle candidate using the already-generated,
## source-registered East desk, chair, computer and employee sheets.

func _ready() -> void:
	quiet_grain = true
	employee_ids.assign(["mira", "theo"])
	initial_facing = "east"
	super._ready()

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	result.grounded_work_shadow = true
	result.grounded_work_shadow_follow_seat_x = true
	result.seat_state_handoff = {"clearance_pixels": 32}
	return result
