extends "res://tools/desk_grain_v2_fixture.gd"
## DEV ONLY. Complete West lifecycle candidate using the already-generated,
## source-registered West desk, chair, computer and employee sheets.

func _ready() -> void:
	quiet_grain = true
	employee_ids.assign(["mira", "theo"])
	initial_facing = "west"
	super._ready()

func profile(facing: String) -> Dictionary:
	var result := super.profile(facing)
	result.grounded_work_shadow = true
	result.grounded_work_shadow_follow_seat_x = true
	# One logical cell keeps the departing body in the authored chair/desk
	# sandwich until floor sorting can safely take over. Native motion evidence,
	# not this declaration, decides whether the West candidate is acceptable.
	result.seat_state_handoff = {"clearance_pixels": 32}
	return result
